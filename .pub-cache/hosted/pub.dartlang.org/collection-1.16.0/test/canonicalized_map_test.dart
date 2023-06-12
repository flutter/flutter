// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:test/test.dart';

void main() {
  group('with an empty canonicalized map', () {
    late CanonicalizedMap<int, String, String> map;

    setUp(() {
      map = CanonicalizedMap(int.parse, isValidKey: RegExp(r'^\d+$').hasMatch);
    });

    test('canonicalizes keys on set and get', () {
      map['1'] = 'value';
      expect(map['01'], equals('value'));
    });

    test('get returns null for uncanonicalizable key', () {
      expect(map['foo'], isNull);
    });

    test('set affects nothing for uncanonicalizable key', () {
      map['foo'] = 'value';
      expect(map['foo'], isNull);
      expect(map.containsKey('foo'), isFalse);
      expect(map.length, equals(0));
    });

    test('canonicalizes keys for addAll', () {
      map.addAll({'1': 'value 1', '2': 'value 2', '3': 'value 3'});
      expect(map['01'], equals('value 1'));
      expect(map['02'], equals('value 2'));
      expect(map['03'], equals('value 3'));
    });

    test('uses the final value for addAll collisions', () {
      map.addAll({'1': 'value 1', '01': 'value 2', '001': 'value 3'});
      expect(map.length, equals(1));
      expect(map['0001'], equals('value 3'));
    });

    test('clear clears the map', () {
      map.addAll({'1': 'value 1', '2': 'value 2', '3': 'value 3'});
      expect(map, isNot(isEmpty));
      map.clear();
      expect(map, isEmpty);
    });

    test('canonicalizes keys for containsKey', () {
      map['1'] = 'value';
      expect(map.containsKey('01'), isTrue);
      expect(map.containsKey('2'), isFalse);
    });

    test('containsKey returns false for uncanonicalizable key', () {
      expect(map.containsKey('foo'), isFalse);
    });

    test('canonicalizes keys for putIfAbsent', () {
      map['1'] = 'value';
      expect(map.putIfAbsent('01', () => throw Exception("shouldn't run")),
          equals('value'));
      expect(map.putIfAbsent('2', () => 'new value'), equals('new value'));
    });

    test('canonicalizes keys for remove', () {
      map['1'] = 'value';
      expect(map.remove('2'), isNull);
      expect(map.remove('01'), equals('value'));
      expect(map, isEmpty);
    });

    test('remove returns null for uncanonicalizable key', () {
      expect(map.remove('foo'), isNull);
    });

    test('containsValue returns whether a value is in the map', () {
      map['1'] = 'value';
      expect(map.containsValue('value'), isTrue);
      expect(map.containsValue('not value'), isFalse);
    });

    test('isEmpty returns whether the map is empty', () {
      expect(map.isEmpty, isTrue);
      map['1'] = 'value';
      expect(map.isEmpty, isFalse);
      map.remove('01');
      expect(map.isEmpty, isTrue);
    });

    test("isNotEmpty returns whether the map isn't empty", () {
      expect(map.isNotEmpty, isFalse);
      map['1'] = 'value';
      expect(map.isNotEmpty, isTrue);
      map.remove('01');
      expect(map.isNotEmpty, isFalse);
    });

    test('length returns the number of pairs in the map', () {
      expect(map.length, equals(0));
      map['1'] = 'value 1';
      expect(map.length, equals(1));
      map['01'] = 'value 01';
      expect(map.length, equals(1));
      map['02'] = 'value 02';
      expect(map.length, equals(2));
    });

    test('uses original keys for keys', () {
      map['001'] = 'value 1';
      map['02'] = 'value 2';
      expect(map.keys, equals(['001', '02']));
    });

    test('uses original keys for forEach', () {
      map['001'] = 'value 1';
      map['02'] = 'value 2';

      var keys = [];
      map.forEach((key, value) => keys.add(key));
      expect(keys, equals(['001', '02']));
    });

    test('values returns all values in the map', () {
      map.addAll(
          {'1': 'value 1', '01': 'value 01', '2': 'value 2', '03': 'value 03'});

      expect(map.values, equals(['value 01', 'value 2', 'value 03']));
    });

    test('entries returns all key-value pairs in the map', () {
      map.addAll({
        '1': 'value 1',
        '01': 'value 01',
        '2': 'value 2',
      });

      var entries = map.entries.toList();
      expect(entries[0].key, '01');
      expect(entries[0].value, 'value 01');
      expect(entries[1].key, '2');
      expect(entries[1].value, 'value 2');
    });

    test('addEntries adds key-value pairs to the map', () {
      map.addEntries([
        MapEntry('1', 'value 1'),
        MapEntry('01', 'value 01'),
        MapEntry('2', 'value 2'),
      ]);
      expect(map, {'01': 'value 01', '2': 'value 2'});
    });

    test('cast returns a new map instance', () {
      expect(map.cast<Pattern, Pattern>(), isNot(same(map)));
    });
  });

  group('CanonicalizedMap builds an informative string representation', () {
    dynamic map;
    setUp(() {
      map = CanonicalizedMap<int, String, dynamic>(int.parse,
          isValidKey: RegExp(r'^\d+$').hasMatch);
    });

    test('for an empty map', () {
      expect(map.toString(), equals('{}'));
    });

    test('for a map with one value', () {
      map.addAll({'1': 'value 1'});
      expect(map.toString(), equals('{1: value 1}'));
    });

    test('for a map with multiple values', () {
      map.addAll(
          {'1': 'value 1', '01': 'value 01', '2': 'value 2', '03': 'value 03'});
      expect(
          map.toString(), equals('{01: value 01, 2: value 2, 03: value 03}'));
    });

    test('for a map with a loop', () {
      map.addAll({'1': 'value 1', '2': map});
      expect(map.toString(), equals('{1: value 1, 2: {...}}'));
    });
  });

  group('CanonicalizedMap.from', () {
    test('canonicalizes its keys', () {
      var map = CanonicalizedMap.from(
          {'1': 'value 1', '2': 'value 2', '3': 'value 3'}, int.parse);
      expect(map['01'], equals('value 1'));
      expect(map['02'], equals('value 2'));
      expect(map['03'], equals('value 3'));
    });

    test('uses the final value for collisions', () {
      var map = CanonicalizedMap.from(
          {'1': 'value 1', '01': 'value 2', '001': 'value 3'}, int.parse);
      expect(map.length, equals(1));
      expect(map['0001'], equals('value 3'));
    });
  });
}
