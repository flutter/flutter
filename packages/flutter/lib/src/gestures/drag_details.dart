// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import 'velocity_tracker.dart';

/// Details object for callbacks that use [GestureDragDownCallback].
///
/// See also:
///
///  * [DragGestureRecognizer.onDown], which uses [GestureDragDownCallback].
///  * [DragStartDetails], the details for [GestureDragStartCallback].
///  * [DragUpdateDetails], the details for [GestureDragUpdateCallback].
///  * [DragEndDetails], the details for [GestureDragEndCallback].
class DragDownDetails {
  /// Creates details for a [GestureDragDownCallback].
  ///
  /// The [globalPosition] argument must not be null.
  DragDownDetails({
    this.globalPosition = Offset.zero,
    Offset? localPosition,
  }) : assert(globalPosition != null),
       localPosition = localPosition ?? globalPosition;

  /// The global position at which the pointer contacted the screen.
  ///
  /// Defaults to the origin if not specified in the constructor.
  ///
  /// See also:
  ///
  ///  * [localPosition], which is the [globalPosition] transformed to the
  ///    coordinate space of the event receiver.
  final Offset globalPosition;

  /// The local position in the coordinate system of the event receiver at
  /// which the pointer contacted the screen.
  ///
  /// Defaults to [globalPosition] if not specified in the constructor.
  final Offset localPosition;

  @override
  String toString() => '${objectRuntimeType(this, 'DragDownDetails')}($globalPosition)';
}

/// Signature for when a pointer has contacted the screen and might begin to
/// move.
///
/// The `details` object provides the position of the touch.
///
/// See [DragGestureRecognizer.onDown].
typedef GestureDragDownCallback = void Function(DragDownDetails details);

/// Details object for callbacks that use [GestureDragStartCallback].
///
/// See also:
///
///  * [DragGestureRecognizer.onStart], which uses [GestureDragStartCallback].
///  * [DragDownDetails], the details for [GestureDragDownCallback].
///  * [DragUpdateDetails], the details for [GestureDragUpdateCallback].
///  * [DragEndDetails], the details for [GestureDragEndCallback].
class DragStartDetails {
  /// Creates details for a [GestureDragStartCallback].
  ///
  /// The [globalPosition] argument must not be null.
  DragStartDetails({
    this.sourceTimeStamp,
    this.globalPosition = Offset.zero,
    Offset? localPosition,
  }) : assert(globalPosition != null),
       localPosition = localPosition ?? globalPosition;

  /// Recorded timestamp of the source pointer event that triggered the drag
  /// event.
  ///
  /// Could be null if triggered from proxied events such as accessibility.
  final Duration? sourceTimeStamp;

  /// The global position at which the pointer contacted the screen.
  ///
  /// Defaults to the origin if not specified in the constructor.
  ///
  /// See also:
  ///
  ///  * [localPosition], which is the [globalPosition] transformed to the
  ///    coordinate space of the event receiver.
  final Offset globalPosition;

  /// The local position in the coordinate system of the event receiver at
  /// which the pointer contacted the screen.
  ///
  /// Defaults to [globalPosition] if not specified in the constructor.
  final Offset localPosition;

  // TODO(ianh): Expose the current position, so that you can have a no-jump
  // drag even when disambiguating (though of course it would lag the finger
  // instead).

  @override
  String toString() => '${objectRuntimeType(this, 'DragStartDetails')}($globalPosition)';
}

/// Signature for when a pointer has contacted the screen and has begun to move.
///
/// The `details` object provides the position of the touch when it first
/// touched the surface.
///
/// See [DragGestureRecognizer.onStart].
typedef GestureDragStartCallback = void Function(DragStartDetails details);

/// Details object for callbacks that use [GestureDragUpdateCallback].
///
/// See also:
///
///  * [DragGestureRecognizer.onUpdate], which uses [GestureDragUpdateCallback].
///  * [DragDownDetails], the details for [GestureDragDownCallback].
///  * [DragStartDetails], the details for [GestureDragStartCallback].
///  * [DragEndDetails], the details for [GestureDragEndCallback].
class DragUpdateDetails {
  /// Creates details for a [DragUpdateDetails].
  ///
  /// The [delta] argument must not be null.
  ///
  /// If [primaryDelta] is non-null, then its value must match one of the
  /// coordinates of [delta] and the other coordinate must be zero.
  ///
  /// The [globalPosition] argument must be provided and must not be null.
  DragUpdateDetails({
    this.sourceTimeStamp,
    this.delta = Offset.zero,
    this.primaryDelta,
    required this.globalPosition,
    Offset? localPosition,
  }) : assert(delta != null),
       assert(primaryDelta == null
           || (primaryDelta == delta.dx && delta.dy == 0.0)
           || (primaryDelta == delta.dy && delta.dx == 0.0)),
       localPosition = localPosition ?? globalPosition;

  /// Recorded timestamp of the source pointer event that triggered the drag
  /// event.
  ///
  /// Could be null if triggered from proxied events such as accessibility.
  final Duration? sourceTimeStamp;

  /// The amount the pointer has moved in the coordinate space of the event
  /// receiver since the previous update.
  ///
  /// If the [GestureDragUpdateCallback] is for a one-dimensional drag (e.g.,
  /// a horizontal or vertical drag), then this offset contains only the delta
  /// in that direction (i.e., the coordinate in the other direction is zero).
  ///
  /// Defaults to zero if not specified in the constructor.
  final Offset delta;

  /// The amount the pointer has moved along the primary axis in the coordinate
  /// space of the event receiver since the previous
  /// update.
  ///
  /// If the [GestureDragUpdateCallback] is for a one-dimensional drag (e.g.,
  /// a horizontal or vertical drag), then this value contains the component of
  /// [delta] along the primary axis (e.g., horizontal or vertical,
  /// respectively). Otherwise, if the [GestureDragUpdateCallback] is for a
  /// two-dimensional drag (e.g., a pan), then this value is null.
  ///
  /// Defaults to null if not specified in the constructor.
  final double? primaryDelta;

  /// The pointer's global position when it triggered this update.
  ///
  /// See also:
  ///
  ///  * [localPosition], which is the [globalPosition] transformed to the
  ///    coordinate space of the event receiver.
  final Offset globalPosition;

  /// The local position in the coordinate system of the event receiver at
  /// which the pointer contacted the screen.
  ///
  /// Defaults to [globalPosition] if not specified in the constructor.
  final Offset localPosition;

  @override
  String toString() => '${objectRuntimeType(this, 'DragUpdateDetails')}($delta)';
}

/// Signature for when a pointer that is in contact with the screen and moving
/// has moved again.
///
/// The `details` object provides the position of the touch and the distance it
/// has traveled since the last update.
///
/// See [DragGestureRecognizer.onUpdate].
typedef GestureDragUpdateCallback = void Function(DragUpdateDetails details);

/// Details object for callbacks that use [GestureDragEndCallback].
///
/// See also:
///
///  * [DragGestureRecognizer.onEnd], which uses [GestureDragEndCallback].
///  * [DragDownDetails], the details for [GestureDragDownCallback].
///  * [DragStartDetails], the details for [GestureDragStartCallback].
///  * [DragUpdateDetails], the details for [GestureDragUpdateCallback].
class DragEndDetails {
  /// Creates details for a [GestureDragEndCallback].
  ///
  /// The [velocity] argument must not be null.
  DragEndDetails({
    this.velocity = Velocity.zero,
    this.primaryVelocity,
  }) : assert(velocity != null),
       assert(primaryVelocity == null
           || primaryVelocity == velocity.pixelsPerSecond.dx
           || primaryVelocity == velocity.pixelsPerSecond.dy);

  /// The velocity the pointer was moving when it stopped contacting the screen.
  ///
  /// Defaults to zero if not specified in the constructor.
  final Velocity velocity;

  /// The velocity the pointer was moving along the primary axis when it stopped
  /// contacting the screen, in logical pixels per second.
  ///
  /// If the [GestureDragEndCallback] is for a one-dimensional drag (e.g., a
  /// horizontal or vertical drag), then this value contains the component of
  /// [velocity] along the primary axis (e.g., horizontal or vertical,
  /// respectively). Otherwise, if the [GestureDragEndCallback] is for a
  /// two-dimensional drag (e.g., a pan), then this value is null.
  ///
  /// Defaults to null if not specified in the constructor.
  final double? primaryVelocity;

  @override
  String toString() => '${objectRuntimeType(this, 'DragEndDetails')}($velocity)';
}
