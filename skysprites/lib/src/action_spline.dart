part of flutter_sprites;

Point _cardinalSplineAt(Point p0, Point p1, Point p2, Point p3, double tension, double t) {
  double t2 = t * t;
  double t3 = t2 * t;

  double s = (1.0 - tension) / 2.0;

  double b1 = s * ((-t3 + (2.0 * t2)) - t);
	double b2 = s * (-t3 + t2) + (2.0 * t3 - 3.0 * t2 + 1.0);
	double b3 = s * (t3 - 2.0 * t2 + t) + (-2.0 * t3 + 3.0 * t2);
	double b4 = s * (t3 - t2);

  double x = p0.x * b1 + p1.x * b2 + p2.x * b3 + p3.x * b4;
	double y = p0.y * b1 + p1.y * b2 + p2.y * b3 + p3.y * b4;

  return new Point(x, y);
}

typedef void PointSetterCallback(Point value);

/// The spline action is used to animate a point along a spline definied by
/// a set of points.
class ActionSpline extends ActionInterval {

  /// Creates a new spline action with a set of points. The [setter] is a
  /// callback for setting the positions, [points] define the spline, and
  /// [duration] is the time for the action to complete. Optionally a [curve]
  /// can be used for easing.
  ActionSpline(this.setter, this.points, double duration, [Curve curve]) : super(duration, curve) {
    _dt = 1.0 / (points.length - 1.0);
  }

  /// The callback used to update a point when the action is run.
  final PointSetterCallback setter;

  /// A list of points that define the spline.
  final List<Point> points;

  /// The tension of the spline, defines the roundness of the curve.
  double tension = 0.5;

  double _dt;

  void update(double t) {

    int p;
    double lt;

    if (t < 0.0) t = 0.0;

    if (t >= 1.0) {
      p = points.length - 1;
      lt = 1.0;
    } else {
      p = (t / _dt).floor();
      lt = (t - _dt * p) / _dt;
    }

    Point p0 = points[(p - 1).clamp(0, points.length - 1)];
    Point p1 = points[(p + 0).clamp(0, points.length - 1)];
    Point p2 = points[(p + 1).clamp(0, points.length - 1)];
    Point p3 = points[(p + 2).clamp(0, points.length - 1)];

    Point newPos = _cardinalSplineAt(p0, p1, p2, p3, tension, lt);

    setter(newPos);
  }
}
