#!/usr/bin/env bash
set -Eeuo pipefail

ROOTFS="${1:?usage: verify-runtime.sh <rootfs> [desktop-binary]}"
DESKTOP_BIN="${2:-$ROOTFS/opt/brainos/bin/brainos-desktop}"
command -v readelf >/dev/null || { echo "readelf is required" >&2; exit 2; }

fail() { echo "[runtime-audit] ERROR: $*" >&2; exit 1; }
exists() { [[ -e "$1" || -L "$1" ]]; }

for tool in "$ROOTFS/bin/toybox" "$ROOTFS/bin/sh" "$ROOTFS/bin/su" "$ROOTFS/bin/id"; do
  exists "$tool" || fail "Toybox command missing: $tool"
  interpreter="$(readelf -l "$tool" 2>/dev/null | sed -n 's/.*Requesting program interpreter: \([^]]*\)].*/\1/p' | head -n1)"
  [[ "$interpreter" == /lib/ld-musl-x86_64.so.1 ]] || fail "$tool is not using the original musl loader (found '${interpreter:-static-or-unknown}')"
done

echo "[runtime-audit] PASS: toybox, sh, su and id remain musl-linked."

exists "$DESKTOP_BIN" || fail "BrainOS executable missing: $DESKTOP_BIN"
interpreter="$(readelf -l "$DESKTOP_BIN" | sed -n 's/.*Requesting program interpreter: \([^]]*\)].*/\1/p' | head -n1)"
[[ "$interpreter" == /lib64/ld-linux-x86-64.so.2 ]] || fail "unexpected BrainOS interpreter: ${interpreter:-missing}"
LOADER="$ROOTFS$interpreter"
exists "$LOADER" || fail "glibc dynamic loader missing: $LOADER"

LIB_PATHS=("$ROOTFS/lib/x86_64-linux-gnu" "$ROOTFS/usr/lib/x86_64-linux-gnu" "$ROOTFS/lib" "$ROOTFS/usr/lib")
LIB_PATH=""
for item in "${LIB_PATHS[@]}"; do [[ -d "$item" ]] && LIB_PATH="${LIB_PATH:+$LIB_PATH:}$item"; done
[[ -n "$LIB_PATH" ]] || fail "no glibc/Qt library directories found"
check_elf() {
  local object="$1" result
  result="$("$LOADER" --library-path "$LIB_PATH" --list "$object" 2>&1)" || { echo "$result" >&2; fail "glibc loader could not resolve $object"; }
  if grep -q 'not found' <<<"$result"; then echo "$result" >&2; fail "unresolved shared libraries for $object"; fi
}
check_elf "$DESKTOP_BIN"
WEBENGINE_PROCESS="$(find "$ROOTFS/usr/lib" "$ROOTFS/lib" -type f -name QtWebEngineProcess -print -quit 2>/dev/null || true)"
[[ -n "$WEBENGINE_PROCESS" ]] || fail "QtWebEngineProcess helper missing"
check_elf "$WEBENGINE_PROCESS"
PLUGIN_ROOT="$ROOTFS/usr/lib/x86_64-linux-gnu/qt6"
for plugin in "$PLUGIN_ROOT/plugins/platforms/libqeglfs.so" "$PLUGIN_ROOT/plugins/egldeviceintegrations/libqeglfs-kms-integration.so" "$PLUGIN_ROOT/qml/QtWayland/Compositor/libqwaylandcompositorplugin.so" "$PLUGIN_ROOT/qml/QtWayland/Compositor/XdgShell/libwaylandcompositorxdgshellplugin.so" "$PLUGIN_ROOT/qml/QtWebEngine/libqtwebenginequickplugin.so"; do
  exists "$plugin" || fail "required Qt plugin missing: $plugin"; check_elf "$plugin"
done
for soname in libEGL.so.1 libGLESv2.so.2 libgbm.so.1 libdrm.so.2 libwayland-server.so.0 libwayland-client.so.0 libxkbcommon.so.0 libinput.so.10 libudev.so.1 libfontconfig.so.1 libfreetype.so.6 libnss3.so libnspr4.so; do
  find "$ROOTFS/lib" "$ROOTFS/usr/lib" -name "$soname" -print -quit 2>/dev/null | grep -q . || fail "runtime library missing: $soname"
done
find "$ROOTFS/usr/share" "$ROOTFS/usr/lib" -type f -name icudtl.dat -print -quit 2>/dev/null | grep -q . || fail "ICU data file icudtl.dat missing"
find "$ROOTFS/usr/share" "$ROOTFS/usr/lib" -type f -name 'qtwebengine_resources*.pak' -print -quit 2>/dev/null | grep -q . || fail "QtWebEngine resource .pak files missing"
find "$ROOTFS/usr/share" "$ROOTFS/usr/lib" -type d -name qtwebengine_locales -print -quit 2>/dev/null | grep -q . || fail "QtWebEngine locales missing"
find "$ROOTFS/usr/lib" -type f \( -name swrast_dri.so -o -name kms_swrast_dri.so \) -print -quit 2>/dev/null | grep -q . || fail "Mesa software DRI driver missing"
exists "$ROOTFS/etc/fonts/fonts.conf" || fail "fontconfig configuration missing"
exists "$ROOTFS/etc/ssl/certs/ca-certificates.crt" || fail "CA certificates bundle missing"
exists "$ROOTFS/usr/bin/dbus-run-session" || exists "$ROOTFS/bin/dbus-run-session" || fail "target dbus-run-session missing"
echo "[runtime-audit] PASS: BrainOS glibc/Qt/WebEngine runtime closure assets are present."
