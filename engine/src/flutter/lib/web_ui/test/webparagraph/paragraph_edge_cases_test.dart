// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/web_paragraph/layout.dart';
import 'package:ui/src/engine/web_paragraph/paragraph.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';

final ui.ParagraphStyle ahemStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests();

  group('Paragraph Newline Edge Cases', () {
    test('Trailing newline creates an additional empty line', () {
      final builder = ui.ParagraphBuilder(ahemStyle);
      builder.addText('Line 1\n');
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 500));

      final List<ui.LineMetrics> lines = paragraph.computeLineMetrics();
      expect(lines.length, 2);

      // Line 0: "Line 1\n"
      expect(lines[0].hardBreak, true);

      // Line 1: empty line created by trailing newline
      expect(lines[1].height, greaterThan(0));

      // Verify line boundaries via public API
      final ui.TextRange line0Boundary = paragraph.getLineBoundary(
        const ui.TextPosition(offset: 0),
      );
      expect(line0Boundary, const ui.TextRange(start: 0, end: 7));

      final ui.TextRange line1Boundary = paragraph.getLineBoundary(
        const ui.TextPosition(offset: 7),
      );
      expect(line1Boundary, const ui.TextRange(start: 0, end: 7));
    });

    test('Multiple consecutive newlines create corresponding empty lines', () {
      final builder = ui.ParagraphBuilder(ahemStyle);
      builder.addText('Hello\n\n\nWorld');
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 500));

      final List<ui.LineMetrics> lines = paragraph.computeLineMetrics();
      expect(lines.length, 4);

      expect(lines[0].hardBreak, true);
      expect(lines[1].hardBreak, true);
      expect(lines[2].hardBreak, true);

      expect(
        paragraph.getLineBoundary(const ui.TextPosition(offset: 0)),
        const ui.TextRange(start: 0, end: 5),
      );
      expect(
        paragraph.getLineBoundary(const ui.TextPosition(offset: 6)),
        const ui.TextRange(start: 6, end: 6),
      );
      expect(
        paragraph.getLineBoundary(const ui.TextPosition(offset: 7)),
        const ui.TextRange(start: 7, end: 7),
      );
      expect(
        paragraph.getLineBoundary(const ui.TextPosition(offset: 8)),
        const ui.TextRange(start: 8, end: 13),
      );
    });

    test('Trailing spaces before a hard newline', () {
      final builder = ui.ParagraphBuilder(ahemStyle);
      builder.addText('First   \nSecond');
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 500));

      final List<ui.LineMetrics> lines = paragraph.computeLineMetrics();
      expect(lines.length, 2);
      expect(lines[0].hardBreak, true);
    });
  });

  group('Paragraph getBoxesForRange Edge Cases', () {
    test('getBoxesForRange on zero-length range at trailing newline', () {
      final builder = ui.ParagraphBuilder(ahemStyle);
      builder.addText('Line 1\n');
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 500));

      // Query position at the empty line (offset 7)
      final List<ui.TextBox> boxes = paragraph.getBoxesForRange(
        7,
        7,
        boxHeightStyle: ui.BoxHeightStyle.max,
        boxWidthStyle: ui.BoxWidthStyle.max,
      );

      expect(boxes, isEmpty);
    });

    test('getBoxesForRange across multiple lines with hard newlines', () {
      final builder = ui.ParagraphBuilder(ahemStyle);
      builder.addText('ABC\nDEF\nGHI');
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 500));

      final List<ui.TextBox> boxes = paragraph.getBoxesForRange(
        0,
        11,
        boxHeightStyle: ui.BoxHeightStyle.max,
        boxWidthStyle: ui.BoxWidthStyle.max,
      );

      expect(boxes.length, greaterThanOrEqualTo(3));
    });
  });

  group('Paragraph getPositionForOffset Edge Cases', () {
    test('getPositionForOffset on empty line in multi-line paragraph', () {
      final builder = ui.ParagraphBuilder(ahemStyle);
      builder.addText('Line 1\n\nLine 3');
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 500));

      final List<ui.LineMetrics> lines = paragraph.computeLineMetrics();
      final double line1Height = lines[0].height;

      // Offset targeting line 2 (the empty line)
      final ui.TextPosition pos = paragraph.getPositionForOffset(ui.Offset(10, line1Height + 2));
      expect(pos.offset >= 7 && pos.offset <= 8, true);
    });

    test('getPositionForOffset out of vertical bounds (clamping)', () {
      final builder = ui.ParagraphBuilder(ahemStyle);
      const text = 'Single line text';
      builder.addText(text);
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 500));

      // Below and right of paragraph height/width
      final ui.TextPosition posBottom = paragraph.getPositionForOffset(const ui.Offset(5000, 5000));
      expect(posBottom.offset, text.length);

      // Above and left of paragraph top
      final ui.TextPosition posTop = paragraph.getPositionForOffset(const ui.Offset(-10, -500));
      expect(posTop.offset, 0);
    });

    test(
      'getPositionForOffset to the right of line end positions at line end, not paragraph end',
      () {
        final builder = ui.ParagraphBuilder(ahemStyle);
        const text0 = 'First line text\n';
        const text1 = 'Second line text\n';
        const text2 = 'Third line text';
        builder.addText(text0);
        builder.addText(text1);
        builder.addText(text2);
        final ui.Paragraph paragraph = builder.build();
        paragraph.layout(const ui.ParagraphConstraints(width: 500));

        final List<ui.LineMetrics> lines = paragraph.computeLineMetrics();
        final double firstLineHeight = lines[0].height;

        // Offset far to the right of line 0 (x = 4000, y inside line 0)
        final ui.TextPosition posLine0 = paragraph.getPositionForOffset(
          ui.Offset(4000, firstLineHeight / 2),
        );
        // Offset far to the right of line 1 (x = 4000, y inside line 1)
        final ui.TextPosition posLine1 = paragraph.getPositionForOffset(
          ui.Offset(4000, firstLineHeight + 5),
        );

        // Position should be at the end of line 0 ("First line text\n" -> index 16)
        expect(posLine0.offset, text0.length - 1);

        // Position should be at the end of line 1 ("Second line text\n" -> index 33)
        expect(posLine1.offset, text0.length + text1.length - 1);
      },
    );
  });

  group('Paragraph Word and Line Boundaries', () {
    test('getWordBoundary at newline character', () {
      final builder = ui.ParagraphBuilder(ahemStyle);
      builder.addText('Hello\nWorld');
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 500));

      // At position 5 ('\n')
      final ui.TextRange range = paragraph.getWordBoundary(const ui.TextPosition(offset: 5));
      expect(range.start, 5);
      expect(range.end, 6);
    });

    test('getLineBoundary for empty line in middle', () {
      final builder = ui.ParagraphBuilder(ahemStyle);
      builder.addText('Top\n\nBottom');
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 500));

      // Position 4 is the second line (empty line)
      final ui.TextRange range = paragraph.getLineBoundary(const ui.TextPosition(offset: 4));
      expect(range.start, 4);
      expect(range.end, 4);
    });
  });

  group('Paragraph MaxLines and Ellipsis Edge Cases', () {
    test('maxLines truncation with newline before maxLines threshold', () {
      final style = ui.ParagraphStyle(
        fontFamily: 'Arial',
        fontSize: 20,
        maxLines: 1,
        ellipsis: '...',
      );
      final builder = ui.ParagraphBuilder(style);
      builder.addText('First Line Long Text That Wraps\nSecond Line');
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 100));

      expect(paragraph.computeLineMetrics().length, 1);
    });

    test('didExceedMaxLines is false when lines fit exactly within maxLines', () {
      final style = ui.ParagraphStyle(
        fontFamily: 'Arial',
        fontSize: 20,
        maxLines: 2,
        ellipsis: '...',
      );
      final builder = ui.ParagraphBuilder(style);
      builder.addText('Line 1\nLine 2');
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 500));

      expect(paragraph.didExceedMaxLines, false);
      expect(paragraph.computeLineMetrics().length, 2);
    });

    test(r'trailing newline respects maxLines: 1', () {
      final style = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20, maxLines: 1);
      final builder = ui.ParagraphBuilder(style);
      builder.addText('Single line with trailing newline\n');
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 500));

      expect(paragraph.computeLineMetrics().length, 1);
      expect(paragraph.didExceedMaxLines, true);
    });

    test(r'trailing newline respects maxLines: 2', () {
      final style = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20, maxLines: 2);
      final builder = ui.ParagraphBuilder(style);
      builder.addText('First line\nSecond line\n');
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 500));

      expect(paragraph.computeLineMetrics().length, 2);
      expect(paragraph.didExceedMaxLines, true);
    });

    test(r'trailing newline within maxLines (maxLines: 2 for Single line\n)', () {
      final style = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20, maxLines: 2);
      final builder = ui.ParagraphBuilder(style);
      builder.addText('Single line\n');
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 500));

      expect(paragraph.computeLineMetrics().length, 2);
      expect(paragraph.didExceedMaxLines, false);
    });
  });

  group('Paragraph Placeholders Edge Cases', () {
    test('Placeholders followed by hard newline', () {
      final builder = ui.ParagraphBuilder(ahemStyle);
      builder.addText('Prefix ');
      builder.addPlaceholder(20, 20, ui.PlaceholderAlignment.bottom);
      builder.addText('\nSuffix');
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 500));

      final List<ui.LineMetrics> lines = paragraph.computeLineMetrics();
      expect(lines.length, 2);
      expect(lines[0].hardBreak, true);
    });
  });

  group('Paragraph GlyphInfo with Newline and Multi-Code-Unit Characters', () {
    test('getGlyphInfoAt for newline after multi-code-unit character (emoji)', () {
      final builder = ui.ParagraphBuilder(ahemStyle);
      // '😀' consists of 2 UTF-16 code units (surrogate pair: 0xD83D, 0xDE00).
      // '\n' is at code unit offset 2.
      builder.addText('😀\n');
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 500));

      // Querying glyph info for '\n' at code unit offset 2
      final ui.GlyphInfo? glyphNewline = paragraph.getGlyphInfoAt(2);
      expect(
        glyphNewline,
        isNotNull,
        reason: 'Glyph info for newline at offset 2 should not be null',
      );
      expect(
        glyphNewline!.graphemeClusterCodeUnitRange,
        const ui.TextRange(start: 2, end: 3),
        reason: 'Newline cluster range should be [2, 3)',
      );
    });

    test('getGlyphInfoAt for newline after multi-code-unit character in multiline text', () {
      final builder = ui.ParagraphBuilder(ahemStyle);
      builder.addText('😀\nSecond line');
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 500));

      final ui.GlyphInfo? glyphNewline = paragraph.getGlyphInfoAt(2);
      expect(
        glyphNewline,
        isNotNull,
        reason: 'Glyph info for newline at offset 2 should not be null',
      );
      expect(
        glyphNewline!.graphemeClusterCodeUnitRange,
        const ui.TextRange(start: 2, end: 3),
        reason: 'Newline cluster range should be [2, 3)',
      );
    });

    test('getGlyphInfoAt for newline on empty line following multi-code-unit character', () {
      final builder = ui.ParagraphBuilder(ahemStyle);
      // '🍎' is 2 code units (0..2).
      // Line 0: '🍎\n' (offsets 0..3)
      // Line 1: '\n'   (offsets 3..4, empty line)
      // Line 2: 'End'  (offsets 4..7)
      builder.addText('🍎\n\nEnd');
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 500));

      final ui.GlyphInfo? glyph = paragraph.getGlyphInfoAt(3);
      expect(glyph, isNotNull);
      expect(
        glyph!.graphemeClusterCodeUnitRange,
        const ui.TextRange(start: 3, end: 4),
        reason: 'Newline at offset 3 on empty line should have range [3, 4)',
      );
    });
  });

  group('Paragraph maxLines with Newlines getBoxesForRange', () {
    test('getBoxesForRange includes newline when maxLines stops on a line ending in newline', () {
      final style = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20, maxLines: 1);
      final builder = ui.ParagraphBuilder(style);
      builder.addText('Hello\nWorld');
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 500));

      expect(paragraph.computeLineMetrics().length, 1);

      // Offset 5..6 is the '\n' character terminating the first line.
      final List<ui.TextBox> boxes = paragraph.getBoxesForRange(
        5,
        6,
        boxHeightStyle: ui.BoxHeightStyle.max,
        boxWidthStyle: ui.BoxWidthStyle.max,
      );
      expect(
        boxes,
        isNotEmpty,
        reason: 'getBoxesForRange should return a box for the newline even when maxLines stops on this line',
      );
    });
  });

  group('Paragraph RTL with Newline Edge Cases', () {
    test('RTL text ending with newline preserves glyph and box positions', () {
      final rtlStyle = ui.ParagraphStyle(
        fontFamily: 'Arial',
        fontSize: 20,
        textDirection: ui.TextDirection.rtl,
      );
      final builder = ui.ParagraphBuilder(rtlStyle);
      const text = 'שלום\n';
      builder.addText(text);
      final ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 500));

      final List<ui.LineMetrics> lines = paragraph.computeLineMetrics();
      expect(lines.length, 2);

      // Baseline reference without trailing newline
      final baselineBuilder = ui.ParagraphBuilder(rtlStyle);
      baselineBuilder.addText('שלום');
      final ui.Paragraph baselineParagraph = baselineBuilder.build();
      baselineParagraph.layout(const ui.ParagraphConstraints(width: 500));

      // The glyph positions for 'שלום' (offsets 0..4) should match between the two paragraphs
      for (var i = 0; i < 4; i++) {
        final ui.GlyphInfo? glyph = paragraph.getGlyphInfoAt(i);
        final ui.GlyphInfo? baselineGlyph = baselineParagraph.getGlyphInfoAt(i);
        expect(glyph, isNotNull);
        expect(baselineGlyph, isNotNull);
        expect(
          glyph!.graphemeClusterLayoutBounds.left,
          closeTo(baselineGlyph!.graphemeClusterLayoutBounds.left, 0.001),
          reason: 'Glyph $i left position should not be displaced by trailing newline in RTL',
        );
      }

      // Check boxes for range (tight width style to isolate character glyph boxes)
      final List<ui.TextBox> boxes = paragraph.getBoxesForRange(
        0,
        4,
        boxHeightStyle: ui.BoxHeightStyle.max,
      );
      final List<ui.TextBox> baselineBoxes = baselineParagraph.getBoxesForRange(
        0,
        4,
        boxHeightStyle: ui.BoxHeightStyle.max,
      );
      expect(boxes.length, baselineBoxes.length);
      for (var i = 0; i < boxes.length; i++) {
        expect(boxes[i].left, closeTo(baselineBoxes[i].left, 0.001));
        expect(boxes[i].right, closeTo(baselineBoxes[i].right, 0.001));
      }
    });

    group('Line flag combinations (isSyntheticEmptyLine, lastLine, includesTrailingNewline)', () {
      WebParagraph createParagraph(String text, {double width = 500, int? maxLines}) {
        final builder = ui.ParagraphBuilder(
          ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20, maxLines: maxLines),
        );
        builder.addText(text);
        final paragraph = builder.build() as WebParagraph;
        paragraph.layout(ui.ParagraphConstraints(width: width));
        return paragraph;
      }

      test('Single-line text without newline (Hello)', () {
        final WebParagraph paragraph = createParagraph('Hello');
        expect(paragraph.lines.length, 1);

        final TextLine line0 = paragraph.lines[0];
        expect(line0.isSyntheticEmptyLine, isFalse);
        expect(line0.lastLine, isTrue);
        expect(line0.includesTrailingNewline, isFalse);
        // The last line of a paragraph always reports hasHardLineBreak == true in Flutter LineMetrics
        expect(line0.hasHardLineBreak, isTrue);
        expect(line0.allLineTextRange, const ui.TextRange(start: 0, end: 5));
      });

      test('Multi-line soft-wrapped text (Hello World)', () {
        final WebParagraph paragraph = createParagraph('Hello World', width: 70);
        expect(paragraph.lines.length, 2);

        final TextLine line0 = paragraph.lines[0];
        expect(line0.isSyntheticEmptyLine, isFalse);
        expect(line0.lastLine, isFalse);
        expect(line0.includesTrailingNewline, isFalse);
        expect(line0.hasHardLineBreak, isFalse);
        // Line 0 includes trailing space at index 5: 'Hello ' -> [0, 6)
        expect(line0.allLineTextRange, const ui.TextRange(start: 0, end: 6));

        final TextLine line1 = paragraph.lines[1];
        expect(line1.isSyntheticEmptyLine, isFalse);
        expect(line1.lastLine, isTrue);
        expect(line1.includesTrailingNewline, isFalse);
        expect(line1.hasHardLineBreak, isTrue);
        expect(line1.allLineTextRange, const ui.TextRange(start: 6, end: 11));
      });

      test(r'Multi-line text with interior newline (Hello\nWorld)', () {
        final WebParagraph paragraph = createParagraph('Hello\nWorld');
        expect(paragraph.lines.length, 2);

        final TextLine line0 = paragraph.lines[0];
        expect(line0.isSyntheticEmptyLine, isFalse);
        expect(line0.lastLine, isFalse);
        expect(line0.includesTrailingNewline, isFalse);
        expect(line0.hasHardLineBreak, isTrue);
        expect(line0.allLineTextRange, const ui.TextRange(start: 0, end: 5));

        final TextLine line1 = paragraph.lines[1];
        expect(line1.isSyntheticEmptyLine, isFalse);
        expect(line1.lastLine, isTrue);
        expect(line1.includesTrailingNewline, isFalse);
        expect(line1.hasHardLineBreak, isTrue);
        expect(line1.allLineTextRange, const ui.TextRange(start: 6, end: 11));
      });

      test(r'Single trailing newline (Hello\n)', () {
        final WebParagraph paragraph = createParagraph('Hello\n');
        expect(paragraph.lines.length, 2);

        // Line 0: Content line ending with newline
        final TextLine line0 = paragraph.lines[0];
        expect(line0.isSyntheticEmptyLine, isFalse);
        expect(line0.lastLine, isFalse);
        expect(line0.includesTrailingNewline, isTrue);
        expect(line0.hasHardLineBreak, isTrue);
        expect(line0.allLineTextRange, const ui.TextRange(start: 0, end: 6));

        // Line 1: Synthetic empty trailing line
        final TextLine line1 = paragraph.lines[1];
        expect(line1.isSyntheticEmptyLine, isTrue);
        expect(line1.lastLine, isTrue);
        expect(line1.includesTrailingNewline, isFalse);
      });

      test(r'Multiple consecutive trailing newlines (Hello\n\n)', () {
        final WebParagraph paragraph = createParagraph('Hello\n\n');
        expect(paragraph.lines.length, 3);

        // Line 0: Interior newline line
        final TextLine line0 = paragraph.lines[0];
        expect(line0.isSyntheticEmptyLine, isFalse);
        expect(line0.lastLine, isFalse);
        expect(line0.includesTrailingNewline, isFalse);
        expect(line0.allLineTextRange, const ui.TextRange(start: 0, end: 5));

        // Line 1: Terminal newline line (before EOF)
        final TextLine line1 = paragraph.lines[1];
        expect(line1.isSyntheticEmptyLine, isFalse);
        expect(line1.lastLine, isFalse);
        expect(line1.includesTrailingNewline, isTrue);
        expect(line1.allLineTextRange, const ui.TextRange(start: 6, end: 7));

        // Line 2: Synthetic empty trailing line
        final TextLine line2 = paragraph.lines[2];
        expect(line2.isSyntheticEmptyLine, isTrue);
        expect(line2.lastLine, isTrue);
        expect(line2.includesTrailingNewline, isFalse);
      });

      test(r'Only newlines (\n and \n\n)', () {
        final WebParagraph singleNewline = createParagraph('\n');
        expect(singleNewline.lines.length, 2);
        expect(singleNewline.lines[0].isSyntheticEmptyLine, isFalse);
        expect(singleNewline.lines[0].lastLine, isFalse);
        expect(singleNewline.lines[0].includesTrailingNewline, isTrue);
        expect(singleNewline.lines[0].allLineTextRange, const ui.TextRange(start: 0, end: 1));
        expect(singleNewline.lines[1].isSyntheticEmptyLine, isTrue);
        expect(singleNewline.lines[1].lastLine, isTrue);
        expect(singleNewline.lines[1].includesTrailingNewline, isFalse);

        final WebParagraph doubleNewline = createParagraph('\n\n');
        expect(doubleNewline.lines.length, 3);
        // Line 0: interior newline
        expect(doubleNewline.lines[0].isSyntheticEmptyLine, isFalse);
        expect(doubleNewline.lines[0].lastLine, isFalse);
        expect(doubleNewline.lines[0].includesTrailingNewline, isFalse);
        expect(doubleNewline.lines[0].allLineTextRange, const ui.TextRange(start: 0, end: 0));
        // Line 1: terminal newline
        expect(doubleNewline.lines[1].isSyntheticEmptyLine, isFalse);
        expect(doubleNewline.lines[1].lastLine, isFalse);
        expect(doubleNewline.lines[1].includesTrailingNewline, isTrue);
        expect(doubleNewline.lines[1].allLineTextRange, const ui.TextRange(start: 1, end: 2));
        // Line 2: synthetic trailing empty line
        expect(doubleNewline.lines[2].isSyntheticEmptyLine, isTrue);
        expect(doubleNewline.lines[2].lastLine, isTrue);
        expect(doubleNewline.lines[2].includesTrailingNewline, isFalse);
      });

      test(r'Trailing newline with maxLines: 1 constraint (Hello\n)', () {
        final WebParagraph paragraph = createParagraph('Hello\n', maxLines: 1);

        // When maxLines == 1, the synthetic line is omitted, so Line 0 is both lastLine and includesTrailingNewline
        expect(paragraph.lines.length, 1);
        final TextLine line0 = paragraph.lines[0];
        expect(line0.isSyntheticEmptyLine, isFalse);
        expect(line0.lastLine, isTrue);
        expect(line0.includesTrailingNewline, isTrue);
        expect(line0.hasHardLineBreak, isTrue);
        expect(line0.allLineTextRange, const ui.TextRange(start: 0, end: 6));
      });

      test(r'Interior newline with maxLines: 1 constraint (Hello\nWorld)', () {
        final WebParagraph paragraph = createParagraph('Hello\nWorld', maxLines: 1);

        expect(paragraph.lines.length, 1);
        final TextLine line0 = paragraph.lines[0];
        expect(line0.isSyntheticEmptyLine, isFalse);
        expect(line0.lastLine, isTrue);
        expect(line0.includesTrailingNewline, isFalse);
        expect(line0.hasHardLineBreak, isTrue);
        expect(line0.allLineTextRange, const ui.TextRange(start: 0, end: 5));
      });
    });

    group(
      'Line flag combinations in RTL (isSyntheticEmptyLine, lastLine, includesTrailingNewline)',
      () {
        WebParagraph createRtlParagraph(String text, {double width = 500, int? maxLines}) {
          final builder = ui.ParagraphBuilder(
            ui.ParagraphStyle(
              fontFamily: 'Arial',
              fontSize: 20,
              textDirection: ui.TextDirection.rtl,
              maxLines: maxLines,
            ),
          );
          builder.addText(text);
          final paragraph = builder.build() as WebParagraph;
          paragraph.layout(ui.ParagraphConstraints(width: width));
          return paragraph;
        }

        test('Single-line text without newline in RTL (שלום)', () {
          final WebParagraph paragraph = createRtlParagraph('שלום');
          expect(paragraph.lines.length, 1);

          final TextLine line0 = paragraph.lines[0];
          expect(line0.isSyntheticEmptyLine, isFalse);
          expect(line0.lastLine, isTrue);
          expect(line0.includesTrailingNewline, isFalse);
          expect(line0.hasHardLineBreak, isTrue);
          expect(line0.allLineTextRange, const ui.TextRange(start: 0, end: 4));
        });

        test('Multi-line soft-wrapped text in RTL (שלום עולם)', () {
          final WebParagraph paragraph = createRtlParagraph('שלום עולם', width: 70);
          expect(paragraph.lines.length, 2);

          final TextLine line0 = paragraph.lines[0];
          expect(line0.isSyntheticEmptyLine, isFalse);
          expect(line0.lastLine, isFalse);
          expect(line0.includesTrailingNewline, isFalse);
          expect(line0.hasHardLineBreak, isFalse);
          // Line 0 includes trailing space at index 4: 'שלום ' -> [0, 5)
          expect(line0.allLineTextRange, const ui.TextRange(start: 0, end: 5));

          final TextLine line1 = paragraph.lines[1];
          expect(line1.isSyntheticEmptyLine, isFalse);
          expect(line1.lastLine, isTrue);
          expect(line1.includesTrailingNewline, isFalse);
          expect(line1.hasHardLineBreak, isTrue);
          expect(line1.allLineTextRange, const ui.TextRange(start: 5, end: 9));
        });

        test(r'Multi-line text with interior newline in RTL (שלום\nעולם)', () {
          final WebParagraph paragraph = createRtlParagraph('שלום\nעולם');
          expect(paragraph.lines.length, 2);

          final TextLine line0 = paragraph.lines[0];
          expect(line0.isSyntheticEmptyLine, isFalse);
          expect(line0.lastLine, isFalse);
          expect(line0.includesTrailingNewline, isFalse);
          expect(line0.hasHardLineBreak, isTrue);
          expect(line0.allLineTextRange, const ui.TextRange(start: 0, end: 4));

          final TextLine line1 = paragraph.lines[1];
          expect(line1.isSyntheticEmptyLine, isFalse);
          expect(line1.lastLine, isTrue);
          expect(line1.includesTrailingNewline, isFalse);
          expect(line1.hasHardLineBreak, isTrue);
          expect(line1.allLineTextRange, const ui.TextRange(start: 5, end: 9));
        });

        test(r'Single trailing newline in RTL (שלום\n)', () {
          final WebParagraph paragraph = createRtlParagraph('שלום\n');
          expect(paragraph.lines.length, 2);

          // Line 0: Content line ending with newline
          final TextLine line0 = paragraph.lines[0];
          expect(line0.isSyntheticEmptyLine, isFalse);
          expect(line0.lastLine, isFalse);
          expect(line0.includesTrailingNewline, isTrue);
          expect(line0.hasHardLineBreak, isTrue);
          expect(line0.allLineTextRange, const ui.TextRange(start: 0, end: 5));

          // Line 1: Synthetic empty trailing line
          final TextLine line1 = paragraph.lines[1];
          expect(line1.isSyntheticEmptyLine, isTrue);
          expect(line1.lastLine, isTrue);
          expect(line1.includesTrailingNewline, isFalse);
        });

        test(r'Multiple consecutive trailing newlines in RTL (שלום\n\n)', () {
          final WebParagraph paragraph = createRtlParagraph('שלום\n\n');
          expect(paragraph.lines.length, 3);

          // Line 0: Interior newline line
          final TextLine line0 = paragraph.lines[0];
          expect(line0.isSyntheticEmptyLine, isFalse);
          expect(line0.lastLine, isFalse);
          expect(line0.includesTrailingNewline, isFalse);
          expect(line0.allLineTextRange, const ui.TextRange(start: 0, end: 4));

          // Line 1: Terminal newline line (before EOF)
          final TextLine line1 = paragraph.lines[1];
          expect(line1.isSyntheticEmptyLine, isFalse);
          expect(line1.lastLine, isFalse);
          expect(line1.includesTrailingNewline, isTrue);
          expect(line1.allLineTextRange, const ui.TextRange(start: 5, end: 6));

          // Line 2: Synthetic empty trailing line
          final TextLine line2 = paragraph.lines[2];
          expect(line2.isSyntheticEmptyLine, isTrue);
          expect(line2.lastLine, isTrue);
          expect(line2.includesTrailingNewline, isFalse);
        });

        test(r'Only newlines in RTL (\n and \n\n)', () {
          final WebParagraph singleNewline = createRtlParagraph('\n');
          expect(singleNewline.lines.length, 2);
          expect(singleNewline.lines[0].isSyntheticEmptyLine, isFalse);
          expect(singleNewline.lines[0].lastLine, isFalse);
          expect(singleNewline.lines[0].includesTrailingNewline, isTrue);
          expect(singleNewline.lines[0].allLineTextRange, const ui.TextRange(start: 0, end: 1));
          expect(singleNewline.lines[1].isSyntheticEmptyLine, isTrue);
          expect(singleNewline.lines[1].lastLine, isTrue);
          expect(singleNewline.lines[1].includesTrailingNewline, isFalse);

          final WebParagraph doubleNewline = createRtlParagraph('\n\n');
          expect(doubleNewline.lines.length, 3);
          // Line 0: interior newline
          expect(doubleNewline.lines[0].isSyntheticEmptyLine, isFalse);
          expect(doubleNewline.lines[0].lastLine, isFalse);
          expect(doubleNewline.lines[0].includesTrailingNewline, isFalse);
          expect(doubleNewline.lines[0].allLineTextRange, const ui.TextRange(start: 0, end: 0));
          // Line 1: terminal newline
          expect(doubleNewline.lines[1].isSyntheticEmptyLine, isFalse);
          expect(doubleNewline.lines[1].lastLine, isFalse);
          expect(doubleNewline.lines[1].includesTrailingNewline, isTrue);
          expect(doubleNewline.lines[1].allLineTextRange, const ui.TextRange(start: 1, end: 2));
          // Line 2: synthetic trailing empty line
          expect(doubleNewline.lines[2].isSyntheticEmptyLine, isTrue);
          expect(doubleNewline.lines[2].lastLine, isTrue);
          expect(doubleNewline.lines[2].includesTrailingNewline, isFalse);
        });

        test(r'Trailing newline with maxLines: 1 constraint in RTL (שלום\n)', () {
          final WebParagraph paragraph = createRtlParagraph('שלום\n', maxLines: 1);

          expect(paragraph.lines.length, 1);
          final TextLine line0 = paragraph.lines[0];
          expect(line0.isSyntheticEmptyLine, isFalse);
          expect(line0.lastLine, isTrue);
          expect(line0.includesTrailingNewline, isTrue);
          expect(line0.hasHardLineBreak, isTrue);
          expect(line0.allLineTextRange, const ui.TextRange(start: 0, end: 5));
        });

        test(r'Interior newline with maxLines: 1 constraint in RTL (שלום\nעולם)', () {
          final WebParagraph paragraph = createRtlParagraph('שלום\nעולם', maxLines: 1);

          expect(paragraph.lines.length, 1);
          final TextLine line0 = paragraph.lines[0];
          expect(line0.isSyntheticEmptyLine, isFalse);
          expect(line0.lastLine, isTrue);
          expect(line0.includesTrailingNewline, isFalse);
          expect(line0.hasHardLineBreak, isTrue);
          expect(line0.allLineTextRange, const ui.TextRange(start: 0, end: 4));
        });
      },
    );
  });
}
