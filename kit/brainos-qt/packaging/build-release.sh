#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_dir="${BUILD_DIR:-$root/build-release}"
stage="${STAGE_DIR:-$root/out/brainos-root}"
artifacts="${ARTIFACT_DIR:-$root/out/artifacts}"

rm -rf "$stage"
cmake -S "$root" -B "$build_dir" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
cmake --build "$build_dir" --parallel
DESTDIR="$stage" cmake --install "$build_dir"
"$root/packaging/scripts/bundle-qt-runtime.sh" "$stage"
"$root/packaging/scripts/bundle-szh-terminal.sh" "$stage"

mkdir -p "$artifacts"
version="${BRAINOS_VERSION:-$(date +%Y.%m.%d)}"
tar --sort=name --mtime="@${SOURCE_DATE_EPOCH:-0}" --owner=0 --group=0 --numeric-owner \
    -C "$stage" -czf "$artifacts/brainos-runtime-$version-x86_64.tar.gz" .
sha256sum "$artifacts/brainos-runtime-$version-x86_64.tar.gz" \
  > "$artifacts/brainos-runtime-$version-x86_64.tar.gz.sha256"
echo "$artifacts/brainos-runtime-$version-x86_64.tar.gz"
