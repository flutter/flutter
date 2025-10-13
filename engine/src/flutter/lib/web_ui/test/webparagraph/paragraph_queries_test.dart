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
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.addText(
      'World domination is such an ugly phrase - I prefer to call it world optimisation. ',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    final SegmentationResult result = segmentText(paragraph.text);
    int start = 0;
    for (final end in result.words.skip(1)) {
      for (int i = start; i < end; i++) {
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
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
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
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
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
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('                     ');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    expect(
      paragraph.getWordBoundary(
        const ui.TextPosition(offset: 0 /* affinity: ui.TextAffinity.downstream */),
      ),
      const ui.TextRange(start: 0, end: 1),
    );
    expect(
      paragraph.getWordBoundary(
        ui.TextPosition(offset: paragraph.text.length, affinity: ui.TextAffinity.upstream),
      ),
      ui.TextRange(start: paragraph.text.length - 1, end: paragraph.text.length),
    );
  });

  test('Paragraph getLineBoundary', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('Line1\nLine2\nLine3');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    expect(
      paragraph.getLineBoundary(
        const ui.TextPosition(offset: 0 /* affinity: ui.TextAffinity.downstream */),
      ),
      const ui.TextRange(start: 0, end: 6),
    );
    expect(
      paragraph.getLineBoundary(
        const ui.TextPosition(offset: 6 /* affinity: ui.TextAffinity.downstream */),
      ),
      const ui.TextRange(start: 6, end: 12),
    );
    expect(
      paragraph.getLineBoundary(
        const ui.TextPosition(offset: 12 /* affinity: ui.TextAffinity.downstream */),
      ),
      const ui.TextRange(start: 12, end: 17),
    );

    expect(
      paragraph.getLineBoundary(
        const ui.TextPosition(offset: -1 /* affinity: ui.TextAffinity.downstream */),
      ),
      ui.TextRange.empty,
    );

    expect(
      paragraph.getLineBoundary(
        ui.TextPosition(offset: paragraph.text.length + 1, affinity: ui.TextAffinity.upstream),
      ),
      ui.TextRange.empty,
    );
  });

  test('Paragraph computeLineMetrics/getLineMetricsAt', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('Line1\nLine2\nLine3');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    final lineMetrics = paragraph.computeLineMetrics();
    expect(lineMetrics.length, 3);
    expect(lineMetrics[0].lineNumber, 0);
    expect(lineMetrics[1].lineNumber, 1);
    expect(lineMetrics[2].lineNumber, 2);
    expect(lineMetrics[1], paragraph.getLineMetricsAt(1));
  });

  test('Paragraph numberOfLines/getLineNumberAt', () {
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('Line1\nLine2\nLine3');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    expect(paragraph.numberOfLines, 3);
    expect(paragraph.getLineNumberAt(3), 0);
    expect(paragraph.getLineNumberAt(9), 1);
    expect(paragraph.getLineNumberAt(15), 2);
  });

  test('Paragraph getGlyphInfoAt', () {
    const double epsilon = 0.001;
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('Line1\nLine2\nLine3');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    for (final line in paragraph.getLayout().lines) {
      double left = line.advance.left;
      for (final visualBlock in line.visualBlocks) {
        for (int i = visualBlock.textRange.start; i < visualBlock.textRange.end; i++) {
          final glyphInfo = paragraph.getGlyphInfoAt(i);
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
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('J');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    final glyphInfo = paragraph.getGlyphInfoAt(0);
    expect(glyphInfo != null, true);
  });

  test('Paragraph getClosestGlyphInfoForOffset', () {
    const double epsilon = 0.001;
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);
    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
    builder.addText('Line1\nLine2\nLine3');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));
    for (final line in paragraph.getLayout().lines) {
      for (final visualBlock in line.visualBlocks) {
        for (int i = visualBlock.textRange.start; i < visualBlock.textRange.end; i++) {
          final glyphInfo = paragraph.getGlyphInfoAt(i);
          if (glyphInfo != null) {
            final center = ui.Offset(
              glyphInfo.graphemeClusterLayoutBounds.left + epsilon,
              glyphInfo.graphemeClusterLayoutBounds.center.dy,
            );
            final closestGlyphInfo = paragraph.getClosestGlyphInfoForOffset(center);
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
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
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
    final WebParagraphStyle paragraphStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 20);

    final WebParagraphBuilder builder = WebParagraphBuilder(paragraphStyle);
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
}
