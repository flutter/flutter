// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

@pragma("vm:entry-point")
class _GrowableList<T> extends ListBase<T> {
  void insert(int index, T element) {
    if ((index < 0) || (index > length)) {
      throw new RangeError.range(index, 0, length);
    }
    int oldLength = this.length;
    add(element);
    if (index == oldLength) {
      return;
    }
    Lists.copy(this, index, this, index + 1, oldLength - index);
    this[index] = element;
  }

  T removeAt(int index) {
    var result = this[index];
    int newLength = this.length - 1;
    if (index < newLength) {
      Lists.copy(this, index + 1, this, index, newLength - index);
    }
    this.length = newLength;
    return result;
  }

  bool remove(Object? element) {
    for (int i = 0; i < this.length; i++) {
      if (this[i] == element) {
        removeAt(i);
        return true;
      }
    }
    return false;
  }

  void insertAll(int index, Iterable<T> iterable) {
    if (index < 0 || index > length) {
      throw new RangeError.range(index, 0, length);
    }
    // TODO(floitsch): we can probably detect more cases.
    if (iterable is! List && iterable is! Set && iterable is! SubListIterable) {
      iterable = iterable.toList();
    }
    int insertionLength = iterable.length;
    // There might be errors after the length change, in which case the list
    // will end up being modified but the operation not complete. Unless we
    // always go through a "toList" we can't really avoid that.
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

  void setAll(int index, Iterable<T> iterable) {
    if (iterable is List) {
      setRange(index, index + iterable.length, iterable);
    } else {
      for (T element in iterable) {
        this[index++] = element;
      }
    }
  }

  void removeRange(int start, int end) {
    RangeError.checkValidRange(start, end, this.length);
    Lists.copy(this, end, this, start, this.length - end);
    this.length = this.length - (end - start);
  }

  List<T> sublist(int start, [int? end]) {
    final int actualEnd = RangeError.checkValidRange(start, end, this.length);
    int length = actualEnd - start;
    if (length == 0) return <T>[];
    final list = new _List(length);
    for (int i = 0; i < length; i++) {
      list[i] = this[start + i];
    }
    final result = new _GrowableList<T>._withData(list);
    result._setLength(length);
    return result;
  }

  factory _GrowableList(int length) {
    var data = _allocateData(length);
    var result = new _GrowableList<T>._withData(data);
    if (length > 0) {
      result._setLength(length);
    }
    return result;
  }

  factory _GrowableList.withCapacity(int capacity) {
    var data = _allocateData(capacity);
    return new _GrowableList<T>._withData(data);
  }

  // Specialization of List.empty constructor for growable == true.
  // Used by pkg/vm/lib/transformations/list_factory_specializer.dart.
  @pragma("vm:prefer-inline")
  factory _GrowableList.empty() {
    // Specialization of `return _GrowableList(0);`.
    return _GrowableList<T>._withData(_emptyList);
  }

  // Specialization of List.filled constructor for growable == true.
  // Used by pkg/vm/lib/transformations/list_factory_specializer.dart.
  factory _GrowableList.filled(int length, T fill) {
    final result = _GrowableList<T>(length);
    if (fill != null) {
      for (int i = 0; i < result.length; i++) {
        result[i] = fill;
      }
    }
    return result;
  }

  // Specialization of List.generate constructor for growable == true.
  // Used by pkg/vm/lib/transformations/list_factory_specializer.dart.
  @pragma("vm:prefer-inline")
  factory _GrowableList.generate(int length, T generator(int index)) {
    final result = _GrowableList<T>(length);
    for (int i = 0; i < result.length; ++i) {
      result[i] = generator(i);
    }
    return result;
  }

  // Specialization of List.of constructor for growable == true.
  factory _GrowableList.of(Iterable<T> elements) {
    if (elements is _GrowableList) {
      return _GrowableList._ofGrowableList(unsafeCast(elements));
    }
    if (elements is _Array) {
      return _GrowableList._ofArray(unsafeCast(elements));
    }
    if (elements is EfficientLengthIterable) {
      return _GrowableList._ofEfficientLengthIterable(unsafeCast(elements));
    }
    return _GrowableList._ofOther(elements);
  }

  factory _GrowableList._ofArray(_Array<T> elements) {
    final int length = elements.length;
    if (length > 0) {
      final data = _List(_adjustedCapacity(length));
      for (int i = 0; i < length; i++) {
        data[i] = elements[i];
      }
      final list = _GrowableList<T>._withData(data);
      list._setLength(length);
      return list;
    }
    return _GrowableList<T>.empty();
  }

  factory _GrowableList._ofGrowableList(_GrowableList<T> elements) {
    final int length = elements.length;
    if (length > 0) {
      final data = _List(_adjustedCapacity(length));
      for (int i = 0; i < length; i++) {
        data[i] = elements[i];
      }
      final list = _GrowableList<T>._withData(data);
      list._setLength(length);
      return list;
    }
    return _GrowableList<T>.empty();
  }

  factory _GrowableList._ofEfficientLengthIterable(
      EfficientLengthIterable<T> elements) {
    final int length = elements.length;
    if (length > 0) {
      final data = _List(_adjustedCapacity(length));
      int i = 0;
      for (var element in elements) {
        data[i++] = element;
      }
      if (i != length) throw ConcurrentModificationError(elements);
      final list = _GrowableList<T>._withData(data);
      list._setLength(length);
      return list;
    }
    return _GrowableList<T>.empty();
  }

  factory _GrowableList._ofOther(Iterable<T> elements) {
    final list = _GrowableList<T>(0);
    for (var elements in elements) {
      list.add(elements);
    }
    return list;
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type",
      <dynamic>[_GrowableList, "result-type-uses-passed-type-arguments"])
  @pragma("vm:external-name", "GrowableList_allocate")
  external factory _GrowableList._withData(_List data);

  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  @pragma("vm:prefer-inline")
  @pragma("vm:external-name", "GrowableList_getCapacity")
  external int get _capacity;

  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  @pragma("vm:prefer-inline")
  @pragma("vm:external-name", "GrowableList_getLength")
  external int get length;

  void set length(int new_length) {
    if (new_length > length) {
      // Verify that element type is nullable.
      null as T;
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
      for (int i = new_length; i < length; i++) {
        _setIndexed(i, null);
      }
    }
    _setLength(new_length);
  }

  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:external-name", "GrowableList_setLength")
  external void _setLength(int new_length);

  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:external-name", "GrowableList_setData")
  external void _setData(_List array);

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external T operator [](int index);

  @pragma("vm:recognized", "other")
  void operator []=(int index, T value) {
    _setIndexed(index, value);
  }

  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:external-name", "GrowableList_setIndexed")
  external void _setIndexed(int index, T? value);

  @pragma("vm:entry-point", "call")
  @pragma("vm:prefer-inline")
  void add(T value) {
    var len = length;
    if (len == _capacity) {
      _growToNextCapacity();
    }
    _setLength(len + 1);
    this[len] = value;
  }

  void addAll(Iterable<T> iterable) {
    var len = length;
    final cid = ClassID.getID(iterable);
    final isVMList = (cid == ClassID.cidArray) ||
        (cid == ClassID.cidGrowableObjectArray) ||
        (cid == ClassID.cidImmutableArray);
    if (isVMList || (iterable is EfficientLengthIterable)) {
      var cap = _capacity;
      // Pregrow if we know iterable.length.
      var iterLen = iterable.length;
      if (iterLen == 0) {
        return;
      }
      var newLen = len + iterLen;
      if (newLen > cap) {
        do {
          cap = _nextCapacity(cap);
        } while (newLen > cap);
        _grow(cap);
      }
      if (isVMList) {
        if (identical(iterable, this)) {
          throw new ConcurrentModificationError(this);
        }
        this._setLength(newLen);
        final ListBase<T> iterableAsList = iterable as ListBase<T>;
        for (int i = 0; i < iterLen; i++) {
          this[len++] = iterableAsList[i];
        }
        return;
      }
    }
    Iterator it = iterable.iterator;
    if (!it.moveNext()) return;
    do {
      while (len < _capacity) {
        int newLen = len + 1;
        this._setLength(newLen);
        this[len] = it.current;
        if (!it.moveNext()) return;
        if (this.length != newLen) throw new ConcurrentModificationError(this);
        len = newLen;
      }
      _growToNextCapacity();
    } while (true);
  }

  @pragma("vm:prefer-inline")
  T removeLast() {
    var len = length - 1;
    var elem = this[len];
    this.length = len;
    return elem;
  }

  T get first {
    if (length > 0) return this[0];
    throw IterableElementError.noElement();
  }

  T get last {
    if (length > 0) return this[length - 1];
    throw IterableElementError.noElement();
  }

  T get single {
    if (length == 1) return this[0];
    if (length == 0) throw IterableElementError.noElement();
    throw IterableElementError.tooMany();
  }

  // Shared array used as backing for new empty growable arrays.
  static final _List _emptyList = new _List(0);

  static _List _allocateData(int capacity) {
    if (capacity == 0) {
      // Use shared empty list as backing.
      return _emptyList;
    }
    return _List(_adjustedCapacity(capacity));
  }

  // Round up size to the next odd number, since this is free
  // because of alignment requirements of the GC.
  static int _adjustedCapacity(int capacity) => capacity | 1;

  // Grow from 0 to 3, and then double + 1.
  int _nextCapacity(int old_capacity) => (old_capacity * 2) | 3;

  void _grow(int new_capacity) {
    var newData = _allocateData(new_capacity);
    // This is a workaround for dartbug.com/30090: array-bound-check
    // generalization causes excessive deoptimizations because it
    // hoists CheckArrayBound(i, ...) out of the loop below and turns it
    // into CheckArrayBound(length - 1, ...). Which deoptimizes
    // if length == 0. However the loop itself does not execute
    // if length == 0.
    if (length > 0) {
      for (int i = 0; i < length; i++) {
        newData[i] = this[i];
      }
    }
    _setData(newData);
  }

  // This method is marked as never-inline to conserve code size.
  // It is called in rare cases, but used in the add() which is
  // used very often and always inlined.
  @pragma("vm:never-inline")
  void _growToNextCapacity() {
    _grow(_nextCapacity(_capacity));
  }

  void _shrink(int new_capacity, int new_length) {
    var newData = _allocateData(new_capacity);
    // This is a workaround for dartbug.com/30090. See the comment in _grow.
    if (new_length > 0) {
      for (int i = 0; i < new_length; i++) {
        newData[i] = this[i];
      }
    }
    _setData(newData);
  }

  // Iterable interface.

  @pragma("vm:prefer-inline")
  void forEach(f(T element)) {
    int initialLength = length;
    for (int i = 0; i < length; i++) {
      f(this[i]);
      if (length != initialLength) throw new ConcurrentModificationError(this);
    }
  }

  String join([String separator = ""]) {
    final int length = this.length;
    if (length == 0) return "";
    if (length == 1) return "${this[0]}";
    if (separator.isNotEmpty) return _joinWithSeparator(separator);
    var i = 0;
    var codeUnitCount = 0;
    while (i < length) {
      final element = this[i];
      // While list contains one-byte strings.
      if (element is _OneByteString) {
        codeUnitCount += element.length;
        i++;
        // Loop back while strings are one-byte strings.
        continue;
      }
      // Otherwise, never loop back to the outer loop, and
      // handle the remaining strings below.

      // Loop while elements are strings,
      final int firstNonOneByteStringLimit = i;
      var nextElement = element;
      while (nextElement is String) {
        i++;
        if (i == length) {
          return _StringBase._concatRangeNative(this, 0, length);
        }
        nextElement = this[i];
      }

      // Not all elements are strings, so allocate a new backing array.
      final list = new _List(length);
      for (int copyIndex = 0; copyIndex < i; copyIndex++) {
        list[copyIndex] = this[copyIndex];
      }
      // Is non-zero if list contains a non-onebyte string.
      var onebyteCanary = i - firstNonOneByteStringLimit;
      while (true) {
        final String elementString = "$nextElement";
        onebyteCanary |=
            (ClassID.getID(elementString) ^ ClassID.cidOneByteString);
        list[i] = elementString;
        codeUnitCount += elementString.length;
        i++;
        if (i == length) break;
        nextElement = this[i];
      }
      if (onebyteCanary == 0) {
        // All elements returned a one-byte string from toString.
        return _OneByteString._concatAll(list, codeUnitCount);
      }
      return _StringBase._concatRangeNative(list, 0, length);
    }
    // All elements were one-byte strings.
    return _OneByteString._concatAll(this, codeUnitCount);
  }

  String _joinWithSeparator(String separator) {
    StringBuffer buffer = new StringBuffer();
    buffer.write(this[0]);
    for (int i = 1; i < this.length; i++) {
      buffer.write(separator);
      buffer.write(this[i]);
    }
    return buffer.toString();
  }

  T elementAt(int index) {
    return this[index];
  }

  bool get isEmpty {
    return this.length == 0;
  }

  bool get isNotEmpty => !isEmpty;

  void clear() {
    this.length = 0;
  }

  String toString() => ListBase.listToString(this);

  @pragma("vm:prefer-inline")
  Iterator<T> get iterator {
    return new ListIterator<T>(this);
  }

  List<T> toList({bool growable = true}) {
    // TODO(sra): We should be able to replace the following with:
    //
    //     return growable
    //         ? _GrowableList<T>._ofGrowableList(this)
    //         : _List<T>._ofGrowableList(this);
    //
    // However, the extra call causes a 5% regression in `ListCopy.toList.2`.

    final length = this.length;
    if (growable) {
      if (length > 0) {
        final data = new _List(_adjustedCapacity(length));
        for (int i = 0; i < length; i++) {
          data[i] = this[i];
        }
        final result = new _GrowableList<T>._withData(data);
        result._setLength(length);
        return result;
      }
      return <T>[];
    } else {
      if (length > 0) {
        final list = new _List<T>(length);
        for (int i = 0; i < length; i++) {
          list[i] = this[i];
        }
        return list;
      }
      return List<T>.empty(growable: false);
    }
  }

  Set<T> toSet() {
    return new Set<T>.of(this);
  }

  // Factory constructing a mutable List from a parser generated List literal.
  // [elements] contains elements that are already type checked.
  @pragma("vm:entry-point", "call")
  factory _GrowableList._literal(_List elements) {
    final result = new _GrowableList<T>._withData(elements);
    result._setLength(elements.length);
    return result;
  }

  // Specialized list literal constructors.
  // Used by pkg/vm/lib/transformations/list_literals_lowering.dart.
  factory _GrowableList._literal1(T e0) {
    _List elements = _List(1);
    elements[0] = e0;
    final result = new _GrowableList<T>._withData(elements);
    result._setLength(1);
    return result;
  }

  factory _GrowableList._literal2(T e0, T e1) {
    _List elements = _List(2);
    elements[0] = e0;
    elements[1] = e1;
    final result = new _GrowableList<T>._withData(elements);
    result._setLength(2);
    return result;
  }

  factory _GrowableList._literal3(T e0, T e1, T e2) {
    _List elements = _List(3);
    elements[0] = e0;
    elements[1] = e1;
    elements[2] = e2;
    final result = new _GrowableList<T>._withData(elements);
    result._setLength(3);
    return result;
  }

  factory _GrowableList._literal4(T e0, T e1, T e2, T e3) {
    _List elements = _List(4);
    elements[0] = e0;
    elements[1] = e1;
    elements[2] = e2;
    elements[3] = e3;
    final result = new _GrowableList<T>._withData(elements);
    result._setLength(4);
    return result;
  }

  factory _GrowableList._literal5(T e0, T e1, T e2, T e3, T e4) {
    _List elements = _List(5);
    elements[0] = e0;
    elements[1] = e1;
    elements[2] = e2;
    elements[3] = e3;
    elements[4] = e4;
    final result = new _GrowableList<T>._withData(elements);
    result._setLength(5);
    return result;
  }

  factory _GrowableList._literal6(T e0, T e1, T e2, T e3, T e4, T e5) {
    _List elements = _List(6);
    elements[0] = e0;
    elements[1] = e1;
    elements[2] = e2;
    elements[3] = e3;
    elements[4] = e4;
    elements[5] = e5;
    final result = new _GrowableList<T>._withData(elements);
    result._setLength(6);
    return result;
  }

  factory _GrowableList._literal7(T e0, T e1, T e2, T e3, T e4, T e5, T e6) {
    _List elements = _List(7);
    elements[0] = e0;
    elements[1] = e1;
    elements[2] = e2;
    elements[3] = e3;
    elements[4] = e4;
    elements[5] = e5;
    elements[6] = e6;
    final result = new _GrowableList<T>._withData(elements);
    result._setLength(7);
    return result;
  }

  factory _GrowableList._literal8(
      T e0, T e1, T e2, T e3, T e4, T e5, T e6, T e7) {
    _List elements = _List(8);
    elements[0] = e0;
    elements[1] = e1;
    elements[2] = e2;
    elements[3] = e3;
    elements[4] = e4;
    elements[5] = e5;
    elements[6] = e6;
    elements[7] = e7;
    final result = new _GrowableList<T>._withData(elements);
    result._setLength(8);
    return result;
  }
}
