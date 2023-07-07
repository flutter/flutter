import 'dart:typed_data';

import '../image.dart';
import '../internal/clamp.dart';

num? _lastContrast;
late Uint8List _contrast;

/// Set the [contrast] level for the image [src].
///
/// [contrast] values below 100 will decrees the contrast of the image,
/// and values above 100 will increase the contrast. A contrast of of 100
/// will have no affect.
Image? contrast(Image? src, num contrast) {
  if (src == null || contrast == 100.0) {
    return src;
  }

  if (contrast != _lastContrast) {
    _lastContrast = contrast;

    contrast = contrast / 100.0;
    contrast = contrast * contrast;
    _contrast = Uint8List(256);
    for (var i = 0; i < 256; ++i) {
      _contrast[i] =
          clamp255((((((i / 255.0) - 0.5) * contrast) + 0.5) * 255.0).toInt());
    }
  }

  final p = src.getBytes();
  for (var i = 0, len = p.length; i < len; i += 4) {
    p[i] = _contrast[p[i]];
    p[i + 1] = _contrast[p[i + 1]];
    p[i + 2] = _contrast[p[i + 2]];
  }

  return src;
}
