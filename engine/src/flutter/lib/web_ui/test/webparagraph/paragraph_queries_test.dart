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
    const text =
        'World domination is such an ugly phrase - I prefer to call it world optimisation. ';
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    final SegmentationResult result = segmentText(text);
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
    const text =
        'World domination is such an ugly phrase - I prefer to call it world optimisation. ';
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    expect(
      paragraph.getWordBoundary(
        const ui.TextPosition(offset: 0, affinity: ui.TextAffinity.upstream),
      ),
      const ui.TextRange(start: text.length, end: text.length),
    );
    expect(
      paragraph.getWordBoundary(
        const ui.TextPosition(offset: -1 /* affinity: ui.TextAffinity.downstream */),
      ),
      const ui.TextRange(start: text.length, end: text.length),
    );
    expect(
      paragraph.getWordBoundary(
        const ui.TextPosition(offset: text.length + 1, affinity: ui.TextAffinity.upstream),
      ),
      const ui.TextRange(start: text.length, end: text.length),
    );
    expect(
      paragraph.getWordBoundary(
        const ui.TextPosition(offset: text.length, affinity: ui.TextAffinity.downstream),
      ),
      const ui.TextRange(start: text.length, end: text.length),
    );
  });

  test('Paragraph getWordBoundary empty text', () {
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    final builder = ui.ParagraphBuilder(paragraphStyle);
    final ui.Paragraph paragraph = builder.build();
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
    const text = '                     ';
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    expect(
      paragraph.getWordBoundary(
        const ui.TextPosition(offset: 0 /* affinity: ui.TextAffinity.downstream */),
      ),
      const ui.TextRange(start: 0, end: text.length),
    );
    expect(
      paragraph.getWordBoundary(
        const ui.TextPosition(offset: text.length, affinity: ui.TextAffinity.upstream),
      ),
      const ui.TextRange(start: 0, end: text.length),
    );
  });

  test('Paragraph getLineBoundary', () {
    const text = '1 234\n\n';
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    expect(
      paragraph.getLineBoundary(
        const ui.TextPosition(offset: 0 /* affinity: ui.TextAffinity.downstream */),
      ),
      const ui.TextRange(start: 0, end: 5),
    );
    expect(
      paragraph.getLineBoundary(
        const ui.TextPosition(offset: 6 /* affinity: ui.TextAffinity.downstream */),
      ),
      const ui.TextRange(start: 6, end: 7),
    );
    expect(
      paragraph.getLineBoundary(
        const ui.TextPosition(offset: 7 /* affinity: ui.TextAffinity.downstream */),
      ),
      const ui.TextRange(start: 6, end: 7),
    );

    expect(
      paragraph.getLineBoundary(
        const ui.TextPosition(offset: -1 /* affinity: ui.TextAffinity.downstream */),
      ),
      const ui.TextRange(start: -1, end: -1),
    );

    expect(
      paragraph.getLineBoundary(
        const ui.TextPosition(offset: text.length + 1, affinity: ui.TextAffinity.upstream),
      ),
      const ui.TextRange(start: -1, end: -1),
    );
  });

  test('Paragraph computeLineMetrics/getLineMetricsAt', () {
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText('Line1\nLine2\nLine3');
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    final List<ui.LineMetrics> lineMetrics = paragraph.computeLineMetrics();
    final ui.LineMetrics? lineMetricsAt1 = paragraph.getLineMetricsAt(1);
    expect(lineMetricsAt1, isNotNull);
    expect(lineMetrics.length, 3);
    expect(lineMetrics[0].lineNumber, 0);
    expect(lineMetrics[1].lineNumber, 1);
    expect(lineMetrics[2].lineNumber, 2);
    expect(lineMetrics[1].left, lineMetricsAt1!.left);
    expect(lineMetrics[1].width, lineMetricsAt1.width);
    expect(lineMetrics[1].height, lineMetricsAt1.height);
  });

  test('Paragraph numberOfLines/getLineNumberAt', () {
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText('Line1\nLine2\nLine3');
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    expect(paragraph.numberOfLines, 3);
    expect(paragraph.getLineNumberAt(3), 0);
    expect(paragraph.getLineNumberAt(9), 1);
    expect(paragraph.getLineNumberAt(15), 2);
  });

  test('Paragraph getGlyphInfoAt', () {
    const epsilon = 0.5;
    const text = 'Line1\nLine2\nLine3';
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    final List<ui.LineMetrics> metrics = paragraph.computeLineMetrics();
    for (final metric in metrics) {
      for (var i = 0; i < text.length; i++) {
        final int pos = (i == 5 || i == 11) ? i - 1 : i;
        final ui.GlyphInfo? glyphInfo = paragraph.getGlyphInfoAt(pos);
        if (glyphInfo != null) {
          expect(glyphInfo.graphemeClusterCodeUnitRange, ui.TextRange(start: pos, end: pos + 1));
          expect(glyphInfo.graphemeClusterLayoutBounds.height, closeTo(metric.height, epsilon));
          expect(glyphInfo.writingDirection, ui.TextDirection.ltr);
        } else {
          assert(false, '${text.length}: glyphInfo[$i] should not be null');
        }
      }
    }
  });

  test('Paragraph getGlyphInfoAt for a single character', () {
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText('J');
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    final ui.GlyphInfo? glyphInfo = paragraph.getGlyphInfoAt(0);
    expect(glyphInfo != null, true);
  });

  test('Paragraph getClosestGlyphInfoForOffset', () {
    const epsilon = 0.1;
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText('Line1\nLine2\nLine3');
    const int length = 'Line1\nLine2\nLine3'.length;
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    for (var i = 0; i < length; i++) {
      // Get the glyph info at the current index, but for the newline characters, get the previous glyph info instead
      final int pos = (i == 5 || i == 11) ? i - 1 : i;
      final ui.GlyphInfo? glyphInfo = paragraph.getGlyphInfoAt(pos);
      if (glyphInfo != null) {
        final center = ui.Offset(
          glyphInfo.graphemeClusterLayoutBounds.left + epsilon,
          glyphInfo.graphemeClusterLayoutBounds.center.dy,
        );
        final ui.GlyphInfo? closestGlyphInfo = paragraph.getClosestGlyphInfoForOffset(center);
        if (closestGlyphInfo != null) {
          expect(
            closestGlyphInfo,
            equals(glyphInfo),
            reason: 'Glyph[$i] @$center "${'Line1\nLine2\nLine3'.substring(pos, pos + 1)}"',
          );
        } else {
          assert(false, '$length: closestGlyphInfo[$i] should not be null');
        }
      } else {
        assert(false, '$length: getGlyphInfoAt[$i] should not be null');
      }
    }
  });

  test('Paragraph empty text', () {
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText('');
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    expect(paragraph.width, double.infinity);
    expect(paragraph.height, closeTo(22.0, 1.0));
    expect(paragraph.minIntrinsicWidth, closeTo(0.0, EPSILON));
    expect(paragraph.maxIntrinsicWidth, closeTo(0.0, EPSILON));
    //expect(paragraph.longestLine, double.negativeInfinity - double.infinity);
    expect(paragraph.numberOfLines, 0);
  });

  test('Paragraph whitespaces', () {
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText(' ');
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    expect(paragraph.width, double.infinity);
    expect(paragraph.height, closeTo(22.0, 1.0));
    //expect(paragraph.minIntrinsicWidth, closeTo(5.556640625, EPSILON));
    //expect(paragraph.maxIntrinsicWidth, closeTo(5.556640625, EPSILON));
    //expect(paragraph.longestLine, closeTo(5.556640625, EPSILON));
    expect(paragraph.numberOfLines, 1);
  });

  test('getGlyphInfoAt handles out of bounds offset', () {
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    const text = 'Hello';
    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final ui.Paragraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    // Out of bounds should return null
    final ui.GlyphInfo? glyphInfo = paragraph.getGlyphInfoAt(text.length);
    expect(glyphInfo, isNull);
  });

  test('getGlyphInfoAt handles bidirectional text', () {
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText('Hello مرحبا'); // LTR + RTL
    final ui.Paragraph paragraph = builder.build();
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
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    const text = 'Hello World';
    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final ui.Paragraph paragraph = builder.build();
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
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    const text = 'Hello World';
    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final ui.Paragraph paragraph = builder.build();
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
    final paragraphStyle = ui.ParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    const text = 'Hello World';
    final builder = ui.ParagraphBuilder(paragraphStyle);
    builder.addText(text);
    final ui.Paragraph paragraph = builder.build();
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
