// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._list;

import 'dart:_internal';
import 'dart:_wasm';
import 'dart:_error_utils';
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
        RangeErrorUtils.checkValueInInterval(capacity, 0, _maxWasmArrayLength),
      );

  WasmListBase._withData(this._length, this._data);

  @pragma('wasm:prefer-inline')
  E operator [](int index) {
    IndexErrorUtils.checkIndexBCE(index, _length, "[]");
    return unsafeCast(_data[index]);
  }

  @pragma('wasm:prefer-inline')
  int get length => _length;

  List<E> sublist(int start, [int? end]) {
    final int listLength = this.length;
    final int actualEnd = RangeErrorUtils.checkValidRange(
      start,
      end,
      listLength,
      'start',
      'end',
    );
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
  List<E> toList({bool growable = true}) => List.of(this, growable: growable);

  @pragma('wasm:prefer-inline')
  Iterator<E> get iterator {
    return _FixedSizeListIterator<E>(this);
  }
}

@pragma("wasm:entry-point")
abstract class _ModifiableList<E> extends WasmListBase<E> {
  _ModifiableList(int length, int capacity) : super(length, capacity);

  _ModifiableList._withData(int length, WasmArray<Object?> data)
    : super._withData(length, data);

  @pragma('wasm:prefer-inline')
  @override
  void operator []=(int index, E value) {
    IndexErrorUtils.checkIndexBCE(index, _length, "[]=");
    _data[index] = value;
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    RangeErrorUtils.checkValidRange(start, end, this.length);
    int length = end - start;
    if (length == 0) return;
    RangeErrorUtils.checkNotNegative(skipCount, "skipCount");

    // Look through `SubListIterable`s while still testing for the fast case as
    // first thing.
    while (true) {
      if (iterable is WasmListBase) {
        final iterableWasmList = unsafeCast<WasmListBase>(iterable);
        if (skipCount + length > iterableWasmList.length) {
          throw IterableElementError.tooFew();
        }
        _data.copy(start, iterableWasmList._data, skipCount, length);
        return;
      }

      if (iterable is List) {
        final iterableList = unsafeCast<List<E>>(iterable);
        for (int i = skipCount, j = start; i < skipCount + length; i++, j++) {
          _data[j] = iterableList[i];
        }
        return;
      }

      if (iterable is SubListIterable) {
        final listIterable = unsafeCast<SubListIterable<E>>(iterable);
        var sourceLength = listIterable.length;
        if (sourceLength - skipCount < length) {
          throw IterableElementError.tooFew();
        }
        iterable = SubListIterable.iterableOf(listIterable);
        skipCount += SubListIterable.startOf(listIterable);
        continue;
      }

      break;
    }

    Iterator<E> it = iterable.iterator;
    while (skipCount > 0) {
      if (!it.moveNext()) throw IterableElementError.tooFew();
      skipCount--;
    }
    for (int i = start; i < end; i++) {
      if (!it.moveNext()) throw IterableElementError.tooFew();
      _data[i] = it.current;
    }
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    final length = this.length;

    if (iterable is WasmListBase) {
      final iterableWasmList = unsafeCast<WasmListBase>(iterable);
      final elementCount = iterableWasmList.length;
      RangeErrorUtils.checkValidRange(index, index + elementCount, length);
      _data.copy(index, iterableWasmList._data, 0, elementCount);
      return;
    }

    if (iterable is List) {
      final iterableList = unsafeCast<List<E>>(iterable);
      final elementCount = iterableList.length;
      RangeErrorUtils.checkValidRange(index, index + elementCount, length);
      for (int i = 0, j = index; i < elementCount; i++, j++) {
        _data[j] = iterableList[i];
      }
      return;
    }

    for (var value in iterable) {
      this[index++] = value;
    }
  }

  @override
  void fillRange(int start, int end, [E? fill]) {
    // Check for nulls the same way as `ListBase.fillRange`.
    final E value = fill as E;
    RangeErrorUtils.checkValidRange(start, end, length);
    _data.fill(start, value, end - start);
  }
}

@pragma("wasm:entry-point")
class ModifiableFixedLengthList<E> extends _ModifiableList<E>
    with FixedLengthListMixin<E> {
  ModifiableFixedLengthList._(int length) : super(length, length);

  ModifiableFixedLengthList._withData(WasmArray<Object?> data)
    : super._withData(data.length, data) {
    assert((() => _elementsHaveType<E>(this))());
  }

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
    int length,
    E generator(int index),
  ) {
    final result = ModifiableFixedLengthList<E>(length);
    for (int i = 0; i < result.length; ++i) {
      result._data[i] = generator(i);
    }
    return result;
  }

  // Target of List.of constructor with untyped iterable and growable == false.
  factory ModifiableFixedLengthList.ofUntypedIterable(Iterable elements) {
    // If elements is an Iterable<E>, we won't need a type-test for each
    // element.
    if (elements is Iterable<E>) {
      return ModifiableFixedLengthList.of(elements);
    }
    // If we know the length of the list then we can avoid using growable
    // arrays.
    if (elements is EfficientLengthIterable) {
      return ModifiableFixedLengthList._ofUntypedEfficientLengthIterable(
        elements,
      );
    }

    return ModifiableFixedLengthList._fromUntypedIterable(elements);
  }

  factory ModifiableFixedLengthList._ofUntypedEfficientLengthIterable(
    EfficientLengthIterable elements,
  ) {
    final length = elements.length;
    final data = WasmArray<Object?>(length);
    int i = 0;
    for (final E o in elements) data[i++] = o;
    if (i != length) throw ConcurrentModificationError(elements);
    return ModifiableFixedLengthList<E>._withData(data);
  }

  @pragma('wasm:prefer-inline')
  factory ModifiableFixedLengthList._fromUntypedIterable(Iterable elements) {
    return GrowableList<E>._fromUntypedIterable(
      elements,
    )._toModifiableFixedLengthList();
  }

  // Specialization of List.of constructor for growable == false.
  @pragma('wasm:entry-point')
  factory ModifiableFixedLengthList.of(Iterable<E> elements) {
    if (elements is WasmListBase) {
      return ModifiableFixedLengthList._ofListBase(unsafeCast(elements));
    }
    if (elements is EfficientLengthIterable) {
      return ModifiableFixedLengthList._ofEfficientLengthIterable(
        unsafeCast(elements),
      );
    }
    return ModifiableFixedLengthList._fromIterable(elements);
  }

  factory ModifiableFixedLengthList._ofListBase(WasmListBase<E> elements) {
    final int length = elements.length;
    final list = ModifiableFixedLengthList<E>(length);
    list._data.copy(0, elements._data, 0, length);
    return list;
  }

  factory ModifiableFixedLengthList._ofEfficientLengthIterable(
    EfficientLengthIterable<E> elements,
  ) {
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

  factory ModifiableFixedLengthList._fromIterable(Iterable<E> elements) {
    return GrowableList<E>._fromIterable(
      elements,
    )._toModifiableFixedLengthList();
  }
}

@pragma("wasm:entry-point")
class ImmutableList<E> extends WasmListBase<E> with UnmodifiableListMixin<E> {
  ImmutableList._withData(WasmArray<Object?> data)
    : super._withData(data.length, data) {
    assert((() => _elementsHaveType<E>(this))());
  }

  // Target of List.unmodifiable constructor.
  factory ImmutableList.ofUntypedIterable(Iterable elements) {
    // If elements is an Iterable<E>, we won't need a type-test for each
    // element.
    if (elements is Iterable<E>) {
      return ImmutableList<E>.of(elements);
    }

    // If we know the length of the list then we can avoid using growable
    // arrays.
    if (elements is EfficientLengthIterable) {
      final length = elements.length;
      final data = WasmArray<Object?>(length);
      int i = 0;
      for (final E o in elements) data[i++] = o;
      if (i != length) throw ConcurrentModificationError(elements);
      return ImmutableList<E>._withData(data);
    }

    final growableList = GrowableList<E>(0);
    for (final E o in elements) growableList.add(o);
    return growableList._toUnmodifiableList();
  }

  // Specialization of List.unmodifiable constructor for typed iterables.
  factory ImmutableList.of(Iterable<E> elements) {
    if (elements is WasmListBase) {
      return ImmutableList._ofListBase(unsafeCast(elements));
    }
    if (elements is EfficientLengthIterable) {
      return ImmutableList._ofEfficientLengthIterable(unsafeCast(elements));
    }
    return ImmutableList._fromIterable(elements);
  }

  factory ImmutableList._ofListBase(WasmListBase<E> elements) {
    final int length = elements.length;
    final data = WasmArray<Object?>(length)..copy(0, elements.data, 0, length);
    return ImmutableList<E>._withData(data);
  }

  factory ImmutableList._ofEfficientLengthIterable(
    EfficientLengthIterable<E> elements,
  ) {
    final length = elements.length;
    final data = WasmArray<Object?>(length);
    int i = 0;
    for (final o in elements) data[i++] = o as E;
    if (i != length) throw ConcurrentModificationError(elements);
    return ImmutableList<E>._withData(data);
  }

  @pragma('wasm:prefer-inline')
  factory ImmutableList._fromIterable(Iterable<E> elements) {
    return GrowableList<E>._fromIterable(elements)._toUnmodifiableList();
  }
}

// Iterator for lists with fixed size.
class _FixedSizeListIterator<E> implements Iterator<E> {
  final WasmArray<Object?> _data;
  int _index;
  E? _current;

  @pragma("wasm:prefer-inline")
  _FixedSizeListIterator(WasmListBase<E> list)
    : _data = list._data,
      _index = 0 {
    assert(list is ModifiableFixedLengthList<E> || list is ImmutableList<E>);
    assert(list.length == list._data.length);
  }

  @pragma("wasm:prefer-inline")
  E get current => _current as E;

  @pragma("wasm:prefer-inline")
  bool moveNext() {
    if (_index >= _data.length) {
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
    : super._withData(data.length, data) {
    assert((() => _elementsHaveType<E>(this))());
  }

  @pragma("wasm:prefer-inline")
  GrowableList.withDataAndLength(WasmArray<Object?> data, int length)
    : super._withData(length, data) {
    assert((() => _elementsHaveType<E>(this))());
  }

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

  // Target of List.of constructor with untyped iterable and growable == true.
  factory GrowableList.ofUntypedIterable(Iterable elements) {
    // If elements is an Iterable<E>, we won't need a type-test for each
    // element.
    if (elements is Iterable<E>) {
      return GrowableList.of(elements);
    }
    // If we know the length of the list then we can avoid using growable
    // arrays.
    if (elements is EfficientLengthIterable) {
      return GrowableList._ofUntypedEfficientLengthIterable(elements);
    }

    final growableList = GrowableList<E>(0);
    for (final E o in elements) growableList.add(o);
    return growableList;
  }

  factory GrowableList._fromUntypedIterable(Iterable elements) {
    final list = GrowableList<E>(0);
    for (final E o in elements) list.add(o);
    return list;
  }

  factory GrowableList._ofUntypedEfficientLengthIterable(
    EfficientLengthIterable elements,
  ) {
    final length = elements.length;
    final data = WasmArray<Object?>(length);
    int i = 0;
    for (final E o in elements) data[i++] = o;
    if (i != length) throw ConcurrentModificationError(elements);
    return GrowableList<E>._withData(data);
  }

  // Specialization of List.of constructor for growable == true.
  factory GrowableList.of(Iterable<E> elements) {
    if (elements is WasmListBase) {
      return GrowableList._ofListBase(unsafeCast(elements));
    }
    if (elements is EfficientLengthIterable) {
      return GrowableList._ofEfficientLengthIterable(unsafeCast(elements));
    }
    return GrowableList._fromIterable(elements);
  }

  factory GrowableList._ofListBase(WasmListBase<E> elements) {
    final int length = elements.length;
    final list = GrowableList<E>(length);
    list._data.copy(0, elements._data, 0, length);
    return list;
  }

  factory GrowableList._ofEfficientLengthIterable(
    EfficientLengthIterable<E> elements,
  ) {
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

  factory GrowableList._fromIterable(Iterable<E> elements) {
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
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(index, length);

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
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(index, length);
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
    RangeErrorUtils.checkValidRange(start, end, length);
    _data.copy(start, _data, end, length - end);
    this.length = this.length - (end - start);
  }

  int get _capacity => _data.length;

  void set length(int newLength) {
    if (newLength > length) {
      // Verify that element type is nullable.
      null as E;
      if (newLength > _capacity) {
        _grow(newLength);
      }
      _setLength(newLength);
      return;
    }
    final int newCapacity = newLength;
    // We are shrinking. Pick the method which has fewer writes.
    // In the shrink-to-fit path, we write |newCapacity + newLength| words
    // (null init + copy).
    // In the non-shrink-to-fit path, we write |length - newLength| words
    // (null overwrite).
    final bool shouldShrinkToFit =
        (newCapacity + newLength) < (length - newLength);
    if (shouldShrinkToFit) {
      _shrink(newCapacity, newLength);
    } else {
      _data.fill(newLength, null, length - newLength);
    }
    _setLength(newLength);
  }

  void _setLength(int newLength) {
    _length = newLength;
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
    if (capacity == 0) {
      // Use shared empty list as backing.
      return _emptyData;
    }
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(
      capacity,
      _maxWasmArrayLength,
    );
    return WasmArray<Object?>(capacity);
  }

  // Grow from 0 to 3, and then double + 1.
  int _nextCapacity(int oldCapacity) => (oldCapacity * 2) | 3;

  void _grow(int newCapacity) {
    var newData = WasmArray<Object?>(newCapacity);
    newData.copy(0, _data, 0, length);
    _data = newData;
  }

  void _growToNextCapacity() {
    _grow(_nextCapacity(_capacity));
  }

  void _shrink(int newCapacity, int newLength) {
    var newData = _allocateData(newCapacity);
    newData.copy(0, _data, 0, newLength);
    _data = newData;
  }

  @pragma('wasm:prefer-inline')
  Iterator<E> get iterator {
    return _GrowableListIterator<E>(this);
  }

  // NOTE: May use the same backing store.
  ModifiableFixedLengthList<E> _toModifiableFixedLengthList() {
    final fixedData = data.length == length
        ? data
        : (WasmArray<Object?>(length)..copy(0, data, 0, length));
    return ModifiableFixedLengthList<E>._withData(fixedData);
  }

  // NOTE: May use the same backing store.
  ImmutableList<E> _toUnmodifiableList() {
    final fixedData = data.length == length
        ? data
        : (WasmArray<Object?>(length)..copy(0, data, 0, length));
    return ImmutableList<E>._withData(fixedData);
  }
}

// Iterator for growable lists.
class _GrowableListIterator<E> implements Iterator<E> {
  final GrowableList<E> _list;
  final int _length; // Cache list length for modification check.
  int _index;
  E? _current;

  @pragma("wasm:prefer-inline")
  _GrowableListIterator(GrowableList<E> list)
    : _list = list,
      _length = list.length,
      _index = 0;

  @pragma("wasm:prefer-inline")
  E get current => _current as E;

  @pragma("wasm:prefer-inline")
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

extension WasmListBaseUnsafeExtensions on WasmListBase {
  @pragma('wasm:prefer-inline')
  WasmArray<Object?> get data => _data;
}

bool _elementsHaveType<T>(List list) {
  for (int i = 0; i < list.length; ++i) {
    if (list[i] is! T) return false;
  }
  return true;
}
