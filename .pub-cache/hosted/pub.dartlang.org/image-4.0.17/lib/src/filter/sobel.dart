import 'dart:math';

import '../color/channel.dart';
import '../image/image.dart';

/// Apply Sobel edge detection filtering to the [src] Image.
Image sobel(Image src,
    {num amount = 1, Image? mask, Channel maskChannel = Channel.luminance}) {
  if (amount == 0.0) {
    return src;
  }

  for (final frame in src.frames) {
    final orig = Image.from(frame, noAnimation: true);
    final width = frame.width;
    final height = frame.height;
    for (final p in frame) {
      final ny = (p.y - 1).clamp(0, height - 1);
      final py = (p.y + 1).clamp(0, height - 1);
      final nx = (p.x - 1).clamp(0, width - 1);
      final px = (p.x + 1).clamp(0, width - 1);

      final bottomLeft = orig.getPixel(nx, py).luminanceNormalized;
      final topLeft = orig.getPixel(nx, ny).luminanceNormalized;
      final bottomRight = orig.getPixel(px, py).luminanceNormalized;
      final topRight = orig.getPixel(px, ny).luminanceNormalized;
      final left = orig.getPixel(nx, p.y).luminanceNormalized;
      final right = orig.getPixel(px, p.y).luminanceNormalized;
      final bottom = orig.getPixel(p.x, py).luminanceNormalized;
      final top = orig.getPixel(p.x, ny).luminanceNormalized;

      final h =
          -topLeft - 2 * top - topRight + bottomLeft + 2 * bottom + bottomRight;

      final v =
          -bottomLeft - 2 * left - topLeft + bottomRight + 2 * right + topRight;

      final mag = sqrt(h * h + v * v) * p.maxChannelValue;

      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
      final mx = (msk ?? 1) * amount;
      final invMx = 1 - mx;

      p
        ..r = mag * mx + p.r * invMx
        ..g = mag * mx + p.g * invMx
        ..b = mag * mx + p.b * invMx;
    }
  }

  return src;
}
