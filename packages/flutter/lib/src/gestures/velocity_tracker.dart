// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Point, Offset;

import 'lsq_solver.dart';

export 'dart:ui' show Point, Offset;

class _Estimate {
  const _Estimate({ this.xCoefficients, this.yCoefficients, this.time, this.degree, this.confidence });

  final List<double> xCoefficients;
  final List<double> yCoefficients;
  final Duration time;
  final int degree;
  final double confidence;

  @override
  String toString() {
    return 'Estimate(xCoefficients: $xCoefficients, '
                    'yCoefficients: $yCoefficients, '
                    'time: $time, '
                    'degree: $degree, '
                    'confidence: $confidence)';
  }
}

abstract class _VelocityTrackerStrategy {
  void addMovement(Duration timeStamp, Point position);
  _Estimate getEstimate();
  void clear();
}

enum _Weighting {
  weightingNone,
  weightingDelta,
  weightingCentral,
  weightingRecent
}

class _Movement {
  Duration eventTime = Duration.ZERO;
  Point position = Point.origin;
}

typedef double _WeightChooser(int index);

class _LeastSquaresVelocityTrackerStrategy extends _VelocityTrackerStrategy {
  static const int kHistorySize = 20;
  static const int kHorizonMilliseconds = 100;

  _LeastSquaresVelocityTrackerStrategy(this.degree, _Weighting weighting)
    : _index = 0, _movements = new List<_Movement>(kHistorySize) {
    switch (weighting) {
      case _Weighting.weightingNone:
        _chooseWeight = null;
        break;
      case _Weighting.weightingDelta:
        _chooseWeight = _weightDelta;
        break;
      case _Weighting.weightingCentral:
        _chooseWeight = _weightCentral;
        break;
      case _Weighting.weightingRecent:
        _chooseWeight = _weightRecent;
        break;
    }
  }

  final int degree;
  final List<_Movement> _movements;
  _WeightChooser _chooseWeight;
  int _index;

  @override
  void addMovement(Duration timeStamp, Point position) {
    _index += 1;
    if (_index == kHistorySize)
      _index = 0;
    _Movement movement = _getMovement(_index);
    movement.eventTime = timeStamp;
    movement.position = position;
  }

  @override
  _Estimate getEstimate() {
    // Iterate over movement samples in reverse time order and collect samples.
    List<double> x = new List<double>();
    List<double> y = new List<double>();
    List<double> w = new List<double>();
    List<double> time = new List<double>();
    int m = 0;
    int index = _index;
    _Movement newestMovement = _getMovement(index);
    do {
      _Movement movement = _getMovement(index);

      double age = (newestMovement.eventTime - movement.eventTime).inMilliseconds.toDouble();
      if (age > kHorizonMilliseconds)
        break;

      Point position = movement.position;
      x.add(position.x);
      y.add(position.y);
      w.add(_chooseWeight != null ? _chooseWeight(index) : 1.0);
      time.add(-age);
      index = (index == 0 ? kHistorySize : index) - 1;

      m += 1;
    } while (m < kHistorySize);

    if (m == 0) // because we broke out of the loop above after age > kHorizonMilliseconds
      return null; // no data

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
          return new _Estimate(
            xCoefficients: xFit.coefficients,
            yCoefficients: yFit.coefficients,
            time: newestMovement.eventTime,
            degree: n,
            confidence: xFit.confidence * yFit.confidence
          );
        }
      }
    }

    // No velocity data available for this pointer, but we do have its current
    // position.
    return new _Estimate(
      xCoefficients: <double>[ x[0] ],
      yCoefficients: <double>[ y[0] ],
      time: newestMovement.eventTime,
      degree: 0,
      confidence: 1.0
    );
  }

  @override
  void clear() {
    _index = -1;
  }

  double _weightDelta(int index) {
    // Weight points based on how much time elapsed between them and the next
    // point so that points that "cover" a shorter time span are weighed less.
    //   delta  0ms: 0.5
    //   delta 10ms: 1.0
    if (index == _index)
      return 1.0;
    int nextIndex = (index + 1) % kHistorySize;
    int deltaMilliseconds = (_movements[nextIndex].eventTime - _movements[index].eventTime).inMilliseconds;
    if (deltaMilliseconds < 0)
      return 0.5;
    if (deltaMilliseconds < 10)
      return 0.5 + deltaMilliseconds * 0.05;
    return 1.0;
  }

  double _weightCentral(int index) {
    // Weight points based on their age, weighing very recent and very old
    // points less.
    //   age  0ms: 0.5
    //   age 10ms: 1.0
    //   age 50ms: 1.0
    //   age 60ms: 0.5
    int ageMilliseconds = (_movements[_index].eventTime - _movements[index].eventTime).inMilliseconds;
    if (ageMilliseconds < 0)
      return 0.5;
    if (ageMilliseconds < 10)
      return 0.5 + ageMilliseconds * 0.05;
    if (ageMilliseconds < 50)
      return 1.0;
    if (ageMilliseconds < 60)
      return 0.5 + (60 - ageMilliseconds) * 0.05;
    return 0.5;
  }

  double _weightRecent(int index) {
    // Weight points based on their age, weighing older points less.
    //   age   0ms: 1.0
    //   age  50ms: 1.0
    //   age 100ms: 0.5
    int ageMilliseconds = (_movements[_index].eventTime - _movements[index].eventTime).inMilliseconds;
    if (ageMilliseconds < 50)
      return 1.0;
    if (ageMilliseconds < 100)
      return 0.5 + (100 - ageMilliseconds) * 0.01;
    return 0.5;
  }

  _Movement _getMovement(int i) {
    _Movement result = _movements[i];
    if (result == null) {
      result = new _Movement();
      _movements[i] = result;
    }
    return result;
  }

}

/// A velocity in two dimensions.
class Velocity {
  /// Creates a velocity.
  ///
  /// The [pixelsPerSecond] argument must not be null.
  const Velocity({ this.pixelsPerSecond });

  /// A velocity that isn't moving at all.
  static const Velocity zero = const Velocity(pixelsPerSecond: Offset.zero);

  /// The number of pixels per second of velocity in the x and y directions.
  final Offset pixelsPerSecond;

  /// Return the negation of a velocity.
  Velocity operator -() => new Velocity(pixelsPerSecond: -pixelsPerSecond);

  /// Return the difference of two velocities.
  Velocity operator -(Velocity other) {
    return new Velocity(
        pixelsPerSecond: pixelsPerSecond - other.pixelsPerSecond);
  }

  /// Return the sum of two velocities.
  Velocity operator +(Velocity other) {
    return new Velocity(
        pixelsPerSecond: pixelsPerSecond + other.pixelsPerSecond);
  }

  @override
  bool operator ==(dynamic other) {
    if (other is! Velocity)
      return false;
    final Velocity typedOther = other;
    return pixelsPerSecond == typedOther.pixelsPerSecond;
  }

  @override
  int get hashCode => pixelsPerSecond.hashCode;

  @override
  String toString() => 'Velocity(${pixelsPerSecond.dx.toStringAsFixed(1)}, ${pixelsPerSecond.dy.toStringAsFixed(1)})';
}

/// Computes a pointer velocity based on data from PointerMove events.
///
/// The input data is provided by calling addPosition(). Adding data
/// is cheap.
///
/// To obtain a velocity, call getVelocity(). This will compute the
/// velocity based on the data added so far. Only call this when you
/// need to use the velocity, as it is comparatively expensive.
///
/// The quality of the velocity estimation will be better if more data
/// points have been received.
class VelocityTracker {

  /// The maximum length of time between two move events to allow
  /// before assuming the pointer stopped.
  static const Duration kAssumePointerMoveStoppedTime = const Duration(milliseconds: 40);

  /// Creates a velocity tracker.
  VelocityTracker() : _strategy = _createStrategy();

  Duration _lastTimeStamp = const Duration();
  _VelocityTrackerStrategy _strategy;

  /// Add a given position corresponding to a specific time.
  ///
  /// If [kAssumePointerMoveStoppedTime] has elapsed since the last
  /// call, then earlier data will be discarded.
  void addPosition(Duration timeStamp, Point position) {
    if (timeStamp - _lastTimeStamp >= kAssumePointerMoveStoppedTime)
      _strategy.clear();
    _lastTimeStamp = timeStamp;
    _strategy.addMovement(timeStamp, position);
  }

  /// Computes the velocity of the pointer at the time of the last
  /// provided data point.
  ///
  /// This can be expensive. Only call this when you need the velocity.
  ///
  /// getVelocity() will return null if no estimate is available or if
  /// the velocity is zero.
  Velocity getVelocity() {
    _Estimate estimate = _strategy.getEstimate();
    if (estimate != null && estimate.degree >= 1) {
      return new Velocity(
        pixelsPerSecond: new Offset( // convert from pixels/ms to pixels/s
          estimate.xCoefficients[1] * 1000,
          estimate.yCoefficients[1] * 1000
        )
      );
    }
    return null;
  }

  static _VelocityTrackerStrategy _createStrategy() {
    return new _LeastSquaresVelocityTrackerStrategy(2, _Weighting.weightingNone);
  }
}
