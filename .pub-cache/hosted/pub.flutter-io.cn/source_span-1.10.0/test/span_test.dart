// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

  late SourceSpan span;
  setUp(() {
    span = SourceSpan(SourceLocation(5, sourceUrl: 'foo.dart'),
        SourceLocation(12, sourceUrl: 'foo.dart'), 'foo bar');
  });

  group('errors', () {
    group('for new SourceSpan()', () {
      test('source URLs must match', () {
        final start = SourceLocation(0, sourceUrl: 'foo.dart');
        final end = SourceLocation(1, sourceUrl: 'bar.dart');
        expect(() => SourceSpan(start, end, '_'), throwsArgumentError);
      });

      test('end must come after start', () {
        final start = SourceLocation(1);
        final end = SourceLocation(0);
        expect(() => SourceSpan(start, end, '_'), throwsArgumentError);
      });

      test('text must be the right length', () {
        final start = SourceLocation(0);
        final end = SourceLocation(1);
        expect(() => SourceSpan(start, end, 'abc'), throwsArgumentError);
      });
    });

    group('for new SourceSpanWithContext()', () {
      test('context must contain text', () {
        final start = SourceLocation(2);
        final end = SourceLocation(5);
        expect(() => SourceSpanWithContext(start, end, 'abc', '--axc--'),
            throwsArgumentError);
      });

      test('text starts at start.column in context', () {
        final start = SourceLocation(3);
        final end = SourceLocation(5);
        expect(() => SourceSpanWithContext(start, end, 'abc', '--abc--'),
            throwsArgumentError);
      });

      test('text starts at start.column of line in multi-line context', () {
        final start = SourceLocation(4, line: 55, column: 3);
        final end = SourceLocation(7, line: 55, column: 6);
        expect(() => SourceSpanWithContext(start, end, 'abc', '\n--abc--'),
            throwsArgumentError);
        expect(() => SourceSpanWithContext(start, end, 'abc', '\n----abc--'),
            throwsArgumentError);
        expect(() => SourceSpanWithContext(start, end, 'abc', '\n\n--abc--'),
            throwsArgumentError);

        // However, these are valid:
        SourceSpanWithContext(start, end, 'abc', '\n---abc--');
        SourceSpanWithContext(start, end, 'abc', '\n\n---abc--');
      });

      test('text can occur multiple times in context', () {
        final start1 = SourceLocation(4, line: 55, column: 2);
        final end1 = SourceLocation(7, line: 55, column: 5);
        final start2 = SourceLocation(4, line: 55, column: 8);
        final end2 = SourceLocation(7, line: 55, column: 11);
        SourceSpanWithContext(start1, end1, 'abc', '--abc---abc--\n');
        SourceSpanWithContext(start1, end1, 'abc', '--abc--abc--\n');
        SourceSpanWithContext(start2, end2, 'abc', '--abc---abc--\n');
        SourceSpanWithContext(start2, end2, 'abc', '---abc--abc--\n');
        expect(
            () => SourceSpanWithContext(start1, end1, 'abc', '---abc--abc--\n'),
            throwsArgumentError);
        expect(
            () => SourceSpanWithContext(start2, end2, 'abc', '--abc--abc--\n'),
            throwsArgumentError);
      });
    });

    group('for union()', () {
      test('source URLs must match', () {
        final other = SourceSpan(SourceLocation(12, sourceUrl: 'bar.dart'),
            SourceLocation(13, sourceUrl: 'bar.dart'), '_');

        expect(() => span.union(other), throwsArgumentError);
      });

      test('spans may not be disjoint', () {
        final other = SourceSpan(SourceLocation(13, sourceUrl: 'foo.dart'),
            SourceLocation(14, sourceUrl: 'foo.dart'), '_');

        expect(() => span.union(other), throwsArgumentError);
      });
    });

    test('for compareTo() source URLs must match', () {
      final other = SourceSpan(SourceLocation(12, sourceUrl: 'bar.dart'),
          SourceLocation(13, sourceUrl: 'bar.dart'), '_');

      expect(() => span.compareTo(other), throwsArgumentError);
    });
  });

  test('fields work correctly', () {
    expect(span.start, equals(SourceLocation(5, sourceUrl: 'foo.dart')));
    expect(span.end, equals(SourceLocation(12, sourceUrl: 'foo.dart')));
    expect(span.sourceUrl, equals(Uri.parse('foo.dart')));
    expect(span.length, equals(7));
  });

  group('union()', () {
    test('works with a preceding adjacent span', () {
      final other = SourceSpan(SourceLocation(0, sourceUrl: 'foo.dart'),
          SourceLocation(5, sourceUrl: 'foo.dart'), 'hey, ');

      final result = span.union(other);
      expect(result.start, equals(other.start));
      expect(result.end, equals(span.end));
      expect(result.text, equals('hey, foo bar'));
    });

    test('works with a preceding overlapping span', () {
      final other = SourceSpan(SourceLocation(0, sourceUrl: 'foo.dart'),
          SourceLocation(8, sourceUrl: 'foo.dart'), 'hey, foo');

      final result = span.union(other);
      expect(result.start, equals(other.start));
      expect(result.end, equals(span.end));
      expect(result.text, equals('hey, foo bar'));
    });

    test('works with a following adjacent span', () {
      final other = SourceSpan(SourceLocation(12, sourceUrl: 'foo.dart'),
          SourceLocation(16, sourceUrl: 'foo.dart'), ' baz');

      final result = span.union(other);
      expect(result.start, equals(span.start));
      expect(result.end, equals(other.end));
      expect(result.text, equals('foo bar baz'));
    });

    test('works with a following overlapping span', () {
      final other = SourceSpan(SourceLocation(9, sourceUrl: 'foo.dart'),
          SourceLocation(16, sourceUrl: 'foo.dart'), 'bar baz');

      final result = span.union(other);
      expect(result.start, equals(span.start));
      expect(result.end, equals(other.end));
      expect(result.text, equals('foo bar baz'));
    });

    test('works with an internal overlapping span', () {
      final other = SourceSpan(SourceLocation(7, sourceUrl: 'foo.dart'),
          SourceLocation(10, sourceUrl: 'foo.dart'), 'o b');

      expect(span.union(other), equals(span));
    });

    test('works with an external overlapping span', () {
      final other = SourceSpan(SourceLocation(0, sourceUrl: 'foo.dart'),
          SourceLocation(16, sourceUrl: 'foo.dart'), 'hey, foo bar baz');

      expect(span.union(other), equals(other));
    });
  });

  group('subspan()', () {
    group('errors', () {
      test('start must be greater than zero', () {
        expect(() => span.subspan(-1), throwsRangeError);
      });

      test('start must be less than or equal to length', () {
        expect(() => span.subspan(span.length + 1), throwsRangeError);
      });

      test('end must be greater than start', () {
        expect(() => span.subspan(2, 1), throwsRangeError);
      });

      test('end must be less than or equal to length', () {
        expect(() => span.subspan(0, span.length + 1), throwsRangeError);
      });
    });

    test('preserves the source URL', () {
      final result = span.subspan(1, 2);
      expect(result.start.sourceUrl, equals(span.sourceUrl));
      expect(result.end.sourceUrl, equals(span.sourceUrl));
    });

    test('preserves the context', () {
      final start = SourceLocation(2);
      final end = SourceLocation(5);
      final span = SourceSpanWithContext(start, end, 'abc', '--abc--');
      expect(span.subspan(1, 2).context, equals('--abc--'));
    });

    group('returns the original span', () {
      test('with an implicit end', () => expect(span.subspan(0), equals(span)));

      test('with an explicit end',
          () => expect(span.subspan(0, span.length), equals(span)));
    });

    group('within a single line', () {
      test('returns a strict substring of the original span', () {
        final result = span.subspan(1, 5);
        expect(result.text, equals('oo b'));
        expect(result.start.offset, equals(6));
        expect(result.start.line, equals(0));
        expect(result.start.column, equals(6));
        expect(result.end.offset, equals(10));
        expect(result.end.line, equals(0));
        expect(result.end.column, equals(10));
      });

      test('an implicit end goes to the end of the original span', () {
        final result = span.subspan(1);
        expect(result.text, equals('oo bar'));
        expect(result.start.offset, equals(6));
        expect(result.start.line, equals(0));
        expect(result.start.column, equals(6));
        expect(result.end.offset, equals(12));
        expect(result.end.line, equals(0));
        expect(result.end.column, equals(12));
      });

      test('can return an empty span', () {
        final result = span.subspan(3, 3);
        expect(result.text, isEmpty);
        expect(result.start.offset, equals(8));
        expect(result.start.line, equals(0));
        expect(result.start.column, equals(8));
        expect(result.end, equals(result.start));
      });
    });

    group('across multiple lines', () {
      setUp(() {
        span = SourceSpan(
            SourceLocation(5, line: 2, column: 0),
            SourceLocation(16, line: 4, column: 3),
            'foo\n'
            'bar\n'
            'baz');
      });

      test('with start and end in the middle of a line', () {
        final result = span.subspan(2, 5);
        expect(result.text, equals('o\nb'));
        expect(result.start.offset, equals(7));
        expect(result.start.line, equals(2));
        expect(result.start.column, equals(2));
        expect(result.end.offset, equals(10));
        expect(result.end.line, equals(3));
        expect(result.end.column, equals(1));
      });

      test('with start at the end of a line', () {
        final result = span.subspan(3, 5);
        expect(result.text, equals('\nb'));
        expect(result.start.offset, equals(8));
        expect(result.start.line, equals(2));
        expect(result.start.column, equals(3));
      });

      test('with start at the beginning of a line', () {
        final result = span.subspan(4, 5);
        expect(result.text, equals('b'));
        expect(result.start.offset, equals(9));
        expect(result.start.line, equals(3));
        expect(result.start.column, equals(0));
      });

      test('with end at the end of a line', () {
        final result = span.subspan(2, 3);
        expect(result.text, equals('o'));
        expect(result.end.offset, equals(8));
        expect(result.end.line, equals(2));
        expect(result.end.column, equals(3));
      });

      test('with end at the beginning of a line', () {
        final result = span.subspan(2, 4);
        expect(result.text, equals('o\n'));
        expect(result.end.offset, equals(9));
        expect(result.end.line, equals(3));
        expect(result.end.column, equals(0));
      });
    });
  });

  group('message()', () {
    test('prints the text being described', () {
      expect(span.message('oh no'), equals("""
line 1, column 6 of foo.dart: oh no
  ,
1 | foo bar
  | ^^^^^^^
  '"""));
    });

    test('gracefully handles a missing source URL', () {
      final span = SourceSpan(SourceLocation(5), SourceLocation(12), 'foo bar');

      expect(span.message('oh no'), equalsIgnoringWhitespace("""
line 1, column 6: oh no
  ,
1 | foo bar
  | ^^^^^^^
  '"""));
    });

    test('gracefully handles empty text', () {
      final span = SourceSpan(SourceLocation(5), SourceLocation(5), '');

      expect(span.message('oh no'), equals('line 1, column 6: oh no'));
    });

    test("doesn't colorize if color is false", () {
      expect(span.message('oh no', color: false), equals("""
line 1, column 6 of foo.dart: oh no
  ,
1 | foo bar
  | ^^^^^^^
  '"""));
    });

    test('colorizes if color is true', () {
      expect(span.message('oh no', color: true), equals("""
line 1, column 6 of foo.dart: oh no
${colors.blue}  ,${colors.none}
${colors.blue}1 |${colors.none} ${colors.red}foo bar${colors.none}
${colors.blue}  |${colors.none} ${colors.red}^^^^^^^${colors.none}
${colors.blue}  '${colors.none}"""));
    });

    test("uses the given color if it's passed", () {
      expect(span.message('oh no', color: colors.yellow), equals("""
line 1, column 6 of foo.dart: oh no
${colors.blue}  ,${colors.none}
${colors.blue}1 |${colors.none} ${colors.yellow}foo bar${colors.none}
${colors.blue}  |${colors.none} ${colors.yellow}^^^^^^^${colors.none}
${colors.blue}  '${colors.none}"""));
    });

    test('with context, underlines the right column', () {
      final spanWithContext = SourceSpanWithContext(
          SourceLocation(5, sourceUrl: 'foo.dart'),
          SourceLocation(12, sourceUrl: 'foo.dart'),
          'foo bar',
          '-----foo bar-----');

      expect(spanWithContext.message('oh no', color: colors.yellow), equals("""
line 1, column 6 of foo.dart: oh no
${colors.blue}  ,${colors.none}
${colors.blue}1 |${colors.none} -----${colors.yellow}foo bar${colors.none}-----
${colors.blue}  |${colors.none} ${colors.yellow}     ^^^^^^^${colors.none}
${colors.blue}  '${colors.none}"""));
    });
  });

  group('compareTo()', () {
    test('sorts by start location first', () {
      final other = SourceSpan(SourceLocation(6, sourceUrl: 'foo.dart'),
          SourceLocation(14, sourceUrl: 'foo.dart'), 'oo bar b');

      expect(span.compareTo(other), lessThan(0));
      expect(other.compareTo(span), greaterThan(0));
    });

    test('sorts by length second', () {
      final other = SourceSpan(SourceLocation(5, sourceUrl: 'foo.dart'),
          SourceLocation(14, sourceUrl: 'foo.dart'), 'foo bar b');

      expect(span.compareTo(other), lessThan(0));
      expect(other.compareTo(span), greaterThan(0));
    });

    test('considers equal spans equal', () {
      expect(span.compareTo(span), equals(0));
    });
  });

  group('equality', () {
    test('two spans with the same locations are equal', () {
      final other = SourceSpan(SourceLocation(5, sourceUrl: 'foo.dart'),
          SourceLocation(12, sourceUrl: 'foo.dart'), 'foo bar');

      expect(span, equals(other));
    });

    test("a different start isn't equal", () {
      final other = SourceSpan(SourceLocation(0, sourceUrl: 'foo.dart'),
          SourceLocation(12, sourceUrl: 'foo.dart'), 'hey, foo bar');

      expect(span, isNot(equals(other)));
    });

    test("a different end isn't equal", () {
      final other = SourceSpan(SourceLocation(5, sourceUrl: 'foo.dart'),
          SourceLocation(16, sourceUrl: 'foo.dart'), 'foo bar baz');

      expect(span, isNot(equals(other)));
    });

    test("a different source URL isn't equal", () {
      final other = SourceSpan(SourceLocation(5, sourceUrl: 'bar.dart'),
          SourceLocation(12, sourceUrl: 'bar.dart'), 'foo bar');

      expect(span, isNot(equals(other)));
    });
  });
}
