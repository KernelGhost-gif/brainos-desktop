#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${1:-$ROOT/linux_distro_original/distro/fs}"
OUTPUT="${2:-$ROOT/out/initramfs/brainos-initramfs.cpio.gz}"
[[ -d "$ROOTFS" ]] || { echo "Rootfs not found: $ROOTFS" >&2; exit 2; }
mkdir -p "$(dirname "$OUTPUT")"
SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-0}" LC_ALL=C python3 "$ROOT/kit/integration/pack_initramfs.py" "$ROOTFS" "$OUTPUT"
sha256sum "$OUTPUT" > "$OUTPUT.sha256"
cat "$OUTPUT.sha256"
