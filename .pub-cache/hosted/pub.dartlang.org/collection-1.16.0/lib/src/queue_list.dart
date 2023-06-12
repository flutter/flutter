// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

/// A class that efficiently implements both [Queue] and [List].
// TODO(nweiz): Currently this code is copied almost verbatim from
// dart:collection. The only changes are to implement List and to remove methods
// that are redundant with ListMixin. Remove or simplify it when issue 21330 is
// fixed.
class QueueList<E> extends Object with ListMixin<E> implements Queue<E> {
  /// Adapts [source] to be a `QueueList<T>`.
  ///
  /// Any time the class would produce an element that is not a [T], the element
  /// access will throw.
  ///
  /// Any time a [T] value is attempted stored into the adapted class, the store
  /// will throw unless the value is also an instance of [S].
  ///
  /// If all accessed elements of [source] are actually instances of [T] and if
  /// all elements stored in the returned  are actually instance of [S],
  /// then the returned instance can be used as a `QueueList<T>`.
  static QueueList<T> _castFrom<S, T>(QueueList<S> source) {
    return _CastQueueList<S, T>(source);
  }

  /// Default and minimal initial capacity of the queue-list.
  static const int _initialCapacity = 8;
  List<E?> _table;
  int _head;
  int _tail;

  /// Creates an empty queue.
  ///
  /// If [initialCapacity] is given, prepare the queue for at least that many
  /// elements.
  QueueList([int? initialCapacity])
      : this._init(_computeInitialCapacity(initialCapacity));

  /// Creates an empty queue with the specific initial capacity.
  QueueList._init(int initialCapacity)
      : assert(_isPowerOf2(initialCapacity)),
        _table = List<E?>.filled(initialCapacity, null),
        _head = 0,
        _tail = 0;

  /// An internal constructor for use by [_CastQueueList].
  QueueList._(this._head, this._tail, this._table);

  /// Create a queue initially containing the elements of [source].
  factory QueueList.from(Iterable<E> source) {
    if (source is List) {
      var length = source.length;
      var queue = QueueList<E>(length + 1);
      assert(queue._table.length > length);
      var sourceList = source;
      queue._table.setRange(0, length, sourceList, 0);
      queue._tail = length;
      return queue;
    } else {
      return QueueList<E>()..addAll(source);
    }
  }

  /// Computes the actual initial capacity based on the constructor parameter.
  static int _computeInitialCapacity(int? initialCapacity) {
    if (initialCapacity == null || initialCapacity < _initialCapacity) {
      return _initialCapacity;
    }
    initialCapacity += 1;
    if (_isPowerOf2(initialCapacity)) {
      return initialCapacity;
    }
    return _nextPowerOf2(initialCapacity);
  }

  // Collection interface.

  @override
  void add(E element) {
    _add(element);
  }

  @override
  void addAll(Iterable<E> iterable) {
    if (iterable is List) {
      var list = iterable;
      var addCount = list.length;
      var length = this.length;
      if (length + addCount >= _table.length) {
        _preGrow(length + addCount);
        // After preGrow, all elements are at the start of the list.
        _table.setRange(length, length + addCount, list, 0);
        _tail += addCount;
      } else {
        // Adding addCount elements won't reach _head.
        var endSpace = _table.length - _tail;
        if (addCount < endSpace) {
          _table.setRange(_tail, _tail + addCount, list, 0);
          _tail += addCount;
        } else {
          var preSpace = addCount - endSpace;
          _table.setRange(_tail, _tail + endSpace, list, 0);
          _table.setRange(0, preSpace, list, endSpace);
          _tail = preSpace;
        }
      }
    } else {
      for (var element in iterable) {
        _add(element);
      }
    }
  }

  QueueList<T> cast<T>() => QueueList._castFrom<E, T>(this);

  @Deprecated("Use cast instead")
  QueueList<T> retype<T>() => cast<T>();

  @override
  String toString() => IterableBase.iterableToFullString(this, '{', '}');

  // Queue interface.

  @override
  void addLast(E element) {
    _add(element);
  }

  @override
  void addFirst(E element) {
    _head = (_head - 1) & (_table.length - 1);
    _table[_head] = element;
    if (_head == _tail) _grow();
  }

  @override
  E removeFirst() {
    if (_head == _tail) throw StateError('No element');
    var result = _table[_head] as E;
    _table[_head] = null;
    _head = (_head + 1) & (_table.length - 1);
    return result;
  }

  @override
  E removeLast() {
    if (_head == _tail) throw StateError('No element');
    _tail = (_tail - 1) & (_table.length - 1);
    var result = _table[_tail] as E;
    _table[_tail] = null;
    return result;
  }

  // List interface.

  @override
  int get length => (_tail - _head) & (_table.length - 1);

  @override
  set length(int value) {
    if (value < 0) throw RangeError('Length $value may not be negative.');
    if (value > length && null is! E) {
      throw UnsupportedError(
          'The length can only be increased when the element type is '
          'nullable, but the current element type is `$E`.');
    }

    var delta = value - length;
    if (delta >= 0) {
      if (_table.length <= value) {
        _preGrow(value);
      }
      _tail = (_tail + delta) & (_table.length - 1);
      return;
    }

    var newTail = _tail + delta; // [delta] is negative.
    if (newTail >= 0) {
      _table.fillRange(newTail, _tail, null);
    } else {
      newTail += _table.length;
      _table.fillRange(0, _tail, null);
      _table.fillRange(newTail, _table.length, null);
    }
    _tail = newTail;
  }

  @override
  E operator [](int index) {
    if (index < 0 || index >= length) {
      throw RangeError('Index $index must be in the range [0..$length).');
    }

    return _table[(_head + index) & (_table.length - 1)] as E;
  }

  @override
  void operator []=(int index, E value) {
    if (index < 0 || index >= length) {
      throw RangeError('Index $index must be in the range [0..$length).');
    }

    _table[(_head + index) & (_table.length - 1)] = value;
  }

  // Internal helper functions.

  /// Whether [number] is a power of two.
  ///
  /// Only works for positive numbers.
  static bool _isPowerOf2(int number) => (number & (number - 1)) == 0;

  /// Rounds [number] up to the nearest power of 2.
  ///
  /// If [number] is a power of 2 already, it is returned.
  ///
  /// Only works for positive numbers.
  static int _nextPowerOf2(int number) {
    assert(number > 0);
    number = (number << 1) - 1;
    for (;;) {
      var nextNumber = number & (number - 1);
      if (nextNumber == 0) return number;
      number = nextNumber;
    }
  }

  /// Adds element at end of queue. Used by both [add] and [addAll].
  void _add(E element) {
    _table[_tail] = element;
    _tail = (_tail + 1) & (_table.length - 1);
    if (_head == _tail) _grow();
  }

  /// Grow the table when full.
  void _grow() {
    var newTable = List<E?>.filled(_table.length * 2, null);
    var split = _table.length - _head;
    newTable.setRange(0, split, _table, _head);
    newTable.setRange(split, split + _head, _table, 0);
    _head = 0;
    _tail = _table.length;
    _table = newTable;
  }

  int _writeToList(List<E?> target) {
    assert(target.length >= length);
    if (_head <= _tail) {
      var length = _tail - _head;
      target.setRange(0, length, _table, _head);
      return length;
    } else {
      var firstPartSize = _table.length - _head;
      target.setRange(0, firstPartSize, _table, _head);
      target.setRange(firstPartSize, firstPartSize + _tail, _table, 0);
      return _tail + firstPartSize;
    }
  }

  /// Grows the table even if it is not full.
  void _preGrow(int newElementCount) {
    assert(newElementCount >= length);

    // Add 1.5x extra room to ensure that there's room for more elements after
    // expansion.
    newElementCount += newElementCount >> 1;
    var newCapacity = _nextPowerOf2(newElementCount);
    var newTable = List<E?>.filled(newCapacity, null);
    _tail = _writeToList(newTable);
    _table = newTable;
    _head = 0;
  }
}

class _CastQueueList<S, T> extends QueueList<T> {
  final QueueList<S> _delegate;

  // Assigns invalid values for head/tail because it uses the delegate to hold
  // the real values, but they are non-null fields.
  _CastQueueList(this._delegate) : super._(-1, -1, _delegate._table.cast<T>());

  @override
  int get _head => _delegate._head;

  @override
  set _head(int value) => _delegate._head = value;

  @override
  int get _tail => _delegate._tail;

  @override
  set _tail(int value) => _delegate._tail = value;
}
