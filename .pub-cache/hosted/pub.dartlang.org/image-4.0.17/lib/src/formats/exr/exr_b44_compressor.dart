import 'dart:typed_data';

import '../../util/_internal.dart';
import '../../util/image_exception.dart';
import '../../util/input_buffer.dart';
import 'exr_compressor.dart';
import 'exr_part.dart';

@internal
abstract class ExrB44Compressor extends ExrCompressor {
  factory ExrB44Compressor(ExrPart header, int? maxScanLineSize,
      int numScanLines, bool optFlatFields) = InternalExrB44Compressor;
}

@internal
class InternalExrB44Compressor extends InternalExrCompressor
    implements ExrB44Compressor {
  InternalExrB44Compressor(ExrPart header, this._maxScanLineSize,
      this._numScanLines, this._optFlatFields)
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

  // Making analysis happy
  @override
  String toString() => '$_maxScanLineSize $_optFlatFields';

  final int? _maxScanLineSize;
  final int _numScanLines;
  final bool? _optFlatFields;
}
