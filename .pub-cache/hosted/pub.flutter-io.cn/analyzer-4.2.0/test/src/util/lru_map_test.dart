// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/util/lru_map.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(_LRUCacheTest);
  });
}

@reflectiveTest
class _LRUCacheTest {
  LRUMap<int, String> cache = LRUMap<int, String>(3);

  void test_evict_notGet() {
    List<int> evictedKeys = <int>[];
    List<String> evictedValues = <String>[];
    cache = LRUMap<int, String>(3, (int key, String value) {
      evictedKeys.add(key);
      evictedValues.add(value);
    });
    // fill
    cache.put(1, 'A');
    cache.put(2, 'B');
    cache.put(3, 'C');
    // access '1' and '3'
    cache.get(1);
    cache.get(3);
    // put '4', evict '2'
    cache.put(4, 'D');
    expect(cache.get(1), 'A');
    expect(cache.get(2), isNull);
    expect(cache.get(3), 'C');
    expect(cache.get(4), 'D');
    // check eviction listener
    expect(evictedKeys, contains(2));
    expect(evictedValues, contains('B'));
  }

  void test_evict_notPut() {
    List<int> evictedKeys = <int>[];
    List<String> evictedValues = <String>[];
    cache = LRUMap<int, String>(3, (int key, String value) {
      evictedKeys.add(key);
      evictedValues.add(value);
    });
    // fill
    cache.put(1, 'A');
    cache.put(2, 'B');
    cache.put(3, 'C');
    // put '1' and '3'
    cache.put(1, 'AA');
    cache.put(3, 'CC');
    // put '4', evict '2'
    cache.put(4, 'D');
    expect(cache.get(1), 'AA');
    expect(cache.get(2), isNull);
    expect(cache.get(3), 'CC');
    expect(cache.get(4), 'D');
    // check eviction listener
    expect(evictedKeys, contains(2));
    expect(evictedValues, contains('B'));
  }

  void test_putGet() {
    // fill
    cache.put(1, 'A');
    cache.put(2, 'B');
    cache.put(3, 'C');
    // check
    expect(cache.get(1), 'A');
    expect(cache.get(2), 'B');
    expect(cache.get(3), 'C');
    expect(cache.get(4), isNull);
  }

  void test_remove() {
    cache.put(1, 'A');
    cache.put(2, 'B');
    cache.put(3, 'C');
    // remove
    cache.remove(1);
    cache.remove(3);
    // check
    expect(cache.get(1), isNull);
    expect(cache.get(2), 'B');
    expect(cache.get(3), isNull);
  }
}
