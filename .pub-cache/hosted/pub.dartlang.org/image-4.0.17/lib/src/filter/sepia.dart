import '../color/channel.dart';
import '../image/image.dart';
import '../util/color_util.dart';

/// Apply sepia tone to the image.
///
/// [amount] controls the strength of the effect, in the range \[0, 1\].
Image sepia(Image src,
    {num amount = 1, Image? mask, Channel maskChannel = Channel.luminance}) {
  if (amount == 0) {
    return src;
  }

  for (final frame in src.frames) {
    for (final p in frame) {
      final r = p.rNormalized;
      final g = p.gNormalized;
      final b = p.bNormalized;
      final y = getLuminanceRgb(r, g, b);
      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
      final mx = (msk ?? 1) * amount;
      p
        ..rNormalized = (mx * (y + 0.15)) + ((1.0 - mx) * r)
        ..gNormalized = (mx * (y + 0.07)) + ((1.0 - mx) * g)
        ..bNormalized = (mx * (y - 0.12)) + ((1.0 - mx) * b);
    }
  }

  return src;
}
