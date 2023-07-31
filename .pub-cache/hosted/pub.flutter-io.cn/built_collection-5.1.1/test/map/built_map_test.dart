// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:collection' show SplayTreeMap;
import 'package:built_collection/src/map.dart';
import 'package:built_collection/src/internal/test_helpers.dart';
import 'package:test/test.dart';

import '../performance.dart';

void main() {
  group('BuiltMap', () {
    test('instantiates empty by default', () {
      var map = BuiltMap<int, String>();
      expect(map.isEmpty, isTrue);
      expect(map.isNotEmpty, isFalse);
    });

    test('allows <dynamic, dynamic>', () {
      BuiltMap<dynamic, dynamic>();
    });

    test('can be instantiated from Map', () {
      BuiltMap<int, String>({});
    });

    test('from constructor takes Map', () {
      BuiltMap<int, String>.from({});
    });

    test('of constructor takes inferred type', () {
      expect(BuiltMap.of({1: '1'}), const TypeMatcher<BuiltMap<int, String>>());
    });

    test('reports non-emptiness', () {
      var map = BuiltMap<int, String>({1: '1'});
      expect(map.isEmpty, isFalse);
      expect(map.isNotEmpty, isTrue);
    });

    test('can be instantiated from Map then converted back to equal Map', () {
      var mutableMap = {1: '1'};
      var map = BuiltMap<int, String>(mutableMap);
      expect(map.toMap(), mutableMap);
    });

    test('throws on wrong type key', () {
      expect(() => BuiltMap<int, String>({'1': '1'}), throwsA(anything));
    });

    test('throws on wrong type value', () {
      expect(() => BuiltMap<int, String>({1: 1}), throwsA(anything));
    });

    test('does not keep a mutable Map', () {
      var mutableMap = {1: '1'};
      var map = BuiltMap<int, String>(mutableMap);
      mutableMap.clear();
      expect(map.toMap(), {1: '1'});
    });

    test('copies from BuiltMap instances of different type', () {
      var map1 = BuiltMap<Object, Object>();
      var map2 = BuiltMap<int, String>(map1);
      expect(map1, isNot(same(map2)));
    });

    test('can be converted to Map<K, V>', () {
      expect(
        BuiltMap<int, String>().toMap(),
        const TypeMatcher<Map<int, String>>(),
      );
      expect(
        BuiltMap<int, String>().toMap(),
        isNot(const TypeMatcher<Map<int, int>>()),
      );
      expect(
        BuiltMap<int, String>().toMap(),
        isNot(const TypeMatcher<Map<String, String>>()),
      );
    });

    test('uses same base when converted with toMap', () {
      var built = BuiltMap<int, String>.build((b) => b
        ..withBase(() => SplayTreeMap<int, String>())
        ..addAll({1: '1', 3: '3'}));
      var map = built.toMap()..addAll({2: '2', 4: '4'});
      expect(map.keys, [1, 2, 3, 4]);
    });

    test('can be converted to an UnmodifiableMapView', () {
      var immutableMap = BuiltMap<int, String>().asMap();
      expect(immutableMap, const TypeMatcher<Map<int, String>>());
      expect(() => immutableMap[1] = 'Hello', throwsUnsupportedError);
      expect(immutableMap, isEmpty);
    });

    test('can be converted to MapBuilder<K, V>', () {
      expect(
        BuiltMap<int, String>().toBuilder(),
        const TypeMatcher<MapBuilder<int, String>>(),
      );
      expect(
        BuiltMap<int, String>().toBuilder(),
        isNot(const TypeMatcher<MapBuilder<int, int>>()),
      );
      expect(
        BuiltMap<int, String>().toBuilder(),
        isNot(const TypeMatcher<MapBuilder<String, String>>()),
      );
    });

    test('can be converted to MapBuilder<K, V> and back to Map<K, V>', () {
      expect(
        BuiltMap<int, String>().toBuilder().build(),
        const TypeMatcher<BuiltMap<int, String>>(),
      );
      expect(
        BuiltMap<int, String>().toBuilder().build(),
        isNot(const TypeMatcher<BuiltMap<int, int>>()),
      );
      expect(
        BuiltMap<int, String>().toBuilder().build(),
        isNot(const TypeMatcher<BuiltMap<String, String>>()),
      );
    });

    test('passes along its base when converted to SetBuilder', () {
      var map = BuiltMap<int, String>.build((b) => b
        ..withBase(() => SplayTreeMap<int, String>())
        ..addAll({10: '10', 15: '15', 5: '5'}));
      var builder = map.toBuilder()..addAll({2: '2', 12: '12'});
      expect(builder.build().keys, orderedEquals([2, 5, 10, 12, 15]));
    });

    test('throws on null keys', () {
      expect(() => BuiltMap<int, String>({null: '1'}), throwsA(anything));
    });

    test('nullable does not throw on null keys', () {
      expect(BuiltMap<int?, String>({null: '1'})[null], '1');
    });

    test('throws on null values', () {
      expect(() => BuiltMap<int, String>({1: null}), throwsA(anything));
    });

    test('nullable does not throw on null values', () {
      expect(BuiltMap<int, String?>({1: null})[1], null);
    });

    test('of constructor throws on null keys', () {
      expect(() => BuiltMap<int, String>.of({null as dynamic: '1'}),
          throwsA(anything));
    });

    test('nullable of constructor does not throw on null keys', () {
      expect(BuiltMap<int?, String>.of({null as dynamic: '1'})[null], '1');
    });

    test('of constructor throws on null values', () {
      expect(() => BuiltMap<int, String>.of({1: null as dynamic}),
          throwsA(anything));
    });

    test('nullable of constructor does not throw on null values', () {
      expect(BuiltMap<int, String?>.of({1: null as dynamic})[1], null);
    });

    test('hashes to same value for same contents', () {
      var map1 = BuiltMap<int, String>({1: '1', 2: '2', 3: '3'});
      var map2 = BuiltMap<int, String>({1: '1', 2: '2', 3: '3'});

      expect(map1.hashCode, map2.hashCode);
    });

    test('hashes to different value for different keys', () {
      var map1 = BuiltMap<int, String>({1: '1', 2: '2', 3: '3'});
      var map2 = BuiltMap<int, String>({1: '1', 2: '2', 4: '3'});

      expect(map1.hashCode, isNot(map2.hashCode));
    });

    test('hashes to different value for different values', () {
      var map1 = BuiltMap<int, String>({1: '1', 2: '2', 3: '3'});
      var map2 = BuiltMap<int, String>({1: '1', 2: '2', 3: '4'});

      expect(map1.hashCode, isNot(map2.hashCode));
    });

    test('caches hash', () {
      var hashCodeSpy = HashCodeSpy();
      var map = BuiltMap<Object, Object>({1: hashCodeSpy});

      hashCodeSpy.hashCodeSeen = 0;
      map.hashCode;
      map.hashCode;
      expect(hashCodeSpy.hashCodeSeen, 1);
    });

    test('compares equal to same instance', () {
      var map = BuiltMap<int, String>({1: '1', 2: '2', 3: '3'});
      expect(map == map, isTrue);
    });

    test('compares equal to same contents', () {
      var map1 = BuiltMap<int, String>({1: '1', 2: '2', 3: '3'});
      var map2 = BuiltMap<int, String>({1: '1', 2: '2', 3: '3'});
      expect(map1 == map2, isTrue);
    });

    test('compares not equal to different type', () {
      expect(
          // ignore: unrelated_type_equality_checks
          BuiltMap<int, String>({1: '1', 2: '2', 3: '3'}) == '',
          isFalse);
    });

    test('compares not equal to different length BuiltMap', () {
      expect(
          BuiltMap<int, String>({1: '1', 2: '2', 3: '3'}) ==
              BuiltMap<int, String>({1: '1', 2: '2'}),
          isFalse);
    });

    test('compares not equal to different hashcode BuiltMap', () {
      expect(
          BuiltCollectionTestHelpers.overridenHashcodeBuiltMap(
                  {1: '1', 2: '2', 3: '3'}, 0) ==
              BuiltCollectionTestHelpers.overridenHashcodeBuiltMap(
                  {1: '1', 2: '2', 3: '3'}, 1),
          isFalse);
    });

    test('compares not equal to different content BuiltMap', () {
      expect(
          BuiltCollectionTestHelpers.overridenHashcodeBuiltMap(
                  {1: '1', 2: '2', 3: '3'}, 0) ==
              BuiltCollectionTestHelpers.overridenHashcodeBuiltMap(
                  {1: '1', 2: '2', 4: '4'}, 0),
          isFalse);
    });

    test('compares without throwing for same hashcode different key type', () {
      expect(
          // ignore: unrelated_type_equality_checks
          BuiltCollectionTestHelpers.overridenHashcodeBuiltMap({1: '1'}, 0) ==
              BuiltCollectionTestHelpers
                  .overridenHashcodeBuiltMapWithStringKeys({'1': '1'}, 0),
          false);
    });

    test('provides toString() for debugging', () {
      expect(BuiltMap<int, String>({1: '1', 2: '2', 3: '3'}).toString(),
          '{1: 1, 2: 2, 3: 3}');
    });

    test('preserves key order', () {
      expect(BuiltMap<int, String>({1: '1', 2: '2', 3: '3'}).keys, [1, 2, 3]);
      expect(BuiltMap<int, String>({3: '3', 2: '2', 1: '1'}).keys, [3, 2, 1]);
    });

    // Lazy copies.

    test('reuses BuiltMap instances of the same type', () {
      var map1 = BuiltMap<int, String>();
      var map2 = BuiltMap<int, String>(map1);
      expect(map1, same(map2));
    });

    test('does not reuse BuiltMap instances with subtype key type', () {
      var map1 = BuiltMap<_ExtendsA, String>();
      var map2 = BuiltMap<_A, String>(map1);
      expect(map1, isNot(same(map2)));
    });

    test('does not reuse BuiltMap instances with subtype value type', () {
      var map1 = BuiltMap<String, _ExtendsA>();
      var map2 = BuiltMap<String, _A>(map1);
      expect(map1, isNot(same(map2)));
    });

    test('can be reused via MapBuilder if there are no changes', () {
      var map1 = BuiltMap<Object, Object>();
      var map2 = map1.toBuilder().build();
      expect(map1, same(map2));
    });

    test('converts to MapBuilder from correct type without copying', () {
      var makeLongMap = () => BuiltMap<int, int>(
          Map<int, int>.fromIterable(List<int>.generate(100000, (x) => x)));
      var longMap = makeLongMap();
      var longMapToMapBuilder = longMap.toBuilder;

      expectMuchFaster(longMapToMapBuilder, makeLongMap);
    });

    test('converts to MapBuilder from wrong type by copying', () {
      var makeLongMap = () => BuiltMap<Object, Object>(
          Map<int, int>.fromIterable(List<int>.generate(100000, (x) => x)));
      var longMap = makeLongMap();
      var longMapToMapBuilder = () => MapBuilder<int, int>(longMap);

      expectNotMuchFaster(longMapToMapBuilder, makeLongMap);
    });

    test('has fast toMap', () {
      var makeLongMap = () => BuiltMap<Object, Object>(
          Map<int, int>.fromIterable(List<int>.generate(100000, (x) => x)));
      var longMap = makeLongMap();
      var longMapToMap = () => longMap.toMap();

      expectMuchFaster(longMapToMap, makeLongMap);
    });

    test('checks for reference identity', () {
      var makeLongMap = () => BuiltMap<Object, Object>(
          Map<int, int>.fromIterable(List<int>.generate(100000, (x) => x)));
      var longMap = makeLongMap();
      var otherLongMap = makeLongMap();

      expectMuchFaster(() => longMap == longMap, () => longMap == otherLongMap);
    });

    test('is not mutated when Map from toMap is mutated', () {
      var map = BuiltMap<int, String>();
      map.toMap()[1] = '1';
      expect(map.isEmpty, isTrue);
    });

    test('has build constructor', () {
      expect(BuiltMap<int, String>.build((b) => b[0] = '0').toMap(), {0: '0'});
    });

    test('has rebuild method', () {
      expect(BuiltMap<int, String>({0: '0'}).rebuild((b) => b[1] = '1').toMap(),
          {0: '0', 1: '1'});
    });

    test('returns identical BuiltMap on repeated build', () {
      var mapBuilder = MapBuilder<int, String>({1: '1', 2: '2', 3: '3'});
      expect(mapBuilder.build(), same(mapBuilder.build()));
    });

    // Map.

    test('does not implement Map', () {
      expect(BuiltMap<int, String>() is Map, isFalse);
    });

    test('has a method like Map[]', () {
      expect(BuiltMap<int, String>({1: '1', 2: '2', 3: '3'})[2], '2');
    });

    test('has a method like Map.length', () {
      expect(BuiltMap<int, String>({1: '1', 2: '2', 3: '3'}).length, 3);
    });

    test('has a method like Map.containsKey', () {
      expect(BuiltMap<int, String>({1: '1', 2: '2', 3: '3'}).containsKey(3),
          isTrue);
      expect(BuiltMap<int, String>({1: '1', 2: '2', 3: '3'}).containsKey(4),
          isFalse);
    });

    test('has a method like Map.containsValue', () {
      expect(BuiltMap<int, String>({1: '1', 2: '2', 3: '3'}).containsValue('3'),
          isTrue);
      expect(BuiltMap<int, String>({1: '1', 2: '2', 3: '3'}).containsValue('4'),
          isFalse);
    });

    test('has a method like Map.forEach', () {
      var totalKeys = 0;
      var concatenatedValues = '';
      BuiltMap<int, String>({1: '1', 2: '2', 3: '3'}).forEach((key, value) {
        totalKeys += key;
        concatenatedValues += value;
      });

      expect(totalKeys, 6);
      expect(concatenatedValues, '123');
    });

    test('has a method like Map.keys', () {
      expect(BuiltMap<int, String>({1: '1', 2: '2', 3: '3'}).keys, [1, 2, 3]);
    });

    test('has a method like Map.values', () {
      expect(BuiltMap<int, String>({1: '1', 2: '2', 3: '3'}).values,
          ['1', '2', '3']);
    });

    test('has a method like Map.entries', () {
      var map = BuiltMap<int, String>({1: '1', 2: '2', 3: '3'});
      expect(BuiltMap<int, String>(Map.fromEntries(map.entries)), map);
    });

    test('has a method like Map.map', () {
      expect(
          BuiltMap<int, String>({1: '1', 2: '2', 3: '3'})
              .map((key, value) => MapEntry(value, key))
              .asMap(),
          {'1': 1, '2': 2, '3': 3});
    });

    test('has stable keys', () {
      var map = BuiltMap<int, String>({1: '1', 2: '2', 3: '3'});
      expect(map.keys, same(map.keys));
    });

    test('has stable values', () {
      var map = BuiltMap<int, String>({1: '1', 2: '2', 3: '3'});
      expect(map.values, same(map.values));
    });

    test('can be created from`Map` using extension methods', () {
      expect(
        {1: '1', 2: '2', 3: '3'}.build(),
        const TypeMatcher<BuiltMap<int, String>>(),
      );
      expect(
          {1: '1', 2: '2', 3: '3'}.build().toMap(), {1: '1', 2: '2', 3: '3'});
    });
  });
}

class _A {}

class _ExtendsA extends _A {}
