part of skysprites;

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

class ActionSpline extends ActionInterval {
  ActionSpline(this.setter, this.points, double duration, [Curve curve]) : super(duration, curve) {
    _dt = 1.0 / (points.length - 1.0);
  }

  final Function setter;
  final List<Point> points;
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
