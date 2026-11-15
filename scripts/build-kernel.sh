#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KERNEL_SRC="${1:-${BRAINOS_KERNEL_SOURCE:-$ROOT/linux_distro_original/src/linux}}"
BUILD_DIR="${KERNEL_BUILD_DIR:-$ROOT/out/kernel-build}"
OUTPUT_DIR="${KERNEL_OUTPUT_DIR:-$ROOT/out/kernel}"
FRAGMENT="${KERNEL_CONFIG_FRAGMENT:-$ROOT/kit/integration/kernel-userns.config}"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}"
[[ -d "$KERNEL_SRC" ]] || { echo "Kernel source tree not found: $KERNEL_SRC" >&2; exit 2; }
[[ -f "$KERNEL_SRC/.config" ]] || { echo "Kernel source .config not found: $KERNEL_SRC/.config" >&2; exit 2; }
[[ -f "$FRAGMENT" ]] || { echo "Kernel config fragment not found: $FRAGMENT" >&2; exit 2; }
[[ -x "$KERNEL_SRC/scripts/config" ]] || { echo "Kernel scripts/config is missing." >&2; exit 2; }
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"; cp "$KERNEL_SRC/.config" "$BUILD_DIR/.config"
while IFS= read -r line; do
 case "$line" in
  CONFIG_*=y) symbol="${line#CONFIG_}"; symbol="${symbol%%=*}"; "$KERNEL_SRC/scripts/config" --file "$BUILD_DIR/.config" --enable "$symbol";;
  CONFIG_*=m) symbol="${line#CONFIG_}"; symbol="${symbol%%=*}"; "$KERNEL_SRC/scripts/config" --file "$BUILD_DIR/.config" --module "$symbol";;
  CONFIG_*=n) symbol="${line#CONFIG_}"; symbol="${symbol%%=*}"; "$KERNEL_SRC/scripts/config" --file "$BUILD_DIR/.config" --disable "$symbol";;
 esac
done < "$FRAGMENT"
make -C "$KERNEL_SRC" O="$BUILD_DIR" ARCH=x86_64 olddefconfig
required=(CONFIG_NAMESPACES CONFIG_USER_NS CONFIG_PID_NS CONFIG_NET_NS CONFIG_IPC_NS CONFIG_UTS_NS CONFIG_TMPFS CONFIG_POSIX_MQUEUE CONFIG_DEVTMPFS CONFIG_DRM CONFIG_DRM_VIRTIO_GPU CONFIG_DRM_BOCHS CONFIG_DRM_FBDEV_EMULATION CONFIG_INPUT_EVDEV CONFIG_UNIX CONFIG_INET CONFIG_SECCOMP CONFIG_SECCOMP_FILTER CONFIG_SERIAL_8250_CONSOLE)
for symbol in "${required[@]}"; do grep -qx "$symbol=y" "$BUILD_DIR/.config" || { echo "Kernel config disabled required option $symbol." >&2; exit 3; }; done
echo "[kernel] CONFIG_USER_NS=y verified after olddefconfig."
make -C "$KERNEL_SRC" O="$BUILD_DIR" ARCH=x86_64 -j"$JOBS" bzImage
IMAGE="$BUILD_DIR/arch/x86/boot/bzImage"
[[ -s "$IMAGE" ]] || { echo "Kernel build did not produce bzImage." >&2; exit 4; }
install -m 0644 "$IMAGE" "$OUTPUT_DIR/bzImage"
install -m 0644 "$BUILD_DIR/.config" "$OUTPUT_DIR/kernel.config"
sha256sum "$OUTPUT_DIR/bzImage" "$OUTPUT_DIR/kernel.config" > "$OUTPUT_DIR/SHA256SUMS"
echo "[kernel] built $OUTPUT_DIR/bzImage"; cat "$OUTPUT_DIR/SHA256SUMS"
