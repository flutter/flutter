import 'dart:math';

import '../color/channel.dart';
import '../image/image.dart';
import '../util/math_util.dart';

/// Apply sketch filter to the image.
///
/// [amount] controls the strength of the effect, in the range \[0, 1\].
Image sketch(Image src,
    {num amount = 1, Image? mask, Channel maskChannel = Channel.luminance}) {
  if (amount == 0) {
    return src;
  }

  for (final frame in src.frames) {
    final width = frame.width;
    final height = frame.height;
    final orig = Image.from(frame, noAnimation: true);
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

      final mag = 1 - sqrt(h * h + v * v);

      final r = (mag * p.r).clamp(0, p.maxChannelValue);
      final g = (mag * p.g).clamp(0, p.maxChannelValue);
      final b = (mag * p.b).clamp(0, p.maxChannelValue);

      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
      final mx = (msk ?? 1) * amount;

      p
        ..r = mix(p.r, r, mx)
        ..g = mix(p.g, g, mx)
        ..b = mix(p.b, b, mx);
    }
  }

  return src;
}
