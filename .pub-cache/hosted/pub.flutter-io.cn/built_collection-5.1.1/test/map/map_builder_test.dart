// Copyright (c) 2015, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:collection' show SplayTreeMap;
import 'package:built_collection/src/map.dart';
import 'package:test/test.dart';

import '../performance.dart';

void main() {
  group('MapBuilder', () {
    test('allows <dynamic, dynamic>', () {
      MapBuilder<dynamic, dynamic>();
    });

    test('allows MapBuilder<Object, Object>', () {
      MapBuilder<Object, Object>();
    });

    test('throws on null key put', () {
      expect(() => MapBuilder<int, String>()[null as dynamic] = '0',
          throwsA(anything));
    });

    test('nullable does not throw on null key put', () {
      var builder = MapBuilder<int?, String>();
      builder[null] = '0';
      expect(builder[null], '0');
    });

    test('throws on null value put', () {
      expect(() => MapBuilder<int, String>()[0] = null as dynamic,
          throwsA(anything));
    });

    test('nullable does not throw on null value put', () {
      var builder = MapBuilder<int, String?>();
      builder[0] = null;
      expect(builder[0], null);
    });

    test('throws on null key putIfAbsent', () {
      expect(
          () =>
              MapBuilder<int, String>().putIfAbsent(null as dynamic, () => '0'),
          throwsA(anything));
    });

    test('nullable does not throw on null key putIfAbsent', () {
      var builder = MapBuilder<int?, String>();
      builder.putIfAbsent(null, () => '0');
      expect(builder[null], '0');
    });

    test('throws on null value putIfAbsent', () {
      expect(
          () => MapBuilder<int, String>().putIfAbsent(0, () => null as dynamic),
          throwsA(anything));
    });

    test('nullable does not throw on null value putIfAbsent', () {
      var builder = MapBuilder<int, String?>();
      builder.putIfAbsent(0, () => null);
      expect(builder[0], null);
    });

    test('throws on null key addAll', () {
      expect(() => MapBuilder<int, String>().addAll({null as dynamic: '0'}),
          throwsA(anything));
    });

    test('nullable does not throw on null key addAll', () {
      var builder = MapBuilder<int?, String>();
      builder.addAll({null: '0'});
      expect(builder[null], '0');
    });

    test('throws on null value addAll', () {
      expect(() => MapBuilder<int, String>().addAll({0: null as dynamic}),
          throwsA(anything));
    });

    test('nullable does not throw on null value addAll', () {
      var builder = MapBuilder<int, String?>();
      builder.addAll({0: null});
      expect(builder[0], null);
    });

    test('throws on null withBase', () {
      var builder = MapBuilder<int, String>({2: '2', 0: '0', 1: '1'});
      expect(() => builder.withBase(null as dynamic), throwsA(anything));
      expect(builder.build().keys, orderedEquals([2, 0, 1]));
    });

    test('has replace method that replaces all data', () {
      expect(
          (MapBuilder<int, String>()..replace({1: '1', 2: '2'}))
              .build()
              .toMap(),
          {1: '1', 2: '2'});
    });

    test('has replace method that casts the supplied map', () {
      expect(
          (MapBuilder<int, String>()..replace(<num, Object>{1: '1', 2: '2'}))
              .build()
              .toMap(),
          {1: '1', 2: '2'});
    });

    test('has addIterable method like Map.fromIterable', () {
      expect((MapBuilder<int, int>()..addIterable([1, 2, 3])).build().toMap(),
          {1: 1, 2: 2, 3: 3});
      expect(
          (MapBuilder<int, int>()
                ..addIterable([1, 2, 3], key: (int element) => element + 1))
              .build()
              .toMap(),
          {2: 1, 3: 2, 4: 3});
      expect(
          (MapBuilder<int, int>()
                ..addIterable([1, 2, 3], value: (int element) => element + 1))
              .build()
              .toMap(),
          {1: 2, 2: 3, 3: 4});
    });

    test('has addEntries method like Map.addEntries', () {
      expect(
          (MapBuilder<int, int>()
                ..addEntries([
                  MapEntry(1, 1),
                  MapEntry(2, 2),
                  MapEntry(3, 3),
                ]))
              .build()
              .toMap(),
          {1: 1, 2: 2, 3: 3});
    });

    test('reuses BuiltMap passed to replace if it has the same base', () {
      var treeMapBase = () => SplayTreeMap<int, String>();
      var map = BuiltMap<int, String>.build((b) => b
        ..withBase(treeMapBase)
        ..addAll({1: '1', 2: '2'}));
      var builder = MapBuilder<int, String>()
        ..withBase(treeMapBase)
        ..replace(map);
      expect(builder.build(), same(map));
    });

    test("doesn't reuse BuiltMap passed to replace if it has a different base",
        () {
      var map = BuiltMap<int, String>.build((b) => b
        ..withBase(() => SplayTreeMap<int, String>())
        ..addAll({1: '1', 2: '2'}));
      var builder = MapBuilder<int, String>()..replace(map);
      expect(builder.build(), isNot(same(map)));
    });

    test('has withBase method that changes the underlying map type', () {
      var builder = MapBuilder<int, String>({2: '2', 0: '0', 1: '1'});
      builder.withBase(() => SplayTreeMap<int, String>());
      expect(builder.build().keys, orderedEquals([0, 1, 2]));
    });

    test('has withDefaultBase method that resets the underlying map type', () {
      var builder = MapBuilder<int, String>()
        ..withBase(() => SplayTreeMap<int, String>())
        ..withDefaultBase()
        ..addAll({2: '2', 0: '0', 1: '1'});
      expect(builder.build().keys, orderedEquals([2, 0, 1]));
    });

    // Lazy copies.

    test('does not mutate BuiltMap following reuse of underlying Map', () {
      var map = BuiltMap<int, String>({1: '1', 2: '2'});
      var mapBuilder = map.toBuilder();
      mapBuilder[3] = '3';
      expect(map.toMap(), {1: '1', 2: '2'});
    });

    test('converts to BuiltMap without copying', () {
      var makeLongMapBuilder = () => MapBuilder<int, int>(
          Map<int, int>.fromIterable(List<int>.generate(100000, (x) => x)));
      var longMapBuilder = makeLongMapBuilder();
      var buildLongMapBuilder = () => longMapBuilder.build();

      expectMuchFaster(buildLongMapBuilder, makeLongMapBuilder);
    });

    test('does not mutate BuiltMap following mutates after build', () {
      var mapBuilder = MapBuilder<int, String>({1: '1', 2: '2'});

      var map1 = mapBuilder.build();
      expect(map1.toMap(), {1: '1', 2: '2'});

      mapBuilder[3] = '3';
      expect(map1.toMap(), {1: '1', 2: '2'});
    });

    // Map.

    test('has a method like Map[]', () {
      var mapBuilder = MapBuilder<int, String>({1: '1', 2: '2'});
      mapBuilder[1] = mapBuilder[1]! + '*';
      mapBuilder[2] = mapBuilder[2]! + '**';
      expect(mapBuilder.build().asMap(), {1: '1*', 2: '2**'});
    });

    test('has a method like Map[]=', () {
      expect((MapBuilder<int, String>({1: '1'})..[2] = '2').build().toMap(),
          {1: '1', 2: '2'});
      expect(
          (BuiltMap<int, String>({1: '1'}).toBuilder()..[2] = '2')
              .build()
              .toMap(),
          {1: '1', 2: '2'});
    });

    test('has a method like Map.length', () {
      expect(MapBuilder<int, String>({1: '1', 2: '2'}).length, 2);
      expect(BuiltMap<int, String>({1: '1', 2: '2'}).toBuilder().length, 2);

      expect(MapBuilder<int, String>({}).length, 0);
      expect(BuiltMap<int, String>({}).toBuilder().length, 0);
    });

    test('has a method like Map.isEmpty', () {
      expect(MapBuilder<int, String>({1: '1', 2: '2'}).isEmpty, false);
      expect(
          BuiltMap<int, String>({1: '1', 2: '2'}).toBuilder().isEmpty, false);

      expect(MapBuilder<int, String>().isEmpty, true);
      expect(BuiltMap<int, String>().toBuilder().isEmpty, true);
    });

    test('has a method like Map.isNotEmpty', () {
      expect(MapBuilder<int, String>({1: '1', 2: '2'}).isNotEmpty, true);
      expect(
          BuiltMap<int, String>({1: '1', 2: '2'}).toBuilder().isNotEmpty, true);

      expect(MapBuilder<int, String>().isNotEmpty, false);
      expect(BuiltMap<int, String>().toBuilder().isNotEmpty, false);
    });

    test('has a method like Map.putIfAbsent', () {
      expect(MapBuilder<int, String>({1: '1'}).putIfAbsent(2, () => '2'), '2');
      expect(
          (MapBuilder<int, String>({1: '1'})
                ..putIfAbsent(2, () => '2')
                ..putIfAbsent(1, () => '3'))
              .build()
              .toMap(),
          {1: '1', 2: '2'});
      expect(
          (BuiltMap<int, String>({1: '1'}).toBuilder()
                ..putIfAbsent(2, () => '2')
                ..putIfAbsent(1, () => '3'))
              .build()
              .toMap(),
          {1: '1', 2: '2'});
    });

    test('has a method like Map.addAll', () {
      expect(
          (MapBuilder<int, String>()..addAll({1: '1', 2: '2'})).build().toMap(),
          {1: '1', 2: '2'});
      expect(
          (BuiltMap<int, String>().toBuilder()..addAll({1: '1', 2: '2'}))
              .build()
              .toMap(),
          {1: '1', 2: '2'});
    });

    test('has a method like Map.remove', () {
      expect(MapBuilder<int, String>({1: '1', 2: '2'}).remove(2), '2');
      expect(MapBuilder<int, String>({1: '1', 2: '2'}).remove(3), null);
      expect(
          (MapBuilder<int, String>({1: '1', 2: '2'})..remove(2))
              .build()
              .toMap(),
          {1: '1'});
      expect(
          (BuiltMap<int, String>({1: '1', 2: '2'}).toBuilder()..remove(2))
              .build()
              .toMap(),
          {1: '1'});
    });

    test('has a method like Map.removeWhere', () {
      expect(
          (MapBuilder<int, String>({1: '1', 2: '2'})
                ..removeWhere((k, v) => k == 2))
              .build()
              .toMap(),
          {1: '1'});
      expect(
          (MapBuilder<int, String>({1: '1', 2: '2'})
                ..removeWhere((k, v) => v == '2'))
              .build()
              .toMap(),
          {1: '1'});
    });

    test('has a method like Map.clear', () {
      expect(
          (MapBuilder<int, String>({1: '1', 2: '2'})..clear()).build().toMap(),
          {});
      expect(
          (BuiltMap<int, String>({1: '1', 2: '2'}).toBuilder()..clear())
              .build()
              .toMap(),
          {});
    });

    test('has a method like Map.update called updateValue', () {
      expect(
          (MapBuilder<int, String>({1: '1', 2: '2'})
                ..updateValue(1, (v) => v + '1', ifAbsent: () => '7'))
              .build()
              .toMap(),
          {1: '11', 2: '2'});
      expect(
          (MapBuilder<int, String>({1: '1', 2: '2'})
                ..updateValue(7, (v) => v + '1', ifAbsent: () => '7'))
              .build()
              .toMap(),
          {1: '1', 2: '2', 7: '7'});
    });

    test('has a method like Map.updateAll called updateAllValues', () {
      expect(
          (MapBuilder<int, String>({1: '1', 2: '2'})
                ..updateAllValues((k, v) => v + k.toString()))
              .build()
              .toMap(),
          {1: '11', 2: '22'});
    });
  });
}
