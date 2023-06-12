import 'dart:typed_data';

import '../../image_exception.dart';
import '../../internal/internal.dart';
import '../../util/input_buffer.dart';
import 'exr_b44_compressor.dart';
import 'exr_part.dart';
import 'exr_piz_compressor.dart';
import 'exr_pxr24_compressor.dart';
import 'exr_rle_compressor.dart';
import 'exr_zip_compressor.dart';

abstract class ExrCompressor {
  static const NO_COMPRESSION = 0;
  static const RLE_COMPRESSION = 1;
  static const ZIPS_COMPRESSION = 2;
  static const ZIP_COMPRESSION = 3;
  static const PIZ_COMPRESSION = 4;
  static const PXR24_COMPRESSION = 5;
  static const B44_COMPRESSION = 6;
  static const B44A_COMPRESSION = 7;

  int decodedWidth = 0;
  int decodedHeight = 0;

  factory ExrCompressor(int type, ExrPart hdr, int? maxScanLineSize,
      [int? numScanLines]) {
    switch (type) {
      case RLE_COMPRESSION:
        return ExrRleCompressor(hdr, maxScanLineSize);
      case ZIPS_COMPRESSION:
        return ExrZipCompressor(hdr, maxScanLineSize, numScanLines ?? 1);
      case ZIP_COMPRESSION:
        return ExrZipCompressor(hdr, maxScanLineSize, numScanLines ?? 16);
      case PIZ_COMPRESSION:
        return ExrPizCompressor(hdr, maxScanLineSize, numScanLines ?? 32);
      case PXR24_COMPRESSION:
        return ExrPxr24Compressor(hdr, maxScanLineSize, numScanLines ?? 16);
      case B44_COMPRESSION:
        return ExrB44Compressor(
            hdr, maxScanLineSize, numScanLines ?? 32, false);
      case B44A_COMPRESSION:
        return ExrB44Compressor(hdr, maxScanLineSize, numScanLines ?? 32, true);
      default:
        throw ImageException('Invalid compression type: $type');
    }
  }

  factory ExrCompressor.tile(
      int type, int tileLineSize, int numTileLines, ExrPart hdr) {
    switch (type) {
      case RLE_COMPRESSION:
        return ExrRleCompressor(hdr, (tileLineSize * numTileLines));
      case ZIPS_COMPRESSION:
      case ZIP_COMPRESSION:
        return ExrZipCompressor(hdr, tileLineSize, numTileLines);
      case PIZ_COMPRESSION:
        return ExrPizCompressor(hdr, tileLineSize, numTileLines);
      case PXR24_COMPRESSION:
        return ExrPxr24Compressor(hdr, tileLineSize, numTileLines);
      case B44_COMPRESSION:
        return ExrB44Compressor(hdr, tileLineSize, numTileLines, false);
      case B44A_COMPRESSION:
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
