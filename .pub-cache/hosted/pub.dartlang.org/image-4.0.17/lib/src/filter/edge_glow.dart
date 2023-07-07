import 'dart:math';

import '../color/channel.dart';
import '../image/image.dart';
import '../util/math_util.dart';

/// Apply the edge glow filter to the [src] Image.
Image edgeGlow(Image src,
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

      final t1 = orig.getPixel(nx, ny);
      final t2 = orig.getPixel(p.x, ny);
      final t3 = orig.getPixel(px, ny);
      final t4 = orig.getPixel(nx, p.y);
      final t5 = p;
      final t6 = orig.getPixel(px, p.y);
      final t7 = orig.getPixel(nx, py);
      final t8 = orig.getPixel(p.x, py);
      final t9 = orig.getPixel(px, py);

      final xxR = t1.rNormalized +
          2 * t2.rNormalized +
          t3.rNormalized -
          t7.rNormalized -
          2 * t8.rNormalized -
          t9.rNormalized;
      final xxG = t1.gNormalized +
          2 * t2.gNormalized +
          t3.gNormalized -
          t7.gNormalized -
          2 * t8.gNormalized -
          t9.gNormalized;
      final xxB = t1.bNormalized +
          2 * t2.bNormalized +
          t3.bNormalized -
          t7.bNormalized -
          2 * t8.bNormalized -
          t9.bNormalized;

      final yyR = t1.rNormalized -
          t3.rNormalized +
          2 * t4.rNormalized -
          2 * t6.rNormalized +
          t7.rNormalized -
          t9.rNormalized;
      final yyG = t1.gNormalized -
          t3.gNormalized +
          2 * t4.gNormalized -
          2 * t6.gNormalized +
          t7.gNormalized -
          t9.gNormalized;
      final yyB = t1.bNormalized -
          t3.bNormalized +
          2 * t4.bNormalized -
          2 * t6.bNormalized +
          t7.bNormalized -
          t9.bNormalized;

      final rrR = sqrt(xxR * xxR + yyR * yyR);
      final rrG = sqrt(xxG * xxG + yyG * yyG);
      final rrB = sqrt(xxB * xxB + yyB * yyB);

      final r = (rrR * 2 * t5.rNormalized) * p.maxChannelValue;
      final g = (rrG * 2 * t5.gNormalized) * p.maxChannelValue;
      final b = (rrB * 2 * t5.bNormalized) * p.maxChannelValue;

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
