import 'dart:typed_data';

import '../../util/_internal.dart';
import '../../util/image_exception.dart';
import '../../util/input_buffer.dart';
import 'exr_b44_compressor.dart';
import 'exr_part.dart';
import 'exr_piz_compressor.dart';
import 'exr_pxr24_compressor.dart';
import 'exr_rle_compressor.dart';
import 'exr_zip_compressor.dart';

@internal
enum ExrCompressorType { none, rle, zips, zip, piz, pxr24, b44, b44a }

@internal
abstract class ExrCompressor {
  int decodedWidth = 0;
  int decodedHeight = 0;

  factory ExrCompressor(
      ExrCompressorType type, ExrPart hdr, int? maxScanLineSize,
      [int? numScanLines]) {
    switch (type) {
      case ExrCompressorType.rle:
        return ExrRleCompressor(hdr, maxScanLineSize);
      case ExrCompressorType.zips:
        return ExrZipCompressor(hdr, maxScanLineSize, numScanLines ?? 1);
      case ExrCompressorType.zip:
        return ExrZipCompressor(hdr, maxScanLineSize, numScanLines ?? 16);
      case ExrCompressorType.piz:
        return ExrPizCompressor(hdr, maxScanLineSize, numScanLines ?? 32);
      case ExrCompressorType.pxr24:
        return ExrPxr24Compressor(hdr, maxScanLineSize, numScanLines ?? 16);
      case ExrCompressorType.b44:
        return ExrB44Compressor(
            hdr, maxScanLineSize, numScanLines ?? 32, false);
      case ExrCompressorType.b44a:
        return ExrB44Compressor(hdr, maxScanLineSize, numScanLines ?? 32, true);
      default:
        throw ImageException('Invalid compression type: $type');
    }
  }

  factory ExrCompressor.tile(
      ExrCompressorType type, int tileLineSize, int numTileLines, ExrPart hdr) {
    switch (type) {
      case ExrCompressorType.rle:
        return ExrRleCompressor(hdr, tileLineSize * numTileLines);
      case ExrCompressorType.zips:
      case ExrCompressorType.zip:
        return ExrZipCompressor(hdr, tileLineSize, numTileLines);
      case ExrCompressorType.piz:
        return ExrPizCompressor(hdr, tileLineSize, numTileLines);
      case ExrCompressorType.pxr24:
        return ExrPxr24Compressor(hdr, tileLineSize, numTileLines);
      case ExrCompressorType.b44:
        return ExrB44Compressor(hdr, tileLineSize, numTileLines, false);
      case ExrCompressorType.b44a:
        return ExrB44Compressor(hdr, tileLineSize, numTileLines, true);
      default:
        throw ImageException('Invalid compression type: $type');
    }
  }

  ExrCompressor._(this._header);

  int numScanLines();

  Uint8List compress(InputBuffer input, int x, int y,
      [int? width, int? height]) {
    throw ImageException('Unsupported compression type');
  }

  Uint8List uncompress(InputBuffer input, int x, int y,
      [int? width, int? height]) {
    throw ImageException('Unsupported compression type');
  }

  ExrPart _header;
}

@internal
abstract class InternalExrCompressor extends ExrCompressor {
  InternalExrCompressor(InternalExrPart header) : super._(header);

  InternalExrPart get header => _header as InternalExrPart;

  int numSamples(int s, int a, int b) {
    final a1 = a ~/ s;
    final b1 = b ~/ s;
    return b1 - a1 + ((a1 * s < a) ? 0 : 1);
  }
}
