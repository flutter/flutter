// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'arena.dart';
import 'constants.dart';
import 'drag_details.dart';
import 'events.dart';
import 'recognizer.dart';
import 'velocity_tracker.dart';

enum _DragState {
  ready,
  possible,
  accepted,
}

/// Signature for when a pointer that was previously in contact with the screen
/// and moving is no longer in contact with the screen.
///
/// The velocity at which the pointer was moving when it stopped contacting
/// the screen is available in the `details`.
///
/// See [DragGestureRecognizer.onEnd].
typedef GestureDragEndCallback = void Function(DragEndDetails details);

/// Signature for when the pointer that previously triggered a
/// [GestureDragDownCallback] did not complete.
///
/// See [DragGestureRecognizer.onCancel].
typedef GestureDragCancelCallback = void Function();

/// Recognizes movement.
///
/// In contrast to [MultiDragGestureRecognizer], [DragGestureRecognizer]
/// recognizes a single gesture sequence for all the pointers it watches, which
/// means that the recognizer has at most one drag sequence active at any given
/// time regardless of how many pointers are in contact with the screen.
///
/// [DragGestureRecognizer] is not intended to be used directly. Instead,
/// consider using one of its subclasses to recognize specific types for drag
/// gestures.
///
/// See also:
///
///  * [HorizontalDragGestureRecognizer], for left and right drags.
///  * [VerticalDragGestureRecognizer], for up and down drags.
///  * [PanGestureRecognizer], for drags that are not locked to a single axis.
abstract class DragGestureRecognizer extends OneSequenceGestureRecognizer {
  /// Initialize the object.
  ///
  /// [dragStartBehavior] must not be null.
  ///
  /// {@macro flutter.gestures.gestureRecognizer.kind}
  DragGestureRecognizer({
    Object debugOwner,
    PointerDeviceKind kind,
    this.dragStartBehavior = DragStartBehavior.start,
  }) : assert(dragStartBehavior != null),
       super(debugOwner: debugOwner, kind: kind);

  /// Configure the behavior of offsets sent to [onStart].
  ///
  /// If set to [DragStartBehavior.start], the [onStart] callback will be called at the time and
  /// position when the gesture detector wins the arena. If [DragStartBehavior.down],
  /// [onStart] will be called at the time and position when a down event was
  /// first detected.
  ///
  /// For more information about the gesture arena:
  /// https://flutter.dev/docs/development/ui/advanced/gestures#gesture-disambiguation
  ///
  /// By default, the drag start behavior is [DragStartBehavior.start].
  ///
  /// ## Example:
  ///
  /// A finger presses down on the screen with offset (500.0, 500.0),
  /// and then moves to position (510.0, 500.0) before winning the arena.
  /// With [dragStartBehavior] set to [DragStartBehavior.down], the [onStart]
  /// callback will be called at the time corresponding to the touch's position
  /// at (500.0, 500.0). If it is instead set to [DragStartBehavior.start],
  /// [onStart] will be called at the time corresponding to the touch's position
  /// at (510.0, 500.0).
  DragStartBehavior dragStartBehavior;

  /// A pointer has contacted the screen and might begin to move.
  ///
  /// The position of the pointer is provided in the callback's `details`
  /// argument, which is a [DragDownDetails] object.
  ///
  /// {@template flutter.dragGestureRecognizer.anyButton}
  /// It does not limit the button that triggers the drag. The callback should
  /// decide which call to respond to based on the detail data.
  ///
  /// The pointer is required to keep a consistent button throughout the
  /// gesture, i.e. subsequent [PointerMoveEvent]s must contain the same button
  /// as the first [PointerDownEvent].
  ///
  /// Also, it must contain one and only one button. For example, since a stylus
  /// touching the screen is also counted as a button, a stylus drag while
  /// pressing any physical button will not be recognized.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///  * [onDown], a similar callback limited to a primary button.
  ///  * [DragDownDetails], which is passed as an argument to this callback.
  GestureDragDownCallback onAnyDown;

  /// A pointer has contacted the screen and has begun to move.
  ///
  /// The position of the pointer is provided in the callback's `details`
  /// argument, which is a [DragStartDetails] object.
  ///
  /// Depending on the value of [dragStartBehavior], this function will be
  /// called on the initial touch down, if set to [DragStartBehavior.down] or
  /// when the drag gesture is first detected, if set to
  /// [DragStartBehavior.start].
  /// 
  /// {@macro flutter.dragGestureRecognizer.anyButton}
  ///
  /// See also:
  ///
  ///  * [onStart], a similar callback limited to a primary button.
  ///  * [DragStartDetails], which is passed as an argument to this callback.
  GestureDragStartCallback onAnyStart;

  /// A pointer that is in contact with the screen and moving has moved again.
  ///
  /// The distance travelled by the pointer since the last update is provided in
  /// the callback's `details` argument, which is a [DragUpdateDetails] object.
  /// 
  /// {@macro flutter.dragGestureRecognizer.anyButton}
  ///
  /// See also:
  ///
  ///  * [onUpdate], a similar callback limited to a primary button.
  ///  * [DragUpdateDetails], which is passed as an argument to this callback.
  GestureDragUpdateCallback onAnyUpdate;

  /// A pointer that was previously in contact with the screen and moving is no
  /// longer in contact with the screen and was moving at a specific velocity
  /// when it stopped contacting the screen.
  ///
  /// The velocity is provided in the callback's `details` argument, which is a
  /// [DragEndDetails] object.
  /// 
  /// {@macro flutter.dragGestureRecognizer.anyButton}
  ///
  /// See also:
  ///
  ///  * [onEnd], a similar callback limited to a primary button.
  ///  * [DragEndDetails], which is passed as an argument to this callback.
  GestureDragEndCallback onAnyEnd;

  /// The pointer that previously triggered [onAnyDown] did not complete.
  ///
  /// It does not send any details. However, it's guaranteed that [onAnyDown]
  /// is called before it, which can be used to determine the button of the
  /// canceled drag.
  ///
  /// See also:
  ///
  ///  * [onCancel], a similar callback limited to a primary button.
  GestureDragCancelCallback onAnyCancel;

  /// A pointer has contacted the screen with a primary button and might begin
  /// to move.
  ///
  /// The position of the pointer is provided in the callback's `details`
  /// argument, which is a [DragDownDetails] object.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onAnyDown], a similar callback but for any single button.
  ///  * [DragDownDetails], which is passed as an argument to this callback.
  GestureDragDownCallback onDown;

  /// A pointer has contacted the screen with a primary button and has begun to
  /// move.
  ///
  /// The position of the pointer is provided in the callback's `details`
  /// argument, which is a [DragStartDetails] object.
  ///
  /// Depending on the value of [dragStartBehavior], this function will be
  /// called on the initial touch down, if set to [DragStartBehavior.down] or
  /// when the drag gesture is first detected, if set to
  /// [DragStartBehavior.start].
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onAnyStart], a similar callback but for any single button.
  ///  * [DragStartDetails], which is passed as an argument to this callback.
  GestureDragStartCallback onStart;

  /// A pointer that is in contact with the screen with a primary button and
  /// moving has moved again.
  ///
  /// The distance travelled by the pointer since the last update is provided in
  /// the callback's `details` argument, which is a [DragUpdateDetails] object.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onAnyUpdate], a similar callback but for any single button.
  ///  * [DragUpdateDetails], which is passed as an argument to this callback.
  GestureDragUpdateCallback onUpdate;

  /// A pointer that was previously in contact with the screen with a primary 
  /// button and moving is no longer in contact with the screen and was moving
  /// at a specific velocity when it stopped contacting the screen.
  ///
  /// The velocity is provided in the callback's `details` argument, which is a
  /// [DragEndDetails] object.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onAnyEnd], a similar callback but for any single button.
  ///  * [DragEndDetails], which is passed as an argument to this callback.
  GestureDragEndCallback onEnd;

  /// The pointer that previously triggered [onDown] did not complete.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onAnyCancel], a similar callback but for any single button.
  GestureDragCancelCallback onCancel;

  /// The minimum distance an input pointer drag must have moved to
  /// to be considered a fling gesture.
  ///
  /// This value is typically compared with the distance traveled along the
  /// scrolling axis. If null then [kTouchSlop] is used.
  double minFlingDistance;

  /// The minimum velocity for an input pointer drag to be considered fling.
  ///
  /// This value is typically compared with the magnitude of fling gesture's
  /// velocity along the scrolling axis. If null then [kMinFlingVelocity]
  /// is used.
  double minFlingVelocity;

  /// Fling velocity magnitudes will be clamped to this value.
  ///
  /// If null then [kMaxFlingVelocity] is used.
  double maxFlingVelocity;

  _DragState _state = _DragState.ready;
  Offset _initialPosition;
  Offset _pendingDragOffset;
  Duration _lastPendingEventTimestamp;
  int _initialButtons;

  bool _isFlingGesture(VelocityEstimate estimate);
  Offset _getDeltaForDetails(Offset delta);
  double _getPrimaryValueFromOffset(Offset value);
  bool get _hasSufficientPendingDragDeltaToAccept;

  final Map<int, VelocityTracker> _velocityTrackers = <int, VelocityTracker>{};

  @override
  bool isPointerAllowed(PointerEvent event) {
    if (_initialButtons == null) {
      if (!isSingleButton(event.buttons)) {
        return false;
      }
    } else {
      if (event.buttons != _initialButtons) {
        return false;
      }
    }
    return super.isPointerAllowed(event);
  }

  @override
  void addAllowedPointer(PointerEvent event) {
    startTrackingPointer(event.pointer);
    _velocityTrackers[event.pointer] = VelocityTracker();
    if (_state == _DragState.ready) {
      _state = _DragState.possible;
      _initialPosition = event.position;
      _initialButtons = event.buttons;
      _pendingDragOffset = Offset.zero;
      _lastPendingEventTimestamp = event.timeStamp;
      _checkDown();
    } else if (_state == _DragState.accepted) {
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    assert(_state != _DragState.ready);
    if (!event.synthesized
        && (event is PointerDownEvent || event is PointerMoveEvent)) {
      final VelocityTracker tracker = _velocityTrackers[event.pointer];
      assert(tracker != null);
      tracker.addPosition(event.timeStamp, event.position);
    }

    if (event is PointerMoveEvent) {
      if (event.buttons != _initialButtons) {
        resolve(GestureDisposition.rejected);
        stopTrackingPointer(event.pointer);
        return;
      }
      final Offset delta = event.delta;
      if (_state == _DragState.accepted) {
        _checkUpdate(
          sourceTimeStamp: event.timeStamp,
          delta: _getDeltaForDetails(delta),
          primaryDelta: _getPrimaryValueFromOffset(delta),
          globalPosition: event.position,
        );
      } else {
        _pendingDragOffset += delta;
        _lastPendingEventTimestamp = event.timeStamp;
        if (_hasSufficientPendingDragDeltaToAccept)
          resolve(GestureDisposition.accepted);
      }
    }
    stopTrackingIfPointerNoLongerDown(event);
  }

  @override
  void acceptGesture(int pointer) {
    if (_state != _DragState.accepted) {
      _state = _DragState.accepted;
      final Offset delta = _pendingDragOffset;
      final Duration timestamp = _lastPendingEventTimestamp;
      Offset updateDelta;
      switch (dragStartBehavior) {
        case DragStartBehavior.start:
          _initialPosition = _initialPosition + delta;
          updateDelta = Offset.zero;
          break;
        case DragStartBehavior.down:
          updateDelta = _getDeltaForDetails(delta);
          break;
      }
      _pendingDragOffset = Offset.zero;
      _lastPendingEventTimestamp = null;
      _checkStart(timestamp);
      if (updateDelta != Offset.zero) {
        _checkUpdate(
          sourceTimeStamp: timestamp,
          delta: updateDelta,
          primaryDelta: _getPrimaryValueFromOffset(updateDelta),
          globalPosition: _initialPosition + updateDelta, // Only adds delta for down behaviour
        );
      }
    }
  }

  @override
  void rejectGesture(int pointer) {
    stopTrackingPointer(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    assert(_state != _DragState.ready);
    switch(_state) {
      case _DragState.ready:
        break;

      case _DragState.possible:
        resolve(GestureDisposition.rejected);
        _checkCancel();
        break;

      case _DragState.accepted:
        _checkEnd(pointer);
        break;
    }
    _velocityTrackers.clear();
    _initialButtons = null;
    _state = _DragState.ready;
  }

  void _checkDown() {
    final DragDownDetails details = DragDownDetails(
      globalPosition: _initialPosition,
      buttons: _initialButtons,
    );
    if (onAnyDown != null)
      invokeCallback<void>('onAnyDown', () => onAnyDown(details));
    switch (_initialButtons) {
      case kPrimaryButton:
        if (onDown != null)
          invokeCallback<void>('onDown', () => onDown(details));
        break;
      default:
    }
  }

  void _checkStart(Duration timestamp) {
    final DragStartDetails details = DragStartDetails(
      sourceTimeStamp: timestamp,
      globalPosition: _initialPosition,
      buttons: _initialButtons,
    );
    if (onAnyStart != null)
      invokeCallback<void>('onAnyStart', () => onAnyStart(details));
    switch (_initialButtons) {
      case kPrimaryButton:
        if (onStart != null)
          invokeCallback<void>('onStart', () => onStart(details));
        break;
      default:
    }
  }

  void _checkUpdate({
    Duration sourceTimeStamp,
    Offset delta,
    double primaryDelta,
    Offset globalPosition,
  }) {
    final DragUpdateDetails details = DragUpdateDetails(
      sourceTimeStamp: sourceTimeStamp,
      delta: delta,
      primaryDelta: primaryDelta,
      globalPosition: globalPosition,
      buttons: _initialButtons,
    );
    if (onAnyUpdate != null)
      invokeCallback<void>('onAnyUpdate', () => onAnyUpdate(details));
    switch (_initialButtons) {
      case kPrimaryButton:
        if (onUpdate != null)
          invokeCallback<void>('onUpdate', () => onUpdate(details));
        break;
      default:
    }
  }

  void _checkEnd(int pointer) {
    final VelocityTracker tracker = _velocityTrackers[pointer];
    assert(tracker != null);

    DragEndDetails details;
    void Function() debugReport;

    final VelocityEstimate estimate = tracker.getVelocityEstimate();
    if (estimate != null && _isFlingGesture(estimate)) {
      final Velocity velocity = Velocity(pixelsPerSecond: estimate.pixelsPerSecond)
        .clampMagnitude(minFlingVelocity ?? kMinFlingVelocity, maxFlingVelocity ?? kMaxFlingVelocity);
      details = DragEndDetails(
        velocity: velocity,
        primaryVelocity: _getPrimaryValueFromOffset(velocity.pixelsPerSecond),
        buttons: _initialButtons,
      );
      debugReport = () {
        return '$estimate; fling at $velocity.';
      };
    } else {
      details = DragEndDetails(
        velocity: Velocity.zero,
        primaryVelocity: 0.0,
        buttons: _initialButtons,
      );
      debugReport = () {
        if (estimate == null)
          return 'Could not estimate velocity.';
        return '$estimate; judged to not be a fling.';
      };
    }
    if (onAnyEnd != null)
      invokeCallback<void>('onAnyEnd', () => onAnyEnd(details), debugReport: debugReport);
    switch (_initialButtons) {
      case kPrimaryButton:
        if (onEnd != null)
          invokeCallback<void>('onEnd', () => onEnd(details), debugReport: debugReport);
        break;
      default:
    }
  }

  void _checkCancel() {
    if (onAnyCancel != null)
      invokeCallback<void>('onAnyCancel', onAnyCancel);
    switch (_initialButtons) {
      case kPrimaryButton:
        if (onCancel != null)
          invokeCallback<void>('onCancel', onCancel);
        break;
      default:
    }
  }

  @override
  void dispose() {
    _velocityTrackers.clear();
    super.dispose();
  }
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<DragStartBehavior>('start behavior', dragStartBehavior));
  }
}

/// Recognizes movement in the vertical direction.
///
/// Used for vertical scrolling.
///
/// See also:
///
///  * [HorizontalDragGestureRecognizer], for a similar recognizer but for
///    horizontal movement.
///  * [MultiDragGestureRecognizer], for a family of gesture recognizers that
///    track each touch point independently.
class VerticalDragGestureRecognizer extends DragGestureRecognizer {
  /// Create a gesture recognizer for interactions in the vertical axis.
  ///
  /// {@macro flutter.gestures.gestureRecognizer.kind}
  VerticalDragGestureRecognizer({
    Object debugOwner,
    PointerDeviceKind kind,
  }) : super(debugOwner: debugOwner, kind: kind);

  @override
  bool _isFlingGesture(VelocityEstimate estimate) {
    final double minVelocity = minFlingVelocity ?? kMinFlingVelocity;
    final double minDistance = minFlingDistance ?? kTouchSlop;
    return estimate.pixelsPerSecond.dy.abs() > minVelocity && estimate.offset.dy.abs() > minDistance;
  }

  @override
  bool get _hasSufficientPendingDragDeltaToAccept => _pendingDragOffset.dy.abs() > kTouchSlop;

  @override
  Offset _getDeltaForDetails(Offset delta) => Offset(0.0, delta.dy);

  @override
  double _getPrimaryValueFromOffset(Offset value) => value.dy;

  @override
  String get debugDescription => 'vertical drag';
}

/// Recognizes movement in the horizontal direction.
///
/// Used for horizontal scrolling.
///
/// See also:
///
///  * [VerticalDragGestureRecognizer], for a similar recognizer but for
///    vertical movement.
///  * [MultiDragGestureRecognizer], for a family of gesture recognizers that
///    track each touch point independently.
class HorizontalDragGestureRecognizer extends DragGestureRecognizer {
  /// Create a gesture recognizer for interactions in the horizontal axis.
  ///
  /// {@macro flutter.gestures.gestureRecognizer.kind}
  HorizontalDragGestureRecognizer({
    Object debugOwner,
    PointerDeviceKind kind,
  }) : super(debugOwner: debugOwner, kind: kind);

  @override
  bool _isFlingGesture(VelocityEstimate estimate) {
    final double minVelocity = minFlingVelocity ?? kMinFlingVelocity;
    final double minDistance = minFlingDistance ?? kTouchSlop;
    return estimate.pixelsPerSecond.dx.abs() > minVelocity && estimate.offset.dx.abs() > minDistance;
  }

  @override
  bool get _hasSufficientPendingDragDeltaToAccept => _pendingDragOffset.dx.abs() > kTouchSlop;

  @override
  Offset _getDeltaForDetails(Offset delta) => Offset(delta.dx, 0.0);

  @override
  double _getPrimaryValueFromOffset(Offset value) => value.dx;

  @override
  String get debugDescription => 'horizontal drag';
}

/// Recognizes movement both horizontally and vertically.
///
/// See also:
///
///  * [ImmediateMultiDragGestureRecognizer], for a similar recognizer that
///    tracks each touch point independently.
///  * [DelayedMultiDragGestureRecognizer], for a similar recognizer that
///    tracks each touch point independently, but that doesn't start until
///    some time has passed.
class PanGestureRecognizer extends DragGestureRecognizer {
  /// Create a gesture recognizer for tracking movement on a plane.
  PanGestureRecognizer({ Object debugOwner }) : super(debugOwner: debugOwner);

  @override
  bool _isFlingGesture(VelocityEstimate estimate) {
    final double minVelocity = minFlingVelocity ?? kMinFlingVelocity;
    final double minDistance = minFlingDistance ?? kTouchSlop;
    return estimate.pixelsPerSecond.distanceSquared > minVelocity * minVelocity
        && estimate.offset.distanceSquared > minDistance * minDistance;
  }

  @override
  bool get _hasSufficientPendingDragDeltaToAccept {
    return _pendingDragOffset.distance > kPanSlop;
  }

  @override
  Offset _getDeltaForDetails(Offset delta) => delta;

  @override
  double _getPrimaryValueFromOffset(Offset value) => null;

  @override
  String get debugDescription => 'pan';
}
