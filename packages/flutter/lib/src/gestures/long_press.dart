// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'arena.dart';
import 'constants.dart';
import 'events.dart';
import 'recognizer.dart';
import 'velocity_tracker.dart';

/// Callback signature for [LongPressGestureRecognizer.onLongPress].
///
/// Called when a pointer has remained in contact with the screen at the
/// same location for a long period of time.
typedef GestureLongPressCallback = void Function();

/// Callback signature for [LongPressGestureRecognizer.onLongPressUp].
///
/// Called when a pointer stops contacting the screen after a long press
/// gesture was detected.
typedef GestureLongPressUpCallback = void Function();

/// Callback signature for [LongPressGestureRecognizer.onLongPressStart].
///
/// Called when a pointer has remained in contact with the screen at the
/// same location for a long period of time. Also reports the long press down
/// position.
typedef GestureLongPressStartCallback = void Function(LongPressStartDetails details);

/// Callback signature for [LongPressGestureRecognizer.onLongPressMoveUpdate].
///
/// Called when a pointer is moving after being held in contact at the same
/// location for a long period of time. Reports the new position and its offset
/// from the original down position.
typedef GestureLongPressMoveUpdateCallback = void Function(LongPressMoveUpdateDetails details);

/// Callback signature for [LongPressGestureRecognizer.onLongPressEnd].
///
/// Called when a pointer stops contacting the screen after a long press
/// gesture was detected. Also reports the position where the pointer stopped
/// contacting the screen.
typedef GestureLongPressEndCallback = void Function(LongPressEndDetails details);

/// Details for callbacks that use [GestureLongPressStartCallback].
///
/// See also:
///
///  * [LongPressGestureRecognizer.onLongPressStart], which uses [GestureLongPressStartCallback].
///  * [LongPressMoveUpdateDetails], the details for [GestureLongPressMoveUpdateCallback]
///  * [LongPressEndDetails], the details for [GestureLongPressEndCallback].
class LongPressStartDetails {
  /// Creates the details for a [GestureLongPressStartCallback].
  ///
  /// The [globalPosition] argument must not be null.
  const LongPressStartDetails({
    this.globalPosition = Offset.zero,
    Offset? localPosition,
  }) : assert(globalPosition != null),
       localPosition = localPosition ?? globalPosition;

  /// The global position at which the pointer contacted the screen.
  final Offset globalPosition;

  /// The local position at which the pointer contacted the screen.
  final Offset localPosition;
}

/// Details for callbacks that use [GestureLongPressMoveUpdateCallback].
///
/// See also:
///
///  * [LongPressGestureRecognizer.onLongPressMoveUpdate], which uses [GestureLongPressMoveUpdateCallback].
///  * [LongPressEndDetails], the details for [GestureLongPressEndCallback]
///  * [LongPressStartDetails], the details for [GestureLongPressStartCallback].
class LongPressMoveUpdateDetails {
  /// Creates the details for a [GestureLongPressMoveUpdateCallback].
  ///
  /// The [globalPosition] and [offsetFromOrigin] arguments must not be null.
  const LongPressMoveUpdateDetails({
    this.globalPosition = Offset.zero,
    Offset? localPosition,
    this.offsetFromOrigin = Offset.zero,
    Offset? localOffsetFromOrigin,
  }) : assert(globalPosition != null),
       assert(offsetFromOrigin != null),
       localPosition = localPosition ?? globalPosition,
       localOffsetFromOrigin = localOffsetFromOrigin ?? offsetFromOrigin;

  /// The global position of the pointer when it triggered this update.
  final Offset globalPosition;

  /// The local position of the pointer when it triggered this update.
  final Offset localPosition;

  /// A delta offset from the point where the long press drag initially contacted
  /// the screen to the point where the pointer is currently located (the
  /// present [globalPosition]) when this callback is triggered.
  final Offset offsetFromOrigin;

  /// A local delta offset from the point where the long press drag initially contacted
  /// the screen to the point where the pointer is currently located (the
  /// present [localPosition]) when this callback is triggered.
  final Offset localOffsetFromOrigin;
}

/// Details for callbacks that use [GestureLongPressEndCallback].
///
/// See also:
///
///  * [LongPressGestureRecognizer.onLongPressEnd], which uses [GestureLongPressEndCallback].
///  * [LongPressMoveUpdateDetails], the details for [GestureLongPressMoveUpdateCallback]
///  * [LongPressStartDetails], the details for [GestureLongPressStartCallback].
class LongPressEndDetails {
  /// Creates the details for a [GestureLongPressEndCallback].
  ///
  /// The [globalPosition] argument must not be null.
  const LongPressEndDetails({
    this.globalPosition = Offset.zero,
    Offset? localPosition,
    this.velocity = Velocity.zero,
  }) : assert(globalPosition != null),
       localPosition = localPosition ?? globalPosition;

  /// The global position at which the pointer lifted from the screen.
  final Offset globalPosition;

  /// The local position at which the pointer contacted the screen.
  final Offset localPosition;

  /// The pointer's velocity when it stopped contacting the screen.
  ///
  /// Defaults to zero if not specified in the constructor.
  final Velocity velocity;
}

/// Recognizes when the user has pressed down at the same location for a long
/// period of time.
///
/// The gesture must not deviate in position from its touch down point for 500ms
/// until it's recognized. Once the gesture is accepted, the finger can be
/// moved, triggering [onLongPressMoveUpdate] callbacks, unless the
/// [postAcceptSlopTolerance] constructor argument is specified.
///
/// [LongPressGestureRecognizer] may compete on pointer events of
/// [kPrimaryButton], [kSecondaryButton], and/or [kTertiaryButton] if at least
/// one corresponding callback is non-null. If it has no callbacks, it is a no-op.
class LongPressGestureRecognizer extends PrimaryPointerGestureRecognizer {
  /// Creates a long-press gesture recognizer.
  ///
  /// Consider assigning the [onLongPressStart] callback after creating this
  /// object.
  ///
  /// The [postAcceptSlopTolerance] argument can be used to specify a maximum
  /// allowed distance for the gesture to deviate from the starting point once
  /// the long press has triggered. If the gesture deviates past that point,
  /// subsequent callbacks ([onLongPressMoveUpdate], [onLongPressUp],
  /// [onLongPressEnd]) will stop. Defaults to null, which means the gesture
  /// can be moved without limit once the long press is accepted.
  ///
  /// The [duration] argument can be used to overwrite the default duration
  /// after which the long press will be recognized.
  LongPressGestureRecognizer({
    Duration? duration,
    double? postAcceptSlopTolerance,
    PointerDeviceKind? kind,
    Object? debugOwner,
  }) : super(
          deadline: duration ?? kLongPressTimeout,
          postAcceptSlopTolerance: postAcceptSlopTolerance,
          kind: kind,
          debugOwner: debugOwner,
        );

  bool _longPressAccepted = false;
  OffsetPair? _longPressOrigin;
  // The buttons sent by `PointerDownEvent`. If a `PointerMoveEvent` comes with a
  // different set of buttons, the gesture is canceled.
  int? _initialButtons;

  /// Called when a long press gesture by a primary button has been recognized.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onLongPressStart], which has the same timing but has data for the
  ///    press location.
  GestureLongPressCallback? onLongPress;

  /// Called when a long press gesture by a primary button has been recognized.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onLongPress], which has the same timing but without details.
  ///  * [LongPressStartDetails], which is passed as an argument to this callback.
  GestureLongPressStartCallback? onLongPressStart;

  /// Called when moving after the long press by a primary button is recognized.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [LongPressMoveUpdateDetails], which is passed as an argument to this
  ///    callback.
  GestureLongPressMoveUpdateCallback? onLongPressMoveUpdate;

  /// Called when the pointer stops contacting the screen after a long-press
  /// by a primary button.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onLongPressEnd], which has the same timing but has data for the up
  ///    gesture location.
  GestureLongPressUpCallback? onLongPressUp;

  /// Called when the pointer stops contacting the screen after a long-press
  /// by a primary button.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onLongPressUp], which has the same timing, but without details.
  ///  * [LongPressEndDetails], which is passed as an argument to this
  ///    callback.
  GestureLongPressEndCallback? onLongPressEnd;

  /// Called when a long press gesture by a secondary button has been
  /// recognized.
  ///
  /// See also:
  ///
  ///  * [kSecondaryButton], the button this callback responds to.
  ///  * [onSecondaryLongPressStart], which has the same timing but has data for
  ///    the press location.
  GestureLongPressCallback? onSecondaryLongPress;

  /// Called when a long press gesture by a secondary button has been recognized.
  ///
  /// See also:
  ///
  ///  * [kSecondaryButton], the button this callback responds to.
  ///  * [onSecondaryLongPress], which has the same timing but without details.
  ///  * [LongPressStartDetails], which is passed as an argument to this
  ///    callback.
  GestureLongPressStartCallback? onSecondaryLongPressStart;

  /// Called when moving after the long press by a secondary button is
  /// recognized.
  ///
  /// See also:
  ///
  ///  * [kSecondaryButton], the button this callback responds to.
  ///  * [LongPressMoveUpdateDetails], which is passed as an argument to this
  ///    callback.
  GestureLongPressMoveUpdateCallback? onSecondaryLongPressMoveUpdate;

  /// Called when the pointer stops contacting the screen after a long-press by
  /// a secondary button.
  ///
  /// See also:
  ///
  ///  * [kSecondaryButton], the button this callback responds to.
  ///  * [onSecondaryLongPressEnd], which has the same timing but has data for
  ///    the up gesture location.
  GestureLongPressUpCallback? onSecondaryLongPressUp;

  /// Called when the pointer stops contacting the screen after a long-press by
  /// a secondary button.
  ///
  /// See also:
  ///
  ///  * [kSecondaryButton], the button this callback responds to.
  ///  * [onSecondaryLongPressUp], which has the same timing, but without
  ///    details.
  ///  * [LongPressEndDetails], which is passed as an argument to this callback.
  GestureLongPressEndCallback? onSecondaryLongPressEnd;

  /// Called when a long press gesture by a tertiary button has been
  /// recognized.
  ///
  /// See also:
  ///
  ///  * [kTertiaryButton], the button this callback responds to.
  ///  * [onTertiaryLongPressStart], which has the same timing but has data for
  ///    the press location.
  GestureLongPressCallback? onTertiaryLongPress;

  /// Called when a long press gesture by a tertiary button has been recognized.
  ///
  /// See also:
  ///
  ///  * [kTertiaryButton], the button this callback responds to.
  ///  * [onTertiaryLongPress], which has the same timing but without details.
  ///  * [LongPressStartDetails], which is passed as an argument to this
  ///    callback.
  GestureLongPressStartCallback? onTertiaryLongPressStart;

  /// Called when moving after the long press by a tertiary button is
  /// recognized.
  ///
  /// See also:
  ///
  ///  * [kTertiaryButton], the button this callback responds to.
  ///  * [LongPressMoveUpdateDetails], which is passed as an argument to this
  ///    callback.
  GestureLongPressMoveUpdateCallback? onTertiaryLongPressMoveUpdate;

  /// Called when the pointer stops contacting the screen after a long-press by
  /// a tertiary button.
  ///
  /// See also:
  ///
  ///  * [kTertiaryButton], the button this callback responds to.
  ///  * [onTertiaryLongPressEnd], which has the same timing but has data for
  ///    the up gesture location.
  GestureLongPressUpCallback? onTertiaryLongPressUp;

  /// Called when the pointer stops contacting the screen after a long-press by
  /// a tertiary button.
  ///
  /// See also:
  ///
  ///  * [kTertiaryButton], the button this callback responds to.
  ///  * [onTertiaryLongPressUp], which has the same timing, but without
  ///    details.
  ///  * [LongPressEndDetails], which is passed as an argument to this callback.
  GestureLongPressEndCallback? onTertiaryLongPressEnd;

  VelocityTracker? _velocityTracker;

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    switch (event.buttons) {
      case kPrimaryButton:
        if (onLongPressStart == null &&
            onLongPress == null &&
            onLongPressMoveUpdate == null &&
            onLongPressEnd == null &&
            onLongPressUp == null)
          return false;
        break;
      case kSecondaryButton:
        if (onSecondaryLongPressStart == null &&
            onSecondaryLongPress == null &&
            onSecondaryLongPressMoveUpdate == null &&
            onSecondaryLongPressEnd == null &&
            onSecondaryLongPressUp == null)
          return false;
        break;
      case kTertiaryButton:
        if (onTertiaryLongPressStart == null &&
            onTertiaryLongPress == null &&
            onTertiaryLongPressMoveUpdate == null &&
            onTertiaryLongPressEnd == null &&
            onTertiaryLongPressUp == null)
          return false;
        break;
      default:
        return false;
    }
    return super.isPointerAllowed(event);
  }

  @override
  void didExceedDeadline() {
    // Exceeding the deadline puts the gesture in the accepted state.
    resolve(GestureDisposition.accepted);
    _longPressAccepted = true;
    super.acceptGesture(primaryPointer!);
    _checkLongPressStart();
  }

  @override
  void handlePrimaryPointer(PointerEvent event) {
    if (!event.synthesized) {
      if (event is PointerDownEvent) {
        _velocityTracker = VelocityTracker.withKind(event.kind);
        _velocityTracker!.addPosition(event.timeStamp, event.localPosition);
      }
      if (event is PointerMoveEvent) {
        assert(_velocityTracker != null);
        _velocityTracker!.addPosition(event.timeStamp, event.localPosition);
      }
    }

    if (event is PointerUpEvent) {
      if (_longPressAccepted == true) {
        _checkLongPressEnd(event);
      } else {
        // Pointer is lifted before timeout.
        resolve(GestureDisposition.rejected);
      }
      _reset();
    } else if (event is PointerCancelEvent) {
      _reset();
    } else if (event is PointerDownEvent) {
      // The first touch.
      _longPressOrigin = OffsetPair.fromEventPosition(event);
      _initialButtons = event.buttons;
    } else if (event is PointerMoveEvent) {
      if (event.buttons != _initialButtons) {
        resolve(GestureDisposition.rejected);
        stopTrackingPointer(primaryPointer!);
      } else if (_longPressAccepted) {
        _checkLongPressMoveUpdate(event);
      }
    }
  }

  void _checkLongPressStart() {
    switch (_initialButtons) {
      case kPrimaryButton:
        if (onLongPressStart != null) {
          final LongPressStartDetails details = LongPressStartDetails(
            globalPosition: _longPressOrigin!.global,
            localPosition: _longPressOrigin!.local,
          );
          invokeCallback<void>('onLongPressStart', () => onLongPressStart!(details));
        }
        if (onLongPress != null) {
          invokeCallback<void>('onLongPress', onLongPress!);
        }
        break;
      case kSecondaryButton:
        if (onSecondaryLongPressStart != null) {
          final LongPressStartDetails details = LongPressStartDetails(
            globalPosition: _longPressOrigin!.global,
            localPosition: _longPressOrigin!.local,
          );
          invokeCallback<void>(
              'onSecondaryLongPressStart', () => onSecondaryLongPressStart!(details));
        }
        if (onSecondaryLongPress != null) {
          invokeCallback<void>('onSecondaryLongPress', onSecondaryLongPress!);
        }
        break;
      case kTertiaryButton:
        if (onTertiaryLongPressStart != null) {
          final LongPressStartDetails details = LongPressStartDetails(
            globalPosition: _longPressOrigin!.global,
            localPosition: _longPressOrigin!.local,
          );
          invokeCallback<void>(
              'onTertiaryLongPressStart', () => onTertiaryLongPressStart!(details));
        }
        if (onTertiaryLongPress != null) {
          invokeCallback<void>('onTertiaryLongPress', onTertiaryLongPress!);
        }
        break;
      default:
        assert(false, 'Unhandled button $_initialButtons');
    }
  }

  void _checkLongPressMoveUpdate(PointerEvent event) {
    final LongPressMoveUpdateDetails details = LongPressMoveUpdateDetails(
      globalPosition: event.position,
      localPosition: event.localPosition,
      offsetFromOrigin: event.position - _longPressOrigin!.global,
      localOffsetFromOrigin: event.localPosition - _longPressOrigin!.local,
    );
    switch (_initialButtons) {
      case kPrimaryButton:
        if (onLongPressMoveUpdate != null) {
          invokeCallback<void>('onLongPressMoveUpdate',
            () => onLongPressMoveUpdate!(details));
        }
        break;
      case kSecondaryButton:
        if (onSecondaryLongPressMoveUpdate != null) {
          invokeCallback<void>('onSecondaryLongPressMoveUpdate',
            () => onSecondaryLongPressMoveUpdate!(details));
        }
        break;
      case kTertiaryButton:
        if (onTertiaryLongPressMoveUpdate != null) {
          invokeCallback<void>('onTertiaryLongPressMoveUpdate',
                  () => onTertiaryLongPressMoveUpdate!(details));
        }
        break;
      default:
        assert(false, 'Unhandled button $_initialButtons');
    }
  }

  void _checkLongPressEnd(PointerEvent event) {
    final VelocityEstimate? estimate = _velocityTracker!.getVelocityEstimate();
    final Velocity velocity = estimate == null
        ? Velocity.zero
        : Velocity(pixelsPerSecond: estimate.pixelsPerSecond);
    final LongPressEndDetails details = LongPressEndDetails(
      globalPosition: event.position,
      localPosition: event.localPosition,
      velocity: velocity,
    );

    _velocityTracker = null;
    switch (_initialButtons) {
      case kPrimaryButton:
        if (onLongPressEnd != null) {
          invokeCallback<void>('onLongPressEnd', () => onLongPressEnd!(details));
        }
        if (onLongPressUp != null) {
          invokeCallback<void>('onLongPressUp', onLongPressUp!);
        }
        break;
      case kSecondaryButton:
        if (onSecondaryLongPressEnd != null) {
          invokeCallback<void>('onSecondaryLongPressEnd', () => onSecondaryLongPressEnd!(details));
        }
        if (onSecondaryLongPressUp != null) {
          invokeCallback<void>('onSecondaryLongPressUp', onSecondaryLongPressUp!);
        }
        break;
      case kTertiaryButton:
        if (onTertiaryLongPressEnd != null) {
          invokeCallback<void>('onTertiaryLongPressEnd', () => onTertiaryLongPressEnd!(details));
        }
        if (onTertiaryLongPressUp != null) {
          invokeCallback<void>('onTertiaryLongPressUp', onTertiaryLongPressUp!);
        }
        break;
      default:
        assert(false, 'Unhandled button $_initialButtons');
    }
  }

  void _reset() {
    _longPressAccepted = false;
    _longPressOrigin = null;
    _initialButtons = null;
    _velocityTracker = null;
  }

  @override
  void resolve(GestureDisposition disposition) {
    if (_longPressAccepted && disposition == GestureDisposition.rejected) {
      // This can happen if the gesture has been canceled. For example when
      // the buttons have changed.
      _reset();
    }
    super.resolve(disposition);
  }

  @override
  void acceptGesture(int pointer) {
    // Winning the arena isn't important here since it may happen from a sweep.
    // Explicitly exceeding the deadline puts the gesture in accepted state.
  }

  @override
  String get debugDescription => 'long press';
}
