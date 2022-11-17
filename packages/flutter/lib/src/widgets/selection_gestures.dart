// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart' show HardwareKeyboard, LogicalKeyboardKey;

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
//   this recognizer moves from the [possible] state to [accepted].
//
// Once the recognizer has stopped tracking any remaining pointers, the recognizer
// returns to the [ready] state.
enum _DragState {
  // The recognizer is ready to start recognizing a drag.
  ready,

  // The sequence of pointer events seen thus far is consistent with a drag but
  // it has not been accepted definitevely.
  possible,

  // The sequence of pointer events has been accepted definitevely as a drag.
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
class TapDragDownDetails {
  /// Creates details for a [GestureTapDragDownCallback].
  ///
  /// The [globalPosition] argument must not be null.
  TapDragDownDetails({
    this.globalPosition = Offset.zero,
    Offset? localPosition,
    this.kind,
    required this.consecutiveTapCount,
    required this.keysPressedOnDown,
  }) : assert(globalPosition != null),
       localPosition = localPosition ?? globalPosition;

  /// The global position at which the pointer contacted the screen.
  final Offset globalPosition;

  /// The kind of the device that initiated the event.
  final PointerDeviceKind? kind;

  /// The local position at which the pointer contacted the screen.
  final Offset localPosition;

  /// If this tap is in a series of taps, then this value represents
  /// the number in the series this tap is.
  final int consecutiveTapCount;

  /// The keys that were pressed when the most recent [PointerDownEvent] occurred.
  final Set<LogicalKeyboardKey> keysPressedOnDown;

  @override
  String toString() => '${objectRuntimeType(this, 'TapDragDownDetails')}($globalPosition)';
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
class TapDragUpDetails {
  /// Creates details for a [GestureTapDragUpCallback].
  ///
  /// The [globalPosition] argument must not be null.
  TapDragUpDetails({
    required this.kind,
    this.globalPosition = Offset.zero,
    Offset? localPosition,
    required this.consecutiveTapCount,
    required this.keysPressedOnDown,
  }) : assert(globalPosition != null),
       localPosition = localPosition ?? globalPosition;

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
  String toString() => '${objectRuntimeType(this, 'TapDragUpDetails')}($globalPosition)';
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
class TapDragStartDetails {
  /// Creates details for a [GestureTapDragStartCallback].
  ///
  /// The [globalPosition] argument must not be null.
  TapDragStartDetails({
    this.sourceTimeStamp,
    this.globalPosition = Offset.zero,
    Offset? localPosition,
    this.kind,
    required this.consecutiveTapCount,
    required this.keysPressedOnDown,
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

  /// The kind of the device that initiated the event.
  final PointerDeviceKind? kind;

  /// If this tap is in a series of taps, then this value represents
  /// the number in the series this tap is.
  final int consecutiveTapCount;

  /// The keys that were pressed when the most recent [PointerDownEvent] occurred.
  final Set<LogicalKeyboardKey> keysPressedOnDown;

  @override
  String toString() => '${objectRuntimeType(this, 'TapDragStartDetails')}($globalPosition)';
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
class TapDragUpdateDetails {
  /// Creates details for a [GestureTapDragUpdateCallback].
  ///
  /// The [delta] argument must not be null.
  ///
  /// If [primaryDelta] is non-null, then its value must match one of the
  /// coordinates of [delta] and the other coordinate must be zero.
  ///
  /// The [globalPosition] argument must be provided and must not be null.
  TapDragUpdateDetails({
    this.sourceTimeStamp,
    this.delta = Offset.zero,
    this.primaryDelta,
    required this.globalPosition,
    this.kind,
    Offset? localPosition,
    this.offsetFromOrigin = Offset.zero,
    Offset? localOffsetFromOrigin,
    required this.consecutiveTapCount,
    required this.keysPressedOnDown,
  }) : assert(delta != null),
       assert(
         primaryDelta == null
           || (primaryDelta == delta.dx && delta.dy == 0.0)
           || (primaryDelta == delta.dy && delta.dx == 0.0),
       ),
       assert(offsetFromOrigin != null),
       localPosition = localPosition ?? globalPosition,
       localOffsetFromOrigin = localOffsetFromOrigin ?? offsetFromOrigin;

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

  /// The kind of the device that initiated the event.
  final PointerDeviceKind? kind;

  /// The local position in the coordinate system of the event receiver at
  /// which the pointer contacted the screen.
  ///
  /// Defaults to [globalPosition] if not specified in the constructor.
  final Offset localPosition;

  /// A delta offset from the point where the drag initially contacted
  /// the screen to the point where the pointer is currently located in global
  /// coordinates (the present [globalPosition]) when this callback is triggered.
  ///
  /// When considering a [GestureRecognizer] that tracks the number of consecutive taps,
  /// this offset is associated with the most recent [PointerDownEvent] that occured.
  final Offset offsetFromOrigin;

  /// A local delta offset from the point where the drag initially contacted
  /// the screen to the point where the pointer is currently located in local
  /// coordinates (the present [localPosition]) when this callback is triggered.
  ///
  /// When considering a [GestureRecognizer] that tracks the number of consecutive taps,
  /// this offset is associated with the most recent [PointerDownEvent] that occured.
  final Offset localOffsetFromOrigin;

  /// If this tap is in a series of taps, then this value represents
  /// the number in the series this tap is.
  final int consecutiveTapCount;

  /// The keys that were pressed when the most recent [PointerDownEvent] occurred.
  final Set<LogicalKeyboardKey> keysPressedOnDown;

  @override
  String toString() => '${objectRuntimeType(this, 'TapDragUpdateDetails')}($delta)';
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
class TapDragEndDetails {
  /// Creates details for a [GestureTapDragEndCallback].
  ///
  /// The [velocity] argument must not be null.
  TapDragEndDetails({
    this.velocity = Velocity.zero,
    this.primaryVelocity,
    required this.consecutiveTapCount,
    required this.keysPressedOnDown,
  }) : assert(velocity != null),
       assert(
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
  String toString() => '${objectRuntimeType(this, 'TapDragEndDetails')}($velocity)';
}

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

  // Whether the tap drifted past the tolerance defined by [kDoubleTapTouchSlop] in any subsequent
  // tracked [PointerMoveEvent]s.
  //
  // This value default to false.
  //
  // If the tap does drift past the tolerance then all of the tracked state is reset except
  // the [currentDown], [currentUp], [consecutiveTapCount], and [keysPressedOnDown]. This is because
  // the [OneSequenceGestureRecognizer] may be handling a gesture that does accept a tap drift past
  // the tolerance defined by [kDoubleTapTouchSlop], such as a drag, so it may still want access
  // to the tracked tap state.
  bool get pastTapTolerance => _pastTapTolerance;

  // The upper limit for the [consecutiveTapCount]. When this limit is reached
  // all tap related state is reset and a new tap series is tracked.
  //
  // If this value is null, [consecutiveTapCount] can grow infinitely large.
  int? get maxConsecutiveTap;

  // Private tap state tracked.
  PointerDownEvent? _down;
  PointerUpEvent? _up;
  int _consecutiveTapCount = 0;
  Set<LogicalKeyboardKey>? _keysPressedOnDown;
  bool _pastTapTolerance = false;

  bool _wonArena = false;
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
    if (maxConsecutiveTap != null && maxConsecutiveTap == _consecutiveTapCount) {
      _tapTrackerReset();
    }
    _up = null;
    _pastTapTolerance = false;
    _wonArena = false;
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
    _trackTrap(event);
  }

  @override
  void acceptGesture(int pointer) {
    _wonArena = true;
    if (_up != null && _down != null) {
      _consecutiveTapTimerStop();
      _consecutiveTapTimerStart();
      _wonArena = false;
    }
  }

  double _getGlobalDistance(PointerEvent event) {
    assert(_originPosition != null);
    final Offset offset = event.position - _originPosition!.global;
    return offset.distance;
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      final bool isSlopPastTolerance = _getGlobalDistance(event) > kDoubleTapTouchSlop;

      if (isSlopPastTolerance) {
        _pastTapTolerance = true;
        _consecutiveTapTimerStop();
        _previousButtons = null;
        _lastTapOffset = null;
      }
    } else if (event is PointerUpEvent) {
      _up = event;
      if (_wonArena && _up != null && _down != null) {
        _consecutiveTapTimerStop();
        _consecutiveTapTimerStart();
        _wonArena = false;
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

  void _trackTrap(PointerDownEvent event) {
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
    assert(secondTapOffset != null);
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
    _wonArena = false;
    _lastTapOffset = null;
    _consecutiveTapCount = 0;
    _keysPressedOnDown = null;
    _down = null;
    _up = null;
    _pastTapTolerance = false;
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
/// or `onDrag*` callback. It competes on the pointer events of [kSecondaryButton]
/// when it has at least one non-null `onSecondaryTap*` callback.
///
/// It will declare defeat if it determines that a gesture is not a
/// tap (e.g. if the pointer is dragged too far while it's contacting the
/// screen) or a drag (e.g. if the pointer was not dragged far enough to
/// be considered a drag or the button used is [kSecondaryButton]).
///
/// It will not immediately declare victory for every tap that it
/// recognizes, but it will declare victory for every drag it recognizes.
///
/// The recognizer will declare victory when all other recognizer's in
/// the arena have lost, if the timeout ([deadline]) elapsed and a tap
/// series greater than 1 is being tracked, or until the pointer has moved
/// a sufficient global distance from the origin to be considered a drag.
///
/// If this recognizer loses the arena (either by declaring defeat or by
/// another recognizer declaring victory) while the pointer is contacting the
/// screen, it will fire [onTapCancel], and [onDragCancel] instead of [onTapUp]
/// or [onDragEnd].
///
/// ### When competing with `TapGestureRecognizer` and `DragGestureRecognizer`
///
/// Similar to [TapGestureRecognizer] and [DragGestureRecognizer],
/// [TapAndDragGestureRecognizer] will not aggresively declare victory when it detects
/// a tap, so when it is competing with those gesture recognizers and others it has a chance
/// of losing.
///
/// When competing against [TapGestureRecognizer], if the pointer does not move past the tap
/// tolerance, then the recognizer that entered the arena first will win. If the pointer does
/// travel past the tap tolerance then this recognizer will declared winner by default. The
/// gesture detected in this case is a tap.
///
/// When competing against [DragGestureRecognizer], if the pointer does not move a sufficient
/// global distance to be considered a drag, the recognizers will tie in the arena. If the
/// pointer does travel enough distance then the recognizer that entered the arena first will win.
/// The gesture detected in this case is a drag.
class TapAndDragGestureRecognizer extends OneSequenceGestureRecognizer with _TapStatusTrackerMixin {
  /// Creates a tap and drag gesture recognizer.
  ///
  /// [dragStartBehavior] must not be null.
  ///
  /// {@macro flutter.gestures.GestureRecognizer.supportedDevices}
  TapAndDragGestureRecognizer({
    this.deadline = kPressTimeout,
    this.dragStartBehavior = DragStartBehavior.start,
    this.dragUpdateThrottleFrequency,
    this.maxConsecutiveTap,
    super.debugOwner,
    super.kind,
    super.supportedDevices,
  }) : assert(dragStartBehavior != null);

  /// If non-null, the recognizer will call [onTapDown] after this
  /// amount of time has elapsed since starting to track the primary pointer.
  ///
  /// [onTapDown] will not be called if the primary pointer is
  /// accepted, rejected, or all pointers are up or canceled before [deadline].
  final Duration? deadline;

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
  Duration? dragUpdateThrottleFrequency;

  /// An upper bound for the amount of taps that can belong to one tap series.
  ///
  /// When this limit is reached the series of taps being tracked by this
  /// recognizer will be reset.
  @override
  int? maxConsecutiveTap;

  /// {@macro flutter.gestures.tap.TapGestureRecognizer.onTapDown}
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
  ///  * [onSecondaryTapDown], a similar callback but for a secondary button.
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
  ///  * [onSecondaryTapUp], a similar callback but for a secondary button.
  ///  * [TapDragUpDetails], which is passed as an argument to this callback.
  GestureTapDragUpCallback? onTapUp;

  /// {@macro flutter.gestures.tap.TapGestureRecognizer.onTapCancel}
  ///
  /// {@template flutter.gestures.selectionrecognizers.TapAndDragGestureRecognizer.onTapCancel}
  /// This is called if a [PointerMoveEvent] has moved a sufficient global distance
  /// from the initial [PointerDownEvent] to be considered a drag.
  ///
  /// It may also be called if the pointer tracked is deemed neither a drag, nor a tap,
  /// due to it not meeting the global distance necessary to be considered a drag, and drifting
  /// too far from the initial [PointerDownEvent] to be considered a tap.
  /// {@endtemplate}
  /// In this case both [onTapCancel] and [onDragCancel] will be called.
  GestureTapCancelCallback? onTapCancel;

  /// {@macro flutter.gestures.tap.TapGestureRecognizer.onSecondaryTap}
  ///
  /// See also:
  ///
  ///  * [kSecondaryButton], the button this callback responds to.
  ///  * [onSecondaryTapUp], which has the same timing but with details.
  GestureTapCallback? onSecondaryTap;

  /// {@macro flutter.gestures.tap.TapGestureRecognizer.onSecondaryTapDown}
  ///
  /// See also:
  ///
  ///  * [kSecondaryButton], the button this callback responds to.
  ///  * [onTapDown], a similar callback but for a primary button.
  ///  * [TapDragDownDetails], which is passed as an argument to this callback.
  GestureTapDragDownCallback? onSecondaryTapDown;

  /// {@macro flutter.gestures.tap.TapGestureRecognizer.onSecondaryTapUp}
  ///
  /// See also:
  ///
  ///  * [onSecondaryTap], a handler triggered right after this one that doesn't
  ///    pass any details about the tap.
  ///  * [kSecondaryButton], the button this callback responds to.
  ///  * [onTapUp], a similar callback but for a primary button.
  ///  * [TapDragUpDetails], which is passed as an argument to this callback.
  GestureTapDragUpCallback? onSecondaryTapUp;

  /// {@macro flutter.gestures.tap.TapGestureRecognizer.onSecondaryTapCancel}
  ///
  /// {@macro flutter.gestures.selectionrecognizers.TapAndDragGestureRecognizer.onTapCancel}
  /// In this case both [onSecondaryTapCancel] and [onDragCancel] will be called.
  GestureTapCancelCallback? onSecondaryTapCancel;

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
  /// This is called when a [PointerUpEvent] is tracked before the recognizer has accepted
  /// the gesture as a drag. This can happen if none of the [PointerMoveEvent]s received
  /// drift far enough to exceed the tap tolerance, and do not meet the global distance specifications
  /// to be considered a drag.
  ///
  /// It may also be called if the pointer tracked is deemed neither a drag, nor a tap,
  /// due to it not meeting the global distance necessary to be considered a drag, and drifting
  /// too far from the initial [PointerDownEvent] to be considered a tap. In this case both [onTapCancel]
  /// and [onDragCancel] will be called.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  GestureDragCancelCallback? onDragCancel;

  // Tap related state.
  bool _sentTapDown = false;
  bool _wonArenaForPrimaryPointer = false;

  // Primary pointer being tracked by this recognizer.
  int? _primaryPointer;
  Timer? _deadlineTimer;

  // Drag related state.
  _DragState _dragState = _DragState.ready;
  PointerEvent? _start;
  late OffsetPair _initialPosition;
  late double _globalDistanceMoved;
  OffsetPair? _correctedPosition;

  // For drag update throttle.
  TapDragUpdateDetails? _lastDragUpdateDetails;
  Timer? _dragUpdateThrottleTimer;

  // The buttons sent by [PointerDownEvent]. If a [PointerMoveEvent] comes with a
  // different set of buttons, the gesture is canceled.
  int? _initialButtons;

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
    if (_initialButtons == null) {
      switch (event.buttons) {
        case kPrimaryButton:
          if (onTapDown == null &&
              onDragStart == null &&
              onDragUpdate == null &&
              onDragEnd == null &&
              onTapUp == null &&
              onTapCancel == null &&
              onDragCancel == null) {
            return false;
          }
          break;
        case kSecondaryButton:
          if (onSecondaryTap == null &&
              onSecondaryTapDown == null &&
              onSecondaryTapUp == null) {
            return false;
          }
          break;
        default:
          return false;
      }
    } else {
      // There can be multiple drags simultaneously. Their effects are combined.
      if (event.buttons != _initialButtons) {
        return false;
      }
    }
    return super.isPointerAllowed(event as PointerDownEvent);
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _primaryPointer = event.pointer;
    if (deadline != null) {
      _deadlineTimer = Timer(deadline!, () => _didExceedDeadlineWithEvent(event));
    }

    if (_dragState == _DragState.ready) {
      _globalDistanceMoved = 0.0;
      _initialButtons = event.buttons;
      _dragState = _DragState.possible;
      _initialPosition = OffsetPair(global: event.position, local: event.localPosition);
    }
  }

  @override
  void acceptGesture(int pointer) {
    super.acceptGesture(pointer);
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
    if (currentUp != null) {
      _checkTapUp(currentUp!);
    }

    // resolve(GestureDisposition.accepted) may be called when the [PointerMoveEvent] has
    // moved a sufficient global distance.
    if (_dragState == _DragState.accepted) {
      if (_start != null) {
        _acceptDrag(_start!);
      }
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    switch (_dragState) {
      case _DragState.ready:
        resolve(GestureDisposition.rejected);
        _checkCancel();
        break;

      case _DragState.possible:
        if (currentUp == null) {
          _checkCancel();
          resolve(GestureDisposition.rejected);
          break;
        }
        if (pastTapTolerance) {
          // This means our pointer was not accepted as a tap nor a drag.
          // This can happen when a user drags on a right click, going past the
          // tap tolerance, and drag tolerance, but being rejected since a right click
          // drag is not allowed by this recognizer.
          _start = currentDown;
          _dragState = _DragState.accepted;
          if (_wonArenaForPrimaryPointer) {
            _acceptDrag(_start!);
            _checkDragEnd();
          } else {
            _checkDragCancel();
          }
        } else {
          _checkDragCancel();
          if (currentUp != null) {
            _checkTapUp(currentUp!);
          }
        }
        break;

      case _DragState.accepted:
        // For the case when the pointer has been accepted as a drag.
        // Meaning [_checkTapDown] and [_checkDragStart] have already ran.
        _checkDragEnd();
        _initialButtons = null;
        break;
    }

    _stopDeadlineTimer();
    _dragState = _DragState.ready;
  }

  @override
  void handleEvent(PointerEvent event) {
    super.handleEvent(event);
    if (event is PointerMoveEvent) {
      // Receiving a [PointerMoveEvent], does not automatically mean the pointer
      // being tracked is doing a drag gesture. There is some drift that can happen
      // between the initial [PointerDownEvent] and subsequent [PointerMoveEvent]s,
      // that drift is handled by the tap status tracker. Accessing [_TapStatusTracker.pastTapTolerance]
      // lets us know if our tap has moved past the acceptable tolerance. If the pointer
      // does not move past this tolerance than it is not considered a drag.
      //
      // To be recognized as a drag, the [PointerMoveEvent] must also have moved
      // a sufficient global distance from the initial [PointerDownEvent] to be
      // accepted as a drag. This logic is handled in [_hasSufficientGlobalDistanceToAccept].

      // If the buttons differ from the [PointerDownEvent]s buttons then stop tracking
      // the pointer.
      if (event.buttons != _initialButtons) {
        _giveUpPointer(event.pointer);
      }

      if (_dragState == _DragState.accepted) {
        _checkDragUpdate(event);
      } else if (_dragState == _DragState.possible) {
        _checkDrag(event);

        // This can occur when the recognizer is accepted before a [PointerMoveEvent] has been
        // received.
        if (_start != null && _wonArenaForPrimaryPointer) {
          _acceptDrag(_start!);
        }
      }
    } else if (event is PointerUpEvent) {
      if (_dragState == _DragState.possible) {
        // If a [PointerUpEvent] is tracked, and the recognizer has not won the arena, and the tap drift
        // has exceeded its tolerance, then reject this recognizer.
        if (pastTapTolerance) {
          _giveUpPointer(event.pointer);
          return;
        }
        // The drag has not been accepted before a [PointerUpEvent], therefore the recognizer
        // only registers a tap has occurred.
        stopTrackingIfPointerNoLongerDown(event);
      } else if (_dragState == _DragState.accepted) {
        _giveUpPointer(event.pointer);
      }
    } else if (event is PointerCancelEvent){
      _giveUpPointer(event.pointer);
    }
  }

  @override
  void rejectGesture(int pointer) {
    super.rejectGesture(pointer);
    if (pointer != _primaryPointer) {
      return;
    }

    _stopDeadlineTimer();
    _giveUpPointer(pointer);
    _resetTaps();
    _resetDragUpdateThrottle();
    _initialButtons = null;
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
    _checkTapCancel();
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
      if (event.buttons == kSecondaryButton) {
        // Reject a right click drag. It is possible that the recognizer may have
        // already won the arena at this point, if it did then the recognizer state
        // is cleared to prepare to track the next [PointerDownEvent].
        if (_wonArenaForPrimaryPointer) {
          _stopDeadlineTimer();
          _giveUpPointer(event.pointer);
          _resetTaps();
          _resetDragUpdateThrottle();
          _initialButtons = null;
        }
        resolve(GestureDisposition.rejected);
        return;
      }
      _start = event;
      _dragState = _DragState.accepted;
      resolve(GestureDisposition.accepted);
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

    switch (_initialButtons) {
      case kPrimaryButton:
        if (onTapDown != null) {
          invokeCallback('onTapDown', () => onTapDown!(details));
        }
        break;
      case kSecondaryButton:
        if (onSecondaryTapDown != null) {
          invokeCallback('onSecondaryTapDown', () => onSecondaryTapDown!(details));
        }
        break;
      default:
        assert(_initialButtons != null);
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

    switch (_initialButtons) {
      case kPrimaryButton:
        if (onTapUp != null) {
          invokeCallback('onTapUp', () => onTapUp!(upDetails));
        }
        break;
      case kSecondaryButton:
        if (onSecondaryTapUp != null) {
          invokeCallback('onSecondaryTapUp', () => onSecondaryTapUp!(upDetails));
        }
        if (onSecondaryTap != null) {
          invokeCallback<void>('onSecondaryTap', () => onSecondaryTap!());
        }
        break;
      default:
        assert(_initialButtons != null);
    }

    _resetTaps();
    if (!_acceptedActivePointers.remove(event.pointer)) {
      resolvePointer(event.pointer, GestureDisposition.rejected);
    }
    _initialButtons = null;
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

    invokeCallback<void>('onDragEnd', () => onDragEnd!(endDetails));

    _resetTaps();
    _resetDragUpdateThrottle();
  }

  void _checkCancel() {
    _checkTapCancel();
    _checkDragCancel();
    _resetTaps();
  }

  void _checkTapCancel() {
    if (!_sentTapDown) {
      // Do not fire tap cancel if [onTapDown] was never called.
      return;
    }
    switch (_initialButtons) {
      case kPrimaryButton:
        if (onTapCancel != null) {
          invokeCallback('onTapCancel', onTapCancel!);
        }
        break;
      case kSecondaryButton:
        if (onSecondaryTapCancel != null) {
          invokeCallback('onSecondaryTapCancel', onSecondaryTapCancel!);
        }
        break;
      default:
        assert(_initialButtons != null);
    }
  }

  void _checkDragCancel() {
    if (onDragCancel != null) {
      invokeCallback<void>('onDragCancel', onDragCancel!);
    }
    _resetDragUpdateThrottle();
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
  }

  void _resetDragUpdateThrottle() {
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
