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

    def test_build_hosts_install_all_required_qml_runtime_modules(self):
        required = (
            "qml6-module-qtcore",
            "qml6-module-qtqml",
            "qml6-module-qtqml-models",
            "qml6-module-qtqml-workerscript",
            "qml6-module-qtquick",
            "qml6-module-qtquick-controls",
            "qml6-module-qtquick-templates",
            "qml6-module-qtquick-layouts",
            "qml6-module-qtquick-window",
            "qml6-module-qtwebengine",
            "qml6-module-qtwebengine-controlsdelegates",
        )
        for path in (".github/workflows/ci.yml",
                     ".github/workflows/release.yml",
                     "kit/brainos-qt/packaging/README.md"):
            source = self.read(path)
            for package in required:
                with self.subTest(path=path, package=package):
                    self.assertIn(package, source)

    def test_qml_resource_prefix_matches_the_runtime_engine_url(self):
        cmake = self.read("kit/brainos-qt/CMakeLists.txt")
        main = self.read("kit/brainos-qt/src/main.cpp")
        self.assertIn('RESOURCE_PREFIX "/qt/qml"', cmake)
        self.assertIn('engine.addImportPath(QStringLiteral("qrc:/qt/qml"));', main)
        self.assertIn('qrc:/qt/qml/BrainOS/qml/Compositor.qml', main)
        self.assertIn("screenshot.isNull()", main)
        self.assertIn("screenshot.save(screenshotPath)", main)

    def test_desktop_surface_imports_controls_for_scrollbar(self):
        source = self.read("kit/brainos-qt/qml/desktop/DesktopSurface.qml")
        self.assertIn("import QtQuick.Controls", source)
        self.assertIn("ScrollBar.vertical: ScrollBar", source)

    def test_qml_runtime_bundle_preserves_the_actual_nested_module_layout(self):
        bundler = self.read("kit/brainos-qt/packaging/scripts/bundle-qt-runtime.sh")
        self.assertIn('cp -a "$qt_qml/." "$destination/qml/"', bundler)
        for module in ("QtQuick/Controls", "QtQuick/Templates", "QtQuick/Layouts", "QtQuick/Window",
                       "QtQml/WorkerScript", "QtWayland/Compositor/XdgShell", "QtWebEngine"):
            self.assertIn(module, bundler)

    def test_certificate_bundle_is_generated_after_deb_extraction(self):
        merger = self.read("kit/integration/merge-into-toybox.sh")
        downloader = self.read("kit/integration/download_brainos_runtime_dependencies.py")
        self.assertIn('build_ca_bundle.py" "$ROOTFS"', merger)
        self.assertIn('"ca-certificates"', downloader)
        self.assertIn("ca-certificates.conf", self.read("kit/integration/build_ca_bundle.py"))
        for path in ("kit/integration/verify-runtime.sh", "scripts/verify-runtime.sh"):
            self.assertIn("ca-certificates.crt", self.read(path))

    def test_qemu_screenshot_gate_rejects_blank_or_invalid_images(self):
        qemu = self.read("scripts/qemu-smoke-test.sh")
        self.assertIn("ImageStat.Stat(image).stddev", qemu)
        self.assertIn("QEMU desktop screenshot is effectively blank", qemu)

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
            "kit/integration/verify-runtime.sh",
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
        self.assertIn("bsdutils", merger)
        downloader = self.read("kit/integration/download_brainos_runtime_dependencies.py")
        self.assertIn('"bsdutils"', downloader)
        self.assertIn('"qml6-module-qtquick-templates"', downloader)
        self.assertIn("qml6-module-qtquick-templates", merger)
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

    def test_runtime_downloader_uses_ubuntu_noble_available_package_names(self):
        downloader = self.read("kit/integration/download_brainos_runtime_dependencies.py")
        for unavailable in ("libqt6waylandcompositorxdgshell6",
                            "libqt6webchannelquick6", "qml6-module-qtnetwork"):
            self.assertNotIn(unavailable, downloader)

    def test_qt_base_runtime_uses_ubuntu_noble_t64_packages(self):
        downloader = self.read("kit/integration/download_brainos_runtime_dependencies.py")
        merger = self.read("kit/integration/merge-into-toybox.sh")
        for package in ("libqt6dbus6t64", "libqt6gui6t64",
                        "libqt6network6t64", "libqt6opengl6t64"):
            self.assertIn(package, downloader)
        self.assertIn("libqt6gui6t64", merger)
        for obsolete in ("libqt6dbus6", "libqt6gui6", "libqt6network6", "libqt6opengl6"):
            self.assertNotIn('"' + obsolete + '"', downloader)

    def test_qt_dbus_runtime_uses_ubuntu_noble_t64_package(self):
        downloader = self.read("kit/integration/download_brainos_runtime_dependencies.py")
        merger = self.read("kit/integration/merge-into-toybox.sh")
        self.assertIn("libqt6dbus6t64", downloader)
        self.assertIn("libqt6dbus6t64", merger)
        self.assertNotIn('"libqt6core6t64", "libqt6dbus6",', downloader)

    def test_native_runtime_dependency_download_mode_exists(self):
        downloader = self.read("kit/integration/download_brainos_runtime_dependencies.py")
        self.assertIn('parser.add_argument("--native"', downloader)
        self.assertIn('parser.add_argument("--output"', downloader)
        self.assertIn('runner = ["bash", "-lc", command]', downloader)

    def test_ubuntu_noble_mesa_gallium_payload_is_bundled_and_verified(self):
        downloader = self.read("kit/integration/download_brainos_runtime_dependencies.py")
        merger = self.read("kit/integration/merge-into-toybox.sh")
        iso_packages = self.read("kit/brainos-qt/packaging/live-build/brainos.list.chroot")
        self.assertIn("mesa-libgallium", downloader)
        self.assertIn("mesa-libgallium", merger)
        self.assertIn("mesa-libgallium", iso_packages)
        for path in ("kit/integration/verify-runtime.sh", "scripts/verify-runtime.sh"):
            verifier = self.read(path)
            self.assertIn('find -L "$ROOTFS" -type f', verifier)
            self.assertIn("Mesa DRI candidates and symlink targets", verifier)
            self.assertIn("kms_swrast_dri.so", verifier)

    def test_glibc_interpreter_uses_ubuntu_noble_libc_layout(self):
        merger = self.read("kit/integration/merge-into-toybox.sh")
        self.assertIn('$TMP/stage/usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2', merger)
        self.assertIn('../usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2', merger)
        self.assertIn('[[ -e "$ROOTFS/lib64/ld-linux-x86-64.so.2" ]]', merger)

    def test_merger_adds_missing_toybox_id_applet_link(self):
        merger = self.read("kit/integration/merge-into-toybox.sh")
        self.assertIn('ln -s toybox "$ROOTFS/bin/id"', merger)
        self.assertIn('"$ROOTFS/bin/id"', merger)
        self.assertIn('"$ROOTFS/bin/toybox"', merger)

    def test_release_workflow_builds_all_readme_artifacts(self):
        workflow = self.read(".github/workflows/release.yml")
        for marker in ("build-release.sh", "download_brainos_runtime_dependencies.py",
                       "merge-into-toybox.sh", "build-kernel.sh", "build-initramfs.sh",
                       "qemu-smoke-test.sh", "build-iso.sh", "softprops/action-gh-release@v2"):
            self.assertIn(marker, workflow)
        self.assertNotIn("\\${", workflow)

    def test_kernel_build_uses_repo_owned_config_updater(self):
        script = self.read("scripts/build-kernel.sh")
        updater = self.read("scripts/update_kernel_config.py")
        self.assertIn('CONFIG_UPDATER="$ROOT/scripts/update_kernel_config.py"', script)
        self.assertIn('config_tool() { python3 "$CONFIG_UPDATER" --file "$BUILD_DIR/.config" "$@"; }', script)
        self.assertIn("config_tool --enable", script)
        self.assertIn("os.replace(", updater)
        self.assertNotIn('KERNEL_SRC/scripts/config', script)

    def test_kernel_build_restores_executable_bits_for_flattened_shell_helpers(self):
        script = self.read("scripts/build-kernel.sh")
        self.assertIn("Kbuild executes shell helpers and extensionless scripts/mkcompile_h directly", script)
        self.assertIn("find \"$KERNEL_SRC\" -type f", script)
        self.assertIn("-name '*.sh' -o -name 'setlocalversion' -o -name 'mkcompile_h'", script)
        self.assertIn("-exec chmod u+x {} +", script)
        backslash = chr(92)
        expected = (
            'find "$KERNEL_SRC" -type f ' + backslash + "\n"
            + "  " + backslash + "( -name '*.sh' -o -name 'setlocalversion' -o -name 'mkcompile_h' "
            + backslash + ") " + backslash + "\n"
            + "  -exec chmod u+x {} +"
        )
        self.assertIn(expected, script)

    def test_kernel_out_of_tree_build_stashes_and_restores_source_generated_files(self):
        script = self.read("scripts/build-kernel.sh")
        self.assertIn('SOURCE_STASH="$(mktemp -d "$BUILD_DIR/.kernel-source-stash.XXXXXX")"', script)
        self.assertIn("trap restore_kernel_source EXIT", script)
        for path in (".config", "include/config", "arch/x86/include/generated"):
            self.assertIn(f"stash_source_path {path}", script)
        self.assertIn('mv "$SOURCE_STASH/$path" "$KERNEL_SRC/$path"', script)
        self.assertNotIn("mrproper", script.splitlines()[-1])

    def test_iso_builder_reuses_prebuilt_runtime_stage(self):
        script = self.read("kit/brainos-qt/packaging/build-iso.sh")
        self.assertIn("BRAINOS_PREBUILT_STAGE", script)
        self.assertIn("Reusing the verified BrainOS runtime stage", script)
    def test_live_iso_builder_exists_and_is_syntax_checked_by_ci(self):
        script = ROOT / "kit/brainos-qt/packaging/build-iso.sh"
        self.assertTrue(script.is_file())
        self.assertIn("lb config", script.read_text(encoding="utf-8"))
        workflow = self.read(".github/workflows/ci.yml")
        self.assertIn("packaging/build-iso.sh", workflow)
        self.assertNotIn(r"\\${", script.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
