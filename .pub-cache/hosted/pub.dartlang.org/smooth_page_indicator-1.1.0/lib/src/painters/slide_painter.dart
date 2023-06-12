import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/src/effects/slide_effect.dart';

import 'indicator_painter.dart';

/// Paints a sliding transition effect between active
/// and non-active dots
///
/// Live demo at
/// https://github.com/Milad-Akarie/smooth_page_indicator/blob/f7ee92e7413a31de77bfb487755d64a385d52a52/demo/slide.gif
class SlidePainter extends BasicIndicatorPainter {
  /// The painting configuration
  final SlideEffect effect;

  /// Default constructor
  SlidePainter({
    required this.effect,
    required int count,
    required double offset,
  }) : super(offset, count, effect);

  @override
  void paint(Canvas canvas, Size size) {
    // paint still dots

    paintStillDots(canvas, size);

    final activeDotPainter = Paint()..color = effect.activeDotColor;
    final dotOffset = offset - offset.toInt();
    // handle dot travel from end to start (for infinite pager support)
    if (offset > count - 1) {
      final startDot = calcPortalTravel(size, effect.dotWidth / 2, dotOffset);
      canvas.drawRRect(startDot, activeDotPainter);

      final endDot = calcPortalTravel(
        size,
        ((count - 1) * distance) + (effect.dotWidth / 2),
        1 - dotOffset,
      );
      canvas.drawRRect(endDot, activeDotPainter);
      return;
    }

    final xPos = offset * distance;
    final yPos = size.height / 2;
    final rRect = RRect.fromLTRBR(
      xPos,
      yPos - effect.dotHeight / 2,
      xPos + effect.dotWidth,
      yPos + effect.dotHeight / 2,
      dotRadius,
    );

    if (effect.type == SlideType.slideUnder) {
      canvas.saveLayer(Rect.largest, Paint());
      canvas.drawRRect(rRect, activeDotPainter);
      maskStillDots(size, canvas);
      canvas.restore();
    } else {
      canvas.drawRRect(rRect, activeDotPainter);
    }
  }
}
