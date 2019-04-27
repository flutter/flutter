// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

const Color _kScrollbarColor = Color(0xFF123456);
const double _kThickness = 2.5;
const double _kMinThumbExtent = 18.0;

class _NoAnimation extends Animation<double> {
  @override
  double get value => 0;
}


Widget _buildBoilerPlate({
    Size size,
    TextDirection textDirection = TextDirection.ltr,
    EdgeInsets padding = EdgeInsets.zero,
    Color color = _kScrollbarColor,
    double thickness = _kThickness,
    double mainAxisMargin = 0.0,
    double crossAxisMargin = 0.0,
    Radius radius,
    double minLength = _kMinThumbExtent,
    double minOverscrollLength = _kMinThumbExtent,
    ScrollMetrics scrollMetrics,
}) {
  return CustomPaint(
    size: size,
    painter: ScrollbarPainter(
      color: color,
      textDirection: textDirection,
      thickness: thickness,
      padding: padding,
      mainAxisMargin: mainAxisMargin,
      crossAxisMargin: crossAxisMargin,
      radius: radius,
      minLength: minLength,
      minOverscrollLength: minOverscrollLength,
      fadeoutOpacityAnimation: _NoAnimation(),
    )..update(scrollMetrics, scrollMetrics.axisDirection)
  );
}

void main() {
  final ScrollMetrics metrics = FixedScrollMetrics(
    minScrollExtent: 0,
    maxScrollExtent: 0,
    pixels: 0,
    viewportDimension: 100,
    axisDirection: AxisDirection.down
  );

  testWidget(
    'Scrollbar is not smaller than minLength with large scroll views',
    (WidgetTester tester) async {
      final double minLen = 3.5;
      await tester.pumpWidget(
        _buildBoilerPlate(
          minLength: minLen,
          scrollMetrics: metrics.copyWith(
            maxScrollExtent: 100000,
            viewportDimension: 10,
          )
        )
      );

      await tester.pump();

      expect(find.byType(ScrollbarPainter), paints..rect(
          rect: Rect.fromLTWH(800 - _kThickness, 0, _kThickness, minLen)
      ));
    }
  );
}
