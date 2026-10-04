// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'monodrag.dart';
library;

import 'package:flutter/foundation.dart';

import 'gesture_details.dart';
import 'velocity_tracker.dart';

export 'dart:ui' show Offset, PointerDeviceKind;

export 'velocity_tracker.dart' show Velocity;

/// Details object for callbacks that use [GestureDragDownCallback].
///
/// See also:
///
///  * [DragGestureRecognizer.onDown], which uses [GestureDragDownCallback].
///  * [DragStartDetails], the details for [GestureDragStartCallback].
///  * [DragUpdateDetails], the details for [GestureDragUpdateCallback].
///  * [DragEndDetails], the details for [GestureDragEndCallback].
class DragDownDetails with Diagnosticable implements PositionedGestureDetails {
  /// Creates details for a [GestureDragDownCallback].
  DragDownDetails({this.globalPosition = Offset.zero, Offset? localPosition})
    : localPosition = localPosition ?? globalPosition;

  /// {@macro flutter.gestures.gesturedetails.PositionedGestureDetails.globalPosition}
  @override
  final Offset globalPosition;

  /// {@macro flutter.gestures.gesturedetails.PositionedGestureDetails.localPosition}
  @override
  final Offset localPosition;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('globalPosition', globalPosition));
    properties.add(DiagnosticsProperty<Offset>('localPosition', localPosition));
  }
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
class DragStartDetails with Diagnosticable implements PositionedGestureDetails {
  /// Creates details for a [GestureDragStartCallback].
  DragStartDetails({
    this.globalPosition = Offset.zero,
    Offset? localPosition,
    this.sourceTimeStamp,
    this.kind,
  }) : localPosition = localPosition ?? globalPosition;

  /// {@macro flutter.gestures.gesturedetails.PositionedGestureDetails.globalPosition}
  @override
  final Offset globalPosition;

  /// {@macro flutter.gestures.gesturedetails.PositionedGestureDetails.localPosition}
  @override
  final Offset localPosition;

  /// Recorded timestamp of the source pointer event that triggered the drag
  /// event.
  ///
  /// Could be null if triggered from proxied events such as accessibility.
  final Duration? sourceTimeStamp;

  /// The kind of the device that initiated the event.
  final PointerDeviceKind? kind;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('globalPosition', globalPosition));
    properties.add(DiagnosticsProperty<Offset>('localPosition', localPosition));
    properties.add(DiagnosticsProperty<Duration?>('sourceTimeStamp', sourceTimeStamp));
    properties.add(EnumProperty<PointerDeviceKind?>('kind', kind));
  }
}

/// {@template flutter.gestures.dragdetails.GestureDragStartCallback}
/// Signature for when a pointer has contacted the screen and has begun to move.
///
/// The `details` object provides the position of the touch when it first
/// touched the surface.
/// {@endtemplate}
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
class DragUpdateDetails with Diagnosticable implements PositionedGestureDetails {
  /// Creates details for a [GestureDragUpdateCallback].
  ///
  /// If [primaryDelta] is non-null, then its value must match one of the
  /// coordinates of [delta] and the other coordinate must be zero.
  DragUpdateDetails({
    required this.globalPosition,
    Offset? localPosition,
    this.sourceTimeStamp,
    this.delta = Offset.zero,
    this.primaryDelta,
    this.kind,
  }) : assert(
         primaryDelta == null ||
             (primaryDelta == delta.dx && delta.dy == 0.0) ||
             (primaryDelta == delta.dy && delta.dx == 0.0),
       ),
       localPosition = localPosition ?? globalPosition;

  /// {@macro flutter.gestures.gesturedetails.PositionedGestureDetails.globalPosition}
  @override
  final Offset globalPosition;

  /// {@macro flutter.gestures.gesturedetails.PositionedGestureDetails.localPosition}
  @override
  final Offset localPosition;

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

  /// The kind of the device that initiated the event.
  final PointerDeviceKind? kind;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('globalPosition', globalPosition));
    properties.add(DiagnosticsProperty<Offset>('localPosition', localPosition));
    properties.add(DiagnosticsProperty<Duration?>('sourceTimeStamp', sourceTimeStamp));
    properties.add(DiagnosticsProperty<Offset>('delta', delta));
    properties.add(DoubleProperty('primaryDelta', primaryDelta));
  }
}

/// {@template flutter.gestures.dragdetails.GestureDragUpdateCallback}
/// Signature for when a pointer that is in contact with the screen and moving
/// has moved again.
///
/// The `details` object provides the position of the touch and the distance it
/// has traveled since the last update.
/// {@endtemplate}
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
class DragEndDetails with Diagnosticable implements PositionedGestureDetails {
  /// Creates details for a [GestureDragEndCallback].
  ///
  /// If [primaryVelocity] is non-null, its value must match one of the
  /// coordinates of `velocity.pixelsPerSecond` and the other coordinate
  /// must be zero.
  DragEndDetails({
    this.globalPosition = Offset.zero,
    Offset? localPosition,
    this.velocity = Velocity.zero,
    this.primaryVelocity,
  }) : assert(
         primaryVelocity == null ||
             (primaryVelocity == velocity.pixelsPerSecond.dx && velocity.pixelsPerSecond.dy == 0) ||
             (primaryVelocity == velocity.pixelsPerSecond.dy && velocity.pixelsPerSecond.dx == 0),
       ),
       localPosition = localPosition ?? globalPosition;

  /// {@macro flutter.gestures.gesturedetails.PositionedGestureDetails.globalPosition}
  @override
  final Offset globalPosition;

  /// {@macro flutter.gestures.gesturedetails.PositionedGestureDetails.localPosition}
  @override
  final Offset localPosition;

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
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('globalPosition', globalPosition));
    properties.add(DiagnosticsProperty<Offset>('localPosition', localPosition));
    properties.add(DiagnosticsProperty<Velocity>('velocity', velocity));
    properties.add(DoubleProperty('primaryVelocity', primaryVelocity));
  }
}
