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
  double get value => 1;

  @override
  AnimationStatus get status => AnimationStatus.dismissed;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void addStatusListener(AnimationStatusListener listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  void removeStatusListener(AnimationStatusListener listener) {}
}

CustomPainter _buildPainter({
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
  return ScrollbarPainter(
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
  )..update(scrollMetrics, scrollMetrics.axisDirection);
}

class _DrawRectOnceCanvas implements Canvas {
  Rect rect;

  @override
  void noSuchMethod(Invocation invocation) {
    assert(invocation.memberName == #drawRect);
    // Must call reset before redraw. This is to catch redundant
    // drawRect calls.
    assert(rect == null);
    assert(invocation.positionalArguments[0] is Rect);
    rect = invocation.positionalArguments[0];
  }

  void reset() {
    rect = null;
  }
}

void main() {
  final _DrawRectOnceCanvas testCanvas = _DrawRectOnceCanvas();
  ScrollbarPainter painter;

  tearDown(testCanvas.reset);

  final ScrollMetrics defaultMetrics = FixedScrollMetrics(
    minScrollExtent: 0,
    maxScrollExtent: 0,
    pixels: 0,
    viewportDimension: 100,
    axisDirection: AxisDirection.down
  );

  testWidgets(
    'Scrollbar is not smaller than minLength with large scroll views',
    (WidgetTester tester) async {
      const double minLen = 3.5;
      const Size size = Size(600, 800);
      final ScrollMetrics metrics = defaultMetrics.copyWith(
        maxScrollExtent: 100000,
        viewportDimension: 10,
      );


      // When overscroll.
      painter = _buildPainter(
        minLength: minLen,
        minOverscrollLength: minLen,
        scrollMetrics: metrics
      );

      painter.paint(testCanvas, size);

      expect(testCanvas.rect.top, 0);
      expect(testCanvas.rect.left, size.width - _kThickness);
      expect(testCanvas.rect.width, _kThickness);
      expect(testCanvas.rect.height >= minLen, true);

      // When scroll normally.
      testCanvas.reset();

      const double newPixels = 1.0;

      painter.update(metrics.copyWith(pixels: newPixels), metrics.axisDirection);

      painter.paint(testCanvas, size);

      expect(testCanvas.rect.top, 0);
      expect(testCanvas.rect.left, size.width - _kThickness);
      expect(testCanvas.rect.width, _kThickness);
      expect(testCanvas.rect.height >= minLen, true);
    }
  );

  testWidgets(
    'When scrolling normally (no overscrolling), the size of the scrollbar stays the same',
    (WidgetTester tester) async {
      const double viewportDimension = 10;
      const double maxExtent = 100;
      final ScrollMetrics startingMetrics = defaultMetrics.copyWith(
        maxScrollExtent: maxExtent,
        viewportDimension: viewportDimension,
      );
      const Size size = Size(600, 800);
      const double minLen = 99999;
      final List<ScrollMetrics> metricsList = [
        startingMetrics.copyWith(pixels: 0.01),
        ... List<ScrollMetrics>.generate(
          maxExtent/viewportDimension,
          (int index) => startingMetrics.copyWith(pixels: index * viewportDimension)
        ).filter((ScrollMetrics metrics) => !metrics.outOfRange),
        startingMetrics.copyWith(pixels: maxExtent - 0.01)
      ];

      for(ScrollMetrics metrics in metricsList) {
        painter = _buildPainter(
          minLength: minLen,
          minOverscrollLength: minLen,
          scrollMetrics: metrics
        );

        painter.paint(testCanvas, size);

        expect(testCanvas.rect.top, metrics.pixels);
        expect(testCanvas.rect.left, size.width - _kThickness);
        expect(testCanvas.rect.width, _kThickness);
        expect(testCanvas.rect.height, maxExtent/viewportDimension);
      }
    }
  );


  /*
  testWidgets(
    'mainAxisMargin is respected',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildBoilerPlate(
          size: const Size(600, 800),
          minLength: minLen,
          minOverscrollLength: minLen,
          scrollMetrics: metrics.copyWith(
            maxScrollExtent: 100000,
            viewportDimension: 10,
          )
        )
      );
    }
  );*/

}
