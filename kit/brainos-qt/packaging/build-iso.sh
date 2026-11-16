#!/usr/bin/env bash
set -Eeuo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../../.." && pwd)"
live_build_dir="${LIVE_BUILD_DIR:-}"
temporary_work=0

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  command -v sudo >/dev/null 2>&1 || { echo "Run as root or install sudo." >&2; exit 2; }
  exec sudo -E "$0" "$@"
fi

command -v lb >/dev/null 2>&1 || { echo "live-build is required (apt install live-build)." >&2; exit 2; }
command -v cmake >/dev/null 2>&1 || { echo "CMake is required." >&2; exit 2; }
command -v ninja >/dev/null 2>&1 || { echo "Ninja is required." >&2; exit 2; }

if [[ -z "$live_build_dir" ]]; then
  live_build_dir="$(mktemp -d "${TMPDIR:-/tmp}/brainos-live-build.XXXXXX")"
  temporary_work=1
fi

cleanup() {
  if [[ "$temporary_work" == 1 ]]; then
    rm -rf "$live_build_dir"
  fi
}
trap cleanup EXIT

live_build_dir="$(mkdir -p "$live_build_dir" && cd "$live_build_dir" && pwd)"
stage="$live_build_dir/brainos-stage"
suite="${DEBIAN_SUITE:-stable}"
artifact_dir="${ARTIFACT_DIR:-$repo_root/out/artifacts}"
version="${BRAINOS_VERSION:-$(date -u +%Y.%m.%d)}"
mkdir -p "$artifact_dir"
artifact_dir="$(cd "$artifact_dir" && pwd)"

if [[ -n "${BRAINOS_PREBUILT_STAGE:-}" ]]; then
  stage="$(cd "$BRAINOS_PREBUILT_STAGE" && pwd)"
  [[ -x "$stage/opt/brainos/bin/brainos-desktop" ]] || {
    echo "Prebuilt BrainOS stage is incomplete: $stage" >&2
    exit 1
  }
  echo "[iso] Reusing the verified BrainOS runtime stage at $stage."
else
  echo "[iso] Building BrainOS and staging the bundled Qt runtime."
  STAGE_DIR="$stage" ARTIFACT_DIR="$live_build_dir/release-artifacts" \
    SOURCE_DATE_EPOCH="${SOURCE_DATE_EPOCH:-0}" \
    "$script_dir/build-release.sh"
fi

cd "$live_build_dir"
echo "[iso] Preparing Debian live-build configuration ($suite, amd64)."
lb config \
  --distribution "$suite" \
  --architectures amd64 \
  --binary-images iso-hybrid \
  --archive-areas "main contrib non-free non-free-firmware" \
  --bootappend-live "boot=live components quiet splash hostname=brainos"

mkdir -p \
  "$live_build_dir/config/package-lists" \
  "$live_build_dir/config/hooks/live" \
  "$live_build_dir/config/includes.chroot/opt" \
  "$live_build_dir/config/includes.chroot/lib/systemd/system"

cp "$script_dir/live-build/brainos.list.chroot" \
  "$live_build_dir/config/package-lists/brainos.list.chroot"
install -m 0755 "$script_dir/live-build/010-brainos-user.hook.chroot" \
  "$live_build_dir/config/hooks/live/010-brainos-user.hook.chroot"
cp -a "$stage/opt/brainos" "$live_build_dir/config/includes.chroot/opt/"
install -m 0644 "$stage/lib/systemd/system/brainos-shell.service" \
  "$live_build_dir/config/includes.chroot/lib/systemd/system/brainos-shell.service"

echo "[iso] Building the live image. This step downloads Debian packages."
lb build

iso_path="$(find "$live_build_dir" -type f -name '*.iso' -print -quit)"
[[ -s "$iso_path" ]] || { echo "live-build completed but no ISO was produced." >&2; exit 1; }

output="$artifact_dir/brainos-desktop-$version-amd64.iso"
cp "$iso_path" "$output"
sha256sum "$output" > "$output.sha256"
if [[ -n "${SUDO_UID:-}" ]]; then
  chown "$SUDO_UID:${SUDO_GID:-$SUDO_UID}" "$output" "$output.sha256"
fi

echo "[iso] Created $output"
cat "$output.sha256"
