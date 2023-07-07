// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: constant_identifier_names

part of protobuf;

/// Writer used for converting [GeneratedMessage]s into binary
/// representation.
///
/// Note that it is impossible to serialize protobuf messages using a one pass
/// streaming serialization as some values are serialized using
/// length-delimited representation, which means that they are represented as
/// a varint encoded length followed by specified number of bytes of data.
///
/// Due to this [CodedBufferWriter] maintains two output buffers:
/// [_outputChunks] which contains all continuously written bytes and
/// [_splices] which describes additional bytes to splice in-between
/// [_outputChunks] bytes.
///
class CodedBufferWriter {
  /// Array of splices representing the data written into the writer.
  /// Each element might be one of:
  ///   * a TypedData object - represents a sequence of bytes that need to be
  ///                          emitted into the result as-is;
  ///   * a positive integer - a number of bytes to copy from [_outputChunks]
  ///                          into resulting buffer;
  ///   * a non-positive integer - a positive number that needs to be emitted
  ///                              into result buffer as a varint;
  final List<dynamic> _splices = <dynamic>[];

  /// Number of bytes written into [_outputChunk] and [_outputChunks] since
  /// the last splice was recorded.
  int _lastSplicePos = 0;

  /// Size of the [_outputChunk].
  static const _chunkLength = 512;

  /// Current chunk used to write data into. Once it is full it is
  /// pushed into [_outputChunks] and a new one is allocated.
  Uint8List? _outputChunk;

  /// Number of bytes written into the [_outputChunk].
  int _bytesInChunk = 0;

  /// ByteData pointing to [_outputChunk]. Used to write primitive values
  /// more efficiently.
  ByteData? _outputChunkAsByteData;

  /// Array of pairs <Uint8List chunk, int bytesInChunk> - chunks are
  /// pushed into this array once they are full.
  final List<dynamic> _outputChunks = <dynamic>[];

  /// Total amount of bytes used in all chunks.
  int _outputChunksBytes = 0;

  /// Total amount of bytes written into this writer.
  int _bytesTotal = 0;
  int get lengthInBytes => _bytesTotal;

  CodedBufferWriter() {
    // Initialize [_outputChunk].
    _commitChunk(true);
  }

  void writeField(int fieldNumber, int fieldType, fieldValue) {
    final valueType = PbFieldType._baseType(fieldType);

    if ((fieldType & PbFieldType._PACKED_BIT) != 0) {
      if (!fieldValue.isEmpty) {
        _writeTag(fieldNumber, WIRETYPE_LENGTH_DELIMITED);
        final mark = _startLengthDelimited();
        for (var value in fieldValue) {
          _writeValueAs(valueType, value);
        }
        _endLengthDelimited(mark);
      }
      return;
    }

    if ((fieldType & PbFieldType._MAP_BIT) != 0) {
      final keyWireFormat =
          _wireTypes[_valueTypeIndex(fieldValue.keyFieldType)];
      final valueWireFormat =
          _wireTypes[_valueTypeIndex(fieldValue.valueFieldType)];

      fieldValue.forEach((key, value) {
        _writeTag(fieldNumber, WIRETYPE_LENGTH_DELIMITED);
        final mark = _startLengthDelimited();
        _writeValue(
            PbMap._keyFieldNumber, fieldValue.keyFieldType, key, keyWireFormat);
        _writeValue(PbMap._valueFieldNumber, fieldValue.valueFieldType, value,
            valueWireFormat);
        _endLengthDelimited(mark);
      });
      return;
    }

    final wireFormat = _wireTypes[_valueTypeIndex(valueType)];

    if ((fieldType & PbFieldType._REPEATED_BIT) != 0) {
      for (var i = 0; i < fieldValue.length; i++) {
        _writeValue(fieldNumber, valueType, fieldValue[i], wireFormat);
      }
      return;
    }
    _writeValue(fieldNumber, valueType, fieldValue, wireFormat);
  }

  Uint8List toBuffer() {
    var result = Uint8List(_bytesTotal);
    writeTo(result);
    return result;
  }

  /// Serializes everything written to this writer so far to [buffer], starting
  /// from [offset] in [buffer]. Returns `true` on success.
  bool writeTo(Uint8List buffer, [int offset = 0]) {
    if (buffer.length - offset < _bytesTotal) {
      return false;
    }

    // Move the current output chunk into _outputChunks and commit the current
    // splice for uniformity.
    _commitChunk(false);
    _commitSplice();

    var outPos = offset; // Output position in the buffer.
    var chunkIndex = 0, chunkPos = 0; // Position within _outputChunks.
    for (var i = 0; i < _splices.length; i++) {
      final action = _splices[i];
      if (action is int) {
        if (action <= 0) {
          // action is a positive varint to be emitted into the output buffer.
          var v = 0 - action; // Note: 0 - action to avoid -0.0 in JS.
          while (v >= 0x80) {
            buffer[outPos++] = 0x80 | (v & 0x7f);
            v >>= 7;
          }
          buffer[outPos++] = v;
        } else {
          // action is an amount of bytes to copy from _outputChunks into the
          // buffer.
          var bytesToCopy = action;
          while (bytesToCopy > 0) {
            final Uint8List chunk = _outputChunks[chunkIndex];
            final int bytesInChunk = _outputChunks[chunkIndex + 1];

            // Copy at most bytesToCopy bytes from the current chunk.
            final leftInChunk = bytesInChunk - chunkPos;
            final bytesToCopyFromChunk =
                leftInChunk > bytesToCopy ? bytesToCopy : leftInChunk;
            final endPos = chunkPos + bytesToCopyFromChunk;
            while (chunkPos < endPos) {
              buffer[outPos++] = chunk[chunkPos++];
            }
            bytesToCopy -= bytesToCopyFromChunk;

            // Move to the next chunk if the current one is exhausted.
            if (chunkPos == bytesInChunk) {
              chunkIndex += 2;
              chunkPos = 0;
            }
          }
        }
      } else {
        // action is a TypedData containing bytes to emit into the output
        // buffer.
        outPos = _copyInto(buffer, outPos, action);
      }
    }

    return true;
  }

  /// Move the current [_outputChunk] into [_outputChunks].
  ///
  /// If [allocateNew] is `true` then allocate a new chunk, otherwise
  /// set [_outputChunk] to `null`.
  void _commitChunk(bool allocateNew) {
    if (_bytesInChunk != 0) {
      _outputChunks.add(_outputChunk);
      _outputChunks.add(_bytesInChunk);
      _outputChunksBytes += _bytesInChunk;
    }

    if (allocateNew) {
      _outputChunk = Uint8List(_chunkLength);
      _bytesInChunk = 0;
      _outputChunkAsByteData = ByteData.view(_outputChunk!.buffer);
    } else {
      _outputChunk = _outputChunkAsByteData = null;
      _bytesInChunk = 0;
    }
  }

  /// Check if [count] bytes would fit into the current chunk. If they will
  /// not then allocate a new [_outputChunk].
  ///
  /// [count] is assumed to be small enough to fit into the newly allocated
  /// chunk.
  void _ensureBytes(int count) {
    if ((_bytesInChunk + count) > _chunkLength) {
      _commitChunk(true);
    }
  }

  /// Record number of bytes written into output chunks since last splice.
  ///
  /// This is used before reserving space for an unknown varint splice or
  /// adding a TypedData array splice.
  void _commitSplice() {
    final pos = _bytesInChunk + _outputChunksBytes;
    final bytes = pos - _lastSplicePos;
    if (bytes > 0) {
      _splices.add(bytes);
    }
    _lastSplicePos = pos;
  }

  /// Add TypedData splice - these bytes would be directly copied into the
  /// output buffer by [writeTo].
  void writeRawBytes(TypedData value) {
    _commitSplice();
    _splices.add(value);
    _bytesTotal += value.lengthInBytes;
  }

  /// Start writing a length-delimited data.
  ///
  /// This reserves the space for varint splice in the splices array and
  /// return its index. Once the writing is finished [_endLengthDelimited]
  /// would be called with this index - which would put the actual amount
  /// of bytes written into the reserved slice space.
  int _startLengthDelimited() {
    _commitSplice();
    var index = _splices.length;
    // Reserve a space for a splice and use it to record the current number of
    // bytes written so that we can compute the length of data later in
    // _endLengthDelimited.
    _splices.add(_bytesTotal);
    return index;
  }

  void _endLengthDelimited(int index) {
    final writtenSizeInBytes = _bytesTotal - _splices[index] as int;
    // Note: 0 - writtenSizeInBytes to avoid -0.0 in JavaScript.
    _splices[index] = 0 - writtenSizeInBytes;
    _bytesTotal += _varint32LengthInBytes(writtenSizeInBytes);
  }

  int _varint32LengthInBytes(int value) {
    value &= 0xFFFFFFFF;
    if (value < 0x80) return 1;
    if (value < 0x4000) return 2;
    if (value < 0x200000) return 3;
    if (value < 0x10000000) return 4;
    return 5;
  }

  void _writeVarint32(int value) {
    _ensureBytes(5);
    var i = _bytesInChunk;
    while (value >= 0x80) {
      _outputChunk![i++] = 0x80 | (value & 0x7f);
      value >>= 7;
    }
    _outputChunk![i++] = value;
    _bytesTotal += (i - _bytesInChunk);
    _bytesInChunk = i;
  }

  void _writeVarint64(Int64 value) {
    _ensureBytes(10);
    var i = _bytesInChunk;
    var lo = value.toUnsigned(32).toInt();
    var hi = (value >> 32).toUnsigned(32).toInt();
    while (hi > 0 || lo >= 0x80) {
      _outputChunk![i++] = 0x80 | (lo & 0x7f);
      lo = (lo >> 7) | ((hi & 0x7f) << 25);
      hi >>= 7;
    }
    _outputChunk![i++] = lo;
    _bytesTotal += (i - _bytesInChunk);
    _bytesInChunk = i;
  }

  void _writeDouble(double value) {
    if (value.isNaN) {
      _writeInt32(0x00000000);
      _writeInt32(0x7ff80000);
      return;
    }
    _ensureBytes(8);
    _outputChunkAsByteData!.setFloat64(_bytesInChunk, value, Endian.little);
    _bytesInChunk += 8;
    _bytesTotal += 8;
  }

  void _writeFloat(double value) {
    const MIN_FLOAT_DENORM = 1.401298464324817E-45;
    const MAX_FLOAT = 3.4028234663852886E38;
    if (value.isNaN) {
      _writeInt32(0x7fc00000);
    } else if (value.abs() < MIN_FLOAT_DENORM) {
      _writeInt32(value.isNegative ? 0x80000000 : 0x00000000);
    } else if (value.isInfinite || value.abs() > MAX_FLOAT) {
      _writeInt32(value.isNegative ? 0xff800000 : 0x7f800000);
    } else {
      const sz = 4;
      _ensureBytes(sz);
      _outputChunkAsByteData!.setFloat32(_bytesInChunk, value, Endian.little);
      _bytesInChunk += sz;
      _bytesTotal += sz;
    }
  }

  void _writeInt32(int value) {
    const sizeInBytes = 4;
    _ensureBytes(sizeInBytes);
    _outputChunkAsByteData!
        .setInt32(_bytesInChunk, value & 0xFFFFFFFF, Endian.little);
    _bytesInChunk += sizeInBytes;
    _bytesTotal += sizeInBytes;
  }

  void _writeInt64(Int64 value) {
    _writeInt32(value.toUnsigned(32).toInt());
    _writeInt32((value >> 32).toUnsigned(32).toInt());
  }

  void _writeValueAs(int valueType, dynamic value) {
    switch (valueType) {
      case PbFieldType._BOOL_BIT:
        _writeVarint32(value ? 1 : 0);
        break;
      case PbFieldType._BYTES_BIT:
        _writeBytesNoTag(
            value is TypedData ? value : Uint8List.fromList(value));
        break;
      case PbFieldType._STRING_BIT:
        _writeBytesNoTag(_utf8.encode(value));
        break;
      case PbFieldType._DOUBLE_BIT:
        _writeDouble(value);
        break;
      case PbFieldType._FLOAT_BIT:
        _writeFloat(value);
        break;
      case PbFieldType._ENUM_BIT:
        _writeVarint32(value.value & 0xffffffff);
        break;
      case PbFieldType._GROUP_BIT:
        value.writeToCodedBufferWriter(this);
        break;
      case PbFieldType._INT32_BIT:
        _writeVarint64(Int64(value));
        break;
      case PbFieldType._INT64_BIT:
        _writeVarint64(value);
        break;
      case PbFieldType._SINT32_BIT:
        _writeVarint32(_encodeZigZag32(value));
        break;
      case PbFieldType._SINT64_BIT:
        _writeVarint64(_encodeZigZag64(value));
        break;
      case PbFieldType._UINT32_BIT:
        _writeVarint32(value);
        break;
      case PbFieldType._UINT64_BIT:
        _writeVarint64(value);
        break;
      case PbFieldType._FIXED32_BIT:
        _writeInt32(value);
        break;
      case PbFieldType._FIXED64_BIT:
        _writeInt64(value);
        break;
      case PbFieldType._SFIXED32_BIT:
        _writeInt32(value);
        break;
      case PbFieldType._SFIXED64_BIT:
        _writeInt64(value);
        break;
      case PbFieldType._MESSAGE_BIT:
        final mark = _startLengthDelimited();
        value.writeToCodedBufferWriter(this);
        _endLengthDelimited(mark);
        break;
    }
  }

  void _writeBytesNoTag(dynamic value) {
    writeInt32NoTag(value.length);
    writeRawBytes(value);
  }

  void _writeTag(int fieldNumber, int wireFormat) {
    writeInt32NoTag(makeTag(fieldNumber, wireFormat));
  }

  void _writeValue(
      int fieldNumber, int valueType, dynamic value, int wireFormat) {
    _writeTag(fieldNumber, wireFormat);
    _writeValueAs(valueType, value);
    if (valueType == PbFieldType._GROUP_BIT) {
      _writeTag(fieldNumber, WIRETYPE_END_GROUP);
    }
  }

  void writeInt32NoTag(int value) {
    _writeVarint32(value & 0xFFFFFFFF);
  }

  /// Copy bytes from the given typed data array into the output buffer.
  ///
  /// Has a specialization for Uint8List for performance.
  int _copyInto(Uint8List buffer, int pos, TypedData value) {
    if (value is Uint8List) {
      var len = value.length;
      for (var j = 0; j < len; j++) {
        buffer[pos++] = value[j];
      }
      return pos;
    } else {
      var len = value.lengthInBytes;
      var u8 = Uint8List.view(
          value.buffer, value.offsetInBytes, value.lengthInBytes);
      for (var j = 0; j < len; j++) {
        buffer[pos++] = u8[j];
      }
      return pos;
    }
  }

  /// This function maps a power-of-2 value (2^0 .. 2^31) to a unique value
  /// in the 0..31 range.
  ///
  /// For more details see "Using de Bruijn Sequences to Index a 1 in
  /// a Computer Word"[1]
  ///
  /// Note: this is guaranteed to work after compilation to JavaScript
  /// where multiplication becomes a floating point multiplication.
  ///
  /// [1] http://supertech.csail.mit.edu/papers/debruijn.pdf
  int _valueTypeIndex(int powerOf2) {
    assert(powerOf2 & (powerOf2 - 1) == 0, '$powerOf2 is not a power of 2');
    return ((0x077CB531 * powerOf2) >> 27) & 31;
  }

  /// Precomputed indices for all FbFieldType._XYZ_BIT values:
  ///
  ///    _XYZ_BIT_INDEX = _valueTypeIndex(FbFieldType._XYZ_BIT)
  ///
  static const _BOOL_BIT_INDEX = 14;
  static const _BYTES_BIT_INDEX = 29;
  static const _STRING_BIT_INDEX = 27;
  static const _DOUBLE_BIT_INDEX = 23;
  static const _FLOAT_BIT_INDEX = 15;
  static const _ENUM_BIT_INDEX = 31;
  static const _GROUP_BIT_INDEX = 30;
  static const _INT32_BIT_INDEX = 28;
  static const _INT64_BIT_INDEX = 25;
  static const _SINT32_BIT_INDEX = 18;
  static const _SINT64_BIT_INDEX = 5;
  static const _UINT32_BIT_INDEX = 11;
  static const _UINT64_BIT_INDEX = 22;
  static const _FIXED32_BIT_INDEX = 13;
  static const _FIXED64_BIT_INDEX = 26;
  static const _SFIXED32_BIT_INDEX = 21;
  static const _SFIXED64_BIT_INDEX = 10;
  static const _MESSAGE_BIT_INDEX = 20;

  /// Mapping from value types to wire-types indexed by _valueTypeIndex(...).
  static final Uint8List _wireTypes = Uint8List(32)
    ..[_BOOL_BIT_INDEX] = WIRETYPE_VARINT
    ..[_BYTES_BIT_INDEX] = WIRETYPE_LENGTH_DELIMITED
    ..[_STRING_BIT_INDEX] = WIRETYPE_LENGTH_DELIMITED
    ..[_DOUBLE_BIT_INDEX] = WIRETYPE_FIXED64
    ..[_FLOAT_BIT_INDEX] = WIRETYPE_FIXED32
    ..[_ENUM_BIT_INDEX] = WIRETYPE_VARINT
    ..[_GROUP_BIT_INDEX] = WIRETYPE_START_GROUP
    ..[_INT32_BIT_INDEX] = WIRETYPE_VARINT
    ..[_INT64_BIT_INDEX] = WIRETYPE_VARINT
    ..[_SINT32_BIT_INDEX] = WIRETYPE_VARINT
    ..[_SINT64_BIT_INDEX] = WIRETYPE_VARINT
    ..[_UINT32_BIT_INDEX] = WIRETYPE_VARINT
    ..[_UINT64_BIT_INDEX] = WIRETYPE_VARINT
    ..[_FIXED32_BIT_INDEX] = WIRETYPE_FIXED32
    ..[_FIXED64_BIT_INDEX] = WIRETYPE_FIXED64
    ..[_SFIXED32_BIT_INDEX] = WIRETYPE_FIXED32
    ..[_SFIXED64_BIT_INDEX] = WIRETYPE_FIXED64
    ..[_MESSAGE_BIT_INDEX] = WIRETYPE_LENGTH_DELIMITED;
}

int _encodeZigZag32(int value) => (value << 1) ^ (value >> 31);
Int64 _encodeZigZag64(Int64 value) => (value << 1) ^ (value >> 63);
