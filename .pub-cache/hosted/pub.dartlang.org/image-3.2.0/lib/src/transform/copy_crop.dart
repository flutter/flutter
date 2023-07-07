import '../../image.dart' show Point;
import '../image.dart';

/// Returns a cropped copy of [src].
Image copyCrop(Image src, int x, int y, int w, int h) {
  // Make sure crop rectangle is within the range of the src image.
  x = x.clamp(0, src.width - 1).toInt();
  y = y.clamp(0, src.height - 1).toInt();
  if (x + w > src.width) {
    w = src.width - x;
  }
  if (y + h > src.height) {
    h = src.height - y;
  }

  final dst =
      Image(w, h, channels: src.channels, exif: src.exif, iccp: src.iccProfile);

  for (var yi = 0, sy = y; yi < h; ++yi, ++sy) {
    for (var xi = 0, sx = x; xi < w; ++xi, ++sx) {
      dst.setPixel(xi, yi, src.getPixel(sx, sy));
    }
  }

  return dst;
}

/// Returns a round cropped copy of [src].
Image copyCropCircle(Image src, {int? radius, Point? center}) {
  int min(num x, num y) => (x < y ? x : y).toInt();
  final defaultRadius = min(src.width, src.height) ~/ 2;
  radius ??= defaultRadius;
  center ??= Point(src.width ~/ 2, src.height ~/ 2);
  // Make sure center point is within the range of the src image
  center.x = center.x.clamp(0, src.width - 1).toInt();
  center.y = center.y.clamp(0, src.height - 1).toInt();
  radius = radius < 1 ? defaultRadius : radius;

  final tlx = center.x.toInt() - radius; //topLeft.x
  final tly = center.y.toInt() - radius; //topLeft.y

  final dst = Image(
    radius * 2,
    radius * 2,
    iccp: src.iccProfile,
  );

  for (var yi = 0, sy = tly; yi < radius * 2; ++yi, ++sy) {
    for (var xi = 0, sx = tlx; xi < radius * 2; ++xi, ++sx) {
      if ((xi - radius) * (xi - radius) + (yi - radius) * (yi - radius) <=
          radius * radius) {
        dst.setPixel(xi, yi, src.getPixelSafe(sx, sy));
      }
    }
  }

  return dst;
}
