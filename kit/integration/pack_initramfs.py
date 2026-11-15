#!/usr/bin/env python3
"""Create a deterministic gzip-compressed cpio newc initramfs.

Usage: pack_initramfs.py ROOTFS OUTPUT.cpio.gz
SOURCE_DATE_EPOCH defaults to 0. Ownership, timestamps, inode allocation,
entry order and gzip metadata are normalized to make repeated builds identical.
"""
from __future__ import annotations
import gzip
import os
import stat
import sys
from pathlib import Path
from typing import BinaryIO

SPECIAL = {
    "dev/console": (stat.S_IFCHR | 0o600, 5, 1),
    "dev/null": (stat.S_IFCHR | 0o666, 1, 3),
    "dev/tty": (stat.S_IFCHR | 0o666, 5, 0),
    "dev/tty0": (stat.S_IFCHR | 0o620, 4, 0),
    "dev/ttyS0": (stat.S_IFCHR | 0o620, 4, 64),
}

def pad4(stream: BinaryIO, length: int) -> None:
    stream.write(b"\0" * ((-length) % 4))

def header(stream: BinaryIO, fields: list[int]) -> None:
    if len(fields) != 13: raise ValueError("newc requires 13 header fields")
    stream.write(b"070701" + "".join(f"{v & 0xffffffff:08x}" for v in fields).encode("ascii"))

def entry(stream: BinaryIO, ino: int, name: str, mode: int, mtime: int, nlink: int,
          data: bytes = b"", rmajor: int = 0, rminor: int = 0, uid: int = 0, gid: int = 0) -> None:
    encoded = name.encode("utf-8", "surrogateescape") + b"\0"
    fields = [ino, mode, uid, gid, nlink, mtime, len(data), 0, 0, rmajor, rminor, len(encoded), 0]
    header(stream, fields); stream.write(encoded); pad4(stream, 110 + len(encoded))
    if data: stream.write(data)
    pad4(stream, len(data))

def collect(root: Path) -> dict[str, Path | None]:
    result: dict[str, Path | None] = {".": root}
    for current, dirs, files in os.walk(root, topdown=True, followlinks=False):
        dirs.sort(); files.sort(); base = Path(current)
        for name in list(dirs):
            p = base / name; rel = p.relative_to(root).as_posix(); result[rel] = p
            if p.is_symlink(): dirs.remove(name)
        for name in files:
            p = base / name; result[p.relative_to(root).as_posix()] = p
    for name in SPECIAL: result.setdefault(name, None)
    return result

def archive(root: Path, output: Path, epoch: int) -> int:
    entries = collect(root); output.parent.mkdir(parents=True, exist_ok=True)
    temp = output.with_name(output.name + ".tmp"); inode = 1; count = 0
    try:
        with temp.open("wb") as raw:
            with gzip.GzipFile(filename="", mode="wb", compresslevel=9, fileobj=raw, mtime=0) as gz:
                for name in sorted(entries, key=lambda x: x.encode("utf-8", "surrogateescape")):
                    path = entries[name]; uid = gid = 0; major = minor = 0; data = b""
                    if name in SPECIAL:
                        mode, major, minor = SPECIAL[name]; nlink = 1
                    elif path is not None:
                        meta = os.lstat(path); mode = meta.st_mode
                        nlink = 2 if stat.S_ISDIR(mode) else 1
                        if stat.S_ISLNK(mode): data = os.readlink(path).encode("utf-8", "surrogateescape")
                        elif stat.S_ISCHR(mode) or stat.S_ISBLK(mode): major, minor = os.major(meta.st_rdev), os.minor(meta.st_rdev)
                    else: continue
                    if name == "home/brainos" or name.startswith("home/brainos/") or name == "run/user/1000" or name.startswith("run/user/1000/"): uid = gid = 1000
                    if name == "etc/shadow": mode = stat.S_IFREG | 0o600
                    if name in {"sbin/brainos-launch", "opt/brainos/bin/brainos-session", "opt/brainos/bin/brainos-desktop"}: mode = stat.S_IFREG | 0o755
                    if path is not None and stat.S_ISREG(mode):
                        encoded = name.encode("utf-8", "surrogateescape") + b"\0"
                        size = os.lstat(path).st_size
                        header(gz, [inode, mode, uid, gid, nlink, epoch, size, 0, 0, 0, 0, len(encoded), 0])
                        gz.write(encoded); pad4(gz, 110 + len(encoded))
                        with path.open("rb") as source:
                            while block := source.read(1024 * 1024): gz.write(block)
                        pad4(gz, size)
                    else: entry(gz, inode, name, mode, epoch, nlink, data, major, minor, uid, gid)
                    inode += 1; count += 1
                entry(gz, inode, "TRAILER!!!", 0, epoch, 1)
        os.replace(temp, output)
    except BaseException:
        temp.unlink(missing_ok=True); raise
    print(f"Wrote {output} ({output.stat().st_size} bytes compressed; {count} entries; SOURCE_DATE_EPOCH={epoch}).")
    return count

def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__, file=sys.stderr); return 2
    root, output = Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve()
    if not root.is_dir(): raise SystemExit(f"Rootfs directory does not exist: {root}")
    try: epoch = int(os.environ.get("SOURCE_DATE_EPOCH", "0"))
    except ValueError as exc: raise SystemExit("SOURCE_DATE_EPOCH must be an integer") from exc
    if not 0 <= epoch <= 0xffffffff: raise SystemExit("SOURCE_DATE_EPOCH must fit a 32-bit newc mtime")
    if output == root or root in output.parents: raise SystemExit("Output archive must be outside rootfs")
    archive(root, output, epoch); return 0

if __name__ == "__main__": raise SystemExit(main())
