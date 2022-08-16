// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'constants.dart';
import 'events.dart';
import 'drag_details.dart';
import 'long_press.dart' show GestureLongPressStartCallback, GestureLongPressMoveUpdateCallback, GestureLongPressEndCallback, GestureLongPressCancelCallback, LongPressStartDetails, LongPressMoveUpdateDetails, LongPressEndDetails;
import 'monodrag.dart' show GestureDragEndCallback;
import 'recognizer.dart';
import 'tap.dart' show GestureTapCallback, GestureTapDownCallback, GestureTapUpCallback, TapUpDetails, TapDownDetails;
import 'velocity_tracker.dart';

enum _DragState {
  ready,
  possible,
  accepted,
}

typedef GestureTapDownWithConsecutiveTapCountCallback  = void Function(TapDownDetails details, int consecutiveTapCount);
typedef GestureTapUpWithConsecutiveTapCountCallback  = void Function(TapUpDetails details, int consecutiveTapCount);
typedef GestureDragStartWithConsecutiveTapCountCallback = void Function(DragStartDetails details, int consecutiveTapCount);
typedef GestureDragUpdateWithConsecutiveTapCountCallback = void Function(DragUpdateDetails details, int consecutiveTapCount);
typedef GestureDragEndWithConsecutiveTapCountCallback = void Function(DragEndDetails endDetails, int consecutiveTapCount);
typedef GestureTapAndDragCancelCallback = void Function();

mixin ConsecutiveTapMixin {
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

class TapAndDragGestureRecognizer extends OneSequenceGestureRecognizer with ConsecutiveTapMixin {
  TapAndDragGestureRecognizer({
    super.debugOwner,
    this.dragStartBehavior = DragStartBehavior.start,
    super.kind,
    super.supportedDevices,
  });

  DragStartBehavior dragStartBehavior;

  GestureTapCallback? onSecondaryTap;

  GestureTapDownWithConsecutiveTapCountCallback? onTapDown;

  GestureTapDownCallback? onSecondaryTapDown;

  GestureDragStartWithConsecutiveTapCountCallback? onStart;

  GestureDragUpdateWithConsecutiveTapCountCallback? onUpdate;

  GestureDragEndWithConsecutiveTapCountCallback? onEnd;

  GestureTapUpWithConsecutiveTapCountCallback? onTapUp;

  GestureTapUpCallback? onSecondaryTapUp;

  GestureTapAndDragCancelCallback? onCancel;

  // For local tap drag count
  int? _consecutiveTapCountWhileDragging;
  
  // Drag related state
  late OffsetPair _initialPosition;
  _DragState _state = _DragState.ready;

  // The buttons sent by `PointerDownEvent`. If a `PointerMoveEvent` comes with a
  // different set of buttons, the gesture is canceled.
  int? _initialButtons;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    print('addAllowedPointer $event');
    super.addAllowedPointer(event);
  }

  @override
  void addAllowedPointerPanZoom(PointerPanZoomStartEvent event) {
    print('addAllowedPointerPanZoom $event');
    super.addAllowedPointerPanZoom(event);
  }

  @override
  void acceptGesture(int pointer) {
    // TODO: implement acceptGesture
    print('accept gesture $pointer');
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      if (_state == _DragState.ready) {
        print('handle PointerDownEvent $event');
        _initialButtons = event.buttons;
        _state = _DragState.possible;
        TapDownDetails details = TapDownDetails(
          globalPosition: event.position,
          localPosition: event.localPosition,
          kind: getKindForPointer(event.pointer),
        );

        if (lastTapOffset == null) {
          consecutiveTapCount += 1;
          lastTapOffset = details.globalPosition;
        } else {
          if (consecutiveTapTimer != null && isWithinConsecutiveTapTolerance(details.globalPosition)) {
            consecutiveTapCount += 1;
            consecutiveTapTimerReset();
          }
        }

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
    } else if (event is PointerMoveEvent || event is PointerPanZoomUpdateEvent) {
      print('handle PointerMoveEvent $event');

      if (_state == _DragState.accepted) {
        DragUpdateDetails details =  DragUpdateDetails(
          sourceTimeStamp: event.timeStamp,
          delta: event.delta,
          primaryDelta: null,
          globalPosition: event.position,
          localPosition: event.localPosition,
          offsetFromOrigin: event.position - _initialPosition.global,
          localOffsetFromOrigin: event.localPosition - _initialPosition.local,
        );
        invokeCallback<void>('onUpdate', () => onUpdate!(details, _consecutiveTapCountWhileDragging!));
      } else if (_state == _DragState.possible) {
        print('is zoom start ${event is PointerPanZoomStartEvent}');
        _state = _DragState.accepted;
        _initialPosition = OffsetPair(global: event.position, local: event.localPosition);
        DragStartDetails details = DragStartDetails(
          sourceTimeStamp: event.timeStamp,
          globalPosition: event.position,
          localPosition: event.localPosition,
          kind: getKindForPointer(event.pointer),
        );

        invokeCallback<void>('onStart', () => onStart!(details, _consecutiveTapCountWhileDragging!));
      }
    } else if (event is PointerUpEvent) {
      print('handle PointerUpEvent $event');
      _state = _DragState.ready;
      TapUpDetails upDetails = TapUpDetails(
        kind: event.kind,
        globalPosition: event.position,
        localPosition: event.localPosition,
      );
      DragEndDetails endDetails = DragEndDetails(primaryVelocity: 0.0);
      switch (_initialButtons) {
        case kPrimaryButton:
          if (onTapDown != null) {
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
      invokeCallback<void>('onEnd', () => onEnd!(endDetails, consecutiveTapCount));
      _consecutiveTapCountWhileDragging = null;
      consecutiveTapTimer ??= Timer(kDoubleTapTimeout, consecutiveTapTimeout);
    } else {
      print('handle unknown pointer $event');
    }
  }

  @override
  // TODO: implement debugDescription
  String get debugDescription => 'tap_and_drag';

  @override
  void rejectGesture(int pointer) {
    // TODO: implement rejectGesture
    print('reject gesture $pointer');
  }
}

class TapAndLongPressGestureRecognizer extends PrimaryPointerGestureRecognizer with ConsecutiveTapMixin {
  TapAndLongPressGestureRecognizer({
    Duration? duration,
    // TODO(goderbauer): remove ignore when https://github.com/dart-lang/linter/issues/3349 is fixed.
    // ignore: avoid_init_to_null
    super.postAcceptSlopTolerance = null,
    super.supportedDevices,
    super.debugOwner,
  }) : super(
         deadline: duration ?? kLongPressTimeout,
       );

  GestureTapDownWithConsecutiveTapCountCallback? onTapDown;
  GestureLongPressStartCallback? onLongPressStart;
  GestureLongPressMoveUpdateCallback? onLongPressMoveUpdate;
  GestureLongPressEndCallback? onLongPressEnd;
  GestureLongPressCancelCallback? onLongPressCancel;
  GestureTapUpWithConsecutiveTapCountCallback? onTapUp;

  bool _isDoubleTap = false;
  bool _longPressAccepted = false;
  OffsetPair? _longPressOrigin;
  // The buttons sent by `PointerDownEvent`. If a `PointerMoveEvent` comes with a
  // different set of buttons, the gesture is canceled.
  int? _initialButtons;

  VelocityTracker? _velocityTracker;

  @override
  bool isPointerAllowed(PointerDownEvent event) {
    switch (event.buttons) {
      case kPrimaryButton:
        if (onTapDown == null &&
            onLongPressCancel == null &&
            onLongPressStart == null &&
            onLongPressMoveUpdate == null &&
            onLongPressEnd == null &&
            onTapUp == null) {
          return false;
        }
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
        // resolve(GestureDisposition.rejected);
        _checkTapUp(event);
      }
      _reset();
    } else if (event is PointerCancelEvent) {
      _checkLongPressCancel();
      _reset();
    } else if (event is PointerDownEvent) {
      // The first touch.
      _longPressOrigin = OffsetPair.fromEventPosition(event);
      _initialButtons = event.buttons;
      _checkTapDown(event);
    } else if (event is PointerMoveEvent) {
      if (event.buttons != _initialButtons) {
        resolve(GestureDisposition.rejected);
        stopTrackingPointer(primaryPointer!);
      } else if (_longPressAccepted) {
        _checkLongPressMoveUpdate(event);
      }
    }
  }

  void _checkTapDown(PointerDownEvent event) {
    assert(_longPressOrigin != null);
    print('from recognizer check tap down');
    final TapDownDetails details = TapDownDetails(
      globalPosition: _longPressOrigin!.global,
      localPosition: _longPressOrigin!.local,
      kind: getKindForPointer(event.pointer),
    );

    if (lastTapOffset == null) {
      consecutiveTapCount += 1;
      lastTapOffset = details.globalPosition;
    } else {
      if (consecutiveTapTimer != null && isWithinConsecutiveTapTolerance(details.globalPosition)) {
        consecutiveTapCount += 1;
        consecutiveTapTimerReset();
      }
    }

    _isDoubleTap = consecutiveTapCount == 2;

    switch (_initialButtons) {
      case kPrimaryButton:
        if (onTapDown != null) {
          invokeCallback<void>('onTapDown', () => onTapDown!(details, consecutiveTapCount));
        }
        break;
      default:
        assert(false, 'Unhandled button $_initialButtons');
    }
  }

  void _checkTapUp(PointerUpEvent event) {
    print('from recognizer check tap up');
    final TapUpDetails details = TapUpDetails(
      globalPosition: event.position,
      localPosition: event.localPosition,
      kind: getKindForPointer(event.pointer),
    );

    _velocityTracker = null;
    switch (_initialButtons) {
      case kPrimaryButton:
        if (onTapUp != null) {
          invokeCallback<void>('onTapUp', () => onTapUp!(details, consecutiveTapCount));
        }
        break;
      default:
        assert(false, 'Unhandled button $_initialButtons');
    }
    consecutiveTapTimer ??= Timer(kDoubleTapTimeout, consecutiveTapTimeout);
  }

  void _checkLongPressCancel() {
    print('from recognizer check tap cancel');
    if (state == GestureRecognizerState.possible) {
      switch (_initialButtons) {
        case kPrimaryButton:
          if (onLongPressCancel != null) {
            invokeCallback<void>('onLongPressCancel', onLongPressCancel!);
          }
          break;
        default:
          assert(false, 'Unhandled button $_initialButtons');
      }
    }
  }

  void _checkLongPressStart() {
    print('from recognizer check long press start');
    if (_isDoubleTap) {
      resolve(GestureDisposition.rejected);
      return;
    }
    switch (_initialButtons) {
      case kPrimaryButton:
        if (onLongPressStart != null) {
          final LongPressStartDetails details = LongPressStartDetails(
            globalPosition: _longPressOrigin!.global,
            localPosition: _longPressOrigin!.local,
          );
          invokeCallback<void>('onLongPressStart', () => onLongPressStart!(details));
        }
        break;
      default:
        assert(false, 'Unhandled button $_initialButtons');
    }
  }

  void _checkLongPressMoveUpdate(PointerEvent event) {
    print('from recognizer check long press move update');
    if (_isDoubleTap) {
      resolve(GestureDisposition.rejected);
      return;
    }
    final LongPressMoveUpdateDetails details = LongPressMoveUpdateDetails(
      globalPosition: event.position,
      localPosition: event.localPosition,
      offsetFromOrigin: event.position - _longPressOrigin!.global,
      localOffsetFromOrigin: event.localPosition - _longPressOrigin!.local,
    );
    switch (_initialButtons) {
      case kPrimaryButton:
        if (onLongPressMoveUpdate != null) {
          invokeCallback<void>('onLongPressMoveUpdate', () => onLongPressMoveUpdate!(details));
        }
        break;
      default:
        assert(false, 'Unhandled button $_initialButtons');
    }
  }

  void _checkLongPressEnd(PointerEvent event) {
    print('from recognizer check long press end');
    if (_isDoubleTap) {
      _isDoubleTap = false;
      resolve(GestureDisposition.rejected);
      return;
    }
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
    if (disposition == GestureDisposition.rejected) {
      if (_longPressAccepted) {
        // This can happen if the gesture has been canceled. For example when
        // the buttons have changed.
        _reset();
      } else {
        _checkLongPressCancel();
      }
    }
    super.resolve(disposition);
  }

  @override
  void acceptGesture(int pointer) {
    // Winning the arena isn't important here since it may happen from a sweep.
    // Explicitly exceeding the deadline puts the gesture in accepted state.
  }

  @override
  String get debugDescription => 'tap_and_long_press';
}

