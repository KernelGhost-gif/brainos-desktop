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
CONFIG_UPDATER="$ROOT/scripts/update_kernel_config.py"
[[ -f "$CONFIG_UPDATER" ]] || { echo "BrainOS kernel config updater is missing: $CONFIG_UPDATER" >&2; exit 2; }
command -v python3 >/dev/null || { echo "python3 is required to update the kernel config." >&2; exit 2; }
# Use a repo-owned config updater instead of depending on scripts/config
# being present in the pinned SZH kernel checkout.
config_tool() { python3 "$CONFIG_UPDATER" --file "$BUILD_DIR/.config" "$@"; }
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"

# The pinned SZH kernel snapshot stores helper scripts with mode 100644.
# Kbuild executes shell helpers and extensionless scripts/mkcompile_h directly,
# so restore their executable bits before invoking make.
find "$KERNEL_SRC" \( -type f -o -type l \) \
  \( -name '*.sh' -o -name 'setlocalversion' -o -name 'mkcompile_h' -o -name 'remove-stale-files' \) \
  -exec chmod u+x {} +
# mkcompile_h may be materialized as a symlink by the pinned snapshot's
# sparse checkout. Normalize the exact Kbuild entry points explicitly too;
# find -type f alone silently skips symlinks.
for helper in "$KERNEL_SRC/scripts/mkcompile_h" "$KERNEL_SRC/scripts/setlocalversion" "$KERNEL_SRC/scripts/remove-stale-files"; do
  if [[ -e "$helper" ]]; then chmod u+x "$helper"; fi
done
for helper in "$KERNEL_SRC/scripts/mkcompile_h" "$KERNEL_SRC/scripts/remove-stale-files"; do
  [[ -x "$helper" ]] || {
    echo "Kernel Kbuild helper is not executable after permission normalization: $helper" >&2
    ls -l "$helper" >&2 || true
    exit 5
  }
done
cp "$KERNEL_SRC/.config" "$BUILD_DIR/.config"

# This SZH snapshot stores a kernel .config and generated Kbuild directories
# in the source tree. Kbuild rejects those when O= is used. Stash only those
# generated/config paths for the duration of the out-of-tree build, then
# restore them even on failure; never run mrproper against the pinned source.
SOURCE_STASH="$(mktemp -d "$BUILD_DIR/.kernel-source-stash.XXXXXX")"
declare -a STASHED_SOURCE_PATHS=()
restore_kernel_source() {
  local path
  for path in "${STASHED_SOURCE_PATHS[@]}"; do
    [[ -e "$SOURCE_STASH/$path" ]] || continue
    rm -rf "$KERNEL_SRC/$path"
    mkdir -p "$KERNEL_SRC/$(dirname "$path")"
    mv "$SOURCE_STASH/$path" "$KERNEL_SRC/$path"
  done
  rm -rf "$SOURCE_STASH"
}
stash_source_path() {
  local path="$1"
  [[ -e "$KERNEL_SRC/$path" ]] || return 0
  mkdir -p "$SOURCE_STASH/$(dirname "$path")"
  mv "$KERNEL_SRC/$path" "$SOURCE_STASH/$path"
  STASHED_SOURCE_PATHS+=("$path")
}
trap restore_kernel_source EXIT
stash_source_path .config
stash_source_path include/config
stash_source_path arch/x86/include/generated

while IFS= read -r line; do
 case "$line" in
  CONFIG_*=y) symbol="${line#CONFIG_}"; symbol="${symbol%%=*}"; config_tool --enable "$symbol";;
  CONFIG_*=m) symbol="${line#CONFIG_}"; symbol="${symbol%%=*}"; config_tool --module "$symbol";;
  CONFIG_*=n) symbol="${line#CONFIG_}"; symbol="${symbol%%=*}"; config_tool --disable "$symbol";;
 esac
done < "$FRAGMENT"
make -C "$KERNEL_SRC" O="$BUILD_DIR" ARCH=x86_64 olddefconfig
required=(CONFIG_NAMESPACES CONFIG_USER_NS CONFIG_PID_NS CONFIG_NET_NS CONFIG_IPC_NS CONFIG_UTS_NS CONFIG_TMPFS CONFIG_POSIX_MQUEUE CONFIG_DEVTMPFS CONFIG_DRM CONFIG_DRM_VIRTIO_GPU CONFIG_DRM_BOCHS CONFIG_DRM_FBDEV_EMULATION CONFIG_INPUT_EVDEV CONFIG_UNIX CONFIG_INET CONFIG_SECCOMP CONFIG_SECCOMP_FILTER CONFIG_SERIAL_8250_CONSOLE)
for symbol in "${required[@]}"; do grep -qx "$symbol=y" "$BUILD_DIR/.config" || { echo "Kernel config disabled required option $symbol." >&2; exit 3; }; done
echo "[kernel] CONFIG_USER_NS=y verified after olddefconfig."
# GCC 13/14 does not implement the optional counted_by metadata used by
# newer Linux headers. Keep -Wattributes visible, but do not fail the kernel
# build solely because this compiler ignores that non-ABI annotation.
KERNEL_KCFLAGS="${KERNEL_KCFLAGS:--Wno-error=attributes}"
make -C "$KERNEL_SRC" O="$BUILD_DIR" ARCH=x86_64 KCFLAGS="$KERNEL_KCFLAGS" -j"$JOBS" bzImage
IMAGE="$BUILD_DIR/arch/x86/boot/bzImage"
[[ -s "$IMAGE" ]] || { echo "Kernel build did not produce bzImage." >&2; exit 4; }
install -m 0644 "$IMAGE" "$OUTPUT_DIR/bzImage"
install -m 0644 "$BUILD_DIR/.config" "$OUTPUT_DIR/kernel.config"
sha256sum "$OUTPUT_DIR/bzImage" "$OUTPUT_DIR/kernel.config" > "$OUTPUT_DIR/SHA256SUMS"
echo "[kernel] built $OUTPUT_DIR/bzImage"; cat "$OUTPUT_DIR/SHA256SUMS"
