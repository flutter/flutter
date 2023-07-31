// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'package:test/test.dart';

import 'package:typed_data/typed_data.dart';

/// The initial capacity of queues if the user doesn't specify one.
const capacity = 16;

void main() {
  group('Uint8Queue()', () {
    test('creates an empty Uint8Queue', () {
      expect(Uint8Queue(), isEmpty);
    });

    test('takes an initial capacity', () {
      expect(Uint8Queue(100), isEmpty);
    });
  });

  group('add() adds an element to the end', () {
    forEachInternalRepresentation((queue) {
      queue.add(16);
      expect(queue, equals(oneThrough(capacity)));
    });
  });

  group('addFirst() adds an element to the beginning', () {
    forEachInternalRepresentation((queue) {
      queue.addFirst(0);
      expect(queue, equals([0, ...oneThrough(capacity - 1)]));
    });
  });

  group('removeFirst() removes an element from the beginning', () {
    forEachInternalRepresentation((queue) {
      expect(queue.removeFirst(), equals(1));
      expect(queue, equals(oneThrough(capacity - 1).skip(1)));
    });

    test('throws a StateError for an empty queue', () {
      expect(Uint8Queue().removeFirst, throwsStateError);
    });
  });

  group('removeLast() removes an element from the end', () {
    forEachInternalRepresentation((queue) {
      expect(queue.removeLast(), equals(15));
      expect(queue, equals(oneThrough(capacity - 2)));
    });

    test('throws a StateError for an empty queue', () {
      expect(Uint8Queue().removeLast, throwsStateError);
    });
  });

  group('removeRange()', () {
    group('removes a prefix', () {
      forEachInternalRepresentation((queue) {
        queue.removeRange(0, 5);
        expect(queue, equals(oneThrough(capacity - 1).skip(5)));
      });
    });

    group('removes a suffix', () {
      forEachInternalRepresentation((queue) {
        queue.removeRange(10, 15);
        expect(queue, equals(oneThrough(capacity - 6)));
      });
    });

    group('removes from the middle', () {
      forEachInternalRepresentation((queue) {
        queue.removeRange(5, 10);
        expect(queue, equals([1, 2, 3, 4, 5, 11, 12, 13, 14, 15]));
      });
    });

    group('removes everything', () {
      forEachInternalRepresentation((queue) {
        queue.removeRange(0, 15);
        expect(queue, isEmpty);
      });
    });

    test('throws a RangeError for an invalid range', () {
      expect(() => Uint8Queue().removeRange(0, 1), throwsRangeError);
    });
  });

  group('setRange()', () {
    group('sets a range to the contents of an iterable', () {
      forEachInternalRepresentation((queue) {
        queue.setRange(5, 10, oneThrough(10).map((n) => 100 + n), 2);
        expect(queue,
            [1, 2, 3, 4, 5, 103, 104, 105, 106, 107, 11, 12, 13, 14, 15]);
      });
    });

    group('sets a range to the contents of a list', () {
      forEachInternalRepresentation((queue) {
        queue.setRange(5, 10, oneThrough(10).map((n) => 100 + n).toList(), 2);
        expect(queue,
            [1, 2, 3, 4, 5, 103, 104, 105, 106, 107, 11, 12, 13, 14, 15]);
      });
    });

    group(
        'sets a range to a section of the same queue overlapping at the beginning',
        () {
      forEachInternalRepresentation((queue) {
        queue.setRange(5, 10, queue, 2);
        expect(queue, [1, 2, 3, 4, 5, 3, 4, 5, 6, 7, 11, 12, 13, 14, 15]);
      });
    });

    group('sets a range to a section of the same queue overlapping at the end',
        () {
      forEachInternalRepresentation((queue) {
        queue.setRange(5, 10, queue, 6);
        expect(queue, [1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 11, 12, 13, 14, 15]);
      });
    });

    test('throws a RangeError for an invalid range', () {
      expect(() => Uint8Queue().setRange(0, 1, [1]), throwsRangeError);
    });
  });

  group('length returns the length', () {
    forEachInternalRepresentation((queue) {
      expect(queue.length, equals(15));
    });
  });

  group('length=', () {
    group('empties', () {
      forEachInternalRepresentation((queue) {
        queue.length = 0;
        expect(queue, isEmpty);
      });
    });

    group('shrinks', () {
      forEachInternalRepresentation((queue) {
        queue.length = 5;
        expect(queue, equals([1, 2, 3, 4, 5]));
      });
    });

    group('grows', () {
      forEachInternalRepresentation((queue) {
        queue.length = 20;
        expect(
            queue,
            equals(oneThrough(capacity - 1) +
                List.filled(20 - (capacity - 1), 0)));
      });
    });

    group('zeroes out existing data', () {
      forEachInternalRepresentation((queue) {
        queue.length = 0;
        queue.length = 15;
        expect(queue, equals([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]));
      });
    });

    test('throws a RangeError if length is less than 0', () {
      expect(() => Uint8Queue().length = -1, throwsRangeError);
    });
  });

  group('[]', () {
    group('returns individual entries', () {
      forEachInternalRepresentation((queue) {
        for (var i = 0; i < capacity - 1; i++) {
          expect(queue[i], equals(i + 1));
        }
      });
    });

    test('throws a RangeError if the index is less than 0', () {
      var queue = Uint8Queue.fromList([1, 2, 3]);
      expect(() => queue[-1], throwsRangeError);
    });

    test(
        'throws a RangeError if the index is greater than or equal to the '
        'length', () {
      var queue = Uint8Queue.fromList([1, 2, 3]);
      expect(() => queue[3], throwsRangeError);
    });
  });

  group('[]=', () {
    group('sets individual entries', () {
      forEachInternalRepresentation((queue) {
        for (var i = 0; i < capacity - 1; i++) {
          queue[i] = 100 + i;
        }
        expect(queue, equals(List.generate(capacity - 1, (i) => 100 + i)));
      });
    });

    test('throws a RangeError if the index is less than 0', () {
      var queue = Uint8Queue.fromList([1, 2, 3]);
      expect(() {
        queue[-1] = 0;
      }, throwsRangeError);
    });

    test(
        'throws a RangeError if the index is greater than or equal to the '
        'length', () {
      var queue = Uint8Queue.fromList([1, 2, 3]);
      expect(() {
        queue[3] = 4;
      }, throwsRangeError);
    });
  });

  group('throws a modification error for', () {
    late Uint8Queue queue;
    setUp(() {
      queue = Uint8Queue.fromList([1, 2, 3]);
    });

    test('add', () {
      expect(() => queue.forEach((_) => queue.add(4)),
          throwsConcurrentModificationError);
    });

    test('addAll', () {
      expect(() => queue.forEach((_) => queue.addAll([4, 5, 6])),
          throwsConcurrentModificationError);
    });

    test('addFirst', () {
      expect(() => queue.forEach((_) => queue.addFirst(0)),
          throwsConcurrentModificationError);
    });

    test('removeFirst', () {
      expect(() => queue.forEach((_) => queue.removeFirst()),
          throwsConcurrentModificationError);
    });

    test('removeLast', () {
      expect(() => queue.forEach((_) => queue.removeLast()),
          throwsConcurrentModificationError);
    });

    test('length=', () {
      expect(() => queue.forEach((_) => queue.length = 1),
          throwsConcurrentModificationError);
    });
  });
}

/// Runs [callback] in multiple tests, all with queues containing numbers from
/// one through 15 in various different internal states.
void forEachInternalRepresentation(void Function(Uint8Queue queue) callback) {
  // Test with a queue whose internal table has plenty of room.
  group("for a queue that's below capacity", () {
    // Test with a queue whose elements are in one contiguous block, so `_head <
    // _tail`.
    test('with contiguous elements', () {
      callback(Uint8Queue(capacity * 2)..addAll(oneThrough(capacity - 1)));
    });

    // Test with a queue whose elements are split across the ends of the table,
    // so `_head > _tail`.
    test('with an internal gap', () {
      var queue = Uint8Queue(capacity * 2);
      for (var i = capacity ~/ 2; i < capacity; i++) {
        queue.add(i);
      }
      for (var i = capacity ~/ 2 - 1; i > 0; i--) {
        queue.addFirst(i);
      }
      callback(queue);
    });
  });

  // Test with a queue whose internal table will need to expand if one more
  // element is added.
  group("for a queue that's at capacity", () {
    test('with contiguous elements', () {
      callback(Uint8Queue()..addAll(oneThrough(capacity - 1)));
    });

    test('with an internal gap', () {
      var queue = Uint8Queue();
      for (var i = capacity ~/ 2; i < capacity; i++) {
        queue.add(i);
      }
      for (var i = capacity ~/ 2 - 1; i > 0; i--) {
        queue.addFirst(i);
      }
      callback(queue);
    });
  });
}

/// Returns a list containing the integers from one through [n].
List<int> oneThrough(int n) => List.generate(n, (i) => i + 1);

/// Returns a matcher that expects that a closure throws a
/// [ConcurrentModificationError].
final throwsConcurrentModificationError =
    throwsA(const TypeMatcher<ConcurrentModificationError>());
