// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:typed_data';

import 'package:collection/collection.dart';

import 'typed_buffer.dart';

/// The shared superclass of all the typed queue subclasses.
abstract class _TypedQueue<E, L extends List<E>> with ListMixin<E> {
  /// The underlying data buffer.
  ///
  /// This is always both a List<E> and a TypedData, which we don't have a type
  /// for that. For example, for a `Uint8Queue`, this is a `Uint8List`.
  L _table;

  int _head;
  int _tail;

  /// Create an empty queue.
  _TypedQueue(List<E> table)
      : _table = table as L,
        _head = 0,
        _tail = 0;

  // Iterable interface.

  @override
  int get length => (_tail - _head) & (_table.length - 1);

  @override
  List<E> toList({bool growable = true}) {
    var list = growable ? _createBuffer(length) : _createList(length);
    _writeToList(list);
    return list;
  }

  @override
  QueueList<T> cast<T>() {
    if (this is QueueList<T>) return this as QueueList<T>;
    throw UnsupportedError('$this cannot be cast to the desired type.');
  }

  @Deprecated('Use `cast` instead')
  QueueList<T> retype<T>() => cast<T>();

  // Queue interface.

  void addLast(E value) {
    _table[_tail] = value;
    _tail = (_tail + 1) & (_table.length - 1);
    if (_head == _tail) _growAtCapacity();
  }

  void addFirst(E value) {
    _head = (_head - 1) & (_table.length - 1);
    _table[_head] = value;
    if (_head == _tail) _growAtCapacity();
  }

  E removeFirst() {
    if (_head == _tail) throw StateError('No element');
    var result = _table[_head];
    _head = (_head + 1) & (_table.length - 1);
    return result;
  }

  @override
  E removeLast() {
    if (_head == _tail) throw StateError('No element');
    _tail = (_tail - 1) & (_table.length - 1);
    return _table[_tail];
  }

  // List interface.

  @override
  void add(E value) => addLast(value);

  @override
  set length(int value) {
    RangeError.checkNotNegative(value, 'length');

    var delta = value - length;
    if (delta >= 0) {
      var needsToGrow = _table.length <= value;
      if (needsToGrow) _growTo(value);
      _tail = (_tail + delta) & (_table.length - 1);

      // If we didn't copy into a new table, make sure that we overwrite the
      // existing data so that users don't accidentally depend on it still
      // existing.
      if (!needsToGrow) fillRange(value - delta, value, _defaultValue);
    } else {
      removeRange(value, length);
    }
  }

  @override
  E operator [](int index) {
    RangeError.checkValidIndex(index, this, null, length);
    return _table[(_head + index) & (_table.length - 1)];
  }

  @override
  void operator []=(int index, E value) {
    RangeError.checkValidIndex(index, this);
    _table[(_head + index) & (_table.length - 1)] = value;
  }

  @override
  void removeRange(int start, int end) {
    var length = this.length;
    RangeError.checkValidRange(start, end, length);

    // Special-case removing an initial or final range because we can do it very
    // efficiently by adjusting `_head` or `_tail`.
    if (start == 0) {
      _head = (_head + end) & (_table.length - 1);
      return;
    }

    var elementsAfter = length - end;
    if (elementsAfter == 0) {
      _tail = (_head + start) & (_table.length - 1);
      return;
    }

    // Choose whether to copy from the beginning of the end of the queue based
    // on which will require fewer copied elements.
    var removedElements = end - start;
    if (start < elementsAfter) {
      setRange(removedElements, end, this);
      _head = (_head + removedElements) & (_table.length - 1);
    } else {
      setRange(start, length - removedElements, this, end);
      _tail = (_tail - removedElements) & (_table.length - 1);
    }
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, length);
    if (start == end) return;

    var targetStart = (_head + start) & (_table.length - 1);
    var targetEnd = (_head + end) & (_table.length - 1);
    var targetIsContiguous = targetStart < targetEnd;
    if (identical(iterable, this)) {
      // If we're copying this queue to itself, we can copy [_table] in directly
      // which requires some annoying case analysis but in return bottoms out on
      // an extremely efficient `memmove` call. However, we may need to do three
      // copies to avoid overwriting data we'll need to use later.
      var sourceStart = (_head + skipCount) & (_table.length - 1);
      var sourceEnd = (sourceStart + (end - start)) & (_table.length - 1);
      if (sourceStart == targetStart) return;

      var sourceIsContiguous = sourceStart < sourceEnd;
      if (targetIsContiguous && sourceIsContiguous) {
        // If both the source and destination ranges are contiguous, we can
        // do a single [setRange]. Hooray!
        _table.setRange(targetStart, targetEnd, _table, sourceStart);
      } else if (!targetIsContiguous && !sourceIsContiguous) {
        // If neither range is contiguous, we need to do three copies.
        if (sourceStart > targetStart) {
          // [=====| targetEnd                 targetStart |======]
          // [========| sourceEnd                 sourceStart |===]

          // Copy front to back.
          var startGap = sourceStart - targetStart;
          var firstEnd = _table.length - startGap;
          _table.setRange(targetStart, firstEnd, _table, sourceStart);
          _table.setRange(firstEnd, _table.length, _table);
          _table.setRange(0, targetEnd, _table, startGap);
        } else if (sourceEnd < targetEnd) {
          // [=====| targetEnd                 targetStart |======]
          // [==| sourceEnd                 sourceStart |=========]

          // Copy back to front.
          var firstStart = targetEnd - sourceEnd;
          _table.setRange(firstStart, targetEnd, _table);
          _table.setRange(0, firstStart, _table, _table.length - firstStart);
          _table.setRange(targetStart, _table.length, _table, sourceStart);
        }
      } else if (sourceStart < targetEnd) {
        // Copying twice is safe here as long as we copy front to back.
        if (sourceIsContiguous) {
          //       [=====| targetEnd            targetStart |======]
          //       [  |===========| sourceEnd                      ]
          // sourceStart
          _table.setRange(targetStart, _table.length, _table, sourceStart);
          _table.setRange(0, targetEnd, _table,
              sourceStart + (_table.length - targetStart));
        } else {
          //                                               targetEnd
          // [                         targetStart |===========|  ]
          // [=====| sourceEnd                 sourceStart |======]
          var firstEnd = _table.length - sourceStart;
          _table.setRange(targetStart, firstEnd, _table, sourceStart);
          _table.setRange(firstEnd, targetEnd, _table);
        }
      } else {
        // Copying twice is safe here as long as we copy back to front. This
        // also covers the case where there's no overlap between the source and
        // target ranges, in which case the direction doesn't matter.
        if (sourceIsContiguous) {
          // [=====| targetEnd                 targetStart |======]
          // [                         sourceStart |===========|  ]
          //                                             sourceEnd
          _table.setRange(0, targetEnd, _table,
              sourceStart + (_table.length - targetStart));
          _table.setRange(targetStart, _table.length, _table, sourceStart);
        } else {
          // targetStart
          //       [  |===========| targetEnd                      ]
          //       [=====| sourceEnd            sourceStart |======]
          var firstStart = targetEnd - sourceEnd;
          _table.setRange(firstStart, targetEnd, _table);
          _table.setRange(targetStart, firstStart, _table, sourceStart);
        }
      }
    } else if (targetIsContiguous) {
      // If the range is contiguous within the table, we can set it with a single
      // underlying [setRange] call.
      _table.setRange(targetStart, targetEnd, iterable, skipCount);
    } else if (iterable is List<E>) {
      // If the range isn't contiguous and [iterable] is actually a [List] (but
      // not this queue), set it with two underlying [setRange] calls.
      _table.setRange(targetStart, _table.length, iterable, skipCount);
      _table.setRange(
          0, targetEnd, iterable, skipCount + (_table.length - targetStart));
    } else {
      // If [iterable] isn't a [List], we don't want to make two different
      // [setRange] calls because it could materialize a lazy iterable twice.
      // Instead we just fall back to the default iteration-based
      // implementation.
      super.setRange(start, end, iterable, skipCount);
    }
  }

  @override
  void fillRange(int start, int end, [E? value]) {
    var startInTable = (_head + start) & (_table.length - 1);
    var endInTable = (_head + end) & (_table.length - 1);
    if (startInTable <= endInTable) {
      _table.fillRange(startInTable, endInTable, value);
    } else {
      _table.fillRange(startInTable, _table.length, value);
      _table.fillRange(0, endInTable, value);
    }
  }

  @override
  L sublist(int start, [int? end]) {
    var length = this.length;
    var nonNullEnd = RangeError.checkValidRange(start, end, length);

    var list = _createList(nonNullEnd - start);
    _writeToList(list, start, nonNullEnd);
    return list;
  }

  // Internal helper functions.

  /// Writes the contents of `this` between [start] (which defaults to 0) and
  /// [end] (which defaults to [length]) to the beginning of [target].
  ///
  /// This is functionally identical to `target.setRange(0, end - start, this,
  /// start)`, but it's more efficient when [target] is typed data.
  ///
  /// Returns the number of elements written to [target].
  int _writeToList(List<E> target, [int? start, int? end]) {
    start ??= 0;
    end ??= length;
    assert(target.length >= end - start);
    assert(start <= end);

    var elementsToWrite = end - start;
    var startInTable = (_head + start) & (_table.length - 1);
    var endInTable = (_head + end) & (_table.length - 1);
    if (startInTable <= endInTable) {
      target.setRange(0, elementsToWrite, _table, startInTable);
    } else {
      var firstPartSize = _table.length - startInTable;
      target.setRange(0, firstPartSize, _table, startInTable);
      target.setRange(firstPartSize, firstPartSize + endInTable, _table, 0);
    }
    return elementsToWrite;
  }

  /// Assumes the table is currently full to capacity, and grows it to the next
  /// power of two.
  void _growAtCapacity() {
    assert(_head == _tail);

    var newTable = _createList(_table.length * 2);

    // We can't use [_writeToList] here because when `_head == _tail` it thinks
    // the queue is empty rather than full.
    var partitionPoint = _table.length - _head;
    newTable.setRange(0, partitionPoint, _table, _head);
    if (partitionPoint != _table.length) {
      newTable.setRange(partitionPoint, _table.length, _table);
    }
    _head = 0;
    _tail = _table.length;
    _table = newTable;
  }

  /// Grows the tableso it's at least large enough size to include that many
  /// elements.
  void _growTo(int newElementCount) {
    assert(newElementCount >= length);

    // Add some extra room to ensure that there's room for more elements after
    // expansion.
    newElementCount += newElementCount >> 1;
    var newTable = _createList(_nextPowerOf2(newElementCount));
    _tail = _writeToList(newTable);
    _table = newTable;
    _head = 0;
  }

  // Specialization for the specific type.

  // Create a new typed list.
  L _createList(int size);

  // Create a new typed buffer of the given type.
  List<E> _createBuffer(int size);

  /// The default value used to fill the queue when changing length.
  E get _defaultValue;
}

abstract class _IntQueue<L extends List<int>> extends _TypedQueue<int, L> {
  _IntQueue(L queue) : super(queue);

  @override
  int get _defaultValue => 0;
}

abstract class _FloatQueue<L extends List<double>>
    extends _TypedQueue<double, L> {
  _FloatQueue(L queue) : super(queue);

  @override
  double get _defaultValue => 0.0;
}

/// A [QueueList] that efficiently stores 8-bit unsigned integers.
///
/// For long queues, this implementation can be considerably more space- and
/// time-efficient than a default [QueueList] implementation.
///
/// Integers stored in this are truncated to their low eight bits, interpreted
/// as an unsigned 8-bit integer with values in the range 0 to 255.
class Uint8Queue extends _IntQueue<Uint8List> implements QueueList<int> {
  /// Creates an empty [Uint8Queue] with the given initial internal capacity (in
  /// elements).
  Uint8Queue([int? initialCapacity])
      : super(Uint8List(_chooseRealInitialCapacity(initialCapacity)));

  /// Creates a [Uint8Queue] with the same length and contents as [elements].
  factory Uint8Queue.fromList(List<int> elements) =>
      Uint8Queue(elements.length)..addAll(elements);

  @override
  Uint8List _createList(int size) => Uint8List(size);
  @override
  Uint8Buffer _createBuffer(int size) => Uint8Buffer(size);
}

/// A [QueueList] that efficiently stores 8-bit signed integers.
///
/// For long queues, this implementation can be considerably more space- and
/// time-efficient than a default [QueueList] implementation.
///
/// Integers stored in this are truncated to their low eight bits, interpreted
/// as a signed 8-bit two's complement integer with values in the range -128 to
/// +127.
class Int8Queue extends _IntQueue<Int8List> implements QueueList<int> {
  /// Creates an empty [Int8Queue] with the given initial internal capacity (in
  /// elements).
  Int8Queue([int? initialCapacity])
      : super(Int8List(_chooseRealInitialCapacity(initialCapacity)));

  /// Creates a [Int8Queue] with the same length and contents as [elements].
  factory Int8Queue.fromList(List<int> elements) =>
      Int8Queue(elements.length)..addAll(elements);

  @override
  Int8List _createList(int size) => Int8List(size);
  @override
  Int8Buffer _createBuffer(int size) => Int8Buffer(size);
}

/// A [QueueList] that efficiently stores 8-bit unsigned integers.
///
/// For long queues, this implementation can be considerably more space- and
/// time-efficient than a default [QueueList] implementation.
///
/// Integers stored in this are clamped to an unsigned eight bit value. That is,
/// all values below zero are stored as zero and all values above 255 are stored
/// as 255.
class Uint8ClampedQueue extends _IntQueue<Uint8ClampedList>
    implements QueueList<int> {
  /// Creates an empty [Uint8ClampedQueue] with the given initial internal
  /// capacity (in elements).
  Uint8ClampedQueue([int? initialCapacity])
      : super(Uint8ClampedList(_chooseRealInitialCapacity(initialCapacity)));

  /// Creates a [Uint8ClampedQueue] with the same length and contents as
  /// [elements].
  factory Uint8ClampedQueue.fromList(List<int> elements) =>
      Uint8ClampedQueue(elements.length)..addAll(elements);

  @override
  Uint8ClampedList _createList(int size) => Uint8ClampedList(size);
  @override
  Uint8ClampedBuffer _createBuffer(int size) => Uint8ClampedBuffer(size);
}

/// A [QueueList] that efficiently stores 16-bit unsigned integers.
///
/// For long queues, this implementation can be considerably more space- and
/// time-efficient than a default [QueueList] implementation.
///
/// Integers stored in this are truncated to their low 16 bits, interpreted as
/// an unsigned 16-bit integer with values in the range 0 to 65535.
class Uint16Queue extends _IntQueue<Uint16List> implements QueueList<int> {
  /// Creates an empty [Uint16Queue] with the given initial internal capacity
  /// (in elements).
  Uint16Queue([int? initialCapacity])
      : super(Uint16List(_chooseRealInitialCapacity(initialCapacity)));

  /// Creates a [Uint16Queue] with the same length and contents as [elements].
  factory Uint16Queue.fromList(List<int> elements) =>
      Uint16Queue(elements.length)..addAll(elements);

  @override
  Uint16List _createList(int size) => Uint16List(size);
  @override
  Uint16Buffer _createBuffer(int size) => Uint16Buffer(size);
}

/// A [QueueList] that efficiently stores 16-bit signed integers.
///
/// For long queues, this implementation can be considerably more space- and
/// time-efficient than a default [QueueList] implementation.
///
/// Integers stored in this are truncated to their low 16 bits, interpreted as a
/// signed 16-bit two's complement integer with values in the range -32768 to
/// +32767.
class Int16Queue extends _IntQueue<Int16List> implements QueueList<int> {
  /// Creates an empty [Int16Queue] with the given initial internal capacity (in
  /// elements).
  Int16Queue([int? initialCapacity])
      : super(Int16List(_chooseRealInitialCapacity(initialCapacity)));

  /// Creates a [Int16Queue] with the same length and contents as [elements].
  factory Int16Queue.fromList(List<int> elements) =>
      Int16Queue(elements.length)..addAll(elements);

  @override
  Int16List _createList(int size) => Int16List(size);
  @override
  Int16Buffer _createBuffer(int size) => Int16Buffer(size);
}

/// A [QueueList] that efficiently stores 32-bit unsigned integers.
///
/// For long queues, this implementation can be considerably more space- and
/// time-efficient than a default [QueueList] implementation.
///
/// Integers stored in this are truncated to their low 32 bits, interpreted as
/// an unsigned 32-bit integer with values in the range 0 to 4294967295.
class Uint32Queue extends _IntQueue<Uint32List> implements QueueList<int> {
  /// Creates an empty [Uint32Queue] with the given initial internal capacity
  /// (in elements).
  Uint32Queue([int? initialCapacity])
      : super(Uint32List(_chooseRealInitialCapacity(initialCapacity)));

  /// Creates a [Uint32Queue] with the same length and contents as [elements].
  factory Uint32Queue.fromList(List<int> elements) =>
      Uint32Queue(elements.length)..addAll(elements);

  @override
  Uint32List _createList(int size) => Uint32List(size);
  @override
  Uint32Buffer _createBuffer(int size) => Uint32Buffer(size);
}

/// A [QueueList] that efficiently stores 32-bit signed integers.
///
/// For long queues, this implementation can be considerably more space- and
/// time-efficient than a default [QueueList] implementation.
///
/// Integers stored in this are truncated to their low 32 bits, interpreted as a
/// signed 32-bit two's complement integer with values in the range -2147483648
/// to 2147483647.
class Int32Queue extends _IntQueue<Int32List> implements QueueList<int> {
  /// Creates an empty [Int32Queue] with the given initial internal capacity (in
  /// elements).
  Int32Queue([int? initialCapacity])
      : super(Int32List(_chooseRealInitialCapacity(initialCapacity)));

  /// Creates a [Int32Queue] with the same length and contents as [elements].
  factory Int32Queue.fromList(List<int> elements) =>
      Int32Queue(elements.length)..addAll(elements);

  @override
  Int32List _createList(int size) => Int32List(size);
  @override
  Int32Buffer _createBuffer(int size) => Int32Buffer(size);
}

/// A [QueueList] that efficiently stores 64-bit unsigned integers.
///
/// For long queues, this implementation can be considerably more space- and
/// time-efficient than a default [QueueList] implementation.
///
/// Integers stored in this are truncated to their low 64 bits, interpreted as
/// an unsigned 64-bit integer with values in the range 0 to
/// 18446744073709551615.
class Uint64Queue extends _IntQueue<Uint64List> implements QueueList<int> {
  /// Creates an empty [Uint64Queue] with the given initial internal capacity
  /// (in elements).
  Uint64Queue([int? initialCapacity])
      : super(Uint64List(_chooseRealInitialCapacity(initialCapacity)));

  /// Creates a [Uint64Queue] with the same length and contents as [elements].
  factory Uint64Queue.fromList(List<int> elements) =>
      Uint64Queue(elements.length)..addAll(elements);

  @override
  Uint64List _createList(int size) => Uint64List(size);
  @override
  Uint64Buffer _createBuffer(int size) => Uint64Buffer(size);
}

/// A [QueueList] that efficiently stores 64-bit signed integers.
///
/// For long queues, this implementation can be considerably more space- and
/// time-efficient than a default [QueueList] implementation.
///
/// Integers stored in this are truncated to their low 64 bits, interpreted as a
/// signed 64-bit two's complement integer with values in the range
/// -9223372036854775808 to +9223372036854775807.
class Int64Queue extends _IntQueue<Int64List> implements QueueList<int> {
  /// Creates an empty [Int64Queue] with the given initial internal capacity (in
  /// elements).
  Int64Queue([int? initialCapacity])
      : super(Int64List(_chooseRealInitialCapacity(initialCapacity)));

  /// Creates a [Int64Queue] with the same length and contents as [elements].
  factory Int64Queue.fromList(List<int> elements) =>
      Int64Queue(elements.length)..addAll(elements);

  @override
  Int64List _createList(int size) => Int64List(size);
  @override
  Int64Buffer _createBuffer(int size) => Int64Buffer(size);
}

/// A [QueueList] that efficiently stores IEEE 754 single-precision binary
/// floating-point numbers.
///
/// For long queues, this implementation can be considerably more space- and
/// time-efficient than a default [QueueList] implementation.
///
/// Doubles stored in this are converted to the nearest single-precision value.
/// Values read are converted to a double value with the same value.
class Float32Queue extends _FloatQueue<Float32List>
    implements QueueList<double> {
  /// Creates an empty [Float32Queue] with the given initial internal capacity
  /// (in elements).
  Float32Queue([int? initialCapacity])
      : super(Float32List(_chooseRealInitialCapacity(initialCapacity)));

  /// Creates a [Float32Queue] with the same length and contents as [elements].
  factory Float32Queue.fromList(List<double> elements) =>
      Float32Queue(elements.length)..addAll(elements);

  @override
  Float32List _createList(int size) => Float32List(size);
  @override
  Float32Buffer _createBuffer(int size) => Float32Buffer(size);
}

/// A [QueueList] that efficiently stores IEEE 754 double-precision binary
/// floating-point numbers.
///
/// For long queues, this implementation can be considerably more space- and
/// time-efficient than a default [QueueList] implementation.
class Float64Queue extends _FloatQueue<Float64List>
    implements QueueList<double> {
  /// Creates an empty [Float64Queue] with the given initial internal capacity
  /// (in elements).
  Float64Queue([int? initialCapacity])
      : super(Float64List(_chooseRealInitialCapacity(initialCapacity)));

  /// Creates a [Float64Queue] with the same length and contents as [elements].
  factory Float64Queue.fromList(List<double> elements) =>
      Float64Queue(elements.length)..addAll(elements);

  @override
  Float64List _createList(int size) => Float64List(size);
  @override
  Float64Buffer _createBuffer(int size) => Float64Buffer(size);
}

/// A [QueueList] that efficiently stores [Int32x4] numbers.
///
/// For long queues, this implementation can be considerably more space- and
/// time-efficient than a default [QueueList] implementation.
class Int32x4Queue extends _TypedQueue<Int32x4, Int32x4List>
    implements QueueList<Int32x4> {
  static final Int32x4 _zero = Int32x4(0, 0, 0, 0);

  /// Creates an empty [Int32x4Queue] with the given initial internal capacity
  /// (in elements).
  Int32x4Queue([int? initialCapacity])
      : super(Int32x4List(_chooseRealInitialCapacity(initialCapacity)));

  /// Creates a [Int32x4Queue] with the same length and contents as [elements].
  factory Int32x4Queue.fromList(List<Int32x4> elements) =>
      Int32x4Queue(elements.length)..addAll(elements);

  @override
  Int32x4List _createList(int size) => Int32x4List(size);
  @override
  Int32x4Buffer _createBuffer(int size) => Int32x4Buffer(size);
  @override
  Int32x4 get _defaultValue => _zero;
}

/// A [QueueList] that efficiently stores [Float32x4] numbers.
///
/// For long queues, this implementation can be considerably more space- and
/// time-efficient than a default [QueueList] implementation.
class Float32x4Queue extends _TypedQueue<Float32x4, Float32x4List>
    implements QueueList<Float32x4> {
  /// Creates an empty [Float32x4Queue] with the given initial internal capacity (in
  /// elements).
  Float32x4Queue([int? initialCapacity])
      : super(Float32x4List(_chooseRealInitialCapacity(initialCapacity)));

  /// Creates a [Float32x4Queue] with the same length and contents as [elements].
  factory Float32x4Queue.fromList(List<Float32x4> elements) =>
      Float32x4Queue(elements.length)..addAll(elements);

  @override
  Float32x4List _createList(int size) => Float32x4List(size);
  @override
  Float32x4Buffer _createBuffer(int size) => Float32x4Buffer(size);
  @override
  Float32x4 get _defaultValue => Float32x4.zero();
}

/// The initial capacity of queues if the user doesn't specify one.
const _defaultInitialCapacity = 16;

/// Choose the next-highest power of two given a user-specified
/// [initialCapacity] for a queue.
int _chooseRealInitialCapacity(int? initialCapacity) {
  if (initialCapacity == null || initialCapacity < _defaultInitialCapacity) {
    return _defaultInitialCapacity;
  } else if (!_isPowerOf2(initialCapacity)) {
    return _nextPowerOf2(initialCapacity);
  } else {
    return initialCapacity;
  }
}

/// Whether [number] is a power of two.
///
/// Only works for positive numbers.
bool _isPowerOf2(int number) => (number & (number - 1)) == 0;

/// Rounds [number] up to the nearest power of 2.
///
/// If [number] is a power of 2 already, it is returned.
///
/// Only works for positive numbers.
int _nextPowerOf2(int number) {
  assert(number > 0);
  number = (number << 1) - 1;
  for (;;) {
    var nextNumber = number & (number - 1);
    if (nextNumber == 0) return number;
    number = nextNumber;
  }
}
