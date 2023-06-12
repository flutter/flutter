import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/src/effects/worm_effect.dart';

import 'indicator_painter.dart';

/// Paints a warm-like transition effect between active
/// and non-active dots
///
/// Live demo at
/// https://github.com/Milad-Akarie/smooth_page_indicator/blob/f7ee92e7413a31de77bfb487755d64a385d52a52/demo/worm.gif
class WormPainter extends BasicIndicatorPainter {
  /// The painting configuration
  final WormEffect effect;

  /// Default constructor
  WormPainter({
    required this.effect,
    required int count,
    required double offset,
  }) : super(offset, count, effect);

  @override
  void paint(Canvas canvas, Size size) {
    // paint still dots
    paintStillDots(canvas, size);

    final activeDotPaint = Paint()..color = effect.activeDotColor;
    final dotOffset = (offset - offset.toInt());

    // handle dot travel from end to start (for infinite pager support)
    if (offset > count - 1) {
      final startDot = calcPortalTravel(size, effect.dotWidth / 2, dotOffset);
      canvas.drawRRect(startDot, activeDotPaint);

      final endDot = calcPortalTravel(
        size,
        ((count - 1) * distance) + (effect.dotWidth / 2),
        1 - dotOffset,
      );
      canvas.drawRRect(endDot, activeDotPaint);
      return;
    }

    final wormOffset = dotOffset * 2;
    final xPos = (offset.floor() * distance);
    final yPos = size.height / 2;
    var head = xPos;
    var tail = xPos + effect.dotWidth + (wormOffset * distance);
    var halfHeight = effect.dotHeight / 2;
    final thinWorm =
        effect.type == WormType.thin || effect.type == WormType.thinUnderground;
    var dotHeight = thinWorm
        ? halfHeight + (halfHeight * (1 - wormOffset))
        : effect.dotHeight;

    if (wormOffset > 1) {
      tail = xPos + effect.dotWidth + (1 * distance);
      head = xPos + distance * (wormOffset - 1);
      if (thinWorm) {
        dotHeight = halfHeight + (halfHeight * (wormOffset - 1));
      }
    }
    final worm = RRect.fromLTRBR(
      head,
      yPos - dotHeight / 2,
      tail,
      yPos + dotHeight / 2,
      dotRadius,
    );
    if (effect.type == WormType.underground ||
        effect.type == WormType.thinUnderground) {
      canvas.saveLayer(Rect.largest, Paint());
      canvas.drawRRect(worm, activeDotPaint);
      maskStillDots(size, canvas);
      canvas.restore();
    } else {
      canvas.drawRRect(worm, activeDotPaint);
    }
  }
}
