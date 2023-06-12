// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:test/test.dart';

/// Iterable like [base] except that it throws when value equals [errorValue].
Iterable iterError(Iterable base, int errorValue) {
  // ignore: only_throw_errors
  return base.map((x) => x == errorValue ? throw 'BAD' : x);
}

void main() {
  test('Basic', () {
    expect(
        IterableZip([
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9]
        ]),
        equals([
          [1, 4, 7],
          [2, 5, 8],
          [3, 6, 9]
        ]));
  });

  test('Uneven length 1', () {
    expect(
        IterableZip([
          [1, 2, 3, 99, 100],
          [4, 5, 6],
          [7, 8, 9]
        ]),
        equals([
          [1, 4, 7],
          [2, 5, 8],
          [3, 6, 9]
        ]));
  });

  test('Uneven length 2', () {
    expect(
        IterableZip([
          [1, 2, 3],
          [4, 5, 6, 99, 100],
          [7, 8, 9]
        ]),
        equals([
          [1, 4, 7],
          [2, 5, 8],
          [3, 6, 9]
        ]));
  });

  test('Uneven length 3', () {
    expect(
        IterableZip([
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9, 99, 100]
        ]),
        equals([
          [1, 4, 7],
          [2, 5, 8],
          [3, 6, 9]
        ]));
  });

  test('Uneven length 3', () {
    expect(
        IterableZip([
          [1, 2, 3, 98],
          [4, 5, 6],
          [7, 8, 9, 99, 100]
        ]),
        equals([
          [1, 4, 7],
          [2, 5, 8],
          [3, 6, 9]
        ]));
  });

  test('Empty 1', () {
    expect(
        IterableZip([
          [],
          [4, 5, 6],
          [7, 8, 9]
        ]),
        equals([]));
  });

  test('Empty 2', () {
    expect(
        IterableZip([
          [1, 2, 3],
          [],
          [7, 8, 9]
        ]),
        equals([]));
  });

  test('Empty 3', () {
    expect(
        IterableZip([
          [1, 2, 3],
          [4, 5, 6],
          []
        ]),
        equals([]));
  });

  test('Empty source', () {
    expect(IterableZip([]), equals([]));
  });

  test('Single Source', () {
    expect(
        IterableZip([
          [1, 2, 3]
        ]),
        equals([
          [1],
          [2],
          [3]
        ]));
  });

  test('Not-lists', () {
    // Use other iterables than list literals.
    var it1 = [1, 2, 3, 4, 5, 6].where((x) => x < 4);
    var it2 = {4, 5, 6};
    var it3 = {7: 0, 8: 0, 9: 0}.keys;
    var allIts = Iterable.generate(3, (i) => [it1, it2, it3][i]);
    expect(
        IterableZip(allIts),
        equals([
          [1, 4, 7],
          [2, 5, 8],
          [3, 6, 9]
        ]));
  });

  test('Error 1', () {
    expect(
        () => IterableZip([
              iterError([1, 2, 3], 2),
              [4, 5, 6],
              [7, 8, 9]
            ]).toList(),
        throwsA(equals('BAD')));
  });

  test('Error 2', () {
    expect(
        () => IterableZip([
              [1, 2, 3],
              iterError([4, 5, 6], 5),
              [7, 8, 9]
            ]).toList(),
        throwsA(equals('BAD')));
  });

  test('Error 3', () {
    expect(
        () => IterableZip([
              [1, 2, 3],
              [4, 5, 6],
              iterError([7, 8, 9], 8)
            ]).toList(),
        throwsA(equals('BAD')));
  });

  test('Error at end', () {
    expect(
        () => IterableZip([
              [1, 2, 3],
              iterError([4, 5, 6], 6),
              [7, 8, 9]
            ]).toList(),
        throwsA(equals('BAD')));
  });

  test('Error before first end', () {
    expect(
        () => IterableZip([
              iterError([1, 2, 3, 4], 4),
              [4, 5, 6],
              [7, 8, 9]
            ]).toList(),
        throwsA(equals('BAD')));
  });

  test('Error after first end', () {
    expect(
        IterableZip([
          [1, 2, 3],
          [4, 5, 6],
          iterError([7, 8, 9, 10], 10)
        ]),
        equals([
          [1, 4, 7],
          [2, 5, 8],
          [3, 6, 9]
        ]));
  });
}
