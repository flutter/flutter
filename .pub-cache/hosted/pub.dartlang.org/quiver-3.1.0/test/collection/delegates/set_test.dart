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

library quiver.collection.delegates.set_test;

import 'dart:collection' show LinkedHashSet;

import 'package:quiver/src/collection/delegates/set.dart';
import 'package:test/test.dart';

class MySet extends DelegatingSet<String> {
  MySet(this._delegate);

  final Set<String> _delegate;

  @override
  Set<String> get delegate => _delegate;
}

void main() {
  group('DelegatingSet', () {
    late DelegatingSet<String> delegatingSet;

    setUp(() {
      delegatingSet = MySet(LinkedHashSet<String>.from(['a', 'b', 'cc']));
    });

    test('add', () {
      delegatingSet.add('d');
      expect(delegatingSet, equals(['a', 'b', 'cc', 'd']));
      delegatingSet.add('d');
      expect(delegatingSet, equals(['a', 'b', 'cc', 'd']));
    });

    test('addAll', () {
      delegatingSet.addAll(['d', 'e']);
      expect(delegatingSet, equals(['a', 'b', 'cc', 'd', 'e']));
    });

    test('clear', () {
      delegatingSet.clear();
      expect(delegatingSet, equals([]));
    });

    test('containsAll', () {
      expect(delegatingSet.containsAll(['a', 'cc']), isTrue);
      expect(delegatingSet.containsAll(['a', 'c']), isFalse);
    });

    test('difference', () {
      expect(delegatingSet.difference(Set<String>.from(['a', 'cc'])),
          equals(['b']));
      expect(delegatingSet.difference(Set<String>.from(['cc'])),
          equals(['a', 'b']));
    });

    test('intersection', () {
      expect(delegatingSet.intersection(Set<String>.from(['a', 'dd'])),
          equals(['a']));
      expect(delegatingSet.intersection(Set<String>.from(['e'])), equals([]));
    });

    test('remove', () {
      expect(delegatingSet.remove('b'), isTrue);
      expect(delegatingSet, equals(['a', 'cc']));
    });

    test('removeAll', () {
      delegatingSet.removeAll(['a', 'cc']);
      expect(delegatingSet, equals(['b']));
    });

    test('removeWhere', () {
      delegatingSet.removeWhere((e) => e.length == 1);
      expect(delegatingSet, equals(['cc']));
    });

    test('retainAll', () {
      delegatingSet.retainAll(['a', 'cc', 'd']);
      expect(delegatingSet, equals(['a', 'cc']));
    });

    test('retainWhere', () {
      delegatingSet.retainWhere((e) => e.length == 1);
      expect(delegatingSet, equals(['a', 'b']));
    });

    test('union', () {
      expect(delegatingSet.union(LinkedHashSet<String>.from(['a', 'cc', 'd'])),
          equals(['a', 'b', 'cc', 'd']));
    });
  });
}
