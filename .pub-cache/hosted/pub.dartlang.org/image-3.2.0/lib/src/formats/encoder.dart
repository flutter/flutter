import '../animation.dart';
import '../image.dart';

/// Base class for image format encoders.
abstract class Encoder {
  /// Encode a single image.
  List<int> encodeImage(Image image);

  /// Does this encoder support animation?
  bool get supportsAnimation => false;

  /// Encode an animation. Not all formats support animation, and null
  /// will be returned if not.
  List<int>? encodeAnimation(Animation anim) => null;
}
