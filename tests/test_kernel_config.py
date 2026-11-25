from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from update_kernel_config import update_config


class KernelConfigUpdaterTests(unittest.TestCase):
    def test_enable_module_disable_and_preserve_unrelated_symbols(self):
        with tempfile.TemporaryDirectory() as temporary:
            config = Path(temporary) / ".config"
            config.write_text(
                "CONFIG_FOO=m\n# CONFIG_BAR is not set\nCONFIG_KEEP=y\n",
                encoding="utf-8",
            )

            update_config(config, "--enable", "FOO")
            update_config(config, "--module", "BAR")
            update_config(config, "--disable", "BAZ")

            self.assertEqual(
                config.read_text(encoding="utf-8"),
                "CONFIG_FOO=y\nCONFIG_BAR=m\nCONFIG_KEEP=y\n# CONFIG_BAZ is not set\n",
            )

    def test_adds_missing_symbol_and_deduplicates_existing_assignments(self):
        with tempfile.TemporaryDirectory() as temporary:
            config = Path(temporary) / ".config"
            config.write_text(
                "CONFIG_FOO=n\nCONFIG_FOO=y\nCONFIG_OTHER=y\n",
                encoding="utf-8",
            )

            update_config(config, "--module", "FOO")

            result = config.read_text(encoding="utf-8")
            self.assertEqual(result.count("CONFIG_FOO="), 1)
            self.assertIn("CONFIG_FOO=m\n", result)
            self.assertIn("CONFIG_OTHER=y\n", result)

    def test_rejects_invalid_symbol_without_modifying_config(self):
        with tempfile.TemporaryDirectory() as temporary:
            config = Path(temporary) / ".config"
            original = "CONFIG_SAFE=y\n"
            config.write_text(original, encoding="utf-8")

            with self.assertRaises(ValueError):
                update_config(config, "--enable", "SAFE;touch /tmp/pwned")

            self.assertEqual(config.read_text(encoding="utf-8"), original)

    def test_missing_config_fails_closed(self):
        with tempfile.TemporaryDirectory() as temporary:
            missing = Path(temporary) / ".config"
            with self.assertRaises(FileNotFoundError):
                update_config(missing, "--enable", "USER_NS")


if __name__ == "__main__":
    unittest.main(verbosity=2)
