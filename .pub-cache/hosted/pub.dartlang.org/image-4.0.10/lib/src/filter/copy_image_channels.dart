import '../color/channel.dart';
import '../image/image.dart';
import '../util/math_util.dart';

/// Copy channels from the [from] image to the [src] image. If [scaled] is
/// true, then the from image will be scaled to the src image resolution.
Image copyImageChannels(Image src,
    {required Image from,
    bool scaled = false,
    Channel? red,
    Channel? green,
    Channel? blue,
    Channel? alpha,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  final dx = from.width / src.width;
  final dy = from.height / src.height;
  final fromPixel = from.getPixel(0, 0);
  for (final frame in src.frames) {
    for (final p in frame) {
      if (scaled) {
        fromPixel.setPosition((p.x * dx).floor(), (p.y * dy).floor());
      } else {
        fromPixel.setPosition(p.x, p.y);
      }

      final r =
          red != null ? fromPixel.getChannelNormalized(red) : p.rNormalized;
      final g =
          green != null ? fromPixel.getChannelNormalized(green) : p.gNormalized;
      final b =
          blue != null ? fromPixel.getChannelNormalized(blue) : p.bNormalized;
      final a =
          alpha != null ? fromPixel.getChannelNormalized(alpha) : p.aNormalized;

      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
      if (msk == null) {
        p
          ..rNormalized = r
          ..gNormalized = g
          ..bNormalized = b
          ..aNormalized = a;
      } else {
        p
          ..rNormalized = mix(p.r, r, msk)
          ..gNormalized = mix(p.g, g, msk)
          ..bNormalized = mix(p.b, b, msk)
          ..aNormalized = mix(p.a, a, msk);
      }
    }
  }
  return src;
}
