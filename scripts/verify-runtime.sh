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
  [[ "$interpreter" == /lib/ld-musl-x86_64.so.1 ]] || fail "$tool is not using original musl loader (found '${interpreter:-static-or-unknown}')"
done
echo "[runtime-audit] PASS: toybox, sh, su and id remain musl-linked."
exists "$DESKTOP_BIN" || fail "BrainOS executable missing: $DESKTOP_BIN"
interpreter="$(readelf -l "$DESKTOP_BIN" | sed -n 's/.*Requesting program interpreter: \([^]]*\)].*/\1/p' | head -n1)"
[[ "$interpreter" == /lib64/ld-linux-x86-64.so.2 ]] || fail "unexpected BrainOS interpreter: ${interpreter:-missing}"
LOADER="$ROOTFS$interpreter"; exists "$LOADER" || fail "glibc loader missing: $LOADER"
LIB_PATH=""
for item in "$ROOTFS/lib/x86_64-linux-gnu" "$ROOTFS/usr/lib/x86_64-linux-gnu" "$ROOTFS/lib" "$ROOTFS/usr/lib"; do [[ -d "$item" ]] && LIB_PATH="${LIB_PATH:+$LIB_PATH:}$item"; done
[[ -n "$LIB_PATH" ]] || fail "no glibc/Qt library directories found"
check_elf() { local result; result="$("$LOADER" --library-path "$LIB_PATH" --list "$1" 2>&1)" || { echo "$result" >&2; fail "loader could not resolve $1"; }; grep -q 'not found' <<<"$result" && { echo "$result" >&2; fail "unresolved libraries for $1"; }; }
check_elf "$DESKTOP_BIN"
WEBENGINE_PROCESS="$(find "$ROOTFS/usr/lib" "$ROOTFS/lib" -type f -name QtWebEngineProcess -print -quit 2>/dev/null || true)"
[[ -n "$WEBENGINE_PROCESS" ]] || fail "QtWebEngineProcess helper missing"; check_elf "$WEBENGINE_PROCESS"
PLUGIN_ROOT="$ROOTFS/usr/lib/x86_64-linux-gnu/qt6"
for plugin in "$PLUGIN_ROOT/plugins/platforms/libqeglfs.so" "$PLUGIN_ROOT/plugins/egldeviceintegrations/libqeglfs-kms-integration.so" "$PLUGIN_ROOT/qml/QtWayland/Compositor/libqwaylandcompositorplugin.so" "$PLUGIN_ROOT/qml/QtWayland/Compositor/XdgShell/libwaylandcompositorxdgshellplugin.so" "$PLUGIN_ROOT/qml/QtWebEngine/libqtwebenginequickplugin.so"; do exists "$plugin" || fail "required Qt plugin missing: $plugin"; check_elf "$plugin"; done
for module in QtQuick/Controls QtQuick/Templates QtQuick/Layouts QtQuick/Window QtQml/WorkerScript QtWayland/Compositor QtWayland/Compositor/XdgShell QtWebEngine; do exists "$PLUGIN_ROOT/qml/$module/qmldir" || fail "required Qt QML module is missing: $module"; done
for soname in libEGL.so.1 libGLESv2.so.2 libgbm.so.1 libdrm.so.2 libwayland-server.so.0 libwayland-client.so.0 libxkbcommon.so.0 libinput.so.10 libudev.so.1 libfontconfig.so.1 libfreetype.so.6 libnss3.so libnspr4.so; do find "$ROOTFS/lib" "$ROOTFS/usr/lib" -name "$soname" -print -quit 2>/dev/null | grep -q . || fail "runtime library missing: $soname"; done
find "$ROOTFS/lib" "$ROOTFS/usr/lib" \( -type f -o -type l \) -name "libicuuc.so.*" -print -quit 2>/dev/null | grep -q . || fail "ICU shared library libicuuc missing"
find "$ROOTFS/usr/share" "$ROOTFS/usr/lib" -type f -name icudtl.dat -print -quit 2>/dev/null | grep -q . || fail "ICU data file missing"
find "$ROOTFS/usr/share" "$ROOTFS/usr/lib" -type f -name 'qtwebengine_resources*.pak' -print -quit 2>/dev/null | grep -q . || fail "QtWebEngine .pak resources missing"
find "$ROOTFS/usr/share" "$ROOTFS/usr/lib" -type d -name qtwebengine_locales -print -quit 2>/dev/null | grep -q . || fail "QtWebEngine locales missing"
# Ubuntu Noble's libgl1-mesa-dri package exposes swrast/kms_swrast
# names as symlinks to libdril_dri.so; the actual Gallium software backend
# lives in a separate versioned libgallium shared object. Check both sides
# explicitly instead of using find -L, which follows absolute symlinks against
# the host filesystem rather than the staged rootfs.
MESA_DRI_DIR="$ROOTFS/usr/lib/x86_64-linux-gnu/dri"
MESA_DRI_STUB="$MESA_DRI_DIR/libdril_dri.so"
MESA_GALLIUM="$(find "$ROOTFS/usr/lib/x86_64-linux-gnu" -maxdepth 1 -type f -name 'libgallium*.so*' -print -quit 2>/dev/null || true)"
for driver in swrast_dri.so kms_swrast_dri.so; do
  driver_path="$MESA_DRI_DIR/$driver"
  [[ -L "$driver_path" || -e "$driver_path" ]] || fail "Mesa DRI entry point missing: $driver_path"
done
[[ -s "$MESA_DRI_STUB" ]] || fail "Mesa DRI dispatcher missing: $MESA_DRI_STUB"
[[ -n "$MESA_GALLIUM" && -s "$MESA_GALLIUM" ]] || fail "Mesa Gallium software backend missing from target rootfs"
check_elf "$MESA_DRI_STUB"
check_elf "$MESA_GALLIUM"
echo "[runtime-audit] PASS: Mesa DRI dispatcher and Gallium backend are present."
exists "$ROOTFS/etc/fonts/fonts.conf" || fail "fontconfig configuration missing"
exists "$ROOTFS/etc/ssl/certs/ca-certificates.crt" || fail "CA bundle missing"
exists "$ROOTFS/usr/bin/dbus-run-session" || exists "$ROOTFS/bin/dbus-run-session" || fail "dbus-run-session missing"
# Verify the separate SZH runtime without replacing the original Toybox binaries.
SZH_ROOTFS="$ROOTFS/opt/brainos/szh"
for file in "$SZH_ROOTFS/szh-shell" "$SZH_ROOTFS/bin/sh.real" \
            "$SZH_ROOTFS/bin/toybox.real" "$SZH_ROOTFS/lib/ld-musl-x86_64.so.1"; do
  [[ -x "$file" ]] || fail "SZH executable missing or not executable: $file"
done
for file in "$SZH_ROOTFS/usr/lib/libreadline.so.8" "$SZH_ROOTFS/usr/lib/libncursesw.so.6"; do
  [[ -f "$file" ]] || fail "SZH shared library missing: $file"
done
exists "$SZH_ROOTFS/lib/libc.musl-x86_64.so.1" || fail "SZH libc loader alias missing"
exists "$SZH_ROOTFS/usr/lib/libc.musl-x86_64.so.1" || fail "SZH usr/lib libc loader alias missing"
exists "$SZH_ROOTFS/bin/ls" || fail "SZH Toybox applet wrapper missing: ls"
[[ -x "$ROOTFS/usr/bin/script" || -x "$ROOTFS/bin/script" ]] || fail "util-linux script PTY command missing from target rootfs"
readelf -l "$SZH_ROOTFS/bin/sh.real" | grep -F '/lib/ld-musl-x86_64.so.1' >/dev/null || fail "SZH shell has an unexpected ELF interpreter"
readelf -d "$SZH_ROOTFS/bin/sh.real" | grep -F 'libreadline.so.8' >/dev/null || fail "SZH shell is missing its readline dependency"
readelf -d "$SZH_ROOTFS/usr/lib/libreadline.so.8" | grep -F 'libncursesw.so.6' >/dev/null || fail "SZH readline is missing its ncurses dependency"
szh_output="$(SZH_ROOT="$SZH_ROOTFS" "$SZH_ROOTFS/szh-shell" -c 'echo SZH_ROOTFS_OK; ls "$SZH_ROOT/bin/sh.real" >/dev/null' 2>&1)" || {
  echo "$szh_output" >&2
  fail "bundled SZH shell failed its rootfs command smoke test"
}
grep -q 'SZH_ROOTFS_OK' <<<"$szh_output" || fail "bundled SZH shell did not produce its smoke-test marker"
echo "[runtime-audit] PASS: isolated SZH shell and Toybox runtime are executable."

echo "[runtime-audit] PASS: BrainOS glibc/Qt/WebEngine closure assets present."
