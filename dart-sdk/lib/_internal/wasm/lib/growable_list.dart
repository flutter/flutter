// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

@pragma("wasm:entry-point")
class _GrowableList<E> extends _ModifiableList<E> {
  _GrowableList._(int length, int capacity) : super(length, capacity);

  @pragma("wasm:entry-point")
  _GrowableList._withData(WasmArray<Object?> data)
      : super._withData(data.length, data);

  factory _GrowableList(int length) {
    return _GrowableList<E>._(length, length);
  }

  factory _GrowableList.withCapacity(int capacity) {
    return _GrowableList<E>._(0, capacity);
  }

  // Specialization of List.empty constructor for growable == true.
  // Used by pkg/dart2wasm/lib/list_factory_specializer.dart.
  @pragma("wasm:entry-point")
  factory _GrowableList.empty() => _GrowableList(0);

  // Specialization of List.filled constructor for growable == true.
  // Used by pkg/dart2wasm/lib/list_factory_specializer.dart.
  factory _GrowableList.filled(int length, E fill) {
    final result = _GrowableList<E>(length);
    if (fill != null) {
      result._data.fill(0, fill, length);
    }
    return result;
  }

  // Specialization of List.generate constructor for growable == true.
  // Used by pkg/dart2wasm/lib/list_factory_specializer.dart.
  factory _GrowableList.generate(int length, E generator(int index)) {
    final result = _GrowableList<E>(length);
    for (int i = 0; i < result.length; ++i) {
      result._data[i] = generator(i);
    }
    return result;
  }

  // Specialization of List.of constructor for growable == true.
  factory _GrowableList.of(Iterable<E> elements) {
    if (elements is _ListBase) {
      return _GrowableList._ofListBase(unsafeCast(elements));
    }
    if (elements is EfficientLengthIterable) {
      return _GrowableList._ofEfficientLengthIterable(unsafeCast(elements));
    }
    return _GrowableList._ofOther(elements);
  }

  factory _GrowableList._ofListBase(_ListBase<E> elements) {
    final int length = elements.length;
    final list = _GrowableList<E>(length);
    list._data.copy(0, elements._data, 0, length);
    return list;
  }

  factory _GrowableList._ofEfficientLengthIterable(
      EfficientLengthIterable<E> elements) {
    final int length = elements.length;
    final list = _GrowableList<E>(length);
    if (length > 0) {
      int i = 0;
      for (var element in elements) {
        list[i++] = element;
      }
      if (i != length) throw ConcurrentModificationError(elements);
    }
    return list;
  }

  factory _GrowableList._ofOther(Iterable<E> elements) {
    final list = _GrowableList<E>(0);
    for (var elements in elements) {
      list.add(elements);
    }
    return list;
  }

  void insert(int index, E element) {
    if (index == length) {
      return add(element);
    }

    if ((index < 0) || (index > length)) {
      throw RangeError.range(index, 0, length);
    }

    final WasmArray<Object?> data;
    if (length == _capacity) {
      data = WasmArray<Object?>(_nextCapacity(_capacity));
      if (index != 0) {
        // Copy elements before the insertion point.
        data.copy(0, _data, 0, index);
      }
    } else {
      data = _data;
    }

    // Shift elements, or copy elements after insertion point if we allocated a
    // new array.
    data.copy(index + 1, _data, index, length - index);

    // Insert new element.
    data[index] = element;

    _data = data;
    _length += 1;
  }

  E removeAt(int index) {
    // TODO(omersa): Check if removal will cause shrinking. If it will create a
    // new list directly, instead of first removing the element and then
    // shrinking.
    var result = this[index];
    int newLength = this.length - 1;
    if (index < newLength) {
      _data.copy(index, _data, index + 1, newLength - index);
    }
    this.length = newLength;
    return result;
  }

  bool remove(Object? element) {
    for (int i = 0; i < this.length; i++) {
      if (_data[i] == element) {
        removeAt(i);
        return true;
      }
    }
    return false;
  }

  void insertAll(int index, Iterable<E> iterable) {
    if (index < 0 || index > length) {
      throw RangeError.range(index, 0, length);
    }
    if (iterable is! _ListBase) {
      // Read out all elements before making room to ensure consistency of the
      // modified list in case the iterator throws.
      iterable = _List.of(iterable);
    }
    int insertionLength = iterable.length;
    int capacity = _capacity;
    int newLength = length + insertionLength;
    if (newLength > capacity) {
      do {
        capacity = _nextCapacity(capacity);
      } while (newLength > capacity);
      _grow(capacity);
    }
    _setLength(newLength);
    setRange(index + insertionLength, this.length, this, index);
    setAll(index, iterable);
  }

  void removeRange(int start, int end) {
    RangeError.checkValidRange(start, end, this.length);
    _data.copy(start, _data, end, length - end);
    this.length = this.length - (end - start);
  }

  int get _capacity => _data.length;

  void set length(int new_length) {
    if (new_length > length) {
      // Verify that element type is nullable.
      null as E;
      if (new_length > _capacity) {
        _grow(new_length);
      }
      _setLength(new_length);
      return;
    }
    final int new_capacity = new_length;
    // We are shrinking. Pick the method which has fewer writes.
    // In the shrink-to-fit path, we write |new_capacity + new_length| words
    // (null init + copy).
    // In the non-shrink-to-fit path, we write |length - new_length| words
    // (null overwrite).
    final bool shouldShrinkToFit =
        (new_capacity + new_length) < (length - new_length);
    if (shouldShrinkToFit) {
      _shrink(new_capacity, new_length);
    } else {
      _data.fill(new_length, null, length - new_length);
    }
    _setLength(new_length);
  }

  void _setLength(int new_length) {
    _length = new_length;
  }

  void add(E value) {
    var len = length;
    if (len == _capacity) {
      _growToNextCapacity();
    }
    _setLength(len + 1);
    _data[len] = value;
  }

  void addAll(Iterable<E> iterable) {
    var len = length;
    if (iterable is EfficientLengthIterable) {
      // Pregrow if we know iterable.length.
      var iterLen = iterable.length;
      if (iterLen == 0) {
        return;
      }
      if (identical(iterable, this)) {
        throw ConcurrentModificationError(this);
      }
      var cap = _capacity;
      var newLen = len + iterLen;
      if (newLen > cap) {
        do {
          cap = _nextCapacity(cap);
        } while (newLen > cap);
        _grow(cap);
      }
    }
    Iterator it = iterable.iterator;
    if (!it.moveNext()) return;
    do {
      while (len < _capacity) {
        int newLen = len + 1;
        this._setLength(newLen);
        _data[len] = it.current;
        if (!it.moveNext()) return;
        if (this.length != newLen) throw ConcurrentModificationError(this);
        len = newLen;
      }
      _growToNextCapacity();
    } while (true);
  }

  E removeLast() {
    var len = length - 1;
    var elem = this[len];
    this.length = len;
    return elem;
  }

  // Shared array used as backing for new empty growable lists.
  static final WasmArray<Object?> _emptyData = WasmArray<Object?>(0);

  static WasmArray<Object?> _allocateData(int capacity) {
    if (capacity < 0) {
      throw RangeError.range(capacity, 0, _maxWasmArrayLength);
    }
    if (capacity == 0) {
      // Use shared empty list as backing.
      return _emptyData;
    }
    return WasmArray<Object?>(capacity);
  }

  // Grow from 0 to 3, and then double + 1.
  int _nextCapacity(int old_capacity) => (old_capacity * 2) | 3;

  void _grow(int new_capacity) {
    var newData = WasmArray<Object?>(new_capacity);
    newData.copy(0, _data, 0, length);
    _data = newData;
  }

  void _growToNextCapacity() {
    _grow(_nextCapacity(_capacity));
  }

  void _shrink(int new_capacity, int new_length) {
    var newData = _allocateData(new_capacity);
    newData.copy(0, _data, 0, new_length);
    _data = newData;
  }

  Iterator<E> get iterator {
    return _GrowableListIterator<E>(this);
  }
}

// Iterator for growable lists.
class _GrowableListIterator<E> implements Iterator<E> {
  final _GrowableList<E> _list;
  final int _length; // Cache list length for modification check.
  int _index;
  E? _current;

  _GrowableListIterator(_GrowableList<E> list)
      : _list = list,
        _length = list.length,
        _index = 0;

  E get current => _current as E;

  bool moveNext() {
    if (_list.length != _length) {
      throw ConcurrentModificationError(_list);
    }
    if (_index >= _length) {
      _current = null;
      return false;
    }
    _current = unsafeCast(_list._data[_index]);
    _index++;
    return true;
  }
}
