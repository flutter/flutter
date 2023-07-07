import 'dart:math';

import '../image/image.dart';
import '../util/_circle_test.dart';

/// Returns a circle cropped copy of [src], centered at [centerX] and
/// [centerY] and with the given [radius]. If [radius] is not provided,
/// a radius filling the image will be used. If [centerX] is not provided,
/// the horizontal mid-point of the image will be used. If [centerY] is not
/// provided, the vertical mid-point of the image will be used.
Image copyCropCircle(Image src,
    {int? radius, int? centerX, int? centerY, bool antialias = true}) {
  centerX ??= src.width ~/ 2;
  centerY ??= src.height ~/ 2;
  radius ??= min(src.width, src.height) ~/ 2;

  // Make sure center point is within the range of the src image
  centerX = centerX.clamp(0, src.width - 1);
  centerY = centerY.clamp(0, src.height - 1);
  if (radius < 1) {
    radius = min(src.width, src.height) ~/ 2;
  }

  final tlx = centerX - radius; //topLeft.x
  final tly = centerY - radius; //topLeft.y

  final wh = radius * 2;
  final radiusSqr = radius * radius;

  if (src.hasPalette) {
    src = src.convert(numChannels: 4);
  }

  Image? firstFrame;
  final numFrames = src.numFrames;
  for (var i = 0; i < numFrames; ++i) {
    final frame = src.frames[i];
    final dst = firstFrame?.addFrame() ??
        Image.fromResized(frame, width: wh, height: wh, noAnimation: true);
    firstFrame ??= dst;

    final bg = frame.backgroundColor ?? src.backgroundColor;
    if (bg != null) {
      dst.clear(bg);
    }

    final dh = dst.height;
    final dw = radius * 2;
    for (var yi = 0, sy = tly; yi < dh; ++yi, ++sy) {
      for (var xi = 0, sx = tlx; xi < dw; ++xi, ++sx) {
        final p = frame.getPixel(sx, sy);
        final a =
            circleTest(p, centerX, centerY, radiusSqr, antialias: antialias);

        if (a != 1) {
          dst.getPixel(xi, yi).setRgba(p.r, p.g, p.b, p.a * a);
        } else {
          dst.setPixel(xi, yi, p);
        }
      }
    }
  }

  return firstFrame!;
}
