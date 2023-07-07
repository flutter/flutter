import '../image/image.dart';
import '../util/point.dart';

/// Calculate the pixels that make up the circumference of a circle on the
/// given [image], centered at [x0],[y0] and the given [radius].
///
/// The returned list of points is sorted, first by the x coordinate, and
/// second by the y coordinate.
List<Point> calculateCircumference(Image image, int x0, int y0, int radius) {
  if (radius < 0 ||
      x0 - radius >= image.width ||
      y0 + radius < 0 ||
      y0 - radius >= image.height) {
    return [];
  }

  if (radius == 0) {
    return [Point(x0, y0)];
  }

  final points = [
    Point(x0 - radius, y0),
    Point(x0 + radius, y0),
    Point(x0, y0 - radius),
    Point(x0, y0 + radius)
  ];

  if (radius == 1) {
    return points;
  }

  for (var f = 1 - radius, ddFx = 0, ddFy = -(radius << 1), x = 0, y = radius;
      x < y;) {
    if (f >= 0) {
      f += (ddFy += 2);
      --y;
    }
    ++x;
    ddFx += 2;
    f += ddFx + 1;

    if (x != y + 1) {
      final x1 = x0 - y;
      final x2 = x0 + y;
      final y1 = y0 - x;
      final y2 = y0 + x;
      final x3 = x0 - x;
      final x4 = x0 + x;
      final y3 = y0 - y;
      final y4 = y0 + y;

      points
        ..add(Point(x1, y1))
        ..add(Point(x1, y2))
        ..add(Point(x2, y1))
        ..add(Point(x2, y2));

      if (x != y) {
        points
          ..add(Point(x3, y3))
          ..add(Point(x4, y4))
          ..add(Point(x4, y3))
          ..add(Point(x3, y4));
      }
    }
  }

  return points;
}
