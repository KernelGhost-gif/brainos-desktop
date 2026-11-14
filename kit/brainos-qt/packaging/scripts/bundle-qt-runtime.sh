#!/usr/bin/env bash
set -Eeuo pipefail

appdir="${1:?usage: bundle-qt-runtime.sh <staged-root>}"
qtpaths="${QTPATHS:-$(command -v qtpaths6 || command -v qtpaths || true)}"
[[ -n "$qtpaths" ]] || { echo "qtpaths6 is required (install qt6-tools-dev-tools)." >&2; exit 1; }

qt_lib="$($qtpaths --query QT_INSTALL_LIBS)"
qt_plugins="$($qtpaths --query QT_INSTALL_PLUGINS)"
qt_qml="$($qtpaths --query QT_INSTALL_QML)"
qt_data="$($qtpaths --query QT_INSTALL_DATA)"
qt_libexecs="$($qtpaths --query QT_INSTALL_LIBEXECS)"
destination="$appdir/opt/brainos/qt"
mkdir -p "$destination/lib" "$destination/plugins" "$destination/qml" \
  "$destination/libexec" "$destination/resources"

declare -A copied=()
copy_qt_library() {
  local library="$1" base
  [[ -e "$library" ]] || return 0
  base="$(basename "$library")"
  [[ "$base" == libQt6* || "$base" == libicu* || "$base" == libdouble-conversion* || "$base" == libpcre2-16* || "$base" == libmd4c* ]] || return 0
  [[ -n "${copied[$base]:-}" ]] && return 0
  cp -aL "$library" "$destination/lib/$base"
  copied[$base]=1
}

scan_dependencies() {
  local elf="$1" output dependency
  [[ -f "$elf" ]] || return 0
  output="$(ldd "$elf" 2>&1)" || { echo "$output" >&2; return 1; }
  if grep -q 'not found' <<<"$output"; then
    echo "Unresolved dependency while bundling $elf:" >&2
    echo "$output" >&2
    return 1
  fi
  while IFS= read -r dependency; do
    [[ -n "$dependency" ]] && copy_qt_library "$dependency"
  done < <(awk '/=> \// {print $3} /^[[:space:]]*\/.*\(0x/ {print $1}' <<<"$output")
}

scan_dependencies "$appdir/opt/brainos/bin/brainos-desktop"

# The Qt WebEngine helper is a separate ELF executable and needs its own Qt libs.
webengine_process="$(find "$qt_libexecs" "$qt_lib" -type f -name QtWebEngineProcess -print -quit 2>/dev/null || true)"
[[ -n "$webengine_process" ]] || { echo "QtWebEngineProcess was not found in the Qt installation." >&2; exit 1; }
install -m 0755 "$webengine_process" "$destination/libexec/QtWebEngineProcess"
scan_dependencies "$webengine_process"

# Stage the platform plugins and EGLFS/KMS integrations used by the compositor.
for plugin_group in platforms egldeviceintegrations imageformats iconengines \
                    platformthemes wayland-decoration-client \
                    wayland-graphics-integration-client wayland-shell-integration; do
  [[ -d "$qt_plugins/$plugin_group" ]] || continue
  cp -a "$qt_plugins/$plugin_group" "$destination/plugins/"
  while IFS= read -r plugin; do scan_dependencies "$plugin"; done \
    < <(find "$qt_plugins/$plugin_group" -type f -name '*.so*' -print | LC_ALL=C sort)
done

# BrainOS imports QtQuick.Controls, QtQuick.Layouts, QtWayland and QtWebEngine.
for module in QtCore QtQml QtQml.Models QtQuick QtQuick.2 QtQuick.Controls \
              QtQuick.Layouts QtWayland QtWebEngine; do
  [[ -d "$qt_qml/$module" ]] && cp -a "$qt_qml/$module" "$destination/qml/"
done

# WebEngine resources: Chromium ICU data, resource packs, and locale packs.
for source_root in "$qt_data" "$qt_lib" "$qt_libexecs"; do
  [[ -d "$source_root" ]] || continue
  while IFS= read -r resource; do
    cp -a "$resource" "$destination/resources/"
  done < <(find "$source_root" -type f \( -name icudtl.dat -o -name 'qtwebengine_resources*.pak' \) -print | LC_ALL=C sort)
  locales="$(find "$source_root" -type d -name qtwebengine_locales -print -quit 2>/dev/null || true)"
  if [[ -n "$locales" ]]; then
    cp -a "$locales" "$destination/resources/"
  fi
done

[[ -s "$destination/resources/icudtl.dat" ]] || { echo "icudtl.dat missing from Qt WebEngine runtime." >&2; exit 1; }
compgen -G "$destination/resources/qtwebengine_resources*.pak" >/dev/null || {
  echo "Qt WebEngine .pak resource files missing." >&2; exit 1;
}
[[ -d "$destination/resources/qtwebengine_locales" ]] || {
  echo "Qt WebEngine locale directory missing." >&2; exit 1;
}

cat > "$appdir/opt/brainos/bin/qt.conf" <<'EOF'
[Paths]
Prefix=../qt
Libraries=lib
Plugins=plugins
Qml2Imports=qml
Data=resources
EOF

echo "Bundled Qt/WebEngine-owned libraries, plugins, QML, helper and resources in $destination"
echo "Note: the target OS still supplies glibc, Mesa/DRM, NSS, fontconfig, FreeType and CA certificates."
