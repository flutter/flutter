part of flutter_sprites;


math.Random _random = new math.Random();

// Random methods

/// Returns a random [double] in the range of 0.0 to 1.0.
double randomDouble() {
  return _random.nextDouble();
}

/// Returns a random [double] in the range of -1.0 to 1.0.
double randomSignedDouble() {
  return _random.nextDouble() * 2.0 - 1.0;
}

/// Returns a random [int] from 0 to max - 1.
int randomInt(int max) {
  return _random.nextInt(max);
}

/// Returns either [true] or [false] in a most random fashion.
bool randomBool() {
  return _random.nextDouble() < 0.5;
}

// atan2

class _Atan2Constants {

  _Atan2Constants() {
    for (int i = 0; i <= size; i++) {
      double f = i.toDouble() / size.toDouble();
      ppy[i] = math.atan(f) * stretch / math.PI;
      ppx[i] = stretch * 0.5 - ppy[i];
      pny[i] = -ppy[i];
      pnx[i] = ppy[i] - stretch * 0.5;
      npy[i] = stretch - ppy[i];
      npx[i] = ppy[i] + stretch * 0.5;
      nny[i] = ppy[i] - stretch;
      nnx[i] = -stretch * 0.5 - ppy[i];
    }
  }

  static const int size = 1024;
  static const double stretch = math.PI;

  static const int ezis = -size;

  final Float64List ppy = new Float64List(size + 1);
  final Float64List ppx = new Float64List(size + 1);
  final Float64List pny = new Float64List(size + 1);
  final Float64List pnx = new Float64List(size + 1);
  final Float64List npy = new Float64List(size + 1);
  final Float64List npx = new Float64List(size + 1);
  final Float64List nny = new Float64List(size + 1);
  final Float64List nnx = new Float64List(size + 1);
}

/// Provides convenience methods for calculations often carried out in graphics.
/// Some of the methods are returning approximations.
class GameMath {
  static final _Atan2Constants _atan2 = new _Atan2Constants();

  /// Returns the angle of two vector components. The result is less acurate
  /// than the standard atan2 function in the math package.
  static double atan2(double y, double x) {
    if (x >= 0) {
      if (y >= 0) {
        if (x >= y)
          return _atan2.ppy[(_Atan2Constants.size * y / x + 0.5).toInt()];
        else
          return _atan2.ppx[(_Atan2Constants.size * x / y + 0.5).toInt()];
      } else {
        if (x >= -y)
          return _atan2.pny[(_Atan2Constants.ezis * y / x + 0.5).toInt()];
        else
          return _atan2.pnx[(_Atan2Constants.ezis * x / y + 0.5).toInt()];
      }
    } else {
      if (y >= 0) {
        if (-x >= y)
          return _atan2.npy[(_Atan2Constants.ezis * y / x + 0.5).toInt()];
        else
          return _atan2.npx[(_Atan2Constants.ezis * x / y + 0.5).toInt()];
      } else {
        if (x <= y)
          return _atan2.nny[(_Atan2Constants.size * y / x + 0.5).toInt()];
        else
          return _atan2.nnx[(_Atan2Constants.size * x / y + 0.5).toInt()];
      }
    }
  }

  /// Approximates the distance between two points. The returned value can be
  /// up to 6% wrong in the worst case.
  static double distanceBetweenPoints(Point a, Point b) {
    double dx = a.x - b.x;
    double dy = a.y - b.y;
    if (dx < 0.0) dx = -dx;
    if (dy < 0.0) dy = -dy;
    if (dx > dy) {
      return dx + dy/2.0;
    }
    else {
      return dy + dx/2.0;
    }
  }

  /// Interpolates a [double] between [a] and [b] according to the
  /// [filterFactor], which should be in the range of 0.0 to 1.0.
  static double filter (double a, double b, double filterFactor) {
      return (a * (1-filterFactor)) + b * filterFactor;
  }

  /// Interpolates a [Point] between [a] and [b] according to the
  /// [filterFactor], which should be in the range of 0.0 to 1.0.
  static Point filterPoint(Point a, Point b, double filterFactor) {
    return new Point(filter(a.x, b.x, filterFactor), filter(a.y, b.y, filterFactor));
  }

  /// Returns the intersection between two line segmentss defined by p0, p1 and
  /// q0, q1. If the lines are not intersecting null is returned.
  static Point lineIntersection(Point p0, Point p1, Point q0, Point q1) {
    double epsilon = 1e-10;

    Vector2 r = new Vector2(p1.x - p0.x, p1.y - p0.y);
    Vector2 s = new Vector2(q1.x - q0.x, q1.y - q0.y);
    Vector2 qp = new Vector2(q0.x - p0.x, q0.y - p0.y);

    double rxs = cross2(r, s);

    if (rxs.abs() < epsilon) {
      // The lines are linear or collinear
      return null;
    }

    double t = cross2(qp, s) / rxs;
    double u = cross2(qp, r) / rxs;

    if ((0.0 <= t && t <= 1.0) && (0.0 <= u && u <= 1.0)) {
      return new Point(p0.x + t * r.x, p0.y + t * r.y);
    }

    // No intersection between the lines
    return null;
  }
}
