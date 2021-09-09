// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/src/physics/utils.dart' show nearEqual;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

const Color _kScrollbarColor = Color(0xFF123456);
const double _kThickness = 2.5;
const double _kMinThumbExtent = 18.0;
const Duration _kScrollbarFadeDuration = Duration(milliseconds: 300);
const Duration _kScrollbarTimeToFade = Duration(milliseconds: 600);

ScrollbarPainter _buildPainter({
  TextDirection textDirection = TextDirection.ltr,
  EdgeInsets padding = EdgeInsets.zero,
  Color color = _kScrollbarColor,
  double thickness = _kThickness,
  double mainAxisMargin = 0.0,
  double crossAxisMargin = 0.0,
  Radius? radius,
  double minLength = _kMinThumbExtent,
  double? minOverscrollLength,
  ScrollbarOrientation? scrollbarOrientation,
  required ScrollMetrics scrollMetrics,
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
    minOverscrollLength: minOverscrollLength ?? minLength,
    fadeoutOpacityAnimation: kAlwaysCompleteAnimation,
    scrollbarOrientation: scrollbarOrientation,
  )..update(scrollMetrics, scrollMetrics.axisDirection);
}

class _DrawRectOnceCanvas extends Fake implements Canvas {
  List<Rect> rects = <Rect>[];

  @override
  void drawRect(Rect rect, Paint paint) {
    rects.add(rect);
  }

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {}
}

void main() {
  final _DrawRectOnceCanvas testCanvas = _DrawRectOnceCanvas();
  ScrollbarPainter painter;

  Rect captureRect() => testCanvas.rects.removeLast();

  tearDown(() {
    testCanvas.rects.clear();
  });

  final ScrollMetrics defaultMetrics = FixedScrollMetrics(
    minScrollExtent: 0,
    maxScrollExtent: 0,
    pixels: 0,
    viewportDimension: 100,
    axisDirection: AxisDirection.down,
  );

  test(
    'Scrollbar is not smaller than minLength with large scroll views, '
    'if minLength is small ',
    () {
      const double minLen = 3.5;
      const Size size = Size(600, 10);
      final ScrollMetrics metrics = defaultMetrics.copyWith(
        maxScrollExtent: 100000,
        viewportDimension: size.height,
      );

      // When overscroll.
      painter = _buildPainter(
        minLength: minLen,
        minOverscrollLength: minLen,
        scrollMetrics: metrics,
      );

      painter.paint(testCanvas, size);

      final Rect rect0 = captureRect();
      expect(rect0.top, 0);
      expect(rect0.left, size.width - _kThickness);
      expect(rect0.width, _kThickness);
      expect(rect0.height >= minLen, true);

      // When scroll normally.
      const double newPixels = 1.0;

      painter.update(metrics.copyWith(pixels: newPixels), metrics.axisDirection);

      painter.paint(testCanvas, size);

      final Rect rect1 = captureRect();
      expect(rect1.left, size.width - _kThickness);
      expect(rect1.width, _kThickness);
      expect(rect1.height >= minLen, true);
    },
  );

  test(
    'When scrolling normally (no overscrolling), the size of the scrollbar stays the same, '
    'and it scrolls evenly',
    () {
      const double viewportDimension = 23;
      const double maxExtent = 100;
      final ScrollMetrics startingMetrics = defaultMetrics.copyWith(
        maxScrollExtent: maxExtent,
        viewportDimension: viewportDimension,
      );
      const Size size = Size(600, viewportDimension);
      const double minLen = 0;

      painter = _buildPainter(
        minLength: minLen,
        minOverscrollLength: minLen,
        scrollMetrics: defaultMetrics,
      );

      final List<ScrollMetrics> metricsList = <ScrollMetrics> [
        startingMetrics.copyWith(pixels: 0.01),
        ...List<ScrollMetrics>.generate(
          (maxExtent / viewportDimension).round(),
          (int index) => startingMetrics.copyWith(pixels: (index + 1) * viewportDimension),
        ).where((ScrollMetrics metrics) => !metrics.outOfRange),
        startingMetrics.copyWith(pixels: maxExtent - 0.01),
      ];

      late double lastCoefficient;
      for (final ScrollMetrics metrics in metricsList) {
        painter.update(metrics, metrics.axisDirection);
        painter.paint(testCanvas, size);

        final Rect rect = captureRect();
        final double newCoefficient = metrics.pixels/rect.top;
        lastCoefficient = newCoefficient;

        expect(rect.top >= 0, true);
        expect(rect.bottom <= maxExtent, true);
        expect(rect.left, size.width - _kThickness);
        expect(rect.width, _kThickness);
        expect(nearEqual(rect.height, viewportDimension * viewportDimension / (viewportDimension + maxExtent), 0.001), true);
        expect(nearEqual(lastCoefficient, newCoefficient, 0.001), true);
      }
    },
  );

  test(
    'mainAxisMargin is respected',
    () {
      const double viewportDimension = 23;
      const double maxExtent = 100;
      final ScrollMetrics startingMetrics = defaultMetrics.copyWith(
        maxScrollExtent: maxExtent,
        viewportDimension: viewportDimension,
      );
      const Size size = Size(600, viewportDimension);
      const double minLen = 0;

      const List<double> margins = <double> [-10, 1, viewportDimension/2 - 0.01];
      for (final double margin in margins) {
        painter = _buildPainter(
          mainAxisMargin: margin,
          minLength: minLen,
          scrollMetrics: defaultMetrics,
        );

        // Overscroll to double.negativeInfinity (top).
        painter.update(
          startingMetrics.copyWith(pixels: double.negativeInfinity),
          startingMetrics.axisDirection,
        );

        painter.paint(testCanvas, size);
        expect(captureRect().top, margin);

        // Overscroll to double.infinity (down).
        painter.update(
          startingMetrics.copyWith(pixels: double.infinity),
          startingMetrics.axisDirection,
        );

        painter.paint(testCanvas, size);
        expect(size.height - captureRect().bottom, margin);
      }
    },
  );

  test(
    'crossAxisMargin & text direction are respected',
    () {
      const double viewportDimension = 23;
      const double maxExtent = 100;
      final ScrollMetrics startingMetrics = defaultMetrics.copyWith(
        maxScrollExtent: maxExtent,
        viewportDimension: viewportDimension,
      );
      const Size size = Size(600, viewportDimension);
      const double margin = 4;

      for (final TextDirection textDirection in TextDirection.values) {
        painter = _buildPainter(
          crossAxisMargin: margin,
          scrollMetrics: startingMetrics,
          textDirection: textDirection,
        );

        for (final AxisDirection direction in AxisDirection.values) {
          painter.update(
            startingMetrics.copyWith(axisDirection: direction),
            direction,
          );

          painter.paint(testCanvas, size);
          final Rect rect = captureRect();

          switch (direction) {
            case AxisDirection.up:
            case AxisDirection.down:
              expect(
                margin,
                textDirection == TextDirection.ltr
                  ? size.width - rect.right
                  : rect.left,
              );
              break;
            case AxisDirection.left:
            case AxisDirection.right:
              expect(margin, size.height - rect.bottom);
              break;
          }
        }
      }
    },
  );

  test('scrollbarOrientation are respected', () {
    const double viewportDimension = 23;
    const double maxExtent = 100;
    final ScrollMetrics startingMetrics = defaultMetrics.copyWith(
      maxScrollExtent: maxExtent,
      viewportDimension: viewportDimension,
    );
    const Size size = Size(600, viewportDimension);
    const double margin = 0;

    for (final ScrollbarOrientation scrollbarOrientation in ScrollbarOrientation.values) {
      final AxisDirection axisDirection;
      if (scrollbarOrientation == ScrollbarOrientation.left || scrollbarOrientation == ScrollbarOrientation.right)
        axisDirection = AxisDirection.down;
      else
        axisDirection = AxisDirection.right;

      painter = _buildPainter(
        crossAxisMargin: margin,
        scrollMetrics: startingMetrics,
        scrollbarOrientation: scrollbarOrientation,
      );

      painter.update(
        startingMetrics.copyWith(axisDirection: axisDirection),
        axisDirection
      );

      painter.paint(testCanvas, size);
      final Rect rect = captureRect();

      switch (scrollbarOrientation) {
        case ScrollbarOrientation.left:
          expect(rect.left, 0);
          expect(rect.top, 0);
          expect(rect.right, _kThickness);
          expect(rect.bottom, _kMinThumbExtent);
          break;
        case ScrollbarOrientation.right:
          expect(rect.left, 600 - _kThickness);
          expect(rect.top, 0);
          expect(rect.right, 600);
          expect(rect.bottom, _kMinThumbExtent);
          break;
        case ScrollbarOrientation.top:
          expect(rect.left, 0);
          expect(rect.top, 0);
          expect(rect.right, _kMinThumbExtent);
          expect(rect.bottom, _kThickness);
          break;
        case ScrollbarOrientation.bottom:
          expect(rect.left, 0);
          expect(rect.top, 23 - _kThickness);
          expect(rect.right, _kMinThumbExtent);
          expect(rect.bottom, 23);
          break;
      }
    }
  });

  test('scrollbarOrientation default values are correct', () {
    const double viewportDimension = 23;
    const double maxExtent = 100;
    final ScrollMetrics startingMetrics = defaultMetrics.copyWith(
      maxScrollExtent: maxExtent,
      viewportDimension: viewportDimension,
    );
    const Size size = Size(600, viewportDimension);
    const double margin = 0;
    Rect rect;

    // Vertical scroll with TextDirection.ltr
    painter = _buildPainter(
      crossAxisMargin: margin,
      scrollMetrics: startingMetrics,
      textDirection: TextDirection.ltr,
    );
    painter.update(
      startingMetrics.copyWith(axisDirection: AxisDirection.down),
      AxisDirection.down
    );
    painter.paint(testCanvas, size);
    rect = captureRect();
    expect(rect.left, 600 - _kThickness);
    expect(rect.top, 0);
    expect(rect.right, 600);
    expect(rect.bottom, _kMinThumbExtent);

    // Vertical scroll with TextDirection.rtl
    painter = _buildPainter(
      crossAxisMargin: margin,
      scrollMetrics: startingMetrics,
      textDirection: TextDirection.rtl,
    );
    painter.update(
      startingMetrics.copyWith(axisDirection: AxisDirection.down),
      AxisDirection.down
    );
    painter.paint(testCanvas, size);
    rect = captureRect();
    expect(rect.left, 0);
    expect(rect.top, 0);
    expect(rect.right, _kThickness);
    expect(rect.bottom, _kMinThumbExtent);

    // Horizontal scroll
    painter = _buildPainter(
      crossAxisMargin: margin,
      scrollMetrics: startingMetrics,
    );
    painter.update(
      startingMetrics.copyWith(axisDirection: AxisDirection.right),
      AxisDirection.right,
    );
    painter.paint(testCanvas, size);
    rect = captureRect();
    expect(rect.left, 0);
    expect(rect.top, 23 - _kThickness);
    expect(rect.right, _kMinThumbExtent);
    expect(rect.bottom, 23);
  });

  group('Padding works for all scroll directions', () {
    const EdgeInsets padding = EdgeInsets.fromLTRB(1, 2, 3, 4);
    const Size size = Size(60, 80);
    final ScrollMetrics metrics = defaultMetrics.copyWith(
      minScrollExtent: -100,
      maxScrollExtent: 240,
      axisDirection: AxisDirection.down,
    );

    final ScrollbarPainter painter = _buildPainter(
      padding: padding,
      scrollMetrics: metrics,
    );

    testWidgets('down', (WidgetTester tester) async {
      painter.update(
        metrics.copyWith(
          viewportDimension: size.height,
          pixels: double.negativeInfinity,
        ),
        AxisDirection.down,
      );

      // Top overscroll.
      painter.paint(testCanvas, size);
      final Rect rect0 = captureRect();
      expect(rect0.top, padding.top);
      expect(size.width - rect0.right, padding.right);

      // Bottom overscroll.
      painter.update(
        metrics.copyWith(
          viewportDimension: size.height,
          pixels: double.infinity,
        ),
        AxisDirection.down,
      );

      painter.paint(testCanvas, size);
      final Rect rect1 = captureRect();
      expect(size.height - rect1.bottom, padding.bottom);
      expect(size.width - rect1.right, padding.right);
    });

    testWidgets('up', (WidgetTester tester) async {
      painter.update(
        metrics.copyWith(
          viewportDimension: size.height,
          pixels: double.infinity,
          axisDirection: AxisDirection.up,
        ),
        AxisDirection.up,
      );

      // Top overscroll.
      painter.paint(testCanvas, size);
      final Rect rect0 = captureRect();
      expect(rect0.top, padding.top);
      expect(size.width - rect0.right, padding.right);

      // Bottom overscroll.
      painter.update(
        metrics.copyWith(
          viewportDimension: size.height,
          pixels: double.negativeInfinity,
          axisDirection: AxisDirection.up,
        ),
        AxisDirection.up,
      );

      painter.paint(testCanvas, size);
      final Rect rect1 = captureRect();
      expect(size.height - rect1.bottom, padding.bottom);
      expect(size.width - rect1.right, padding.right);
    });

    testWidgets('left', (WidgetTester tester) async {
      painter.update(
        metrics.copyWith(
          viewportDimension: size.width,
          pixels: double.negativeInfinity,
          axisDirection: AxisDirection.left,
        ),
        AxisDirection.left,
      );

      // Right overscroll.
      painter.paint(testCanvas, size);
      final Rect rect0 = captureRect();
      expect(size.height - rect0.bottom, padding.bottom);
      expect(size.width - rect0.right, padding.right);

      // Left overscroll.
      painter.update(
        metrics.copyWith(
          viewportDimension: size.width,
          pixels: double.infinity,
          axisDirection: AxisDirection.left,
        ),
        AxisDirection.left,
      );

      painter.paint(testCanvas, size);
      final Rect rect1 = captureRect();
      expect(size.height - rect1.bottom, padding.bottom);
      expect(rect1.left, padding.left);
    });

    testWidgets('right', (WidgetTester tester) async {
      painter.update(
        metrics.copyWith(
          viewportDimension: size.width,
          pixels: double.infinity,
          axisDirection: AxisDirection.right,
        ),
        AxisDirection.right,
      );

      // Right overscroll.
      painter.paint(testCanvas, size);
      final Rect rect0 = captureRect();
      expect(size.height - rect0.bottom, padding.bottom);
      expect(size.width - rect0.right, padding.right);

      // Left overscroll.
      painter.update(
        metrics.copyWith(
          viewportDimension: size.width,
          pixels: double.negativeInfinity,
          axisDirection: AxisDirection.right,
        ),
        AxisDirection.right,
      );

      painter.paint(testCanvas, size);
      final Rect rect1 = captureRect();
      expect(size.height - rect1.bottom, padding.bottom);
      expect(rect1.left, padding.left);
    });
  });

  testWidgets('thumb resizes gradually on overscroll', (WidgetTester tester) async {
    const EdgeInsets padding = EdgeInsets.fromLTRB(1, 2, 3, 4);
    const Size size = Size(60, 300);
    final double scrollExtent = size.height * 10;
    final ScrollMetrics metrics = defaultMetrics.copyWith(
      minScrollExtent: 0,
      maxScrollExtent: scrollExtent,
      axisDirection: AxisDirection.down,
      viewportDimension: size.height,
    );

    const double minOverscrollLength = 8.0;
    final ScrollbarPainter painter = _buildPainter(
      padding: padding,
      scrollMetrics: metrics,
      minLength: 36.0,
      minOverscrollLength: 8.0,
    );

    // No overscroll gives a full sized thumb.
    painter.update(
      metrics.copyWith(
        pixels: 0.0,
      ),
      AxisDirection.down,
    );
    painter.paint(testCanvas, size);
    final double fullThumbExtent = captureRect().height;
    expect(fullThumbExtent, greaterThan(_kMinThumbExtent));

    // Scrolling to the middle also gives a full sized thumb.
    painter.update(
      metrics.copyWith(
        pixels: scrollExtent / 2,
      ),
      AxisDirection.down,
    );
    painter.paint(testCanvas, size);
    expect(captureRect().height, moreOrLessEquals(fullThumbExtent, epsilon: 1e-6));

    // Scrolling just to the very end also gives a full sized thumb.
    painter.update(
      metrics.copyWith(
        pixels: scrollExtent,
      ),
      AxisDirection.down,
    );
    painter.paint(testCanvas, size);
    expect(captureRect().height, moreOrLessEquals(fullThumbExtent, epsilon: 1e-6));

    // Scrolling just past the end shrinks the thumb slightly.
    painter.update(
      metrics.copyWith(
        pixels: scrollExtent * 1.001,
      ),
      AxisDirection.down,
    );
    painter.paint(testCanvas, size);
    expect(captureRect().height, moreOrLessEquals(fullThumbExtent, epsilon: 2.0));

    // Scrolling way past the end shrinks the thumb to minimum.
    painter.update(
      metrics.copyWith(
        pixels: double.infinity,
      ),
      AxisDirection.down,
    );
    painter.paint(testCanvas, size);
    expect(captureRect().height, minOverscrollLength);
  });

  test('should scroll towards the right direction',
    () {
      const Size size = Size(60, 80);
      const double maxScrollExtent = 240;
      const double minScrollExtent = -100;
      final ScrollMetrics startingMetrics = defaultMetrics.copyWith(
        minScrollExtent: minScrollExtent,
        maxScrollExtent: maxScrollExtent,
        axisDirection: AxisDirection.down,
        viewportDimension: size.height,
      );

      for (final double minLength in <double>[_kMinThumbExtent, double.infinity]) {
        // Disregard `minLength` and `minOverscrollLength` to keep
        // scroll direction correct, if needed
        painter = _buildPainter(
          minLength: minLength,
          minOverscrollLength: minLength,
          scrollMetrics: startingMetrics,
        );

        final Iterable<ScrollMetrics> metricsList = Iterable<ScrollMetrics>.generate(
          9999,
          (int index) => startingMetrics.copyWith(pixels: minScrollExtent + index * size.height / 3),
        )
        .takeWhile((ScrollMetrics metrics) => !metrics.outOfRange);

        Rect? previousRect;

        for (final ScrollMetrics metrics in metricsList) {
          painter.update(metrics, metrics.axisDirection);
          painter.paint(testCanvas, size);
          final Rect rect = captureRect();
          if (previousRect != null) {
            if (rect.height == size.height) {
              // Size of the scrollbar is too large for the view port
              expect(previousRect.top <= rect.top, true);
              expect(previousRect.bottom <= rect.bottom, true);
            } else {
              // The scrollbar can fit in the view port.
              expect(previousRect.top < rect.top, true);
              expect(previousRect.bottom < rect.bottom, true);
            }
          }

          previousRect = rect;
        }
      }
    },
  );

  testWidgets('ScrollbarPainter asserts if no TextDirection has been provided', (WidgetTester tester) async {
    final ScrollbarPainter painter = ScrollbarPainter(
      color: _kScrollbarColor,
      fadeoutOpacityAnimation: kAlwaysCompleteAnimation,
    );
    const Size size = Size(60, 80);
    final ScrollMetrics scrollMetrics = defaultMetrics.copyWith(
      maxScrollExtent: 100000,
      viewportDimension: size.height,
    );
    painter.update(scrollMetrics, scrollMetrics.axisDirection);
    // Try to paint the scrollbar
    try {
      painter.paint(testCanvas, size);
    } on AssertionError catch (error) {
      expect(error.message, 'A TextDirection must be provided before a Scrollbar can be painted.');
    }
  });

  testWidgets('Tapping the track area pages the Scroll View', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: RawScrollbar(
            isAlwaysShown: true,
            controller: scrollController,
            child: SingleChildScrollView(
              controller: scrollController,
              child: const SizedBox(width: 1000.0, height: 1000.0),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(scrollController.offset, 0.0);
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 360.0),
          color: const Color(0x66BCBCBC),
        ),
    );

    // Tap on the track area below the thumb.
    await tester.tapAt(const Offset(796.0, 550.0));
    await tester.pumpAndSettle();

    expect(scrollController.offset, 400.0);
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 240.0, 800.0, 600.0),
          color: const Color(0x66BCBCBC),
      ),
    );

    // Tap on the track area above the thumb.
    await tester.tapAt(const Offset(796.0, 50.0));
    await tester.pumpAndSettle();

    expect(scrollController.offset, 0.0);
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 360.0),
          color: const Color(0x66BCBCBC),
      ),
    );
  });

  testWidgets('Scrollbar never goes away until finger lift', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(),
          child: RawScrollbar(
            child: SingleChildScrollView(
              child: SizedBox(width: 4000.0, height: 4000.0),
            ),
          ),
        ),
      ),
    );
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(SingleChildScrollView)));
    await gesture.moveBy(const Offset(0.0, -20.0));
    await tester.pump();
    // Scrollbar fully showing
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 3.0, 800.0, 93.0),
          color: const Color(0x66BCBCBC),
      ),
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
    // Still there.
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 3.0, 800.0, 93.0),
          color: const Color(0x66BCBCBC),
      ),
    );

    await gesture.up();
    await tester.pump(_kScrollbarTimeToFade);
    await tester.pump(_kScrollbarFadeDuration * 0.5);

    // Opacity going down now.
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 3.0, 800.0, 93.0),
          color: const Color(0x4fbcbcbc),
      ),
    );
  });

  testWidgets('Scrollbar does not fade away while hovering', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(),
          child: RawScrollbar(
            child: SingleChildScrollView(
              child: SizedBox(width: 4000.0, height: 4000.0),
            ),
          ),
        ),
      ),
    );
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(SingleChildScrollView)));
    await gesture.moveBy(const Offset(0.0, -20.0));
    await tester.pump();
    // Scrollbar fully showing
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 3.0, 800.0, 93.0),
          color: const Color(0x66BCBCBC),
      ),
    );

    final TestPointer testPointer = TestPointer(1, ui.PointerDeviceKind.mouse);
    // Hover over the thumb to prevent the scrollbar from fading out.
    testPointer.hover(const Offset(790.0, 5.0));
    await gesture.up();
    await tester.pump(const Duration(seconds: 3));

    // Still there.
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 3.0, 800.0, 93.0),
          color: const Color(0x66BCBCBC),
      ),
    );
  });

  testWidgets('Scrollbar will fade back in when hovering over known track area', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(),
          child: RawScrollbar(
            child: SingleChildScrollView(
              child: SizedBox(width: 4000.0, height: 4000.0),
            ),
          ),
        ),
      ),
    );
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(SingleChildScrollView)));
    await gesture.moveBy(const Offset(0.0, -20.0));
    await tester.pump();
    // Scrollbar fully showing
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 3.0, 800.0, 93.0),
          color: const Color(0x66BCBCBC),
        ),
    );
    await gesture.up();
    await tester.pump(_kScrollbarTimeToFade);
    await tester.pump(_kScrollbarFadeDuration * 0.5);

    // Scrollbar is fading out
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 3.0, 800.0, 93.0),
          color: const Color(0x4fbcbcbc),
        ),
    );

    // Hover over scrollbar with mouse to bring opacity back up
    final TestGesture mouseGesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouseGesture.addPointer();
    addTearDown(mouseGesture.removePointer);
    await mouseGesture.moveTo(const Offset(794.0, 5.0));
    await tester.pumpAndSettle();
    // Scrollbar should be visible
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 3.0, 800.0, 93.0),
          color: const Color(0x66BCBCBC),
        ),
    );
  });

  testWidgets('Scrollbar thumb can be dragged', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: PrimaryScrollController(
            controller: scrollController,
            child: RawScrollbar(
              isAlwaysShown: true,
              controller: scrollController,
              child: const SingleChildScrollView(
                child: SizedBox(width: 4000.0, height: 4000.0),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(scrollController.offset, 0.0);
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 90.0),
          color: const Color(0x66BCBCBC),
      ),
    );

    // Drag the thumb down to scroll down.
    const double scrollAmount = 10.0;
    final TestGesture dragScrollbarGesture = await tester.startGesture(const Offset(797.0, 45.0));
    await tester.pumpAndSettle();
    await dragScrollbarGesture.moveBy(const Offset(0.0, scrollAmount));
    await tester.pumpAndSettle();
    await dragScrollbarGesture.up();
    await tester.pumpAndSettle();

    // The view has scrolled more than it would have by a swipe gesture of the
    // same distance.
    expect(scrollController.offset, greaterThan(scrollAmount * 2));
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 10.0, 800.0, 100.0),
          color: const Color(0x66BCBCBC),
      ),
    );
  });

  testWidgets('Scrollbar thumb cannot be dragged into overscroll if the physics do not allow', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: PrimaryScrollController(
            controller: scrollController,
            child: RawScrollbar(
              isAlwaysShown: true,
              controller: scrollController,
              child: const SingleChildScrollView(
                child: SizedBox(width: 4000.0, height: 4000.0),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(scrollController.offset, 0.0);
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 90.0),
          color: const Color(0x66BCBCBC),
        ),
    );

    // Try to drag the thumb into overscroll.
    const double scrollAmount = -10.0;
    final TestGesture dragScrollbarGesture = await tester.startGesture(const Offset(797.0, 45.0));
    await tester.pumpAndSettle();
    await dragScrollbarGesture.moveBy(const Offset(0.0, scrollAmount));
    await tester.pumpAndSettle();

    // The physics should not have allowed us to enter overscroll.
    expect(scrollController.offset, 0.0);
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 90.0),
          color: const Color(0x66BCBCBC),
        ),
    );
  });

  // Regression test for https://github.com/flutter/flutter/issues/66444
  testWidgets("RawScrollbar doesn't show when scroll the inner scrollable widget", (WidgetTester tester) async {
    final GlobalKey key1 = GlobalKey();
    final GlobalKey key2 = GlobalKey();
    final GlobalKey outerKey = GlobalKey();
    final GlobalKey innerKey = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: RawScrollbar(
            key: key2,
            thumbColor: const Color(0x11111111),
            child: SingleChildScrollView(
              key: outerKey,
              child: SizedBox(
                height: 1000.0,
                width: double.infinity,
                child: Column(
                  children: <Widget>[
                    RawScrollbar(
                      key: key1,
                      thumbColor: const Color(0x22222222),
                      child: SizedBox(
                        height: 300.0,
                        width: double.infinity,
                        child: SingleChildScrollView(
                          key: innerKey,
                          child: const SizedBox(
                            key: Key('Inner scrollable'),
                            height: 1000.0,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Drag the inner scrollable widget.
    await tester.drag(find.byKey(innerKey), const Offset(0.0, -25.0));
    await tester.pump();
    // Scrollbar fully showing.
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      tester.renderObject(find.byKey(key2)),
      paintsExactlyCountTimes(#drawRect, 2), // Each bar will call [drawRect] twice.
    );

    expect(
      tester.renderObject(find.byKey(key1)),
      paintsExactlyCountTimes(#drawRect, 2),
    );
  });

  testWidgets('Scrollbar hit test area adjusts for PointerDeviceKind', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: PrimaryScrollController(
            controller: scrollController,
            child: RawScrollbar(
              isAlwaysShown: true,
              controller: scrollController,
              child: const SingleChildScrollView(
                child: SizedBox(width: 4000.0, height: 4000.0),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(scrollController.offset, 0.0);
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 90.0),
          color: const Color(0x66BCBCBC),
        ),
    );

    // Drag the scrollbar just outside of the painted thumb with touch input.
    // The hit test area is padded to meet the minimum interactive size.
    const double scrollAmount = 10.0;
    final TestGesture dragScrollbarGesture = await tester.startGesture(const Offset(790.0, 45.0));
    await tester.pumpAndSettle();
    await dragScrollbarGesture.moveBy(const Offset(0.0, scrollAmount));
    await tester.pumpAndSettle();

    // The scrollbar moved by scrollAmount, and the scrollOffset moved forward.
    expect(scrollController.offset, greaterThan(0.0));
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 10.0, 800.0, 100.0),
          color: const Color(0x66BCBCBC),
        ),
    );

    // Move back to reset.
    await dragScrollbarGesture.moveBy(const Offset(0.0, -scrollAmount));
    await tester.pumpAndSettle();
    await dragScrollbarGesture.up();
    expect(scrollController.offset, 0.0);
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 90.0),
          color: const Color(0x66BCBCBC),
        ),
    );

    // The same should not be possible with a mouse since it is more precise,
    // the padding it not necessary.
    final TestGesture gesture = await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.down(const Offset(790.0, 45.0));
    await tester.pump();
    await gesture.moveTo(const Offset(790.0, 55.0));
    await gesture.up();
    await tester.pumpAndSettle();
    // The scrollbar/scrollable should not have moved.
    expect(scrollController.offset, 0.0);
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 90.0),
          color: const Color(0x66BCBCBC),
        ),
    );
  });

  testWidgets('RawScrollbar.isAlwaysShown asserts that a ScrollPosition is attached', (WidgetTester tester) async {
    final FlutterExceptionHandler? handler = FlutterError.onError;
    FlutterErrorDetails? error;
    FlutterError.onError = (FlutterErrorDetails details) {
      error = details;
    };

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: RawScrollbar(
            isAlwaysShown: true,
            controller: ScrollController(),
            thumbColor: const Color(0x11111111),
            child: const SingleChildScrollView(
              child: SizedBox(
                height: 1000.0,
                width: 50.0,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(error, isNotNull);
    final AssertionError exception = error!.exception as AssertionError;
    expect(
      exception.message,
      contains("The Scrollbar's ScrollController has no ScrollPosition attached."),
    );

    FlutterError.onError = handler;
  });

  testWidgets('Interactive scrollbars should have a valid scroll controller', (WidgetTester tester) async {
    final ScrollController primaryScrollController = ScrollController();
    final ScrollController scrollController = ScrollController();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: PrimaryScrollController(
            controller: primaryScrollController,
              child: RawScrollbar(
                child: SingleChildScrollView(
                controller: scrollController,
                child: const SizedBox(
                  height: 1000.0,
                  width: 1000.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    AssertionError? exception = tester.takeException() as AssertionError?;
    // The scrollbar is not visible and cannot be interacted with, so no assertion.
    expect(exception, isNull);
    // Scroll to trigger the scrollbar to come into view.
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(SingleChildScrollView)));
    await gesture.moveBy(const Offset(0.0, -20.0));
    exception = tester.takeException() as AssertionError;
    expect(exception, isAssertionError);
    expect(
      exception.message,
      contains("The Scrollbar's ScrollController has no ScrollPosition attached."),
    );
  });

  testWidgets('Simultaneous dragging and pointer scrolling does not cause a crash', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/70105
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: PrimaryScrollController(
            controller: scrollController,
            child: RawScrollbar(
              isAlwaysShown: true,
              controller: scrollController,
              child: const SingleChildScrollView(
                child: SizedBox(width: 4000.0, height: 4000.0),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(scrollController.offset, 0.0);
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(
          rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0),
          color: const Color(0x00000000),
        )
        ..line(
          p1: const Offset(794.0, 0.0),
          p2: const Offset(794.0, 600.0),
          strokeWidth: 1.0,
          color: const Color(0x00000000),
        )
        ..rect(
          rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 90.0),
          color: const Color(0x66bcbcbc),
        ),
    );

    // Drag the thumb down to scroll down.
    const double scrollAmount = 10.0;
    final TestGesture dragScrollbarGesture = await tester.startGesture(const Offset(797.0, 45.0));
    await tester.pumpAndSettle();

    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(
          rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0),
          color: const Color(0x00000000),
        )
        ..line(
          p1: const Offset(794.0, 0.0),
          p2: const Offset(794.0, 600.0),
          strokeWidth: 1.0,
          color: const Color(0x00000000),
        )
        ..rect(
          rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 90.0),
          // Drag color
          color: const Color(0x66bcbcbc),
        ),
    );

    await dragScrollbarGesture.moveBy(const Offset(0.0, scrollAmount));
    await tester.pumpAndSettle();
    expect(scrollController.offset, greaterThan(10.0));
    final double previousOffset = scrollController.offset;
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(
          rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0),
          color: const Color(0x00000000),
        )
        ..line(
          p1: const Offset(794.0, 0.0),
          p2: const Offset(794.0, 600.0),
          strokeWidth: 1.0,
          color: const Color(0x00000000),
        )
        ..rect(
          rect: const Rect.fromLTRB(794.0, 10.0, 800.0, 100.0),
          color: const Color(0x66bcbcbc),
        ),
    );

    // Execute a pointer scroll while dragging (drag gesture has not come up yet)
    final TestPointer pointer = TestPointer(1, ui.PointerDeviceKind.mouse);
    pointer.hover(const Offset(798.0, 15.0));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0.0, 20.0)));
    await tester.pumpAndSettle();
    // Scrolling while holding the drag on the scrollbar and still hovered over
    // the scrollbar should not have changed the scroll offset.
    expect(pointer.location, const Offset(798.0, 15.0));
    expect(scrollController.offset, previousOffset);
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(
          rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0),
          color: const Color(0x00000000),
        )
        ..line(
          p1: const Offset(794.0, 0.0),
          p2: const Offset(794.0, 600.0),
          strokeWidth: 1.0,
          color: const Color(0x00000000),
        )
        ..rect(
          rect: const Rect.fromLTRB(794.0, 10.0, 800.0, 100.0),
          color: const Color(0x66bcbcbc),
        ),
    );

    // Drag is still being held, move pointer to be hovering over another area
    // of the scrollable (not over the scrollbar) and execute another pointer scroll
    pointer.hover(tester.getCenter(find.byType(SingleChildScrollView)));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0.0, -70.0)));
    await tester.pumpAndSettle();
    // Scrolling while holding the drag on the scrollbar changed the offset
    expect(pointer.location, const Offset(400.0, 300.0));
    expect(scrollController.offset, 0.0);
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(
          rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0),
          color: const Color(0x00000000),
        )
        ..line(
          p1: const Offset(794.0, 0.0),
          p2: const Offset(794.0, 600.0),
          strokeWidth: 1.0,
          color: const Color(0x00000000),
        )
        ..rect(
          rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 90.0),
          color: const Color(0x66bcbcbc),
        ),
    );

    await dragScrollbarGesture.up();
    await tester.pumpAndSettle();
    expect(scrollController.offset, 0.0);
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(
          rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0),
          color: const Color(0x00000000),
        )
        ..line(
          p1: const Offset(794.0, 0.0),
          p2: const Offset(794.0, 600.0),
          strokeWidth: 1.0,
          color: const Color(0x00000000),
        )
        ..rect(
          rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 90.0),
          color: const Color(0x66bcbcbc),
        ),
    );
  });

  testWidgets('Scrollbar thumb can be dragged in reverse', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: PrimaryScrollController(
            controller: scrollController,
            child: RawScrollbar(
              isAlwaysShown: true,
              controller: scrollController,
              child: const SingleChildScrollView(
                reverse: true,
                child: SizedBox(width: 4000.0, height: 4000.0),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(scrollController.offset, 0.0);
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 510.0, 800.0, 600.0),
          color: const Color(0x66BCBCBC),
        ),
    );

    // Drag the thumb up to scroll up.
    const double scrollAmount = 10.0;
    final TestGesture dragScrollbarGesture = await tester.startGesture(const Offset(797.0, 550.0));
    await tester.pumpAndSettle();
    await dragScrollbarGesture.moveBy(const Offset(0.0, -scrollAmount));
    await tester.pumpAndSettle();
    await dragScrollbarGesture.up();
    await tester.pumpAndSettle();

    // The view has scrolled more than it would have by a swipe gesture of the
    // same distance.
    expect(scrollController.offset, greaterThan(scrollAmount * 2));
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 500.0, 800.0, 590.0),
          color: const Color(0x66BCBCBC),
        ),
    );
  });

  testWidgets('ScrollbarPainter asserts if scrollbarOrientation is used with wrong axisDirection', (WidgetTester tester) async {
    final ScrollbarPainter painter = ScrollbarPainter(
      color: _kScrollbarColor,
      fadeoutOpacityAnimation: kAlwaysCompleteAnimation,
      textDirection: TextDirection.ltr,
      scrollbarOrientation: ScrollbarOrientation.left,
    );
    const Size size = Size(60, 80);
    final ScrollMetrics scrollMetrics = defaultMetrics.copyWith(
      maxScrollExtent: 100,
      viewportDimension: size.height,
      axisDirection: AxisDirection.right,
    );
    painter.update(scrollMetrics, scrollMetrics.axisDirection);

    expect(() => painter.paint(testCanvas, size), throwsA(isA<AssertionError>()));
  });

  testWidgets('RawScrollbar mainAxisMargin property works properly', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: RawScrollbar(
            mainAxisMargin: 10,
            isAlwaysShown: true,
            controller: scrollController,
            child: SingleChildScrollView(
              controller: scrollController,
              child: const SizedBox(width: 1000.0, height: 1000.0),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(scrollController.offset, 0.0);
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 580.0))
        ..rect(rect: const Rect.fromLTRB(794.0, 10.0, 800.0, 358.0))
    );
  });

  testWidgets('shape property of RawScrollbar can draw a BeveledRectangleBorder', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: RawScrollbar(
            shape: const BeveledRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8.0))
            ),
            controller: scrollController,
            isAlwaysShown: true,
            child: SingleChildScrollView(
              controller: scrollController,
              child: const SizedBox(height: 1000.0),
            ),
          ),
        )));
    await tester.pumpAndSettle();
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..path(
          includes: const <Offset>[
            Offset(797.0, 0.0),
            Offset(797.0, 18.0),
          ],
          excludes: const <Offset>[
            Offset(796.0, 0.0),
            Offset(798.0, 0.0),
          ],
        ),
    );
  });

  testWidgets('minThumbLength property of RawScrollbar is respected', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: RawScrollbar(
            controller: scrollController,
            minThumbLength: 21,
            minOverscrollLength: 8,
            isAlwaysShown: true,
            child: SingleChildScrollView(
              controller: scrollController,
              child: const SizedBox(width: 1000.0, height: 50000.0),
            ),
          ),
        )));
    await tester.pumpAndSettle();
    expect(
        find.byType(RawScrollbar),
        paints
          ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0)) // track
          ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 21.0))); // thumb
  });

  testWidgets('shape property of RawScrollbar can draw a CircleBorder', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: RawScrollbar(
            shape: const CircleBorder(side: BorderSide(width: 2.0)),
            thickness: 36.0,
            controller: scrollController,
            isAlwaysShown: true,
            child: SingleChildScrollView(
              controller: scrollController,
              child: const SizedBox(height: 1000.0, width: 1000),
            ),
          ),
        )));
    await tester.pumpAndSettle();

    expect(
      find.byType(RawScrollbar),
      paints
        ..path(
          includes: const <Offset>[
            Offset(782.0, 180.0),
            Offset(782.0, 180.0 - 18.0),
            Offset(782.0 + 18.0, 180),
            Offset(782.0, 180.0 + 18.0),
            Offset(782.0 - 18.0, 180),
          ],
        )
        ..circle(x: 782.0, y: 180.0, radius: 17.0, strokeWidth: 2.0)
    );
  });

  testWidgets('crossAxisMargin property of RawScrollbar is respected', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: RawScrollbar(
            controller: scrollController,
            crossAxisMargin: 30,
            isAlwaysShown: true,
            child: SingleChildScrollView(
              controller: scrollController,
              child: const SizedBox(width: 1000.0, height: 1000.0),
            ),
          ),
        )));
    await tester.pumpAndSettle();
    expect(
        find.byType(RawScrollbar),
        paints
          ..rect(rect: const Rect.fromLTRB(734.0, 0.0, 800.0, 600.0))
          ..rect(rect: const Rect.fromLTRB(764.0, 0.0, 770.0, 360.0)));
  });

  testWidgets('shape property of RawScrollbar can draw a RoundedRectangleBorder', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: RawScrollbar(
            thickness: 20,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(8))),
            controller: scrollController,
            isAlwaysShown: true,
            child: SingleChildScrollView(
              controller: scrollController,
              child: const SizedBox(height: 1000.0, width: 1000.0),
            ),
          ),
        )));
    await tester.pumpAndSettle();
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(780.0, 0.0, 800.0, 600.0))
        ..path(
          includes: const <Offset>[
            Offset(800.0, 0.0),
          ],
          excludes: const <Offset>[
            Offset(780.0, 0.0),
          ],
        ),
    );
  });

  testWidgets('minOverscrollLength property of RawScrollbar is respected', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: RawScrollbar(
            controller: scrollController,
            isAlwaysShown: true,
            minOverscrollLength: 8.0,
            minThumbLength: 36.0,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              controller: scrollController,
              child: const SizedBox(height: 10000),
            )
          ),
        )
      )
    );
    await tester.pumpAndSettle();
    final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(RawScrollbar)));
    await gesture.moveBy(const Offset(0, 1000));
    await tester.pump();
    expect(
        find.byType(RawScrollbar),
        paints
          ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
          ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 8.0)));
  });

  testWidgets('not passing any shape or radius to RawScrollbar will draw the usual rectangular thumb', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: RawScrollbar(
            controller: scrollController,
            isAlwaysShown: true,
            child: SingleChildScrollView(
              controller: scrollController,
              child: const SizedBox(height: 1000.0),
            ),
          ),
        )));
    await tester.pumpAndSettle();

    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 360.0))
    );
  });

  testWidgets('The bar can show or hide when the viewport size change', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    Widget buildFrame(double height) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: RawScrollbar(
            controller: scrollController,
            isAlwaysShown: true,
            child: SingleChildScrollView(
                controller: scrollController,
                child: SizedBox(width: double.infinity, height: height)
            ),
          ),
        ),
      );
    }
    await tester.pumpWidget(buildFrame(600.0));
    await tester.pumpAndSettle();
    expect(find.byType(RawScrollbar), isNot(paints..rect())); // Not shown.

    await tester.pumpWidget(buildFrame(600.1));
    await tester.pumpAndSettle();
    expect(find.byType(RawScrollbar), paints..rect()..rect()); // Show the bar.

    await tester.pumpWidget(buildFrame(600.0));
    await tester.pumpAndSettle();
    expect(find.byType(RawScrollbar), isNot(paints..rect())); // Hide the bar.
  });

  testWidgets('The bar can show or hide when the window size change', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    Widget buildFrame() {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: PrimaryScrollController(
            controller: scrollController,
            child: RawScrollbar(
              isAlwaysShown: true,
              controller: scrollController,
              child: const SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  height: 600.0,
                ),
              ),
            ),
          ),
        ),
      );
    }
    tester.binding.window.physicalSizeTestValue = const Size(800.0, 600.0);
    tester.binding.window.devicePixelRatioTestValue = 1;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);

    await tester.pumpWidget(buildFrame());
    await tester.pumpAndSettle();
    expect(scrollController.offset, 0.0);
    expect(find.byType(RawScrollbar), isNot(paints..rect())); // Not shown.

    tester.binding.window.physicalSizeTestValue = const Size(800.0, 599.0);
    await tester.pumpAndSettle();
    expect(find.byType(RawScrollbar), paints..rect()..rect()); // Show the bar.

    tester.binding.window.physicalSizeTestValue = const Size(800.0, 600.0);
    await tester.pumpAndSettle();
    expect(find.byType(RawScrollbar), isNot(paints..rect())); // Not shown.
  });

  testWidgets('Scrollbar will not flip axes based on notification is there is a scroll controller', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/87697
    final ScrollController verticalScrollController = ScrollController();
    final ScrollController horizontalScrollController = ScrollController();
    Widget buildFrame() {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: RawScrollbar(
            isAlwaysShown: true,
            controller: verticalScrollController,
            // This scrollbar will receive scroll notifications from both nested
            // scroll views of opposite axes, but should stay on the vertical
            // axis that its scroll controller is associated with.
            notificationPredicate: (ScrollNotification notification) => notification.depth <= 1,
            child: SingleChildScrollView(
              controller: verticalScrollController,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: horizontalScrollController,
                child: const SizedBox(
                  width: 1000.0,
                  height: 1000.0,
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame());
    await tester.pumpAndSettle();
    expect(verticalScrollController.offset, 0.0);
    expect(horizontalScrollController.offset, 0.0);
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 360.0),
          color: const Color(0x66BCBCBC),
        ),
    );

    // Move the horizontal scroll view. The vertical scrollbar should not flip.
    horizontalScrollController.jumpTo(10.0);
    expect(verticalScrollController.offset, 0.0);
    expect(horizontalScrollController.offset, 10.0);
    expect(
      find.byType(RawScrollbar),
      paints
        ..rect(rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 600.0))
        ..rect(
          rect: const Rect.fromLTRB(794.0, 0.0, 800.0, 360.0),
          color: const Color(0x66BCBCBC),
        ),
    );
  });

  testWidgets('notificationPredicate depth test.', (WidgetTester tester) async {
    final ScrollController scrollController = ScrollController();
    final List<int> depths = <int>[];
    Widget buildFrame() {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: RawScrollbar(
            notificationPredicate: (ScrollNotification notification) {
              depths.add(notification.depth);
              return notification.depth == 0;
            },
            controller: scrollController,
            isAlwaysShown: true,
            child: SingleChildScrollView(
              controller: scrollController,
              child: const SingleChildScrollView(),
            ),
          ),
        ),
      );
    }
    await tester.pumpWidget(buildFrame());
    await tester.pumpAndSettle();

    // `notificationPredicate` should be called twice with different `depth`
    // because there are two scrollable widgets.
    expect(depths.length, 2);
    expect(depths[0], 1);
    expect(depths[1], 0);
  });
}
