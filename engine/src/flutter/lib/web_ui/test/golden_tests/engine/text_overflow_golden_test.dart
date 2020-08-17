// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';

import 'package:test/bootstrap/browser.dart';
import 'package:ui/ui.dart' hide window;
import 'package:ui/src/engine.dart';

import 'scuba.dart';

typedef CanvasTest = FutureOr<void> Function(EngineCanvas canvas);

const String threeLines = 'First\nSecond\nThird';
const String veryLongWithShortPrefix =
    'Lorem ipsum dolor\nsit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.';
const String veryLongWithShortSuffix =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et\ndolore magna aliqua.';
const String veryLong =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.';
const String longUnbreakable = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() async {
  final EngineScubaTester scuba = await EngineScubaTester.initialize(
    viewportSize: const Size(800, 800),
  );

  final TextStyle warningStyle = TextStyle(
    color: const Color(0xFFFF0000),
    fontFamily: 'Roboto',
    fontSize: 10,
  );

  setUpStableTestFonts();

  Paragraph warning(String text) {
    return paragraph(text, textStyle: warningStyle);
  }

  testEachCanvas('maxLines clipping', (EngineCanvas canvas) {
    Offset offset = Offset.zero;
    Paragraph p;

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

  testEachCanvas('maxLines with overflow', (EngineCanvas canvas) {
    Offset offset = Offset.zero;
    Paragraph p;

    // Only the first line is rendered with no ellipsis because the first line
    // doesn't overflow.
    p = paragraph(
      threeLines,
      paragraphStyle: ParagraphStyle(ellipsis: '...'),
    );
    canvas.drawParagraph(p, offset);
    offset = offset.translate(0, p.height + 10);

    // The first two lines are rendered with an ellipsis on the 2nd line.
    p = paragraph(
      veryLongWithShortPrefix,
      paragraphStyle: ParagraphStyle(ellipsis: '...'),
      maxWidth: 200,
    );
    canvas.drawParagraph(p, offset);
    offset = offset.translate(0, p.height + 10);

    // Only the first line is rendered with an ellipsis.
    if (!WebExperiments.instance.useCanvasText) {
      // This is now correct with the canvas-based measurement, so we shouldn't
      // print the "(wrong)" warning.
      p = warning('(wrong)');
      canvas.drawParagraph(p, offset);
      offset = offset.translate(0, p.height);
    }
    p = paragraph(
      veryLongWithShortSuffix,
      paragraphStyle: ParagraphStyle(ellipsis: '...'),
      maxWidth: 200,
    );
    canvas.drawParagraph(p, offset);
    offset = offset.translate(0, p.height + 10);

    // Only the first two lines are rendered and the ellipsis appears on the 2nd
    // line.
    if (!WebExperiments.instance.useCanvasText) {
      // This is now correct with the canvas-based measurement, so we shouldn't
      // print the "(wrong)" warning.
      p = warning('(wrong)');
      canvas.drawParagraph(p, offset);
      offset = offset.translate(0, p.height);
    }
    p = paragraph(
      veryLong,
      paragraphStyle: ParagraphStyle(maxLines: 2, ellipsis: '...'),
      maxWidth: 200,
    );
    canvas.drawParagraph(p, offset);
    offset = offset.translate(0, p.height + 10);

    return scuba.diffCanvasScreenshot(canvas, 'text_max_lines_with_ellipsis');
  });

  testEachCanvas('long unbreakable text', (EngineCanvas canvas) {
    Offset offset = Offset.zero;
    Paragraph p;

    // The whole line is rendered unbroken when there are no constraints.
    p = paragraph(longUnbreakable);
    canvas.drawParagraph(p, offset);
    offset = offset.translate(0, p.height + 10);

    // The whole line is rendered with an ellipsis.
    p = paragraph(
      longUnbreakable,
      paragraphStyle: ParagraphStyle(ellipsis: '...'),
      maxWidth: 200,
    );
    canvas.drawParagraph(p, offset);
    offset = offset.translate(0, p.height + 10);

    // The text is broken into multiple lines.
    p = paragraph(longUnbreakable, maxWidth: 200);
    canvas.drawParagraph(p, offset);
    offset = offset.translate(0, p.height + 10);

    // Very narrow constraint (less than one character's width).
    p = paragraph('AA', maxWidth: 7);
    canvas.drawParagraph(p, offset);
    offset = offset.translate(0, p.height + 10);

    return scuba.diffCanvasScreenshot(canvas, 'text_long_unbreakable');
  });
}
