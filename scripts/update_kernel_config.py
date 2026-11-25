#!/usr/bin/env python3
"""Safely update Linux Kconfig assignments in an existing .config file."""
from __future__ import annotations

import argparse
import os
import re
import stat
import tempfile
from pathlib import Path


def update_config(config_path: Path, action: str, symbol: str) -> None:
    if action not in {"--enable", "--module", "--disable"}:
        raise ValueError(f"unsupported config action: {action}")
    if not re.fullmatch(r"[A-Z0-9_]+", symbol):
        raise ValueError(f"invalid Kconfig symbol: {symbol!r}")

    config_path = config_path.expanduser().resolve()
    if not config_path.is_file():
        raise FileNotFoundError(f"kernel config file does not exist: {config_path}")

    original = config_path.read_text(encoding="utf-8")
    lines = original.splitlines()
    assignment = re.compile(
        rf"^(?:CONFIG_{re.escape(symbol)}=.*|# CONFIG_{re.escape(symbol)} is not set)$"
    )
    if action == "--enable":
        replacement = f"CONFIG_{symbol}=y"
    elif action == "--module":
        replacement = f"CONFIG_{symbol}=m"
    else:
        replacement = f"# CONFIG_{symbol} is not set"

    updated: list[str] = []
    inserted = False
    for line in lines:
        if assignment.fullmatch(line):
            if not inserted:
                updated.append(replacement)
                inserted = True
            continue
        updated.append(line)
    if not inserted:
        updated.append(replacement)

    content = "\n".join(updated) + "\n"
    old_mode = stat.S_IMODE(config_path.stat().st_mode)
    fd, temporary_name = tempfile.mkstemp(
        prefix=f".{config_path.name}.", suffix=".tmp", dir=config_path.parent
    )
    temporary = Path(temporary_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        temporary.chmod(old_mode)
        os.replace(temporary, config_path)
    finally:
        try:
            temporary.unlink()
        except FileNotFoundError:
            pass


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--file", required=True, type=Path, help="Kconfig .config file")
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--enable", action="store_const", const="--enable", dest="action")
    action.add_argument("--module", action="store_const", const="--module", dest="action")
    action.add_argument("--disable", action="store_const", const="--disable", dest="action")
    parser.add_argument("symbol", help="Kconfig symbol without the CONFIG_ prefix")
    args = parser.parse_args()
    try:
        update_config(args.file, args.action, args.symbol)
    except (OSError, ValueError) as exc:
        parser.error(str(exc))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
