// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Specialized integers and floating point numbers,
/// with SIMD support and efficient lists.
library dart.typed_data.implementation;

import 'dart:collection';
import 'dart:_internal';
import 'dart:_interceptors' show JavaScriptObject, JSIndexable;
import 'dart:_js_helper'
    show
        Creates,
        JavaScriptIndexingBehavior,
        JSName,
        Native,
        Returns,
        diagnoseIndexError,
        diagnoseRangeError;
import 'dart:_foreign_helper' show JS;
import 'dart:math' as Math;

import 'dart:typed_data';

@Native('ArrayBuffer')
final class NativeByteBuffer extends JavaScriptObject implements ByteBuffer {
  @JSName('byteLength')
  external int get lengthInBytes;

  Type get runtimeType => ByteBuffer;

  Uint8List asUint8List([int offsetInBytes = 0, int? length]) {
    return NativeUint8List.view(this, offsetInBytes, length);
  }

  Int8List asInt8List([int offsetInBytes = 0, int? length]) {
    return NativeInt8List.view(this, offsetInBytes, length);
  }

  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int? length]) {
    return NativeUint8ClampedList.view(this, offsetInBytes, length);
  }

  Uint16List asUint16List([int offsetInBytes = 0, int? length]) {
    return NativeUint16List.view(this, offsetInBytes, length);
  }

  Int16List asInt16List([int offsetInBytes = 0, int? length]) {
    return NativeInt16List.view(this, offsetInBytes, length);
  }

  Uint32List asUint32List([int offsetInBytes = 0, int? length]) {
    return NativeUint32List.view(this, offsetInBytes, length);
  }

  Int32List asInt32List([int offsetInBytes = 0, int? length]) {
    return NativeInt32List.view(this, offsetInBytes, length);
  }

  Uint64List asUint64List([int offsetInBytes = 0, int? length]) {
    throw UnsupportedError("Uint64List not supported by dart2js.");
  }

  Int64List asInt64List([int offsetInBytes = 0, int? length]) {
    throw UnsupportedError("Int64List not supported by dart2js.");
  }

  Int32x4List asInt32x4List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Int32x4List.bytesPerElement;
    var storage = this.asInt32List(offsetInBytes, length * 4);
    return NativeInt32x4List._externalStorage(storage);
  }

  Float32List asFloat32List([int offsetInBytes = 0, int? length]) {
    return NativeFloat32List.view(this, offsetInBytes, length);
  }

  Float64List asFloat64List([int offsetInBytes = 0, int? length]) {
    return NativeFloat64List.view(this, offsetInBytes, length);
  }

  Float32x4List asFloat32x4List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Float32x4List.bytesPerElement;
    var storage = this.asFloat32List(offsetInBytes, length * 4);
    return NativeFloat32x4List._externalStorage(storage);
  }

  Float64x2List asFloat64x2List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Float64x2List.bytesPerElement;
    var storage = this.asFloat64List(offsetInBytes, length * 2);
    return NativeFloat64x2List._externalStorage(storage);
  }

  ByteData asByteData([int offsetInBytes = 0, int? length]) {
    return NativeByteData.view(this, offsetInBytes, length);
  }
}

/// A fixed-length list of Float32x4 numbers that is viewable as a
/// [TypedData]. For long lists, this implementation will be considerably more
/// space- and time-efficient than the default [List] implementation.
final class NativeFloat32x4List extends Object
    with ListMixin<Float32x4>, FixedLengthListMixin<Float32x4>
    implements Float32x4List {
  final Float32List _storage;

  /// Creates a [Float32x4List] of the specified length (in elements),
  /// all of whose elements are initially zero.
  NativeFloat32x4List(int length) : _storage = NativeFloat32List(length * 4);

  NativeFloat32x4List._externalStorage(this._storage);

  NativeFloat32x4List._slowFromList(List<Float32x4> list)
      : _storage = NativeFloat32List(list.length * 4) {
    for (int i = 0; i < list.length; i++) {
      var e = list[i];
      _storage[(i * 4) + 0] = e.x;
      _storage[(i * 4) + 1] = e.y;
      _storage[(i * 4) + 2] = e.z;
      _storage[(i * 4) + 3] = e.w;
    }
  }

  Type get runtimeType => Float32x4List;

  /// Creates a [Float32x4List] with the same size as the [elements] list
  /// and copies over the elements.
  factory NativeFloat32x4List.fromList(List<Float32x4> list) {
    if (list is NativeFloat32x4List) {
      return NativeFloat32x4List._externalStorage(
          NativeFloat32List.fromList(list._storage));
    } else {
      return NativeFloat32x4List._slowFromList(list);
    }
  }

  ByteBuffer get buffer => _storage.buffer;

  int get lengthInBytes => _storage.lengthInBytes;

  int get offsetInBytes => _storage.offsetInBytes;

  int get elementSizeInBytes => Float32x4List.bytesPerElement;

  int get length => _storage.length ~/ 4;

  Float32x4 operator [](int index) {
    _checkValidIndex(index, this, this.length);
    double _x = _storage[(index * 4) + 0];
    double _y = _storage[(index * 4) + 1];
    double _z = _storage[(index * 4) + 2];
    double _w = _storage[(index * 4) + 3];
    return NativeFloat32x4._truncated(_x, _y, _z, _w);
  }

  void operator []=(int index, Float32x4 value) {
    _checkValidIndex(index, this, this.length);
    _storage[(index * 4) + 0] = value.x;
    _storage[(index * 4) + 1] = value.y;
    _storage[(index * 4) + 2] = value.z;
    _storage[(index * 4) + 3] = value.w;
  }

  Float32x4List asUnmodifiableView() => _UnmodifiableFloat32x4ListView(this);

  Float32x4List sublist(int start, [int? end]) {
    var stop = _checkValidRange(start, end, this.length);
    return NativeFloat32x4List._externalStorage(
        _storage.sublist(start * 4, stop * 4));
  }
}

/// A fixed-length list of Int32x4 numbers that is viewable as a
/// [TypedData]. For long lists, this implementation will be considerably more
/// space- and time-efficient than the default [List] implementation.
final class NativeInt32x4List extends Object
    with ListMixin<Int32x4>, FixedLengthListMixin<Int32x4>
    implements Int32x4List {
  final Int32List _storage;

  /// Creates a [Int32x4List] of the specified length (in elements),
  /// all of whose elements are initially zero.
  NativeInt32x4List(int length) : _storage = NativeInt32List(length * 4);

  NativeInt32x4List._externalStorage(Int32List storage) : _storage = storage;

  NativeInt32x4List._slowFromList(List<Int32x4> list)
      : _storage = NativeInt32List(list.length * 4) {
    for (int i = 0; i < list.length; i++) {
      var e = list[i];
      _storage[(i * 4) + 0] = e.x;
      _storage[(i * 4) + 1] = e.y;
      _storage[(i * 4) + 2] = e.z;
      _storage[(i * 4) + 3] = e.w;
    }
  }

  Type get runtimeType => Int32x4List;

  /// Creates a [Int32x4List] with the same size as the [elements] list
  /// and copies over the elements.
  factory NativeInt32x4List.fromList(List<Int32x4> list) {
    if (list is NativeInt32x4List) {
      return NativeInt32x4List._externalStorage(
          NativeInt32List.fromList(list._storage));
    } else {
      return NativeInt32x4List._slowFromList(list);
    }
  }

  ByteBuffer get buffer => _storage.buffer;

  int get lengthInBytes => _storage.lengthInBytes;

  int get offsetInBytes => _storage.offsetInBytes;

  int get elementSizeInBytes => Int32x4List.bytesPerElement;

  int get length => _storage.length ~/ 4;

  Int32x4 operator [](int index) {
    _checkValidIndex(index, this, this.length);
    int _x = _storage[(index * 4) + 0];
    int _y = _storage[(index * 4) + 1];
    int _z = _storage[(index * 4) + 2];
    int _w = _storage[(index * 4) + 3];
    return NativeInt32x4._truncated(_x, _y, _z, _w);
  }

  void operator []=(int index, Int32x4 value) {
    _checkValidIndex(index, this, this.length);
    _storage[(index * 4) + 0] = value.x;
    _storage[(index * 4) + 1] = value.y;
    _storage[(index * 4) + 2] = value.z;
    _storage[(index * 4) + 3] = value.w;
  }

  Int32x4List asUnmodifiableView() => _UnmodifiableInt32x4ListView(this);

  Int32x4List sublist(int start, [int? end]) {
    var stop = _checkValidRange(start, end, this.length);
    return NativeInt32x4List._externalStorage(
        _storage.sublist(start * 4, stop * 4));
  }
}

/// A fixed-length list of Float64x2 numbers that is viewable as a
/// [TypedData]. For long lists, this implementation will be considerably more
/// space- and time-efficient than the default [List] implementation.
final class NativeFloat64x2List extends Object
    with ListMixin<Float64x2>, FixedLengthListMixin<Float64x2>
    implements Float64x2List {
  final Float64List _storage;

  /// Creates a [Float64x2List] of the specified length (in elements),
  /// all of whose elements are initially zero.
  NativeFloat64x2List(int length) : _storage = NativeFloat64List(length * 2);

  NativeFloat64x2List._externalStorage(this._storage);

  NativeFloat64x2List._slowFromList(List<Float64x2> list)
      : _storage = NativeFloat64List(list.length * 2) {
    for (int i = 0; i < list.length; i++) {
      var e = list[i];
      _storage[(i * 2) + 0] = e.x;
      _storage[(i * 2) + 1] = e.y;
    }
  }

  /// Creates a [Float64x2List] with the same size as the [elements] list
  /// and copies over the elements.
  factory NativeFloat64x2List.fromList(List<Float64x2> list) {
    if (list is NativeFloat64x2List) {
      return NativeFloat64x2List._externalStorage(
          NativeFloat64List.fromList(list._storage));
    } else {
      return NativeFloat64x2List._slowFromList(list);
    }
  }

  Type get runtimeType => Float64x2List;

  ByteBuffer get buffer => _storage.buffer;

  int get lengthInBytes => _storage.lengthInBytes;

  int get offsetInBytes => _storage.offsetInBytes;

  int get elementSizeInBytes => Float64x2List.bytesPerElement;

  int get length => _storage.length ~/ 2;

  Float64x2 operator [](int index) {
    _checkValidIndex(index, this, this.length);
    double _x = _storage[(index * 2) + 0];
    double _y = _storage[(index * 2) + 1];
    return Float64x2(_x, _y);
  }

  void operator []=(int index, Float64x2 value) {
    _checkValidIndex(index, this, this.length);
    _storage[(index * 2) + 0] = value.x;
    _storage[(index * 2) + 1] = value.y;
  }

  Float64x2List asUnmodifiableView() => _UnmodifiableFloat64x2ListView(this);

  Float64x2List sublist(int start, [int? end]) {
    var stop = _checkValidRange(start, end, this.length);
    return NativeFloat64x2List._externalStorage(
        _storage.sublist(start * 2, stop * 2));
  }
}

@Native('ArrayBufferView')
final class NativeTypedData extends JavaScriptObject implements TypedData {
  /// Returns the byte buffer associated with this object.
  @Creates('NativeByteBuffer')
  @Returns('NativeByteBuffer')
  external ByteBuffer get buffer;

  /// Returns the length of this view, in bytes.
  @JSName('byteLength')
  external int get lengthInBytes;

  /// Returns the offset in bytes into the underlying byte buffer of this view.
  @JSName('byteOffset')
  external int get offsetInBytes;

  /// Returns the number of bytes in the representation of each element in this
  /// list.
  @JSName('BYTES_PER_ELEMENT')
  external int get elementSizeInBytes;

  void _invalidPosition(int position, int length, String name) {
    if (position is! int) {
      throw ArgumentError.value(position, name, 'Invalid list position');
    } else {
      throw RangeError.range(position, 0, length, name);
    }
  }

  void _checkPosition(int position, int length, String name) {
    if (JS<bool>('!', '(# >>> 0) !== #', position, position) ||
        JS<int>('!', '#', position) > length) {
      // 'int' guaranteed by above test.
      _invalidPosition(position, length, name);
    }
  }
}

// Validates the unnamed constructor length argument.  Checking is necessary
// because passing unvalidated values to the native constructors can cause
// conversions or create views.
int _checkLength(length) {
  if (length is! int) throw ArgumentError('Invalid length $length');
  return length;
}

// Validates `.view` constructor arguments.  Checking is necessary because
// passing unvalidated values to the native constructors can cause conversions
// (e.g. String arguments) or create typed data objects that are not actually
// views of the input.
void _checkViewArguments(buffer, offsetInBytes, length) {
  if (buffer is! NativeByteBuffer) {
    throw ArgumentError('Invalid view buffer');
  }
  if (offsetInBytes is! int) {
    throw ArgumentError('Invalid view offsetInBytes $offsetInBytes');
  }
  if (length is! int?) {
    throw ArgumentError('Invalid view length $length');
  }
}

// Ensures that [list] is a JavaScript Array or a typed array.  If necessary,
// returns a copy of the list.
List _ensureNativeList(List list) {
  if (list is JSIndexable) return list;
  List result = List.filled(list.length, null);
  for (int i = 0; i < list.length; i++) {
    result[i] = list[i];
  }
  return result;
}

@Native('DataView')
final class NativeByteData extends NativeTypedData implements ByteData {
  /// Creates a [ByteData] of the specified length (in elements), all of
  /// whose elements are initially zero.
  factory NativeByteData(int length) => _create1(_checkLength(length));

  /// Creates an [ByteData] _view_ of the specified region in the specified
  /// byte buffer. Changes in the [ByteData] will be visible in the byte
  /// buffer and vice versa. If the [offsetInBytes] index of the region is not
  /// specified, it defaults to zero (the first byte in the byte buffer).
  /// If the length is not specified, it defaults to null, which indicates
  /// that the view extends to the end of the byte buffer.
  ///
  /// The [offsetInBytes] and [length] must be non-negative, and
  /// [offsetInBytes] + ([length] * elementSizeInBytes) must be less than or
  /// equal to the length of [buffer].
  factory NativeByteData.view(
      ByteBuffer buffer, int offsetInBytes, int? length) {
    _checkViewArguments(buffer, offsetInBytes, length);
    return length == null
        ? _create2(buffer, offsetInBytes)
        : _create3(buffer, offsetInBytes, length);
  }

  Type get runtimeType => ByteData;

  int get elementSizeInBytes => 1;

  ByteData asUnmodifiableView() => _UnmodifiableByteDataView(this);

  /// Returns the floating point number represented by the four bytes at
  /// the specified [byteOffset] in this object, in IEEE 754
  /// single-precision binary floating-point format (binary32).
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 4` must be less than or equal to the length of this object.
  double getFloat32(int byteOffset, [Endian endian = Endian.big]) =>
      _getFloat32(byteOffset, Endian.little == endian);

  @JSName('getFloat32')
  @Returns('double')
  double _getFloat32(int byteOffset, [bool? littleEndian]) native;

  /// Returns the floating point number represented by the eight bytes at
  /// the specified [byteOffset] in this object, in IEEE 754
  /// double-precision binary floating-point format (binary64).
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 8` must be less than or equal to the length of this object.
  double getFloat64(int byteOffset, [Endian endian = Endian.big]) =>
      _getFloat64(byteOffset, Endian.little == endian);

  @JSName('getFloat64')
  @Returns('double')
  double _getFloat64(int byteOffset, [bool? littleEndian]) native;

  /// Returns the (possibly negative) integer represented by the two bytes at
  /// the specified [byteOffset] in this object, in two's complement binary
  /// form.
  /// The return value will be between 2<sup>15</sup> and 2<sup>15</sup> - 1,
  /// inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 2` must be less than or equal to the length of this object.
  int getInt16(int byteOffset, [Endian endian = Endian.big]) =>
      _getInt16(byteOffset, Endian.little == endian);

  @JSName('getInt16')
  @Returns('int')
  int _getInt16(int byteOffset, [bool? littleEndian]) native;

  /// Returns the (possibly negative) integer represented by the four bytes at
  /// the specified [byteOffset] in this object, in two's complement binary
  /// form.
  /// The return value will be between 2<sup>31</sup> and 2<sup>31</sup> - 1,
  /// inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 4` must be less than or equal to the length of this object.
  int getInt32(int byteOffset, [Endian endian = Endian.big]) =>
      _getInt32(byteOffset, Endian.little == endian);

  @JSName('getInt32')
  @Returns('int')
  int _getInt32(int byteOffset, [bool? littleEndian]) native;

  /// Returns the (possibly negative) integer represented by the eight bytes at
  /// the specified [byteOffset] in this object, in two's complement binary
  /// form.
  /// The return value will be between 2<sup>63</sup> and 2<sup>63</sup> - 1,
  /// inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 8` must be less than or equal to the length of this object.
  int getInt64(int byteOffset, [Endian endian = Endian.big]) {
    throw UnsupportedError('Int64 accessor not supported by dart2js.');
  }

  /// Returns the (possibly negative) integer represented by the byte at the
  /// specified [byteOffset] in this object, in two's complement binary
  /// representation. The return value will be between -128 and 127, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// less than the length of this object.
  int getInt8(int byteOffset) native;

  /// Returns the positive integer represented by the two bytes starting
  /// at the specified [byteOffset] in this object, in unsigned binary
  /// form.
  /// The return value will be between 0 and  2<sup>16</sup> - 1, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 2` must be less than or equal to the length of this object.
  int getUint16(int byteOffset, [Endian endian = Endian.big]) =>
      _getUint16(byteOffset, Endian.little == endian);

  @JSName('getUint16')
  @Returns('int')
  int _getUint16(int byteOffset, [bool? littleEndian]) native;

  /// Returns the positive integer represented by the four bytes starting
  /// at the specified [byteOffset] in this object, in unsigned binary
  /// form.
  /// The return value will be between 0 and  2<sup>32</sup> - 1, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 4` must be less than or equal to the length of this object.
  int getUint32(int byteOffset, [Endian endian = Endian.big]) =>
      _getUint32(byteOffset, Endian.little == endian);

  @JSName('getUint32')
  @Returns('int')
  int _getUint32(int byteOffset, [bool? littleEndian]) native;

  /// Returns the positive integer represented by the eight bytes starting
  /// at the specified [byteOffset] in this object, in unsigned binary
  /// form.
  /// The return value will be between 0 and  2<sup>64</sup> - 1, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 8` must be less than or equal to the length of this object.
  int getUint64(int byteOffset, [Endian endian = Endian.big]) {
    throw UnsupportedError('Uint64 accessor not supported by dart2js.');
  }

  /// Returns the positive integer represented by the byte at the specified
  /// [byteOffset] in this object, in unsigned binary form. The
  /// return value will be between 0 and 255, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// less than the length of this object.
  int getUint8(int byteOffset) native;

  /// Sets the four bytes starting at the specified [byteOffset] in this
  /// object to the IEEE 754 single-precision binary floating-point
  /// (binary32) representation of the specified [value].
  ///
  /// **Note that this method can lose precision.** The input [value] is
  /// a 64-bit floating point value, which will be converted to 32-bit
  /// floating point value by IEEE 754 rounding rules before it is stored.
  /// If [value] cannot be represented exactly as a binary32, it will be
  /// converted to the nearest binary32 value.  If two binary32 values are
  /// equally close, the one whose least significant bit is zero will be used.
  /// Note that finite (but large) values can be converted to infinity, and
  /// small non-zero values can be converted to zero.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 4` must be less than or equal to the length of this object.
  void setFloat32(int byteOffset, num value, [Endian endian = Endian.big]) =>
      _setFloat32(byteOffset, value, Endian.little == endian);

  @JSName('setFloat32')
  void _setFloat32(int byteOffset, num value, [bool? littleEndian]) native;

  /// Sets the eight bytes starting at the specified [byteOffset] in this
  /// object to the IEEE 754 double-precision binary floating-point
  /// (binary64) representation of the specified [value].
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 8` must be less than or equal to the length of this object.
  void setFloat64(int byteOffset, num value, [Endian endian = Endian.big]) =>
      _setFloat64(byteOffset, value, Endian.little == endian);

  @JSName('setFloat64')
  void _setFloat64(int byteOffset, num value, [bool? littleEndian]) native;

  /// Sets the two bytes starting at the specified [byteOffset] in this
  /// object to the two's complement binary representation of the specified
  /// [value], which must fit in two bytes. In other words, [value] must lie
  /// between 2<sup>15</sup> and 2<sup>15</sup> - 1, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 2` must be less than or equal to the length of this object.
  void setInt16(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _setInt16(byteOffset, value, Endian.little == endian);

  @JSName('setInt16')
  void _setInt16(int byteOffset, int value, [bool? littleEndian]) native;

  /// Sets the four bytes starting at the specified [byteOffset] in this
  /// object to the two's complement binary representation of the specified
  /// [value], which must fit in four bytes. In other words, [value] must lie
  /// between 2<sup>31</sup> and 2<sup>31</sup> - 1, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 4` must be less than or equal to the length of this object.
  void setInt32(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _setInt32(byteOffset, value, Endian.little == endian);

  @JSName('setInt32')
  void _setInt32(int byteOffset, int value, [bool? littleEndian]) native;

  /// Sets the eight bytes starting at the specified [byteOffset] in this
  /// object to the two's complement binary representation of the specified
  /// [value], which must fit in eight bytes. In other words, [value] must lie
  /// between 2<sup>63</sup> and 2<sup>63</sup> - 1, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 8` must be less than or equal to the length of this object.
  void setInt64(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw UnsupportedError('Int64 accessor not supported by dart2js.');
  }

  /// Sets the byte at the specified [byteOffset] in this object to the
  /// two's complement binary representation of the specified [value], which
  /// must fit in a single byte. In other words, [value] must be between
  /// -128 and 127, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// less than the length of this object.
  void setInt8(int byteOffset, int value) native;

  /// Sets the two bytes starting at the specified [byteOffset] in this object
  /// to the unsigned binary representation of the specified [value],
  /// which must fit in two bytes. in other words, [value] must be between
  /// 0 and 2<sup>16</sup> - 1, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 2` must be less than or equal to the length of this object.
  void setUint16(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _setUint16(byteOffset, value, Endian.little == endian);

  @JSName('setUint16')
  void _setUint16(int byteOffset, int value, [bool? littleEndian]) native;

  /// Sets the four bytes starting at the specified [byteOffset] in this object
  /// to the unsigned binary representation of the specified [value],
  /// which must fit in four bytes. in other words, [value] must be between
  /// 0 and 2<sup>32</sup> - 1, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 4` must be less than or equal to the length of this object.
  void setUint32(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _setUint32(byteOffset, value, Endian.little == endian);

  @JSName('setUint32')
  void _setUint32(int byteOffset, int value, [bool? littleEndian]) native;

  /// Sets the eight bytes starting at the specified [byteOffset] in this object
  /// to the unsigned binary representation of the specified [value],
  /// which must fit in eight bytes. in other words, [value] must be between
  /// 0 and 2<sup>64</sup> - 1, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 8` must be less than or equal to the length of this object.
  void setUint64(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw UnsupportedError('Uint64 accessor not supported by dart2js.');
  }

  /// Sets the byte at the specified [byteOffset] in this object to the
  /// unsigned binary representation of the specified [value], which must fit
  /// in a single byte. in other words, [value] must be between 0 and 255,
  /// inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// less than the length of this object.
  void setUint8(int byteOffset, int value) native;

  static NativeByteData _create1(arg) =>
      JS('NativeByteData', 'new DataView(new ArrayBuffer(#))', arg);

  static NativeByteData _create2(arg1, arg2) =>
      JS('NativeByteData', 'new DataView(#, #)', arg1, arg2);

  static NativeByteData _create3(arg1, arg2, arg3) =>
      JS('NativeByteData', 'new DataView(#, #, #)', arg1, arg2, arg3);
}

abstract final class NativeTypedArray<E> extends NativeTypedData
    implements JavaScriptIndexingBehavior<E> {
  int get length;

  void _setRangeFast(
      int start, int end, NativeTypedArray source, int skipCount) {
    int targetLength = this.length;
    _checkPosition(start, targetLength, "start");
    _checkPosition(end, targetLength, "end");
    if (start > end) throw RangeError.range(start, 0, end);
    int count = end - start;

    if (skipCount < 0) throw ArgumentError(skipCount);

    int sourceLength = source.length;
    if (sourceLength - skipCount < count) {
      throw StateError('Not enough elements');
    }

    if (skipCount != 0 || sourceLength != count) {
      // Create a view of the exact subrange that is copied from the source.
      source = JS('', '#.subarray(#, #)', source, skipCount, skipCount + count);
    }
    JS('void', '#.set(#, #)', this, source, start);
  }
}

abstract final class NativeTypedArrayOfDouble extends NativeTypedArray<double>
    with ListMixin<double>, FixedLengthListMixin<double> {
  int get length => JS<int>('!', '#.length', this);

  double operator [](int index) {
    _checkValidIndex(index, this, this.length);
    return JS<double>('!', '#[#]', this, index);
  }

  void operator []=(int index, num value) {
    _checkValidIndex(index, this, this.length);
    JS('void', '#[#] = #', this, index, value);
  }

  void setRange(int start, int end, Iterable<double> iterable,
      [int skipCount = 0]) {
    if (iterable is NativeTypedArrayOfDouble) {
      _setRangeFast(start, end, iterable, skipCount);
      return;
    }
    super.setRange(start, end, iterable, skipCount);
  }
}

abstract final class NativeTypedArrayOfInt extends NativeTypedArray<int>
    with ListMixin<int>, FixedLengthListMixin<int>
    implements List<int> {
  int get length => JS<int>('!', '#.length', this);

  // operator[]() is not here since different versions have different return
  // types

  void operator []=(int index, int value) {
    _checkValidIndex(index, this, this.length);
    JS('void', '#[#] = #', this, index, value);
  }

  void setRange(int start, int end, Iterable<int> iterable,
      [int skipCount = 0]) {
    if (iterable is NativeTypedArrayOfInt) {
      _setRangeFast(start, end, iterable, skipCount);
      return;
    }
    super.setRange(start, end, iterable, skipCount);
  }
}

@Native('Float32Array')
final class NativeFloat32List extends NativeTypedArrayOfDouble
    implements Float32List {
  factory NativeFloat32List(int length) => _create1(_checkLength(length));

  factory NativeFloat32List.fromList(List<double> elements) =>
      _create1(_ensureNativeList(elements));

  factory NativeFloat32List.view(
      ByteBuffer buffer, int offsetInBytes, int? length) {
    _checkViewArguments(buffer, offsetInBytes, length);
    length ??=
        (buffer.lengthInBytes - offsetInBytes) ~/ Float32List.bytesPerElement;
    return _create3(buffer, offsetInBytes, length);
  }

  Type get runtimeType => Float32List;

  Float32List asUnmodifiableView() => _UnmodifiableFloat32ListView(this);

  Float32List sublist(int start, [int? end]) {
    var stop = _checkValidRange(start, end, this.length);
    var source =
        JS<NativeFloat32List>('!', '#.subarray(#, #)', this, start, stop);
    return _create1(source);
  }

  static NativeFloat32List _create1(arg) =>
      JS<NativeFloat32List>('!', 'new Float32Array(#)', arg);

  static NativeFloat32List _create3(arg1, arg2, arg3) =>
      JS<NativeFloat32List>('!', 'new Float32Array(#, #, #)', arg1, arg2, arg3);
}

@Native('Float64Array')
final class NativeFloat64List extends NativeTypedArrayOfDouble
    implements Float64List {
  factory NativeFloat64List(int length) => _create1(_checkLength(length));

  factory NativeFloat64List.fromList(List<double> elements) =>
      _create1(_ensureNativeList(elements));

  factory NativeFloat64List.view(
      ByteBuffer buffer, int offsetInBytes, int? length) {
    _checkViewArguments(buffer, offsetInBytes, length);
    length ??=
        (buffer.lengthInBytes - offsetInBytes) ~/ Float64List.bytesPerElement;
    return _create3(buffer, offsetInBytes, length);
  }

  Type get runtimeType => Float64List;

  Float64List asUnmodifiableView() => _UnmodifiableFloat64ListView(this);

  Float64List sublist(int start, [int? end]) {
    var stop = _checkValidRange(start, end, this.length);
    var source = JS('NativeFloat64List', '#.subarray(#, #)', this, start, stop);
    return _create1(source);
  }

  static NativeFloat64List _create1(arg) =>
      JS('NativeFloat64List', 'new Float64Array(#)', arg);

  static NativeFloat64List _create3(arg1, arg2, arg3) =>
      JS('NativeFloat64List', 'new Float64Array(#, #, #)', arg1, arg2, arg3);
}

@Native('Int16Array')
final class NativeInt16List extends NativeTypedArrayOfInt implements Int16List {
  factory NativeInt16List(int length) => _create1(_checkLength(length));

  factory NativeInt16List.fromList(List<int> elements) =>
      _create1(_ensureNativeList(elements));

  factory NativeInt16List.view(
      NativeByteBuffer buffer, int offsetInBytes, int? length) {
    _checkViewArguments(buffer, offsetInBytes, length);
    length ??=
        (buffer.lengthInBytes - offsetInBytes) ~/ Int16List.bytesPerElement;
    return _create3(buffer, offsetInBytes, length);
  }

  Type get runtimeType => Int16List;

  int operator [](int index) {
    _checkValidIndex(index, this, this.length);
    return JS<int>('!', '#[#]', this, index);
  }

  Int16List asUnmodifiableView() => _UnmodifiableInt16ListView(this);

  Int16List sublist(int start, [int? end]) {
    var stop = _checkValidRange(start, end, this.length);
    var source = JS('NativeInt16List', '#.subarray(#, #)', this, start, stop);
    return _create1(source);
  }

  static NativeInt16List _create1(arg) =>
      JS('NativeInt16List', 'new Int16Array(#)', arg);

  static NativeInt16List _create3(arg1, arg2, arg3) =>
      JS('NativeInt16List', 'new Int16Array(#, #, #)', arg1, arg2, arg3);
}

@Native('Int32Array')
final class NativeInt32List extends NativeTypedArrayOfInt implements Int32List {
  factory NativeInt32List(int length) => _create1(_checkLength(length));

  factory NativeInt32List.fromList(List<int> elements) =>
      _create1(_ensureNativeList(elements));

  factory NativeInt32List.view(
      ByteBuffer buffer, int offsetInBytes, int? length) {
    _checkViewArguments(buffer, offsetInBytes, length);
    length ??=
        (buffer.lengthInBytes - offsetInBytes) ~/ Int32List.bytesPerElement;
    return _create3(buffer, offsetInBytes, length);
  }

  Type get runtimeType => Int32List;

  int operator [](int index) {
    _checkValidIndex(index, this, this.length);
    return JS<int>('!', '#[#]', this, index);
  }

  Int32List asUnmodifiableView() => _UnmodifiableInt32ListView(this);

  Int32List sublist(int start, [int? end]) {
    var stop = _checkValidRange(start, end, this.length);
    var source =
        JS<NativeInt32List>('!', '#.subarray(#, #)', this, start, stop);
    return _create1(source);
  }

  static NativeInt32List _create1(arg) =>
      JS<NativeInt32List>('!', 'new Int32Array(#)', arg);

  static NativeInt32List _create3(arg1, arg2, arg3) =>
      JS<NativeInt32List>('!', 'new Int32Array(#, #, #)', arg1, arg2, arg3);
}

@Native('Int8Array')
final class NativeInt8List extends NativeTypedArrayOfInt implements Int8List {
  factory NativeInt8List(int length) => _create1(_checkLength(length));

  factory NativeInt8List.fromList(List<int> elements) =>
      _create1(_ensureNativeList(elements));

  factory NativeInt8List.view(
      ByteBuffer buffer, int offsetInBytes, int? length) {
    _checkViewArguments(buffer, offsetInBytes, length);
    return length == null
        ? _create2(buffer, offsetInBytes)
        : _create3(buffer, offsetInBytes, length);
  }

  Type get runtimeType => Int8List;

  int operator [](int index) {
    _checkValidIndex(index, this, this.length);
    return JS<int>('!', '#[#]', this, index);
  }

  Int8List asUnmodifiableView() => _UnmodifiableInt8ListView(this);

  Int8List sublist(int start, [int? end]) {
    var stop = _checkValidRange(start, end, this.length);
    var source = JS<NativeInt8List>('!', '#.subarray(#, #)', this, start, stop);
    return _create1(source);
  }

  static NativeInt8List _create1(arg) =>
      JS<NativeInt8List>('!', 'new Int8Array(#)', arg);

  static NativeInt8List _create2(arg1, arg2) =>
      JS<NativeInt8List>('!', 'new Int8Array(#, #)', arg1, arg2);

  static NativeInt8List _create3(arg1, arg2, arg3) =>
      JS<NativeInt8List>('!', 'new Int8Array(#, #, #)', arg1, arg2, arg3);
}

@Native('Uint16Array')
final class NativeUint16List extends NativeTypedArrayOfInt
    implements Uint16List {
  factory NativeUint16List(int length) => _create1(_checkLength(length));

  factory NativeUint16List.fromList(List<int> list) =>
      _create1(_ensureNativeList(list));

  factory NativeUint16List.view(
      ByteBuffer buffer, int offsetInBytes, int? length) {
    _checkViewArguments(buffer, offsetInBytes, length);
    length ??=
        (buffer.lengthInBytes - offsetInBytes) ~/ Uint16List.bytesPerElement;
    return _create3(buffer, offsetInBytes, length);
  }

  Type get runtimeType => Uint16List;

  int operator [](int index) {
    _checkValidIndex(index, this, this.length);
    return JS<int>('!', '#[#]', this, index);
  }

  Uint16List asUnmodifiableView() => _UnmodifiableUint16ListView(this);

  Uint16List sublist(int start, [int? end]) {
    var stop = _checkValidRange(start, end, this.length);
    var source =
        JS<NativeUint16List>('!', '#.subarray(#, #)', this, start, stop);
    return _create1(source);
  }

  static NativeUint16List _create1(arg) =>
      JS<NativeUint16List>('!', 'new Uint16Array(#)', arg);

  static NativeUint16List _create3(arg1, arg2, arg3) =>
      JS<NativeUint16List>('!', 'new Uint16Array(#, #, #)', arg1, arg2, arg3);
}

@Native('Uint32Array')
final class NativeUint32List extends NativeTypedArrayOfInt
    implements Uint32List {
  factory NativeUint32List(int length) => _create1(_checkLength(length));

  factory NativeUint32List.fromList(List<int> elements) =>
      _create1(_ensureNativeList(elements));

  factory NativeUint32List.view(
      ByteBuffer buffer, int offsetInBytes, int? length) {
    _checkViewArguments(buffer, offsetInBytes, length);
    length ??=
        (buffer.lengthInBytes - offsetInBytes) ~/ Uint32List.bytesPerElement;
    return _create3(buffer, offsetInBytes, length);
  }

  Type get runtimeType => Uint32List;

  int operator [](int index) {
    _checkValidIndex(index, this, this.length);
    return JS<int>('!', '#[#]', this, index);
  }

  Uint32List asUnmodifiableView() => _UnmodifiableUint32ListView(this);

  Uint32List sublist(int start, [int? end]) {
    var stop = _checkValidRange(start, end, this.length);
    var source =
        JS<NativeUint32List>('!', '#.subarray(#, #)', this, start, stop);
    return _create1(source);
  }

  static NativeUint32List _create1(arg) =>
      JS<NativeUint32List>('!', 'new Uint32Array(#)', arg);

  static NativeUint32List _create3(arg1, arg2, arg3) =>
      JS<NativeUint32List>('!', 'new Uint32Array(#, #, #)', arg1, arg2, arg3);
}

@Native('Uint8ClampedArray,CanvasPixelArray')
final class NativeUint8ClampedList extends NativeTypedArrayOfInt
    implements Uint8ClampedList {
  factory NativeUint8ClampedList(int length) => _create1(_checkLength(length));

  factory NativeUint8ClampedList.fromList(List<int> elements) =>
      _create1(_ensureNativeList(elements));

  factory NativeUint8ClampedList.view(
      ByteBuffer buffer, int offsetInBytes, int? length) {
    _checkViewArguments(buffer, offsetInBytes, length);
    return length == null
        ? _create2(buffer, offsetInBytes)
        : _create3(buffer, offsetInBytes, length);
  }

  Type get runtimeType => Uint8ClampedList;

  int get length => JS<int>('!', '#.length', this);

  int operator [](int index) {
    _checkValidIndex(index, this, this.length);
    return JS<int>('!', '#[#]', this, index);
  }

  Uint8ClampedList asUnmodifiableView() =>
      _UnmodifiableUint8ClampedListView(this);

  Uint8ClampedList sublist(int start, [int? end]) {
    var stop = _checkValidRange(start, end, this.length);
    var source =
        JS<NativeUint8ClampedList>('!', '#.subarray(#, #)', this, start, stop);
    return _create1(source);
  }

  static NativeUint8ClampedList _create1(arg) =>
      JS<NativeUint8ClampedList>('!', 'new Uint8ClampedArray(#)', arg);

  static NativeUint8ClampedList _create2(arg1, arg2) =>
      JS<NativeUint8ClampedList>(
          '!', 'new Uint8ClampedArray(#, #)', arg1, arg2);

  static NativeUint8ClampedList _create3(arg1, arg2, arg3) => JS(
      'NativeUint8ClampedList',
      'new Uint8ClampedArray(#, #, #)',
      arg1,
      arg2,
      arg3);
}

// On some browsers Uint8ClampedArray is a subtype of Uint8Array.  Marking
// Uint8List as !nonleaf ensures that the native dispatch correctly handles
// the potential for Uint8ClampedArray to 'accidentally' pick up the
// dispatch record for Uint8List.
@Native('Uint8Array,!nonleaf')
final class NativeUint8List extends NativeTypedArrayOfInt implements Uint8List {
  factory NativeUint8List(int length) => _create1(_checkLength(length));

  factory NativeUint8List.fromList(List<int> elements) =>
      _create1(_ensureNativeList(elements));

  factory NativeUint8List.view(
      ByteBuffer buffer, int offsetInBytes, int? length) {
    _checkViewArguments(buffer, offsetInBytes, length);
    return length == null
        ? _create2(buffer, offsetInBytes)
        : _create3(buffer, offsetInBytes, length);
  }

  Type get runtimeType => Uint8List;

  int get length => JS<int>('!', '#.length', this);

  int operator [](int index) {
    _checkValidIndex(index, this, this.length);
    return JS<int>('!', '#[#]', this, index);
  }

  Uint8List asUnmodifiableView() => _UnmodifiableUint8ListView(this);

  Uint8List sublist(int start, [int? end]) {
    var stop = _checkValidRange(start, end, this.length);
    var source =
        JS<NativeUint8List>('!', '#.subarray(#, #)', this, start, stop);
    return _create1(source);
  }

  static NativeUint8List _create1(arg) =>
      JS<NativeUint8List>('!', 'new Uint8Array(#)', arg);

  static NativeUint8List _create2(arg1, arg2) =>
      JS<NativeUint8List>('!', 'new Uint8Array(#, #)', arg1, arg2);

  static NativeUint8List _create3(arg1, arg2, arg3) =>
      JS<NativeUint8List>('!', 'new Uint8Array(#, #, #)', arg1, arg2, arg3);
}

/// Implementation of Dart Float32x4 immutable value type and operations.
/// Float32x4 stores 4 32-bit floating point values in "lanes".
/// The lanes are "x", "y", "z", and "w" respectively.
final class NativeFloat32x4 implements Float32x4 {
  final double x;
  final double y;
  final double z;
  final double w;

  static final NativeFloat32List _list = NativeFloat32List(4);
  static final Uint32List _uint32view = _list.buffer.asUint32List();

  static double _truncate(x) {
    // TODO(nshahan) Is it safe to replace this operation the JavaScript
    // Math.fround()?
    JS('', '#[0] = #', _list, x);
    return JS<double>('!', '#[0]', _list);
  }

  NativeFloat32x4(double x, double y, double z, double w)
      : this.x = _truncate(x),
        this.y = _truncate(y),
        this.z = _truncate(z),
        this.w = _truncate(w) {
    // We would prefer to check for `double` but in dart2js we can't see the
    // difference anyway.
    if (x is! num) throw ArgumentError(x);
    if (y is! num) throw ArgumentError(y);
    if (z is! num) throw ArgumentError(z);
    if (w is! num) throw ArgumentError(w);
  }

  NativeFloat32x4.splat(double v) : this(v, v, v, v);
  NativeFloat32x4.zero() : this._truncated(0.0, 0.0, 0.0, 0.0);

  /// Returns a bit-wise copy of [i] as a Float32x4.
  factory NativeFloat32x4.fromInt32x4Bits(Int32x4 i) {
    _uint32view[0] = i.x;
    _uint32view[1] = i.y;
    _uint32view[2] = i.z;
    _uint32view[3] = i.w;
    return NativeFloat32x4._truncated(_list[0], _list[1], _list[2], _list[3]);
  }

  NativeFloat32x4.fromFloat64x2(Float64x2 v)
      : this._truncated(_truncate(v.x), _truncate(v.y), 0.0, 0.0);

  /// Creates a new NativeFloat32x4.
  ///
  /// Does not verify if the given arguments are non-null.
  NativeFloat32x4._doubles(double x, double y, double z, double w)
      : this.x = _truncate(x),
        this.y = _truncate(y),
        this.z = _truncate(z),
        this.w = _truncate(w);

  /// Creates a new NativeFloat32x4.
  ///
  /// The constructor does not truncate the arguments. They must already be in
  /// the correct range. It does not verify the type of the given arguments,
  /// either.
  NativeFloat32x4._truncated(this.x, this.y, this.z, this.w);

  String toString() {
    return '[$x, $y, $z, $w]';
  }

  /// Addition operator.
  Float32x4 operator +(Float32x4 other) {
    double _x = x + other.x;
    double _y = y + other.y;
    double _z = z + other.z;
    double _w = w + other.w;
    return NativeFloat32x4._doubles(_x, _y, _z, _w);
  }

  /// Negate operator.
  Float32x4 operator -() {
    return NativeFloat32x4._truncated(-x, -y, -z, -w);
  }

  /// Subtraction operator.
  Float32x4 operator -(Float32x4 other) {
    double _x = x - other.x;
    double _y = y - other.y;
    double _z = z - other.z;
    double _w = w - other.w;
    return NativeFloat32x4._doubles(_x, _y, _z, _w);
  }

  /// Multiplication operator.
  Float32x4 operator *(Float32x4 other) {
    double _x = x * other.x;
    double _y = y * other.y;
    double _z = z * other.z;
    double _w = w * other.w;
    return NativeFloat32x4._doubles(_x, _y, _z, _w);
  }

  /// Division operator.
  Float32x4 operator /(Float32x4 other) {
    double _x = x / other.x;
    double _y = y / other.y;
    double _z = z / other.z;
    double _w = w / other.w;
    return NativeFloat32x4._doubles(_x, _y, _z, _w);
  }

  /// Relational less than.
  Int32x4 lessThan(Float32x4 other) {
    bool _cx = x < other.x;
    bool _cy = y < other.y;
    bool _cz = z < other.z;
    bool _cw = w < other.w;
    return NativeInt32x4._truncated(
        _cx ? -1 : 0, _cy ? -1 : 0, _cz ? -1 : 0, _cw ? -1 : 0);
  }

  /// Relational less than or equal.
  Int32x4 lessThanOrEqual(Float32x4 other) {
    bool _cx = x <= other.x;
    bool _cy = y <= other.y;
    bool _cz = z <= other.z;
    bool _cw = w <= other.w;
    return NativeInt32x4._truncated(
        _cx ? -1 : 0, _cy ? -1 : 0, _cz ? -1 : 0, _cw ? -1 : 0);
  }

  /// Relational greater than.
  Int32x4 greaterThan(Float32x4 other) {
    bool _cx = x > other.x;
    bool _cy = y > other.y;
    bool _cz = z > other.z;
    bool _cw = w > other.w;
    return NativeInt32x4._truncated(
        _cx ? -1 : 0, _cy ? -1 : 0, _cz ? -1 : 0, _cw ? -1 : 0);
  }

  /// Relational greater than or equal.
  Int32x4 greaterThanOrEqual(Float32x4 other) {
    bool _cx = x >= other.x;
    bool _cy = y >= other.y;
    bool _cz = z >= other.z;
    bool _cw = w >= other.w;
    return NativeInt32x4._truncated(
        _cx ? -1 : 0, _cy ? -1 : 0, _cz ? -1 : 0, _cw ? -1 : 0);
  }

  /// Relational equal.
  Int32x4 equal(Float32x4 other) {
    bool _cx = x == other.x;
    bool _cy = y == other.y;
    bool _cz = z == other.z;
    bool _cw = w == other.w;
    return NativeInt32x4._truncated(
        _cx ? -1 : 0, _cy ? -1 : 0, _cz ? -1 : 0, _cw ? -1 : 0);
  }

  /// Relational not-equal.
  Int32x4 notEqual(Float32x4 other) {
    bool _cx = x != other.x;
    bool _cy = y != other.y;
    bool _cz = z != other.z;
    bool _cw = w != other.w;
    return NativeInt32x4._truncated(
        _cx ? -1 : 0, _cy ? -1 : 0, _cz ? -1 : 0, _cw ? -1 : 0);
  }

  /// Returns a copy of this [Float32x4] each lane being scaled by [s].
  Float32x4 scale(double s) {
    double _x = s * x;
    double _y = s * y;
    double _z = s * z;
    double _w = s * w;
    return NativeFloat32x4._doubles(_x, _y, _z, _w);
  }

  /// Returns the absolute value of this [Float32x4].
  Float32x4 abs() {
    double _x = x.abs();
    double _y = y.abs();
    double _z = z.abs();
    double _w = w.abs();
    return NativeFloat32x4._truncated(_x, _y, _z, _w);
  }

  /// Clamps this [Float32x4] to be in the range [lowerLimit]-[upperLimit].
  Float32x4 clamp(Float32x4 lowerLimit, Float32x4 upperLimit) {
    double _lx = lowerLimit.x;
    double _ly = lowerLimit.y;
    double _lz = lowerLimit.z;
    double _lw = lowerLimit.w;
    double _ux = upperLimit.x;
    double _uy = upperLimit.y;
    double _uz = upperLimit.z;
    double _uw = upperLimit.w;
    double _x = x;
    double _y = y;
    double _z = z;
    double _w = w;
    // MAX(MIN(self, upper), lower).
    _x = _x > _ux ? _ux : _x;
    _y = _y > _uy ? _uy : _y;
    _z = _z > _uz ? _uz : _z;
    _w = _w > _uw ? _uw : _w;
    _x = _x < _lx ? _lx : _x;
    _y = _y < _ly ? _ly : _y;
    _z = _z < _lz ? _lz : _z;
    _w = _w < _lw ? _lw : _w;
    return NativeFloat32x4._truncated(_x, _y, _z, _w);
  }

  /// Extract the sign bit from each lane return them in the first 4 bits.
  int get signMask {
    var view = _uint32view;
    int mx, my, mz, mw;
    _list[0] = x;
    _list[1] = y;
    _list[2] = z;
    _list[3] = w;
    // This is correct because dart2js uses the unsigned right shift.
    mx = (view[0] & 0x80000000) >> 31;
    my = (view[1] & 0x80000000) >> 30;
    mz = (view[2] & 0x80000000) >> 29;
    mw = (view[3] & 0x80000000) >> 28;
    return mx | my | mz | mw;
  }

  /// Shuffle the lane values. [mask] must be one of the 256 shuffle constants.
  Float32x4 shuffle(int mask) {
    if ((mask < 0) || (mask > 255)) {
      throw RangeError.range(mask, 0, 255, "mask");
    }
    _list[0] = x;
    _list[1] = y;
    _list[2] = z;
    _list[3] = w;

    double _x = _list[mask & 0x3];
    double _y = _list[(mask >> 2) & 0x3];
    double _z = _list[(mask >> 4) & 0x3];
    double _w = _list[(mask >> 6) & 0x3];
    return NativeFloat32x4._truncated(_x, _y, _z, _w);
  }

  /// Shuffle the lane values in this [Float32x4] and [other]. The returned
  /// Float32x4 will have XY lanes from this [Float32x4] and ZW lanes from
  /// [other]. Uses the same [mask] as [shuffle].
  Float32x4 shuffleMix(Float32x4 other, int mask) {
    if ((mask < 0) || (mask > 255)) {
      throw RangeError.range(mask, 0, 255, "mask");
    }
    _list[0] = x;
    _list[1] = y;
    _list[2] = z;
    _list[3] = w;
    double _x = _list[mask & 0x3];
    double _y = _list[(mask >> 2) & 0x3];

    _list[0] = other.x;
    _list[1] = other.y;
    _list[2] = other.z;
    _list[3] = other.w;
    double _z = _list[(mask >> 4) & 0x3];
    double _w = _list[(mask >> 6) & 0x3];
    return NativeFloat32x4._truncated(_x, _y, _z, _w);
  }

  /// Copy this [Float32x4] and replace the [x] lane.
  Float32x4 withX(double newX) {
    ArgumentError.checkNotNull(newX);
    return NativeFloat32x4._truncated(_truncate(newX), y, z, w);
  }

  /// Copy this [Float32x4] and replace the [y] lane.
  Float32x4 withY(double newY) {
    ArgumentError.checkNotNull(newY);
    return NativeFloat32x4._truncated(x, _truncate(newY), z, w);
  }

  /// Copy this [Float32x4] and replace the [z] lane.
  Float32x4 withZ(double newZ) {
    ArgumentError.checkNotNull(newZ);
    return NativeFloat32x4._truncated(x, y, _truncate(newZ), w);
  }

  /// Copy this [Float32x4] and replace the [w] lane.
  Float32x4 withW(double newW) {
    ArgumentError.checkNotNull(newW);
    return NativeFloat32x4._truncated(x, y, z, _truncate(newW));
  }

  /// Returns the lane-wise minimum value in this [Float32x4] or [other].
  Float32x4 min(Float32x4 other) {
    double _x = x < other.x ? x : other.x;
    double _y = y < other.y ? y : other.y;
    double _z = z < other.z ? z : other.z;
    double _w = w < other.w ? w : other.w;
    return NativeFloat32x4._truncated(_x, _y, _z, _w);
  }

  /// Returns the lane-wise maximum value in this [Float32x4] or [other].
  Float32x4 max(Float32x4 other) {
    double _x = x > other.x ? x : other.x;
    double _y = y > other.y ? y : other.y;
    double _z = z > other.z ? z : other.z;
    double _w = w > other.w ? w : other.w;
    return NativeFloat32x4._truncated(_x, _y, _z, _w);
  }

  /// Returns the square root of this [Float32x4].
  Float32x4 sqrt() {
    double _x = Math.sqrt(x);
    double _y = Math.sqrt(y);
    double _z = Math.sqrt(z);
    double _w = Math.sqrt(w);
    return NativeFloat32x4._doubles(_x, _y, _z, _w);
  }

  /// Returns the reciprocal of this [Float32x4].
  Float32x4 reciprocal() {
    double _x = 1.0 / x;
    double _y = 1.0 / y;
    double _z = 1.0 / z;
    double _w = 1.0 / w;
    return NativeFloat32x4._doubles(_x, _y, _z, _w);
  }

  /// Returns the square root of the reciprocal of this [Float32x4].
  Float32x4 reciprocalSqrt() {
    double _x = Math.sqrt(1.0 / x);
    double _y = Math.sqrt(1.0 / y);
    double _z = Math.sqrt(1.0 / z);
    double _w = Math.sqrt(1.0 / w);
    return NativeFloat32x4._doubles(_x, _y, _z, _w);
  }
}

/// Interface of Dart Int32x4 and operations.
/// Int32x4 stores 4 32-bit bit-masks in "lanes".
/// The lanes are "x", "y", "z", and "w" respectively.
final class NativeInt32x4 implements Int32x4 {
  final int x;
  final int y;
  final int z;
  final int w;

  static final _list = NativeInt32List(4);

  static int _truncate(x) {
    // TODO(nshahan) Is it safe to replace this operation the JavaScript
    // Math.round()?
    JS('', '#[0] = #', _list, x);
    return JS<int>('!', '#[0]', _list);
  }

  NativeInt32x4(int x, int y, int z, int w)
      : this.x = _truncate(x),
        this.y = _truncate(y),
        this.z = _truncate(z),
        this.w = _truncate(w) {
    if (x != this.x && x is! int) throw ArgumentError(x);
    if (y != this.y && y is! int) throw ArgumentError(y);
    if (z != this.z && z is! int) throw ArgumentError(z);
    if (w != this.w && w is! int) throw ArgumentError(w);
  }

  NativeInt32x4.bool(bool x, bool y, bool z, bool w)
      : this.x = x ? -1 : 0,
        this.y = y ? -1 : 0,
        this.z = z ? -1 : 0,
        this.w = w ? -1 : 0;

  /// Returns a bit-wise copy of [f] as a Int32x4.
  factory NativeInt32x4.fromFloat32x4Bits(Float32x4 f) {
    NativeFloat32List floatList = NativeFloat32x4._list;
    floatList[0] = f.x;
    floatList[1] = f.y;
    floatList[2] = f.z;
    floatList[3] = f.w;
    Int32List view = floatList.buffer.asInt32List();
    return NativeInt32x4._truncated(view[0], view[1], view[2], view[3]);
  }

  NativeInt32x4._truncated(this.x, this.y, this.z, this.w);

  String toString() => '[$x, $y, $z, $w]';

  /// The bit-wise or operator.
  Int32x4 operator |(Int32x4 other) {
    // Dart2js uses unsigned results for bit-operations.
    // We use "JS" to fall back to the signed versions.
    return NativeInt32x4._truncated(
        JS("int", "# | #", x, other.x),
        JS("int", "# | #", y, other.y),
        JS("int", "# | #", z, other.z),
        JS("int", "# | #", w, other.w));
  }

  /// The bit-wise and operator.
  Int32x4 operator &(Int32x4 other) {
    // Dart2js uses unsigned results for bit-operations.
    // We use "JS" to fall back to the signed versions.
    return NativeInt32x4._truncated(
        JS("int", "# & #", x, other.x),
        JS("int", "# & #", y, other.y),
        JS("int", "# & #", z, other.z),
        JS("int", "# & #", w, other.w));
  }

  /// The bit-wise xor operator.
  Int32x4 operator ^(Int32x4 other) {
    // Dart2js uses unsigned results for bit-operations.
    // We use "JS" to fall back to the signed versions.
    return NativeInt32x4._truncated(
        JS("int", "# ^ #", x, other.x),
        JS("int", "# ^ #", y, other.y),
        JS("int", "# ^ #", z, other.z),
        JS("int", "# ^ #", w, other.w));
  }

  Int32x4 operator +(Int32x4 other) {
    // Avoid going through the typed array by "| 0" the result.
    return NativeInt32x4._truncated(
        JS("int", "(# + #) | 0", x, other.x),
        JS("int", "(# + #) | 0", y, other.y),
        JS("int", "(# + #) | 0", z, other.z),
        JS("int", "(# + #) | 0", w, other.w));
  }

  Int32x4 operator -(Int32x4 other) {
    // Avoid going through the typed array by "| 0" the result.
    return NativeInt32x4._truncated(
        JS("int", "(# - #) | 0", x, other.x),
        JS("int", "(# - #) | 0", y, other.y),
        JS("int", "(# - #) | 0", z, other.z),
        JS("int", "(# - #) | 0", w, other.w));
  }

  Int32x4 operator -() {
    // Avoid going through the typed array by "| 0" the result.
    return NativeInt32x4._truncated(
        JS("int", "(-#) | 0", x),
        JS("int", "(-#) | 0", y),
        JS("int", "(-#) | 0", z),
        JS("int", "(-#) | 0", w));
  }

  /// Extract the top bit from each lane return them in the first 4 bits.
  int get signMask {
    int mx = (x & 0x80000000) >> 31;
    int my = (y & 0x80000000) >> 31;
    int mz = (z & 0x80000000) >> 31;
    int mw = (w & 0x80000000) >> 31;
    return mx | my << 1 | mz << 2 | mw << 3;
  }

  /// Shuffle the lane values. [mask] must be one of the 256 shuffle constants.
  Int32x4 shuffle(int mask) {
    if ((mask < 0) || (mask > 255)) {
      throw RangeError.range(mask, 0, 255, "mask");
    }
    _list[0] = x;
    _list[1] = y;
    _list[2] = z;
    _list[3] = w;
    int _x = _list[mask & 0x3];
    int _y = _list[(mask >> 2) & 0x3];
    int _z = _list[(mask >> 4) & 0x3];
    int _w = _list[(mask >> 6) & 0x3];
    return NativeInt32x4._truncated(_x, _y, _z, _w);
  }

  /// Shuffle the lane values in this [Int32x4] and [other]. The returned
  /// Int32x4 will have XY lanes from this [Int32x4] and ZW lanes from [other].
  /// Uses the same [mask] as [shuffle].
  Int32x4 shuffleMix(Int32x4 other, int mask) {
    if ((mask < 0) || (mask > 255)) {
      throw RangeError.range(mask, 0, 255, "mask");
    }
    _list[0] = x;
    _list[1] = y;
    _list[2] = z;
    _list[3] = w;
    int _x = _list[mask & 0x3];
    int _y = _list[(mask >> 2) & 0x3];

    _list[0] = other.x;
    _list[1] = other.y;
    _list[2] = other.z;
    _list[3] = other.w;
    int _z = _list[(mask >> 4) & 0x3];
    int _w = _list[(mask >> 6) & 0x3];
    return NativeInt32x4._truncated(_x, _y, _z, _w);
  }

  /// Returns a new [Int32x4] copied from this [Int32x4] with a new x value.
  Int32x4 withX(int x) {
    ArgumentError.checkNotNull(x);
    int _x = _truncate(x);
    return NativeInt32x4._truncated(_x, y, z, w);
  }

  /// Returns a new [Int32x4] copied from this [Int32x4] with a new y value.
  Int32x4 withY(int y) {
    ArgumentError.checkNotNull(y);
    int _y = _truncate(y);
    return NativeInt32x4._truncated(x, _y, z, w);
  }

  /// Returns a new [Int32x4] copied from this [Int32x4] with a new z value.
  Int32x4 withZ(int z) {
    ArgumentError.checkNotNull(z);
    int _z = _truncate(z);
    return NativeInt32x4._truncated(x, y, _z, w);
  }

  /// Returns a new [Int32x4] copied from this [Int32x4] with a new w value.
  Int32x4 withW(int w) {
    ArgumentError.checkNotNull(w);
    int _w = _truncate(w);
    return NativeInt32x4._truncated(x, y, z, _w);
  }

  /// Extracted x value. Returns `false` for 0, `true` for any other value.
  bool get flagX => x != 0;

  /// Extracted y value. Returns `false` for 0, `true` for any other value.
  bool get flagY => y != 0;

  /// Extracted z value. Returns `false` for 0, `true` for any other value.
  bool get flagZ => z != 0;

  /// Extracted w value. Returns `false` for 0, `true` for any other value.
  bool get flagW => w != 0;

  /// Returns a new [Int32x4] copied from this [Int32x4] with a new x value.
  Int32x4 withFlagX(bool flagX) {
    int _x = flagX ? -1 : 0;
    return NativeInt32x4._truncated(_x, y, z, w);
  }

  /// Returns a new [Int32x4] copied from this [Int32x4] with a new y value.
  Int32x4 withFlagY(bool flagY) {
    int _y = flagY ? -1 : 0;
    return NativeInt32x4._truncated(x, _y, z, w);
  }

  /// Returns a new [Int32x4] copied from this [Int32x4] with a new z value.
  Int32x4 withFlagZ(bool flagZ) {
    int _z = flagZ ? -1 : 0;
    return NativeInt32x4._truncated(x, y, _z, w);
  }

  /// Returns a new [Int32x4] copied from this [Int32x4] with a new w value.
  Int32x4 withFlagW(bool flagW) {
    int _w = flagW ? -1 : 0;
    return NativeInt32x4._truncated(x, y, z, _w);
  }

  /// Merge [trueValue] and [falseValue] based on this [Int32x4] bit mask:
  /// Select bit from [trueValue] when bit in this [Int32x4] is on.
  /// Select bit from [falseValue] when bit in this [Int32x4] is off.
  Float32x4 select(Float32x4 trueValue, Float32x4 falseValue) {
    var floatList = NativeFloat32x4._list;
    var intView = NativeFloat32x4._uint32view;

    floatList[0] = trueValue.x;
    floatList[1] = trueValue.y;
    floatList[2] = trueValue.z;
    floatList[3] = trueValue.w;
    int stx = intView[0];
    int sty = intView[1];
    int stz = intView[2];
    int stw = intView[3];

    floatList[0] = falseValue.x;
    floatList[1] = falseValue.y;
    floatList[2] = falseValue.z;
    floatList[3] = falseValue.w;
    int sfx = intView[0];
    int sfy = intView[1];
    int sfz = intView[2];
    int sfw = intView[3];
    int _x = (x & stx) | (~x & sfx);
    int _y = (y & sty) | (~y & sfy);
    int _z = (z & stz) | (~z & sfz);
    int _w = (w & stw) | (~w & sfw);
    intView[0] = _x;
    intView[1] = _y;
    intView[2] = _z;
    intView[3] = _w;
    return NativeFloat32x4._truncated(
        floatList[0], floatList[1], floatList[2], floatList[3]);
  }
}

final class NativeFloat64x2 implements Float64x2 {
  final double x;
  final double y;

  static NativeFloat64List _list = NativeFloat64List(2);
  static Uint32List _uint32View = _list.buffer.asUint32List();

  NativeFloat64x2(this.x, this.y) {
    if (x is! num) throw ArgumentError(x);
    if (y is! num) throw ArgumentError(y);
  }

  NativeFloat64x2.splat(double v) : this(v, v);

  NativeFloat64x2.zero() : this.splat(0.0);

  NativeFloat64x2.fromFloat32x4(Float32x4 v) : this(v.x, v.y);

  /// Arguments [x] and [y] must be doubles.
  NativeFloat64x2._doubles(this.x, this.y);

  String toString() => '[$x, $y]';

  /// Addition operator.
  Float64x2 operator +(Float64x2 other) {
    return NativeFloat64x2._doubles(x + other.x, y + other.y);
  }

  /// Negate operator.
  Float64x2 operator -() {
    return NativeFloat64x2._doubles(-x, -y);
  }

  /// Subtraction operator.
  Float64x2 operator -(Float64x2 other) {
    return NativeFloat64x2._doubles(x - other.x, y - other.y);
  }

  /// Multiplication operator.
  Float64x2 operator *(Float64x2 other) {
    return NativeFloat64x2._doubles(x * other.x, y * other.y);
  }

  /// Division operator.
  Float64x2 operator /(Float64x2 other) {
    return NativeFloat64x2._doubles(x / other.x, y / other.y);
  }

  /// Returns a copy of this [Float64x2] each lane being scaled by [s].
  Float64x2 scale(double s) {
    return NativeFloat64x2._doubles(x * s, y * s);
  }

  /// Returns the absolute value of this [Float64x2].
  Float64x2 abs() {
    return NativeFloat64x2._doubles(x.abs(), y.abs());
  }

  /// Clamps this [Float64x2] to be in the range [lowerLimit]-[upperLimit].
  Float64x2 clamp(Float64x2 lowerLimit, Float64x2 upperLimit) {
    double _lx = lowerLimit.x;
    double _ly = lowerLimit.y;
    double _ux = upperLimit.x;
    double _uy = upperLimit.y;
    double _x = x;
    double _y = y;
    // MAX(MIN(self, upper), lower).
    _x = _x > _ux ? _ux : _x;
    _y = _y > _uy ? _uy : _y;
    _x = _x < _lx ? _lx : _x;
    _y = _y < _ly ? _ly : _y;
    return NativeFloat64x2._doubles(_x, _y);
  }

  /// Extract the sign bits from each lane return them in the first 2 bits.
  int get signMask {
    var view = _uint32View;
    _list[0] = x;
    _list[1] = y;
    var mx = (view[1] & 0x80000000) >> 31;
    var my = (view[3] & 0x80000000) >> 31;
    return mx | my << 1;
  }

  /// Returns a new [Float64x2] copied from this [Float64x2] with a new x
  /// value.
  Float64x2 withX(double x) {
    if (x is! num) throw ArgumentError(x);
    return NativeFloat64x2._doubles(x, y);
  }

  /// Returns a new [Float64x2] copied from this [Float64x2] with a new y
  /// value.
  Float64x2 withY(double y) {
    if (y is! num) throw ArgumentError(y);
    return NativeFloat64x2._doubles(x, y);
  }

  /// Returns the lane-wise minimum value in this [Float64x2] or [other].
  Float64x2 min(Float64x2 other) {
    return NativeFloat64x2._doubles(
        x < other.x ? x : other.x, y < other.y ? y : other.y);
  }

  /// Returns the lane-wise maximum value in this [Float64x2] or [other].
  Float64x2 max(Float64x2 other) {
    return NativeFloat64x2._doubles(
        x > other.x ? x : other.x, y > other.y ? y : other.y);
  }

  /// Returns the lane-wise square root of this [Float64x2].
  Float64x2 sqrt() {
    return NativeFloat64x2._doubles(Math.sqrt(x), Math.sqrt(y));
  }
}

/// Checks that the value is a Uint32. If not, it's not valid as an array
/// index or offset. Also ensures that the value is non-negative.
bool _isInvalidArrayIndex(int index) {
  return (JS<bool>('!', '(# >>> 0 !== #)', index, index));
}

/// Checks that [index] is a valid index into [list] which has length [length].
///
/// That is, [index] is an integer in the range `0..length - 1`.
void _checkValidIndex(int index, List list, int length) {
  if (_isInvalidArrayIndex(index) || JS<int>('!', '#', index) >= length) {
    throw diagnoseIndexError(list, index);
  }
}

/// Checks that [start] and [end] form a range of a list of length [length].
///
/// That is: `start` and `end` are integers with `0 <= start <= end <= length`.
/// If `end` is `null` in which case it is considered to be `length`
///
/// Returns the actual value of `end`, which is `length` if `end` is `null`, and
/// the original value of `end` otherwise.
int _checkValidRange(int start, int? end, int length) {
  if (_isInvalidArrayIndex(start) || // Ensures start is non-negative int.
      ((end == null)
          ? start > length
          : (_isInvalidArrayIndex(end) || start > end || end > length))) {
    throw diagnoseRangeError(start, end, length);
  }
  if (end == null) return length;
  return end;
}

/// A read-only view of a [ByteBuffer].
final class _UnmodifiableByteBufferView implements ByteBuffer {
  final ByteBuffer _data;

  _UnmodifiableByteBufferView(ByteBuffer data) : _data = data;

  int get lengthInBytes => _data.lengthInBytes;

  Uint8List asUint8List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableUint8ListView(_data.asUint8List(offsetInBytes, length));

  Int8List asInt8List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableInt8ListView(_data.asInt8List(offsetInBytes, length));

  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableUint8ClampedListView(
          _data.asUint8ClampedList(offsetInBytes, length));

  Uint16List asUint16List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableUint16ListView(_data.asUint16List(offsetInBytes, length));

  Int16List asInt16List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableInt16ListView(_data.asInt16List(offsetInBytes, length));

  Uint32List asUint32List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableUint32ListView(_data.asUint32List(offsetInBytes, length));

  Int32List asInt32List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableInt32ListView(_data.asInt32List(offsetInBytes, length));

  Uint64List asUint64List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableUint64ListView(_data.asUint64List(offsetInBytes, length));

  Int64List asInt64List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableInt64ListView(_data.asInt64List(offsetInBytes, length));

  Int32x4List asInt32x4List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableInt32x4ListView(_data.asInt32x4List(offsetInBytes, length));

  Float32List asFloat32List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableFloat32ListView(_data.asFloat32List(offsetInBytes, length));

  Float64List asFloat64List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableFloat64ListView(_data.asFloat64List(offsetInBytes, length));

  Float32x4List asFloat32x4List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableFloat32x4ListView(
          _data.asFloat32x4List(offsetInBytes, length));

  Float64x2List asFloat64x2List([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableFloat64x2ListView(
          _data.asFloat64x2List(offsetInBytes, length));

  ByteData asByteData([int offsetInBytes = 0, int? length]) =>
      _UnmodifiableByteDataView(_data.asByteData(offsetInBytes, length));
}

/// A read-only view of a [ByteData].
final class _UnmodifiableByteDataView implements ByteData {
  final ByteData _data;

  _UnmodifiableByteDataView(ByteData data) : _data = data;

  ByteData asUnmodifiableView() => this;

  int getInt8(int byteOffset) => _data.getInt8(byteOffset);

  void setInt8(int byteOffset, int value) => _unsupported();

  int getUint8(int byteOffset) => _data.getUint8(byteOffset);

  void setUint8(int byteOffset, int value) => _unsupported();

  int getInt16(int byteOffset, [Endian endian = Endian.big]) =>
      _data.getInt16(byteOffset, endian);

  void setInt16(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _unsupported();

  int getUint16(int byteOffset, [Endian endian = Endian.big]) =>
      _data.getUint16(byteOffset, endian);

  void setUint16(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _unsupported();

  int getInt32(int byteOffset, [Endian endian = Endian.big]) =>
      _data.getInt32(byteOffset, endian);

  void setInt32(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _unsupported();

  int getUint32(int byteOffset, [Endian endian = Endian.big]) =>
      _data.getUint32(byteOffset, endian);

  void setUint32(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _unsupported();

  int getInt64(int byteOffset, [Endian endian = Endian.big]) =>
      _data.getInt64(byteOffset, endian);

  void setInt64(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _unsupported();

  int getUint64(int byteOffset, [Endian endian = Endian.big]) =>
      _data.getUint64(byteOffset, endian);

  void setUint64(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _unsupported();

  double getFloat32(int byteOffset, [Endian endian = Endian.big]) =>
      _data.getFloat32(byteOffset, endian);

  void setFloat32(int byteOffset, double value, [Endian endian = Endian.big]) =>
      _unsupported();

  double getFloat64(int byteOffset, [Endian endian = Endian.big]) =>
      _data.getFloat64(byteOffset, endian);

  void setFloat64(int byteOffset, double value, [Endian endian = Endian.big]) =>
      _unsupported();

  int get elementSizeInBytes => _data.elementSizeInBytes;

  int get offsetInBytes => _data.offsetInBytes;

  int get lengthInBytes => _data.lengthInBytes;

  ByteBuffer get buffer => _UnmodifiableByteBufferView(_data.buffer);

  void _unsupported() {
    throw UnsupportedError("An UnmodifiableByteDataView may not be modified");
  }
}

mixin _UnmodifiableTypedListMixin<N, L extends List<N>, TD extends TypedData> {
  L get _list;
  TD get _data => (_list as TD);

  int get length => _list.length;

  N operator [](int index) => _list[index];

  int get elementSizeInBytes => _data.elementSizeInBytes;

  int get offsetInBytes => _data.offsetInBytes;

  int get lengthInBytes => _data.lengthInBytes;

  TD asUnmodifiableView() => unsafeCast<TD>(this);

  ByteBuffer get buffer => _UnmodifiableByteBufferView(_data.buffer);

  L _createList(int length);

  L sublist(int start, [int? end]) {
    // NNBD: Spurious error at `end`, `checkValidRange` is legacy.
    int endIndex = RangeError.checkValidRange(start, end!, length);
    int sublistLength = endIndex - start;
    L result = _createList(sublistLength);
    result.setRange(0, sublistLength, _list, start);
    return result;
  }
}

/// View of a [Uint8List] that disallows modification.
final class _UnmodifiableUint8ListView extends UnmodifiableListBase<int>
    with _UnmodifiableTypedListMixin<int, Uint8List, Uint8List>
    implements Uint8List {
  final Uint8List _list;
  _UnmodifiableUint8ListView(Uint8List list) : _list = list;

  Uint8List _createList(int length) => Uint8List(length);
}

/// View of a [Int8List] that disallows modification.
final class _UnmodifiableInt8ListView extends UnmodifiableListBase<int>
    with _UnmodifiableTypedListMixin<int, Int8List, Int8List>
    implements Int8List {
  final Int8List _list;
  _UnmodifiableInt8ListView(Int8List list) : _list = list;

  Int8List _createList(int length) => Int8List(length);
}

/// View of a [Uint8ClampedList] that disallows modification.
final class _UnmodifiableUint8ClampedListView extends UnmodifiableListBase<int>
    with _UnmodifiableTypedListMixin<int, Uint8ClampedList, Uint8ClampedList>
    implements Uint8ClampedList {
  final Uint8ClampedList _list;
  _UnmodifiableUint8ClampedListView(Uint8ClampedList list) : _list = list;

  Uint8ClampedList _createList(int length) => Uint8ClampedList(length);
}

/// View of a [Uint16List] that disallows modification.
final class _UnmodifiableUint16ListView extends UnmodifiableListBase<int>
    with _UnmodifiableTypedListMixin<int, Uint16List, Uint16List>
    implements Uint16List {
  final Uint16List _list;
  _UnmodifiableUint16ListView(Uint16List list) : _list = list;

  Uint16List _createList(int length) => Uint16List(length);
}

/// View of a [Int16List] that disallows modification.
final class _UnmodifiableInt16ListView extends UnmodifiableListBase<int>
    with _UnmodifiableTypedListMixin<int, Int16List, Int16List>
    implements Int16List {
  final Int16List _list;
  _UnmodifiableInt16ListView(Int16List list) : _list = list;

  Int16List _createList(int length) => Int16List(length);
}

/// View of a [Uint32List] that disallows modification.
final class _UnmodifiableUint32ListView extends UnmodifiableListBase<int>
    with _UnmodifiableTypedListMixin<int, Uint32List, Uint32List>
    implements Uint32List {
  final Uint32List _list;
  _UnmodifiableUint32ListView(Uint32List list) : _list = list;

  Uint32List _createList(int length) => Uint32List(length);
}

/// View of a [Int32List] that disallows modification.
final class _UnmodifiableInt32ListView extends UnmodifiableListBase<int>
    with _UnmodifiableTypedListMixin<int, Int32List, Int32List>
    implements Int32List {
  final Int32List _list;
  _UnmodifiableInt32ListView(Int32List list) : _list = list;

  Int32List _createList(int length) => Int32List(length);
}

/// View of a [Uint64List] that disallows modification.
final class _UnmodifiableUint64ListView extends UnmodifiableListBase<int>
    with _UnmodifiableTypedListMixin<int, Uint64List, Uint64List>
    implements Uint64List {
  final Uint64List _list;
  _UnmodifiableUint64ListView(Uint64List list) : _list = list;

  Uint64List _createList(int length) => Uint64List(length);
}

/// View of a [Int64List] that disallows modification.
final class _UnmodifiableInt64ListView extends UnmodifiableListBase<int>
    with _UnmodifiableTypedListMixin<int, Int64List, Int64List>
    implements Int64List {
  final Int64List _list;
  _UnmodifiableInt64ListView(Int64List list) : _list = list;

  Int64List _createList(int length) => Int64List(length);
}

/// View of a [Int32x4List] that disallows modification.
final class _UnmodifiableInt32x4ListView extends UnmodifiableListBase<Int32x4>
    with _UnmodifiableTypedListMixin<Int32x4, Int32x4List, Int32x4List>
    implements Int32x4List {
  final Int32x4List _list;
  _UnmodifiableInt32x4ListView(Int32x4List list) : _list = list;

  Int32x4List _createList(int length) => Int32x4List(length);
}

/// View of a [Float32x4List] that disallows modification.
final class _UnmodifiableFloat32x4ListView
    extends UnmodifiableListBase<Float32x4>
    with _UnmodifiableTypedListMixin<Float32x4, Float32x4List, Float32x4List>
    implements Float32x4List {
  final Float32x4List _list;
  _UnmodifiableFloat32x4ListView(Float32x4List list) : _list = list;

  Float32x4List _createList(int length) => Float32x4List(length);
}

/// View of a [Float64x2List] that disallows modification.
final class _UnmodifiableFloat64x2ListView
    extends UnmodifiableListBase<Float64x2>
    with _UnmodifiableTypedListMixin<Float64x2, Float64x2List, Float64x2List>
    implements Float64x2List {
  final Float64x2List _list;
  _UnmodifiableFloat64x2ListView(Float64x2List list) : _list = list;

  Float64x2List _createList(int length) => Float64x2List(length);
}

/// View of a [Float32List] that disallows modification.
final class _UnmodifiableFloat32ListView extends UnmodifiableListBase<double>
    with _UnmodifiableTypedListMixin<double, Float32List, Float32List>
    implements Float32List {
  final Float32List _list;
  _UnmodifiableFloat32ListView(Float32List list) : _list = list;

  Float32List _createList(int length) => Float32List(length);
}

/// View of a [Float64List] that disallows modification.
final class _UnmodifiableFloat64ListView extends UnmodifiableListBase<double>
    with _UnmodifiableTypedListMixin<double, Float64List, Float64List>
    implements Float64List {
  final Float64List _list;
  _UnmodifiableFloat64ListView(Float64List list) : _list = list;

  Float64List _createList(int length) => Float64List(length);
}
