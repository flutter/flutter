// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library quiver.collection.bimap_test;

import 'package:quiver/src/collection/bimap.dart';
import 'package:test/test.dart';

void main() {
  group('BiMap', () {
    test('should construct a HashBiMap', () {
      expect(BiMap() is HashBiMap, true);
    });
  });

  group('HashBiMap', () {
    late BiMap<String, int> map;
    const String k1 = 'k1', k2 = 'k2', k3 = 'k3';
    const int v1 = 1, v2 = 2, v3 = 3;

    setUp(() {
      map = HashBiMap();
    });

    test('should initialize empty', () {
      expect(map.isEmpty, true);
      expect(map.isNotEmpty, false);
      expect(map.inverse.isEmpty, true);
      expect(map.inverse.isNotEmpty, false);
    });

    test('should support null keys', () {
      final map = BiMap<String?, int>();
      map[null] = 5;
      expect(map.isEmpty, false);
      expect(map.containsKey(null), true);
      expect(map.containsValue(5), true);
      expect(map.keys, contains(null));

      expect(map.inverse.containsKey(5), true);
      expect(map.inverse.containsValue(null), true);
      expect(map.inverse.keys, contains(5));
    });

    test('should support null values', () {
      final map = BiMap<String, int?>();
      map[k1] = null;
      expect(map.isEmpty, false);
      expect(map.containsKey(k1), true);
      expect(map.containsValue(null), true);
      expect(map[k1], isNull);
    });

    test('should not be empty after adding a mapping', () {
      map[k1] = v1;
      expect(map.isEmpty, false);
      expect(map.isNotEmpty, true);
      expect(map.inverse.isEmpty, false);
      expect(map.inverse.isNotEmpty, true);
    });

    test('should not be empty after adding a mapping via its inverse', () {
      map.inverse[v1] = k1;
      expect(map.isEmpty, false);
      expect(map.isNotEmpty, true);
      expect(map.inverse.isEmpty, false);
      expect(map.inverse.isNotEmpty, true);
    });

    test('should contain added mappings', () {
      map[k1] = v1;
      map[k2] = v2;
      expect(map[k1], v1);
      expect(map[k2], v2);
      expect(map.inverse[v1], k1);
      expect(map.inverse[v2], k2);
    });

    test('should contain mappings added via its inverse', () {
      map.inverse[v1] = k1;
      map.inverse[v2] = k2;
      expect(map[k1], v1);
      expect(map[k2], v2);
      expect(map.inverse[v1], k1);
      expect(map.inverse[v2], k2);
    });

    test('should allow overwriting existing keys', () {
      map[k1] = v1;
      map[k1] = v2;
      expect(map[k1], v2);
      expect(map.inverse.containsKey(v1), false);
      expect(map.inverse[v2], k1);
    });

    test('should allow overwriting existing keys via its inverse', () {
      map.inverse[v1] = k1;
      map.inverse[v1] = k2;
      expect(map[k2], v1);
      expect(map.inverse.containsKey(v2), false);
      expect(map.inverse[v1], k2);
    });

    test('should allow overwriting existing key-value pairs', () {
      map[k1] = v1;
      map[k1] = v1;
      expect(map[k1], v1);
      expect(map.inverse.containsKey(v1), true);
      expect(map.inverse[v1], k1);
    });

    test('should allow overwriting existing key-value pairs via its inverse',
        () {
      map.inverse[v1] = k1;
      map.inverse[v1] = k1;
      expect(map[k1], v1);
      expect(map.inverse.containsKey(v1), true);
      expect(map.inverse[v1], k1);
    });

    test('should throw on overwriting unmapped keys with a mapped value', () {
      map[k1] = v1;
      expect(() => map[k2] = v1, throwsArgumentError);
      expect(map.containsKey(k2), false);
      expect(map.inverse.containsValue(k2), false);
    });

    test('should throw on overwriting unmapped keys with a mapped null value',
        () {
      final map = BiMap<String, int?>();
      map[k1] = null;
      expect(() => map[k2] = null, throwsArgumentError);
      expect(map.containsKey(k2), false);
      expect(map.inverse.containsValue(k2), false);
    });

    test(
        'should throw on overwriting unmapped keys with a mapped value via inverse',
        () {
      map[k1] = v1;
      expect(() => map.inverse[v2] = k1, throwsArgumentError);
      expect(map.containsValue(v2), false);
      expect(map.inverse.containsKey(v2), false);
    });

    test(
        'should throw on overwriting unmapped keys with a mapped null value via inverse',
        () {
      final map = BiMap<String?, int>();
      map[null] = v1;
      expect(() => map.inverse[v2] = null, throwsArgumentError);
      expect(map.containsValue(v2), false);
      expect(map.inverse.containsKey(v2), false);
    });

    test('should allow force-adding unmapped keys with a mapped value', () {
      map[k1] = v1;
      map.replace(k2, v1);
      expect(map[k2], v1);
      expect(map.containsKey(k1), false);
      expect(map.inverse[v1], k2);
      expect(map.inverse.containsValue(k1), false);
    });

    test(
        'should allow force-adding unmapped keys with a mapped value via inverse',
        () {
      map.inverse[v1] = k1;
      map.inverse.replace(v2, k1);
      expect(map[k1], v2);
      expect(map.containsValue(v1), false);
      expect(map.inverse[v2], k1);
      expect(map.inverse.containsKey(v1), false);
    });

    test('should not contain removed mappings', () {
      map[k1] = v1;
      map.remove(k1);
      expect(map.containsKey(k1), false);
      expect(map.inverse.containsKey(v1), false);

      map[k1] = v1;
      map[k2] = v2;
      map.removeWhere((k, v) => v.isOdd);
      expect(map.containsKey(k1), false);
      expect(map.containsKey(k2), true);
      expect(map.inverse.containsKey(v1), false);
      expect(map.inverse.containsKey(v2), true);
    });

    test('should not contain mappings removed from its inverse', () {
      map[k1] = v1;
      map.inverse.remove(v1);
      expect(map.containsKey(k1), false);
      expect(map.inverse.containsKey(v1), false);

      map[k1] = v1;
      map[k2] = v2;
      map.inverse.removeWhere((v, k) => v.isOdd);
      expect(map.containsKey(k1), false);
      expect(map.containsKey(k2), true);
      expect(map.inverse.containsKey(v1), false);
      expect(map.inverse.containsKey(v2), true);
    });

    test('should update both sides', () {
      map[k1] = v1;
      map.update(k1, (v) => v + 1);
      expect(map[k1], equals(v1 + 1));
      expect(map.inverse[v1 + 1], equals(k1));

      map[k1] = v1;
      map.inverse.update(v1, (k) => '_$k');
      expect(map['_$k1'], equals(v1));
      expect(map.inverse[v1], equals('_$k1'));
    });

    test('should update absent key values', () {
      map[k1] = v1;
      map.update(k2, (v) => v + 1, ifAbsent: () => 0);
      expect(map[k2], equals(0));
      expect(map.inverse[0], equals(k2));

      map[k1] = v1;
      map.inverse.update(v2, (k) => '_$k', ifAbsent: () => '_X');
      expect(map['_X'], equals(v2));
      expect(map.inverse[v2], equals('_X'));
    });

    test('should update all values', () {
      map[k1] = v1;
      map[k2] = v2;
      map.updateAll((k, v) => v + k.length);
      expect(map[k1], equals(3));
      expect(map[k2], equals(4));
      expect(map.inverse[3], equals(k1));
      expect(map.inverse[4], equals(k2));
    });

    test('should be empty after clear', () {
      map[k1] = v1;
      map[k2] = v2;
      map.clear();
      expect(map.isEmpty, true);
      expect(map.inverse.isEmpty, true);
    });

    test('should be empty after inverse.clear', () {
      map[k1] = v1;
      map[k2] = v2;
      map.inverse.clear();
      expect(map.isEmpty, true);
      expect(map.inverse.isEmpty, true);
    });

    test('should contain mapped keys', () {
      map[k1] = v1;
      map[k2] = v2;
      expect(map.containsKey(k1), true);
      expect(map.containsKey(k2), true);
      expect(map.keys, unorderedEquals([k1, k2]));
      expect(map.inverse.containsKey(v1), true);
      expect(map.inverse.containsKey(v2), true);
      expect(map.inverse.keys, unorderedEquals([v1, v2]));
    });

    test('should contain keys mapped via its inverse', () {
      map.inverse[v1] = k1;
      map.inverse[v2] = k2;
      expect(map.containsKey(k1), true);
      expect(map.containsKey(k2), true);
      expect(map.keys, unorderedEquals([k1, k2]));
      expect(map.inverse.containsKey(v1), true);
      expect(map.inverse.containsKey(v2), true);
      expect(map.inverse.keys, unorderedEquals([v1, v2]));
    });

    test('should contain mapped values', () {
      map[k1] = v1;
      map[k2] = v2;
      expect(map.containsValue(v1), true);
      expect(map.containsValue(v2), true);
      expect(map.values, unorderedEquals([v1, v2]));
      expect(map.inverse.containsValue(k1), true);
      expect(map.inverse.containsValue(k2), true);
      expect(map.inverse.values, unorderedEquals([k1, k2]));
    });

    test('should contain values mapped via its inverse', () {
      map.inverse[v1] = k1;
      map.inverse[v2] = k2;
      expect(map.containsValue(v1), true);
      expect(map.containsValue(v2), true);
      expect(map.values, unorderedEquals([v1, v2]));
      expect(map.inverse.containsValue(k1), true);
      expect(map.inverse.containsValue(k2), true);
      expect(map.inverse.values, unorderedEquals([k1, k2]));
    });

    test('should add entries', () {
      map.addEntries(const [MapEntry<String, int>(k1, v1)]);
      expect(map[k1], equals(v1));
      expect(map.inverse[v1], equals(k1));

      map.inverse.addEntries(const [MapEntry<int, String>(v2, k2)]);
      expect(map[k2], equals(v2));
      expect(map.inverse[v2], equals(k2));
    });

    test('should get entries', () {
      map[k1] = v1;
      map.inverse[v2] = k2;

      var mapEntries = map.entries;
      expect(mapEntries, hasLength(2));
      // MapEntry objects are not equal to each other; cannot use `contains`. :(
      expect(mapEntries.singleWhere((e) => e.key == k1).value, equals(v1));
      expect(mapEntries.singleWhere((e) => e.key == k2).value, equals(v2));

      var inverseEntries = map.inverse.entries;
      expect(inverseEntries, hasLength(2));
      expect(inverseEntries.singleWhere((e) => e.key == v1).value, equals(k1));
      expect(inverseEntries.singleWhere((e) => e.key == v2).value, equals(k2));
    });

    test('should map mappings', () {
      map[k1] = v1;
      map[k2] = v2;

      var mapped = map.map((k, v) => MapEntry(k.toUpperCase(), '$k / $v'));
      expect(mapped, contains('K1'));
      expect(mapped, contains('K2'));
      expect(mapped['K1'], equals('k1 / 1'));
      expect(mapped['K2'], equals('k2 / 2'));

      var mapped2 = map.inverse.map((v, k) => MapEntry('$v$v', k.length));
      expect(mapped2, contains('11'));
      expect(mapped2, contains('22'));
      expect(mapped2['11'], equals(2));
      expect(mapped2['22'], equals(2));
    });

    test('should add mappings via putIfAbsent if absent', () {
      map.putIfAbsent(k1, () => v1);
      expect(map[k1], v1);
      expect(map.inverse[v1], k1);
    });

    test('should add mappings via inverse.putIfAbsent if absent', () {
      map.inverse.putIfAbsent(v1, () => k1);
      expect(map[k1], v1);
      expect(map.inverse[v1], k1);
    });

    test('should not add mappings via putIfAbsent if present', () {
      map[k1] = v1;
      map.putIfAbsent(k1, () => v2);
      expect(map[k1], v1);
      expect(map.inverse[v1], k1);
      expect(map.inverse.containsKey(v2), false);
    });

    test('should not add mappings via inverse.putIfAbsent if present', () {
      map[k1] = v1;
      map.inverse.putIfAbsent(v1, () => k2);
      expect(map[k1], v1);
      expect(map.containsKey(k2), false);
      expect(map.inverse[v1], k1);
    });

    test('should contain mappings added from another map', () {
      map.addAll({k1: v1, k2: v2, k3: v3});
      expect(map[k1], v1);
      expect(map[k2], v2);
      expect(map[k3], v3);
      expect(map.inverse[v1], k1);
      expect(map.inverse[v2], k2);
      expect(map.inverse[v3], k3);
    });

    test('should contain mappings added via its inverse from another map', () {
      map.inverse.addAll({v1: k1, v2: k2, v3: k3});
      expect(map[k1], v1);
      expect(map[k2], v2);
      expect(map[k3], v3);
      expect(map.inverse[v1], k1);
      expect(map.inverse[v2], k2);
      expect(map.inverse[v3], k3);
    });

    test('should throw on adding from another map with duplicate values', () {
      expect(() => map.addAll({k1: v1, k2: v2, k3: v2}),
          throwsA(isA<ArgumentError>()));
    });

    test(
        'should throw on adding from another map with duplicate values via inverse',
        () {
      expect(() => map.inverse.addAll({v1: k1, v2: k2, v3: k2}),
          throwsA(isA<ArgumentError>()));
    });

    test('should return the number of key-value pairs as its length', () {
      expect(map.length, 0);
      map[k1] = v1;
      expect(map.length, 1);
      map[k1] = v2;
      expect(map.length, 1);
      map.replace(k2, v2);
      expect(map.length, 1);
      map[k1] = v1;
      expect(map.length, 2);
    });

    test('should iterate over all pairs via forEach', () {
      map[k1] = v1;
      map[k2] = v2;
      var keys = [];
      var values = [];
      map.forEach((k, v) {
        keys.add(k);
        values.add(v);
      });
      expect(keys, unorderedEquals([k1, k2]));
      expect(values, unorderedEquals([v1, v2]));
    });

    test('should iterate over all pairs via forEach of its inverse', () {
      map[k1] = v1;
      map[k2] = v2;
      var keys = [];
      var values = [];
      map.inverse.forEach((k, v) {
        keys.add(k);
        values.add(v);
      });
      expect(keys, unorderedEquals([v1, v2]));
      expect(values, unorderedEquals([k1, k2]));
    });
  });
}
