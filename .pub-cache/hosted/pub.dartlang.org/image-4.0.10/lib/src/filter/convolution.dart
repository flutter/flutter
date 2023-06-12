import 'dart:math';

import '../color/channel.dart';
import '../image/image.dart';
import '../util/math_util.dart';

/// Apply a 3x3 convolution filter to the [src] image. [filter] should be a
/// list of 9 numbers.
///
/// The rgb channels will be divided by [div] and add [offset], allowing
/// filters to normalize and offset the filtered pixel value.
Image convolution(Image src,
    {required List<num> filter,
    num div = 1.0,
    num offset = 0.0,
    num amount = 1,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  final tmp = Image.from(src);
  for (final frame in src.frames) {
    final tmpFrame = tmp.frames[frame.frameIndex];
    for (final c in tmpFrame) {
      num r = 0.0;
      num g = 0.0;
      num b = 0.0;
      for (var j = 0, fi = 0; j < 3; ++j) {
        final yv = min(max(c.y - 1 + j, 0), src.height - 1);
        for (var i = 0; i < 3; ++i, ++fi) {
          final xv = min(max(c.x - 1 + i, 0), src.width - 1);
          final c2 = tmpFrame.getPixel(xv, yv);
          r += c2.r * filter[fi];
          g += c2.g * filter[fi];
          b += c2.b * filter[fi];
        }
      }

      r = ((r / div) + offset).clamp(0, 255);
      g = ((g / div) + offset).clamp(0, 255);
      b = ((b / div) + offset).clamp(0, 255);

      final p = frame.getPixel(c.x, c.y);

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
