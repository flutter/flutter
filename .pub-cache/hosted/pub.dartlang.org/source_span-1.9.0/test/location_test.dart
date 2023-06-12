// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';
import 'package:test/test.dart';

void main() {
  late SourceLocation location;
  setUp(() {
    location = SourceLocation(15, line: 2, column: 6, sourceUrl: 'foo.dart');
  });

  group('errors', () {
    group('for new SourceLocation()', () {
      test('offset may not be negative', () {
        expect(() => SourceLocation(-1), throwsRangeError);
      });

      test('line may not be negative', () {
        expect(() => SourceLocation(0, line: -1), throwsRangeError);
      });

      test('column may not be negative', () {
        expect(() => SourceLocation(0, column: -1), throwsRangeError);
      });
    });

    test('for distance() source URLs must match', () {
      expect(() => location.distance(SourceLocation(0)), throwsArgumentError);
    });

    test('for compareTo() source URLs must match', () {
      expect(() => location.compareTo(SourceLocation(0)), throwsArgumentError);
    });
  });

  test('fields work correctly', () {
    expect(location.sourceUrl, equals(Uri.parse('foo.dart')));
    expect(location.offset, equals(15));
    expect(location.line, equals(2));
    expect(location.column, equals(6));
  });

  group('toolString', () {
    test('returns a computer-readable representation', () {
      expect(location.toolString, equals('foo.dart:3:7'));
    });

    test('gracefully handles a missing source URL', () {
      final location = SourceLocation(15, line: 2, column: 6);
      expect(location.toolString, equals('unknown source:3:7'));
    });
  });

  test('distance returns the absolute distance between locations', () {
    final other = SourceLocation(10, sourceUrl: 'foo.dart');
    expect(location.distance(other), equals(5));
    expect(other.distance(location), equals(5));
  });

  test('pointSpan returns an empty span at location', () {
    final span = location.pointSpan();
    expect(span.start, equals(location));
    expect(span.end, equals(location));
    expect(span.text, isEmpty);
  });

  group('compareTo()', () {
    test('sorts by offset', () {
      final other = SourceLocation(20, sourceUrl: 'foo.dart');
      expect(location.compareTo(other), lessThan(0));
      expect(other.compareTo(location), greaterThan(0));
    });

    test('considers equal locations equal', () {
      expect(location.compareTo(location), equals(0));
    });
  });

  group('equality', () {
    test('two locations with the same offset and source are equal', () {
      final other = SourceLocation(15, sourceUrl: 'foo.dart');
      expect(location, equals(other));
    });

    test("a different offset isn't equal", () {
      final other = SourceLocation(10, sourceUrl: 'foo.dart');
      expect(location, isNot(equals(other)));
    });

    test("a different source isn't equal", () {
      final other = SourceLocation(15, sourceUrl: 'bar.dart');
      expect(location, isNot(equals(other)));
    });
  });
}
