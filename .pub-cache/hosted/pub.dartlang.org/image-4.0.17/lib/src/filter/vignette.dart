import 'dart:math';

import '../color/channel.dart';
import '../color/color.dart';
import '../image/image.dart';
import '../util/math_util.dart';

num _smoothStep(num edge0, num edge1, num x) {
  x = (x - edge0) / (edge1 - edge0);
  if (x < 0.0) {
    x = 0.0;
  }
  if (x > 1.0) {
    x = 1.0;
  }
  return x * x * (3.0 - 2.0 * x);
}

/// Apply a vignette filter to the image.
/// [start] is the inner radius from the center of the image, where the fade to
/// [color] starts to be applied; and [end] is the outer radius of the
/// vignette effect where the [color] is fully applied. The radius values are in
/// normalized percentage of the image size \[0, 1\].
/// [amount] controls the blend of the effect with the original image.
Image vignette(Image src,
    {num start = 0.3,
    num end = 0.85,
    num amount = 0.9,
    Color? color,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  final h = src.height - 1;
  final w = src.width - 1;
  final cr = color?.rNormalized ?? 0;
  final cg = color?.gNormalized ?? 0;
  final cb = color?.bNormalized ?? 0;
  final ca = color?.aNormalized ?? 1;
  final aspect = w / h;
  for (final frame in src.frames) {
    for (final p in frame) {
      final dx = (0.5 - (p.x / w)) * aspect;
      final dy = 0.5 - (p.y / h);

      num d = sqrt(dx * dx + dy * dy);
      d = 1 - _smoothStep(end, start, d);

      final r = mix(p.rNormalized, cr, d) * p.maxChannelValue;
      final g = mix(p.gNormalized, cg, d) * p.maxChannelValue;
      final b = mix(p.bNormalized, cb, d) * p.maxChannelValue;
      final a = mix(p.aNormalized, ca, d) * p.maxChannelValue;

      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
      final mx = (msk ?? 1) * amount;

      p
        ..r = mix(p.r, r, mx)
        ..g = mix(p.g, g, mx)
        ..b = mix(p.b, b, mx)
        ..a = mix(p.a, a, mx);
    }
  }
  return src;
}
