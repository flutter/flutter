// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

import 'text_scuba.dart';

typedef PaintTest = void Function(RecordingCanvas recordingCanvas);

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

/// Whether we are running on iOS Safari.
// TODO(mdebbar): https://github.com/flutter/flutter/issues/66656
bool get isIosSafari => browserEngine == BrowserEngine.webkit &&
          operatingSystem == OperatingSystem.iOs;

Future<void> testMain() async {
  final EngineScubaTester scuba = await EngineScubaTester.initialize(
    viewportSize: const Size(600, 600),
  );


  setUpStableTestFonts();

  testEachCanvas('draws paragraphs with placeholders', (EngineCanvas canvas) {
    const Rect screenRect = Rect.fromLTWH(0, 0, 600, 600);
    final RecordingCanvas recordingCanvas = RecordingCanvas(screenRect);

    Offset offset = Offset.zero;
    for (final PlaceholderAlignment placeholderAlignment
        in PlaceholderAlignment.values) {
      _paintTextWithPlaceholder(
        recordingCanvas,
        offset,
        before: 'Lorem ipsum',
        after: 'dolor sit amet, consectetur.',
        placeholderAlignment: placeholderAlignment,
      );
      offset = offset.translate(0.0, 80.0);
    }
    recordingCanvas.endRecording();
    recordingCanvas.apply(canvas, screenRect);
    if (!isIosSafari) {
      return scuba.diffCanvasScreenshot(canvas, 'text_with_placeholders');
    }
  });

  testEachCanvas('text alignment and placeholders', (EngineCanvas canvas) {
    const Rect screenRect = Rect.fromLTWH(0, 0, 600, 600);
    final RecordingCanvas recordingCanvas = RecordingCanvas(screenRect);

    Offset offset = Offset.zero;
    _paintTextWithPlaceholder(
      recordingCanvas,
      offset,
      before: 'Lorem',
      after: 'ipsum.',
      textAlignment: TextAlign.start,
    );
    offset = offset.translate(0.0, 80.0);
    _paintTextWithPlaceholder(
      recordingCanvas,
      offset,
      before: 'Lorem',
      after: 'ipsum.',
      textAlignment: TextAlign.center,
    );
    offset = offset.translate(0.0, 80.0);
    _paintTextWithPlaceholder(
      recordingCanvas,
      offset,
      before: 'Lorem',
      after: 'ipsum.',
      textAlignment: TextAlign.end,
    );
    recordingCanvas.endRecording();
    recordingCanvas.apply(canvas, screenRect);
    return scuba.diffCanvasScreenshot(canvas, 'text_align_with_placeholders');
  });
}

const Color black = Color(0xFF000000);
const Color blue = Color(0xFF0000FF);
const Color red = Color(0xFFFF0000);

const Size placeholderSize = Size(80.0, 50.0);

void _paintTextWithPlaceholder(
  RecordingCanvas canvas,
  Offset offset, {
  required String before,
  required String after,
  PlaceholderAlignment placeholderAlignment = PlaceholderAlignment.baseline,
  TextAlign textAlignment = TextAlign.left,
}) {
  // First let's draw the paragraph.
  final Paragraph paragraph = _createParagraphWithPlaceholder(
    before,
    after,
    placeholderAlignment,
    textAlignment,
  );
  canvas.drawParagraph(paragraph, offset);

  // Then fill the placeholders.
  final TextBox placeholderBox = paragraph.getBoxesForPlaceholders().single;
  canvas.drawRect(
    placeholderBox.toRect().shift(offset),
    SurfacePaint()..color = red,
  );
}

Paragraph _createParagraphWithPlaceholder(
  String before,
  String after,
  PlaceholderAlignment placeholderAlignment,
  TextAlign textAlignment,
) {
  final ParagraphBuilder builder =
      ParagraphBuilder(ParagraphStyle(textAlign: textAlignment));
  builder
      .pushStyle(TextStyle(color: black, fontFamily: 'Roboto', fontSize: 14));
  builder.addText(before);
  builder.addPlaceholder(
    placeholderSize.width,
    placeholderSize.height,
    placeholderAlignment,
    baselineOffset: 40.0,
    baseline: TextBaseline.alphabetic,
  );
  builder.pushStyle(TextStyle(color: blue, fontFamily: 'Roboto', fontSize: 14));
  builder.addText(after);
  return builder.build()..layout(const ParagraphConstraints(width: 200.0));
}
