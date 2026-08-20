// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/web_paragraph/layout.dart';
import 'package:ui/src/engine/web_paragraph/paragraph.dart';
import 'package:ui/ui.dart';

import '../common/test_initialization.dart';

// TODO(mdebbar): To make the tests consistent in all environments, we need to use the Ahem font.
final WebParagraphStyle ahemStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests();

  test(
    'Text wrapper, 10 lines, 3 trailing whitespaces on each line except the one that has a cluster break',
    () {
      final builder = WebParagraphBuilder(ahemStyle);
      builder.addText(
        'World   domination   is such   an ugly   phrase - I   prefer to   call it   world   optimisation.   ',
      );
      final WebParagraph paragraph = builder.build();
      paragraph.layout(const ParagraphConstraints(width: 250));
      final List<TextLine> lines = paragraph.lines;
      expect(lines.length, 10);
      for (var i = 0; i < 10; i++) {
        if (i == 8) {
          expect(lines[i].whitespacesRange.isEmpty, true);
        } else {
          expect(lines[i].whitespacesRange.size, 3);
        }
      }
    },
  );
  test('Text wrapper, 4 lines, 3 trailing whitespaces on each line', () {
    final builder = WebParagraphBuilder(ahemStyle);
    builder.addText(
      'World domination is   such an ugly phrase   - I prefer to call it   world optimisation.   ',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 500));
    final List<TextLine> lines = paragraph.lines;
    expect(lines.length, 4);
    for (var i = 0; i < 4; i++) {
      expect(lines[i].whitespacesRange.size, 3);
    }
  });
  test('Text wrapper, 1 line, 5 whitespaces and nothing else', () {
    final builder = WebParagraphBuilder(ahemStyle);
    builder.addText('     ');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    final List<TextLine> lines = paragraph.lines;
    expect(lines.length, 1);
    expect(lines[0].whitespacesRange.size, 5);
    expect(lines[0].textRange.size, 0);
  });
  test('Text wrapper, 3 lines, one very long word', () {
    final builder = WebParagraphBuilder(ahemStyle);
    builder.addText('abcdefghijklmnopqrstuvwxyz');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 250));
    final List<TextLine> lines = paragraph.lines;
    expect(lines.length, 3);
    var length = 0;
    for (var i = 0; i < 3; i++) {
      expect(lines[i].whitespacesRange.size, 0);
      length += lines[i].textRange.size;
    }
    expect(length, paragraph.text.length);
  });

  test('1 line, one cluster that does not fit', () {
    final builder = WebParagraphBuilder(ahemStyle);
    builder.pushStyle(WebTextStyle(fontSize: 500));
    builder.addText('a');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 50));
    final List<TextLine> lines = paragraph.lines;
    expect(lines, hasLength(1));

    final TextLine singleLine = lines.single;
    expect(singleLine.textRange.size, paragraph.text.length);
    expect(singleLine.whitespacesRange.size, 0);
  });

  test('Text wrapper, leading spaces', () {
    final builder = WebParagraphBuilder(ahemStyle);
    builder.addText('   abcdefghijklmnopqrstuvwxyz');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 250));

    final List<TextLine> lines = paragraph.lines;
    expect(lines.length, 3);
    var length = 0;
    for (var i = 0; i < 3; i++) {
      expect(lines[i].whitespacesRange.size, 0);
      length += lines[i].textRange.size;
    }
    expect(length, paragraph.text.length);
  });

  test('Text wrapper, 14 hard line breaks', () {
    final builder = WebParagraphBuilder(ahemStyle);
    builder.addText(
      'World\ndomination\nis\nsuch\nan\nugly\nphrase\n-\nI\nprefer\nto\ncall\nit\nworld\noptimisation.',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 10000));

    final List<TextLine> lines = paragraph.lines;
    expect(lines.length, 15);
    var length = 0;
    for (var i = 0; i < 15; i++) {
      expect(lines[i].whitespacesRange.size, 0);
      expect(lines[i].hasHardLineBreak, true, reason: 'Line $i line.hasHardLineBreak');
      length += lines[i].allLineTextRange.size + (i != 14 ? 1 : 0);
    }
    expect(length, paragraph.text.length);
  });

  test('Text wrapper, 1 hard line break with 3 trailing spaces before', () {
    final builder = WebParagraphBuilder(ahemStyle);
    builder.addText('abcd   \nefghijklmnopqrstuvwxyz');

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 10000));

    final List<TextLine> lines = paragraph.lines;
    expect(lines.length, 2);
    expect(lines[0].whitespacesRange.size, 3);
    expect(lines[0].hasHardLineBreak, true);
    expect(lines[1].whitespacesRange.size, 0);
    expect(lines[1].hasHardLineBreak, true);
  });

  test('Text wrapper, 3 hard line breaks and nothing else', () {
    final builder = WebParagraphBuilder(ahemStyle);
    builder.addText('\n\n\n');

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 10000));

    final List<TextLine> lines = paragraph.lines;
    expect(lines.length, 4);
    for (var i = 0; i < lines.length; i++) {
      expect(
        lines[i].allLineTextRange.size,
        i >= 2 ? 1 : 0,
        reason: 'Line $i line.allLineTextRange.size',
      );
      expect(lines[i].whitespacesRange.size, 0, reason: 'Line $i line.whitespacesRange.size');
      expect(lines[i].textRange.size, 0, reason: 'Line $i line.textRange.size');
      expect(lines[i].hardLineBreakRange.size, 1, reason: 'Line $i line.hardLineBreakRange.size');
      expect(lines[i].hasHardLineBreak, true);
    }
  });

  test('Text wrapper, ultimate test for edge cases', () {
    final builder = ParagraphBuilder(ParagraphStyle(fontFamily: 'Arial', fontSize: 50));
    builder.addText('Text\nText \nText \n');
    builder.addText(' \n  \n');
    builder.addText('\n\n \n\n');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 10000));

    if (paragraph is! WebParagraph) {
      return;
    }
    final List<TextLine> lines = paragraph.lines;

    expect(paragraph.numberOfLines, 10);

    void expectLineRanges(
      int index,
      int textStart,
      int allLineTextEnd,
      int textEnd,
      int whitespacesEnd,
      int hardLineBreakEnd,
    ) {
      final TextLine line = lines[index];
      expect(
        line.allLineTextRange,
        TextRange(start: textStart, end: allLineTextEnd),
        reason:
            'Line $index allLineTextRange ${line.allLineTextRange} != ${TextRange(start: textStart, end: allLineTextEnd)}',
      );
      expect(
        line.textRange,
        TextRange(start: textStart, end: textEnd),
        reason:
            'Line $index textRange $index ${line.textRange} != ${TextRange(start: textStart, end: textEnd)}',
      );
      expect(
        line.whitespacesRange,
        TextRange(start: textEnd, end: whitespacesEnd),
        reason:
            'Line $index whitespacesRange ${line.whitespacesRange} != ${TextRange(start: textEnd, end: whitespacesEnd)}',
      );
      expect(
        line.hardLineBreakRange,
        TextRange(start: whitespacesEnd, end: hardLineBreakEnd),
        reason:
            'Line $index hardLineBreakRange ${line.hardLineBreakRange} != ${TextRange(start: whitespacesEnd, end: hardLineBreakEnd)}',
      );
      expect(line.hasHardLineBreak, true, reason: 'Line $index line.hasHardLineBreak');
    }

    // In some cases (line #8,#9 SkParagraph does not match WebParagraph but it's internal data only and we align on the public output)
    expectLineRanges(0, 0, 4, 4, 4, 5);
    expectLineRanges(1, 5, 10, 9, 10, 11);
    expectLineRanges(2, 11, 16, 15, 16, 17);
    expectLineRanges(3, 17, 18, 17, 18, 19);
    expectLineRanges(4, 19, 21, 19, 21, 22);
    expectLineRanges(5, 22, 22, 22, 22, 23);
    expectLineRanges(6, 23, 23, 23, 23, 24);
    expectLineRanges(7, 24, 25, 24, 25, 26);
    expectLineRanges(8, 26, 27, 26, 26, 27);
    expectLineRanges(9, 26, 27, 26, 26, 27);
  });
}
