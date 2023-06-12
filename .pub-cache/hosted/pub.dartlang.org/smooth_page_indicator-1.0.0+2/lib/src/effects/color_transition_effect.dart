import 'package:flutter/material.dart';

import '../painters/color_transition_painter.dart';
import '../painters/indicator_painter.dart';
import 'indicator_effect.dart';

/// Holds [TransitionPainter]
class ColorTransitionEffect extends BasicIndicatorEffect {
  // The active dot strokeWidth
  final double activeStrokeWidth;

  const ColorTransitionEffect({
    this.activeStrokeWidth = 1.5,
    double offset = 16.0,
    double dotWidth = 16.0,
    double dotHeight = 16.0,
    double spacing = 8.0,
    double radius = 16,
    Color dotColor = Colors.grey,
    Color activeDotColor = Colors.indigo,
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
  IndicatorPainter buildPainter(int count, double offset) {
    return TransitionPainter(
      count: count,
      offset: offset,
      effect: this,
    );
  }
}
