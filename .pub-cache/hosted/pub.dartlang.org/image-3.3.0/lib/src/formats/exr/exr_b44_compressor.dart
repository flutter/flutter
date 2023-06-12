import 'dart:typed_data';

import '../../image_exception.dart';
import '../../internal/internal.dart';
import '../../util/input_buffer.dart';
import 'exr_compressor.dart';
import 'exr_part.dart';

abstract class ExrB44Compressor extends ExrCompressor {
  factory ExrB44Compressor(ExrPart header, int? maxScanLineSize,
      int numScanLines, bool optFlatFields) = InternalExrB44Compressor;
}

@internal
class InternalExrB44Compressor extends InternalExrCompressor
    implements ExrB44Compressor {
  InternalExrB44Compressor(ExrPart header, int? maxScanLineSize,
      this._numScanLines, bool optFlatFields)
      : super(header as InternalExrPart);

  @override
  int numScanLines() => _numScanLines;

  @override
  Uint8List compress(InputBuffer input, int x, int y,
      [int? width, int? height]) {
    throw ImageException('B44 compression not yet supported.');
  }

  @override
  Uint8List uncompress(InputBuffer input, int x, int y,
      [int? width, int? height]) {
    throw ImageException('B44 compression not yet supported.');
  }

  //int _maxScanLineSize;
  final int _numScanLines;
  //bool _optFlatFields;
}
