import 'dart:math';

import '../color/channel.dart';
import '../image/image.dart';
import '../util/math_util.dart';

/// Apply the dot screen filter to the image.
Image dotScreen(Image src,
    {num angle = 180,
    num size = 5.75,
    int? centerX,
    int? centerY,
    num amount = 1,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  angle = angle * 0.0174533;
  final s = sin(angle);
  final c = cos(angle);
  for (final frame in src.frames) {
    final w = frame.width - 1;
    final h = frame.height - 1;
    final cntX = (centerX ?? w ~/ 2) / w;
    final cntY = (centerY ?? h ~/ 2) / h;

    num pattern(num cntX, num cntY, num tx, num ty) {
      final texX = (tx - cntX) * w;
      final texY = (ty - cntY) * h;
      final pointX = (c * texX - s * texY) * size;
      final pointY = (s * texX + c * texY) * size;
      return (sin(pointX) * sin(pointY)) * 4.0;
    }

    for (final p in frame) {
      final average = p.luminanceNormalized;
      final pat = pattern(cntX, cntY, p.x / w, p.y / h);
      final c = (average * 10 - 5 + pat) * p.maxChannelValue;
      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
      final mx = (msk ?? 1) * amount;
      p
        ..r = mix(p.r, c, mx)
        ..g = mix(p.g, c, mx)
        ..b = mix(p.b, c, mx);
    }
  }
  return src;
}
