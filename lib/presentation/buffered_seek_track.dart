import 'package:flutter/material.dart';

/// The entire playable file has a background; downloaded bytes fill the
/// middle layer, and the already heard position paints on top. This is a
/// visual track only: the overlaid Slider owns all touch and seek behavior.
class BufferedSeekTrack extends StatelessWidget {
  const BufferedSeekTrack({
    required this.played,
    required this.buffered,
    super.key,
  });

  final double played;
  final double buffered;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cacheFraction = buffered.clamp(0.0, 1.0).toDouble();
    final heardFraction = played.clamp(0.0, 1.0).toDouble();

    return Semantics(
      label: null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: SizedBox(
          key: const ValueKey('buffered-seek-track'),
          height: 12,
          child: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(color: colors.surfaceContainerHighest),
              ),
              Positioned.fill(
                child: FractionallySizedBox(
                  key: const ValueKey('seek-buffered-fill'),
                  alignment: Alignment.centerLeft,
                  widthFactor: cacheFraction,
                  child: ColoredBox(
                    color: colors.primary.withValues(alpha: 0.36),
                  ),
                ),
              ),
              Positioned.fill(
                child: FractionallySizedBox(
                  key: const ValueKey('seek-played-fill'),
                  alignment: Alignment.centerLeft,
                  widthFactor: heardFraction,
                  child: ColoredBox(color: colors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
