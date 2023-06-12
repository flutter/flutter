import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'util/archive_exception.dart';
import 'util/crc32.dart';
import 'util/crc64.dart';
import 'util/input_stream.dart';

import 'lzma/lzma_decoder.dart';

// The XZ specification can be found at
// https://tukaani.org/xz/xz-file-format.txt.

/// Decompress data with the xz format decoder.
class XZDecoder {
  List<int> decodeBytes(List<int> data, {bool verify = false}) {
    return decodeBuffer(InputStream(data), verify: verify);
  }

  List<int> decodeBuffer(InputStreamBase input, {bool verify = false}) {
    var decoder = _XZStreamDecoder(verify: verify);
    return decoder.decode(input);
  }
}

/// Decodes an XZ stream.
class _XZStreamDecoder {
  // True if checksums are confirmed.
  final bool verify;

  // Decoded data.
  final data = BytesBuilder();

  // LZMA decoder.
  final decoder = LzmaDecoder();

  // Stream flags, which are sent in both the header and the footer.
  var streamFlags = 0;

  // Block sizes.
  final _blockSizes = <_XZBlockSize>[];

  _XZStreamDecoder({this.verify = false});

  // Decode this stream and return the uncompressed data.
  List<int> decode(InputStreamBase input) {
    _readStreamHeader(input);

    while (true) {
      var blockHeader = input.peekBytes(1).readByte();

      if (blockHeader == 0) {
        var indexSize = _readStreamIndex(input);
        _readStreamFooter(input, indexSize);
        return data.takeBytes();
      }

      var blockLength = (blockHeader + 1) * 4;
      _readBlock(input, blockLength);
    }
  }

  // Reads an XZ steam header from [input].
  void _readStreamHeader(InputStreamBase input) {
    final magic = input.readBytes(6).toUint8List();
    final magicIsValid = magic[0] == 253 &&
        magic[1] == 55 /* '7' */ &&
        magic[2] == 122 /* 'z' */ &&
        magic[3] == 88 /* 'X' */ &&
        magic[4] == 90 /* 'Z' */ &&
        magic[5] == 0;
    if (!magicIsValid) {
      throw ArchiveException('Invalid XZ stream header signature');
    }

    final header = input.readBytes(2);
    if (header.readByte() != 0) {
      throw ArchiveException('Invalid stream flags');
    }
    streamFlags = header.readByte();
    header.reset();

    final crc = input.readUint32();
    if (getCrc32(header.toUint8List()) != crc) {
      throw ArchiveException('Invalid stream header CRC checksum');
    }
  }

  // Reads a data block from [input].
  void _readBlock(InputStreamBase input, int headerLength) {
    final blockStart = input.position;
    final header = input.readBytes(headerLength - 4);

    header.skip(1); // Skip length field
    final blockFlags = header.readByte();
    final nFilters = (blockFlags & 0x3) + 1;
    final hasCompressedLength = blockFlags & 0x40 != 0;
    final hasUncompressedLength = blockFlags & 0x80 != 0;

    int? compressedLength;
    if (hasCompressedLength) {
      compressedLength = _readMultibyteInteger(header);
    }
    int? uncompressedLength;
    if (hasUncompressedLength) {
      uncompressedLength = _readMultibyteInteger(header);
    }

    final filters = <int>[];
    var dictionarySize = 0;
    for (var i = 0; i < nFilters; i++) {
      final id = _readMultibyteInteger(header);
      final propertiesLength = _readMultibyteInteger(header);
      final properties = header.readBytes(propertiesLength).toUint8List();
      if (id == 0x03) {
        // delta filter
        final distance = properties[0];
        filters.add(id);
        filters.add(distance);
      } else if (id == 0x21) {
        // lzma2 filter
        final v = properties[0];
        if (v > 40) {
          throw ArchiveException('Invalid LZMA dictionary size');
        } else if (v == 40) {
          dictionarySize = 0xffffffff;
        } else {
          final mantissa = 2 | (v & 0x1);
          final exponent = (v >> 1) + 11;
          dictionarySize = mantissa << exponent;
        }
        filters.add(id);
        filters.add(dictionarySize);
      } else {
        filters.add(id);
        filters.add(0);
      }
    }
    _readPadding(header);
    header.reset();

    final crc = input.readUint32();
    if (getCrc32(header.toUint8List()) != crc) {
      throw ArchiveException('Invalid block CRC checksum');
    }

    if (filters.length != 2 && filters.first != 0x21) {
      throw ArchiveException('Unsupported filters');
    }

    final startPosition = input.position;
    final startDataLength = data.length;

    _readLZMA2(input, dictionarySize);

    final actualCompressedLength = input.position - startPosition;
    final actualUncompressedLength = data.length - startDataLength;

    if (compressedLength != null &&
        compressedLength != actualCompressedLength) {
      throw ArchiveException("Compressed data doesn't match expected length");
    }

    uncompressedLength ??= actualUncompressedLength;
    if (uncompressedLength != actualUncompressedLength) {
      throw ArchiveException("Uncompressed data doesn't match expected length");
    }

    final paddingSize = _readPadding(input);

    // Checksum
    final checkType = streamFlags & 0xf;
    switch (checkType) {
      case 0: // none
        break;
      case 0x1: // CRC32
        final expectedCrc = input.readUint32();
        if (verify) {
          final actualCrc = getCrc32(data.toBytes().sublist(startDataLength));
          if (actualCrc != expectedCrc) {
            throw ArchiveException('CRC32 check failed');
          }
        }
        break;
      case 0x2:
      case 0x3:
        input.skip(4);
        if (verify) {
          throw ArchiveException('Unknown check type $checkType');
        }
        break;
      case 0x4: // CRC64
        final expectedCrc = input.readUint64();
        if (verify && isCrc64Supported()) {
          final actualCrc = getCrc64(data.toBytes().sublist(startDataLength));
          if (actualCrc != expectedCrc) {
            throw ArchiveException('CRC64 check failed');
          }
        }
        break;
      case 0x5:
      case 0x6:
        input.skip(8);
        if (verify) {
          throw ArchiveException('Unknown check type $checkType');
        }
        break;
      case 0x7:
      case 0x8:
      case 0x9:
        input.skip(16);
        if (verify) {
          throw ArchiveException('Unknown check type $checkType');
        }
        break;
      case 0xa: // SHA-256
        final expectedCrc = input.readBytes(32).toUint8List();
        if (verify) {
          final actualCrc =
              sha256.convert(data.toBytes().sublist(startDataLength)).bytes;
          for (var i = 0; i < 32; i++) {
            if (actualCrc[i] != expectedCrc[i]) {
              throw ArchiveException('SHA-256 check failed');
            }
          }
        }
        break;
      case 0xb:
      case 0xc:
        input.skip(32);
        if (verify) {
          throw ArchiveException('Unknown check type $checkType');
        }
        break;
      case 0xd:
      case 0xe:
      case 0xf:
        input.skip(64);
        if (verify) {
          throw ArchiveException('Unknown check type $checkType');
        }
        break;
      default:
        throw ArchiveException('Unknown block check type $checkType');
    }

    final unpaddedLength = input.position - blockStart - paddingSize;
    _blockSizes.add(_XZBlockSize(unpaddedLength, uncompressedLength));
  }

  // Reads LZMA2 data from [input].
  void _readLZMA2(InputStreamBase input, int dictionarySize) {
    while (true) {
      final control = input.readByte();
      // Control values:
      // 00000000 - end marker
      // 00000001 - reset dictionary and uncompresed data
      // 00000010 - uncompressed data
      // 1rrxxxxx - LZMA data with reset (r) and high bits of size field (x)
      if (control & 0x80 == 0) {
        if (control == 0) {
          decoder.reset(resetDictionary: true);
          return;
        } else if (control == 1) {
          final length = (input.readByte() << 8 | input.readByte()) + 1;
          data.add(input.readBytes(length).toUint8List());
        } else if (control == 2) {
          // uncompressed data
          final length = (input.readByte() << 8 | input.readByte()) + 1;
          data.add(decoder.decodeUncompressed(input.readBytes(length), length));
        } else {
          throw ArchiveException('Unknown LZMA2 control code $control');
        }
      } else {
        // Reset flags:
        // 0 - reset nothing
        // 1 - reset state
        // 2 - reset state, properties
        // 3 - reset state, properties and dictionary
        final reset = (control >> 5) & 0x3;
        final uncompressedLength = ((control & 0x1f) << 16 |
                input.readByte() << 8 |
                input.readByte()) +
            1;
        final compressedLength = (input.readByte() << 8 | input.readByte()) + 1;
        int? literalContextBits;
        int? literalPositionBits;
        int? positionBits;
        if (reset >= 2) {
          // The three LZMA decoder properties are combined into a single number.
          var properties = input.readByte();
          positionBits = properties ~/ 45;
          properties -= positionBits * 45;
          literalPositionBits = properties ~/ 9;
          literalContextBits = properties - literalPositionBits * 9;
        }
        if (reset > 0) {
          decoder.reset(
              literalContextBits: literalContextBits,
              literalPositionBits: literalPositionBits,
              positionBits: positionBits,
              resetDictionary: reset == 3);
        }

        data.add(decoder.decode(
            input.readBytes(compressedLength), uncompressedLength));
      }
    }
  }

  // Reads an XZ stream index from [input].
  // Returns the length of the index in bytes.
  int _readStreamIndex(InputStreamBase input) {
    final startPosition = input.position;
    input.skip(1); // Skip index indicator
    final nRecords = _readMultibyteInteger(input);
    if (nRecords != _blockSizes.length) {
      throw ArchiveException('Stream index block count mismatch');
    }

    for (var i = 0; i < nRecords; i++) {
      final unpaddedLength = _readMultibyteInteger(input);
      final uncompressedLength = _readMultibyteInteger(input);
      if (_blockSizes[i].unpaddedLength != unpaddedLength) {
        throw ArchiveException('Stream index compressed length mismatch');
      }
      if (_blockSizes[i].uncompressedLength != uncompressedLength) {
        throw ArchiveException('Stream index uncompressed length mismatch');
      }
    }
    _readPadding(input);

    // Re-read for CRC calculation
    final indexLength = input.position - startPosition;
    input.rewind(indexLength);
    final indexData = input.readBytes(indexLength);

    final crc = input.readUint32();
    if (getCrc32(indexData.toUint8List()) != crc) {
      throw ArchiveException('Invalid stream index CRC checksum');
    }

    return indexLength + 4;
  }

  // Reads an XZ stream footer from [input] and check the index size matches
  // [indexSize].
  void _readStreamFooter(InputStreamBase input, int indexSize) {
    final crc = input.readUint32();
    final footer = input.readBytes(6);
    final backwardSize = (footer.readUint32() + 1) * 4;
    if (backwardSize != indexSize) {
      throw ArchiveException('Stream footer has invalid index size');
    }
    if (footer.readByte() != 0) {
      throw ArchiveException('Invalid stream flags');
    }
    final footerFlags = footer.readByte();
    if (footerFlags != streamFlags) {
      throw ArchiveException("Stream footer flags don't match header flags");
    }
    footer.reset();

    if (getCrc32(footer.toUint8List()) != crc) {
      throw ArchiveException('Invalid stream footer CRC checksum');
    }

    final magic = input.readBytes(2).toUint8List();
    if (magic[0] != 89 /* 'Y' */ && magic[1] != 90 /* 'Z' */) {
      throw ArchiveException('Invalid XZ stream footer signature');
    }
  }

  // Reads a multibyte integer from [input].
  int _readMultibyteInteger(InputStreamBase input) {
    var value = 0;
    var shift = 0;
    while (true) {
      final data = input.readByte();
      value |= (data & 0x7f) << shift;
      if (data & 0x80 == 0) {
        return value;
      }
      shift += 7;
    }
  }

  // Reads padding from [input] until the read position is aligned to a 4 byte
  // boundary. The padding bytes are confirmed to be zeros.
  // Returns he number of padding bytes.
  int _readPadding(InputStreamBase input) {
    var count = 0;
    while (input.position % 4 != 0) {
      if (input.readByte() != 0) {
        throw ArchiveException('Non-zero padding byte');
      }
      count++;
    }
    return count;
  }
}

// Information about a block size.
class _XZBlockSize {
  // The block size excluding padding.
  final int unpaddedLength;

  // The size of the data in the block when uncompressed.
  final int uncompressedLength;

  const _XZBlockSize(this.unpaddedLength, this.uncompressedLength);
}
