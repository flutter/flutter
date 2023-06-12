import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/src/painters/expanding_dots_painter.dart';
import 'package:smooth_page_indicator/src/painters/indicator_painter.dart';

import 'indicator_effect.dart';

/// Holds painting configuration to be used by [ExpandingDotsPainter]
class ExpandingDotsEffect extends BasicIndicatorEffect {
  /// This is multiplied by [dotWidth] to calculate
  /// the width of the expanded dot.
  final double expansionFactor;

  /// Default constructor
  const ExpandingDotsEffect({
    this.expansionFactor = 3,
    double offset = 16.0,
    double dotWidth = 16.0,
    double dotHeight = 16.0,
    double spacing = 8.0,
    double radius = 16.0,
    Color activeDotColor = Colors.indigo,
    Color dotColor = Colors.grey,
    double strokeWidth = 1.0,
    PaintingStyle paintStyle = PaintingStyle.fill,
  })  : assert(expansionFactor > 1),
        super(
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
    /// Add the expanded dot width to our size calculation
    return Size(
        ((dotWidth + spacing) * (count - 1)) + (expansionFactor * dotWidth),
        dotHeight);
  }

  @override
  IndicatorPainter buildPainter(int count, double offset) {
    return ExpandingDotsPainter(count: count, offset: offset, effect: this);
  }

  @override
  int hitTestDots(double dx, int count, double current) {
    var anchor = -spacing / 2;
    for (var index = 0; index < count; index++) {
      var widthBound =
          (index == current ? (dotWidth * expansionFactor) : dotWidth) +
              spacing;
      if (dx <= (anchor += widthBound)) {
        return index;
      }
    }
    return -1;
  }
}
