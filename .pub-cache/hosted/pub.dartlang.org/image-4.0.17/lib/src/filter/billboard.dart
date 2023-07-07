import 'dart:math';

import '../color/channel.dart';
import '../image/image.dart';
import '../util/math_util.dart';

/// Apply the billboard filter to the image.
Image billboard(Image src,
    {num grid = 10,
    num amount = 1,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  const rs = 0.2025; // pow(0.45, 2.0);

  for (final frame in src.frames) {
    final w = frame.width;
    final h = frame.height;
    final aspect = w / h;
    const stepX = 0.0015625;
    final stepY = 0.0015625 * aspect;
    final orig = frame.clone(noAnimation: true);
    for (final p in frame) {
      final uvX = p.x / (w - 1);
      final uvY = p.y / (h - 1);

      final offX = (uvX / (grid * stepX)).floor();
      final offY = (uvY / (grid * stepY)).floor();

      final x2 = ((offX * grid * stepX) * (w - 1)).floor();
      final y2 = ((offY * grid * stepY) * (h - 1)).floor();

      if (x2 >= w || y2 >= h) {
        continue;
      }

      final op = orig.getPixel(x2, y2);

      final prcX = fract(uvX / (grid * stepX));
      final prcY = fract(uvY / (grid * stepY));
      final pwX = pow((prcX - 0.5).abs(), 2.0);
      final pwY = pow((prcY - 0.5).abs(), 2.0);

      num r = op.r / p.maxChannelValue;
      num g = op.g / p.maxChannelValue;
      num b = op.b / p.maxChannelValue;

      final gr = smoothstep(rs - 0.1, rs + 0.1, pwX + pwY);
      final y = (r + g + b) / 3.0;

      const ls = 0.3;
      final lb = (y / ls).ceil();
      final lf = ls * lb + 0.3;

      r = mix(lf * r, 0.1, gr);
      g = mix(lf * g, 0.1, gr);
      b = mix(lf * b, 0.1, gr);

      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
      final mx = (msk ?? 1) * amount;

      p
        ..r = mix(p.r, r * p.maxChannelValue, mx)
        ..g = mix(p.g, g * p.maxChannelValue, mx)
        ..b = mix(p.b, b * p.maxChannelValue, mx);
    }
  }
  return src;
}
