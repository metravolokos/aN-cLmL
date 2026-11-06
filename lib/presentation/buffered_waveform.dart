import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Decorative wave-shaped seek track. Height is a deterministic motif rather
/// than a decoded audio waveform; buffer fill is based on actual cache bytes.
class BufferedWaveform extends StatelessWidget {
  const BufferedWaveform({
    required this.played,
    required this.buffered,
    super.key,
  });

  final double played;
  final double buffered;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: CustomPaint(
        key: const ValueKey('buffered-waveform'),
        painter: _WaveformPainter(
          played: played.clamp(0.0, 1.0).toDouble(),
          buffered: buffered.clamp(0.0, 1.0).toDouble(),
          playedColor: colors.primary,
          cachedColor: colors.primary.withValues(alpha: 0.45),
          emptyColor: colors.onSurface.withValues(alpha: 0.16),
        ),
        size: const Size(0, 38),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.played,
    required this.buffered,
    required this.playedColor,
    required this.cachedColor,
    required this.emptyColor,
  });

  final double played;
  final double buffered;
  final Color playedColor;
  final Color cachedColor;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final count = math.max(1, (size.width / 6).floor());
    final step = size.width / count;
    final width = math.min(3.5, step * 0.65);
    for (var i = 0; i < count; i++) {
      final fraction = (i + 0.5) / count;
      final height = size.height *
          (0.24 + 0.62 * (0.5 + 0.5 * math.sin(i * 1.77)));
      final bar = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset((i + 0.5) * step, size.height / 2),
          width: width,
          height: height,
        ),
        const Radius.circular(3),
      );
      final color = fraction <= played
          ? playedColor
          : fraction <= buffered
              ? cachedColor
              : emptyColor;
      canvas.drawRRect(bar, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      played != old.played ||
      buffered != old.buffered ||
      playedColor != old.playedColor ||
      cachedColor != old.cachedColor ||
      emptyColor != old.emptyColor;
}
