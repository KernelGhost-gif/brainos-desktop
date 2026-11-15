#!/usr/bin/env bash
set -Eeuo pipefail

usage() { echo "Usage: $0 <linux_distro_original> <runtime-dependencies-full.zip> <brainos-desktop-binary>" >&2; }
[[ $# -eq 3 ]] || { usage; exit 2; }
PROJECT_ROOT="$(cd "$1" && pwd)"
DEPS_ZIP="$(realpath "$2")"
DESKTOP_BIN="$(realpath "$3")"
KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="$PROJECT_ROOT/distro/fs"
INITTAB="$ROOTFS/etc/inittab"
RCS="$ROOTFS/etc/init.d/rcS"
for f in "$ROOTFS/bin/toybox" "$ROOTFS/bin/sh" "$ROOTFS/bin/su" "$ROOTFS/bin/id" "$INITTAB" "$RCS" "$DEPS_ZIP" "$DESKTOP_BIN"; do
  [[ -e "$f" ]] || { echo "Required input missing: $f" >&2; exit 2; }
done
for tool in unzip dpkg-deb readelf python3 curl sha1sum; do command -v "$tool" >/dev/null || { echo "Missing tool: $tool" >&2; exit 2; }; done

# Confirm the original command provider uses musl before modifying anything.
for tool in "$ROOTFS/bin/toybox" "$ROOTFS/bin/sh" "$ROOTFS/bin/su" "$ROOTFS/bin/id"; do
  interp="$(readelf -l "$tool" 2>/dev/null | sed -n 's/.*Requesting program interpreter: \([^]]*\)].*/\1/p' | head -n1)"
  [[ "$interp" == /lib/ld-musl-x86_64.so.1 ]] || { echo "$tool does not use the expected musl loader: ${interp:-unknown}" >&2; exit 3; }
done
if ! grep -q '^::respawn:/bin/sh$' "$INITTAB" && ! grep -q '^::respawn:/sbin/brainos-launch$' "$INITTAB"; then
  echo "Unexpected init respawn entry; refusing to change it." >&2; exit 3
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/debs" "$TMP/stage"
unzip -oq "$DEPS_ZIP" -d "$TMP/debs"
shopt -s nullglob
DEBS=("$TMP/debs"/*.deb)
(( ${#DEBS[@]} > 0 )) || { echo "No .deb files found in runtime ZIP." >&2; exit 4; }
declare -A PRESENT=()
for deb in "${DEBS[@]}"; do
  package="$(dpkg-deb -f "$deb" Package)"
  arch="$(dpkg-deb -f "$deb" Architecture)"
  [[ "$arch" == amd64 || "$arch" == all ]] || { echo "Unexpected package architecture $arch: $deb" >&2; exit 4; }
  PRESENT["$package"]="$deb"
done
required=(libc6 libc-bin libgcc-s1 libstdc++6 dbus dbus-daemon fontconfig libfontconfig1 libfreetype6 ca-certificates libnss3 libnspr4 libegl1 libgles2 libgl1 libgl1-mesa-dri libglx-mesa0 libdrm2 libgbm1 libwayland-client0 libwayland-server0 libwayland-egl1 libwayland-cursor0 libxkbcommon0 libinput10 libudev1 libqt6core6t64 libqt6dbus6 libqt6gui6 libqt6qml6 libqt6qmlmodels6 libqt6qmlworkerscript6 libqt6quick6 libqt6quickcontrols2-6 libqt6quicktemplates2-6 libqt6waylandcompositor6 libqt6webenginecore6 libqt6webenginequick6 util-linux)
for package in "${required[@]}"; do [[ -n "${PRESENT[$package]:-}" ]] || { echo "Runtime bundle is incomplete: missing $package" >&2; exit 5; }; done
icu_package=""
for package in "${!PRESENT[@]}"; do
  if [[ "$package" =~ ^libicu[0-9]+$ ]]; then icu_package="$package"; break; fi
done
[[ -n "$icu_package" ]] || { echo "Runtime bundle is incomplete: no versioned libicu runtime package was supplied." >&2; exit 5; }

# Extract first into a staging tree. No target file is changed until preflight passes.
for deb in "${DEBS[@]}"; do dpkg-deb -x "$deb" "$TMP/stage"; done
loader="$TMP/stage/lib64/ld-linux-x86-64.so.2"
[[ -e "$loader" ]] || loader="$TMP/stage/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2"
[[ -e "$loader" ]] || { echo "glibc x86_64 loader missing from runtime package closure." >&2; exit 5; }
install -d "$ROOTFS"
cp -a "$TMP/stage/." "$ROOTFS/"
install -d "$ROOTFS/opt/brainos/bin" "$ROOTFS/sbin" "$ROOTFS/etc/sysctl.d" "$ROOTFS/run/user/1000"
install -m 0755 "$DESKTOP_BIN" "$ROOTFS/opt/brainos/bin/brainos-desktop"
install -m 0755 "$KIT_DIR/integration/brainos-session" "$ROOTFS/opt/brainos/bin/brainos-session"
install -m 0755 "$KIT_DIR/integration/brainos-launch" "$ROOTFS/sbin/brainos-launch"
install -m 0755 "$KIT_DIR/integration/verify-runtime.sh" "$ROOTFS/opt/brainos/bin/verify-runtime.sh"

# Ensure the isolated glibc loader is discoverable without touching musl paths.
mkdir -p "$ROOTFS/lib64"
if [[ ! -e "$ROOTFS/lib64/ld-linux-x86-64.so.2" ]]; then
  ln -s ../lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 "$ROOTFS/lib64/ld-linux-x86-64.so.2"
fi

add_group() {
  local name="$1" gid="$2"
  if ! grep -q "^${name}:" "$ROOTFS/etc/group" 2>/dev/null; then echo "$name:x:$gid:brainos" >> "$ROOTFS/etc/group"; fi
}
add_group brainos 1000; add_group video 27; add_group audio 29; add_group input 104; add_group render 105
if ! grep -q '^brainos:' "$ROOTFS/etc/passwd" 2>/dev/null; then echo 'brainos:x:1000:1000:BrainOS Desktop:/home/brainos:/bin/sh' >> "$ROOTFS/etc/passwd"; fi
if ! grep -q '^brainos:' "$ROOTFS/etc/shadow" 2>/dev/null; then echo 'brainos:!:19000:0:99999:7:::' >> "$ROOTFS/etc/shadow"; fi
mkdir -p "$ROOTFS/home/brainos"; chown 1000:1000 "$ROOTFS/home/brainos" 2>/dev/null || true; chmod 0700 "$ROOTFS/home/brainos"
cat > "$ROOTFS/etc/sysctl.d/90-brainos-userns.conf" <<'EOF'
user.max_user_namespaces = 65536
kernel.unprivileged_userns_clone = 1
EOF
if ! grep -q 'BRAINOS-DESKTOP-INTEGRATION' "$RCS"; then
  cat >> "$RCS" <<'EOF'

# BRAINOS-DESKTOP-INTEGRATION: required runtime mounts.
mkdir -p /dev/pts /dev/shm /run
mount -t devpts devpts /dev/pts 2>/dev/null || true
mount -t tmpfs tmpfs /dev/shm 2>/dev/null || true
mount -t tmpfs tmpfs /run 2>/dev/null || true
mkdir -p /run/user/1000
EOF
fi
if grep -q '^::respawn:/bin/sh$' "$INITTAB"; then sed -i 's#^::respawn:/bin/sh$#::respawn:/sbin/brainos-launch#' "$INITTAB"; fi
cat > "$ROOTFS/etc/brainos-release" <<'EOF'
BrainOS Qt desktop integrated over the Toybox-based Linux userspace.
Toybox remains the command provider for the original rootfs.
EOF
# Add the exact SZH shell/runtime as a separate /opt payload. The existing
# /bin/sh, /bin/toybox and /lib/ld-musl paths remain untouched.
SZH_BUNDLER="$KIT_DIR/brainos-qt/packaging/scripts/bundle-szh-terminal.sh"
[[ -x "$SZH_BUNDLER" ]] || { echo "SZH terminal bundler is missing or not executable." >&2; exit 6; }
SZH_ROOTFS="${SZH_ROOTFS:-}" "$SZH_BUNDLER" "$ROOTFS"

# Add the exact SZH shell/runtime as a separate /opt payload. The existing
# /bin/sh, /bin/toybox and /lib/ld-musl paths remain untouched.
SZH_BUNDLER="$KIT_DIR/brainos-qt/packaging/scripts/bundle-szh-terminal.sh"
[[ -x "$SZH_BUNDLER" ]] || { echo "SZH terminal bundler is missing or not executable." >&2; exit 6; }
SZH_ROOTFS="${SZH_ROOTFS:-}" "$SZH_BUNDLER" "$ROOTFS"

"$KIT_DIR/integration/verify-runtime.sh" "$ROOTFS" "$ROOTFS/opt/brainos/bin/brainos-desktop"
mkdir -p "$PROJECT_ROOT/distro"
python3 "$KIT_DIR/integration/pack_initramfs.py" "$ROOTFS" "$PROJECT_ROOT/distro/init.brainos.cpio.gz"
sha256sum "$PROJECT_ROOT/distro/init.brainos.cpio.gz" > "$PROJECT_ROOT/distro/init.brainos.cpio.gz.sha256"
echo "Integration staged at: $ROOTFS"
echo "New initramfs: $PROJECT_ROOT/distro/init.brainos.cpio.gz"
echo "Kernel not rebuilt. QEMU boot and runtime validation remain required."
