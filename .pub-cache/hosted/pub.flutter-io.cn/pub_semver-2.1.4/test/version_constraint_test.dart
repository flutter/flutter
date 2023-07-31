// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('any', () {
    expect(VersionConstraint.any.isAny, isTrue);
    expect(
        VersionConstraint.any,
        allows(Version.parse('0.0.0-blah'), Version.parse('1.2.3'),
            Version.parse('12345.678.90')));
  });

  test('empty', () {
    expect(VersionConstraint.empty.isEmpty, isTrue);
    expect(VersionConstraint.empty.isAny, isFalse);
    expect(
        VersionConstraint.empty,
        doesNotAllow(Version.parse('0.0.0-blah'), Version.parse('1.2.3'),
            Version.parse('12345.678.90')));
  });

  group('parse()', () {
    test('parses an exact version', () {
      var constraint = VersionConstraint.parse('1.2.3-alpha');

      expect(constraint is Version, isTrue);
      expect(constraint, equals(Version(1, 2, 3, pre: 'alpha')));
    });

    test('parses "any"', () {
      var constraint = VersionConstraint.parse('any');

      expect(
          constraint,
          allows(Version.parse('0.0.0'), Version.parse('1.2.3'),
              Version.parse('12345.678.90')));
    });

    test('parses a ">" minimum version', () {
      var constraint = VersionConstraint.parse('>1.2.3');

      expect(constraint,
          allows(Version.parse('1.2.3+foo'), Version.parse('1.2.4')));
      expect(
          constraint,
          doesNotAllow(Version.parse('1.2.1'), Version.parse('1.2.3-build'),
              Version.parse('1.2.3')));
    });

    test('parses a ">=" minimum version', () {
      var constraint = VersionConstraint.parse('>=1.2.3');

      expect(
          constraint,
          allows(Version.parse('1.2.3'), Version.parse('1.2.3+foo'),
              Version.parse('1.2.4')));
      expect(constraint,
          doesNotAllow(Version.parse('1.2.1'), Version.parse('1.2.3-build')));
    });

    test('parses a "<" maximum version', () {
      var constraint = VersionConstraint.parse('<1.2.3');

      expect(constraint,
          allows(Version.parse('1.2.1'), Version.parse('1.2.2+foo')));
      expect(
          constraint,
          doesNotAllow(Version.parse('1.2.3'), Version.parse('1.2.3+foo'),
              Version.parse('1.2.4')));
    });

    test('parses a "<=" maximum version', () {
      var constraint = VersionConstraint.parse('<=1.2.3');

      expect(
          constraint,
          allows(Version.parse('1.2.1'), Version.parse('1.2.3-build'),
              Version.parse('1.2.3')));
      expect(constraint,
          doesNotAllow(Version.parse('1.2.3+foo'), Version.parse('1.2.4')));
    });

    test('parses a series of space-separated constraints', () {
      var constraint = VersionConstraint.parse('>1.0.0 >=1.2.3 <1.3.0');

      expect(
          constraint, allows(Version.parse('1.2.3'), Version.parse('1.2.5')));
      expect(
          constraint,
          doesNotAllow(Version.parse('1.2.3-pre'), Version.parse('1.3.0'),
              Version.parse('3.4.5')));
    });

    test('parses a pre-release-only constraint', () {
      var constraint = VersionConstraint.parse('>=1.0.0-dev.2 <1.0.0');
      expect(constraint,
          allows(Version.parse('1.0.0-dev.2'), Version.parse('1.0.0-dev.3')));
      expect(constraint,
          doesNotAllow(Version.parse('1.0.0-dev.1'), Version.parse('1.0.0')));
    });

    test('ignores whitespace around comparison operators', () {
      var constraint = VersionConstraint.parse(' >1.0.0>=1.2.3 < 1.3.0');

      expect(
          constraint, allows(Version.parse('1.2.3'), Version.parse('1.2.5')));
      expect(
          constraint,
          doesNotAllow(Version.parse('1.2.3-pre'), Version.parse('1.3.0'),
              Version.parse('3.4.5')));
    });

    test('does not allow "any" to be mixed with other constraints', () {
      expect(() => VersionConstraint.parse('any 1.0.0'), throwsFormatException);
    });

    test('parses a "^" version', () {
      expect(VersionConstraint.parse('^0.0.3'),
          equals(VersionConstraint.compatibleWith(v003)));

      expect(VersionConstraint.parse('^0.7.2'),
          equals(VersionConstraint.compatibleWith(v072)));

      expect(VersionConstraint.parse('^1.2.3'),
          equals(VersionConstraint.compatibleWith(v123)));

      var min = Version.parse('0.7.2-pre+1');
      expect(VersionConstraint.parse('^0.7.2-pre+1'),
          equals(VersionConstraint.compatibleWith(min)));
    });

    test('does not allow "^" to be mixed with other constraints', () {
      expect(() => VersionConstraint.parse('>=1.2.3 ^1.0.0'),
          throwsFormatException);
      expect(() => VersionConstraint.parse('^1.0.0 <1.2.3'),
          throwsFormatException);
    });

    test('ignores whitespace around "^"', () {
      var constraint = VersionConstraint.parse(' ^ 1.2.3 ');

      expect(constraint, equals(VersionConstraint.compatibleWith(v123)));
    });

    test('throws FormatException on a bad string', () {
      var bad = [
        '', '   ', // Empty string.
        'foo', // Bad text.
        '>foo', // Bad text after operator.
        '^foo', // Bad text after "^".
        '1.0.0 foo', '1.0.0foo', // Bad text after version.
        'anything', // Bad text after "any".
        '<>1.0.0', // Multiple operators.
        '1.0.0<' // Trailing operator.
      ];

      for (var text in bad) {
        expect(() => VersionConstraint.parse(text), throwsFormatException);
      }
    });
  });

  group('compatibleWith()', () {
    test('returns the range of compatible versions', () {
      var constraint = VersionConstraint.compatibleWith(v072);

      expect(
          constraint,
          equals(VersionRange(
              min: v072, includeMin: true, max: v072.nextBreaking)));
    });

    test('toString() uses "^"', () {
      var constraint = VersionConstraint.compatibleWith(v072);

      expect(constraint.toString(), equals('^0.7.2'));
    });
  });
}
