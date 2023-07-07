import '../color/channel.dart';
import '../image/image.dart';
import '../util/math_util.dart';

/// Add the [red], [green], [blue] and [alpha] values to the [src] image
/// colors, a per-channel brightness.
Image colorOffset(Image src,
    {num red = 0,
    num green = 0,
    num blue = 0,
    num alpha = 0,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  for (final frame in src.frames) {
    for (final p in frame) {
      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
      if (msk == null) {
        p
          ..r += red
          ..g += green
          ..b += blue
          ..a += alpha;
      } else {
        p
          ..r = mix(p.r, p.r + red, msk)
          ..g = mix(p.g, p.g + green, msk)
          ..b = mix(p.b, p.b + blue, msk)
          ..a = mix(p.a, p.a + alpha, msk);
      }
    }
  }
  return src;
}
