import 'dart:math';

import '../color/channel.dart';
import '../image/image.dart';
import '../util/math_util.dart';

/// Apply color halftone filter to the image.
Image colorHalftone(Image src,
    {num amount = 1,
    int? centerX,
    int? centerY,
    num angle = 180,
    num size = 5,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  angle = angle * 0.0174533;

  num pattern(int x, int y, int cx, int cy, num angle) {
    final scale = 3.14159 / size;
    final s = sin(angle);
    final c = cos(angle);
    final tx = x - cx;
    final ty = y - cy;
    final px = (c * tx - s * ty) * scale;
    final py = (s * tx + c * ty) * scale;
    return (sin(px) * sin(py)) * 4.0;
  }

  for (final frame in src.frames) {
    final w = frame.width;
    final h = frame.height;
    final cx = centerX ?? w ~/ 2;
    final cy = centerY ?? h ~/ 2;
    for (final p in frame) {
      final x = p.x;
      final y = p.y;
      var cmyC = 1 - p.rNormalized;
      var cmyM = 1 - p.gNormalized;
      var cmyY = 1 - p.bNormalized;
      var cmyK = min(cmyC, min(cmyM, cmyY));
      cmyC = (cmyC - cmyK) / (1 - cmyK);
      cmyM = (cmyM - cmyK) / (1 - cmyK);
      cmyY = (cmyY - cmyK) / (1 - cmyK);
      cmyC =
          (cmyC * 10 - 3 + pattern(x, y, cx, cy, angle + 0.26179)).clamp(0, 1);
      cmyM =
          (cmyM * 10 - 3 + pattern(x, y, cx, cy, angle + 1.30899)).clamp(0, 1);
      cmyY = (cmyY * 10 - 3 + pattern(x, y, cx, cy, angle)).clamp(0, 1);
      cmyK =
          (cmyK * 10 - 5 + pattern(x, y, cx, cy, angle + 0.78539)).clamp(0, 1);

      final r = (1 - cmyC - cmyK) * p.maxChannelValue;
      final g = (1 - cmyM - cmyK) * p.maxChannelValue;
      final b = (1 - cmyY - cmyK) * p.maxChannelValue;

      final msk = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel);
      final mx = (msk ?? 1) * amount;

      if (mx != 1) {
        p
          ..r = mix(p.r, r, mx)
          ..g = mix(p.g, g, mx)
          ..b = mix(p.b, b, mx);
      } else {
        p
          ..r = r
          ..g = g
          ..b = b;
      }
    }
  }
  return src;
}
