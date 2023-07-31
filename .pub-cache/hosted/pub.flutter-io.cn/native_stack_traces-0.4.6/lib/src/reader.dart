// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

String paddedHex(int value, [int bytes = 0]) =>
    value.toRadixString(16).padLeft(2 * bytes, '0');

class Reader {
  final ByteData bdata;
  // These are mutable so we can update them, in case the endianness and
  // wordSize are read using the reader (e.g., ELF files).
  Endian? _endian;
  int? _wordSize;

  int _offset = 0;

  Endian get endian => _endian as Endian;
  set endian(Endian value) => _endian = value;
  int get wordSize => _wordSize as int;
  set wordSize(int value) => _wordSize = value;

  /// Unless provided, [wordSize] and [endian] are initialized to values that
  /// ensure no reads are made that depend on their value (e.g., readBytes).
  Reader.fromTypedData(TypedData data, {int? wordSize, Endian? endian})
      : _wordSize = wordSize,
        _endian = endian,
        bdata =
            ByteData.view(data.buffer, data.offsetInBytes, data.lengthInBytes);

  Reader.fromFile(String path, {int? wordSize, Endian? endian})
      : _wordSize = wordSize,
        _endian = endian,
        bdata = ByteData.sublistView(File(path).readAsBytesSync());

  /// Returns a reader focused on a different portion of the underlying buffer.
  Reader refocusedCopy(int pos, int size) {
    assert(pos >= 0 && pos < bdata.buffer.lengthInBytes);
    assert(size >= 0 && (pos + size) <= bdata.buffer.lengthInBytes);
    return Reader.fromTypedData(ByteData.view(bdata.buffer, pos, size),
        wordSize: _wordSize, endian: _endian);
  }

  int get start => bdata.offsetInBytes;
  int get offset => _offset;
  int get length => bdata.lengthInBytes;
  bool get done => _offset >= length;

  void seek(int offset, {bool absolute = false}) {
    final newOffset = (absolute ? 0 : _offset) + offset;
    assert(newOffset >= 0 && newOffset < bdata.lengthInBytes);
    _offset = newOffset;
  }

  int readBytes(int size, {bool signed = false}) {
    if (_offset + size > length) {
      throw ArgumentError('attempt to read $size bytes with only '
          '${length - _offset} bytes remaining in the reader');
    }
    final start = _offset;
    _offset += size;
    switch (size) {
      case 1:
        return signed ? bdata.getInt8(start) : bdata.getUint8(start);
      case 2:
        return signed
            ? bdata.getInt16(start, endian)
            : bdata.getUint16(start, endian);
      case 4:
        return signed
            ? bdata.getInt32(start, endian)
            : bdata.getUint32(start, endian);
      case 8:
        return signed
            ? bdata.getInt64(start, endian)
            : bdata.getUint64(start, endian);
      default:
        _offset -= size;
        throw ArgumentError('invalid request to read $size bytes');
    }
  }

  int readByte({bool signed = false}) => readBytes(1, signed: signed);
  int readWord() => readBytes(wordSize);
  String readNullTerminatedString() {
    final start = bdata.offsetInBytes + _offset;
    for (var i = 0; _offset + i < bdata.lengthInBytes; i++) {
      if (bdata.getUint8(_offset + i) == 0) {
        _offset += i + 1;
        return String.fromCharCodes(bdata.buffer.asUint8List(start, i));
      }
    }
    return String.fromCharCodes(
        bdata.buffer.asUint8List(start, bdata.lengthInBytes - _offset));
  }

  int readLEB128EncodedInteger({bool signed = false}) {
    var ret = 0;
    var shift = 0;
    for (var byte = readByte(); !done; byte = readByte()) {
      ret |= (byte & 0x7f) << shift;
      shift += 7;
      if (byte & 0x80 == 0) {
        if (signed && byte & 0x40 != 0) {
          ret |= -(1 << shift);
        }
        break;
      }
    }
    return ret;
  }

  /// Repeatedly calls [callback] with this reader to retrieve items.
  ///
  /// The key of the returned [MapEntry]s are the offsets of the items. If
  /// absolute is false, the offsets are from the reader position when
  /// [readRepeated] was invoked, otherwise they are absolute offsets from
  /// the start of the reader.
  ///
  /// Stops either when the reader is empty or when a null item is returned
  /// from the callback.
  Iterable<MapEntry<int, S>> readRepeatedWithOffsets<S>(
      S? Function(Reader) callback,
      {bool absolute = false}) sync* {
    final start = offset;
    while (!done) {
      final itemStart = offset;
      final item = callback(this);
      if (item == null) break;
      yield MapEntry(absolute ? itemStart : itemStart - start, item);
    }
  }

  Iterable<S> readRepeated<S>(S? Function(Reader) callback) =>
      readRepeatedWithOffsets(callback).map((kv) => kv.value);

  void writeCurrentReaderPosition(StringBuffer buffer,
      {int maxSize = 0, int bytesPerLine = 16}) {
    var baseData = ByteData.view(bdata.buffer, 0, bdata.buffer.lengthInBytes);
    var startOffset = 0;
    var endOffset = baseData.lengthInBytes;
    final currentOffset = start + _offset;
    if (maxSize != 0 && maxSize < baseData.lengthInBytes) {
      var lowerWindow = currentOffset - (maxSize >> 1);
      // Adjust so that we always start at the beginning of a line.
      lowerWindow -= lowerWindow % bytesPerLine;
      final upperWindow = lowerWindow + maxSize;
      startOffset = max(startOffset, lowerWindow);
      endOffset = min(endOffset, upperWindow);
    }
    for (var i = startOffset; i < endOffset; i += bytesPerLine) {
      buffer
        ..write('0x')
        ..write(paddedHex(i, 8))
        ..write(' ');
      for (var j = 0; j < bytesPerLine && i + j < endOffset; j++) {
        var byte = baseData.getUint8(i + j);
        buffer
          ..write(i + j == currentOffset ? '|' : ' ')
          ..write(paddedHex(byte, 1));
      }
      buffer.writeln();
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer
      ..write('Word size: ')
      ..write(_wordSize)
      ..writeln();
    buffer
      ..write('Endianness: ')
      ..write(_endian)
      ..writeln();
    buffer
      ..write('Start:  0x')
      ..write(paddedHex(start, _wordSize ?? 0))
      ..write(' (')
      ..write(start)
      ..writeln(')');
    buffer
      ..write('Offset: 0x')
      ..write(paddedHex(offset, _wordSize ?? 0))
      ..write(' (')
      ..write(offset)
      ..writeln(')');
    buffer
      ..write('Length: 0x')
      ..write(paddedHex(length, _wordSize ?? 0))
      ..write(' (')
      ..write(length)
      ..writeln(')');
    buffer.writeln('Bytes around current position:');
    writeCurrentReaderPosition(buffer, maxSize: 256);
    return buffer.toString();
  }
}
