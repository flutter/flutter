import '../color/channel.dart';
import '../color/color.dart';
import '../image/image.dart';
import '../util/math_util.dart';

Image scaleRgba(Image src,
    {required Color scale,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  final dr = scale.rNormalized;
  final dg = scale.gNormalized;
  final db = scale.bNormalized;
  final da = scale.aNormalized;
  for (final frame in src.frames) {
    for (final p in frame) {
      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
      if (msk == null) {
        p.setRgba(p.r * dr, p.g * dg, p.b * db, p.a * da);
      } else {
        p
          ..r = mix(p.r, p.r * dr, msk)
          ..g = mix(p.g, p.g * dg, msk)
          ..b = mix(p.b, p.b * db, msk)
          ..a = mix(p.a, p.a * da, msk);
      }
    }
  }
  return src;
}
