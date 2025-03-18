// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/web_paragraph/layout.dart';
import 'package:ui/src/engine/web_paragraph/paragraph.dart';
import 'package:ui/ui.dart';

import '../../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

  test(
    'Text wrapper, 10 lines, 3 trailing whitespaces on each line except the one that has a cluster break',
    () {
      final WebParagraphStyle ahemStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
      final WebParagraphBuilder builder = WebParagraphBuilder(ahemStyle);
      builder.addText(
        'World   domination   is such   an ugly   phrase - I   prefer to   call it   world   optimisation.   ',
      );
      final WebParagraph paragraph = builder.build();
      paragraph.layout(const ParagraphConstraints(width: 250));
      final List<TextLine> lines = paragraph.lines;
      expect(lines.length, 10);
      for (int i = 0; i < 10; i++) {
        if (i == 8) {
          expect(lines[i].whitespacesRange.isEmpty(), true);
        } else {
          expect(lines[i].whitespacesRange.width(), 3);
        }
      }
    },
  );
  test('Text wrapper, 4 lines, 3 trailing whitespaces on each line', () {
    final WebParagraphStyle ahemStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(ahemStyle);
    builder.addText(
      'World domination is   such an ugly phrase   - I prefer to call it   world optimisation.   ',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 500));
    final List<TextLine> lines = paragraph.lines;
    expect(lines.length, 4);
    for (int i = 0; i < 4; i++) {
      expect(lines[i].whitespacesRange.width(), 3);
    }
  });
  test('Text wrapper, 1 line, 5 whitespaces and nothing else', () {
    final WebParagraphStyle ahemStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(ahemStyle);
    builder.addText('     ');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    final List<TextLine> lines = paragraph.lines;
    expect(lines.length, 1);
    expect(lines[0].whitespacesRange.width(), 5);
    expect(lines[0].clusterRange.width(), 0);
  });
  test('Text wrapper, 3 lines, one very long word', () {
    final WebParagraphStyle ahemStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(ahemStyle);
    builder.addText('abcdefghijklmnopqrstuvwxyz');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 250));
    final List<TextLine> lines = paragraph.lines;
    expect(lines.length, 3);
    int length = 0;
    for (int i = 0; i < 3; i++) {
      expect(lines[i].whitespacesRange.width(), 0);
      length += lines[i].clusterRange.width();
    }
    expect(length, paragraph.text.length);
  });

  test('Text wrapper, leading spaces', () {
    final WebParagraphStyle ahemStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(ahemStyle);
    builder.addText('   abcdefghijklmnopqrstuvwxyz');
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 250));

    final List<TextLine> lines = paragraph.lines;
    expect(lines.length, 3);
    int length = 0;
    for (int i = 0; i < 3; i++) {
      expect(lines[i].whitespacesRange.width(), 0);
      length += lines[i].clusterRange.width();
    }
    expect(length, paragraph.text.length);
  });

  test('Text wrapper, 14 hard line breaks', () {
    final WebParagraphStyle ahemStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(ahemStyle);
    builder.addText(
      'World\ndomination\nis\nsuch\nan\nugly\nphrase\n-\nI\nprefer\nto\ncall\nit\nworld\noptimisation.',
    );
    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 10000));

    final List<TextLine> lines = paragraph.lines;
    expect(lines.length, 15);
    int length = 0;
    for (int i = 0; i < 15; i++) {
      expect(lines[i].whitespacesRange.width(), i != 14 ? 1 : 0);
      expect(lines[i].hardLineBreak, i != 14);
      length += lines[i].clusterRange.width();
      length += lines[i].whitespacesRange.width();
    }
    expect(length, paragraph.text.length);
  });

  test('Text wrapper, 1 hard line break with 3 trailing spaces before', () {
    final WebParagraphStyle ahemStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(ahemStyle);
    builder.addText('abcd   \nefghijklmnopqrstuvwxyz');

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 10000));

    final List<TextLine> lines = paragraph.lines;
    expect(lines.length, 2);
    expect(lines[0].whitespacesRange.width(), 3 + 1);
    expect(lines[0].hardLineBreak, true);
    expect(lines[1].whitespacesRange.width(), 0);
    expect(lines[1].hardLineBreak, false);
  });

  test('Text wrapper, 3 hard line breaks and nothing else', () {
    final WebParagraphStyle ahemStyle = WebParagraphStyle(fontFamily: 'Arial', fontSize: 50);
    final WebParagraphBuilder builder = WebParagraphBuilder(ahemStyle);
    builder.addText('\n\n\n');

    final WebParagraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 10000));

    final List<TextLine> lines = paragraph.lines;
    expect(lines.length, 4);
    const int length = 0;
    for (int i = 0; i < 4; i++) {
      expect(lines[i].whitespacesRange.width(), i != 3 ? 1 : 0);
      expect(lines[i].clusterRange.width(), 0);
      expect(lines[i].hardLineBreak, i != 3);
    }
  });
}
