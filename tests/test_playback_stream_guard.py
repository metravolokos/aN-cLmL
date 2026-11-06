"""Source contract for preventing stale player events during source replacement."""

from pathlib import Path
import re
import unittest


SOURCE = (Path(__file__).resolve().parents[1] / "lib/data/audio/playback_controller.dart").read_text(encoding="utf-8")


class PlaybackStreamGuardTest(unittest.TestCase):
    def test_all_player_stream_callbacks_guard_source_switch(self):
        streams = ("positionStream", "durationStream", "playingStream", "processingStateStream", "errorStream")
        for stream in streams:
            with self.subTest(stream=stream):
                match = re.search(rf"audio\\.{stream}\\.listen\\(\\([^)]*\\) \\{{(.*?)\\n      \\}}\\)", SOURCE, re.S)
                self.assertIsNotNone(match, f"Missing {stream} listener")
                self.assertIn("_changingTrack", match.group(1))


if __name__ == "__main__":
    unittest.main()
