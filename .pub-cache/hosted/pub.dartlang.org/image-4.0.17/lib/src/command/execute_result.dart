import 'dart:typed_data';

import '../image/image.dart';
import '../util/_internal.dart';

@internal
class ExecuteResult {
  Image? image;
  Uint8List? bytes;
  Object? object;
  Object? exception;
  ExecuteResult(this.image, this.bytes, this.object, {this.exception});
}
