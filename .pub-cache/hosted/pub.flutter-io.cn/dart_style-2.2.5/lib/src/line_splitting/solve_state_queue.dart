// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'line_splitter.dart';
import 'solve_state.dart';

/// A priority queue of [SolveStates] to consider while line splitting.
///
/// This is based on the [HeapPriorityQueue] class from the "collection"
/// package, but is modified to handle the "overlap" logic that allows one
/// [SolveState] to supercede another.
///
/// States are stored internally in a heap ordered by cost, the number of
/// overflow characters. When a new state is added to the heap, it will be
/// discarded, or a previously enqueued one will be discarded, if two overlap.
class SolveStateQueue {
  /// Initial capacity of a queue when created, or when added to after a [clear].
  /// Number can be any positive value. Picking a size that gives a whole
  /// number of "tree levels" in the heap is only done for aesthetic reasons.
  static const int _initialCapacity = 7;

  late final LineSplitter _splitter;

  /// List implementation of a heap.
  List<SolveState?> _queue = List.filled(_initialCapacity, null);

  /// Number of elements in queue.
  /// The heap is implemented in the first [_length] entries of [_queue].
  int _length = 0;

  bool get isNotEmpty => _length != 0;

  void bindSplitter(LineSplitter splitter) {
    _splitter = splitter;
  }

  /// Add [state] to the queue.
  ///
  /// Grows the capacity if the backing list is full.
  void add(SolveState state) {
    if (_tryOverlap(state)) return;

    if (_length == _queue.length) {
      var newCapacity = _queue.length * 2 + 1;
      if (newCapacity < _initialCapacity) newCapacity = _initialCapacity;

      var newQueue = List<SolveState?>.filled(newCapacity, null);
      newQueue.setRange(0, _length, _queue);
      _queue = newQueue;
    }

    _bubbleUp(state, _length++);
  }

  SolveState removeFirst() {
    assert(_length > 0);

    // Remove the highest priority state.
    var result = _queue[0]!;
    _length--;

    // Fill the gap with the one at the end of the list and re-heapify.
    if (_length > 0) {
      var last = _queue[_length]!;
      _queue[_length] = null;
      _bubbleDown(last, 0);
    }

    return result;
  }

  /// Orders this state relative to [other].
  ///
  /// This is a best-first ordering that prefers cheaper states even if they
  /// overflow because this ensures it finds the best solution first as soon as
  /// it finds one that fits in the page so it can early out.
  int _compare(SolveState a, SolveState b) {
    // TODO(rnystrom): It may be worth sorting by the estimated lowest number
    // of overflow characters first. That doesn't help in cases where there is
    // a solution that fits, but may help in corner cases where there is no
    // fitting solution.

    var comparison = _compareScore(a, b);
    if (comparison != 0) return comparison;

    return _compareRules(a, b);
  }

  /// Compares the overflow and cost of [a] to [b].
  int _compareScore(SolveState a, SolveState b) {
    if (a.splits.cost != b.splits.cost) {
      return a.splits.cost.compareTo(b.splits.cost);
    }

    return a.overflowChars.compareTo(b.overflowChars);
  }

  /// Distinguish states based on the rule values just so that states with the
  /// same cost range but different rule values don't get considered identical
  /// and inadvertantly merged.
  int _compareRules(SolveState a, SolveState b) {
    for (var rule in _splitter.rules) {
      var aValue = a.getValue(rule);
      var bValue = b.getValue(rule);

      if (aValue != bValue) return aValue.compareTo(bValue);
    }

    // The way SolveStates are expanded should guarantee that we never generate
    // the exact same state twice. Getting here implies that that failed.
    throw 'unreachable';
  }

  /// Determines if any already enqueued state overlaps [state].
  ///
  /// If so, chooses the best and discards the other. Returns `true` in this
  /// case. Otherwise, returns `false`.
  bool _tryOverlap(SolveState state) {
    if (_length == 0) return false;

    // Count positions from one instead of zero. This gives the numbers some
    // nice properties. For example, all right children are odd, their left
    // sibling is even, and the parent is found by shifting right by one.
    // Valid range for position is [1.._length], inclusive.
    var position = 1;

    // Pre-order depth first search, omit child nodes if the current node has
    // lower priority than [object], because all nodes lower in the heap will
    // also have lower priority.
    do {
      var index = position - 1;
      var enqueued = _queue[index]!;

      var comparison = _compareScore(enqueued, state);

      if (comparison == 0) {
        var overlap = enqueued.compareOverlap(state);
        if (overlap < 0) {
          // The old state is better, so just discard the new one.
          return true;
        } else if (overlap > 0) {
          // The new state is better than the enqueued one, so replace it.
          _queue[index] = state;
          return true;
        } else {
          // We can't merge them, so sort by their bound rule values.
          comparison = _compareRules(enqueued, state);
        }
      }

      if (comparison < 0) {
        // Element may be in subtree. Continue with the left child, if any.
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

        // Then go to the right sibling of the left child.
        position += 1;
      } while (position > _length); // Happens if last element is a left child.
    } while (position != 1); // At root again. Happens for right-most element.

    return false;
  }

  /// Place [element] in heap at [index] or above.
  ///
  /// Put element into the empty cell at `index`. While the `element` has
  /// higher priority than the parent, swap it with the parent.
  void _bubbleUp(SolveState element, int index) {
    while (index > 0) {
      var parentIndex = (index - 1) ~/ 2;
      var parent = _queue[parentIndex]!;

      if (_compare(element, parent) > 0) break;

      _queue[index] = parent;
      index = parentIndex;
    }

    _queue[index] = element;
  }

  /// Place [element] in heap at [index] or above.
  ///
  /// Put element into the empty cell at `index`. While the `element` has lower
  /// priority than either child, swap it with the highest priority child.
  void _bubbleDown(SolveState element, int index) {
    var rightChildIndex = index * 2 + 2;

    while (rightChildIndex < _length) {
      var leftChildIndex = rightChildIndex - 1;
      var leftChild = _queue[leftChildIndex]!;
      var rightChild = _queue[rightChildIndex]!;

      var comparison = _compare(leftChild, rightChild);
      int minChildIndex;
      SolveState minChild;

      if (comparison < 0) {
        minChild = leftChild;
        minChildIndex = leftChildIndex;
      } else {
        minChild = rightChild;
        minChildIndex = rightChildIndex;
      }

      comparison = _compare(element, minChild);

      if (comparison <= 0) {
        _queue[index] = element;
        return;
      }

      _queue[index] = minChild;
      index = minChildIndex;
      rightChildIndex = index * 2 + 2;
    }

    var leftChildIndex = rightChildIndex - 1;
    if (leftChildIndex < _length) {
      var child = _queue[leftChildIndex]!;
      var comparison = _compare(element, child);

      if (comparison > 0) {
        _queue[index] = child;
        index = leftChildIndex;
      }
    }

    _queue[index] = element;
  }
}
