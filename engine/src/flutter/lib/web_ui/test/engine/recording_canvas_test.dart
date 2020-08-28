// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart';
import 'package:ui/src/engine.dart';

import '../mock_engine_canvas.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  RecordingCanvas underTest;
  MockEngineCanvas mockCanvas;
  final Rect screenRect = Rect.largest;

  setUp(() {
    underTest = RecordingCanvas(screenRect);
    mockCanvas = MockEngineCanvas();
  });

  group('drawDRRect', () {
    final RRect rrect = RRect.fromLTRBR(10, 10, 50, 50, Radius.circular(3));
    final SurfacePaint somePaint = SurfacePaint()
      ..color = const Color(0xFFFF0000);

    test('Happy case', () {
      underTest.drawDRRect(rrect, rrect.deflate(1), somePaint);
      underTest.endRecording();
      underTest.apply(mockCanvas, screenRect);

      _expectDrawDRRectCall(mockCanvas, <String, dynamic>{
        'path':
            'Path(MoveTo(10, 47) LineTo(10, 13) Conic(10, 10, 10, 13, w = 0.7071067690849304) LineTo(47, 10) Conic(50, 10, 10, 50, w = 0.7071067690849304) LineTo(50, 47) Conic(50, 50, 50, 47, w = 0.7071067690849304) LineTo(13, 50) Conic(10, 50, 50, 10, w = 0.7071067690849304) Close() MoveTo(11, 47) LineTo(11, 13) Conic(11, 11, 11, 13, w = 0.7071067690849304) LineTo(47, 11) Conic(49, 11, 11, 49, w = 0.7071067690849304) LineTo(49, 47) Conic(49, 49, 49, 47, w = 0.7071067690849304) LineTo(13, 49) Conic(11, 49, 49, 11, w = 0.7071067690849304) Close())',
        'paint': somePaint.paintData,
      });
    });

    test('Inner RRect > Outer RRect', () {
      underTest.drawDRRect(rrect, rrect.inflate(1), somePaint);
      underTest.endRecording();
      underTest.apply(mockCanvas, screenRect);
      // Expect nothing to be called
      expect(mockCanvas.methodCallLog.length, equals(1));
      expect(mockCanvas.methodCallLog.single.methodName, 'endOfPaint');
    });

    test('Inner RRect not completely inside Outer RRect', () {
      underTest.drawDRRect(
          rrect, rrect.deflate(1).shift(const Offset(0.0, 10)), somePaint);
      underTest.endRecording();
      underTest.apply(mockCanvas, screenRect);
      // Expect nothing to be called
      expect(mockCanvas.methodCallLog.length, equals(1));
      expect(mockCanvas.methodCallLog.single.methodName, 'endOfPaint');
    });

    test('Inner RRect same as Outer RRect', () {
      underTest.drawDRRect(rrect, rrect, somePaint);
      underTest.endRecording();
      underTest.apply(mockCanvas, screenRect);
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
      underTest.endRecording();
      underTest.apply(mockCanvas, screenRect);

      // Expect to draw, even when inner has negative radii (which get ignored by canvas)
      _expectDrawDRRectCall(mockCanvas, <String, dynamic>{
        'path':
            'Path(MoveTo(0, 42) LineTo(0, 6) Conic(0, 0, 0, 6, w = 0.7071067690849304) LineTo(88, 0) Conic(88, 0, 0, 88, w = 0.7071067690849304) LineTo(88, 48) Conic(88, 48, 48, 88, w = 0.7071067690849304) LineTo(6, 48) Conic(0, 48, 48, 0, w = 0.7071067690849304) Close() MoveTo(1, 42) LineTo(1, 6) Conic(1, 1, 1, 6, w = 0.7071067690849304) LineTo(87, 1) Conic(87, 1, 1, 87, w = 0.7071067690849304) LineTo(87, 47) Conic(87, 47, 47, 87, w = 0.7071067690849304) LineTo(6, 47) Conic(1, 47, 47, 1, w = 0.7071067690849304) Close())',
        'paint': somePaint.paintData,
      });
    });

    test('preserve old scuba test behavior', () {
      final RRect outer =
          RRect.fromRectAndCorners(const Rect.fromLTRB(10, 20, 30, 40));
      final RRect inner =
          RRect.fromRectAndCorners(const Rect.fromLTRB(12, 22, 28, 38));

      underTest.drawDRRect(outer, inner, somePaint);
      underTest.endRecording();
      underTest.apply(mockCanvas, screenRect);

      _expectDrawDRRectCall(mockCanvas, <String, dynamic>{
        'path':
            'Path(MoveTo(10, 20) LineTo(30, 20) LineTo(30, 40) LineTo(10, 40) Close() MoveTo(12, 22) LineTo(28, 22) LineTo(28, 38) LineTo(12, 38) Close())',
        'paint': somePaint.paintData,
      });
    });
  });

  test('Filters out paint commands outside the clip rect', () {
    // Outside to the left
    underTest.drawRect(Rect.fromLTWH(0.0, 20.0, 10.0, 10.0), Paint());

    // Outside above
    underTest.drawRect(Rect.fromLTWH(20.0, 0.0, 10.0, 10.0), Paint());

    // Visible
    underTest.drawRect(Rect.fromLTWH(20.0, 20.0, 10.0, 10.0), Paint());

    // Inside the layer clip rect but zero-size
    underTest.drawRect(Rect.fromLTRB(20.0, 20.0, 30.0, 20.0), Paint());

    // Inside the layer clip but clipped out by a canvas clip
    underTest.save();
    underTest.clipRect(Rect.fromLTWH(0, 0, 10, 10), ClipOp.intersect);
    underTest.drawRect(Rect.fromLTWH(20.0, 20.0, 10.0, 10.0), Paint());
    underTest.restore();

    // Outside to the right
    underTest.drawRect(Rect.fromLTWH(40.0, 20.0, 10.0, 10.0), Paint());

    // Outside below
    underTest.drawRect(Rect.fromLTWH(20.0, 40.0, 10.0, 10.0), Paint());

    underTest.endRecording();

    expect(underTest.debugPaintCommands, hasLength(10));
    final PaintDrawRect outsideLeft = underTest.debugPaintCommands[0];
    expect(outsideLeft.isClippedOut, false);
    expect(outsideLeft.leftBound, 0);
    expect(outsideLeft.topBound, 20);
    expect(outsideLeft.rightBound, 10);
    expect(outsideLeft.bottomBound, 30);

    final PaintDrawRect outsideAbove = underTest.debugPaintCommands[1];
    expect(outsideAbove.isClippedOut, false);

    final PaintDrawRect visible = underTest.debugPaintCommands[2];
    expect(visible.isClippedOut, false);

    final PaintDrawRect zeroSize = underTest.debugPaintCommands[3];
    expect(zeroSize.isClippedOut, true);

    expect(underTest.debugPaintCommands[4], isA<PaintSave>());

    final PaintClipRect clip = underTest.debugPaintCommands[5];
    expect(clip.isClippedOut, false);

    final PaintDrawRect clippedOut = underTest.debugPaintCommands[6];
    expect(clippedOut.isClippedOut, true);

    expect(underTest.debugPaintCommands[7], isA<PaintRestore>());

    final PaintDrawRect outsideRight = underTest.debugPaintCommands[8];
    expect(outsideRight.isClippedOut, false);

    final PaintDrawRect outsideBelow = underTest.debugPaintCommands[9];
    expect(outsideBelow.isClippedOut, false);

    // Give it the entire screen so everything paints.
    underTest.apply(mockCanvas, screenRect);
    expect(mockCanvas.methodCallLog, hasLength(11));
    expect(mockCanvas.methodCallLog[0].methodName, 'drawRect');
    expect(mockCanvas.methodCallLog[1].methodName, 'drawRect');
    expect(mockCanvas.methodCallLog[2].methodName, 'drawRect');
    expect(mockCanvas.methodCallLog[3].methodName, 'drawRect');
    expect(mockCanvas.methodCallLog[4].methodName, 'save');
    expect(mockCanvas.methodCallLog[5].methodName, 'clipRect');
    expect(mockCanvas.methodCallLog[6].methodName, 'drawRect');
    expect(mockCanvas.methodCallLog[7].methodName, 'restore');
    expect(mockCanvas.methodCallLog[8].methodName, 'drawRect');
    expect(mockCanvas.methodCallLog[9].methodName, 'drawRect');
    expect(mockCanvas.methodCallLog[10].methodName, 'endOfPaint');

    // Clip out a middle region that only contains 'drawRect'
    mockCanvas.methodCallLog.clear();
    underTest.apply(mockCanvas, Rect.fromLTRB(15, 15, 35, 35));
    expect(mockCanvas.methodCallLog, hasLength(4));
    expect(mockCanvas.methodCallLog[0].methodName, 'drawRect');
    expect(mockCanvas.methodCallLog[1].methodName, 'save');
    expect(mockCanvas.methodCallLog[2].methodName, 'restore');
    expect(mockCanvas.methodCallLog[3].methodName, 'endOfPaint');
  });

  // Regression test for https://github.com/flutter/flutter/issues/61697.
  test('Allows restore calls after recording has ended', () {
    final RecordingCanvas rc = RecordingCanvas(Rect.fromLTRB(0, 0, 200, 400));
    rc.endRecording();
    // Should not throw exception on restore.
    expect(() => rc.restore(), returnsNormally);
  });

  // Regression test for https://github.com/flutter/flutter/issues/61697.
  test('Allows restore calls even if recording is not ended', () {
    final RecordingCanvas rc = RecordingCanvas(Rect.fromLTRB(0, 0, 200, 400));
    // Should not throw exception on restore.
    expect(() => rc.restore(), returnsNormally);
  });
}

// Expect a drawDRRect call to be registered in the mock call log, with the expectedArguments
void _expectDrawDRRectCall(
    MockEngineCanvas mock, Map<String, dynamic> expectedArguments) {
  expect(mock.methodCallLog.length, equals(2));
  MockCanvasCall mockCall = mock.methodCallLog[0];
  expect(mockCall.methodName, equals('drawPath'));
  Map<String, dynamic> argMap = mockCall.arguments as Map<String, dynamic>;
  Map<String, dynamic> argContents = <String, dynamic>{};
  argMap.forEach((String key, dynamic value) {
    argContents[key] = value is SurfacePath ? value.toString() : value;
  });
  expect(argContents, equals(expectedArguments));
}
