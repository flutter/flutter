part of game;

typedef void PointSetterCallback(Point value);

class ActionCircularMove extends ActionInterval {
  ActionCircularMove(this.setter, this.center, this.radius, this.startAngle, this.clockWise, double duration) : super (duration);

  final PointSetterCallback setter;
  final Point center;
  final double radius;
  final double startAngle;
  final bool clockWise;

  void update(double t) {
    if (!clockWise) t = -t;
    double rad = radians(startAngle + t * 360.0);
    Offset offset = new Offset(math.cos(rad) * radius, math.sin(rad) * radius);
    Point pos = center + offset;
    setter(pos);
  }
}

class ActionOscillate extends ActionInterval {
  ActionOscillate(this.setter, this.center, this.radius, double duration) : super(duration);

  final PointSetterCallback setter;
  final Point center;
  final double radius;

  void update(double t) {
    double rad = radians(t * 360.0);
    Offset offset = new Offset(math.sin(rad) * radius, 0.0);
    setter(center + offset);
  }
}
