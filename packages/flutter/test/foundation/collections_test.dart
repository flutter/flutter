// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter/src/foundation/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('listEquals', () {
    final listA = <int>[1, 2, 3];
    final listB = <int>[1, 2, 3];
    final listC = <int>[1, 2];
    final listD = <int>[3, 2, 1];

    expect(listEquals<void>(null, null), isTrue);
    expect(listEquals(listA, null), isFalse);
    expect(listEquals(null, listB), isFalse);
    expect(listEquals(listA, listA), isTrue);
    expect(listEquals(listA, listB), isTrue);
    expect(listEquals(listA, listC), isFalse);
    expect(listEquals(listA, listD), isFalse);
  });
  test('setEquals', () {
    final setA = <int>{1, 2, 3};
    final setB = <int>{1, 2, 3};
    final setC = <int>{1, 2};
    final setD = <int>{3, 2, 1};

    expect(setEquals<void>(null, null), isTrue);
    expect(setEquals(setA, null), isFalse);
    expect(setEquals(null, setB), isFalse);
    expect(setEquals(setA, setA), isTrue);
    expect(setEquals(setA, setB), isTrue);
    expect(setEquals(setA, setC), isFalse);
    expect(setEquals(setA, setD), isTrue);
  });
  test('mapEquals', () {
    final mapA = <int, int>{1: 1, 2: 2, 3: 3};
    final mapB = <int, int>{1: 1, 2: 2, 3: 3};
    final mapC = <int, int>{1: 1, 2: 2};
    final mapD = <int, int>{3: 3, 2: 2, 1: 1};
    final mapE = <int, int>{3: 1, 2: 2, 1: 3};

    expect(mapEquals<void, void>(null, null), isTrue);
    expect(mapEquals(mapA, null), isFalse);
    expect(mapEquals(null, mapB), isFalse);
    expect(mapEquals(mapA, mapA), isTrue);
    expect(mapEquals(mapA, mapB), isTrue);
    expect(mapEquals(mapA, mapC), isFalse);
    expect(mapEquals(mapA, mapD), isTrue);
    expect(mapEquals(mapA, mapE), isFalse);
  });
  test('binarySearch', () {
    final items = <int>[1, 2, 3];

    expect(binarySearch(items, 1), 0);
    expect(binarySearch(items, 2), 1);
    expect(binarySearch(items, 3), 2);
    expect(binarySearch(items, 12), -1);
  });
  test('MergeSortRandom', () {
    final random = Random();
    for (var i = 0; i < 250; i += 1) {
      // Expect some equal elements.
      final list = List<int>.generate(i, (int j) => random.nextInt(i));
      mergeSort(list);
      for (var j = 1; j < i; j++) {
        expect(list[j - 1], lessThanOrEqualTo(list[j]));
      }
    }
  });
  test('MergeSortPreservesOrder', () {
    final random = Random();
    // Small case where only insertion call is called,
    // larger case where the internal moving insertion sort is used
    // larger cases with multiple splittings, numbers just around a power of 2.
    for (final size in <int>[8, 50, 511, 512, 513]) {
      // Class OC compares using id.
      // With size elements with id's in the range 0..size/4, a number of
      // collisions are guaranteed. These should be sorted so that the 'order'
      // part of the objects are still in order.
      final list = List<OrderedComparable>.generate(
        size,
        (int i) => OrderedComparable(random.nextInt(size >> 2), i),
      );
      mergeSort(list);
      OrderedComparable prev = list[0];
      for (var i = 1; i < size; i++) {
        final OrderedComparable next = list[i];
        expect(prev.id, lessThanOrEqualTo(next.id));
        if (next.id == prev.id) {
          expect(prev.order, lessThanOrEqualTo(next.order));
        }
        prev = next;
      }
      // Reverse compare on part of list.
      final List<OrderedComparable> copy = list.toList();
      final int min = size >> 2;
      final int max = size - min;
      mergeSort<OrderedComparable>(
        list,
        start: min,
        end: max,
        compare: (OrderedComparable a, OrderedComparable b) => b.compareTo(a),
      );
      prev = list[min];
      for (int i = min + 1; i < max; i++) {
        final OrderedComparable next = list[i];
        expect(prev.id, greaterThanOrEqualTo(next.id));
        if (next.id == prev.id) {
          expect(prev.order, lessThanOrEqualTo(next.order));
        }
        prev = next;
      }
      // Equals on OC objects is identity, so this means the parts before min,
      // and the parts after max, didn't change at all.
      expect(list.sublist(0, min), equals(copy.sublist(0, min)));
      expect(list.sublist(max), equals(copy.sublist(max)));
    }
  });
  test('MergeSortSpecialCases', () {
    for (final size in <int>[511, 512, 513]) {
      // All equal.
      final list = List<OrderedComparable>.generate(size, (int i) => OrderedComparable(0, i));
      mergeSort(list);
      for (var i = 0; i < size; i++) {
        expect(list[i].order, equals(i));
      }
      // All but one equal, first.
      list[0] = OrderedComparable(1, 0);
      for (var i = 1; i < size; i++) {
        list[i] = OrderedComparable(0, i);
      }
      mergeSort(list);
      for (var i = 0; i < size - 1; i++) {
        expect(list[i].order, equals(i + 1));
      }
      expect(list[size - 1].order, equals(0));

      // All but one equal, last.
      for (var i = 0; i < size - 1; i++) {
        list[i] = OrderedComparable(0, i);
      }
      list[size - 1] = OrderedComparable(-1, size - 1);
      mergeSort(list);
      expect(list[0].order, equals(size - 1));
      for (var i = 1; i < size; i++) {
        expect(list[i].order, equals(i - 1));
      }

      // Reversed.
      for (var i = 0; i < size; i++) {
        list[i] = OrderedComparable(size - 1 - i, i);
      }
      mergeSort(list);
      for (var i = 0; i < size; i++) {
        expect(list[i].id, equals(i));
        expect(list[i].order, equals(size - 1 - i));
      }
    }
  });
}

class OrderedComparable implements Comparable<OrderedComparable> {
  OrderedComparable(this.id, this.order);
  final int id;
  final int order;
  @override
  int compareTo(OrderedComparable other) => id - other.id;
  @override
  String toString() => 'OverrideComparable[$id,$order]';
}
