// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart' show HardwareKeyboard, LogicalKeyboardKey;

enum _DragState {
  ready,
  possible,
  accepted,
}

/// {@macro flutter.gestures.tap.GestureTapDownCallback}
///
/// The consecutive tap count at the time the pointer contacted the screen is given by [TapDragDownDetails.consecutiveTapCount].
///
/// Used by [TapAndDragGestureRecognizer.onTapDown].
typedef GestureTapDragDownCallback  = void Function(TapDragDownDetails details);

/// Details for [GestureTapDragDownCallback], such as the tap count within
/// the series.
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
/// The consecutive tap count at the time the pointer contacted the screen is given by [TapDragUpDetails.consecutiveTapCount].
///
/// Used by [TapAndDragGestureRecognizer.onTapUp].
typedef GestureTapDragUpCallback  = void Function(TapDragUpDetails details);

/// Details for [GestureTapDragUpCallback], such as the tap count within
/// the series.
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
/// The consecutive tap count when the drag was initiated is given by [TapDragStartDetails.consecutiveTapCount].
///
/// Used by [TapAndDragGestureRecognizer.onStart].
typedef GestureTapDragStartCallback = void Function(TapDragStartDetails details);

/// Details for [GestureTapDragStartCallback], such as the tap count within
/// the series.
///
/// See also:
///
///  * [TapAndDragGestureRecognizer], which passes this information to its
///    [TapAndDragGestureRecognizer.onStart] callback.
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
/// The consecutive tap count when the drag was initiated is given by [TapDragUpdateDetails.consecutiveTapCount].
///
/// Used by [TapAndDragGestureRecognizer.onUpdate].
typedef GestureTapDragUpdateCallback = void Function(TapDragUpdateDetails details);

/// Details for [GestureTapDragUpdateCallback], such as the tap count within
/// the series.
///
/// See also:
///
///  * [TapAndDragGestureRecognizer], which passes this information to its
///    [TapAndDragGestureRecognizer.onUpdate] callback.
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
/// The consecutive tap count when the drag was initiated is given by [TapDragEndDetails.consecutiveTapCount].
///
/// Used by [TapAndDragGestureRecognizer.onEnd].
typedef GestureTapDragEndCallback = void Function(TapDragEndDetails endDetails);

/// Details for [GestureTapDragEndCallback], such as the tap count within
/// the series.
///
/// See also:
///
///  * [TapAndDragGestureRecognizer], which passes this information to its
///    [TapAndDragGestureRecognizer.onEnd] callback.
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
// that occur in a series of [PointerEvent]'s and the most recent set of
// [LogicalKeyboardKey]'s pressed on the most recent tap down.
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
  // This value will be null if we have not yet tracked a [PointerDownEvent] in
  // [addAllowedPointer] or the timer between two taps has elapsed.
  //
  // This value is only reset when the timer between a [PointerUpEvent] and the
  // [PointerDownEvent] times out or when we track a new [PointerDownEvent] in
  // [addAllowedPointer].
  PointerDownEvent? get currentDown => _down;
  // The [PointerUpEvent] that was most recently tracked in [handleEvent].
  //
  // This value will be null if we have not yet tracked a [PointerUpEvent] in
  // [handleEvent] or the timer between two taps has elapsed.
  //
  // This value is only reset when the timer between a [PointerUpEvent] and the
  // [PointerDownEvent] times out or when we track a new [PointerDownEvent] in
  // [addAllowedPointer].
  PointerUpEvent? get currentUp => _up;
  // The number of consecutive taps that the most recently tracked [PointerDownEvent]
  // in [currentDown] represents.
  //
  // This value defaults to zero, which means we are not currently tracking
  // a series of taps.
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
  // The set of [LogicalKeyboardKey]'s pressed when the most recent [PointerDownEvent]
  // was tracked in [addAllowedPointer].
  //
  // This value defaults to an empty set.
  //
  // When the timer between two taps elapses, the recognizer loses the arena, the gesture is cancelled
  // or the recognizer is disposed of then this value is reset.
  Set<LogicalKeyboardKey> get keysPressedOnDown => _keysPressedOnDown ?? <LogicalKeyboardKey>{};
  // Whether the tap drifted past the tolerance defined by [kDoubleTapTouchSlop] in any subsequent
  // tracked [PointerMoveEvent]'s.
  //
  // This value default to false.
  //
  // If the tap does drift past the tolerance then we reset all of the tracked state except
  // the [currentDown], [currentUp], [consecutiveTapCount], and [keysPressedOnDown]. This is because
  // the [OneSequenceGestureRecognizer] may be handling a gesture that does accept a tap drift past
  // the tolerance defined by [kDoubleTapTouchSlop], such as a drag, so it may still want access
  // to the tracked tap state.
  bool get pastTapTolerance => _pastTapTolerance;
  // The upper limit for the [consecutiveTapCount]. When this limit is reached
  // all tap related state is reset and a new tap series is tracked.
  //
  // If this value is null, [consecutiveTapCount] can grow infinitely large.
  int? get upperLimit;

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

  // When we start to track a tap, we can choose to increment the [consecutiveTapCount]
  // if the given tap falls under the tolerance specifications or we can reset the count to 1.
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    if (upperLimit != null && upperLimit == _consecutiveTapCount) {
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
/// Takes on the responsibilities of [TapGestureRecognizer] and [DragGestureRecognizer] in one [GestureRecognizer].
class TapAndDragGestureRecognizer extends OneSequenceGestureRecognizer with _TapStatusTrackerMixin {
  /// Initialize the object.
  ///
  /// [dragStartBehavior] must not be null.
  ///
  /// {@macro flutter.gestures.GestureRecognizer.supportedDevices}
  TapAndDragGestureRecognizer({
    this.deadline = kPressTimeout,
    this.dragStartBehavior = DragStartBehavior.start,
    this.dragUpdateThrottleFrequency,
    this.upperLimit,
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

  /// {@macro flutter.gestures.monodrag.DragGestureRecognizer.dragStartBehavior}
  DragStartBehavior dragStartBehavior;

  /// The frequency at which the [onUpdate] callback is called.
  ///
  /// The value defaults to null, meaning there is no delay for [onUpdate] callback.
  Duration? dragUpdateThrottleFrequency;

  /// An upper bound for the amount of taps that can belong to one series.
  ///
  /// When this limit is reached the series of taps being tracked by this
  /// recognizer will be reset.
  @override
  int? upperLimit;

  /// {@macro flutter.gestures.tap.TapGestureRecognizer.onTapDown}
  ///
  /// {@template flutter.gestures.selectionrecognizers.TapAndDragGestureRecognizer.tapStatus}
  /// The number of consecutive taps, and the keys that were pressed on tap down
  /// are provided in the callback's `details` argument.
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
  /// {@macro flutter.gestures.selectionrecognizers.TapAndDragGestureRecognizer.tapStatus}
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
  /// {@macro flutter.gestures.selectionrecognizers.TapAndDragGestureRecognizer.tapStatus}
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [TapDragStartDetails], which is passed as an argument to this callback.
  GestureTapDragStartCallback? onStart;

  /// {@macro flutter.gestures.monodrag.DragGestureRecognizer.onUpdate}
  ///
  /// {@macro flutter.gestures.selectionrecognizers.TapAndDragGestureRecognizer.tapStatus}
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [TapDragUpdateDetails], which is passed as an argument to this callback.
  GestureTapDragUpdateCallback? onUpdate;

  /// {@macro flutter.gestures.monodrag.DragGestureRecognizer.onEnd}
  ///
  /// {@macro flutter.gestures.selectionrecognizers.TapAndDragGestureRecognizer.tapStatus}
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [TapDragEndDetails], which is passed as an argument to this callback.
  GestureTapDragEndCallback? onEnd;

  /// The pointer that previously triggered [onTapDown] did not complete.
  ///
  /// This is called when we receive a [PointerUpEvent] before the recognizer has accepted
  /// the gesture as a drag. This can happen if none of the [PointerMoveEvent]`s received
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
  PointerMoveEvent? _start;
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
  // immediately. See [_checkEnd].
  void _handleDragUpdateThrottled() {
    assert(_lastDragUpdateDetails != null);
    if (onUpdate != null) {
      invokeCallback<void>('onUpdate', () => onUpdate!(_lastDragUpdateDetails!));
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
              onStart == null &&
              onUpdate == null &&
              onEnd == null &&
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
          resolve(GestureDisposition.rejected);
          _checkCancel();
          break;
        }
        if (pastTapTolerance) {
          // This means our pointer was not accepted as a tap nor a drag.
          // This can happen when a user drags on a right click, going past the
          // tap tolerance, and drag tolerance, but being rejected since a right click
          // drag is not allowed by this recognizer.
          resolve(GestureDisposition.rejected);
          _checkCancel();
        } else {
          _checkDragCancel();
          if (currentUp != null) {
            _checkTapUp(currentUp!);
          }
        }
        break;

      case _DragState.accepted:
        // We only arrive here, after the recognizer has accepted the [PointerEvent]
        // as a drag. Meaning [_checkTapDown], and [_checkStart] have already ran.
        _checkEnd();
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
      // between the initial [PointerDownEvent] and subsequent [PointerMoveEvent]`s,
      // that drift is handled by the tap status tracker. Accessing [_TapStatusTracker.pastTapTolerance]
      // lets us know if our tap has moved past the acceptable tolerance. If the pointer
      // does not move past this tolerance than it is not considered a drag.
      //
      // To be recognized as a drag, the [PointerMoveEvent] must also have moved
      // a sufficient global distance from the initial [PointerDownEvent] to be
      // accepted as a drag. This logic is handled in [_hasSufficientGlobalDistanceToAccept].

      // If the buttons differ from the [PointerDownEvent]`s buttons then we should stop tracking
      // the pointer.
      if (event.buttons != _initialButtons) {
        _giveUpPointer(event.pointer);
      }

      if (_dragState == _DragState.accepted) {
        _checkUpdate(event);
      } else if (_dragState == _DragState.possible) {
        _checkDrag(event);

        // We may arrive here if the recognizer is accepted before a [PointerMoveEvent] has been
        // received.
        if (_start != null && _wonArenaForPrimaryPointer) {
          _acceptDrag(_start!);
        }
      }
    } else if (event is PointerUpEvent) {
      if (_dragState == _DragState.possible) {
        // If we arrive at a [PointerUpEvent], and the recognizer has not won the arena, and the tap drift
        // has exceeded its tolerance, then we should reject this recognizer.
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

  void _acceptDrag(PointerMoveEvent event) {
    _checkTapCancel();
    if (dragStartBehavior == DragStartBehavior.start) {
      _initialPosition = _initialPosition + OffsetPair(global: event.delta, local: event.localDelta);
    }
    _checkStart(event);
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
      _checkUpdate(event);
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
        // already won the arena at this point, if it did then we should clear some
        // state to prepare to track the next [PointerDownEvent].
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
    }

    _resetTaps();
    if (!_acceptedActivePointers.remove(event.pointer)) {
      resolvePointer(event.pointer, GestureDisposition.rejected);
    }
    _initialButtons = null;
  }

  void _checkStart(PointerMoveEvent event) {
    if (onStart != null) {
      final TapDragStartDetails details = TapDragStartDetails(
        sourceTimeStamp: event.timeStamp,
        globalPosition: _initialPosition.global,
        localPosition: _initialPosition.local,
        kind: getKindForPointer(event.pointer),
        consecutiveTapCount: consecutiveTapCount,
        keysPressedOnDown: keysPressedOnDown,
      );

      invokeCallback<void>('onStart', () => onStart!(details));
    }

    _start = null;
  }

  void _checkUpdate(PointerMoveEvent event) {
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
      // Only schedule a new timer if there's no one pending.
      _dragUpdateThrottleTimer ??= Timer(dragUpdateThrottleFrequency!, _handleDragUpdateThrottled);
    } else {
      if (onUpdate != null) {
        invokeCallback<void>('onUpdate', () => onUpdate!(details));
      }
    }
  }

  void _checkEnd() {
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

    invokeCallback<void>('onEnd', () => onEnd!(endDetails));

    _resetTaps();
    _resetDragUpdateThrottle();
  }

  void _checkCancel() {
    _checkTapCancel();
    _checkDragCancel();
    _resetTaps();
  }

  void _checkTapCancel() {
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
        // then this recognizer should declare itself the winner to avoid the [LongPressGestureRecognizer]
        // from declaring itself the winner if a double tap is held for to long.
        resolve(GestureDisposition.accepted);
      }
    }
  }

  void _giveUpPointer(int pointer) {
    stopTrackingPointer(pointer);
    // If we never accepted the pointer, we reject it since we are no longer
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
