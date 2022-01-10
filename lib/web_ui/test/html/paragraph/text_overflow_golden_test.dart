// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/bootstrap/browser.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' hide window;

import 'text_scuba.dart';

typedef CanvasTest = FutureOr<void> Function(EngineCanvas canvas);

const String threeLines = 'First\nSecond\nThird';
const String veryLong =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.';
const String longUnbreakable = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  final EngineScubaTester scuba = await EngineScubaTester.initialize(
    viewportSize: const Size(800, 800),
  );

  setUpStableTestFonts();

  testEachCanvas('maxLines clipping', (EngineCanvas canvas) {
    Offset offset = Offset.zero;
    CanvasParagraph p;

    // All three lines are rendered.
    p = paragraph(threeLines);
    canvas.drawParagraph(p, offset);
    offset = offset.translate(0, p.height + 10);

    // Only the first two lines are rendered.
    p = paragraph(threeLines, paragraphStyle: ParagraphStyle(maxLines: 2));
    canvas.drawParagraph(p, offset);
    offset = offset.translate(0, p.height + 10);

    // The whole text is rendered.
    p = paragraph(veryLong, maxWidth: 200);
    canvas.drawParagraph(p, offset);
    offset = offset.translate(0, p.height + 10);

    // Only the first two lines are rendered.
    p = paragraph(veryLong,
        paragraphStyle: ParagraphStyle(maxLines: 2), maxWidth: 200);
    canvas.drawParagraph(p, offset);
    offset = offset.translate(0, p.height + 10);

    return scuba.diffCanvasScreenshot(canvas, 'text_max_lines');
  });
}
