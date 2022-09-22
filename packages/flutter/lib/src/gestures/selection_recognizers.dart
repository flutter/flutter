// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart' show HardwareKeyboard, LogicalKeyboardKey;

import 'constants.dart';
import 'drag_details.dart';
import 'events.dart';
import 'monodrag.dart' show GestureDragCancelCallback;
import 'recognizer.dart';
import 'tap.dart' show GestureTapCallback, GestureTapCancelCallback, GestureTapDownCallback, GestureTapUpCallback, TapDownDetails, TapUpDetails;

enum _GestureState {
  ready,
  possible,
  accepted,
}

/// {@macro flutter.gestures.tap.GestureTapDownCallback}
///
/// The consecutive tap count at the time the pointer contacted the screen is given by `consecutiveTapCount`.
///
/// Used by [TapAndDragGestureRecognizer.onTapDown].
typedef GestureTapDownWithTapStatusCallback  = void Function(TapDownDetails details, TapStatus status);

/// {@macro flutter.gestures.tap.GestureTapUpCallback}
///
/// The consecutive tap count at the time the pointer contacted the screen is given by `consecutiveTapCount`.
///
/// Used by [TapAndDragGestureRecognizer.onTapUp].
typedef GestureTapUpWithTapStatusCallback  = void Function(TapUpDetails details, TapStatus status);

/// {@macro flutter.gestures.dragdetails.GestureDragStartCallback}
///
/// The consecutive tap count when the drag was initiated is given by `consecutiveTapCount`.
///
/// Used by [TapAndDragGestureRecognizer.onStart].
typedef GestureDragStartWithTapStatusCallback = void Function(DragStartDetails details, TapStatus status);

/// {@macro flutter.gestures.dragdetails.GestureDragUpdateCallback}
///
/// The consecutive tap count when the drag was initiated is given by `consecutiveTapCount`.
///
/// Used by [TapAndDragGestureRecognizer.onUpdate].
typedef GestureDragUpdateWithTapStatusCallback = void Function(DragUpdateDetails details, TapStatus status);

/// {@macro flutter.gestures.monodrag.GestureDragEndCallback}
///
/// The consecutive tap count when the drag was initiated is given by `consecutiveTapCount`.
///
/// Used by [TapAndDragGestureRecognizer.onEnd].
typedef GestureDragEndWithTapStatusCallback = void Function(DragEndDetails endDetails, TapStatus status);

mixin _ConsecutiveTapMixin {
  // For consecutive tap
  Timer? consecutiveTapTimer;
  Offset? lastTapOffset;
  int consecutiveTapCount = 0;

  bool isWithinConsecutiveTapTolerance(Offset secondTapOffset) {
    assert(secondTapOffset != null);
    if (lastTapOffset == null) {
      return false;
    }

    final Offset difference = secondTapOffset - lastTapOffset!;
    return difference.distance <= kDoubleTapSlop;
  }

  void incrementConsecutiveTapCountOnDown(Offset tapGlobalPosition) {
    if (lastTapOffset == null) {
      // If last tap offset is null then we have not started our consecutive tap count,
      // so the consecutiveTapTimer should be null.
      assert(consecutiveTapTimer == null);
      consecutiveTapCount += 1;
      lastTapOffset = tapGlobalPosition;
    } else if (consecutiveTapTimer != null && isWithinConsecutiveTapTolerance(tapGlobalPosition)) {
      consecutiveTapCount += 1;
      consecutiveTapTimerStop();
    }
  }

  void consecutiveTapReset() {
    consecutiveTapTimer?.cancel();
    consecutiveTapTimer = null;
    lastTapOffset = null;
    consecutiveTapCount = 0;
  }

  void consecutiveTapTimerStop() {
    consecutiveTapTimer?.cancel();
    consecutiveTapTimer = null;
  }
}

/// An object that includes supplementary details of a tap event, such as
/// if the shift key was pressed when the tap occured, and what the tap count
/// is.
class TapStatus {
  /// Creates a [TapStatus].
  const TapStatus({
    required this.consecutiveTapCount,
    required this.isShiftPressed,
  });

  /// If this tap is in a series of taps, the `consecutiveTapCount` is
  /// what number in the series this tap is.
  final int consecutiveTapCount;

  /// Whether the shift key was pressed when this tap happened.
  final bool isShiftPressed;
}

/// Recognizes taps and movements.
///
/// Takes on the responsibilities of [TapGestureRecognizer] and [DragGestureRecognizer] in one [GestureRecognizer].
class TapAndDragGestureRecognizer extends OneSequenceGestureRecognizer with _ConsecutiveTapMixin {
  /// Initialize the object.
  ///
  /// [dragStartBehavior] must not be null.
  ///
  /// {@macro flutter.gestures.GestureRecognizer.supportedDevices}
  TapAndDragGestureRecognizer({
    this.deadline = kPressTimeout,
    this.preAcceptSlopTolerance = kTouchSlop,
    this.postAcceptSlopTolerance = kTouchSlop,
    super.debugOwner,
    this.dragStartBehavior = DragStartBehavior.start,
    super.kind,
    super.supportedDevices,
  });

  /// If non-null, the recognizer will call [_didExceedDeadline] after this
  /// amount of time has elapsed since starting to track the primary pointer.
  ///
  /// The [_didExceedDeadline] will not be called if the primary pointer is
  /// accepted, rejected, or all pointers are up or canceled before [deadline].
  final Duration? deadline;

  /// {@macro flutter.gestures.monodrag.DragGestureRecognizer.dragStartBehavior}
  DragStartBehavior dragStartBehavior;

  /// The maximum distance in logical pixels the gesture is allowed to drift
  /// from the initial touch down position before the gesture is accepted.
  ///
  /// Drifting past the allowed slop amount causes the gesture to be rejected.
  ///
  /// Can be null to indicate that the gesture can drift for any distance.
  /// Defaults to 18 logical pixels.
  final double? preAcceptSlopTolerance;

  /// The maximum distance in logical pixels the gesture is allowed to drift
  /// after the gesture has been accepted.
  ///
  /// Drifting past the allowed slop amount causes the gesture to stop tracking
  /// and signaling subsequent callbacks.
  ///
  /// Can be null to indicate that the gesture can drift for any distance.
  /// Defaults to 18 logical pixels.
  final double? postAcceptSlopTolerance;

  /// {@macro flutter.gestures.tap.TapGestureRecognizer.onTapDown}
  GestureTapDownWithTapStatusCallback? onTapDown;

  /// {@macro flutter.gestures.tap.TapGestureRecognizer.onTapUp}
  GestureTapUpWithTapStatusCallback? onTapUp;

  /// {@macro flutter.gestures.tap.TapGestureRecognizer.onTapCancel}
  // TODO(Renzo-Olivares): Explain cases when onTapCancel is called.
  GestureTapCancelCallback? onTapCancel;

  /// {@macro flutter.gestures.tap.TapGestureRecognizer.onSecondaryTap}
  GestureTapCallback? onSecondaryTap;

  /// {@macro flutter.gestures.tap.TapGestureRecognizer.onSecondaryTapDown}
  GestureTapDownCallback? onSecondaryTapDown;

  /// {@macro flutter.gestures.tap.TapGestureRecognizer.onSecondaryTapUp}
  GestureTapUpCallback? onSecondaryTapUp;

  /// {@macro flutter.gestures.monodrag.DragGestureRecognizer.onStart}
  GestureDragStartWithTapStatusCallback? onStart;

  /// {@macro flutter.gestures.monodrag.DragGestureRecognizer.onUpdate}
  GestureDragUpdateWithTapStatusCallback? onUpdate;

  /// {@macro flutter.gestures.monodrag.DragGestureRecognizer.onEnd}
  GestureDragEndWithTapStatusCallback? onEnd;

  /// {@macro flutter.gestures.monodrag.DragGestureRecognizer.onCancel}
  // TODO(Renzo-Olivares): Explain cases when onDragCancel is called.
  GestureDragCancelCallback? onDragCancel;

  // Tap related state.
  PointerUpEvent? _up;
  PointerDownEvent? _down;

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

  // For shift aware.
  static bool get _isShiftPressed {
    return HardwareKeyboard.instance.logicalKeysPressed
        .any(<LogicalKeyboardKey>{
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight,
    }.contains);
  }

  bool _isShiftTapping = false;

  // The buttons sent by `PointerDownEvent`. If a `PointerMoveEvent` comes with a
  // different set of buttons, the gesture is canceled.
  int? _initialButtons;

  final Set<int> _acceptedActivePointers = <int>{};

  bool _hasSufficientGlobalDistanceToAccept(PointerDeviceKind pointerDeviceKind, double? deviceTouchSlop) {
    return _globalDistanceMoved.abs() > computePanSlop(pointerDeviceKind, gestureSettings);
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

    // `_down` must be assigned in this method instead of `handlePrimaryPointer`,
    // because `acceptGesture` might be called before `handlePrimaryPointer`,
    // which relies on `_down` to call `handleTapDown`.
    if (_dragState == _GestureState.ready) {
      _globalDistanceMoved = 0.0;
      _initialButtons = event.buttons;
      _dragState = _GestureState.possible;
      _down = event;
      _initialPosition = OffsetPair(global: event.position, local: event.localPosition);

      if (_isShiftPressed) {
        _isShiftTapping = true;
      }
    }
  }

  @override
  void acceptGesture(int pointer) {
    if (pointer != primaryPointer) {
      return null;
    }

    _stopDeadlineTimer();

    assert(!_acceptedActivePointers.contains(pointer));
    _acceptedActivePointers.add(pointer);

    // Called when this recognizer is accepted by the `GestureArena`.
    if (_down != null) {
      _checkTapDown(_down!);
    }
    _wonArenaForPrimaryPointer = true;
    if (_up != null) {
      _checkTapUp(_up!);
    }

    // resolve(GestureDisposition.accepted) may be called when the `PointerMoveEvent` has
    // moved a sufficient global distance.
    if (_dragState == _GestureState.accepted) {
      if (_start != null) {
        _acceptDrag(_start!);
      }
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    switch (_dragState) {
      case _GestureState.ready:
        resolve(GestureDisposition.rejected);
        _checkCancel();
        break;

      case _GestureState.possible:
        if (_up == null) {
          // This means our pointer was not accepted as a tap nor a drag.
          // This can happen when a user drags on a right click, going past the
          // tap tolerance, and drag tolerance, but being rejected since a right click
          // drag is not allowed by this recognizer.
          resolve(GestureDisposition.rejected);
          _checkCancel();
        } else {
          _checkDragCancel();
          _checkTapUp(_up!);
        }
        break;

      case _GestureState.accepted:
        // We only arrive here, after the recognizer has accepted the `PointerEvent`
        // as a drag. Meaning `_checkTapDown`, and `_checkStart` have already ran.
        _checkEnd();
        _initialButtons = null;
        break;
    }

    _stopDeadlineTimer();
    _dragState = _GestureState.ready;
    _pastTapTolerance = false;
    _consecutiveTapCountWhileDragging = null;
  }

  @override
  void handleEvent(PointerEvent event) {
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
      if (event.buttons != _initialButtons) {
        _giveUpPointer(event.pointer);
      }

      if (_dragState == _GestureState.accepted) {
        _checkUpdate(event);
      } else if (_dragState == _GestureState.possible) {
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

        _checkDrag(event);

        // We may arrive here if the recognizer is accepted before a `PointerMoveEvent` has been
        // received.
        if (_start != null && _wonArenaForPrimaryPointer) {
          _acceptDrag(_start!);
        }
      }
    } else if (event is PointerUpEvent) {
      if (_dragState == _GestureState.possible) {
        // If we arrive at a `PointerUpEvent`, and the recognizer has not won the arena, and the tap drift
        // has exceeded its tolerance, then we should reject this recognizer.
        if (_pastTapTolerance && !_wonArenaForPrimaryPointer) {
          resolve(GestureDisposition.rejected);
          return;
        }
        // The drag has not been accepted before a `PointerUpEvent`, therefore the recognizer
        // only registers a tap has occurred. 
        _up = event;
        stopTrackingIfPointerNoLongerDown(event);
      } else if (_dragState == _GestureState.accepted) {
        _giveUpPointer(event.pointer);
      }
    } else if (event is PointerCancelEvent){
      _giveUpPointer(event.pointer);
    }
  }

  @override
  void rejectGesture(int pointer) {
    if (pointer != primaryPointer) {
      return;
    }

    _stopDeadlineTimer();
    _giveUpPointer(pointer);

    // Reset down and up when the recognizer has been rejected.
    // This prevents an erroneous _up being sent when this recognizer is
    // accepted for a drag, following a previous rejection.
    _resetTaps();
    consecutiveTapReset();
    _initialButtons = null;
  }

  @override
  void dispose() {
    _stopDeadlineTimer();
    consecutiveTapReset();
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
        // Reject a right click drag.
        resolve(GestureDisposition.rejected);
        return;
      }
      _start = event;
      _dragState = _GestureState.accepted;
      resolve(GestureDisposition.accepted);
    }
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

    incrementConsecutiveTapCountOnDown(details.globalPosition);
    _consecutiveTapCountWhileDragging = consecutiveTapCount;

    final TapStatus status = TapStatus(
      consecutiveTapCount: consecutiveTapCount,
      isShiftPressed: _isShiftTapping,
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

    consecutiveTapTimer ??= Timer(kDoubleTapTimeout, consecutiveTapReset);

    final TapUpDetails upDetails = TapUpDetails(
      kind: event.kind,
      globalPosition: event.position,
      localPosition: event.localPosition,
    );

    final TapStatus status = TapStatus(
      consecutiveTapCount: consecutiveTapCount,
      isShiftPressed: _isShiftTapping,
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
    _isShiftTapping = false;
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
      isShiftPressed: _isShiftTapping,
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
      isShiftPressed: _isShiftTapping,
    );

    invokeCallback<void>('onUpdate', () => onUpdate!(details, status));
  }

  void _checkEnd() {
    final DragEndDetails endDetails = DragEndDetails(primaryVelocity: 0.0);

    final TapStatus status = TapStatus(
      consecutiveTapCount: _consecutiveTapCountWhileDragging!,
      isShiftPressed: _isShiftTapping,
    );

    invokeCallback<void>('onEnd', () => onEnd!(endDetails, status));

    _resetTaps();
    consecutiveTapReset();
    _isShiftTapping = false;
  }

  void _checkCancel() {
    _checkTapCancel();
    _checkDragCancel();
    _resetTaps();
    consecutiveTapReset();
  }

  void _checkTapCancel() {
    if (onTapCancel != null) {
      invokeCallback<void>('onTapCancel', onTapCancel!);
    }
  }

  void _checkDragCancel() {
    if (onDragCancel != null) {
      invokeCallback<void>('onDragCancel', onDragCancel!);
    }
  }

  void _didExceedDeadlineWithEvent(PointerDownEvent event) {
    _didExceedDeadline();
  }

  void _didExceedDeadline() {
    if (_down != null) {
      _checkTapDown(_down!);

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
    _up = null;
    _down = null;
  }

  void _stopDeadlineTimer() {
    if (_deadlineTimer != null) {
      _deadlineTimer!.cancel();
      _deadlineTimer = null;
    }
  }
}
