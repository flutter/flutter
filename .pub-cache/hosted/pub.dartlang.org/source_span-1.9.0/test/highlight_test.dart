// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:source_span/source_span.dart';
import 'package:source_span/src/colors.dart' as colors;
import 'package:term_glyph/term_glyph.dart' as glyph;
import 'package:test/test.dart';

void main() {
  late bool oldAscii;
  setUpAll(() {
    oldAscii = glyph.ascii;
    glyph.ascii = true;
  });

  tearDownAll(() {
    glyph.ascii = oldAscii;
  });

  late SourceFile file;
  setUp(() {
    file = SourceFile.fromString('''
foo bar baz
whiz bang boom
zip zap zop
''');
  });

  test('points to the span in the source', () {
    expect(file.span(4, 7).highlight(), equals("""
  ,
1 | foo bar baz
  |     ^^^
  '"""));
  });

  test('gracefully handles a missing source URL', () {
    final span = SourceFile.fromString('foo bar baz').span(4, 7);
    expect(span.highlight(), equals("""
  ,
1 | foo bar baz
  |     ^^^
  '"""));
  });

  group('highlights a point span', () {
    test('in the middle of a line', () {
      expect(file.location(4).pointSpan().highlight(), equals("""
  ,
1 | foo bar baz
  |     ^
  '"""));
    });

    test('at the beginning of the file', () {
      expect(file.location(0).pointSpan().highlight(), equals("""
  ,
1 | foo bar baz
  | ^
  '"""));
    });

    test('at the beginning of a line', () {
      expect(file.location(12).pointSpan().highlight(), equals("""
  ,
2 | whiz bang boom
  | ^
  '"""));
    });

    test('at the end of a line', () {
      expect(file.location(11).pointSpan().highlight(), equals("""
  ,
1 | foo bar baz
  |            ^
  '"""));
    });

    test('at the end of the file', () {
      expect(file.location(38).pointSpan().highlight(), equals("""
  ,
3 | zip zap zop
  |            ^
  '"""));
    });

    test('after the end of the file', () {
      expect(file.location(39).pointSpan().highlight(), equals("""
  ,
4 | 
  | ^
  '"""));
    });

    test('at the end of the file with no trailing newline', () {
      file = SourceFile.fromString('zip zap zop');
      expect(file.location(10).pointSpan().highlight(), equals("""
  ,
1 | zip zap zop
  |           ^
  '"""));
    });

    test('after the end of the file with no trailing newline', () {
      file = SourceFile.fromString('zip zap zop');
      expect(file.location(11).pointSpan().highlight(), equals("""
  ,
1 | zip zap zop
  |            ^
  '"""));
    });

    test('in an empty file', () {
      expect(SourceFile.fromString('').location(0).pointSpan().highlight(),
          equals("""
  ,
1 | 
  | ^
  '"""));
    });

    test('on an empty line', () {
      final file = SourceFile.fromString('foo\n\nbar');
      expect(file.location(4).pointSpan().highlight(), equals("""
  ,
2 | 
  | ^
  '"""));
    });
  });

  test('highlights a single-line file without a newline', () {
    expect(SourceFile.fromString('foo bar').span(0, 7).highlight(), equals("""
  ,
1 | foo bar
  | ^^^^^^^
  '"""));
  });

  test('highlights text including a trailing newline', () {
    expect(file.span(8, 12).highlight(), equals("""
  ,
1 | foo bar baz
  |         ^^^
  '"""));
  });

  test('highlights a single empty line', () {
    expect(
        SourceFile.fromString('foo\n\nbar').span(4, 5).highlight(), equals("""
  ,
2 | 
  | ^
  '"""));
  });

  test('highlights a trailing newline', () {
    expect(file.span(11, 12).highlight(), equals("""
  ,
1 | foo bar baz
  |            ^
  '"""));
  });

  group('with a multiline span', () {
    test('highlights the middle of the first and last lines', () {
      expect(file.span(4, 34).highlight(), equals("""
  ,
1 |   foo bar baz
  | ,-----^
2 | | whiz bang boom
3 | | zip zap zop
  | '-------^
  '"""));
    });

    test('works when it begins at the end of a line', () {
      expect(file.span(11, 34).highlight(), equals("""
  ,
1 |   foo bar baz
  | ,------------^
2 | | whiz bang boom
3 | | zip zap zop
  | '-------^
  '"""));
    });

    test('works when it ends at the beginning of a line', () {
      expect(file.span(4, 28).highlight(), equals("""
  ,
1 |   foo bar baz
  | ,-----^
2 | | whiz bang boom
3 | | zip zap zop
  | '-^
  '"""));
    });

    test('highlights the full first line', () {
      expect(file.span(0, 34).highlight(), equals("""
  ,
1 | / foo bar baz
2 | | whiz bang boom
3 | | zip zap zop
  | '-------^
  '"""));
    });

    test("highlights the full first line even if it's indented", () {
      final file = SourceFile.fromString('''
  foo bar baz
  whiz bang boom
  zip zap zop
''');

      expect(file.span(2, 38).highlight(), equals("""
  ,
1 | /   foo bar baz
2 | |   whiz bang boom
3 | |   zip zap zop
  | '-------^
  '"""));
    });

    test("highlights the full first line if it's empty", () {
      final file = SourceFile.fromString('''
foo

bar
''');

      expect(file.span(4, 9).highlight(), equals("""
  ,
2 | / 
3 | \\ bar
  '"""));
    });

    test('highlights the full last line', () {
      expect(file.span(4, 27).highlight(), equals("""
  ,
1 |   foo bar baz
  | ,-----^
2 | \\ whiz bang boom
  '"""));
    });

    test('highlights the full last line with no trailing newline', () {
      expect(file.span(4, 26).highlight(), equals("""
  ,
1 |   foo bar baz
  | ,-----^
2 | \\ whiz bang boom
  '"""));
    });

    test('highlights the full last line with a trailing Windows newline', () {
      final file = SourceFile.fromString('''
foo bar baz\r
whiz bang boom\r
zip zap zop\r
''');

      expect(file.span(4, 29).highlight(), equals("""
  ,
1 |   foo bar baz
  | ,-----^
2 | \\ whiz bang boom
  '"""));
    });

    test('highlights the full last line at the end of the file', () {
      expect(file.span(4, 39).highlight(), equals("""
  ,
1 |   foo bar baz
  | ,-----^
2 | | whiz bang boom
3 | \\ zip zap zop
  '"""));
    });

    test(
        'highlights the full last line at the end of the file with no trailing '
        'newline', () {
      final file = SourceFile.fromString('''
foo bar baz
whiz bang boom
zip zap zop''');

      expect(file.span(4, 38).highlight(), equals("""
  ,
1 |   foo bar baz
  | ,-----^
2 | | whiz bang boom
3 | \\ zip zap zop
  '"""));
    });

    test("highlights the full last line if it's empty", () {
      final file = SourceFile.fromString('''
foo

bar
''');

      expect(file.span(0, 5).highlight(), equals("""
  ,
1 | / foo
2 | \\ 
  '"""));
    });

    test('highlights multiple empty lines', () {
      final file = SourceFile.fromString('foo\n\n\n\nbar');
      expect(file.span(4, 7).highlight(), equals("""
  ,
2 | / 
3 | | 
4 | \\ 
  '"""));
    });

    // Regression test for #32
    test('highlights the end of a line and an empty line', () {
      final file = SourceFile.fromString('foo\n\n');
      expect(file.span(3, 5).highlight(), equals("""
  ,
1 |   foo
  | ,----^
2 | \\ 
  '"""));
    });
  });

  group('prints tabs as spaces', () {
    group('in a single-line span', () {
      test('before the highlighted section', () {
        final span = SourceFile.fromString('foo\tbar baz').span(4, 7);

        expect(span.highlight(), equals("""
  ,
1 | foo    bar baz
  |        ^^^
  '"""));
      });

      test('within the highlighted section', () {
        final span = SourceFile.fromString('foo bar\tbaz bang').span(4, 11);

        expect(span.highlight(), equals("""
  ,
1 | foo bar    baz bang
  |     ^^^^^^^^^^
  '"""));
      });

      test('after the highlighted section', () {
        final span = SourceFile.fromString('foo bar\tbaz').span(4, 7);

        expect(span.highlight(), equals("""
  ,
1 | foo bar    baz
  |     ^^^
  '"""));
      });
    });

    group('in a multi-line span', () {
      test('before the highlighted section', () {
        final span = SourceFile.fromString('''
foo\tbar baz
whiz bang boom
''').span(4, 21);

        expect(span.highlight(), equals("""
  ,
1 |   foo    bar baz
  | ,--------^
2 | | whiz bang boom
  | '---------^
  '"""));
      });

      test('within the first highlighted line', () {
        final span = SourceFile.fromString('''
foo bar\tbaz
whiz bang boom
''').span(4, 21);

        expect(span.highlight(), equals("""
  ,
1 |   foo bar    baz
  | ,-----^
2 | | whiz bang boom
  | '---------^
  '"""));
      });

      test('at the beginning of the first highlighted line', () {
        final span = SourceFile.fromString('''
foo bar\tbaz
whiz bang boom
''').span(7, 21);

        expect(span.highlight(), equals("""
  ,
1 |   foo bar    baz
  | ,--------^
2 | | whiz bang boom
  | '---------^
  '"""));
      });

      test('within a middle highlighted line', () {
        final span = SourceFile.fromString('''
foo bar baz
whiz\tbang boom
zip zap zop
''').span(4, 34);

        expect(span.highlight(), equals("""
  ,
1 |   foo bar baz
  | ,-----^
2 | | whiz    bang boom
3 | | zip zap zop
  | '-------^
  '"""));
      });

      test('within the last highlighted line', () {
        final span = SourceFile.fromString('''
foo bar baz
whiz\tbang boom
''').span(4, 21);

        expect(span.highlight(), equals("""
  ,
1 |   foo bar baz
  | ,-----^
2 | | whiz    bang boom
  | '------------^
  '"""));
      });

      test('at the end of the last highlighted line', () {
        final span = SourceFile.fromString('''
foo bar baz
whiz\tbang boom
''').span(4, 17);

        expect(span.highlight(), equals("""
  ,
1 |   foo bar baz
  | ,-----^
2 | | whiz    bang boom
  | '--------^
  '"""));
      });

      test('after the highlighted section', () {
        final span = SourceFile.fromString('''
foo bar baz
whiz bang\tboom
''').span(4, 21);

        expect(span.highlight(), equals("""
  ,
1 |   foo bar baz
  | ,-----^
2 | | whiz bang    boom
  | '---------^
  '"""));
      });
    });
  });

  group('supports lines of preceding and following context for a span', () {
    test('within a single line', () {
      final span = SourceSpanWithContext(
          SourceLocation(20, line: 2, column: 5, sourceUrl: 'foo.dart'),
          SourceLocation(27, line: 2, column: 12, sourceUrl: 'foo.dart'),
          'foo bar',
          'previous\nlines\n-----foo bar-----\nfollowing line\n');

      expect(span.highlight(), equals("""
  ,
1 | previous
2 | lines
3 | -----foo bar-----
  |      ^^^^^^^
4 | following line
  '"""));
    });

    test('covering a full line', () {
      final span = SourceSpanWithContext(
          SourceLocation(15, line: 2, column: 0, sourceUrl: 'foo.dart'),
          SourceLocation(33, line: 3, column: 0, sourceUrl: 'foo.dart'),
          '-----foo bar-----\n',
          'previous\nlines\n-----foo bar-----\nfollowing line\n');

      expect(span.highlight(), equals("""
  ,
1 | previous
2 | lines
3 | -----foo bar-----
  | ^^^^^^^^^^^^^^^^^
4 | following line
  '"""));
    });

    test('covering multiple full lines', () {
      final span = SourceSpanWithContext(
          SourceLocation(15, line: 2, column: 0, sourceUrl: 'foo.dart'),
          SourceLocation(23, line: 4, column: 0, sourceUrl: 'foo.dart'),
          'foo\nbar\n',
          'previous\nlines\nfoo\nbar\nfollowing line\n');

      expect(span.highlight(), equals("""
  ,
1 |   previous
2 |   lines
3 | / foo
4 | \\ bar
5 |   following line
  '"""));
    });
  });

  group('colors', () {
    test("doesn't colorize if color is false", () {
      expect(file.span(4, 7).highlight(color: false), equals("""
  ,
1 | foo bar baz
  |     ^^^
  '"""));
    });

    test('colorizes if color is true', () {
      expect(file.span(4, 7).highlight(color: true), equals('''
${colors.blue}  ,${colors.none}
${colors.blue}1 |${colors.none} foo ${colors.red}bar${colors.none} baz
${colors.blue}  |${colors.none} ${colors.red}    ^^^${colors.none}
${colors.blue}  '${colors.none}'''));
    });

    test("uses the given color if it's passed", () {
      expect(file.span(4, 7).highlight(color: colors.yellow), equals('''
${colors.blue}  ,${colors.none}
${colors.blue}1 |${colors.none} foo ${colors.yellow}bar${colors.none} baz
${colors.blue}  |${colors.none} ${colors.yellow}    ^^^${colors.none}
${colors.blue}  '${colors.none}'''));
    });

    test('colorizes a multiline span', () {
      expect(file.span(4, 34).highlight(color: true), equals('''
${colors.blue}  ,${colors.none}
${colors.blue}1 |${colors.none}   foo ${colors.red}bar baz${colors.none}
${colors.blue}  |${colors.none} ${colors.red},${colors.none}${colors.red}-----^${colors.none}
${colors.blue}2 |${colors.none} ${colors.red}|${colors.none} ${colors.red}whiz bang boom${colors.none}
${colors.blue}3 |${colors.none} ${colors.red}|${colors.none} ${colors.red}zip zap${colors.none} zop
${colors.blue}  |${colors.none} ${colors.red}'${colors.none}${colors.red}-------^${colors.none}
${colors.blue}  '${colors.none}'''));
    });

    test('colorizes a multiline span that highlights full lines', () {
      expect(file.span(0, 39).highlight(color: true), equals('''
${colors.blue}  ,${colors.none}
${colors.blue}1 |${colors.none} ${colors.red}/${colors.none} ${colors.red}foo bar baz${colors.none}
${colors.blue}2 |${colors.none} ${colors.red}|${colors.none} ${colors.red}whiz bang boom${colors.none}
${colors.blue}3 |${colors.none} ${colors.red}\\${colors.none} ${colors.red}zip zap zop${colors.none}
${colors.blue}  '${colors.none}'''));
    });
  });

  group('line numbers have appropriate padding', () {
    test('with line number 9', () {
      expect(
          SourceFile.fromString('\n' * 8 + 'foo bar baz\n')
              .span(8, 11)
              .highlight(),
          equals("""
  ,
9 | foo bar baz
  | ^^^
  '"""));
    });

    test('with line number 10', () {
      expect(
          SourceFile.fromString('\n' * 9 + 'foo bar baz\n')
              .span(9, 12)
              .highlight(),
          equals("""
   ,
10 | foo bar baz
   | ^^^
   '"""));
    });
  });
}
