import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../image_exception.dart';
import '../../util/input_buffer.dart';
import 'exr_compressor.dart';
import 'exr_part.dart';

abstract class ExrZipCompressor extends ExrCompressor {
  factory ExrZipCompressor(
          ExrPart header, int? maxScanLineSize, int numScanLines) =
      InternalExrZipCompressor;
}

class InternalExrZipCompressor extends InternalExrCompressor
    implements ExrZipCompressor {
  ZLibDecoder zlib = const ZLibDecoder();

  InternalExrZipCompressor(
      ExrPart header, int? maxScanLineSize, this._numScanLines)
      : super(header as InternalExrPart);

  @override
  int numScanLines() => _numScanLines;

  @override
  Uint8List compress(InputBuffer input, int x, int y,
      [int? width, int? height]) {
    throw ImageException('Zip compression not yet supported');
  }

  @override
  Uint8List uncompress(InputBuffer input, int x, int y,
      [int? width, int? height]) {
    final data = zlib.decodeBytes(input.toUint8List());

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

    // Predictor
    for (var i = 1, len = data.length; i < len; ++i) {
      data[i] = data[i - 1] + data[i] - 128;
    }

    // Reorder the pixel data
    if (_outCache == null || _outCache!.length != data.length) {
      _outCache = Uint8List(data.length);
    }

    final len = data.length;
    var t1 = 0;
    var t2 = (len + 1) ~/ 2;
    var si = 0;

    while (true) {
      if (si < len) {
        _outCache![si++] = data[t1++];
      } else {
        break;
      }
      if (si < len) {
        _outCache![si++] = data[t2++];
      } else {
        break;
      }
    }

    return _outCache!;
  }

  final int _numScanLines;
  Uint8List? _outCache;
}
