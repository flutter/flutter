import 'dart:math';

import '../color/channel.dart';
import '../image/image.dart';
import '../util/math_util.dart';

///
Image luminanceThreshold(Image src,
    {num threshold = 0.5,
    bool outputColor = false,
    num amount = 1,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  for (final frame in src.frames) {
    for (final p in frame) {
      final y =
          0.3 * p.rNormalized + 0.59 * p.gNormalized + 0.11 * p.bNormalized;
      if (outputColor) {
        final l = max(0, y - threshold);
        final sl = sign(l);
        final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
        final mx = (msk ?? 1) * amount;
        p
          ..r = mix(p.r, p.r * sl, mx)
          ..g = mix(p.g, p.g * sl, mx)
          ..b *= mix(p.b, p.b * sl, mx);
      } else {
        final y2 = y < threshold ? 0 : p.maxChannelValue;
        final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
        final mx = (msk ?? 1) * amount;
        p
          ..r = mix(p.r, y2, mx)
          ..g = mix(p.g, y2, mx)
          ..b = mix(p.b, y2, mx);
      }
    }
  }
  return src;
}
