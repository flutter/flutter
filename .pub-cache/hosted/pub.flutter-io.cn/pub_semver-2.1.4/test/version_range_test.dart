// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('constructor', () {
    test('takes a min and max', () {
      var range = VersionRange(min: v123, max: v124);
      expect(range.isAny, isFalse);
      expect(range.min, equals(v123));
      expect(range.max, equals(v124.firstPreRelease));
    });

    group("doesn't make the max a pre-release if", () {
      test("it's already a pre-release", () {
        expect(VersionRange(max: Version.parse('1.2.4-pre')).max,
            equals(Version.parse('1.2.4-pre')));
      });

      test('includeMax is true', () {
        expect(VersionRange(max: v124, includeMax: true).max, equals(v124));
      });

      test('min is a prerelease of max', () {
        expect(VersionRange(min: Version.parse('1.2.4-pre'), max: v124).max,
            equals(v124));
      });

      test('max has a build identifier', () {
        expect(VersionRange(max: Version.parse('1.2.4+1')).max,
            equals(Version.parse('1.2.4+1')));
      });
    });

    test('allows omitting max', () {
      var range = VersionRange(min: v123);
      expect(range.isAny, isFalse);
      expect(range.min, equals(v123));
      expect(range.max, isNull);
    });

    test('allows omitting min and max', () {
      var range = VersionRange();
      expect(range.isAny, isTrue);
      expect(range.min, isNull);
      expect(range.max, isNull);
    });

    test('takes includeMin', () {
      var range = VersionRange(min: v123, includeMin: true);
      expect(range.includeMin, isTrue);
    });

    test('includeMin defaults to false if omitted', () {
      var range = VersionRange(min: v123);
      expect(range.includeMin, isFalse);
    });

    test('takes includeMax', () {
      var range = VersionRange(max: v123, includeMax: true);
      expect(range.includeMax, isTrue);
    });

    test('includeMax defaults to false if omitted', () {
      var range = VersionRange(max: v123);
      expect(range.includeMax, isFalse);
    });

    test('throws if min > max', () {
      expect(() => VersionRange(min: v124, max: v123), throwsArgumentError);
    });
  });

  group('allows()', () {
    test('version must be greater than min', () {
      var range = VersionRange(min: v123);

      expect(range, allows(Version.parse('1.3.3'), Version.parse('2.3.3')));
      expect(
          range, doesNotAllow(Version.parse('1.2.2'), Version.parse('1.2.3')));
    });

    test('version must be min or greater if includeMin', () {
      var range = VersionRange(min: v123, includeMin: true);

      expect(
          range,
          allows(Version.parse('1.2.3'), Version.parse('1.3.3'),
              Version.parse('2.3.3')));
      expect(range, doesNotAllow(Version.parse('1.2.2')));
    });

    test('pre-release versions of inclusive min are excluded', () {
      var range = VersionRange(min: v123, includeMin: true);

      expect(range, allows(Version.parse('1.2.4-dev')));
      expect(range, doesNotAllow(Version.parse('1.2.3-dev')));
    });

    test('version must be less than max', () {
      var range = VersionRange(max: v234);

      expect(range, allows(Version.parse('2.3.3')));
      expect(
          range, doesNotAllow(Version.parse('2.3.4'), Version.parse('2.4.3')));
    });

    test('pre-release versions of non-pre-release max are excluded', () {
      var range = VersionRange(max: v234);

      expect(range, allows(Version.parse('2.3.3')));
      expect(range,
          doesNotAllow(Version.parse('2.3.4-dev'), Version.parse('2.3.4')));
    });

    test(
        'pre-release versions of non-pre-release max are included if min is a '
        'pre-release of the same version', () {
      var range = VersionRange(min: Version.parse('2.3.4-dev.0'), max: v234);

      expect(range, allows(Version.parse('2.3.4-dev.1')));
      expect(
          range,
          doesNotAllow(Version.parse('2.3.3'), Version.parse('2.3.4-dev'),
              Version.parse('2.3.4')));
    });

    test('pre-release versions of pre-release max are included', () {
      var range = VersionRange(max: Version.parse('2.3.4-dev.2'));

      expect(range, allows(Version.parse('2.3.4-dev.1')));
      expect(
          range,
          doesNotAllow(
              Version.parse('2.3.4-dev.2'), Version.parse('2.3.4-dev.3')));
    });

    test('version must be max or less if includeMax', () {
      var range = VersionRange(min: v123, max: v234, includeMax: true);

      expect(
          range,
          allows(
              Version.parse('2.3.3'),
              Version.parse('2.3.4'),
              // Pre-releases of the max are allowed.
              Version.parse('2.3.4-dev')));
      expect(range, doesNotAllow(Version.parse('2.4.3')));
    });

    test('has no min if one was not set', () {
      var range = VersionRange(max: v123);

      expect(range, allows(Version.parse('0.0.0')));
      expect(range, doesNotAllow(Version.parse('1.2.3')));
    });

    test('has no max if one was not set', () {
      var range = VersionRange(min: v123);

      expect(range, allows(Version.parse('1.3.3'), Version.parse('999.3.3')));
      expect(range, doesNotAllow(Version.parse('1.2.3')));
    });

    test('allows any version if there is no min or max', () {
      var range = VersionRange();

      expect(range, allows(Version.parse('0.0.0'), Version.parse('999.99.9')));
    });

    test('allows pre-releases of the max with includeMaxPreRelease', () {
      expect(includeMaxPreReleaseRange, allows(Version.parse('2.0.0-dev')));
    });
  });

  group('allowsAll()', () {
    test('allows an empty constraint', () {
      expect(
          VersionRange(min: v123, max: v250).allowsAll(VersionConstraint.empty),
          isTrue);
    });

    test('allows allowed versions', () {
      var range = VersionRange(min: v123, max: v250, includeMax: true);
      expect(range.allowsAll(v123), isFalse);
      expect(range.allowsAll(v124), isTrue);
      expect(range.allowsAll(v250), isTrue);
      expect(range.allowsAll(v300), isFalse);
    });

    test('with no min', () {
      var range = VersionRange(max: v250);
      expect(range.allowsAll(VersionRange(min: v080, max: v140)), isTrue);
      expect(range.allowsAll(VersionRange(min: v080, max: v300)), isFalse);
      expect(range.allowsAll(VersionRange(max: v140)), isTrue);
      expect(range.allowsAll(VersionRange(max: v300)), isFalse);
      expect(range.allowsAll(range), isTrue);
      expect(range.allowsAll(VersionConstraint.any), isFalse);
    });

    test('with no max', () {
      var range = VersionRange(min: v010);
      expect(range.allowsAll(VersionRange(min: v080, max: v140)), isTrue);
      expect(range.allowsAll(VersionRange(min: v003, max: v140)), isFalse);
      expect(range.allowsAll(VersionRange(min: v080)), isTrue);
      expect(range.allowsAll(VersionRange(min: v003)), isFalse);
      expect(range.allowsAll(range), isTrue);
      expect(range.allowsAll(VersionConstraint.any), isFalse);
    });

    test('with a min and max', () {
      var range = VersionRange(min: v010, max: v250);
      expect(range.allowsAll(VersionRange(min: v080, max: v140)), isTrue);
      expect(range.allowsAll(VersionRange(min: v080, max: v300)), isFalse);
      expect(range.allowsAll(VersionRange(min: v003, max: v140)), isFalse);
      expect(range.allowsAll(VersionRange(min: v080)), isFalse);
      expect(range.allowsAll(VersionRange(max: v140)), isFalse);
      expect(range.allowsAll(range), isTrue);
    });

    test("allows a bordering range that's not more inclusive", () {
      var exclusive = VersionRange(min: v010, max: v250);
      var inclusive = VersionRange(
          min: v010, includeMin: true, max: v250, includeMax: true);
      expect(inclusive.allowsAll(exclusive), isTrue);
      expect(inclusive.allowsAll(inclusive), isTrue);
      expect(exclusive.allowsAll(inclusive), isFalse);
      expect(exclusive.allowsAll(exclusive), isTrue);
    });

    test('allows unions that are completely contained', () {
      var range = VersionRange(min: v114, max: v200);
      expect(range.allowsAll(VersionRange(min: v123, max: v124).union(v140)),
          isTrue);
      expect(range.allowsAll(VersionRange(min: v010, max: v124).union(v140)),
          isFalse);
      expect(range.allowsAll(VersionRange(min: v123, max: v234).union(v140)),
          isFalse);
    });

    group('pre-release versions', () {
      test('of inclusive min are excluded', () {
        var range = VersionRange(min: v123, includeMin: true);

        expect(range.allowsAll(VersionConstraint.parse('>1.2.4-dev')), isTrue);
        expect(range.allowsAll(VersionConstraint.parse('>1.2.3-dev')), isFalse);
      });

      test('of non-pre-release max are excluded', () {
        var range = VersionRange(max: v234);

        expect(range.allowsAll(VersionConstraint.parse('<2.3.3')), isTrue);
        expect(range.allowsAll(VersionConstraint.parse('<2.3.4-dev')), isFalse);
      });

      test('of non-pre-release max are included with includeMaxPreRelease', () {
        expect(
            includeMaxPreReleaseRange
                .allowsAll(VersionConstraint.parse('<2.0.0-dev')),
            isTrue);
      });

      test(
          'of non-pre-release max are included if min is a pre-release of the '
          'same version', () {
        var range = VersionRange(min: Version.parse('2.3.4-dev.0'), max: v234);

        expect(
            range.allowsAll(
                VersionConstraint.parse('>2.3.4-dev.0 <2.3.4-dev.1')),
            isTrue);
      });

      test('of pre-release max are included', () {
        var range = VersionRange(max: Version.parse('2.3.4-dev.2'));

        expect(
            range.allowsAll(VersionConstraint.parse('<2.3.4-dev.1')), isTrue);
        expect(
            range.allowsAll(VersionConstraint.parse('<2.3.4-dev.2')), isTrue);
        expect(
            range.allowsAll(VersionConstraint.parse('<=2.3.4-dev.2')), isFalse);
        expect(
            range.allowsAll(VersionConstraint.parse('<2.3.4-dev.3')), isFalse);
      });
    });
  });

  group('allowsAny()', () {
    test('disallows an empty constraint', () {
      expect(
          VersionRange(min: v123, max: v250).allowsAny(VersionConstraint.empty),
          isFalse);
    });

    test('allows allowed versions', () {
      var range = VersionRange(min: v123, max: v250, includeMax: true);
      expect(range.allowsAny(v123), isFalse);
      expect(range.allowsAny(v124), isTrue);
      expect(range.allowsAny(v250), isTrue);
      expect(range.allowsAny(v300), isFalse);
    });

    test('with no min', () {
      var range = VersionRange(max: v200);
      expect(range.allowsAny(VersionRange(min: v140, max: v300)), isTrue);
      expect(range.allowsAny(VersionRange(min: v234, max: v300)), isFalse);
      expect(range.allowsAny(VersionRange(min: v140)), isTrue);
      expect(range.allowsAny(VersionRange(min: v234)), isFalse);
      expect(range.allowsAny(range), isTrue);
    });

    test('with no max', () {
      var range = VersionRange(min: v072);
      expect(range.allowsAny(VersionRange(min: v003, max: v140)), isTrue);
      expect(range.allowsAny(VersionRange(min: v003, max: v010)), isFalse);
      expect(range.allowsAny(VersionRange(max: v080)), isTrue);
      expect(range.allowsAny(VersionRange(max: v003)), isFalse);
      expect(range.allowsAny(range), isTrue);
    });

    test('with a min and max', () {
      var range = VersionRange(min: v072, max: v200);
      expect(range.allowsAny(VersionRange(min: v003, max: v140)), isTrue);
      expect(range.allowsAny(VersionRange(min: v140, max: v300)), isTrue);
      expect(range.allowsAny(VersionRange(min: v003, max: v010)), isFalse);
      expect(range.allowsAny(VersionRange(min: v234, max: v300)), isFalse);
      expect(range.allowsAny(VersionRange(max: v010)), isFalse);
      expect(range.allowsAny(VersionRange(min: v234)), isFalse);
      expect(range.allowsAny(range), isTrue);
    });

    test('allows a bordering range when both are inclusive', () {
      expect(
          VersionRange(max: v250).allowsAny(VersionRange(min: v250)), isFalse);

      expect(
          VersionRange(max: v250, includeMax: true)
              .allowsAny(VersionRange(min: v250)),
          isFalse);

      expect(
          VersionRange(max: v250)
              .allowsAny(VersionRange(min: v250, includeMin: true)),
          isFalse);

      expect(
          VersionRange(max: v250, includeMax: true)
              .allowsAny(VersionRange(min: v250, includeMin: true)),
          isTrue);

      expect(
          VersionRange(min: v250).allowsAny(VersionRange(max: v250)), isFalse);

      expect(
          VersionRange(min: v250, includeMin: true)
              .allowsAny(VersionRange(max: v250)),
          isFalse);

      expect(
          VersionRange(min: v250)
              .allowsAny(VersionRange(max: v250, includeMax: true)),
          isFalse);

      expect(
          VersionRange(min: v250, includeMin: true)
              .allowsAny(VersionRange(max: v250, includeMax: true)),
          isTrue);
    });

    test('allows unions that are partially contained', () {
      var range = VersionRange(min: v114, max: v200);
      expect(range.allowsAny(VersionRange(min: v010, max: v080).union(v140)),
          isTrue);
      expect(range.allowsAny(VersionRange(min: v123, max: v234).union(v300)),
          isTrue);
      expect(range.allowsAny(VersionRange(min: v234, max: v300).union(v010)),
          isFalse);
    });

    group('pre-release versions', () {
      test('of inclusive min are excluded', () {
        var range = VersionRange(min: v123, includeMin: true);

        expect(range.allowsAny(VersionConstraint.parse('<1.2.4-dev')), isTrue);
        expect(range.allowsAny(VersionConstraint.parse('<1.2.3-dev')), isFalse);
      });

      test('of non-pre-release max are excluded', () {
        var range = VersionRange(max: v234);

        expect(range.allowsAny(VersionConstraint.parse('>2.3.3')), isTrue);
        expect(range.allowsAny(VersionConstraint.parse('>2.3.4-dev')), isFalse);
      });

      test('of non-pre-release max are included with includeMaxPreRelease', () {
        expect(
            includeMaxPreReleaseRange
                .allowsAny(VersionConstraint.parse('>2.0.0-dev')),
            isTrue);
      });

      test(
          'of non-pre-release max are included if min is a pre-release of the '
          'same version', () {
        var range = VersionRange(min: Version.parse('2.3.4-dev.0'), max: v234);

        expect(
            range.allowsAny(VersionConstraint.parse('>2.3.4-dev.1')), isTrue);
        expect(range.allowsAny(VersionConstraint.parse('>2.3.4')), isFalse);

        expect(
            range.allowsAny(VersionConstraint.parse('<2.3.4-dev.1')), isTrue);
        expect(range.allowsAny(VersionConstraint.parse('<2.3.4-dev')), isFalse);
      });

      test('of pre-release max are included', () {
        var range = VersionConstraint.parse('<2.3.4-dev.2');

        expect(
            range.allowsAny(VersionConstraint.parse('>2.3.4-dev.1')), isTrue);
        expect(
            range.allowsAny(VersionConstraint.parse('>2.3.4-dev.2')), isFalse);
        expect(
            range.allowsAny(VersionConstraint.parse('>2.3.4-dev.3')), isFalse);
      });
    });
  });

  group('intersect()', () {
    test('two overlapping ranges', () {
      expect(
          VersionRange(min: v123, max: v250)
              .intersect(VersionRange(min: v200, max: v300)),
          equals(VersionRange(min: v200, max: v250)));
    });

    test('a non-overlapping range allows no versions', () {
      var a = VersionRange(min: v114, max: v124);
      var b = VersionRange(min: v200, max: v250);
      expect(a.intersect(b).isEmpty, isTrue);
    });

    test('adjacent ranges allow no versions if exclusive', () {
      var a = VersionRange(min: v114, max: v124);
      var b = VersionRange(min: v124, max: v200);
      expect(a.intersect(b).isEmpty, isTrue);
    });

    test('adjacent ranges allow version if inclusive', () {
      var a = VersionRange(min: v114, max: v124, includeMax: true);
      var b = VersionRange(min: v124, max: v200, includeMin: true);
      expect(a.intersect(b), equals(v124));
    });

    test('with an open range', () {
      var open = VersionRange();
      var a = VersionRange(min: v114, max: v124);
      expect(open.intersect(open), equals(open));
      expect(a.intersect(open), equals(a));
    });

    test('returns the version if the range allows it', () {
      expect(VersionRange(min: v114, max: v124).intersect(v123), equals(v123));
      expect(
          VersionRange(min: v123, max: v124).intersect(v114).isEmpty, isTrue);
    });

    test('with a range with a pre-release min, returns an empty constraint',
        () {
      expect(
          VersionRange(max: v200)
              .intersect(VersionConstraint.parse('>=2.0.0-dev')),
          equals(VersionConstraint.empty));
    });

    test('with a range with a pre-release max, returns the original', () {
      expect(
          VersionRange(max: v200)
              .intersect(VersionConstraint.parse('<2.0.0-dev')),
          equals(VersionRange(max: v200)));
    });

    group('with includeMaxPreRelease', () {
      test('preserves includeMaxPreRelease if the max version is included', () {
        expect(
            includeMaxPreReleaseRange
                .intersect(VersionConstraint.parse('<1.0.0')),
            equals(VersionConstraint.parse('<1.0.0')));
        expect(
            includeMaxPreReleaseRange
                .intersect(VersionConstraint.parse('<2.0.0')),
            equals(VersionConstraint.parse('<2.0.0')));
        expect(includeMaxPreReleaseRange.intersect(includeMaxPreReleaseRange),
            equals(includeMaxPreReleaseRange));
        expect(
            includeMaxPreReleaseRange
                .intersect(VersionConstraint.parse('<3.0.0')),
            equals(includeMaxPreReleaseRange));
        expect(
            includeMaxPreReleaseRange
                .intersect(VersionConstraint.parse('>1.1.4')),
            equals(VersionRange(
                min: v114, max: v200, alwaysIncludeMaxPreRelease: true)));
      });

      test(
          'and a range with a pre-release min, returns '
          'an intersection', () {
        expect(
            includeMaxPreReleaseRange
                .intersect(VersionConstraint.parse('>=2.0.0-dev')),
            equals(VersionConstraint.parse('>=2.0.0-dev <2.0.0')));
      });

      test(
          'and a range with a pre-release max, returns '
          'the narrower constraint', () {
        expect(
            includeMaxPreReleaseRange
                .intersect(VersionConstraint.parse('<2.0.0-dev')),
            equals(VersionConstraint.parse('<2.0.0-dev')));
      });
    });
  });

  group('union()', () {
    test('with a version returns the range if it contains the version', () {
      var range = VersionRange(min: v114, max: v124);
      expect(range.union(v123), equals(range));
    });

    test('with a version on the edge of the range, expands the range', () {
      expect(
          VersionRange(min: v114, max: v124, alwaysIncludeMaxPreRelease: true)
              .union(v124),
          equals(VersionRange(min: v114, max: v124, includeMax: true)));
      expect(VersionRange(min: v114, max: v124).union(v114),
          equals(VersionRange(min: v114, max: v124, includeMin: true)));
    });

    test(
        'with a version allows both the range and the version if the range '
        "doesn't contain the version", () {
      var result = VersionRange(min: v003, max: v114).union(v124);
      expect(result, allows(v010));
      expect(result, doesNotAllow(v123));
      expect(result, allows(v124));
    });

    test('returns a VersionUnion for a disjoint range', () {
      var result = VersionRange(min: v003, max: v114)
          .union(VersionRange(min: v130, max: v200));
      expect(result, allows(v080));
      expect(result, doesNotAllow(v123));
      expect(result, allows(v140));
    });

    test('returns a VersionUnion for a disjoint range with infinite end', () {
      void isVersionUnion(VersionConstraint constraint) {
        expect(constraint, allows(v080));
        expect(constraint, doesNotAllow(v123));
        expect(constraint, allows(v140));
      }

      for (final includeAMin in [true, false]) {
        for (final includeAMax in [true, false]) {
          for (final includeBMin in [true, false]) {
            for (final includeBMax in [true, false]) {
              final a = VersionRange(
                  min: v130, includeMin: includeAMin, includeMax: includeAMax);
              final b = VersionRange(
                  max: v114, includeMin: includeBMin, includeMax: includeBMax);
              isVersionUnion(a.union(b));
              isVersionUnion(b.union(a));
            }
          }
        }
      }
    });

    test('considers open ranges disjoint', () {
      var result = VersionRange(min: v003, max: v114)
          .union(VersionRange(min: v114, max: v200));
      expect(result, allows(v080));
      expect(result, doesNotAllow(v114));
      expect(result, allows(v140));

      result = VersionRange(min: v114, max: v200)
          .union(VersionRange(min: v003, max: v114));
      expect(result, allows(v080));
      expect(result, doesNotAllow(v114));
      expect(result, allows(v140));
    });

    test('returns a merged range for an overlapping range', () {
      var result = VersionRange(min: v003, max: v114)
          .union(VersionRange(min: v080, max: v200));
      expect(result, equals(VersionRange(min: v003, max: v200)));
    });

    test('considers closed ranges overlapping', () {
      var result = VersionRange(min: v003, max: v114, includeMax: true)
          .union(VersionRange(min: v114, max: v200));
      expect(result, equals(VersionRange(min: v003, max: v200)));

      result =
          VersionRange(min: v003, max: v114, alwaysIncludeMaxPreRelease: true)
              .union(VersionRange(min: v114, max: v200, includeMin: true));
      expect(result, equals(VersionRange(min: v003, max: v200)));

      result = VersionRange(min: v114, max: v200)
          .union(VersionRange(min: v003, max: v114, includeMax: true));
      expect(result, equals(VersionRange(min: v003, max: v200)));

      result = VersionRange(min: v114, max: v200, includeMin: true).union(
          VersionRange(min: v003, max: v114, alwaysIncludeMaxPreRelease: true));
      expect(result, equals(VersionRange(min: v003, max: v200)));
    });

    test('includes edges if either range does', () {
      var result = VersionRange(min: v003, max: v114, includeMin: true)
          .union(VersionRange(min: v003, max: v114, includeMax: true));
      expect(
          result,
          equals(VersionRange(
              min: v003, max: v114, includeMin: true, includeMax: true)));
    });

    test('with a range with a pre-release min, returns a constraint with a gap',
        () {
      var result =
          VersionRange(max: v200).union(VersionConstraint.parse('>=2.0.0-dev'));
      expect(result, allows(v140));
      expect(result, doesNotAllow(Version.parse('2.0.0-alpha')));
      expect(result, allows(Version.parse('2.0.0-dev')));
      expect(result, allows(Version.parse('2.0.0-dev.1')));
      expect(result, allows(Version.parse('2.0.0')));
    });

    test('with a range with a pre-release max, returns the larger constraint',
        () {
      expect(
          VersionRange(max: v200).union(VersionConstraint.parse('<2.0.0-dev')),
          equals(VersionConstraint.parse('<2.0.0-dev')));
    });

    group('with includeMaxPreRelease', () {
      test('adds includeMaxPreRelease if the max version is included', () {
        expect(
            includeMaxPreReleaseRange.union(VersionConstraint.parse('<1.0.0')),
            equals(includeMaxPreReleaseRange));
        expect(includeMaxPreReleaseRange.union(includeMaxPreReleaseRange),
            equals(includeMaxPreReleaseRange));
        expect(
            includeMaxPreReleaseRange.union(VersionConstraint.parse('<2.0.0')),
            equals(includeMaxPreReleaseRange));
        expect(
            includeMaxPreReleaseRange.union(VersionConstraint.parse('<3.0.0')),
            equals(VersionConstraint.parse('<3.0.0')));
      });

      test('and a range with a pre-release min, returns any', () {
        expect(
            includeMaxPreReleaseRange
                .union(VersionConstraint.parse('>=2.0.0-dev')),
            equals(VersionConstraint.any));
      });

      test('and a range with a pre-release max, returns the original', () {
        expect(
            includeMaxPreReleaseRange
                .union(VersionConstraint.parse('<2.0.0-dev')),
            equals(includeMaxPreReleaseRange));
      });
    });
  });

  group('difference()', () {
    test('with an empty range returns the original range', () {
      expect(
          VersionRange(min: v003, max: v114)
              .difference(VersionConstraint.empty),
          equals(VersionRange(min: v003, max: v114)));
    });

    test('with a version outside the range returns the original range', () {
      expect(VersionRange(min: v003, max: v114).difference(v200),
          equals(VersionRange(min: v003, max: v114)));
    });

    test('with a version in the range splits the range', () {
      expect(
          VersionRange(min: v003, max: v114).difference(v072),
          equals(VersionConstraint.unionOf([
            VersionRange(
                min: v003, max: v072, alwaysIncludeMaxPreRelease: true),
            VersionRange(min: v072, max: v114)
          ])));
    });

    test('with the max version makes the max exclusive', () {
      expect(
          VersionRange(min: v003, max: v114, includeMax: true).difference(v114),
          equals(VersionRange(
              min: v003, max: v114, alwaysIncludeMaxPreRelease: true)));
    });

    test('with the min version makes the min exclusive', () {
      expect(
          VersionRange(min: v003, max: v114, includeMin: true).difference(v003),
          equals(VersionRange(min: v003, max: v114)));
    });

    test('with a disjoint range returns the original', () {
      expect(
          VersionRange(min: v003, max: v114)
              .difference(VersionRange(min: v123, max: v140)),
          equals(VersionRange(min: v003, max: v114)));
    });

    test('with an adjacent range returns the original', () {
      expect(
          VersionRange(min: v003, max: v114, includeMax: true)
              .difference(VersionRange(min: v114, max: v140)),
          equals(VersionRange(min: v003, max: v114, includeMax: true)));
    });

    test('with a range at the beginning cuts off the beginning of the range',
        () {
      expect(
          VersionRange(min: v080, max: v130)
              .difference(VersionRange(min: v010, max: v114)),
          equals(VersionConstraint.parse('>=1.1.4-0 <1.3.0')));
      expect(
          VersionRange(min: v080, max: v130)
              .difference(VersionRange(max: v114)),
          equals(VersionConstraint.parse('>=1.1.4-0 <1.3.0')));
      expect(
          VersionRange(min: v080, max: v130)
              .difference(VersionRange(min: v010, max: v114, includeMax: true)),
          equals(VersionRange(min: v114, max: v130)));
      expect(
          VersionRange(min: v080, max: v130, includeMin: true)
              .difference(VersionRange(min: v010, max: v080, includeMax: true)),
          equals(VersionRange(min: v080, max: v130)));
      expect(
          VersionRange(min: v080, max: v130, includeMax: true)
              .difference(VersionRange(min: v080, max: v130)),
          equals(VersionConstraint.parse('>=1.3.0-0 <=1.3.0')));
    });

    test('with a range at the end cuts off the end of the range', () {
      expect(
          VersionRange(min: v080, max: v130)
              .difference(VersionRange(min: v114, max: v140)),
          equals(VersionRange(min: v080, max: v114, includeMax: true)));
      expect(
          VersionRange(min: v080, max: v130)
              .difference(VersionRange(min: v114)),
          equals(VersionRange(min: v080, max: v114, includeMax: true)));
      expect(
          VersionRange(min: v080, max: v130)
              .difference(VersionRange(min: v114, max: v140, includeMin: true)),
          equals(VersionRange(
              min: v080, max: v114, alwaysIncludeMaxPreRelease: true)));
      expect(
          VersionRange(min: v080, max: v130, includeMax: true)
              .difference(VersionRange(min: v130, max: v140, includeMin: true)),
          equals(VersionRange(
              min: v080, max: v130, alwaysIncludeMaxPreRelease: true)));
      expect(
          VersionRange(min: v080, max: v130, includeMin: true)
              .difference(VersionRange(min: v080, max: v130)),
          equals(v080));
    });

    test('with a range in the middle cuts the range in half', () {
      expect(
          VersionRange(min: v003, max: v130)
              .difference(VersionRange(min: v072, max: v114)),
          equals(VersionConstraint.unionOf([
            VersionRange(min: v003, max: v072, includeMax: true),
            VersionConstraint.parse('>=1.1.4-0 <1.3.0')
          ])));
    });

    test('with a totally covering range returns empty', () {
      expect(
          VersionRange(min: v114, max: v200)
              .difference(VersionRange(min: v072, max: v300)),
          isEmpty);
      expect(
          VersionRange(min: v003, max: v114)
              .difference(VersionRange(min: v003, max: v114)),
          isEmpty);
      expect(
          VersionRange(min: v003, max: v114, includeMin: true, includeMax: true)
              .difference(VersionRange(
                  min: v003, max: v114, includeMin: true, includeMax: true)),
          isEmpty);
    });

    test(
        "with a version union that doesn't cover the range, returns the "
        'original', () {
      expect(
          VersionRange(min: v114, max: v140)
              .difference(VersionConstraint.unionOf([v010, v200])),
          equals(VersionRange(min: v114, max: v140)));
    });

    test('with a version union that intersects the ends, chops them off', () {
      expect(
          VersionRange(min: v114, max: v140).difference(
              VersionConstraint.unionOf([
            VersionRange(min: v080, max: v123),
            VersionRange(min: v130, max: v200)
          ])),
          equals(VersionConstraint.parse('>=1.2.3-0 <=1.3.0')));
    });

    test('with a version union that intersects the middle, chops it up', () {
      expect(
          VersionRange(min: v114, max: v140)
              .difference(VersionConstraint.unionOf([v123, v124, v130])),
          equals(VersionConstraint.unionOf([
            VersionRange(
                min: v114, max: v123, alwaysIncludeMaxPreRelease: true),
            VersionRange(
                min: v123, max: v124, alwaysIncludeMaxPreRelease: true),
            VersionRange(
                min: v124, max: v130, alwaysIncludeMaxPreRelease: true),
            VersionRange(min: v130, max: v140)
          ])));
    });

    test('with a version union that covers the whole range, returns empty', () {
      expect(
          VersionRange(min: v114, max: v140).difference(
              VersionConstraint.unionOf([v003, VersionRange(min: v010)])),
          equals(VersionConstraint.empty));
    });

    test('with a range with a pre-release min, returns the original', () {
      expect(
          VersionRange(max: v200)
              .difference(VersionConstraint.parse('>=2.0.0-dev')),
          equals(VersionRange(max: v200)));
    });

    test('with a range with a pre-release max, returns null', () {
      expect(
          VersionRange(max: v200)
              .difference(VersionConstraint.parse('<2.0.0-dev')),
          equals(VersionConstraint.empty));
    });

    group('with includeMaxPreRelease', () {
      group('for the minuend', () {
        test('preserves includeMaxPreRelease if the max version is included',
            () {
          expect(
              includeMaxPreReleaseRange
                  .difference(VersionConstraint.parse('<1.0.0')),
              equals(VersionRange(
                  min: Version.parse('1.0.0-0'),
                  max: v200,
                  includeMin: true,
                  alwaysIncludeMaxPreRelease: true)));
          expect(
              includeMaxPreReleaseRange
                  .difference(VersionConstraint.parse('<2.0.0')),
              equals(VersionRange(
                  min: v200.firstPreRelease,
                  max: v200,
                  includeMin: true,
                  alwaysIncludeMaxPreRelease: true)));
          expect(
              includeMaxPreReleaseRange.difference(includeMaxPreReleaseRange),
              equals(VersionConstraint.empty));
          expect(
              includeMaxPreReleaseRange
                  .difference(VersionConstraint.parse('<3.0.0')),
              equals(VersionConstraint.empty));
        });

        test('with a range with a pre-release min, adjusts the max', () {
          expect(
              includeMaxPreReleaseRange
                  .difference(VersionConstraint.parse('>=2.0.0-dev')),
              equals(VersionConstraint.parse('<2.0.0-dev')));
        });

        test('with a range with a pre-release max, adjusts the min', () {
          expect(
              includeMaxPreReleaseRange
                  .difference(VersionConstraint.parse('<2.0.0-dev')),
              equals(VersionConstraint.parse('>=2.0.0-dev <2.0.0')));
        });
      });

      group('for the subtrahend', () {
        group("doesn't create a pre-release minimum", () {
          test('when cutting off the bottom', () {
            expect(
                VersionConstraint.parse('<3.0.0')
                    .difference(includeMaxPreReleaseRange),
                equals(VersionRange(min: v200, max: v300, includeMin: true)));
          });

          test('with splitting down the middle', () {
            expect(
                VersionConstraint.parse('<4.0.0').difference(VersionRange(
                    min: v200,
                    max: v300,
                    includeMin: true,
                    alwaysIncludeMaxPreRelease: true)),
                equals(VersionConstraint.unionOf([
                  VersionRange(max: v200, alwaysIncludeMaxPreRelease: true),
                  VersionConstraint.parse('>=3.0.0 <4.0.0')
                ])));
          });

          test('can leave a single version', () {
            expect(
                VersionConstraint.parse('<=2.0.0')
                    .difference(includeMaxPreReleaseRange),
                equals(v200));
          });
        });
      });
    });
  });

  test('isEmpty', () {
    expect(VersionRange().isEmpty, isFalse);
    expect(VersionRange(min: v123, max: v124).isEmpty, isFalse);
  });

  group('compareTo()', () {
    test('orders by minimum first', () {
      _expectComparesSmaller(VersionRange(min: v003, max: v080),
          VersionRange(min: v010, max: v072));
      _expectComparesSmaller(VersionRange(min: v003, max: v080),
          VersionRange(min: v010, max: v080));
      _expectComparesSmaller(VersionRange(min: v003, max: v080),
          VersionRange(min: v010, max: v114));
    });

    test('orders by maximum second', () {
      _expectComparesSmaller(VersionRange(min: v003, max: v010),
          VersionRange(min: v003, max: v072));
    });

    test('includeMin comes before !includeMin', () {
      _expectComparesSmaller(
          VersionRange(min: v003, max: v080, includeMin: true),
          VersionRange(min: v003, max: v080));
    });

    test('includeMax comes after !includeMax', () {
      _expectComparesSmaller(VersionRange(min: v003, max: v080),
          VersionRange(min: v003, max: v080, includeMax: true));
    });

    test('includeMaxPreRelease comes after !includeMaxPreRelease', () {
      _expectComparesSmaller(
          VersionRange(max: v200), includeMaxPreReleaseRange);
    });

    test('no minimum comes before small minimum', () {
      _expectComparesSmaller(
          VersionRange(max: v010), VersionRange(min: v003, max: v010));
      _expectComparesSmaller(VersionRange(max: v010, includeMin: true),
          VersionRange(min: v003, max: v010));
    });

    test('no maximium comes after large maximum', () {
      _expectComparesSmaller(
          VersionRange(min: v003, max: v300), VersionRange(min: v003));
      _expectComparesSmaller(VersionRange(min: v003, max: v300),
          VersionRange(min: v003, includeMax: true));
    });
  });
}

void _expectComparesSmaller(VersionRange smaller, VersionRange larger) {
  expect(smaller.compareTo(larger), lessThan(0),
      reason: 'expected $smaller to sort below $larger');
  expect(larger.compareTo(smaller), greaterThan(0),
      reason: 'expected $larger to sort above $smaller');
}
