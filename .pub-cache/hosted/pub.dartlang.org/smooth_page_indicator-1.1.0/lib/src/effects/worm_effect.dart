import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/src/painters/indicator_painter.dart';
import 'package:smooth_page_indicator/src/painters/worm_painter.dart';

import 'indicator_effect.dart';

/// Holds painting configuration to be used by [WormPainter]
class WormEffect extends BasicIndicatorEffect {
  /// The effect variant
  ///
  /// defaults to [WormType.normal]
  final WormType type;

  /// Default constructor
  const WormEffect({
    double offset = 16.0,
    double dotWidth = 16.0,
    double dotHeight = 16.0,
    double spacing = 8.0,
    double radius = 16,
    Color dotColor = Colors.grey,
    Color activeDotColor = Colors.indigo,
    double strokeWidth = 1.0,
    PaintingStyle paintStyle = PaintingStyle.fill,
    this.type = WormType.normal,
  }) : super(
          dotWidth: dotWidth,
          dotHeight: dotHeight,
          spacing: spacing,
          radius: radius,
          strokeWidth: strokeWidth,
          paintStyle: paintStyle,
          dotColor: dotColor,
          activeDotColor: activeDotColor,
        );

  @override
  IndicatorPainter buildPainter(int count, double offset) {
    return WormPainter(count: count, offset: offset, effect: this);
  }
}

/// The Worm effect variants
enum WormType {
  /// Draws normal worm animation
  normal,

  /// Draws a thin worm animation
  thin,

  /// Draws normal worm animation that looks like
  /// it's under the background
  underground,

  /// Draws a thing worm animation that looks like
  /// it's under the background
  thinUnderground,
}
