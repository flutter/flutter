// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import 'lsq_solver.dart';

export 'dart:ui' show Offset;

/// A velocity in two dimensions.
class Velocity {
  /// Creates a velocity.
  ///
  /// The [pixelsPerSecond] argument must not be null.
  const Velocity({
    @required this.pixelsPerSecond,
  }) : assert(pixelsPerSecond != null);

  /// A velocity that isn't moving at all.
  static const Velocity zero = Velocity(pixelsPerSecond: Offset.zero);

  /// The number of pixels per second of velocity in the x and y directions.
  final Offset pixelsPerSecond;

  /// Return the negation of a velocity.
  Velocity operator -() => Velocity(pixelsPerSecond: -pixelsPerSecond);

  /// Return the difference of two velocities.
  Velocity operator -(Velocity other) {
    return Velocity(
        pixelsPerSecond: pixelsPerSecond - other.pixelsPerSecond);
  }

  /// Return the sum of two velocities.
  Velocity operator +(Velocity other) {
    return Velocity(
        pixelsPerSecond: pixelsPerSecond + other.pixelsPerSecond);
  }

  /// Return a velocity whose magnitude has been clamped to [minValue]
  /// and [maxValue].
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
      return Velocity(pixelsPerSecond: (pixelsPerSecond / pixelsPerSecond.distance) * maxValue);
    if (valueSquared < minValue * minValue)
      return Velocity(pixelsPerSecond: (pixelsPerSecond / pixelsPerSecond.distance) * minValue);
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
///
/// VelocityEstimates are computed by [VelocityTracker.getVelocityEstimate]. An
/// estimate's [confidence] measures how well the velocity tracker's position
/// data fit a straight line, [duration] is the time that elapsed between the
/// first and last position sample used to compute the velocity, and [offset]
/// is similarly the difference between the first and last positions.
///
/// See also:
///
///  * VelocityTracker, which computes [VelocityEstimate]s.
///  * Velocity, which encapsulates (just) a velocity vector and provides some
///    useful velocity operations.
class VelocityEstimate {
  /// Creates a dimensional velocity estimate.
  ///
  /// [pixelsPerSecond], [confidence], [duration], and [offset] must not be null.
  const VelocityEstimate({
    @required this.pixelsPerSecond,
    @required this.confidence,
    @required this.duration,
    @required this.offset,
  }) : assert(pixelsPerSecond != null),
       assert(confidence != null),
       assert(duration != null),
       assert(offset != null);

  /// The number of pixels per second of velocity in the x and y directions.
  final Offset pixelsPerSecond;

  /// A value between 0.0 and 1.0 that indicates how well [VelocityTracker]
  /// was able to fit a straight line to its position data.
  ///
  /// The value of this property is 1.0 for a perfect fit, 0.0 for a poor fit.
  final double confidence;

  /// The time that elapsed between the first and last position sample used
  /// to compute [pixelsPerSecond].
  final Duration duration;

  /// The difference between the first and last position sample used
  /// to compute [pixelsPerSecond].
  final Offset offset;

  @override
  String toString() => 'VelocityEstimate(${pixelsPerSecond.dx.toStringAsFixed(1)}, ${pixelsPerSecond.dy.toStringAsFixed(1)}; offset: $offset, duration: $duration, confidence: ${confidence.toStringAsFixed(1)})';
}

class _PointAtTime {
  const _PointAtTime(this.point, this.time)
      : assert(point != null),
        assert(time != null);

  final Duration time;
  final Offset point;

  @override
  String toString() => '_PointAtTime($point at $time)';
}

/// Computes a pointer's velocity based on data from [PointerMoveEvent]s.
///
/// The input data is provided by calling [addPosition]. Adding data is cheap.
///
/// To obtain a velocity, call [getVelocity] or [getVelocityEstimate]. This will
/// compute the velocity based on the data added so far. Only call these when
/// you need to use the velocity, as they are comparatively expensive.
///
/// The quality of the velocity estimation will be better if more data points
/// have been received.
class VelocityTracker {
  static const int _assumePointerMoveStoppedMilliseconds = 40;
  static const int _historySize = 20;
  static const int _horizonMilliseconds = 100;
  static const int _minSampleSize = 3;

  // Circular buffer; current sample at _index.
  final List<_PointAtTime> _samples = List<_PointAtTime>(_historySize);
  int _index = 0;

  /// Adds a position as the given time to the tracker.
  void addPosition(Duration time, Offset position) {
    _index += 1;
    if (_index == _historySize)
      _index = 0;
    _samples[_index] = _PointAtTime(position, time);
  }

  /// Returns an estimate of the velocity of the object being tracked by the
  /// tracker given the current information available to the tracker.
  ///
  /// Information is added using [addPosition].
  ///
  /// Returns null if there is no data on which to base an estimate.
  VelocityEstimate getVelocityEstimate() {
    final List<double> x = <double>[];
    final List<double> y = <double>[];
    final List<double> w = <double>[];
    final List<double> time = <double>[];
    int sampleCount = 0;
    int index = _index;

    final _PointAtTime newestSample = _samples[index];
    if (newestSample == null)
      return null;

    _PointAtTime previousSample = newestSample;
    _PointAtTime oldestSample = newestSample;

    // Starting with the most recent PointAtTime sample, iterate backwards while
    // the samples represent continuous motion.
    do {
      final _PointAtTime sample = _samples[index];
      if (sample == null)
        break;

      final double age = (newestSample.time - sample.time).inMilliseconds.toDouble();
      final double delta = (sample.time - previousSample.time).inMilliseconds.abs().toDouble();
      previousSample = sample;
      if (age > _horizonMilliseconds || delta > _assumePointerMoveStoppedMilliseconds)
        break;

      oldestSample = sample;
      final Offset position = sample.point;
      x.add(position.dx);
      y.add(position.dy);
      w.add(1.0);
      time.add(-age);
      index = (index == 0 ? _historySize : index) - 1;

      sampleCount += 1;
    } while (sampleCount < _historySize);

    if (sampleCount >= _minSampleSize) {
      final LeastSquaresSolver xSolver = LeastSquaresSolver(time, x, w);
      final PolynomialFit xFit = xSolver.solve(2);
      if (xFit != null) {
        final LeastSquaresSolver ySolver = LeastSquaresSolver(time, y, w);
        final PolynomialFit yFit = ySolver.solve(2);
        if (yFit != null) {
          return VelocityEstimate( // convert from pixels/ms to pixels/s
            pixelsPerSecond: Offset(xFit.coefficients[1] * 1000, yFit.coefficients[1] * 1000),
            confidence: xFit.confidence * yFit.confidence,
            duration: newestSample.time - oldestSample.time,
            offset: newestSample.point - oldestSample.point,
          );
        }
      }
    }

    // We're unable to make a velocity estimate but we did have at least one
    // valid pointer position.
    return VelocityEstimate(
      pixelsPerSecond: Offset.zero,
      confidence: 1.0,
      duration: newestSample.time - oldestSample.time,
      offset: newestSample.point - oldestSample.point,
    );
  }

  /// Computes the velocity of the pointer at the time of the last
  /// provided data point.
  ///
  /// This can be expensive. Only call this when you need the velocity.
  ///
  /// Returns [Velocity.zero] if there is no data from which to compute an
  /// estimate or if the estimated velocity is zero.
  Velocity getVelocity() {
    final VelocityEstimate estimate = getVelocityEstimate();
    if (estimate == null || estimate.pixelsPerSecond == Offset.zero)
      return Velocity.zero;
    return Velocity(pixelsPerSecond: estimate.pixelsPerSecond);
  }
}
