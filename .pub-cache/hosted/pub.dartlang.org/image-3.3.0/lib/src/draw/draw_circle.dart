import '../image.dart';
import '../util/point.dart';
import 'draw_line.dart';
import 'draw_pixel.dart';

/// Draw a circle into the [image] with a center of [x0],[y0] and
/// the given [radius] and [color].
Image drawCircle(Image image, int x0, int y0, int radius, int color) {
  final points = _calculateCircumference(image, x0, y0, radius);
  return _draw(image, points, color);
}

/// Draw and fill a circle into the [image] with a center of [x0],[y0]
/// and the given [radius] and [color].
///
/// The algorithm uses the same logic as [drawCircle] to calculate each point
/// around the circle's circumference. Then it iterates through every point,
/// finding the smallest and largest y-coordinate values for a given x-
/// coordinate.
///
/// Once found, it draws a line connecting those two points. The circle is thus
/// filled one vertical slice at a time (each slice being 1-pixel wide).
Image fillCircle(Image image, int x0, int y0, int radius, int color) {
  final points = _calculateCircumference(image, x0, y0, radius);

  // sort points by x-coordinate and then by y-coordinate
  points.sort((a, b) => (a.x == b.x) ? a.y.compareTo(b.y) : a.x.compareTo(b.x));

  var start = points.first;
  var end = points.first;

  for (var pt in points.sublist(1)) {
    if (pt.x == start.x) {
      end = pt;
    } else {
      drawLine(image, start.xi, start.yi, end.xi, end.yi, color);
      start = pt;
      end = pt;
    }
  }
  drawLine(image, start.xi, start.yi, end.xi, end.yi, color);
  return image;
}

/// Calculate the pixels that make up the circumference of a circle on the
/// given [image], centered at [x0],[y0] and the given [radius].
///
/// The returned list of points is sorted, first by the x coordinate, and
/// second by the y coordinate.
List<Point> _calculateCircumference(Image image, int x0, int y0, int radius) {
  if (radius < 0 ||
      x0 - radius >= image.width ||
      y0 + radius < 0 ||
      y0 - radius >= image.height) {
    return [];
  }

  if (radius == 0) {
    return [Point(x0, y0)];
  }

  final points = <Point>[];
  points.add(Point(x0 - radius, y0));
  points.add(Point(x0 + radius, y0));
  points.add(Point(x0, y0 - radius));
  points.add(Point(x0, y0 + radius));

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

      points.add(Point(x1, y1));
      points.add(Point(x1, y2));
      points.add(Point(x2, y1));
      points.add(Point(x2, y2));

      if (x != y) {
        points.add(Point(x3, y3));
        points.add(Point(x4, y4));
        points.add(Point(x4, y3));
        points.add(Point(x3, y4));
      }
    }
  }

  return points;
}

/// Given a list of [points], draw each corresponding pixel into the [image]
/// with the given [color].
Image _draw(Image image, List<Point> points, int color) {
  for (var pt in points) {
    drawPixel(image, pt.xi, pt.yi, color);
  }
  return image;
}
