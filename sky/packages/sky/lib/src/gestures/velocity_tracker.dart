import 'dart:ui' as ui;

import 'lsq_solver.dart';

class GestureVelocity {
  GestureVelocity({ this.isValid: false, this.x: 0.0, this.y : 0.0 });

  final bool isValid;
  final double x;
  final double y;
}

class Estimator {
  int degree;
  double time;
  List<double> xcoeff;
  List<double> ycoeff;
  double confidence;

  String toString() {
    String result = "Estimator(degree: " + degree.toString();
    result +=  ", time: " + time.toString();
    result +=  ", confidence: " + confidence.toString();
    result +=  ", xcoeff: " + (new Vector.fromValues(xcoeff)).toString();
    result +=  ", ycoeff: " + (new Vector.fromValues(ycoeff)).toString();
    return result;
  }
}

abstract class VelocityTrackerStrategy {
  void addMovement(double timeStamp, double x, double y);
  bool getEstimator(Estimator estimator);
  void clear();
}

enum Weighting {
  WEIGHTING_NONE,
  WEIGHTING_DELTA,
  WEIGHTING_CENTRAL,
  WEIGHTING_RECENT
}

class Movement {
  double event_time = 0.0;
  ui.Point position = ui.Point.origin;
}

class LeastSquaresVelocityTrackerStrategy extends VelocityTrackerStrategy {
  static const int kHistorySize = 20;
  static const int kHorizonMS = 100;

  LeastSquaresVelocityTrackerStrategy(this.degree, this.weighting)
  : _index = 0, _movements = new List<Movement>(kHistorySize);

  final int degree;
  final Weighting weighting;
  final List<Movement> _movements;
  int _index;

  void addMovement(double timeStamp, double x, double y) {
    if (++_index == kHistorySize)
      _index = 0;
    Movement movement = _getMovement(_index);
    movement.event_time = timeStamp;
    movement.position = new ui.Point(x, y);
  }

  bool getEstimator(Estimator estimator) {
    // Iterate over movement samples in reverse time order and collect samples.
    List<double> x = new List<double>();
    List<double> y = new List<double>();
    List<double> w = new List<double>();
    List<double> time = new List<double>();
    int m = 0;
    int index = _index;
    Movement newest_movement = _getMovement(index);
    do {
      Movement movement = _getMovement(index);

      double age = newest_movement.event_time - movement.event_time;
      if (age > kHorizonMS)
        break;

      ui.Point position = movement.position;
      x.add(position.x);
      y.add(position.y);
      w.add(_chooseWeight(index));
      time.add(-age);
      index = (index == 0 ? kHistorySize : index) - 1;
    } while (++m < kHistorySize);

    if (m == 0)
      return false;  // no data

    // Calculate a least squares polynomial fit.
    int n = degree;
    if (n > m - 1)
      n = m - 1;

    if (n >= 1) {
      LeastSquaresSolver xSolver = new LeastSquaresSolver(time, x, w);
      PolynomialFit xFit = xSolver.solve(n);
      if (xFit != null) {
        LeastSquaresSolver ySolver = new LeastSquaresSolver(time, y, w);
        PolynomialFit yFit = ySolver.solve(n);
        if (yFit != null) {
          estimator.xcoeff = xFit.coefficients;
          estimator.ycoeff = yFit.coefficients;
          estimator.time = newest_movement.event_time;
          estimator.degree = n;
          estimator.confidence = xFit.confidence * yFit.confidence;
          return true;
        }
      }
    }

    // No velocity data available for this pointer, but we do have its current
    // position.
    estimator.xcoeff = [ x[0] ];
    estimator.ycoeff = [ y[0] ];
    estimator.time = newest_movement.event_time;
    estimator.degree = 0;
    estimator.confidence = 1.0;
    return true;
  }

  void clear() {
    _index = -1;
  }

  double _chooseWeight(int index) {
    switch (weighting) {
      case Weighting.WEIGHTING_DELTA:
        // Weight points based on how much time elapsed between them and the next
        // point so that points that "cover" a shorter time span are weighed less.
        //   delta  0ms: 0.5
        //   delta 10ms: 1.0
        if (index == _index) {
          return 1.0;
        }
        int next_index = (index + 1) % kHistorySize;
        double delta_millis = _movements[next_index].event_time -
          _movements[index].event_time;
        if (delta_millis < 0)
          return 0.5;
        if (delta_millis < 10)
          return 0.5 + delta_millis * 0.05;

        return 1.0;

      case Weighting.WEIGHTING_CENTRAL:
        // Weight points based on their age, weighing very recent and very old
        // points less.
        //   age  0ms: 0.5
        //   age 10ms: 1.0
        //   age 50ms: 1.0
        //   age 60ms: 0.5
        double age_millis = _movements[_index].event_time -
          _movements[index].event_time;
        if (age_millis < 0)
          return 0.5;
        if (age_millis < 10)
          return 0.5 + age_millis * 0.05;
        if (age_millis < 50)
          return 1.0;
        if (age_millis < 60)
          return 0.5 + (60 - age_millis) * 0.05;

        return 0.5;

      case Weighting.WEIGHTING_RECENT:
        // Weight points based on their age, weighing older points less.
        //   age   0ms: 1.0
        //   age  50ms: 1.0
        //   age 100ms: 0.5
        double age_millis = _movements[_index].event_time -
          _movements[index].event_time;
        if (age_millis < 50) {
          return 1.0;
        }
        if (age_millis < 100) {
          return 0.5 + (100 - age_millis) * 0.01;
        }
        return 0.5;

      case Weighting.WEIGHTING_NONE:
      default:
        return 1.0;
    }
  }

  Movement _getMovement(int i) {
      Movement result = _movements[i];
      if (result == null) {
        result = new Movement();
        _movements[i] = result;
      }
      return result;
  }

}

class VelocityTracker {
  static const int kAssumePointerMoveStoppedTimeMs = 40;

  VelocityTracker() : _lastTimeStamp = 0.0, _strategy = _createStrategy();

  double _lastTimeStamp;
  VelocityTrackerStrategy _strategy;

  void addPosition(double timeStamp, double x, double y) {
    if ((timeStamp - _lastTimeStamp) >= kAssumePointerMoveStoppedTimeMs)
      _strategy.clear();
    _lastTimeStamp = timeStamp;
    _strategy.addMovement(timeStamp, x, y);
  }

  GestureVelocity getVelocity() {
    Estimator estimator = new Estimator();
    if (_strategy.getEstimator(estimator) && estimator.degree >= 1) {
      // convert from pixels/ms to pixels/s
      return new GestureVelocity(
        isValid: true,
        x: estimator.xcoeff[1]*1000,
        y: estimator.ycoeff[1]*1000
      );
    }
    return new GestureVelocity(isValid: false, x: 0.0, y: 0.0);
  }

  static VelocityTrackerStrategy _createStrategy() {
    return new LeastSquaresVelocityTrackerStrategy(2, Weighting.WEIGHTING_NONE);
  }
}
