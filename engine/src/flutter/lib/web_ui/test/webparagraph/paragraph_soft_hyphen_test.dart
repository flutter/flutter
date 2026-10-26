// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;
import 'package:web_engine_tester/golden_tester.dart';

import '../common/test_initialization.dart';
import '../ui/utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

const double tolerance = 0.001;

// Every glyph of the FlutterTest font is 1 em wide, so at font size 10 each
// character, including the hyphen, is 10 wide. The soft hyphen itself is 0.
ui.Paragraph layoutParagraph(
  String text,
  double width, {
  ui.Hyphens? hyphens,
  ui.TextDirection textDirection = ui.TextDirection.ltr,
  ui.TextAlign? textAlign,
  int? maxLines,
  String? ellipsis,
}) {
  final builder = ui.ParagraphBuilder(
    ui.ParagraphStyle(
      fontFamily: 'FlutterTest',
      fontSize: 10,
      hyphens: hyphens,
      textDirection: textDirection,
      textAlign: textAlign,
      maxLines: maxLines,
      ellipsis: ellipsis,
    ),
  );
  builder.addText(text);
  return builder.build()..layout(ui.ParagraphConstraints(width: width));
}

/// The line number of each character in [text], with "|" between lines.
///
/// For example "ab|cd" for a paragraph that broke between "b" and "c".
String lineBreaks(ui.Paragraph paragraph, String text) {
  final buffer = StringBuffer();
  int? previousLine;
  for (var i = 0; i < text.length; i++) {
    if (text.codeUnitAt(i) == 0x00AD) {
      continue;
    }
    final int? line = paragraph.getLineNumberAt(i);
    if (previousLine != null && line != previousLine) {
      buffer.write('|');
    }
    buffer.write(text[i]);
    previousLine = line;
  }
  return buffer.toString();
}

Future<void> testMain() async {
  setUpUnitTests(
    withImplicitView: true,
    setUpTestViewDimensions: false,
    testEnvironment: const ui_web.TestEnvironment(forceTestFonts: true),
  );

  group('Soft hyphen', () {
    test('manual draws a hyphen at a soft hyphen break', () {
      const text = 'abcd\u00ADe';
      final ui.Paragraph manual = layoutParagraph(text, 45, hyphens: ui.Hyphens.manual);
      final ui.Paragraph hidden = layoutParagraph(text, 45, hyphens: ui.Hyphens.hidden);

      expect(lineBreaks(manual, text), 'abcd|e');
      expect(lineBreaks(hidden, text), 'abcd|e');
      expect(manual.longestLine, closeTo(50, tolerance));
      expect(hidden.longestLine, closeTo(40, tolerance));
    });

    test('unspecified behaves like manual', () {
      const text = 'abcd\u00ADe';
      expect(
        layoutParagraph(text, 45).longestLine,
        closeTo(layoutParagraph(text, 45, hyphens: ui.Hyphens.manual).longestLine, tolerance),
      );
    });

    test('is invisible in the middle of a line', () {
      final ui.Paragraph paragraph = layoutParagraph('abcd\u00ADe', double.infinity);
      expect(paragraph.numberOfLines, 1);
      expect(paragraph.longestLine, closeTo(50, tolerance));
    });

    test('draws only the hyphen at the break when there are several', () {
      final ui.Paragraph paragraph = layoutParagraph('a\u00ADb\u00ADc\u00ADdef', 45);
      expect(lineBreaks(paragraph, 'a\u00ADb\u00ADc\u00ADdef'), 'abc|def');
      expect(paragraph.longestLine, closeTo(40, tolerance));
    });

    test('draws no hyphen at the end of the text', () {
      const text = 'ab cd\u00AD';
      final ui.Paragraph paragraph = layoutParagraph(text, 25);
      expect(lineBreaks(paragraph, text), 'ab |cd');
      expect(paragraph.longestLine, closeTo(20, tolerance));
    });

    test('draws no hyphen when the line breaks at a space after it', () {
      const text = 'ab\u00AD cd';
      final ui.Paragraph paragraph = layoutParagraph(text, 25);
      expect(lineBreaks(paragraph, text), 'ab |cd');
      expect(paragraph.longestLine, closeTo(20, tolerance));
    });

    test('draws no hyphen before a newline', () {
      const text = 'ab\u00AD\ncd';
      final ui.Paragraph paragraph = layoutParagraph(text, 100);
      expect(paragraph.numberOfLines, 2);
      expect(paragraph.longestLine, closeTo(20, tolerance));
    });

    test('leaves the hyphen out of maxIntrinsicWidth and LineMetrics.width', () {
      final ui.Paragraph paragraph = layoutParagraph('abcd\u00ADe', 45);
      expect(paragraph.maxIntrinsicWidth, closeTo(50, tolerance));
      final List<ui.LineMetrics> metrics = paragraph.computeLineMetrics();
      expect(metrics, hasLength(2));
      expect(metrics[0].width, closeTo(40, tolerance));
      expect(metrics[1].width, closeTo(10, tolerance));
    });
  });

  // These follow SkParagraph's layoutWithSoftHyphens tests.
  group('Soft hyphen line breaking', () {
    test('reserves room for the hyphen', () {
      const text = 'xy abcd\u00ADefgh';
      // Wide enough for "xy abcd" but not for "xy abcd-".
      final ui.Paragraph manual = layoutParagraph(text, 75);
      final ui.Paragraph hidden = layoutParagraph(text, 75, hyphens: ui.Hyphens.hidden);

      expect(lineBreaks(manual, text), 'xy |abcd|efgh');
      expect(manual.longestLine, lessThanOrEqualTo(75));
      expect(lineBreaks(hidden, text), 'xy abcd|efgh');
    });

    test('falls back to an earlier soft hyphen', () {
      const text = 'ab\u00ADcd\u00ADefgh';
      final ui.Paragraph paragraph = layoutParagraph(text, 45);
      expect(lineBreaks(paragraph, text), 'ab|cd|efgh');
      expect(paragraph.longestLine, closeTo(40, tolerance));
    });

    test('falls back past soft hyphens that do not fit', () {
      const text = 'x ab\u00ADcd\u00ADef';
      final ui.Paragraph paragraph = layoutParagraph(text, 45);
      expect(lineBreaks(paragraph, text), 'x |ab|cdef');
    });

    test('lets the hyphen overflow when there is no earlier break', () {
      const text = 'abcd\u00ADefgh';
      final ui.Paragraph paragraph = layoutParagraph(text, 45);
      expect(lineBreaks(paragraph, text), 'abcd|efgh');
      expect(paragraph.longestLine, closeTo(50, tolerance));
    });

    test('reserves nothing when the line does not break at the soft hyphen', () {
      // "i" is half as wide as the hyphen, so "xy abcdi" fits but "xy abcd-" does not.
      final builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(fontFamily: 'FlutterTest', fontSize: 10),
      );
      builder.addText('xy abcd\u00AD');
      builder.pushStyle(ui.TextStyle(fontSize: 5));
      builder.addText('i');
      builder.pop();
      builder.addText(' jklm');
      final ui.Paragraph paragraph = builder.build()
        ..layout(const ui.ParagraphConstraints(width: 77));

      expect(lineBreaks(paragraph, 'xy abcd\u00ADi jklm'), 'xy abcdi |jklm');
      expect(paragraph.longestLine, closeTo(75, tolerance));
    });

    test('reserves no room on a line that gets an ellipsis', () {
      const text = 'xy abcd\u00ADefgh ijkl';
      final ui.Paragraph manual = layoutParagraph(text, 75, maxLines: 1, ellipsis: '...');
      final ui.Paragraph hidden = layoutParagraph(
        text,
        75,
        maxLines: 1,
        ellipsis: '...',
        hyphens: ui.Hyphens.hidden,
      );

      expect(manual.didExceedMaxLines, isTrue);
      expect(manual.longestLine, closeTo(hidden.longestLine, tolerance));
      expect(
        manual.computeLineMetrics().single.width,
        closeTo(hidden.computeLineMetrics().single.width, tolerance),
      );
    });

    test('gives no ellipsis to a line that went back to an earlier break', () {
      const text = 'x ab\u00ADcd\u00ADef gh ij';
      final ui.Paragraph paragraph = layoutParagraph(text, 45, maxLines: 2, ellipsis: '...');

      expect(paragraph.numberOfLines, 2);
      expect(paragraph.didExceedMaxLines, isTrue);
      expect(paragraph.getLineNumberAt(0), 0);
      expect(paragraph.getLineNumberAt(2), 1);
    });

    test('lays out the same again after a different width', () {
      const text = 'abcd\u00ADefgh';
      final ui.Paragraph paragraph = layoutParagraph(text, 45);
      expect(lineBreaks(paragraph, text), 'abcd|efgh');
      expect(paragraph.longestLine, closeTo(50, tolerance));

      paragraph.layout(const ui.ParagraphConstraints(width: 1000));
      expect(paragraph.numberOfLines, 1);
      expect(paragraph.longestLine, closeTo(80, tolerance));

      paragraph.layout(const ui.ParagraphConstraints(width: 45));
      expect(lineBreaks(paragraph, text), 'abcd|efgh');
      expect(paragraph.longestLine, closeTo(50, tolerance));
    });

    test('can end the last line with maxLines and no ellipsis', () {
      final ui.Paragraph paragraph = layoutParagraph('abcd\u00ADefgh', 45, maxLines: 1);
      expect(paragraph.didExceedMaxLines, isTrue);
      expect(paragraph.longestLine, closeTo(50, tolerance));
    });

    test('measures the hyphen in the style of the soft hyphen', () {
      final builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(fontFamily: 'FlutterTest', fontSize: 10),
      );
      builder.pushStyle(ui.TextStyle(fontSize: 20));
      builder.addText('ab\u00AD');
      builder.pop();
      builder.addText('cd');
      final ui.Paragraph paragraph = builder.build()
        ..layout(const ui.ParagraphConstraints(width: 50));

      expect(lineBreaks(paragraph, 'ab\u00ADcd'), 'ab|cd');
      // "ab" and the hyphen are 20 each.
      expect(paragraph.longestLine, closeTo(60, tolerance));
    });

    test('ignores a soft hyphen immediately after a space', () {
      // When U+00AD immediately follows a space, breaking before "ccc" breaks at the space
      // with no pending word before the hyphen, so no hyphen width is reserved or counted in
      // minIntrinsicWidth.
      const text = 'a bbbb \u00ADccc';
      final ui.Paragraph paragraph = layoutParagraph(text, 65);
      expect(lineBreaks(paragraph, text), 'a bbbb |ccc');
      expect(paragraph.minIntrinsicWidth, closeTo(40, tolerance));
    });

    test('handles a soft hyphen in its own styled span', () {
      // When U+00AD is in a separate styled span and the line does not break there, the
      // empty cluster range of the soft-hyphen span must not emit a visual block or out-of-range
      // cluster lookup in LTR or RTL.
      for (final ui.TextDirection direction in ui.TextDirection.values) {
        final builder = ui.ParagraphBuilder(
          ui.ParagraphStyle(fontFamily: 'FlutterTest', fontSize: 10, textDirection: direction),
        );
        builder.addText('ab');
        builder.pushStyle(ui.TextStyle(color: const ui.Color(0xFFFF0000)));
        builder.addText('\u00AD');
        builder.pop();
        builder.addText('cd');
        final ui.Paragraph paragraph = builder.build()
          ..layout(const ui.ParagraphConstraints(width: 1000));

        expect(paragraph.longestLine, closeTo(40, tolerance));
        expect(paragraph.getBoxesForRange(0, 5), hasLength(2));
      }
    });
  });

  group('Soft hyphen intrinsic widths', () {
    test('minIntrinsicWidth counts the hyphen', () {
      const text = 'xy abcd\u00ADef';
      final double manual = layoutParagraph(text, 1000).minIntrinsicWidth;
      final double hidden = layoutParagraph(
        text,
        1000,
        hyphens: ui.Hyphens.hidden,
      ).minIntrinsicWidth;

      expect(manual, closeTo(50, tolerance));
      expect(hidden, closeTo(40, tolerance));
    });

    test('a soft hyphen at the end of the text adds nothing', () {
      const text = 'xy abcd\u00AD';
      expect(
        layoutParagraph(text, 1000).minIntrinsicWidth,
        closeTo(
          layoutParagraph(text, 1000, hyphens: ui.Hyphens.hidden).minIntrinsicWidth,
          tolerance,
        ),
      );
    });

    test('text laid out at its minIntrinsicWidth fits', () {
      const text = 'xy abcd\u00ADef';
      final double minIntrinsicWidth = layoutParagraph(text, 1000).minIntrinsicWidth;
      final ui.Paragraph paragraph = layoutParagraph(text, minIntrinsicWidth);

      expect(lineBreaks(paragraph, text), 'xy |abcd|ef');
      expect(paragraph.longestLine, lessThanOrEqualTo(minIntrinsicWidth));
    });
  });

  group('Soft hyphen queries', () {
    test('the soft hyphen has one box, over the drawn hyphen', () {
      final ui.Paragraph paragraph = layoutParagraph('abcd\u00ADe', 45);
      final List<ui.TextBox> boxes = paragraph.getBoxesForRange(4, 5);

      expect(boxes, hasLength(1));
      expect(boxes.single.left, closeTo(40, tolerance));
      expect(boxes.single.right, closeTo(50, tolerance));
    });

    test('selecting the line covers the hyphen', () {
      final ui.Paragraph paragraph = layoutParagraph('abcd\u00ADe', 45);
      final List<ui.TextBox> boxes = paragraph.getBoxesForRange(0, 5);

      expect(boxes.first.left, closeTo(0, tolerance));
      expect(boxes.last.right, closeTo(50, tolerance));
    });

    test('a hidden soft hyphen has no box', () {
      final ui.Paragraph paragraph = layoutParagraph('abcd\u00ADe', 45, hyphens: ui.Hyphens.hidden);
      expect(paragraph.getBoxesForRange(4, 5), isEmpty);
    });

    test('the glyph at the soft hyphen is the drawn hyphen', () {
      final ui.Paragraph paragraph = layoutParagraph('abcd\u00ADe', 45);
      final ui.GlyphInfo? glyph = paragraph.getGlyphInfoAt(4);

      expect(glyph, isNotNull);
      expect(glyph!.graphemeClusterCodeUnitRange, const ui.TextRange(start: 4, end: 5));
      expect(glyph.graphemeClusterLayoutBounds.left, closeTo(40, tolerance));
      expect(glyph.graphemeClusterLayoutBounds.right, closeTo(50, tolerance));
    });

    test('hit testing the hyphen gives the position after the soft hyphen', () {
      final ui.Paragraph paragraph = layoutParagraph('abcd\u00ADe', 45);
      expect(paragraph.getPositionForOffset(const ui.Offset(45, 5)).offset, 5);
      expect(paragraph.getPositionForOffset(const ui.Offset(44, 5)).offset, 5);
      // To the left of the hyphen, it is a normal character.
      expect(paragraph.getPositionForOffset(const ui.Offset(36, 5)).offset, 4);
    });

    test('right alignment includes the hyphen', () {
      const text = 'abcd\u00ADefghi';
      final ui.Paragraph paragraph = layoutParagraph(text, 55, textAlign: ui.TextAlign.right);

      expect(lineBreaks(paragraph, text), 'abcd|efghi');
      // "abcd-" is 50 wide, so the line is shifted by 5.
      expect(paragraph.getBoxesForRange(0, 1).single.left, closeTo(5, tolerance));
      expect(paragraph.getBoxesForRange(4, 5).single.right, closeTo(55, tolerance));
    });

    test('in an RTL paragraph, the hyphen is at the left end of the line', () {
      const text = 'inter\u00ADnational';
      final ui.Paragraph paragraph = layoutParagraph(text, 80, textDirection: ui.TextDirection.rtl);
      final ui.TextBox hyphen = paragraph.getBoxesForRange(5, 6).single;
      final ui.TextBox inter = paragraph.getBoxesForRange(0, 5).single;

      expect(lineBreaks(paragraph, text), 'inter|national');
      // Like SkParagraph, the LTR word "inter" shows as "-inter".
      expect(hyphen.right, closeTo(inter.left, tolerance));
      expect(inter.right, closeTo(80, tolerance));

      // Hit testing and glyph info follow the hyphen's position.
      expect(paragraph.getPositionForOffset(const ui.Offset(25, 5)).offset, 6);
      final ui.GlyphInfo glyph = paragraph.getGlyphInfoAt(5)!;
      expect(glyph.graphemeClusterLayoutBounds.left, closeTo(20, tolerance));
      expect(glyph.graphemeClusterLayoutBounds.right, closeTo(30, tolerance));
    });

    test('in an LTR paragraph, an RTL word ends with the hyphen on the right', () {
      // FlutterTest does not make Hebrew letters 1 em wide, so measure them first.
      const text = '\u05D0\u05D1\u05D2\u05D3\u00AD\u05D4\u05D5\u05D6\u05D7';
      final double firstFour = layoutParagraph(
        text,
        1000,
      ).getBoxesForRange(0, 4).single.toRect().width;
      final ui.Paragraph paragraph = layoutParagraph(text, firstFour + 10.5);
      final ui.TextBox hyphen = paragraph.getBoxesForRange(4, 5).single;

      expect(paragraph.numberOfLines, 2);
      expect(paragraph.getLineNumberAt(5), 1);
      expect(hyphen.left, closeTo(firstFour, tolerance));
      expect(hyphen.right, closeTo(firstFour + 10, tolerance));
      expect(hyphen.direction, ui.TextDirection.rtl);
    });

    test('hit testing the hyphen returns upstream affinity on the hyphen line', () {
      // The position after a broken soft hyphen equals the start offset of the next line, so it
      // must have upstream affinity to stay on the hyphenated line for getLineBoundary and
      // getClosestGlyphInfoForOffset.
      final ui.Paragraph paragraph = layoutParagraph('abcd\u00ADe', 45);
      for (final dx in <double>[44, 45, 55]) {
        final ui.TextPosition pos = paragraph.getPositionForOffset(ui.Offset(dx, 5));
        expect(pos, const ui.TextPosition(offset: 5, affinity: ui.TextAffinity.upstream));
        expect(paragraph.getLineBoundary(pos), const ui.TextRange(start: 0, end: 5));
      }

      final ui.GlyphInfo? glyph = paragraph.getClosestGlyphInfoForOffset(const ui.Offset(45, 5));
      expect(glyph, isNotNull);
      expect(glyph!.graphemeClusterCodeUnitRange, const ui.TextRange(start: 4, end: 5));
    });

    test('getLineNumberAt maps a leading soft hyphen to its line', () {
      // When a line starts with U+00AD (at offset 0 or right after a hard newline), the first
      // visible cluster starts after the soft hyphen, but the line's text range must still
      // start at the beginning of the line so binary search in getLineNumberAt finds it.
      final ui.Paragraph atStart = layoutParagraph('\u00ADabcd\ne', 1000);
      expect(atStart.getLineNumberAt(0), 0);

      final ui.Paragraph afterNewline = layoutParagraph('a\nb\n\u00ADc\nd', 1000);
      expect(afterNewline.getLineNumberAt(4), 2);
    });

    test('directional marks without a cluster do not create empty or duplicate bidi runs', () {
      // In FlutterTest, U+200F (RLM) has no cluster of its own. At the start of an LTR
      // paragraph it must map to an empty cluster range [0, 0), and before a newline its
      // empty BidiRun must be skipped during line layout.
      final ui.Paragraph leadingRlm = layoutParagraph('\u200Fabc', 1000);
      expect(leadingRlm.computeLineMetrics().single.width, closeTo(30, tolerance));
      expect(leadingRlm.getBoxesForRange(1, 4), hasLength(1));

      final ui.Paragraph interiorRlm = layoutParagraph('a\u200F\nb', 1000);
      expect(interiorRlm.numberOfLines, 2);
    });
  });

  test('paints the hyphen', () async {
    const region = ui.Rect.fromLTWH(0, 0, 300, 120);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, region);
    canvas.drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);

    for (final (int index, ui.Hyphens hyphens) in <(int, ui.Hyphens)>[
      (0, ui.Hyphens.manual),
      (1, ui.Hyphens.hidden),
    ]) {
      final builder = ui.ParagraphBuilder(
        ui.ParagraphStyle(fontFamily: 'Roboto', fontSize: 24, hyphens: hyphens),
      );
      builder.pushStyle(
        ui.TextStyle(
          color: const ui.Color(0xFF000000),
          // The hyphen takes the decorations of the text it ends.
          decoration: ui.TextDecoration.underline,
          decorationStyle: ui.TextDecorationStyle.solid,
          decorationThickness: 1,
          decorationColor: const ui.Color(0xFFFF0000),
        ),
      );
      builder.addText('inter\u00ADnational');
      final ui.Paragraph paragraph = builder.build()
        ..layout(const ui.ParagraphConstraints(width: 120));
      canvas.drawParagraph(paragraph, ui.Offset(10 + 150.0 * index, 10));
    }

    await drawPictureUsingCurrentRenderer(recorder.endRecording());
    await matchGoldenFile('web_paragraph.soft_hyphen.png', region: region);
  });
}
