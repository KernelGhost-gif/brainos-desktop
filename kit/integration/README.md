# BrainOS Qt + Toybox integration

This integration adds the BrainOS Qt 6 Wayland compositor to an existing x86_64 Toybox root filesystem. It preserves the Toybox/musl command provider and installs BrainOS under `/opt/brainos` while a separate glibc runtime closure provides `/lib64/ld-linux-x86-64.so.2`.

The source repository does not contain a complete Qt/glibc runtime `.deb` closure or the Linux/Toybox base tree. Generate the runtime ZIP with the downloader before running the merger. The merger inspects the bundle and fails closed when required packages are absent.

## 1. Build dependencies

Install the Qt 6 packages listed in `kit/brainos-qt/packaging/README.md`, including `qt6-wayland-dev` and `qt6-webengine-dev`.

```bash
cmake -S kit/brainos-qt -B out/qt-build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build out/qt-build --parallel
```

## 2. Obtain the target runtime bundle

Run `download_brainos_runtime_dependencies.py` with Windows Python and WSL Ubuntu configured. It downloads the dependency closure using a fresh dpkg status database, so packages already installed in WSL are included without installing anything into WSL.

```powershell
py .\kit\integration\download_brainos_runtime_dependencies.py
```

Review `brainos-runtime-dependencies-full.zip` before integrating it. The bundle needs glibc, C++ runtime, ICU, Qt Core/DBus/Gui/QML/Quick/Controls/Wayland/WebEngine, `QtWebEngineProcess`, WebEngine resources/locales, EGL/GLES, Mesa, DRM/GBM, Wayland, libinput, xkbcommon, udev, NSS/NSPR, OpenSSL, certificates, fontconfig and FreeType.

## 3. Import and merge the Toybox rootfs

```bash
./scripts/import-toybox-base.sh /path/to/linux_distro_original
bash kit/integration/merge-into-toybox.sh \
  linux_distro_original \
  /path/to/brainos-runtime-dependencies-full.zip \
  out/qt-build/brainos-desktop
```

The base project must contain `distro/fs`, `src/linux/.config` and the existing Toybox shell, `su`, `id`, `/etc/inittab` and `/etc/init.d/rcS`. Back up the target first. The merger checks that the Toybox command binaries use `/lib/ld-musl-x86_64.so.1` before modifying the rootfs. It extracts the glibc packages separately, installs BrainOS, creates an unprivileged session account, adds a launcher to init and builds a deterministic initramfs. The glibc dependency bundle must include the Qt Wayland Compositor and WebEngine runtime plugins and resources expected by `verify-runtime.sh`.

Boot modes: `brainos.mode=cli` starts the original Toybox shell; `brainos.mode=desktop` starts BrainOS (default). A missing runtime or failed compositor returns to Toybox CLI. Chromium sandboxing stays enabled; there is no `--no-sandbox` fallback.

## 4. Build the kernel

```bash
JOBS="$(nproc)" ./scripts/build-kernel.sh
```

The kernel source must exist under `linux_distro_original/src/linux` with the original `.config`. The build merges `kernel-userns.config`, runs `olddefconfig`, checks required symbols and stores the kernel, config and checksums under `out/kernel`.

## 5. Build deterministic initramfs

```bash
SOURCE_DATE_EPOCH=0 ./scripts/build-initramfs.sh
./scripts/test-initramfs-reproducible.sh
```

The packer normalizes file order, inode allocation, UID/GID, timestamps and gzip metadata.

## 6. QEMU verification

Install `qemu-system-x86`, `binutils`, `gzip` and `vncdotool` (`python3 -m pip install vncdotool`). Then run:

```bash
./scripts/qemu-smoke-test.sh
```

It tests the Toybox CLI boot and the desktop boot with virtio VGA and VNC, checks Wayland socket readiness and compositor stability, and saves serial logs/screenshots under `out/qemu`. A source check or deterministic initramfs is not proof of a successful Qt launch; QEMU verification with the complete runtime and kernel is a release gate.
