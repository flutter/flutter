import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/src/painters/indicator_painter.dart';
import 'package:smooth_page_indicator/src/painters/slide_painter.dart';

import 'indicator_effect.dart';

/// Holds painting configuration to be used by [SlidePainter]
class SlideEffect extends BasicIndicatorEffect {
  /// The effect variant
  ///
  /// defaults to [SlideType.normal]
  final SlideType type;

  /// Default constructor
  const SlideEffect({
    Color activeDotColor = Colors.indigo,
    double offset = 16.0,
    double dotWidth = 16.0,
    double dotHeight = 16.0,
    double spacing = 8.0,
    double radius = 16,
    Color dotColor = Colors.grey,
    double strokeWidth = 1.0,
    PaintingStyle paintStyle = PaintingStyle.fill,
    this.type = SlideType.normal,
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
  IndicatorPainter buildPainter(int count, double offset) {
    return SlidePainter(count: count, offset: offset, effect: this);
  }
}

/// The Slide effect variants
enum SlideType {
  /// Paints regular dot sliding animation
  normal,

  /// Paints masked (under-layered) dot sliding animation
  slideUnder
}
