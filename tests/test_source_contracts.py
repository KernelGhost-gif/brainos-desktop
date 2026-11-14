from pathlib import Path
import unittest
ROOT = Path(__file__).resolve().parents[1]
class BrainOSSourceContracts(unittest.TestCase):
    def read(self, relative: str) -> str:
        return (ROOT / relative).read_text(encoding="utf-8")
    def test_cmake_requires_wayland_and_webengine_quick(self):
        cmake=self.read("kit/brainos-qt/CMakeLists.txt")
        self.assertIn("WaylandCompositor",cmake); self.assertIn("WebEngineQuick",cmake)
        self.assertIn("qml/pages/BrowserPage.qml",cmake); self.assertIn("qml/pages/CalculatorPage.qml",cmake)
    def test_browser_and_calculator_are_registered(self):
        desktop=self.read("kit/brainos-qt/qml/desktop/DesktopSurface.qml"); menu=self.read("kit/brainos-qt/qml/system/ApplicationMenu.qml")
        self.assertIn('"calculator":',desktop); self.assertIn('"browser":',desktop)
        self.assertIn('{ id: "calculator",',menu); self.assertIn('{ id: "browser",',menu)
    def test_calculator_does_not_execute_dynamic_javascript(self):
        calculator=self.read("kit/brainos-qt/qml/pages/CalculatorPage.qml")
        self.assertIn("function safeEvaluate",calculator); self.assertNotIn("Function(",calculator); self.assertNotIn("eval(",calculator)
    def test_kernel_fragment_keeps_webengine_sandbox_prerequisites(self):
        fragment=self.read("kit/integration/kernel-userns.config")
        for symbol in ("CONFIG_NAMESPACES=y","CONFIG_USER_NS=y","CONFIG_PID_NS=y","CONFIG_NET_NS=y","CONFIG_IPC_NS=y","CONFIG_UTS_NS=y","CONFIG_TMPFS=y","CONFIG_DEVTMPFS=y","CONFIG_SECCOMP=y","CONFIG_SECCOMP_FILTER=y","CONFIG_DRM=y","CONFIG_DRM_VIRTIO_GPU=y","CONFIG_INPUT_EVDEV=y"):
            self.assertIn(symbol,fragment)
    def test_cli_mode_checks_sh_su_and_id(self):
        launcher=self.read("kit/integration/brainos-launch")
        for marker in ("brainos.mode=cli","TOYBOX_SH_OK","TOYBOX_SU_OK","TOYBOX_CLI_READY","TOYBOX_CLI_FALLBACK"): self.assertIn(marker,launcher)
    def test_qemu_gate_requires_user_namespaces_and_stability_window(self):
        qemu=self.read("scripts/qemu-smoke-test.sh")
        self.assertIn("CONFIG_USER_NS=y",qemu); self.assertIn("DESKTOP_STABILITY_SECONDS",qemu); self.assertIn("WAYLAND_SOCKET_READY",qemu)
    def test_chromium_sandbox_is_not_disabled(self):
        session=self.read("kit/integration/brainos-session")
        for marker in ("XDG_RUNTIME_DIR","QTWEBENGINEPROCESS_PATH","QTWEBENGINE_RESOURCES_PATH","QTWEBENGINE_LOCALES_PATH",'--socket-name "$WAYLAND_DISPLAY"',"QT_QPA_EGLFS_INTEGRATION"):
            self.assertIn(marker,session)
        self.assertNotIn("--no-sandbox",session); self.assertNotIn("QTWEBENGINE_DISABLE_SANDBOX",session)
if __name__=="__main__": unittest.main(verbosity=2)
