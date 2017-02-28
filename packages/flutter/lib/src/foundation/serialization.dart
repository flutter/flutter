// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:typed_data/typed_buffers.dart' show Uint8Buffer;

/// Write-only buffer for incrementally building a [ByteData] instance.
///
/// A WriteBuffer instance can be used only once. Attempts to reuse will result
/// in [NoSuchMethodError]s being thrown.
///
/// The byte order of serialized data is [Endianness.BIG_ENDIAN].
/// The byte order of deserialized data is [Endianness.HOST_ENDIAN].
class WriteBuffer {
  Uint8Buffer _buffer;
  ByteData _eightBytes;
  Uint8List _eightBytesAsList;

  WriteBuffer() {
    _buffer = new Uint8Buffer();
    _eightBytes = new ByteData(8);
    _eightBytesAsList = _eightBytes.buffer.asUint8List();
  }

  void putUint8(int byte) {
    _buffer.add(byte);
  }

  void putInt32(int value) {
    putUint8(value >> 24);
    putUint8(value >> 16);
    putUint8(value >> 8);
    putUint8(value);
  }

  void putInt64(int value) {
    putUint8(value >> 56);
    putUint8(value >> 48);
    putUint8(value >> 40);
    putUint8(value >> 32);
    putUint8(value >> 24);
    putUint8(value >> 16);
    putUint8(value >> 8);
    putUint8(value);
  }

  void putFloat64(double value) {
    _eightBytes.setFloat64(0, value);
    _buffer.addAll(_eightBytesAsList);
  }

  void putUint8List(Uint8List list) {
    _buffer.addAll(list);
  }

  void putInt32List(Int32List list) {
    _alignTo(4);
    if (Endianness.HOST_ENDIAN == Endianness.BIG_ENDIAN) {
      _buffer.addAll(list.buffer.asUint8List(list.offsetInBytes, 4 * list.length));
    } else {
      for (final int value in list) {
        putInt32(value);
      }
    }
  }

  void putInt64List(Int64List list) {
    _alignTo(8);
    if (Endianness.HOST_ENDIAN == Endianness.BIG_ENDIAN) {
      _buffer.addAll(list.buffer.asUint8List(list.offsetInBytes, 8 * list.length));
    } else {
      for (final int value in list) {
        putInt64(value);
      }
    }
  }

  void putFloat64List(Float64List list) {
    _alignTo(8);
    if (Endianness.HOST_ENDIAN == Endianness.BIG_ENDIAN) {
      _buffer.addAll(list.buffer.asUint8List(list.offsetInBytes, 8 * list.length));
    } else {
      for (final double value in list) {
        putFloat64(value);
      }
    }
  }

  void _alignTo(int alignment) {
    final int mod = _buffer.length % alignment;
    if (mod != 0) {
      for (int i = 0; i < alignment - mod; i++) {
        _buffer.add(0);
      }
    }
  }

  ByteData done() {
    final ByteData result = _buffer.buffer.asByteData(0, _buffer.lengthInBytes);
    _buffer = null;
    return result;
  }
}

/// Read-only buffer for reading sequentially from a [ByteData] instance.
///
/// The byte order of serialized data is [Endianness.BIG_ENDIAN].
/// The byte order of deserialized data is [Endianness.HOST_ENDIAN].
class ReadBuffer {
  final ByteData data;
  int position = 0;

  /// Creates a [ReadBuffer] for reading from the specified [data].
  ReadBuffer(this.data) {
    assert(data != null);
  }

  int getUint8() {
    return data.getUint8(position++);
  }

  int getInt32() {
    final int value = data.getInt32(position);
    position += 4;
    return value;
  }

  int getInt64() {
    final int value = data.getInt64(position);
    position += 8;
    return value;
  }

  double getFloat64() {
    final double value = data.getFloat64(position);
    position += 8;
    return value;
  }

  Uint8List getUint8List(int length) {
    final Uint8List list = data.buffer.asUint8List(data.offsetInBytes + position, length);
    position += length;
    return list;
  }

  Int32List getInt32List(int length) {
    _alignTo(4);
    Int32List list;
    if (Endianness.HOST_ENDIAN == Endianness.BIG_ENDIAN) {
      list = data.buffer.asInt32List(data.offsetInBytes + position, length);
    } else {
      final ByteData invertedData = new ByteData(4 * length);
      for (int i = 0; i < length; i++) {
        invertedData.setInt32(i * 4, data.getInt32(position + i * 4, Endianness.HOST_ENDIAN));
      }
      list = new Int32List.view(invertedData.buffer);
    }
    position += 4 * length;
    return list;
  }

  Int64List getInt64List(int length) {
    _alignTo(8);
    Int64List list;
    if (Endianness.HOST_ENDIAN == Endianness.BIG_ENDIAN) {
      list = data.buffer.asInt64List(data.offsetInBytes + position, length);
    } else {
      final ByteData invertedData = new ByteData(8 * length);
      for (int i = 0; i < length; i++) {
        invertedData.setInt64(i * 8, data.getInt64(position + i * 8, Endianness.HOST_ENDIAN));
      }
      list = new Int64List.view(invertedData.buffer);
    }
    position += 8 * length;
    return list;
  }

  Float64List getFloat64List(int length) {
    _alignTo(8);
    Float64List list;
    if (Endianness.HOST_ENDIAN == Endianness.BIG_ENDIAN) {
      list = data.buffer.asFloat64List(data.offsetInBytes + position, length);
    } else {
      final ByteData invertedData = new ByteData(8 * length);
      for (int i = 0; i < length; i++) {
        invertedData.setFloat64(i * 8, data.getFloat64(position + i * 8, Endianness.HOST_ENDIAN));
      }
      list = new Float64List.view(invertedData.buffer);
    }
    position += 8 * length;
    return list;
  }

  void _alignTo(int alignment) {
    final int mod = position % alignment;
    if (mod != 0) {
      position += alignment - mod;
    }
  }

  bool get hasRemaining => position < data.lengthInBytes;
}
