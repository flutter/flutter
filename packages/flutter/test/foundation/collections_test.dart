// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/foundation/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('listEquals', () {
    final List<int> listA = <int>[1, 2, 3];
    final List<int> listB = <int>[1, 2, 3];
    final List<int> listC = <int>[1, 2];
    final List<int> listD = <int>[3, 2, 1];

    expect(listEquals<void>(null, null), isTrue);
    expect(listEquals(listA, null), isFalse);
    expect(listEquals(null, listB), isFalse);
    expect(listEquals(listA, listA), isTrue);
    expect(listEquals(listA, listB), isTrue);
    expect(listEquals(listA, listC), isFalse);
    expect(listEquals(listA, listD), isFalse);
  });
  test('setEquals', () {
    final Set<int> setA = <int>{1, 2, 3};
    final Set<int> setB = <int>{1, 2, 3};
    final Set<int> setC = <int>{1, 2};
    final Set<int> setD = <int>{3, 2, 1};

    expect(setEquals<void>(null, null), isTrue);
    expect(setEquals(setA, null), isFalse);
    expect(setEquals(null, setB), isFalse);
    expect(setEquals(setA, setA), isTrue);
    expect(setEquals(setA, setB), isTrue);
    expect(setEquals(setA, setC), isFalse);
    expect(setEquals(setA, setD), isTrue);
  });
  test('mapEquals', () {
    final Map<int, int> mapA = <int, int>{1:1, 2:2, 3:3};
    final Map<int, int> mapB = <int, int>{1:1, 2:2, 3:3};
    final Map<int, int> mapC = <int, int>{1:1, 2:2};
    final Map<int, int> mapD = <int, int>{3:3, 2:2, 1:1};
    final Map<int, int> mapE = <int, int>{3:1, 2:2, 1:3};

    expect(mapEquals<void, void>(null, null), isTrue);
    expect(mapEquals(mapA, null), isFalse);
    expect(mapEquals(null, mapB), isFalse);
    expect(mapEquals(mapA, mapA), isTrue);
    expect(mapEquals(mapA, mapB), isTrue);
    expect(mapEquals(mapA, mapC), isFalse);
    expect(mapEquals(mapA, mapD), isTrue);
    expect(mapEquals(mapA, mapE), isFalse);
  });
  test('binarySearch', () {
    final List<int> items = <int>[1, 2, 3];

    expect(binarySearch(items, 1), 0);
    expect(binarySearch(items, 2), 1);
    expect(binarySearch(items, 3), 2);
    expect(binarySearch(items, 12), -1);
  });
}
