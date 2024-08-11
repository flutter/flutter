// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._js_types;

/// A JS `ArrayBuffer`.
final class JSArrayBufferImpl implements ByteBuffer {
  /// `externref` of a JS `ArrayBuffer`.
  final WasmExternRef? _ref;

  final bool _immutable;

  JSArrayBufferImpl.fromRef(this._ref) : _immutable = false;

  JSArrayBufferImpl.fromRefImmutable(this._ref) : _immutable = true;

  @pragma("wasm:prefer-inline")
  WasmExternRef? get toExternRef => _ref;

  /// Get a JS `DataView` of this `ArrayBuffer`.
  WasmExternRef? view(int offsetInBytes, int? length) =>
      _newDataViewFromArrayBuffer(toExternRef, offsetInBytes, length);

  WasmExternRef? cloneAsDataView(int offsetInBytes, int? lengthInBytes) {
    lengthInBytes ??= this.lengthInBytes;
    return js.JS<WasmExternRef?>('''(o, offsetInBytes, lengthInBytes) => {
      var dst = new ArrayBuffer(lengthInBytes);
      new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
      return new DataView(dst);
    }''', toExternRef, offsetInBytes.toDouble(), lengthInBytes.toDouble());
  }

  @override
  @pragma("wasm:prefer-inline")
  int get lengthInBytes => _arrayBufferByteLength(toExternRef);

  @override
  Uint8List asUint8List([int offsetInBytes = 0, int? length]) {
    final view = JSUint8ArrayImpl.view(this, offsetInBytes, length);
    return _immutable ? view.asUnmodifiableView() : view;
  }

  @override
  Int8List asInt8List([int offsetInBytes = 0, int? length]) {
    final view = JSInt8ArrayImpl.view(this, offsetInBytes, length);
    return _immutable ? view.asUnmodifiableView() : view;
  }

  @override
  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int? length]) {
    final view = JSUint8ClampedArrayImpl.view(this, offsetInBytes, length);
    return _immutable ? view.asUnmodifiableView() : view;
  }

  @override
  Uint16List asUint16List([int offsetInBytes = 0, int? length]) {
    final view = JSUint16ArrayImpl.view(this, offsetInBytes, length);
    return _immutable ? view.asUnmodifiableView() : view;
  }

  @override
  Int16List asInt16List([int offsetInBytes = 0, int? length]) {
    final view = JSInt16ArrayImpl.view(this, offsetInBytes, length);
    return _immutable ? view.asUnmodifiableView() : view;
  }

  @override
  Uint32List asUint32List([int offsetInBytes = 0, int? length]) {
    final view = JSUint32ArrayImpl.view(this, offsetInBytes, length);
    return _immutable ? view.asUnmodifiableView() : view;
  }

  @override
  Int32List asInt32List([int offsetInBytes = 0, int? length]) {
    final view = JSInt32ArrayImpl.view(this, offsetInBytes, length);
    return _immutable ? view.asUnmodifiableView() : view;
  }

  @override
  Uint64List asUint64List([int offsetInBytes = 0, int? length]) {
    final view = JSBigUint64ArrayImpl.view(this, offsetInBytes, length);
    return _immutable ? view.asUnmodifiableView() : view;
  }

  @override
  Int64List asInt64List([int offsetInBytes = 0, int? length]) {
    final view = JSBigInt64ArrayImpl.view(this, offsetInBytes, length);
    return _immutable ? view.asUnmodifiableView() : view;
  }

  @override
  Int32x4List asInt32x4List([int offsetInBytes = 0, int? length]) {
    _offsetAlignmentCheck(offsetInBytes, Int32x4List.bytesPerElement);
    length ??= (lengthInBytes - offsetInBytes) ~/ Int32x4List.bytesPerElement;
    final storage = JSInt32ArrayImpl.view(this, offsetInBytes, length * 4);
    final view = JSInt32x4ArrayImpl.externalStorage(storage);
    return _immutable ? view.asUnmodifiableView() : view;
  }

  @override
  Float32List asFloat32List([int offsetInBytes = 0, int? length]) {
    final view = JSFloat32ArrayImpl.view(this, offsetInBytes, length);
    return _immutable ? view.asUnmodifiableView() : view;
  }

  @override
  Float64List asFloat64List([int offsetInBytes = 0, int? length]) {
    final view = JSFloat64ArrayImpl.view(this, offsetInBytes, length);
    return _immutable ? view.asUnmodifiableView() : view;
  }

  @override
  Float32x4List asFloat32x4List([int offsetInBytes = 0, int? length]) {
    _offsetAlignmentCheck(offsetInBytes, Float32x4List.bytesPerElement);
    length ??= (lengthInBytes - offsetInBytes) ~/ Float32x4List.bytesPerElement;
    final storage = JSFloat32ArrayImpl.view(this, offsetInBytes, length * 4);
    final view = JSFloat32x4ArrayImpl.externalStorage(storage);
    return _immutable ? view.asUnmodifiableView() : view;
  }

  @override
  Float64x2List asFloat64x2List([int offsetInBytes = 0, int? length]) {
    _offsetAlignmentCheck(offsetInBytes, Float64x2List.bytesPerElement);
    length ??= (lengthInBytes - offsetInBytes) ~/ Float64x2List.bytesPerElement;
    final storage = JSFloat64ArrayImpl.view(this, offsetInBytes, length * 2);
    final view = JSFloat64x2ArrayImpl.externalStorage(storage);
    return _immutable ? view.asUnmodifiableView() : view;
  }

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) {
    final view = JSDataViewImpl.view(this, offsetInBytes, length);
    return _immutable ? view.asUnmodifiableView() : view;
  }

  @override
  bool operator ==(Object that) =>
      that is JSArrayBufferImpl && js.areEqualInJS(_ref, that._ref);
}

/// Base class for all JS typed array classes.
abstract class JSArrayBase implements TypedData {
  /// `externref` of a JS `DataView`.
  final WasmExternRef? _ref;

  /// List length
  final int length;

  JSArrayBase(this._ref, int elementSizeShift)
      : length = _dataViewByteLength(_ref) >>> elementSizeShift;

  @pragma("wasm:prefer-inline")
  WasmExternRef? get toExternRef => _ref;

  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]);

  @override
  JSArrayBufferImpl get buffer =>
      JSArrayBufferImpl.fromRef(_dataViewBuffer(_ref));

  @override
  @pragma("wasm:prefer-inline")
  int get lengthInBytes => _dataViewByteLength(toExternRef);

  @override
  @pragma("wasm:prefer-inline")
  int get offsetInBytes => _dataViewByteOffset(_ref);

  @override
  bool operator ==(Object that) =>
      that is JSArrayBase && js.areEqualInJS(_ref, that._ref);

  void clear() {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  bool remove(Object? element) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  void removeRange(int start, int end) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  void replaceRange(int start, int end, Iterable iterable) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  set length(int newLength) {
    throw UnsupportedError("Cannot resize a fixed-length list");
  }

  void add(dynamic value) {
    throw UnsupportedError("Cannot add to a fixed-length list");
  }

  void addAll(Iterable value) {
    throw UnsupportedError("Cannot add to a fixed-length list");
  }

  void insert(int index, dynamic value) {
    throw UnsupportedError("Cannot insert into a fixed-length list");
  }

  void insertAll(int index, Iterable values) {
    throw UnsupportedError("Cannot insert into a fixed-length list");
  }
}

/// A JS `DataView`.
final class JSDataViewImpl implements ByteData {
  /// `externref` of a JS `DataView`.
  final WasmExternRef? _ref;

  final int lengthInBytes;

  final bool _immutable;

  JSDataViewImpl(this.lengthInBytes)
      : _ref = _newDataView(lengthInBytes),
        _immutable = false;

  JSDataViewImpl.fromRef(this._ref)
      : lengthInBytes = _dataViewByteLength(_ref),
        _immutable = false;

  JSDataViewImpl.immutable(this._ref, this.lengthInBytes) : _immutable = true;

  factory JSDataViewImpl.view(
          JSArrayBufferImpl buffer, int offsetInBytes, int? length) =>
      JSDataViewImpl.fromRef(_newDataViewFromArrayBuffer(
          buffer.toExternRef, offsetInBytes, length));

  @pragma("wasm:prefer-inline")
  WasmExternRef? get toExternRef => _ref;

  @override
  JSArrayBufferImpl get buffer => _immutable
      ? JSArrayBufferImpl.fromRefImmutable(_dataViewBuffer(toExternRef))
      : JSArrayBufferImpl.fromRef(_dataViewBuffer(toExternRef));

  @override
  @pragma("wasm:prefer-inline")
  int get offsetInBytes => _dataViewByteOffset(_ref);

  @override
  @pragma("wasm:prefer-inline")
  int get elementSizeInBytes => 1;

  @override
  ByteData asUnmodifiableView() =>
      JSDataViewImpl.immutable(_ref, lengthInBytes);

  @override
  double getFloat32(int byteOffset, [Endian endian = Endian.big]) =>
      _getFloat32(toExternRef, byteOffset, Endian.little == endian);

  @override
  double getFloat64(int byteOffset, [Endian endian = Endian.big]) =>
      _getFloat64(toExternRef, byteOffset, Endian.little == endian);

  @override
  int getInt16(int byteOffset, [Endian endian = Endian.big]) =>
      _getInt16(toExternRef, byteOffset, Endian.little == endian);

  @override
  int getInt32(int byteOffset, [Endian endian = Endian.big]) =>
      _getInt32(toExternRef, byteOffset, Endian.little == endian);

  @override
  int getInt64(int byteOffset, [Endian endian = Endian.big]) =>
      _getBigInt64(toExternRef, byteOffset, Endian.little == endian);

  @override
  int getInt8(int byteOffset) => _getInt8(toExternRef, byteOffset);

  @override
  int getUint16(int byteOffset, [Endian endian = Endian.big]) =>
      _getUint16(toExternRef, byteOffset, Endian.little == endian);

  @override
  int getUint32(int byteOffset, [Endian endian = Endian.big]) =>
      _getUint32(toExternRef, byteOffset, Endian.little == endian);

  @override
  int getUint64(int byteOffset, [Endian endian = Endian.big]) =>
      _getBigUint64(toExternRef, byteOffset, Endian.little == endian);

  @override
  int getUint8(int byteOffset) => _getUint8(toExternRef, byteOffset);

  @override
  void setFloat32(int byteOffset, num value, [Endian endian = Endian.big]) {
    if (_immutable) {
      throw UnsupportedError("Cannot modify an unmodifiable byte data");
    }
    _setFloat32(toExternRef, byteOffset, value, Endian.little == endian);
  }

  @override
  void setFloat64(int byteOffset, num value, [Endian endian = Endian.big]) {
    if (_immutable) {
      throw UnsupportedError("Cannot modify an unmodifiable byte data");
    }
    _setFloat64(toExternRef, byteOffset, value, Endian.little == endian);
  }

  @override
  void setInt16(int byteOffset, int value, [Endian endian = Endian.big]) {
    if (_immutable) {
      throw UnsupportedError("Cannot modify an unmodifiable byte data");
    }
    _setInt16(toExternRef, byteOffset, value, Endian.little == endian);
  }

  @override
  void setInt32(int byteOffset, int value, [Endian endian = Endian.big]) {
    if (_immutable) {
      throw UnsupportedError("Cannot modify an unmodifiable byte data");
    }
    _setInt32(toExternRef, byteOffset, value, Endian.little == endian);
  }

  @override
  void setInt64(int byteOffset, int value, [Endian endian = Endian.big]) {
    if (_immutable) {
      throw UnsupportedError("Cannot modify an unmodifiable byte data");
    }
    _setBigInt64(toExternRef, byteOffset, value, Endian.little == endian);
  }

  @override
  void setInt8(int byteOffset, int value) {
    if (_immutable) {
      throw UnsupportedError("Cannot modify an unmodifiable byte data");
    }
    _setInt8(toExternRef, byteOffset, value);
  }

  @override
  void setUint16(int byteOffset, int value, [Endian endian = Endian.big]) {
    if (_immutable) {
      throw UnsupportedError("Cannot modify an unmodifiable byte data");
    }
    _setUint16(toExternRef, byteOffset, value, Endian.little == endian);
  }

  @override
  void setUint32(int byteOffset, int value, [Endian endian = Endian.big]) {
    if (_immutable) {
      throw UnsupportedError("Cannot modify an unmodifiable byte data");
    }
    _setUint32(toExternRef, byteOffset, value, Endian.little == endian);
  }

  @override
  void setUint64(int byteOffset, int value, [Endian endian = Endian.big]) {
    if (_immutable) {
      throw UnsupportedError("Cannot modify an unmodifiable byte data");
    }
    _setBigUint64(toExternRef, byteOffset, value, Endian.little == endian);
  }

  @override
  void setUint8(int byteOffset, int value) {
    if (_immutable) {
      throw UnsupportedError("Cannot modify an unmodifiable byte data");
    }
    _setUint8(toExternRef, byteOffset, value);
  }
}

abstract class _IntArrayIteratorBase implements Iterator<int> {
  final WasmExternRef? _ref;
  final int _length;
  int _position = -1;
  int _current = 0;

  _IntArrayIteratorBase(this._ref, this._length);

  @pragma("wasm:prefer-inline")
  int get current => _current;
}

mixin _IntListMixin implements List<int> {
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]);

  void _setUnchecked(int index, int value);

  int _getUnchecked(int index);

  Iterable<T> whereType<T>() => WhereTypeIterable<T>(this);

  Iterable<int> followedBy(Iterable<int> other) =>
      FollowedByIterable<int>.firstEfficient(this, other);

  List<R> cast<R>() => List.castFrom<int, R>(this);

  void set first(int value) {
    if (length == 0) {
      throw IndexError.withLength(0, length, indexable: this);
    }
    _setUnchecked(0, value);
  }

  void set last(int value) {
    if (length == 0) {
      throw IndexError.withLength(0, length, indexable: this);
    }
    _setUnchecked(length - 1, value);
  }

  int indexWhere(bool test(int element), [int start = 0]) {
    final length = this.length;
    if (start < 0) start = 0;
    for (int i = start; i < length; i++) {
      if (test(_getUnchecked(i))) return i;
    }
    return -1;
  }

  int lastIndexWhere(bool test(int element), [int? start]) {
    final length = this.length;
    int startIndex = (start == null || start >= length) ? length - 1 : start;
    for (int i = startIndex; i >= 0; i--) {
      if (test(_getUnchecked(i))) return i;
    }
    return -1;
  }

  List<int> operator +(List<int> other) => [...this, ...other];

  bool contains(Object? element) {
    final length = this.length;
    for (var i = 0; i < length; ++i) {
      if (_getUnchecked(i) == element) return true;
    }
    return false;
  }

  void shuffle([Random? random]) {
    random ??= Random();
    var i = length;
    while (i > 1) {
      int pos = random.nextInt(i);
      i -= 1;
      var tmp = _getUnchecked(i);
      _setUnchecked(i, _getUnchecked(pos));
      _setUnchecked(pos, tmp);
    }
  }

  Iterable<int> where(bool f(int element)) => WhereIterable<int>(this, f);

  Iterable<int> take(int n) => SubListIterable<int>(this, 0, n);

  Iterable<int> takeWhile(bool test(int element)) =>
      TakeWhileIterable<int>(this, test);

  Iterable<int> skip(int n) => SubListIterable<int>(this, n, null);

  Iterable<int> skipWhile(bool test(int element)) =>
      SkipWhileIterable<int>(this, test);

  Iterable<int> get reversed => ReversedListIterable<int>(this);

  Map<int, int> asMap() => ListMapView<int>(this);

  Iterable<int> getRange(int start, [int? end]) {
    int endIndex = RangeError.checkValidRange(start, end, this.length);
    return SubListIterable<int>(this, start, endIndex);
  }

  List<int> toList({bool growable = true}) {
    return List<int>.from(this, growable: growable);
  }

  Set<int> toSet() {
    return Set<int>.from(this);
  }

  void forEach(void f(int element)) {
    final length = this.length;
    for (var i = 0; i < length; i++) {
      f(_getUnchecked(i));
    }
  }

  int reduce(int combine(int value, int element)) {
    final length = this.length;
    if (length == 0) throw IterableElementError.noElement();
    var value = _getUnchecked(0);
    for (var i = 1; i < length; ++i) {
      value = combine(value, _getUnchecked(i));
    }
    return value;
  }

  T fold<T>(T initialValue, T combine(T initialValue, int element)) {
    final length = this.length;
    for (var i = 0; i < length; ++i) {
      initialValue = combine(initialValue, _getUnchecked(i));
    }
    return initialValue;
  }

  Iterable<T> map<T>(T f(int element)) => MappedIterable<int, T>(this, f);

  Iterable<T> expand<T>(Iterable<T> f(int element)) =>
      ExpandIterable<int, T>(this, f);

  bool every(bool f(int element)) {
    final length = this.length;
    for (var i = 0; i < length; ++i) {
      if (!f(_getUnchecked(i))) return false;
    }
    return true;
  }

  bool any(bool f(int element)) {
    final length = this.length;
    for (var i = 0; i < length; ++i) {
      if (f(_getUnchecked(i))) return true;
    }
    return false;
  }

  int firstWhere(bool test(int element), {int orElse()?}) {
    final length = this.length;
    for (var i = 0; i < length; ++i) {
      final element = _getUnchecked(i);
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  int lastWhere(bool test(int element), {int orElse()?}) {
    final length = this.length;
    for (var i = length - 1; i >= 0; --i) {
      final element = _getUnchecked(i);
      if (test(element)) {
        return element;
      }
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  int singleWhere(bool test(int element), {int orElse()?}) {
    var result = null;
    bool foundMatching = false;
    final length = this.length;
    for (var i = 0; i < length; ++i) {
      final element = _getUnchecked(i);
      if (test(element)) {
        if (foundMatching) {
          throw IterableElementError.tooMany();
        }
        result = element;
        foundMatching = true;
      }
    }
    if (foundMatching) return result;
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  int elementAt(int index) {
    return this[index];
  }

  void sort([int compare(int a, int b)?]) {
    Sort.sort(this, compare ?? Comparable.compare);
  }

  int indexOf(int element, [int start = 0]) {
    final length = this.length;
    if (start >= length) {
      return -1;
    } else if (start < 0) {
      start = 0;
    }
    for (int i = start; i < length; i++) {
      if (_getUnchecked(i) == element) return i;
    }
    return -1;
  }

  int lastIndexOf(int element, [int? start]) {
    final length = this.length;
    int startIndex = (start == null || start >= length) ? length - 1 : start;
    for (int i = startIndex; i >= 0; i--) {
      if (_getUnchecked(i) == element) return i;
    }
    return -1;
  }

  int removeLast() {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  int removeAt(int index) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  void removeWhere(bool test(int element)) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  void retainWhere(bool test(int element)) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  int get first {
    if (length > 0) return _getUnchecked(0);
    throw IterableElementError.noElement();
  }

  int get last {
    final length = this.length;
    if (length > 0) return _getUnchecked(length - 1);
    throw IterableElementError.noElement();
  }

  int get single {
    final length = this.length;
    if (length == 1) return _getUnchecked(0);
    if (length == 0) throw IterableElementError.noElement();
    throw IterableElementError.tooMany();
  }

  void fillRange(int start, int end, [int? fillValue]) {
    RangeError.checkValidRange(start, end, this.length);
    if (start == end) return;
    if (fillValue == null) {
      throw ArgumentError.notNull("fillValue");
    }
    for (var i = start; i < end; ++i) {
      _setUnchecked(i, fillValue);
    }
  }

  void setAll(int index, Iterable<int> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  void setRange(int start, int end, Iterable<int> iterable,
      [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, length);

    if (skipCount < 0) {
      throw ArgumentError(skipCount);
    }

    if (iterable is JSArrayBase) {
      final JSArrayBase source = unsafeCast<JSArrayBase>(iterable);

      // JS `TypedArray.prototype.set` does not allow mixing `BigInt` and other
      // types. Check that either both of the arrays are `BigInt`s (signed or
      // unsigned), or none of them are.
      final sourceBigInt = source.elementSizeInBytes == 8;
      final targetBigInt = elementSizeInBytes == 8;
      if (!(sourceBigInt ^ targetBigInt)) {
        final length = end - start;
        final sourceArray = source.toJSArrayExternRef(skipCount, length);
        final targetArray = toJSArrayExternRef(start, length);
        return _setRangeFast(targetArray, sourceArray);
      }
    }

    List<int> otherList = iterable.skip(skipCount).toList(growable: false);

    final count = end - start;
    if (otherList.length < count) {
      throw IterableElementError.tooFew();
    }

    // TODO(omersa): Use unchecked read.
    for (int i = 0, j = start; i < count; i++, j++) {
      _setUnchecked(j, otherList[i]);
    }
  }

  int get length;

  int get elementSizeInBytes;

  int get lengthInBytes;

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  String join([String separator = ""]) =>
      (StringBuffer()..writeAll(this, separator)).toString();

  @override
  String toString() => ListBase.listToString(this);
}

// TODO(omersa): This mixin should override other update methods (probably just
// setRange) that don't use `[]=` to modify the list.
mixin _UnmodifiableIntListMixin {
  WasmExternRef? get toExternRef;

  JSArrayBufferImpl get buffer =>
      JSArrayBufferImpl.fromRefImmutable(_dataViewBuffer(toExternRef));

  void operator []=(int index, int value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  void setRange(int start, int end, Iterable<int> iterable,
      [int skipCount = 0]) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }
}

final class JSUint8ArrayImpl extends JSArrayBase
    with _IntListMixin
    implements Uint8List {
  JSUint8ArrayImpl._(WasmExternRef? _ref) : super(_ref, 0);

  factory JSUint8ArrayImpl(int length) =>
      JSUint8ArrayImpl._(_newDataView(length));

  factory JSUint8ArrayImpl.fromJSArray(WasmExternRef? jsArrayRef) =>
      JSUint8ArrayImpl._(_dataViewFromJSArray(jsArrayRef));

  factory JSUint8ArrayImpl.view(
          JSArrayBufferImpl buffer, int offsetInBytes, int? length) =>
      JSUint8ArrayImpl._(buffer.view(offsetInBytes, length));

  @override
  @pragma("wasm:prefer-inline")
  int get elementSizeInBytes => 1;

  @override
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]) => js.JS<
          WasmExternRef?>(
      '(o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length)',
      toExternRef,
      WasmI32.fromInt(start),
      WasmI32.fromInt(length ?? (this.length - start)));

  @pragma("wasm:prefer-inline")
  int _getUnchecked(int index) => _getUint8(toExternRef, index);

  @pragma("wasm:prefer-inline")
  void _setUnchecked(int index, int value) =>
      _setUint8(toExternRef, index, value);

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    indexCheck(index, length);
    return _getUint8(toExternRef, index);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _setUint8(toExternRef, index, value);
  }

  @override
  UnmodifiableJSUint8Array asUnmodifiableView() =>
      UnmodifiableJSUint8Array._(_ref);

  @override
  JSUint8ArrayImpl sublist(int start, [int? end]) {
    final newOffset = offsetInBytes + start;
    final newEnd = RangeError.checkValidRange(newOffset, end, lengthInBytes);
    final newLength = newEnd - newOffset;
    return JSUint8ArrayImpl._(buffer.cloneAsDataView(newOffset, newLength));
  }

  @override
  _JSUint8ArrayIterator get iterator => _JSUint8ArrayIterator(_ref, length);
}

final class _JSUint8ArrayIterator extends _IntArrayIteratorBase {
  _JSUint8ArrayIterator(WasmExternRef? ref, int length) : super(ref, length);

  @pragma("wasm:prefer-inline")
  bool moveNext() {
    _position += 1;
    if (_position < _length) {
      _current = _getUint8(_ref, _position);
      return true;
    }
    return false;
  }
}

final class UnmodifiableJSUint8Array extends JSUint8ArrayImpl
    with _UnmodifiableIntListMixin {
  UnmodifiableJSUint8Array._(WasmExternRef? ref) : super._(ref);
}

final class JSInt8ArrayImpl extends JSArrayBase
    with _IntListMixin
    implements Int8List {
  JSInt8ArrayImpl._(WasmExternRef? _ref) : super(_ref, 0);

  factory JSInt8ArrayImpl(int length) =>
      JSInt8ArrayImpl._(_newDataView(length));

  factory JSInt8ArrayImpl.fromJSArray(WasmExternRef? jsArrayRef) =>
      JSInt8ArrayImpl._(_dataViewFromJSArray(jsArrayRef));

  factory JSInt8ArrayImpl.view(
          JSArrayBufferImpl buffer, int offsetInBytes, int? length) =>
      JSInt8ArrayImpl._(buffer.view(offsetInBytes, length));

  @override
  @pragma("wasm:prefer-inline")
  int get elementSizeInBytes => 1;

  @override
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]) => js.JS<
          WasmExternRef?>(
      '(o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length)',
      toExternRef,
      WasmI32.fromInt(start),
      WasmI32.fromInt(length ?? (this.length - start)));

  @pragma("wasm:prefer-inline")
  int _getUnchecked(int index) => _getInt8(toExternRef, index);

  @pragma("wasm:prefer-inline")
  void _setUnchecked(int index, int value) =>
      _setInt8(toExternRef, index, value);

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    indexCheck(index, length);
    return _getInt8(toExternRef, index);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _setInt8(toExternRef, index, value);
  }

  @override
  UnmodifiableJSInt8Array asUnmodifiableView() =>
      UnmodifiableJSInt8Array._(_ref);

  @override
  JSInt8ArrayImpl sublist(int start, [int? end]) {
    final newOffset = offsetInBytes + start;
    final newEnd = RangeError.checkValidRange(newOffset, end, lengthInBytes);
    final newLength = newEnd - newOffset;
    return JSInt8ArrayImpl._(buffer.cloneAsDataView(newOffset, newLength));
  }

  @override
  _JSInt8ArrayIterator get iterator => _JSInt8ArrayIterator(this);
}

final class _JSInt8ArrayIterator extends _IntArrayIteratorBase {
  _JSInt8ArrayIterator(JSInt8ArrayImpl array) : super(array._ref, array.length);

  @pragma("wasm:prefer-inline")
  bool moveNext() {
    _position += 1;
    if (_position < _length) {
      _current = _getInt8(_ref, _position);
      return true;
    }
    return false;
  }
}

final class UnmodifiableJSInt8Array extends JSInt8ArrayImpl
    with _UnmodifiableIntListMixin {
  UnmodifiableJSInt8Array._(WasmExternRef? ref) : super._(ref);
}

final class JSUint8ClampedArrayImpl extends JSArrayBase
    with _IntListMixin
    implements Uint8ClampedList {
  JSUint8ClampedArrayImpl._(WasmExternRef? _ref) : super(_ref, 0);

  factory JSUint8ClampedArrayImpl(int length) =>
      JSUint8ClampedArrayImpl._(_newDataView(length));

  factory JSUint8ClampedArrayImpl.fromJSArray(WasmExternRef? jsArrayRef) =>
      JSUint8ClampedArrayImpl._(_dataViewFromJSArray(jsArrayRef));

  factory JSUint8ClampedArrayImpl.view(
          JSArrayBufferImpl buffer, int offsetInBytes, int? length) =>
      JSUint8ClampedArrayImpl._(buffer.view(offsetInBytes, length));

  @override
  @pragma("wasm:prefer-inline")
  int get elementSizeInBytes => 1;

  @override
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]) => js.JS<
          WasmExternRef?>(
      '(o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length)',
      toExternRef,
      WasmI32.fromInt(start),
      WasmI32.fromInt(length ?? (this.length - start)));

  @pragma("wasm:prefer-inline")
  int _getUnchecked(int index) => _getUint8(toExternRef, index);

  @pragma("wasm:prefer-inline")
  void _setUnchecked(int index, int value) =>
      _setUint8(toExternRef, index, value.clamp(0, 255));

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    indexCheck(index, length);
    return _getUint8(toExternRef, index);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _setUint8(toExternRef, index, value.clamp(0, 255));
  }

  @override
  UnmodifiableJSUint8ClampedArray asUnmodifiableView() =>
      UnmodifiableJSUint8ClampedArray._(_ref);

  @override
  JSUint8ClampedArrayImpl sublist(int start, [int? end]) {
    final newOffset = offsetInBytes + start;
    final newEnd = RangeError.checkValidRange(newOffset, end, lengthInBytes);
    final newLength = newEnd - newOffset;
    return JSUint8ClampedArrayImpl._(
        buffer.cloneAsDataView(newOffset, newLength));
  }

  @override
  _JSUint8ArrayIterator get iterator => _JSUint8ArrayIterator(_ref, length);
}

final class UnmodifiableJSUint8ClampedArray extends JSUint8ClampedArrayImpl
    with _UnmodifiableIntListMixin {
  UnmodifiableJSUint8ClampedArray._(WasmExternRef? ref) : super._(ref);
}

final class JSUint16ArrayImpl extends JSArrayBase
    with _IntListMixin
    implements Uint16List {
  JSUint16ArrayImpl._(WasmExternRef? _ref) : super(_ref, 1);

  factory JSUint16ArrayImpl(int length) =>
      JSUint16ArrayImpl._(_newDataView(length * 2));

  factory JSUint16ArrayImpl.fromJSArray(WasmExternRef? jsArrayRef) =>
      JSUint16ArrayImpl._(_dataViewFromJSArray(jsArrayRef));

  factory JSUint16ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Uint16List.bytesPerElement);
    final lengthInBytes = (length == null
        ? ((buffer.lengthInBytes - offsetInBytes) & -2)
        : length * 2);
    return JSUint16ArrayImpl._(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  @pragma("wasm:prefer-inline")
  int get elementSizeInBytes => 2;

  @override
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]) => js.JS<
          WasmExternRef?>(
      '(o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length)',
      toExternRef,
      WasmI32.fromInt(start * 2),
      WasmI32.fromInt(length ?? (this.length - start)));

  @pragma("wasm:prefer-inline")
  int _getUnchecked(int index) => _getUint16(toExternRef, index * 2, true);

  @pragma("wasm:prefer-inline")
  void _setUnchecked(int index, int value) =>
      _setUint16(toExternRef, index * 2, value, true);

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    indexCheck(index, length);
    return _getUint16(toExternRef, index * 2, true);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _setUint16(toExternRef, index * 2, value, true);
  }

  @override
  UnmodifiableJSUint16Array asUnmodifiableView() =>
      UnmodifiableJSUint16Array._(_ref);

  @override
  JSUint16ArrayImpl sublist(int start, [int? end]) {
    final int newOffset = offsetInBytes + (start * 2);
    final int newEnd = end == null ? lengthInBytes : end * 2;
    final int newLength = newEnd - newOffset;
    RangeError.checkValidRange(newOffset ~/ 2, newEnd ~/ 2, lengthInBytes ~/ 2);
    return JSUint16ArrayImpl._(buffer.cloneAsDataView(newOffset, newLength));
  }

  @override
  _JSUint16ArrayIterator get iterator => _JSUint16ArrayIterator(this);
}

final class _JSUint16ArrayIterator extends _IntArrayIteratorBase {
  _JSUint16ArrayIterator(JSUint16ArrayImpl array)
      : super(array._ref, array.length);

  @pragma("wasm:prefer-inline")
  bool moveNext() {
    _position += 1;
    if (_position < _length) {
      _current = _getUint16(_ref, _position * 2, true);
      return true;
    }
    return false;
  }
}

final class UnmodifiableJSUint16Array extends JSUint16ArrayImpl
    with _UnmodifiableIntListMixin {
  UnmodifiableJSUint16Array._(WasmExternRef? ref) : super._(ref);
}

final class JSInt16ArrayImpl extends JSArrayBase
    with _IntListMixin
    implements Int16List {
  JSInt16ArrayImpl._(WasmExternRef? _ref) : super(_ref, 1);

  factory JSInt16ArrayImpl(int length) =>
      JSInt16ArrayImpl._(_newDataView(length * 2));

  factory JSInt16ArrayImpl.fromJSArray(WasmExternRef? jsArrayRef) =>
      JSInt16ArrayImpl._(_dataViewFromJSArray(jsArrayRef));

  factory JSInt16ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Int16List.bytesPerElement);
    final lengthInBytes = (length == null
        ? ((buffer.lengthInBytes - offsetInBytes) & -2)
        : length * 2);
    return JSInt16ArrayImpl._(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  @pragma("wasm:prefer-inline")
  int get elementSizeInBytes => 2;

  @override
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]) => js.JS<
          WasmExternRef?>(
      '(o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length)',
      toExternRef,
      WasmI32.fromInt(start * 2),
      WasmI32.fromInt(length ?? (this.length - start)));

  @pragma("wasm:prefer-inline")
  int _getUnchecked(int index) => _getInt16(toExternRef, index * 2, true);

  @pragma("wasm:prefer-inline")
  void _setUnchecked(int index, int value) =>
      _setInt16(toExternRef, index * 2, value, true);

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    indexCheck(index, length);
    return _getInt16(toExternRef, index * 2, true);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _setInt16(toExternRef, index * 2, value, true);
  }

  @override
  UnmodifiableJSInt16Array asUnmodifiableView() =>
      UnmodifiableJSInt16Array._(_ref);

  @override
  JSInt16ArrayImpl sublist(int start, [int? end]) {
    final int newOffset = offsetInBytes + (start * 2);
    final int newEnd = end == null ? lengthInBytes : end * 2;
    final int newLength = newEnd - newOffset;
    RangeError.checkValidRange(newOffset ~/ 2, newEnd ~/ 2, lengthInBytes ~/ 2);
    return JSInt16ArrayImpl._(buffer.cloneAsDataView(newOffset, newLength));
  }

  @override
  _JSInt16ArrayIterator get iterator => _JSInt16ArrayIterator(this);
}

final class _JSInt16ArrayIterator extends _IntArrayIteratorBase {
  _JSInt16ArrayIterator(JSInt16ArrayImpl array)
      : super(array._ref, array.length);

  @pragma("wasm:prefer-inline")
  bool moveNext() {
    _position += 1;
    if (_position < _length) {
      _current = _getInt16(_ref, _position * 2, true);
      return true;
    }
    return false;
  }
}

final class UnmodifiableJSInt16Array extends JSInt16ArrayImpl
    with _UnmodifiableIntListMixin {
  UnmodifiableJSInt16Array._(WasmExternRef? ref) : super._(ref);
}

final class JSUint32ArrayImpl extends JSArrayBase
    with _IntListMixin
    implements Uint32List {
  JSUint32ArrayImpl._(WasmExternRef? _ref) : super(_ref, 2);

  factory JSUint32ArrayImpl(int length) =>
      JSUint32ArrayImpl._(_newDataView(length * 4));

  factory JSUint32ArrayImpl.fromJSArray(WasmExternRef? jsArrayRef) =>
      JSUint32ArrayImpl._(_dataViewFromJSArray(jsArrayRef));

  factory JSUint32ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Uint32List.bytesPerElement);
    final lengthInBytes = (length == null
        ? ((buffer.lengthInBytes - offsetInBytes) & -4)
        : length * 4);
    return JSUint32ArrayImpl._(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  @pragma("wasm:prefer-inline")
  int get elementSizeInBytes => 4;

  @override
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]) => js.JS<
          WasmExternRef?>(
      '(o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length)',
      toExternRef,
      WasmI32.fromInt(start * 4),
      WasmI32.fromInt(length ?? (this.length - start)));

  @pragma("wasm:prefer-inline")
  int _getUnchecked(int index) => _getUint32(toExternRef, index * 4, true);

  @pragma("wasm:prefer-inline")
  void _setUnchecked(int index, int value) =>
      _setUint32(toExternRef, index * 4, value, true);

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    indexCheck(index, length);
    return _getUint32(toExternRef, index * 4, true);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _setUint32(toExternRef, index * 4, value, true);
  }

  @override
  UnmodifiableJSUint32Array asUnmodifiableView() =>
      UnmodifiableJSUint32Array._(_ref);

  @override
  JSUint32ArrayImpl sublist(int start, [int? end]) {
    final int newOffset = offsetInBytes + (start * 4);
    final int newEnd = end == null ? lengthInBytes : end * 4;
    final int newLength = newEnd - newOffset;
    RangeError.checkValidRange(newOffset ~/ 4, newEnd ~/ 4, lengthInBytes ~/ 4);
    return JSUint32ArrayImpl._(buffer.cloneAsDataView(newOffset, newLength));
  }

  @override
  _JSUint32ArrayIterator get iterator => _JSUint32ArrayIterator(this);
}

final class _JSUint32ArrayIterator extends _IntArrayIteratorBase {
  _JSUint32ArrayIterator(JSUint32ArrayImpl array)
      : super(array._ref, array.length);

  @pragma("wasm:prefer-inline")
  bool moveNext() {
    _position += 1;
    if (_position < _length) {
      _current = _getUint32(_ref, _position * 4, true);
      return true;
    }
    return false;
  }
}

final class UnmodifiableJSUint32Array extends JSUint32ArrayImpl
    with _UnmodifiableIntListMixin {
  UnmodifiableJSUint32Array._(WasmExternRef? ref) : super._(ref);
}

final class JSInt32ArrayImpl extends JSArrayBase
    with _IntListMixin
    implements Int32List {
  JSInt32ArrayImpl._(WasmExternRef? _ref) : super(_ref, 2);

  factory JSInt32ArrayImpl(int length) =>
      JSInt32ArrayImpl._(_newDataView(length * 4));

  factory JSInt32ArrayImpl.fromJSArray(WasmExternRef? jsArrayRef) =>
      JSInt32ArrayImpl._(_dataViewFromJSArray(jsArrayRef));

  factory JSInt32ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Int32List.bytesPerElement);
    final lengthInBytes = (length == null
        ? ((buffer.lengthInBytes - offsetInBytes) & -4)
        : length * 4);
    return JSInt32ArrayImpl._(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  @pragma("wasm:prefer-inline")
  int get elementSizeInBytes => 4;

  @override
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]) => js.JS<
          WasmExternRef?>(
      '(o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length)',
      toExternRef,
      WasmI32.fromInt(start * 4),
      WasmI32.fromInt(length ?? (this.length - start)));

  @pragma("wasm:prefer-inline")
  int _getUnchecked(int index) => _getInt32(toExternRef, index * 4, true);

  @pragma("wasm:prefer-inline")
  void _setUnchecked(int index, int value) =>
      _setInt32(toExternRef, index * 4, value, true);

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    indexCheck(index, length);
    return _getInt32(toExternRef, index * 4, true);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _setInt32(toExternRef, index * 4, value, true);
  }

  @override
  UnmodifiableJSInt32Array asUnmodifiableView() =>
      UnmodifiableJSInt32Array._(_ref);

  @override
  JSInt32ArrayImpl sublist(int start, [int? end]) {
    final int newOffset = offsetInBytes + (start * 4);
    final int newEnd = end == null ? lengthInBytes : end * 4;
    final int newLength = newEnd - newOffset;
    RangeError.checkValidRange(newOffset ~/ 4, newEnd ~/ 4, lengthInBytes ~/ 4);
    return JSInt32ArrayImpl._(buffer.cloneAsDataView(newOffset, newLength));
  }

  @override
  _JSInt32ArrayIterator get iterator => _JSInt32ArrayIterator(this);
}

final class _JSInt32ArrayIterator extends _IntArrayIteratorBase {
  _JSInt32ArrayIterator(JSInt32ArrayImpl array)
      : super(array._ref, array.length);

  @pragma("wasm:prefer-inline")
  bool moveNext() {
    _position += 1;
    if (_position < _length) {
      _current = _getInt32(_ref, _position * 4, true);
      return true;
    }
    return false;
  }
}

final class UnmodifiableJSInt32Array extends JSInt32ArrayImpl
    with _UnmodifiableIntListMixin {
  UnmodifiableJSInt32Array._(WasmExternRef? ref) : super._(ref);
}

final class JSInt32x4ArrayImpl
    with ListMixin<Int32x4>, FixedLengthListMixin<Int32x4>
    implements Int32x4List {
  final JSInt32ArrayImpl _storage;

  JSInt32x4ArrayImpl.externalStorage(JSInt32ArrayImpl storage)
      : _storage = storage;

  @override
  ByteBuffer get buffer => _storage.buffer;

  @override
  @pragma("wasm:prefer-inline")
  int get lengthInBytes => _storage.lengthInBytes;

  @override
  int get offsetInBytes => _storage.offsetInBytes;

  @override
  int get elementSizeInBytes => Int32x4List.bytesPerElement;

  @override
  @pragma("wasm:prefer-inline")
  int get length => _storage.length ~/ 4;

  @override
  @pragma("wasm:prefer-inline")
  Int32x4 operator [](int index) {
    indexCheck(index, length);
    int _x = _storage[(index * 4) + 0];
    int _y = _storage[(index * 4) + 1];
    int _z = _storage[(index * 4) + 2];
    int _w = _storage[(index * 4) + 3];
    return Int32x4(_x, _y, _z, _w);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, Int32x4 value) {
    indexCheck(index, length);
    _storage[(index * 4) + 0] = value.x;
    _storage[(index * 4) + 1] = value.y;
    _storage[(index * 4) + 2] = value.z;
    _storage[(index * 4) + 3] = value.w;
  }

  @override
  Int32x4List asUnmodifiableView() =>
      NaiveUnmodifiableInt32x4List.externalStorage(_storage);

  @override
  JSInt32x4ArrayImpl sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    return JSInt32x4ArrayImpl.externalStorage(
        _storage.sublist(start * 4, stop * 4));
  }

  @override
  void setAll(int index, Iterable<Int32x4> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  @override
  void setRange(int start, int end, Iterable<Int32x4> iterable,
      [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, length);

    if (skipCount < 0) {
      throw ArgumentError(skipCount);
    }

    List<Int32x4> otherList = iterable.skip(skipCount).toList(growable: false);

    final count = end - start;
    if (otherList.length < count) {
      throw IterableElementError.tooFew();
    }

    // TODO(omersa): Use unchecked operations here.
    for (int i = 0, j = start; i < count; i++, j++) {
      this[j] = otherList[i];
    }
  }
}

final class JSBigUint64ArrayImpl extends JSArrayBase
    with _IntListMixin
    implements Uint64List {
  JSBigUint64ArrayImpl._(WasmExternRef? _ref) : super(_ref, 3);

  factory JSBigUint64ArrayImpl(int length) =>
      JSBigUint64ArrayImpl._(_newDataView(length * 8));

  factory JSBigUint64ArrayImpl.fromJSArray(WasmExternRef? jsArrayRef) =>
      JSBigUint64ArrayImpl._(_dataViewFromJSArray(jsArrayRef));

  factory JSBigUint64ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Uint64List.bytesPerElement);
    final lengthInBytes = (length == null
        ? ((buffer.lengthInBytes - offsetInBytes) & -8)
        : length * 8);
    return JSBigUint64ArrayImpl._(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  @pragma("wasm:prefer-inline")
  int get elementSizeInBytes => 8;

  @override
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]) => js.JS<
          WasmExternRef?>(
      '(o, start, length) => new BigUint64Array(o.buffer, o.byteOffset + start, length)',
      toExternRef,
      WasmI32.fromInt(start * 8),
      WasmI32.fromInt(length ?? (this.length - start)));

  @pragma("wasm:prefer-inline")
  int _getUnchecked(int index) => _getBigUint64(toExternRef, index * 8, true);

  @pragma("wasm:prefer-inline")
  void _setUnchecked(int index, int value) =>
      _setBigUint64(toExternRef, index * 8, value, true);

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    indexCheck(index, length);
    return _getBigUint64(toExternRef, index * 8, true);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    indexCheck(index, length);
    return _setBigUint64(toExternRef, index * 8, value, true);
  }

  @override
  UnmodifiableJSBigUint64Array asUnmodifiableView() =>
      UnmodifiableJSBigUint64Array._(_ref);

  @override
  JSBigUint64ArrayImpl sublist(int start, [int? end]) {
    final int newOffset = offsetInBytes + (start * 8);
    final int newEnd = end == null ? lengthInBytes : end * 8;
    final int newLength = newEnd - newOffset;
    RangeError.checkValidRange(newOffset ~/ 8, newEnd ~/ 8, lengthInBytes ~/ 8);
    return JSBigUint64ArrayImpl._(buffer.cloneAsDataView(newOffset, newLength));
  }

  @override
  _JSUint64ArrayIterator get iterator => _JSUint64ArrayIterator(this);
}

final class _JSUint64ArrayIterator extends _IntArrayIteratorBase {
  _JSUint64ArrayIterator(JSBigUint64ArrayImpl array)
      : super(array._ref, array.length);

  @pragma("wasm:prefer-inline")
  bool moveNext() {
    _position += 1;
    if (_position < _length) {
      _current = _getBigUint64(_ref, _position * 8, true);
      return true;
    }
    return false;
  }
}

final class UnmodifiableJSBigUint64Array extends JSBigUint64ArrayImpl
    with _UnmodifiableIntListMixin {
  UnmodifiableJSBigUint64Array._(WasmExternRef? ref) : super._(ref);
}

final class JSBigInt64ArrayImpl extends JSArrayBase
    with _IntListMixin
    implements Int64List {
  JSBigInt64ArrayImpl._(WasmExternRef? _ref) : super(_ref, 3);

  factory JSBigInt64ArrayImpl(int length) =>
      JSBigInt64ArrayImpl._(_newDataView(length * 8));

  factory JSBigInt64ArrayImpl.fromJSArray(WasmExternRef? jsArrayRef) =>
      JSBigInt64ArrayImpl._(_dataViewFromJSArray(jsArrayRef));

  factory JSBigInt64ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Int64List.bytesPerElement);
    final lengthInBytes = (length == null
        ? ((buffer.lengthInBytes - offsetInBytes) & -8)
        : length * 8);
    return JSBigInt64ArrayImpl._(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  @pragma("wasm:prefer-inline")
  int get elementSizeInBytes => 8;

  @override
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]) => js.JS<
          WasmExternRef?>(
      '(o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length)',
      toExternRef,
      WasmI32.fromInt(start * 8),
      WasmI32.fromInt(length ?? (this.length - start)));

  @pragma("wasm:prefer-inline")
  int _getUnchecked(int index) => _getBigInt64(toExternRef, index * 8, true);

  @pragma("wasm:prefer-inline")
  void _setUnchecked(int index, int value) =>
      _setBigInt64(toExternRef, index * 8, value, true);

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    indexCheck(index, length);
    return _getBigInt64(toExternRef, index * 8, true);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _setBigInt64(toExternRef, index * 8, value, true);
  }

  @override
  UnmodifiableJSBigInt64Array asUnmodifiableView() =>
      UnmodifiableJSBigInt64Array._(_ref);

  @override
  JSBigInt64ArrayImpl sublist(int start, [int? end]) {
    final int newOffset = offsetInBytes + (start * 8);
    final int newEnd = end == null ? lengthInBytes : end * 8;
    final int newLength = newEnd - newOffset;
    RangeError.checkValidRange(newOffset ~/ 8, newEnd ~/ 8, lengthInBytes ~/ 8);
    return JSBigInt64ArrayImpl._(buffer.cloneAsDataView(newOffset, newLength));
  }

  @override
  _JSInt64ArrayIterator get iterator => _JSInt64ArrayIterator(this);
}

final class _JSInt64ArrayIterator extends _IntArrayIteratorBase {
  _JSInt64ArrayIterator(JSBigInt64ArrayImpl array)
      : super(array._ref, array.length);

  @pragma("wasm:prefer-inline")
  bool moveNext() {
    _position += 1;
    if (_position < _length) {
      _current = _getBigInt64(_ref, _position * 8, true);
      return true;
    }
    return false;
  }
}

final class UnmodifiableJSBigInt64Array extends JSBigInt64ArrayImpl
    with _UnmodifiableIntListMixin {
  UnmodifiableJSBigInt64Array._(WasmExternRef? ref) : super._(ref);
}

abstract class _DoubleArrayIteratorBase implements Iterator<double> {
  final WasmExternRef? _ref;
  final int _length;
  int _position = -1;
  double _current = 0;

  _DoubleArrayIteratorBase(this._ref, this._length);

  @pragma("wasm:prefer-inline")
  double get current => _current;
}

mixin _DoubleListMixin implements List<double> {
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]);

  void _setUnchecked(int index, double value);

  double _getUnchecked(int index);

  Iterable<T> whereType<T>() => WhereTypeIterable<T>(this);

  Iterable<double> followedBy(Iterable<double> other) =>
      FollowedByIterable<double>.firstEfficient(this, other);

  List<R> cast<R>() => List.castFrom<double, R>(this);

  void set first(double value) {
    if (length == 0) {
      throw IndexError.withLength(0, length, indexable: this);
    }
    _setUnchecked(0, value);
  }

  void set last(double value) {
    if (length == 0) {
      throw IndexError.withLength(0, length, indexable: this);
    }
    _setUnchecked(length - 1, value);
  }

  int indexWhere(bool test(double element), [int start = 0]) {
    final length = this.length;
    if (start < 0) start = 0;
    for (int i = start; i < length; i++) {
      if (test(_getUnchecked(i))) return i;
    }
    return -1;
  }

  int lastIndexWhere(bool test(double element), [int? start]) {
    final length = this.length;
    int startIndex = (start == null || start >= length) ? length - 1 : start;
    for (int i = startIndex; i >= 0; i--) {
      if (test(_getUnchecked(i))) return i;
    }
    return -1;
  }

  List<double> operator +(List<double> other) => [...this, ...other];

  bool contains(Object? element) {
    final length = this.length;
    for (var i = 0; i < length; ++i) {
      if (_getUnchecked(i) == element) return true;
    }
    return false;
  }

  void shuffle([Random? random]) {
    random ??= Random();
    var i = length;
    while (i > 1) {
      int pos = random.nextInt(i);
      i -= 1;
      var tmp = _getUnchecked(i);
      _setUnchecked(i, _getUnchecked(pos));
      _setUnchecked(pos, tmp);
    }
  }

  Iterable<double> where(bool f(double element)) =>
      WhereIterable<double>(this, f);

  Iterable<double> take(int n) => SubListIterable<double>(this, 0, n);

  Iterable<double> takeWhile(bool test(double element)) =>
      TakeWhileIterable<double>(this, test);

  Iterable<double> skip(int n) => SubListIterable<double>(this, n, null);

  Iterable<double> skipWhile(bool test(double element)) =>
      SkipWhileIterable<double>(this, test);

  Iterable<double> get reversed => ReversedListIterable<double>(this);

  Map<int, double> asMap() => ListMapView<double>(this);

  Iterable<double> getRange(int start, [int? end]) {
    int endIndex = RangeError.checkValidRange(start, end, this.length);
    return SubListIterable<double>(this, start, endIndex);
  }

  List<double> toList({bool growable = true}) {
    return List<double>.from(this, growable: growable);
  }

  Set<double> toSet() {
    return Set<double>.from(this);
  }

  void forEach(void f(double element)) {
    final length = this.length;
    for (var i = 0; i < length; i++) {
      f(_getUnchecked(i));
    }
  }

  double reduce(double combine(double value, double element)) {
    final length = this.length;
    if (length == 0) throw IterableElementError.noElement();
    var value = _getUnchecked(0);
    for (var i = 1; i < length; ++i) {
      value = combine(value, _getUnchecked(i));
    }
    return value;
  }

  T fold<T>(T initialValue, T combine(T initialValue, double element)) {
    final length = this.length;
    for (var i = 0; i < length; ++i) {
      initialValue = combine(initialValue, _getUnchecked(i));
    }
    return initialValue;
  }

  Iterable<T> map<T>(T f(double element)) => MappedIterable<double, T>(this, f);

  Iterable<T> expand<T>(Iterable<T> f(double element)) =>
      ExpandIterable<double, T>(this, f);

  bool every(bool f(double element)) {
    final length = this.length;
    for (var i = 0; i < length; ++i) {
      if (!f(_getUnchecked(i))) return false;
    }
    return true;
  }

  bool any(bool f(double element)) {
    final length = this.length;
    for (var i = 0; i < length; ++i) {
      if (f(_getUnchecked(i))) return true;
    }
    return false;
  }

  double firstWhere(bool test(double element), {double orElse()?}) {
    final length = this.length;
    for (var i = 0; i < length; ++i) {
      final element = _getUnchecked(i);
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  double lastWhere(bool test(double element), {double orElse()?}) {
    final length = this.length;
    for (var i = length - 1; i >= 0; --i) {
      final element = _getUnchecked(i);
      if (test(element)) {
        return element;
      }
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  double singleWhere(bool test(double element), {double orElse()?}) {
    var result = null;
    bool foundMatching = false;
    final length = this.length;
    for (var i = 0; i < length; ++i) {
      final element = _getUnchecked(i);
      if (test(element)) {
        if (foundMatching) {
          throw IterableElementError.tooMany();
        }
        result = element;
        foundMatching = true;
      }
    }
    if (foundMatching) return result;
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  double elementAt(int index) {
    return this[index];
  }

  void sort([int compare(double a, double b)?]) {
    Sort.sort(this, compare ?? Comparable.compare);
  }

  int indexOf(double element, [int start = 0]) {
    final length = this.length;
    if (start >= length) {
      return -1;
    } else if (start < 0) {
      start = 0;
    }
    for (int i = start; i < length; i++) {
      if (_getUnchecked(i) == element) return i;
    }
    return -1;
  }

  int lastIndexOf(double element, [int? start]) {
    final length = this.length;
    int startIndex = (start == null || start >= length) ? length - 1 : start;
    for (int i = startIndex; i >= 0; i--) {
      if (_getUnchecked(i) == element) return i;
    }
    return -1;
  }

  double removeLast() {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  double removeAt(int index) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  void removeWhere(bool test(double element)) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  void retainWhere(bool test(double element)) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  double get first {
    if (length > 0) return _getUnchecked(0);
    throw IterableElementError.noElement();
  }

  double get last {
    final length = this.length;
    if (length > 0) return _getUnchecked(length - 1);
    throw IterableElementError.noElement();
  }

  double get single {
    final length = this.length;
    if (length == 1) return _getUnchecked(0);
    if (length == 0) throw IterableElementError.noElement();
    throw IterableElementError.tooMany();
  }

  void fillRange(int start, int end, [double? fillValue]) {
    RangeError.checkValidRange(start, end, this.length);
    if (start == end) return;
    if (fillValue == null) {
      throw ArgumentError.notNull("fillValue");
    }
    for (var i = start; i < end; ++i) {
      _setUnchecked(i, fillValue);
    }
  }

  void setAll(int index, Iterable<double> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  void setRange(int start, int end, Iterable<double> iterable,
      [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, length);

    if (skipCount < 0) {
      throw ArgumentError(skipCount);
    }

    if (iterable is JSArrayBase) {
      final JSArrayBase source = unsafeCast<JSArrayBase>(iterable);
      final length = end - start;
      final sourceArray = source.toJSArrayExternRef(skipCount, length);
      final targetArray = toJSArrayExternRef(start, length);
      return _setRangeFast(targetArray, sourceArray);
    }

    List<double> otherList = iterable.skip(skipCount).toList(growable: false);

    final count = end - start;
    if (otherList.length < count) {
      throw IterableElementError.tooFew();
    }

    // TODO(omersa): Use unchecked read.
    for (int i = 0, j = start; i < count; i++, j++) {
      _setUnchecked(j, otherList[i]);
    }
  }

  int get length;

  int get elementSizeInBytes;

  int get lengthInBytes;

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  String join([String separator = ""]) =>
      (StringBuffer()..writeAll(this, separator)).toString();

  @override
  String toString() => ListBase.listToString(this);
}

mixin _UnmodifiableDoubleListMixin {
  WasmExternRef? get toExternRef;

  JSArrayBufferImpl get buffer =>
      JSArrayBufferImpl.fromRefImmutable(_dataViewBuffer(toExternRef));

  void operator []=(int index, double value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }

  void setRange(int start, int end, Iterable<double> iterable,
      [int skipCount = 0]) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }
}

final class JSFloat32ArrayImpl extends JSArrayBase
    with _DoubleListMixin
    implements Float32List {
  JSFloat32ArrayImpl._(WasmExternRef? _ref) : super(_ref, 2);

  factory JSFloat32ArrayImpl(int length) =>
      JSFloat32ArrayImpl._(_newDataView(length * 4));

  factory JSFloat32ArrayImpl.fromJSArray(WasmExternRef? jsArrayRef) =>
      JSFloat32ArrayImpl._(_dataViewFromJSArray(jsArrayRef));

  factory JSFloat32ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Float32List.bytesPerElement);
    final lengthInBytes = (length == null
        ? ((buffer.lengthInBytes - offsetInBytes) & -4)
        : length * 4);
    return JSFloat32ArrayImpl._(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  @pragma("wasm:prefer-inline")
  int get elementSizeInBytes => 4;

  @override
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]) => js.JS<
          WasmExternRef?>(
      '(o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length)',
      toExternRef,
      WasmI32.fromInt(start * 4),
      WasmI32.fromInt(length ?? (this.length - start)));

  @pragma("wasm:prefer-inline")
  double _getUnchecked(int index) => _getFloat32(toExternRef, index * 4, true);

  @pragma("wasm:prefer-inline")
  void _setUnchecked(int index, double value) =>
      _setFloat32(toExternRef, index * 4, value, true);

  @override
  @pragma("wasm:prefer-inline")
  double operator [](int index) {
    indexCheck(index, length);
    return _getFloat32(toExternRef, index * 4, true);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, double value) {
    indexCheck(index, length);
    _setFloat32(toExternRef, index * 4, value, true);
  }

  @override
  UnmodifiableJSFloat32Array asUnmodifiableView() =>
      UnmodifiableJSFloat32Array._(_ref);

  @override
  JSFloat32ArrayImpl sublist(int start, [int? end]) {
    final int newOffset = offsetInBytes + (start * 4);
    final int newEnd = end == null ? lengthInBytes : end * 4;
    final int newLength = newEnd - newOffset;
    RangeError.checkValidRange(newOffset ~/ 4, newEnd ~/ 4, lengthInBytes ~/ 4);
    return JSFloat32ArrayImpl._(buffer.cloneAsDataView(newOffset, newLength));
  }

  @override
  _JSFloat32ArrayIterator get iterator => _JSFloat32ArrayIterator(this);
}

final class _JSFloat32ArrayIterator extends _DoubleArrayIteratorBase {
  _JSFloat32ArrayIterator(JSFloat32ArrayImpl array)
      : super(array._ref, array.length);

  @pragma("wasm:prefer-inline")
  bool moveNext() {
    _position += 1;
    if (_position < _length) {
      _current = _getFloat32(_ref, _position * 4, true);
      return true;
    }
    return false;
  }
}

final class UnmodifiableJSFloat32Array extends JSFloat32ArrayImpl
    with _UnmodifiableDoubleListMixin {
  UnmodifiableJSFloat32Array._(WasmExternRef? ref) : super._(ref);
}

final class JSFloat64ArrayImpl extends JSArrayBase
    with _DoubleListMixin
    implements Float64List {
  JSFloat64ArrayImpl._(WasmExternRef? _ref) : super(_ref, 3);

  factory JSFloat64ArrayImpl(int length) =>
      JSFloat64ArrayImpl._(_newDataView(length * 8));

  factory JSFloat64ArrayImpl.fromJSArray(WasmExternRef? jsArrayRef) =>
      JSFloat64ArrayImpl._(_dataViewFromJSArray(jsArrayRef));

  factory JSFloat64ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Float64List.bytesPerElement);
    final lengthInBytes = (length == null
        ? ((buffer.lengthInBytes - offsetInBytes) & -8)
        : length * 8);
    return JSFloat64ArrayImpl._(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  @pragma("wasm:prefer-inline")
  int get elementSizeInBytes => 8;

  @override
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]) => js.JS<
          WasmExternRef?>(
      '(o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length)',
      toExternRef,
      WasmI32.fromInt(start * 8),
      WasmI32.fromInt(length ?? (this.length - start)));

  @pragma("wasm:prefer-inline")
  double _getUnchecked(int index) => _getFloat64(toExternRef, index * 8, true);

  @pragma("wasm:prefer-inline")
  void _setUnchecked(int index, double value) =>
      _setFloat64(toExternRef, index * 8, value, true);

  @override
  @pragma("wasm:prefer-inline")
  double operator [](int index) {
    indexCheck(index, length);
    return _getFloat64(toExternRef, index * 8, true);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, double value) {
    indexCheck(index, length);
    _setFloat64(toExternRef, index * 8, value, true);
  }

  @override
  UnmodifiableJSFloat64Array asUnmodifiableView() =>
      UnmodifiableJSFloat64Array._(_ref);

  @override
  JSFloat64ArrayImpl sublist(int start, [int? end]) {
    final int newOffset = offsetInBytes + (start * 8);
    final int newEnd = end == null ? lengthInBytes : end * 8;
    final int newLength = newEnd - newOffset;
    RangeError.checkValidRange(newOffset ~/ 8, newEnd ~/ 8, lengthInBytes ~/ 8);
    return JSFloat64ArrayImpl._(buffer.cloneAsDataView(newOffset, newLength));
  }

  @override
  _JSFloat64ArrayIterator get iterator => _JSFloat64ArrayIterator(this);
}

final class _JSFloat64ArrayIterator extends _DoubleArrayIteratorBase {
  _JSFloat64ArrayIterator(JSFloat64ArrayImpl array)
      : super(array._ref, array.length);

  @pragma("wasm:prefer-inline")
  bool moveNext() {
    _position += 1;
    if (_position < _length) {
      _current = _getFloat64(_ref, _position * 8, true);
      return true;
    }
    return false;
  }
}

final class UnmodifiableJSFloat64Array extends JSFloat64ArrayImpl
    with _UnmodifiableDoubleListMixin {
  UnmodifiableJSFloat64Array._(WasmExternRef? ref) : super._(ref);
}

final class JSFloat32x4ArrayImpl
    with ListMixin<Float32x4>, FixedLengthListMixin<Float32x4>
    implements Float32x4List {
  final JSFloat32ArrayImpl _storage;

  JSFloat32x4ArrayImpl.externalStorage(JSFloat32ArrayImpl storage)
      : _storage = storage;

  @override
  ByteBuffer get buffer => _storage.buffer;

  @override
  @pragma("wasm:prefer-inline")
  int get lengthInBytes => _storage.lengthInBytes;

  @override
  int get offsetInBytes => _storage.offsetInBytes;

  @override
  int get elementSizeInBytes => Float32x4List.bytesPerElement;

  @override
  @pragma("wasm:prefer-inline")
  int get length => _storage.length ~/ 4;

  @override
  @pragma("wasm:prefer-inline")
  Float32x4 operator [](int index) {
    indexCheck(index, length);
    double _x = _storage[(index * 4) + 0];
    double _y = _storage[(index * 4) + 1];
    double _z = _storage[(index * 4) + 2];
    double _w = _storage[(index * 4) + 3];
    return Float32x4(_x, _y, _z, _w);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, Float32x4 value) {
    indexCheck(index, length);
    _storage[(index * 4) + 0] = value.x;
    _storage[(index * 4) + 1] = value.y;
    _storage[(index * 4) + 2] = value.z;
    _storage[(index * 4) + 3] = value.w;
  }

  @override
  Float32x4List asUnmodifiableView() =>
      NaiveUnmodifiableFloat32x4List.externalStorage(_storage);

  @override
  JSFloat32x4ArrayImpl sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    return JSFloat32x4ArrayImpl.externalStorage(
        _storage.sublist(start * 4, stop * 4));
  }

  @override
  void setAll(int index, Iterable<Float32x4> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  @override
  void setRange(int start, int end, Iterable<Float32x4> iterable,
      [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, length);

    if (skipCount < 0) {
      throw ArgumentError(skipCount);
    }

    List<Float32x4> otherList =
        iterable.skip(skipCount).toList(growable: false);

    final count = end - start;
    if (otherList.length < count) {
      throw IterableElementError.tooFew();
    }

    // TODO(omersa): Use unchecked operations here.
    for (int i = 0, j = start; i < count; i++, j++) {
      this[j] = otherList[i];
    }
  }
}

final class JSFloat64x2ArrayImpl
    with ListMixin<Float64x2>, FixedLengthListMixin<Float64x2>
    implements Float64x2List {
  final JSFloat64ArrayImpl _storage;

  JSFloat64x2ArrayImpl.externalStorage(JSFloat64ArrayImpl storage)
      : _storage = storage;

  @override
  ByteBuffer get buffer => _storage.buffer;

  @override
  @pragma("wasm:prefer-inline")
  int get lengthInBytes => _storage.lengthInBytes;

  @override
  int get offsetInBytes => _storage.offsetInBytes;

  @override
  int get elementSizeInBytes => Float64x2List.bytesPerElement;

  @override
  @pragma("wasm:prefer-inline")
  int get length => _storage.length ~/ 2;

  @override
  @pragma("wasm:prefer-inline")
  Float64x2 operator [](int index) {
    indexCheck(index, length);
    double _x = _storage[(index * 2) + 0];
    double _y = _storage[(index * 2) + 1];
    return Float64x2(_x, _y);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, Float64x2 value) {
    indexCheck(index, length);
    _storage[(index * 2) + 0] = value.x;
    _storage[(index * 2) + 1] = value.y;
  }

  @override
  Float64x2List asUnmodifiableView() =>
      NaiveUnmodifiableFloat64x2List.externalStorage(_storage);

  @override
  JSFloat64x2ArrayImpl sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    return JSFloat64x2ArrayImpl.externalStorage(
        _storage.sublist(start * 2, stop * 2));
  }

  @override
  void setAll(int index, Iterable<Float64x2> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  @override
  void setRange(int start, int end, Iterable<Float64x2> iterable,
      [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, length);

    if (skipCount < 0) {
      throw ArgumentError(skipCount);
    }

    List<Float64x2> otherList =
        iterable.skip(skipCount).toList(growable: false);

    final count = end - start;
    if (otherList.length < count) {
      throw IterableElementError.tooFew();
    }

    // TODO(omersa): Use unchecked operations here.
    for (int i = 0, j = start; i < count; i++, j++) {
      this[j] = otherList[i];
    }
  }
}

void _setRangeFast(WasmExternRef? targetArray, WasmExternRef? sourceArray) =>
    js.JS<void>('(t, s) => t.set(s)', targetArray, sourceArray);

void _offsetAlignmentCheck(int offset, int alignment) {
  if ((offset % alignment) != 0) {
    throw new RangeError('Offset ($offset) must be a multiple of '
        'bytesPerElement ($alignment)');
  }
}

@pragma("wasm:prefer-inline")
WasmExternRef? _newDataView(int length) => js.JS<WasmExternRef?>(
    'l => new DataView(new ArrayBuffer(l))', WasmI32.fromInt(length));

WasmExternRef? _dataViewFromJSArray(WasmExternRef? jsArrayRef) =>
    js.JS<WasmExternRef?>(
        '(o) => new DataView(o.buffer, o.byteOffset, o.byteLength)',
        jsArrayRef);

@pragma("wasm:prefer-inline")
int _arrayBufferByteLength(WasmExternRef? ref) =>
    js.JS<WasmI32>('o => o.byteLength', ref).toIntSigned();

WasmExternRef? _dataViewBuffer(WasmExternRef? dataViewRef) =>
    js.JS<WasmExternRef?>('o => o.buffer', dataViewRef);

@pragma("wasm:prefer-inline")
int _dataViewByteOffset(WasmExternRef? dataViewRef) =>
    js.JS<WasmI32>('o => o.byteOffset', dataViewRef).toIntSigned();

@pragma("wasm:prefer-inline")
int _dataViewByteLength(WasmExternRef? ref) => js
    .JS<WasmF64>(
        "Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get)",
        ref)
    .truncSatS()
    .toInt();

@pragma("wasm:prefer-inline")
WasmExternRef? _newDataViewFromArrayBuffer(
        WasmExternRef? bufferRef, int offsetInBytes, int? length) =>
    length == null
        ? js.JS<WasmExternRef?>('(b, o) => new DataView(b, o)', bufferRef,
            WasmI32.fromInt(offsetInBytes))
        : js.JS<WasmExternRef?>('(b, o, l) => new DataView(b, o, l)', bufferRef,
            WasmI32.fromInt(offsetInBytes), WasmI32.fromInt(length));

@pragma("wasm:prefer-inline")
int _getUint8(WasmExternRef? ref, int byteOffset) => js
    .JS<WasmI32>('Function.prototype.call.bind(DataView.prototype.getUint8)',
        ref, WasmI32.fromInt(byteOffset))
    .toIntUnsigned();

@pragma("wasm:prefer-inline")
void _setUint8(WasmExternRef? ref, int byteOffset, int value) => js.JS<void>(
    'Function.prototype.call.bind(DataView.prototype.setUint8)',
    ref,
    WasmI32.fromInt(byteOffset),
    WasmI32.fromInt(value));

@pragma("wasm:prefer-inline")
int _getInt8(WasmExternRef? ref, int byteOffset) => js
    .JS<WasmI32>('Function.prototype.call.bind(DataView.prototype.getInt8)',
        ref, WasmI32.fromInt(byteOffset))
    .toIntSigned();

@pragma("wasm:prefer-inline")
void _setInt8(WasmExternRef? ref, int byteOffset, int value) => js.JS<void>(
    'Function.prototype.call.bind(DataView.prototype.setInt8)',
    ref,
    WasmI32.fromInt(byteOffset),
    WasmI32.fromInt(value));

@pragma("wasm:prefer-inline")
int _getUint16(WasmExternRef? ref, int byteOffset, bool littleEndian) => js
    .JS<WasmI32>('Function.prototype.call.bind(DataView.prototype.getUint16)',
        ref, WasmI32.fromInt(byteOffset), WasmI32.fromBool(littleEndian))
    .toIntUnsigned();

@pragma("wasm:prefer-inline")
void _setUint16(
        WasmExternRef? ref, int byteOffset, int value, bool littleEndian) =>
    js.JS<void>(
        'Function.prototype.call.bind(DataView.prototype.setUint16)',
        ref,
        WasmI32.fromInt(byteOffset),
        WasmI32.fromInt(value),
        WasmI32.fromBool(littleEndian));

@pragma("wasm:prefer-inline")
int _getInt16(WasmExternRef? ref, int byteOffset, bool littleEndian) => js
    .JS<WasmI32>('Function.prototype.call.bind(DataView.prototype.getInt16)',
        ref, WasmI32.fromInt(byteOffset), WasmI32.fromBool(littleEndian))
    .toIntSigned();

@pragma("wasm:prefer-inline")
void _setInt16(
        WasmExternRef? ref, int byteOffset, int value, bool littleEndian) =>
    js.JS<void>(
        'Function.prototype.call.bind(DataView.prototype.setInt16)',
        ref,
        WasmI32.fromInt(byteOffset),
        WasmI32.fromInt(value),
        WasmI32.fromBool(littleEndian));

@pragma("wasm:prefer-inline")
int _getUint32(WasmExternRef? ref, int byteOffset, bool littleEndian) => js
    .JS<WasmI32>('Function.prototype.call.bind(DataView.prototype.getUint32)',
        ref, WasmI32.fromInt(byteOffset), WasmI32.fromBool(littleEndian))
    .toIntUnsigned();

@pragma("wasm:prefer-inline")
void _setUint32(
        WasmExternRef? ref, int byteOffset, int value, bool littleEndian) =>
    js.JS<void>(
        'Function.prototype.call.bind(DataView.prototype.setUint32)',
        ref,
        WasmI32.fromInt(byteOffset),
        WasmI32.fromInt(value),
        WasmI32.fromBool(littleEndian));

@pragma("wasm:prefer-inline")
int _getInt32(WasmExternRef? ref, int byteOffset, bool littleEndian) => js
    .JS<WasmI32>('Function.prototype.call.bind(DataView.prototype.getInt32)',
        ref, WasmI32.fromInt(byteOffset), WasmI32.fromBool(littleEndian))
    .toIntSigned();

@pragma("wasm:prefer-inline")
void _setInt32(
        WasmExternRef? ref, int byteOffset, int value, bool littleEndian) =>
    js.JS<void>(
        'Function.prototype.call.bind(DataView.prototype.setInt32)',
        ref,
        WasmI32.fromInt(byteOffset),
        WasmI32.fromInt(value),
        WasmI32.fromBool(littleEndian));

@pragma("wasm:prefer-inline")
int _getBigUint64(WasmExternRef? ref, int byteOffset, bool littleEndian) => js
    .JS<WasmI64>(
        'Function.prototype.call.bind(DataView.prototype.getBigUint64)',
        ref,
        WasmI32.fromInt(byteOffset),
        WasmI32.fromBool(littleEndian))
    .toInt();

@pragma("wasm:prefer-inline")
void _setBigUint64(
        WasmExternRef? ref, int byteOffset, int value, bool littleEndian) =>
    js.JS<void>(
        'Function.prototype.call.bind(DataView.prototype.setBigUint64)',
        ref,
        WasmI32.fromInt(byteOffset),
        WasmI64.fromInt(value),
        WasmI32.fromBool(littleEndian));

@pragma("wasm:prefer-inline")
int _getBigInt64(WasmExternRef? ref, int byteOffset, bool littleEndian) => js
    .JS<WasmI64>('Function.prototype.call.bind(DataView.prototype.getBigInt64)',
        ref, WasmI32.fromInt(byteOffset), WasmI32.fromBool(littleEndian))
    .toInt();

@pragma("wasm:prefer-inline")
void _setBigInt64(
        WasmExternRef? ref, int byteOffset, int value, bool littleEndian) =>
    js.JS<void>(
        'Function.prototype.call.bind(DataView.prototype.setBigInt64)',
        ref,
        WasmI32.fromInt(byteOffset),
        WasmI64.fromInt(value),
        WasmI32.fromBool(littleEndian));

@pragma("wasm:prefer-inline")
double _getFloat32(WasmExternRef? ref, int byteOffset, bool littleEndian) => js
    .JS<WasmF32>('Function.prototype.call.bind(DataView.prototype.getFloat32)',
        ref, WasmI32.fromInt(byteOffset), WasmI32.fromBool(littleEndian))
    .toDouble();

@pragma("wasm:prefer-inline")
void _setFloat32(
        WasmExternRef? ref, int byteOffset, num value, bool littleEndian) =>
    js.JS<void>(
        'Function.prototype.call.bind(DataView.prototype.setFloat32)',
        ref,
        WasmI32.fromInt(byteOffset),
        WasmF32.fromDouble(value.toDouble()),
        WasmI32.fromBool(littleEndian));

@pragma("wasm:prefer-inline")
double _getFloat64(WasmExternRef? ref, int byteOffset, bool littleEndian) => js
    .JS<WasmF64>('Function.prototype.call.bind(DataView.prototype.getFloat64)',
        ref, WasmI32.fromInt(byteOffset), WasmI32.fromBool(littleEndian))
    .toDouble();

@pragma("wasm:prefer-inline")
void _setFloat64(
        WasmExternRef? ref, int byteOffset, num value, bool littleEndian) =>
    js.JS<void>(
        'Function.prototype.call.bind(DataView.prototype.setFloat64)',
        ref,
        WasmI32.fromInt(byteOffset),
        WasmF64.fromDouble(value.toDouble()),
        WasmI32.fromBool(littleEndian));
