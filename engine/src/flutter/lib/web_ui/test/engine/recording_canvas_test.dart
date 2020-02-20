// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'package:ui/ui.dart';
import 'package:ui/src/engine.dart';
import 'package:test/test.dart';

import '../mock_engine_canvas.dart';

void main() {
  RecordingCanvas underTest;
  MockEngineCanvas mockCanvas;

  setUp(() {
    underTest = RecordingCanvas(Rect.largest);
    mockCanvas = MockEngineCanvas();
  });

  group('drawDRRect', () {
    final RRect rrect = RRect.fromLTRBR(10, 10, 50, 50, Radius.circular(3));
    final SurfacePaint somePaint = SurfacePaint()
      ..color = const Color(0xFFFF0000);

    test('Happy case', () {
      underTest.drawDRRect(rrect, rrect.deflate(1), somePaint);
      underTest.apply(mockCanvas);

      _expectDrawCall(mockCanvas, {
        'outer': rrect,
        'inner': rrect.deflate(1),
        'paint': somePaint.paintData,
      });
    });

    test('Inner RRect > Outer RRect', () {
      underTest.drawDRRect(rrect, rrect.inflate(1), somePaint);
      underTest.apply(mockCanvas);
      // Expect nothing to be called
      expect(mockCanvas.methodCallLog.length, equals(1));
      expect(mockCanvas.methodCallLog.single.methodName, 'endOfPaint');
    });

    test('Inner RRect not completely inside Outer RRect', () {
      underTest.drawDRRect(
          rrect, rrect.deflate(1).shift(const Offset(0.0, 10)), somePaint);
      underTest.apply(mockCanvas);
      // Expect nothing to be called
      expect(mockCanvas.methodCallLog.length, equals(1));
      expect(mockCanvas.methodCallLog.single.methodName, 'endOfPaint');
    });

    test('Inner RRect same as Outer RRect', () {
      underTest.drawDRRect(rrect, rrect, somePaint);
      underTest.apply(mockCanvas);
      // Expect nothing to be called
      expect(mockCanvas.methodCallLog.length, equals(1));
      expect(mockCanvas.methodCallLog.single.methodName, 'endOfPaint');
    });

    test('negative corners in inner RRect get passed through to draw', () {
      // This comes from github issue #40728
      final RRect outer = RRect.fromRectAndCorners(
          const Rect.fromLTWH(0, 0, 88, 48),
          topLeft: Radius.circular(6),
          bottomLeft: Radius.circular(6));
      final RRect inner = outer.deflate(1);

      // If these assertions fail, check [_measureBorderRadius] in recording_canvas.dart
      expect(inner.brRadius, equals(Radius.circular(-1)));
      expect(inner.trRadius, equals(Radius.circular(-1)));

      underTest.drawDRRect(outer, inner, somePaint);
      underTest.apply(mockCanvas);

      // Expect to draw, even when inner has negative radii (which get ignored by canvas)
      _expectDrawCall(mockCanvas, {
        'outer': outer,
        'inner': inner,
        'paint': somePaint.paintData,
      });
    });

    test('preserve old scuba test behavior', () {
      final RRect outer =
          RRect.fromRectAndCorners(const Rect.fromLTRB(10, 20, 30, 40));
      final RRect inner =
          RRect.fromRectAndCorners(const Rect.fromLTRB(12, 22, 28, 38));

      underTest.drawDRRect(outer, inner, somePaint);
      underTest.apply(mockCanvas);

      _expectDrawCall(mockCanvas, {
        'outer': outer,
        'inner': inner,
        'paint': somePaint.paintData,
      });
    });
  });
}

// Expect a drawDRRect call to be registered in the mock call log, with the expectedArguments
void _expectDrawCall(
    MockEngineCanvas mock, Map<String, dynamic> expectedArguments) {
  expect(mock.methodCallLog.length, equals(2));
  MockCanvasCall mockCall = mock.methodCallLog[0];
  expect(mockCall.methodName, equals('drawDRRect'));
  expect(mockCall.arguments, equals(expectedArguments));
}
