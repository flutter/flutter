// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
// import 'package:image/image.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

import 'scuba.dart';

typedef PaintTest = void Function(RecordingCanvas recordingCanvas);

void main() async {
  final EngineScubaTester scuba = await EngineScubaTester.initialize(
    viewportSize: const Size(600, 600),
  );

  setUpStableTestFonts();

  testEachCanvas('draws paragraphs with placeholders', (EngineCanvas canvas) {
    final Rect screenRect = const Rect.fromLTWH(0, 0, 600, 600);
    final RecordingCanvas recordingCanvas = RecordingCanvas(screenRect);

    Offset offset = Offset.zero;
    for (PlaceholderAlignment alignment in PlaceholderAlignment.values) {
      _paintTextWithPlaceholder(recordingCanvas, offset, alignment);
      offset = offset.translate(0.0, 80.0);
    }
    recordingCanvas.endRecording();
    recordingCanvas.apply(canvas, screenRect);
    return scuba.diffCanvasScreenshot(canvas, 'text_with_placeholders');
  });
}

const Color black = Color(0xFF000000);
const Color blue = Color(0xFF0000FF);
const Color red = Color(0xFFFF0000);

const Size placeholderSize = Size(80.0, 50.0);

void _paintTextWithPlaceholder(
  RecordingCanvas canvas,
  Offset offset,
  PlaceholderAlignment alignment,
) {
  // First let's draw the paragraph.
  final Paragraph paragraph = _createParagraphWithPlaceholder(alignment);
  canvas.drawParagraph(paragraph, offset);

  // Then fill the placeholders.
  final TextBox placeholderBox = paragraph.getBoxesForPlaceholders().single;
  canvas.drawRect(
    placeholderBox.toRect().shift(offset),
    Paint()..color = red,
  );
}

Paragraph _createParagraphWithPlaceholder(PlaceholderAlignment alignment) {
  final ParagraphBuilder builder = ParagraphBuilder(ParagraphStyle());
  builder
      .pushStyle(TextStyle(color: black, fontFamily: 'Roboto', fontSize: 14));
  builder.addText('Lorem ipsum');
  builder.addPlaceholder(
    placeholderSize.width,
    placeholderSize.height,
    alignment,
    baselineOffset: 40.0,
    baseline: TextBaseline.alphabetic,
  );
  builder.pushStyle(TextStyle(color: blue, fontFamily: 'Roboto', fontSize: 14));
  builder.addText('dolor sit amet, consectetur.');
  return builder.build()..layout(ParagraphConstraints(width: 200.0));
}
