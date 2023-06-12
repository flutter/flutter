import 'dart:math';

import '../color/channel.dart';
import '../image/image.dart';
import '../image/interpolation.dart';
import '../util/math_util.dart';

Image bulgeDistortion(Image src,
    {int? centerX,
    int? centerY,
    num? radius,
    num scale = 0.5,
    Interpolation interpolation = Interpolation.nearest,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  for (final frame in src.frames) {
    final orig = frame.clone(noAnimation: true);
    final w = frame.width;
    final h = frame.height;
    final cx = centerX ?? w ~/ 2;
    final cy = centerY ?? h ~/ 2;
    final rad = radius ?? min(w, h) ~/ 2;
    final radSqr = rad * rad;
    for (final p in frame) {
      num x = p.x;
      num y = p.y;
      final deltaX = cx - x;
      final deltaY = cy - y;
      final dist = deltaX * deltaX + deltaY * deltaY;
      x -= cx;
      y -= cy;
      if (dist < radSqr) {
        final percent = 1 - ((radSqr - dist) / radSqr) * scale;
        final percentSqr = percent * percent;
        x *= percentSqr;
        y *= percentSqr;
      }
      x += cx;
      y += cy;

      final p2 = orig.getPixelInterpolate(x, y, interpolation: interpolation);
      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);

      if (msk == null) {
        p.set(p2);
      } else {
        p
          ..r = mix(p.r, p2.r, msk)
          ..g = mix(p.g, p2.g, msk)
          ..b = mix(p.b, p2.b, msk)
          ..a = mix(p.a, p2.a, msk);
      }
    }
  }
  return src;
}
