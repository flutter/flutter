// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

@immutable
class _MockKey {
  const _MockKey({required this.hashCode, required this.payload});

  @override
  final int hashCode;
  final String payload;

  @override
  bool operator ==(Object other) {
    return other is _MockKey && other.payload == payload;
  }
}

void main() {
  test('PersistentHashMap - Simple Test', () {
    final maps = <PersistentHashMap<String, int>>[];
    maps.add(const PersistentHashMap<String, int>.empty());
    for (var i = 0; i < 50; i++) {
      maps.add(maps.last.put('key:$i', i));
    }
    for (var i = 1; i < maps.length; i++) {
      final PersistentHashMap<String, int> m = maps[i];
      for (var j = 0; j < i; j++) {
        expect(m['key:$j'], equals(j));
      }
    }
  });

  test('PersistentHashMap - hash collisions', () {
    const key1 = _MockKey(hashCode: 1, payload: 'key:1');
    const key2 = _MockKey(hashCode: 0 | (1 << 5), payload: 'key:2');
    const key3 = _MockKey(hashCode: 1, payload: 'key:3');
    const key4 = _MockKey(hashCode: 1 | (1 << 5), payload: 'key:4');

    final PersistentHashMap<_MockKey, String> map =
        const PersistentHashMap<_MockKey, String>.empty()
            .put(key1, 'a')
            .put(key2, 'b')
            .put(key3, 'c');

    expect(map[key1], equals('a'));
    expect(map[key2], equals('b'));
    expect(map[key3], equals('c'));

    final PersistentHashMap<_MockKey, String> map2 = map.put(key4, 'd');
    expect(map2[key4], equals('d'));

    final PersistentHashMap<_MockKey, String> map3 = map2
        .put(key1, 'updated(a)')
        .put(key2, 'updated(b)')
        .put(key3, 'updated(c)')
        .put(key4, 'updated(d)');
    expect(map3[key1], equals('updated(a)'));
    expect(map3[key2], equals('updated(b)'));
    expect(map3[key3], equals('updated(c)'));
    expect(map3[key4], equals('updated(d)'));
  });

  test('PersistentHashMap - inflation of nodes', () {
    final maps = <PersistentHashMap<_MockKey, int>>[];
    maps.add(const PersistentHashMap<_MockKey, int>.empty());
    for (var i = 0; i < 32 * 32; i++) {
      maps.add(maps.last.put(_MockKey(hashCode: i, payload: '$i'), i));
    }
    for (var i = 1; i < maps.length; i++) {
      final PersistentHashMap<_MockKey, int> m = maps[i];
      for (var j = 0; j < i; j++) {
        expect(m[_MockKey(hashCode: j, payload: '$j')], equals(j));
      }
    }
  });

  test('PersistentHashMap - bit 31 and compressed bitmap popcount', () {
    // Place index 31 (1 << 31) first so occupiedIndices has bit 31 set during
    // every subsequent _CompressedNode.put call while below the 16-entry
    // _FullNode inflation threshold, then cross inflation with bit 31 occupied.
    const compressedIndices = <int>[31, 0, 1, 2, 5, 7, 11, 13, 15, 17, 19, 23, 25, 29, 30];
    var map = const PersistentHashMap<_MockKey, int>.empty();
    for (final index in compressedIndices) {
      map = map.put(_MockKey(hashCode: index, payload: 'k$index'), index * 10);
    }
    for (final index in compressedIndices) {
      expect(map[_MockKey(hashCode: index, payload: 'k$index')], equals(index * 10));
    }
    expect(map[const _MockKey(hashCode: 28, payload: 'missing')], isNull);

    const inflationIndices = <int>[3, 4];
    for (final index in inflationIndices) {
      map = map.put(_MockKey(hashCode: index, payload: 'k$index'), index * 10);
    }
    for (final index in <int>[...compressedIndices, ...inflationIndices]) {
      expect(map[_MockKey(hashCode: index, payload: 'k$index')], equals(index * 10));
    }
    expect(map[const _MockKey(hashCode: 28, payload: 'missing')], isNull);
  });
}
