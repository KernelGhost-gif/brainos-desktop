# BrainOS Qt desktop: build and runtime packaging

BrainOS uses Qt 6 Quick as its shell UI and Qt Wayland Compositor as the native
Wayland server. The Browser page uses Qt WebEngine Quick. A complete build host
must provide all three Qt development modules; installing only `qt6-base-dev`
and `qt6-declarative-dev` is not sufficient.

## Build dependencies (Debian/Ubuntu)

```bash
sudo apt-get update
sudo apt-get install --no-install-recommends \
  build-essential cmake ninja-build pkg-config \
  qt6-base-dev qt6-declarative-dev qt6-wayland-dev qt6-wayland \
  qml6-module-qtwayland-compositor qt6-webengine-dev \
  qml6-module-qtcore qml6-module-qtqml qml6-module-qtqml-models \
  qml6-module-qtqml-workerscript qml6-module-qtquick \
  qml6-module-qtquick-controls qml6-module-qtquick-templates \
  qml6-module-qtquick-layouts \
  qml6-module-qtquick-window qml6-module-qtwebengine \
  qml6-module-qtwebengine-controlsdelegates \
  qt6-tools-dev qt6-tools-dev-tools qt6-positioning-dev qt6-webchannel-dev \
  binutils curl util-linux \
  libegl-dev libgl-dev libdrm-dev libgbm-dev libinput-dev \
  libwayland-dev libxkbcommon-dev libudev-dev libdbus-1-dev \
  libfontconfig1-dev libfreetype6-dev libnss3-dev libssl-dev
```

The `qt6-webengine-dev` package supplies the Qt 6 WebEngine CMake package and
`WebEngineQuick` development target required by `CMakeLists.txt`.
`qt6-wayland-dev` provides the Qt Wayland Compositor development module.
Ubuntu also splits the Qt Wayland plugin binaries into the separate
`qt6-wayland` package; install it so the imported CMake plugin targets have
their referenced shared objects. The `qml6-module-qtwayland-compositor` package supplies the runtime QML
compositor module. Qt 6 runtime QML modules are separate Debian/Ubuntu
packages; install the Core, QML, Models, WorkerScript, Quick, Quick Controls,
Layouts, Window, and WebEngine modules listed above. The bundler validates
these imports and fails if any required module is absent. Package names can
vary on non-Debian systems; install the equivalent Qt 6 modules and system
development headers.

## Configure and compile from source

```bash
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build --parallel
DESTDIR="$PWD/stage" cmake --install build
```

For a release archive (Qt libraries, plugins, QML modules, WebEngine helper and
resource data):

```bash
./packaging/build-release.sh
```

The release bundles Qt libraries and Qt-owned runtime assets. It does **not**
turn a glibc application into a musl application and does not replace the host's
core glibc, Mesa, DRM, NSS, fontconfig, or certificate packages. The Toybox
initramfs integration uses the separate `.deb` dependency-closure workflow in
`kit/integration/README.md` to keep glibc alongside musl safely.

## Build a bootable live ISO

A complete Debian live-build host is required. The builder compiles BrainOS,
bundles Qt/WebEngine assets, and creates the live image:

```bash
sudo apt-get install live-build
sudo ./packaging/build-iso.sh
```

The default target is Debian `stable` amd64. Set `DEBIAN_SUITE` to select
another suite, `LIVE_BUILD_DIR` to retain the build workspace, and
`ARTIFACT_DIR` to change the output directory. The ISO and SHA-256 file are
written under `out/artifacts/` by default. This is a full Debian-based live
system, not the minimal musl/Toybox image.

## Installer safety

The installer enumerates targets with `lsblk`, detects EFI from
`/sys/firmware/efi`, rejects the running system disk, validates account names,
and requires exact confirmation of the target device before partitioning. Test
only in a disposable VM until a complete end-to-end installer run has passed.
