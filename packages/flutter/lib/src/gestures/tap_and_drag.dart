// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:async/async.dart';

import 'constants.dart';
import 'events.dart';
import 'drag_details.dart';
import 'recognizer.dart';
import 'tap.dart' show TapUpDetails, TapDownDetails;

typedef GestureTapAndDragDownCallback  = void Function(TapDownDetails details, int tapCount);
typedef GestureTapAndDragStartCallback = void Function(DragStartDetails details, int tapCount);
typedef GestureTapAndDragUpdateCallback = void Function(DragUpdateDetails details, int tapCount);
typedef GestureTapUpAndDragEndCallback = void Function(TapUpDetails upDetails, DragEndDetails endDetails, int tapCount);
typedef GestureTapAndDragCancelCallback = void Function();

class TapAndDragGestureRecognizer extends OneSequenceGestureRecognizer {
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

  // For consecutive tap
  RestartableTimer? _consecutiveTapTimer;
  Offset? _lastTapOffset;
  int _tapCount = 0;

  bool _isWithinConsecutiveTapTolerance(Offset secondTapOffset) {
    assert(secondTapOffset != null);
    if (_lastTapOffset == null) {
      return false;
    }

    final Offset difference = secondTapOffset - _lastTapOffset!;
    return difference.distance <= kDoubleTapSlop;
  }

  void _consecutiveTapTimeout() {
    _consecutiveTapTimer = null;
    _lastTapOffset = null;
    _tapCount = 0;
  }

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
    print(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      print('handle PointerDownEvent $event');
      // DragDownDetails details = DragDownDetails(globalPosition: event.position, localPosition: event.localPosition);
      DragStartDetails details = DragStartDetails(
        sourceTimeStamp: event.timeStamp,
        globalPosition: event.position,
        localPosition: event.localPosition,
        kind: getKindForPointer(event.pointer),
      );

      if (_lastTapOffset == null) {
        _tapCount += 1;
        _lastTapOffset = details.globalPosition;
      } else {
        if (_consecutiveTapTimer != null && _isWithinConsecutiveTapTolerance(details.globalPosition)) {
          _tapCount += 1;
          _consecutiveTapTimer!.reset();
        }
      }

      invokeCallback<void>('onStart', () => onStart!(details, 0));
    } else if (event is PointerMoveEvent) {
      print('handle PointerMoveEvent $event');
      DragUpdateDetails details =  DragUpdateDetails(
        sourceTimeStamp: event.timeStamp,
        delta: event.delta,
        primaryDelta: null,
        globalPosition: event.position,
        localPosition: event.localPosition,
      );
      invokeCallback<void>('onUpdate', () => onUpdate!(details, 0));
    } else if (event is PointerUpEvent) {
      print('handle PointerUpEvent $event');
      TapUpDetails upDetails = TapUpDetails(
        kind: event.kind,
        globalPosition: event.position,
        localPosition: event.localPosition,
      );
      DragEndDetails endDetails = DragEndDetails(primaryVelocity: 0.0);
      invokeCallback<void>('onUpAndEnd', () => onUpAndEnd!(upDetails, endDetails, 0));
      _consecutiveTapTimer ??= RestartableTimer(kDoubleTapTimeout, _consecutiveTapTimeout);
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
    print(pointer);
  }
}
