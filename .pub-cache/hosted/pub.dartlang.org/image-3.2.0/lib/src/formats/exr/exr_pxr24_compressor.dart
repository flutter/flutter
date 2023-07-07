import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../image_exception.dart';
import '../../util/input_buffer.dart';
import '../../util/output_buffer.dart';
import 'exr_channel.dart';
import 'exr_compressor.dart';
import 'exr_part.dart';

abstract class ExrPxr24Compressor extends ExrCompressor {
  factory ExrPxr24Compressor(
          ExrPart header, int? maxScanLineSize, int numScanLines) =
      InternalExrPxr24Compressor;
}

class InternalExrPxr24Compressor extends InternalExrCompressor
    implements ExrPxr24Compressor {
  InternalExrPxr24Compressor(
      ExrPart header, this._maxScanLineSize, this._numScanLines)
      : super(header as InternalExrPart);

  @override
  int numScanLines() => _numScanLines;

  @override
  Uint8List compress(InputBuffer input, int x, int y,
      [int? width, int? height]) {
    throw ImageException('Pxr24 compression not yet supported.');
  }

  @override
  Uint8List uncompress(InputBuffer input, int x, int y,
      [int? width, int? height]) {
    final data = _zlib.decodeBytes(input.toUint8List());

    _output ??= OutputBuffer(size: _numScanLines * _maxScanLineSize!);
    _output!.rewind();

    var tmpEnd = 0;
    final ptr = [0, 0, 0, 0];
    final pixel = Uint32List(1);
    final pixelBytes = Uint8List.view(pixel.buffer);

    width ??= header.width;
    height ??= header.linesInBuffer;

    final minX = x;
    var maxX = x + width! - 1;
    final minY = y;
    var maxY = y + height! - 1;

    if (maxX > header.width!) {
      maxX = header.width! - 1;
    }
    if (maxY > header.height!) {
      maxY = header.height! - 1;
    }

    decodedWidth = (maxX - minX) + 1;
    decodedHeight = (maxY - minY) + 1;

    final numChannels = header.channels.length;
    for (var yi = minY; yi <= maxY; ++yi) {
      for (var ci = 0; ci < numChannels; ++ci) {
        final ch = header.channels[ci];
        if ((y % ch.ySampling) != 0) {
          continue;
        }

        final n = numSamples(ch.xSampling, minX, maxX);
        pixel[0] = 0;

        switch (ch.type) {
          case ExrChannel.TYPE_UINT:
            ptr[0] = tmpEnd;
            ptr[1] = ptr[0] + n;
            ptr[2] = ptr[1] + n;
            tmpEnd = ptr[2] + n;
            for (var j = 0; j < n; ++j) {
              final diff = (data[ptr[0]++] << 24) |
                  (data[ptr[1]++] << 16) |
                  (data[ptr[2]++] << 8);
              pixel[0] += diff;
              for (var k = 0; k < 4; ++k) {
                _output!.writeByte(pixelBytes[k]);
              }
            }
            break;
          case ExrChannel.TYPE_HALF:
            ptr[0] = tmpEnd;
            ptr[1] = ptr[0] + n;
            tmpEnd = ptr[1] + n;
            for (var j = 0; j < n; ++j) {
              final diff = (data[ptr[0]++] << 8) | data[ptr[1]++];
              pixel[0] += diff;

              for (var k = 0; k < 2; ++k) {
                _output!.writeByte(pixelBytes[k]);
              }
            }
            break;
          case ExrChannel.TYPE_FLOAT:
            ptr[0] = tmpEnd;
            ptr[1] = ptr[0] + n;
            ptr[2] = ptr[1] + n;
            tmpEnd = ptr[2] + n;
            for (var j = 0; j < n; ++j) {
              final diff = (data[ptr[0]++] << 24) |
                  (data[ptr[1]++] << 16) |
                  (data[ptr[2]++] << 8);
              pixel[0] += diff;
              for (var k = 0; k < 4; ++k) {
                _output!.writeByte(pixelBytes[k]);
              }
            }
            break;
        }
      }
    }

    return _output!.getBytes() as Uint8List;
  }

  final _zlib = const ZLibDecoder();
  final int? _maxScanLineSize;
  final int _numScanLines;
  OutputBuffer? _output;
}
