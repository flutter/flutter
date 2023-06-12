import 'dart:math';

import '../color.dart';
import '../image.dart';

/// Generate a normal map from a heightfield bump image.
///
/// The red channel of the [src] image is used as an input, 0 represents a low
/// height and 1 a high value. The optional [strength] parameter allows to set
/// the strength of the normal image.
Image bumpToNormal(Image src, {num strength = 2.0}) {
  final dest = Image.from(src);

  for (var y = 0; y < src.height; ++y) {
    for (var x = 0; x < src.width; ++x) {
      final height = getRed(src.getPixel(x, y)) / 255.0;
      var du = (height -
              getRed(src.getPixel(x < src.width - 1 ? x + 1 : x, y)) / 255.0) *
          strength;
      var dv = (height -
              getRed(src.getPixel(x, y < src.height - 1 ? y + 1 : y)) / 255.0) *
          strength;
      final z = du.abs() + dv.abs();

      if (z > 1) {
        du /= z;
        dv /= z;
      }

      final dw = sqrt(1.0 - du * du - dv * dv);
      final nX = du * 0.5 + 0.5;
      final nY = dv * 0.5 + 0.5;
      final nZ = dw;

      dest.setPixelRgba(
          x, y, (255 * nX).floor(), (255 * nY).floor(), (255 * nZ).floor());
    }
  }

  return dest;
}
