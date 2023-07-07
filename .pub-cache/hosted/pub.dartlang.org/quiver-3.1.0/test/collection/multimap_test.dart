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

library quiver.collection.multimap_test;

import 'package:quiver/src/collection/multimap.dart';
import 'package:test/test.dart';

void main() {
  group('Multimap', () {
    test('should be a list-backed multimap', () {
      var map = Multimap();
      expect(map is ListMultimap, true);
    });
  });

  group('Multimap.fromIterable', () {
    test('should default to the identity for key and value', () {
      var map = Multimap<int, int>.fromIterable([1, 2, 1]);
      expect(map.asMap(), {
        1: [1, 1],
        2: [2],
      });
    });

    test('should allow setting value', () {
      var i = 0;
      var map = Multimap<int, String>.fromIterable([1, 2, 1],
          value: (x) => '$x:${i++}');
      expect(map.asMap(), {
        1: ['1:0', '1:2'],
        2: ['2:1'],
      });
    });

    test('should allow setting key', () {
      var map =
          Multimap<String, int>.fromIterable([1, 2, 1], key: (x) => '($x)');
      expect(map.asMap(), {
        '(1)': [1, 1],
        '(2)': [2],
      });
    });

    test('should allow setting both key and value', () {
      var i = 0;
      var map = Multimap<int, String>.fromIterable([1, 2, 1],
          key: (x) => -x, value: (x) => '$x:${i++}');
      expect(map.asMap(), {
        -1: ['1:0', '1:2'],
        -2: ['2:1'],
      });
    }, tags: ['fails-on-dartdevc']);
  });

  group('Multimap asMap() view', () {
    late Multimap<String, String> mmap;
    late Map<String, Iterable<String>> map;
    setUp(() {
      mmap = Multimap()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3');
      map = mmap.asMap();
    });

    test('operator[]= should throw UnsupportedError', () {
      expect(() => map['k1'] = ['1', '2', '3'], throwsUnsupportedError);
    });

    test('addEntries should throw UnsupportedError', () {
      expect(() => map.addEntries(<MapEntry<String, List<String>>>[]),
          throwsUnsupportedError);
    });

    test('update should throw UnsupportedError', () {
      expect(() => map.update('k1', (_) => ['1', '2', '3']),
          throwsUnsupportedError);
    });

    test('updateAll should throw UnsupportedError', () {
      expect(() => map.updateAll((_, __) => ['1', '2', '3']),
          throwsUnsupportedError);
    });

    test('containsKey() should return false for missing key', () {
      expect(map.containsKey('k3'), isFalse);
    });

    test('containsKey() should return true for key in map', () {
      expect(map.containsKey('k1'), isTrue);
    });

    test('containsValue() should return false for missing value', () {
      expect(map.containsValue('k3'), isFalse);
    });

    test('containsValue() should return true for value in map', () {
      expect(map.containsValue('v1'), isTrue);
    });

    test('forEach should iterate over all key-value pairs', () {
      var results = [];
      map.forEach((k, v) => results.add(Pair(k, v)));
      expect(
          results,
          unorderedEquals([
            Pair('k1', ['v1', 'v2']),
            Pair('k2', ['v3'])
          ]));
    });

    test('isEmpty should return whether the map contains key-value pairs', () {
      expect(map.isEmpty, isFalse);
      expect(map.isNotEmpty, isTrue);
      expect(Multimap().asMap().isEmpty, isTrue);
      expect(Multimap().asMap().isNotEmpty, isFalse);
    });

    test('length should return the number of key-value pairs', () {
      expect(Multimap().asMap().length, equals(0));
      expect(map.length, equals(2));
    });

    test('addAll(Map m) should throw UnsupportedError', () {
      expect(
          () => map.addAll(<String, List<String>>{
                'k1': ['1', '2', '3']
              }),
          throwsUnsupportedError);
    }, tags: ['fails-on-dartdevc']);

    test('putIfAbsent() should throw UnsupportedError', () {
      var map = Multimap().asMap();
      expect(() => map.putIfAbsent('k1', () => [1]), throwsUnsupportedError);
    });
  });

  group('ListMultimap', () {
    test('should initialize empty', () {
      var map = ListMultimap();
      expect(map.isEmpty, true);
      expect(map.isNotEmpty, false);
    });

    test('should not be empty after adding', () {
      var map = ListMultimap<String, String>()..add('k', 'v');
      expect(map.isEmpty, false);
      expect(map.isNotEmpty, true);
    });

    test('should return the number of keys as length', () {
      var map = ListMultimap<String, String>();
      expect(map.length, 0);
      map
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3');
      expect(map.length, 2);
    });

    test('should return an empty iterable for unmapped keys', () {
      var map = ListMultimap<String, String>();
      expect(map['k1'], []);
    });

    test('should support adding values for unmapped keys', () {
      var map = ListMultimap<String, String>()..['k1'].add('v1');
      expect(map['k1'], ['v1']);
    });

    test('should support adding multiple values for unmapped keys', () {
      var map = ListMultimap<String, String>()..['k1'].addAll(['v1', 'v2']);
      expect(map['k1'], ['v1', 'v2']);
    });

    test('should support inserting values for unmapped keys', () {
      var map = ListMultimap<String, String>()..['k1'].insert(0, 'v1');
      expect(map['k1'], ['v1']);
    });

    test('should support inserting multiple values for unmapped keys', () {
      var map = ListMultimap<String, String>()
        ..['k1'].insertAll(0, ['v1', 'v2']);
      expect(map['k1'], ['v1', 'v2']);
    });

    test('should support growing underlying list for unmapped keys', () {
      var map = ListMultimap<String, String?>()..['k1'].length = 2;
      expect(map['k1'], [null, null]);
    });

    test('should return unmapped iterables that stay in sync on add', () {
      var map = ListMultimap<String, String>();
      List values1 = map['k1'];
      List values2 = map['k1'];
      values1.add('v1');
      expect(map['k1'], ['v1']);
      expect(values2, ['v1']);
    });

    test('should return unmapped iterables that stay in sync on addAll', () {
      var map = ListMultimap<String, String>();
      List values1 = map['k1'];
      List values2 = map['k1'];
      values1.addAll(<String>['v1', 'v2']);
      expect(map['k1'], ['v1', 'v2']);
      expect(values2, ['v1', 'v2']);
    });

    test('should support adding duplicate values for a key', () {
      var map = ListMultimap<String, String>()
        ..add('k', 'v1')
        ..add('k', 'v1');
      expect(map['k'], ['v1', 'v1']);
    });

    test(
        'should support adding duplicate values for a key when initialized '
        'from an iterable', () {
      var map = ListMultimap<String, String>.fromIterable(['k', 'k'],
          value: (x) => 'v1');
      expect(map['k'], ['v1', 'v1']);
    });

    test('should support adding multiple keys', () {
      var map = ListMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3');
      expect(map['k1'], ['v1', 'v2']);
      expect(map['k2'], ['v3']);
    });

    test('should support adding multiple values at once', () {
      var map = ListMultimap<String, String>()..addValues('k1', ['v1', 'v2']);
      expect(map['k1'], ['v1', 'v2']);
    });

    test('should support adding multiple values at once for existing keys', () {
      var map = ListMultimap<String, String>()
        ..add('k1', 'v1')
        ..addValues('k1', ['v1', 'v2']);
      expect(map['k1'], ['v1', 'v1', 'v2']);
    });

    test('should support adding from another multimap', () {
      var from = ListMultimap<String, String>()
        ..addValues('k1', ['v1', 'v2'])
        ..add('k2', 'v3');
      var map = ListMultimap<String, String>()..addAll(from);
      expect(map['k1'], ['v1', 'v2']);
      expect(map['k2'], ['v3']);
    });

    test('should support adding from another multimap with existing keys', () {
      var from = ListMultimap<String, String>()
        ..addValues('k1', ['v1', 'v2'])
        ..add('k2', 'v3');
      var map = ListMultimap<String, String>()
        ..add('k1', 'v0')
        ..add('k2', 'v3')
        ..addAll(from);
      expect(map['k1'], ['v0', 'v1', 'v2']);
      expect(map['k2'], ['v3', 'v3']);
    });

    test('should return its keys', () {
      var map = ListMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3');
      expect(map.keys, unorderedEquals(['k1', 'k2']));
    });

    test('should return its values', () {
      var map = ListMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3');
      expect(map.values, unorderedEquals(['v1', 'v2', 'v3']));
    });

    test('should support duplicate values', () {
      var map = ListMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v1');
      expect(map.values, unorderedEquals(['v1', 'v2', 'v1']));
    });

    test('should return an ordered list of values', () {
      var map = ListMultimap<String, String>()
        ..add('k', 'v1')
        ..add('k', 'v2');
      expect(map['k'], ['v1', 'v2']);
    });

    test('should reflect changes to underlying list', () {
      var map = ListMultimap<String, String>()
        ..add('k', 'v1')
        ..add('k', 'v2');
      map['k'].add('v3');
      map['k'].remove('v2');
      expect(map['k'], ['v1', 'v3']);
    });

    test('should return whether it contains a key', () {
      var map = ListMultimap<String, String>()
        ..add('k', 'v1')
        ..add('k', 'v2');
      expect(map.containsKey('j'), false);
      expect(map.containsKey('k'), true);
    });

    test('should return whether it contains a value', () {
      var map = ListMultimap<String, String>()
        ..add('k', 'v1')
        ..add('k', 'v2');
      expect(map.containsValue('v0'), false);
      expect(map.containsValue('v1'), true);
    });

    test('should return whether it contains a key/value association', () {
      var map = ListMultimap<String, String>()
        ..add('k', 'v1')
        ..add('k', 'v2');
      expect(map.contains('k', 'v0'), false);
      expect(map.contains('f', 'v1'), false);
      expect(map.contains('k', 'v1'), true);
    });

    test('should remove specified key-value associations', () {
      var map = ListMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3');
      expect(map.remove('k1', 'v0'), false);
      expect(map.remove('k1', 'v1'), true);
      expect(map['k1'], ['v2']);
      expect(map.containsKey('k2'), true);
    });

    test('should remove a key when all associated values are removed', () {
      var map = ListMultimap<String, String>()
        ..add('k1', 'v1')
        ..remove('k1', 'v1');
      expect(map.containsKey('k1'), false);
    });

    test(
        'should remove a key when all associated values are removed '
        'via the underlying iterable.remove', () {
      var map = ListMultimap<String, String>()..add('k1', 'v1');
      map['k1'].remove('v1');
      expect(map.containsKey('k1'), false);
    });

    test(
        'should remove a key when all associated values are removed '
        'via the underlying iterable.removeAt', () {
      var map = ListMultimap<String, String>()..add('k1', 'v1');
      map['k1'].removeAt(0);
      expect(map.containsKey('k1'), false);
    });

    test(
        'should remove a key when all associated values are removed '
        'via the underlying iterable.removeAt', () {
      var map = ListMultimap<String, String>()..add('k1', 'v1');
      map['k1'].removeLast();
      expect(map.containsKey('k1'), false);
    });

    test(
        'should remove a key when all associated values are removed '
        'via the underlying iterable.removeRange', () {
      var map = ListMultimap<String, String>()..add('k1', 'v1');
      map['k1'].removeRange(0, 1);
      expect(map.containsKey('k1'), false);
    });

    test(
        'should remove a key when all associated values are removed '
        'via the underlying iterable.removeWhere', () {
      var map = ListMultimap<String, String>()..add('k1', 'v1');
      map['k1'].removeWhere((_) => true);
      expect(map.containsKey('k1'), false);
    });

    test(
        'should remove a key when all associated values are removed '
        'via the underlying iterable.replaceRange', () {
      var map = ListMultimap<String, String>()..add('k1', 'v1');
      map['k1'].replaceRange(0, 1, []);
      expect(map.containsKey('k1'), false);
    });

    test(
        'should remove a key when all associated values are removed '
        'via the underlying iterable.retainWhere', () {
      var map = ListMultimap<String, String>()..add('k1', 'v1');
      map['k1'].retainWhere((_) => false);
      expect(map.containsKey('k1'), false);
    });

    test(
        'should remove a key when all associated values are removed '
        'via the underlying iterable.clear', () {
      var map = ListMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2');
      map['k1'].clear();
      expect(map.containsKey('k1'), false);
    });

    test('should remove all values for a key', () {
      var map = ListMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3');
      expect(map.removeAll('k1'), ['v1', 'v2']);
      expect(map.containsKey('k1'), false);
      expect(map.containsKey('k2'), true);
    });

    test('should call removeWhere with all {key, value} pairs', () {
      Set s = Set();
      ListMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3')
        ..removeWhere((k, v) {
          s.add(Pair(k, v));
          return false;
        });
      expect(
          s,
          unorderedEquals(
              [Pair('k1', 'v1'), Pair('k1', 'v2'), Pair('k2', 'v3')]));
    });

    test(
        'should remove all the {key, value} pairs that satisfy the '
        'predicate in removeWhere', () {
      var map = ListMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v1')
        ..removeWhere((k, v) => k == 'k2' || v == 'v1');
      expect(map.keys, equals(['k1']));
      expect(map.values, equals(['v2']));
    });

    test('should clear underlying iterable on remove', () {
      var map = ListMultimap<String, String>()..add('k1', 'v1');
      List values = map['k1'];
      expect(map.removeAll('k1'), ['v1']);
      expect(values, []);
    });

    test('should return an empty iterable on removeAll of unmapped key', () {
      var map = ListMultimap<String, String>();
      var removed = map.removeAll('k1');
      expect(removed, []);
    });

    test('should be uncoupled from the iterable returned by removeAll', () {
      var map = ListMultimap<String, String>()..add('k1', 'v1');
      var removed = map.removeAll('k1');
      removed.add('v2');
      map.add('k1', 'v3');
      expect(removed, ['v1', 'v2']);
      expect(map['k1'], ['v3']);
    });

    test('should clear the map', () {
      var map = ListMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3')
        ..clear();
      expect(map.isEmpty, true);
      expect(map.containsKey('k1'), false);
      expect(map.containsKey('k2'), false);
    });

    test('should clear underlying iterables on clear', () {
      var map = ListMultimap<String, String>()..add('k1', 'v1');
      List values = map['k1'];
      map.clear();
      expect(values, []);
    });

    test('should not add mappings on lookup of unmapped keys', () {
      var map = ListMultimap<String, String>()..['k1'];
      expect(map.containsKey('k1'), false);
    });

    test('should not remove mappings on clearing mapped values', () {
      var map = ListMultimap<String, String>()
        ..add('k1', 'v1')
        ..['v1'].clear();
      expect(map.containsKey('k1'), true);
    });

    test('should return a map view', () {
      var mmap = ListMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3');
      Map map = mmap.asMap();
      expect(map.keys, unorderedEquals(['k1', 'k2']));
      expect(map.values, hasLength(2));
      expect(map.values, anyElement(unorderedEquals(['v1', 'v2'])));
      expect(map.values, anyElement(unorderedEquals(['v3'])));
      expect(map['k1'], ['v1', 'v2']);
      expect(map['k2'], ['v3']);
    });

    test('should return an empty iterable on map view unmapped key', () {
      Map map = ListMultimap<String, String>().asMap();
      expect(map['k1'], []);
    });

    test('should allow addition via unmapped key lookup on map view', () {
      var mmap = ListMultimap<String, String>();
      Map map = mmap.asMap();
      map['k1'].add('v1');
      map['k2'].addAll(['v1', 'v2']);
      expect(mmap['k1'], ['v1']);
      expect(mmap['k2'], ['v1', 'v2']);
    });

    test('should reflect additions to iterables returned by map view', () {
      var mmap = ListMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2');
      Map map = mmap.asMap();
      map['k1'].add('v3');
      expect(mmap['k1'], ['v1', 'v2', 'v3']);
    });

    test('should reflect removals of keys in returned map view', () {
      var mmap = ListMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2');
      Map map = mmap.asMap();
      map.remove('k1');
      expect(mmap.containsKey('k1'), false);
    });

    test('should reflect clearing of returned map view', () {
      var mmap = ListMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3');
      Map map = mmap.asMap();
      map.clear();
      expect(mmap.isEmpty, true);
    });

    test('should support iteration over all {key, value} pairs', () {
      Set s = Set();
      ListMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3')
        ..forEach((k, v) => s.add(Pair(k, v)));
      expect(
          s,
          unorderedEquals(
              [Pair('k1', 'v1'), Pair('k1', 'v2'), Pair('k2', 'v3')]));
    });

    test('should support iteration over all {key, Iterable<value>} pairs', () {
      Map map = {};
      var mmap = ListMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3')
        ..forEachKey((k, v) => map[k] = v);
      expect(map.length, mmap.length);
      expect(map['k1'], ['v1', 'v2']);
      expect(map['k2'], ['v3']);
    });

    test(
        'should support operations on empty map views without breaking delegate synchronization',
        () {
      var mmap = ListMultimap<String, String>();
      List x = mmap['k1'];
      List y = mmap['k1'];
      List z = mmap['k1'];
      List w = mmap['k1'];
      mmap['k1'].add('v1');
      expect(mmap['k1'], ['v1']);
      x.add('v2');
      expect(mmap['k1'], ['v1', 'v2']);
      y.addAll(<String>['v3', 'v4']);
      expect(mmap['k1'], ['v1', 'v2', 'v3', 'v4']);
      z.insert(0, 'v0');
      expect(mmap['k1'], ['v0', 'v1', 'v2', 'v3', 'v4']);
      w.insertAll(5, <String>['v5', 'v6']);
      expect(mmap['k1'], ['v0', 'v1', 'v2', 'v3', 'v4', 'v5', 'v6']);
    });
  });

  group('SetMultimap', () {
    test('should initialize empty', () {
      var map = SetMultimap<String, String>();
      expect(map.isEmpty, true);
      expect(map.isNotEmpty, false);
    });

    test('should not be empty after adding', () {
      var map = SetMultimap<String, String>()..add('k', 'v');
      expect(map.isEmpty, false);
      expect(map.isNotEmpty, true);
    });

    test('should return the number of keys as length', () {
      var map = SetMultimap<String, String>();
      expect(map.length, 0);
      map
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3');
      expect(map.length, 2);
    });

    test('should return an empty iterable for unmapped keys', () {
      var map = SetMultimap<String, String>();
      expect(map['k1'], []);
    });

    test('should support adding values for unmapped keys', () {
      var map = SetMultimap<String, String>()..['k1'].add('v1');
      expect(map['k1'], ['v1']);
    });

    test('should support adding multiple values for unmapped keys', () {
      var map = SetMultimap<String, String>()..['k1'].addAll(['v1', 'v2']);
      expect(map['k1'], unorderedEquals(['v1', 'v2']));
    });

    test('should return unmapped iterables that stay in sync on add', () {
      var map = SetMultimap<String, String>();
      Set values1 = map['k1'];
      Set values2 = map['k1'];
      values1.add('v1');
      expect(map['k1'], ['v1']);
      expect(values2, ['v1']);
    });

    test('should return unmapped iterables that stay in sync on addAll', () {
      var map = SetMultimap<String, String>();
      Set values1 = map['k1'];
      Set values2 = map['k1'];
      values1.addAll(<String>['v1', 'v2']);
      expect(map['k1'], unorderedEquals(['v1', 'v2']));
      expect(values2, unorderedEquals(['v1', 'v2']));
    });

    test('should not support adding duplicate values for a key', () {
      var map = SetMultimap<String, String>()
        ..add('k', 'v1')
        ..add('k', 'v1');
      expect(map['k'], ['v1']);
    });

    test(
        'should not support adding duplicate values for a key when '
        'initialized from an iterable', () {
      var map = SetMultimap<String, String>.fromIterable(['k', 'k'],
          value: (x) => 'v1');
      expect(map['k'], ['v1']);
    });

    test('should support adding multiple keys', () {
      var map = SetMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3');
      expect(map['k1'], unorderedEquals(['v1', 'v2']));
      expect(map['k2'], ['v3']);
    });

    test('should support adding multiple values at once', () {
      var map = SetMultimap<String, String>()..addValues('k1', ['v1', 'v2']);
      expect(map['k1'], ['v1', 'v2']);
    });

    test('should support adding multiple values at once for existing keys', () {
      var map = SetMultimap<String, String>()
        ..add('k1', 'v0')
        ..addValues('k1', ['v1', 'v2']);
      expect(map['k1'], unorderedEquals(['v0', 'v1', 'v2']));
    });

    test('should support adding multiple values for existing (key,value)', () {
      var map = SetMultimap<String, String>()
        ..add('k1', 'v1')
        ..addValues('k1', ['v1', 'v2']);
      expect(map['k1'], unorderedEquals(['v1', 'v2']));
    });

    test('should support adding from another multimap', () {
      var from = SetMultimap<String, String>()
        ..addValues('k1', ['v1', 'v2'])
        ..add('k2', 'v3');
      var map = SetMultimap<String, String>()..addAll(from);
      expect(map['k1'], unorderedEquals(['v1', 'v2']));
      expect(map['k2'], ['v3']);
    });

    test('should support adding from another multimap with existing keys', () {
      var from = SetMultimap<String, String>()
        ..addValues('k1', ['v1', 'v2'])
        ..add('k2', 'v3');
      var map = SetMultimap<String, String>()
        ..add('k1', 'v0')
        ..add('k2', 'v3')
        ..addAll(from);
      expect(map['k1'], unorderedEquals(['v0', 'v1', 'v2']));
      expect(map['k2'], ['v3']);
    });

    test('should return its keys', () {
      var map = SetMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3');
      expect(map.keys, unorderedEquals(['k1', 'k2']));
    });

    test('should return its values', () {
      var map = SetMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3');
      expect(map.values, unorderedEquals(['v1', 'v2', 'v3']));
    });

    test('should support duplicate values', () {
      var map = SetMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v1');
      expect(map.values, unorderedEquals(['v1', 'v2', 'v1']));
    });

    test('should return an ordered list of values', () {
      var map = SetMultimap<String, String>()
        ..add('k', 'v1')
        ..add('k', 'v2');
      expect(map['k'], unorderedEquals(['v1', 'v2']));
    });

    test('should reflect changes to underlying set', () {
      var map = SetMultimap<String, String>()
        ..add('k', 'v1')
        ..add('k', 'v2');
      map['k'].add('v3');
      map['k'].remove('v2');
      expect(map['k'], unorderedEquals(['v1', 'v3']));
    });

    test('should return whether it contains a key', () {
      var map = SetMultimap<String, String>()
        ..add('k', 'v1')
        ..add('k', 'v2');
      expect(map.containsKey('j'), false);
      expect(map.containsKey('k'), true);
    });

    test('should return whether it contains a value', () {
      var map = SetMultimap<String, String>()
        ..add('k', 'v1')
        ..add('k', 'v2');
      expect(map.containsValue('v0'), false);
      expect(map.containsValue('v1'), true);
    });

    test('should remove specified key-value associations', () {
      var map = SetMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3');
      expect(map.remove('k1', 'v0'), false);
      expect(map.remove('k1', 'v1'), true);
      expect(map['k1'], ['v2']);
      expect(map.containsKey('k2'), true);
    });

    test('should remove a key when all associated values are removed', () {
      var map = SetMultimap<String, String>()
        ..add('k1', 'v1')
        ..remove('k1', 'v1');
      expect(map.containsKey('k1'), false);
    });

    test(
        'should remove a key when all associated values are removed '
        'via the underlying iterable.remove', () {
      var map = SetMultimap<String, String>()..add('k1', 'v1');
      map['k1'].remove('v1');
      expect(map.containsKey('k1'), false);
    });

    test(
        'should remove a key when all associated values are removed '
        'via the underlying iterable.removeAll', () {
      var map = SetMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2');
      map['k1'].removeAll(['v1', 'v2']);
      expect(map.containsKey('k1'), false);
    });

    test(
        'should remove a key when all associated values are removed '
        'via the underlying iterable.removeWhere', () {
      var map = SetMultimap<String, String>()..add('k1', 'v1');
      map['k1'].removeWhere((_) => true);
      expect(map.containsKey('k1'), false);
    });

    test(
        'should remove a key when all associated values are removed '
        'via the underlying iterable.retainAll', () {
      var map = SetMultimap<String, String>()..add('k1', 'v1');
      map['k1'].retainAll([]);
      expect(map.containsKey('k1'), false);
    });

    test(
        'should remove a key when all associated values are removed '
        'via the underlying iterable.retainWhere', () {
      var map = SetMultimap<String, String>()..add('k1', 'v1');
      map['k1'].retainWhere((_) => false);
      expect(map.containsKey('k1'), false);
    });

    test(
        'should remove a key when all associated values are removed '
        'via the underlying iterable.clear', () {
      var map = SetMultimap<String, String>()..add('k1', 'v1');
      map['k1'].clear();
      expect(map.containsKey('k1'), false);
    });

    test('should remove all values for a key', () {
      var map = SetMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3');
      expect(map.removeAll('k1'), unorderedEquals(['v1', 'v2']));
      expect(map.containsKey('k1'), false);
      expect(map.containsKey('k2'), true);
    });

    test('should call removeWhere with all {key, value} pairs', () {
      Set s = Set();
      SetMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3')
        ..removeWhere((k, v) {
          s.add(Pair(k, v));
          return false;
        });
      expect(
          s,
          unorderedEquals(
              [Pair('k1', 'v1'), Pair('k1', 'v2'), Pair('k2', 'v3')]));
    });

    test(
        'should remove all the {key, value} pairs that satisfy the '
        'predicate in removeWhere', () {
      var map = SetMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v1')
        ..removeWhere((k, v) => k == 'k2' || v == 'v1');
      expect(map.keys, equals(['k1']));
      expect(map.values, equals(['v2']));
    });

    test('should clear underlying iterable on remove', () {
      var map = SetMultimap<String, String>()..add('k1', 'v1');
      Set values = map['k1'];
      expect(map.removeAll('k1'), ['v1']);
      expect(values, []);
    });

    test('should return an empty iterable on removeAll of unmapped key', () {
      var map = SetMultimap<String, String>();
      var removed = map.removeAll('k1');
      expect(removed, []);
    });

    test('should be uncoupled from the iterable returned by removeAll', () {
      var map = SetMultimap<String, String>()..add('k1', 'v1');
      var removed = map.removeAll('k1');
      removed.add('v2');
      map.add('k1', 'v3');
      expect(removed, unorderedEquals(['v1', 'v2']));
      expect(map['k1'], ['v3']);
    });

    test('should clear the map', () {
      var map = SetMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3')
        ..clear();
      expect(map.isEmpty, true);
      expect(map.containsKey('k1'), false);
      expect(map.containsKey('k2'), false);
    });

    test('should clear underlying iterables on clear', () {
      var map = SetMultimap<String, String>()..add('k1', 'v1');
      Set values = map['k1'];
      map.clear();
      expect(values, []);
    });

    test('should not add mappings on lookup of unmapped keys', () {
      var map = SetMultimap<String, String>()..['k1'];
      expect(map.containsKey('k1'), false);
    });

    test('should not remove mappings on clearing mapped values', () {
      var map = SetMultimap<String, String>()
        ..add('k1', 'v1')
        ..['v1'].clear();
      expect(map.containsKey('k1'), true);
    });

    test('should return a map view', () {
      var mmap = SetMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3');
      Map map = mmap.asMap();
      expect(map.keys, unorderedEquals(['k1', 'k2']));
      expect(map['k1'], ['v1', 'v2']);
      expect(map['k2'], ['v3']);
    });

    test('should return an empty iterable on map view unmapped key', () {
      Map map = SetMultimap<String, String>().asMap();
      expect(map['k1'], []);
    });

    test('should allow addition via unmapped key lookup on map view', () {
      var mmap = SetMultimap<String, String>();
      Map map = mmap.asMap();
      map['k1'].add('v1');
      map['k2'].addAll(['v1', 'v2']);
      expect(mmap['k1'], ['v1']);
      expect(mmap['k2'], unorderedEquals(['v1', 'v2']));
    });

    test('should reflect additions to iterables returned by map view', () {
      var mmap = SetMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2');
      Map map = mmap.asMap();
      map['k1'].add('v3');
      expect(mmap['k1'], unorderedEquals(['v1', 'v2', 'v3']));
    });

    test('should reflect additions to iterables returned by map view', () {
      var mmap = SetMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2');
      Map map = mmap.asMap();
      map['k1'].add('v3');
      expect(mmap['k1'], unorderedEquals(['v1', 'v2', 'v3']));
    });

    test('should reflect removals of keys in returned map view', () {
      var mmap = SetMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2');
      Map map = mmap.asMap();
      map.remove('k1');
      expect(mmap.containsKey('k1'), false);
    });

    test('should something about entries in returned map view', () {
      var mmap = SetMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2');
      Map map = mmap.asMap();
      expect(map.entries, hasLength(1));
      expect(map.entries.single.key, equals('k1'));
      expect(map.entries.single.value, unorderedEquals(['v1', 'v2']));
    });

    test('should map from returned map view', () {
      var mmap = SetMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2');
      Map map = mmap.asMap();
      var newMap = map.map((k, v) => MapEntry(k, v.join(',')));
      expect(newMap, hasLength(1));
      expect(newMap, contains('k1'));
      expect(newMap, containsValue('v1,v2'));
    });

    test('should reflect clearing of returned map view', () {
      var mmap = SetMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3');
      Map map = mmap.asMap();
      map.clear();
      expect(mmap.isEmpty, true);
    });

    test('should support iteration over all {key, value} pairs', () {
      Set s = Set();
      SetMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3')
        ..forEach((k, v) => s.add(Pair(k, v)));
      expect(
          s,
          unorderedEquals(
              [Pair('k1', 'v1'), Pair('k1', 'v2'), Pair('k2', 'v3')]));
    });

    test('should support iteration over all {key, Iterable<value>} pairs', () {
      Map map = {};
      var mmap = SetMultimap<String, String>()
        ..add('k1', 'v1')
        ..add('k1', 'v2')
        ..add('k2', 'v3')
        ..forEachKey((k, v) => map[k] = v);
      expect(map.length, mmap.length);
      expect(map['k1'], unorderedEquals(['v1', 'v2']));
      expect(map['k2'], unorderedEquals(['v3']));
    });

    test(
        'should support operations on empty map views without breaking '
        'delegate synchronization', () {
      var mmap = SetMultimap<String, String>();
      Set x = mmap['k1'];
      Set y = mmap['k1'];
      mmap['k1'].add('v0');
      x.add('v1');
      y.addAll(<String>['v2', 'v3']);
      expect(mmap['k1'], unorderedEquals(['v0', 'v1', 'v2', 'v3']));
    });
  });
}

class Pair<T> {
  Pair(this.x, this.y) : assert(x != null && y != null);

  final T x;
  final T y;

  @override
  bool operator ==(Object other) {
    if (other is! Pair<T>) return false;
    if (x != other.x) return false;
    return equals(y).matches(other.y, {});
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => '($x, $y)';
}
