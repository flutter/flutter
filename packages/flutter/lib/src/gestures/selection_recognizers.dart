// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'constants.dart';
import 'drag_details.dart';
import 'events.dart';
import 'long_press.dart' show GestureLongPressCancelCallback, GestureLongPressEndCallback, GestureLongPressMoveUpdateCallback, GestureLongPressStartCallback, LongPressEndDetails, LongPressMoveUpdateDetails, LongPressStartDetails;
import 'monodrag.dart' show GestureDragCancelCallback;
import 'recognizer.dart';
import 'tap.dart' show GestureTapCallback, GestureTapCancelCallback, GestureTapDownCallback, GestureTapUpCallback, TapDownDetails, TapUpDetails;
import 'velocity_tracker.dart';

enum _DragState {
  ready,
  possible,
  accepted,
}

/// {@macro flutter.gestures.tap.GestureTapDownCallback}
/// 
/// The consecutive tap count at the time the pointer contacted the screen, is given by `consecutiveTapCount`.
/// 
/// Used by [TapAndDragGestureRecognizer.onTapDown].
typedef GestureTapDownWithConsecutiveTapCountCallback  = void Function(TapDownDetails details, int consecutiveTapCount);

/// {@macro flutter.gestures.tap.GestureTapUpCallback}
/// 
/// The consecutive tap count at the time the pointer contacted the screen, is given by `consecutiveTapCount`.
/// 
/// Used by [TapAndDragGestureRecognizer.onTapUp].
typedef GestureTapUpWithConsecutiveTapCountCallback  = void Function(TapUpDetails details, int consecutiveTapCount);

/// {@macro flutter.gestures.dragdetails.GestureDragStartCallback}
///
/// The consecutive tap count, when the drag was initiated is given by `consecutiveTapCount`.
///
/// Used by [TapAndDragGestureRecognizer.onStart].
typedef GestureDragStartWithConsecutiveTapCountCallback = void Function(DragStartDetails details, int consecutiveTapCount);

/// {@macro flutter.gestures.dragdetails.GestureDragUpdateCallback}
/// 
/// The consecutive tap count, when the drag was initiated is given by `consecutiveTapCount`.
///
/// Used by [TapAndDragGestureRecognizer.onUpdate].
typedef GestureDragUpdateWithConsecutiveTapCountCallback = void Function(DragUpdateDetails details, int consecutiveTapCount);

/// {@macro flutter.gestures.monodrag.GestureDragEndCallback}
///
/// The consecutive tap count, when the drag was initiated is given by `consecutiveTapCount`.
///
/// Used by [TapAndDragGestureRecognizer.onEnd].
typedef GestureDragEndWithConsecutiveTapCountCallback = void Function(DragEndDetails endDetails, int consecutiveTapCount);

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
      consecutiveTapCount += 1;
      lastTapOffset = tapGlobalPosition;
    } else {
      if (consecutiveTapTimer != null && isWithinConsecutiveTapTolerance(tapGlobalPosition)) {
        consecutiveTapCount += 1;
        consecutiveTapTimerReset();
      }
    }
  }

  void consecutiveTapTimeout() {
    print('consecutive tap timeout');
    consecutiveTapTimer?.cancel();
    consecutiveTapTimer = null;
    lastTapOffset = null;
    consecutiveTapCount = 0;
  }

  void consecutiveTapTimerReset() {
    print('consecutiveTapTimer reset');
    consecutiveTapTimer?.cancel();
    consecutiveTapTimer = null;
    consecutiveTapTimer = Timer(kDoubleTapTimeout, consecutiveTapTimeout);
  }
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

  /// {@macro flutter.gestures.tap.TapGestureRecognizer.onTapDown}
  GestureTapDownWithConsecutiveTapCountCallback? onTapDown;

  /// {@macro flutter.gestures.tap.TapGestureRecognizer.onTapUp}
  GestureTapUpWithConsecutiveTapCountCallback? onTapUp;

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
  GestureDragStartWithConsecutiveTapCountCallback? onStart;

  /// {@macro flutter.gestures.monodrag.DragGestureRecognizer.onUpdate}
  GestureDragUpdateWithConsecutiveTapCountCallback? onUpdate;

  /// {@macro flutter.gestures.monodrag.DragGestureRecognizer.onEnd}
  GestureDragEndWithConsecutiveTapCountCallback? onEnd;

  /// {@macro flutter.gestures.monodrag.DragGestureRecognizer.onCancel}
  // TODO(Renzo-Olivares): Explain cases when onDragCancel is called.
  GestureDragCancelCallback? onDragCancel;

  // For local tap drag count
  int? _consecutiveTapCountWhileDragging;

  // Tap related state
  PointerUpEvent? _up;
  PointerDownEvent? _down;
  Timer? _deadlineTimer;
  int? get primaryPointer => _primaryPointer;
  int? _primaryPointer;
  
  // Drag related state
  OffsetPair? _correctedPosition;
  late OffsetPair _initialPosition;
  late double _globalDistanceMoved;
  _DragState _state = _DragState.ready;

  // The buttons sent by `PointerDownEvent`. If a `PointerMoveEvent` comes with a
  // different set of buttons, the gesture is canceled.
  int? _initialButtons;

  final Set<int> _acceptedActivePointers = <int>{};

  bool _hasSufficientGlobalDistanceToAccept(PointerDeviceKind pointerDeviceKind, double? deviceTouchSlop) {
    return _globalDistanceMoved.abs() > computePanSlop(pointerDeviceKind, gestureSettings);
  }

  @override
  bool isPointerAllowed(PointerEvent event) {
    print('isPointerAllowed');
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
      print('hmmmm');
      if (event.buttons != _initialButtons) {
        print('cant have different buttons');
        return false;
      }
    }
    return super.isPointerAllowed(event as PointerDownEvent);
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    print('addAllowedPointer $event ${event.pointer}');
    super.addAllowedPointer(event);
    if (_state == _DragState.ready) {
      print('setting deadline');
      _primaryPointer = event.pointer;
      if (deadline != null) {
        print('setting deadline 2');
        _deadlineTimer = Timer(deadline!, () => _didExceedDeadlineWithEvent(event));
      }
    }
  }

  @override
  void addAllowedPointerPanZoom(PointerPanZoomStartEvent event) {
    print('addAllowedPointerPanZoom $event');
    super.addAllowedPointerPanZoom(event);
  }

  @override
  void acceptGesture(int pointer) {
    print('accept gesture $pointer');
    if (pointer == primaryPointer) {
      _stopDeadlineTimer();
    }
    assert(!_acceptedActivePointers.contains(pointer));
    _acceptedActivePointers.add(pointer);
    if (pointer == primaryPointer) {
      if (_down != null) {
        _checkTapDown(_down!);
      }
      if (_up != null) {
        _checkTapUp(_up!);
      }
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    print('didStopTrackingLastPointer $_state $pointer');
    switch (_state) {
      case _DragState.ready:
        resolve(GestureDisposition.rejected);
        _checkCancel();
        break;

      case _DragState.possible:
        if (_up == null) {
          resolve(GestureDisposition.rejected);
          _checkCancel();
        } else {
          _checkDragCancel();
          _checkTapUp(_up!);
          consecutiveTapTimer ??= Timer(kDoubleTapTimeout, consecutiveTapTimeout);
        }
        break;

      case _DragState.accepted:
        _checkEnd();
        break;
    }
    _stopDeadlineTimer();
    _up = null;
    _down = null;
    _initialButtons = null;
    _state = _DragState.ready;
    _consecutiveTapCountWhileDragging = null;
  }

  @override
  void handleEvent(PointerEvent event) {
    print('handle event ${event.pointer}');
    if (event is PointerDownEvent) {
      print('handle PointerDownEvent $event');
      if (_state == _DragState.ready) {
        _globalDistanceMoved = 0.0;
        _initialButtons = event.buttons;
        _state = _DragState.possible;
        _down = event;

        if (dragStartBehavior == DragStartBehavior.down) {
          _initialPosition = OffsetPair(global: event.position, local: event.localPosition);
        }
        // _checkTapDown(event);

      }
    } else if (event is PointerMoveEvent) {
      print('handle PointerMoveEvent $event');
      if (_initialButtons == kSecondaryButton) {
        resolve(GestureDisposition.rejected);
        return;
      }

      if (_state == _DragState.accepted) {
        print('PointerMoveEvent while drag is accepted');
        _checkUpdate(event);
      } else if (_state == _DragState.possible) {
        print('PointerMoveEvent while drag is is possible');
        final Matrix4? localToGlobalTransform = event.transform == null ? null : Matrix4.tryInvert(event.transform!);
        _globalDistanceMoved += PointerEvent.transformDeltaViaPositions(
          transform: localToGlobalTransform,
          untransformedDelta: event.localDelta,
          untransformedEndPosition: event.localPosition
        ).distance * 1.sign;
        if (_hasSufficientGlobalDistanceToAccept(event.kind, gestureSettings?.touchSlop)) {
          print('has sufficient global distance to accept');
          _checkTapCancel();
          _checkStart(event);
          if (event.localDelta != Offset.zero) {
            print('should call dragupdate here ${event.localDelta} != ${Offset.zero}');
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
      }
    } else if (event is PointerUpEvent) {
      print('handle PointerUpEvent $event');
      if (_state == _DragState.possible) {
        _up = event;
      }
      _giveUpPointer(event.pointer);
    } else if (event is PointerCancelEvent){
      print('cancel from pointercancel');
      _giveUpPointer(event.pointer);
    } else {
      print('handle unknown pointer $event');
    }
  }

  @override
  void rejectGesture(int pointer) {
    print('reject gesture $pointer');
    print('cancel from reject');
    if (pointer == primaryPointer) {
      _stopDeadlineTimer();
    }
    _giveUpPointer(pointer);
  }

  @override
  void dispose() {
    _stopDeadlineTimer();
    consecutiveTapTimeout();
    super.dispose();
  }

  @override
  String get debugDescription => 'tap_and_drag';

  void _checkTapDown(PointerDownEvent event) {
    _initialButtons = event.buttons;
    _state = _DragState.possible;

    if (dragStartBehavior == DragStartBehavior.down) {
      _initialPosition = OffsetPair(global: event.position, local: event.localPosition);
    }

    final TapDownDetails details = TapDownDetails(
      globalPosition: event.position,
      localPosition: event.localPosition,
      kind: getKindForPointer(event.pointer),
    );

    incrementConsecutiveTapCountOnDown(details.globalPosition);
    _consecutiveTapCountWhileDragging = consecutiveTapCount;

    switch (_initialButtons) {
      case kPrimaryButton:
        if (onTapDown != null) {
          invokeCallback('onTapDown', () => onTapDown!(details, consecutiveTapCount));
        }
        break;
      case kSecondaryButton:
        if (onSecondaryTapDown != null) {
          invokeCallback('onSecondaryTapDown', () => onSecondaryTapDown!(details));
        }
        break;
      default:
    }
  }

  void _checkTapUp(PointerUpEvent event) {
    final TapUpDetails upDetails = TapUpDetails(
      kind: event.kind,
      globalPosition: event.position,
      localPosition: event.localPosition,
    );

    switch (_initialButtons) {
      case kPrimaryButton:
        if (onTapUp != null) {
          invokeCallback('onTapUp', () => onTapUp!(upDetails, consecutiveTapCount));
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
  }

  void _checkStart(PointerMoveEvent event) {
    _state = _DragState.accepted;
    
    if (dragStartBehavior == DragStartBehavior.start) {
      _initialPosition = OffsetPair(global: event.position, local: event.localPosition);
    }
    final DragStartDetails details = DragStartDetails(
      sourceTimeStamp: event.timeStamp,
      globalPosition: _initialPosition.global,
      localPosition: _initialPosition.local,
      kind: getKindForPointer(event.pointer),
    );

    invokeCallback<void>('onStart', () => onStart!(details, _consecutiveTapCountWhileDragging!));
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
    invokeCallback<void>('onUpdate', () => onUpdate!(details, _consecutiveTapCountWhileDragging!));
  }

  void _checkEnd() {
    final DragEndDetails endDetails = DragEndDetails(primaryVelocity: 0.0);
    invokeCallback<void>('onEnd', () => onEnd!(endDetails, consecutiveTapCount));
  }

  void _checkCancel() {
    print('state when cancel is called $_state');
    _checkTapCancel();
    _checkDragCancel();
  }

  void _checkTapCancel() {
    print('tap cancel $_state');
    if (onTapCancel != null) {
      invokeCallback<void>('onTapCancel', onTapCancel!);
    }
  }

  void _checkDragCancel() {
    print('drag cancel $_state');
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
    }
  }

  void _giveUpPointer(int pointer) {
    print('give up pointer $pointer');
    stopTrackingPointer(pointer);
    // If we never accepted the pointer, we reject it since we are no longer
    // interested in winning the gesture arena for it.
    if (!_acceptedActivePointers.remove(pointer)) {
      resolvePointer(pointer, GestureDisposition.rejected);
    }
  }

  void _stopDeadlineTimer() {
    if (_deadlineTimer != null) {
      _deadlineTimer!.cancel();
      _deadlineTimer = null;
    }
  }
}

