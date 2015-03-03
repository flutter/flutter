part of widgets;

class FrameGenerator {

  Function onDone;
  StreamController _controller;

  Stream<double> get onTick => _controller.stream;

  int _animationId = 0;
  bool _cancelled = false;

  FrameGenerator({this.onDone}) {
    _controller = new StreamController(
      sync: true,
      onListen: _scheduleTick,
      onCancel: cancel);
  }

  void cancel() {
    if (_cancelled) {
      return;
    }
    if (_animationId != 0) {
      sky.window.cancelAnimationFrame(_animationId);
    }
    _animationId = 0;
    _cancelled = true;
    if (onDone != null) {
      onDone();
    }
  }

  void _scheduleTick() {
    assert(_animationId == 0);
    _animationId = sky.window.requestAnimationFrame(_tick);
  }

  void _tick(double timeStamp) {
    _animationId = 0;
    _controller.add(timeStamp);
    if (!_cancelled) {
      _scheduleTick();
    }
  }
}

const double _kFrameTime = 1000 / 60;

class AnimationGenerator extends FrameGenerator {

  Stream<double> get onTick => _stream;
  final double duration;
  final double begin;
  final double end;
  final Curve curve;
  Stream<double> _stream;

  AnimationGenerator(this.duration, {
    this.begin: 0.0,
    this.end: 1.0,
    this.curve: linear,
    Function onDone
  }):super(onDone: onDone) {
    double startTime = 0.0;
    double targetTime = 0.0;
    bool done = false;
    _stream = super.onTick.map((timeStamp) {
      if (startTime == 0.0) {
        startTime = timeStamp;
        targetTime = startTime + duration;
      }

      // Clamp the final frame to target time so we terminate the series with
      // 1.0 exactly.
      if ((timeStamp - targetTime).abs() <= _kFrameTime) {
        return 1.0;
      }

      return (timeStamp - startTime) / duration;
    })
    .takeWhile((t) => t <= 1.0)
    .map((t) =>  begin + (end - begin) * curve.transform(t));
  }
}

double _evaluateCubic(double a, double b, double m) {
  // TODO(abarth): Would Math.pow be faster?
  return 3 * a * (1 - m) * (1 - m) * m + 3 * b * (1 - m) * m * m + m * m * m;
}

const double _kCubicErrorBound = 0.001;

abstract class Curve {
  double transform(double t);
}

class Linear implements Curve {
  const Linear();

  double transform(double t) {
    return t;
  }
}

class Cubic implements Curve {
  final double a;
  final double b;
  final double c;
  final double d;

  const Cubic(this.a, this.b, this.c, this.d);

  double transform(double t) {
    if (t == 0.0 || t == 1.0)
      return t;

    double start = 0.0;
    double end = 1.0;
    while (true) {
      double midpoint = (start + end) / 2;
      double estimate = _evaluateCubic(a, c, midpoint);

      if ((t - estimate).abs() < _kCubicErrorBound)
        return _evaluateCubic(b, d, midpoint);

      if (estimate < t)
        start = midpoint;
      else
        end = midpoint;
    }
  }
}

const Linear linear = const Linear();
const Cubic ease = const Cubic(0.25, 0.1, 0.25, 1.0);
const Cubic easeIn = const Cubic(0.42, 0.0, 1.0, 1.0);
const Cubic easeOut = const Cubic(0.0, 0.0, 0.58, 1.0);
const Cubic easeInOut = const Cubic(0.42, 0.0, 0.58, 1.0);
