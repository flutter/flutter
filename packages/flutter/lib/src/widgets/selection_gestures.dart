// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart' show HardwareKeyboard, LogicalKeyboardKey;

enum _GestureState {
  ready,
  possible,
  accepted,
}

/// {@macro flutter.gestures.tap.GestureTapDownCallback}
///
/// The consecutive tap count at the time the pointer contacted the screen is given by [TapStatus.consecutiveTapCount].
///
/// Used by [TapAndDragGestureRecognizer.onTapDown].
typedef GestureTapDownWithTapStatusCallback  = void Function(TapDownDetails details, TapStatus status);

/// {@macro flutter.gestures.tap.GestureTapUpCallback}
///
/// The consecutive tap count at the time the pointer contacted the screen is given by [TapStatus.consecutiveTapCount].
///
/// Used by [TapAndDragGestureRecognizer.onTapUp].
typedef GestureTapUpWithTapStatusCallback  = void Function(TapUpDetails details, TapStatus status);

/// {@macro flutter.gestures.dragdetails.GestureDragStartCallback}
///
/// The consecutive tap count when the drag was initiated is given by [TapStatus.consecutiveTapCount].
///
/// Used by [TapAndDragGestureRecognizer.onStart].
typedef GestureDragStartWithTapStatusCallback = void Function(DragStartDetails details, TapStatus status);

/// {@macro flutter.gestures.dragdetails.GestureDragUpdateCallback}
///
/// The consecutive tap count when the drag was initiated is given by [TapStatus.consecutiveTapCount].
///
/// Used by [TapAndDragGestureRecognizer.onUpdate].
typedef GestureDragUpdateWithTapStatusCallback = void Function(DragUpdateDetails details, TapStatus status);

/// {@macro flutter.gestures.monodrag.GestureDragEndCallback}
///
/// The consecutive tap count when the drag was initiated is given by [TapStatus.consecutiveTapCount].
///
/// Used by [TapAndDragGestureRecognizer.onEnd].
typedef GestureDragEndWithTapStatusCallback = void Function(DragEndDetails endDetails, TapStatus status);

/// An object that includes supplementary details of a tap event, such as
/// the keys that were pressed when tap down occured, and what the tap count
/// is.
class TapStatus {
  /// Creates a [TapStatus].
  const TapStatus({
    required this.consecutiveTapCount,
    required this.keysPressedOnDown,
  });

  /// If this tap is in a series of taps, the `consecutiveTapCount` is
  /// what number in the series this tap is.
  final int consecutiveTapCount;

  /// The keys that were pressed when the most recent `PointerDownEvent` occurred.
  final Set<LogicalKeyboardKey> keysPressedOnDown;
}

// A mixin for [OneSequenceGestureRecognizer] that tracks the number of taps
// that occur in a series of [PointerEvent]'s and the most recent set of
// [LogicalKeyboardKey]'s pressed on the most recent tap down.
//
// A tap is tracked as part of a series of taps if:
//
// 1. The elapsed time between when a [PointerUpEvent] and the subsequent
// [PointerDownEvent] does not exceed `kDoubleTapTimeout`.
// 2. The delta between the position tapped in the global coordinate system
// and the position that was tapped previously must be less than or equal
// to `kDoubleTapSlop`.
// 3. The tap being tracked does not become a drag.
//
// This mixin's state, i.e. the series of taps being tracked is reset when 
// a tap is tracked that does not meet any of the specifications stated above.
mixin _TapStatusTrackerMixin on OneSequenceGestureRecognizer {
  // Public state available to [OneSequenceGestureRecognizer].
  PointerDownEvent? get currentDown => _down;
  PointerUpEvent? get currentUp => _up;
  int get consecutiveTapCount => _consecutiveTapCount;
  Set<LogicalKeyboardKey> get keysPressedOnDown => _keysPressedOnDown ?? <LogicalKeyboardKey>{};
  // bool get _pastTapTolerance => _pastTapTolerance;

  // Private tap state tracked.
  PointerDownEvent? _down;
  PointerUpEvent? _up;
  int _consecutiveTapCount = 0;
  Set<LogicalKeyboardKey>? _keysPressedOnDown;
  // bool _pastTapTolerance = false;

  // For timing taps.
  Timer? _consecutiveTapTimer;
  Offset? _lastTapOffset;

  int? _previousButtons;

  bool _wonArena = false;

  OffsetPair? _originPosition;

  @override
  void didStopTrackingLastPointer(int pointer) {
    _originPosition = null;
  }

  // When we start to track a tap, we can choose to increment the 
  // `consecutiveTapCount` if the given tap falls under the tolerance specifications
  // or we can reset the count to 1. 
  //
  // We should not reset the tap count due to a timeout because a drag may be occuring.
  // Hmm, but technically the timer should not be active during a drag so a timeout
  // should not be possible because the timer is cancelled on down and not resumed until
  // a PointerUpEvent is received. make sure of this.
  @override
  void addAllowedPointer(PointerDownEvent event) {
    print('tracking from mixin');
    _up = null;
    // _pastTapTolerance = false;
    _originPosition = OffsetPair(local: event.localPosition, global: event.position);
    if (_down != null && !_representsSameSeries(event)) {
      // The given tap does not match the specifications of the series of taps being tracked,
      // reset the tap count and related state.
      _consecutiveTapCount = 1;
      print('reset');
    } else {
      _consecutiveTapCount += 1;
      print('increment');
    }
    _consecutiveTapTimerStop();
    _trackTrap(event);

    // The super class is called once the `consecutiveTapCount` is updated,
    // so the [OneSequenceGestureRecognizer] has an accurate count. In this case
    // [BaseDragGestureRecognizer.addAllowedPointer] is called.
    super.addAllowedPointer(event);
  }

  @override
  void acceptGesture(int pointer) {
    super.acceptGesture(pointer);
    print('accept from mixin');
    _wonArena = true;
    if (_up != null && _down != null) {
      print('up');
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
    print('handle event from mixin');
    if (event is PointerMoveEvent) {
      final bool isPreAcceptSlopPastTolerance =
          !_wonArena &&
          _getGlobalDistance(event) > kTouchSlop!;
      final bool isPostAcceptSlopPastTolerance =
          _wonArena &&
          _getGlobalDistance(event) > kTouchSlop;
      
      if (isPreAcceptSlopPastTolerance || isPostAcceptSlopPastTolerance) {
        // _pastTapTolerance = true;
      }
    } else if (event is PointerUpEvent) {
      _up = event;
      if (_wonArena && _up != null && _down != null) {
        print('up from handle event mixin');
        _consecutiveTapTimerStop();
        _consecutiveTapTimerStart();
        _wonArena = false;
      }
    }
  }

  @override
  void rejectGesture(int pointer) {
    super.rejectGesture(pointer);
    _consecutiveTapTimerReset();
  }

  @override
  void dispose() {
    _consecutiveTapTimerReset();
    super.dispose();
  }
 
  void _trackTrap(PointerDownEvent event) {
    _down = event;
    _keysPressedOnDown = HardwareKeyboard.instance.logicalKeysPressed;
    _previousButtons = event.buttons;
    _lastTapOffset = event.position;
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
    print('start');
    _consecutiveTapTimer ??= Timer(kDoubleTapTimeout, _consecutiveTapTimerReset);
  }

  void _consecutiveTapTimerStop() {
    if (_consecutiveTapTimer != null) {
      print('stop');
      _consecutiveTapTimer!.cancel();
      _consecutiveTapTimer = null;
    } else {
      print('tried to stop');
    }
  }

  void _consecutiveTapTimerReset() {
    // The timer has timed out, i.e. the time between a [PointerUpEvent] and the subsequent
    // [PointerDownEvent] exceeded the duration of `kDoubleTapTimeout`, so the tap belonging
    // to the [PointerDownEvent] cannot be considered part of the same tap series as the
    // previous [PointerUpEvent].
    _consecutiveTapTimerStop();
    _previousButtons = null;
    _lastTapOffset = null;
    _consecutiveTapCount = 0;
    _keysPressedOnDown = null;
    _down = null;
    _up = null;
    print('timeout');
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
    this.preAcceptSlopTolerance = kTouchSlop,
    this.postAcceptSlopTolerance = kTouchSlop,
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

  /// {@macro flutter.gestures.recognizer.PrimaryPointerGestureRecognizer.preAcceptSlopTolerance}
  final double? preAcceptSlopTolerance;

  /// {@macro flutter.gestures.recognizer.PrimaryPointerGestureRecognizer.postAcceptSlopTolerance}
  final double? postAcceptSlopTolerance;

  /// {@macro flutter.gestures.tap.TapGestureRecognizer.onTapDown}
  ///
  /// {@template flutter.gestures.selectionrecognizers.TapAndDragGestureRecognizer.tapStatus}
  /// The number of consecutive taps, and the keys that were pressed on tap down
  /// are provided in the callback's `status` argument, which is a [TapStatus] object.
  /// {@endtemplate}
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onSecondaryTapDown], a similar callback but for a secondary button.
  ///  * [TapDownDetails], which is passed as an argument to this callback.
  ///  * [TapStatus], which is passed as an argument to this callback.
  GestureTapDownWithTapStatusCallback? onTapDown;

  /// {@macro flutter.gestures.tap.TapGestureRecognizer.onTapUp}
  ///
  /// {@macro flutter.gestures.selectionrecognizers.TapAndDragGestureRecognizer.tapStatus}
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [onSecondaryTapUp], a similar callback but for a secondary button.
  ///  * [TapUpDetails], which is passed as an argument to this callback.
  ///  * [TapStatus], which is passed as an argument to this callback.
  GestureTapUpWithTapStatusCallback? onTapUp;

  /// {@macro flutter.gestures.tap.TapGestureRecognizer.onTapCancel}
  ///
  /// This is called if a `PointerMoveEvent` has moved a sufficient global distance
  /// from the initial `PointerDownEvent` to be considered a drag.
  ///
  /// It may also be called if the pointer tracked is deemed neither a drag, nor a tap,
  /// due to it not meeting the global distance necessary to be considered a drag, and drifting
  /// too far from the initial `PointerDownEvent` to be considered a tap. In this case both [onTapCancel]
  /// and [onDragCancel] will be called.
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
  ///  * [TapDownDetails], which is passed as an argument to this callback.
  GestureTapDownCallback? onSecondaryTapDown;

  /// {@macro flutter.gestures.tap.TapGestureRecognizer.onSecondaryTapUp}
  ///
  /// See also:
  ///
  ///  * [onSecondaryTap], a handler triggered right after this one that doesn't
  ///    pass any details about the tap.
  ///  * [kSecondaryButton], the button this callback responds to.
  ///  * [onTapUp], a similar callback but for a primary button.
  ///  * [TapUpDetails], which is passed as an argument to this callback.
  GestureTapUpCallback? onSecondaryTapUp;

  /// {@macro flutter.gestures.monodrag.DragGestureRecognizer.onStart}
  ///
  /// {@macro flutter.gestures.selectionrecognizers.TapAndDragGestureRecognizer.tapStatus}
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [DragStartDetails], which is passed as an argument to this callback.
  ///  * [TapStatus], which is passed as an argument to this callback.
  GestureDragStartWithTapStatusCallback? onStart;

  /// {@macro flutter.gestures.monodrag.DragGestureRecognizer.onUpdate}
  ///
  /// {@macro flutter.gestures.selectionrecognizers.TapAndDragGestureRecognizer.tapStatus}
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [DragUpdateDetails], which is passed as an argument to this callback.
  ///  * [TapStatus], which is passed as an argument to this callback.
  GestureDragUpdateWithTapStatusCallback? onUpdate;

  /// {@macro flutter.gestures.monodrag.DragGestureRecognizer.onEnd}
  ///
  /// {@macro flutter.gestures.selectionrecognizers.TapAndDragGestureRecognizer.tapStatus}
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  ///  * [DragEndDetails], which is passed as an argument to this callback.
  ///  * [TapStatus], which is passed as an argument to this callback.
  GestureDragEndWithTapStatusCallback? onEnd;

  /// The pointer that previously triggered [onTapDown] did not complete.
  ///
  /// This is called when we receive a `PointerUpEvent` before the recognizer has accepted
  /// the gesture as a drag. This can happen if none of the `PointerMoveEvent`s received
  /// drift far enough to exceed the tap tolerance, and do not meet the global distance specifications
  /// to be considered a drag.
  ///
  /// It may also be called if the pointer tracked is deemed neither a drag, nor a tap,
  /// due to it not meeting the global distance necessary to be considered a drag, and drifting
  /// too far from the initial `PointerDownEvent` to be considered a tap. In this case both [onTapCancel]
  /// and [onDragCancel] will be called.
  ///
  /// See also:
  ///
  ///  * [kPrimaryButton], the button this callback responds to.
  GestureDragCancelCallback? onDragCancel;

  // Tap related state.
  bool _pastTapTolerance = false;
  bool _sentTapDown = false;
  bool _wonArenaForPrimaryPointer = false;

  /// Primary pointer being tracked by this recognizer.
  int? get primaryPointer => _primaryPointer;
  int? _primaryPointer;

  Timer? _deadlineTimer;

  // Drag related state.
  _GestureState _dragState = _GestureState.ready;
  PointerMoveEvent? _start;
  late OffsetPair _initialPosition;
  late double _globalDistanceMoved;
  OffsetPair? _correctedPosition;
  // For the local tap drag count.
  int? _consecutiveTapCountWhileDragging;

  // For drag update throttle.
  DragUpdateDetails? _lastDragUpdateDetails;
  Timer? _dragUpdateThrottleTimer;
  TapStatus? _lastDragTapStatus;

  // The buttons sent by `PointerDownEvent`. If a `PointerMoveEvent` comes with a
  // different set of buttons, the gesture is canceled.
  int? _initialButtons;

  final Set<int> _acceptedActivePointers = <int>{};

  bool _hasSufficientGlobalDistanceToAccept(PointerDeviceKind pointerDeviceKind, double? deviceTouchSlop) {
    return _globalDistanceMoved.abs() > computePanSlop(pointerDeviceKind, gestureSettings);
  }

  // Drag updates may require throttling to avoid excessive updating, such as for text layouts in text
  // fields. The frequency of invocations is controlled by the `dragUpdateThrottleFrequency`.
  //
  // Once the drag gesture ends, any pending drag update will be fired
  // immediately. See [_checkEnd].
  void _handleDragUpdateThrottled() {
    assert(_lastDragUpdateDetails != null);
    assert(_lastDragTapStatus != null);
    invokeCallback<void>('onUpdate', () => onUpdate!(_lastDragUpdateDetails!, _lastDragTapStatus!));
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

    // `_down` must be assigned in this method instead of `handleEvent`,
    // because `acceptGesture` might be called before `handleEvent`,
    // which relies on `_down` to call `checkTapDown`.
    if (_dragState == _GestureState.ready) {
      _globalDistanceMoved = 0.0;
      _initialButtons = event.buttons;
      _dragState = _GestureState.possible;
      _initialPosition = OffsetPair(global: event.position, local: event.localPosition);
    }
  }

  @override
  void acceptGesture(int pointer) {
    print('acceptGesture - recognizer');
    if (pointer != primaryPointer) {
      return;
    }

    _stopDeadlineTimer();

    assert(!_acceptedActivePointers.contains(pointer));
    _acceptedActivePointers.add(pointer);

    // Called when this recognizer is accepted by the `GestureArena`.
    if (currentDown != null) {
      print('send tap down - recognizer');
      _checkTapDown(currentDown!);
    }
    _wonArenaForPrimaryPointer = true;
    print('won arena recognizer');
    if (currentUp != null) {
      print('send tap up - recognizer');
      _checkTapUp(currentUp!);
    }

    // resolve(GestureDisposition.accepted) may be called when the `PointerMoveEvent` has
    // moved a sufficient global distance.
    if (_dragState == _GestureState.accepted) {
      if (_start != null) {
        _acceptDrag(_start!);
      }
    }

    super.acceptGesture(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    print('didstoptrackinglastpointer -recognizer $_dragState');
    switch (_dragState) {
      case _GestureState.ready:
        resolve(GestureDisposition.rejected);
        _checkCancel();
        break;

      case _GestureState.possible:
        if (_pastTapTolerance) {
          // This means our pointer was not accepted as a tap nor a drag.
          // This can happen when a user drags on a right click, going past the
          // tap tolerance, and drag tolerance, but being rejected since a right click
          // drag is not allowed by this recognizer.
          resolve(GestureDisposition.rejected);
          _checkCancel();
        } else {
          print('from up not null');
          _checkDragCancel();
          if (currentUp != null) {
            _checkTapUp(currentUp!);
          }
        }
        break;

      case _GestureState.accepted:
        // We only arrive here, after the recognizer has accepted the `PointerEvent`
        // as a drag. Meaning `_checkTapDown`, and `_checkStart` have already ran.
        _checkEnd();
        print('hello worldzaaaaaaaaaqaa');
        _initialButtons = null;
        break;
    }

    _stopDeadlineTimer();
    _dragState = _GestureState.ready;
    print('hehz-1');
    _pastTapTolerance = false;
    _consecutiveTapCountWhileDragging = null;
  }

  @override
  void handleEvent(PointerEvent event) {
    super.handleEvent(event);
    print('handle event - recognizer');
    if (event is PointerMoveEvent) {
      // Receiving a `PointerMoveEvent`, does not automatically mean the pointer
      // being tracked is doing a drag gesture. There is some drift that can happen
      // between the initial `PointerDownEvent` and subsequent `PointerMoveEvent`s,
      // that drift is calculated by the `isPreAcceptSlopPastTolerance`, and
      // `isPostAcceptSlopPastTolerance`. If the pointer does not move past this tolerance
      // than it is not considered a drag.
      //
      // To be recognized as a drag, the `PointerMoveEvent` must also have moved
      // a sufficient global distance from the initial `PointerDownEvent` to be
      // accepted as a drag. This logic is handled in `_hasSufficientGlobalDistanceToAccept`.

      // If the buttons differ from the `PointerDownEvent`s buttons then we should stop tracking
      // the pointer.
      print('move');
      if (event.buttons != _initialButtons) {
        _giveUpPointer(event.pointer);
      }

      if (_dragState == _GestureState.accepted) {
        print('accepted');
        _checkUpdate(event);
      } else if (_dragState == _GestureState.possible) {
        print('possible');
        final bool isPreAcceptSlopPastTolerance =
            !_wonArenaForPrimaryPointer &&
            preAcceptSlopTolerance != null &&
            _getGlobalDistance(event) > preAcceptSlopTolerance!;
        final bool isPostAcceptSlopPastTolerance =
            _wonArenaForPrimaryPointer &&
            postAcceptSlopTolerance != null &&
            _getGlobalDistance(event) > postAcceptSlopTolerance!;

        if (isPreAcceptSlopPastTolerance || isPostAcceptSlopPastTolerance) {
          // When the tap has drifted past the tolerance, the pointer being tracked
          // can no longer be considered a tap, i.e. the `OnTapUp` and `onSecondaryTapUp`
          // callback will not be called. However, the pointer can potentially still be a drag.
          _pastTapTolerance = true;
        }

        print('checking drag');
        _checkDrag(event);

        // We may arrive here if the recognizer is accepted before a `PointerMoveEvent` has been
        // received.
        if (_start != null && _wonArenaForPrimaryPointer) {
          _acceptDrag(_start!);
        }
      }
      print('netierh');
    } else if (event is PointerUpEvent) {
      if (_dragState == _GestureState.possible) {
        print('pointer up event handled - drag possible -recognizer');
        // If we arrive at a `PointerUpEvent`, and the recognizer has not won the arena, and the tap drift
        // has exceeded its tolerance, then we should reject this recognizer.
        if (_pastTapTolerance) {
          _giveUpPointer(event.pointer);
          return;
        }
        // The drag has not been accepted before a `PointerUpEvent`, therefore the recognizer
        // only registers a tap has occurred.
        stopTrackingIfPointerNoLongerDown(event);
      } else if (_dragState == _GestureState.accepted) {
        _giveUpPointer(event.pointer);
      }
    } else if (event is PointerCancelEvent){
      _giveUpPointer(event.pointer);
    }
    // super.handleEvent(event);
  }

  @override
  void rejectGesture(int pointer) {
    super.rejectGesture(pointer);
    if (pointer != primaryPointer) {
      return;
    }

    _stopDeadlineTimer();
    _giveUpPointer(pointer);

    // Reset down and up when the recognizer has been rejected.
    // This prevents an erroneous _up being sent when this recognizer is
    // accepted for a drag, following a previous rejection.
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
    print('accept drag');
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
    print('checkkk');
    if (_hasSufficientGlobalDistanceToAccept(event.kind, gestureSettings?.touchSlop)) {
      if (event.buttons == kSecondaryButton) {
        // Reject a right click drag.
        resolve(GestureDisposition.rejected);
        print('reject');
        return;
      }
      print('accept');
      _start = event;
      _dragState = _GestureState.accepted;
      resolve(GestureDisposition.accepted);
    }
    print('woah');
  }

  void _checkTapDown(PointerDownEvent event) {
    if (_sentTapDown) {
      return;
    }

    final TapDownDetails details = TapDownDetails(
      globalPosition: event.position,
      localPosition: event.localPosition,
      kind: getKindForPointer(event.pointer),
    );

    _consecutiveTapCountWhileDragging = consecutiveTapCount;

    final TapStatus status = TapStatus(
      consecutiveTapCount: consecutiveTapCount,
      keysPressedOnDown: keysPressedOnDown,
    );

    switch (_initialButtons) {
      case kPrimaryButton:
        if (onTapDown != null) {
          invokeCallback('onTapDown', () => onTapDown!(details, status));
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
    print('running check tap up - recognizer');

    final TapUpDetails upDetails = TapUpDetails(
      kind: event.kind,
      globalPosition: event.position,
      localPosition: event.localPosition,
    );

    final TapStatus status = TapStatus(
      consecutiveTapCount: consecutiveTapCount,
      keysPressedOnDown: keysPressedOnDown,
    );

    switch (_initialButtons) {
      case kPrimaryButton:
        if (onTapUp != null) {
          invokeCallback('onTapUp', () => onTapUp!(upDetails, status));
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
    } // revisit
    _initialButtons = null;
  }

  void _checkStart(PointerMoveEvent event) {
    final DragStartDetails details = DragStartDetails(
      sourceTimeStamp: event.timeStamp,
      globalPosition: _initialPosition.global,
      localPosition: _initialPosition.local,
      kind: getKindForPointer(event.pointer),
    );

    final TapStatus status = TapStatus(
      consecutiveTapCount: _consecutiveTapCountWhileDragging!,
      keysPressedOnDown: keysPressedOnDown,
    );

    invokeCallback<void>('onStart', () => onStart!(details, status));

    _start = null;
  }

  void _checkUpdate(PointerMoveEvent event) {
    final Offset globalPosition = _correctedPosition != null ? _correctedPosition!.global : event.position;
    final Offset localPosition = _correctedPosition != null ? _correctedPosition!.local : event.localPosition;

    final DragUpdateDetails details =  DragUpdateDetails(
      sourceTimeStamp: event.timeStamp,
      delta: event.localDelta,
      globalPosition: globalPosition,
      kind: getKindForPointer(event.pointer),
      localPosition: localPosition,
      offsetFromOrigin: globalPosition - _initialPosition.global,
      localOffsetFromOrigin: localPosition - _initialPosition.local,
    );

    final TapStatus status = TapStatus(
      consecutiveTapCount: _consecutiveTapCountWhileDragging!,
      keysPressedOnDown: keysPressedOnDown,
    );

    if (dragUpdateThrottleFrequency != null) {
      _lastDragUpdateDetails = details;
      _lastDragTapStatus = status;
      // Only schedule a new timer if there's no one pending.
      _dragUpdateThrottleTimer ??= Timer(dragUpdateThrottleFrequency!, _handleDragUpdateThrottled);
    } else {
      invokeCallback<void>('onUpdate', () => onUpdate!(details, status));
    }
  }

  void _checkEnd() {
    if (_dragUpdateThrottleTimer != null) {
      // If there's already an update scheduled, trigger it immediately and
      // cancel the timer.
      _dragUpdateThrottleTimer!.cancel();
      _handleDragUpdateThrottled();
    }

    final DragEndDetails endDetails = DragEndDetails(primaryVelocity: 0.0);

    final TapStatus status = TapStatus(
      consecutiveTapCount: _consecutiveTapCountWhileDragging!,
      keysPressedOnDown: keysPressedOnDown,
    );

    invokeCallback<void>('onEnd', () => onEnd!(endDetails, status));

    _resetTaps();
    _resetDragUpdateThrottle();
  }

  void _checkCancel() {
    print('from casncel');
    _checkTapCancel();
    _checkDragCancel();
    _resetTaps();
  }

  void _checkTapCancel() {
    if (onTapCancel != null) {
      invokeCallback<void>('onTapCancel', onTapCancel!);
    }
  }

  void _checkDragCancel() {
    print('drag cancel');
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
        // then this recognizer should declare itself the winner to avoid the `LongPressGestureRecognizer`
        // from declaring itself the winner if a double tap is held for to long.
        resolve(GestureDisposition.accepted);
      }
    }
  }

  double _getGlobalDistance(PointerEvent event) {
    final Offset offset = event.position - _initialPosition.global;
    return offset.distance;
  }

  void _giveUpPointer(int pointer) {
    print('give up pointer -recognizer');
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
    // _up = null;
    // _down = null;
  }

  void _resetDragUpdateThrottle() {
    _lastDragTapStatus = null;
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
