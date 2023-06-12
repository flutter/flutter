// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests priority queue implementations utilities.
import 'package:collection/src/priority_queue.dart';
import 'package:test/test.dart';

void main() {
  testDefault();
  testInt(() => HeapPriorityQueue<int>());
  testCustom((comparator) => HeapPriorityQueue<C>(comparator));
  testDuplicates();
  testNullable();
  testConcurrentModification();
}

void testDefault() {
  test('PriorityQueue() returns a HeapPriorityQueue', () {
    expect(PriorityQueue<int>(), TypeMatcher<HeapPriorityQueue<int>>());
  });
  testInt(() => PriorityQueue<int>());
  testCustom((comparator) => PriorityQueue<C>(comparator));
}

void testInt(PriorityQueue<int> Function() create) {
  for (var count in [1, 5, 127, 128]) {
    testQueue('int:$count', create, List<int>.generate(count, (x) => x), count);
  }
}

void testCustom(
    PriorityQueue<C> Function(int Function(C, C)? comparator) create) {
  for (var count in [1, 5, 127, 128]) {
    testQueue('Custom:$count/null', () => create(null),
        List<C>.generate(count, (x) => C(x)), C(count));
    testQueue('Custom:$count/compare', () => create(compare),
        List<C>.generate(count, (x) => C(x)), C(count));
    testQueue('Custom:$count/compareNeg', () => create(compareNeg),
        List<C>.generate(count, (x) => C(count - x)), C(0));
  }
}

/// Test that a queue behaves correctly.
///
/// The elements must be in priority order, from highest to lowest.
void testQueue(
    String name, PriorityQueue Function() create, List elements, notElement) {
  test(name, () => testQueueBody(create, elements, notElement));
}

void testQueueBody<T>(
    PriorityQueue<T> Function() create, List<T> elements, notElement) {
  var q = create();
  expect(q.isEmpty, isTrue);
  expect(q, hasLength(0));
  expect(() {
    q.first;
  }, throwsStateError);
  expect(() {
    q.removeFirst();
  }, throwsStateError);

  // Tests removeFirst, first, contains, toList and toSet.
  void testElements() {
    expect(q.isNotEmpty, isTrue);
    expect(q, hasLength(elements.length));

    expect(q.toList(), equals(elements));
    expect(q.toSet().toList(), equals(elements));
    expect(q.toUnorderedList(), unorderedEquals(elements));
    expect(q.unorderedElements, unorderedEquals(elements));

    var allElements = q.removeAll();
    q.addAll(allElements);

    for (var i = 0; i < elements.length; i++) {
      expect(q.contains(elements[i]), isTrue);
    }
    expect(q.contains(notElement), isFalse);

    var all = [];
    while (q.isNotEmpty) {
      var expected = q.first;
      var actual = q.removeFirst();
      expect(actual, same(expected));
      all.add(actual);
    }

    expect(all.length, elements.length);
    for (var i = 0; i < all.length; i++) {
      expect(all[i], same(elements[i]));
    }

    expect(q.isEmpty, isTrue);
  }

  q.addAll(elements);
  testElements();

  q.addAll(elements.reversed);
  testElements();

  // Add elements in a non-linear order (gray order).
  for (var i = 0, j = 0; i < elements.length; i++) {
    int gray;
    do {
      gray = j ^ (j >> 1);
      j++;
    } while (gray >= elements.length);
    q.add(elements[gray]);
  }
  testElements();

  // Add elements by picking the middle element first, and then recursing
  // on each side.
  void addRec(int min, int max) {
    var mid = min + ((max - min) >> 1);
    q.add(elements[mid]);
    if (mid + 1 < max) addRec(mid + 1, max);
    if (mid > min) addRec(min, mid);
  }

  addRec(0, elements.length);
  testElements();

  // Test removeAll.
  q.addAll(elements);
  expect(q, hasLength(elements.length));
  var all = q.removeAll();
  expect(q.isEmpty, isTrue);
  expect(all, hasLength(elements.length));
  for (var i = 0; i < elements.length; i++) {
    expect(all, contains(elements[i]));
  }

  // Test the same element more than once in queue.
  q.addAll(elements);
  q.addAll(elements.reversed);
  expect(q, hasLength(elements.length * 2));
  for (var i = 0; i < elements.length; i++) {
    var element = elements[i];
    expect(q.contains(element), isTrue);
    expect(q.removeFirst(), element);
    expect(q.removeFirst(), element);
  }

  // Test queue with all same element.
  var a = elements[0];
  for (var i = 0; i < elements.length; i++) {
    q.add(a);
  }
  expect(q, hasLength(elements.length));
  expect(q.contains(a), isTrue);
  expect(q.contains(notElement), isFalse);
  q.removeAll().forEach((x) => expect(x, same(a)));

  // Test remove.
  q.addAll(elements);
  for (var element in elements.reversed) {
    expect(q.remove(element), isTrue);
  }
  expect(q.isEmpty, isTrue);
}

void testDuplicates() {
  // Check how the heap handles duplicate, or equal-but-not-identical, values.
  test('duplicates', () {
    var q = HeapPriorityQueue<C>(compare);
    var c1 = C(0);
    var c2 = C(0);

    // Can contain the same element more than once.
    expect(c1, equals(c2));
    expect(c1, isNot(same(c2)));
    q.add(c1);
    q.add(c1);
    expect(q.length, 2);
    expect(q.contains(c1), true);
    expect(q.contains(c2), true);
    expect(q.remove(c2), true);
    expect(q.length, 1);
    expect(q.removeFirst(), same(c1));

    // Can contain equal elements.
    q.add(c1);
    q.add(c2);
    expect(q.length, 2);
    expect(q.contains(c1), true);
    expect(q.contains(c2), true);
    expect(q.remove(c1), true);
    expect(q.length, 1);
    expect(q.first, anyOf(same(c1), same(c2)));
  });
}

void testNullable() {
  // Check that the queue works with a nullable type, and a comparator
  // which accepts `null`.
  // Compares `null` before instances of `C`.
  int nullCompareFirst(C? a, C? b) => a == null
      ? b == null
          ? 0
          : -1
      : b == null
          ? 1
          : compare(a, b);

  int nullCompareLast(C? a, C? b) => a == null
      ? b == null
          ? 0
          : 1
      : b == null
          ? -1
          : compare(a, b);

  var c1 = C(1);
  var c2 = C(2);
  var c3 = C(3);

  test('nulls first', () {
    var q = HeapPriorityQueue<C?>(nullCompareFirst);
    q.add(c2);
    q.add(c1);
    q.add(null);
    expect(q.length, 3);
    expect(q.contains(null), true);
    expect(q.contains(c1), true);
    expect(q.contains(c3), false);

    expect(q.removeFirst(), null);
    expect(q.length, 2);
    expect(q.contains(null), false);
    q.add(null);
    expect(q.length, 3);
    expect(q.contains(null), true);
    q.add(null);
    expect(q.length, 4);
    expect(q.contains(null), true);
    expect(q.remove(null), true);
    expect(q.length, 3);
    expect(q.toList(), [null, c1, c2]);
  });

  test('nulls last', () {
    var q = HeapPriorityQueue<C?>(nullCompareLast);
    q.add(c2);
    q.add(c1);
    q.add(null);
    expect(q.length, 3);
    expect(q.contains(null), true);
    expect(q.contains(c1), true);
    expect(q.contains(c3), false);
    expect(q.first, c1);

    q.add(null);
    expect(q.length, 4);
    expect(q.contains(null), true);
    q.add(null);
    expect(q.length, 5);
    expect(q.contains(null), true);
    expect(q.remove(null), true);
    expect(q.length, 4);
    expect(q.toList(), [c1, c2, null, null]);
  });
}

void testConcurrentModification() {
  group('concurrent modification for', () {
    test('add', () {
      var q = HeapPriorityQueue<int>((a, b) => a - b)
        ..addAll([6, 4, 2, 3, 5, 8]);
      var e = q.unorderedElements;
      q.add(12); // Modifiation before creating iterator is not a problem.
      var it = e.iterator;
      q.add(7); // Modification after creatig iterator is a problem.
      expect(it.moveNext, throwsConcurrentModificationError);

      it = e.iterator; // New iterator is not affected.
      expect(it.moveNext(), true);
      expect(it.moveNext(), true);
      q.add(9); // Modification during iteration is a problem.
      expect(it.moveNext, throwsConcurrentModificationError);
    });

    test('addAll', () {
      var q = HeapPriorityQueue<int>((a, b) => a - b)
        ..addAll([6, 4, 2, 3, 5, 8]);
      var e = q.unorderedElements;
      q.addAll([12]); // Modifiation before creating iterator is not a problem.
      var it = e.iterator;
      q.addAll([7]); // Modification after creatig iterator is a problem.
      expect(it.moveNext, throwsConcurrentModificationError);
      it = e.iterator; // New iterator is not affected.
      expect(it.moveNext(), true);
      q.addAll([]); // Adding nothing is not a modification.
      expect(it.moveNext(), true);
      q.addAll([9]); // Modification during iteration is a problem.
      expect(it.moveNext, throwsConcurrentModificationError);
    });

    test('removeFirst', () {
      var q = HeapPriorityQueue<int>((a, b) => a - b)
        ..addAll([6, 4, 2, 3, 5, 8]);
      var e = q.unorderedElements;
      expect(q.removeFirst(),
          2); // Modifiation before creating iterator is not a problem.
      var it = e.iterator;
      expect(q.removeFirst(),
          3); // Modification after creatig iterator is a problem.
      expect(it.moveNext, throwsConcurrentModificationError);

      it = e.iterator; // New iterator is not affected.
      expect(it.moveNext(), true);
      expect(it.moveNext(), true);
      expect(q.removeFirst(), 4); // Modification during iteration is a problem.
      expect(it.moveNext, throwsConcurrentModificationError);
    });

    test('remove', () {
      var q = HeapPriorityQueue<int>((a, b) => a - b)
        ..addAll([6, 4, 2, 3, 5, 8]);
      var e = q.unorderedElements;
      expect(q.remove(3), true);
      var it = e.iterator;
      expect(q.remove(2), true);
      expect(it.moveNext, throwsConcurrentModificationError);
      it = e.iterator;
      expect(q.remove(99), false);
      expect(it.moveNext(), true);
      expect(it.moveNext(), true);
      expect(q.remove(5), true);
      expect(it.moveNext, throwsConcurrentModificationError);
    });

    test('removeAll', () {
      var q = HeapPriorityQueue<int>((a, b) => a - b)
        ..addAll([6, 4, 2, 3, 5, 8]);
      var e = q.unorderedElements;
      var it = e.iterator;
      expect(it.moveNext(), true);
      expect(it.moveNext(), true);
      expect(q.removeAll(), hasLength(6));
      expect(it.moveNext, throwsConcurrentModificationError);
    });

    test('clear', () {
      var q = HeapPriorityQueue<int>((a, b) => a - b)
        ..addAll([6, 4, 2, 3, 5, 8]);
      var e = q.unorderedElements;
      var it = e.iterator;
      expect(it.moveNext(), true);
      expect(it.moveNext(), true);
      q.clear();
      expect(it.moveNext, throwsConcurrentModificationError);
    });
  });
}

// Custom class.
// Class is comparable, comparators match normal and inverse order.
int compare(C c1, C c2) => c1.value - c2.value;
int compareNeg(C c1, C c2) => c2.value - c1.value;

class C implements Comparable<C> {
  final int value;
  const C(this.value);
  @override
  int get hashCode => value;
  @override
  bool operator ==(Object other) => other is C && value == other.value;
  @override
  int compareTo(C other) => value - other.value;
  @override
  String toString() => 'C($value)';
}
