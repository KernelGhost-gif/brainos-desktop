#!/usr/bin/env python3
"""Restore executable bits omitted from the pinned SZH Git rootfs snapshot.

The snapshot tracks several ELF command binaries and init scripts with mode
100644. That is sufficient for Git blob storage but not for executing PID 1,
Toybox applets, or the rcS init script from an initramfs.
"""
from __future__ import annotations

import argparse
import os
import stat
from pathlib import Path

ELF_MAGIC = b"\x7fELF"
COMMAND_DIRS = ("bin", "sbin", "usr/bin", "usr/sbin")
SCRIPT_DIRS = ("etc/init.d", "etc/rc.d")
ENTRYPOINTS = (
    "bin/toybox",
    "bin/sh",
    "bin/su",
    "sbin/init",
    "etc/init.d/rcS",
)


def has_executable_format(path: Path) -> bool:
    try:
        with path.open("rb") as stream:
            header = stream.read(4)
    except OSError:
        return False
    return header == ELF_MAGIC or header.startswith(b"#!")


def make_executable(path: Path) -> bool:
    try:
        metadata = path.stat()
    except FileNotFoundError:
        return False
    if not stat.S_ISREG(metadata.st_mode) or not has_executable_format(path):
        return False
    permissions = stat.S_IMODE(metadata.st_mode)
    if permissions & 0o111:
        return False
    path.chmod(permissions | 0o111)
    print(f"[rootfs-mode] +x {path}")
    return True


def restore(root: Path) -> int:
    root = root.resolve()
    changed = 0

    # Commands are stored directly in these standard executable directories.
    # Do not chmod shared libraries or data elsewhere in the root filesystem.
    for directory in COMMAND_DIRS:
        folder = root / directory
        if not folder.is_dir():
            continue
        for path in sorted(folder.iterdir()):
            if path.is_symlink() or not path.is_file():
                continue
            changed += int(make_executable(path))

    # Init scripts are invoked directly by Toybox init.
    for directory in SCRIPT_DIRS:
        folder = root / directory
        if not folder.is_dir():
            continue
        for path in sorted(folder.iterdir()):
            if path.is_symlink() or not path.is_file():
                continue
            changed += int(make_executable(path))

    # Fail closed if any required PID 1/CLI entrypoint is missing or remains
    # non-executable after automatic format detection.
    for relative in ENTRYPOINTS:
        path = root / relative
        if not path.exists() or not path.is_file():
            raise FileNotFoundError(f"required init/CLI executable is missing: {path}")
        if not os.access(path, os.X_OK):
            if not make_executable(path) or not os.access(path, os.X_OK):
                raise PermissionError(f"required init/CLI executable cannot be made executable: {path}")

    print(f"[rootfs-mode] Restored executable bits on {changed} ELF/script files.")
    return changed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("rootfs", type=Path, help="target root filesystem to normalize")
    args = parser.parse_args()
    try:
        restore(args.rootfs)
    except (OSError, FileNotFoundError, PermissionError) as exc:
        parser.error(str(exc))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
