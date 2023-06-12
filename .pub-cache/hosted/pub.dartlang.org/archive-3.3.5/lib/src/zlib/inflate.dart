import 'dart:typed_data';
import '../util/input_stream.dart';
import '../util/output_stream.dart';
import 'huffman_table.dart';

class Inflate {
  late InputStreamBase input;
  bool inputSet = false;
  dynamic output;

  Inflate(List<int> bytes, [int? uncompressedSize])
      : input = InputStream(bytes),
        output = OutputStream(size: uncompressedSize) {
    inputSet = true;
    _inflate();
  }

  Inflate.buffer(this.input, [int? uncompressedSize])
      : output = OutputStream(size: uncompressedSize) {
    inputSet = true;
    _inflate();
  }

  Inflate.stream([InputStreamBase? input, dynamic outputStream])
      : output = outputStream ?? OutputStream() {
    if (input != null) {
      this.input = input;
      inputSet = true;
    }
    _inflate();
  }

  void streamInput(List<int> bytes) {
    if (inputSet && input is InputStream) {
      var i = input as InputStream;
      i.offset = _blockPos;
      final inputLen = input.length;
      final newLen = inputLen + bytes.length;
      final newBytes = Uint8List(newLen);
      newBytes.setRange(0, inputLen, i.buffer, i.offset);
      newBytes.setRange(inputLen, newLen, bytes, 0);

      input = InputStream(newBytes);
    } else {
      input = InputStream(bytes);
    }
    inputSet = true;
  }

  List<int>? inflateNext() {
    _bitBuffer = 0;
    _bitBufferLen = 0;
    if (output is OutputStream) {
      output.clear();
    }
    if (!inputSet || input.isEOS) {
      return null;
    }

    try {
      if (input is InputStream) {
        var i = input as InputStream;
        _blockPos = i.offset;
      }
      _parseBlock();
      // If it didn't finish reading the block, it will have thrown an exception
      _blockPos = 0;
    } catch (e) {
      return null;
    }

    if (output is OutputStream) {
      return output.getBytes() as List<int>;
    }
    return null;
  }

  /// Get the decompressed data.
  List<int> getBytes() {
    return output.getBytes() as List<int>;
  }

  void _inflate() {
    _bitBuffer = 0;
    _bitBufferLen = 0;
    if (!inputSet) {
      return;
    }

    while (!input.isEOS) {
      if (!_parseBlock()) {
        break;
      }
    }
  }

  /// Parse deflated block.  Returns true if there is more to read, false
  /// if we're done.
  bool _parseBlock() {
    if (input.isEOS) {
      return false;
    }

    // Each block has a 3-bit header
    final blockHeader = _readBits(3);

    // BFINAL (is this the final block)?
    final finalBlock = (blockHeader & 0x1) != 0;

    // BTYPE (the type of block)
    final blockType = blockHeader >> 1;
    switch (blockType) {
      case 0: // Uncompressed block
        if (_parseUncompressedBlock() == -1) {
          return false;
        }
        break;
      case 1: // Fixed huffman block
        if (_parseFixedHuffmanBlock() == -1) {
          return false;
        }
        break;
      case 2: // Dynamic huffman block
        if (_parseDynamicHuffmanBlock() == -1) {
          return false;
        }
        break;
      default:
        return false;
    }

    // Continue while not the final block
    return !finalBlock;
  }

  /// Read a number of bits from the input stream.
  int _readBits(int length) {
    if (length == 0) {
      return 0;
    }

    // not enough buffer
    while (_bitBufferLen < length) {
      if (input.isEOS) {
        return -1;
      }

      // input byte
      final octet = input.readByte();

      // concat octet
      _bitBuffer |= octet << _bitBufferLen;
      _bitBufferLen += 8;
    }

    // output byte
    final octet = _bitBuffer & ((1 << length) - 1);
    _bitBuffer >>= length;
    _bitBufferLen -= length;

    return octet;
  }

  /// Read huffman code using [table].
  int _readCodeByTable(HuffmanTable table) {
    final codeTable = table.table;
    final maxCodeLength = table.maxCodeLength;

    // Not enough buffer
    while (_bitBufferLen < maxCodeLength) {
      if (input.isEOS) {
        return -1;
      }

      final octet = input.readByte();

      _bitBuffer |= octet << _bitBufferLen;
      _bitBufferLen += 8;
    }

    // read max length
    final codeWithLength = codeTable[_bitBuffer & ((1 << maxCodeLength) - 1)];
    final codeLength = codeWithLength >> 16;

    _bitBuffer >>= codeLength;
    _bitBufferLen -= codeLength;

    return codeWithLength & 0xffff;
  }

  int _parseUncompressedBlock() {
    // skip buffered header bits
    _bitBuffer = 0;
    _bitBufferLen = 0;

    final len = _readBits(16);
    final nlen = _readBits(16) ^ 0xffff;

    // Make sure the block size checksum is valid.
    if (len != 0 && len != nlen) {
      return -1;
    }

    // check size
    if (len > input.length) {
      return -1;
    }

    output.writeInputStream(input.readBytes(len));
    return 0;
  }

  int _parseFixedHuffmanBlock() {
    return _decodeHuffman(_fixedLiteralLengthTable, _fixedDistanceTable);
  }

  int _parseDynamicHuffmanBlock() {
    // number of literal and length codes.
    var numLitLengthCodes = _readBits(5);
    if (numLitLengthCodes == -1) {
      return -1;
    }
    numLitLengthCodes += 257;
    if (numLitLengthCodes > 288) {
      return - 1;
    }
    // number of distance codes.
    var numDistanceCodes = _readBits(5);
    if (numDistanceCodes == -1) {
      return -1;
    }
    numDistanceCodes += 1;
    if (numDistanceCodes > 32) {
      return -1;
    }
    // number of code lengths.
    var numCodeLengths = _readBits(4);
    if (numCodeLengths == -1) {
      return -1;
    }
    numCodeLengths += 4;
    if (numCodeLengths > 19) {
      return -1;
    }

    // decode code lengths
    final codeLengths = Uint8List(_order.length);
    for (var i = 0; i < numCodeLengths; ++i) {
      final len = _readBits(3);
      if (len == -1) {
        return -1;
      }
      codeLengths[_order[i]] = len;
    }

    final codeLengthsTable = HuffmanTable(codeLengths);

    final litLenDistLengths = Uint8List(numLitLengthCodes + numDistanceCodes);

    // literal and length code
    final litlenLengths = Uint8List.view(litLenDistLengths.buffer, 0, numLitLengthCodes);

    // distance code
    final distLengths = Uint8List.view(litLenDistLengths.buffer, numLitLengthCodes, numDistanceCodes);

    if (_decode(litLenDistLengths.length, codeLengthsTable, litLenDistLengths) == -1) {
      return -1;
    }

    return _decodeHuffman(HuffmanTable(litlenLengths), HuffmanTable(distLengths));
  }

  int _decodeHuffman(HuffmanTable litlen, HuffmanTable dist) {
    while (true) {
      final code = _readCodeByTable(litlen);
      if (code < 0 || code > 285) {
        return -1;
      }

      // 256 - End of Huffman block
      if (code == 256) {
        break;
      }

      // [0, 255] - Literal
      if (code < 256) {
        output.writeByte(code & 0xff);
        continue;
      }

      // [257, 285] Dictionary Lookup
      // length code
      final ti = code - 257;

      var codeLength =
          _lengthCodeTable[ti] + _readBits(_lengthExtraTable[ti]);

      // distance code
      final distCode = _readCodeByTable(dist);
      if (distCode < 0 || distCode > 29) {
        return -1;
      }
      final distance =
          _distCodeTable[distCode] + _readBits(_distExtraTable[distCode]);

      // lz77 decode
      while (codeLength > distance) {
        output.writeBytes(output.subset(-distance));
        codeLength -= distance;
      }

      if (codeLength == distance) {
        output.writeBytes(output.subset(-distance));
      } else {
        output.writeBytes(output.subset(-distance, codeLength - distance));
      }
    }

    while (_bitBufferLen >= 8) {
      _bitBufferLen -= 8;
      input.rewind(1);
    }

    return 0;
  }

  int _decode(int num, HuffmanTable table, List<int> codeLengths) {
    var prev = 0;
    var i = 0;
    while (i < num) {
      final code = _readCodeByTable(table);
      if (code == -1) {
        return -1;
      }
      switch (code) {
        case 16:
          // Repeat last code
          var repeat = _readBits(2);
          if (repeat == -1) {
            return -1;
          }
          repeat += 3;
          while (repeat-- > 0) {
            codeLengths[i++] = prev;
          }
          break;
        case 17:
          // Repeat 0
          var repeat = _readBits(3);
          if (repeat == -1) {
            return -1;
          }
          repeat += 3;
          while (repeat-- > 0) {
            codeLengths[i++] = 0;
          }
          prev = 0;
          break;
        case 18:
          // Repeat lots of 0s.
          var repeat = _readBits(7);
          if (repeat == -1) {
            return - 1;
          }
          repeat += 11;
          while (repeat-- > 0) {
            codeLengths[i++] = 0;
          }
          prev = 0;
          break;
        default: // [0, 15]
          // Literal bitlength for this code.
          if (code < 0 || code > 15) {
            return -1;
          }
          codeLengths[i++] = code;
          prev = code;
          break;
      }
    }

    return 0;
  }

  int _bitBuffer = 0;
  int _bitBufferLen = 0;
  int _blockPos = 0;

  /// Fixed huffman length code table
  static const List<int> _fixedLiteralLengths = [
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    9,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    7,
    8,
    8,
    8,
    8,
    8,
    8,
    8,
    8
  ];
  final HuffmanTable _fixedLiteralLengthTable =
      HuffmanTable(_fixedLiteralLengths);

  /// Fixed huffman distance code table
  static const List<int> _fixedDistanceTableData = [
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5,
    5
  ];
  final HuffmanTable _fixedDistanceTable = HuffmanTable(_fixedDistanceTableData);

    /// Huffman order
  static const List<int> _order = [
    16,
    17,
    18,
    0,
    8,
    7,
    9,
    6,
    10,
    5,
    11,
    4,
    12,
    3,
    13,
    2,
    14,
    1,
    15
  ];

  /// Huffman length code table.
  static const List<int> _lengthCodeTable = [
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    13,
    15,
    17,
    19,
    23,
    27,
    31,
    35,
    43,
    51,
    59,
    67,
    83,
    99,
    115,
    131,
    163,
    195,
    227,
    258
  ];

  /// Huffman length extra-bits table.
  static const List<int> _lengthExtraTable = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    1,
    1,
    1,
    1,
    2,
    2,
    2,
    2,
    3,
    3,
    3,
    3,
    4,
    4,
    4,
    4,
    5,
    5,
    5,
    5,
    0,
    0,
    0
  ];

  /// Huffman dist code table.
  static const List<int> _distCodeTable = [
    1,
    2,
    3,
    4,
    5,
    7,
    9,
    13,
    17,
    25,
    33,
    49,
    65,
    97,
    129,
    193,
    257,
    385,
    513,
    769,
    1025,
    1537,
    2049,
    3073,
    4097,
    6145,
    8193,
    12289,
    16385,
    24577
  ];

  /// Huffman dist extra-bits table.
  static const List<int> _distExtraTable = [
    0,
    0,
    0,
    0,
    1,
    1,
    2,
    2,
    3,
    3,
    4,
    4,
    5,
    5,
    6,
    6,
    7,
    7,
    8,
    8,
    9,
    9,
    10,
    10,
    11,
    11,
    12,
    12,
    13,
    13
  ];
}
