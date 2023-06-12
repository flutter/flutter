import 'dart:math';

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/src/painters/indicator_painter.dart';
import 'package:smooth_page_indicator/src/painters/jumping_dot_painter.dart';

import 'indicator_effect.dart';

/// Holds painting configuration to be used by [JumpingDotPainter]
class JumpingDotEffect extends BasicIndicatorEffect {
  /// The maximum scale the dot will hit while jumping
  final double jumpScale;

  /// The vertical offset of the jumping dot
  final double verticalOffset;

  /// Default constructor
  const JumpingDotEffect({
    Color activeDotColor = Colors.indigo,
    this.jumpScale = 1.4,
    this.verticalOffset = 0.0,
    double offset = 16.0,
    double dotWidth = 16.0,
    double dotHeight = 16.0,
    double spacing = 8.0,
    double radius = 16,
    Color dotColor = Colors.grey,
    double strokeWidth = 1.0,
    PaintingStyle paintStyle = PaintingStyle.fill,
  }) : super(
            dotWidth: dotWidth,
            dotHeight: dotHeight,
            spacing: spacing,
            radius: radius,
            strokeWidth: strokeWidth,
            paintStyle: paintStyle,
            dotColor: dotColor,
            activeDotColor: activeDotColor);

  @override
  Size calculateSize(int count) {
    return Size(
      dotWidth * count + (spacing * (count - 1)),
      max(dotHeight, dotHeight * jumpScale) + verticalOffset.abs(),
    );
  }

  @override
  IndicatorPainter buildPainter(int count, double offset) {
    return JumpingDotPainter(count: count, offset: offset, effect: this);
  }
}
