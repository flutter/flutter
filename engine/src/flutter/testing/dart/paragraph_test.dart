// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:test/test.dart';

void main() {
  group('placeholder boxes in logical order', () {
    const languages = <String, List<(String, TextDirection)>>{
      'Russian': <(String, TextDirection)>[('мир', TextDirection.ltr)],
      'Arabic': <(String, TextDirection)>[('نص', TextDirection.rtl)],
      'Hebrew': <(String, TextDirection)>[('עם', TextDirection.rtl)],
      'mixed Russian, Arabic and Hebrew': <(String, TextDirection)>[
        ('мир', TextDirection.ltr),
        ('نص', TextDirection.rtl),
        ('עם', TextDirection.rtl),
      ],
    };
    for (final sample in languages.entries) {
      for (final TextDirection direction in TextDirection.values) {
        test('${sample.key} preserve placeholder identity and script order: $direction', () {
          // Ahem makes geometry deterministic; the SkParagraph language test also
          // exercises real script fonts and asserts there are no missing glyphs.
          final builder = ParagraphBuilder(
            ParagraphStyle(textDirection: direction, fontFamily: 'Ahem', fontSize: 10),
          );
          final offsets = <int>[];
          var offset = 0;
          for (final (String word, TextDirection _) in sample.value) {
            for (var i = 0; i < 3; i++) {
              final text = '$word ';
              builder.addText(text);
              offset += text.length;
              if (i < 2) {
                offsets.add(offset++);
                builder.addPlaceholder(10.0 + 10 * offsets.length, 20, PlaceholderAlignment.bottom);
              }
            }
          }
          final Paragraph paragraph = builder.build();
          addTearDown(paragraph.dispose);
          for (final width in <double>[800, 80, 800]) {
            paragraph.layout(ParagraphConstraints(width: width));
            final List<TextBox> boxes = paragraph.getBoxesForPlaceholders();
            expect(boxes, hasLength(offsets.length));
            for (var i = 0; i < boxes.length; i++) {
              expect(boxes[i].right - boxes[i].left, closeTo(20 + 10 * i, 0.001));
              expect(boxes[i].direction, sample.value[i ~/ 2].$2);
              expect(boxes[i], paragraph.getBoxesForRange(offsets[i], offsets[i] + 1).single);
              final Rect rect = boxes[i].toRect();
              final double startX = boxes[i].direction == TextDirection.rtl
                  ? rect.right - rect.width / 4
                  : rect.left + rect.width / 4;
              expect(
                paragraph.getPositionForOffset(Offset(startX, rect.center.dy)).offset,
                offsets[i],
              );
              expect(
                paragraph
                    .getPositionForOffset(Offset(rect.left + rect.right - startX, rect.center.dy))
                    .offset,
                offsets[i] + 1,
              );
              if (width == 800 && i.isEven) {
                expect(boxes[i].top, boxes[i + 1].top);
                expect(
                  boxes[i].left < boxes[i + 1].left,
                  sample.value[i ~/ 2].$2 == TextDirection.ltr,
                );
              }
            }
          }
        });
      }
    }

    for (final TextDirection direction in TextDirection.values) {
      test('preserve identity across bidi layout and reflow: $direction', () {
        final builder = ParagraphBuilder(ParagraphStyle(textDirection: direction));
        for (final width in <double>[30, 50, 70]) {
          builder.addPlaceholder(width, 20, PlaceholderAlignment.bottom);
        }
        final Paragraph paragraph = builder.build();
        addTearDown(paragraph.dispose);

        for (final width in <double>[500, 80, 500]) {
          paragraph.layout(ParagraphConstraints(width: width));
          final List<TextBox> boxes = paragraph.getBoxesForPlaceholders();
          expect(boxes, hasLength(3));
          for (var i = 0; i < boxes.length; i++) {
            expect(boxes[i].right - boxes[i].left, 30 + 20 * i);
            expect(boxes[i].bottom - boxes[i].top, 20);
            expect(boxes[i].direction, direction);
            expect(boxes[i].toRect(), paragraph.getBoxesForRange(i, i + 1).single.toRect());
          }
          if (direction == TextDirection.rtl) {
            expect(boxes.map((TextBox box) => box.left), <double>[
              width - 30,
              width - 80,
              width - (width == 80 ? 70 : 150),
            ]);
          } else {
            expect(boxes.map((TextBox box) => box.left), <double>[
              0,
              30,
              if (width == 80) 0 else 80,
            ]);
          }
          expect(boxes[0].top, boxes[1].top);
          expect(boxes[2].top, width == 80 ? greaterThan(boxes[1].top) : boxes[1].top);
        }
      });

      test('preserve identity with an opposite-direction embedding: $direction', () {
        final builder = ParagraphBuilder(
          ParagraphStyle(textDirection: direction, fontFamily: 'Ahem', fontSize: 20),
        );
        builder.addPlaceholder(30, 20, PlaceholderAlignment.bottom);
        builder.addText(direction == TextDirection.rtl ? '\u202a' : '\u202b');
        builder.addPlaceholder(50, 20, PlaceholderAlignment.bottom);
        builder.addPlaceholder(70, 20, PlaceholderAlignment.bottom);
        builder.addText('\u202c');
        builder.addPlaceholder(90, 20, PlaceholderAlignment.bottom);
        final Paragraph paragraph = builder.build();
        addTearDown(paragraph.dispose);
        paragraph.layout(const ParagraphConstraints(width: 500));
        final List<TextBox> boxes = paragraph.getBoxesForPlaceholders();
        expect(boxes, hasLength(4));
        expect(
          boxes.map((TextBox box) => box.left),
          direction == TextDirection.rtl ? <double>[470, 350, 400, 260] : <double>[0, 100, 30, 150],
        );
        const offsets = <int>[0, 2, 3, 5];
        for (var i = 0; i < boxes.length; i++) {
          expect(boxes[i].right - boxes[i].left, 30 + 20 * i);
          final TextBox range = paragraph.getBoxesForRange(offsets[i], offsets[i] + 1).single;
          expect(boxes[i], range);
          final Rect rect = boxes[i].toRect();
          final double startX = boxes[i].direction == TextDirection.rtl
              ? rect.right - rect.width / 4
              : rect.left + rect.width / 4;
          expect(paragraph.getPositionForOffset(Offset(startX, rect.center.dy)).offset, offsets[i]);
          expect(
            paragraph
                .getPositionForOffset(Offset(rect.left + rect.right - startX, rect.center.dy))
                .offset,
            offsets[i] + 1,
          );
        }
      });
    }

    for (final ellipsis in <String?>[null, '\u2026']) {
      test('omit RTL placeholders after maxLines, ellipsis: $ellipsis', () {
        final builder = ParagraphBuilder(
          ParagraphStyle(
            textDirection: TextDirection.rtl,
            fontFamily: 'Ahem',
            fontSize: 20,
            maxLines: 1,
            ellipsis: ellipsis,
          ),
        );
        for (final width in <double>[30, 50, 70]) {
          builder.addPlaceholder(width, 20, PlaceholderAlignment.bottom);
        }
        final Paragraph paragraph = builder.build();
        addTearDown(paragraph.dispose);
        paragraph.layout(const ParagraphConstraints(width: 110));
        final List<TextBox> boxes = paragraph.getBoxesForPlaceholders();
        expect(boxes, hasLength(2));
        expect(boxes.map((TextBox box) => box.right - box.left), <double>[30, 50]);
        expect(boxes[0].left, greaterThan(boxes[1].left));
        expect(paragraph.getBoxesForRange(2, 3), isEmpty);
      });
    }
  });

  // Ahem font uses a constant ideographic/alphabetic baseline ratio.
  const kAhemBaselineRatio = 1.25;

  test('predictably lays out a single-line paragraph - Ahem', () {
    for (final fontSize in <double>[10.0, 20.0, 30.0, 40.0]) {
      final builder = ParagraphBuilder(
        ParagraphStyle(
          fontFamily: 'Ahem',
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.normal,
          fontSize: fontSize,
        ),
      );
      builder.addText('Test');
      final Paragraph paragraph = builder.build();
      paragraph.layout(const ParagraphConstraints(width: 400.0));

      expect(paragraph.height, closeTo(fontSize, 0.001));
      expect(paragraph.width, closeTo(400.0, 0.001));
      expect(paragraph.minIntrinsicWidth, closeTo(fontSize * 4.0, 0.001));
      expect(paragraph.maxIntrinsicWidth, closeTo(fontSize * 4.0, 0.001));
      expect(paragraph.alphabeticBaseline, closeTo(fontSize * .8, 0.001));
      expect(
        paragraph.ideographicBaseline,
        closeTo(paragraph.alphabeticBaseline * kAhemBaselineRatio, 0.001),
      );
    }
  });

  test('predictably lays out a single-line paragraph - FlutterTest', () {
    for (final fontSize in <double>[10.0, 20.0, 30.0, 40.0]) {
      final builder = ParagraphBuilder(
        ParagraphStyle(
          fontFamily: 'FlutterTest',
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.normal,
          fontSize: fontSize,
        ),
      );
      builder.addText('Test');
      final Paragraph paragraph = builder.build();
      paragraph.layout(const ParagraphConstraints(width: 400.0));

      expect(paragraph.height, fontSize);
      expect(paragraph.width, 400.0);
      expect(paragraph.minIntrinsicWidth, fontSize * 4.0);
      expect(paragraph.maxIntrinsicWidth, fontSize * 4.0);
      expect(paragraph.alphabeticBaseline, fontSize * 0.75);
      expect(paragraph.ideographicBaseline, fontSize);
    }
  });

  // dart:ui only passes ParagraphStyle.hyphens through to the text layout. This
  // checks that it gets there, by comparing layouts that differ only in that
  // setting, without depending on how wide the hyphen is.
  test('ParagraphStyle.hyphens is passed to the text layout', () {
    double longestLine(Hyphens? hyphens) {
      final builder = ParagraphBuilder(
        ParagraphStyle(fontFamily: 'FlutterTest', fontSize: 10.0, hyphens: hyphens),
      );
      // Narrow enough that the line breaks at the soft hyphen.
      builder.addText('abc\u00ADde');
      final Paragraph paragraph = builder.build();
      paragraph.layout(const ParagraphConstraints(width: 45.0));
      return paragraph.longestLine;
    }

    expect(longestLine(Hyphens.manual), greaterThan(longestLine(Hyphens.hidden)));
    expect(longestLine(null), longestLine(Hyphens.manual));
  });

  test('predictably lays out a multi-line paragraph', () {
    for (final fontSize in <double>[10.0, 20.0, 30.0, 40.0]) {
      final builder = ParagraphBuilder(
        ParagraphStyle(
          fontFamily: 'Ahem',
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.normal,
          fontSize: fontSize,
        ),
      );
      builder.addText('Test Ahem');
      final Paragraph paragraph = builder.build();
      paragraph.layout(ParagraphConstraints(width: fontSize * 5.0));

      expect(paragraph.height, closeTo(fontSize * 2.0, 0.001)); // because it wraps
      expect(paragraph.width, closeTo(fontSize * 5.0, 0.001));
      expect(paragraph.minIntrinsicWidth, closeTo(fontSize * 4.0, 0.001));

      // TODO(yjbanov): see https://github.com/flutter/flutter/issues/21965
      expect(paragraph.maxIntrinsicWidth, closeTo(fontSize * 9.0, 0.001));
      expect(paragraph.alphabeticBaseline, closeTo(fontSize * .8, 0.001));
      expect(
        paragraph.ideographicBaseline,
        closeTo(paragraph.alphabeticBaseline * kAhemBaselineRatio, 0.001),
      );
    }
  });

  test('getLineBoundary', () {
    const fontSize = 10.0;
    final builder = ParagraphBuilder(
      ParagraphStyle(
        fontFamily: 'Ahem',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.normal,
        fontSize: fontSize,
      ),
    );
    builder.addText('Test Ahem');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: fontSize * 5.0));

    // Wraps to two lines.
    expect(paragraph.height, closeTo(fontSize * 2.0, 0.001));

    const wrapPositionDown = TextPosition(offset: 5);
    TextRange line = paragraph.getLineBoundary(wrapPositionDown);
    expect(line.start, 5);
    expect(line.end, 9);

    const wrapPositionUp = TextPosition(offset: 5, affinity: TextAffinity.upstream);
    line = paragraph.getLineBoundary(wrapPositionUp);
    expect(line.start, 0);
    expect(line.end, 5);

    const wrapPositionStart = TextPosition(offset: 0);
    line = paragraph.getLineBoundary(wrapPositionStart);
    expect(line.start, 0);
    expect(line.end, 5);

    const wrapPositionEnd = TextPosition(offset: 9);
    line = paragraph.getLineBoundary(wrapPositionEnd);
    expect(line.start, 5);
    expect(line.end, 9);
  });

  test('getLineBoundary RTL', () {
    const fontSize = 10.0;
    final builder = ParagraphBuilder(
      ParagraphStyle(
        fontFamily: 'Ahem',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.normal,
        fontSize: fontSize,
        textDirection: TextDirection.rtl,
      ),
    );
    builder.addText('القاهرةالقاهرة');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: fontSize * 5.0));

    // Wraps to three lines.
    expect(paragraph.height, closeTo(fontSize * 3.0, 0.001));

    const wrapPositionDown = TextPosition(offset: 5);
    TextRange line = paragraph.getLineBoundary(wrapPositionDown);
    expect(line.start, 5);
    expect(line.end, 10);

    const wrapPositionUp = TextPosition(offset: 5, affinity: TextAffinity.upstream);
    line = paragraph.getLineBoundary(wrapPositionUp);
    expect(line.start, 0);
    expect(line.end, 5);

    const wrapPositionStart = TextPosition(offset: 0);
    line = paragraph.getLineBoundary(wrapPositionStart);
    expect(line.start, 0);
    expect(line.end, 5);

    const wrapPositionEnd = TextPosition(offset: 9);
    line = paragraph.getLineBoundary(wrapPositionEnd);
    expect(line.start, 5);
    expect(line.end, 10);
  });

  test('getLineBoundary empty line', () {
    const fontSize = 10.0;
    final builder = ParagraphBuilder(
      ParagraphStyle(
        fontFamily: 'Ahem',
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.normal,
        fontSize: fontSize,
        textDirection: TextDirection.rtl,
      ),
    );
    builder.addText('Test\n\nAhem');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: fontSize * 5.0));

    // Three lines due to line breaks, with the middle line being empty.
    expect(paragraph.height, closeTo(fontSize * 3.0, 0.001));

    const emptyLinePosition = TextPosition(offset: 5);
    TextRange line = paragraph.getLineBoundary(emptyLinePosition);
    expect(line.start, 5);
    expect(line.end, 5);

    // Since these are hard newlines, TextAffinity has no effect here.
    const emptyLinePositionUpstream = TextPosition(offset: 5, affinity: TextAffinity.upstream);
    line = paragraph.getLineBoundary(emptyLinePositionUpstream);
    expect(line.start, 5);
    expect(line.end, 5);

    const endOfFirstLinePosition = TextPosition(offset: 4);
    line = paragraph.getLineBoundary(endOfFirstLinePosition);
    expect(line.start, 0);
    expect(line.end, 4);

    const startOfLastLinePosition = TextPosition(offset: 6);
    line = paragraph.getLineBoundary(startOfLastLinePosition);
    expect(line.start, 6);
    expect(line.end, 10);
  });

  test('getLineMetricsAt', () {
    const fontSize = 10.0;
    final builder = ParagraphBuilder(
      ParagraphStyle(fontSize: fontSize, textDirection: TextDirection.rtl, height: 2.0),
    );
    builder.addText('Test\npppp');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 100.0));
    final LineMetrics? line = paragraph.getLineMetricsAt(1);
    expect(line?.hardBreak, isTrue);
    expect(line?.ascent, 15.0);
    expect(line?.descent, 5.0);
    expect(line?.height, 20.0);
    expect(line?.width, 4 * 10.0);
    expect(line?.left, 100.0 - 40.0);
    expect(line?.baseline, 20.0 + 15.0);
    expect(line?.lineNumber, 1);
  });

  test('line number', () {
    const fontSize = 10.0;
    final builder = ParagraphBuilder(ParagraphStyle(fontSize: fontSize));
    builder.addText('Test\n\nTest');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 100.0));
    expect(paragraph.numberOfLines, 3);
    expect(paragraph.getLineNumberAt(4), 0); // first LF
    expect(paragraph.getLineNumberAt(5), 1); // second LF
    expect(paragraph.getLineNumberAt(6), 2); // "T" in the second "Test"
  });

  test('empty paragraph', () {
    const fontSize = 10.0;
    final Paragraph paragraph = ParagraphBuilder(ParagraphStyle(fontSize: fontSize)).build();
    paragraph.layout(const ParagraphConstraints(width: double.infinity));

    expect(paragraph.getClosestGlyphInfoForOffset(Offset.zero), isNull);
    expect(paragraph.getGlyphInfoAt(0), isNull);

    expect(paragraph.getLineMetricsAt(0), isNull);
    expect(paragraph.numberOfLines, 0);
    expect(paragraph.getLineNumberAt(0), isNull);

    expect(paragraph.getGlyphInfoAt(0), isNull);
    expect(paragraph.getClosestGlyphInfoForOffset(Offset.zero), isNull);
  });

  test('OOB indices as input', () {
    const fontSize = 10.0;
    final builder = ParagraphBuilder(
      ParagraphStyle(fontSize: fontSize, maxLines: 1, ellipsis: 'BBB'),
    )..addText('A' * 100);
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 100));

    expect(paragraph.numberOfLines, 1);

    expect(paragraph.getLineMetricsAt(-1), isNull);
    expect(paragraph.getLineMetricsAt(0)?.lineNumber, 0);
    expect(paragraph.getLineMetricsAt(1), isNull);

    expect(paragraph.getLineNumberAt(-1), isNull);
    expect(paragraph.getLineNumberAt(0), 0);
    expect(paragraph.getLineNumberAt(6), 0);
    // The last 3 characters on the first line are ellipsized with BBB.
    expect(paragraph.getLineMetricsAt(7), isNull);

    expect(paragraph.getGlyphInfoAt(-1), isNull);
    expect(
      paragraph.getGlyphInfoAt(0)?.graphemeClusterCodeUnitRange,
      const TextRange(start: 0, end: 1),
    );
    expect(
      paragraph.getGlyphInfoAt(6)?.graphemeClusterCodeUnitRange,
      const TextRange(start: 6, end: 7),
    );
    expect(paragraph.getGlyphInfoAt(7), isNull);
    expect(paragraph.getGlyphInfoAt(200), isNull);
  });

  test('querying glyph info', () {
    const fontSize = 10.0;
    final builder = ParagraphBuilder(ParagraphStyle(fontSize: fontSize));
    builder.addText('Test\nTest');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: double.infinity));

    final GlyphInfo? bottomRight = paragraph.getClosestGlyphInfoForOffset(const Offset(99.0, 99.0));
    final GlyphInfo? last = paragraph.getGlyphInfoAt(8);
    expect(bottomRight, equals(last));
    expect(bottomRight, isNot(paragraph.getGlyphInfoAt(0)));

    expect(bottomRight?.graphemeClusterLayoutBounds, const Rect.fromLTWH(30, 10, 10, 10));
    expect(bottomRight?.graphemeClusterCodeUnitRange, const TextRange(start: 8, end: 9));
    expect(bottomRight?.writingDirection, TextDirection.ltr);
  });

  test('painting a disposed paragraph does not crash', () {
    final Paragraph paragraph = ParagraphBuilder(ParagraphStyle()).build();
    paragraph.dispose();

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    void callback() {
      canvas.drawParagraph(paragraph, Offset.zero);
    }

    expect(callback, throwsA(isA<AssertionError>()));
  });

  test('rounding hack disabled', () {
    const fontSize = 1.25;
    const text = '12345';

    expect((fontSize * text.length).truncate(), isNot(fontSize * text.length));
    final builder = ParagraphBuilder(ParagraphStyle(fontSize: fontSize));
    builder.addText(text);
    final Paragraph paragraph = builder.build()
      ..layout(const ParagraphConstraints(width: text.length * fontSize));
    expect(paragraph.maxIntrinsicWidth, text.length * fontSize);
    switch (paragraph.computeLineMetrics()) {
      case [LineMetrics(width: final double width)]:
        expect(width, text.length * fontSize);
      case final List<LineMetrics> metrics:
        expect(metrics, hasLength(1));
    }
  });

  test('kTextHeightNone unsets the height multiplier', () {
    const double fontSize = 10;
    final builder = ParagraphBuilder(ParagraphStyle(fontSize: fontSize, height: 10));
    builder.pushStyle(TextStyle(height: kTextHeightNone));
    builder.addText('A');
    final Paragraph paragraph = builder.build()..layout(const ParagraphConstraints(width: 1000));
    expect(paragraph.height, fontSize);
  });

  test('kTextHeightNone ParagraphStyle', () {
    const double fontSize = 10;
    final builder = ParagraphBuilder(ParagraphStyle(fontSize: fontSize, height: kTextHeightNone));
    builder.addText('A');
    final Paragraph paragraph = builder.build()..layout(const ParagraphConstraints(width: 1000));
    expect(paragraph.height, fontSize);
  });

  test('kTextHeightNone StrutStyle', () {
    const double fontSize = 10;
    final builder = ParagraphBuilder(
      ParagraphStyle(
        fontSize: 100,
        strutStyle: StrutStyle(forceStrutHeight: true, height: kTextHeightNone, fontSize: fontSize),
      ),
    );
    builder.addText('A');
    final Paragraph paragraph = builder.build()..layout(const ParagraphConstraints(width: 1000));
    expect(paragraph.height, fontSize);
  });
}
