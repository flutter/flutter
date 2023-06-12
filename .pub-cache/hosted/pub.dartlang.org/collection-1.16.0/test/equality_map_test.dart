// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:test/test.dart';

void main() {
  test('uses the given equality', () {
    var map = EqualityMap(const IterableEquality());
    expect(map, isEmpty);

    map[[1, 2, 3]] = 1;
    expect(map, containsPair([1, 2, 3], 1));

    map[[1, 2, 3]] = 2;
    expect(map, containsPair([1, 2, 3], 2));

    map[[2, 3, 4]] = 3;
    expect(map, containsPair([1, 2, 3], 2));
    expect(map, containsPair([2, 3, 4], 3));
  });

  test('EqualityMap.from() prefers the lattermost equivalent key', () {
    var map = EqualityMap.from(const IterableEquality(), {
      [1, 2, 3]: 1,
      [2, 3, 4]: 2,
      [1, 2, 3]: 3,
      [2, 3, 4]: 4,
      [1, 2, 3]: 5,
      [1, 2, 3]: 6,
    });

    expect(map, containsPair([1, 2, 3], 6));
    expect(map, containsPair([2, 3, 4], 4));
  });
}
