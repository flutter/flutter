// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ObserverList', () async {
    final list = ObserverList<int>();
    for (var i = 0; i < 10; ++i) {
      list.add(i);
    }
    final Iterator<int> iterator = list.iterator;
    for (var i = 0; i < 10 && iterator.moveNext(); ++i) {
      expect(iterator.current, equals(i));
    }
    for (var i = 9; i >= 0; --i) {
      expect(list.remove(i), isTrue);
      final Iterator<int> iterator = list.iterator;
      for (var j = 0; j < i && iterator.moveNext(); ++j) {
        expect(iterator.current, equals(j));
      }
    }
  });
  test('HashedObserverList', () async {
    final list = HashedObserverList<int>();
    for (var i = 0; i < 10; ++i) {
      list.add(i);
    }
    Iterator<int> iterator = list.iterator;
    for (var i = 0; i < 10 && iterator.moveNext(); ++i) {
      expect(iterator.current, equals(i));
    }
    for (var i = 9; i >= 0; --i) {
      expect(list.remove(i), isTrue);
      iterator = list.iterator;
      for (var j = 0; j < i && iterator.moveNext(); ++j) {
        expect(iterator.current, equals(j));
      }
    }
    list.add(0);
    for (var i = 0; i < 10; ++i) {
      list.add(1);
    }
    list.add(2);
    iterator = list.iterator;
    for (var i = 0; iterator.moveNext(); ++i) {
      expect(iterator.current, equals(i));
      expect(i, lessThan(3));
    }
    for (var i = 2; i >= 0; --i) {
      expect(list.remove(i), isTrue);
      iterator = list.iterator;
      for (var j = 0; iterator.moveNext(); ++j) {
        expect(iterator.current, equals(i != 0 ? j : 1));
        expect(j, lessThan(3));
      }
    }
    iterator = list.iterator;
    for (var j = 0; iterator.moveNext(); ++j) {
      expect(iterator.current, equals(1));
      expect(j, equals(0));
    }
    expect(list.isEmpty, isFalse);
    iterator = list.iterator;
    iterator.moveNext();
    expect(iterator.current, equals(1));
    for (var i = 0; i < 9; ++i) {
      expect(list.remove(1), isTrue);
    }
    expect(list.isEmpty, isTrue);
  });
  test('ObserverList.length', () {
    final list = ObserverList<int>();
    expect(list.length, 0);
    list.add(1);
    list.add(2);
    list.add(2);
    expect(list.length, 3);
    list.remove(2);
    expect(list.length, 2);
  });
  test('HashedObserverList.length and toList', () {
    final list = HashedObserverList<int>();
    expect(list.length, 0);
    list.add(1);
    list.add(2);
    list.add(2);
    expect(list.length, 2);
    expect(list.toList(), <int>[1, 2]);
    final List<int> fixed = list.toList(growable: false);
    expect(fixed, <int>[1, 2]);
    expect(() => fixed.add(3), throwsUnsupportedError);
    expect(list.remove(2), isTrue);
    expect(list.length, 2);
    expect(list.remove(2), isTrue);
    expect(list.length, 1);
    expect(list.toList(), <int>[1]);
  });
}
