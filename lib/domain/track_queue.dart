import 'dart:math';

import 'remote_track.dart';

/// Pure domain model for a track/album/artist context. No audio or network I/O.
/// Shuffle never changes the currently selected track.
enum QueueRepeat { off, all, one }

class TrackQueue {
  TrackQueue({Random? random}) : _random = random ?? Random();

  final Random _random;
  List<RemoteTrack> _tracks = const [];
  List<int> _order = const [];
  int _cursor = -1;
  QueueRepeat _repeat = QueueRepeat.off;
  bool _shuffle = false;

  QueueRepeat get repeat => _repeat;
  bool get shuffle => _shuffle;
  int get length => _tracks.length;
  bool get isEmpty => _cursor < 0;
  RemoteTrack? get current => _cursor < 0 ? null : _tracks[_order[_cursor]];
  int get originalIndex => _cursor < 0 ? -1 : _order[_cursor];

  void load(List<RemoteTrack> tracks, {int startIndex = 0}) {
    if (tracks.isNotEmpty && (startIndex < 0 || startIndex >= tracks.length)) {
      throw RangeError.range(startIndex, 0, tracks.length - 1, 'startIndex');
    }
    _tracks = List.unmodifiable(tracks);
    _order = List.generate(tracks.length, (index) => index);
    _cursor = tracks.isEmpty ? -1 : startIndex;
    if (_shuffle && !isEmpty) _shuffleAroundCurrent();
  }

  void clear() {
    _tracks = const [];
    _order = const [];
    _cursor = -1;
  }

  void setRepeat(QueueRepeat value) => _repeat = value;

  void setShuffle(bool enabled) {
    if (_shuffle == enabled) return;
    final selectedIndex = originalIndex;
    _shuffle = enabled;
    _order = List.generate(_tracks.length, (index) => index);
    _cursor = selectedIndex;
    if (_shuffle && !isEmpty) _shuffleAroundCurrent();
  }

  void _shuffleAroundCurrent() {
    final selected = originalIndex;
    final rest = <int>[
      for (var i = 0; i < _tracks.length; i++)
        if (i != selected) i,
    ];
    // Fisher-Yates with injected Random to make tests deterministic.
    for (var i = rest.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final item = rest[i];
      rest[i] = rest[j];
      rest[j] = item;
    }
    _order = [selected, ...rest];
    _cursor = 0;
  }

  /// Automatic transition respects Repeat One; manual Next always advances.
  RemoteTrack? next({bool automatic = false}) {
    if (isEmpty) return null;
    if (automatic && _repeat == QueueRepeat.one) return current;
    if (_cursor + 1 < _order.length) {
      _cursor++;
      return current;
    }
    if (_repeat == QueueRepeat.all) {
      _cursor = 0;
      return current;
    }
    return null;
  }

  /// Manual Previous ignores Repeat One and follows the active queue order.
  RemoteTrack? previous() {
    if (isEmpty) return null;
    if (_cursor > 0) {
      _cursor--;
      return current;
    }
    if (_repeat == QueueRepeat.all) {
      _cursor = _order.length - 1;
      return current;
    }
    return null;
  }
}
