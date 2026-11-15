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

    def test_qml_plugin_dependencies_are_included_in_release_closure(self):
        bundler = self.read("kit/brainos-qt/packaging/scripts/bundle-qt-runtime.sh")
        self.assertIn("QML import plugins are loaded lazily", bundler)
        self.assertIn('find "$destination/qml" -type f', bundler)
        self.assertIn('scan_dependencies "$plugin"', bundler)

    def test_archive_verification_uses_portable_find_expression(self):
        workflow = self.read(".github/workflows/ci.yml")
        self.assertIn('find "$runtime/qt/qml" -type f -name \'*.so\' -print -quit | grep -q .', workflow)
        self.assertNotIn('\\\\( -name', workflow)

    def test_ci_builds_verifies_and_uploads_release_runtime(self):
        workflow = self.read(".github/workflows/ci.yml")
        self.assertIn("packaging/build-release.sh", workflow)
        self.assertIn("QtWebEngineProcess", workflow)
        self.assertIn("sha256sum --check", workflow)
        self.assertIn("actions/upload-artifact@v4", workflow)

    def test_release_packaging_scripts_are_executable(self):
        for relative in (
            "kit/brainos-qt/packaging/build-release.sh",
            "kit/brainos-qt/packaging/scripts/bundle-qt-runtime.sh",
            "kit/brainos-qt/packaging/scripts/bundle-szh-terminal.sh",
        ):
            with self.subTest(script=relative):
                script = ROOT / relative
                self.assertTrue(script.stat().st_mode & 0o111, f"{relative} must be executable")

    def test_ubuntu_system_icu_layout_is_supported(self):
        bundler = self.read("kit/brainos-qt/packaging/scripts/bundle-qt-runtime.sh")
        session = self.read("kit/integration/brainos-session")
        verifier = self.read("kit/integration/verify-runtime.sh")
        self.assertIn("libicudata.so.*", bundler)
        self.assertIn("/usr/share/qt6/translations/qtwebengine_locales", session)
        self.assertIn("libicudata.so.*", session)
        self.assertIn("libicudata.so.*", verifier)

    def test_release_installs_to_the_runtime_prefix(self):
        script = self.read("kit/brainos-qt/packaging/build-release.sh")
        self.assertIn("-DCMAKE_INSTALL_PREFIX=/", script)

    def test_szh_runtime_is_pinned_verified_and_uses_musl(self):
        bundler = self.read("kit/brainos-qt/packaging/scripts/bundle-szh-terminal.sh")
        self.assertIn("1037b073d4ef62029548305b6b13fcd133e3a270", bundler)
        self.assertIn("verify_git_blob", bundler)
        self.assertIn("libreadline.so.8", bundler)
        self.assertIn("libncursesw.so.6", bundler)
        self.assertIn("ld-musl-x86_64.so.1", bundler)
        self.assertIn("toybox-applet", bundler)
        self.assertIn("szh-shell", bundler)

    def test_terminal_uses_persistent_pty_and_szh_is_default(self):
        service = self.read("kit/brainos-qt/src/common/SzhTerminalService.cpp")
        header = self.read("kit/brainos-qt/src/common/SzhTerminalService.h")
        qml = self.read("kit/brainos-qt/qml/pages/TerminalPage.qml")
        self.assertIn('QStandardPaths::findExecutable(QStringLiteral("script"))', service)
        self.assertIn('QStringLiteral("-c")', service)
        self.assertIn("sendInterrupt", header)
        self.assertIn("startSzh()", qml)
        self.assertIn("szhTerminal.sendInput(raw +", qml)
        self.assertIn("szhTerminal.startHost()", qml)
        self.assertIn("Component.onDestruction: szhTerminal.stop()", qml)

    def test_szh_service_is_registered_with_qml_and_compiled(self):
        main = self.read("kit/brainos-qt/src/main.cpp")
        cmake = self.read("kit/brainos-qt/CMakeLists.txt")
        workflow = self.read(".github/workflows/ci.yml")
        self.assertIn("SzhTerminalService szhTerminal", main)
        self.assertIn("&szhTerminal", main)
        self.assertIn("SzhTerminalService.cpp", cmake)
        self.assertIn("SZH_PTY_OK", workflow)

    def test_toybox_merge_keeps_base_shell_and_adds_szh_separately(self):
        merger = self.read("kit/integration/merge-into-toybox.sh")
        bundler = self.read("kit/brainos-qt/packaging/scripts/bundle-szh-terminal.sh")
        self.assertIn('SZH_BUNDLER="$KIT_DIR/brainos-qt/packaging/scripts/bundle-szh-terminal.sh"', merger)
        self.assertIn('SZH_ROOTFS="${SZH_ROOTFS:-}"', merger)
        self.assertIn('"$ROOTFS/bin/sh"', merger)
        self.assertIn('"$ROOTFS/bin/toybox"', merger)
        self.assertIn("util-linux", merger)
        downloader = self.read("kit/integration/download_brainos_runtime_dependencies.py")
        self.assertIn("util-linux", downloader)
        self.assertIn('destination="$stage/opt/brainos/szh"', bundler)

    def test_rootfs_verifier_checks_szh_runtime_and_toybox_isolation(self):
        for path in ("kit/integration/verify-runtime.sh", "scripts/verify-runtime.sh"):
            verifier = self.read(path)
            self.assertIn('SZH_ROOTFS="$ROOTFS/opt/brainos/szh"', verifier)
            self.assertIn("SZH_ROOTFS_OK", verifier)
            self.assertIn("libreadline.so.8", verifier)
            self.assertIn("libncursesw.so.6", verifier)
            self.assertIn("/lib/ld-musl-x86_64.so.1", verifier)
        merger = self.read("kit/integration/merge-into-toybox.sh")
        self.assertIn("python3 curl sha1sum script;", merger)

    def test_terminal_output_is_scrollable_and_follows_latest_output(self):
        qml = self.read("kit/brainos-qt/qml/pages/TerminalPage.qml")
        self.assertIn("Flickable {", qml)
        self.assertIn("ScrollBar.vertical", qml)
        self.assertIn("outputScroll.contentY", qml)

    def test_live_iso_builder_exists_and_is_syntax_checked_by_ci(self):
        script = ROOT / "kit/brainos-qt/packaging/build-iso.sh"
        self.assertTrue(script.is_file())
        self.assertIn("lb config", script.read_text(encoding="utf-8"))
        workflow = self.read(".github/workflows/ci.yml")
        self.assertIn("packaging/build-iso.sh", workflow)
        self.assertNotIn(r"\\${", script.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
