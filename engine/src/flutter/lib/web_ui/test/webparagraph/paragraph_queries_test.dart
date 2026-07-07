// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const double EPSILON = 0.001;

Future<void> testMain() async {
  setUpUnitTests();

  test('Paragraph getWordBoundary', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(
      'World domination is such an ugly phrase - I prefer to call it world optimisation. ',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    final SegmentationResult result = segmentText(paragraph.text);
    var start = 0;
    for (final int end in result.words.skip(1)) {
      for (var i = start; i < end; i++) {
        expect(
          paragraph.getWordBoundary(
            ui.TextPosition(offset: i /*affinity: ui.TextAffinity.downstream*/),
          ),
          ui.TextRange(start: start, end: end),
        );
      }
      expect(
        paragraph.getWordBoundary(ui.TextPosition(offset: end, affinity: ui.TextAffinity.upstream)),
        ui.TextRange(start: start, end: end),
      );
      start = end;
    }
  });

  test('Paragraph getWordBoundary outside of the text', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(
      'World domination is such an ugly phrase - I prefer to call it world optimisation. ',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    expect(
      paragraph.getWordBoundary(
        const ui.TextPosition(offset: 0, affinity: ui.TextAffinity.upstream),
      ),
      const ui.TextRange(start: 0, end: 0),
    );
    expect(
      paragraph.getWordBoundary(
        const ui.TextPosition(offset: -1 /* affinity: ui.TextAffinity.downstream */),
      ),
      const ui.TextRange(start: 0, end: 0),
    );
    expect(
      paragraph.getWordBoundary(
        ui.TextPosition(offset: paragraph.text.length + 1, affinity: ui.TextAffinity.upstream),
      ),
      ui.TextRange(start: paragraph.text.length, end: paragraph.text.length),
    );
    expect(
      paragraph.getWordBoundary(
        ui.TextPosition(offset: paragraph.text.length /* affinity: ui.TextAffinity.downstream */),
      ),
      ui.TextRange(start: paragraph.text.length, end: paragraph.text.length),
    );
  });

  test('Paragraph getWordBoundary empty text', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    final builder = WebParagraphBuilder(paragraphStyle);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    expect(
      paragraph.getWordBoundary(
        const ui.TextPosition(offset: 0 /* affinity: ui.TextAffinity.downstream */),
      ),
      const ui.TextRange(start: 0, end: 0),
    );
    expect(
      paragraph.getWordBoundary(
        const ui.TextPosition(offset: 1 /* affinity: ui.TextAffinity.upstream */),
      ),
      const ui.TextRange(start: 0, end: 0),
    );
  });

  test('Paragraph getWordBoundary only whitespaces', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('                     ');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    expect(
      paragraph.getWordBoundary(
        const ui.TextPosition(offset: 0 /* affinity: ui.TextAffinity.downstream */),
      ),
      ui.TextRange(start: 0, end: paragraph.text.length),
    );
    expect(
      paragraph.getWordBoundary(
        ui.TextPosition(offset: paragraph.text.length, affinity: ui.TextAffinity.upstream),
      ),
      ui.TextRange(start: 0, end: paragraph.text.length),
    );
  });

  test('getLineBoundary correctly handles text with soft line break at the end', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    const text = 'Hello world';
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: 50));

    expect(paragraph.numberOfLines, 2);

    // Line 1: "Hello "
    final ui.TextRange line1Boundary = paragraph.getLineBoundary(const ui.TextPosition(offset: 0));
    expect(line1Boundary.start, 0);
    expect(line1Boundary.end, 6); // Should not include the newline

    // Line 2: "World"
    final ui.TextRange line2Boundary = paragraph.getLineBoundary(const ui.TextPosition(offset: 6));
    expect(line2Boundary.start, 6);
    expect(line2Boundary.end, 11); // Should not include the newline
  });

  test('getLineBoundary correctly handles text with hard line break at the end', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    const text = 'Hello\nWorld\n';
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    expect(paragraph.numberOfLines, 3);

    // Line 1: "Hello\n"
    final ui.TextRange line1Boundary = paragraph.getLineBoundary(const ui.TextPosition(offset: 0));
    expect(line1Boundary.start, 0);
    expect(line1Boundary.end, 5); // Should not include the newline

    // Line 2: "World\n"
    final ui.TextRange line2Boundary = paragraph.getLineBoundary(const ui.TextPosition(offset: 6));
    expect(line2Boundary.start, 6);
    expect(line2Boundary.end, 11); // Should not include the newline

    // Position past the end of the text should return an empty range
    final ui.TextRange line2BoundaryAtNewline = paragraph.getLineBoundary(
      const ui.TextPosition(offset: 12),
    );
    expect(line2BoundaryAtNewline.start, -1);
    expect(line2BoundaryAtNewline.end, -1);
  });

  test('getLineBoundary correctly handles trailing whitespaces before hard line break', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    const text = 'Hello \nWorld!';
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    // Line 1: "Hello \n" (with trailing space)
    final ui.TextRange line1Boundary = paragraph.getLineBoundary(const ui.TextPosition(offset: 0));
    expect(line1Boundary.start, 0);
    expect(line1Boundary.end, 6); // Should include the space and exclude the newline

    // Position at the space should return line 1 boundary
    final ui.TextRange line1BoundaryAtSpace = paragraph.getLineBoundary(
      const ui.TextPosition(offset: 5),
    );
    expect(line1BoundaryAtSpace.start, 0);
    expect(line1BoundaryAtSpace.end, 6);

    // Position at the newline should return line 1 boundary
    final ui.TextRange line1BoundaryAtNewline = paragraph.getLineBoundary(
      const ui.TextPosition(offset: 6),
    );
    expect(line1BoundaryAtNewline.start, 0);
    expect(line1BoundaryAtNewline.end, 6);

    // Line 2: "World!"
    final ui.TextRange line2Boundary = paragraph.getLineBoundary(const ui.TextPosition(offset: 7));
    expect(line2Boundary.start, 7);
    expect(line2Boundary.end, 13); // No trailing newline in this line
  });

  test('Paragraph computeLineMetrics/getLineMetricsAt', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('Line1\nLine2\nLine3');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    final List<ui.LineMetrics> lineMetrics = paragraph.computeLineMetrics();
    expect(lineMetrics.length, 3);
    expect(lineMetrics[0].lineNumber, 0);
    expect(lineMetrics[1].lineNumber, 1);
    expect(lineMetrics[2].lineNumber, 2);
    expect(lineMetrics[1], paragraph.getLineMetricsAt(1));
  });

  test('Paragraph numberOfLines/getLineNumberAt', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('Line1\nLine2\nLine3');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    expect(paragraph.numberOfLines, 3);
    expect(paragraph.getLineNumberAt(3), 0);
    expect(paragraph.getLineNumberAt(9), 1);
    expect(paragraph.getLineNumberAt(15), 2);
  });

  test('Paragraph getGlyphInfoAt', () {
    const epsilon = 0.001;
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('Line1\nLine2\nLine3');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    for (final TextLine line in paragraph.getLayout().lines) {
      double left = line.advance.left;
      for (final LineBlock visualBlock in line.visualBlocks) {
        for (int i = visualBlock.textRange.start; i < visualBlock.textRange.end; i++) {
          final ui.GlyphInfo? glyphInfo = paragraph.getGlyphInfoAt(i);
          if (glyphInfo != null) {
            expect(glyphInfo.graphemeClusterCodeUnitRange, ui.TextRange(start: i, end: i + 1));
            expect(
              glyphInfo.graphemeClusterLayoutBounds.height,
              closeTo(line.advance.height, epsilon),
            );
            expect(glyphInfo.graphemeClusterLayoutBounds.left, closeTo(left, epsilon));
            left = glyphInfo.graphemeClusterLayoutBounds.right;
            expect(glyphInfo.writingDirection, ui.TextDirection.ltr);
          } else {
            assert(false, 'glyphInfo should not be null');
          }
        }
      }
    }
  });

  test('Paragraph getGlyphInfoAt for a single character', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('J');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    final ui.GlyphInfo? glyphInfo = paragraph.getGlyphInfoAt(0);
    expect(glyphInfo != null, true);
  });

  test('Paragraph getClosestGlyphInfoForOffset', () {
    const epsilon = 0.001;
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('Line1\nLine2\nLine3');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    for (final TextLine line in paragraph.getLayout().lines) {
      for (final LineBlock visualBlock in line.visualBlocks) {
        for (int i = visualBlock.textRange.start; i < visualBlock.textRange.end; i++) {
          final ui.GlyphInfo? glyphInfo = paragraph.getGlyphInfoAt(i);
          if (glyphInfo != null) {
            final center = ui.Offset(
              glyphInfo.graphemeClusterLayoutBounds.left + epsilon,
              glyphInfo.graphemeClusterLayoutBounds.center.dy,
            );
            final ui.GlyphInfo? closestGlyphInfo = paragraph.getClosestGlyphInfoForOffset(center);
            if (closestGlyphInfo != null) {
              expect(closestGlyphInfo, equals(glyphInfo));
            } else {
              assert(false, 'closestGlyphInfo should not be null');
            }
          } else {
            assert(false, 'glyphInfo should not be null');
          }
        }
      }
    }
  });

  test('Paragraph empty text', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    expect(paragraph.width, double.infinity);
    expect(paragraph.height, closeTo(22.0, EPSILON));
    expect(paragraph.minIntrinsicWidth, closeTo(0.0, EPSILON));
    expect(paragraph.maxIntrinsicWidth, closeTo(0.0, EPSILON));
    expect(paragraph.longestLine, double.negativeInfinity);
    expect(paragraph.numberOfLines, 0);
  });

  test('Paragraph whitespaces', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(' ');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    expect(paragraph.width, double.infinity);
    expect(paragraph.height, closeTo(22.0, EPSILON));
    expect(paragraph.minIntrinsicWidth, closeTo(5.556640625, EPSILON));
    expect(paragraph.maxIntrinsicWidth, closeTo(5.556640625, EPSILON));
    expect(paragraph.longestLine, closeTo(5.556640625, EPSILON));
    expect(paragraph.numberOfLines, 1);
  });

  test('getGlyphInfoAt handles out of bounds offset', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    const text = 'Hello';
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    // Out of bounds should return null
    final ui.GlyphInfo? glyphInfo = paragraph.getGlyphInfoAt(text.length);
    expect(glyphInfo, isNull);
  });

  test('getGlyphInfoAt handles bidirectional text', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('Hello مرحبا'); // LTR + RTL
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    // Get glyph info for LTR text
    final ui.GlyphInfo? glyphInfoLtr = paragraph.getGlyphInfoAt(0);
    // Get glyph info for RTL text
    final ui.GlyphInfo? glyphInfoRtl = paragraph.getGlyphInfoAt(6);

    expect(glyphInfoLtr, isNotNull);
    expect(glyphInfoRtl, isNotNull);

    if (glyphInfoLtr != null && glyphInfoRtl != null) {
      expect(glyphInfoLtr.writingDirection == ui.TextDirection.ltr, true);
      expect(glyphInfoRtl.writingDirection == ui.TextDirection.rtl, true);
    }
  });

  test('getClosestGlyphInfoForOffset uses correct affinity', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    const text = 'Hello World';
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    final List<ui.TextBox> boxes = paragraph.getBoxesForRange(0, 1);
    if (boxes.isNotEmpty) {
      final ui.Rect rect = boxes.first.toRect();
      final ui.GlyphInfo? glyph = paragraph.getClosestGlyphInfoForOffset(rect.center);
      expect(glyph, isNotNull);
      expect(glyph!.graphemeClusterCodeUnitRange, const ui.TextRange(start: 0, end: 1));
    }
  });

  test('Round-trip getBoxesForRange and getPositionForOffset', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    const text = 'Hello World';
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    // Get boxes for a range
    final List<ui.TextBox> boxes = paragraph.getBoxesForRange(0, 5);
    expect(boxes.isNotEmpty, true);

    if (boxes.isNotEmpty) {
      final ui.Rect rect = boxes.first.toRect();
      final ui.TextPosition position0 = paragraph.getPositionForOffset(
        rect.centerLeft.translate(0.1, 0),
      );
      final ui.TextPosition position1 = paragraph.getPositionForOffset(
        rect.centerRight.translate(-0.1, 0),
      );
      // Position should be within the range we queried
      expect(position0.offset == 0, true);
      expect(position1.offset == 5, true);
    }
  });

  test('Consistency between getBoxesForRange and getGlyphInfoAt', () {
    final paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    const text = 'Hello World';
    final builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    for (var i = 0; i < text.length; i++) {
      final List<ui.TextBox> boxes = paragraph.getBoxesForRange(i, i + 1);
      final ui.GlyphInfo? glyph = paragraph.getGlyphInfoAt(i);

      if (boxes.isNotEmpty && glyph != null) {
        // Both should return non-zero dimensions
        expect(boxes.first.toRect().width > 0, true);
        expect(glyph.graphemeClusterLayoutBounds.width > 0, true);
      } else {
        assert(false);
      }
    }
  });
}
