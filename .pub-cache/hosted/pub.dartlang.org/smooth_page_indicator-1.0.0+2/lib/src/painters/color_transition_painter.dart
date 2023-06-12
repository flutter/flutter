import 'dart:math';

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:smooth_page_indicator/src/effects/color_transition_effect.dart';

import 'indicator_painter.dart';

class TransitionPainter extends BasicIndicatorPainter {
  final ColorTransitionEffect effect;

  TransitionPainter({
    required this.effect,
    required int count,
    required double offset,
  }) : super(offset, count, effect);

  @override
  void paint(Canvas canvas, Size size) {
    final current = offset.floor();
    final dotPaint = Paint()
      ..strokeWidth = effect.strokeWidth
      ..style = effect.paintStyle;

    final dotOffset = offset - current;
    for (var i = 0; i < count; i++) {
      var color = effect.dotColor;
      if (i == current) {
        // ! Both a and b are non nullable
        color = Color.lerp(effect.activeDotColor, effect.dotColor, dotOffset)!;
        dotPaint.strokeWidth =
            max(effect.activeStrokeWidth * (1 - dotOffset), effect.strokeWidth);
      } else if (i - 1 == current || (i == 0 && offset > count - 1)) {
        // ! Both a and b are non nullable
        dotPaint.strokeWidth =
            max(effect.activeStrokeWidth * dotOffset, effect.strokeWidth);
        color = Color.lerp(
            effect.activeDotColor, effect.dotColor, 1.0 - dotOffset)!;
      } else {
        dotPaint.strokeWidth = effect.strokeWidth;
        color = effect.dotColor;
      }

      final xPos = (i * distance);
      final yPos = size.height / 2;
      final rRect = RRect.fromLTRBR(
        xPos,
        yPos - effect.dotHeight / 2,
        xPos + effect.dotWidth,
        yPos + effect.dotHeight / 2,
        dotRadius,
      );
      canvas.drawRRect(rRect, dotPaint..color = color);
    }
  }
}
