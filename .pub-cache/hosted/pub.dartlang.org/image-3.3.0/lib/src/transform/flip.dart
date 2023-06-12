import '../image.dart';

enum Flip {
  /// Flip the image horizontally.
  horizontal,

  /// Flip the image vertically.
  vertical,

  /// Flip the image both horizontally and vertically.
  both
}

/// Flips the [src] image using the given [mode], which can be one of:
/// [Flip.horizontal], [Flip.vertical], or [Flip.both].
Image flip(Image src, Flip mode) {
  switch (mode) {
    case Flip.horizontal:
      flipHorizontal(src);
      break;
    case Flip.vertical:
      flipVertical(src);
      break;
    case Flip.both:
      flipVertical(src);
      flipHorizontal(src);
      break;
  }

  return src;
}

/// Flip the [src] image vertically.
Image flipVertical(Image src) {
  final w = src.width;
  final h = src.height;
  final h2 = h ~/ 2;
  for (var y = 0; y < h2; ++y) {
    final y1 = y * w;
    final y2 = (h - 1 - y) * w;
    for (var x = 0; x < w; ++x) {
      final t = src[y2 + x];
      src[y2 + x] = src[y1 + x];
      src[y1 + x] = t;
    }
  }
  return src;
}

/// Flip the src image horizontally.
Image flipHorizontal(Image src) {
  final w = src.width;
  final h = src.height;
  final w2 = src.width ~/ 2;
  for (var y = 0; y < h; ++y) {
    final y1 = y * w;
    for (var x = 0; x < w2; ++x) {
      final x2 = (w - 1 - x);
      final t = src[y1 + x2];
      src[y1 + x2] = src[y1 + x];
      src[y1 + x] = t;
    }
  }
  return src;
}
