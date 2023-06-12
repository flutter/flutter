import 'dart:math';

import 'hdr_image.dart';

/// Apply gamma scaling to the HDR image, in-place.
HdrImage hdrGamma(HdrImage hdr, {double gamma = 2.2}) {
  for (var y = 0; y < hdr.height; ++y) {
    for (var x = 0; x < hdr.width; ++x) {
      final r = pow(hdr.getRed(x, y), 1.0 / gamma);
      final g = pow(hdr.getGreen(x, y), 1.0 / gamma);
      final b = pow(hdr.getBlue(x, y), 1.0 / gamma);

      hdr.setRed(x, y, r);
      hdr.setGreen(x, y, g);
      hdr.setBlue(x, y, b);
    }
  }

  return hdr;
}
