// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'package:test/test.dart';

import 'mock_engine_canvas.dart';

void main() {
  setUpAll(() {
    WebExperiments.ensureInitialized();
  });

  group('EngineCanvas', () {
    MockEngineCanvas mockCanvas;
    ui.Paragraph paragraph;

    void testCanvas(
        String description, void Function(EngineCanvas canvas) testFn,
        {ui.Rect canvasSize, ui.VoidCallback whenDone}) {
      canvasSize ??= const ui.Rect.fromLTWH(0, 0, 100, 100);
      test(description, () {
        testFn(BitmapCanvas(canvasSize));
        testFn(DomCanvas());
        testFn(mockCanvas = MockEngineCanvas());
        if (whenDone != null) {
          whenDone();
        }
      });
    }

    testCanvas('draws laid out paragraph', (EngineCanvas canvas) {
      final ui.Rect screenRect = const ui.Rect.fromLTWH(0, 0, 100, 100);
      final RecordingCanvas recordingCanvas = RecordingCanvas(screenRect);
      final ui.ParagraphBuilder builder =
          ui.ParagraphBuilder(ui.ParagraphStyle());
      builder.addText('sample');
      paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 100));
      recordingCanvas.drawParagraph(paragraph, const ui.Offset(10, 10));
      recordingCanvas.endRecording();
      canvas.clear();
      recordingCanvas.apply(canvas, screenRect);
    }, whenDone: () {
      expect(mockCanvas.methodCallLog, hasLength(3));

      MockCanvasCall call = mockCanvas.methodCallLog[0];
      expect(call.methodName, 'clear');

      call = mockCanvas.methodCallLog[1];
      expect(call.methodName, 'drawParagraph');
      expect(call.arguments['paragraph'], paragraph);
      expect(call.arguments['offset'], const ui.Offset(10, 10));
    });

    testCanvas('ignores paragraphs that were not laid out',
        (EngineCanvas canvas) {
      final ui.Rect screenRect = const ui.Rect.fromLTWH(0, 0, 100, 100);
      final RecordingCanvas recordingCanvas = RecordingCanvas(screenRect);
      final ui.ParagraphBuilder builder =
          ui.ParagraphBuilder(ui.ParagraphStyle());
      builder.addText('sample');
      final ui.Paragraph paragraph = builder.build();
      recordingCanvas.drawParagraph(paragraph, const ui.Offset(10, 10));
      recordingCanvas.endRecording();
      canvas.clear();
      recordingCanvas.apply(canvas, screenRect);
    }, whenDone: () {
      expect(mockCanvas.methodCallLog, hasLength(2));
      expect(mockCanvas.methodCallLog[0].methodName, 'clear');
      expect(mockCanvas.methodCallLog[1].methodName, 'endOfPaint');
    });
  });
}
