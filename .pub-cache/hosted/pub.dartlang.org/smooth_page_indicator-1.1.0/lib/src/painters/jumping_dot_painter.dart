import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/src/effects/jumping_dot_effect.dart';

import 'indicator_painter.dart';

/// Paints a jumping dot transition effect between active
/// and non-active dots
///
/// Live demo at
/// https://github.com/Milad-Akarie/smooth_page_indicator/blob/f7ee92e7413a31de77bfb487755d64a385d52a52/demo/jumping-dot.gif
class JumpingDotPainter extends BasicIndicatorPainter {
  /// The painting configuration
  final JumpingDotEffect effect;

  /// Default constructor
  JumpingDotPainter({
    required this.effect,
    required int count,
    required double offset,
  }) : super(offset, count, effect);

  @override
  void paint(Canvas canvas, Size size) {
    // paint still dots
    if (effect.verticalOffset != 0) {
      canvas.translate(0, effect.verticalOffset / 2);
    }
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

    var scale = 1.0;
    var targetScale = effect.jumpScale - 1.0;

    if (dotOffset < .5) {
      scale = 1.0 + (dotOffset * 2) * targetScale;
    } else {
      scale = effect.jumpScale + ((1 - (dotOffset * 2)) * targetScale);
    }
    final piFactor = (dotOffset * math.pi);
    var yPos = size.height / 2;
    var xPos = offset.floor() * distance;
    var x = (1 - ((math.cos(piFactor) + 1) / 2)) * distance;
    var y = -math.sin(piFactor) * effect.verticalOffset;
    xPos += x;
    yPos += y;

    final height = effect.dotHeight * scale;
    final width = effect.dotWidth * scale;
    final scaleRatio = width / effect.dotWidth;
    final rRect = RRect.fromLTRBR(
      xPos,
      yPos - height / 2,
      xPos + width,
      yPos + height / 2,
      dotRadius * scaleRatio,
    );

    canvas.drawRRect(rRect, activeDotPainter);
  }
}
