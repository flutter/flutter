// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._js_types;

// TODO(joshualitt): Refactor indexing here and in `js_string` to elide range
// checks for internal functions.
class JSArrayImpl<T extends JSAny?> implements List<T> {
  final WasmExternRef? _ref;

  JSArrayImpl(this._ref);

  factory JSArrayImpl.fromLength(int length) =>
      JSArrayImpl<T>(js.newArrayFromLengthRaw(length));

  static JSArrayImpl<T>? box<T extends JSAny?>(WasmExternRef? ref) =>
      js.isDartNull(ref) ? null : JSArrayImpl<T>(ref);

  WasmExternRef? get toExternRef => _ref;

  @override
  List<R> cast<R>() => List.castFrom<T, R>(this);

  @override
  void add(T value) =>
      js.JS<void>('(a, i) => a.push(i)', toExternRef, value.toExternRef);

  @override
  T removeAt(int index) {
    RangeError.checkValueInInterval(index, 0, length - 1);
    return js.JSValue.boxT<T>(js.JS<WasmExternRef?>(
        '(a, i) => a.splice(i, 1)[0]', toExternRef, WasmI32.fromInt(index)));
  }

  @override
  void insert(int index, T value) {
    RangeError.checkValueInInterval(index, 0, length);
    js.JS<void>('(a, i, v) => a.splice(i, 0, v)', toExternRef,
        WasmI32.fromInt(index), value.toExternRef);
  }

  void _setLengthUnsafe(int newLength) => js.JS<void>(
      '(a, l) => a.length = l', toExternRef, WasmI32.fromInt(newLength));

  @override
  void insertAll(int index, Iterable<T> iterable) {
    RangeError.checkValueInInterval(index, 0, length);
    final that =
        iterable is EfficientLengthIterable ? iterable : iterable.toList();
    final thatLength = that.length;
    _setLengthUnsafe(length + thatLength);
    final end = index + thatLength;
    setRange(end, length, this, index);
    setRange(index, end, iterable);
  }

  @override
  void setAll(int index, Iterable<T> iterable) {
    RangeError.checkValueInInterval(index, 0, length);
    for (final element in iterable) {
      this[index++] = element;
    }
  }

  @override
  T removeLast() =>
      js.JSValue.boxT<T>(js.JS<WasmExternRef?>('a => a.pop()', toExternRef));

  @override
  bool remove(Object? element) {
    for (var i = 0; i < length; i++) {
      if (this[i] == element) {
        js.JS<void>(
            '(a, i) => a.splice(i, 1)', toExternRef, WasmI32.fromInt(i));
        return true;
      }
    }
    return false;
  }

  @override
  void removeWhere(bool Function(T) test) => _retainWhere(test, false);

  @override
  void retainWhere(bool Function(T) test) => _retainWhere(test, true);

  void _retainWhere(bool Function(T) test, bool retainMatching) {
    final retained = <T>[];
    final end = length;
    for (var i = 0; i < end; i++) {
      final element = this[i];
      if (test(element) == retainMatching) {
        retained.add(element);
      }
      if (length != end) throw ConcurrentModificationError(this);
    }
    if (retained.length == end) return;
    final newLength = retained.length;
    _setLengthUnsafe(newLength);
    for (var i = 0; i < newLength; i++) {
      this[i] = retained[i];
    }
  }

  @override
  Iterable<T> where(bool Function(T) f) {
    return WhereIterable<T>(this, f);
  }

  @override
  Iterable<U> expand<U>(Iterable<U> Function(T) f) {
    return ExpandIterable<T, U>(this, f);
  }

  @override
  void addAll(Iterable<T> collection) {
    for (final v in collection) {
      add(v);
    }
  }

  @override
  void clear() {
    _setLengthUnsafe(0);
  }

  @override
  void forEach(void Function(T) f) {
    final end = length;
    for (var i = 0; i < end; i++) {
      f(this[i]);
      if (length != end) throw ConcurrentModificationError(this);
    }
  }

  @override
  Iterable<U> map<U>(U Function(T) f) => MappedListIterable<T, U>(this, f);

  @override
  String join([String separator = ""]) {
    WasmExternRef? result;
    if (separator is JSStringImpl) {
      result = js.JS<WasmExternRef?>(
          '(a, s) => a.join(s)', toExternRef, separator.toExternRef);
    } else {
      result = js.JS<WasmExternRef?>(
          '(a, s) => a.join(s)', toExternRef, separator.toJS.toExternRef);
    }
    return JSStringImpl(result);
  }

  @override
  Iterable<T> take(int n) => SubListIterable<T>(this, 0, n);

  @override
  Iterable<T> takeWhile(bool test(T value)) => TakeWhileIterable<T>(this, test);

  @override
  Iterable<T> skip(int n) => SubListIterable<T>(this, n, null);

  @override
  Iterable<T> skipWhile(bool Function(T) test) =>
      SkipWhileIterable<T>(this, test);

  @override
  T reduce(T combine(T previousValue, T element)) {
    final end = length;
    if (end == 0) throw IterableElementError.noElement();
    T value = this[0];
    for (var i = 1; i < end; i++) {
      final element = this[i];
      value = combine(value, element);
      if (end != length) throw ConcurrentModificationError(this);
    }
    return value;
  }

  @override
  U fold<U>(U initialValue, U Function(U previousValue, T element) combine) {
    final end = length;
    var value = initialValue;
    for (int i = 0; i < end; i++) {
      final element = this[i];
      value = combine(value, element);
      if (end != length) throw ConcurrentModificationError(this);
    }
    return value;
  }

  @override
  T firstWhere(bool Function(T) test, {T Function()? orElse}) {
    final end = length;
    for (int i = 0; i < end; i++) {
      final element = this[i];
      if (test(element)) return element;
      if (end != length) throw ConcurrentModificationError(this);
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  @override
  T lastWhere(bool Function(T) test, {T Function()? orElse}) {
    final end = length;
    for (int i = end - 1; i >= 0; i--) {
      final element = this[i];
      if (test(element)) return element;
      if (end != length) throw ConcurrentModificationError(this);
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  @override
  T singleWhere(bool Function(T) test, {T Function()? orElse}) {
    final end = length;
    late T match;
    var matchFound = false;
    for (int i = 0; i < end; i++) {
      final element = this[i];
      if (test(element)) {
        if (matchFound) {
          throw IterableElementError.tooMany();
        }
        matchFound = true;
        match = element;
      }
      if (end != length) throw ConcurrentModificationError(this);
    }
    if (matchFound) return match;
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  @override
  T elementAt(int index) => this[index];

  @override
  List<T> sublist(int start, [int? end]) {
    end = RangeError.checkValidRange(start, end, length);
    return JSArrayImpl<T>(js.JS<WasmExternRef?>('(a, s, e) => a.slice(s, e)',
        toExternRef, WasmI32.fromInt(start), WasmI32.fromInt(end)));
  }

  @override
  Iterable<T> getRange(int start, int end) {
    RangeError.checkValidRange(start, end, length);
    return SubListIterable<T>(this, start, end);
  }

  @override
  T get first {
    if (length > 0) return this[0];
    throw IterableElementError.noElement();
  }

  @override
  T get last {
    if (length > 0) return this[length - 1];
    throw IterableElementError.noElement();
  }

  @override
  T get single {
    if (length == 1) return this[0];
    if (length == 0) throw IterableElementError.noElement();
    throw IterableElementError.tooMany();
  }

  @override
  void removeRange(int start, int end) {
    RangeError.checkValidRange(start, end, length);
    int deleteCount = end - start;
    js.JS<void>('(a, s, e) => a.splice(s, e)', toExternRef,
        WasmI32.fromInt(start), WasmI32.fromInt(deleteCount));
  }

  @override
  void setRange(int start, int end, Iterable<T> iterable, [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, length);
    final rangeLength = end - start;
    if (rangeLength == 0) return;
    RangeError.checkNotNegative(skipCount);

    // TODO(joshualitt): Fast path for when iterable is JS backed.
    List<T> otherList;
    int otherStart;
    if (iterable is List<T>) {
      otherList = iterable;
      otherStart = skipCount;
    } else {
      otherList = iterable.skip(skipCount).toList(growable: false);
      otherStart = 0;
    }
    if (otherStart + rangeLength > otherList.length)
      throw IterableElementError.tooFew();

    if (otherStart < start) {
      // Copy backwards to ensure correct copy if [from] is this.
      for (var i = rangeLength - 1; i >= 0; i--) {
        this[start + i] = otherList[otherStart + i];
      }
    } else {
      for (var i = 0; i < rangeLength; i++) {
        this[start + i] = otherList[otherStart + i];
      }
    }
  }

  @override
  void fillRange(int start, int end, [T? fillValue]) {
    RangeError.checkValidRange(start, end, length);
    for (var i = start; i < end; i++) {
      this[i] = fillValue as T;
    }
  }

  @override
  void replaceRange(int start, int end, Iterable<T> replacement) {
    RangeError.checkValidRange(start, end, length);
    final replacementList = replacement is EfficientLengthIterable
        ? replacement
        : replacement.toList();
    final removeLength = end - start;
    final insertLength = replacementList.length;
    if (removeLength >= insertLength) {
      final delta = removeLength - insertLength;
      final insertEnd = start + insertLength;
      final newLength = length - delta;
      setRange(start, insertEnd, replacementList);
      if (delta != 0) {
        setRange(insertEnd, newLength, this, end);
        _setLengthUnsafe(newLength);
      }
    } else {
      final delta = insertLength - removeLength;
      final newLength = length + delta;
      final insertEnd = start + insertLength;
      _setLengthUnsafe(newLength);
      setRange(insertEnd, newLength, this, end);
      setRange(start, insertEnd, replacementList);
    }
  }

  @override
  bool any(bool test(T element)) {
    final end = length;
    for (var i = 0; i < end; i++) {
      final element = this[i];
      if (test(element)) return true;
      if (end != length) throw ConcurrentModificationError(this);
    }
    return false;
  }

  @override
  bool every(bool test(T element)) {
    final end = length;
    for (var i = 0; i < end; i++) {
      final element = this[i];
      if (!test(element)) return false;
      if (end != length) throw ConcurrentModificationError(this);
    }
    return true;
  }

  @override
  Iterable<T> get reversed => ReversedListIterable<T>(this);

  static int _compareAny<T extends JSAny?>(T a, T b) => js
      .JS<double>('(a, b) => a == b ? 0 : (a > b ? 1 : -1)', a.toExternRef,
          b.toExternRef)
      .toInt();

  @override
  void sort([int Function(T, T)? compare]) =>
      Sort.sort(this, compare ?? _compareAny<T>);

  @override
  void shuffle([Random? random]) {
    random ??= Random();
    int shufflePoint = length;
    while (shufflePoint > 1) {
      final pos = random.nextInt(shufflePoint);
      shufflePoint--;
      final tmp = this[shufflePoint];
      this[shufflePoint] = this[pos];
      this[pos] = tmp;
    }
  }

  @override
  int indexOf(Object? element, [int start = 0]) {
    if (start >= length) {
      return -1;
    }
    if (start < 0) {
      start = 0;
    }
    for (var i = start; i < length; i++) {
      if (this[i] == element) {
        return i;
      }
    }
    return -1;
  }

  @override
  int lastIndexOf(Object? element, [int? startIndex]) {
    var start = startIndex ?? length - 1;
    if (start >= length) {
      start = length - 1;
    } else if (start < 0) {
      return -1;
    }
    for (var i = start; i >= 0; i--) {
      if (this[i] == element) {
        return i;
      }
    }
    return -1;
  }

  @override
  bool contains(Object? other) {
    for (final element in this) {
      if (element == other) {
        return true;
      }
    }
    return false;
  }

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  String toString() => ListBase.listToString(this);

  @override
  List<T> toList({bool growable = true}) =>
      List<T>.of(this, growable: growable);

  @override
  Set<T> toSet() => Set<T>.from(this);

  @override
  Iterator<T> get iterator => JSArrayImplIterator<T>(this);

  @override
  int get length => js.JS<double>('a => a.length', toExternRef).toInt();

  void set length(int newLength) {
    if (newLength < 0) {
      throw RangeError.range(newLength, 0, null);
    }
    js.JS<void>(
        '(a, l) => a.length = l', toExternRef, WasmI32.fromInt(newLength));
  }

  @pragma("wasm:prefer-inline")
  T _getUnchecked(int index) => js.JSValue.boxT<T>(js.JS<WasmExternRef?>(
      '(a, i) => a[i]', toExternRef, WasmI32.fromInt(index)));

  @override
  @pragma("wasm:prefer-inline")
  T operator [](int index) {
    IndexErrorUtils.checkAssumePositiveLength(index, length);
    return _getUnchecked(index);
  }

  @pragma("wasm:prefer-inline")
  void _setUnchecked(int index, T value) => js.JS<void>('(a, i, v) => a[i] = v',
      toExternRef, WasmI32.fromInt(index), value.toExternRef);

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, T value) {
    IndexErrorUtils.checkAssumePositiveLength(index, length);
    _setUnchecked(index, value);
  }

  @override
  Map<int, T> asMap() => ListMapView<T>(this);

  @override
  Iterable<T> followedBy(Iterable<T> other) =>
      FollowedByIterable<T>.firstEfficient(this, other);

  @override
  Iterable<T> whereType<T>() => WhereTypeIterable<T>(this);

  @override
  List<T> operator +(List<T> other) {
    if (other is JSArrayImpl) {
      return JSArrayImpl<T>(js.JS<WasmExternRef?>(
          '(a, t) => a.concat(t)', toExternRef, other.toExternRef));
    } else {
      return [...this, ...other];
    }
  }

  @override
  int indexWhere(bool Function(T) test, [int start = 0]) {
    if (start >= length) {
      return -1;
    }
    if (start < 0) {
      start = 0;
    }
    for (var i = start; i < length; i++) {
      if (test(this[i])) {
        return i;
      }
    }
    return -1;
  }

  @override
  int lastIndexWhere(bool Function(T) test, [int? start]) {
    if (start == null) {
      start = length - 1;
    }
    if (start < 0) {
      return -1;
    }
    for (var i = start; i >= 0; i--) {
      if (test(this[i])) {
        return i;
      }
    }
    return -1;
  }

  void set first(T element) {
    if (isEmpty) {
      throw IterableElementError.noElement();
    }
    this[0] = element;
  }

  void set last(T element) {
    if (isEmpty) {
      throw IterableElementError.noElement();
    }
    this[length - 1] = element;
  }

  // TODO(joshualitt): Override hash code and operator==?
}

class JSArrayImplIterator<T extends JSAny?> implements Iterator<T> {
  final JSArrayImpl<T> _array;
  final int _length;
  int _index = -1;

  JSArrayImplIterator(this._array) : _length = _array.length {}

  T get current => _array[_index];

  bool moveNext() {
    if (_length != _array.length) {
      throw ConcurrentModificationError(_array);
    }
    if (_index >= _length - 1) {
      return false;
    }
    _index++;
    return true;
  }
}
