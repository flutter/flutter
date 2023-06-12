import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/src/painters/indicator_painter.dart';
import 'package:smooth_page_indicator/src/painters/swap_painter.dart';

import 'indicator_effect.dart';

class SwapEffect extends BasicIndicatorEffect {
  final SwapType type;
  const SwapEffect({
    Color activeDotColor = Colors.indigo,
    double offset = 16.0,
    double dotWidth = 16.0,
    double dotHeight = 16.0,
    double spacing = 8.0,
    double radius = 16,
    Color dotColor = Colors.grey,
    double strokeWidth = 1.0,
    this.type = SwapType.normal,
    PaintingStyle paintStyle = PaintingStyle.fill,
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
  Size calculateSize(int count) {
    var height = dotHeight;
    if (type == SwapType.zRotation) {
      height += height * .2;
    } else if (type == SwapType.yRotation) {
      height += dotWidth + spacing;
    }
    return Size(dotWidth * count + (spacing * count), height);
  }

  @override
  IndicatorPainter buildPainter(int count, double offset) {
    assert(
      offset.ceil() < count,
      'SwapEffect does not support infinite looping.',
    );
    return SwapPainter(count: count, offset: offset, effect: this);
  }
}

enum SwapType { normal, yRotation, zRotation }
