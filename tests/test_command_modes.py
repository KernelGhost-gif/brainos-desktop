from pathlib import Path
import tempfile
import unittest

from restore_command_modes import restore


ELF = b"\x7fELF" + b"test executable payload"
SCRIPT = b"#!/bin/sh\necho init\n"


class RestoreCommandModesTests(unittest.TestCase):
    def test_restores_elf_and_shebang_files_but_not_data(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for relative in ("bin", "sbin", "usr/bin", "usr/sbin", "etc/init.d", "share"):
                (root / relative).mkdir(parents=True, exist_ok=True)

            for relative in (
                "bin/toybox", "bin/su", "sbin/init", "usr/bin/script"
            ):
                path = root / relative
                path.write_bytes(ELF)
                path.chmod(0o644)

            shell = root / "bin/sh"
            shell.write_bytes(ELF)
            shell.chmod(0o644)
            (root / "bin/id").symlink_to("toybox")

            rc = root / "etc/init.d/rcS"
            rc.write_bytes(SCRIPT)
            rc.chmod(0o644)

            data = root / "usr/bin/mime.types"
            data.write_text("text/plain\n", encoding="utf-8")
            data.chmod(0o644)
            external = root / "share/tool"
            external.parent.mkdir(exist_ok=True)
            external.write_bytes(ELF)
            external.chmod(0o644)

            changed = restore(root)

            self.assertEqual(changed, 6)
            for relative in (
                "bin/toybox", "bin/sh", "bin/su", "sbin/init",
                "usr/bin/script", "etc/init.d/rcS"
            ):
                self.assertEqual((root / relative).stat().st_mode & 0o111, 0o111)
            self.assertEqual(data.stat().st_mode & 0o111, 0)
            self.assertEqual(external.stat().st_mode & 0o111, 0)
            self.assertTrue((root / "bin/id").is_symlink())

    def test_missing_required_entrypoint_fails_closed(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for relative in ("bin", "sbin", "etc/init.d"):
                (root / relative).mkdir(parents=True, exist_ok=True)
            (root / "bin/toybox").write_bytes(ELF)
            (root / "bin/sh").write_bytes(ELF)
            (root / "bin/su").write_bytes(ELF)
            (root / "sbin/init").write_bytes(ELF)
            (root / "etc/init.d/rcS").write_bytes(SCRIPT)
            restore(root)
            (root / "sbin/init").unlink()
            with self.assertRaises(FileNotFoundError):
                restore(root)


if __name__ == "__main__":
    unittest.main(verbosity=2)
