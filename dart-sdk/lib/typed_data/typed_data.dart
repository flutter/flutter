// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Lists that efficiently handle fixed sized data
/// (for example, unsigned 8 byte integers) and SIMD numeric types.
///
/// To use this library in your code:
/// ```dart
/// import 'dart:typed_data';
/// ```
/// {@category Core}
/// {@canonicalFor dart:_internal.BytesBuilder}
library dart.typed_data;

import "dart:_internal" show Since, UnmodifiableListBase;

@Since("2.10")
export "dart:_internal" show BytesBuilder;

/// A sequence of bytes underlying a typed data object.
///
/// Used to process large quantities of binary or numerical data
/// more efficiently using a typed view.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// `ByteBuffer`.
abstract final class ByteBuffer {
  /// The length of this byte buffer, in bytes.
  int get lengthInBytes;

  /// Creates a [Uint8List] _view_ of a region of this byte buffer.
  ///
  /// The view is backed by the bytes of this byte buffer.
  /// Any changes made to the `Uint8List` will also change the buffer,
  /// and vice versa.
  ///
  /// The viewed region start at [offsetInBytes] and contains [length] bytes.
  /// If [length] is omitted, the range extends to the end of the buffer.
  ///
  /// The start index and length must describe a valid range of the buffer:
  ///
  /// * `offsetInBytes` must not be negative,
  /// * `length` must not be negative, and
  /// * `offsetInBytes + length` must not be greater than [lengthInBytes].
  Uint8List asUint8List([int offsetInBytes = 0, int? length]);

  /// Creates a [Int8List] _view_ of a region of this byte buffer.
  ///
  /// The view is backed by the bytes of this byte buffer.
  /// Any changes made to the `Int8List` will also change the buffer,
  /// and vice versa.
  ///
  /// The viewed region start at [offsetInBytes] and contains [length] bytes.
  /// If [length] is omitted, the range extends to the end of the buffer.
  ///
  /// The start index and length must describe a valid range of the buffer:
  ///
  /// * `offsetInBytes` must not be negative,
  /// * `length` must not be negative, and
  /// * `offsetInBytes + length` must not be greater than [lengthInBytes].
  Int8List asInt8List([int offsetInBytes = 0, int? length]);

  /// Creates a [Uint8ClampedList] _view_ of a region of this byte buffer.
  ///
  /// The view is backed by the bytes of this byte buffer.
  /// Any changes made to the `Uint8ClampedList` will also change the buffer,
  /// and vice versa.
  ///
  /// The viewed region start at [offsetInBytes] and contains [length] bytes.
  /// If [length] is omitted, the range extends to the end of the buffer.
  ///
  /// The start index and length must describe a valid range of the buffer:
  ///
  /// * `offsetInBytes` must not be negative,
  /// * `length` must not be negative, and
  /// * `offsetInBytes + length` must not be greater than [lengthInBytes].
  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int? length]);

  /// Creates a [Uint16List] _view_ of a region of this byte buffer.
  ///
  /// The view is backed by the bytes of this byte buffer.
  /// Any changes made to the `Uint16List` will also change the buffer,
  /// and vice versa.
  ///
  /// The viewed region start at [offsetInBytes], which must be 16-bit aligned,
  /// and contains [length] 16-bit integers with
  /// the same endianness as the host ([Endian.host]).
  /// If [length] is omitted, the range extends as far towards the end of
  /// the buffer as possible -
  /// if [lengthInBytes] is not even, the last byte can't be part of the view.
  ///
  /// The start index and length must describe a valid 16-bit aligned range
  /// of the buffer:
  ///
  /// * `offsetInBytes` must not be negative,
  /// * `offsetInBytes` must be divisible by two,
  /// * `length` must not be negative, and
  /// * `offsetInBytes + length * 2` must not be greater than [lengthInBytes].
  Uint16List asUint16List([int offsetInBytes = 0, int? length]);

  /// Creates a [Int16List] _view_ of a region of this byte buffer.
  ///
  /// The view is backed by the bytes of this byte buffer.
  /// Any changes made to the `Int16List` will also change the buffer,
  /// and vice versa.
  ///
  /// The viewed region start at [offsetInBytes], which must be 16-bit aligned,
  /// and contains [length] 16-bit integers with
  /// the same endianness as the host ([Endian.host]).
  /// If [length] is omitted, the range extends as far towards the end of
  /// the buffer as possible -
  /// if [lengthInBytes] is not even, the last byte can't be part of the view.
  ///
  /// The start index and length must describe a valid 16-bit aligned range
  /// of the buffer:
  ///
  /// * `offsetInBytes` must not be negative,
  /// * `offsetInBytes` must be divisible by two,
  /// * `length` must not be negative, and
  /// * `offsetInBytes + length * 2` must not be greater than [lengthInBytes].
  Int16List asInt16List([int offsetInBytes = 0, int? length]);

  /// Creates a [Uint32List] _view_ of a region of this byte buffer.
  ///
  /// The view is backed by the bytes of this byte buffer.
  /// Any changes made to the `Uint32List` will also change the buffer,
  /// and vice versa.
  ///
  /// The viewed region start at [offsetInBytes], which must be 32-bit aligned,
  /// and contains [length] 32-bit integers with
  /// the same endianness as the host ([Endian.host]).
  /// If [length] is omitted, the range extends as far towards the end of
  /// the buffer as possible -
  /// if [lengthInBytes] is not divisible by four, the last bytes can't be part
  /// of the view.
  ///
  /// The start index and length must describe a valid 32-bit aligned range
  /// of the buffer:
  ///
  /// * `offsetInBytes` must not be negative,
  /// * `offsetInBytes` must be divisible by four,
  /// * `length` must not be negative, and
  /// * `offsetInBytes + length * 4` must not be greater than [lengthInBytes].
  Uint32List asUint32List([int offsetInBytes = 0, int? length]);

  /// Creates a [Int32List] _view_ of a region of this byte buffer.
  ///
  /// The view is backed by the bytes of this byte buffer.
  /// Any changes made to the `Int32List` will also change the buffer,
  /// and vice versa.
  ///
  /// The viewed region start at [offsetInBytes], which must be 32-bit aligned,
  /// and contains [length] 32-bit integers with
  /// the same endianness as the host ([Endian.host]).
  /// If [length] is omitted, the range extends as far towards the end of
  /// the buffer as possible -
  /// if [lengthInBytes] is not divisible by four, the last bytes can't be part
  /// of the view.
  ///
  /// The start index and length must describe a valid 32-bit aligned range
  /// of the buffer:
  ///
  /// * `offsetInBytes` must not be negative,
  /// * `offsetInBytes` must be divisible by four,
  /// * `length` must not be negative, and
  /// * `offsetInBytes + length * 4` must not be greater than [lengthInBytes].
  Int32List asInt32List([int offsetInBytes = 0, int? length]);

  /// Creates a [Uint64List] _view_ of a region of this byte buffer.
  ///
  /// The view is backed by the bytes of this byte buffer.
  /// Any changes made to the `Uint64List` will also change the buffer,
  /// and vice versa.
  ///
  /// The viewed region start at [offsetInBytes], which must be 64-bit aligned,
  /// and contains [length] 64-bit integers with
  /// the same endianness as the host ([Endian.host]).
  /// If [length] is omitted, the range extends as far towards the end of
  /// the buffer as possible -
  /// if [lengthInBytes] is not divisible by eight, the last bytes can't be part
  /// of the view.
  ///
  /// The start index and length must describe a valid 64-bit aligned range
  /// of the buffer:
  ///
  /// * `offsetInBytes` must not be negative,
  /// * `offsetInBytes` must be divisible by eight,
  /// * `length` must not be negative, and
  /// * `offsetInBytes + length * 8` must not be greater than [lengthInBytes].
  Uint64List asUint64List([int offsetInBytes = 0, int? length]);

  /// Creates a [Int64List] _view_ of a region of this byte buffer.
  ///
  /// The view is backed by the bytes of this byte buffer.
  /// Any changes made to the `Int64List` will also change the buffer,
  /// and vice versa.
  ///
  /// The viewed region start at [offsetInBytes], which must be 64-bit aligned,
  /// and contains [length] 64-bit integers with
  /// the same endianness as the host ([Endian.host]).
  /// If [length] is omitted, the range extends as far towards the end of
  /// the buffer as possible -
  /// if [lengthInBytes] is not divisible by eight, the last bytes can't be part
  /// of the view.
  ///
  /// The start index and length must describe a valid 64-bit aligned range
  /// of the buffer:
  ///
  /// * `offsetInBytes` must not be negative,
  /// * `offsetInBytes` must be divisible by eight,
  /// * `length` must not be negative, and
  /// * `offsetInBytes + length * 8` must not be greater than [lengthInBytes].
  Int64List asInt64List([int offsetInBytes = 0, int? length]);

  /// Creates a [Int32x4List] _view_ of a region of this byte buffer.
  ///
  /// The view is backed by the bytes of this byte buffer.
  /// Any changes made to the `Int32x4List` will also change the buffer,
  /// and vice versa.
  ///
  /// The viewed region start at [offsetInBytes], which must be 128-bit aligned,
  /// and contains [length] 128-bit integers.
  /// If [length] is omitted, the range extends as far towards the end of
  /// the buffer as possible -
  /// if [lengthInBytes] is not divisible by 16, the last bytes can't be part
  /// of the view.
  ///
  /// The start index and length must describe a valid 128-bit aligned range
  /// of the buffer:
  ///
  /// * `offsetInBytes` must not be negative,
  /// * `offsetInBytes` must be divisible by sixteen,
  /// * `length` must not be negative, and
  /// * `offsetInBytes + length * 16` must not be greater than [lengthInBytes].
  Int32x4List asInt32x4List([int offsetInBytes = 0, int? length]);

  /// Creates a [Float32List] _view_ of a region of this byte buffer.
  ///
  /// The view is backed by the bytes of this byte buffer.
  /// Any changes made to the `Float32List` will also change the buffer,
  /// and vice versa.
  ///
  /// The viewed region start at [offsetInBytes], which must be 32-bit aligned,
  /// and contains [length] 32-bit integers.
  /// If [length] is omitted, the range extends as far towards the end of
  /// the buffer as possible -
  /// if [lengthInBytes] is not divisible by four, the last bytes can't be part
  /// of the view.
  ///
  /// The start index and length must describe a valid 32-bit aligned range
  /// of the buffer:
  ///
  /// * `offsetInBytes` must not be negative,
  /// * `offsetInBytes` must be divisible by four,
  /// * `length` must not be negative, and
  /// * `offsetInBytes + length * 4` must not be greater than [lengthInBytes].
  Float32List asFloat32List([int offsetInBytes = 0, int? length]);

  /// Creates a [Float64List] _view_ of a region of this byte buffer.
  ///
  /// The view is backed by the bytes of this byte buffer.
  /// Any changes made to the `Float64List` will also change the buffer,
  /// and vice versa.
  ///
  /// The viewed region start at [offsetInBytes], which must be 64-bit aligned,
  /// and contains [length] 64-bit integers.
  /// If [length] is omitted, the range extends as far towards the end of
  /// the buffer as possible -
  /// if [lengthInBytes] is not divisible by eight, the last bytes can't be part
  /// of the view.
  ///
  /// The start index and length must describe a valid 64-bit aligned range
  /// of the buffer:
  ///
  /// * `offsetInBytes` must not be negative,
  /// * `offsetInBytes` must be divisible by eight,
  /// * `length` must not be negative, and
  /// * `offsetInBytes + length * 8` must not be greater than [lengthInBytes].
  Float64List asFloat64List([int offsetInBytes = 0, int? length]);

  /// Creates a [Float32x4List] _view_ of a region of this byte buffer.
  ///
  /// The view is backed by the bytes of this byte buffer.
  /// Any changes made to the `Float32x4List` will also change the buffer,
  /// and vice versa.
  ///
  /// The viewed region start at [offsetInBytes], which must be 128-bit aligned,
  /// and contains [length] 128-bit integers.
  /// If [length] is omitted, the range extends as far towards the end of
  /// the buffer as possible -
  /// if [lengthInBytes] is not divisible by 16, the last bytes can't be part
  /// of the view.
  ///
  /// The start index and length must describe a valid 128-bit aligned range
  /// of the buffer:
  ///
  /// * `offsetInBytes` must not be negative,
  /// * `offsetInBytes` must be divisible by sixteen,
  /// * `length` must not be negative, and
  /// * `offsetInBytes + length * 16` must not be greater than [lengthInBytes].
  Float32x4List asFloat32x4List([int offsetInBytes = 0, int? length]);

  /// Creates a [Float64x2List] _view_ of a region of this byte buffer.
  ///
  /// The view is backed by the bytes of this byte buffer.
  /// Any changes made to the `Float64x2List` will also change the buffer,
  /// and vice versa.
  ///
  /// The viewed region start at [offsetInBytes], which must be 128-bit aligned,
  /// and contains [length] 128-bit integers.
  /// If [length] is omitted, the range extends as far towards the end of
  /// the buffer as possible -
  /// if [lengthInBytes] is not divisible by 16, the last bytes can't be part
  /// of the view.
  ///
  /// The start index and length must describe a valid 128-bit aligned range
  /// of the buffer:
  ///
  /// * `offsetInBytes` must not be negative,
  /// * `offsetInBytes` must be divisible by sixteen,
  /// * `length` must not be negative, and
  /// * `offsetInBytes + length * 16` must not be greater than [lengthInBytes].
  Float64x2List asFloat64x2List([int offsetInBytes = 0, int? length]);

  /// Creates a [ByteData] _view_ of a region of this byte buffer.
  ///
  /// The view is backed by the bytes of this byte buffer.
  /// Any changes made to the `ByteData` will also change the buffer,
  /// and vice versa.
  ///
  /// The viewed region start at [offsetInBytes] and contains [length] bytes.
  /// If [length] is omitted, the range extends to the end of the buffer.
  ///
  /// The start index and length must describe a valid range of the buffer:
  ///
  /// * `offsetInBytes` must not be negative,
  /// * `length` must not be negative, and
  /// * `offsetInBytes + length` must not be greater than [lengthInBytes].
  ByteData asByteData([int offsetInBytes = 0, int? length]);
}

/// A typed view of a sequence of bytes.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// `TypedData`.
abstract final class TypedData {
  /// The number of bytes in the representation of each element in this list.
  int get elementSizeInBytes;

  /// The offset of this view into the underlying byte buffer, in bytes.
  int get offsetInBytes;

  /// The length of this view, in bytes.
  int get lengthInBytes;

  /// The byte buffer associated with this object.
  ByteBuffer get buffer;
}

/// A [TypedData] fixed-length [List]-view on the bytes of [buffer].
@Since("3.5")
abstract final class TypedDataList<E> implements TypedData, List<E> {}

abstract final class _TypedIntList implements TypedDataList<int> {
  /// The concatenation of this list and [other].
  ///
  /// If other is also a typed-data integer list, the returned list will
  /// be a type-data integer list capable of containing all the elements of
  /// this list and of [other].
  /// Otherwise the returned list will be a normal growable `List<int>`.
  List<int> operator +(List<int> other);
}

abstract final class _TypedFloatList implements TypedDataList<double> {
  /// The concatenation of this list and [other].
  ///
  /// If other is also a typed-data floating point number list,
  /// the returned list will be a type-data float list capable of containing
  /// all the elements of this list and of [other].
  /// Otherwise the returned list will be a normal growable `List<double>`.
  List<double> operator +(List<double> other);
}

/// Endianness of number representation.
///
/// The order of bytes in memory of a number representation, with
/// [little] endian having the least significant byte first, and [big] endian
/// (aka. network byte order) having the most significant byte first.
///
/// The [host] endian is the native endianness of the underlying platform,
/// and the default endianness used by typed-data lists, like [Uint16List],
/// on this platform. Always one of [little] or [big] endian.
///
/// Can be specified when accessing or updating a sequence of bytes using a
/// [ByteData] view. The host endianness can be used if accessing larger
/// numbers by their bytes, for example through a [Uint8List] view on
/// a buffer written using an [Int64List] view of the same buffer..
///
/// It is a compile-time error for a class to attempt to extend or implement
/// `Endian`.
final class Endian {
  final bool _littleEndian;
  const Endian._(this._littleEndian);

  static const Endian big = const Endian._(false);
  static const Endian little = const Endian._(true);
  static final Endian host =
      (new ByteData.view(new Uint16List.fromList([1]).buffer)).getInt8(0) == 1
          ? little
          : big;
}

/// A fixed-length, random-access sequence of bytes that also provides random
/// and unaligned access to the fixed-width integers and floating point
/// numbers represented by those bytes.
///
/// `ByteData` may be used to pack and unpack data from external sources
/// (such as networks or files systems), and to process large quantities
/// of numerical data more efficiently than would be possible
/// with ordinary [List] implementations.
/// `ByteData` can save space, by eliminating the need for object headers,
/// and time, by eliminating the need for data copies.
///
/// If data comes in as bytes, they can be converted to `ByteData` by
/// sharing the same buffer.
/// ```dart
/// Uint8List bytes = ...;
/// var blob = ByteData.sublistView(bytes);
/// if (blob.getUint32(0, Endian.little) == 0x04034b50) { // Zip file marker
///   ...
/// }
/// ```
///
/// Finally, `ByteData` may be used to intentionally reinterpret the bytes
/// representing one arithmetic type as another.
/// For example this code fragment determine what 32-bit signed integer
/// is represented by the bytes of a 32-bit floating point number
/// (both stored as big endian):
/// ```dart
/// var bdata = ByteData(8);
/// bdata.setFloat32(0, 3.04);
/// int huh = bdata.getInt32(0); // 0x40428f5c
/// ```
///
/// It is a compile-time error for a class to attempt to extend or implement
/// `ByteData`.
abstract final class ByteData implements TypedData {
  /// Creates a [ByteData] of the specified length (in elements), all of
  /// whose bytes are initially zero.
  @pragma("vm:entry-point")
  external factory ByteData(int length);

  /// Creates an [ByteData] _view_ of the specified region in [buffer].
  ///
  /// Changes in the [ByteData] will be visible in the byte
  /// buffer and vice versa.
  /// If the [offsetInBytes] index of the region is not specified,
  /// it defaults to zero (the first byte in the byte buffer).
  /// If the length is not provided,
  /// the view extends to the end of the byte buffer.
  ///
  /// The [offsetInBytes] and [length] must be non-negative, and
  /// [offsetInBytes] + [length] must be less than or
  /// equal to the length of [buffer].
  ///
  /// Note that when creating a view from a [TypedData] list or byte data,
  /// that list or byte data may itself be a view on a larger buffer
  /// with a [TypedData.offsetInBytes] greater than zero.
  /// Merely doing `ByteData.view(other.buffer, 0, count)` may not
  /// point to the bytes you intended. Instead you may need to do:
  /// ```dart
  /// ByteData.view(other.buffer, other.offsetInBytes, count)
  /// ```
  /// Alternatively, use [ByteData.sublistView]
  /// which includes this computation:
  /// ```dart
  /// ByteData.sublistView(other, 0, count);
  /// ```
  /// (The third argument is an end index rather than a length, so if
  /// you start from a position greater than zero, you need not
  /// reduce the count correspondingly).
  factory ByteData.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int? length]) {
    return buffer.asByteData(offsetInBytes, length);
  }

  /// Creates a [ByteData] view on a range of elements of [data].
  ///
  /// Creates a view on the range of `data.buffer` which corresponds
  /// to the elements of [data] from [start] until [end].
  /// If [data] is a typed data list, like [Uint16List], then the view is on
  /// the bytes of the elements with indices from [start] until [end].
  /// If [data] is a [ByteData], it's treated like a list of bytes.
  ///
  /// If provided, [start] and [end] must satisfy
  ///
  /// 0 &le; `start` &le; `end` &le; *elementCount*
  ///
  /// where *elementCount* is the number of elements in [data], which
  /// is the same as the [List.length] of a typed data list.
  ///
  /// If omitted, [start] defaults to zero and [end] to *elementCount*.
  @Since("2.8")
  factory ByteData.sublistView(TypedData data, [int start = 0, int? end]) {
    int elementSize = data.elementSizeInBytes;
    end = RangeError.checkValidRange(
        start, end, data.lengthInBytes ~/ elementSize);
    return data.buffer.asByteData(
        data.offsetInBytes + start * elementSize, (end - start) * elementSize);
  }

  /// A read-only view of this [ByteData].
  @Since("3.3")
  ByteData asUnmodifiableView();

  /// The (possibly negative) integer represented by the byte at the
  /// specified [byteOffset] in this object, in two's complement binary
  /// representation.
  ///
  /// The return value will be between -128 and 127, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// less than the length of this object.
  int getInt8(int byteOffset);

  /// Sets the byte at the specified [byteOffset] in this object to the
  /// two's complement binary representation of the specified [value], which
  /// must fit in a single byte.
  ///
  /// In other words, [value] must be between -128 and 127, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// less than the length of this object.
  void setInt8(int byteOffset, int value);

  /// The positive integer represented by the byte at the specified
  /// [byteOffset] in this object, in unsigned binary form.
  ///
  /// The return value will be between 0 and 255, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// less than the length of this object.
  int getUint8(int byteOffset);

  /// Sets the byte at the specified [byteOffset] in this object to the
  /// unsigned binary representation of the specified [value], which must fit
  /// in a single byte.
  ///
  /// In other words, [value] must be between 0 and 255, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// less than the length of this object.
  void setUint8(int byteOffset, int value);

  /// The (possibly negative) integer represented by the two bytes at
  /// the specified [byteOffset] in this object, in two's complement binary
  /// form.
  ///
  /// The return value will be between -2<sup>15</sup> and 2<sup>15</sup> - 1,
  /// inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 2` must be less than or equal to the length of this object.
  int getInt16(int byteOffset, [Endian endian = Endian.big]);

  /// Sets the two bytes starting at the specified [byteOffset] in this
  /// object to the two's complement binary representation of the specified
  /// [value], which must fit in two bytes.
  ///
  /// In other words, [value] must lie
  /// between -2<sup>15</sup> and 2<sup>15</sup> - 1, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 2` must be less than or equal to the length of this object.
  void setInt16(int byteOffset, int value, [Endian endian = Endian.big]);

  /// The positive integer represented by the two bytes starting
  /// at the specified [byteOffset] in this object, in unsigned binary
  /// form.
  ///
  /// The return value will be between 0 and  2<sup>16</sup> - 1, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 2` must be less than or equal to the length of this object.
  int getUint16(int byteOffset, [Endian endian = Endian.big]);

  /// Sets the two bytes starting at the specified [byteOffset] in this object
  /// to the unsigned binary representation of the specified [value],
  /// which must fit in two bytes.
  ///
  /// In other words, [value] must be between
  /// 0 and 2<sup>16</sup> - 1, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 2` must be less than or equal to the length of this object.
  void setUint16(int byteOffset, int value, [Endian endian = Endian.big]);

  /// The (possibly negative) integer represented by the four bytes at
  /// the specified [byteOffset] in this object, in two's complement binary
  /// form.
  ///
  /// The return value will be between -2<sup>31</sup> and 2<sup>31</sup> - 1,
  /// inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 4` must be less than or equal to the length of this object.
  int getInt32(int byteOffset, [Endian endian = Endian.big]);

  /// Sets the four bytes starting at the specified [byteOffset] in this
  /// object to the two's complement binary representation of the specified
  /// [value], which must fit in four bytes.
  ///
  /// In other words, [value] must lie
  /// between -2<sup>31</sup> and 2<sup>31</sup> - 1, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 4` must be less than or equal to the length of this object.
  void setInt32(int byteOffset, int value, [Endian endian = Endian.big]);

  /// The positive integer represented by the four bytes starting
  /// at the specified [byteOffset] in this object, in unsigned binary
  /// form.
  ///
  /// The return value will be between 0 and  2<sup>32</sup> - 1, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 4` must be less than or equal to the length of this object.
  int getUint32(int byteOffset, [Endian endian = Endian.big]);

  /// Sets the four bytes starting at the specified [byteOffset] in this object
  /// to the unsigned binary representation of the specified [value],
  /// which must fit in four bytes.
  ///
  /// In other words, [value] must be between
  /// 0 and 2<sup>32</sup> - 1, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 4` must be less than or equal to the length of this object.
  void setUint32(int byteOffset, int value, [Endian endian = Endian.big]);

  /// The (possibly negative) integer represented by the eight bytes at
  /// the specified [byteOffset] in this object, in two's complement binary
  /// form.
  ///
  /// The return value will be between -2<sup>63</sup> and 2<sup>63</sup> - 1,
  /// inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 8` must be less than or equal to the length of this object.
  int getInt64(int byteOffset, [Endian endian = Endian.big]);

  /// Sets the eight bytes starting at the specified [byteOffset] in this
  /// object to the two's complement binary representation of the specified
  /// [value], which must fit in eight bytes.
  ///
  /// In other words, [value] must lie
  /// between -2<sup>63</sup> and 2<sup>63</sup> - 1, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 8` must be less than or equal to the length of this object.
  void setInt64(int byteOffset, int value, [Endian endian = Endian.big]);

  /// The positive integer represented by the eight bytes starting
  /// at the specified [byteOffset] in this object, in unsigned binary
  /// form.
  ///
  /// The return value will be between 0 and  2<sup>64</sup> - 1, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 8` must be less than or equal to the length of this object.
  int getUint64(int byteOffset, [Endian endian = Endian.big]);

  /// Sets the eight bytes starting at the specified [byteOffset] in this object
  /// to the unsigned binary representation of the specified [value],
  /// which must fit in eight bytes.
  ///
  /// In other words, [value] must be between
  /// 0 and 2<sup>64</sup> - 1, inclusive.
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 8` must be less than or equal to the length of this object.
  void setUint64(int byteOffset, int value, [Endian endian = Endian.big]);

  /// The floating point number represented by the four bytes at
  /// the specified [byteOffset] in this object, in IEEE 754
  /// single-precision binary floating-point format (binary32).
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 4` must be less than or equal to the length of this object.
  double getFloat32(int byteOffset, [Endian endian = Endian.big]);

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
  void setFloat32(int byteOffset, double value, [Endian endian = Endian.big]);

  /// The floating point number represented by the eight bytes at
  /// the specified [byteOffset] in this object, in IEEE 754
  /// double-precision binary floating-point format (binary64).
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 8` must be less than or equal to the length of this object.
  double getFloat64(int byteOffset, [Endian endian = Endian.big]);

  /// Sets the eight bytes starting at the specified [byteOffset] in this
  /// object to the IEEE 754 double-precision binary floating-point
  /// (binary64) representation of the specified [value].
  ///
  /// The [byteOffset] must be non-negative, and
  /// `byteOffset + 8` must be less than or equal to the length of this object.
  void setFloat64(int byteOffset, double value, [Endian endian = Endian.big]);
}

/// A fixed-length list of 8-bit signed integers.
///
/// For long lists, this implementation can be considerably
/// more space- and time-efficient than the default [List] implementation.
///
/// Integers stored in the list are truncated to their low eight bits,
/// interpreted as a signed 8-bit two's complement integer with values in the
/// range -128 to +127.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// `Int8List`.
abstract final class Int8List implements _TypedIntList {
  /// Creates an [Int8List] of the specified length (in elements), all of
  /// whose elements are initially zero.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely [length] bytes.
  external factory Int8List(int length);

  /// Creates a [Int8List] with the same length as the [elements] list
  /// and copies over the elements.
  ///
  /// Values are truncated to fit in the list when they are copied,
  /// the same way storing values truncates them.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely `elements.length`
  /// bytes.
  external factory Int8List.fromList(List<int> elements);

  /// Creates an [Int8List] _view_ of the specified region in [buffer].
  ///
  /// Changes in the [Int8List] will be visible in the byte
  /// buffer and vice versa.
  /// If the [offsetInBytes] index of the region is not specified,
  /// it defaults to zero (the first byte in the byte buffer).
  /// If the length is not provided,
  /// the view extends to the end of the byte buffer.
  ///
  /// The [offsetInBytes] and [length] must be non-negative, and
  /// [offsetInBytes] + ([length] * [bytesPerElement]) must be less than or
  /// equal to the length of [buffer].
  ///
  /// Note that when creating a view from a [TypedData] list or byte data,
  /// that list or byte data may itself be a view on a larger buffer
  /// with a [TypedData.offsetInBytes] greater than zero.
  /// Merely doing `Int8List.view(other.buffer, 0, count)` may not
  /// point to the bytes you intended. Instead you may need to do:
  /// ```dart
  /// Int8List.view(other.buffer, other.offsetInBytes, count)
  /// ```
  /// Alternatively, use [Int8List.sublistView]
  /// which includes this computation:
  /// ```dart
  /// Int8List.sublistView(other, 0, count);
  /// ```
  /// (The third argument is an end index rather than a length, so if
  /// you start from a position greater than zero, you need not
  /// reduce the count correspondingly).
  factory Int8List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int? length]) {
    return buffer.asInt8List(offsetInBytes, length);
  }

  /// Creates an [Int8List] view on a range of elements of [data].
  ///
  /// Creates a view on the range of `data.buffer` which corresponds
  /// to the elements of [data] from [start] until [end].
  /// If [data] is a typed data list, like [Uint16List], then the view is on
  /// the bytes of the elements with indices from [start] until [end].
  /// If [data] is a [ByteData], it's treated like a list of bytes.
  ///
  /// If provided, [start] and [end] must satisfy
  ///
  /// 0 &le; `start` &le; `end` &le; *elementCount*
  ///
  /// where *elementCount* is the number of elements in [data], which
  /// is the same as the [List.length] of a typed data list.
  ///
  /// If omitted, [start] defaults to zero and [end] to *elementCount*.
  @Since("2.8")
  factory Int8List.sublistView(TypedData data, [int start = 0, int? end]) {
    int elementSize = data.elementSizeInBytes;
    end = RangeError.checkValidRange(
        start, end, data.lengthInBytes ~/ elementSize);
    return data.buffer.asInt8List(
        data.offsetInBytes + start * elementSize, (end - start) * elementSize);
  }

  /// A read-only view of this [Int8List];
  @Since("3.3")
  Int8List asUnmodifiableView();

  /// Creates a new list containing the elements between [start] and [end].
  ///
  /// The new list is an `Int8List` containing the elements of this list at
  /// positions greater than or equal to [start] and less than [end] in the same
  /// order as they occur in this list.
  ///
  /// ```dart
  /// var numbers = Int8List.fromList([0, 1, 2, 3, 4]);
  /// print(numbers.sublist(1, 3)); // [1, 2]
  /// print(numbers.sublist(1, 3).runtimeType); // Int8List
  /// ```
  ///
  /// If [end] is omitted, it defaults to the [length] of this list.
  ///
  /// ```dart
  /// print(numbers.sublist(1)); // [1, 2, 3, 4]
  /// ```
  ///
  /// The `start` and `end` positions must satisfy the relations
  /// 0 ≤ `start` ≤ `end` ≤ `this.length`.
  /// If `end` is equal to `start`, then the returned list is empty.
  Int8List sublist(int start, [int? end]);

  static const int bytesPerElement = 1;
}

/// A fixed-length list of 8-bit unsigned integers.
///
/// For long lists, this implementation can be considerably
/// more space- and time-efficient than the default [List] implementation.
///
/// Integers stored in the list are truncated to their low eight bits,
/// interpreted as an unsigned 8-bit integer with values in the
/// range 0 to 255.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// `Uint8List`.
abstract final class Uint8List implements _TypedIntList {
  /// Creates a [Uint8List] of the specified length (in elements), all of
  /// whose elements are initially zero.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely [length] bytes.
  external factory Uint8List(int length);

  /// Creates a [Uint8List] with the same length as the [elements] list
  /// and copies over the elements.
  ///
  /// Values are truncated to fit in the list when they are copied,
  /// the same way storing values truncates them.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely `elements.length`
  /// bytes.
  external factory Uint8List.fromList(List<int> elements);

  /// Creates a [Uint8List] _view_ of the specified region in [buffer].
  ///
  /// Changes in the [Uint8List] will be visible in the byte
  /// buffer and vice versa.
  /// If the [offsetInBytes] index of the region is not specified,
  /// it defaults to zero (the first byte in the byte buffer).
  /// If the length is not provided,
  /// the view extends to the end of the byte buffer.
  ///
  /// The [offsetInBytes] and [length] must be non-negative, and
  /// [offsetInBytes] + ([length] * [bytesPerElement]) must be less than or
  /// equal to the length of [buffer].
  ///
  /// Note that when creating a view from a [TypedData] list or byte data,
  /// that list or byte data may itself be a view on a larger buffer
  /// with a [TypedData.offsetInBytes] greater than zero.
  /// Merely doing `Uint8List.view(other.buffer, 0, count)` may not
  /// point to the bytes you intended. Instead you may need to do:
  /// ```dart
  /// Uint8List.view(other.buffer, other.offsetInBytes, count)
  /// ```
  /// Alternatively, use [Uint8List.sublistView]
  /// which includes this computation:
  /// ```dart
  /// Uint8List.sublistView(other, 0, count);
  /// ```
  /// (The third argument is an end index rather than a length, so if
  /// you start from a position greater than zero, you need not
  /// reduce the count correspondingly).
  factory Uint8List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int? length]) {
    return buffer.asUint8List(offsetInBytes, length);
  }

  /// Creates a [Uint8List] view on a range of elements of [data].
  ///
  /// Creates a view on the range of `data.buffer` which corresponds
  /// to the elements of [data] from [start] until [end].
  /// If [data] is a typed data list, like [Uint16List], then the view is on
  /// the bytes of the elements with indices from [start] until [end].
  /// If [data] is a [ByteData], it's treated like a list of bytes.
  ///
  /// If provided, [start] and [end] must satisfy
  ///
  /// 0 &le; `start` &le; `end` &le; *elementCount*
  ///
  /// where *elementCount* is the number of elements in [data], which
  /// is the same as the [List.length] of a typed data list.
  ///
  /// If omitted, [start] defaults to zero and [end] to *elementCount*.
  @Since("2.8")
  factory Uint8List.sublistView(TypedData data, [int start = 0, int? end]) {
    int elementSize = data.elementSizeInBytes;
    end = RangeError.checkValidRange(
        start, end, data.lengthInBytes ~/ elementSize);
    return data.buffer.asUint8List(
        data.offsetInBytes + start * elementSize, (end - start) * elementSize);
  }

  /// A read-only view of this [Uint8List].
  @Since("3.3")
  Uint8List asUnmodifiableView();

  /// Returns a concatenation of this list and [other].
  ///
  /// If [other] is also a typed-data list, then the return list will be a
  /// typed data list capable of holding both unsigned 8-bit integers and
  /// the elements of [other], otherwise it'll be a normal list of integers.
  List<int> operator +(List<int> other);

  /// Creates a new list containing the elements between [start] and [end].
  ///
  /// The new list is a `Uint8List` containing the elements of this list at
  /// positions greater than or equal to [start] and less than [end] in the same
  /// order as they occur in this list.
  ///
  /// ```dart
  /// var numbers = Uint8List.fromList([0, 1, 2, 3, 4]);
  /// print(numbers.sublist(1, 3)); // [1, 2]
  /// print(numbers.sublist(1, 3).runtimeType); // Uint8List
  /// ```
  ///
  /// If [end] is omitted, it defaults to the [length] of this list.
  ///
  /// ```dart
  /// print(numbers.sublist(1)); // [1, 2, 3, 4]
  /// ```
  ///
  /// The `start` and `end` positions must satisfy the relations
  /// 0 ≤ `start` ≤ `end` ≤ `this.length`.
  /// If `end` is equal to `start`, then the returned list is empty.
  Uint8List sublist(int start, [int? end]);

  static const int bytesPerElement = 1;
}

/// A fixed-length list of 8-bit unsigned integers.
///
/// For long lists, this implementation can be considerably
/// more space- and time-efficient than the default [List] implementation.
///
/// Integers stored in the list are clamped to an unsigned eight bit value.
/// That is, all values below zero are stored as zero
/// and all values above 255 are stored as 255.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// `Uint8ClampedList`.
abstract final class Uint8ClampedList implements _TypedIntList {
  /// Creates a [Uint8ClampedList] of the specified length (in elements), all of
  /// whose elements are initially zero.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely [length] bytes.
  external factory Uint8ClampedList(int length);

  /// Creates a [Uint8ClampedList] of the same size as the [elements]
  /// list and copies over the values clamping when needed.
  ///
  /// Values are clamped to fit in the list when they are copied,
  /// the same way storing values clamps them.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely `elements.length`
  /// bytes.
  external factory Uint8ClampedList.fromList(List<int> elements);

  /// Creates a [Uint8ClampedList] _view_ of the specified region in the
  /// specified byte [buffer].
  ///
  /// Changes in the [Uint8List] will be visible in the byte buffer
  /// and vice versa.
  /// If the [offsetInBytes] index of the region is not specified,
  /// it defaults to zero (the first byte in the byte buffer).
  /// If the length is not provided,
  /// the view extends to the end of the byte buffer.
  ///
  /// The [offsetInBytes] and [length] must be non-negative, and
  /// [offsetInBytes] + ([length] * [bytesPerElement]) must be less than or
  /// equal to the length of [buffer].
  ///
  /// Note that when creating a view from a [TypedData] list or byte data,
  /// that list or byte data may itself be a view on a larger buffer
  /// with a [TypedData.offsetInBytes] greater than zero.
  /// Merely doing `Uint8ClampedList.view(other.buffer, 0, count)` may not
  /// point to the bytes you intended. Instead you may need to do:
  /// ```dart
  /// Uint8ClampedList.view(other.buffer, other.offsetInBytes, count)
  /// ```
  /// Alternatively, use [Uint8ClampedList.sublistView]
  /// which includes this computation:
  /// ```dart
  /// Uint8ClampedList.sublistView(other, 0, count);
  /// ```
  /// (The third argument is an end index rather than a length, so if
  /// you start from a position greater than zero, you need not
  /// reduce the count correspondingly).
  factory Uint8ClampedList.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int? length]) {
    return buffer.asUint8ClampedList(offsetInBytes, length);
  }

  /// Creates a [Uint8ClampedList] view on a range of elements of [data].
  ///
  /// Creates a view on the range of `data.buffer` which corresponds
  /// to the elements of [data] from [start] until [end].
  /// If [data] is a typed data list, like [Uint16List], then the view is on
  /// the bytes of the elements with indices from [start] until [end].
  /// If [data] is a [ByteData], it's treated like a list of bytes.
  ///
  /// If provided, [start] and [end] must satisfy
  ///
  /// 0 &le; `start` &le; `end` &le; *elementCount*
  ///
  /// where *elementCount* is the number of elements in [data], which
  /// is the same as the [List.length] of a typed data list.
  ///
  /// If omitted, [start] defaults to zero and [end] to *elementCount*.
  @Since("3.3")
  factory Uint8ClampedList.sublistView(TypedData data,
      [int start = 0, int? end]) {
    int elementSize = data.elementSizeInBytes;
    end = RangeError.checkValidRange(
        start, end, data.lengthInBytes ~/ elementSize);
    return data.buffer.asUint8ClampedList(
        data.offsetInBytes + start * elementSize, (end - start) * elementSize);
  }

  /// A read-only view of this [Uint8ClampedList].
  @Since("3.3")
  Uint8ClampedList asUnmodifiableView();

  /// Creates a new list containing the elements between [start] and [end].
  ///
  /// The new list is a `Uint8ClampedList` containing the elements of this
  /// list at positions greater than or equal to [start] and less than [end] in
  /// the same order as they occur in this list.
  ///
  /// ```dart
  /// var numbers = Uint8ClampedList.fromList([0, 1, 2, 3, 4]);
  /// print(numbers.sublist(1, 3)); // [1, 2]
  /// print(numbers.sublist(1, 3).runtimeType); // Uint8ClampedList
  /// ```
  ///
  /// If [end] is omitted, it defaults to the [length] of this list.
  ///
  /// ```dart
  /// print(numbers.sublist(1)); // [1, 2, 3, 4]
  /// ```
  ///
  /// The `start` and `end` positions must satisfy the relations
  /// 0 ≤ `start` ≤ `end` ≤ `this.length`.
  /// If `end` is equal to `start`, then the returned list is empty.
  Uint8ClampedList sublist(int start, [int? end]);

  static const int bytesPerElement = 1;
}

/// A fixed-length list of 16-bit signed integers that is viewable as a
/// [TypedData].
///
/// For long lists, this implementation can be considerably
/// more space- and time-efficient than the default [List] implementation.
///
/// Integers stored in the list are truncated to their low 16 bits,
/// interpreted as a signed 16-bit two's complement integer with values in the
/// range -32768 to +32767.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// `Int16List`.
abstract final class Int16List implements _TypedIntList {
  /// Creates an [Int16List] of the specified length (in elements), all of
  /// whose elements are initially zero.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely
  /// [length] times 2 bytes.
  external factory Int16List(int length);

  /// Creates a [Int16List] with the same length as the [elements] list
  /// and copies over the elements.
  ///
  /// Values are truncated to fit in the list when they are copied,
  /// the same way storing values truncates them.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely
  /// `elements.length` times 2 bytes.
  external factory Int16List.fromList(List<int> elements);

  /// Creates an [Int16List] _view_ of the specified region in [buffer].
  ///
  /// Changes in the [Int16List] will be visible in the byte
  /// buffer and vice versa.
  /// If the [offsetInBytes] index of the region is not specified,
  /// it defaults to zero (the first byte in the byte buffer).
  /// If the length is not provided,
  /// the view extends to the end of the byte buffer.
  ///
  /// The [offsetInBytes] and [length] must be non-negative, and
  /// [offsetInBytes] + ([length] * [bytesPerElement]) must be less than or
  /// equal to the length of [buffer].
  ///
  /// The [offsetInBytes] must be a multiple of [bytesPerElement].
  ///
  /// Note that when creating a view from a [TypedData] list or byte data,
  /// that list or byte data may itself be a view on a larger buffer
  /// with a [TypedData.offsetInBytes] greater than zero.
  /// Merely doing `Int16List.view(other.buffer, 0, count)` may not
  /// point to the bytes you intended. Instead you may need to do:
  /// ```dart
  /// Int16List.view(other.buffer, other.offsetInBytes, count)
  /// ```
  /// Alternatively, use [Int16List.sublistView]
  /// which includes this computation:
  /// ```dart
  /// Int16List.sublistView(other, 0, count);
  /// ```
  /// (The third argument is an end index rather than a length, so if
  /// you start from a position greater than zero, you need not
  /// reduce the count correspondingly).
  factory Int16List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int? length]) {
    return buffer.asInt16List(offsetInBytes, length);
  }

  /// Creates an [Int16List] view on a range of elements of [data].
  ///
  /// Creates a view on the range of `data.buffer` which corresponds
  /// to the elements of [data] from [start] until [end].
  /// If [data] is a typed data list, like [Uint16List], then the view is on
  /// the bytes of the elements with indices from [start] until [end].
  /// If [data] is a [ByteData], it's treated like a list of bytes.
  ///
  /// If provided, [start] and [end] must satisfy
  ///
  /// 0 &le; `start` &le; `end` &le; *elementCount*
  ///
  /// where *elementCount* is the number of elements in [data], which
  /// is the same as the [List.length] of a typed data list.
  ///
  /// If omitted, [start] defaults to zero and [end] to *elementCount*.
  ///
  /// The start and end indices of the range of bytes being viewed must be
  /// multiples of two.
  @Since("2.8")
  factory Int16List.sublistView(TypedData data, [int start = 0, int? end]) {
    int elementSize = data.elementSizeInBytes;
    end = RangeError.checkValidRange(
        start, end, data.lengthInBytes ~/ elementSize);
    int byteLength = (end - start) * elementSize;
    if (byteLength % bytesPerElement != 0) {
      throw ArgumentError("The number of bytes to view must be a multiple of " +
          "$bytesPerElement");
    }
    return data.buffer.asInt16List(data.offsetInBytes + start * elementSize,
        byteLength ~/ bytesPerElement);
  }

  /// A read-only view of this [Int16List].
  @Since("3.3")
  Int16List asUnmodifiableView();

  /// Creates a new list containing the elements between [start] and [end].
  ///
  /// The new list is an `Int16List` containing the elements of this
  /// list at positions greater than or equal to [start] and less than [end] in
  /// the same order as they occur in this list.
  ///
  /// ```dart
  /// var numbers = Int16List.fromList([0, 1, 2, 3, 4]);
  /// print(numbers.sublist(1, 3)); // [1, 2]
  /// print(numbers.sublist(1, 3).runtimeType); // Int16List
  /// ```
  ///
  /// If [end] is omitted, it defaults to the [length] of this list.
  ///
  /// ```dart
  /// print(numbers.sublist(1)); // [1, 2, 3, 4]
  /// ```
  ///
  /// The `start` and `end` positions must satisfy the relations
  /// 0 ≤ `start` ≤ `end` ≤ `this.length`.
  /// If `end` is equal to `start`, then the returned list is empty.
  Int16List sublist(int start, [int? end]);

  static const int bytesPerElement = 2;
}

/// A fixed-length list of 16-bit unsigned integers that is viewable as a
/// [TypedData].
///
/// For long lists, this implementation can be considerably
/// more space- and time-efficient than the default [List] implementation.
///
/// Integers stored in the list are truncated to their low 16 bits,
/// interpreted as an unsigned 16-bit integer with values in the
/// range 0 to 65535.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// `Uint16List`.
abstract final class Uint16List implements _TypedIntList {
  /// Creates a [Uint16List] of the specified length (in elements), all
  /// of whose elements are initially zero.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely
  /// [length] times 2 bytes.
  external factory Uint16List(int length);

  /// Creates a [Uint16List] with the same length as the [elements] list
  /// and copies over the elements.
  ///
  /// Values are truncated to fit in the list when they are copied,
  /// the same way storing values truncates them.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely
  /// `elements.length` times 2 bytes.
  external factory Uint16List.fromList(List<int> elements);

  /// Creates a [Uint16List] _view_ of the specified region in
  /// the specified byte buffer.
  ///
  /// Changes in the [Uint16List] will be visible in the byte buffer
  /// and vice versa.
  /// If the [offsetInBytes] index of the region is not specified,
  /// it defaults to zero (the first byte in the byte buffer).
  /// If the length is not provided,
  /// the view extends to the end of the byte buffer.
  ///
  /// The [offsetInBytes] and [length] must be non-negative, and
  /// [offsetInBytes] + ([length] * [bytesPerElement]) must be less than or
  /// equal to the length of [buffer].
  ///
  /// The [offsetInBytes] must be a multiple of [bytesPerElement].
  ///
  /// Note that when creating a view from a [TypedData] list or byte data,
  /// that list or byte data may itself be a view on a larger buffer
  /// with a [TypedData.offsetInBytes] greater than zero.
  /// Merely doing `Uint16List.view(other.buffer, 0, count)` may not
  /// point to the bytes you intended. Instead you may need to do:
  /// ```dart
  /// Uint16List.view(other.buffer, other.offsetInBytes, count)
  /// ```
  /// Alternatively, use [Uint16List.sublistView]
  /// which includes this computation:
  /// ```dart
  /// Uint16List.sublistView(other, 0, count);
  /// ```
  /// (The third argument is an end index rather than a length, so if
  /// you start from a position greater than zero, you need not
  /// reduce the count correspondingly).
  factory Uint16List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int? length]) {
    return buffer.asUint16List(offsetInBytes, length);
  }

  /// Creates a [Uint16List] view on a range of elements of [data].
  ///
  /// Creates a view on the range of `data.buffer` which corresponds
  /// to the elements of [data] from [start] until [end].
  /// If [data] is a typed data list, like [Uint16List], then the view is on
  /// the bytes of the elements with indices from [start] until [end].
  /// If [data] is a [ByteData], it's treated like a list of bytes.
  ///
  /// If provided, [start] and [end] must satisfy
  ///
  /// 0 &le; `start` &le; `end` &le; *elementCount*
  ///
  /// where *elementCount* is the number of elements in [data], which
  /// is the same as the [List.length] of a typed data list.
  ///
  /// If omitted, [start] defaults to zero and [end] to *elementCount*.
  ///
  /// The start and end indices of the range of bytes being viewed must be
  /// multiples of two.
  @Since("2.8")
  factory Uint16List.sublistView(TypedData data, [int start = 0, int? end]) {
    int elementSize = data.elementSizeInBytes;
    end = RangeError.checkValidRange(
        start, end, data.lengthInBytes ~/ elementSize);
    int byteLength = (end - start) * elementSize;
    if (byteLength % bytesPerElement != 0) {
      throw ArgumentError("The number of bytes to view must be a multiple of " +
          "$bytesPerElement");
    }
    return data.buffer.asUint16List(data.offsetInBytes + start * elementSize,
        byteLength ~/ bytesPerElement);
  }

  /// A read-only view of this [Uint16List].
  @Since("3.3")
  Uint16List asUnmodifiableView();

  /// Creates a new list containing the elements between [start] and [end].
  ///
  /// The new list is a `Uint16List` containing the elements of this
  /// list at positions greater than or equal to [start] and less than [end] in
  /// the same order as they occur in this list.
  ///
  /// ```dart
  /// var numbers = Uint16List.fromList([0, 1, 2, 3, 4]);
  /// print(numbers.sublist(1, 3)); // [1, 2]
  /// print(numbers.sublist(1, 3).runtimeType); // Uint16List
  /// ```
  ///
  /// If [end] is omitted, it defaults to the [length] of this list.
  ///
  /// ```dart
  /// print(numbers.sublist(1)); // [1, 2, 3, 4]
  /// ```
  ///
  /// The `start` and `end` positions must satisfy the relations
  /// 0 ≤ `start` ≤ `end` ≤ `this.length`.
  /// If `end` is equal to `start`, then the returned list is empty.
  Uint16List sublist(int start, [int? end]);

  static const int bytesPerElement = 2;
}

/// A fixed-length list of 32-bit signed integers that is viewable as a
/// [TypedData].
///
/// For long lists, this implementation can be considerably
/// more space- and time-efficient than the default [List] implementation.
///
/// Integers stored in the list are truncated to their low 32 bits,
/// interpreted as a signed 32-bit two's complement integer with values in the
/// range -2147483648 to 2147483647.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// `Int32List`.
abstract final class Int32List implements _TypedIntList {
  /// Creates an [Int32List] of the specified length (in elements), all of
  /// whose elements are initially zero.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely
  /// [length] times 4 bytes.
  external factory Int32List(int length);

  /// Creates a [Int32List] with the same length as the [elements] list
  /// and copies over the elements.
  ///
  /// Values are truncated to fit in the list when they are copied,
  /// the same way storing values truncates them.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely
  /// `elements.length` times 4 bytes.
  external factory Int32List.fromList(List<int> elements);

  /// Creates an [Int32List] _view_ of the specified region in [buffer].
  ///
  /// Changes in the [Int32List] will be visible in the byte
  /// buffer and vice versa.
  /// If the [offsetInBytes] index of the region is not specified,
  /// it defaults to zero (the first byte in the byte buffer).
  /// If the length is not provided,
  /// the view extends to the end of the byte buffer.
  ///
  /// The [offsetInBytes] and [length] must be non-negative, and
  /// [offsetInBytes] + ([length] * [bytesPerElement]) must be less than or
  /// equal to the length of [buffer].
  ///
  /// The [offsetInBytes] must be a multiple of [bytesPerElement].
  ///
  /// Note that when creating a view from a [TypedData] list or byte data,
  /// that list or byte data may itself be a view on a larger buffer
  /// with a [TypedData.offsetInBytes] greater than zero.
  /// Merely doing `Int32List.view(other.buffer, 0, count)` may not
  /// point to the bytes you intended. Instead you may need to do:
  /// ```dart
  /// Int32List.view(other.buffer, other.offsetInBytes, count)
  /// ```
  /// Alternatively, use [Int32List.sublistView]
  /// which includes this computation:
  /// ```dart
  /// Int32List.sublistView(other, 0, count);
  /// ```
  /// (The third argument is an end index rather than a length, so if
  /// you start from a position greater than zero, you need not
  /// reduce the count correspondingly).
  factory Int32List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int? length]) {
    return buffer.asInt32List(offsetInBytes, length);
  }

  /// Creates an [Int32List] view on a range of elements of [data].
  ///
  /// Creates a view on the range of `data.buffer` which corresponds
  /// to the elements of [data] from [start] until [end].
  /// If [data] is a typed data list, like [Uint16List], then the view is on
  /// the bytes of the elements with indices from [start] until [end].
  /// If [data] is a [ByteData], it's treated like a list of bytes.
  ///
  /// If provided, [start] and [end] must satisfy
  ///
  /// 0 &le; `start` &le; `end` &le; *elementCount*
  ///
  /// where *elementCount* is the number of elements in [data], which
  /// is the same as the [List.length] of a typed data list.
  ///
  /// If omitted, [start] defaults to zero and [end] to *elementCount*.
  ///
  /// The start and end indices of the range of bytes being viewed must be
  /// multiples of four.
  @Since("2.8")
  factory Int32List.sublistView(TypedData data, [int start = 0, int? end]) {
    int elementSize = data.elementSizeInBytes;
    end = RangeError.checkValidRange(
        start, end, data.lengthInBytes ~/ elementSize);
    int byteLength = (end - start) * elementSize;
    if (byteLength % bytesPerElement != 0) {
      throw ArgumentError("The number of bytes to view must be a multiple of " +
          "$bytesPerElement");
    }
    return data.buffer.asInt32List(data.offsetInBytes + start * elementSize,
        byteLength ~/ bytesPerElement);
  }

  /// A read-only view of this [Int16List].
  @Since("3.3")
  Int32List asUnmodifiableView();

  /// Creates a new list containing the elements between [start] and [end].
  ///
  /// The new list is an `Int32List` containing the elements of this
  /// list at positions greater than or equal to [start] and less than [end] in
  /// the same order as they occur in this list.
  ///
  /// ```dart
  /// var numbers = Int32List.fromList([0, 1, 2, 3, 4]);
  /// print(numbers.sublist(1, 3)); // [1, 2]
  /// print(numbers.sublist(1, 3).runtimeType); // Int32List
  /// ```
  ///
  /// If [end] is omitted, it defaults to the [length] of this list.
  ///
  /// ```dart
  /// print(numbers.sublist(1)); // [1, 2, 3, 4]
  /// ```
  ///
  /// The `start` and `end` positions must satisfy the relations
  /// 0 ≤ `start` ≤ `end` ≤ `this.length`.
  /// If `end` is equal to `start`, then the returned list is empty.
  Int32List sublist(int start, [int? end]);

  static const int bytesPerElement = 4;
}

/// A fixed-length list of 32-bit unsigned integers that is viewable as a
/// [TypedData].
///
/// For long lists, this implementation can be considerably
/// more space- and time-efficient than the default [List] implementation.
///
/// Integers stored in the list are truncated to their low 32 bits,
/// interpreted as an unsigned 32-bit integer with values in the
/// range 0 to 4294967295.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// `Uint32List`.
abstract final class Uint32List implements _TypedIntList {
  /// Creates a [Uint32List] of the specified length (in elements), all
  /// of whose elements are initially zero.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely
  /// [length] times 4 bytes.
  external factory Uint32List(int length);

  /// Creates a [Uint32List] with the same length as the [elements] list
  /// and copies over the elements.
  ///
  /// Values are truncated to fit in the list when they are copied,
  /// the same way storing values truncates them.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely
  /// `elements.length` times 4 bytes.
  external factory Uint32List.fromList(List<int> elements);

  /// Creates a [Uint32List] _view_ of the specified region in
  /// the specified byte buffer.
  ///
  /// Changes in the [Uint32List] will be visible in the byte buffer
  /// and vice versa.
  /// If the [offsetInBytes] index of the region is not specified,
  /// it defaults to zero (the first byte in the byte buffer).
  /// If the length is not provided,
  /// the view extends to the end of the byte buffer.
  ///
  /// The [offsetInBytes] and [length] must be non-negative, and
  /// [offsetInBytes] + ([length] * [bytesPerElement]) must be less than or
  /// equal to the length of [buffer].
  ///
  /// The [offsetInBytes] must be a multiple of [bytesPerElement].
  ///
  /// Note that when creating a view from a [TypedData] list or byte data,
  /// that list or byte data may itself be a view on a larger buffer
  /// with a [TypedData.offsetInBytes] greater than zero.
  /// Merely doing `Uint32List.view(other.buffer, 0, count)` may not
  /// point to the bytes you intended. Instead you may need to do:
  /// ```dart
  /// Uint32List.view(other.buffer, other.offsetInBytes, count)
  /// ```
  /// Alternatively, use [Uint32List.sublistView]
  /// which includes this computation:
  /// ```dart
  /// Uint32List.sublistView(other, 0, count);
  /// ```
  /// (The third argument is an end index rather than a length, so if
  /// you start from a position greater than zero, you need not
  /// reduce the count correspondingly).
  factory Uint32List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int? length]) {
    return buffer.asUint32List(offsetInBytes, length);
  }

  /// Creates a [Uint32List] view on a range of elements of [data].
  ///
  /// Creates a view on the range of `data.buffer` which corresponds
  /// to the elements of [data] from [start] until [end].
  /// If [data] is a typed data list, like [Uint16List], then the view is on
  /// the bytes of the elements with indices from [start] until [end].
  /// If [data] is a [ByteData], it's treated like a list of bytes.
  ///
  /// If provided, [start] and [end] must satisfy
  ///
  /// 0 &le; `start` &le; `end` &le; *elementCount*
  ///
  /// where *elementCount* is the number of elements in [data], which
  /// is the same as the [List.length] of a typed data list.
  ///
  /// If omitted, [start] defaults to zero and [end] to *elementCount*.
  ///
  /// The start and end indices of the range of bytes being viewed must be
  /// multiples of four.
  @Since("2.8")
  factory Uint32List.sublistView(TypedData data, [int start = 0, int? end]) {
    int elementSize = data.elementSizeInBytes;
    end = RangeError.checkValidRange(
        start, end, data.lengthInBytes ~/ elementSize);
    int byteLength = (end - start) * elementSize;
    if (byteLength % bytesPerElement != 0) {
      throw ArgumentError("The number of bytes to view must be a multiple of " +
          "$bytesPerElement");
    }
    return data.buffer.asUint32List(data.offsetInBytes + start * elementSize,
        byteLength ~/ bytesPerElement);
  }

  /// A read-only view of this [Uint32List].
  @Since("3.3")
  Uint32List asUnmodifiableView();

  /// Creates a new list containing the elements between [start] and [end].
  ///
  /// The new list is a `Uint32List` containing the elements of this
  /// list at positions greater than or equal to [start] and less than [end] in
  /// the same order as they occur in this list.
  ///
  /// ```dart
  /// var numbers = Uint32List.fromList([0, 1, 2, 3, 4]);
  /// print(numbers.sublist(1, 3)); // [1, 2]
  /// print(numbers.sublist(1, 3).runtimeType); // Uint32List
  /// ```
  ///
  /// If [end] is omitted, it defaults to the [length] of this list.
  ///
  /// ```dart
  /// print(numbers.sublist(1)); // [1, 2, 3, 4]
  /// ```
  ///
  /// The `start` and `end` positions must satisfy the relations
  /// 0 ≤ `start` ≤ `end` ≤ `this.length`.
  /// If `end` is equal to `start`, then the returned list is empty.
  Uint32List sublist(int start, [int? end]);

  static const int bytesPerElement = 4;
}

/// A fixed-length list of 64-bit signed integers that is viewable as a
/// [TypedData].
///
/// For long lists, this implementation can be considerably
/// more space- and time-efficient than the default [List] implementation.
///
/// Integers stored in the list are truncated to their low 64 bits,
/// interpreted as a signed 64-bit two's complement integer with values in the
/// range -9223372036854775808 to +9223372036854775807.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// `Int64List`.
abstract final class Int64List implements _TypedIntList {
  /// Creates an [Int64List] of the specified length (in elements), all of
  /// whose elements are initially zero.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely
  /// [length] times 8 bytes.
  external factory Int64List(int length);

  /// Creates a [Int64List] with the same length as the [elements] list
  /// and copies over the elements.
  ///
  /// Values are truncated to fit in the list when they are copied,
  /// the same way storing values truncates them.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely
  /// `elements.length` times 8 bytes.
  external factory Int64List.fromList(List<int> elements);

  /// Creates an [Int64List] _view_ of the specified region in [buffer].
  ///
  /// Changes in the [Int64List] will be visible in the byte buffer
  /// and vice versa.
  /// If the [offsetInBytes] index of the region is not specified,
  /// it defaults to zero (the first byte in the byte buffer).
  /// If the length is not provided,
  /// the view extends to the end of the byte buffer.
  ///
  /// The [offsetInBytes] and [length] must be non-negative, and
  /// [offsetInBytes] + ([length] * [bytesPerElement]) must be less than or
  /// equal to the length of [buffer].
  ///
  /// The [offsetInBytes] must be a multiple of [bytesPerElement].
  ///
  /// Note that when creating a view from a [TypedData] list or byte data,
  /// that list or byte data may itself be a view on a larger buffer
  /// with a [TypedData.offsetInBytes] greater than zero.
  /// Merely doing `Int64List.view(other.buffer, 0, count)` may not
  /// point to the bytes you intended. Instead you may need to do:
  /// ```dart
  /// Int64List.view(other.buffer, other.offsetInBytes, count)
  /// ```
  /// Alternatively, use [Int64List.sublistView]
  /// which includes this computation:
  /// ```dart
  /// Int64List.sublistView(other, 0, count);
  /// ```
  /// (The third argument is an end index rather than a length, so if
  /// you start from a position greater than zero, you need not
  /// reduce the count correspondingly).
  factory Int64List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int? length]) {
    return buffer.asInt64List(offsetInBytes, length);
  }

  /// Creates an [Int64List] view on a range of elements of [data].
  ///
  /// Creates a view on the range of `data.buffer` which corresponds
  /// to the elements of [data] from [start] until [end].
  /// If [data] is a typed data list, like [Uint16List], then the view is on
  /// the bytes of the elements with indices from [start] until [end].
  /// If [data] is a [ByteData], it's treated like a list of bytes.
  ///
  /// If provided, [start] and [end] must satisfy
  ///
  /// 0 &le; `start` &le; `end` &le; *elementCount*
  ///
  /// where *elementCount* is the number of elements in [data], which
  /// is the same as the [List.length] of a typed data list.
  ///
  /// If omitted, [start] defaults to zero and [end] to *elementCount*.
  ///
  /// The start and end indices of the range of bytes being viewed must be
  /// multiples of eight.
  @Since("2.8")
  factory Int64List.sublistView(TypedData data, [int start = 0, int? end]) {
    int elementSize = data.elementSizeInBytes;
    end = RangeError.checkValidRange(
        start, end, data.lengthInBytes ~/ elementSize);
    int byteLength = (end - start) * elementSize;
    if (byteLength % bytesPerElement != 0) {
      throw ArgumentError("The number of bytes to view must be a multiple of " +
          "$bytesPerElement");
    }
    return data.buffer.asInt64List(data.offsetInBytes + start * elementSize,
        byteLength ~/ bytesPerElement);
  }

  /// A read-only view of this [Int64List].
  @Since("3.3")
  Int64List asUnmodifiableView();

  /// Creates a new list containing the elements between [start] and [end].
  ///
  /// The new list is an `Int64List` containing the elements of this
  /// list at positions greater than or equal to [start] and less than [end] in
  /// the same order as they occur in this list.
  ///
  /// ```dart
  /// var numbers = Int64List.fromList([0, 1, 2, 3, 4]);
  /// print(numbers.sublist(1, 3)); // [1, 2]
  /// print(numbers.sublist(1, 3).runtimeType); // Int64List
  /// ```
  ///
  /// If [end] is omitted, it defaults to the [length] of this list.
  ///
  /// ```dart
  /// print(numbers.sublist(1)); // [1, 2, 3, 4]
  /// ```
  ///
  /// The `start` and `end` positions must satisfy the relations
  /// 0 ≤ `start` ≤ `end` ≤ `this.length`.
  /// If `end` is equal to `start`, then the returned list is empty.
  Int64List sublist(int start, [int? end]);

  static const int bytesPerElement = 8;
}

/// A fixed-length list of 64-bit unsigned integers that is viewable as a
/// [TypedData].
///
/// For long lists, this implementation can be considerably
/// more space- and time-efficient than the default [List] implementation.
///
/// Integers stored in the list are truncated to their low 64 bits,
/// interpreted as an unsigned 64-bit integer with values in the
/// range 0 to 18446744073709551615.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// `Uint64List`.
abstract final class Uint64List implements _TypedIntList {
  /// Creates a [Uint64List] of the specified length (in elements), all
  /// of whose elements are initially zero.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely
  /// [length] times 8 bytes.
  external factory Uint64List(int length);

  /// Creates a [Uint64List] with the same length as the [elements] list
  /// and copies over the elements.
  ///
  /// Values are truncated to fit in the list when they are copied,
  /// the same way storing values truncates them.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely
  /// `elements.length` times 8 bytes.
  external factory Uint64List.fromList(List<int> elements);

  /// Creates an [Uint64List] _view_ of the specified region in
  /// the specified byte buffer.
  ///
  /// Changes in the [Uint64List] will be visible in the byte buffer
  /// and vice versa.
  /// If the [offsetInBytes] index of the region is not specified,
  /// it defaults to zero (the first byte in the byte buffer).
  /// If the length is not provided,
  /// the view extends to the end of the byte buffer.
  ///
  /// The [offsetInBytes] and [length] must be non-negative, and
  /// [offsetInBytes] + ([length] * [bytesPerElement]) must be less than or
  /// equal to the length of [buffer].
  ///
  /// The [offsetInBytes] must be a multiple of [bytesPerElement].
  ///
  /// Note that when creating a view from a [TypedData] list or byte data,
  /// that list or byte data may itself be a view on a larger buffer
  /// with a [TypedData.offsetInBytes] greater than zero.
  /// Merely doing `Uint64List.view(other.buffer, 0, count)` may not
  /// point to the bytes you intended. Instead you may need to do:
  /// ```dart
  /// Uint64List.view(other.buffer, other.offsetInBytes, count)
  /// ```
  /// Alternatively, use [Uint64List.sublistView]
  /// which includes this computation:
  /// ```dart
  /// Uint64List.sublistView(other, 0, count);
  /// ```
  /// (The third argument is an end index rather than a length, so if
  /// you start from a position greater than zero, you need not
  /// reduce the count correspondingly).
  factory Uint64List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int? length]) {
    return buffer.asUint64List(offsetInBytes, length);
  }

  /// Creates a [Uint64List] view on a range of elements of [data].
  ///
  /// Creates a view on the range of `data.buffer` which corresponds
  /// to the elements of [data] from [start] until [end].
  /// If [data] is a typed data list, like [Uint16List], then the view is on
  /// the bytes of the elements with indices from [start] until [end].
  /// If [data] is a [ByteData], it's treated like a list of bytes.
  ///
  /// If provided, [start] and [end] must satisfy
  ///
  /// 0 &le; `start` &le; `end` &le; *elementCount*
  ///
  /// where *elementCount* is the number of elements in [data], which
  /// is the same as the [List.length] of a typed data list.
  ///
  /// If omitted, [start] defaults to zero and [end] to *elementCount*.
  ///
  /// The start and end indices of the range of bytes being viewed must be
  /// multiples of eight.
  @Since("2.8")
  factory Uint64List.sublistView(TypedData data, [int start = 0, int? end]) {
    int elementSize = data.elementSizeInBytes;
    end = RangeError.checkValidRange(
        start, end, data.lengthInBytes ~/ elementSize);
    int byteLength = (end - start) * elementSize;
    if (byteLength % bytesPerElement != 0) {
      throw ArgumentError("The number of bytes to view must be a multiple of " +
          "$bytesPerElement");
    }
    return data.buffer.asUint64List(data.offsetInBytes + start * elementSize,
        byteLength ~/ bytesPerElement);
  }

  /// A read-only view of this [Uint64List].
  @Since("3.3")
  Uint64List asUnmodifiableView();

  /// Creates a new list containing the elements between [start] and [end].
  ///
  /// The new list is a `Uint64List` containing the elements of this
  /// list at positions greater than or equal to [start] and less than [end] in
  /// the same order as they occur in this list.
  ///
  /// ```dart
  /// var numbers = Uint64List.fromList([0, 1, 2, 3, 4]);
  /// print(numbers.sublist(1, 3)); // [1, 2]
  /// print(numbers.sublist(1, 3).runtimeType); // Uint64List
  /// ```
  ///
  /// If [end] is omitted, it defaults to the [length] of this list.
  ///
  /// ```dart
  /// print(numbers.sublist(1)); // [1, 2, 3, 4]
  /// ```
  ///
  /// The `start` and `end` positions must satisfy the relations
  /// 0 ≤ `start` ≤ `end` ≤ `this.length`.
  /// If `end` is equal to `start`, then the returned list is empty.
  Uint64List sublist(int start, [int? end]);

  static const int bytesPerElement = 8;
}

/// A fixed-length list of IEEE 754 single-precision binary floating-point
/// numbers that is viewable as a [TypedData].
///
/// For long lists, this
/// implementation can be considerably more space- and time-efficient than
/// the default [List] implementation.
///
/// Double values stored in the list are converted to the nearest
/// single-precision value. Values read are converted to a double
/// value with the same value.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// `Float32List`.
abstract final class Float32List implements _TypedFloatList {
  /// Creates a [Float32List] of the specified length (in elements), all of
  /// whose elements are initially zero.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely
  /// [length] times 4 bytes.
  external factory Float32List(int length);

  /// Creates a [Float32List] with the same length as the [elements] list
  /// and copies over the elements.
  ///
  /// Values are truncated to fit in the list when they are copied,
  /// the same way storing values truncates them.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely
  /// `elements.length` times 4 bytes.
  external factory Float32List.fromList(List<double> elements);

  /// Creates a [Float32List] _view_ of the specified region in [buffer].
  ///
  /// Changes in the [Float32List] will be visible in the byte
  /// buffer and vice versa.
  /// If the [offsetInBytes] index of the region is not specified,
  /// it defaults to zero (the first byte in the byte buffer).
  /// If the length is not provided,
  /// the view extends to the end of the byte buffer.
  ///
  /// The [offsetInBytes] and [length] must be non-negative, and
  /// [offsetInBytes] + ([length] * [bytesPerElement]) must be less than or
  /// equal to the length of [buffer].
  ///
  /// The [offsetInBytes] must be a multiple of [bytesPerElement].
  ///
  /// Note that when creating a view from a [TypedData] list or byte data,
  /// that list or byte data may itself be a view on a larger buffer
  /// with a [TypedData.offsetInBytes] greater than zero.
  /// Merely doing `Float32List.view(other.buffer, 0, count)` may not
  /// point to the bytes you intended. Instead you may need to do:
  /// ```dart
  /// Float32List.view(other.buffer, other.offsetInBytes, count)
  /// ```
  /// Alternatively, use [Float32List.sublistView]
  /// which includes this computation:
  /// ```dart
  /// Float32List.sublistView(other, 0, count);
  /// ```
  /// (The third argument is an end index rather than a length, so if
  /// you start from a position greater than zero, you need not
  /// reduce the count correspondingly).
  factory Float32List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int? length]) {
    return buffer.asFloat32List(offsetInBytes, length);
  }

  /// Creates an [Float32List] view on a range of elements of [data].
  ///
  /// Creates a view on the range of `data.buffer` which corresponds
  /// to the elements of [data] from [start] until [end].
  /// If [data] is a typed data list, like [Uint16List], then the view is on
  /// the bytes of the elements with indices from [start] until [end].
  /// If [data] is a [ByteData], it's treated like a list of bytes.
  ///
  /// If provided, [start] and [end] must satisfy
  ///
  /// 0 &le; `start` &le; `end` &le; *elementCount*
  ///
  /// where *elementCount* is the number of elements in [data], which
  /// is the same as the [List.length] of a typed data list.
  ///
  /// If omitted, [start] defaults to zero and [end] to *elementCount*.
  ///
  /// The start and end indices of the range of bytes being viewed must be
  /// multiples of four.
  @Since("2.8")
  factory Float32List.sublistView(TypedData data, [int start = 0, int? end]) {
    int elementSize = data.elementSizeInBytes;
    end = RangeError.checkValidRange(
        start, end, data.lengthInBytes ~/ elementSize);
    int byteLength = (end - start) * elementSize;
    if (byteLength % bytesPerElement != 0) {
      throw ArgumentError("The number of bytes to view must be a multiple of " +
          "$bytesPerElement");
    }
    return data.buffer.asFloat32List(data.offsetInBytes + start * elementSize,
        byteLength ~/ bytesPerElement);
  }

  /// A read-only view of this [Float32List].
  @Since("3.3")
  Float32List asUnmodifiableView();

  /// Creates a new list containing the elements between [start] and [end].
  ///
  /// The new list is a `Float32List` containing the elements of this
  /// list at positions greater than or equal to [start] and less than [end] in
  /// the same order as they occur in this list.
  ///
  /// ```dart
  /// var numbers = Float32List.fromList([0.0, 1.0, 2.0, 3.0, 4.0]);
  /// print(numbers.sublist(1, 3)); // [1.0, 2.0]
  /// print(numbers.sublist(1, 3).runtimeType); // Float32List
  /// ```
  ///
  /// If [end] is omitted, it defaults to the [length] of this list.
  ///
  /// ```dart
  /// print(numbers.sublist(1)); // [1.0, 2.0, 3.0, 4.0]
  /// ```
  ///
  /// The `start` and `end` positions must satisfy the relations
  /// 0 ≤ `start` ≤ `end` ≤ `this.length`.
  /// If `end` is equal to `start`, then the returned list is empty.
  Float32List sublist(int start, [int? end]);

  static const int bytesPerElement = 4;
}

/// A fixed-length list of IEEE 754 double-precision binary floating-point
/// numbers  that is viewable as a [TypedData].
///
/// For long lists, this
/// implementation can be considerably more space- and time-efficient than
/// the default [List] implementation.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// `Float64List`.
abstract final class Float64List implements _TypedFloatList {
  /// Creates a [Float64List] of the specified length (in elements), all of
  /// whose elements are initially zero.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely
  /// [length] times 8 bytes.
  external factory Float64List(int length);

  /// Creates a [Float64List] with the same length as the [elements] list
  /// and copies over the elements.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely
  /// `elements.length` times 8 bytes.
  external factory Float64List.fromList(List<double> elements);

  /// Creates a [Float64List] _view_ of the specified region in [buffer].
  ///
  /// Changes in the [Float64List] will be visible in the byte
  /// buffer and vice versa.
  /// If the [offsetInBytes] index of the region is not specified,
  /// it defaults to zero (the first byte in the byte buffer).
  /// If the length is not provided,
  /// the view extends to the end of the byte buffer.
  ///
  /// The [offsetInBytes] and [length] must be non-negative, and
  /// [offsetInBytes] + ([length] * [bytesPerElement]) must be less than or
  /// equal to the length of [buffer].
  ///
  /// The [offsetInBytes] must be a multiple of [bytesPerElement].
  ///
  /// Note that when creating a view from a [TypedData] list or byte data,
  /// that list or byte data may itself be a view on a larger buffer
  /// with a [TypedData.offsetInBytes] greater than zero.
  /// Merely doing `Float64List.view(other.buffer, 0, count)` may not
  /// point to the bytes you intended. Instead you may need to do:
  /// ```dart
  /// Float64List.view(other.buffer, other.offsetInBytes, count)
  /// ```
  /// Alternatively, use [Float64List.sublistView]
  /// which includes this computation:
  /// ```dart
  /// Float64List.sublistView(other, 0, count);
  /// ```
  /// (The third argument is an end index rather than a length, so if
  /// you start from a position greater than zero, you need not
  /// reduce the count correspondingly).
  factory Float64List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int? length]) {
    return buffer.asFloat64List(offsetInBytes, length);
  }

  /// Creates a [Float64List] view on a range of elements of [data].
  ///
  /// Creates a view on the range of `data.buffer` which corresponds
  /// to the elements of [data] from [start] until [end].
  /// If [data] is a typed data list, like [Uint16List], then the view is on
  /// the bytes of the elements with indices from [start] until [end].
  /// If [data] is a [ByteData], it's treated like a list of bytes.
  ///
  /// If provided, [start] and [end] must satisfy
  ///
  /// 0 &le; `start` &le; `end` &le; *elementCount*
  ///
  /// where *elementCount* is the number of elements in [data], which
  /// is the same as the [List.length] of a typed data list.
  ///
  /// If omitted, [start] defaults to zero and [end] to *elementCount*.
  ///
  /// The start and end indices of the range of bytes being viewed must be
  /// multiples of eight.
  @Since("2.8")
  factory Float64List.sublistView(TypedData data, [int start = 0, int? end]) {
    int elementSize = data.elementSizeInBytes;
    end = RangeError.checkValidRange(
        start, end, data.lengthInBytes ~/ elementSize);
    int byteLength = (end - start) * elementSize;
    if (byteLength % bytesPerElement != 0) {
      throw ArgumentError("The number of bytes to view must be a multiple of " +
          "$bytesPerElement");
    }
    return data.buffer.asFloat64List(data.offsetInBytes + start * elementSize,
        byteLength ~/ bytesPerElement);
  }

  /// A read-only view of this [Float64List].
  @Since("3.3")
  Float64List asUnmodifiableView();

  /// Creates a new list containing the elements between [start] and [end].
  ///
  /// The new list is a `Float64List` containing the elements of this
  /// list at positions greater than or equal to [start] and less than [end] in
  /// the same order as they occur in this list.
  ///
  /// ```dart
  /// var numbers = Float64List.fromList([0.0, 1.0, 2.0, 3.0, 4.0]);
  /// print(numbers.sublist(1, 3)); // [1.0, 2.0]
  /// print(numbers.sublist(1, 3).runtimeType); // Float64List
  /// ```
  ///
  /// If [end] is omitted, it defaults to the [length] of this list.
  ///
  /// ```dart
  /// print(numbers.sublist(1)); // [1.0, 2.0, 3.0, 4.0]
  /// ```
  ///
  /// The `start` and `end` positions must satisfy the relations
  /// 0 ≤ `start` ≤ `end` ≤ `this.length`.
  /// If `end` is equal to `start`, then the returned list is empty.
  Float64List sublist(int start, [int? end]);

  static const int bytesPerElement = 8;
}

/// A fixed-length list of [Float32x4] numbers that is viewable as a
/// [TypedData].
///
/// For long lists, this implementation will be considerably more
/// space- and time-efficient than the default [List] implementation.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// `Float32x4List`.
abstract final class Float32x4List
    implements TypedDataList<Float32x4>, TypedData {
  /// Creates a [Float32x4List] of the specified length (in elements),
  /// all of whose elements are initially zero.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely
  /// [length] times 16 bytes.
  external factory Float32x4List(int length);

  /// Creates a [Float32x4List] with the same length as the [elements] list
  /// and copies over the elements.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely
  /// `elements.length` times 16 bytes.
  external factory Float32x4List.fromList(List<Float32x4> elements);

  /// Creates a [Float32x4List] _view_ of the specified region in [buffer].
  ///
  /// Changes in the [Float32x4List] will be visible in the byte
  /// buffer and vice versa.
  /// If the [offsetInBytes] index of the region is not specified,
  /// it defaults to zero (the first byte in the byte buffer).
  /// If the length is not provided,
  /// the view extends to the end of the byte buffer.
  ///
  /// The [offsetInBytes] and [length] must be non-negative, and
  /// [offsetInBytes] + ([length] * [bytesPerElement]) must be less than or
  /// equal to the length of [buffer].
  ///
  /// The [offsetInBytes] must be a multiple of [bytesPerElement].
  ///
  /// Note that when creating a view from a [TypedData] list or byte data,
  /// that list or byte data may itself be a view on a larger buffer
  /// with a [TypedData.offsetInBytes] greater than zero.
  /// Merely doing `Float32x4List.view(other.buffer, 0, count)` may not
  /// point to the bytes you intended. Instead you may need to do:
  /// ```dart
  /// Float32x4List.view(other.buffer, other.offsetInBytes, count)
  /// ```
  /// Alternatively, use [Float32x4List.sublistView]
  /// which includes this computation:
  /// ```dart
  /// Float32x4List.sublistView(other, 0, count);
  /// ```
  /// (The third argument is an end index rather than a length, so if
  /// you start from a position greater than zero, you need not
  /// reduce the count correspondingly).
  factory Float32x4List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int? length]) {
    return buffer.asFloat32x4List(offsetInBytes, length);
  }

  /// Creates a [Float32x4List] view on a range of elements of [data].
  ///
  /// Creates a view on the range of `data.buffer` which corresponds
  /// to the elements of [data] from [start] until [end].
  /// If [data] is a typed data list, like [Uint16List], then the view is on
  /// the bytes of the elements with indices from [start] until [end].
  /// If [data] is a [ByteData], it's treated like a list of bytes.
  ///
  /// If provided, [start] and [end] must satisfy
  ///
  /// 0 &le; `start` &le; `end` &le; *elementCount*
  ///
  /// where *elementCount* is the number of elements in [data], which
  /// is the same as the [List.length] of a typed data list.
  ///
  /// If omitted, [start] defaults to zero and [end] to *elementCount*.
  ///
  /// The start and end indices of the range of bytes being viewed must be
  /// multiples of sixteen.
  @Since("2.8")
  factory Float32x4List.sublistView(TypedData data, [int start = 0, int? end]) {
    int elementSize = data.elementSizeInBytes;
    end = RangeError.checkValidRange(
        start, end, data.lengthInBytes ~/ elementSize);
    int byteLength = (end - start) * elementSize;
    if (byteLength % bytesPerElement != 0) {
      throw ArgumentError("The number of bytes to view must be a multiple of " +
          "$bytesPerElement");
    }
    return data.buffer.asFloat32x4List(data.offsetInBytes + start * elementSize,
        byteLength ~/ bytesPerElement);
  }

  /// A read-only view of this [Float32x4List].
  @Since("3.3")
  Float32x4List asUnmodifiableView();

  /// The concatenation of this list and [other].
  ///
  /// If [other] is also a [Float32x4List], the result is a new [Float32x4List],
  /// otherwise the result is a normal growable `List<Float32x4>`.
  List<Float32x4> operator +(List<Float32x4> other);

  /// Creates a new list containing the elements between [start] and [end].
  ///
  /// The new list is a `Float32x4List` containing the elements of this
  /// list at positions greater than or equal to [start] and less than [end] in
  /// the same order as they occur in this list.
  ///
  /// ```dart
  /// var numbers = Float32x4List.fromList([
  ///   Float32x4(0, 1, 2, 3),
  ///   Float32x4(1, 2, 3, 4),
  ///   Float32x4(2, 3, 4, 5),
  ///   Float32x4(3, 4, 5, 6),
  ///   Float32x4(4, 5, 6, 7),
  /// ]);
  /// print(numbers.sublist(1, 2)); // [Float32x4(1, 2, 3, 4)]
  /// print(numbers.sublist(1, 2).runtimeType); // Float32x4List
  /// ```
  ///
  /// If [end] is omitted, it defaults to the [length] of this list.
  ///
  /// ```dart
  /// print(numbers.sublist(4)); // [Float32x4(4, 5, 6, 7)]
  /// ```
  ///
  /// The `start` and `end` positions must satisfy the relations
  /// 0 ≤ `start` ≤ `end` ≤ `this.length`.
  /// If `end` is equal to `start`, then the returned list is empty.
  Float32x4List sublist(int start, [int? end]);

  static const int bytesPerElement = 16;
}

/// A fixed-length list of [Int32x4] numbers that is viewable as a
/// [TypedData].
///
/// For long lists, this implementation will be considerably more
/// space- and time-efficient than the default [List] implementation.
abstract final class Int32x4List implements TypedDataList<Int32x4>, TypedData {
  /// Creates a [Int32x4List] of the specified length (in elements),
  /// all of whose elements are initially zero.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely
  /// [length] times 16 bytes.
  external factory Int32x4List(int length);

  /// Creates a [Int32x4List] with the same length as the [elements] list
  /// and copies over the elements.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely
  /// `elements.length` times 16 bytes.
  external factory Int32x4List.fromList(List<Int32x4> elements);

  /// Creates a [Int32x4List] _view_ of the specified region in [buffer].
  ///
  /// Changes in the [Int32x4List] will be visible in the byte
  /// buffer and vice versa.
  /// If the [offsetInBytes] index of the region is not specified,
  /// it defaults to zero (the first byte in the byte buffer).
  /// If the length is not provided,
  /// the view extends to the end of the byte buffer.
  ///
  /// The [offsetInBytes] and [length] must be non-negative, and
  /// [offsetInBytes] + ([length] * [bytesPerElement]) must be less than or
  /// equal to the length of [buffer].
  ///
  /// The [offsetInBytes] must be a multiple of [bytesPerElement].
  ///
  /// Note that when creating a view from a [TypedData] list or byte data,
  /// that list or byte data may itself be a view on a larger buffer
  /// with a [TypedData.offsetInBytes] greater than zero.
  /// Merely doing `Int32x4List.view(other.buffer, 0, count)` may not
  /// point to the bytes you intended. Instead you may need to do:
  /// ```dart
  /// Int32x4List.view(other.buffer, other.offsetInBytes, count)
  /// ```
  /// Alternatively, use [Int32x4List.sublistView]
  /// which includes this computation:
  /// ```dart
  /// Int32x4List.sublistView(other, 0, count);
  /// ```
  /// (The third argument is an end index rather than a length, so if
  /// you start from a position greater than zero, you need not
  /// reduce the count correspondingly).
  factory Int32x4List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int? length]) {
    return buffer.asInt32x4List(offsetInBytes, length);
  }

  /// Creates an [Int32x4List] view on a range of elements of [data].
  ///
  /// Creates a view on the range of `data.buffer` which corresponds
  /// to the elements of [data] from [start] until [end].
  /// If [data] is a typed data list, like [Uint16List], then the view is on
  /// the bytes of the elements with indices from [start] until [end].
  /// If [data] is a [ByteData], it's treated like a list of bytes.
  ///
  /// If provided, [start] and [end] must satisfy
  ///
  /// 0 &le; `start` &le; `end` &le; *elementCount*
  ///
  /// where *elementCount* is the number of elements in [data], which
  /// is the same as the [List.length] of a typed data list.
  ///
  /// If omitted, [start] defaults to zero and [end] to *elementCount*.
  ///
  /// The start and end indices of the range of bytes being viewed must be
  /// multiples of sixteen.
  @Since("2.8")
  factory Int32x4List.sublistView(TypedData data, [int start = 0, int? end]) {
    int elementSize = data.elementSizeInBytes;
    end = RangeError.checkValidRange(
        start, end, data.lengthInBytes ~/ elementSize);
    int byteLength = (end - start) * elementSize;
    if (byteLength % bytesPerElement != 0) {
      throw ArgumentError("The number of bytes to view must be a multiple of " +
          "$bytesPerElement");
    }
    return data.buffer.asInt32x4List(data.offsetInBytes + start * elementSize,
        byteLength ~/ bytesPerElement);
  }

  /// A read-only view of this [Int32x4List].
  @Since("3.3")
  Int32x4List asUnmodifiableView();

  /// The concatenation of this list and [other].
  ///
  /// If [other] is also a [Int32x4List], the result is a new [Int32x4List],
  /// otherwise the result is a normal growable `List<Int32x4>`.
  List<Int32x4> operator +(List<Int32x4> other);

  /// Creates a new list containing the elements between [start] and [end].
  ///
  /// The new list is an `Int32x4List` containing the elements of this
  /// list at positions greater than or equal to [start] and less than [end] in
  /// the same order as they occur in this list.
  ///
  /// ```dart
  /// var numbers = Int32x4List.fromList([
  ///   Int32x4(0, 1, 2, 3),
  ///   Int32x4(1, 2, 3, 4),
  ///   Int32x4(2, 3, 4, 5),
  ///   Int32x4(3, 4, 5, 6),
  ///   Int32x4(4, 5, 6, 7),
  /// ]);
  /// print(numbers.sublist(1, 2)); // [Int32x4(1, 2, 3, 4)]
  /// print(numbers.sublist(1, 2).runtimeType); // Int32x4List
  /// ```
  ///
  /// If [end] is omitted, it defaults to the [length] of this list.
  ///
  /// ```dart
  /// print(numbers.sublist(3)); // [Int32x4(3, 4, 5, 6), Int32x4(4, 5, 6, 7)]
  /// ```
  ///
  /// The `start` and `end` positions must satisfy the relations
  /// 0 ≤ `start` ≤ `end` ≤ `this.length`.
  /// If `end` is equal to `start`, then the returned list is empty.
  Int32x4List sublist(int start, [int? end]);

  static const int bytesPerElement = 16;
}

/// A fixed-length list of [Float64x2] numbers that is viewable as a
/// [TypedData].
///
/// For long lists, this implementation will be considerably more
/// space- and time-efficient than the default [List] implementation.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// `Float64x2List`.
abstract final class Float64x2List
    implements TypedDataList<Float64x2>, TypedData {
  /// Creates a [Float64x2List] of the specified length (in elements),
  /// all of whose elements have all lanes set to zero.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely
  /// [length] times 16 bytes.
  external factory Float64x2List(int length);

  /// Creates a [Float64x2List] with the same length as the [elements] list
  /// and copies over the elements.
  ///
  /// The list is backed by a [ByteBuffer] containing precisely
  /// `elements.length` times 16 bytes.
  external factory Float64x2List.fromList(List<Float64x2> elements);

  /// The concatenation of this list and [other].
  ///
  /// If [other] is also a [Float64x2List], the result is a new [Float64x2List],
  /// otherwise the result is a normal growable `List<Float64x2>`.
  List<Float64x2> operator +(List<Float64x2> other);

  /// Creates a [Float64x2List] _view_ of the specified region in [buffer].
  ///
  /// Changes in the [Float64x2List] will be visible in the byte
  /// buffer and vice versa.
  /// If the [offsetInBytes] index of the region is not specified,
  /// it defaults to zero (the first byte in the byte buffer).
  /// If the length is not provided,
  /// the view extends to the end of the byte buffer.
  ///
  /// The [offsetInBytes] and [length] must be non-negative, and
  /// [offsetInBytes] + ([length] * [bytesPerElement]) must be less than or
  /// equal to the length of [buffer].
  ///
  /// The [offsetInBytes] must be a multiple of [bytesPerElement].
  ///
  /// Note that when creating a view from a [TypedData] list or byte data,
  /// that list or byte data may itself be a view on a larger buffer
  /// with a [TypedData.offsetInBytes] greater than zero.
  /// Merely doing `Float64x2List.view(other.buffer, 0, count)` may not
  /// point to the bytes you intended. Instead you may need to do:
  /// ```dart
  /// Float64x2List.view(other.buffer, other.offsetInBytes, count)
  /// ```
  /// Alternatively, use [Float64x2List.sublistView]
  /// which includes this computation:
  /// ```dart
  /// Float64x2List.sublistView(other, 0, count);
  /// ```
  /// (The third argument is an end index rather than a length, so if
  /// you start from a position greater than zero, you need not
  /// reduce the count correspondingly).
  factory Float64x2List.view(ByteBuffer buffer,
      [int offsetInBytes = 0, int? length]) {
    return buffer.asFloat64x2List(offsetInBytes, length);
  }

  /// Creates an [Float64x2List] view on a range of elements of [data].
  ///
  /// Creates a view on the range of `data.buffer` which corresponds
  /// to the elements of [data] from [start] until [end].
  /// If [data] is a typed data list, like [Uint16List], then the view is on
  /// the bytes of the elements with indices from [start] until [end].
  /// If [data] is a [ByteData], it's treated like a list of bytes.
  ///
  /// If provided, [start] and [end] must satisfy
  ///
  /// 0 &le; `start` &le; `end` &le; *elementCount*
  ///
  /// where *elementCount* is the number of elements in [data], which
  /// is the same as the [List.length] of a typed data list.
  ///
  /// If omitted, [start] defaults to zero and [end] to *elementCount*.
  ///
  /// The start and end indices of the range of bytes being viewed must be
  /// multiples of sixteen.
  @Since("2.8")
  factory Float64x2List.sublistView(TypedData data, [int start = 0, int? end]) {
    int elementSize = data.elementSizeInBytes;
    end = RangeError.checkValidRange(
        start, end, data.lengthInBytes ~/ elementSize);
    int byteLength = (end - start) * elementSize;
    if (byteLength % bytesPerElement != 0) {
      throw ArgumentError("The number of bytes to view must be a multiple of " +
          "$bytesPerElement");
    }
    return data.buffer.asFloat64x2List(data.offsetInBytes + start * elementSize,
        byteLength ~/ bytesPerElement);
  }

  /// A read-only view of this [Float64x2List].
  @Since("3.3")
  Float64x2List asUnmodifiableView();

  /// Creates a new list containing the elements between [start] and [end].
  ///
  /// The new list is a `Float64x2List` containing the elements of this
  /// list at positions greater than or equal to [start] and less than [end] in
  /// the same order as they occur in this list.
  ///
  /// ```dart
  /// var numbers = Float64x2List.fromList([
  ///   Float64x2(0, 1),
  ///   Float64x2(1, 2),
  ///   Float64x2(2, 3),
  ///   Float64x2(3, 4),
  ///   Float64x2(4, 5),
  /// ]);
  /// print(numbers.sublist(1, 3)); // [Float64x2(1, 2), Float64x2(2, 3)]
  /// print(numbers.sublist(1, 3).runtimeType); // Float64x2List
  /// ```
  ///
  /// If [end] is omitted, it defaults to the [length] of this list.
  ///
  /// ```dart
  /// print(numbers.sublist(3)); // [Float64x2(3, 4), Float64x2(4, 5)]
  /// ```
  ///
  /// The `start` and `end` positions must satisfy the relations
  /// 0 ≤ `start` ≤ `end` ≤ `this.length`.
  /// If `end` is equal to `start`, then the returned list is empty.
  Float64x2List sublist(int start, [int? end]);

  static const int bytesPerElement = 16;
}

/// Float32x4 immutable value type and operations.
///
/// Float32x4 stores 4 32-bit floating point values in "lanes".
/// The lanes are "x", "y", "z", and "w" respectively.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// `Float32x4`.
abstract final class Float32x4 {
  external factory Float32x4(double x, double y, double z, double w);
  external factory Float32x4.splat(double v);
  external factory Float32x4.zero();
  external factory Float32x4.fromInt32x4Bits(Int32x4 x);

  /// Sets the x and y lanes to their respective values in [v] and sets the z
  /// and w lanes to 0.0.
  external factory Float32x4.fromFloat64x2(Float64x2 v);

  /// Addition operator.
  Float32x4 operator +(Float32x4 other);

  /// Negate operator.
  Float32x4 operator -();

  /// Subtraction operator.
  Float32x4 operator -(Float32x4 other);

  /// Multiplication operator.
  Float32x4 operator *(Float32x4 other);

  /// Division operator.
  Float32x4 operator /(Float32x4 other);

  /// Relational less than.
  Int32x4 lessThan(Float32x4 other);

  /// Relational less than or equal.
  Int32x4 lessThanOrEqual(Float32x4 other);

  /// Relational greater than.
  Int32x4 greaterThan(Float32x4 other);

  /// Relational greater than or equal.
  Int32x4 greaterThanOrEqual(Float32x4 other);

  /// Relational equal.
  Int32x4 equal(Float32x4 other);

  /// Relational not-equal.
  Int32x4 notEqual(Float32x4 other);

  /// Returns a copy of this [Float32x4] each lane being scaled by [s].
  /// Equivalent to this * new Float32x4.splat(s)
  Float32x4 scale(double s);

  /// The lane-wise absolute value of this [Float32x4].
  Float32x4 abs();

  /// Lane-wise clamp this [Float32x4] to be in the range
  /// [lowerLimit]-[upperLimit].
  Float32x4 clamp(Float32x4 lowerLimit, Float32x4 upperLimit);

  /// Extracted x value.
  double get x;

  /// Extracted y value.
  double get y;

  /// Extracted z value.
  double get z;

  /// Extracted w value.
  double get w;

  /// Extract the sign bits from each lane return them in the first 4 bits.
  /// "x" lane is bit 0.
  /// "y" lane is bit 1.
  /// "z" lane is bit 2.
  /// "w" lane is bit 3.
  int get signMask;

  /// Mask passed to [shuffle] or [shuffleMix].
  static const int xxxx = 0x00;
  static const int xxxy = 0x40;
  static const int xxxz = 0x80;
  static const int xxxw = 0xC0;
  static const int xxyx = 0x10;
  static const int xxyy = 0x50;
  static const int xxyz = 0x90;
  static const int xxyw = 0xD0;
  static const int xxzx = 0x20;
  static const int xxzy = 0x60;
  static const int xxzz = 0xA0;
  static const int xxzw = 0xE0;
  static const int xxwx = 0x30;
  static const int xxwy = 0x70;
  static const int xxwz = 0xB0;
  static const int xxww = 0xF0;
  static const int xyxx = 0x04;
  static const int xyxy = 0x44;
  static const int xyxz = 0x84;
  static const int xyxw = 0xC4;
  static const int xyyx = 0x14;
  static const int xyyy = 0x54;
  static const int xyyz = 0x94;
  static const int xyyw = 0xD4;
  static const int xyzx = 0x24;
  static const int xyzy = 0x64;
  static const int xyzz = 0xA4;
  static const int xyzw = 0xE4;
  static const int xywx = 0x34;
  static const int xywy = 0x74;
  static const int xywz = 0xB4;
  static const int xyww = 0xF4;
  static const int xzxx = 0x08;
  static const int xzxy = 0x48;
  static const int xzxz = 0x88;
  static const int xzxw = 0xC8;
  static const int xzyx = 0x18;
  static const int xzyy = 0x58;
  static const int xzyz = 0x98;
  static const int xzyw = 0xD8;
  static const int xzzx = 0x28;
  static const int xzzy = 0x68;
  static const int xzzz = 0xA8;
  static const int xzzw = 0xE8;
  static const int xzwx = 0x38;
  static const int xzwy = 0x78;
  static const int xzwz = 0xB8;
  static const int xzww = 0xF8;
  static const int xwxx = 0x0C;
  static const int xwxy = 0x4C;
  static const int xwxz = 0x8C;
  static const int xwxw = 0xCC;
  static const int xwyx = 0x1C;
  static const int xwyy = 0x5C;
  static const int xwyz = 0x9C;
  static const int xwyw = 0xDC;
  static const int xwzx = 0x2C;
  static const int xwzy = 0x6C;
  static const int xwzz = 0xAC;
  static const int xwzw = 0xEC;
  static const int xwwx = 0x3C;
  static const int xwwy = 0x7C;
  static const int xwwz = 0xBC;
  static const int xwww = 0xFC;
  static const int yxxx = 0x01;
  static const int yxxy = 0x41;
  static const int yxxz = 0x81;
  static const int yxxw = 0xC1;
  static const int yxyx = 0x11;
  static const int yxyy = 0x51;
  static const int yxyz = 0x91;
  static const int yxyw = 0xD1;
  static const int yxzx = 0x21;
  static const int yxzy = 0x61;
  static const int yxzz = 0xA1;
  static const int yxzw = 0xE1;
  static const int yxwx = 0x31;
  static const int yxwy = 0x71;
  static const int yxwz = 0xB1;
  static const int yxww = 0xF1;
  static const int yyxx = 0x05;
  static const int yyxy = 0x45;
  static const int yyxz = 0x85;
  static const int yyxw = 0xC5;
  static const int yyyx = 0x15;
  static const int yyyy = 0x55;
  static const int yyyz = 0x95;
  static const int yyyw = 0xD5;
  static const int yyzx = 0x25;
  static const int yyzy = 0x65;
  static const int yyzz = 0xA5;
  static const int yyzw = 0xE5;
  static const int yywx = 0x35;
  static const int yywy = 0x75;
  static const int yywz = 0xB5;
  static const int yyww = 0xF5;
  static const int yzxx = 0x09;
  static const int yzxy = 0x49;
  static const int yzxz = 0x89;
  static const int yzxw = 0xC9;
  static const int yzyx = 0x19;
  static const int yzyy = 0x59;
  static const int yzyz = 0x99;
  static const int yzyw = 0xD9;
  static const int yzzx = 0x29;
  static const int yzzy = 0x69;
  static const int yzzz = 0xA9;
  static const int yzzw = 0xE9;
  static const int yzwx = 0x39;
  static const int yzwy = 0x79;
  static const int yzwz = 0xB9;
  static const int yzww = 0xF9;
  static const int ywxx = 0x0D;
  static const int ywxy = 0x4D;
  static const int ywxz = 0x8D;
  static const int ywxw = 0xCD;
  static const int ywyx = 0x1D;
  static const int ywyy = 0x5D;
  static const int ywyz = 0x9D;
  static const int ywyw = 0xDD;
  static const int ywzx = 0x2D;
  static const int ywzy = 0x6D;
  static const int ywzz = 0xAD;
  static const int ywzw = 0xED;
  static const int ywwx = 0x3D;
  static const int ywwy = 0x7D;
  static const int ywwz = 0xBD;
  static const int ywww = 0xFD;
  static const int zxxx = 0x02;
  static const int zxxy = 0x42;
  static const int zxxz = 0x82;
  static const int zxxw = 0xC2;
  static const int zxyx = 0x12;
  static const int zxyy = 0x52;
  static const int zxyz = 0x92;
  static const int zxyw = 0xD2;
  static const int zxzx = 0x22;
  static const int zxzy = 0x62;
  static const int zxzz = 0xA2;
  static const int zxzw = 0xE2;
  static const int zxwx = 0x32;
  static const int zxwy = 0x72;
  static const int zxwz = 0xB2;
  static const int zxww = 0xF2;
  static const int zyxx = 0x06;
  static const int zyxy = 0x46;
  static const int zyxz = 0x86;
  static const int zyxw = 0xC6;
  static const int zyyx = 0x16;
  static const int zyyy = 0x56;
  static const int zyyz = 0x96;
  static const int zyyw = 0xD6;
  static const int zyzx = 0x26;
  static const int zyzy = 0x66;
  static const int zyzz = 0xA6;
  static const int zyzw = 0xE6;
  static const int zywx = 0x36;
  static const int zywy = 0x76;
  static const int zywz = 0xB6;
  static const int zyww = 0xF6;
  static const int zzxx = 0x0A;
  static const int zzxy = 0x4A;
  static const int zzxz = 0x8A;
  static const int zzxw = 0xCA;
  static const int zzyx = 0x1A;
  static const int zzyy = 0x5A;
  static const int zzyz = 0x9A;
  static const int zzyw = 0xDA;
  static const int zzzx = 0x2A;
  static const int zzzy = 0x6A;
  static const int zzzz = 0xAA;
  static const int zzzw = 0xEA;
  static const int zzwx = 0x3A;
  static const int zzwy = 0x7A;
  static const int zzwz = 0xBA;
  static const int zzww = 0xFA;
  static const int zwxx = 0x0E;
  static const int zwxy = 0x4E;
  static const int zwxz = 0x8E;
  static const int zwxw = 0xCE;
  static const int zwyx = 0x1E;
  static const int zwyy = 0x5E;
  static const int zwyz = 0x9E;
  static const int zwyw = 0xDE;
  static const int zwzx = 0x2E;
  static const int zwzy = 0x6E;
  static const int zwzz = 0xAE;
  static const int zwzw = 0xEE;
  static const int zwwx = 0x3E;
  static const int zwwy = 0x7E;
  static const int zwwz = 0xBE;
  static const int zwww = 0xFE;
  static const int wxxx = 0x03;
  static const int wxxy = 0x43;
  static const int wxxz = 0x83;
  static const int wxxw = 0xC3;
  static const int wxyx = 0x13;
  static const int wxyy = 0x53;
  static const int wxyz = 0x93;
  static const int wxyw = 0xD3;
  static const int wxzx = 0x23;
  static const int wxzy = 0x63;
  static const int wxzz = 0xA3;
  static const int wxzw = 0xE3;
  static const int wxwx = 0x33;
  static const int wxwy = 0x73;
  static const int wxwz = 0xB3;
  static const int wxww = 0xF3;
  static const int wyxx = 0x07;
  static const int wyxy = 0x47;
  static const int wyxz = 0x87;
  static const int wyxw = 0xC7;
  static const int wyyx = 0x17;
  static const int wyyy = 0x57;
  static const int wyyz = 0x97;
  static const int wyyw = 0xD7;
  static const int wyzx = 0x27;
  static const int wyzy = 0x67;
  static const int wyzz = 0xA7;
  static const int wyzw = 0xE7;
  static const int wywx = 0x37;
  static const int wywy = 0x77;
  static const int wywz = 0xB7;
  static const int wyww = 0xF7;
  static const int wzxx = 0x0B;
  static const int wzxy = 0x4B;
  static const int wzxz = 0x8B;
  static const int wzxw = 0xCB;
  static const int wzyx = 0x1B;
  static const int wzyy = 0x5B;
  static const int wzyz = 0x9B;
  static const int wzyw = 0xDB;
  static const int wzzx = 0x2B;
  static const int wzzy = 0x6B;
  static const int wzzz = 0xAB;
  static const int wzzw = 0xEB;
  static const int wzwx = 0x3B;
  static const int wzwy = 0x7B;
  static const int wzwz = 0xBB;
  static const int wzww = 0xFB;
  static const int wwxx = 0x0F;
  static const int wwxy = 0x4F;
  static const int wwxz = 0x8F;
  static const int wwxw = 0xCF;
  static const int wwyx = 0x1F;
  static const int wwyy = 0x5F;
  static const int wwyz = 0x9F;
  static const int wwyw = 0xDF;
  static const int wwzx = 0x2F;
  static const int wwzy = 0x6F;
  static const int wwzz = 0xAF;
  static const int wwzw = 0xEF;
  static const int wwwx = 0x3F;
  static const int wwwy = 0x7F;
  static const int wwwz = 0xBF;
  static const int wwww = 0xFF;

  /// Shuffle the lane values. [mask] must be one of the 256 shuffle constants.
  Float32x4 shuffle(int mask);

  /// Shuffle the lane values in this [Float32x4] and [other]. The returned
  /// Float32x4 will have XY lanes from this [Float32x4] and ZW lanes from
  /// [other].  Uses the same [mask] as [shuffle].
  Float32x4 shuffleMix(Float32x4 other, int mask);

  /// Returns a new [Float32x4] copied from this [Float32x4] with a new x
  /// value.
  Float32x4 withX(double x);

  /// Returns a new [Float32x4] copied from this [Float32x4] with a new y
  /// value.
  Float32x4 withY(double y);

  /// Returns a new [Float32x4] copied from this [Float32x4] with a new z
  /// value.
  Float32x4 withZ(double z);

  /// Returns a new [Float32x4] copied from this [Float32x4] with a new w
  /// value.
  Float32x4 withW(double w);

  /// The lane-wise minimum value in this [Float32x4] or [other].
  Float32x4 min(Float32x4 other);

  /// The lane-wise maximum value in this [Float32x4] or [other].
  Float32x4 max(Float32x4 other);

  /// The square root of this [Float32x4].
  Float32x4 sqrt();

  /// The reciprocal of this [Float32x4].
  Float32x4 reciprocal();

  /// The square root of the reciprocal of this [Float32x4].
  Float32x4 reciprocalSqrt();
}

/// Int32x4 and operations.
///
/// Int32x4 stores 4 32-bit bit-masks in "lanes".
/// The lanes are "x", "y", "z", and "w" respectively.
abstract final class Int32x4 {
  external factory Int32x4(int x, int y, int z, int w);
  external factory Int32x4.bool(bool x, bool y, bool z, bool w);
  external factory Int32x4.fromFloat32x4Bits(Float32x4 x);

  /// The bit-wise or operator.
  Int32x4 operator |(Int32x4 other);

  /// The bit-wise and operator.
  Int32x4 operator &(Int32x4 other);

  /// The bit-wise xor operator.
  Int32x4 operator ^(Int32x4 other);

  /// Addition operator.
  Int32x4 operator +(Int32x4 other);

  /// Subtraction operator.
  Int32x4 operator -(Int32x4 other);

  /// Extract 32-bit mask from x lane.
  int get x;

  /// Extract 32-bit mask from y lane.
  int get y;

  /// Extract 32-bit mask from z lane.
  int get z;

  /// Extract 32-bit mask from w lane.
  int get w;

  /// Extract the top bit from each lane return them in the first 4 bits.
  /// "x" lane is bit 0.
  /// "y" lane is bit 1.
  /// "z" lane is bit 2.
  /// "w" lane is bit 3.
  int get signMask;

  /// Mask passed to [shuffle] or [shuffleMix].
  static const int xxxx = 0x00;
  static const int xxxy = 0x40;
  static const int xxxz = 0x80;
  static const int xxxw = 0xC0;
  static const int xxyx = 0x10;
  static const int xxyy = 0x50;
  static const int xxyz = 0x90;
  static const int xxyw = 0xD0;
  static const int xxzx = 0x20;
  static const int xxzy = 0x60;
  static const int xxzz = 0xA0;
  static const int xxzw = 0xE0;
  static const int xxwx = 0x30;
  static const int xxwy = 0x70;
  static const int xxwz = 0xB0;
  static const int xxww = 0xF0;
  static const int xyxx = 0x04;
  static const int xyxy = 0x44;
  static const int xyxz = 0x84;
  static const int xyxw = 0xC4;
  static const int xyyx = 0x14;
  static const int xyyy = 0x54;
  static const int xyyz = 0x94;
  static const int xyyw = 0xD4;
  static const int xyzx = 0x24;
  static const int xyzy = 0x64;
  static const int xyzz = 0xA4;
  static const int xyzw = 0xE4;
  static const int xywx = 0x34;
  static const int xywy = 0x74;
  static const int xywz = 0xB4;
  static const int xyww = 0xF4;
  static const int xzxx = 0x08;
  static const int xzxy = 0x48;
  static const int xzxz = 0x88;
  static const int xzxw = 0xC8;
  static const int xzyx = 0x18;
  static const int xzyy = 0x58;
  static const int xzyz = 0x98;
  static const int xzyw = 0xD8;
  static const int xzzx = 0x28;
  static const int xzzy = 0x68;
  static const int xzzz = 0xA8;
  static const int xzzw = 0xE8;
  static const int xzwx = 0x38;
  static const int xzwy = 0x78;
  static const int xzwz = 0xB8;
  static const int xzww = 0xF8;
  static const int xwxx = 0x0C;
  static const int xwxy = 0x4C;
  static const int xwxz = 0x8C;
  static const int xwxw = 0xCC;
  static const int xwyx = 0x1C;
  static const int xwyy = 0x5C;
  static const int xwyz = 0x9C;
  static const int xwyw = 0xDC;
  static const int xwzx = 0x2C;
  static const int xwzy = 0x6C;
  static const int xwzz = 0xAC;
  static const int xwzw = 0xEC;
  static const int xwwx = 0x3C;
  static const int xwwy = 0x7C;
  static const int xwwz = 0xBC;
  static const int xwww = 0xFC;
  static const int yxxx = 0x01;
  static const int yxxy = 0x41;
  static const int yxxz = 0x81;
  static const int yxxw = 0xC1;
  static const int yxyx = 0x11;
  static const int yxyy = 0x51;
  static const int yxyz = 0x91;
  static const int yxyw = 0xD1;
  static const int yxzx = 0x21;
  static const int yxzy = 0x61;
  static const int yxzz = 0xA1;
  static const int yxzw = 0xE1;
  static const int yxwx = 0x31;
  static const int yxwy = 0x71;
  static const int yxwz = 0xB1;
  static const int yxww = 0xF1;
  static const int yyxx = 0x05;
  static const int yyxy = 0x45;
  static const int yyxz = 0x85;
  static const int yyxw = 0xC5;
  static const int yyyx = 0x15;
  static const int yyyy = 0x55;
  static const int yyyz = 0x95;
  static const int yyyw = 0xD5;
  static const int yyzx = 0x25;
  static const int yyzy = 0x65;
  static const int yyzz = 0xA5;
  static const int yyzw = 0xE5;
  static const int yywx = 0x35;
  static const int yywy = 0x75;
  static const int yywz = 0xB5;
  static const int yyww = 0xF5;
  static const int yzxx = 0x09;
  static const int yzxy = 0x49;
  static const int yzxz = 0x89;
  static const int yzxw = 0xC9;
  static const int yzyx = 0x19;
  static const int yzyy = 0x59;
  static const int yzyz = 0x99;
  static const int yzyw = 0xD9;
  static const int yzzx = 0x29;
  static const int yzzy = 0x69;
  static const int yzzz = 0xA9;
  static const int yzzw = 0xE9;
  static const int yzwx = 0x39;
  static const int yzwy = 0x79;
  static const int yzwz = 0xB9;
  static const int yzww = 0xF9;
  static const int ywxx = 0x0D;
  static const int ywxy = 0x4D;
  static const int ywxz = 0x8D;
  static const int ywxw = 0xCD;
  static const int ywyx = 0x1D;
  static const int ywyy = 0x5D;
  static const int ywyz = 0x9D;
  static const int ywyw = 0xDD;
  static const int ywzx = 0x2D;
  static const int ywzy = 0x6D;
  static const int ywzz = 0xAD;
  static const int ywzw = 0xED;
  static const int ywwx = 0x3D;
  static const int ywwy = 0x7D;
  static const int ywwz = 0xBD;
  static const int ywww = 0xFD;
  static const int zxxx = 0x02;
  static const int zxxy = 0x42;
  static const int zxxz = 0x82;
  static const int zxxw = 0xC2;
  static const int zxyx = 0x12;
  static const int zxyy = 0x52;
  static const int zxyz = 0x92;
  static const int zxyw = 0xD2;
  static const int zxzx = 0x22;
  static const int zxzy = 0x62;
  static const int zxzz = 0xA2;
  static const int zxzw = 0xE2;
  static const int zxwx = 0x32;
  static const int zxwy = 0x72;
  static const int zxwz = 0xB2;
  static const int zxww = 0xF2;
  static const int zyxx = 0x06;
  static const int zyxy = 0x46;
  static const int zyxz = 0x86;
  static const int zyxw = 0xC6;
  static const int zyyx = 0x16;
  static const int zyyy = 0x56;
  static const int zyyz = 0x96;
  static const int zyyw = 0xD6;
  static const int zyzx = 0x26;
  static const int zyzy = 0x66;
  static const int zyzz = 0xA6;
  static const int zyzw = 0xE6;
  static const int zywx = 0x36;
  static const int zywy = 0x76;
  static const int zywz = 0xB6;
  static const int zyww = 0xF6;
  static const int zzxx = 0x0A;
  static const int zzxy = 0x4A;
  static const int zzxz = 0x8A;
  static const int zzxw = 0xCA;
  static const int zzyx = 0x1A;
  static const int zzyy = 0x5A;
  static const int zzyz = 0x9A;
  static const int zzyw = 0xDA;
  static const int zzzx = 0x2A;
  static const int zzzy = 0x6A;
  static const int zzzz = 0xAA;
  static const int zzzw = 0xEA;
  static const int zzwx = 0x3A;
  static const int zzwy = 0x7A;
  static const int zzwz = 0xBA;
  static const int zzww = 0xFA;
  static const int zwxx = 0x0E;
  static const int zwxy = 0x4E;
  static const int zwxz = 0x8E;
  static const int zwxw = 0xCE;
  static const int zwyx = 0x1E;
  static const int zwyy = 0x5E;
  static const int zwyz = 0x9E;
  static const int zwyw = 0xDE;
  static const int zwzx = 0x2E;
  static const int zwzy = 0x6E;
  static const int zwzz = 0xAE;
  static const int zwzw = 0xEE;
  static const int zwwx = 0x3E;
  static const int zwwy = 0x7E;
  static const int zwwz = 0xBE;
  static const int zwww = 0xFE;
  static const int wxxx = 0x03;
  static const int wxxy = 0x43;
  static const int wxxz = 0x83;
  static const int wxxw = 0xC3;
  static const int wxyx = 0x13;
  static const int wxyy = 0x53;
  static const int wxyz = 0x93;
  static const int wxyw = 0xD3;
  static const int wxzx = 0x23;
  static const int wxzy = 0x63;
  static const int wxzz = 0xA3;
  static const int wxzw = 0xE3;
  static const int wxwx = 0x33;
  static const int wxwy = 0x73;
  static const int wxwz = 0xB3;
  static const int wxww = 0xF3;
  static const int wyxx = 0x07;
  static const int wyxy = 0x47;
  static const int wyxz = 0x87;
  static const int wyxw = 0xC7;
  static const int wyyx = 0x17;
  static const int wyyy = 0x57;
  static const int wyyz = 0x97;
  static const int wyyw = 0xD7;
  static const int wyzx = 0x27;
  static const int wyzy = 0x67;
  static const int wyzz = 0xA7;
  static const int wyzw = 0xE7;
  static const int wywx = 0x37;
  static const int wywy = 0x77;
  static const int wywz = 0xB7;
  static const int wyww = 0xF7;
  static const int wzxx = 0x0B;
  static const int wzxy = 0x4B;
  static const int wzxz = 0x8B;
  static const int wzxw = 0xCB;
  static const int wzyx = 0x1B;
  static const int wzyy = 0x5B;
  static const int wzyz = 0x9B;
  static const int wzyw = 0xDB;
  static const int wzzx = 0x2B;
  static const int wzzy = 0x6B;
  static const int wzzz = 0xAB;
  static const int wzzw = 0xEB;
  static const int wzwx = 0x3B;
  static const int wzwy = 0x7B;
  static const int wzwz = 0xBB;
  static const int wzww = 0xFB;
  static const int wwxx = 0x0F;
  static const int wwxy = 0x4F;
  static const int wwxz = 0x8F;
  static const int wwxw = 0xCF;
  static const int wwyx = 0x1F;
  static const int wwyy = 0x5F;
  static const int wwyz = 0x9F;
  static const int wwyw = 0xDF;
  static const int wwzx = 0x2F;
  static const int wwzy = 0x6F;
  static const int wwzz = 0xAF;
  static const int wwzw = 0xEF;
  static const int wwwx = 0x3F;
  static const int wwwy = 0x7F;
  static const int wwwz = 0xBF;
  static const int wwww = 0xFF;

  /// Shuffle the lane values. [mask] must be one of the 256 shuffle constants.
  Int32x4 shuffle(int mask);

  /// Shuffle the lane values in this [Int32x4] and [other]. The returned
  /// Int32x4 will have XY lanes from this [Int32x4] and ZW lanes from [other].
  /// Uses the same [mask] as [shuffle].
  Int32x4 shuffleMix(Int32x4 other, int mask);

  /// Returns a new [Int32x4] copied from this [Int32x4] with a new x value.
  Int32x4 withX(int x);

  /// Returns a new [Int32x4] copied from this [Int32x4] with a new y value.
  Int32x4 withY(int y);

  /// Returns a new [Int32x4] copied from this [Int32x4] with a new z value.
  Int32x4 withZ(int z);

  /// Returns a new [Int32x4] copied from this [Int32x4] with a new w value.
  Int32x4 withW(int w);

  /// Extracted x value. Returns false for 0, true for any other value.
  bool get flagX;

  /// Extracted y value. Returns false for 0, true for any other value.
  bool get flagY;

  /// Extracted z value. Returns false for 0, true for any other value.
  bool get flagZ;

  /// Extracted w value. Returns false for 0, true for any other value.
  bool get flagW;

  /// Returns a new [Int32x4] copied from this [Int32x4] with a new x value.
  Int32x4 withFlagX(bool x);

  /// Returns a new [Int32x4] copied from this [Int32x4] with a new y value.
  Int32x4 withFlagY(bool y);

  /// Returns a new [Int32x4] copied from this [Int32x4] with a new z value.
  Int32x4 withFlagZ(bool z);

  /// Returns a new [Int32x4] copied from this [Int32x4] with a new w value.
  Int32x4 withFlagW(bool w);

  /// Merge [trueValue] and [falseValue] based on this [Int32x4] bit mask:
  /// Select bit from [trueValue] when bit in this [Int32x4] is on.
  /// Select bit from [falseValue] when bit in this [Int32x4] is off.
  Float32x4 select(Float32x4 trueValue, Float32x4 falseValue);
}

/// Float64x2 immutable value type and operations.
///
/// Float64x2 stores 2 64-bit floating point values in "lanes".
/// The lanes are "x" and "y" respectively.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// `Float64x2`.
abstract final class Float64x2 {
  external factory Float64x2(double x, double y);
  external factory Float64x2.splat(double v);
  external factory Float64x2.zero();

  /// Uses the "x" and "y" lanes from [v].
  external factory Float64x2.fromFloat32x4(Float32x4 v);

  /// Addition operator.
  Float64x2 operator +(Float64x2 other);

  /// Negate operator.
  Float64x2 operator -();

  /// Subtraction operator.
  Float64x2 operator -(Float64x2 other);

  /// Multiplication operator.
  Float64x2 operator *(Float64x2 other);

  /// Division operator.
  Float64x2 operator /(Float64x2 other);

  /// Returns a copy of this [Float64x2] each lane being scaled by [s].
  /// Equivalent to this * new Float64x2.splat(s)
  Float64x2 scale(double s);

  /// The lane-wise absolute value of this [Float64x2].
  Float64x2 abs();

  /// Lane-wise clamp this [Float64x2] to be in the range
  /// [lowerLimit]-[upperLimit].
  Float64x2 clamp(Float64x2 lowerLimit, Float64x2 upperLimit);

  /// Extracted x value.
  double get x;

  /// Extracted y value.
  double get y;

  /// Extract the sign bits from each lane return them in the first 2 bits.
  /// "x" lane is bit 0.
  /// "y" lane is bit 1.
  int get signMask;

  /// Returns a new [Float64x2] copied from this [Float64x2] with a new x
  /// value.
  Float64x2 withX(double x);

  /// Returns a new [Float64x2] copied from this [Float64x2] with a new y
  /// value.
  Float64x2 withY(double y);

  /// The lane-wise minimum value in this [Float64x2] or [other].
  Float64x2 min(Float64x2 other);

  /// The lane-wise maximum value in this [Float64x2] or [other].
  Float64x2 max(Float64x2 other);

  /// The lane-wise square root of this [Float64x2].
  Float64x2 sqrt();
}
