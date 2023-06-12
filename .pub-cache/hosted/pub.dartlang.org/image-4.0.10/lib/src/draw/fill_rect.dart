import 'dart:math';

import '../color/channel.dart';
import '../color/color.dart';
import '../image/image.dart';
import '../util/_circle_test.dart';
import '../util/math_util.dart';

/// Fill a rectangle in the image [src] with the given [color] with the corners
/// [x1],[y1] and [x2],[y2].
Image fillRect(Image src,
    {required int x1,
    required int y1,
    required int x2,
    required int y2,
    required Color color,
    num radius = 0,
    Image? mask,
    Channel maskChannel = Channel.luminance}) {
  if (color.a == 0) {
    return src;
  }

  final xx0 = min(x1, x2).clamp(0, src.width - 1);
  final yy0 = min(y1, y2).clamp(0, src.height - 1);
  final xx1 = max(x1, x2).clamp(0, src.width - 1);
  final yy1 = max(y1, y2).clamp(0, src.height - 1);
  final ww = (xx1 - xx0) + 1;
  final hh = (yy1 - yy0) + 1;

  // Fill a rounded rect
  if (radius > 0) {
    final rad = radius.round();
    final rad2 = rad * rad;
    final c1x = xx0 + rad;
    final c1y = yy0 + rad;
    final c2x = xx1 - rad + 1;
    final c2y = yy0 + rad;
    final c3x = xx1 - rad + 1;
    final c3y = yy1 - rad + 1;
    final c4x = xx0 + rad;
    final c4y = yy1 - rad + 1;

    final iter = src.getRange(xx0, yy0, ww, hh);
    while (iter.moveNext()) {
      final p = iter.current;
      final px = p.x;
      final py = p.y;

      num a = 1;
      if (px < c1x && py < c1y) {
        a = circleTest(p, c1x, c1y, rad2);
        if (a == 0) {
          continue;
        }
      } else if (px > c2x && py < c2y) {
        a = circleTest(p, c2x, c2y, rad2);
        if (a == 0) {
          continue;
        }
      } else if (px > c3x && py > c3y) {
        a = circleTest(p, c3x, c3y, rad2);
        if (a == 0) {
          continue;
        }
      } else if (px < c4x && py > c4y) {
        a = circleTest(p, c4x, c4y, rad2);
        if (a == 0) {
          continue;
        }
      }

      a *= color.aNormalized;

      final m = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel) ?? 1;
      p
        ..r = mix(p.r, color.r, a * m)
        ..g = mix(p.g, color.g, a * m)
        ..b = mix(p.b, color.b, a * m)
        ..a = p.a * (1 - (color.a * m));
    }

    return src;
  }

  // If no blending is necessary, use a faster fill method.
  if (color.a == color.maxChannelValue && mask == null) {
    final iter = src.getRange(xx0, yy0, ww, hh);
    while (iter.moveNext()) {
      iter.current.set(color);
    }
  } else {
    final a = color.a / color.maxChannelValue;
    final iter = src.getRange(xx0, yy0, ww, hh);
    while (iter.moveNext()) {
      final p = iter.current;
      final m = mask?.getPixel(p.x, p.y).getChannelNormalized(maskChannel) ?? 1;
      p
        ..r = mix(p.r, color.r, a * m)
        ..g = mix(p.g, color.g, a * m)
        ..b = mix(p.b, color.b, a * m)
        ..a = p.a * (1 - (color.a * m));
    }
  }

  return src;
}
