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

library quiver.collection.delegates.map_test;

import 'package:quiver/src/collection/delegates/map.dart';
import 'package:test/test.dart';

class MyMap extends DelegatingMap<String, int> {
  MyMap(this._delegate);

  final Map<String, int> _delegate;

  @override
  Map<String, int> get delegate => _delegate;
}

void main() {
  group('DelegatingMap', () {
    late DelegatingMap<String, int> delegatingMap;

    setUp(() {
      delegatingMap = MyMap({'a': 1, 'bb': 2});
    });

    test('[]', () {
      expect(delegatingMap['a'], equals(1));
      expect(delegatingMap['bb'], equals(2));
      expect(delegatingMap['c'], isNull);
    });

    test('[]=', () {
      delegatingMap['a'] = 3;
      delegatingMap['c'] = 4;
      expect(delegatingMap, equals({'a': 3, 'bb': 2, 'c': 4}));
    });

    test('addAll', () {
      delegatingMap.addAll({'a': 3, 'c': 4});
      expect(delegatingMap, equals({'a': 3, 'bb': 2, 'c': 4}));
    });

    test('clear', () {
      delegatingMap.clear();
      expect(delegatingMap, equals({}));
    });

    test('containsKey', () {
      expect(delegatingMap.containsKey('a'), isTrue);
      expect(delegatingMap.containsKey('b'), isFalse);
    });

    test('containsValue', () {
      expect(delegatingMap.containsValue(1), isTrue);
      expect(delegatingMap.containsValue('b'), isFalse);
    });

    test('forEach', () {
      final s = StringBuffer();
      delegatingMap.forEach((k, v) => s.write('$k$v'));
      expect(s.toString(), equals('a1bb2'));
    });

    test('isEmpty', () {
      expect(delegatingMap.isEmpty, isFalse);
      expect(MyMap({}).isEmpty, isTrue);
    });

    test('isNotEmpty', () {
      expect(delegatingMap.isNotEmpty, isTrue);
      expect(MyMap({}).isNotEmpty, isFalse);
    });

    test('keys', () {
      expect(delegatingMap.keys, equals(['a', 'bb']));
    });

    test('length', () {
      expect(delegatingMap.length, equals(2));
      expect(MyMap({}).length, equals(0));
    });

    test('putIfAbsent', () {
      expect(delegatingMap.putIfAbsent('c', () => 4), equals(4));
      expect(delegatingMap.putIfAbsent('c', () => throw ''), equals(4));
    });

    test('remove', () {
      expect(delegatingMap.remove('a'), equals(1));
      expect(delegatingMap, equals({'bb': 2}));
    });

    test('values', () {
      expect(delegatingMap.values, equals([1, 2]));
    });
  });
}
