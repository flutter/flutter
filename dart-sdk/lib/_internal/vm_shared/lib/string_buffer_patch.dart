// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;

import "dart:typed_data" show Uint16List;

@patch
class StringBuffer {
  static const int _BUFFER_SIZE = 64;
  static const int _PARTS_TO_COMPACT = 128;
  static const int _PARTS_TO_COMPACT_SIZE_LIMIT = _PARTS_TO_COMPACT * 8;

  /**
   * When strings are written to the string buffer, we add them to a
   * list of string parts.
   */
  List<String>? _parts;

  /**
    * Total number of code units in the string parts. Does not include
    * the code units added to the buffer.
    */
  int _partsCodeUnits = 0;

  /**
   * To preserve memory, we sometimes compact the parts. This combines
   * several smaller parts into a single larger part to cut down on the
   * cost that comes from the per-object memory overhead. We keep track
   * of the last index where we ended our compaction and the number of
   * code units added since the last compaction.
   */
  int _partsCompactionIndex = 0;
  int _partsCodeUnitsSinceCompaction = 0;

  /**
   * The buffer is used to build up a string from code units. It is
   * used when writing short strings or individual char codes to the
   * buffer. The buffer is allocated on demand.
   */
  Uint16List? _buffer;
  int _bufferPosition = 0;

  /**
   * Collects the approximate maximal magnitude of the code units added
   * to the buffer.
   *
   * The value of each added code unit is or'ed with this variable, so the
   * most significant bit set in any code unit is also set in this value.
   * If below 256, the string in the buffer is a Latin-1 string.
   */
  int _bufferCodeUnitMagnitude = 0;

  /// Creates the string buffer with an initial content.
  @patch
  StringBuffer([Object content = ""]) {
    write(content);
  }

  @patch
  int get length => _partsCodeUnits + _bufferPosition;

  @patch
  void write(Object? obj) {
    String str = "$obj";
    if (str.isEmpty) return;
    _consumeBuffer();
    _addPart(str);
  }

  @patch
  void writeCharCode(int charCode) {
    if (charCode <= 0xFFFF) {
      if (charCode < 0) {
        throw new RangeError.range(charCode, 0, 0x10FFFF);
      }
      _ensureCapacity(1);
      final localBuffer = _buffer!;
      localBuffer[_bufferPosition++] = charCode;
      _bufferCodeUnitMagnitude |= charCode;
    } else {
      if (charCode > 0x10FFFF) {
        throw new RangeError.range(charCode, 0, 0x10FFFF);
      }
      _ensureCapacity(2);
      int bits = charCode - 0x10000;
      final localBuffer = _buffer!;
      localBuffer[_bufferPosition++] = 0xD800 | (bits >> 10);
      localBuffer[_bufferPosition++] = 0xDC00 | (bits & 0x3FF);
      _bufferCodeUnitMagnitude |= 0xFFFF;
    }
  }

  @patch
  void writeAll(Iterable objects, [String separator = ""]) {
    Iterator iterator = objects.iterator;
    if (!iterator.moveNext()) return;
    if (separator.isEmpty) {
      do {
        write(iterator.current);
      } while (iterator.moveNext());
    } else {
      write(iterator.current);
      while (iterator.moveNext()) {
        write(separator);
        write(iterator.current);
      }
    }
  }

  @patch
  void writeln([Object? obj = ""]) {
    write(obj);
    write("\n");
  }

  /** Makes the buffer empty. */
  @patch
  void clear() {
    _parts = null;
    _partsCodeUnits = _bufferPosition = _bufferCodeUnitMagnitude = 0;
  }

  /** Returns the contents of buffer as a string. */
  @patch
  String toString() {
    _consumeBuffer();
    final localParts = _parts;
    return (_partsCodeUnits == 0 || localParts == null)
        ? ""
        : _StringBase._concatRange(localParts, 0, localParts.length);
  }

  /** Ensures that the buffer has enough capacity to add n code units. */
  void _ensureCapacity(int n) {
    final localBuffer = _buffer;
    if (localBuffer == null) {
      _buffer = new Uint16List(_BUFFER_SIZE);
    } else if (_bufferPosition + n > localBuffer.length) {
      _consumeBuffer();
    }
  }

  /**
   * Consumes the content of the buffer by turning it into a string
   * and adding it as a part. After calling this the buffer position
   * will be reset to zero.
   */
  void _consumeBuffer() {
    if (_bufferPosition == 0) return;
    bool isLatin1 = _bufferCodeUnitMagnitude <= 0xFF;
    String str = _create(_buffer!, _bufferPosition, isLatin1);
    _bufferPosition = _bufferCodeUnitMagnitude = 0;
    _addPart(str);
  }

  /**
   * Adds a new part to this string buffer and keeps track of how
   * many code units are contained in the parts.
   */
  void _addPart(String str) {
    final localParts = _parts;
    int length = str.length;
    _partsCodeUnits += length;
    _partsCodeUnitsSinceCompaction += length;

    if (localParts == null) {
      // Empirically this is a good capacity to minimize total bytes allocated.
      _parts = new _GrowableList.withCapacity(10)..add(str);
    } else {
      localParts.add(str);
      int partsSinceCompaction = localParts.length - _partsCompactionIndex;
      if (partsSinceCompaction == _PARTS_TO_COMPACT) {
        _compact();
      }
    }
  }

  /**
   * Compacts the last N parts if their average size allows us to save a
   * lot of memory by turning them all into a single part.
   */
  void _compact() {
    final localParts = _parts!;
    if (_partsCodeUnitsSinceCompaction < _PARTS_TO_COMPACT_SIZE_LIMIT) {
      String compacted = _StringBase._concatRange(
          localParts,
          _partsCompactionIndex, // Start
          _partsCompactionIndex + _PARTS_TO_COMPACT // End
          );
      localParts.length = localParts.length - _PARTS_TO_COMPACT;
      localParts.add(compacted);
    }
    _partsCodeUnitsSinceCompaction = 0;
    _partsCompactionIndex = localParts.length;
  }

  /**
   * Create a [String] from the UFT-16 code units in buffer.
   */
  @pragma("vm:external-name", "StringBuffer_createStringFromUint16Array")
  external static String _create(Uint16List buffer, int length, bool isLatin1);
}
