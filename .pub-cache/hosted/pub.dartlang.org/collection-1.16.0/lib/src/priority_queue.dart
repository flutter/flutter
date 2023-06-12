// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'utils.dart';

/// A priority queue is a priority based work-list of elements.
///
/// The queue allows adding elements, and removing them again in priority order.
/// The same object can be added to the queue more than once.
/// There is no specified ordering for objects with the same priority
/// (where the `comparison` function returns zero).
///
/// Operations which care about object equality, [contains] and [remove],
/// use [Object.==] for testing equality.
/// In most situations this will be the same as identity ([identical]),
/// but there are types, like [String], where users can reasonably expect
/// distinct objects to represent the same value.
/// If elements override [Object.==], the `comparison` function must
/// always give equal objects the same priority,
/// otherwise [contains] or [remove] might not work correctly.
abstract class PriorityQueue<E> {
  /// Creates an empty [PriorityQueue].
  ///
  /// The created [PriorityQueue] is a plain [HeapPriorityQueue].
  ///
  /// The [comparison] is a [Comparator] used to compare the priority of
  /// elements. An element that compares as less than another element has
  /// a higher priority.
  ///
  /// If [comparison] is omitted, it defaults to [Comparable.compare]. If this
  /// is the case, `E` must implement [Comparable], and this is checked at
  /// runtime for every comparison.
  factory PriorityQueue([int Function(E, E)? comparison]) =
      HeapPriorityQueue<E>;

  /// Number of elements in the queue.
  int get length;

  /// Whether the queue is empty.
  bool get isEmpty;

  /// Whether the queue has any elements.
  bool get isNotEmpty;

  /// Checks if [object] is in the queue.
  ///
  /// Returns true if the element is found.
  ///
  /// Uses the [Object.==] of elements in the queue to check
  /// for whether they are equal to [object].
  /// Equal objects objects must have the same priority
  /// according to the [comparison] function.
  /// That is, if `a == b` then `comparison(a, b) == 0`.
  /// If that is not the case, this check might fail to find
  /// an object.
  bool contains(E object);

  /// Provides efficient access to all the elements currently in the queue.
  ///
  /// The operation should be performed without copying or moving
  /// the elements, if at all possible.
  ///
  /// The elements are iterated in no particular order.
  /// The order is stable as long as the queue is not modified.
  /// The queue must not be modified during an iteration.
  Iterable<E> get unorderedElements;

  /// Adds element to the queue.
  ///
  /// The element will become the next to be removed by [removeFirst]
  /// when all elements with higher priority have been removed.
  void add(E element);

  /// Adds all [elements] to the queue.
  void addAll(Iterable<E> elements);

  /// Returns the next element that will be returned by [removeFirst].
  ///
  /// The element is not removed from the queue.
  ///
  /// The queue must not be empty when this method is called.
  E get first;

  /// Removes and returns the element with the highest priority.
  ///
  /// Repeatedly calling this method, without adding element in between,
  /// is guaranteed to return elements in non-decreasing order as, specified by
  /// [comparison].
  ///
  /// The queue must not be empty when this method is called.
  E removeFirst();

  /// Removes an element of the queue that compares equal to [element].
  ///
  /// Returns true if an element is found and removed,
  /// and false if no equal element is found.
  ///
  /// If the queue contains more than one object equal to [element],
  /// only one of them is removed.
  ///
  /// Uses the [Object.==] of elements in the queue to check
  /// for whether they are equal to [element].
  /// Equal objects objects must have the same priority
  /// according to the [comparison] function.
  /// That is, if `a == b` then `comparison(a, b) == 0`.
  /// If that is not the case, this check might fail to find
  /// an object.
  bool remove(E element);

  /// Removes all the elements from this queue and returns them.
  ///
  /// The returned iterable has no specified order.
  Iterable<E> removeAll();

  /// Removes all the elements from this queue.
  void clear();

  /// Returns a list of the elements of this queue in priority order.
  ///
  /// The queue is not modified.
  ///
  /// The order is the order that the elements would be in if they were
  /// removed from this queue using [removeFirst].
  List<E> toList();

  /// Returns a list of the elements of this queue in no specific order.
  ///
  /// The queue is not modified.
  ///
  /// The order of the elements is implementation specific.
  /// The order may differ between different calls on the same queue.
  List<E> toUnorderedList();

  /// Return a comparator based set using the comparator of this queue.
  ///
  /// The queue is not modified.
  ///
  /// The returned [Set] is currently a [SplayTreeSet],
  /// but this may change as other ordered sets are implemented.
  ///
  /// The set contains all the elements of this queue.
  /// If an element occurs more than once in the queue,
  /// the set will contain it only once.
  Set<E> toSet();
}

/// Heap based priority queue.
///
/// The elements are kept in a heap structure,
/// where the element with the highest priority is immediately accessible,
/// and modifying a single element takes
/// logarithmic time in the number of elements on average.
///
/// * The [add] and [removeFirst] operations take amortized logarithmic time,
///   O(log(n)), but may occasionally take linear time when growing the capacity
///   of the heap.
/// * The [addAll] operation works as doing repeated [add] operations.
/// * The [first] getter takes constant time, O(1).
/// * The [clear] and [removeAll] methods also take constant time, O(1).
/// * The [contains] and [remove] operations may need to search the entire
///   queue for the elements, taking O(n) time.
/// * The [toList] operation effectively sorts the elements, taking O(n*log(n))
///   time.
/// * The [toUnorderedList] operation copies, but does not sort, the elements,
///   and is linear, O(n).
/// * The [toSet] operation effectively adds each element to the new set, taking
///   an expected O(n*log(n)) time.
class HeapPriorityQueue<E> implements PriorityQueue<E> {
  /// Initial capacity of a queue when created, or when added to after a
  /// [clear].
  ///
  /// Number can be any positive value. Picking a size that gives a whole
  /// number of "tree levels" in the heap is only done for aesthetic reasons.
  static const int _initialCapacity = 7;

  /// The comparison being used to compare the priority of elements.
  final Comparator<E> comparison;

  /// List implementation of a heap.
  List<E?> _queue = List<E?>.filled(_initialCapacity, null);

  /// Number of elements in queue.
  ///
  /// The heap is implemented in the first [_length] entries of [_queue].
  int _length = 0;

  /// Modification count.
  ///
  /// Used to detect concurrent modifications during iteration.
  int _modificationCount = 0;

  /// Create a new priority queue.
  ///
  /// The [comparison] is a [Comparator] used to compare the priority of
  /// elements. An element that compares as less than another element has
  /// a higher priority.
  ///
  /// If [comparison] is omitted, it defaults to [Comparable.compare]. If this
  /// is the case, `E` must implement [Comparable], and this is checked at
  /// runtime for every comparison.
  HeapPriorityQueue([int Function(E, E)? comparison])
      : comparison = comparison ?? defaultCompare;

  E _elementAt(int index) => _queue[index] ?? (null as E);

  @override
  void add(E element) {
    _modificationCount++;
    _add(element);
  }

  @override
  void addAll(Iterable<E> elements) {
    var modified = 0;
    for (var element in elements) {
      modified = 1;
      _add(element);
    }
    _modificationCount += modified;
  }

  @override
  void clear() {
    _modificationCount++;
    _queue = const [];
    _length = 0;
  }

  @override
  bool contains(E object) => _locate(object) >= 0;

  /// Provides efficient access to all the elements currently in the queue.
  ///
  /// The operation is performed in the order they occur
  /// in the underlying heap structure.
  ///
  /// The order is stable as long as the queue is not modified.
  /// The queue must not be modified during an iteration.
  @override
  Iterable<E> get unorderedElements => _UnorderedElementsIterable<E>(this);

  @override
  E get first {
    if (_length == 0) throw StateError('No element');
    return _elementAt(0);
  }

  @override
  bool get isEmpty => _length == 0;

  @override
  bool get isNotEmpty => _length != 0;

  @override
  int get length => _length;

  @override
  bool remove(E element) {
    var index = _locate(element);
    if (index < 0) return false;
    _modificationCount++;
    var last = _removeLast();
    if (index < _length) {
      var comp = comparison(last, element);
      if (comp <= 0) {
        _bubbleUp(last, index);
      } else {
        _bubbleDown(last, index);
      }
    }
    return true;
  }

  /// Removes all the elements from this queue and returns them.
  ///
  /// The returned iterable has no specified order.
  /// The operation does not copy the elements,
  /// but instead keeps them in the existing heap structure,
  /// and iterates over that directly.
  @override
  Iterable<E> removeAll() {
    _modificationCount++;
    var result = _queue;
    var length = _length;
    _queue = const [];
    _length = 0;
    return result.take(length).cast();
  }

  @override
  E removeFirst() {
    if (_length == 0) throw StateError('No element');
    _modificationCount++;
    var result = _elementAt(0);
    var last = _removeLast();
    if (_length > 0) {
      _bubbleDown(last, 0);
    }
    return result;
  }

  @override
  List<E> toList() => _toUnorderedList()..sort(comparison);

  @override
  Set<E> toSet() {
    var set = SplayTreeSet<E>(comparison);
    for (var i = 0; i < _length; i++) {
      set.add(_elementAt(i));
    }
    return set;
  }

  @override
  List<E> toUnorderedList() => _toUnorderedList();

  List<E> _toUnorderedList() =>
      [for (var i = 0; i < _length; i++) _elementAt(i)];

  /// Returns some representation of the queue.
  ///
  /// The format isn't significant, and may change in the future.
  @override
  String toString() {
    return _queue.take(_length).toString();
  }

  /// Add element to the queue.
  ///
  /// Grows the capacity if the backing list is full.
  void _add(E element) {
    if (_length == _queue.length) _grow();
    _bubbleUp(element, _length++);
  }

  /// Find the index of an object in the heap.
  ///
  /// Returns -1 if the object is not found.
  ///
  /// A matching object, `o`, must satisfy that
  /// `comparison(o, object) == 0 && o == object`.
  int _locate(E object) {
    if (_length == 0) return -1;
    // Count positions from one instead of zero. This gives the numbers
    // some nice properties. For example, all right children are odd,
    // their left sibling is even, and the parent is found by shifting
    // right by one.
    // Valid range for position is [1.._length], inclusive.
    var position = 1;
    // Pre-order depth first search, omit child nodes if the current
    // node has lower priority than [object], because all nodes lower
    // in the heap will also have lower priority.
    do {
      var index = position - 1;
      var element = _elementAt(index);
      var comp = comparison(element, object);
      if (comp <= 0) {
        if (comp == 0 && element == object) return index;
        // Element may be in subtree.
        // Continue with the left child, if it is there.
        var leftChildPosition = position * 2;
        if (leftChildPosition <= _length) {
          position = leftChildPosition;
          continue;
        }
      }
      // Find the next right sibling or right ancestor sibling.
      do {
        while (position.isOdd) {
          // While position is a right child, go to the parent.
          position >>= 1;
        }
        // Then go to the right sibling of the left-child.
        position += 1;
      } while (position > _length); // Happens if last element is a left child.
    } while (position != 1); // At root again. Happens for right-most element.
    return -1;
  }

  E _removeLast() {
    var newLength = _length - 1;
    var last = _elementAt(newLength);
    _queue[newLength] = null;
    _length = newLength;
    return last;
  }

  /// Place [element] in heap at [index] or above.
  ///
  /// Put element into the empty cell at `index`.
  /// While the `element` has higher priority than the
  /// parent, swap it with the parent.
  void _bubbleUp(E element, int index) {
    while (index > 0) {
      var parentIndex = (index - 1) ~/ 2;
      var parent = _elementAt(parentIndex);
      if (comparison(element, parent) > 0) break;
      _queue[index] = parent;
      index = parentIndex;
    }
    _queue[index] = element;
  }

  /// Place [element] in heap at [index] or above.
  ///
  /// Put element into the empty cell at `index`.
  /// While the `element` has lower priority than either child,
  /// swap it with the highest priority child.
  void _bubbleDown(E element, int index) {
    var rightChildIndex = index * 2 + 2;
    while (rightChildIndex < _length) {
      var leftChildIndex = rightChildIndex - 1;
      var leftChild = _elementAt(leftChildIndex);
      var rightChild = _elementAt(rightChildIndex);
      var comp = comparison(leftChild, rightChild);
      int minChildIndex;
      E minChild;
      if (comp < 0) {
        minChild = leftChild;
        minChildIndex = leftChildIndex;
      } else {
        minChild = rightChild;
        minChildIndex = rightChildIndex;
      }
      comp = comparison(element, minChild);
      if (comp <= 0) {
        _queue[index] = element;
        return;
      }
      _queue[index] = minChild;
      index = minChildIndex;
      rightChildIndex = index * 2 + 2;
    }
    var leftChildIndex = rightChildIndex - 1;
    if (leftChildIndex < _length) {
      var child = _elementAt(leftChildIndex);
      var comp = comparison(element, child);
      if (comp > 0) {
        _queue[index] = child;
        index = leftChildIndex;
      }
    }
    _queue[index] = element;
  }

  /// Grows the capacity of the list holding the heap.
  ///
  /// Called when the list is full.
  void _grow() {
    var newCapacity = _queue.length * 2 + 1;
    if (newCapacity < _initialCapacity) newCapacity = _initialCapacity;
    var newQueue = List<E?>.filled(newCapacity, null);
    newQueue.setRange(0, _length, _queue);
    _queue = newQueue;
  }
}

/// Implementation of [HeapPriorityQueue.unorderedElements].
class _UnorderedElementsIterable<E> extends Iterable<E> {
  final HeapPriorityQueue<E> _queue;
  _UnorderedElementsIterable(this._queue);
  @override
  Iterator<E> get iterator => _UnorderedElementsIterator<E>(_queue);
}

class _UnorderedElementsIterator<E> implements Iterator<E> {
  final HeapPriorityQueue<E> _queue;
  final int _initialModificationCount;
  E? _current;
  int _index = -1;

  _UnorderedElementsIterator(this._queue)
      : _initialModificationCount = _queue._modificationCount;

  @override
  bool moveNext() {
    if (_initialModificationCount != _queue._modificationCount) {
      throw ConcurrentModificationError(_queue);
    }
    var nextIndex = _index + 1;
    if (0 <= nextIndex && nextIndex < _queue.length) {
      _current = _queue._queue[nextIndex];
      _index = nextIndex;
      return true;
    }
    _current = null;
    _index = -2;
    return false;
  }

  @override
  E get current =>
      _index < 0 ? throw StateError('No element') : (_current ?? null as E);
}
