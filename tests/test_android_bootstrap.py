"""Android bootstrap contracts; historical desktop source may remain until a later PR."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class AndroidBootstrapTests(unittest.TestCase):
    def test_entry_point_has_android_only_initialization(self):
        main = (ROOT / "lib/main.dart").read_text(encoding="utf-8")
        self.assertIn("initializeAndroidPlaybackControls()", main)
        self.assertIn("configureAndroidMusicAudioSession()", main)
        self.assertIn("AndroidMediaSessionBridge", main)
        for forbidden in (
            "JustAudioMediaKit",
            "initializeWindowsMediaControls",
            "initializeLinuxMprisControls",
            "WindowsMediaControlsBridge",
            "LinuxMprisBridge",
        ):
            self.assertNotIn(forbidden, main)

    def test_ci_targets_android_only(self):
        workflow = (ROOT / ".github/workflows/flutter.yml").read_text(encoding="utf-8")
        self.assertIn("  quality:", workflow)
        self.assertIn("  android:", workflow)
        self.assertNotIn("  windows:", workflow)
        self.assertNotIn("  linux:", workflow)
        self.assertIn("flutter build apk --debug", workflow)

    def test_original_spec_is_preserved(self):
        spec = (ROOT / "docs/USER_SPEC_RU.md").read_text(encoding="utf-8")
        self.assertIn("Windows 10/11", spec)
        self.assertIn("Android", spec)
        self.assertIn("Linux", spec)


if __name__ == "__main__":
    unittest.main()
