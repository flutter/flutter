// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import 'velocity_tracker.dart';

/// Details object for callbacks that use [ScrollStartCallback].
///
/// See also:
///
///  * [PointerScrollGestureRecognizer.onStart], which uses
///    [PointerScrollStartCallback].
///  * [PointerScrollUpdateDetails], the details for
///    [PointerScrollUpdateCallback].
///  * [PointerScrollEndDetails], the details for [PointerScrollEndCallback].
class PointerScrollStartDetails {
  /// Creates details for a [PointerScrollStartCallback].
  ///
  /// The [globalPosition] argument must not be null.
  PointerScrollStartDetails(
      {this.sourceTimeStamp, this.globalPosition = Offset.zero})
      : assert(globalPosition != null);

  /// Recorded timestamp of the source pointer event that triggered the scroll
  /// event.
  ///
  /// Could be null if triggered from proxied events such as accessibility.
  final Duration sourceTimeStamp;

  /// The global position of the pointer at the time the scroll started.
  ///
  /// Defaults to the origin if not specified in the constructor.
  final Offset globalPosition;

  @override
  String toString() => '$runtimeType($globalPosition)';
}

/// Signature for when scroll gesture has started.
///
/// The `details` object provides the position of the pointer when the scroll
/// began.
///
/// See [PointerScrollGestureRecognizer.onStart].
typedef void PointerScrollStartCallback(PointerScrollStartDetails details);

/// Details object for callbacks that use [PointerScrollUpdateCallback].
///
/// See also:
///
///  * [PointerScrollGestureRecognizer.onUpdate], which uses
///    [PointerScrollUpdateCallback].
///  * [PointerScrollStartDetails], the details for
///    [PointerScrollStartCallback].
///  * [PointerScrollEndDetails], the details for [PointerScrollEndCallback].
class PointerScrollUpdateDetails {
  /// Creates details for a [PointerScrollUpdateDetails].
  ///
  /// The [delta] argument must not be null.
  ///
  /// If [primaryDelta] is non-null, then its value must match one of the
  /// coordinates of [delta] and the other coordinate must be zero.
  ///
  /// The [globalPosition] argument must be provided and must not be null.
  PointerScrollUpdateDetails(
      {this.sourceTimeStamp,
      this.delta = Offset.zero,
      this.primaryDelta,
      @required this.globalPosition})
      : assert(delta != null),
        assert(primaryDelta == null ||
            (primaryDelta == delta.dx && delta.dy == 0.0) ||
            (primaryDelta == delta.dy && delta.dx == 0.0));

  /// Recorded timestamp of the source pointer event that triggered the scroll
  /// event.
  ///
  /// Could be null if triggered from proxied events such as accessibility.
  final Duration sourceTimeStamp;

  /// The amount scrolled since the previous update.
  ///
  /// If the [PointerScrollUpdateCallback] is for a one-dimensional scroll
  /// (e.g., a horizontal or vertical scroll), then this offset contains only
  /// the delta in that direction (i.e., the coordinate in the other direction
  /// is zero).
  ///
  /// Defaults to zero if not specified in the constructor.
  final Offset delta;

  /// The amount the pointer has moved along the primary axis since the previous
  /// update.
  ///
  /// If the [PointerScrollUpdateCallback] is for a one-dimensional scroll
  /// (e.g., a horizontal or vertical scroll), then this value contains the
  /// component of [delta] along the primary axis (e.g., horizontal or vertical,
  /// respectively). Otherwise, if the [PointerScrollUpdateCallback] is for a
  /// two-dimensional scroll (e.g., a pan), then this value is null.
  ///
  /// Defaults to null if not specified in the constructor.
  final double primaryDelta;

  /// The pointer's global position when it triggered this update.
  final Offset globalPosition;

  @override
  String toString() => '$runtimeType($delta)';
}

/// Signature for when a pointer that is currently in a scroll gesture has
/// scrolled again.
///
/// The `details` object provides the position of the pointer and the amount
/// scrolled since the last update.
///
/// See [PointerScrollGestureRecognizer.onUpdate].
typedef void PointerScrollUpdateCallback(PointerScrollUpdateDetails details);

/// Details object for callbacks that use [PointerScrollEndCallback].
///
/// See also:
///
///  * [PointerScrollGestureRecognizer.onEnd], which uses
///    [PointerScrollEndCallback].
///  * [PointerScrollStartDetails], the details for
///    [PointerScrollStartCallback].
///  * [PointerScrollUpdateDetails], the details for
///    [PointerScrollUpdateCallback].
class PointerScrollEndDetails {
  /// Creates details for a [PointerScrollEndCallback].
  ///
  /// The [velocity] argument must not be null.
  PointerScrollEndDetails({
    this.velocity = Velocity.zero,
    this.primaryVelocity,
  })  : assert(velocity != null),
        assert(primaryVelocity == null ||
            primaryVelocity == velocity.pixelsPerSecond.dx ||
            primaryVelocity == velocity.pixelsPerSecond.dy);

  /// The velocity the pointer was moving when it stopped contacting the screen.
  ///
  /// Defaults to zero if not specified in the constructor.
  final Velocity velocity;

  /// The velocity the pointer was moving along the primary axis the scroll
  /// gesture ended, in logical pixels per second.
  ///
  /// If the [PointerScrollEndCallback] is for a one-dimensional scroll (e.g., a
  /// horizontal or vertical scroll), then this value contains the component of
  /// [velocity] along the primary axis (e.g., horizontal or vertical,
  /// respectively). Otherwise, if the [PointerScrollEndCallback] is for a
  /// two-dimensional scroll (e.g., a pan), then this value is null.
  ///
  /// Defaults to null if not specified in the constructor.
  final double primaryVelocity;

  @override
  String toString() => '$runtimeType($velocity)';
}
