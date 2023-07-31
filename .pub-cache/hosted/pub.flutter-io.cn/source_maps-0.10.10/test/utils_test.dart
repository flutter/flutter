// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests for the binary search utility algorithm.
library test.utils_test;

import 'package:test/test.dart';
import 'package:source_maps/src/utils.dart';

void main() {
  group('binary search', () {
    test('empty', () {
      expect(binarySearch([], (x) => true), -1);
    });

    test('single element', () {
      expect(binarySearch([1], (x) => true), 0);
      expect(binarySearch([1], (x) => false), 1);
    });

    test('no matches', () {
      var list = [1, 2, 3, 4, 5, 6, 7];
      expect(binarySearch(list, (x) => false), list.length);
    });

    test('all match', () {
      var list = [1, 2, 3, 4, 5, 6, 7];
      expect(binarySearch(list, (x) => true), 0);
    });

    test('compare with linear search', () {
      for (var size = 0; size < 100; size++) {
        var list = [];
        for (var i = 0; i < size; i++) {
          list.add(i);
        }
        for (var pos = 0; pos <= size; pos++) {
          expect(binarySearch(list, (x) => x >= pos),
              _linearSearch(list, (x) => x >= pos));
        }
      }
    });
  });
}

int _linearSearch(list, predicate) {
  if (list.length == 0) return -1;
  for (var i = 0; i < list.length; i++) {
    if (predicate(list[i])) return i;
  }
  return list.length;
}
