// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ObserverList', () async {
    final ObserverList<int> list = ObserverList<int>();
    for (int i = 0; i < 10; ++i) {
      list.add(i);
    }
    final Iterator<int> iterator = list.iterator;
    for (int i = 0; i < 10 && iterator.moveNext(); ++i) {
      expect(iterator.current, equals(i));
    }
    for (int i = 9; i >= 0; --i) {
      expect(list.remove(i), isTrue);
      final Iterator<int> iterator = list.iterator;
      for (int j = 0; j < i && iterator.moveNext(); ++j) {
        expect(iterator.current, equals(j));
      }
    }
  });
  test('HashedObserverList', () async {
    final HashedObserverList<int> list = HashedObserverList<int>();
    for (int i = 0; i < 10; ++i) {
      list.add(i);
    }
    Iterator<int> iterator = list.iterator;
    for (int i = 0; i < 10 && iterator.moveNext(); ++i) {
      expect(iterator.current, equals(i));
    }
    for (int i = 9; i >= 0; --i) {
      expect(list.remove(i), isTrue);
      iterator = list.iterator;
      for (int j = 0; j < i && iterator.moveNext(); ++j) {
        expect(iterator.current, equals(j));
      }
    }
    list.add(0);
    for (int i = 0; i < 10; ++i) {
      list.add(1);
    }
    list.add(2);
    iterator = list.iterator;
    for (int i = 0; iterator.moveNext(); ++i) {
      expect(iterator.current, equals(i));
      expect(i, lessThan(3));
    }
    for (int i = 2; i >= 0; --i) {
      expect(list.remove(i), isTrue);
      iterator = list.iterator;
      for (int j = 0; iterator.moveNext(); ++j) {
        expect(iterator.current, equals(i != 0 ? j : 1));
        expect(j, lessThan(3));
      }
    }
    iterator = list.iterator;
    for (int j = 0; iterator.moveNext(); ++j) {
      expect(iterator.current, equals(1));
      expect(j, equals(0));
    }
    expect(list.isEmpty, isFalse);
    iterator = list.iterator;
    iterator.moveNext();
    expect(iterator.current, equals(1));
    for (int i = 0; i < 9; ++i) {
      expect(list.remove(1), isTrue);
    }
    expect(list.isEmpty, isTrue);
  });
}
