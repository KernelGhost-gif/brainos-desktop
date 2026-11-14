#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="${1:?usage: import-toybox-base.sh <existing-linux_distro_original-directory>}"
SOURCE="$(cd "$SOURCE" && pwd)"
DEST="$ROOT/linux_distro_original"
[[ -d "$SOURCE/distro/fs" ]] || { echo "Source does not contain distro/fs: $SOURCE" >&2; exit 2; }
[[ -d "$SOURCE/src/linux" ]] || { echo "Source does not contain src/linux kernel tree: $SOURCE" >&2; exit 2; }
[[ -f "$SOURCE/src/linux/.config" ]] || { echo "Source kernel .config missing." >&2; exit 2; }
[[ ! -e "$DEST" ]] || { echo "Refusing to overwrite existing $DEST." >&2; exit 3; }
cp -a "$SOURCE" "$DEST"
for tool in "$DEST/distro/fs/bin/toybox" "$DEST/distro/fs/bin/sh" "$DEST/distro/fs/bin/su" "$DEST/distro/fs/bin/id"; do [[ -e "$tool" ]] || { echo "Imported Toybox command missing: $tool" >&2; exit 4; }; done
printf '[base] imported Toybox rootfs + kernel source from %s\n' "$SOURCE"
printf '[base] no source repository files were modified\n'
