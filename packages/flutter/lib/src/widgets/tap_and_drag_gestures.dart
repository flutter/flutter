// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart' show HardwareKeyboard, LogicalKeyboardKey;

double _getGlobalDistance(PointerEvent event, OffsetPair? originPosition) {
  assert(originPosition != null);
  final Offset offset = event.position - originPosition!.global;
  return offset.distance;
}

// The possible states of a [TapAndDragGestureRecognizer].
//
// The recognizer advances from [ready] to [possible] when it starts tracking
// a pointer in [TapAndDragGestureRecognizer.addAllowedPointer]. Where it advances
// from there depends on the sequence of pointer events that is tracked by the
// recognizer, following the initial [PointerDownEvent]:
//
// * If a [PointerUpEvent] has not been tracked, the recognizer stays in the [possible]
//   state as long as it continues to track a pointer.
// * If a [PointerMoveEvent] is tracked that has moved a sufficient global distance
//   from the initial [PointerDownEvent] and it came before a [PointerUpEvent], then
//   when this recognizer wins the arena, it will move from the [possible] state to [accepted].
// * If a [PointerUpEvent] is tracked before the pointer has moved a sufficient global
//   distance to be considered a drag, then this recognizer moves from the [possible]
//   state to [ready].
// * If a [PointerCancelEvent] is tracked then this recognizer moves from its current
//   state to [ready].
//
// Once the recognizer has stopped tracking any remaining pointers, the recognizer
// returns to the [ready] state.
enum _DragState {
  // The recognizer is ready to start recognizing a drag.
  ready,

  // The sequence of pointer events seen thus far is consistent with a drag but
  // it has not been accepted definitively.
  possible,

  // The sequence of pointer events has been accepted definitively as a drag.
  accepted,
}

/// {@macro flutter.gestures.tap.GestureTapDownCallback}
///
/// The consecutive tap count at the time the pointer contacted the
/// screen is given by [TapDragDownDetails.consecutiveTapCount].
///
/// Used by [TapAndDragGestureRecognizer.onTapDown].
typedef GestureTapDragDownCallback  = void Function(TapDragDownDetails details);

/// Details for [GestureTapDragDownCallback], such as the number of
/// consecutive taps.
///
/// See also:
///
///  * [TapAndDragGestureRecognizer], which passes this information to its
///    [TapAndDragGestureRecognizer.onTapDown] callback.
///  * [TapDragUpDetails], the details for [GestureTapDragUpCallback].
///  * [TapDragStartDetails], the details for [GestureTapDragStartCallback].
///  * [TapDragUpdateDetails], the details for [GestureTapDragUpdateCallback].
///  * [TapDragEndDetails], the details for [GestureTapDragEndCallback].
class TapDragDownDetails with Diagnosticable {
  /// Creates details for a [GestureTapDragDownCallback].
  ///
  /// The [globalPosition], [localPosition], [consecutiveTapCount], and
  /// [keysPressedOnDown] arguments must be provided and must not be null.
  TapDragDownDetails({
    required this.globalPosition,
    required this.localPosition,
    this.kind,
    required this.consecutiveTapCount,
    required this.keysPressedOnDown,
  });

  /// The global position at which the pointer contacted the screen.
  final Offset globalPosition;

  /// The local position at which the pointer contacted the screen.
  final Offset localPosition;

  /// The kind of the device that initiated the event.
  final PointerDeviceKind? kind;

  /// If this tap is in a series of taps, then this value represents
  /// the number in the series this tap is.
  final int consecutiveTapCount;

  /// The keys that were pressed when the most recent [PointerDownEvent] occurred.
  final Set<LogicalKeyboardKey> keysPressedOnDown;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('globalPosition', globalPosition));
    properties.add(DiagnosticsProperty<Offset>('localPosition', localPosition));
    properties.add(DiagnosticsProperty<PointerDeviceKind?>('kind', kind));
    properties.add(DiagnosticsProperty<int>('consecutiveTapCount', consecutiveTapCount));
    properties.add(DiagnosticsProperty<Set<LogicalKeyboardKey>>('keysPressedOnDown', keysPressedOnDown));
  }
}

/// {@macro flutter.gestures.tap.GestureTapUpCallback}
///
/// The consecutive tap count at the time the pointer contacted the
/// screen is given by [TapDragUpDetails.consecutiveTapCount].
///
/// Used by [TapAndDragGestureRecognizer.onTapUp].
typedef GestureTapDragUpCallback  = void Function(TapDragUpDetails details);

/// Details for [GestureTapDragUpCallback], such as the number of
/// consecutive taps.
///
/// See also:
///
///  * [TapAndDragGestureRecognizer], which passes this information to its
///    [TapAndDragGestureRecognizer.onTapUp] callback.
///  * [TapDragDownDetails], the details for [GestureTapDragDownCallback].
///  * [TapDragStartDetails], the details for [GestureTapDragStartCallback].
///  * [TapDragUpdateDetails], the details for [GestureTapDragUpdateCallback].
///  * [TapDragEndDetails], the details for [GestureTapDragEndCallback].
class TapDragUpDetails with Diagnosticable {
  /// Creates details for a [GestureTapDragUpCallback].
  ///
  /// The [kind], [globalPosition], [localPosition], [consecutiveTapCount], and
  /// [keysPressedOnDown] arguments must be provided and must not be null.
  TapDragUpDetails({
    required this.kind,
    required this.globalPosition,
    required this.localPosition,
    required this.consecutiveTapCount,
    required this.keysPressedOnDown,
  });

  /// The global position at which the pointer contacted the screen.
  final Offset globalPosition;

  /// The local position at which the pointer contacted the screen.
  final Offset localPosition;

  /// The kind of the device that initiated the event.
  final PointerDeviceKind kind;

  /// If this tap is in a series of taps, then this value represents
  /// the number in the series this tap is.
  final int consecutiveTapCount;

  /// The keys that were pressed when the most recent [PointerDownEvent] occurred.
  final Set<LogicalKeyboardKey> keysPressedOnDown;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Offset>('globalPosition', globalPosition));
    properties.add(DiagnosticsProperty<Offset>('localPosition', localPosition));
    properties.add(DiagnosticsProperty<PointerDeviceKind?>('kind', kind));
    properties.add(DiagnosticsProperty<int>('consecutiveTapCount', consecutiveTapCount));
    properties.add(DiagnosticsProperty<Set<LogicalKeyboardKey>>('keysPressedOnDown', keysPressedOnDown));
  }
}

/// {@macro flutter.gestures.dragdetails.GestureDragStartCallback}
///
/// The consecutive tap count at the time the pointer contacted the
/// screen is given by [TapDragStartDetails.consecutiveTapCount].
///
/// Used by [TapAndDragGestureRecognizer.onDragStart].
typedef GestureTapDragStartCallback = void Function(TapDragStartDetails details);

/// Details for [GestureTapDragStartCallback], such as the number of
/// consecutive taps.
///
/// See also:
///
///  * [TapAndDragGestureRecognizer], which passes this information to its
///    [TapAndDragGestureRecognizer.onDragStart] callback.
///  * [TapDragDownDetails], the details for [GestureTapDragDownCallback].
///  * [TapDragUpDetails], the details for [GestureTapDragUpCallback].
///  * [TapDragUpdateDetails], the details for [GestureTapDragUpdateCallback].
///  * [TapDragEndDetails], the details for [GestureTapDragEndCallback].
class TapDragStartDetails with Diagnosticable {
  /// Creates details for a [GestureTapDragStartCallback].
  ///
  /// The [globalPosition], [localPosition], [consecutiveTapCount], and
  /// [keysPressedOnDown] arguments must be provided and must not be null.
  TapDragStartDetails({
    this.sourceTimeStamp,
    required this.globalPosition,
    required this.localPosition,
    this.kind,
    required this.consecutiveTapCount,
    required this.keysPressedOnDown,
  });

  /// Recorded timestamp of the source pointer event that triggered the drag
  /// event.
  ///
  /// Could be null if triggered from proxied events such as accessibility.
  final Duration? sourceTimeStamp;

  /// The global position at which the pointer contacted the screen.
  ///
  /// See also:
  ///
  ///  * [localPosition], which is the [globalPosition] transformed to the
  ///    coordinate space of the event receiver.
  final Offset globalPosition;

  /// The local position in the coordinate system of the event receiver at
  /// which the pointer contacted the screen.
  final Offset localPosition;

  /// The kind of the device that initiated the event.
  final PointerDeviceKind? kind;

  /// If this tap is in a series of taps, then this value represents
  /// the number in the series this tap is.
  final int consecutiveTapCount;

  /// The keys that were pressed when the most recent [PointerDownEvent] occurred.
  final Set<LogicalKeyboardKey> keysPressedOnDown;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Duration?>('sourceTimeStamp', sourceTimeStamp));
    properties.add(DiagnosticsProperty<Offset>('globalPosition', globalPosition));
    properties.add(DiagnosticsProperty<Offset>('localPosition', localPosition));
    properties.add(DiagnosticsProperty<PointerDeviceKind?>('kind', kind));
    properties.add(DiagnosticsProperty<int>('consecutiveTapCount', consecutiveTapCount));
    properties.add(DiagnosticsProperty<Set<LogicalKeyboardKey>>('keysPressedOnDown', keysPressedOnDown));
  }
}

/// {@macro flutter.gestures.dragdetails.GestureDragUpdateCallback}
///
/// The consecutive tap count at the time the pointer contacted the
/// screen is given by [TapDragUpdateDetails.consecutiveTapCount].
///
/// Used by [TapAndDragGestureRecognizer.onDragUpdate].
typedef GestureTapDragUpdateCallback = void Function(TapDragUpdateDetails details);

/// Details for [GestureTapDragUpdateCallback], such as the number of
/// consecutive taps.
///
/// See also:
///
///  * [TapAndDragGestureRecognizer], which passes this information to its
///    [TapAndDragGestureRecognizer.onDragUpdate] callback.
///  * [TapDragDownDetails], the details for [GestureTapDragDownCallback].
///  * [TapDragUpDetails], the details for [GestureTapDragUpCallback].
///  * [TapDragStartDetails], the details for [GestureTapDragStartCallback].
///  * [TapDragEndDetails], the details for [GestureTapDragEndCallback].
class TapDragUpdateDetails with Diagnosticable {
  /// Creates details for a [GestureTapDragUpdateCallback].
  ///
  /// The [delta] argument must not be null.
  ///
  /// If [primaryDelta] is non-null, then its value must match one of the
  /// coordinates of [delta] and the other coordinate must be zero.
  ///
  /// The [globalPosition], [localPosition], [offsetFromOrigin], [localOffsetFromOrigin],
  /// [consecutiveTapCount], and [keysPressedOnDown] arguments must be provided and must
  /// not be null.
  TapDragUpdateDetails({
    this.sourceTimeStamp,
    this.delta = Offset.zero,
    this.primaryDelta,
    required this.globalPosition,
    this.kind,
    required this.localPosition,
    required this.offsetFromOrigin,
    required this.localOffsetFromOrigin,
    required this.consecutiveTapCount,
    required this.keysPressedOnDown,
  }) : assert(
         primaryDelta == null
           || (primaryDelta == delta.dx && delta.dy == 0.0)
           || (primaryDelta == delta.dy && delta.dx == 0.0),
       );

  /// Recorded timestamp of the source pointer event that triggered the drag
  /// event.
  ///
  /// Could be null if triggered from proxied events such as accessibility.
  final Duration? sourceTimeStamp;

  /// The amount the pointer has moved in the coordinate space of the event
  /// receiver since the previous update.
  ///
  /// If the [GestureTapDragUpdateCallback] is for a one-dimensional drag (e.g.,
  /// a horizontal or vertical drag), then this offset contains only the delta
  /// in that direction (i.e., the coordinate in the other direction is zero).
  ///
  /// Defaults to zero if not specified in the constructor.
  final Offset delta;

  /// The amount the pointer has moved along the primary axis in the coordinate
  /// space of the event receiver since the previous
  /// update.
  ///
  /// If the [GestureTapDragUpdateCallback] is for a one-dimensional drag (e.g.,
  /// a horizontal or vertical drag), then this value contains the component of
  /// [delta] along the primary axis (e.g., horizontal or vertical,
  /// respectively). Otherwise, if the [GestureTapDragUpdateCallback] is for a
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

  /// The kind of the device that initiated the event.
  final PointerDeviceKind? kind;

  /// A delta offset from the point where the drag initially contacted
  /// the screen to the point where the pointer is currently located in global
  /// coordinates (the present [globalPosition]) when this callback is triggered.
  ///
  /// When considering a [GestureRecognizer] that tracks the number of consecutive taps,
  /// this offset is associated with the most recent [PointerDownEvent] that occurred.
  final Offset offsetFromOrigin;

  /// A local delta offset from the point where the drag initially contacted
  /// the screen to the point where the pointer is currently located in local
  /// coordinates (the present [localPosition]) when this callback is triggered.
  ///
  /// When considering a [GestureRecognizer] that tracks the number of consecutive taps,
  /// this offset is associated with the most recent [PointerDownEvent] that occurred.
  final Offset localOffsetFromOrigin;

  /// If this tap is in a series of taps, then this value represents
  /// the number in the series this tap is.
  final int consecutiveTapCount;

  /// The keys that were pressed when the most recent [PointerDownEvent] occurred.
  final Set<LogicalKeyboardKey> keysPressedOnDown;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Duration?>('sourceTimeStamp', sourceTimeStamp));
    properties.add(DiagnosticsProperty<Offset>('delta', delta));
    properties.add(DiagnosticsProperty<double?>('primaryDelta', primaryDelta));
    properties.add(DiagnosticsProperty<Offset>('globalPosition', globalPosition));
    properties.add(DiagnosticsProperty<Offset>('localPosition', localPosition));
    properties.add(DiagnosticsProperty<PointerDeviceKind?>('kind', kind));
    properties.add(DiagnosticsProperty<Offset>('offsetFromOrigin', offsetFromOrigin));
    properties.add(DiagnosticsProperty<Offset>('localOffsetFromOrigin', localOffsetFromOrigin));
    properties.add(DiagnosticsProperty<int>('consecutiveTapCount', consecutiveTapCount));
    properties.add(DiagnosticsProperty<Set<LogicalKeyboardKey>>('keysPressedOnDown', keysPressedOnDown));
  }
}

/// {@macro flutter.gestures.monodrag.GestureDragEndCallback}
///
/// The consecutive tap count at the time the pointer contacted the
/// screen is given by [TapDragEndDetails.consecutiveTapCount].
///
/// Used by [TapAndDragGestureRecognizer.onDragEnd].
typedef GestureTapDragEndCallback = void Function(TapDragEndDetails endDetails);

/// Details for [GestureTapDragEndCallback], such as the number of
/// consecutive taps.
///
/// See also:
///
///  * [TapAndDragGestureRecognizer], which passes this information to its
///    [TapAndDragGestureRecognizer.onDragEnd] callback.
///  * [TapDragDownDetails], the details for [GestureTapDragDownCallback].
///  * [TapDragUpDetails], the details for [GestureTapDragUpCallback].
///  * [TapDragStartDetails], the details for [GestureTapDragStartCallback].
///  * [TapDragUpdateDetails], the details for [GestureTapDragUpdateCallback].
class TapDragEndDetails with Diagnosticable {
  /// Creates details for a [GestureTapDragEndCallback].
  ///
  /// The [velocity] argument must not be null.
  ///
  /// The [consecutiveTapCount], and [keysPressedOnDown] arguments must
  /// be provided and must not be null.
  TapDragEndDetails({
    this.velocity = Velocity.zero,
    this.primaryVelocity,
    required this.consecutiveTapCount,
    required this.keysPressedOnDown,
  }) : assert(
         primaryVelocity == null
           || primaryVelocity == velocity.pixelsPerSecond.dx
           || primaryVelocity == velocity.pixelsPerSecond.dy,
       );

  /// The velocity the pointer was moving when it stopped contacting the screen.
  ///
  /// Defaults to zero if not specified in the constructor.
  final Velocity velocity;

  /// The velocity the pointer was moving along the primary axis when it stopped
  /// contacting the screen, in logical pixels per second.
  ///
  /// If the [GestureTapDragEndCallback] is for a one-dimensional drag (e.g., a
  /// horizontal or vertical drag), then this value contains the component of
  /// [velocity] along the primary axis (e.g., horizontal or vertical,
  /// respectively). Otherwise, if the [GestureTapDragEndCallback] is for a
  /// two-dimensional drag (e.g., a pan), then this value is null.
  ///
  /// Defaults to null if not specified in the constructor.
  final double? primaryVelocity;

  /// If this tap is in a series of taps, then this value represents
  /// the number in the series this tap is.
  final int consecutiveTapCount;

  /// The keys that were pressed when the most recent [PointerDownEvent] occurred.
  final Set<LogicalKeyboardKey> keysPressedOnDown;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Velocity>('velocity', velocity));
    properties.add(DiagnosticsProperty<double?>('primaryVelocity', primaryVelocity));
    properties.add(DiagnosticsProperty<int>('consecutiveTapCount', consecutiveTapCount));
    properties.add(DiagnosticsProperty<Set<LogicalKeyboardKey>>('keysPressedOnDown', keysPressedOnDown));
  }
}

/// Signature for when the pointer that previously triggered a
/// [GestureTapDragDownCallback] did not complete.
///
/// Used by [TapAndDragGestureRecognizer.onCancel].
typedef GestureCancelCallback = void Function();

// A mixin for [OneSequenceGestureRecognizer] that tracks the number of taps
// that occur in a series of [PointerEvent]s and the most recent set of
// [LogicalKeyboardKey]s pressed on the most recent tap down.
//
// A tap is tracked as part of a series of taps if:
//
// 1. The elapsed time between when a [PointerUpEvent] and the subsequent
// [PointerDownEvent] does not exceed [kDoubleTapTimeout].
// 2. The delta between the position tapped in the global coordinate system
// and the position that was tapped previously must be less than or equal
// to [kDoubleTapSlop].
//
// This mixin's state, i.e. the series of taps being tracked is reset when
// a tap is tracked that does not meet any of the specifications stated above.
mixin _TapStatusTrackerMixin on OneSequenceGestureRecognizer {
  // Public state available to [OneSequenceGestureRecognizer].

  // The [PointerDownEvent] that was most recently tracked in [addAllowedPointer].
  //
  // This value will be null if a [PointerDownEvent] has not been tracked yet in
  // [addAllowedPointer] or the timer between two taps has elapsed.
  //
  // This value is only reset when the timer between a [PointerUpEvent] and the
  // [PointerDownEvent] times out or when a new [PointerDownEvent] is tracked in
  // [addAllowedPointer].
  PointerDownEvent? get currentDown => _down;

  // The [PointerUpEvent] that was most recently tracked in [handleEvent].
  //
  // This value will be null if a [PointerUpEvent] has not been tracked yet in
  // [handleEvent] or the timer between two taps has elapsed.
  //
  // This value is only reset when the timer between a [PointerUpEvent] and the
  // [PointerDownEvent] times out or when a new [PointerDownEvent] is tracked in
  // [addAllowedPointer].
  PointerUpEvent? get currentUp => _up;

  // The number of consecutive taps that the most recently tracked [PointerDownEvent]
  // in [currentDown] represents.
  //
  // This value defaults to zero, meaning a tap series is not currently being tracked.
  //
  // When this value is greater than zero it means [addAllowedPointer] has run
  // and at least one [PointerDownEvent] belongs to the current series of taps
  // being tracked.
  //
  // [addAllowedPointer] will either increment this value by `1` or set the value to `1`
  // depending if the new [PointerDownEvent] is determined to be in the same series as the
  // tap that preceded it. If too much time has elapsed between two taps, the recognizer has lost
  // in the arena, the gesture has been cancelled, or the recognizer is being disposed then
  // this value will be set to `0`, and a new series will begin.
  int get consecutiveTapCount => _consecutiveTapCount;

  // The set of [LogicalKeyboardKey]s pressed when the most recent [PointerDownEvent]
  // was tracked in [addAllowedPointer].
  //
  // This value defaults to an empty set.
  //
  // When the timer between two taps elapses, the recognizer loses the arena, the gesture is cancelled
  // or the recognizer is disposed of then this value is reset.
  Set<LogicalKeyboardKey> get keysPressedOnDown => _keysPressedOnDown ?? <LogicalKeyboardKey>{};

  // The upper limit for the [consecutiveTapCount]. When this limit is reached
  // all tap related state is reset and a new tap series is tracked.
  //
  // If this value is null, [consecutiveTapCount] can grow infinitely large.
  int? get maxConsecutiveTap;

  // The maximum distance in logical pixels the gesture is allowed to drift
  // from the initial touch down position before the [consecutiveTapCount]
  // and [keysPressedOnDown] are frozen and the remaining tracker state is
  // reset. These values remain frozen until the next [PointerDownEvent] is
  // tracked in [addAllowedPointer].
  double? get slopTolerance;

  // Private tap state tracked.
  PointerDownEvent? _down;
  PointerUpEvent? _up;
  int _consecutiveTapCount = 0;
  Set<LogicalKeyboardKey>? _keysPressedOnDown;

  OffsetPair? _originPosition;
  int? _previousButtons;

  // For timing taps.
  Timer? _consecutiveTapTimer;
  Offset? _lastTapOffset;

  // When tracking a tap, the [consecutiveTapCount] is incremented if the given tap
  // falls under the tolerance specifications and reset to 1 if not.
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    if (maxConsecutiveTap == _consecutiveTapCount) {
      _tapTrackerReset();
    }
    _up = null;
    if (_down != null && !_representsSameSeries(event)) {
      // The given tap does not match the specifications of the series of taps being tracked,
      // reset the tap count and related state.
      _consecutiveTapCount = 1;
    } else {
      _consecutiveTapCount += 1;
    }
    _consecutiveTapTimerStop();
    // `_down` must be assigned in this method instead of [handleEvent],
    // because [acceptGesture] might be called before [handleEvent],
    // which may rely on `_down` to initiate a callback.
    _trackTap(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      final bool isSlopPastTolerance = slopTolerance != null && _getGlobalDistance(event, _originPosition) > slopTolerance!;

      if (isSlopPastTolerance) {
        _consecutiveTapTimerStop();
        _previousButtons = null;
        _lastTapOffset = null;
      }
    } else if (event is PointerUpEvent) {
      _up = event;
      if (_down != null) {
        _consecutiveTapTimerStop();
        _consecutiveTapTimerStart();
      }
    } else if (event is PointerCancelEvent) {
      _tapTrackerReset();
    }
  }

  @override
  void rejectGesture(int pointer) {
    _tapTrackerReset();
  }

  @override
  void dispose() {
    _tapTrackerReset();
    super.dispose();
  }

  void _trackTap(PointerDownEvent event) {
    _down = event;
    _keysPressedOnDown = HardwareKeyboard.instance.logicalKeysPressed;
    _previousButtons = event.buttons;
    _lastTapOffset = event.position;
    _originPosition = OffsetPair(local: event.localPosition, global: event.position);
  }

  bool _hasSameButton(int buttons) {
    assert(_previousButtons != null);
    if (buttons == _previousButtons!) {
      return true;
    } else {
      return false;
    }
  }

  bool _isWithinConsecutiveTapTolerance(Offset secondTapOffset) {
    if (_lastTapOffset == null) {
      return false;
    }

    final Offset difference = secondTapOffset - _lastTapOffset!;
    return difference.distance <= kDoubleTapSlop;
  }

  bool _representsSameSeries(PointerDownEvent event) {
    return _consecutiveTapTimer != null
        && _isWithinConsecutiveTapTolerance(event.position)
        && _hasSameButton(event.buttons);
  }

  void _consecutiveTapTimerStart() {
    _consecutiveTapTimer ??= Timer(kDoubleTapTimeout, _tapTrackerReset);
  }

  void _consecutiveTapTimerStop() {
    if (_consecutiveTapTimer != null) {
      _consecutiveTapTimer!.cancel();
      _consecutiveTapTimer = null;
    }
  }

  void _tapTrackerReset() {
    // The timer has timed out, i.e. the time between a [PointerUpEvent] and the subsequent
    // [PointerDownEvent] exceeded the duration of [kDoubleTapTimeout], so the tap belonging
    // to the [PointerDownEvent] cannot be considered part of the same tap series as the
    // previous [PointerUpEvent].
    _consecutiveTapTimerStop();
    _previousButtons = null;
    _originPosition = null;
    _lastTapOffset = null;
    _consecutiveTapCount = 0;
    _keysPressedOnDown = null;
    _down = null;
    _up = null;
  }
}

/// Recognizes taps and movements.
///
/// Takes on the responsibilities of [TapGestureRecognizer] and
/// [DragGestureRecognizer] in one [GestureRecognizer].
///
/// ### Gesture arena behavior
///
/// [TapAndDragGestureRecognizer] competes on the pointer events of
/// [kPrimaryButton] only when it has at least one non-null `onTap*`
/// or `onDrag*` callback.
///
/// It will declare defeat if it determines that a gesture is not a
/// tap (e.g. if the pointer is dragged too far while it's contacting the
/// screen) or a drag (e.g. if the pointer was not dragged far enough to
/// be considered a drag.
///
/// This recognizer will not immediately declare victory for every tap or drag that it
/// recognizes.
///
/// The recognizer will declare victory when all other recognizer's in
/// the arena have lost, if the timer of [kPressTimeout] elapses and a tap
/// series greater than 1 is being tracked.
///
/// If this recognizer loses the arena (either by declaring defeat or by
/// another recognizer declaring victory) while the pointer is contacting the
/// screen, it will fire [onCancel] instead of [onTapUp] or [onDragEnd].
///
/// ### When competing with `TapGestureRecognizer` and `DragGestureRecognizer`
///
/// Similar to [TapGestureRecognizer] and [DragGestureRecognizer],
/// [TapAndDragGestureRecognizer] will not aggressively declare victory when it detects
/// a tap, so when it is competing with those gesture recognizers and others it has a chance
/// of losing.
///
/// When competing against [TapGestureRecognizer], if the pointer does not move past the tap
/// tolerance, then the recognizer that entered the arena first will win. In this case the
/// gesture detected is a tap. If the pointer does travel past the tap tolerance then this
/// recognizer will be declared winner by default. The gesture detected in this case is a drag.
///
/// When competing against [DragGestureRecognizer], if the pointer does not move a sufficient
/// global distance to be considered a drag, the recognizers will tie in the arena. If the
/// pointer does travel enough distance then the [TapAndDragGestureRecognizer] will lose because
/// the [DragGestureRecognizer] will declare self-victory when the drag threshold is met.
class TapAndDragGestureRecognizer extends OneSequenceGestureRecognizer with _TapStatusTrackerMixin {
  /// Creates a tap and drag gesture recognizer.
  ///
  /// {@macro flutter.gestures.GestureRecognizer.supportedDevices}
  TapAndDragGestureRecognizer({
    super.debugOwner,
    super.supportedDevices,
    super.allowedButtonsFilter,
  }) : _deadline = kPressTimeout,
      dragStartBehavior = DragStartBehavior.start,
      slopTolerance = kTouchSlop;

  /// Configure the behavior of offsets passed to [onDragStart].
  ///
  /// If set to [DragStartBehavior.start], the [onDragStart] callback will be called
  /// with the position of the pointer at the time this gesture recognizer won
  /// the arena. If [DragStartBehavior.down], [onDragStart] will be called with
  /// the position of the first detected down event for the pointer. When there
  /// are no other gestures competing with this gesture in the arena, there's
  /// no difference in behavior between the two settings.
  ///
  /// For more information about the gesture arena:
  /// https://flutter.dev/docs/development/ui/advanced/gestures#gesture-disambiguation
  ///
  /// By default, the drag start behavior is [DragStartBehavior.start].
  ///
  /// See also:
  ///
  ///  * [DragGestureRecognizer.dragStartBehavior], which includes more details and an example.
  DragStartBehavior dragStartBehavior;

  /// The frequency at which the [onDragUpdate] callback is called.
  ///
  /// The value defaults to null, meaning there is no delay for [onDragUpdate] callback.
  ///
  /// See also:
  ///   * [TextSelectionGestureDetector], which uses this parameter to avoid excessive updates
  ///     text layouts in text fields.
  Duration? dragUpdateThrottleFrequency;

  /// An upper bound for the amount of taps that can belong to one tap series.
  ///
  /// When this limit is reached the series of taps being tracked by this
  /// recognizer will be reset.
  @override
  int? maxConsecutiveTap;

  // The maximum distance in logical pixels the gesture is allowed to drift
  // to still be considered a tap.
  //
  // Drifting past the allowed slop amount causes the recognizer to reset
  // the tap series it is currently tracking, stopping the consecutive tap
  // count from increasing. The consecutive tap count and the set of hardware
  // keys that were pressed on tap down will retain their pre-past slop
  // tolerance values until the next [PointerDownEvent] is tracked.
  //
  // If the gesture exceeds this value, then it can only be accepted as a drag
  // gesture.
  //
  // Can be null to indicate that the gesture can drift for any distance.
  // Defaults to 18 logical pixels.
  @override
  final double? slopTolerance;

  /// {@macro flutter.gestures.tap.TapGestureRecognizer.onTapDown}
  ///
  /// This triggers after the down event, once a short timeout ([kPressTimeout]) has
  /// elapsed, or once the gestures has won the arena, whichever comes first.
  ///
  /// The position of the pointer is provided in the callback's `details`
  /// argument, which is a [TapDragDownDetails] object.
  ///
  /// {@template flutter.gestures.selectionrecognizers.TapAndDragGestureRecognizer.tapStatusTrackerData}
  /// The number of consecutive taps, and the keys that were pressed on tap down
  /// are also provided in the callback's `details` argument.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [TapDragDownDetails], which is passed as an argument to this callback.
  GestureTapDragDownCallback? onTapDown;

  /// {@macro flutter.gestures.tap.TapGestureRecognizer.onTapUp}
  ///
  /// This triggers on the up event, if the recognizer wins the arena with it
  /// or has previously won.
  ///
  /// The position of the pointer is provided in the callback's `details`
  /// argument, which is a [TapDragUpDetails] object.
  ///
  /// {@macro flutter.gestures.selectionrecognizers.TapAndDragGestureRecognizer.tapStatusTrackerData}
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [TapDragUpDetails], which is passed as an argument to this callback.
  GestureTapDragUpCallback? onTapUp;

  /// {@macro flutter.gestures.monodrag.DragGestureRecognizer.onStart}
  ///
  /// The position of the pointer is provided in the callback's `details`
  /// argument, which is a [TapDragStartDetails] object. The [dragStartBehavior]
  /// determines this position.
  ///
  /// {@macro flutter.gestures.selectionrecognizers.TapAndDragGestureRecognizer.tapStatusTrackerData}
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [TapDragStartDetails], which is passed as an argument to this callback.
  GestureTapDragStartCallback? onDragStart;

  /// {@macro flutter.gestures.monodrag.DragGestureRecognizer.onUpdate}
  ///
  /// The distance traveled by the pointer since the last update is provided in
  /// the callback's `details` argument, which is a [TapDragUpdateDetails] object.
  ///
  /// {@macro flutter.gestures.selectionrecognizers.TapAndDragGestureRecognizer.tapStatusTrackerData}
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [TapDragUpdateDetails], which is passed as an argument to this callback.
  GestureTapDragUpdateCallback? onDragUpdate;

  /// {@macro flutter.gestures.monodrag.DragGestureRecognizer.onEnd}
  ///
  /// The velocity is provided in the callback's `details` argument, which is a
  /// [TapDragEndDetails] object.
  ///
  /// {@macro flutter.gestures.selectionrecognizers.TapAndDragGestureRecognizer.tapStatusTrackerData}
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [TapDragEndDetails], which is passed as an argument to this callback.
  GestureTapDragEndCallback? onDragEnd;

  /// The pointer that previously triggered [onTapDown] did not complete.
  ///
  /// This is called when a [PointerCancelEvent] is tracked when the [onTapDown] callback
  /// was previously called.
  ///
  /// It may also be called if a [PointerUpEvent] is tracked after the pointer has moved
  /// past the tap tolerance but not past the drag tolerance, and the recognizer has not
  /// yet won the arena.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  GestureCancelCallback? onCancel;

  // Tap related state.
  bool _pastSlopTolerance = false;
  bool _sentTapDown = false;
  bool _wonArenaForPrimaryPointer = false;

  // Primary pointer being tracked by this recognizer.
  int? _primaryPointer;
  Timer? _deadlineTimer;
  // The recognizer will call [onTapDown] after this amount of time has elapsed
  // since starting to track the primary pointer.
  //
  // [onTapDown] will not be called if the primary pointer is
  // accepted, rejected, or all pointers are up or canceled before [_deadline].
  final Duration _deadline;

  // Drag related state.
  _DragState _dragState = _DragState.ready;
  PointerEvent? _start;
  late OffsetPair _initialPosition;
  late double _globalDistanceMoved;
  OffsetPair? _correctedPosition;

  // For drag update throttle.
  TapDragUpdateDetails? _lastDragUpdateDetails;
  Timer? _dragUpdateThrottleTimer;

  final Set<int> _acceptedActivePointers = <int>{};

  bool _hasSufficientGlobalDistanceToAccept(PointerDeviceKind pointerDeviceKind, double? deviceTouchSlop) {
    return _globalDistanceMoved.abs() > computePanSlop(pointerDeviceKind, gestureSettings);
  }

  // Drag updates may require throttling to avoid excessive updating, such as for text layouts in text
  // fields. The frequency of invocations is controlled by the [dragUpdateThrottleFrequency].
  //
  // Once the drag gesture ends, any pending drag update will be fired
  // immediately. See [_checkDragEnd].
  void _handleDragUpdateThrottled() {
    assert(_lastDragUpdateDetails != null);
    if (onDragUpdate != null) {
      invokeCallback<void>('onDragUpdate', () => onDragUpdate!(_lastDragUpdateDetails!));
    }
    _dragUpdateThrottleTimer = null;
    _lastDragUpdateDetails = null;
  }

  @override
  bool isPointerAllowed(PointerEvent event) {
    if (_primaryPointer == null) {
      switch (event.buttons) {
        case kPrimaryButton:
          if (onTapDown == null &&
              onDragStart == null &&
              onDragUpdate == null &&
              onDragEnd == null &&
              onTapUp == null &&
              onCancel == null) {
            return false;
          }
        default:
          return false;
      }
    } else {
      if (event.pointer != _primaryPointer) {
        return false;
      }
    }

    return super.isPointerAllowed(event as PointerDownEvent);
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (_dragState == _DragState.ready) {
      super.addAllowedPointer(event);
      _primaryPointer = event.pointer;
      _globalDistanceMoved = 0.0;
      _dragState = _DragState.possible;
      _initialPosition = OffsetPair(global: event.position, local: event.localPosition);
      _deadlineTimer = Timer(_deadline, () => _didExceedDeadlineWithEvent(event));
    }
  }

  @override
  void handleNonAllowedPointer(PointerDownEvent event) {
    // There can be multiple drags simultaneously. Their effects are combined.
    if (event.buttons != kPrimaryButton) {
      if (!_wonArenaForPrimaryPointer) {
        super.handleNonAllowedPointer(event);
      }
    }
  }

  @override
  void acceptGesture(int pointer) {
    if (pointer != _primaryPointer) {
      return;
    }

    _stopDeadlineTimer();

    assert(!_acceptedActivePointers.contains(pointer));
    _acceptedActivePointers.add(pointer);

    // Called when this recognizer is accepted by the [GestureArena].
    if (currentDown != null) {
      _checkTapDown(currentDown!);
    }

    _wonArenaForPrimaryPointer = true;

    if (_start != null) {
      _acceptDrag(_start!);
    }

    if (currentUp != null) {
      _checkTapUp(currentUp!);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    switch (_dragState) {
      case _DragState.ready:
        _checkCancel();
        resolve(GestureDisposition.rejected);

      case _DragState.possible:
        if (_pastSlopTolerance) {
          // This means the pointer was not accepted as a tap.
          if (_wonArenaForPrimaryPointer) {
            // If the recognizer has already won the arena for the primary pointer being tracked
            // but the pointer has exceeded the tap tolerance, then the pointer is accepted as a
            // drag gesture.
            if (currentDown != null) {
              _acceptDrag(currentDown!);
              _checkDragEnd();
            }
          } else {
            _checkCancel();
            resolve(GestureDisposition.rejected);
          }
        } else {
          // The pointer is accepted as a tap.
          if (currentUp != null) {
            _checkTapUp(currentUp!);
          }
        }

      case _DragState.accepted:
        // For the case when the pointer has been accepted as a drag.
        // Meaning [_checkTapDown] and [_checkDragStart] have already ran.
        _checkDragEnd();
    }

    _stopDeadlineTimer();
    _dragState = _DragState.ready;
    _pastSlopTolerance = false;
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event.pointer != _primaryPointer) {
      return;
    }
    super.handleEvent(event);
    if (event is PointerMoveEvent) {
      // Receiving a [PointerMoveEvent], does not automatically mean the pointer
      // being tracked is doing a drag gesture. There is some drift that can happen
      // between the initial [PointerDownEvent] and subsequent [PointerMoveEvent]s.
      // Accessing [_pastSlopTolerance] lets us know if our tap has moved past the
      // acceptable tolerance. If the pointer does not move past this tolerance than
      // it is not considered a drag.
      //
      // To be recognized as a drag, the [PointerMoveEvent] must also have moved
      // a sufficient global distance from the initial [PointerDownEvent] to be
      // accepted as a drag. This logic is handled in [_hasSufficientGlobalDistanceToAccept].
      //
      // The recognizer will also detect the gesture as a drag when the pointer
      // has been accepted and it has moved past the [slopTolerance] but has not moved
      // a sufficient global distance from the initial position to be considered a drag.
      // In this case since the gesture cannot be a tap, it defaults to a drag.

      _pastSlopTolerance = _pastSlopTolerance || slopTolerance != null && _getGlobalDistance(event, _initialPosition) > slopTolerance!;

      if (_dragState == _DragState.accepted) {
        _checkDragUpdate(event);
      } else if (_dragState == _DragState.possible) {
        if (_start == null) {
          // Only check for a drag if the start of a drag was not already identified.
          _checkDrag(event);
        }

        // This can occur when the recognizer is accepted before a [PointerMoveEvent] has been
        // received that moves the pointer a sufficient global distance to be considered a drag.
        if (_start != null) {
          _acceptDrag(_start!);
        }
      }
    } else if (event is PointerUpEvent) {
      if (_dragState == _DragState.possible) {
        // The drag has not been accepted before a [PointerUpEvent], therefore the recognizer
        // attempts to recognize a tap.
        stopTrackingIfPointerNoLongerDown(event);
      } else if (_dragState == _DragState.accepted) {
        _giveUpPointer(event.pointer);
      }
    } else if (event is PointerCancelEvent) {
      _dragState = _DragState.ready;
      _giveUpPointer(event.pointer);
    }
  }

  @override
  void rejectGesture(int pointer) {
    if (pointer != _primaryPointer) {
      return;
    }
    super.rejectGesture(pointer);

    _stopDeadlineTimer();
    _giveUpPointer(pointer);
    _resetTaps();
    _resetDragUpdateThrottle();
  }

  @override
  void dispose() {
    _stopDeadlineTimer();
    _resetDragUpdateThrottle();
    super.dispose();
  }

  @override
  String get debugDescription => 'tap_and_drag';

  void _acceptDrag(PointerEvent event) {
    if (!_wonArenaForPrimaryPointer) {
      return;
    }
    _dragState = _DragState.accepted;
    if (dragStartBehavior == DragStartBehavior.start) {
      _initialPosition = _initialPosition + OffsetPair(global: event.delta, local: event.localDelta);
    }
    _checkDragStart(event);
    if (event.localDelta != Offset.zero) {
      final Matrix4? localToGlobal = event.transform != null ? Matrix4.tryInvert(event.transform!) : null;
      final Offset correctedLocalPosition = _initialPosition.local + event.localDelta;
      final Offset globalUpdateDelta = PointerEvent.transformDeltaViaPositions(
        untransformedEndPosition: correctedLocalPosition,
        untransformedDelta: event.localDelta,
        transform: localToGlobal,
      );
      final OffsetPair updateDelta = OffsetPair(local: event.localDelta, global: globalUpdateDelta);
      _correctedPosition = _initialPosition + updateDelta; // Only adds delta for down behaviour
      _checkDragUpdate(event);
      _correctedPosition = null;
    }
  }

  void _checkDrag(PointerMoveEvent event) {
    final Matrix4? localToGlobalTransform = event.transform == null ? null : Matrix4.tryInvert(event.transform!);
    _globalDistanceMoved += PointerEvent.transformDeltaViaPositions(
      transform: localToGlobalTransform,
      untransformedDelta: event.localDelta,
      untransformedEndPosition: event.localPosition
    ).distance * 1.sign;
    if (_hasSufficientGlobalDistanceToAccept(event.kind, gestureSettings?.touchSlop)) {
      _start = event;
    }
  }

  void _checkTapDown(PointerDownEvent event) {
    if (_sentTapDown) {
      return;
    }

    final TapDragDownDetails details = TapDragDownDetails(
      globalPosition: event.position,
      localPosition: event.localPosition,
      kind: getKindForPointer(event.pointer),
      consecutiveTapCount: consecutiveTapCount,
      keysPressedOnDown: keysPressedOnDown,
    );

    if (onTapDown != null) {
      invokeCallback('onTapDown', () => onTapDown!(details));
    }

    _sentTapDown = true;
  }

  void _checkTapUp(PointerUpEvent event) {
    if (!_wonArenaForPrimaryPointer) {
      return;
    }

    final TapDragUpDetails upDetails = TapDragUpDetails(
      kind: event.kind,
      globalPosition: event.position,
      localPosition: event.localPosition,
      consecutiveTapCount: consecutiveTapCount,
      keysPressedOnDown: keysPressedOnDown,
    );

    if (onTapUp != null) {
      invokeCallback('onTapUp', () => onTapUp!(upDetails));
    }

    _resetTaps();
    if (!_acceptedActivePointers.remove(event.pointer)) {
      resolvePointer(event.pointer, GestureDisposition.rejected);
    }
  }

  void _checkDragStart(PointerEvent event) {
    if (onDragStart != null) {
      final TapDragStartDetails details = TapDragStartDetails(
        sourceTimeStamp: event.timeStamp,
        globalPosition: _initialPosition.global,
        localPosition: _initialPosition.local,
        kind: getKindForPointer(event.pointer),
        consecutiveTapCount: consecutiveTapCount,
        keysPressedOnDown: keysPressedOnDown,
      );

      invokeCallback<void>('onDragStart', () => onDragStart!(details));
    }

    _start = null;
  }

  void _checkDragUpdate(PointerEvent event) {
    final Offset globalPosition = _correctedPosition != null ? _correctedPosition!.global : event.position;
    final Offset localPosition = _correctedPosition != null ? _correctedPosition!.local : event.localPosition;

    final TapDragUpdateDetails details =  TapDragUpdateDetails(
      sourceTimeStamp: event.timeStamp,
      delta: event.localDelta,
      globalPosition: globalPosition,
      kind: getKindForPointer(event.pointer),
      localPosition: localPosition,
      offsetFromOrigin: globalPosition - _initialPosition.global,
      localOffsetFromOrigin: localPosition - _initialPosition.local,
      consecutiveTapCount: consecutiveTapCount,
      keysPressedOnDown: keysPressedOnDown,
    );

    if (dragUpdateThrottleFrequency != null) {
      _lastDragUpdateDetails = details;
      // Only schedule a new timer if there's not one pending.
      _dragUpdateThrottleTimer ??= Timer(dragUpdateThrottleFrequency!, _handleDragUpdateThrottled);
    } else {
      if (onDragUpdate != null) {
        invokeCallback<void>('onDragUpdate', () => onDragUpdate!(details));
      }
    }
  }

  void _checkDragEnd() {
    if (_dragUpdateThrottleTimer != null) {
      // If there's already an update scheduled, trigger it immediately and
      // cancel the timer.
      _dragUpdateThrottleTimer!.cancel();
      _handleDragUpdateThrottled();
    }

    final TapDragEndDetails endDetails =
      TapDragEndDetails(
        primaryVelocity: 0.0,
        consecutiveTapCount: consecutiveTapCount,
        keysPressedOnDown: keysPressedOnDown,
      );

    if (onDragEnd != null) {
      invokeCallback<void>('onDragEnd', () => onDragEnd!(endDetails));
    }

    _resetTaps();
    _resetDragUpdateThrottle();
  }

  void _checkCancel() {
    if (!_sentTapDown) {
      // Do not fire tap cancel if [onTapDown] was never called.
      return;
    }
    if (onCancel != null) {
      invokeCallback('onCancel', onCancel!);
    }
    _resetDragUpdateThrottle();
    _resetTaps();
  }

  void _didExceedDeadlineWithEvent(PointerDownEvent event) {
    _didExceedDeadline();
  }

  void _didExceedDeadline() {
    if (currentDown != null) {
      _checkTapDown(currentDown!);

      if (consecutiveTapCount > 1) {
        // If our consecutive tap count is greater than 1, i.e. is a double tap or greater,
        // then this recognizer declares victory to prevent the [LongPressGestureRecognizer]
        // from declaring itself the winner if a double tap is held for too long.
        resolve(GestureDisposition.accepted);
      }
    }
  }

  void _giveUpPointer(int pointer) {
    stopTrackingPointer(pointer);
    // If the pointer was never accepted, then it is rejected since this recognizer is no longer
    // interested in winning the gesture arena for it.
    if (!_acceptedActivePointers.remove(pointer)) {
      resolvePointer(pointer, GestureDisposition.rejected);
    }
  }

  void _resetTaps() {
    _sentTapDown = false;
    _wonArenaForPrimaryPointer = false;
    _primaryPointer = null;
  }

  void _resetDragUpdateThrottle() {
    if (dragUpdateThrottleFrequency == null) {
      return;
    }
    _lastDragUpdateDetails = null;
    if (_dragUpdateThrottleTimer != null) {
      _dragUpdateThrottleTimer!.cancel();
      _dragUpdateThrottleTimer = null;
    }
  }

  void _stopDeadlineTimer() {
    if (_deadlineTimer != null) {
      _deadlineTimer!.cancel();
      _deadlineTimer = null;
    }
  }
}
