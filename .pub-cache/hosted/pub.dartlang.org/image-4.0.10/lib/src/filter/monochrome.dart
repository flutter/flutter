import '../color/channel.dart';
import '../color/color.dart';
import '../image/image.dart';
import '../util/math_util.dart';

/// [amount] controls the strength of the effect, in the range \[0, 1\].
Image monochrome(Image src,
    {Color? color,
    num amount = 1,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (amount == 0) {
    return src;
  }

  final nr = color?.rNormalized ?? 0.45;
  final ng = color?.gNormalized ?? 0.6;
  final nb = color?.bNormalized ?? 0.3;

  for (final frame in src.frames) {
    for (final p in frame) {
      final y = p.luminanceNormalized;

      final r = y < 0.5 ? (2 * y * nr) : 1 - 2 * (1 - y) * (1 - nr);
      final g = y < 0.5 ? (2 * y * ng) : 1 - 2 * (1 - y) * (1 - ng);
      final b = y < 0.5 ? (2 * y * nb) : 1 - 2 * (1 - y) * (1 - nb);
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
