// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart';

import '../common/test_initialization.dart';

final ParagraphStyle ahemStyle = ParagraphStyle(fontFamily: 'Arial', fontSize: 50);

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests();

  test('Text wrapper, 10 lines, 3 trailing whitespaces on each line except the one that has a cluster break', () {
    final builder = ParagraphBuilder(ahemStyle);
    builder.addText(
      'World   domination   is such   an ugly   phrase - I   prefer to   call it   world   optimisation.   ',
    );
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 250));
    final List<LineMetrics> lines = paragraph.computeLineMetrics();
    // On CanvasKit (using FreeType/Skia font fallback for Arial), 'optimisation.'
    // measures ~206px <= 250px and fits on 1 line (total 9 lines).
    // On WebParagraph (using DOM Canvas2D Arial), 'optimisation.'
    // measures ~280px > 250px and wraps across 2 lines (total 10 lines).
    expect(lines.length, anyOf(9, 10));
    expect(paragraph.numberOfLines, lines.length);
    for (var i = 0; i < lines.length; i++) {
      expect(lines[i].lineNumber, i);
      expect(lines[i].hardBreak, i == lines.length - 1);
    }
  });

  test('Text wrapper, 4 lines, 3 trailing whitespaces on each line', () {
    final builder = ParagraphBuilder(ahemStyle);
    builder.addText(
      'World domination is   such an ugly phrase   - I prefer to call it   world optimisation.   ',
    );
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 500));
    expect(paragraph.numberOfLines, 4);
    final List<LineMetrics> lines = paragraph.computeLineMetrics();
    expect(lines.length, 4);
    for (var i = 0; i < 4; i++) {
      expect(lines[i].lineNumber, i);
      expect(lines[i].hardBreak, i == 3);
    }
  });

  test('Text wrapper, 1 line, 5 whitespaces and nothing else', () {
    final builder = ParagraphBuilder(ahemStyle);
    builder.addText('     ');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: double.infinity));
    expect(paragraph.numberOfLines, 1);
    final List<LineMetrics> lines = paragraph.computeLineMetrics();
    expect(lines.length, 1);
    expect(lines[0].lineNumber, 0);
    expect(lines[0].hardBreak, isTrue);
  });

  test('Text wrapper, 3 lines, one very long word', () {
    final builder = ParagraphBuilder(ahemStyle);
    builder.addText('abcdefghijklmnopqrstuvwxyz');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 250));
    expect(paragraph.numberOfLines, 3);
    final List<LineMetrics> lines = paragraph.computeLineMetrics();
    expect(lines.length, 3);
    for (var i = 0; i < 3; i++) {
      expect(lines[i].lineNumber, i);
      expect(lines[i].hardBreak, i == 2);
    }
  });

  test('1 line, one cluster that does not fit', () {
    final builder = ParagraphBuilder(ahemStyle);
    builder.pushStyle(TextStyle(fontSize: 500));
    builder.addText('a');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 50));
    expect(paragraph.numberOfLines, 1);
    final List<LineMetrics> lines = paragraph.computeLineMetrics();
    expect(lines, hasLength(1));
    expect(lines[0].lineNumber, 0);
    expect(lines[0].hardBreak, isTrue);
  });

  test('Text wrapper, leading spaces', () {
    final builder = ParagraphBuilder(ahemStyle);
    builder.addText('   abcdefghijklmnopqrstuvwxyz');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 250));

    expect(paragraph.numberOfLines, 3);
    final List<LineMetrics> lines = paragraph.computeLineMetrics();
    expect(lines.length, 3);
    for (var i = 0; i < 3; i++) {
      expect(lines[i].lineNumber, i);
      expect(lines[i].hardBreak, i == 2);
    }
  });

  test('Text wrapper, 14 hard line breaks', () {
    final builder = ParagraphBuilder(ahemStyle);
    builder.addText(
      'World\ndomination\nis\nsuch\nan\nugly\nphrase\n-\nI\nprefer\nto\ncall\nit\nworld\noptimisation.',
    );
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 10000));

    expect(paragraph.numberOfLines, 15);
    final List<LineMetrics> lines = paragraph.computeLineMetrics();
    expect(lines.length, 15);
    for (var i = 0; i < 15; i++) {
      expect(lines[i].lineNumber, i);
      expect(lines[i].hardBreak, isTrue, reason: 'Line $i line.hardBreak');
    }
  });

  test('Text wrapper, 1 hard line break with 3 trailing spaces before', () {
    final builder = ParagraphBuilder(ahemStyle);
    builder.addText('abcd   \nefghijklmnopqrstuvwxyz');

    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 10000));

    expect(paragraph.numberOfLines, 2);
    final List<LineMetrics> lines = paragraph.computeLineMetrics();
    expect(lines.length, 2);
    expect(lines[0].lineNumber, 0);
    expect(lines[0].hardBreak, isTrue);
    expect(lines[1].lineNumber, 1);
    expect(lines[1].hardBreak, isTrue);
  });

  test('Text wrapper, 3 hard line breaks and nothing else', () {
    final builder = ParagraphBuilder(ahemStyle);
    builder.addText('\n\n\n');

    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 10000));

    expect(paragraph.numberOfLines, 4);
    final List<LineMetrics> lines = paragraph.computeLineMetrics();
    expect(lines.length, 4);
    for (var i = 0; i < lines.length; i++) {
      expect(lines[i].lineNumber, i);
      expect(lines[i].hardBreak, isTrue);
      expect(lines[i].width, 0.0);
    }
  });

  test('Text wrapper, ultimate test for edge cases', () {
    final builder = ParagraphBuilder(ParagraphStyle(fontFamily: 'Arial', fontSize: 50));
    builder.addText('Text\nText \nText \n');
    builder.addText(' \n  \n');
    builder.addText('\n\n \n\n');
    final Paragraph paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: 10000));

    expect(paragraph.numberOfLines, 10);
    final List<LineMetrics> lines = paragraph.computeLineMetrics();
    expect(lines.length, 10);
    for (var i = 0; i < 10; i++) {
      expect(lines[i].lineNumber, i);
      expect(lines[i].hardBreak, isTrue, reason: 'Line $i line.hardBreak');
    }
  });
}
