import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/src/effects/swap_effect.dart';

import 'indicator_painter.dart';

/// Paints a swapping transition effect between active
/// and non-active dots
///
/// Live demo at
/// https://github.com/Milad-Akarie/smooth_page_indicator/blob/f7ee92e7413a31de77bfb487755d64a385d52a52/demo/swap.gif
class SwapPainter extends BasicIndicatorPainter {
  /// The painting configuration
  final SwapEffect effect;

  /// Default constructor
  SwapPainter({
    required double offset,
    required this.effect,
    required int count,
  }) : super(offset, count, effect);

  @override
  void paint(Canvas canvas, Size size) {
    final current = offset.floor();
    final dotOffset = offset - offset.floor();
    final activePaint = Paint()..color = effect.activeDotColor;
    var dotScale = effect.dotWidth * .2;
    final yPos = size.height / 2;
    final xAnchor = effect.spacing / 2;

    void drawDot(double xPos, double yPos, Paint paint, [double scale = 0]) {
      final rRect = RRect.fromLTRBR(
        xPos,
        yPos - effect.dotHeight / 2,
        xPos + effect.dotWidth,
        yPos + effect.dotHeight / 2,
        dotRadius,
      ).inflate(scale);

      canvas.drawRRect(rRect, paint);
    }

    for (var i = count - 1; i >= 0; i--) {
      // if current or next
      if (i == current || (i - 1 == current)) {
        if (effect.type == SwapType.yRotation) {
          final piFactor = (dotOffset * math.pi);
          if (i == current) {
            var x = (1 - ((math.cos(piFactor) + 1) / 2)) * distance;
            var y = -math.sin(piFactor) * distance / 2;
            drawDot(xAnchor + distance * i + x, yPos + y, activePaint);
          } else {
            var x = -(1 - ((math.cos(piFactor) + 1) / 2)) * distance;
            var y = (math.sin(piFactor) * distance / 2);
            drawDot(xAnchor + distance * i + x, yPos + y, dotPaint);
          }
        } else {
          var posOffset = i.toDouble();
          var scale = 0.0;
          if (effect.type == SwapType.zRotation) {
            scale = dotScale * dotOffset;
            if (dotOffset > .5) {
              scale = dotScale - (dotScale * dotOffset);
            }
          }
          if (i == current) {
            posOffset = offset;
            drawDot(xAnchor + posOffset * distance, yPos, activePaint, scale);
          } else {
            posOffset = i - dotOffset;
            drawDot(xAnchor + posOffset * distance, yPos, dotPaint, -scale);
          }
        }
      } else {
        // draw still dots
        final xPos = xAnchor + i * distance;
        drawDot(xPos, yPos, dotPaint);
      }
    }
  }
}
