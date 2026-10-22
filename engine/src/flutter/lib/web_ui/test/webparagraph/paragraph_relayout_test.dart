// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart';

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests();

  WebParagraph build(
    void Function(WebParagraphBuilder builder) addContent, {
    TextDirection textDirection = TextDirection.ltr,
    WebTextStyle? textStyle,
  }) {
    final builder = WebParagraphBuilder(
      WebParagraphStyle(fontFamily: 'Roboto', fontSize: 20, textDirection: textDirection),
    );
    builder.pushStyle(textStyle ?? WebTextStyle(color: const Color(0xFF000000)));
    addContent(builder);
    return builder.build();
  }

  final cases = <String, WebParagraph Function()>{
    'latin with trailing spaces': () =>
        build((b) => b.addText('Hello world,   quick brown fox  ' * 4)),
    'letter and word spacing': () => build(
      (b) => b.addText('Spaced letters and words here ' * 3),
      textStyle: WebTextStyle(color: const Color(0xFF000000), letterSpacing: 2, wordSpacing: 5),
    ),
    'ligatures and kerning': () => build((b) => b.addText('office affine AVATAR WAVE To Ty ' * 3)),
    'RTL paragraph': () => build(
      (b) => b.addText(
        '\u0645\u0631\u062D\u0628\u0627 \u0628\u0627\u0644\u0639\u0627\u0644\u0645 42 ' * 4,
      ),
      textDirection: TextDirection.rtl,
    ),
    'multi-span BiDi': () => build((b) {
      b.addText('Hello, ');
      b.pushStyle(WebTextStyle(color: const Color(0xFF0000FF), fontWeight: FontWeight.bold));
      b.addText('world \u05E9\u05DC\u05D5\u05DD (\u05E2\u05D5\u05DC\u05DD) 123 ');
      b.pop();
      b.addText('tail \u0645\u0631\u062D\u0628\u0627 end');
    }, textDirection: TextDirection.rtl),
    'emoji': () => build(
      (b) => b.addText('Hi \u{1F44D}\u{1F3FD} \u{1F468}\u200D\u{1F469}\u200D\u{1F467} ok ' * 3),
    ),
    'hard line breaks': () => build((b) => b.addText('First line\nSecond  \n\nFourth line\n')),
    'placeholders': () => build((b) {
      b.addText('Before ');
      b.addPlaceholder(30, 20, PlaceholderAlignment.middle);
      b.addText(' after the placeholder and more text');
    }),
    'zero-width space and soft hyphen': () =>
        build((b) => b.addText('a\u200Bb soft\u00ADhyphen a\u200Bb soft\u00ADhyphen ' * 3)),
    'combining marks and directional marks': () =>
        build((b) => b.addText('e\u0301 x\u200Ey e\u0301 x\u200Ey ' * 3)),
    'Latin mixed with CJK': () =>
        build((b) => b.addText('Latin \u6F22\u5B57\u304B\u306A mixed \u4E2D\u6587 text ' * 3)),
    'CR LF line breaks': () => build((b) => b.addText('First line\r\nSecond line  \r\nThird')),
    'negative letter spacing': () => build(
      (b) => b.addText('Tight letters and words here ' * 3),
      textStyle: WebTextStyle(color: const Color(0xFF000000), letterSpacing: -1.5),
    ),
  };

  group('re-layout block geometry', () {
    for (final MapEntry<String, WebParagraph Function()> entry in cases.entries) {
      test('re-layout makes no text metrics queries: ${entry.key}', () {
        final WebParagraph paragraph = entry.value();
        // First layout measures each text span once plus the trailing empty cluster span,
        // deriving cluster advances from DomTextCluster.x without getSelectionRects queries.
        debugTextMetricsQueryCount = 0;
        paragraph.layout(const ParagraphConstraints(width: 500));
        expect(debugTextMetricsQueryCount, paragraph.spans.whereType<TextSpan>().length + 1);

        debugTextMetricsQueryCount = 0;
        for (final width in <double>[120, 260, 80, 500]) {
          paragraph.layout(ParagraphConstraints(width: width));
        }
        expect(debugTextMetricsQueryCount, 0);

        // Ink bounds are measured once, when painting first needs them.
        paragraph.paintBounds;
        expect(debugTextMetricsQueryCount, greaterThan(0));
        debugTextMetricsQueryCount = 0;
        paragraph.paintBounds;
        expect(debugTextMetricsQueryCount, 0);
        paragraph.dispose();
      });
      test('block advance matches the span metrics: ${entry.key}', () {
        final WebParagraph paragraph = entry.value();
        for (final width in <double>[500, 120, 260, 80]) {
          paragraph.layout(ParagraphConstraints(width: width));
          var blocks = 0;
          for (final TextLine line in paragraph.lines) {
            for (final LineBlock block in line.visualBlocks) {
              if (block is! TextBlock || block is EllipsisBlock) {
                continue;
              }
              blocks++;
              expect(
                block.advance,
                block.span.getBlockSelection(block),
                reason: 'width $width, block ${block.textRange}',
              );
            }
          }
          expect(blocks, greaterThan(0));
        }
        paragraph.dispose();
      });

      test('trailing whitespace width matches the span metrics: ${entry.key}', () {
        final WebParagraph paragraph = entry.value();
        for (final width in <double>[500, 120, 260, 80]) {
          paragraph.layout(ParagraphConstraints(width: width));
          for (final TextLine line in paragraph.lines) {
            var lastWhitespaceWidth = 0.0;
            for (final LineBlock block in line.visualBlocks) {
              if (block is! TextBlock || block is EllipsisBlock) {
                continue;
              }
              // intersect() leaves start > end for disjoint ranges.
              final TextRange whitespaces = block.textRange.intersect(line.whitespacesRange);
              if (whitespaces.start >= whitespaces.end) {
                expect(block.whitespacesWidth, 0.0, reason: 'width $width, ${block.textRange}');
                continue;
              }
              lastWhitespaceWidth = block.span
                  .getTextRangeSelectionInBlock(block, whitespaces)
                  .width;
              expect(
                block.whitespacesWidth,
                lastWhitespaceWidth,
                reason: 'width $width, block ${block.textRange}',
              );
            }
            if (!line.visualBlocks.any((LineBlock block) => block is EllipsisBlock)) {
              expect(line.trailingSpacesWidth, lastWhitespaceWidth, reason: 'width $width');
            }
          }
        }
        paragraph.dispose();
      });
    }

    for (final align in <TextAlign>[TextAlign.left, TextAlign.center, TextAlign.right]) {
      test('paint bounds follow the latest layout: $align', () {
        // The trailing newline adds a synthetic empty line that repeats the previous line's ink.
        WebParagraph buildAligned() {
          final builder = WebParagraphBuilder(
            WebParagraphStyle(fontFamily: 'Roboto', fontSize: 20, textAlign: align),
          );
          builder.pushStyle(WebTextStyle(color: const Color(0xFF000000)));
          builder.addText('Hello world,   quick brown fox  ' * 4 + '\n');
          return builder.build();
        }

        final WebParagraph paragraph = buildAligned();
        paragraph.layout(const ParagraphConstraints(width: 80));
        final Rect narrowBounds = paragraph.paintBounds;
        paragraph.layout(const ParagraphConstraints(width: 500));

        final WebParagraph fresh = buildAligned();
        fresh.layout(const ParagraphConstraints(width: 500));
        expect(paragraph.paintBounds, fresh.paintBounds);
        expect(paragraph.paintBounds, isNot(narrowBounds));
        paragraph.dispose();
        fresh.dispose();
      });
    }

    test('a wider re-layout drops the ellipsis of an earlier narrow layout', () {
      WebParagraph buildEllipsized() {
        final builder = WebParagraphBuilder(
          WebParagraphStyle(fontFamily: 'Roboto', fontSize: 20, maxLines: 1, ellipsis: '...'),
        );
        builder.pushStyle(WebTextStyle(color: const Color(0xFF000000)));
        builder.addText('Fits in a wide line');
        return builder.build();
      }

      bool hasEllipsis(WebParagraph paragraph) => paragraph.lines.any(
        (TextLine line) => line.visualBlocks.any((LineBlock block) => block is EllipsisBlock),
      );

      final WebParagraph paragraph = buildEllipsized();
      paragraph.layout(const ParagraphConstraints(width: 80));
      expect(hasEllipsis(paragraph), isTrue);
      paragraph.layout(const ParagraphConstraints(width: 500));

      final WebParagraph fresh = buildEllipsized();
      fresh.layout(const ParagraphConstraints(width: 500));
      expect(hasEllipsis(fresh), isFalse);
      expect(hasEllipsis(paragraph), isFalse);
      expect(paragraph.lines.single.advance, fresh.lines.single.advance);
      paragraph.dispose();
      fresh.dispose();
    });

    test('cluster advance matches the span selection across scripts and negative spacing', () {
      final extraCases = <WebParagraph>[
        for (final WebParagraph Function() make in cases.values) make(),
        build((b) => b.addText('\u0645\u0631\u062D\u0628\u0627'), textDirection: TextDirection.rtl),
        build(
          (b) => b.addText('\u0644\u0627 \u0644\u0623 \u0644\u0625 \u0644\u0622'),
          textDirection: TextDirection.rtl,
        ),
        build(
          (b) => b.addText('iiiiiiabcdef'),
          textStyle: WebTextStyle(color: const Color(0xFF000000), letterSpacing: -15),
        ),
      ];
      for (final paragraph in extraCases) {
        paragraph.layout(const ParagraphConstraints(width: 500));
        for (final WebCluster cluster in paragraph.getLayout().allClusters) {
          if (cluster is TextCluster) {
            expect(cluster.advance, cluster.span.getClusterSelection(cluster));
          }
        }
        paragraph.dispose();
      }
    });
  });
}
