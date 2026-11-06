"""Offline public-display-name contract for Android-only app."""
from pathlib import Path
import json
import unittest

ROOT = Path(__file__).resolve().parents[1]
BRAND = "teStPlaYclouDE"


class PublicIdentityTests(unittest.TestCase):
    def test_arb_display_name(self):
        data = json.loads((ROOT / "lib/l10n/app_ru.arb").read_text(encoding="utf-8"))
        self.assertEqual(data["appTitle"], BRAND)

    def test_android_display_name(self):
        manifest = (ROOT / "android/app/src/main/AndroidManifest.xml").read_text(encoding="utf-8")
        self.assertIn(f'android:label="{BRAND}"', manifest)

    def test_stable_android_identifiers(self):
        self.assertIn("name: cloudmail_player", (ROOT / "pubspec.yaml").read_text())
        self.assertIn(
            'applicationId = "com.cloudmailplayer.cloudmail_player"',
            (ROOT / "android/app/build.gradle.kts").read_text(),
        )


if __name__ == "__main__":
    unittest.main()
