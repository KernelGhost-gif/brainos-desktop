#!/usr/bin/env bash
set -Eeuo pipefail
stage="${1:?Usage: bundle-szh-terminal.sh <staged-root>}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
applet_manifest="$script_dir/szh-toybox-applets.txt"
destination="$stage/opt/brainos/szh"
szh_commit="${SZH_COMMIT:-1037b073d4ef62029548305b6b13fcd133e3a270}"
source_root="${SZH_ROOTFS:-}"
raw_base="https://raw.githubusercontent.com/KernelGhost-gif/szh/$szh_commit"

command -v readelf >/dev/null || { echo "readelf (binutils) is required." >&2; exit 2; }
command -v sha1sum >/dev/null || { echo "sha1sum is required." >&2; exit 2; }
command -v curl >/dev/null || { echo "curl is required to fetch the pinned SZH source license." >&2; exit 2; }
[[ -f "$applet_manifest" ]] || { echo "Toybox applet manifest is missing." >&2; exit 2; }

mkdir -p "$destination/bin" "$destination/lib" "$destination/usr/lib" "$destination/usr/bin"

verify_git_blob() {
  local file="$1" expected="$2" size actual
  size="$(wc -c < "$file" | tr -d ' ')"
  actual="$( (printf 'blob %s\0' "$size"; cat "$file") | sha1sum | awk '{print $1}')"
  [[ "$actual" == "$expected" ]] || {
    echo "SZH payload integrity failure for $file: expected $expected, got $actual" >&2
    exit 3
  }
}

fetch_payload() {
  local remote_path="$1" local_path="$2" output="$3" expected="$4"
  if [[ -n "$source_root" ]]; then
    [[ -f "$source_root/$local_path" ]] || { echo "Missing SZH source file: $source_root/$local_path" >&2; exit 4; }
    install -m 0644 "$source_root/$local_path" "$output"
  else
    curl --fail --location --retry 4 --retry-all-errors --connect-timeout 20 \
      --silent --show-error "$raw_base/$remote_path" --output "$output"
  fi
  verify_git_blob "$output" "$expected"
}

fetch_payload "linux_distro_original/distro/fs/bin/sh" "bin/sh" \
  "$destination/bin/sh.real" "53e79f0ae45db7468378f37087397db74d16eb3f"
fetch_payload "linux_distro_original/distro/fs/bin/toybox" "bin/toybox" \
  "$destination/bin/toybox.real" "f6b7816a508aed050140739f5f2cc8957264ddb6"
fetch_payload "linux_distro_original/distro/fs/lib/ld-musl-x86_64.so.1" "lib/ld-musl-x86_64.so.1" \
  "$destination/lib/ld-musl-x86_64.so.1" "5ed7db5710f24459a14c3960e9863d9f1a57b3bf"
fetch_payload "linux_distro_original/distro/fs/usr/lib/libreadline.so.8" "usr/lib/libreadline.so.8" \
  "$destination/usr/lib/libreadline.so.8" "3e66239cd84b7fb6e28d90b4a173783e4946fc11"
fetch_payload "linux_distro_original/distro/fs/usr/lib/libncursesw.so.6" "usr/lib/libncursesw.so.6" \
  "$destination/usr/lib/libncursesw.so.6" "c54630b419cf77293e94a83f0d31ba077d5602b2"

# Keep the upstream SZH license alongside the copied runtime.
curl --fail --location --retry 4 --retry-all-errors --connect-timeout 20 \
  --silent --show-error "$raw_base/LICENSE" --output "$destination/SZH-LICENSE.txt"
verify_git_blob "$destination/SZH-LICENSE.txt" "f288702d2fa16d3cdf0035b15a9fcbc552cd88e7"

chmod 0755 "$destination/bin/sh.real" "$destination/bin/toybox.real" \
  "$destination/lib/ld-musl-x86_64.so.1"

# musl's loader is also the libc object for this SZH build.
ln -sfn ld-musl-x86_64.so.1 "$destination/lib/libc.musl-x86_64.so.1"
ln -sfn ../../lib/libc.musl-x86_64.so.1 "$destination/usr/lib/libc.musl-x86_64.so.1"

# Applet commands are host-shell wrappers which dispatch through SZH's own musl loader.
cat > "$destination/bin/toybox-applet" <<'EOF'
#!/bin/sh
ROOT="${SZH_ROOT:-/opt/brainos/szh}"
APPLET="${0##*/}"
export LD_LIBRARY_PATH="$ROOT/usr/lib:$ROOT/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$ROOT/lib/ld-musl-x86_64.so.1" "$ROOT/bin/toybox.real" "$APPLET" "$@"
EOF
cat > "$destination/bin/toybox" <<'EOF'
#!/bin/sh
ROOT="${SZH_ROOT:-/opt/brainos/szh}"
export LD_LIBRARY_PATH="$ROOT/usr/lib:$ROOT/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$ROOT/lib/ld-musl-x86_64.so.1" "$ROOT/bin/toybox.real" "$@"
EOF
cat > "$destination/bin/sh" <<'EOF'
#!/bin/sh
ROOT="${SZH_ROOT:-/opt/brainos/szh}"
export LD_LIBRARY_PATH="$ROOT/usr/lib:$ROOT/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
exec "$ROOT/lib/ld-musl-x86_64.so.1" "$ROOT/bin/sh.real" "$@"
EOF
cat > "$destination/szh-shell" <<'EOF'
#!/bin/sh
ROOT="${SZH_ROOT:-/opt/brainos/szh}"
export LD_LIBRARY_PATH="$ROOT/usr/lib:$ROOT/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PATH="$ROOT/bin:$ROOT/usr/bin:$ROOT/sbin:$ROOT/usr/sbin:$PATH"
export TERM="${TERM:-xterm-256color}"
export COLORTERM="${COLORTERM:-truecolor}"
export HISTFILE="${HISTFILE:-$HOME/.szh_history}"
export PS1="${PS1:-szh$ }"
if [ "$#" -gt 0 ]; then
    exec "$ROOT/bin/sh" "$@"
fi
exec "$ROOT/bin/sh" -i
EOF
chmod 0755 "$destination/bin/toybox-applet" "$destination/bin/toybox" \
  "$destination/bin/sh" "$destination/szh-shell"

while IFS= read -r applet; do
  [[ -n "$applet" ]] || continue
  case "$applet" in toybox|sh) continue ;; esac
  ln -sfn toybox-applet "$destination/bin/$applet"
  ln -sfn "../../bin/$applet" "$destination/usr/bin/$applet"
done < "$applet_manifest"

mkdir -p "$destination/sbin" "$destination/usr/sbin"
for applet in halt hwclock ifconfig insmod killall5 losetup lsmod mkswap modinfo \
  partprobe pivot_root poweroff reboot rmmod swapoff swapon switch_root sysctl \
  vconfig watchdog chroot devmem fsfreeze rfkill; do
  ln -sfn "../bin/$applet" "$destination/sbin/$applet"
  ln -sfn "../../bin/$applet" "$destination/usr/sbin/$applet"
done

# Check the ELF interpreter and transitive SZH userland dependencies before packaging.
readelf -l "$destination/bin/sh.real" | grep -F '/lib/ld-musl-x86_64.so.1' >/dev/null
readelf -d "$destination/bin/sh.real" | grep -F 'libreadline.so.8' >/dev/null
readelf -d "$destination/bin/sh.real" | grep -F 'libc.musl-x86_64.so.1' >/dev/null
readelf -d "$destination/usr/lib/libreadline.so.8" | grep -F 'libncursesw.so.6' >/dev/null
readelf -d "$destination/bin/toybox.real" | grep -F 'libc.musl-x86_64.so.1' >/dev/null
[[ -x "$destination/szh-shell" && -x "$destination/bin/toybox" && -L "$destination/bin/ls" ]]

cat > "$destination/BUILD-INFO.txt" <<EOF
SZH terminal runtime
Source: https://github.com/KernelGhost-gif/szh
Pinned commit: $szh_commit
Shell: musl-linked /bin/sh with readline
Utilities: Toybox multicall build from SZH
Runtime: bundled musl loader and musl readline/ncurses libraries
Filesystem/privileges: commands run as the current BrainOS user against the BrainOS host filesystem.
This is an embedded shell/userland, not a chroot or a complete SZH boot.
EOF

echo "Bundled SZH shell, musl loader, readline, ncurses and Toybox applets at $destination"
