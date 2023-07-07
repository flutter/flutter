import '../image/image.dart';
import '../util/_circle_test.dart';

/// Returns a cropped copy of [src].
Image copyCrop(Image src,
    {required int x,
    required int y,
    required int width,
    required int height,
    num radius = 0,
    bool antialias = true}) {
  // Make sure crop rectangle is within the range of the src image.
  x = x.clamp(0, src.width - 1).toInt();
  y = y.clamp(0, src.height - 1).toInt();
  if (x + width > src.width) {
    width = src.width - x;
  }
  if (y + height > src.height) {
    height = src.height - y;
  }

  if (radius > 0 && src.hasPalette) {
    src = src.convert(numChannels: src.numChannels);
  }

  Image? firstFrame;
  final numFrames = src.numFrames;
  for (var i = 0; i < numFrames; ++i) {
    final frame = src.frames[i];
    final dst = firstFrame?.addFrame() ??
        Image.fromResized(frame,
            width: width, height: height, noAnimation: true);
    firstFrame ??= dst;

    if (radius > 0) {
      final rad = radius.round();
      final rad2 = rad * rad;
      final x1 = x;
      final y1 = y;
      final x2 = x + width;
      final y2 = y + height;
      final c1x = x1 + rad - 1;
      final c1y = y1 + rad - 1;
      final c2x = x2 - rad + 1;
      final c2y = y1 + rad - 1;
      final c3x = x2 - rad + 1;
      final c3y = y2 - rad + 1;
      final c4x = x1 + rad - 1;
      final c4y = y2 - rad + 1;

      final iter = src.getRange(x1, y1, width, height);
      while (iter.moveNext()) {
        final p = iter.current;
        final px = p.x;
        final py = p.y;

        num a = 1;
        if (px < c1x && py < c1y) {
          a = circleTest(p, c1x, c1y, rad2, antialias: antialias);
          if (a == 0) {
            dst.setPixelRgba(p.x - x1, p.y - y1, 0, 0, 0, 0);
            continue;
          }
        } else if (px > c2x && py < c2y) {
          a = circleTest(p, c2x, c2y, rad2, antialias: antialias);
          if (a == 0) {
            dst.setPixelRgba(p.x - x1, p.y - y1, 0, 0, 0, 0);
            continue;
          }
        } else if (px > c3x && py > c3y) {
          a = circleTest(p, c3x, c3y, rad2, antialias: antialias);
          if (a == 0) {
            dst.setPixelRgba(p.x - x1, p.y - y1, 0, 0, 0, 0);
            continue;
          }
        } else if (px < c4x && py > c4y) {
          a = circleTest(p, c4x, c4y, rad2, antialias: antialias);
          if (a == 0) {
            dst.setPixelRgba(p.x - x1, p.y - y1, 0, 0, 0, 0);
            continue;
          }
        }

        if (a != 1) {
          dst.getPixel(p.x - x1, p.y - y1).setRgba(p.r, p.g, p.b, p.a * a);
        } else {
          dst.setPixel(p.x - x1, p.y - y1, p);
        }
      }
    } else {
      for (final p in dst) {
        p.set(frame.getPixel(x + p.x, y + p.y));
      }
    }
  }

  return firstFrame!;
}
