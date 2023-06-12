// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/cache.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CacheTest);
  });
}

List<int> _b(int length) {
  return List<int>.filled(length, 0);
}

@reflectiveTest
class CacheTest {
  test_get_notFound_evict() {
    var cache = _newBytesCache(100);

    // Request '1'.  Nothing found.
    expect(cache.get('1', _noBytes), isNull);

    // Add enough data to the store to force an eviction.
    cache.put('2', _b(40));
    cache.put('3', _b(40));
    cache.put('4', _b(40));
  }

  test_get_notFound_retry() {
    var cache = _newBytesCache(100);

    // Request '1'.  Nothing found.
    expect(cache.get('1', _noBytes), isNull);

    // Request '1' again.
    // The previous `null` result should not have been cached.
    expect(cache.get('1', () => _b(40)), isNotNull);
  }

  test_get_put_evict() {
    var cache = _newBytesCache(100);

    // Keys: [1, 2].
    cache.put('1', _b(40));
    cache.put('2', _b(50));

    // Request '1', so now it is the most recently used.
    // Keys: [2, 1].
    cache.get('1', _noBytes);

    // 40 + 50 + 30 > 100
    // So, '2' is evicted.
    cache.put('3', _b(30));
    expect(cache.get('1', _noBytes), hasLength(40));
    expect(cache.get('2', _noBytes), isNull);
    expect(cache.get('3', _noBytes), hasLength(30));
  }

  test_put_evict_first() {
    var cache = _newBytesCache(100);

    // 40 + 50 < 100
    cache.put('1', _b(40));
    cache.put('2', _b(50));
    expect(cache.get('1', _noBytes), hasLength(40));
    expect(cache.get('2', _noBytes), hasLength(50));

    // 40 + 50 + 30 > 100
    // So, '1' is evicted.
    cache.put('3', _b(30));
    expect(cache.get('1', _noBytes), isNull);
    expect(cache.get('2', _noBytes), hasLength(50));
    expect(cache.get('3', _noBytes), hasLength(30));
  }

  test_put_evict_firstAndSecond() {
    var cache = _newBytesCache(100);

    // 10 + 80 < 100
    cache.put('1', _b(10));
    cache.put('2', _b(80));
    expect(cache.get('1', _noBytes), hasLength(10));
    expect(cache.get('2', _noBytes), hasLength(80));

    // 10 + 80 + 30 > 100
    // So, '1' and '2' are evicted.
    cache.put('3', _b(30));
    expect(cache.get('1', _noBytes), isNull);
    expect(cache.get('2', _noBytes), isNull);
    expect(cache.get('3', _noBytes), hasLength(30));
  }

  Cache<String, List<int>> _newBytesCache(int maxSizeBytes) =>
      Cache<String, List<int>>(maxSizeBytes, (bytes) => bytes.length);

  static List<int>? _noBytes() => null;
}
