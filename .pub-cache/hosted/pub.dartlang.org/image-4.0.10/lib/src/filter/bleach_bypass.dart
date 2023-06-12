import '../color/channel.dart';
import '../image/image.dart';
import '../util/math_util.dart';

Image bleachBypass(Image src,
    {num amount = 1, Image? mask, Channel maskChannel = Channel.luminance}) {
  const luminanceR = 0.2125;
  const luminanceG = 0.7154;
  const luminanceB = 0.0721;
  for (final frame in src.frames) {
    for (final p in frame) {
      final r = p.rNormalized;
      final g = p.gNormalized;
      final b = p.bNormalized;
      final lr = r * luminanceR;
      final lg = g * luminanceG;
      final lb = b * luminanceB;
      final l = lr + lg + lb;

      final mixAmount = ((l - 0.45) * 10).clamp(0, 1);
      final branch1R = 2 * r * l;
      final branch1G = 2 * g * l;
      final branch1B = 2 * b * l;
      final branch2R = 1 - (2 * (1 - r) * (1 - l));
      final branch2G = 1 - (2 * (1 - g) * (1 - l));
      final branch2B = 1 - (2 * (1 - b) * (1 - l));

      final msk =
          mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel) ?? 1;
      final mx = msk * amount;

      if (mx != 1) {
        final nr = mix(branch1R, branch2R, mixAmount) * p.maxChannelValue;
        final ng = mix(branch1G, branch2G, mixAmount) * p.maxChannelValue;
        final nb = mix(branch1B, branch2B, mixAmount) * p.maxChannelValue;
        p
          ..r = mix(p.r, nr, amount)
          ..g = mix(p.g, ng, amount)
          ..b = mix(p.b, nb, amount);
      } else {
        p
          ..rNormalized = mix(branch1R, branch2R, mixAmount)
          ..gNormalized = mix(branch1G, branch2G, mixAmount)
          ..bNormalized = mix(branch1B, branch2B, mixAmount);
      }
    }
  }
  return src;
}
