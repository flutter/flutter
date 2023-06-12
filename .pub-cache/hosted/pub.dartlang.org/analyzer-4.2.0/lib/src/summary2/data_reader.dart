// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

/// Helper for reading primitive types from bytes.
class SummaryDataReader {
  final Uint8List bytes;
  int offset = 0;

  late final _StringTable _stringTable;

  final Float64List _doubleBuffer = Float64List(1);
  Uint8List? _doubleBufferUint8;

  SummaryDataReader(this.bytes);

  void createStringTable(int offset) {
    _stringTable = _StringTable(bytes: bytes, startOffset: offset);
  }

  /// Create a new instance with the given [offset].
  /// It shares the same bytes and string reader.
  SummaryDataReader fork(int offset) {
    var result = SummaryDataReader(bytes);
    result.offset = offset;
    result._stringTable = _stringTable;
    return result;
  }

  @pragma("vm:prefer-inline")
  bool readBool() {
    return readByte() != 0;
  }

  @pragma("vm:prefer-inline")
  int readByte() {
    return bytes[offset++];
  }

  double readDouble() {
    var doubleBufferUint8 =
        _doubleBufferUint8 ??= _doubleBuffer.buffer.asUint8List();
    doubleBufferUint8[0] = readByte();
    doubleBufferUint8[1] = readByte();
    doubleBufferUint8[2] = readByte();
    doubleBufferUint8[3] = readByte();
    doubleBufferUint8[4] = readByte();
    doubleBufferUint8[5] = readByte();
    doubleBufferUint8[6] = readByte();
    doubleBufferUint8[7] = readByte();
    return _doubleBuffer[0];
  }

  T? readOptionalObject<T>(T Function(SummaryDataReader reader) read) {
    if (readBool()) {
      return read(this);
    } else {
      return null;
    }
  }

  String? readOptionalStringReference() {
    if (readBool()) {
      return readStringReference();
    } else {
      return null;
    }
  }

  String? readOptionalStringUtf8() {
    if (readBool()) {
      return readStringUtf8();
    } else {
      return null;
    }
  }

  int? readOptionalUInt30() {
    if (readBool()) {
      return readUInt30();
    } else {
      return null;
    }
  }

  String readStringReference() {
    var index = readUInt30();
    return stringOfIndex(index);
  }

  List<String> readStringReferenceList() {
    return readTypedList(readStringReference);
  }

  String readStringUtf8() {
    var bytes = readUint8List();
    return utf8.decode(bytes);
  }

  List<String> readStringUtf8List() {
    return readTypedList(readStringUtf8);
  }

  Set<String> readStringUtf8Set() {
    var length = readUInt30();
    var result = <String>{};
    for (var i = 0; i < length; i++) {
      var item = readStringUtf8();
      result.add(item);
    }
    return result;
  }

  List<T> readTypedList<T>(T Function() read) {
    var length = readUInt30();
    return List<T>.generate(length, (_) {
      return read();
    });
  }

  int readUInt30() {
    var byte = readByte();
    if (byte & 0x80 == 0) {
      // 0xxxxxxx
      return byte;
    } else if (byte & 0x40 == 0) {
      // 10xxxxxx
      return ((byte & 0x3F) << 8) | readByte();
    } else {
      // 11xxxxxx
      return ((byte & 0x3F) << 24) |
          (readByte() << 16) |
          (readByte() << 8) |
          readByte();
    }
  }

  Uint32List readUInt30List() {
    var length = readUInt30();
    var result = Uint32List(length);
    for (var i = 0; i < length; ++i) {
      result[i] = readUInt30();
    }
    return result;
  }

  int readUInt32() {
    return (readByte() << 24) |
        (readByte() << 16) |
        (readByte() << 8) |
        readByte();
  }

  Uint32List readUInt32List() {
    var length = readUInt32();
    var result = Uint32List(length);
    for (var i = 0; i < length; ++i) {
      result[i] = readUInt32();
    }
    return result;
  }

  Uint8List readUint8List() {
    var length = readUInt30();
    var result = Uint8List.sublistView(bytes, offset, offset + length);
    offset += length;
    return result;
  }

  String stringOfIndex(int index) {
    return _stringTable[index];
  }
}

class _StringTable {
  final Uint8List _bytes;
  int _byteOffset;

  late final Uint32List _offsets;
  late final Uint32List _lengths;
  late final List<String?> _strings;

  /// The structure of the table:
  ///   <bytes with encoded strings>
  ///   <the length of the bytes> <-- [startOffset]
  ///   <the number strings>
  ///   <the array of lengths of individual strings>
  _StringTable({
    required Uint8List bytes,
    required int startOffset,
  })  : _bytes = bytes,
        _byteOffset = startOffset {
    var offset = startOffset - _readUInt30();
    var length = _readUInt30();

    _offsets = Uint32List(length);
    _lengths = Uint32List(length);
    for (var i = 0; i < length; i++) {
      var stringLength = _readUInt30();
      _offsets[i] = offset;
      _lengths[i] = stringLength;
      offset += stringLength;
    }

    _strings = List.filled(length, null, growable: false);
  }

  String operator [](int index) {
    var result = _strings[index];

    if (result == null) {
      result = _readStringEntry(_offsets[index], _lengths[index]);
      _strings[index] = result;
    }

    return result;
  }

  int _readByte() {
    return _bytes[_byteOffset++];
  }

  String _readStringEntry(int start, int numBytes) {
    var end = start + numBytes;
    for (var i = start; i < end; i++) {
      if (_bytes[i] > 127) {
        return _decodeWtf8(_bytes, start, end);
      }
    }
    return String.fromCharCodes(_bytes, start, end);
  }

  int _readUInt30() {
    var byte = _readByte();
    if (byte & 0x80 == 0) {
      // 0xxxxxxx
      return byte;
    } else if (byte & 0x40 == 0) {
      // 10xxxxxx
      return ((byte & 0x3F) << 8) | _readByte();
    } else {
      // 11xxxxxx
      return ((byte & 0x3F) << 24) |
          (_readByte() << 16) |
          (_readByte() << 8) |
          _readByte();
    }
  }

  static String _decodeWtf8(Uint8List bytes, int start, int end) {
    // WTF-8 decoder that trusts its input, meaning that the correctness of
    // the code depends on the bytes from start to end being valid and
    // complete WTF-8. Instead of masking off the control bits from every
    // byte, it simply xor's the byte values together at their appropriate
    // bit shifts, and then xor's out all of the control bits at once.
    Uint16List charCodes = Uint16List(end - start);
    int i = start;
    int j = 0;
    while (i < end) {
      int byte = bytes[i++];
      if (byte < 0x80) {
        // ASCII.
        charCodes[j++] = byte;
      } else if (byte < 0xE0) {
        // Two-byte sequence (11-bit unicode value).
        int byte2 = bytes[i++];
        int value = (byte << 6) ^ byte2 ^ 0x3080;
        assert(value >= 0x80 && value < 0x800);
        charCodes[j++] = value;
      } else if (byte < 0xF0) {
        // Three-byte sequence (16-bit unicode value).
        int byte2 = bytes[i++];
        int byte3 = bytes[i++];
        int value = (byte << 12) ^ (byte2 << 6) ^ byte3 ^ 0xE2080;
        assert(value >= 0x800 && value < 0x10000);
        charCodes[j++] = value;
      } else {
        // Four-byte sequence (non-BMP unicode value).
        int byte2 = bytes[i++];
        int byte3 = bytes[i++];
        int byte4 = bytes[i++];
        int value =
            (byte << 18) ^ (byte2 << 12) ^ (byte3 << 6) ^ byte4 ^ 0x3C82080;
        assert(value >= 0x10000 && value < 0x110000);
        charCodes[j++] = 0xD7C0 + (value >> 10);
        charCodes[j++] = 0xDC00 + (value & 0x3FF);
      }
    }
    assert(i == end);
    return String.fromCharCodes(charCodes, 0, j);
  }
}
