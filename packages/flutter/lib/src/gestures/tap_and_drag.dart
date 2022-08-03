// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'drag_details.dart';
import 'recognizer.dart';

typedef GestureTapAndDragDownCallback  = void Function(DragDownDetails details, int tapCount);
typedef GestureTapAndDragStartCallback = void Function(DragStartDetails details, int tapCount);
typedef GestureTapAndDragUpdateCallback = void Function(DragUpdateDetails details, int tapCount);
typedef GestureTapAndDragEndCallback = void Function(DragEndDetails details, int tapCount);
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

  GestureTapAndDragEndCallback? onEnd;

  GestureTapAndDragCancelCallback? onCancel;

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
    print('handleEvent $event');
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
