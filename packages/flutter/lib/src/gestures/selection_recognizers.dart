// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:async/async.dart';

import 'constants.dart';
import 'events.dart';
import 'drag_details.dart';
import 'recognizer.dart';
import 'tap.dart' show TapUpDetails, TapDownDetails;
import 'velocity_tracker.dart';

enum _DragState {
  ready,
  possible,
  accepted,
}

typedef GestureTapAndDragDownCallback  = void Function(TapDownDetails details, int tapCount);
typedef GestureTapAndDragStartCallback = void Function(DragStartDetails details, int tapCount);
typedef GestureTapAndDragUpdateCallback = void Function(DragUpdateDetails details, int tapCount);
typedef GestureTapUpAndDragEndCallback = void Function(TapUpDetails upDetails, DragEndDetails endDetails, int tapCount);
typedef GestureTapAndDragCancelCallback = void Function();

mixin ConsecutiveTapMixin {
  // For consecutive tap
  RestartableTimer? consecutiveTapTimer;
  Offset? lastTapOffset;
  int tapCount = 0;

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
    consecutiveTapTimer = null;
    lastTapOffset = null;
    tapCount = 0;
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

  GestureTapAndDragDownCallback? onDown;

  GestureTapAndDragStartCallback? onStart;

  GestureTapAndDragUpdateCallback? onUpdate;

  GestureTapUpAndDragEndCallback? onUpAndEnd;

  GestureTapAndDragCancelCallback? onCancel;

  // For local tap drag count
  int? _dragTapCount;
  
  // Drag related state
  late OffsetPair _initialPosition;
  _DragState _state = _DragState.ready;

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
      print('handle PointerDownEvent $event');
      _state = _DragState.possible;
      TapDownDetails details = TapDownDetails(
        globalPosition: event.position,
        localPosition: event.localPosition,
        kind: getKindForPointer(event.pointer),
      );

      if (lastTapOffset == null) {
        tapCount += 1;
        lastTapOffset = details.globalPosition;
      } else {
        if (consecutiveTapTimer != null && isWithinConsecutiveTapTolerance(details.globalPosition)) {
          tapCount += 1;
          consecutiveTapTimer!.reset();
        }
      }

      _dragTapCount = tapCount;

      invokeCallback('onDown', () => onDown!(details, tapCount));
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
        invokeCallback<void>('onUpdate', () => onUpdate!(details, _dragTapCount!));
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

        invokeCallback<void>('onStart', () => onStart!(details, _dragTapCount!));
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
      invokeCallback<void>('onUpAndEnd', () => onUpAndEnd!(upDetails, endDetails, tapCount));
      _dragTapCount = null;
      consecutiveTapTimer ??= RestartableTimer(kDoubleTapTimeout, consecutiveTapTimeout);
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


