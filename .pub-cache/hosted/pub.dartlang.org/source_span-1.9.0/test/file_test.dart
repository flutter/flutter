// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';
import 'package:test/test.dart';

void main() {
  late SourceFile file;
  setUp(() {
    file = SourceFile.fromString('''
foo bar baz
whiz bang boom
zip zap zop''', url: 'foo.dart');
  });

  group('errors', () {
    group('for span()', () {
      test('end must come after start', () {
        expect(() => file.span(10, 5), throwsArgumentError);
      });

      test('start may not be negative', () {
        expect(() => file.span(-1, 5), throwsRangeError);
      });

      test('end may not be outside the file', () {
        expect(() => file.span(10, 100), throwsRangeError);
      });
    });

    group('for location()', () {
      test('offset may not be negative', () {
        expect(() => file.location(-1), throwsRangeError);
      });

      test('offset may not be outside the file', () {
        expect(() => file.location(100), throwsRangeError);
      });
    });

    group('for getLine()', () {
      test('offset may not be negative', () {
        expect(() => file.getLine(-1), throwsRangeError);
      });

      test('offset may not be outside the file', () {
        expect(() => file.getLine(100), throwsRangeError);
      });
    });

    group('for getColumn()', () {
      test('offset may not be negative', () {
        expect(() => file.getColumn(-1), throwsRangeError);
      });

      test('offset may not be outside the file', () {
        expect(() => file.getColumn(100), throwsRangeError);
      });

      test('line may not be negative', () {
        expect(() => file.getColumn(1, line: -1), throwsRangeError);
      });

      test('line may not be outside the file', () {
        expect(() => file.getColumn(1, line: 100), throwsRangeError);
      });

      test('line must be accurate', () {
        expect(() => file.getColumn(1, line: 1), throwsRangeError);
      });
    });

    group('getOffset()', () {
      test('line may not be negative', () {
        expect(() => file.getOffset(-1), throwsRangeError);
      });

      test('column may not be negative', () {
        expect(() => file.getOffset(1, -1), throwsRangeError);
      });

      test('line may not be outside the file', () {
        expect(() => file.getOffset(100), throwsRangeError);
      });

      test('column may not be outside the file', () {
        expect(() => file.getOffset(2, 100), throwsRangeError);
      });

      test('column may not be outside the line', () {
        expect(() => file.getOffset(1, 20), throwsRangeError);
      });
    });

    group('for getText()', () {
      test('end must come after start', () {
        expect(() => file.getText(10, 5), throwsArgumentError);
      });

      test('start may not be negative', () {
        expect(() => file.getText(-1, 5), throwsRangeError);
      });

      test('end may not be outside the file', () {
        expect(() => file.getText(10, 100), throwsRangeError);
      });
    });

    group('for span().union()', () {
      test('source URLs must match', () {
        final other = SourceSpan(SourceLocation(10), SourceLocation(11), '_');

        expect(() => file.span(9, 10).union(other), throwsArgumentError);
      });

      test('spans may not be disjoint', () {
        expect(() => file.span(9, 10).union(file.span(11, 12)),
            throwsArgumentError);
      });
    });

    test('for span().expand() source URLs must match', () {
      final other = SourceFile.fromString('''
foo bar baz
whiz bang boom
zip zap zop''', url: 'bar.dart').span(10, 11);

      expect(() => file.span(9, 10).expand(other), throwsArgumentError);
    });
  });

  test('fields work correctly', () {
    expect(file.url, equals(Uri.parse('foo.dart')));
    expect(file.lines, equals(3));
    expect(file.length, equals(38));
  });

  group('new SourceFile()', () {
    test('handles CRLF correctly', () {
      expect(SourceFile.fromString('foo\r\nbar').getLine(6), equals(1));
    });

    test('handles a lone CR correctly', () {
      expect(SourceFile.fromString('foo\rbar').getLine(5), equals(1));
    });
  });

  group('span()', () {
    test('returns a span between the given offsets', () {
      final span = file.span(5, 10);
      expect(span.start, equals(file.location(5)));
      expect(span.end, equals(file.location(10)));
    });

    test('end defaults to the end of the file', () {
      final span = file.span(5);
      expect(span.start, equals(file.location(5)));
      expect(span.end, equals(file.location(file.length)));
    });
  });

  group('getLine()', () {
    test('works for a middle character on the line', () {
      expect(file.getLine(15), equals(1));
    });

    test('works for the first character of a line', () {
      expect(file.getLine(12), equals(1));
    });

    test('works for a newline character', () {
      expect(file.getLine(11), equals(0));
    });

    test('works for the last offset', () {
      expect(file.getLine(file.length), equals(2));
    });
  });

  group('getColumn()', () {
    test('works for a middle character on the line', () {
      expect(file.getColumn(15), equals(3));
    });

    test('works for the first character of a line', () {
      expect(file.getColumn(12), equals(0));
    });

    test('works for a newline character', () {
      expect(file.getColumn(11), equals(11));
    });

    test('works when line is passed as well', () {
      expect(file.getColumn(12, line: 1), equals(0));
    });

    test('works for the last offset', () {
      expect(file.getColumn(file.length), equals(11));
    });
  });

  group('getOffset()', () {
    test('works for a middle character on the line', () {
      expect(file.getOffset(1, 3), equals(15));
    });

    test('works for the first character of a line', () {
      expect(file.getOffset(1), equals(12));
    });

    test('works for a newline character', () {
      expect(file.getOffset(0, 11), equals(11));
    });

    test('works for the last offset', () {
      expect(file.getOffset(2, 11), equals(file.length));
    });
  });

  group('getText()', () {
    test('returns a substring of the source', () {
      expect(file.getText(8, 15), equals('baz\nwhi'));
    });

    test('end defaults to the end of the file', () {
      expect(file.getText(20), equals('g boom\nzip zap zop'));
    });
  });

  group('FileLocation', () {
    test('reports the correct line number', () {
      expect(file.location(15).line, equals(1));
    });

    test('reports the correct column number', () {
      expect(file.location(15).column, equals(3));
    });

    test('pointSpan() returns a FileSpan', () {
      final location = file.location(15);
      final span = location.pointSpan();
      expect(span, isA<FileSpan>());
      expect(span.start, equals(location));
      expect(span.end, equals(location));
      expect(span.text, isEmpty);
    });
  });

  group('FileSpan', () {
    test('text returns a substring of the source', () {
      expect(file.span(8, 15).text, equals('baz\nwhi'));
    });

    test('text includes the last char when end is defaulted to EOF', () {
      expect(file.span(29).text, equals('p zap zop'));
    });

    group('context', () {
      test("contains the span's text", () {
        final span = file.span(8, 15);
        expect(span.context.contains(span.text), isTrue);
        expect(span.context, equals('foo bar baz\nwhiz bang boom\n'));
      });

      test('contains the previous line for a point span at the end of a line',
          () {
        final span = file.span(25, 25);
        expect(span.context, equals('whiz bang boom\n'));
      });

      test('contains the next line for a point span at the beginning of a line',
          () {
        final span = file.span(12, 12);
        expect(span.context, equals('whiz bang boom\n'));
      });

      group('for a point span at the end of a file', () {
        test('without a newline, contains the last line', () {
          final span = file.span(file.length, file.length);
          expect(span.context, equals('zip zap zop'));
        });

        test('with a newline, contains an empty line', () {
          file = SourceFile.fromString('''
foo bar baz
whiz bang boom
zip zap zop
''', url: 'foo.dart');

          final span = file.span(file.length, file.length);
          expect(span.context, isEmpty);
        });
      });
    });

    group('union()', () {
      late FileSpan span;
      setUp(() {
        span = file.span(5, 12);
      });

      test('works with a preceding adjacent span', () {
        final other = file.span(0, 5);
        final result = span.union(other);
        expect(result.start, equals(other.start));
        expect(result.end, equals(span.end));
        expect(result.text, equals('foo bar baz\n'));
      });

      test('works with a preceding overlapping span', () {
        final other = file.span(0, 8);
        final result = span.union(other);
        expect(result.start, equals(other.start));
        expect(result.end, equals(span.end));
        expect(result.text, equals('foo bar baz\n'));
      });

      test('works with a following adjacent span', () {
        final other = file.span(12, 16);
        final result = span.union(other);
        expect(result.start, equals(span.start));
        expect(result.end, equals(other.end));
        expect(result.text, equals('ar baz\nwhiz'));
      });

      test('works with a following overlapping span', () {
        final other = file.span(9, 16);
        final result = span.union(other);
        expect(result.start, equals(span.start));
        expect(result.end, equals(other.end));
        expect(result.text, equals('ar baz\nwhiz'));
      });

      test('works with an internal overlapping span', () {
        final other = file.span(7, 10);
        expect(span.union(other), equals(span));
      });

      test('works with an external overlapping span', () {
        final other = file.span(0, 16);
        expect(span.union(other), equals(other));
      });

      test('returns a FileSpan for a FileSpan input', () {
        expect(span.union(file.span(0, 5)), isA<FileSpan>());
      });

      test('returns a base SourceSpan for a SourceSpan input', () {
        final other = SourceSpan(SourceLocation(0, sourceUrl: 'foo.dart'),
            SourceLocation(5, sourceUrl: 'foo.dart'), 'hey, ');
        final result = span.union(other);
        expect(result, isNot(isA<FileSpan>()));
        expect(result.start, equals(other.start));
        expect(result.end, equals(span.end));
        expect(result.text, equals('hey, ar baz\n'));
      });
    });

    group('expand()', () {
      late FileSpan span;
      setUp(() {
        span = file.span(5, 12);
      });

      test('works with a preceding nonadjacent span', () {
        final other = file.span(0, 3);
        final result = span.expand(other);
        expect(result.start, equals(other.start));
        expect(result.end, equals(span.end));
        expect(result.text, equals('foo bar baz\n'));
      });

      test('works with a preceding overlapping span', () {
        final other = file.span(0, 8);
        final result = span.expand(other);
        expect(result.start, equals(other.start));
        expect(result.end, equals(span.end));
        expect(result.text, equals('foo bar baz\n'));
      });

      test('works with a following nonadjacent span', () {
        final other = file.span(14, 16);
        final result = span.expand(other);
        expect(result.start, equals(span.start));
        expect(result.end, equals(other.end));
        expect(result.text, equals('ar baz\nwhiz'));
      });

      test('works with a following overlapping span', () {
        final other = file.span(9, 16);
        final result = span.expand(other);
        expect(result.start, equals(span.start));
        expect(result.end, equals(other.end));
        expect(result.text, equals('ar baz\nwhiz'));
      });

      test('works with an internal overlapping span', () {
        final other = file.span(7, 10);
        expect(span.expand(other), equals(span));
      });

      test('works with an external overlapping span', () {
        final other = file.span(0, 16);
        expect(span.expand(other), equals(other));
      });
    });

    group('subspan()', () {
      late FileSpan span;
      setUp(() {
        span = file.span(5, 11); // "ar baz"
      });

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

      group('returns the original span', () {
        test('with an implicit end',
            () => expect(span.subspan(0), equals(span)));

        test('with an explicit end',
            () => expect(span.subspan(0, span.length), equals(span)));
      });

      group('within a single line', () {
        test('returns a strict substring of the original span', () {
          final result = span.subspan(1, 5);
          expect(result.text, equals('r ba'));
          expect(result.start.offset, equals(6));
          expect(result.start.line, equals(0));
          expect(result.start.column, equals(6));
          expect(result.end.offset, equals(10));
          expect(result.end.line, equals(0));
          expect(result.end.column, equals(10));
        });

        test('an implicit end goes to the end of the original span', () {
          final result = span.subspan(1);
          expect(result.text, equals('r baz'));
          expect(result.start.offset, equals(6));
          expect(result.start.line, equals(0));
          expect(result.start.column, equals(6));
          expect(result.end.offset, equals(11));
          expect(result.end.line, equals(0));
          expect(result.end.column, equals(11));
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
          span = file.span(22, 30); // "boom\nzip"
        });

        test('with start and end in the middle of a line', () {
          final result = span.subspan(3, 6);
          expect(result.text, equals('m\nz'));
          expect(result.start.offset, equals(25));
          expect(result.start.line, equals(1));
          expect(result.start.column, equals(13));
          expect(result.end.offset, equals(28));
          expect(result.end.line, equals(2));
          expect(result.end.column, equals(1));
        });

        test('with start at the end of a line', () {
          final result = span.subspan(4, 6);
          expect(result.text, equals('\nz'));
          expect(result.start.offset, equals(26));
          expect(result.start.line, equals(1));
          expect(result.start.column, equals(14));
        });

        test('with start at the beginning of a line', () {
          final result = span.subspan(5, 6);
          expect(result.text, equals('z'));
          expect(result.start.offset, equals(27));
          expect(result.start.line, equals(2));
          expect(result.start.column, equals(0));
        });

        test('with end at the end of a line', () {
          final result = span.subspan(3, 4);
          expect(result.text, equals('m'));
          expect(result.end.offset, equals(26));
          expect(result.end.line, equals(1));
          expect(result.end.column, equals(14));
        });

        test('with end at the beginning of a line', () {
          final result = span.subspan(3, 5);
          expect(result.text, equals('m\n'));
          expect(result.end.offset, equals(27));
          expect(result.end.line, equals(2));
          expect(result.end.column, equals(0));
        });
      });
    });
  });
}
