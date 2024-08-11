// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._typed_data;

import 'dart:_internal'
    show
        doubleToIntBits,
        ExpandIterable,
        floatToIntBits,
        FollowedByIterable,
        indexCheck,
        intBitsToDouble,
        intBitsToFloat,
        IterableElementError,
        ListMapView,
        Lists,
        MappedIterable,
        ReversedListIterable,
        SkipWhileIterable,
        Sort,
        SubListIterable,
        TakeWhileIterable,
        unsafeCast,
        WasmTypedDataBase,
        WhereIterable,
        WhereTypeIterable;
import 'dart:_simd';
import 'dart:_wasm';

import 'dart:collection' show ListBase;
import 'dart:math' show Random;
import 'dart:typed_data';

const int _maxWasmArrayLength = 2147483647; // max i32

int _newArrayLengthCheck(int length) {
  // length < 0 || length > _maxWasmArrayLength
  if (length.gtU(_maxWasmArrayLength)) {
    throw RangeError.value(length);
  }
  return length;
}

void _rangeCheck(int listLength, int start, int length) {
  if (length < 0) {
    throw RangeError.value(length);
  }
  if (start < 0) {
    throw RangeError.value(start);
  }
  if (start + length > listLength) {
    throw RangeError.value(start + length);
  }
}

void _offsetAlignmentCheck(int offset, int alignment) {
  if ((offset % alignment) != 0) {
    throw RangeError('Offset ($offset) must be a multiple of $alignment');
  }
}

final class _TypedListIterator<E> implements Iterator<E> {
  final List<E> _array;
  final int _length;
  int _position;
  E? _current;

  _TypedListIterator(List<E> array)
      : _array = array,
        _length = array.length,
        _position = -1;

  bool moveNext() {
    int nextPosition = _position + 1;
    if (nextPosition < _length) {
      // TODO(#52971): Use unchecked read here.
      _current = _array[nextPosition];
      _position = nextPosition;
      return true;
    }
    _position = _length;
    _current = null;
    return false;
  }

  E get current => _current as E;
}

//
// Byte data
//

/// The base class for all [ByteData] implementations. This provides slow
/// implementations for get and set methods using abstract [_getUint8Unchecked]
/// and [_setUint8Unchecked] methods. Implementations should implement these
/// methods and override get/set methods for elements matching the buffer
/// element type to provide fast access.
abstract class ByteDataBase extends WasmTypedDataBase implements ByteData {
  final int offsetInBytes;
  final int lengthInBytes;

  ByteDataBase(this.offsetInBytes, this.lengthInBytes);

  @override
  ByteData asUnmodifiableView();

  void _offsetRangeCheck(int byteOffset, int size) {
    if (byteOffset < 0 || byteOffset + size > lengthInBytes) {
      throw IndexError.withLength(byteOffset, lengthInBytes - offsetInBytes,
          indexable: this, name: "index");
    }
  }

  @override
  int getInt8(int byteOffset) {
    _offsetRangeCheck(byteOffset, 1);
    return _getUint8Unchecked(byteOffset).toSigned(8);
  }

  int _getInt8Unchecked(int byteOffset) {
    return _getUint8Unchecked(byteOffset).toSigned(8);
  }

  @override
  void setInt8(int byteOffset, int value) {
    _offsetRangeCheck(byteOffset, 1);
    _setUint8Unchecked(byteOffset, value.toUnsigned(8));
  }

  void _setInt8Unchecked(int byteOffset, int value) {
    _setUint8Unchecked(byteOffset, value.toUnsigned(8));
  }

  @override
  int getUint8(int byteOffset) {
    _offsetRangeCheck(byteOffset, 1);
    return _getUint8Unchecked(byteOffset);
  }

  int _getUint8Unchecked(int byteOffset);

  @override
  void setUint8(int byteOffset, int value) {
    _offsetRangeCheck(byteOffset, 1);
    return _setUint8Unchecked(byteOffset, value);
  }

  void _setUint8Unchecked(int byteOffset, int value);

  @override
  int getInt16(int byteOffset, [Endian endian = Endian.big]) {
    _offsetRangeCheck(byteOffset, 2);
    return _getUint16Unchecked(byteOffset, endian).toSigned(16);
  }

  int _getInt16Unchecked(int byteOffset, [Endian endian = Endian.big]) {
    return _getUint16Unchecked(byteOffset, endian).toSigned(16);
  }

  @override
  void setInt16(int byteOffset, int value, [Endian endian = Endian.big]) {
    _offsetRangeCheck(byteOffset, 2);
    _setUint16Unchecked(byteOffset, value.toUnsigned(16), endian);
  }

  @override
  void _setInt16Unchecked(int byteOffset, int value,
      [Endian endian = Endian.big]) {
    _setUint16Unchecked(byteOffset, value.toUnsigned(16), endian);
  }

  @override
  int getUint16(int byteOffset, [Endian endian = Endian.big]) {
    _offsetRangeCheck(byteOffset, 2);
    return _getUint16Unchecked(byteOffset, endian);
  }

  @override
  int _getUint16Unchecked(int byteOffset, [Endian endian = Endian.big]) {
    final b1 = _getUint8Unchecked(byteOffset);
    final b2 = _getUint8Unchecked(byteOffset + 1);
    if (endian == Endian.little) {
      return (b2 << 8) | b1;
    } else {
      return (b1 << 8) | b2;
    }
  }

  @override
  void setUint16(int byteOffset, int value, [Endian endian = Endian.big]) {
    _offsetRangeCheck(byteOffset, 2);
    _setUint16Unchecked(byteOffset, value, endian);
  }

  void _setUint16Unchecked(int byteOffset, int value,
      [Endian endian = Endian.big]) {
    final b1 = value & 0xFF;
    final b2 = (value >> 8) & 0xFF;
    if (endian == Endian.little) {
      _setUint8Unchecked(byteOffset, b1);
      _setUint8Unchecked(byteOffset + 1, b2);
    } else {
      _setUint8Unchecked(byteOffset, b2);
      _setUint8Unchecked(byteOffset + 1, b1);
    }
  }

  @override
  int getInt32(int byteOffset, [Endian endian = Endian.big]) {
    _offsetRangeCheck(byteOffset, 4);
    return _getInt32Unchecked(byteOffset, endian);
  }

  int _getInt32Unchecked(int byteOffset, [Endian endian = Endian.big]) {
    return _getUint32Unchecked(byteOffset, endian).toSigned(32);
  }

  @override
  void setInt32(int byteOffset, int value, [Endian endian = Endian.big]) {
    _offsetRangeCheck(byteOffset, 4);
    _setInt32Unchecked(byteOffset, value, endian);
  }

  void _setInt32Unchecked(int byteOffset, int value,
      [Endian endian = Endian.big]) {
    _setUint32Unchecked(byteOffset, value.toUnsigned(32), endian);
  }

  @override
  int getUint32(int byteOffset, [Endian endian = Endian.big]) {
    _offsetRangeCheck(byteOffset, 4);
    return _getUint32Unchecked(byteOffset, endian);
  }

  int _getUint32Unchecked(int byteOffset, [Endian endian = Endian.big]) {
    final b1 = _getUint8Unchecked(byteOffset);
    final b2 = _getUint8Unchecked(byteOffset + 1);
    final b3 = _getUint8Unchecked(byteOffset + 2);
    final b4 = _getUint8Unchecked(byteOffset + 3);
    if (endian == Endian.little) {
      return (b4 << 24) | (b3 << 16) | (b2 << 8) | b1;
    } else {
      return (b1 << 24) | (b2 << 16) | (b3 << 8) | b4;
    }
  }

  @override
  void setUint32(int byteOffset, int value, [Endian endian = Endian.big]) {
    _offsetRangeCheck(byteOffset, 4);
    _setUint32Unchecked(byteOffset, value, endian);
  }

  void _setUint32Unchecked(int byteOffset, int value,
      [Endian endian = Endian.big]) {
    final b1 = value & 0xFF;
    final b2 = (value >> 8) & 0xFF;
    final b3 = (value >> 16) & 0xFF;
    final b4 = (value >> 24) & 0xFF;
    if (endian == Endian.little) {
      _setUint8Unchecked(byteOffset, b1);
      _setUint8Unchecked(byteOffset + 1, b2);
      _setUint8Unchecked(byteOffset + 2, b3);
      _setUint8Unchecked(byteOffset + 3, b4);
    } else {
      _setUint8Unchecked(byteOffset, b4);
      _setUint8Unchecked(byteOffset + 1, b3);
      _setUint8Unchecked(byteOffset + 2, b2);
      _setUint8Unchecked(byteOffset + 3, b1);
    }
  }

  @override
  int getInt64(int byteOffset, [Endian endian = Endian.big]) {
    _offsetRangeCheck(byteOffset, 8);
    return _getInt64Unchecked(byteOffset, endian);
  }

  int _getInt64Unchecked(int byteOffset, [Endian endian = Endian.big]) {
    return _getUint64Unchecked(byteOffset, endian);
  }

  @override
  void setInt64(int byteOffset, int value, [Endian endian = Endian.big]) {
    _offsetRangeCheck(byteOffset, 8);
    _setUint64Unchecked(byteOffset, value, endian);
  }

  void _setInt64Unchecked(int byteOffset, int value,
      [Endian endian = Endian.big]) {
    _offsetRangeCheck(byteOffset, 8);
    _setInt64Unchecked(byteOffset, value, endian);
  }

  @override
  int getUint64(int byteOffset, [Endian endian = Endian.big]) {
    _offsetRangeCheck(byteOffset, 8);
    return _getUint64Unchecked(byteOffset, endian);
  }

  int _getUint64Unchecked(int byteOffset, [Endian endian = Endian.big]) {
    final b1 = _getUint8Unchecked(byteOffset);
    final b2 = _getUint8Unchecked(byteOffset + 1);
    final b3 = _getUint8Unchecked(byteOffset + 2);
    final b4 = _getUint8Unchecked(byteOffset + 3);
    final b5 = _getUint8Unchecked(byteOffset + 4);
    final b6 = _getUint8Unchecked(byteOffset + 5);
    final b7 = _getUint8Unchecked(byteOffset + 6);
    final b8 = _getUint8Unchecked(byteOffset + 7);
    if (endian == Endian.little) {
      return (b8 << 56) |
          (b7 << 48) |
          (b6 << 40) |
          (b5 << 32) |
          (b4 << 24) |
          (b3 << 16) |
          (b2 << 8) |
          b1;
    } else {
      return (b1 << 56) |
          (b2 << 48) |
          (b3 << 40) |
          (b4 << 32) |
          (b5 << 24) |
          (b6 << 16) |
          (b7 << 8) |
          b8;
    }
  }

  @override
  void setUint64(int byteOffset, int value, [Endian endian = Endian.big]) {
    _offsetRangeCheck(byteOffset, 8);
    _setUint64Unchecked(byteOffset, value, endian);
  }

  void _setUint64Unchecked(int byteOffset, int value,
      [Endian endian = Endian.big]) {
    final b1 = value & 0xFF;
    final b2 = (value >> 8) & 0xFF;
    final b3 = (value >> 16) & 0xFF;
    final b4 = (value >> 24) & 0xFF;
    final b5 = (value >> 32) & 0xFF;
    final b6 = (value >> 40) & 0xFF;
    final b7 = (value >> 48) & 0xFF;
    final b8 = (value >> 56) & 0xFF;
    if (endian == Endian.little) {
      _setUint8Unchecked(byteOffset, b1);
      _setUint8Unchecked(byteOffset + 1, b2);
      _setUint8Unchecked(byteOffset + 2, b3);
      _setUint8Unchecked(byteOffset + 3, b4);
      _setUint8Unchecked(byteOffset + 4, b5);
      _setUint8Unchecked(byteOffset + 5, b6);
      _setUint8Unchecked(byteOffset + 6, b7);
      _setUint8Unchecked(byteOffset + 7, b8);
    } else {
      _setUint8Unchecked(byteOffset, b8);
      _setUint8Unchecked(byteOffset + 1, b7);
      _setUint8Unchecked(byteOffset + 2, b6);
      _setUint8Unchecked(byteOffset + 3, b5);
      _setUint8Unchecked(byteOffset + 4, b4);
      _setUint8Unchecked(byteOffset + 5, b3);
      _setUint8Unchecked(byteOffset + 6, b2);
      _setUint8Unchecked(byteOffset + 7, b1);
    }
  }

  @override
  double getFloat32(int byteOffset, [Endian endian = Endian.big]) {
    _offsetRangeCheck(byteOffset, 4);
    return _getFloat32Unchecked(byteOffset, endian);
  }

  double _getFloat32Unchecked(int byteOffset, [Endian endian = Endian.big]) {
    return intBitsToFloat(_getUint32Unchecked(byteOffset, endian));
  }

  @override
  void setFloat32(int byteOffset, double value, [Endian endian = Endian.big]) {
    _offsetRangeCheck(byteOffset, 4);
    _setFloat32Unchecked(byteOffset, value, endian);
  }

  void _setFloat32Unchecked(int byteOffset, double value,
      [Endian endian = Endian.big]) {
    _setUint32Unchecked(byteOffset, floatToIntBits(value), endian);
  }

  @override
  double getFloat64(int byteOffset, [Endian endian = Endian.big]) {
    _offsetRangeCheck(byteOffset, 8);
    return _getFloat64Unchecked(byteOffset, endian);
  }

  double _getFloat64Unchecked(int byteOffset, [Endian endian = Endian.big]) {
    return intBitsToDouble(_getUint64Unchecked(byteOffset, endian));
  }

  @override
  void setFloat64(int byteOffset, double value, [Endian endian = Endian.big]) {
    _offsetRangeCheck(byteOffset, 8);
    _setFloat64Unchecked(byteOffset, value, endian);
  }

  void _setFloat64Unchecked(int byteOffset, double value,
      [Endian endian = Endian.big]) {
    _setUint64Unchecked(byteOffset, doubleToIntBits(value), endian);
  }
}

mixin _UnmodifiableByteDataMixin on ByteDataBase {
  @override
  void setInt8(int byteOffset, int value) {
    throw UnsupportedError("Cannot modify an unmodifiable byte data");
  }

  @override
  void setUint8(int byteOffset, int value) {
    throw UnsupportedError("Cannot modify an unmodifiable byte data");
  }

  @override
  void setInt16(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw UnsupportedError("Cannot modify an unmodifiable byte data");
  }

  @override
  void setUint16(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw UnsupportedError("Cannot modify an unmodifiable byte data");
  }

  @override
  void setInt32(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw UnsupportedError("Cannot modify an unmodifiable byte data");
  }

  @override
  void setUint32(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw UnsupportedError("Cannot modify an unmodifiable byte data");
  }

  @override
  void setInt64(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw UnsupportedError("Cannot modify an unmodifiable byte data");
  }

  @override
  void setUint64(int byteOffset, int value, [Endian endian = Endian.big]) {
    throw UnsupportedError("Cannot modify an unmodifiable byte data");
  }

  @override
  void setFloat32(int byteOffset, double value, [Endian endian = Endian.big]) {
    throw UnsupportedError("Cannot modify an unmodifiable byte data");
  }

  @override
  void setFloat64(int byteOffset, double value, [Endian endian = Endian.big]) {
    throw UnsupportedError("Cannot modify an unmodifiable byte data");
  }
}

class I8ByteData extends ByteDataBase {
  final WasmArray<WasmI8> _data;

  I8ByteData(int length)
      : _data = WasmArray(_newArrayLengthCheck(length)),
        super(0, length);

  I8ByteData._(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  factory I8ByteData._withMutability(WasmArray<WasmI8> data, int offsetInBytes,
          int lengthInBytes, bool mutable) =>
      mutable
          ? I8ByteData._(data, offsetInBytes, lengthInBytes)
          : _UnmodifiableI8ByteData._(data, offsetInBytes, lengthInBytes);

  @override
  _UnmodifiableI8ByteData asUnmodifiableView() =>
      _UnmodifiableI8ByteData._(_data, offsetInBytes, lengthInBytes);

  @override
  _I8ByteBuffer get buffer => _I8ByteBuffer(_data);

  @override
  int get elementSizeInBytes => Int8List.bytesPerElement;

  @override
  int _getUint8Unchecked(int byteOffset) {
    return _data.readUnsigned(offsetInBytes + byteOffset);
  }

  @override
  void _setUint8Unchecked(int byteOffset, int value) {
    _data.write(offsetInBytes + byteOffset, value.toUnsigned(8));
  }
}

class _I16ByteData extends ByteDataBase {
  final WasmArray<WasmI16> _data;

  _I16ByteData._(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  factory _I16ByteData._withMutability(WasmArray<WasmI16> data,
          int offsetInBytes, int lengthInBytes, bool mutable) =>
      mutable
          ? _I16ByteData._(data, offsetInBytes, lengthInBytes)
          : _UnmodifiableI16ByteData._(data, offsetInBytes, lengthInBytes);

  @override
  _UnmodifiableI16ByteData asUnmodifiableView() =>
      _UnmodifiableI16ByteData._(_data, offsetInBytes, lengthInBytes);

  @override
  _I16ByteBuffer get buffer => _I16ByteBuffer(_data);

  @override
  int get elementSizeInBytes => Int16List.bytesPerElement;

  @override
  int _getUint8Unchecked(int byteOffset) {
    byteOffset += offsetInBytes;
    final byteIndex = byteOffset ~/ elementSizeInBytes;
    return (_data.readUnsigned(byteIndex) >> (8 * (byteOffset & 1))) & 0xFF;
  }

  @override
  void _setUint8Unchecked(int byteOffset, int value) {
    byteOffset += offsetInBytes;
    final byteIndex = byteOffset ~/ elementSizeInBytes;
    final element = _data.readUnsigned(byteIndex);
    final byteElementIndex = byteOffset & 1;
    final b1 = byteElementIndex == 0 ? value : (element & 0xFF);
    final b2 = byteElementIndex == 1 ? value : (element >> 8);
    final newValue = (b2 << 8) | b1;
    _data.write(byteIndex, newValue);
  }

  @override
  int _getUint16Unchecked(int byteOffset, [Endian endian = Endian.big]) {
    final totalOffset = offsetInBytes + byteOffset;
    if (totalOffset & 1 == 0 && endian == Endian.little) {
      return _data.readUnsigned(totalOffset ~/ elementSizeInBytes);
    } else {
      return super._getUint16Unchecked(byteOffset, endian);
    }
  }

  @override
  void _setUint16Unchecked(int byteOffset, int value,
      [Endian endian = Endian.big]) {
    final totalOffset = offsetInBytes + byteOffset;
    if (totalOffset & 1 == 0 && endian == Endian.little) {
      _data.write(totalOffset ~/ elementSizeInBytes, value);
    } else {
      super._setUint16Unchecked(byteOffset, value, endian);
    }
  }
}

class _I32ByteData extends ByteDataBase {
  final WasmArray<WasmI32> _data;

  _I32ByteData._(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  factory _I32ByteData._withMutability(WasmArray<WasmI32> data,
          int offsetInBytes, int lengthInBytes, bool mutable) =>
      mutable
          ? _I32ByteData._(data, offsetInBytes, lengthInBytes)
          : _UnmodifiableI32ByteData._(data, offsetInBytes, lengthInBytes);

  @override
  _UnmodifiableI32ByteData asUnmodifiableView() =>
      _UnmodifiableI32ByteData._(_data, offsetInBytes, lengthInBytes);

  @override
  _I32ByteBuffer get buffer => _I32ByteBuffer(_data);

  @override
  int get elementSizeInBytes => Int32List.bytesPerElement;

  @override
  int _getUint8Unchecked(int byteOffset) {
    byteOffset += offsetInBytes;
    final byteIndex = byteOffset ~/ elementSizeInBytes;
    return (_data.readUnsigned(byteIndex) >> (8 * (byteOffset & 3))) & 0xFF;
  }

  @override
  void _setUint8Unchecked(int byteOffset, int value) {
    byteOffset += offsetInBytes;
    final byteIndex = byteOffset ~/ elementSizeInBytes;
    final element = _data.readUnsigned(byteIndex);
    final byteElementIndex = byteOffset & 3;
    final b1 = byteElementIndex == 0 ? value : (element & 0xFF);
    final b2 = byteElementIndex == 1 ? value : ((element >> 8) & 0xFF);
    final b3 = byteElementIndex == 2 ? value : ((element >> 16) & 0xFF);
    final b4 = byteElementIndex == 3 ? value : ((element >> 24) & 0xFF);
    final newValue = (b4 << 24) | (b3 << 16) | (b2 << 8) | b1;
    _data.write(byteIndex, newValue);
  }

  @override
  int _getInt32Unchecked(int byteOffset, [Endian endian = Endian.big]) {
    final totalOffset = offsetInBytes + byteOffset;
    if (totalOffset & 3 == 0 && endian == Endian.little) {
      return _data.readSigned(totalOffset ~/ elementSizeInBytes);
    } else {
      return super._getInt32Unchecked(byteOffset, endian);
    }
  }

  @override
  int _getUint32Unchecked(int byteOffset, [Endian endian = Endian.big]) {
    final totalOffset = offsetInBytes + byteOffset;
    if (totalOffset & 3 == 0 && endian == Endian.little) {
      return _data.readUnsigned(totalOffset ~/ elementSizeInBytes);
    } else {
      return super._getUint32Unchecked(byteOffset, endian);
    }
  }

  @override
  void _setInt32Unchecked(int byteOffset, int value,
      [Endian endian = Endian.big]) {
    final totalOffset = offsetInBytes + byteOffset;
    if (totalOffset & 3 == 0 && endian == Endian.little) {
      _data.write(totalOffset ~/ elementSizeInBytes, value.toUnsigned(32));
    } else {
      super._setInt32Unchecked(byteOffset, value, endian);
    }
  }

  @override
  void _setUint32Unchecked(int byteOffset, int value,
      [Endian endian = Endian.big]) {
    final totalOffset = offsetInBytes + byteOffset;
    if (totalOffset & 3 == 0 && endian == Endian.little) {
      _data.write(totalOffset ~/ elementSizeInBytes, value);
    } else {
      super._setUint32Unchecked(byteOffset, value, endian);
    }
  }
}

class _I64ByteData extends ByteDataBase {
  final WasmArray<WasmI64> _data;

  _I64ByteData._(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  factory _I64ByteData._withMutability(WasmArray<WasmI64> data,
          int offsetInBytes, int lengthInBytes, bool mutable) =>
      mutable
          ? _I64ByteData._(data, offsetInBytes, lengthInBytes)
          : _UnmodifiableI64ByteData._(data, offsetInBytes, lengthInBytes);

  @override
  _UnmodifiableI64ByteData asUnmodifiableView() =>
      _UnmodifiableI64ByteData._(_data, offsetInBytes, lengthInBytes);

  @override
  _I64ByteBuffer get buffer => _I64ByteBuffer(_data);

  @override
  int get elementSizeInBytes => Int64List.bytesPerElement;

  @override
  int _getUint8Unchecked(int byteOffset) {
    byteOffset += offsetInBytes;
    final byteIndex = byteOffset ~/ elementSizeInBytes;
    return (_data.read(byteIndex) >> (8 * (byteOffset & 7))) & 0xFF;
  }

  @override
  void _setUint8Unchecked(int byteOffset, int value) {
    byteOffset += offsetInBytes;
    final byteIndex = byteOffset ~/ elementSizeInBytes;
    final element = _data.read(byteIndex);
    final byteElementIndex = byteOffset & 7;
    final b1 = byteElementIndex == 0 ? value : (element & 0xFF);
    final b2 = byteElementIndex == 1 ? value : ((element >> 8) & 0xFF);
    final b3 = byteElementIndex == 2 ? value : ((element >> 16) & 0xFF);
    final b4 = byteElementIndex == 3 ? value : ((element >> 24) & 0xFF);
    final b5 = byteElementIndex == 4 ? value : ((element >> 32) & 0xFF);
    final b6 = byteElementIndex == 5 ? value : ((element >> 40) & 0xFF);
    final b7 = byteElementIndex == 6 ? value : ((element >> 48) & 0xFF);
    final b8 = byteElementIndex == 7 ? value : ((element >> 56) & 0xFF);
    final newValue = (b8 << 56) |
        (b7 << 48) |
        (b6 << 40) |
        (b5 << 32) |
        (b4 << 24) |
        (b3 << 16) |
        (b2 << 8) |
        b1;
    _data.write(byteIndex, newValue);
  }

  @override
  int _getInt64Unchecked(int byteOffset, [Endian endian = Endian.big]) {
    final totalOffset = offsetInBytes + byteOffset;
    if (totalOffset & 7 == 0 && endian == Endian.little) {
      return _data.read(totalOffset ~/ elementSizeInBytes);
    } else {
      return super._getInt64Unchecked(byteOffset, endian);
    }
  }

  @override
  int _getUint64Unchecked(int byteOffset, [Endian endian = Endian.big]) {
    final totalOffset = offsetInBytes + byteOffset;
    if (totalOffset & 7 == 0 && endian == Endian.little) {
      return _data.read(totalOffset ~/ elementSizeInBytes);
    } else {
      return super._getUint64Unchecked(byteOffset, endian);
    }
  }

  @override
  void _setInt64Unchecked(int byteOffset, int value,
      [Endian endian = Endian.big]) {
    final totalOffset = offsetInBytes + byteOffset;
    if (totalOffset & 7 == 0 && endian == Endian.little) {
      _data.write(totalOffset ~/ elementSizeInBytes, value);
    } else {
      super._setInt64Unchecked(byteOffset, value, endian);
    }
  }

  @override
  void _setUint64Unchecked(int byteOffset, int value,
      [Endian endian = Endian.big]) {
    final totalOffset = offsetInBytes + byteOffset;
    if (totalOffset & 7 == 0 && endian == Endian.little) {
      _data.write(totalOffset ~/ elementSizeInBytes, value);
    } else {
      super._setUint64Unchecked(byteOffset, value, endian);
    }
  }
}

class _F32ByteData extends ByteDataBase {
  final WasmArray<WasmF32> _data;

  _F32ByteData._(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  factory _F32ByteData._withMutability(WasmArray<WasmF32> data,
          int offsetInBytes, int lengthInBytes, bool mutable) =>
      mutable
          ? _F32ByteData._(data, offsetInBytes, lengthInBytes)
          : _UnmodifiableF32ByteData._(data, offsetInBytes, lengthInBytes);

  @override
  _UnmodifiableF32ByteData asUnmodifiableView() =>
      _UnmodifiableF32ByteData._(_data, offsetInBytes, lengthInBytes);

  @override
  _F32ByteBuffer get buffer => _F32ByteBuffer(_data);

  @override
  int get elementSizeInBytes => Float32List.bytesPerElement;

  @override
  int _getUint8Unchecked(int byteOffset) {
    byteOffset += offsetInBytes;
    final byteIndex = byteOffset ~/ elementSizeInBytes;
    final word = floatToIntBits(_data.read(byteIndex));
    return (word >> (8 * (byteOffset & 3))) & 0xFF;
  }

  @override
  void _setUint8Unchecked(int byteOffset, int value) {
    byteOffset += offsetInBytes;
    final byteIndex = byteOffset ~/ elementSizeInBytes;
    final element = floatToIntBits(_data.read(byteIndex));
    final byteElementIndex = byteOffset & 3;
    final b1 = byteElementIndex == 0 ? value : (element & 0xFF);
    final b2 = byteElementIndex == 1 ? value : ((element >> 8) & 0xFF);
    final b3 = byteElementIndex == 2 ? value : ((element >> 16) & 0xFF);
    final b4 = byteElementIndex == 3 ? value : ((element >> 24) & 0xFF);
    final newValue = (b4 << 24) | (b3 << 16) | (b2 << 8) | b1;
    _data.write(byteIndex, intBitsToFloat(newValue));
  }

  @override
  double _getFloat32Unchecked(int byteOffset, [Endian endian = Endian.big]) {
    final totalOffset = offsetInBytes + byteOffset;
    if (totalOffset & 3 == 0 && endian == Endian.little) {
      return _data.read(totalOffset ~/ elementSizeInBytes);
    } else {
      return super._getFloat32Unchecked(byteOffset, endian);
    }
  }

  @override
  void _setFloat32Unchecked(int byteOffset, double value,
      [Endian endian = Endian.big]) {
    final totalOffset = offsetInBytes + byteOffset;
    if (totalOffset & 3 == 0 && endian == Endian.little) {
      _data.write(totalOffset ~/ elementSizeInBytes, value);
    } else {
      super._setFloat32Unchecked(byteOffset, value, endian);
    }
  }
}

class _F64ByteData extends ByteDataBase {
  final WasmArray<WasmF64> _data;

  _F64ByteData._(this._data, int offsetInBytes, int lengthInBytes)
      : super(offsetInBytes, lengthInBytes);

  factory _F64ByteData._withMutability(WasmArray<WasmF64> data,
          int offsetInBytes, int lengthInBytes, bool mutable) =>
      mutable
          ? _F64ByteData._(data, offsetInBytes, lengthInBytes)
          : _UnmodifiableF64ByteData._(data, offsetInBytes, lengthInBytes);

  @override
  _UnmodifiableF64ByteData asUnmodifiableView() =>
      _UnmodifiableF64ByteData._(_data, offsetInBytes, lengthInBytes);

  @override
  _F64ByteBuffer get buffer => _F64ByteBuffer(_data);

  @override
  int get elementSizeInBytes => Float64List.bytesPerElement;

  @override
  int _getUint8Unchecked(int byteOffset) {
    byteOffset += offsetInBytes;
    final byteIndex = byteOffset ~/ elementSizeInBytes;
    final word = doubleToIntBits(_data.read(byteIndex));
    return (word >> (8 * (byteOffset & 7))) & 0xFF;
  }

  @override
  void _setUint8Unchecked(int byteOffset, int value) {
    byteOffset += offsetInBytes;
    final byteIndex = byteOffset ~/ elementSizeInBytes;
    final element = doubleToIntBits(_data.read(byteIndex));
    final byteElementIndex = byteOffset & 7;
    final b1 = byteElementIndex == 0 ? value : (element & 0xFF);
    final b2 = byteElementIndex == 1 ? value : ((element >> 8) & 0xFF);
    final b3 = byteElementIndex == 2 ? value : ((element >> 16) & 0xFF);
    final b4 = byteElementIndex == 3 ? value : ((element >> 24) & 0xFF);
    final b5 = byteElementIndex == 4 ? value : ((element >> 32) & 0xFF);
    final b6 = byteElementIndex == 5 ? value : ((element >> 40) & 0xFF);
    final b7 = byteElementIndex == 6 ? value : ((element >> 48) & 0xFF);
    final b8 = byteElementIndex == 7 ? value : ((element >> 56) & 0xFF);
    final newValue = (b8 << 56) |
        (b7 << 48) |
        (b6 << 40) |
        (b5 << 32) |
        (b4 << 24) |
        (b3 << 16) |
        (b2 << 8) |
        b1;
    _data.write(byteIndex, intBitsToDouble(newValue));
  }

  @override
  double _getFloat64Unchecked(int byteOffset, [Endian endian = Endian.big]) {
    final totalOffset = offsetInBytes + byteOffset;
    if (totalOffset & 7 == 0 && endian == Endian.little) {
      return _data.read(totalOffset ~/ elementSizeInBytes);
    } else {
      return super._getFloat64Unchecked(byteOffset, endian);
    }
  }

  @override
  void _setFloat64Unchecked(int byteOffset, double value,
      [Endian endian = Endian.big]) {
    final totalOffset = offsetInBytes + byteOffset;
    if (totalOffset & 7 == 0 && endian == Endian.little) {
      _data.write(totalOffset ~/ elementSizeInBytes, value);
    } else {
      super._setFloat64Unchecked(byteOffset, value, endian);
    }
  }
}

class _UnmodifiableI8ByteData extends I8ByteData
    with _UnmodifiableByteDataMixin {
  _UnmodifiableI8ByteData._(
      WasmArray<WasmI8> _data, int offsetInBytes, int lengthInBytes)
      : super._(_data, offsetInBytes, lengthInBytes);

  @override
  _I8ByteBuffer get buffer => _I8ByteBuffer._(_data, false);
}

class _UnmodifiableI16ByteData extends _I16ByteData
    with _UnmodifiableByteDataMixin {
  _UnmodifiableI16ByteData._(
      WasmArray<WasmI16> _data, int offsetInBytes, int lengthInBytes)
      : super._(_data, offsetInBytes, lengthInBytes);

  @override
  _I16ByteBuffer get buffer => _I16ByteBuffer._(_data, false);
}

class _UnmodifiableI32ByteData extends _I32ByteData
    with _UnmodifiableByteDataMixin {
  _UnmodifiableI32ByteData._(
      WasmArray<WasmI32> _data, int offsetInBytes, int lengthInBytes)
      : super._(_data, offsetInBytes, lengthInBytes);

  @override
  _I32ByteBuffer get buffer => _I32ByteBuffer._(_data, false);
}

class _UnmodifiableI64ByteData extends _I64ByteData
    with _UnmodifiableByteDataMixin {
  _UnmodifiableI64ByteData._(
      WasmArray<WasmI64> _data, int offsetInBytes, int lengthInBytes)
      : super._(_data, 0, _data.length * 8);

  @override
  _I64ByteBuffer get buffer => _I64ByteBuffer._(_data, false);
}

class _UnmodifiableF32ByteData extends _F32ByteData
    with _UnmodifiableByteDataMixin {
  _UnmodifiableF32ByteData._(
      WasmArray<WasmF32> _data, int offsetInBytes, int lengthInBytes)
      : super._(_data, offsetInBytes, lengthInBytes);

  @override
  _F32ByteBuffer get buffer => _F32ByteBuffer._(_data, false);
}

class _UnmodifiableF64ByteData extends _F64ByteData
    with _UnmodifiableByteDataMixin {
  _UnmodifiableF64ByteData._(
      WasmArray<WasmF64> _data, int offsetInBytes, int lengthInBytes)
      : super._(_data, offsetInBytes, lengthInBytes);

  @override
  _F64ByteBuffer get buffer => _F64ByteBuffer._(_data, false);
}

//
// Byte buffers
//

/// Base class for [ByteBuffer] implementations. Returns slow lists in all
/// methods. Implementations should override relevant methods to return fast
/// lists when possible and implement [asByteData].
abstract class ByteBufferBase extends WasmTypedDataBase implements ByteBuffer {
  final int lengthInBytes;
  final bool _mutable;

  ByteBufferBase(this.lengthInBytes, this._mutable);

  ByteBufferBase _immutable();

  @override
  Uint8List asUint8List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Uint8List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Uint8List.bytesPerElement);
    return _SlowU8List._withMutability(this, offsetInBytes, length, _mutable);
  }

  @override
  Int8List asInt8List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Int8List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Int8List.bytesPerElement);
    return _SlowI8List._withMutability(this, offsetInBytes, length, _mutable);
  }

  @override
  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int? length]) {
    length ??=
        (lengthInBytes - offsetInBytes) ~/ Uint8ClampedList.bytesPerElement;
    _rangeCheck(lengthInBytes, offsetInBytes,
        length * Uint8ClampedList.bytesPerElement);
    return _SlowU8ClampedList._withMutability(
        this, offsetInBytes, length, _mutable);
  }

  @override
  Uint16List asUint16List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Uint16List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Uint16List.bytesPerElement);
    _offsetAlignmentCheck(offsetInBytes, Uint16List.bytesPerElement);
    return _SlowU16List._withMutability(this, offsetInBytes, length, _mutable);
  }

  @override
  Int16List asInt16List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Int16List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Int16List.bytesPerElement);
    _offsetAlignmentCheck(offsetInBytes, Int16List.bytesPerElement);
    return _SlowI16List._withMutability(this, offsetInBytes, length, _mutable);
  }

  @override
  Uint32List asUint32List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Uint32List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Uint32List.bytesPerElement);
    _offsetAlignmentCheck(offsetInBytes, Uint32List.bytesPerElement);
    return _SlowU32List._withMutability(this, offsetInBytes, length, _mutable);
  }

  @override
  Int32List asInt32List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Int32List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Int32List.bytesPerElement);
    _offsetAlignmentCheck(offsetInBytes, Int32List.bytesPerElement);
    return _SlowI32List._withMutability(this, offsetInBytes, length, _mutable);
  }

  @override
  Uint64List asUint64List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Uint64List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Uint64List.bytesPerElement);
    _offsetAlignmentCheck(offsetInBytes, Uint64List.bytesPerElement);
    return _SlowU64List._withMutability(this, offsetInBytes, length, _mutable);
  }

  @override
  Int64List asInt64List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Int64List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Int64List.bytesPerElement);
    _offsetAlignmentCheck(offsetInBytes, Int64List.bytesPerElement);
    return _SlowI64List._withMutability(this, offsetInBytes, length, _mutable);
  }

  @override
  Int32x4List asInt32x4List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Int32x4List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Int32x4List.bytesPerElement);
    _offsetAlignmentCheck(offsetInBytes, Int32x4List.bytesPerElement);
    // TODO: mutability
    return NaiveInt32x4List.externalStorage(
        _SlowI32List._(this, offsetInBytes, length * 4));
  }

  @override
  Float32List asFloat32List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Float32List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Float32List.bytesPerElement);
    _offsetAlignmentCheck(offsetInBytes, Float32List.bytesPerElement);
    return _SlowF32List._withMutability(this, offsetInBytes, length, _mutable);
  }

  @override
  Float64List asFloat64List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Float64List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Float64List.bytesPerElement);
    _offsetAlignmentCheck(offsetInBytes, Float64List.bytesPerElement);
    return SlowF64List._withMutability(this, offsetInBytes, length, _mutable);
  }

  @override
  Float32x4List asFloat32x4List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Float32x4List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Float32x4List.bytesPerElement);
    _offsetAlignmentCheck(offsetInBytes, Float32x4List.bytesPerElement);
    // TODO: mutability
    return NaiveFloat32x4List.externalStorage(
        _SlowF32List._(this, offsetInBytes, length * 4));
  }

  @override
  Float64x2List asFloat64x2List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Float64x2List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Float64x2List.bytesPerElement);
    _offsetAlignmentCheck(offsetInBytes, Float64x2List.bytesPerElement);
    // TODO: mutability
    return NaiveFloat64x2List.externalStorage(
        SlowF64List._(this, offsetInBytes, length * 2));
  }
}

class _I8ByteBuffer extends ByteBufferBase {
  final WasmArray<WasmI8> _data;

  _I8ByteBuffer(this._data) : super(_data.length, true);

  _I8ByteBuffer._(this._data, bool mutable) : super(_data.length, mutable);

  @override
  _I8ByteBuffer _immutable() => _I8ByteBuffer._(_data, false);

  @override
  bool operator ==(Object other) =>
      other is _I8ByteBuffer && identical(_data, other._data);

  @override
  Int8List asInt8List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Int8List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Int8List.bytesPerElement);
    return I8List._withMutability(_data, offsetInBytes, length, _mutable);
  }

  @override
  Uint8List asUint8List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Uint8List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Uint8List.bytesPerElement);
    return U8List._withMutability(_data, offsetInBytes, length, _mutable);
  }

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) {
    length ??= lengthInBytes - offsetInBytes;
    _rangeCheck(lengthInBytes, offsetInBytes, length);
    return I8ByteData._withMutability(_data, offsetInBytes, length, _mutable);
  }
}

class _I16ByteBuffer extends ByteBufferBase {
  final WasmArray<WasmI16> _data;

  _I16ByteBuffer(this._data) : super(_data.length * 2, true);

  _I16ByteBuffer._(this._data, bool mutable) : super(_data.length * 2, mutable);

  @override
  _I16ByteBuffer _immutable() => _I16ByteBuffer._(_data, false);

  @override
  bool operator ==(Object other) =>
      other is _I16ByteBuffer && identical(_data, other._data);

  @override
  Int16List asInt16List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Int16List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Int16List.bytesPerElement);
    _offsetAlignmentCheck(offsetInBytes, Int16List.bytesPerElement);
    return I16List._withMutability(
        _data, offsetInBytes ~/ Int16List.bytesPerElement, length, _mutable);
  }

  @override
  Uint16List asUint16List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Uint16List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Uint16List.bytesPerElement);
    _offsetAlignmentCheck(offsetInBytes, Uint16List.bytesPerElement);
    return U16List._withMutability(
        _data, offsetInBytes ~/ Uint16List.bytesPerElement, length, _mutable);
  }

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) {
    length ??= lengthInBytes - offsetInBytes;
    _rangeCheck(lengthInBytes, offsetInBytes, length);
    return _I16ByteData._withMutability(_data, offsetInBytes, length, _mutable);
  }
}

class _I32ByteBuffer extends ByteBufferBase {
  final WasmArray<WasmI32> _data;

  _I32ByteBuffer(this._data) : super(_data.length * 4, true);

  _I32ByteBuffer._(this._data, bool mutable) : super(_data.length * 4, mutable);

  @override
  _I32ByteBuffer _immutable() => _I32ByteBuffer._(_data, false);

  @override
  bool operator ==(Object other) =>
      other is _I32ByteBuffer && identical(_data, other._data);

  @override
  Int32List asInt32List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Int32List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Int32List.bytesPerElement);
    _offsetAlignmentCheck(offsetInBytes, Int32List.bytesPerElement);
    return I32List._withMutability(
        _data, offsetInBytes ~/ Int32List.bytesPerElement, length, _mutable);
  }

  @override
  Uint32List asUint32List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Uint32List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Uint32List.bytesPerElement);
    _offsetAlignmentCheck(offsetInBytes, Uint32List.bytesPerElement);
    return U32List._withMutability(
        _data, offsetInBytes ~/ Uint32List.bytesPerElement, length, _mutable);
  }

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) {
    length ??= lengthInBytes - offsetInBytes;
    _rangeCheck(lengthInBytes, offsetInBytes, length);
    return _I32ByteData._withMutability(_data, offsetInBytes, length, _mutable);
  }
}

class _I64ByteBuffer extends ByteBufferBase {
  final WasmArray<WasmI64> _data;

  _I64ByteBuffer(this._data) : super(_data.length * 8, true);

  _I64ByteBuffer._(this._data, bool mutable) : super(_data.length * 8, mutable);

  @override
  _I64ByteBuffer _immutable() => _I64ByteBuffer._(_data, false);

  @override
  bool operator ==(Object other) =>
      other is _I64ByteBuffer && identical(_data, other._data);

  @override
  Int64List asInt64List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Int64List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Int64List.bytesPerElement);
    _offsetAlignmentCheck(offsetInBytes, Int64List.bytesPerElement);
    return I64List._withMutability(
        _data, offsetInBytes ~/ Int64List.bytesPerElement, length, _mutable);
  }

  @override
  Uint64List asUint64List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Int64List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Uint64List.bytesPerElement);
    _offsetAlignmentCheck(offsetInBytes, Uint64List.bytesPerElement);
    return U64List._withMutability(
        _data, offsetInBytes ~/ Uint64List.bytesPerElement, length, _mutable);
  }

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) {
    length ??= lengthInBytes - offsetInBytes;
    _rangeCheck(lengthInBytes, offsetInBytes, length);
    return _I64ByteData._withMutability(_data, offsetInBytes, length, _mutable);
  }
}

class _F32ByteBuffer extends ByteBufferBase {
  final WasmArray<WasmF32> _data;

  _F32ByteBuffer(this._data) : super(_data.length * 4, true);

  _F32ByteBuffer._(this._data, bool mutable) : super(_data.length * 4, mutable);

  @override
  _F32ByteBuffer _immutable() => _F32ByteBuffer._(_data, false);

  @override
  bool operator ==(Object other) =>
      other is _F32ByteBuffer && identical(_data, other._data);

  @override
  Float32List asFloat32List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Float32List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Float32List.bytesPerElement);
    _offsetAlignmentCheck(offsetInBytes, Float32List.bytesPerElement);
    return F32List._withMutability(
        _data, offsetInBytes ~/ Float32List.bytesPerElement, length, _mutable);
  }

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) {
    length ??= lengthInBytes - offsetInBytes;
    _rangeCheck(lengthInBytes, offsetInBytes, length);
    return _F32ByteData._withMutability(_data, offsetInBytes, length, _mutable);
  }
}

class _F64ByteBuffer extends ByteBufferBase {
  final WasmArray<WasmF64> _data;

  _F64ByteBuffer(this._data) : super(_data.length * 8, true);

  _F64ByteBuffer._(this._data, bool mutable) : super(_data.length * 8, mutable);

  @override
  _F64ByteBuffer _immutable() => _F64ByteBuffer._(_data, false);

  @override
  bool operator ==(Object other) =>
      other is _F64ByteBuffer && identical(_data, other._data);

  @override
  Float64List asFloat64List([int offsetInBytes = 0, int? length]) {
    length ??= (lengthInBytes - offsetInBytes) ~/ Float64List.bytesPerElement;
    _rangeCheck(
        lengthInBytes, offsetInBytes, length * Float64List.bytesPerElement);
    _offsetAlignmentCheck(offsetInBytes, Float64List.bytesPerElement);
    return F64List._withMutability(
        _data, offsetInBytes ~/ Int64List.bytesPerElement, length, _mutable);
  }

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) {
    length ??= lengthInBytes - offsetInBytes;
    _rangeCheck(lengthInBytes, offsetInBytes, length);
    return _F64ByteData._withMutability(_data, offsetInBytes, length, _mutable);
  }
}

class UnmodifiableByteBuffer extends WasmTypedDataBase implements ByteBuffer {
  final ByteBufferBase _buffer;

  UnmodifiableByteBuffer(ByteBufferBase buffer) : _buffer = buffer._immutable();

  @override
  int get lengthInBytes => _buffer.lengthInBytes;

  @override
  Uint8List asUint8List([int offsetInBytes = 0, int? length]) =>
      _buffer.asUint8List(offsetInBytes, length);

  @override
  Int8List asInt8List([int offsetInBytes = 0, int? length]) =>
      _buffer.asInt8List(offsetInBytes, length);

  @override
  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int? length]) =>
      _buffer.asUint8ClampedList(offsetInBytes, length);

  @override
  Uint16List asUint16List([int offsetInBytes = 0, int? length]) =>
      _buffer.asUint16List(offsetInBytes, length);

  @override
  Int16List asInt16List([int offsetInBytes = 0, int? length]) =>
      _buffer.asInt16List(offsetInBytes, length);

  @override
  Uint32List asUint32List([int offsetInBytes = 0, int? length]) =>
      _buffer.asUint32List(offsetInBytes, length);

  @override
  Int32List asInt32List([int offsetInBytes = 0, int? length]) =>
      _buffer.asInt32List(offsetInBytes, length);

  @override
  Uint64List asUint64List([int offsetInBytes = 0, int? length]) =>
      _buffer.asUint64List(offsetInBytes, length);

  @override
  Int64List asInt64List([int offsetInBytes = 0, int? length]) =>
      _buffer.asInt64List(offsetInBytes, length);

  @override
  Int32x4List asInt32x4List([int offsetInBytes = 0, int? length]) =>
      _buffer.asInt32x4List(offsetInBytes, length);

  @override
  Float32List asFloat32List([int offsetInBytes = 0, int? length]) =>
      _buffer.asFloat32List(offsetInBytes, length);

  @override
  Float64List asFloat64List([int offsetInBytes = 0, int? length]) =>
      _buffer.asFloat64List(offsetInBytes, length);

  @override
  Float32x4List asFloat32x4List([int offsetInBytes = 0, int? length]) =>
      _buffer.asFloat32x4List(offsetInBytes, length);

  @override
  Float64x2List asFloat64x2List([int offsetInBytes = 0, int? length]) =>
      _buffer.asFloat64x2List(offsetInBytes, length);

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) =>
      _buffer.asByteData(offsetInBytes, length);
}

//
// Mixins
//

mixin _TypedListCommonOperationsMixin {
  int get length;

  int get elementSizeInBytes;

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  int get lengthInBytes => elementSizeInBytes * length;

  @override
  String join([String separator = ""]) {
    StringBuffer buffer = StringBuffer();
    buffer.writeAll(this as Iterable, separator);
    return buffer.toString();
  }

  @override
  void clear() {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  @override
  bool remove(Object? element) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  @override
  void removeRange(int start, int end) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  @override
  void replaceRange(int start, int end, Iterable iterable) {
    throw UnsupportedError("Cannot remove from a fixed-length list");
  }

  @override
  set length(int newLength) {
    throw UnsupportedError("Cannot resize a fixed-length list");
  }

  @override
  String toString() => ListBase.listToString(this as List);
}

mixin _IntListMixin implements TypedDataList<int> {
  Iterable<T> whereType<T>() => WhereTypeIterable<T>(this);

  Iterable<int> followedBy(Iterable<int> other) =>
      FollowedByIterable<int>.firstEfficient(this, other);

  List<R> cast<R>() => List.castFrom<int, R>(this);
  void set first(int value) {
    if (this.length == 0) {
      throw IndexError.withLength(0, length, indexable: this);
    }
    this[0] = value;
  }

  void set last(int value) {
    if (this.length == 0) {
      throw IndexError.withLength(0, length, indexable: this);
    }
    this[this.length - 1] = value;
  }

  int indexWhere(bool test(int element), [int start = 0]) {
    if (start < 0) start = 0;
    for (int i = start; i < length; i++) {
      if (test(this[i])) return i;
    }
    return -1;
  }

  int lastIndexWhere(bool test(int element), [int? start]) {
    int startIndex =
        (start == null || start >= this.length) ? this.length - 1 : start;
    for (int i = startIndex; i >= 0; i--) {
      if (test(this[i])) return i;
    }
    return -1;
  }

  List<int> operator +(List<int> other) => [...this, ...other];

  bool contains(Object? element) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (this[i] == element) return true;
    }
    return false;
  }

  void shuffle([Random? random]) {
    random ??= Random();
    var i = this.length;
    while (i > 1) {
      int pos = random.nextInt(i);
      i -= 1;
      var tmp = this[i];
      this[i] = this[pos];
      this[pos] = tmp;
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

  Iterator<int> get iterator => _TypedListIterator<int>(this);

  List<int> toList({bool growable = true}) {
    return List<int>.from(this, growable: growable);
  }

  Set<int> toSet() {
    return Set<int>.from(this);
  }

  void forEach(void f(int element)) {
    var len = this.length;
    for (var i = 0; i < len; i++) {
      f(this[i]);
    }
  }

  int reduce(int combine(int value, int element)) {
    var len = this.length;
    if (len == 0) throw IterableElementError.noElement();
    var value = this[0];
    for (var i = 1; i < len; ++i) {
      value = combine(value, this[i]);
    }
    return value;
  }

  T fold<T>(T initialValue, T combine(T initialValue, int element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      initialValue = combine(initialValue, this[i]);
    }
    return initialValue;
  }

  Iterable<T> map<T>(T f(int element)) => MappedIterable<int, T>(this, f);

  Iterable<T> expand<T>(Iterable<T> f(int element)) =>
      ExpandIterable<int, T>(this, f);

  bool every(bool f(int element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (!f(this[i])) return false;
    }
    return true;
  }

  bool any(bool f(int element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (f(this[i])) return true;
    }
    return false;
  }

  int firstWhere(bool test(int element), {int orElse()?}) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      var element = this[i];
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  int lastWhere(bool test(int element), {int orElse()?}) {
    var len = this.length;
    for (var i = len - 1; i >= 0; --i) {
      var element = this[i];
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
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      var element = this[i];
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

  void add(int value) {
    throw UnsupportedError("Cannot add to a fixed-length list");
  }

  void addAll(Iterable<int> value) {
    throw UnsupportedError("Cannot add to a fixed-length list");
  }

  void insert(int index, int value) {
    throw UnsupportedError("Cannot insert into a fixed-length list");
  }

  void insertAll(int index, Iterable<int> values) {
    throw UnsupportedError("Cannot insert into a fixed-length list");
  }

  void sort([int compare(int a, int b)?]) {
    Sort.sort(this, compare ?? Comparable.compare);
  }

  int indexOf(int element, [int start = 0]) {
    if (start >= this.length) {
      return -1;
    } else if (start < 0) {
      start = 0;
    }
    for (int i = start; i < this.length; i++) {
      if (this[i] == element) return i;
    }
    return -1;
  }

  int lastIndexOf(int element, [int? start]) {
    int startIndex =
        (start == null || start >= this.length) ? this.length - 1 : start;
    for (int i = startIndex; i >= 0; i--) {
      if (this[i] == element) return i;
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
    if (length > 0) return this[0];
    throw IterableElementError.noElement();
  }

  int get last {
    if (length > 0) return this[length - 1];
    throw IterableElementError.noElement();
  }

  int get single {
    if (length == 1) return this[0];
    if (length == 0) throw IterableElementError.noElement();
    throw IterableElementError.tooMany();
  }

  void setAll(int index, Iterable<int> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  void fillRange(int start, int end, [int? fillValue]) {
    RangeError.checkValidRange(start, end, this.length);
    if (start == end) return;
    if (fillValue == null) {
      throw ArgumentError.notNull("fillValue");
    }
    for (var i = start; i < end; ++i) {
      this[i] = fillValue;
    }
  }
}

mixin _TypedIntListMixin<SpawnedType extends TypedDataList<int>>
    on _IntListMixin {
  SpawnedType _createList(int length);

  void setRange(int start, int end, Iterable<int> from, [int skipCount = 0]) {
    // Check ranges.
    if (0 > start || start > end || end > length) {
      RangeError.checkValidRange(start, end, length); // Always throws.
    }
    if (skipCount < 0) {
      throw RangeError.range(skipCount, 0, null, "skipCount");
    }

    final count = end - start;
    if ((from.length - skipCount) < count) {
      throw IterableElementError.tooFew();
    }

    if (count == 0) return;

    if (from is TypedData) {
      // We only add this mixin to typed lists in this library so we know
      // `this` is `TypedData`.
      final TypedData destTypedData = this;
      final TypedData fromTypedData = unsafeCast<TypedData>(from);

      final ByteBuffer destBuffer = destTypedData.buffer;
      final ByteBuffer fromBuffer = fromTypedData.buffer;

      final destDartElementSizeInBytes = destTypedData.elementSizeInBytes;
      final fromDartElementSizeInBytes = fromTypedData.elementSizeInBytes;

      final fromBufferByteOffset = fromTypedData.offsetInBytes +
          (skipCount * fromDartElementSizeInBytes);
      final destBufferByteOffset =
          destTypedData.offsetInBytes + (start * destDartElementSizeInBytes);

      // Use `array.copy` when:
      //
      // 1. Dart array element types are the same.
      // 2. Wasm array element sizes are the same.
      // 3. Source and destination offsets are multiples of element size.
      //
      // (1) is to make sure no sign extension, clamping, or truncation needs
      // to happen when copying. (2) and (3) are requirements for `array.copy`.
      //
      // We don't check for `_F32ByteBuffer` and `_F64ByteBuffer` here as the
      // receiver is an int array and if the buffer is a F32/F64 buffer that
      // means casting needs to happen when reading.
      if (destDartElementSizeInBytes == fromDartElementSizeInBytes) {
        if (destDartElementSizeInBytes == 1 &&
            destBuffer is _I8ByteBuffer &&
            fromBuffer is _I8ByteBuffer) {
          if (destTypedData is! U8ClampedList &&
              destTypedData is! _SlowU8ClampedList) {
            destBuffer._data.copy(destBufferByteOffset, fromBuffer._data,
                fromBufferByteOffset, count);
            return;
          }
        } else if (destDartElementSizeInBytes == 2 &&
            destBuffer is _I16ByteBuffer &&
            fromBuffer is _I16ByteBuffer) {
          if (fromBufferByteOffset & 1 == 0 && destBufferByteOffset & 1 == 0) {
            destBuffer._data.copy(destBufferByteOffset ~/ 2, fromBuffer._data,
                fromBufferByteOffset ~/ 2, count);
            return;
          }
        } else if (destDartElementSizeInBytes == 4 &&
            destBuffer is _I32ByteBuffer &&
            fromBuffer is _I32ByteBuffer) {
          if (fromBufferByteOffset & 3 == 0 && destBufferByteOffset & 3 == 0) {
            destBuffer._data.copy(destBufferByteOffset ~/ 4, fromBuffer._data,
                fromBufferByteOffset ~/ 4, count);
            return;
          }
        } else if (destDartElementSizeInBytes == 8 &&
            destBuffer is _I64ByteBuffer &&
            fromBuffer is _I64ByteBuffer) {
          if (fromBufferByteOffset & 7 == 0 && destBufferByteOffset & 7 == 0) {
            destBuffer._data.copy(destBufferByteOffset ~/ 8, fromBuffer._data,
                fromBufferByteOffset ~/ 8, count);
            return;
          }
        }
      }

      // TODO(#52971): Use unchecked list access functions below.
      if (destBuffer == fromBuffer) {
        final fromAsList = from as List<int>;
        final tempBuffer = _createList(count);
        for (var i = 0; i < count; i++) {
          tempBuffer[i] = fromAsList[skipCount + i];
        }
        for (var i = start; i < end; i++) {
          this[i] = tempBuffer[i - start];
        }
        return;
      }
    }

    final List<int> otherList;
    final int otherStart;
    if (from is List<int>) {
      otherList = from;
      otherStart = skipCount;
    } else {
      otherList = from.skip(skipCount).toList(growable: false);
      otherStart = 0;
    }
    Lists.copy(otherList, otherStart, this, start, count);
  }

  SpawnedType sublist(int start, [int? end]) {
    int endIndex = RangeError.checkValidRange(start, end, this.length);
    var length = endIndex - start;
    SpawnedType result = _createList(length);
    result.setRange(0, length, this, start);
    return result;
  }
}

mixin _DoubleListMixin implements TypedDataList<double> {
  Iterable<T> whereType<T>() => WhereTypeIterable<T>(this);

  Iterable<double> followedBy(Iterable<double> other) =>
      FollowedByIterable<double>.firstEfficient(this, other);

  List<R> cast<R>() => List.castFrom<double, R>(this);
  void set first(double value) {
    if (this.length == 0) {
      throw IndexError.withLength(0, length, indexable: this);
    }
    this[0] = value;
  }

  void set last(double value) {
    if (this.length == 0) {
      throw IndexError.withLength(0, length, indexable: this);
    }
    this[this.length - 1] = value;
  }

  int indexWhere(bool test(double element), [int start = 0]) {
    if (start < 0) start = 0;
    for (int i = start; i < length; i++) {
      if (test(this[i])) return i;
    }
    return -1;
  }

  int lastIndexWhere(bool test(double element), [int? start]) {
    int startIndex =
        (start == null || start >= this.length) ? this.length - 1 : start;
    for (int i = startIndex; i >= 0; i--) {
      if (test(this[i])) return i;
    }
    return -1;
  }

  List<double> operator +(List<double> other) => [...this, ...other];

  bool contains(Object? element) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (this[i] == element) return true;
    }
    return false;
  }

  void shuffle([Random? random]) {
    random ??= Random();
    var i = this.length;
    while (i > 1) {
      int pos = random.nextInt(i);
      i -= 1;
      var tmp = this[i];
      this[i] = this[pos];
      this[pos] = tmp;
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

  Iterator<double> get iterator => _TypedListIterator<double>(this);

  List<double> toList({bool growable = true}) {
    return List<double>.from(this, growable: growable);
  }

  Set<double> toSet() {
    return Set<double>.from(this);
  }

  void forEach(void f(double element)) {
    var len = this.length;
    for (var i = 0; i < len; i++) {
      f(this[i]);
    }
  }

  double reduce(double combine(double value, double element)) {
    var len = this.length;
    if (len == 0) throw IterableElementError.noElement();
    var value = this[0];
    for (var i = 1; i < len; ++i) {
      value = combine(value, this[i]);
    }
    return value;
  }

  T fold<T>(T initialValue, T combine(T initialValue, double element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      initialValue = combine(initialValue, this[i]);
    }
    return initialValue;
  }

  Iterable<T> map<T>(T f(double element)) => MappedIterable<double, T>(this, f);

  Iterable<T> expand<T>(Iterable<T> f(double element)) =>
      ExpandIterable<double, T>(this, f);

  bool every(bool f(double element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (!f(this[i])) return false;
    }
    return true;
  }

  bool any(bool f(double element)) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      if (f(this[i])) return true;
    }
    return false;
  }

  double firstWhere(bool test(double element), {double orElse()?}) {
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      var element = this[i];
      if (test(element)) return element;
    }
    if (orElse != null) return orElse();
    throw IterableElementError.noElement();
  }

  double lastWhere(bool test(double element), {double orElse()?}) {
    var len = this.length;
    for (var i = len - 1; i >= 0; --i) {
      var element = this[i];
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
    var len = this.length;
    for (var i = 0; i < len; ++i) {
      var element = this[i];
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

  void add(double value) {
    throw UnsupportedError("Cannot add to a fixed-length list");
  }

  void addAll(Iterable<double> value) {
    throw UnsupportedError("Cannot add to a fixed-length list");
  }

  void insert(int index, double value) {
    throw UnsupportedError("Cannot insert into a fixed-length list");
  }

  void insertAll(int index, Iterable<double> values) {
    throw UnsupportedError("Cannot insert into a fixed-length list");
  }

  void sort([int compare(double a, double b)?]) {
    Sort.sort(this, compare ?? Comparable.compare);
  }

  int indexOf(double element, [int start = 0]) {
    if (start >= this.length) {
      return -1;
    } else if (start < 0) {
      start = 0;
    }
    for (int i = start; i < this.length; i++) {
      if (this[i] == element) return i;
    }
    return -1;
  }

  int lastIndexOf(double element, [int? start]) {
    int startIndex =
        (start == null || start >= this.length) ? this.length - 1 : start;
    for (int i = startIndex; i >= 0; i--) {
      if (this[i] == element) return i;
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
    if (length > 0) return this[0];
    throw IterableElementError.noElement();
  }

  double get last {
    if (length > 0) return this[length - 1];
    throw IterableElementError.noElement();
  }

  double get single {
    if (length == 1) return this[0];
    if (length == 0) throw IterableElementError.noElement();
    throw IterableElementError.tooMany();
  }

  void setAll(int index, Iterable<double> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  void fillRange(int start, int end, [double? fillValue]) {
    // TODO(eernst): Could use zero as default and not throw; issue .
    RangeError.checkValidRange(start, end, this.length);
    if (start == end) return;
    if (fillValue == null) {
      throw ArgumentError.notNull("fillValue");
    }
    for (var i = start; i < end; ++i) {
      this[i] = fillValue;
    }
  }
}

mixin _TypedDoubleListMixin<SpawnedType extends TypedDataList<double>>
    on _DoubleListMixin {
  SpawnedType _createList(int length);

  void setRange(int start, int end, Iterable<double> from,
      [int skipCount = 0]) {
    // Check ranges.
    if (0 > start || start > end || end > length) {
      RangeError.checkValidRange(start, end, length); // Always throws.
      assert(false);
    }
    if (skipCount < 0) {
      throw RangeError.range(skipCount, 0, null, "skipCount");
    }

    final count = end - start;
    if ((from.length - skipCount) < count) {
      throw IterableElementError.tooFew();
    }

    if (count == 0) return;

    if (from is TypedData) {
      // We only add this mixin to typed lists in this library so we know
      // `this` is `TypedData`.
      final TypedData destTypedData = this;
      final TypedData fromTypedData = unsafeCast<TypedData>(from);

      final ByteBuffer destBuffer = destTypedData.buffer;
      final ByteBuffer fromBuffer = fromTypedData.buffer;

      final destDartElementSizeInBytes = destTypedData.elementSizeInBytes;
      final fromDartElementSizeInBytes = fromTypedData.elementSizeInBytes;

      // See comments in `_TypedIntListMixin.setRange`.
      if (destDartElementSizeInBytes == fromDartElementSizeInBytes) {
        final fromBufferByteOffset = fromTypedData.offsetInBytes +
            (skipCount * fromDartElementSizeInBytes);
        final destBufferByteOffset =
            destTypedData.offsetInBytes + (start * destDartElementSizeInBytes);
        if (destDartElementSizeInBytes == 4 &&
            destBuffer is _F32ByteBuffer &&
            fromBuffer is _F32ByteBuffer) {
          if (fromBufferByteOffset & 3 == 0 && destBufferByteOffset & 3 == 0) {
            destBuffer._data.copy(destBufferByteOffset ~/ 4, fromBuffer._data,
                fromBufferByteOffset ~/ 4, count);
            return;
          }
        } else if (destDartElementSizeInBytes == 8 &&
            destBuffer is _F64ByteBuffer &&
            fromBuffer is _F64ByteBuffer) {
          if (fromBufferByteOffset & 7 == 0 && destBufferByteOffset & 7 == 0) {
            destBuffer._data.copy(destBufferByteOffset ~/ 8, fromBuffer._data,
                fromBufferByteOffset ~/ 8, count);
            return;
          }
        }
      }

      if (destBuffer == fromBuffer) {
        final fromAsList = from as List<double>;
        final tempBuffer = _createList(count);
        for (var i = 0; i < count; i++) {
          tempBuffer[i] = fromAsList[skipCount + i];
        }
        for (var i = start; i < end; i++) {
          this[i] = tempBuffer[i - start];
        }
        return;
      }
    }

    final List otherList;
    final int otherStart;
    if (from is List<double>) {
      otherList = from;
      otherStart = skipCount;
    } else {
      otherList = from.skip(skipCount).toList(growable: false);
      otherStart = 0;
    }
    Lists.copy(otherList, otherStart, this, start, count);
  }

  SpawnedType sublist(int start, [int? end]) {
    int endIndex = RangeError.checkValidRange(start, end, this.length);
    var length = endIndex - start;
    SpawnedType result = _createList(length);
    result.setRange(0, length, this, start);
    return result;
  }
}

// TODO(omersa): This mixin should override other update methods (probably just
// setRange) that don't use `[]=` to modify the list.
mixin _UnmodifiableIntListMixin {
  void operator []=(int index, int value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }
}

// TODO(omersa): Same as above.
mixin _UnmodifiableDoubleListMixin {
  void operator []=(int index, double value) {
    throw UnsupportedError("Cannot modify an unmodifiable list");
  }
}

//
// Fast lists
//

abstract class _WasmI8ArrayBase extends WasmTypedDataBase {
  final WasmArray<WasmI8> _data;
  final int _offsetInElements;
  final int length;

  _WasmI8ArrayBase(this.length)
      : _data = WasmArray(_newArrayLengthCheck(length)),
        _offsetInElements = 0;

  _WasmI8ArrayBase._(this._data, this._offsetInElements, this.length);

  int get elementSizeInBytes => 1;

  int get offsetInBytes => _offsetInElements;

  ByteBuffer get buffer => _I8ByteBuffer(_data);
}

abstract class _WasmI16ArrayBase extends WasmTypedDataBase {
  final WasmArray<WasmI16> _data;
  final int _offsetInElements;
  final int length;

  _WasmI16ArrayBase(this.length)
      : _data = WasmArray(_newArrayLengthCheck(length)),
        _offsetInElements = 0;

  _WasmI16ArrayBase._(this._data, this._offsetInElements, this.length);

  int get elementSizeInBytes => 2;

  int get offsetInBytes => _offsetInElements * 2;

  ByteBuffer get buffer => _I16ByteBuffer(_data);
}

abstract class _WasmI32ArrayBase extends WasmTypedDataBase {
  final WasmArray<WasmI32> _data;
  final int _offsetInElements;
  final int length;

  _WasmI32ArrayBase(this.length)
      : _data = WasmArray(_newArrayLengthCheck(length)),
        _offsetInElements = 0;

  _WasmI32ArrayBase._(this._data, this._offsetInElements, this.length);

  int get elementSizeInBytes => 4;

  int get offsetInBytes => _offsetInElements * 4;

  ByteBuffer get buffer => _I32ByteBuffer(_data);
}

abstract class _WasmI64ArrayBase extends WasmTypedDataBase {
  final WasmArray<WasmI64> _data;
  final int _offsetInElements;
  final int length;

  _WasmI64ArrayBase(this.length)
      : _data = WasmArray(_newArrayLengthCheck(length)),
        _offsetInElements = 0;

  _WasmI64ArrayBase._(this._data, this._offsetInElements, this.length);

  int get elementSizeInBytes => 8;

  int get offsetInBytes => _offsetInElements * 8;

  ByteBuffer get buffer => _I64ByteBuffer(_data);
}

abstract class _WasmF32ArrayBase extends WasmTypedDataBase {
  final WasmArray<WasmF32> _data;
  final int _offsetInElements;
  final int length;

  _WasmF32ArrayBase(this.length)
      : _data = WasmArray(_newArrayLengthCheck(length)),
        _offsetInElements = 0;

  _WasmF32ArrayBase._(this._data, this._offsetInElements, this.length);

  int get elementSizeInBytes => 4;

  int get offsetInBytes => _offsetInElements * 4;

  ByteBuffer get buffer => _F32ByteBuffer(_data);
}

abstract class _WasmF64ArrayBase extends WasmTypedDataBase {
  final WasmArray<WasmF64> _data;
  final int _offsetInElements;
  final int length;

  _WasmF64ArrayBase(this.length)
      : _data = WasmArray(_newArrayLengthCheck(length)),
        _offsetInElements = 0;

  _WasmF64ArrayBase._(this._data, this._offsetInElements, this.length);

  int get elementSizeInBytes => 8;

  int get offsetInBytes => _offsetInElements * 8;

  ByteBuffer get buffer => _F64ByteBuffer(_data);
}

class I8List extends _WasmI8ArrayBase
    with
        _IntListMixin,
        _TypedIntListMixin<I8List>,
        _TypedListCommonOperationsMixin
    implements Int8List {
  I8List(int length) : super(length);

  I8List._(WasmArray<WasmI8> data, int offsetInElements, int length)
      : super._(data, offsetInElements, length);

  factory I8List._withMutability(WasmArray<WasmI8> buffer, int offsetInBytes,
          int length, bool mutable) =>
      mutable
          ? I8List._(buffer, offsetInBytes, length)
          : UnmodifiableI8List._(buffer, offsetInBytes, length);

  @override
  UnmodifiableI8List asUnmodifiableView() => UnmodifiableI8List(this);

  @override
  I8List _createList(int length) => I8List(length);

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    indexCheck(index, length);
    return _data.readSigned(_offsetInElements + index);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _data.write(_offsetInElements + index, value);
  }
}

class U8List extends _WasmI8ArrayBase
    with
        _IntListMixin,
        _TypedIntListMixin<U8List>,
        _TypedListCommonOperationsMixin
    implements Uint8List {
  U8List(int length) : super(length);

  U8List._(WasmArray<WasmI8> data, int offsetInElements, int length)
      : super._(data, offsetInElements, length);

  WasmArray<WasmI8> get data => _data;

  factory U8List._withMutability(WasmArray<WasmI8> buffer, int offsetInBytes,
          int length, bool mutable) =>
      mutable
          ? U8List._(buffer, offsetInBytes, length)
          : UnmodifiableU8List._(buffer, offsetInBytes, length);

  @override
  UnmodifiableU8List asUnmodifiableView() => UnmodifiableU8List(this);

  @override
  U8List _createList(int length) => U8List(length);

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    indexCheck(index, length);
    return _data.readUnsigned(_offsetInElements + index);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _data.write(_offsetInElements + index, value);
  }
}

class U8ClampedList extends _WasmI8ArrayBase
    with
        _IntListMixin,
        _TypedIntListMixin<U8ClampedList>,
        _TypedListCommonOperationsMixin
    implements Uint8ClampedList {
  U8ClampedList(int length) : super(length);

  U8ClampedList._(WasmArray<WasmI8> data, int offsetInElements, int length)
      : super._(data, offsetInElements, length);

  factory U8ClampedList._withMutability(WasmArray<WasmI8> buffer,
          int offsetInBytes, int length, bool mutable) =>
      mutable
          ? U8ClampedList._(buffer, offsetInBytes, length)
          : UnmodifiableU8ClampedList._(buffer, offsetInBytes, length);

  @override
  UnmodifiableU8ClampedList asUnmodifiableView() =>
      UnmodifiableU8ClampedList(this);

  @override
  U8ClampedList _createList(int length) => U8ClampedList(length);

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    indexCheck(index, length);
    return _data.readUnsigned(_offsetInElements + index);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _data.write(_offsetInElements + index, value.clamp(0, 255));
  }
}

class I16List extends _WasmI16ArrayBase
    with
        _IntListMixin,
        _TypedIntListMixin<I16List>,
        _TypedListCommonOperationsMixin
    implements Int16List {
  I16List(int length) : super(length);

  I16List._(WasmArray<WasmI16> data, int offsetInElements, int length)
      : super._(data, offsetInElements, length);

  factory I16List._withMutability(WasmArray<WasmI16> buffer, int offsetInBytes,
          int length, bool mutable) =>
      mutable
          ? I16List._(buffer, offsetInBytes, length)
          : UnmodifiableI16List._(buffer, offsetInBytes, length);

  @override
  UnmodifiableI16List asUnmodifiableView() => UnmodifiableI16List(this);

  @override
  I16List _createList(int length) => I16List(length);

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    indexCheck(index, length);
    return _data.readSigned(_offsetInElements + index);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _data.write(_offsetInElements + index, value);
  }
}

class U16List extends _WasmI16ArrayBase
    with
        _IntListMixin,
        _TypedIntListMixin<U16List>,
        _TypedListCommonOperationsMixin
    implements Uint16List {
  U16List(int length) : super(length);

  U16List._(WasmArray<WasmI16> data, int offsetInElements, int length)
      : super._(data, offsetInElements, length);

  factory U16List._withMutability(WasmArray<WasmI16> buffer, int offsetInBytes,
          int length, bool mutable) =>
      mutable
          ? U16List._(buffer, offsetInBytes, length)
          : UnmodifiableU16List._(buffer, offsetInBytes, length);

  @override
  UnmodifiableU16List asUnmodifiableView() => UnmodifiableU16List(this);

  @override
  U16List _createList(int length) => U16List(length);

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    indexCheck(index, length);
    return _data.readUnsigned(_offsetInElements + index);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _data.write(_offsetInElements + index, value);
  }
}

class I32List extends _WasmI32ArrayBase
    with
        _IntListMixin,
        _TypedIntListMixin<I32List>,
        _TypedListCommonOperationsMixin
    implements Int32List {
  I32List(int length) : super(length);

  I32List._(WasmArray<WasmI32> data, int offsetInElements, int length)
      : super._(data, offsetInElements, length);

  factory I32List._withMutability(WasmArray<WasmI32> buffer, int offsetInBytes,
          int length, bool mutable) =>
      mutable
          ? I32List._(buffer, offsetInBytes, length)
          : UnmodifiableI32List._(buffer, offsetInBytes, length);

  @override
  UnmodifiableI32List asUnmodifiableView() => UnmodifiableI32List(this);

  @override
  I32List _createList(int length) => I32List(length);

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    indexCheck(index, length);
    return _data.readSigned(_offsetInElements + index);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _data.write(_offsetInElements + index, value);
  }
}

class U32List extends _WasmI32ArrayBase
    with
        _IntListMixin,
        _TypedIntListMixin<U32List>,
        _TypedListCommonOperationsMixin
    implements Uint32List {
  U32List(int length) : super(length);

  U32List._(WasmArray<WasmI32> data, int offsetInElements, int length)
      : super._(data, offsetInElements, length);

  factory U32List._withMutability(WasmArray<WasmI32> buffer, int offsetInBytes,
          int length, bool mutable) =>
      mutable
          ? U32List._(buffer, offsetInBytes, length)
          : UnmodifiableU32List._(buffer, offsetInBytes, length);

  @override
  UnmodifiableU32List asUnmodifiableView() => UnmodifiableU32List(this);

  @override
  U32List _createList(int length) => U32List(length);

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    indexCheck(index, length);
    return _data.readUnsigned(_offsetInElements + index);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _data.write(_offsetInElements + index, value);
  }
}

class I64List extends _WasmI64ArrayBase
    with
        _IntListMixin,
        _TypedIntListMixin<I64List>,
        _TypedListCommonOperationsMixin
    implements Int64List {
  I64List(int length) : super(length);

  I64List._(WasmArray<WasmI64> data, int offsetInElements, int length)
      : super._(data, offsetInElements, length);

  factory I64List._withMutability(WasmArray<WasmI64> buffer, int offsetInBytes,
          int length, bool mutable) =>
      mutable
          ? I64List._(buffer, offsetInBytes, length)
          : UnmodifiableI64List._(buffer, offsetInBytes, length);

  @override
  UnmodifiableI64List asUnmodifiableView() => UnmodifiableI64List(this);

  @override
  I64List _createList(int length) => I64List(length);

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    indexCheck(index, length);
    return _data.read(_offsetInElements + index);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _data.write(_offsetInElements + index, value);
  }
}

class U64List extends _WasmI64ArrayBase
    with
        _IntListMixin,
        _TypedIntListMixin<U64List>,
        _TypedListCommonOperationsMixin
    implements Uint64List {
  U64List(int length) : super(length);

  U64List._(WasmArray<WasmI64> data, int offsetInElements, int length)
      : super._(data, offsetInElements, length);

  factory U64List._withMutability(WasmArray<WasmI64> buffer, int offsetInBytes,
          int length, bool mutable) =>
      mutable
          ? U64List._(buffer, offsetInBytes, length)
          : UnmodifiableU64List._(buffer, offsetInBytes, length);

  @override
  UnmodifiableU64List asUnmodifiableView() => UnmodifiableU64List(this);

  @override
  U64List _createList(int length) => U64List(length);

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    indexCheck(index, length);
    return _data.read(_offsetInElements + index);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _data.write(_offsetInElements + index, value);
  }
}

class F32List extends _WasmF32ArrayBase
    with
        _DoubleListMixin,
        _TypedDoubleListMixin<Float32List>,
        _TypedListCommonOperationsMixin
    implements Float32List {
  F32List(int length) : super(length);

  F32List._(WasmArray<WasmF32> data, int offsetInElements, int length)
      : super._(data, offsetInElements, length);

  factory F32List._withMutability(WasmArray<WasmF32> buffer, int offsetInBytes,
          int length, bool mutable) =>
      mutable
          ? F32List._(buffer, offsetInBytes, length)
          : UnmodifiableF32List._(buffer, offsetInBytes, length);

  @override
  UnmodifiableF32List asUnmodifiableView() => UnmodifiableF32List(this);

  @override
  F32List _createList(int length) => F32List(length);

  @override
  @pragma("wasm:prefer-inline")
  double operator [](int index) {
    indexCheck(index, length);
    return _data.read(_offsetInElements + index);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, double value) {
    indexCheck(index, length);
    _data.write(_offsetInElements + index, value);
  }
}

class F64List extends _WasmF64ArrayBase
    with
        _DoubleListMixin,
        _TypedDoubleListMixin<Float64List>,
        _TypedListCommonOperationsMixin
    implements Float64List {
  F64List(int length) : super(length);

  F64List._(WasmArray<WasmF64> data, int offsetInElements, int length)
      : super._(data, offsetInElements, length);

  factory F64List._withMutability(WasmArray<WasmF64> buffer, int offsetInBytes,
          int length, bool mutable) =>
      mutable
          ? F64List._(buffer, offsetInBytes, length)
          : UnmodifiableF64List._(buffer, offsetInBytes, length);

  @override
  UnmodifiableF64List asUnmodifiableView() => UnmodifiableF64List(this);

  @override
  F64List _createList(int length) => F64List(length);

  @override
  @pragma("wasm:prefer-inline")
  double operator [](int index) {
    indexCheck(index, length);
    return _data.read(_offsetInElements + index);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, double value) {
    indexCheck(index, length);
    _data.write(_offsetInElements + index, value);
  }
}

//
// Unmodifiable fast lists
//

class UnmodifiableI8List extends I8List with _UnmodifiableIntListMixin {
  UnmodifiableI8List(I8List list)
      : super._(list._data, list._offsetInElements, list.length);

  UnmodifiableI8List._(WasmArray<WasmI8> data, int offsetInElements, int length)
      : super._(data, offsetInElements, length);

  @override
  _I8ByteBuffer get buffer => _I8ByteBuffer._(_data, false);
}

class UnmodifiableU8List extends U8List with _UnmodifiableIntListMixin {
  UnmodifiableU8List(U8List list)
      : super._(list._data, list._offsetInElements, list.length);

  UnmodifiableU8List._(WasmArray<WasmI8> data, int offsetInElements, int length)
      : super._(data, offsetInElements, length);

  @override
  _I8ByteBuffer get buffer => _I8ByteBuffer._(_data, false);
}

class UnmodifiableU8ClampedList extends U8ClampedList
    with _UnmodifiableIntListMixin {
  UnmodifiableU8ClampedList(U8ClampedList list)
      : super._(list._data, list._offsetInElements, list.length);

  UnmodifiableU8ClampedList._(
      WasmArray<WasmI8> data, int offsetInElements, int length)
      : super._(data, offsetInElements, length);

  @override
  _I8ByteBuffer get buffer => _I8ByteBuffer._(_data, false);
}

class UnmodifiableI16List extends I16List with _UnmodifiableIntListMixin {
  UnmodifiableI16List(I16List list)
      : super._(list._data, list._offsetInElements, list.length);

  UnmodifiableI16List._(
      WasmArray<WasmI16> data, int offsetInElements, int length)
      : super._(data, offsetInElements, length);

  @override
  _I16ByteBuffer get buffer => _I16ByteBuffer._(_data, false);
}

class UnmodifiableU16List extends U16List with _UnmodifiableIntListMixin {
  UnmodifiableU16List(U16List list)
      : super._(list._data, list._offsetInElements, list.length);

  UnmodifiableU16List._(
      WasmArray<WasmI16> data, int offsetInElements, int length)
      : super._(data, offsetInElements, length);

  @override
  _I16ByteBuffer get buffer => _I16ByteBuffer._(_data, false);
}

class UnmodifiableI32List extends I32List with _UnmodifiableIntListMixin {
  UnmodifiableI32List(I32List list)
      : super._(list._data, list._offsetInElements, list.length);

  UnmodifiableI32List._(
      WasmArray<WasmI32> data, int offsetInElements, int length)
      : super._(data, offsetInElements, length);

  @override
  _I32ByteBuffer get buffer => _I32ByteBuffer._(_data, false);
}

class UnmodifiableU32List extends U32List with _UnmodifiableIntListMixin {
  UnmodifiableU32List(U32List list)
      : super._(list._data, list._offsetInElements, list.length);

  UnmodifiableU32List._(
      WasmArray<WasmI32> data, int offsetInElements, int length)
      : super._(data, offsetInElements, length);

  @override
  _I32ByteBuffer get buffer => _I32ByteBuffer._(_data, false);
}

class UnmodifiableI64List extends I64List with _UnmodifiableIntListMixin {
  UnmodifiableI64List(I64List list)
      : super._(list._data, list._offsetInElements, list.length);

  UnmodifiableI64List._(
      WasmArray<WasmI64> data, int offsetInElements, int length)
      : super._(data, offsetInElements, length);

  @override
  _I64ByteBuffer get buffer => _I64ByteBuffer._(_data, false);
}

class UnmodifiableU64List extends U64List with _UnmodifiableIntListMixin {
  UnmodifiableU64List(U64List list)
      : super._(list._data, list._offsetInElements, list.length);

  UnmodifiableU64List._(
      WasmArray<WasmI64> data, int offsetInElements, int length)
      : super._(data, offsetInElements, length);

  @override
  _I64ByteBuffer get buffer => _I64ByteBuffer._(_data, false);
}

class UnmodifiableF32List extends F32List with _UnmodifiableDoubleListMixin {
  UnmodifiableF32List(F32List list)
      : super._(list._data, list._offsetInElements, list.length);

  UnmodifiableF32List._(
      WasmArray<WasmF32> data, int offsetInElements, int length)
      : super._(data, offsetInElements, length);

  @override
  _F32ByteBuffer get buffer => _F32ByteBuffer._(_data, false);
}

class UnmodifiableF64List extends F64List with _UnmodifiableDoubleListMixin {
  UnmodifiableF64List(F64List list)
      : super._(list._data, list._offsetInElements, list.length);

  UnmodifiableF64List._(
      WasmArray<WasmF64> data, int offsetInElements, int length)
      : super._(data, offsetInElements, length);

  @override
  _F64ByteBuffer get buffer => _F64ByteBuffer._(_data, false);
}

//
// Slow lists
//

class _SlowListBase extends WasmTypedDataBase {
  final ByteBuffer buffer;
  final int offsetInBytes;
  final int length;

  final ByteData _data;

  _SlowListBase(this.buffer, this.offsetInBytes, this.length)
      : _data = buffer.asByteData();
}

class _SlowI8List extends _SlowListBase
    with
        _IntListMixin,
        _TypedIntListMixin<I8List>,
        _TypedListCommonOperationsMixin
    implements Int8List {
  _SlowI8List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super(buffer, offsetInBytes, length);

  factory _SlowI8List._withMutability(
          ByteBuffer buffer, int offsetInBytes, int length, bool mutable) =>
      mutable
          ? _SlowI8List._(buffer, offsetInBytes, length)
          : UnmodifiableSlowI8List._(buffer, offsetInBytes, length);

  @override
  UnmodifiableSlowI8List asUnmodifiableView() => UnmodifiableSlowI8List(this);

  @override
  I8List _createList(int length) => I8List(length);

  @override
  int get elementSizeInBytes => Int8List.bytesPerElement;

  @override
  int operator [](int index) {
    indexCheck(index, length);
    return _data.getInt8(offsetInBytes + index);
  }

  @override
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _data.setInt8(offsetInBytes + index, value);
  }
}

class _SlowU8List extends _SlowListBase
    with
        _IntListMixin,
        _TypedIntListMixin<U8List>,
        _TypedListCommonOperationsMixin
    implements Uint8List {
  _SlowU8List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super(buffer, offsetInBytes, length);

  factory _SlowU8List._withMutability(
          ByteBuffer buffer, int offsetInBytes, int length, bool mutable) =>
      mutable
          ? _SlowU8List._(buffer, offsetInBytes, length)
          : UnmodifiableSlowU8List._(buffer, offsetInBytes, length);

  @override
  UnmodifiableSlowU8List asUnmodifiableView() => UnmodifiableSlowU8List(this);

  @override
  U8List _createList(int length) => U8List(length);

  @override
  int get elementSizeInBytes => Uint8List.bytesPerElement;

  @override
  int operator [](int index) {
    indexCheck(index, length);
    return _data.getUint8(offsetInBytes + (index * elementSizeInBytes));
  }

  @override
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _data.setUint8(offsetInBytes + (index * elementSizeInBytes), value);
  }
}

class _SlowU8ClampedList extends _SlowListBase
    with
        _IntListMixin,
        _TypedIntListMixin<U8ClampedList>,
        _TypedListCommonOperationsMixin
    implements Uint8ClampedList {
  _SlowU8ClampedList._(ByteBuffer buffer, int offsetInBytes, int length)
      : super(buffer, offsetInBytes, length);

  factory _SlowU8ClampedList._withMutability(
          ByteBuffer buffer, int offsetInBytes, int length, bool mutable) =>
      mutable
          ? _SlowU8ClampedList._(buffer, offsetInBytes, length)
          : UnmodifiableSlowU8ClampedList._(buffer, offsetInBytes, length);

  @override
  UnmodifiableSlowU8ClampedList asUnmodifiableView() =>
      UnmodifiableSlowU8ClampedList(this);

  @override
  U8ClampedList _createList(int length) => U8ClampedList(length);

  @override
  int get elementSizeInBytes => Uint8ClampedList.bytesPerElement;

  @override
  int operator [](int index) {
    indexCheck(index, length);
    return _data.getUint8(offsetInBytes + (index * elementSizeInBytes));
  }

  @override
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _data.setUint8(
        offsetInBytes + (index * elementSizeInBytes), value.clamp(0, 255));
  }
}

class _SlowI16List extends _SlowListBase
    with
        _IntListMixin,
        _TypedIntListMixin<I16List>,
        _TypedListCommonOperationsMixin
    implements Int16List {
  _SlowI16List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super(buffer, offsetInBytes, length);

  factory _SlowI16List._withMutability(
          ByteBuffer buffer, int offsetInBytes, int length, bool mutable) =>
      mutable
          ? _SlowI16List._(buffer, offsetInBytes, length)
          : UnmodifiableSlowI16List._(buffer, offsetInBytes, length);

  @override
  UnmodifiableSlowI16List asUnmodifiableView() => UnmodifiableSlowI16List(this);

  @override
  I16List _createList(int length) => I16List(length);

  @override
  int get elementSizeInBytes => Int16List.bytesPerElement;

  @override
  int operator [](int index) {
    indexCheck(index, length);
    return _data.getInt16(
        offsetInBytes + (index * elementSizeInBytes), Endian.little);
  }

  @override
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _data.setInt16(
        offsetInBytes + (index * elementSizeInBytes), value, Endian.little);
  }
}

class _SlowU16List extends _SlowListBase
    with
        _IntListMixin,
        _TypedIntListMixin<U16List>,
        _TypedListCommonOperationsMixin
    implements Uint16List {
  _SlowU16List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super(buffer, offsetInBytes, length);

  factory _SlowU16List._withMutability(
          ByteBuffer buffer, int offsetInBytes, int length, bool mutable) =>
      mutable
          ? _SlowU16List._(buffer, offsetInBytes, length)
          : UnmodifiableSlowU16List._(buffer, offsetInBytes, length);

  @override
  UnmodifiableSlowU16List asUnmodifiableView() => UnmodifiableSlowU16List(this);

  @override
  U16List _createList(int length) => U16List(length);

  @override
  int get elementSizeInBytes => Uint16List.bytesPerElement;

  @override
  int operator [](int index) {
    indexCheck(index, length);
    return _data.getUint16(
        offsetInBytes + (index * elementSizeInBytes), Endian.little);
  }

  @override
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _data.setUint16(
        offsetInBytes + (index * elementSizeInBytes), value, Endian.little);
  }
}

class _SlowI32List extends _SlowListBase
    with
        _IntListMixin,
        _TypedIntListMixin<I32List>,
        _TypedListCommonOperationsMixin
    implements Int32List {
  _SlowI32List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super(buffer, offsetInBytes, length);

  factory _SlowI32List._withMutability(
          ByteBuffer buffer, int offsetInBytes, int length, bool mutable) =>
      mutable
          ? _SlowI32List._(buffer, offsetInBytes, length)
          : UnmodifiableSlowI32List._(buffer, offsetInBytes, length);

  @override
  UnmodifiableSlowI32List asUnmodifiableView() => UnmodifiableSlowI32List(this);

  @override
  I32List _createList(int length) => I32List(length);

  @override
  int get elementSizeInBytes => Int32List.bytesPerElement;

  @override
  int operator [](int index) {
    indexCheck(index, length);
    return _data.getInt32(
        offsetInBytes + (index * elementSizeInBytes), Endian.little);
  }

  @override
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _data.setInt32(
        offsetInBytes + (index * elementSizeInBytes), value, Endian.little);
  }
}

class _SlowU32List extends _SlowListBase
    with
        _IntListMixin,
        _TypedIntListMixin<U32List>,
        _TypedListCommonOperationsMixin
    implements Uint32List {
  _SlowU32List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super(buffer, offsetInBytes, length);

  factory _SlowU32List._withMutability(
          ByteBuffer buffer, int offsetInBytes, int length, bool mutable) =>
      mutable
          ? _SlowU32List._(buffer, offsetInBytes, length)
          : UnmodifiableSlowU32List._(buffer, offsetInBytes, length);

  @override
  UnmodifiableSlowU32List asUnmodifiableView() => UnmodifiableSlowU32List(this);

  @override
  U32List _createList(int length) => U32List(length);

  @override
  int get elementSizeInBytes => Uint32List.bytesPerElement;

  @override
  int operator [](int index) {
    indexCheck(index, length);
    return _data.getUint32(
        offsetInBytes + (index * elementSizeInBytes), Endian.little);
  }

  @override
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _data.setUint32(
        offsetInBytes + (index * elementSizeInBytes), value, Endian.little);
  }
}

class _SlowI64List extends _SlowListBase
    with
        _IntListMixin,
        _TypedIntListMixin<I64List>,
        _TypedListCommonOperationsMixin
    implements Int64List {
  _SlowI64List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super(buffer, offsetInBytes, length);

  factory _SlowI64List._withMutability(
          ByteBuffer buffer, int offsetInBytes, int length, bool mutable) =>
      mutable
          ? _SlowI64List._(buffer, offsetInBytes, length)
          : UnmodifiableSlowI64List._(buffer, offsetInBytes, length);

  @override
  UnmodifiableSlowI64List asUnmodifiableView() => UnmodifiableSlowI64List(this);

  @override
  I64List _createList(int length) => I64List(length);

  @override
  int get elementSizeInBytes => Int64List.bytesPerElement;

  @override
  int operator [](int index) {
    indexCheck(index, length);
    return _data.getInt64(
        offsetInBytes + (index * elementSizeInBytes), Endian.little);
  }

  @override
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _data.setInt64(
        offsetInBytes + (index * elementSizeInBytes), value, Endian.little);
  }
}

class _SlowU64List extends _SlowListBase
    with
        _IntListMixin,
        _TypedIntListMixin<U64List>,
        _TypedListCommonOperationsMixin
    implements Uint64List {
  _SlowU64List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super(buffer, offsetInBytes, length);

  factory _SlowU64List._withMutability(
          ByteBuffer buffer, int offsetInBytes, int length, bool mutable) =>
      mutable
          ? _SlowU64List._(buffer, offsetInBytes, length)
          : UnmodifiableSlowU64List._(buffer, offsetInBytes, length);

  @override
  UnmodifiableSlowU64List asUnmodifiableView() => UnmodifiableSlowU64List(this);

  @override
  U64List _createList(int length) => U64List(length);

  @override
  int get elementSizeInBytes => Uint64List.bytesPerElement;

  @override
  int operator [](int index) {
    indexCheck(index, length);
    return _data.getUint64(
        offsetInBytes + (index * elementSizeInBytes), Endian.little);
  }

  @override
  void operator []=(int index, int value) {
    indexCheck(index, length);
    _data.setUint64(
        offsetInBytes + (index * elementSizeInBytes), value, Endian.little);
  }
}

class _SlowF32List extends _SlowListBase
    with
        _DoubleListMixin,
        _TypedDoubleListMixin<F32List>,
        _TypedListCommonOperationsMixin
    implements Float32List {
  _SlowF32List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super(buffer, offsetInBytes, length);

  factory _SlowF32List._withMutability(
          ByteBuffer buffer, int offsetInBytes, int length, bool mutable) =>
      mutable
          ? _SlowF32List._(buffer, offsetInBytes, length)
          : UnmodifiableSlowF32List._(buffer, offsetInBytes, length);

  @override
  UnmodifiableSlowF32List asUnmodifiableView() => UnmodifiableSlowF32List(this);

  @override
  F32List _createList(int length) => F32List(length);

  @override
  int get elementSizeInBytes => Float32List.bytesPerElement;

  @override
  double operator [](int index) {
    indexCheck(index, length);
    return _data.getFloat32(
        offsetInBytes + (index * elementSizeInBytes), Endian.little);
  }

  @override
  void operator []=(int index, double value) {
    indexCheck(index, length);
    _data.setFloat32(
        offsetInBytes + (index * elementSizeInBytes), value, Endian.little);
  }
}

class SlowF64List extends _SlowListBase
    with
        _DoubleListMixin,
        _TypedDoubleListMixin<F64List>,
        _TypedListCommonOperationsMixin
    implements Float64List {
  SlowF64List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super(buffer, offsetInBytes, length);

  factory SlowF64List._withMutability(
          ByteBuffer buffer, int offsetInBytes, int length, bool mutable) =>
      mutable
          ? SlowF64List._(buffer, offsetInBytes, length)
          : UnmodifiableSlowF64List._(buffer, offsetInBytes, length);

  @override
  UnmodifiableSlowF64List asUnmodifiableView() => UnmodifiableSlowF64List(this);

  @override
  F64List _createList(int length) => F64List(length);

  @override
  int get elementSizeInBytes => Float64List.bytesPerElement;

  @override
  double operator [](int index) {
    indexCheck(index, length);
    return _data.getFloat64(
        offsetInBytes + (index * elementSizeInBytes), Endian.little);
  }

  @override
  void operator []=(int index, double value) {
    indexCheck(index, length);
    _data.setFloat64(
        offsetInBytes + (index * elementSizeInBytes), value, Endian.little);
  }
}

//
// Unmodifiable slow lists
//

mixin _UnmodifiableSlowListMixin on _SlowListBase {
  ByteBuffer get buffer =>
      unsafeCast<ByteBufferBase>(super.buffer)._immutable();
}

class UnmodifiableSlowI8List extends _SlowI8List
    with _UnmodifiableIntListMixin, _UnmodifiableSlowListMixin {
  UnmodifiableSlowI8List(Int8List list)
      : super._(list.buffer, list.offsetInBytes, list.length);

  UnmodifiableSlowI8List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super._(buffer, offsetInBytes, length);
}

class UnmodifiableSlowU8List extends _SlowU8List
    with _UnmodifiableIntListMixin, _UnmodifiableSlowListMixin {
  UnmodifiableSlowU8List(Uint8List list)
      : super._(list.buffer, list.offsetInBytes, list.length);

  UnmodifiableSlowU8List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super._(buffer, offsetInBytes, length);
}

class UnmodifiableSlowU8ClampedList extends _SlowU8ClampedList
    with _UnmodifiableIntListMixin, _UnmodifiableSlowListMixin {
  UnmodifiableSlowU8ClampedList(Uint8ClampedList list)
      : super._(list.buffer, list.offsetInBytes, list.length);

  UnmodifiableSlowU8ClampedList._(
      ByteBuffer buffer, int offsetInBytes, int length)
      : super._(buffer, offsetInBytes, length);
}

class UnmodifiableSlowI16List extends _SlowI16List
    with _UnmodifiableIntListMixin, _UnmodifiableSlowListMixin {
  UnmodifiableSlowI16List(Int16List list)
      : super._(list.buffer, list.offsetInBytes, list.length);

  UnmodifiableSlowI16List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super._(buffer, offsetInBytes, length);
}

class UnmodifiableSlowU16List extends _SlowU16List
    with _UnmodifiableIntListMixin, _UnmodifiableSlowListMixin {
  UnmodifiableSlowU16List(Uint16List list)
      : super._(list.buffer, list.offsetInBytes, list.length);

  UnmodifiableSlowU16List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super._(buffer, offsetInBytes, length);
}

class UnmodifiableSlowI32List extends _SlowI32List
    with _UnmodifiableIntListMixin, _UnmodifiableSlowListMixin {
  UnmodifiableSlowI32List(Int32List list)
      : super._(list.buffer, list.offsetInBytes, list.length);

  UnmodifiableSlowI32List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super._(buffer, offsetInBytes, length);
}

class UnmodifiableSlowU32List extends _SlowU32List
    with _UnmodifiableIntListMixin, _UnmodifiableSlowListMixin {
  UnmodifiableSlowU32List(Uint32List list)
      : super._(list.buffer, list.offsetInBytes, list.length);

  UnmodifiableSlowU32List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super._(buffer, offsetInBytes, length);
}

class UnmodifiableSlowI64List extends _SlowI64List
    with _UnmodifiableIntListMixin, _UnmodifiableSlowListMixin {
  UnmodifiableSlowI64List(Int64List list)
      : super._(list.buffer, list.offsetInBytes, list.length);

  UnmodifiableSlowI64List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super._(buffer, offsetInBytes, length);
}

class UnmodifiableSlowU64List extends _SlowU64List
    with _UnmodifiableIntListMixin, _UnmodifiableSlowListMixin {
  UnmodifiableSlowU64List(Uint64List list)
      : super._(list.buffer, list.offsetInBytes, list.length);

  UnmodifiableSlowU64List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super._(buffer, offsetInBytes, length);
}

class UnmodifiableSlowF32List extends _SlowF32List
    with _UnmodifiableDoubleListMixin, _UnmodifiableSlowListMixin {
  UnmodifiableSlowF32List(Float32List list)
      : super._(list.buffer, list.offsetInBytes, list.length);

  UnmodifiableSlowF32List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super._(buffer, offsetInBytes, length);
}

class UnmodifiableSlowF64List extends SlowF64List
    with _UnmodifiableDoubleListMixin, _UnmodifiableSlowListMixin {
  UnmodifiableSlowF64List(Float64List list)
      : super._(list.buffer, list.offsetInBytes, list.length);

  UnmodifiableSlowF64List._(ByteBuffer buffer, int offsetInBytes, int length)
      : super._(buffer, offsetInBytes, length);
}
