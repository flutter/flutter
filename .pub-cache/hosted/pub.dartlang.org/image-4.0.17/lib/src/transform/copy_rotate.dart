import 'dart:math';

import '../image/image.dart';
import '../image/interpolation.dart';

/// Returns a copy of the [src] image, rotated by [angle] degrees.
Image copyRotate(Image src,
    {required num angle, Interpolation interpolation = Interpolation.nearest}) {
  final num nAngle = angle % 360.0;

  // You can't interpolate index pixels
  if (src.hasPalette) {
    interpolation = Interpolation.nearest;
  }

  // Optimized version for orthogonal angles.
  if ((nAngle % 90.0) == 0.0) {
    final iAngle = nAngle ~/ 90.0;
    switch (iAngle) {
      case 1: // 90 deg.
        return _rotate90(src);
      /**/
      case 2: // 180 deg.
        return _rotate180(src);
      case 3: // 270 deg.
        return _rotate270(src);
      default: // 0 deg.
        return Image.from(src);
    }
  }

  // Generic angle.
  final rad = nAngle * pi / 180.0;
  final ca = cos(rad);
  final sa = sin(rad);
  final ux = (src.width * ca).abs();
  final uy = (src.width * sa).abs();
  final vx = (src.height * sa).abs();
  final vy = (src.height * ca).abs();
  final w2 = 0.5 * src.width;
  final h2 = 0.5 * src.height;
  final dw2 = 0.5 * (ux + vx);
  final dh2 = 0.5 * (uy + vy);

  Image? firstFrame;
  final numFrames = src.numFrames;
  for (var i = 0; i < numFrames; ++i) {
    final frame = src.frames[i];
    final dst = firstFrame?.addFrame() ??
        Image.fromResized(src,
            width: (ux + vx).toInt(),
            height: (uy + vy).toInt(),
            noAnimation: true);
    firstFrame ??= dst;
    final bg = frame.backgroundColor ?? src.backgroundColor;
    if (bg != null) {
      dst.clear(bg);
    }

    for (final p in dst) {
      final x = p.x;
      final y = p.y;
      final x2 = w2 + (x - dw2) * ca + (y - dh2) * sa;
      final y2 = h2 - (x - dw2) * sa + (y - dh2) * ca;
      if (frame.isBoundsSafe(x2, y2)) {
        final c =
            frame.getPixelInterpolate(x2, y2, interpolation: interpolation);
        dst.setPixel(x, y, c);
      }
    }
  }

  return firstFrame!;
}

Image _rotate90(Image src) {
  Image? firstFrame;
  for (final frame in src.frames) {
    final dst = firstFrame?.addFrame() ??
        Image.fromResized(frame,
            width: frame.height, height: frame.width, noAnimation: true);
    firstFrame ??= dst;
    final hm1 = frame.height - 1;
    for (var y = 0; y < dst.height; ++y) {
      for (var x = 0; x < dst.width; ++x) {
        dst.setPixel(x, y, frame.getPixel(y, hm1 - x));
      }
    }
  }
  return firstFrame!;
}

Image _rotate180(Image src) {
  Image? firstFrame;
  for (final frame in src.frames) {
    final wm1 = frame.width - 1;
    final hm1 = frame.height - 1;
    final dst = firstFrame?.addFrame() ??
        Image.from(frame, noAnimation: true, noPixels: true);
    firstFrame ??= dst;
    for (var y = 0; y < dst.height; ++y) {
      for (var x = 0; x < dst.width; ++x) {
        dst.setPixel(x, y, frame.getPixel(wm1 - x, hm1 - y));
      }
    }
  }
  return firstFrame!;
}

Image _rotate270(Image src) {
  Image? firstFrame;
  for (final frame in src.frames) {
    final wm1 = src.width - 1;
    final dst = firstFrame?.addFrame() ??
        Image.fromResized(frame,
            width: frame.height, height: frame.width, noAnimation: true);
    firstFrame ??= dst;
    for (var y = 0; y < dst.height; ++y) {
      for (var x = 0; x < dst.width; ++x) {
        dst.setPixel(x, y, frame.getPixel(wm1 - y, x));
      }
    }
  }
  return firstFrame!;
}
