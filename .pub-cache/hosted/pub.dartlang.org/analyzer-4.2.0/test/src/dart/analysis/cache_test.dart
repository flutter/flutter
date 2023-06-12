// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/src/dart/analysis/cache.dart';
import 'package:analyzer_utilities/testing/map_entry_matcher.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CacheTest);
  });
}

Uint8List _b(int length) {
  return Uint8List(length);
}

@reflectiveTest
class CacheTest {
  test_get() {
    final cache = _newBytesCache(100);

    expect(cache.get('1'), isNull);
    expect(cache.map.entries, isEmpty);

    cache.put('1', _b(10));
    expect(cache.map.entries, [
      isMapEntry('1', hasLength(10)),
    ]);

    expect(cache.get('1'), hasLength(10));
  }

  test_get_reorders() {
    final cache = _newBytesCache(100);

    cache.put('1', _b(1));
    cache.put('2', _b(2));
    cache.put('3', _b(3));
    cache.put('4', _b(4));
    expect(cache.map.entries, [
      isMapEntry('1', hasLength(1)),
      isMapEntry('2', hasLength(2)),
      isMapEntry('3', hasLength(3)),
      isMapEntry('4', hasLength(4)),
    ]);

    expect(cache.get('2'), hasLength(2));
    expect(cache.map.entries, [
      isMapEntry('1', hasLength(1)),
      isMapEntry('3', hasLength(3)),
      isMapEntry('4', hasLength(4)),
      isMapEntry('2', hasLength(2)),
    ]);
  }

  test_put_evict_first() {
    var cache = _newBytesCache(100);

    // 40 + 50 < 100
    cache.put('1', _b(40));
    cache.put('2', _b(50));
    expect(cache.map.entries, [
      isMapEntry('1', hasLength(40)),
      isMapEntry('2', hasLength(50)),
    ]);

    // 40 + 50 + 30 > 100
    // So, '1' is evicted.
    cache.put('3', _b(30));
    expect(cache.map.entries, [
      isMapEntry('2', hasLength(50)),
      isMapEntry('3', hasLength(30)),
    ]);
  }

  test_put_evict_firstSecond() {
    var cache = _newBytesCache(100);

    // 10 + 80 < 100
    cache.put('1', _b(10));
    cache.put('2', _b(80));
    expect(cache.map.entries, [
      isMapEntry('1', hasLength(10)),
      isMapEntry('2', hasLength(80)),
    ]);

    // 10 + 80 + 30 > 100
    // So, '1' and '2' are evicted.
    cache.put('3', _b(30));
    expect(cache.map.entries, [
      isMapEntry('3', hasLength(30)),
    ]);
  }

  Cache<String, Uint8List> _newBytesCache(int maxSizeBytes) =>
      Cache<String, Uint8List>(maxSizeBytes, (bytes) => bytes.length);
}
