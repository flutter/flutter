// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('factory', () {
    test('ignores empty constraints', () {
      expect(
          VersionConstraint.unionOf([
            VersionConstraint.empty,
            VersionConstraint.empty,
            v123,
            VersionConstraint.empty
          ]),
          equals(v123));

      expect(
          VersionConstraint.unionOf(
              [VersionConstraint.empty, VersionConstraint.empty]),
          isEmpty);
    });

    test('returns an empty constraint for an empty list', () {
      expect(VersionConstraint.unionOf([]), isEmpty);
    });

    test('any constraints override everything', () {
      expect(
          VersionConstraint.unionOf([
            v123,
            VersionConstraint.any,
            v200,
            VersionRange(min: v234, max: v250)
          ]),
          equals(VersionConstraint.any));
    });

    test('flattens other unions', () {
      expect(
          VersionConstraint.unionOf([
            v072,
            VersionConstraint.unionOf([v123, v124]),
            v250
          ]),
          equals(VersionConstraint.unionOf([v072, v123, v124, v250])));
    });

    test('returns a single merged range as-is', () {
      expect(
          VersionConstraint.unionOf([
            VersionRange(min: v080, max: v140),
            VersionRange(min: v123, max: v200)
          ]),
          equals(VersionRange(min: v080, max: v200)));
    });
  });

  group('equality', () {
    test("doesn't depend on original order", () {
      expect(
          VersionConstraint.unionOf([
            v250,
            VersionRange(min: v201, max: v234),
            v124,
            v072,
            VersionRange(min: v080, max: v114),
            v123
          ]),
          equals(VersionConstraint.unionOf([
            v072,
            VersionRange(min: v080, max: v114),
            v123,
            v124,
            VersionRange(min: v201, max: v234),
            v250
          ])));
    });

    test('merges overlapping ranges', () {
      expect(
          VersionConstraint.unionOf([
            VersionRange(min: v003, max: v072),
            VersionRange(min: v010, max: v080),
            VersionRange(min: v114, max: v124),
            VersionRange(min: v123, max: v130)
          ]),
          equals(VersionConstraint.unionOf([
            VersionRange(min: v003, max: v080),
            VersionRange(min: v114, max: v130)
          ])));
    });

    test('merges adjacent ranges', () {
      expect(
          VersionConstraint.unionOf([
            VersionRange(min: v003, max: v072, includeMax: true),
            VersionRange(min: v072, max: v080),
            VersionRange(
                min: v114, max: v124, alwaysIncludeMaxPreRelease: true),
            VersionRange(min: v124, max: v130, includeMin: true),
            VersionRange(min: v130.firstPreRelease, max: v200, includeMin: true)
          ]),
          equals(VersionConstraint.unionOf([
            VersionRange(min: v003, max: v080),
            VersionRange(min: v114, max: v200)
          ])));
    });

    test("doesn't merge not-quite-adjacent ranges", () {
      expect(
          VersionConstraint.unionOf([
            VersionRange(min: v114, max: v124),
            VersionRange(min: v124, max: v130, includeMin: true)
          ]),
          isNot(equals(VersionRange(min: v114, max: v130))));

      expect(
          VersionConstraint.unionOf([
            VersionRange(min: v003, max: v072),
            VersionRange(min: v072, max: v080)
          ]),
          isNot(equals(VersionRange(min: v003, max: v080))));
    });

    test('merges version numbers into ranges', () {
      expect(
          VersionConstraint.unionOf([
            VersionRange(min: v003, max: v072),
            v010,
            VersionRange(min: v114, max: v124),
            v123
          ]),
          equals(VersionConstraint.unionOf([
            VersionRange(min: v003, max: v072),
            VersionRange(min: v114, max: v124)
          ])));
    });

    test('merges adjacent version numbers into ranges', () {
      expect(
          VersionConstraint.unionOf([
            VersionRange(
                min: v003, max: v072, alwaysIncludeMaxPreRelease: true),
            v072,
            v114,
            VersionRange(min: v114, max: v124),
            v124.firstPreRelease
          ]),
          equals(VersionConstraint.unionOf([
            VersionRange(min: v003, max: v072, includeMax: true),
            VersionRange(
                min: v114,
                max: v124.firstPreRelease,
                includeMin: true,
                includeMax: true)
          ])));
    });

    test("doesn't merge not-quite-adjacent version numbers into ranges", () {
      expect(
          VersionConstraint.unionOf([VersionRange(min: v003, max: v072), v072]),
          isNot(equals(VersionRange(min: v003, max: v072, includeMax: true))));
    });
  });

  test('isEmpty returns false', () {
    expect(
        VersionConstraint.unionOf([
          VersionRange(min: v003, max: v080),
          VersionRange(min: v123, max: v130),
        ]),
        isNot(isEmpty));
  });

  test('isAny returns false', () {
    expect(
        VersionConstraint.unionOf([
          VersionRange(min: v003, max: v080),
          VersionRange(min: v123, max: v130),
        ]).isAny,
        isFalse);
  });

  test('allows() allows anything the components allow', () {
    var union = VersionConstraint.unionOf([
      VersionRange(min: v003, max: v080),
      VersionRange(min: v123, max: v130),
      v200
    ]);

    expect(union, allows(v010));
    expect(union, doesNotAllow(v080));
    expect(union, allows(v124));
    expect(union, doesNotAllow(v140));
    expect(union, allows(v200));
  });

  group('allowsAll()', () {
    test('for a version, returns true if any component allows the version', () {
      var union = VersionConstraint.unionOf([
        VersionRange(min: v003, max: v080),
        VersionRange(min: v123, max: v130),
        v200
      ]);

      expect(union.allowsAll(v010), isTrue);
      expect(union.allowsAll(v080), isFalse);
      expect(union.allowsAll(v124), isTrue);
      expect(union.allowsAll(v140), isFalse);
      expect(union.allowsAll(v200), isTrue);
    });

    test(
        'for a version range, returns true if any component allows the whole '
        'range', () {
      var union = VersionConstraint.unionOf([
        VersionRange(min: v003, max: v080),
        VersionRange(min: v123, max: v130)
      ]);

      expect(union.allowsAll(VersionRange(min: v003, max: v080)), isTrue);
      expect(union.allowsAll(VersionRange(min: v010, max: v072)), isTrue);
      expect(union.allowsAll(VersionRange(min: v010, max: v124)), isFalse);
    });

    group('for a union,', () {
      var union = VersionConstraint.unionOf([
        VersionRange(min: v003, max: v080),
        VersionRange(min: v123, max: v130)
      ]);

      test('returns true if every constraint matches a different constraint',
          () {
        expect(
            union.allowsAll(VersionConstraint.unionOf([
              VersionRange(min: v010, max: v072),
              VersionRange(min: v124, max: v130)
            ])),
            isTrue);
      });

      test('returns true if every constraint matches the same constraint', () {
        expect(
            union.allowsAll(VersionConstraint.unionOf([
              VersionRange(min: v003, max: v010),
              VersionRange(min: v072, max: v080)
            ])),
            isTrue);
      });

      test("returns false if there's an unmatched constraint", () {
        expect(
            union.allowsAll(VersionConstraint.unionOf([
              VersionRange(min: v010, max: v072),
              VersionRange(min: v124, max: v130),
              VersionRange(min: v140, max: v200)
            ])),
            isFalse);
      });

      test("returns false if a constraint isn't fully matched", () {
        expect(
            union.allowsAll(VersionConstraint.unionOf([
              VersionRange(min: v010, max: v114),
              VersionRange(min: v124, max: v130)
            ])),
            isFalse);
      });
    });
  });

  group('allowsAny()', () {
    test('for a version, returns true if any component allows the version', () {
      var union = VersionConstraint.unionOf([
        VersionRange(min: v003, max: v080),
        VersionRange(min: v123, max: v130),
        v200
      ]);

      expect(union.allowsAny(v010), isTrue);
      expect(union.allowsAny(v080), isFalse);
      expect(union.allowsAny(v124), isTrue);
      expect(union.allowsAny(v140), isFalse);
      expect(union.allowsAny(v200), isTrue);
    });

    test(
        'for a version range, returns true if any component allows part of '
        'the range', () {
      var union =
          VersionConstraint.unionOf([VersionRange(min: v003, max: v080), v123]);

      expect(union.allowsAny(VersionRange(min: v010, max: v114)), isTrue);
      expect(union.allowsAny(VersionRange(min: v114, max: v124)), isTrue);
      expect(union.allowsAny(VersionRange(min: v124, max: v130)), isFalse);
    });

    group('for a union,', () {
      var union = VersionConstraint.unionOf([
        VersionRange(min: v010, max: v080),
        VersionRange(min: v123, max: v130)
      ]);

      test('returns true if any constraint matches', () {
        expect(
            union.allowsAny(VersionConstraint.unionOf(
                [v072, VersionRange(min: v200, max: v300)])),
            isTrue);

        expect(
            union.allowsAny(VersionConstraint.unionOf(
                [v003, VersionRange(min: v124, max: v300)])),
            isTrue);
      });

      test('returns false if no constraint matches', () {
        expect(
            union.allowsAny(VersionConstraint.unionOf([
              v003,
              VersionRange(min: v130, max: v140),
              VersionRange(min: v140, max: v200)
            ])),
            isFalse);
      });
    });
  });

  group('intersect()', () {
    test('with an overlapping version, returns that version', () {
      expect(
          VersionConstraint.unionOf([
            VersionRange(min: v010, max: v080),
            VersionRange(min: v123, max: v140)
          ]).intersect(v072),
          equals(v072));
    });

    test('with a non-overlapping version, returns an empty constraint', () {
      expect(
          VersionConstraint.unionOf([
            VersionRange(min: v010, max: v080),
            VersionRange(min: v123, max: v140)
          ]).intersect(v300),
          isEmpty);
    });

    test('with an overlapping range, returns that range', () {
      var range = VersionRange(min: v072, max: v080);
      expect(
          VersionConstraint.unionOf([
            VersionRange(min: v010, max: v080),
            VersionRange(min: v123, max: v140)
          ]).intersect(range),
          equals(range));
    });

    test('with a non-overlapping range, returns an empty constraint', () {
      expect(
          VersionConstraint.unionOf([
            VersionRange(min: v010, max: v080),
            VersionRange(min: v123, max: v140)
          ]).intersect(VersionRange(min: v080, max: v123)),
          isEmpty);
    });

    test('with a parially-overlapping range, returns the overlapping parts',
        () {
      expect(
          VersionConstraint.unionOf([
            VersionRange(min: v010, max: v080),
            VersionRange(min: v123, max: v140)
          ]).intersect(VersionRange(min: v072, max: v130)),
          equals(VersionConstraint.unionOf([
            VersionRange(min: v072, max: v080),
            VersionRange(min: v123, max: v130)
          ])));
    });

    group('for a union,', () {
      var union = VersionConstraint.unionOf([
        VersionRange(min: v003, max: v080),
        VersionRange(min: v123, max: v130)
      ]);

      test('returns the overlapping parts', () {
        expect(
            union.intersect(VersionConstraint.unionOf([
              v010,
              VersionRange(min: v072, max: v124),
              VersionRange(min: v124, max: v130)
            ])),
            equals(VersionConstraint.unionOf([
              v010,
              VersionRange(min: v072, max: v080),
              VersionRange(min: v123, max: v124),
              VersionRange(min: v124, max: v130)
            ])));
      });

      test("drops parts that don't match", () {
        expect(
            union.intersect(VersionConstraint.unionOf([
              v003,
              VersionRange(min: v072, max: v080),
              VersionRange(min: v080, max: v123)
            ])),
            equals(VersionRange(min: v072, max: v080)));
      });
    });
  });

  group('difference()', () {
    test("ignores ranges that don't intersect", () {
      expect(
          VersionConstraint.unionOf([
            VersionRange(min: v072, max: v080),
            VersionRange(min: v123, max: v130)
          ]).difference(VersionConstraint.unionOf([
            VersionRange(min: v003, max: v010),
            VersionRange(min: v080, max: v123),
            VersionRange(min: v140)
          ])),
          equals(VersionConstraint.unionOf([
            VersionRange(min: v072, max: v080),
            VersionRange(min: v123, max: v130)
          ])));
    });

    test('removes overlapping portions', () {
      expect(
          VersionConstraint.unionOf([
            VersionRange(min: v010, max: v080),
            VersionRange(min: v123, max: v130)
          ]).difference(VersionConstraint.unionOf(
              [VersionRange(min: v003, max: v072), VersionRange(min: v124)])),
          equals(VersionConstraint.unionOf([
            VersionRange(
                min: v072.firstPreRelease, max: v080, includeMin: true),
            VersionRange(min: v123, max: v124, includeMax: true)
          ])));
    });

    test('removes multiple portions from the same range', () {
      expect(
          VersionConstraint.unionOf([
            VersionRange(min: v010, max: v114),
            VersionRange(min: v130, max: v200)
          ]).difference(VersionConstraint.unionOf([v072, v080])),
          equals(VersionConstraint.unionOf([
            VersionRange(
                min: v010, max: v072, alwaysIncludeMaxPreRelease: true),
            VersionRange(
                min: v072, max: v080, alwaysIncludeMaxPreRelease: true),
            VersionRange(min: v080, max: v114),
            VersionRange(min: v130, max: v200)
          ])));
    });

    test('removes the same range from multiple ranges', () {
      expect(
          VersionConstraint.unionOf([
            VersionRange(min: v010, max: v072),
            VersionRange(min: v080, max: v123),
            VersionRange(min: v124, max: v130),
            VersionRange(min: v200, max: v234),
            VersionRange(min: v250, max: v300)
          ]).difference(VersionRange(min: v114, max: v201)),
          equals(VersionConstraint.unionOf([
            VersionRange(min: v010, max: v072),
            VersionRange(min: v080, max: v114, includeMax: true),
            VersionRange(
                min: v201.firstPreRelease, max: v234, includeMin: true),
            VersionRange(min: v250, max: v300)
          ])));
    });
  });
}
