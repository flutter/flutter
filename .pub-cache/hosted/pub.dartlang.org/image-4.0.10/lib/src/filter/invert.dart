import '../color/channel.dart';
import '../image/image.dart';
import '../util/math_util.dart';

/// Invert the colors of the [src] image.
Image invert(Image src,
    {Image? mask, Channel maskChannel = Channel.luminance}) {
  final max = src.maxChannelValue;
  for (final frame in src.frames) {
    if (src.hasPalette) {
      final p = frame.palette!;
      final numColors = p.numColors;
      for (var i = 0; i < numColors; ++i) {
        final r = max - p.getRed(i);
        final g = max - p.getGreen(i);
        final b = max - p.getBlue(i);
        p.setRgb(i, r, g, b);
      }
    } else {
      if (max != 0.0) {
        for (final p in frame) {
          final msk =
              mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);

          if (msk == null) {
            p
              ..r = max - p.r
              ..g = max - p.g
              ..b = max - p.b;
          } else {
            p
              ..r = mix(p.r, max - p.r, msk)
              ..g = mix(p.g, max - p.g, msk)
              ..b = mix(p.b, max - p.b, msk);
          }
        }
      }
    }
  }
  return src;
}
