// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Point, Offset;

import 'lsq_solver.dart';

export 'dart:ui' show Point, Offset;

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

  /// Clamp the magnitude of this velocity to [minValue] and [maxValue] if necessary.
  ///
  /// If the magnitude of this Velocity is less than minValue then return a new
  /// Velocity with the same direction and with magnitude [minValue]. Similarly,
  /// if the magnitude of this Velocity is greater than maxValue then return a
  /// new Velocity with the same direction and magnitude [maxValue].
  ///
  /// If the magnitude of this Velocity is within the specified bounds then
  /// just return this.
  Velocity clampMagnitude(double minValue, double maxValue) {
    assert(minValue != null && minValue >= 0.0);
    assert(maxValue != null && maxValue >= 0.0 && maxValue >= minValue);
    final double valueSquared = pixelsPerSecond.distanceSquared;
    if (valueSquared > maxValue * maxValue)
      return new Velocity(pixelsPerSecond: (pixelsPerSecond / pixelsPerSecond.distance) * maxValue);
    if (valueSquared < minValue * minValue)
      return new Velocity(pixelsPerSecond: (pixelsPerSecond / pixelsPerSecond.distance) * minValue);
    return this;
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

/// A two dimensional velocity estimate.
class VelocityEstimate {
  const VelocityEstimate({
    this.pixelsPerSecond,
    this.confidence,
    this.duration,
    this.offset,
  });

  /// The number of pixels per second of velocity in the x and y directions.
  final Offset pixelsPerSecond;

  final double confidence;
  final Duration duration;
  final Offset offset;

  @override
  String toString() => 'VelocityEstimate(${pixelsPerSecond.dx.toStringAsFixed(1)}, ${pixelsPerSecond.dy.toStringAsFixed(1)})';
}

abstract class _VelocityTrackerStrategy {
  void addMovement(Duration timeStamp, Point position);
  VelocityEstimate getEstimate();
  void clear();
}

class _Movement {
  const _Movement(this.eventTime, this.position);

  final Duration eventTime;
  final Point position;

  @override
  String toString() => 'Movement($position at $eventTime)';
}

// TODO: On iOS we're not necccessarily seeing all of the motion events. See:
// https://github.com/flutter/flutter/issues/4737#issuecomment-241076994

class _LeastSquaresVelocityTrackerStrategy extends _VelocityTrackerStrategy {
  _LeastSquaresVelocityTrackerStrategy(this.degree);

  final int degree;

  final List<_Movement> _movements = new List<_Movement>(kHistorySize);
  int _index = 0;

  static const int kHistorySize = 20;
  static const int kHorizonMilliseconds = 100;

  // The maximum length of time between two move events to allow before
  // assuming the pointer stopped.
  static const int kAssumePointerMoveStoppedMilliseconds = 40;

  @override
  void addMovement(Duration timeStamp, Point position) {
    _index += 1;
    if (_index == kHistorySize)
      _index = 0;
    _movements[_index] = new _Movement(timeStamp, position);
  }

  @override
  VelocityEstimate getEstimate() {
    // Iterate over movement samples in reverse time order and collect samples.
    final List<double> x = <double>[];
    final List<double> y = <double>[];
    final List<double> w = <double>[];
    final List<double> time = <double>[];
    int m = 0;
    int index = _index;

    final _Movement newestMovement = _movements[index];
    _Movement previousMovement = newestMovement;
    _Movement oldestMovement = newestMovement;
    if (newestMovement == null)
      return null;

    do {
      final _Movement movement = _movements[index];
      if (movement == null)
        break;

      final double age = (newestMovement.eventTime - movement.eventTime).inMilliseconds.toDouble();
      final double delta = (movement.eventTime - previousMovement.eventTime).inMilliseconds.abs().toDouble();
      previousMovement = movement;
      if (age > kHorizonMilliseconds || delta > kAssumePointerMoveStoppedMilliseconds)
        break;

      oldestMovement = movement;
      final Point position = movement.position;
      x.add(position.x);
      y.add(position.y);
      w.add(1.0);
      time.add(-age);
      index = (index == 0 ? kHistorySize : index) - 1;

      m += 1;
    } while (m < kHistorySize);

    // Calculate a least squares polynomial fit.
    int n = degree;
    if (n > m - 1)
      n = m - 1;

    if (n >= 1) {
      final LeastSquaresSolver xSolver = new LeastSquaresSolver(time, x, w);
      final PolynomialFit xFit = xSolver.solve(n);
      if (xFit != null) {
        final LeastSquaresSolver ySolver = new LeastSquaresSolver(time, y, w);
        final PolynomialFit yFit = ySolver.solve(n);
        if (yFit != null) {
          return new VelocityEstimate( // convert from pixels/ms to pixels/s
            pixelsPerSecond: new Offset(xFit.coefficients[1] * 1000, yFit.coefficients[1] * 1000),
            confidence: xFit.confidence * yFit.confidence,
            duration: newestMovement.eventTime - oldestMovement.eventTime,
            offset: newestMovement.position - oldestMovement.position,
          );
        }
      }
    }

    // We're unable to make a velocity estimate but we did have at least one
    // valid pointer position.
    return new VelocityEstimate(
      pixelsPerSecond: Offset.zero,
      confidence: 1.0,
      duration: newestMovement.eventTime - oldestMovement.eventTime,
      offset: newestMovement.position - oldestMovement.position,
    );
  }

  @override
  void clear() {
    _index = -1;
  }

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
  /// Creates a velocity tracker.
  VelocityTracker() : _strategy = _createStrategy();

  // VelocityTracker is designed to easily be adapted to using different
  // algorithms in the future, potentially picking algorithms on the fly based
  // on hardware or other environment factors.
  //
  // For now, though, we just use the _LeastSquaresVelocityTrackerStrategy
  // defined above.

  // TODO(ianh): Simplify this. We don't see to need multiple stategies.

  static _VelocityTrackerStrategy _createStrategy() {
    return new _LeastSquaresVelocityTrackerStrategy(2);
  }

  _VelocityTrackerStrategy _strategy;

  /// Add a given position corresponding to a specific time.
  void addPosition(Duration timeStamp, Point position) {
    _strategy.addMovement(timeStamp, position);
  }

  VelocityEstimate getVelocityEstimate() => _strategy.getEstimate();

  /// Computes the velocity of the pointer at the time of the last
  /// provided data point.
  ///
  /// This can be expensive. Only call this when you need the velocity.
  ///
  /// getVelocity() will return null if no estimate is available or if
  /// the velocity is zero.
  Velocity getVelocity() {
    final VelocityEstimate estimate = getVelocityEstimate();
    if (estimate == null || estimate.pixelsPerSecond == Offset.zero)
      return null;
    return new Velocity(pixelsPerSecond: estimate.pixelsPerSecond);
  }
}
