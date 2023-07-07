import '../color/channel.dart';
import '../image/image.dart';
import '../util/math_util.dart';
import '../util/min_max.dart';

/// Linearly normalize the colors of the image. All color values will be mapped
/// to the range [min], [max] inclusive.
Image normalize(Image src,
    {required num min,
    required num max,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  final num a = min < max ? min : max;
  final num b = min < max ? max : min;

  final mM = minMax(src);
  final mn = mM[0];
  final mx = mM[1];

  if (mn == mx) {
    return src;
  }

  final fm = mn.toDouble();
  final fM = mx.toDouble();

  if (mn != a || mx != b) {
    for (var frame in src.frames) {
      for (final p in frame) {
        final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
        if (msk == null) {
          p
            ..r = (p.r - fm) / (fM - fm) * (b - a) + a
            ..g = (p.g - fm) / (fM - fm) * (b - a) + a
            ..b = (p.b - fm) / (fM - fm) * (b - a) + a
            ..a = (p.a - fm) / (fM - fm) * (b - a) + a;
        } else {
          final xr = (p.r - fm) / (fM - fm) * (b - a) + a;
          final xg = (p.g - fm) / (fM - fm) * (b - a) + a;
          final xb = (p.b - fm) / (fM - fm) * (b - a) + a;
          final xa = (p.a - fm) / (fM - fm) * (b - a) + a;
          p
            ..r = mix(p.r, xr, msk)
            ..g = mix(p.g, xg, msk)
            ..b = mix(p.b, xb, msk)
            ..a = mix(p.a, xa, msk);
        }
      }
    }
  }

  return src;
}
