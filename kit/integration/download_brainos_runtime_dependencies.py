#!/usr/bin/env python3
"""Download a complete Ubuntu amd64 Qt/WebEngine runtime dependency bundle through WSL apt.

Run with Windows Python. The resolver receives an empty dpkg status database,
so packages already installed in WSL are included without installing anything.
"""
from __future__ import annotations

import os
import shlex
import subprocess
import sys
from pathlib import Path

PACKAGES = [
    "libc6", "libc-bin", "libgcc-s1", "libstdc++6",
    "qt6-qpa-plugins", "qt6-wayland", "libqt6core6t64", "libqt6dbus6", "libqt6gui6",
    "libqt6network6", "libqt6opengl6", "libqt6qml6", "libqt6qmlmodels6", "libqt6qmlworkerscript6",
    "libqt6quick6", "libqt6quickcontrols2-6", "libqt6quicktemplates2-6", "libqt6waylandcompositor6",
    "libqt6waylandcompositorxdgshell6", "libqt6webchannel6", "libqt6webchannelquick6",
    "libqt6webengine6-data", "libqt6webenginecore6", "libqt6webenginecore6-bin", "libqt6webenginequick6",
    "qml6-module-qtcore", "qml6-module-qtnetwork", "qml6-module-qtqml", "qml6-module-qtqml-models",
    "qml6-module-qtqml-workerscript", "qml6-module-qtquick", "qml6-module-qtquick-controls",
    "qml6-module-qtquick-layouts", "qml6-module-qtquick-window", "qml6-module-qtwayland-compositor",
    "qml6-module-qtwebengine", "qml6-module-qtwebengine-controlsdelegates",
    "dbus", "dbus-daemon", "dbus-bin", "dbus-session-bus-common",
    "libegl1", "libgles2", "libgl1", "libgl1-mesa-dri", "libglx-mesa0", "libdrm2", "libgbm1",
    "libwayland-client0", "libwayland-server0", "libwayland-egl1", "libwayland-cursor0",
    "libxkbcommon0", "libinput10", "libudev1", "libnss3", "libnspr4", "ca-certificates",
    "fontconfig", "libfontconfig1", "libfreetype6", "fonts-dejavu-core",
]


def main() -> int:
    if os.name != "nt":
        print("Run this script with Windows Python so the ZIP lands in Windows Downloads.")
        return 2

    user = Path.home().name
    output = f"/mnt/c/Users/{user}/Downloads/brainos-runtime-dependencies-full.zip"
    root = "/tmp/brainos-full-runtime-dependencies"
    cache = f"{root}/archives"
    status = f"{root}/empty-dpkg-status"
    packages = " ".join(shlex.quote(package) for package in PACKAGES)

    zip_code = (
        "import hashlib,os,zipfile; "
        f"root={cache!r}; out={output!r}; "
        "debs=sorted(os.path.join(root,n) for n in os.listdir(root) if n.endswith('.deb')); "
        "assert debs, 'apt did not download any .deb packages'; "
        "z=zipfile.ZipFile(out,'w',compression=zipfile.ZIP_STORED); "
        "lines=['BrainOS Qt runtime bundle','Target: Ubuntu amd64','']; "
        "[lines.append(hashlib.sha256(open(p,'rb').read()).hexdigest()+'  '+os.path.basename(p)) for p in debs]; "
        "z.writestr('MANIFEST.sha256',chr(10).join(lines)+chr(10)); "
        "[z.write(p,os.path.basename(p)) for p in debs]; z.close(); "
        "print('Created',out,'with',len(debs),'packages')"
    )

    command = "set -eu; sudo apt-get update; "
    command += 'ICU_PACKAGE=$(apt-cache pkgnames | grep -E "^libicu[0-9]+$" | sort -V | tail -n 1); '
    command += '[ -n "$ICU_PACKAGE" ] || { echo "No versioned ICU runtime package is available." >&2; exit 1; }; '
    command += f"sudo rm -rf {shlex.quote(root)}; mkdir -p {shlex.quote(cache + '/partial')}; "
    command += f": > {shlex.quote(status)}; chmod 644 {shlex.quote(status)}; "
    command += (
        "sudo apt-get "
        f"-o Dir::State::status={shlex.quote(status)} "
        f"-o Dir::Cache::archives={shlex.quote(cache + '/')} "
        f"-o Dir::Cache::pkgcache={shlex.quote(root + '/pkgcache.bin')} "
        f"-o Dir::Cache::srcpkgcache={shlex.quote(root + '/srcpkgcache.bin')} "
        "-o Debug::NoLocking=1 --download-only --yes --no-install-recommends install "
        + packages + ' "$ICU_PACKAGE"; '
    )
    command += (
        f"sudo chown -R $(id -u):$(id -g) {shlex.quote(root)}; "
        "python3 -c " + shlex.quote(zip_code)
    )

    print("Downloading a runtime dependency closure only; packages are not installed into WSL.")
    print("Output:", Path.home() / "Downloads" / "brainos-runtime-dependencies-full.zip")
    try:
        result = subprocess.run(["wsl.exe", "--", "bash", "-lc", command], check=False)
    except OSError as exc:
        print(f"Could not start WSL: {exc}", file=sys.stderr)
        return 1

    if result.returncode:
        print(f"WSL download failed with exit code {result.returncode}.", file=sys.stderr)
        return result.returncode

    print("Done. Verify the ZIP before using it in the rootfs merger.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
