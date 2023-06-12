import '../../internal/internal.dart';

// Decodes a frame from a PNG animation.
class PngFrame {
  // DisposeMode
  static const APNG_DISPOSE_OP_NONE = 0;
  static const APNG_DISPOSE_OP_BACKGROUND = 1;
  static const APNG_DISPOSE_OP_PREVIOUS = 2;
  // BlendMode
  static const APNG_BLEND_OP_SOURCE = 0;
  static const APNG_BLEND_OP_OVER = 1;

  int? sequenceNumber;
  int? width;
  int? height;
  int? xOffset;
  int? yOffset;
  int? delayNum;
  int? delayDen;
  int? dispose;
  int? blend;

  final List<int> _fdat = [];

  double get delay => delayNum == null || delayDen == null ? 0 :
    delayDen != 0 ? delayNum! / delayDen! : 0;
}

@internal
class InternalPngFrame extends PngFrame {
  List<int> get fdat => _fdat;
}
