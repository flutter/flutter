// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const double precisionTolerance = 0.001;

ui.Paragraph buildParagraph(
  String text, {
  double fontSize = 10.0,
  String fontFamily = 'FlutterTest',
  ui.TextDirection textDirection = ui.TextDirection.ltr,
  double maxConstraintsWidth = double.infinity,
}) {
  final paragraphStyle = ui.ParagraphStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    textDirection: textDirection,
  );
  final builder = ui.ParagraphBuilder(paragraphStyle);
  builder.addText(text);
  final ui.Paragraph paragraph = builder.build();
  paragraph.layout(ui.ParagraphConstraints(width: maxConstraintsWidth));
  return paragraph;
}

Future<void> testMain() async {
  setUpUnitTests(
    withImplicitView: true,
    setUpTestViewDimensions: false,
    testEnvironment: const ui_web.TestEnvironment(forceTestFonts: true),
  );

  group('Line Widths & Geometry Metrics Tests for WebParagraph', () {
    test('Single-line text width without trailing space or newline', () {
      // 'Hello' has 5 characters of fontSize 10.0 in FlutterTest font = 50.0px width
      final ui.Paragraph paragraph = buildParagraph('Hello');
      final List<ui.LineMetrics> metrics = paragraph.computeLineMetrics();

      expect(metrics.length, 1);
      expect(paragraph.numberOfLines, 1);
      // Last line of paragraph always has hardBreak = true per LineMetrics definition
      expect(metrics[0].hardBreak, isTrue);
      expect(metrics[0].lineNumber, 0);
      expect(metrics[0].width, closeTo(50.0, precisionTolerance));
      expect(metrics[0].width, closeTo(paragraph.longestLine, precisionTolerance));
    });

    test('Single-line text with trailing spaces', () {
      // 'Hello   ' has 5 letters + 3 spaces
      final ui.Paragraph pWithSpaces = buildParagraph('Hello   ');
      final ui.Paragraph pNoSpaces = buildParagraph('Hello');

      final List<ui.LineMetrics> metricsWithSpaces = pWithSpaces.computeLineMetrics();
      final List<ui.LineMetrics> metricsNoSpaces = pNoSpaces.computeLineMetrics();

      expect(metricsWithSpaces.length, 1);
      // longestLine excludes trailing spaces
      expect(pWithSpaces.longestLine, closeTo(50.0, precisionTolerance));
      expect(pWithSpaces.longestLine, closeTo(pNoSpaces.longestLine, precisionTolerance));
      // maxIntrinsicWidth includes trailing spaces (8 chars * 10 = 80.0)
      expect(pWithSpaces.maxIntrinsicWidth, closeTo(80.0, precisionTolerance));
      // LineMetrics.width excludes trailing spaces
      expect(metricsWithSpaces[0].width, closeTo(metricsNoSpaces[0].width, precisionTolerance));
    });

    test(r'Multiline text line width with explicit newline (\n)', () {
      final ui.Paragraph pMultiline = buildParagraph('Hello\nWorld');
      final ui.Paragraph pSingle = buildParagraph('Hello');

      final List<ui.LineMetrics> metricsMultiline = pMultiline.computeLineMetrics();
      final List<ui.LineMetrics> metricsSingle = pSingle.computeLineMetrics();

      expect(metricsMultiline.length, 2);
      expect(pMultiline.numberOfLines, 2);

      // Line 0 ends with \n so hardBreak is true. Line 1 is end of paragraph so hardBreak is also true.
      expect(metricsMultiline[0].hardBreak, isTrue);
      expect(metricsMultiline[1].hardBreak, isTrue);

      // Line 0 width of 'Hello\n' MUST equal width of single-line 'Hello' (50.0px)
      // (\n must NOT add width or extra space to line 0)
      expect(metricsMultiline[0].width, closeTo(50.0, precisionTolerance));
      expect(metricsMultiline[0].width, closeTo(metricsSingle[0].width, precisionTolerance));
    });

    test(r'Multiline text ending with newline (\n)', () {
      final ui.Paragraph pEndingNewline = buildParagraph('Hello\n');
      final ui.Paragraph pSingle = buildParagraph('Hello');

      final List<ui.LineMetrics> metricsEnding = pEndingNewline.computeLineMetrics();
      final List<ui.LineMetrics> metricsSingle = pSingle.computeLineMetrics();

      expect(metricsEnding.length, 2);
      expect(pEndingNewline.numberOfLines, 2);

      // Line 0 of 'Hello\n'
      expect(metricsEnding[0].hardBreak, isTrue);
      expect(metricsEnding[0].width, closeTo(50.0, precisionTolerance));
      expect(metricsEnding[0].width, closeTo(metricsSingle[0].width, precisionTolerance));

      // Line 1 is the empty line created by \n at end (last line of paragraph -> hardBreak is true)
      expect(metricsEnding[1].hardBreak, isTrue);
      expect(metricsEnding[1].width, 0.0);
    });

    test(r'Multiline text with spaces before newline (Hello  \nWorld)', () {
      final ui.Paragraph pSpacesBeforeNewline = buildParagraph('Hello  \nWorld');

      final List<ui.LineMetrics> metricsSpacesNL = pSpacesBeforeNewline.computeLineMetrics();

      expect(metricsSpacesNL.length, 2);
      expect(metricsSpacesNL[0].hardBreak, isTrue);

      // Line 0 width excludes trailing spaces on that line -> 50.0px for 'Hello'
      expect(metricsSpacesNL[0].width, closeTo(50.0, precisionTolerance));
    });

    test(r'Consecutive newlines (\n\n\n)', () {
      final ui.Paragraph pConsecutive = buildParagraph('Line1\n\nLine3');
      final List<ui.LineMetrics> metrics = pConsecutive.computeLineMetrics();

      expect(metrics.length, 3);
      expect(pConsecutive.numberOfLines, 3);

      expect(metrics[0].hardBreak, isTrue);
      expect(metrics[0].width, closeTo(50.0, precisionTolerance));

      expect(metrics[1].hardBreak, isTrue);
      expect(metrics[1].width, 0.0);

      expect(metrics[2].hardBreak, isTrue);
      expect(metrics[2].width, closeTo(50.0, precisionTolerance));
    });

    test(r'Leading newline (\nHello)', () {
      final ui.Paragraph pLeading = buildParagraph('\nHello');
      final List<ui.LineMetrics> metrics = pLeading.computeLineMetrics();

      expect(metrics.length, 2);
      expect(metrics[0].hardBreak, isTrue);
      expect(metrics[0].width, 0.0);

      expect(metrics[1].hardBreak, isTrue);
      expect(metrics[1].width, closeTo(50.0, precisionTolerance));
    });

    test(r'Single newline string (\n)', () {
      final ui.Paragraph pNL = buildParagraph('\n');
      final List<ui.LineMetrics> metrics = pNL.computeLineMetrics();

      expect(metrics.length, 2);
      expect(pNL.numberOfLines, 2);
      expect(metrics[0].hardBreak, isTrue);
      expect(metrics[0].width, 0.0);
      expect(metrics[1].hardBreak, isTrue);
      expect(metrics[1].width, 0.0);
    });

    test(r'getBoxesForRange box width for line ending in \n', () {
      final ui.Paragraph p = buildParagraph('Hello\nWorld');

      // Range (0, 5) -> 'Hello'
      final List<ui.TextBox> boxesTextOnly = p.getBoxesForRange(0, 5);
      // Range (0, 6) -> 'Hello\n'
      final List<ui.TextBox> boxesWithNewline = p.getBoxesForRange(0, 6);

      expect(boxesTextOnly.length, 1);

      // The right edge of the selection box for 'Hello\n' on line 0
      // should NOT extend beyond the right edge of 'Hello' (50.0px)
      final double textOnlyRight = boxesTextOnly.first.right;
      final double newlineRight = boxesWithNewline.first.right;

      expect(textOnlyRight, closeTo(50.0, precisionTolerance));
      expect(newlineRight, closeTo(50.0, precisionTolerance));
    });

    test(r'getBoxesForRange tight style on line ending in \n', () {
      final ui.Paragraph p = buildParagraph('Hello\nWorld');

      final List<ui.TextBox> tightBoxes = p.getBoxesForRange(0, 6);
      final List<ui.TextBox> helloTightBoxes = p.getBoxesForRange(0, 5);

      expect(
        tightBoxes.first.toRect().width,
        closeTo(helloTightBoxes.first.toRect().width, precisionTolerance),
      );
      expect(tightBoxes.first.toRect().width, closeTo(50.0, precisionTolerance));
    });

    test(r'getGlyphInfoAt for \n character', () {
      final ui.Paragraph p = buildParagraph('Hello\nWorld');

      final ui.GlyphInfo? newlineGlyph = p.getGlyphInfoAt(5); // index 5 is '\n'
      if (newlineGlyph != null) {
        // \n glyph cluster layout bounds width must be 0.0
        expect(newlineGlyph.graphemeClusterLayoutBounds.width, 0.0);
      }
    });

    test(r'longestLine and maxIntrinsicWidth for multiline with \n', () {
      final ui.Paragraph pShortNL = buildParagraph('Short\nLongerLine\nTiny');
      final ui.Paragraph pLongestSingle = buildParagraph('LongerLine');

      // 'LongerLine' has 10 chars * 10 = 100.0px
      expect(pShortNL.longestLine, closeTo(100.0, precisionTolerance));
      expect(pShortNL.longestLine, closeTo(pLongestSingle.longestLine, precisionTolerance));

      final ui.Paragraph pHelloNL = buildParagraph('Hello\n');
      expect(pHelloNL.longestLine, closeTo(50.0, precisionTolerance));
      expect(pHelloNL.maxIntrinsicWidth, closeTo(50.0, precisionTolerance));
    });

    test(r'getPositionForOffset to the right of line ending in \n', () {
      final ui.Paragraph p = buildParagraph('Hello\nWorld');

      // Tap far to the right on line 0 (x=100.0, y=5.0)
      final ui.TextPosition positionFarRight = p.getPositionForOffset(const ui.Offset(100.0, 5.0));

      // Should map to index 5 (end of line 0 before \n or at \n), NOT line 1
      expect(positionFarRight.offset, 5);
    });

    test(r'Soft break (auto-wrap) vs Hard break (\n) LineMetrics hardBreak flag', () {
      // Create paragraph that auto-wraps 'Hello World' with narrow constraint (60px)
      final ui.Paragraph pSoft = buildParagraph('Hello World', maxConstraintsWidth: 60.0);
      final List<ui.LineMetrics> softMetrics = pSoft.computeLineMetrics();

      if (softMetrics.length > 1) {
        // Line 0 is auto-wrapped (soft break), hardBreak MUST be false
        expect(softMetrics[0].hardBreak, isFalse);
      }

      // Hard break text
      final ui.Paragraph pHard = buildParagraph('Hello\nWorld');
      final List<ui.LineMetrics> hardMetrics = pHard.computeLineMetrics();
      expect(hardMetrics[0].hardBreak, isTrue);
    });

    test('Empty string paragraph line metrics', () {
      final ui.Paragraph pEmpty = buildParagraph('');
      final List<ui.LineMetrics> metrics = pEmpty.computeLineMetrics();

      expect(metrics.length, 0);
      expect(pEmpty.numberOfLines, 0);
      expect(pEmpty.getLineMetricsAt(0), isNull);
    });
  });
}
