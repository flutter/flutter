import 'dart:typed_data';

import '../../util/image_exception.dart';
import '../../util/input_buffer.dart';

class PsdChannel {
  static const red = 0;
  static const green = 1;
  static const blue = 2;
  static const black = 3;
  static const alpha = -1;
  static const mask = -2;
  static const realMask = -3;

  static const compressNone = 0;
  static const compressRle = 1;
  static const compressZip = 2;
  static const compressZipPredictor = 3;

  int id;
  int? dataLength;
  late Uint8List data;

  PsdChannel(this.id, this.dataLength);

  PsdChannel.read(
      InputBuffer input,
      this.id,
      int width,
      int height,
      int? bitDepth,
      int compression,
      Uint16List? lineLengths,
      int planeNumber) {
    readPlane(
        input, width, height, bitDepth, compression, lineLengths, planeNumber);
  }

  void readPlane(InputBuffer input, int width, int height, int? bitDepth,
      [int? compression, Uint16List? lineLengths, int planeNum = 0]) {
    compression ??= input.readUint16();

    switch (compression) {
      case compressNone:
        _readPlaneUncompressed(input, width, height, bitDepth!);
        break;
      case compressRle:
        lineLengths ??= _readLineLengths(input, height);
        _readPlaneRleCompressed(
            input, width, height, bitDepth!, lineLengths, planeNum);
        break;
      default:
        throw ImageException('Unsupported compression: $compression');
    }
  }

  Uint16List _readLineLengths(InputBuffer input, int height) {
    final lineLengths = Uint16List(height);
    for (var i = 0; i < height; ++i) {
      lineLengths[i] = input.readUint16();
    }
    return lineLengths;
  }

  void _readPlaneUncompressed(
      InputBuffer input, int width, int height, int bitDepth) {
    var len = width * height;
    if (bitDepth == 16) {
      len *= 2;
    }
    if (len > input.length) {
      data = Uint8List(len);
      data.fillRange(0, len, 255);
      return;
    }

    final imgData = input.readBytes(len);
    data = imgData.toUint8List();
  }

  void _readPlaneRleCompressed(InputBuffer input, int width, int height,
      int bitDepth, Uint16List lineLengths, int planeNum) {
    var len = width * height;
    if (bitDepth == 16) {
      len *= 2;
    }
    data = Uint8List(len);
    var pos = 0;
    var lineIndex = planeNum * height;
    if (lineIndex >= lineLengths.length) {
      data.fillRange(0, data.length, 255);
      return;
    }

    for (var i = 0; i < height; ++i) {
      final len = lineLengths[lineIndex++];
      final s = input.readBytes(len);
      _decodeRLE(s, data, pos);
      pos += width;
    }
  }

  void _decodeRLE(InputBuffer src, Uint8List dst, int dstIndex) {
    while (!src.isEOS) {
      var n = src.readInt8();
      if (n < 0) {
        n = 1 - n;
        final b = src.readByte();
        for (var i = 0; i < n; ++i) {
          dst[dstIndex++] = b;
        }
      } else {
        n++;
        for (var i = 0; i < n; ++i) {
          dst[dstIndex++] = src.readByte();
        }
      }
    }
  }
}
