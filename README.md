# BrainOS Desktop

BrainOS Desktop is a Qt 6 / QML Wayland desktop shell with application windows, a dock, desktop widgets, status and quick-settings panels, Files, an SZH/Toybox-backed Terminal, Settings, Calculator, Browser, editor and media views. This repository tracks the source implementation and Toybox integration tooling. The vector mark and wallpaper assets are source SVGs.

## Repository layout

- `kit/brainos-qt/` — Qt 6 C++ and QML desktop, vector assets, and packaging.
- `kit/integration/` — Toybox rootfs merger, isolated glibc/Qt runtime validation, boot launcher, runtime downloader, kernel config fragment and deterministic newc/gzip packer.
- `scripts/` — kernel and initramfs build, source import, runtime checks, QEMU smoke test and publishing helper.
- `tests/` — source-contract and deterministic initramfs regression tests.

## SZH Terminal

The Terminal app defaults to the real `/bin/sh` from the pinned
`KernelGhost-gif/szh` build, with its matching musl loader, readline, ncurses,
and Toybox applet commands. It runs as a persistent PTY session, supports
shell state and history, Ctrl+C/Ctrl+D, and has a Host shell fallback.
Install `util-linux` for PTY support. SZH commands run as the current BrainOS
user against the BrainOS host filesystem; this is not a chroot or security
sandbox. The text-based UI handles shell command sessions but does not claim
full-screen terminal emulation for programs such as `vi` or `top`.

## Build the desktop

Install the Ubuntu/Debian Qt 6 development dependencies documented in [`kit/brainos-qt/packaging/README.md`](kit/brainos-qt/packaging/README.md), including Qt Wayland Compositor and Qt WebEngine Quick.

```bash
cmake -S kit/brainos-qt -B out/qt-build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build out/qt-build --parallel
```

## Integrate with Toybox

The original source ZIP did not include a complete glibc/Qt/WebEngine runtime `.deb` closure or the Linux/Toybox base source tree. Obtain those inputs using the downloader and base import instructions in [`kit/integration/README.md`](kit/integration/README.md). Build `brainos-desktop` first, then call the merger with the Toybox project, runtime dependency ZIP and built desktop executable:

```bash
./scripts/import-toybox-base.sh /path/to/linux_distro_original
python3 kit/integration/download_brainos_runtime_dependencies.py
bash kit/integration/merge-into-toybox.sh \
  linux_distro_original \
  /path/to/brainos-runtime-dependencies-full.zip \
  out/qt-build/brainos-desktop
```

The merger fails closed when required runtime libraries, Qt modules or WebEngine assets are missing. It preserves the existing musl/Toybox command provider and installs BrainOS into a separate glibc runtime area. `brainos.mode=cli` selects the original Toybox shell; `brainos.mode=desktop` selects the desktop session, with CLI fallback on failure. Chromium sandboxing is not disabled.

## Build a Debian live ISO

On a Debian build host with Qt 6 development dependencies and `live-build` installed:

```bash
sudo ./kit/brainos-qt/packaging/build-iso.sh
```

This builds the desktop from source, bundles the Qt/WebEngine runtime, and
writes an amd64 live ISO plus its SHA-256 file to `out/artifacts/`. It is a
separate Debian live image and does not replace the Toybox/musl workflow.

## Build and test the boot image

```bash
JOBS="$(nproc)" ./scripts/build-kernel.sh
SOURCE_DATE_EPOCH=0 ./scripts/build-initramfs.sh
./scripts/test-initramfs-reproducible.sh
./scripts/qemu-smoke-test.sh
```

A kernel source checkout and complete runtime bundle are required for a bootable image. The QEMU script expects a built kernel/config and initramfs under `out/`. Source tests and deterministic initramfs tests are not proof of a graphical boot; real compositor/WebEngine/QEMU verification remains a release gate.

## CI

GitHub Actions runs shell/Python syntax checks, source-contract tests, deterministic initramfs tests and a Qt 6 source build. The repository does not include the original prebuilt ELF executable or image bitmaps; build from the committed source. The complete runtime `.deb` archive and kernel/Toybox base tree are also external build inputs.
