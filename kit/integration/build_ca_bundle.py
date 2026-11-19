#!/usr/bin/env python3
"""Build the Debian CA trust bundle without running package post-install hooks.

The Toybox merger extracts .deb payloads with dpkg-deb -x, so ca-certificates'
postinst hook (update-ca-certificates) never runs. This reproduces the relevant
bundle-generation step deterministically from the selected package PEM files.
"""
from __future__ import annotations

import argparse
from pathlib import Path, PurePosixPath


def build_bundle(root: Path) -> int:
    root = root.resolve()
    config = root / "etc/ca-certificates.conf"
    package_certs = root / "usr/share/ca-certificates"
    local_certs = root / "usr/local/share/ca-certificates"
    if not config.is_file():
        raise FileNotFoundError(f"ca-certificates configuration is missing: {config}")
    if not package_certs.is_dir():
        raise FileNotFoundError(f"packaged CA certificate directory is missing: {package_certs}")

    selected: set[Path] = set()
    for raw_line in config.read_text(encoding="utf-8").splitlines():
        entry = raw_line.strip()
        if not entry or entry.startswith("#") or entry.startswith("!"):
            continue
        relative = PurePosixPath(entry)
        if relative.is_absolute() or ".." in relative.parts:
            raise ValueError(f"unsafe CA certificate path in configuration: {entry}")
        certificate = package_certs.joinpath(*relative.parts)
        if not certificate.is_file():
            raise FileNotFoundError(f"configured CA certificate is missing: {certificate}")
        selected.add(certificate)

    if local_certs.is_dir():
        selected.update(path for path in local_certs.rglob("*.crt") if path.is_file())
    if not selected:
        raise RuntimeError("ca-certificates configuration selected no certificates")

    chunks: list[bytes] = []
    for certificate in sorted(selected, key=lambda path: path.relative_to(root).as_posix()):
        data = certificate.read_bytes()
        if b"-----BEGIN CERTIFICATE-----" not in data or b"-----END CERTIFICATE-----" not in data:
            raise ValueError(f"CA certificate is not PEM encoded: {certificate}")
        chunks.append(data.rstrip() + b"\n")

    bundle = b"\n".join(chunks)
    if not bundle.endswith(b"\n"):
        bundle += b"\n"
    target = root / "etc/ssl/certs/ca-certificates.crt"
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = target.with_suffix(".crt.tmp")
    temporary.write_bytes(bundle)
    temporary.chmod(0o644)
    temporary.replace(target)
    return len(chunks)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("rootfs", type=Path, help="staged target root filesystem")
    args = parser.parse_args()
    try:
        count = build_bundle(args.rootfs)
    except (OSError, ValueError, RuntimeError) as exc:
        parser.error(str(exc))
    print(f"[ca-bundle] Generated target trust bundle from {count} PEM certificates.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
