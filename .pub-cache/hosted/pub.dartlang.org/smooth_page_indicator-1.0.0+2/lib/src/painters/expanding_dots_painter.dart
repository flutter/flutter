import 'package:flutter/material.dart';

import '../effects/expanding_dots_effect.dart';
import 'indicator_painter.dart';

class ExpandingDotsPainter extends BasicIndicatorPainter {
  final ExpandingDotsEffect effect;

  ExpandingDotsPainter({
    required double offset,
    required this.effect,
    required int count,
  }) : super(offset, count, effect);

  @override
  void paint(Canvas canvas, Size size) {
    final current = offset.floor();
    var drawingOffset = -effect.spacing;
    final dotOffset = offset - current;

    for (var i = 0; i < count; i++) {
      var color = effect.dotColor;
      final activeDotWidth = effect.dotWidth * effect.expansionFactor;
      final expansion =
          (dotOffset / 2 * ((activeDotWidth - effect.dotWidth) / .5));
      final xPos = drawingOffset + effect.spacing;
      var width = effect.dotWidth;
      if (i == current) {
        // ! Both a and b are non nullable
        color = Color.lerp(effect.activeDotColor, effect.dotColor, dotOffset)!;
        width = activeDotWidth - expansion;
      } else if (i - 1 == current || (i == 0 && offset > count - 1)) {
        width = effect.dotWidth + expansion;
        // ! Both a and b are non nullable
        color = Color.lerp(
            effect.activeDotColor, effect.dotColor, 1.0 - dotOffset)!;
      }
      final yPos = size.height / 2;
      final rRect = RRect.fromLTRBR(
        xPos,
        yPos - effect.dotHeight / 2,
        xPos + width,
        yPos + effect.dotHeight / 2,
        dotRadius,
      );
      drawingOffset = rRect.right;
      canvas.drawRRect(rRect, dotPaint..color = color);
    }
  }
}
