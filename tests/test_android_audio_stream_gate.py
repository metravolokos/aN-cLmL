"""Source contract: all Android audio event callbacks use a common lifecycle gate."""
from pathlib import Path
import re
import unittest

SOURCE = (Path(__file__).resolve().parents[1] / "lib/data/audio/playback_controller.dart").read_text(encoding="utf-8")


class AndroidAudioStreamContract(unittest.TestCase):
    def test_all_five_stream_handlers_guard_the_active_source(self):
        for stream in ("positionStream", "durationStream", "playingStream",
                       "processingStateStream", "errorStream"):
            with self.subTest(stream=stream):
                match = re.search(r"audio\." + stream + r"\.listen\(\([^)]*\) \{(.*?)\n      \}\)", SOURCE, re.S)
                self.assertIsNotNone(match, f"Missing {stream} listener")
                self.assertIn("_acceptAudioEvent", match.group(1))

    def test_gate_requires_queue_track_and_completed_switch(self):
        self.assertIn("hasQueue: _queue != null", SOURCE)
        self.assertIn("hasTrack: state.track != null", SOURCE)
        self.assertIn("switchingTrack: _changingTrack", SOURCE)
        self.assertIn("disposed: _closed", SOURCE)


if __name__ == "__main__":
    unittest.main()
