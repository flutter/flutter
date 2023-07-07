import 'dart:typed_data';

import '../image/image.dart';

/// Base class for image format encoders.
abstract class Encoder {
  /// Encode an [image] to an image format.
  /// If [singleFrame] is true, only the one Image will be encoded;
  /// otherwise if image has animation, all frames of the [image] will be
  /// encoded if the encoder supports animation.
  Uint8List encode(Image image, {bool singleFrame = false});

  /// True if the encoder supports animated Images; otherwise false.
  bool get supportsAnimation => false;
}
