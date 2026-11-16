#!/usr/bin/env python3
"""Download the Ubuntu amd64 Qt/WebEngine runtime dependency closure.

On Windows, run from Windows Python with WSL Ubuntu configured.
On Linux (including GitHub Actions), pass --native and --output. In both
modes an empty dpkg status database is used so already-installed packages
are still included. Packages are downloaded, not installed into the host.
"""
from __future__ import annotations

import argparse
import os
import shlex
import subprocess
import sys
from pathlib import Path

PACKAGES = [
    "libc6", "libc-bin", "libgcc-s1", "libstdc++6",
    "qt6-qpa-plugins", "qt6-wayland", "libqt6core6t64", "libqt6dbus6t64", "libqt6gui6",
    "libqt6network6", "libqt6opengl6", "libqt6qml6", "libqt6qmlmodels6", "libqt6qmlworkerscript6",
    "libqt6quick6", "libqt6quickcontrols2-6", "libqt6quicktemplates2-6", "libqt6waylandcompositor6",
    "libqt6webchannel6",
    "libqt6webengine6-data", "libqt6webenginecore6", "libqt6webenginecore6-bin", "libqt6webenginequick6",
    "qml6-module-qtcore", "qml6-module-qtqml", "qml6-module-qtqml-models",
    "qml6-module-qtqml-workerscript", "qml6-module-qtquick", "qml6-module-qtquick-controls",
    "qml6-module-qtquick-layouts", "qml6-module-qtquick-window", "qml6-module-qtwayland-compositor",
    "qml6-module-qtwebengine", "qml6-module-qtwebengine-controlsdelegates",
    "dbus", "dbus-daemon", "dbus-bin", "dbus-session-bus-common",
    "libegl1", "libgles2", "libgl1", "libgl1-mesa-dri", "libglx-mesa0", "libdrm2", "libgbm1",
    "libwayland-client0", "libwayland-server0", "libwayland-egl1", "libwayland-cursor0",
    "libxkbcommon0", "libinput10", "libudev1", "libnss3", "libnspr4", "ca-certificates",
    "fontconfig", "libfontconfig1", "libfreetype6", "fonts-dejavu-core", "util-linux",
]


def make_command(output: Path, use_sudo: bool) -> str:
    root = "/tmp/brainos-full-runtime-dependencies"
    cache = f"{root}/archives"
    status = f"{root}/empty-dpkg-status"
    packages = " ".join(shlex.quote(package) for package in PACKAGES)
    sudo = "sudo " if use_sudo else ""
    output_text = str(output)

    zip_code = (
        "import hashlib,os,zipfile; "
        f"root={cache!r}; out={output_text!r}; "
        "debs=sorted(os.path.join(root,n) for n in os.listdir(root) if n.endswith('.deb')); "
        "assert debs, 'apt did not download any .deb packages'; "
        "z=zipfile.ZipFile(out,'w',compression=zipfile.ZIP_STORED); "
        "lines=['BrainOS Qt runtime bundle','Target: Ubuntu amd64','']; "
        "[lines.append(hashlib.sha256(open(p,'rb').read()).hexdigest()+'  '+os.path.basename(p)) for p in debs]; "
        "z.writestr('MANIFEST.sha256',chr(10).join(lines)+chr(10)); "
        "[z.write(p,os.path.basename(p)) for p in debs]; z.close(); "
        "print('Created',out,'with',len(debs),'packages')"
    )

    command = f"set -eu; {sudo}apt-get update; "
    command += 'ICU_PACKAGE="$(apt-cache pkgnames | grep -E "^libicu[0-9]+$" | sort -V | tail -n 1)"; '
    command += '[ -n "$ICU_PACKAGE" ] || { echo "No versioned ICU runtime package is available." >&2; exit 1; }; '
    command += f"{sudo}rm -rf {shlex.quote(root)}; mkdir -p {shlex.quote(cache + '/partial')}; "
    command += f": > {shlex.quote(status)}; chmod 644 {shlex.quote(status)}; "
    command += f"mkdir -p {shlex.quote(str(output.parent))}; "
    command += (
        f"{sudo}apt-get "
        f"-o Dir::State::status={shlex.quote(status)} "
        f"-o Dir::Cache::archives={shlex.quote(cache + '/') } "
        f"-o Dir::Cache::pkgcache={shlex.quote(root + '/pkgcache.bin')} "
        f"-o Dir::Cache::srcpkgcache={shlex.quote(root + '/srcpkgcache.bin')} "
        "-o Debug::NoLocking=1 --download-only --yes --no-install-recommends install "
        + packages + ' "$ICU_PACKAGE"; '
    )
    command += (
        f"{sudo}chown -R $(id -u):$(id -g) {shlex.quote(root)}; "
        "python3 -c " + shlex.quote(zip_code)
    )
    return command


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--native", action="store_true",
                        help="run apt directly on Linux instead of invoking WSL")
    parser.add_argument("--output", type=Path,
                        help="output ZIP path (required with --native)")
    args = parser.parse_args()

    if os.name == "nt":
        if args.native:
            parser.error("--native is only available on Linux")
        user = Path.home().name
        output = Path(f"/mnt/c/Users/{user}/Downloads/brainos-runtime-dependencies-full.zip")
        command = make_command(output, use_sudo=True)
        runner = ["wsl.exe", "--", "bash", "-lc", command]
        print("Downloading through WSL Ubuntu; packages are not installed into WSL.")
        print("Output:", Path.home() / "Downloads" / output.name)
    elif os.name == "posix" and args.native:
        if not args.output:
            parser.error("--output is required with --native")
        output = args.output.expanduser().resolve()
        command = make_command(output, use_sudo=os.geteuid() != 0)
        runner = ["bash", "-lc", command]
        print("Downloading through native apt; packages are not installed into the build host.")
        print("Output:", output)
    else:
        parser.error("Use Windows Python + WSL, or Linux with --native --output <file.zip>")

    try:
        result = subprocess.run(runner, check=False)
    except OSError as exc:
        print(f"Could not start the package download command: {exc}", file=sys.stderr)
        return 1
    if result.returncode:
        print(f"Runtime dependency download failed with exit code {result.returncode}.", file=sys.stderr)
        return result.returncode
    print("Done. Verify the ZIP before using it in the rootfs merger.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
