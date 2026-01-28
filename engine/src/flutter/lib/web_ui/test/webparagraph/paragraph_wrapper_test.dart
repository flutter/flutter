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
      expect(lines[i].whitespacesRange.size, i != 14 ? 1 : 0);
      expect(lines[i].hardLineBreak, i != 14);
      length += lines[i].textRange.size;
      length += lines[i].whitespacesRange.size;
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
    expect(lines[0].whitespacesRange.size, 3 + 1);
    expect(lines[0].hardLineBreak, true);
    expect(lines[1].whitespacesRange.size, 0);
    expect(lines[1].hardLineBreak, false);
  });

  test('Text wrapper, 3 hard line breaks and nothing else', () {
    final builder = WebParagraphBuilder(ahemStyle);
    builder.addText('\n\n\n');

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 10000));

    final List<TextLine> lines = paragraph.lines;
    expect(lines.length, 3);
    for (var i = 0; i < 3; i++) {
      expect(lines[i].whitespacesRange.size, 1);
      expect(lines[i].textRange.size, 0);
      expect(lines[i].hardLineBreak, i != 3);
    }
  });
}
