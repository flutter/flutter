// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._list;

import 'dart:_internal';
import 'dart:_wasm';
import 'dart:collection';

const int _maxWasmArrayLength = 2147483647; // max i32

@pragma("wasm:entry-point")
abstract class WasmListBase<E> extends ListBase<E> {
  @pragma("wasm:entry-point")
  int _length;

  @pragma("wasm:entry-point")
  WasmArray<Object?> _data;

  WasmListBase(int length, int capacity)
      : _length = length,
        _data = WasmArray<Object?>(
            RangeError.checkValueInInterval(capacity, 0, _maxWasmArrayLength));

  WasmListBase._withData(this._length, this._data);

  @pragma('wasm:prefer-inline')
  E operator [](int index) {
    indexCheckWithName(index, _length, "[]");
    return unsafeCast(_data[index]);
  }

  @pragma('wasm:prefer-inline')
  int get length => _length;

  List<E> sublist(int start, [int? end]) {
    final int listLength = this.length;
    final int actualEnd = RangeError.checkValidRange(start, end, listLength);
    int length = actualEnd - start;
    if (length == 0) return <E>[];
    return GrowableList<E>(length)..setRange(0, length, this, start);
  }

  void forEach(f(E element)) {
    final initialLength = length;
    for (int i = 0; i < initialLength; i++) {
      f(unsafeCast<E>(_data[i]));
      if (length != initialLength) throw ConcurrentModificationError(this);
    }
  }

  @pragma("wasm:prefer-inline")
  List<E> toList({bool growable = true}) => List.from(this, growable: growable);
}

@pragma("wasm:entry-point")
abstract class _ModifiableList<E> extends WasmListBase<E> {
  _ModifiableList(int length, int capacity) : super(length, capacity);

  _ModifiableList._withData(int length, WasmArray<Object?> data)
      : super._withData(length, data);

  @pragma('wasm:prefer-inline')
  void operator []=(int index, E value) {
    indexCheckWithName(index, _length, "[]=");
    _data[index] = value;
  }

  // List interface.
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, this.length);
    int length = end - start;
    if (length == 0) return;
    RangeError.checkNotNegative(skipCount, "skipCount");
    if (identical(this, iterable)) {
      _data.copy(start, _data, skipCount, length);
    } else if (iterable is List<E>) {
      Lists.copy(iterable, skipCount, this, start, length);
    } else {
      Iterator<E> it = iterable.iterator;
      while (skipCount > 0) {
        if (!it.moveNext()) return;
        skipCount--;
      }
      for (int i = start; i < end; i++) {
        if (!it.moveNext()) return;
        _data[i] = it.current;
      }
    }
  }

  void setAll(int index, Iterable<E> iterable) {
    if (index < 0 || index > this.length) {
      throw RangeError.range(index, 0, this.length, "index");
    }
    List<E> iterableAsList;
    if (identical(this, iterable)) {
      iterableAsList = this;
    } else if (iterable is List<E>) {
      iterableAsList = iterable;
    } else {
      for (var value in iterable) {
        this[index++] = value;
      }
      return;
    }
    int length = iterableAsList.length;
    if (index + length > this.length) {
      throw RangeError.range(index + length, 0, this.length);
    }
    Lists.copy(iterableAsList, 0, this, index, length);
  }
}

@pragma("wasm:entry-point")
class ModifiableFixedLengthList<E> extends _ModifiableList<E>
    with FixedLengthListMixin<E> {
  ModifiableFixedLengthList._(int length) : super(length, length);

  factory ModifiableFixedLengthList(int length) =>
      ModifiableFixedLengthList._(length);

  // Specialization of List.empty constructor for growable == false.
  // Used by pkg/dart2wasm/lib/list_factory_specializer.dart.
  factory ModifiableFixedLengthList.empty() => ModifiableFixedLengthList<E>(0);

  // Specialization of List.filled constructor for growable == false.
  // Used by pkg/dart2wasm/lib/list_factory_specializer.dart.
  factory ModifiableFixedLengthList.filled(int length, E fill) {
    final result = ModifiableFixedLengthList<E>(length);
    if (fill != null) {
      result._data.fill(0, fill, length);
    }
    return result;
  }

  // Specialization of List.generate constructor for growable == false.
  // Used by pkg/dart2wasm/lib/list_factory_specializer.dart.
  factory ModifiableFixedLengthList.generate(
      int length, E generator(int index)) {
    final result = ModifiableFixedLengthList<E>(length);
    for (int i = 0; i < result.length; ++i) {
      result._data[i] = generator(i);
    }
    return result;
  }

  // Specialization of List.of constructor for growable == false.
  factory ModifiableFixedLengthList.of(Iterable<E> elements) {
    if (elements is WasmListBase) {
      return ModifiableFixedLengthList._ofListBase(unsafeCast(elements));
    }
    if (elements is EfficientLengthIterable) {
      return ModifiableFixedLengthList._ofEfficientLengthIterable(
          unsafeCast(elements));
    }
    return ModifiableFixedLengthList.fromIterable(elements);
  }

  factory ModifiableFixedLengthList._ofListBase(WasmListBase<E> elements) {
    final int length = elements.length;
    final list = ModifiableFixedLengthList<E>(length);
    list._data.copy(0, elements._data, 0, length);
    return list;
  }

  factory ModifiableFixedLengthList._ofEfficientLengthIterable(
      EfficientLengthIterable<E> elements) {
    final int length = elements.length;
    final list = ModifiableFixedLengthList<E>(length);
    if (length > 0) {
      int i = 0;
      for (var element in elements) {
        list[i++] = element;
      }
      if (i != length) throw ConcurrentModificationError(elements);
    }
    return list;
  }

  factory ModifiableFixedLengthList.fromIterable(Iterable<E> elements) {
    // The static type of `makeListFixedLength` is `List<E>`, not `ModifiableFixedLengthList<E>`,
    // but we know that is what it does.  `makeListFixedLength` is too generally
    // typed since it is available on the web platform which has different
    // system List types.
    return unsafeCast(
        makeListFixedLength(GrowableList<E>.fromIterable(elements)));
  }

  Iterator<E> get iterator {
    return _FixedSizeListIterator<E>(this);
  }
}

@pragma("wasm:entry-point")
class ImmutableList<E> extends WasmListBase<E> with UnmodifiableListMixin<E> {
  factory ImmutableList._uninstantiable() {
    throw UnsupportedError(
        "ImmutableList can only be allocated by the runtime");
  }

  Iterator<E> get iterator {
    return _FixedSizeListIterator<E>(this);
  }
}

// Iterator for lists with fixed size.
class _FixedSizeListIterator<E> implements Iterator<E> {
  final WasmArray<Object?> _data;
  final int _length; // Cache list length for faster access.
  int _index;
  E? _current;

  _FixedSizeListIterator(WasmListBase<E> list)
      : _data = list._data,
        _length = list.length,
        _index = 0 {
    assert(list is ModifiableFixedLengthList<E> || list is ImmutableList<E>);
  }

  E get current => _current as E;

  bool moveNext() {
    if (_index >= _length) {
      _current = null;
      return false;
    }
    _current = unsafeCast(_data[_index]);
    _index++;
    return true;
  }
}

@pragma("wasm:entry-point")
class GrowableList<E> extends _ModifiableList<E> {
  GrowableList._(int length, int capacity) : super(length, capacity);

  @pragma("wasm:entry-point")
  GrowableList._withData(WasmArray<Object?> data)
      : super._withData(data.length, data);

  @pragma("wasm:prefer-inline")
  factory GrowableList(int length) => GrowableList<E>._(length, length);

  @pragma("wasm:prefer-inline")
  factory GrowableList.withCapacity(int capacity) =>
      GrowableList<E>._(0, capacity);

  // Specialization of List.empty constructor for growable == true.
  // Used by pkg/dart2wasm/lib/list_factory_specializer.dart.
  @pragma("wasm:entry-point")
  factory GrowableList.empty() => GrowableList(0);

  // Specialization of List.filled constructor for growable == true.
  // Used by pkg/dart2wasm/lib/list_factory_specializer.dart.
  factory GrowableList.filled(int length, E fill) {
    final result = GrowableList<E>(length);
    if (fill != null) {
      result._data.fill(0, fill, length);
    }
    return result;
  }

  // Specialization of List.generate constructor for growable == true.
  // Used by pkg/dart2wasm/lib/list_factory_specializer.dart.
  factory GrowableList.generate(int length, E generator(int index)) {
    final result = GrowableList<E>(length);
    for (int i = 0; i < result.length; ++i) {
      result._data[i] = generator(i);
    }
    return result;
  }

  // Specialization of List.of constructor for growable == true.
  factory GrowableList.of(Iterable<E> elements) {
    if (elements is WasmListBase) {
      return GrowableList._ofListBase(unsafeCast(elements));
    }
    if (elements is EfficientLengthIterable) {
      return GrowableList._ofEfficientLengthIterable(unsafeCast(elements));
    }
    return GrowableList.fromIterable(elements);
  }

  factory GrowableList._ofListBase(WasmListBase<E> elements) {
    final int length = elements.length;
    final list = GrowableList<E>(length);
    list._data.copy(0, elements._data, 0, length);
    return list;
  }

  factory GrowableList._ofEfficientLengthIterable(
      EfficientLengthIterable<E> elements) {
    final int length = elements.length;
    final list = GrowableList<E>(length);
    if (length > 0) {
      int i = 0;
      for (var element in elements) {
        list[i++] = element;
      }
      if (i != length) throw ConcurrentModificationError(elements);
    }
    return list;
  }

  factory GrowableList.fromIterable(Iterable<E> elements) {
    final list = GrowableList<E>(0);
    for (var elements in elements) {
      list.add(elements);
    }
    return list;
  }

  void insert(int index, E element) {
    if (index == length) {
      return add(element);
    }

    // index < 0 || index > length
    if (index.gtU(length)) {
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
    // index < 0 || index > length
    if (index.gtU(length)) {
      throw RangeError.range(index, 0, length);
    }
    if (iterable is! WasmListBase) {
      // Read out all elements before making room to ensure consistency of the
      // modified list in case the iterator throws.
      iterable = ModifiableFixedLengthList.of(iterable);
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
  final GrowableList<E> _list;
  final int _length; // Cache list length for modification check.
  int _index;
  E? _current;

  _GrowableListIterator(GrowableList<E> list)
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
