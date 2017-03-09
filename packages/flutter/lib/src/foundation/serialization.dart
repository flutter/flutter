// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:typed_data/typed_buffers.dart' show Uint8Buffer;

/// Write-only buffer for incrementally building a [ByteData] instance.
///
/// A WriteBuffer instance can be used only once. Attempts to reuse will result
/// in [NoSuchMethodError]s being thrown.
///
/// The byte order used is [Endianness.HOST_ENDIAN] throughout.
class WriteBuffer {
  WriteBuffer() {
    _buffer = new Uint8Buffer();
    _eightBytes = new ByteData(8);
    _eightBytesAsList = _eightBytes.buffer.asUint8List();
  }

  Uint8Buffer _buffer;
  ByteData _eightBytes;
  Uint8List _eightBytesAsList;

  void putUint8(int byte) {
    _buffer.add(byte);
  }

  void putUint16(int value) {
    _eightBytes.setUint16(0, value, Endianness.HOST_ENDIAN);
    _buffer.addAll(_eightBytesAsList, 0, 2);
  }

  void putUint32(int value) {
    _eightBytes.setUint32(0, value, Endianness.HOST_ENDIAN);
    _buffer.addAll(_eightBytesAsList, 0, 4);
  }

  void putInt32(int value) {
    _eightBytes.setInt32(0, value, Endianness.HOST_ENDIAN);
    _buffer.addAll(_eightBytesAsList, 0, 4);
  }

  void putInt64(int value) {
    _eightBytes.setInt64(0, value, Endianness.HOST_ENDIAN);
    _buffer.addAll(_eightBytesAsList, 0, 8);
  }

  void putFloat64(double value) {
    _eightBytes.setFloat64(0, value, Endianness.HOST_ENDIAN);
    _buffer.addAll(_eightBytesAsList);
  }

  void putUint8List(Uint8List list) {
    _buffer.addAll(list);
  }

  void putInt32List(Int32List list) {
    _alignTo(4);
    _buffer.addAll(list.buffer.asUint8List(list.offsetInBytes, 4 * list.length));
  }

  void putInt64List(Int64List list) {
    _alignTo(8);
    _buffer.addAll(list.buffer.asUint8List(list.offsetInBytes, 8 * list.length));
  }

  void putFloat64List(Float64List list) {
    _alignTo(8);
    _buffer.addAll(list.buffer.asUint8List(list.offsetInBytes, 8 * list.length));
  }

  void _alignTo(int alignment) {
    final int mod = _buffer.length % alignment;
    if (mod != 0) {
      for (int i = 0; i < alignment - mod; i++)
        _buffer.add(0);
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
/// The byte order used is [Endianness.HOST_ENDIAN] throughout.
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

  int getUint16() {
    final int value = data.getUint16(position, Endianness.HOST_ENDIAN);
    position += 2;
    return value;
  }

  int getUint32() {
    final int value = data.getUint32(position, Endianness.HOST_ENDIAN);
    position += 4;
    return value;
  }

  int getInt32() {
    final int value = data.getInt32(position, Endianness.HOST_ENDIAN);
    position += 4;
    return value;
  }

  int getInt64() {
    final int value = data.getInt64(position, Endianness.HOST_ENDIAN);
    position += 8;
    return value;
  }

  double getFloat64() {
    final double value = data.getFloat64(position, Endianness.HOST_ENDIAN);
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
    Int32List list = data.buffer.asInt32List(data.offsetInBytes + position, length);
    position += 4 * length;
    return list;
  }

  Int64List getInt64List(int length) {
    _alignTo(8);
    Int64List list = data.buffer.asInt64List(data.offsetInBytes + position, length);
    position += 8 * length;
    return list;
  }

  Float64List getFloat64List(int length) {
    _alignTo(8);
    Float64List list = data.buffer.asFloat64List(data.offsetInBytes + position, length);
    position += 8 * length;
    return list;
  }

  void _alignTo(int alignment) {
    final int mod = position % alignment;
    if (mod != 0)
      position += alignment - mod;
  }

  bool get hasRemaining => position < data.lengthInBytes;
}
