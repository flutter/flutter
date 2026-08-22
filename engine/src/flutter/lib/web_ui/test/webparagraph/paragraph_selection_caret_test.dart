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

  group('Caret & Selection Bounding Boxes Tests', () {
    test('Single-line selection boxes and caret position', () {
      final ui.Paragraph paragraph = buildParagraph('Hello');
      final List<ui.TextBox> fullBoxes = paragraph.getBoxesForRange(0, 5);

      expect(fullBoxes.length, 1);
      final ui.Rect box0 = fullBoxes[0].toRect();
      expect(box0.left, closeTo(0.0, precisionTolerance));
      expect(box0.right, closeTo(50.0, precisionTolerance));
      expect(box0.width, closeTo(50.0, precisionTolerance));

      // Partial selection 'ell' (range 1..4)
      final List<ui.TextBox> partialBoxes = paragraph.getBoxesForRange(1, 4);
      expect(partialBoxes.length, 1);
      final ui.Rect partial0 = partialBoxes[0].toRect();
      expect(partial0.left, closeTo(10.0, precisionTolerance));
      expect(partial0.right, closeTo(40.0, precisionTolerance));
      expect(partial0.width, closeTo(30.0, precisionTolerance));

      // Collapsed selection (caret position at index 3)
      final List<ui.TextBox> caretBoxes = paragraph.getBoxesForRange(3, 3);
      expect(caretBoxes.length, 0);
    });

    test(r'Multiline selection boxes spanning explicit newline (Hello\nWorld)', () {
      final ui.Paragraph paragraph = buildParagraph('Hello\nWorld');

      // Selection spanning 'llo\nWo' (range 2..8)
      final List<ui.TextBox> boxes = paragraph.getBoxesForRange(2, 8);
      expect(boxes.length, 2);

      // Line 0 box for 'llo\n' (range 2..6): should start at 20.0px and end at 50.0px (excluding \n)
      final ui.Rect box0 = boxes[0].toRect();
      expect(box0.left, closeTo(20.0, precisionTolerance));
      expect(box0.right, closeTo(50.0, precisionTolerance));
      expect(box0.width, closeTo(30.0, precisionTolerance));

      // Line 1 box for 'Wo' (range 6..8): should start at 0.0px and end at 20.0px
      final ui.Rect box1 = boxes[1].toRect();
      expect(box1.left, closeTo(0.0, precisionTolerance));
      expect(box1.right, closeTo(20.0, precisionTolerance));
      expect(box1.width, closeTo(20.0, precisionTolerance));
    });

    test(r'Selection boxes for text ending with newline (Hello\n)', () {
      final ui.Paragraph paragraph = buildParagraph('Hello\n');
      final List<ui.TextBox> boxes = paragraph.getBoxesForRange(0, 6);

      // Line 0 box for 'Hello\n' (range 0..6): box ends at rightmost character 'o' (50.0px)
      expect(boxes.length, 1);
      final ui.Rect box0 = boxes[0].toRect();
      expect(box0.left, closeTo(0.0, precisionTolerance));
      expect(box0.right, closeTo(50.0, precisionTolerance));
      expect(box0.width, closeTo(50.0, precisionTolerance));

      // Empty selection on line 1 (range 6..6)
      final List<ui.TextBox> line1CaretBoxes = paragraph.getBoxesForRange(6, 6);
      expect(line1CaretBoxes.length, 0);
    });

    test(r'Selection boxes for spaces before newline (Hello  \nWorld)', () {
      final ui.Paragraph paragraph = buildParagraph('Hello  \nWorld');
      // Selection for line 0 'Hello  \n' (range 0..8)
      final List<ui.TextBox> boxes = paragraph.getBoxesForRange(0, 8);

      expect(boxes.length, 1);
      // Line 0 box includes trailing spaces (70.0px) but excludes \n
      final ui.Rect box0 = boxes[0].toRect();
      expect(box0.left, closeTo(0.0, precisionTolerance));
      expect(box0.right, closeTo(70.0, precisionTolerance));
      expect(box0.width, closeTo(70.0, precisionTolerance));
    });

    test(r'Selection boxes for consecutive newlines (\n\n\n)', () {
      final ui.Paragraph paragraph = buildParagraph('\n\n\n');
      final List<ui.TextBox> boxes = paragraph.getBoxesForRange(0, 3);

      // Each newline has 0 width selection box on its line
      for (final box in boxes) {
        expect(box.toRect().width, closeTo(0.0, precisionTolerance));
      }
    });

    test(r'Selection boxes for leading newline (\nHello)', () {
      final ui.Paragraph paragraph = buildParagraph('\nHello');
      final List<ui.TextBox> line0Boxes = paragraph.getBoxesForRange(0, 1);

      // Line 0 is just \n -> 1 box of 0 width
      expect(line0Boxes.length, 1);
      expect(line0Boxes[0].toRect().width, closeTo(0.0, precisionTolerance));

      // Selection across line 0 and line 1 'Hel' (range 0..4)
      final List<ui.TextBox> fullBoxes = paragraph.getBoxesForRange(0, 4);
      expect(fullBoxes.length, 2);
      expect(fullBoxes[0].toRect().width, closeTo(0.0, precisionTolerance));
      final ui.Rect box1 = fullBoxes[1].toRect();
      expect(box1.left, closeTo(0.0, precisionTolerance));
      expect(box1.right, closeTo(30.0, precisionTolerance));
    });

    test(r'Caret hit-testing (getPositionForOffset) across lines', () {
      final ui.Paragraph paragraph = buildParagraph('Hello\nWorld');
      final double lineHeight = paragraph.height / 2;

      // Click at middle of line 0 ('Hel' at x=25.0px) -> maps to index 3 with upstream affinity in SkParagraph
      final ui.TextPosition posLine0 = paragraph.getPositionForOffset(
        ui.Offset(25.0, lineHeight / 2),
      );
      expect(posLine0.offset, 3);
      //expect(posLine0.affinity, ui.TextAffinity.upstream);

      // Click past right edge of line 0 ('Hello\n')
      final ui.TextPosition posPastLine0 = paragraph.getPositionForOffset(
        ui.Offset(100.0, lineHeight / 2),
      );
      expect(posPastLine0.offset, 5);
      expect(posPastLine0.affinity, ui.TextAffinity.upstream);

      // Click on line 1 ('World')
      final ui.TextPosition posLine1 = paragraph.getPositionForOffset(
        ui.Offset(20.0, lineHeight + lineHeight / 2),
      );
      expect(posLine1.offset, 8);
      //expect(posLine1.affinity, ui.TextAffinity.downstream);

      // Click above paragraph at x=25.0px -> hit-tests line 0 at x=25.0px (offset 3, upstream)
      final ui.TextPosition posAbove = paragraph.getPositionForOffset(const ui.Offset(25.0, -10.0));
      expect(posAbove.offset, 3);

      // Click below paragraph at x=25.0px -> hit-tests line 1 at x=25.0px (offset 9, upstream)
      final ui.TextPosition posBelow = paragraph.getPositionForOffset(
        ui.Offset(25.0, paragraph.height + 10.0),
      );
      expect(posBelow.offset, 9);
    });

    test(r'Caret hit-testing on empty trailing line (Hello\n)', () {
      final ui.Paragraph paragraph = buildParagraph('Hello\n');
      final double lineHeight = paragraph.height / 2;

      // Click on empty trailing line (line 1)
      final ui.TextPosition posLine1 = paragraph.getPositionForOffset(
        ui.Offset(10.0, lineHeight + lineHeight / 2),
      );
      expect(posLine1.offset, 6);
      expect(posLine1.affinity, ui.TextAffinity.downstream);
    });

    test('getLineBoundary queries for multiline text', () {
      final ui.Paragraph paragraph = buildParagraph('Hello\nWorld');

      // Position in line 0 -> boundary is TextRange(0, 5) in SkParagraph
      final ui.TextRange rangeLine0 = paragraph.getLineBoundary(const ui.TextPosition(offset: 2));
      expect(rangeLine0, const ui.TextRange(start: 0, end: 5));

      // Position at \n itself -> boundary is TextRange(0, 5)
      final ui.TextRange rangeNewline = paragraph.getLineBoundary(const ui.TextPosition(offset: 5));
      expect(rangeNewline, const ui.TextRange(start: 0, end: 5));

      // Position in line 1 -> boundary is TextRange(6, 11)
      final ui.TextRange rangeLine1 = paragraph.getLineBoundary(const ui.TextPosition(offset: 8));
      expect(rangeLine1, const ui.TextRange(start: 6, end: 11));
    });

    test(r'getLineBoundary on empty trailing line (Hello\n)', () {
      final ui.Paragraph paragraph = buildParagraph('Hello\n');
      // metric[0]: 0 6 5 6 6 true
      // metric[1]: 5 6 6 6 6 true

      // Line 0 boundary (0..6)
      final ui.TextRange rangeLine0 = paragraph.getLineBoundary(const ui.TextPosition(offset: 2));
      expect(rangeLine0, const ui.TextRange(start: 0, end: 6));

      // Position at offset 6 (empty trailing line after \n) -> TextRange(0, 6)
      final ui.TextRange rangeLine1 = paragraph.getLineBoundary(const ui.TextPosition(offset: 6));
      expect(rangeLine1, const ui.TextRange(start: 0, end: 6));
    });

    test(r'getGlyphInfoAt for regular character vs newline (\n)', () {
      final ui.Paragraph paragraph = buildParagraph('Hello\nWorld');

      // Glyph info for 'e' at index 1
      final ui.GlyphInfo? glyphE = paragraph.getGlyphInfoAt(1);
      expect(glyphE, isNotNull);
      expect(glyphE!.graphemeClusterLayoutBounds.left, closeTo(10.0, precisionTolerance));
      expect(glyphE.graphemeClusterLayoutBounds.width, closeTo(10.0, precisionTolerance));

      // Glyph info for \n at index 5
      final ui.GlyphInfo? glyphNewline = paragraph.getGlyphInfoAt(5);
      expect(glyphNewline, isNotNull);
      expect(glyphNewline!.graphemeClusterLayoutBounds.left, closeTo(50.0, precisionTolerance));
      expect(glyphNewline.graphemeClusterLayoutBounds.width, closeTo(0.0, precisionTolerance));
    });
  });
}
