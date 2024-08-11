// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

abstract class _Array<E> extends FixedLengthListBase<E> {
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external E operator [](int index);

  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  @pragma("vm:prefer-inline")
  @pragma("vm:external-name", "List_getLength")
  external int get length;

  @pragma("vm:prefer-inline")
  _List _slice(int start, int count, bool needsTypeArgument) {
    if (count <= 64) {
      final result = needsTypeArgument ? new _List<E>(count) : new _List(count);
      for (int i = 0; i < result.length; i++) {
        result[i] = this[start + i];
      }
      return result;
    } else {
      return _sliceInternal(start, count, needsTypeArgument);
    }
  }

  @pragma("vm:external-name", "List_slice")
  external _List _sliceInternal(int start, int count, bool needsTypeArgument);

  // Iterable interface.

  @pragma("vm:prefer-inline")
  void forEach(f(E element)) {
    final length = this.length;
    for (int i = 0; i < length; i++) {
      f(this[i]);
    }
  }

  @pragma("vm:prefer-inline")
  Iterator<E> get iterator {
    return new _ArrayIterator<E>(this);
  }

  E get first {
    if (length > 0) return this[0];
    throw IterableElementError.noElement();
  }

  E get last {
    if (length > 0) return this[length - 1];
    throw IterableElementError.noElement();
  }

  E get single {
    if (length == 1) return this[0];
    if (length == 0) throw IterableElementError.noElement();
    throw IterableElementError.tooMany();
  }

  List<E> toList({bool growable = true}) {
    var length = this.length;
    if (length > 0) {
      _List result = _slice(0, length, !growable);
      if (growable) {
        return new _GrowableList<E>._withData(result).._setLength(length);
      }
      return unsafeCast<_List<E>>(result);
    }
    // _GrowableList._withData must not be called with empty list.
    return growable ? <E>[] : new _List<E>(0);
  }
}

// Known to the VM as kArrayCid.
@pragma("vm:entry-point")
class _List<E> extends _Array<E> {
  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type",
      <dynamic>[_List, "result-type-uses-passed-type-arguments"])
  @pragma("vm:prefer-inline")
  @pragma("vm:external-name", "List_allocate")
  external factory _List(length);

  // Specialization of List.empty constructor for growable == false.
  // Used by pkg/vm/lib/transformations/list_factory_specializer.dart.
  @pragma("vm:prefer-inline")
  factory _List.empty() => _List<E>(0);

  // Specialization of List.filled constructor for growable == false.
  // Used by pkg/vm/lib/transformations/list_factory_specializer.dart.
  factory _List.filled(int length, E fill) {
    final result = _List<E>(length);
    if (fill != null) {
      for (int i = 0; i < result.length; i++) {
        result[i] = fill;
      }
    }
    return result;
  }

  // Specialization of List.generate constructor for growable == false.
  // Used by pkg/vm/lib/transformations/list_factory_specializer.dart.
  @pragma("vm:prefer-inline")
  factory _List.generate(int length, E generator(int index)) {
    final result = _List<E>(length);
    for (int i = 0; i < result.length; ++i) {
      result[i] = generator(i);
    }
    return result;
  }

  // Specialization of List.of constructor for growable == false.
  @pragma("vm:always-consider-inlining")
  factory _List.of(Iterable<E> elements) {
    if (elements is _GrowableList) {
      return _List._ofGrowableList(unsafeCast(elements));
    }
    if (elements is _Array) {
      return _List._ofArray(unsafeCast(elements));
    }
    if (elements is EfficientLengthIterable) {
      return _List._ofEfficientLengthIterable(unsafeCast(elements));
    }
    return _List._ofOther(elements);
  }

  factory _List._ofGrowableList(_GrowableList<E> elements) {
    final int length = elements.length;
    final list = _List<E>(length);
    // TODO(30102): Remove this loop zero-trip guard.
    if (length > 0) {
      for (int i = 0; i < length; i++) {
        list[i] = elements[i];
      }
    }
    return list;
  }

  factory _List._ofArray(_Array<E> elements) {
    final int length = elements.length;
    final list = _List<E>(length);
    // TODO(30102): Remove this loop zero-trip guard.
    if (length > 0) {
      for (int i = 0; i < length; i++) {
        list[i] = elements[i];
      }
    }
    return list;
  }

  factory _List._ofEfficientLengthIterable(
      EfficientLengthIterable<E> elements) {
    final int length = elements.length;
    final list = _List<E>(length);
    if (length > 0) {
      int i = 0;
      for (var element in elements) {
        list[i++] = element;
      }
      if (i != length) throw ConcurrentModificationError(elements);
    }
    return list;
  }

  factory _List._ofOther(Iterable<E> elements) {
    // The static type of `makeListFixedLength` is `List<E>`, not `_List<E>`,
    // but we know that is what it does.  `makeListFixedLength` is too generally
    // typed since it is available on the web platform which has different
    // system List types.
    return unsafeCast(makeListFixedLength(_GrowableList<E>._ofOther(elements)));
  }

  @pragma("vm:recognized", "other")
  void operator []=(int index, E value) {
    _setIndexed(index, value);
  }

  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:external-name", "List_setIndexed")
  external void _setIndexed(int index, E value);

  // List interface.
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    if (start < 0 || start > this.length) {
      throw new RangeError.range(start, 0, this.length);
    }
    if (end < start || end > this.length) {
      throw new RangeError.range(end, start, this.length);
    }
    int length = end - start;
    if (length == 0) return;
    if (identical(this, iterable)) {
      Lists.copy(this, skipCount, this, start, length);
    } else if (ClassID.getID(iterable) == ClassID.cidArray) {
      final _List<E> iterableAsList = unsafeCast<_List<E>>(iterable);
      Lists.copy(iterableAsList, skipCount, this, start, length);
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
        this[i] = it.current;
      }
    }
  }

  void setAll(int index, Iterable<E> iterable) {
    if (index < 0 || index > this.length) {
      throw new RangeError.range(index, 0, this.length, "index");
    }
    List<E> iterableAsList;
    if (identical(this, iterable)) {
      iterableAsList = this;
    } else if (ClassID.getID(iterable) == ClassID.cidArray) {
      iterableAsList = unsafeCast<_List<E>>(iterable);
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
      throw new RangeError.range(index + length, 0, this.length);
    }
    Lists.copy(iterableAsList, 0, this, index, length);
  }

  List<E> sublist(int start, [int? end]) {
    final int listLength = this.length;
    final int actualEnd = RangeError.checkValidRange(start, end, listLength);
    int length = actualEnd - start;
    if (length == 0) return <E>[];
    var result = new _GrowableList<E>._withData(_slice(start, length, false));
    result._setLength(length);
    return result;
  }
}

// Known to the VM as kImmutableArrayCid.
@pragma("vm:entry-point")
class _ImmutableList<E> extends _Array<E> with UnmodifiableListMixin<E> {
  factory _ImmutableList._uninstantiable() {
    throw new UnsupportedError(
        "ImmutableArray can only be allocated by the VM");
  }

  @pragma("vm:external-name", "ImmutableList_from")
  external factory _ImmutableList._from(List from, int offset, int length);
}

// Iterator for arrays.
class _ArrayIterator<E> implements Iterator<E> {
  final _Array<E> _array;
  final int _length; // Cache array length for faster access.
  int _index;
  E? _current;

  _ArrayIterator(_Array<E> array)
      : _array = array,
        _length = array.length,
        _index = 0 {}

  E get current => _current as E;

  @pragma("vm:prefer-inline")
  bool moveNext() {
    if (_index >= _length) {
      _current = null;
      return false;
    }
    _current = _array[_index];
    _index++;
    return true;
  }
}
