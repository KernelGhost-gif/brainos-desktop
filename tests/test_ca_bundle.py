from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "kit/integration"))
from build_ca_bundle import build_bundle


CERT_A = b"-----BEGIN CERTIFICATE-----\nCERTIFICATE_A\n-----END CERTIFICATE-----\n"
CERT_B = b"-----BEGIN CERTIFICATE-----\nCERTIFICATE_B\n-----END CERTIFICATE-----\n"
CERT_DISABLED = b"-----BEGIN CERTIFICATE-----\nDISABLED\n-----END CERTIFICATE-----\n"


class BuildCaBundleTests(unittest.TestCase):
    def make_root(self, root: Path) -> None:
        (root / "etc").mkdir(parents=True)
        (root / "usr/share/ca-certificates/mozilla").mkdir(parents=True)
        (root / "usr/local/share/ca-certificates/custom").mkdir(parents=True)
        (root / "etc/ca-certificates.conf").write_text(
            "# selected roots\nmozilla/a.crt\n!mozilla/disabled.crt\nmozilla/b.crt\n",
            encoding="utf-8",
        )
        (root / "usr/share/ca-certificates/mozilla/a.crt").write_bytes(CERT_A)
        (root / "usr/share/ca-certificates/mozilla/b.crt").write_bytes(CERT_B)
        (root / "usr/share/ca-certificates/mozilla/disabled.crt").write_bytes(CERT_DISABLED)
        (root / "usr/local/share/ca-certificates/custom/local.crt").write_bytes(CERT_B)

    def test_builds_selected_and_local_certs_but_skips_disabled_entries(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            self.make_root(root)
            count = build_bundle(root)
            bundle = (root / "etc/ssl/certs/ca-certificates.crt").read_bytes()
            self.assertEqual(count, 3)
            self.assertEqual(bundle.count(b"-----BEGIN CERTIFICATE-----"), 3)
            self.assertNotIn(b"DISABLED", bundle)
            self.assertIn(CERT_A, bundle)
            self.assertIn(CERT_B, bundle)
            self.assertEqual((root / "etc/ssl/certs/ca-certificates.crt").stat().st_mode & 0o777, 0o644)

    def test_fresh_rootfs_defaults_to_all_packaged_roots_and_writes_config(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            self.make_root(root)
            (root / "etc/ca-certificates.conf").unlink()

            count = build_bundle(root)
            bundle = (root / "etc/ssl/certs/ca-certificates.crt").read_bytes()
            config = (root / "etc/ca-certificates.conf").read_text(encoding="utf-8")

            self.assertEqual(count, 4)
            self.assertEqual(bundle.count(b"-----BEGIN CERTIFICATE-----"), 4)
            self.assertIn(b"DISABLED", bundle)
            self.assertIn("mozilla/a.crt", config)
            self.assertIn("mozilla/disabled.crt", config)
            self.assertIn("mozilla/b.crt", config)

    def test_missing_configured_certificate_fails_closed(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            self.make_root(root)
            (root / "usr/share/ca-certificates/mozilla/a.crt").unlink()
            with self.assertRaises(FileNotFoundError):
                build_bundle(root)

    def test_rejects_path_traversal_in_configuration(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            self.make_root(root)
            (root / "etc/ca-certificates.conf").write_text("../outside.crt\n", encoding="utf-8")
            with self.assertRaises(ValueError):
                build_bundle(root)


if __name__ == "__main__":
    unittest.main(verbosity=2)
