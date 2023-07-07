import 'dart:typed_data';

import '../image/image.dart';
import '../image/interpolation.dart';
import '../util/_circle_test.dart';
import '../util/image_exception.dart';

/// Returns a resized and square cropped copy of the [src] image of [size] size.
Image copyResizeCropSquare(Image src,
    {required int size,
    Interpolation interpolation = Interpolation.nearest,
    num radius = 0,
    bool antialias = false}) {
  if (size <= 0) {
    throw ImageException('Invalid size');
  }

  // You can't interpolate index pixels
  if (src.hasPalette) {
    interpolation = Interpolation.nearest;
  }

  var height = size;
  var width = size;
  if (src.width < src.height) {
    height = (size * (src.height / src.width)).toInt();
  } else if (src.width > src.height) {
    width = (size * (src.width / src.height)).toInt();
  }

  final dy = src.height / height;
  final dx = src.width / width;

  final xOffset = (width - size) ~/ 2;
  final yOffset = (height - size) ~/ 2;

  final scaleX =
      interpolation == Interpolation.nearest ? Int32List(size) : null;

  if (scaleX != null) {
    for (var x = 0; x < size; ++x) {
      scaleX[x] = ((x + xOffset) * dx).toInt();
    }
  }

  Image? firstFrame;
  for (final frame in src.frames) {
    final dst = firstFrame?.addFrame() ??
        Image.fromResized(frame, width: size, height: size, noAnimation: true);
    firstFrame ??= dst;

    // Rounded corners
    if (radius > 0) {
      final rad = radius.round();
      final rad2 = rad * rad;
      const x1 = 0;
      const y1 = 0;
      final x2 = size - 1;
      final y2 = size - 1;
      final c1x = x1 + rad - 1;
      final c1y = y1 + rad - 1;
      final c2x = x2 - rad + 1;
      final c2y = y1 + rad - 1;
      final c3x = x2 - rad + 1;
      final c3y = y2 - rad + 1;
      final c4x = x1 + rad - 1;
      final c4y = y2 - rad + 1;

      final iter = dst.getRange(x1, y1, width, height);
      while (iter.moveNext()) {
        final p = iter.current;
        final px = p.x;
        final py = p.y;

        num a = 1;
        if (px < c1x && py < c1y) {
          a = circleTest(p, c1x, c1y, rad2, antialias: antialias);
          if (a == 0) {
            p.setRgba(0, 0, 0, 0);
            continue;
          }
        } else if (px > c2x && py < c2y) {
          a = circleTest(p, c2x, c2y, rad2, antialias: antialias);
          if (a == 0) {
            p.setRgba(0, 0, 0, 0);
            continue;
          }
        } else if (px > c3x && py > c3y) {
          a = circleTest(p, c3x, c3y, rad2, antialias: antialias);
          if (a == 0) {
            p.setRgba(0, 0, 0, 0);
            continue;
          }
        } else if (px < c4x && py > c4y) {
          a = circleTest(p, c4x, c4y, rad2, antialias: antialias);
          if (a == 0) {
            p.setRgba(0, 0, 0, 0);
            continue;
          }
        }

        if (interpolation == Interpolation.nearest) {
          final sy = ((p.y + yOffset) * dy).toInt();
          final sp = frame.getPixel(scaleX![p.x], sy);
          p.setRgba(sp.r, sp.g, sp.b, sp.a * a);
        } else {
          final x = p.x * dx;
          final y = p.y * dy;
          final sp =
              frame.getPixelInterpolate(x, y, interpolation: interpolation);
          final spa = sp.a * a;
          p.setRgba(sp.r, sp.g, sp.b, spa);
        }
      }

      return dst;
    }

    if (interpolation == Interpolation.nearest) {
      for (var y = 0; y < size; ++y) {
        final y2 = ((y + yOffset) * dy).toInt();
        for (var x = 0; x < size; ++x) {
          dst.setPixel(x, y, frame.getPixel(scaleX![x], y2));
        }
      }
    } else {
      for (final p in dst) {
        final x = p.x * dx;
        final y = p.y * dy;
        p.set(frame.getPixelInterpolate(x, y, interpolation: interpolation));
      }
    }
  }

  return firstFrame!;
}
