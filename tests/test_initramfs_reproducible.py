#!/usr/bin/env python3
"""Regression test for source-tree timestamp/ownership independence."""
from __future__ import annotations
import gzip, hashlib, os, random, subprocess, sys, tempfile, time
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
PACKER = ROOT / "kit/integration/pack_initramfs.py"
def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""): digest.update(chunk)
    return digest.hexdigest()
def cpio_entries(path: Path) -> list[tuple[str, int, int, int]]:
    data = gzip.decompress(path.read_bytes()); offset = 0; entries = []
    while offset < len(data):
        header = data[offset:offset+110]
        if len(header) != 110 or header[:6] != b"070701": raise AssertionError(f"invalid newc header at byte {offset}")
        fields = [int(header[6+i*8:14+i*8],16) for i in range(13)]
        mode,uid,gid,mtime,filesize,namesize=fields[1],fields[2],fields[3],fields[5],fields[6],fields[11]
        name_start=offset+110; raw_name=data[name_start:name_start+namesize]; name=raw_name[:-1].decode("utf-8","surrogateescape")
        data_start=(name_start+namesize+3)&~3; data_end=data_start+filesize; offset=(data_end+3)&~3
        entries.append((name,mtime,uid,gid))
        if name=="TRAILER!!!": break
    return entries
def run_packer(root: Path, out: Path) -> None:
    env=dict(os.environ,SOURCE_DATE_EPOCH="0",LC_ALL="C")
    subprocess.run([sys.executable,str(PACKER),str(root),str(out)],check=True,env=env)
def main() -> None:
    with tempfile.TemporaryDirectory(prefix="brainos-initramfs-test-") as temp:
        workspace=Path(temp); rootfs=workspace/"rootfs"
        (rootfs/"bin").mkdir(parents=True); (rootfs/"etc/init.d").mkdir(parents=True); (rootfs/"home/brainos").mkdir(parents=True); (rootfs/"dev").mkdir()
        (rootfs/"bin/toybox").write_bytes(b"toybox-test-payload\n"); (rootfs/"bin/toybox").chmod(0o755); (rootfs/"bin/sh").symlink_to("toybox")
        (rootfs/"etc/init.d/rcS").write_text("#!/bin/sh\necho init\n"); (rootfs/"etc/init.d/rcS").chmod(0o755)
        (rootfs/"home/brainos/notes.txt").write_text("persistent-looking fixture\n"); (rootfs/"dev/null").write_text("placeholder must become a device node in newc\n")
        image_a=workspace/"A.cpio.gz"; image_b=workspace/"B.cpio.gz"; run_packer(rootfs,image_a); hash_a=sha256(image_a)
        rng=random.Random(20261113); now=int(time.time())
        for current,directories,files in os.walk(rootfs,topdown=False,followlinks=False):
            for name in directories+files:
                path=Path(current)/name; stamp=now-rng.randrange(1,10_000_000)
                try: os.utime(path,(stamp,stamp),follow_symlinks=False)
                except (NotImplementedError,PermissionError): pass
            stamp=now-rng.randrange(1,10_000_000); os.utime(current,(stamp,stamp),follow_symlinks=False)
        run_packer(rootfs,image_b); hash_b=sha256(image_b)
        if hash_a!=hash_b: raise SystemExit(f"timestamp determinism failed: A={hash_a} B={hash_b}")
        entries=cpio_entries(image_b)
        if not entries or entries[-1][0]!="TRAILER!!!": raise AssertionError("missing cpio trailer")
        bad=[name for name,mtime,_,_ in entries if mtime!=0]
        if bad: raise AssertionError(f"non-normalized cpio mtimes: {bad[:5]}")
        by_name={entry[0]:entry for entry in entries}
        if "dev/null" not in by_name: raise AssertionError("/dev/null entry missing")
        print(f"SHA256(A) {hash_a}"); print(f"SHA256(B) {hash_b}"); print(f"MATCH yes; entries={len(entries)}; all_mtime=0; output-size={image_a.stat().st_size}")
if __name__=="__main__": main()
