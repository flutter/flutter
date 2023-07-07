import 'dart:math';

import 'hdr_image.dart';

/// Applies Reinhard tone mapping to the hdr image, in-place.
HdrImage reinhardToneMap(HdrImage hdr) {
  const yw = [0.212671, 0.715160, 0.072169];

  // Compute world adaptation luminance, _Ywa_
  var Ywa = 0.0;
  for (var y = 0; y < hdr.height; ++y) {
    for (var x = 0; x < hdr.width; ++x) {
      final r = hdr.getRed(x, y);
      final g = hdr.getGreen(x, y);
      final b = hdr.getBlue(x, y);

      final lum = yw[0] * r + yw[1] * g + yw[2] * b;
      if (lum > 1.0e-4) {
        Ywa += log(lum);
      }
    }
  }

  Ywa = exp(Ywa / (hdr.width * hdr.height));

  final invY2 = 1.0 / (Ywa * Ywa);

  for (var y = 0; y < hdr.height; ++y) {
    for (var x = 0; x < hdr.width; ++x) {
      final r = hdr.getRed(x, y);
      final g = hdr.getGreen(x, y);
      final b = hdr.getBlue(x, y);

      final lum = yw[0] * r + yw[1] * g + yw[2] * b;

      final s = (1.0 + lum * invY2) / (1.0 + lum);

      hdr.setRed(x, y, r * s);
      hdr.setGreen(x, y, g * s);
      hdr.setBlue(x, y, b * s);
    }
  }

  return hdr;
}
