from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class BrainOSReleaseContracts(unittest.TestCase):
    def read(self, relative: str) -> str:
        return (ROOT / relative).read_text(encoding="utf-8")

    def test_icu_runtime_is_not_pinned_to_one_distribution_abi(self):
        downloader = self.read("kit/integration/download_brainos_runtime_dependencies.py")
        merger = self.read("kit/integration/merge-into-toybox.sh")
        for source in (downloader, merger):
            self.assertNotIn("libicu78", source)
        self.assertIn("apt-cache pkgnames", downloader)
        self.assertIn(r"^libicu[0-9]+$", downloader)
        self.assertIn(r"^libicu[0-9]+$", merger)
        for path in ("kit/integration/verify-runtime.sh", "scripts/verify-runtime.sh"):
            self.assertIn("libicuuc.so.*", self.read(path))

    def test_installer_protects_root_and_live_media_parent_disks(self):
        installer = self.read("kit/brainos-qt/packaging/scripts/brainos-install")
        service = self.read("kit/brainos-qt/src/common/InstallerService.cpp")
        for marker in ("for target in / /run/live/medium /cdrom", "lsblk -s -nrpo PATH,TYPE", "whole physical disk"):
            self.assertIn(marker, installer)
        self.assertIn('QStringLiteral("/run/live/medium")', service)
        self.assertIn('QStringLiteral("disk")', service)
        self.assertIn("systemDisks.contains", service)

    def test_installer_handles_live_user_and_rejects_chpasswd_injection(self):
        installer = self.read("kit/brainos-qt/packaging/scripts/brainos-install")
        service = self.read("kit/brainos-qt/src/common/InstallerService.cpp")
        self.assertIn('chroot /mnt/brainos id -u "$username"', installer)
        self.assertIn('chroot /mnt/brainos usermod -a -G', installer)
        self.assertIn("$'\\n'", installer)
        self.assertIn("password.contains(QLatin1Char(':'))", service)

    def test_file_editor_saves_atomically_and_checks_size_before_open(self):
        source = self.read("kit/brainos-qt/src/common/SystemService.cpp")
        self.assertIn("#include <QSaveFile>", source)
        function = source.split("bool SystemService::writeTextFile", 1)[1].split("\n}", 1)[0]
        self.assertLess(function.index("data.size()"), function.index("QSaveFile file"))
        self.assertIn("file.commit()", function)
        self.assertIn("file.cancelWriting()", function)

    def test_live_iso_builder_exists_and_is_syntax_checked_by_ci(self):
        script = ROOT / "kit/brainos-qt/packaging/build-iso.sh"
        self.assertTrue(script.is_file())
        self.assertIn("lb config", script.read_text(encoding="utf-8"))
        workflow = self.read(".github/workflows/ci.yml")
        self.assertIn("packaging/build-iso.sh", workflow)


if __name__ == "__main__":
    unittest.main(verbosity=2)
