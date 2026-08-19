// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
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
}
