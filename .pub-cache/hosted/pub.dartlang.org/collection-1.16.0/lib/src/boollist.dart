// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show ListMixin;
import 'dart:typed_data' show Uint32List;

import 'unmodifiable_wrappers.dart' show NonGrowableListMixin;

/// A space-efficient list of boolean values.
///
/// Uses list of integers as internal storage to reduce memory usage.
abstract class BoolList with ListMixin<bool> {
  static const int _entryShift = 5;

  static const int _bitsPerEntry = 32;

  static const int _entrySignBitIndex = 31;

  /// The length of the list.
  ///
  /// Maybe be shorter than the capacity of the backing store.
  int _length;

  /// Backing store for bits.
  Uint32List _data;

  BoolList._(this._data, this._length);

  factory BoolList._selectType(int length, bool growable) {
    if (growable) {
      return _GrowableBoolList(length);
    } else {
      return _NonGrowableBoolList(length);
    }
  }

  /// Creates a list of booleans with the provided length.
  ///
  /// The list is initially filled with the [fill] value, and
  /// the list is growable if [growable] is true.
  factory BoolList(int length, {bool fill = false, bool growable = false}) {
    RangeError.checkNotNegative(length, 'length');

    BoolList boolist;
    if (growable) {
      boolist = _GrowableBoolList(length);
    } else {
      boolist = _NonGrowableBoolList(length);
    }

    if (fill) {
      boolist.fillRange(0, length, true);
    }

    return boolist;
  }

  /// Creates an empty list of booleans.
  ///
  /// The list defaults to being growable unless [growable] is `false`.
  /// If [capacity] is provided, and [growable] is not `false`,
  /// the implementation will attempt to make space for that
  /// many elements before needing to grow its internal storage.
  factory BoolList.empty({bool growable = true, int capacity = 0}) {
    RangeError.checkNotNegative(capacity, 'length');

    if (growable) {
      return _GrowableBoolList._withCapacity(0, capacity);
    } else {
      return _NonGrowableBoolList._withCapacity(0, capacity);
    }
  }

  /// Generates a [BoolList] of values.
  ///
  /// Creates a [BoolList] with [length] positions and fills it with values created by
  /// calling [generator] for each index in the range `0` .. `length - 1` in increasing order.
  ///
  /// The created list is fixed-length unless [growable] is true.
  factory BoolList.generate(
    int length,
    bool Function(int) generator, {
    bool growable = true,
  }) {
    RangeError.checkNotNegative(length, 'length');

    var instance = BoolList._selectType(length, growable);
    for (var i = 0; i < length; i++) {
      instance._setBit(i, generator(i));
    }
    return instance;
  }

  /// Creates a list containing all [elements].
  ///
  /// The [Iterator] of [elements] provides the order of the elements.
  ///
  /// This constructor creates a growable [BoolList] when [growable] is true;
  /// otherwise, it returns a fixed-length list.
  factory BoolList.of(Iterable<bool> elements, {bool growable = false}) {
    return BoolList._selectType(elements.length, growable)..setAll(0, elements);
  }

  /// The number of boolean values in this list.
  ///
  /// The valid indices for a list are `0` through `length - 1`.
  ///
  /// If the list is growable, setting the length will change the
  /// number of values.
  /// Setting the length to a smaller number will remove all
  /// values with indices greater than or equal to the new length.
  /// Setting the length to a larger number will increase the number of
  /// values, and all the new values will be `false`.
  @override
  int get length => _length;

  @override
  bool operator [](int index) {
    RangeError.checkValidIndex(index, this, 'index', _length);
    return (_data[index >> _entryShift] &
            (1 << (index & _entrySignBitIndex))) !=
        0;
  }

  @override
  void operator []=(int index, bool value) {
    RangeError.checkValidIndex(index, this, 'index', _length);
    _setBit(index, value);
  }

  @override
  void fillRange(int start, int end, [bool? fill]) {
    RangeError.checkValidRange(start, end, _length);
    fill ??= false;

    var startWord = start >> _entryShift;
    var endWord = (end - 1) >> _entryShift;

    var startBit = start & _entrySignBitIndex;
    var endBit = (end - 1) & _entrySignBitIndex;

    if (startWord < endWord) {
      if (fill) {
        _data[startWord] |= -1 << startBit;
        _data.fillRange(startWord + 1, endWord, -1);
        _data[endWord] |= (1 << (endBit + 1)) - 1;
      } else {
        _data[startWord] &= (1 << startBit) - 1;
        _data.fillRange(startWord + 1, endWord, 0);
        _data[endWord] &= -1 << (endBit + 1);
      }
    } else {
      if (fill) {
        _data[startWord] |= ((1 << (endBit - startBit + 1)) - 1) << startBit;
      } else {
        _data[startWord] &= ((1 << startBit) - 1) | (-1 << (endBit + 1));
      }
    }
  }

  /// Creates an iterator for the elements of this [BoolList].
  ///
  /// The [Iterator.current] getter of the returned iterator
  /// is `false` when the iterator has no current element.
  @override
  Iterator<bool> get iterator => _BoolListIterator(this);

  void _setBit(int index, bool value) {
    if (value) {
      _data[index >> _entryShift] |= 1 << (index & _entrySignBitIndex);
    } else {
      _data[index >> _entryShift] &= ~(1 << (index & _entrySignBitIndex));
    }
  }

  static int _lengthInWords(int bitLength) {
    return (bitLength + (_bitsPerEntry - 1)) >> _entryShift;
  }
}

class _GrowableBoolList extends BoolList {
  static const int _growthFactor = 2;

  _GrowableBoolList._withCapacity(int length, int capacity)
      : super._(
          Uint32List(BoolList._lengthInWords(capacity)),
          length,
        );

  _GrowableBoolList(int length)
      : super._(
          Uint32List(BoolList._lengthInWords(length * _growthFactor)),
          length,
        );

  @override
  set length(int length) {
    RangeError.checkNotNegative(length, 'length');
    if (length > _length) {
      _expand(length);
    } else if (length < _length) {
      _shrink(length);
    }
  }

  void _expand(int length) {
    if (length > _data.length * BoolList._bitsPerEntry) {
      _data = Uint32List(
        BoolList._lengthInWords(length * _growthFactor),
      )..setRange(0, _data.length, _data);
    }
    _length = length;
  }

  void _shrink(int length) {
    if (length < _length ~/ _growthFactor) {
      var newDataLength = BoolList._lengthInWords(length);
      _data = Uint32List(newDataLength)..setRange(0, newDataLength, _data);
    }

    for (var i = length; i < _data.length * BoolList._bitsPerEntry; i++) {
      _setBit(i, false);
    }

    _length = length;
  }
}

class _NonGrowableBoolList extends BoolList with NonGrowableListMixin<bool> {
  _NonGrowableBoolList._withCapacity(int length, int capacity)
      : super._(
          Uint32List(BoolList._lengthInWords(capacity)),
          length,
        );

  _NonGrowableBoolList(int length)
      : super._(
          Uint32List(BoolList._lengthInWords(length)),
          length,
        );
}

class _BoolListIterator implements Iterator<bool> {
  bool _current = false;
  int _pos = 0;
  final int _length;

  final BoolList _boolList;

  _BoolListIterator(this._boolList) : _length = _boolList._length;

  @override
  bool get current => _current;

  @override
  bool moveNext() {
    if (_boolList._length != _length) {
      throw ConcurrentModificationError(_boolList);
    }

    if (_pos < _boolList.length) {
      var pos = _pos++;
      _current = _boolList._data[pos >> BoolList._entryShift] &
              (1 << (pos & BoolList._entrySignBitIndex)) !=
          0;
      return true;
    }
    _current = false;
    return false;
  }
}
