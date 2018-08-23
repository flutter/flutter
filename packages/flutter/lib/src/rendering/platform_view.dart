// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'box.dart';
import 'layer.dart';
import 'object.dart';


/// How an embedded platform view behave during hit tests.
enum PlatformViewHitTestBehavior {
  /// Opaque targets can be hit by hit tests, causing them to both receive
  /// events within their bounds and prevent targets visually behind them from
  /// also receiving events.
  opaque,

  /// Translucent targets both receive events within their bounds and permit
  /// targets visually behind them to also receive events.
  translucent,

  /// Transparent targets don't receive events within their bounds and permit
  /// targets visually behind them to receive events.
  transparent,
}

enum _PlatformViewState {
  uninitialized,
  resizing,
  ready,
}

/// A render object for an Android view.
///
/// [RenderAndroidView] is responsible for sizing, displaying and passing touch events to an
/// Android [View](https://developer.android.com/reference/android/view/View).
///
/// The render object's layout behavior is to fill all available space, the parent of this object must
/// provide bounded layout constraints
///
/// See also:
///  * [AndroidView] which is a widget that is used to show an Android view.
///  * [PlatformViewsService] which is a service for controlling platform views.
class RenderAndroidView extends RenderBox {

  /// Creates a render object for an Android view.
  RenderAndroidView({
    @required AndroidViewController viewController,
    @required this.hitTestBehavior,
  }) : assert(viewController != null),
       assert(hitTestBehavior != null),
       _viewController = viewController {
    _motionEventsDispatcher = new _MotionEventsDispatcher(globalToLocal, viewController);
  }

  _PlatformViewState _state = _PlatformViewState.uninitialized;

  /// The Android view controller for the Android view associated with this render object.
  AndroidViewController get viewcontroller => _viewController;
  AndroidViewController _viewController;
  /// Sets a new Android view controller.
  ///
  /// `viewController` must not be null.
  set viewController(AndroidViewController viewController) {
    assert(_viewController != null);
    if (_viewController == viewController)
      return;
    _viewController = viewController;
    _sizePlatformView();
  }

  /// How to behave during hit testing.
  // The implicit setter is enough here as changing this value will just affect
  // any newly arriving events there's nothing we need to invalidate.
  PlatformViewHitTestBehavior hitTestBehavior;

  @override
  bool get sizedByParent => true;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool get isRepaintBoundary => true;

  _MotionEventsDispatcher _motionEventsDispatcher;

  @override
  void performResize() {
    size = constraints.biggest;
    _sizePlatformView();
  }

  Size _currentAndroidViewSize;

  Future<Null> _sizePlatformView() async {
    // Android virtual displays cannot have a zero size.
    // Trying to size it to 0 crashes the app, which was happening when starting the app
    // with a locked screen (see: https://github.com/flutter/flutter/issues/20456).
    if (_state == _PlatformViewState.resizing || size.isEmpty) {
      return;
    }

    _state = _PlatformViewState.resizing;
    markNeedsPaint();

    Size targetSize;
    do {
      targetSize = size;
      await _viewController.setSize(targetSize);
      _currentAndroidViewSize = targetSize;
      // We've resized the platform view to targetSize, but it is possible that
      // while we were resizing the render object's size was changed again.
      // In that case we will resize the platform view again.
    } while (size != targetSize);

    _state = _PlatformViewState.ready;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_viewController.textureId == null)
      return;

    // Clip the texture if it's going to paint out of the bounds of the renter box
    // (see comment in _paintTexture for an explanation of when this happens).
    if (size.width < _currentAndroidViewSize.width || size.height < _currentAndroidViewSize.height) {
      context.pushClipRect(true, offset, offset & size, _paintTexture);
      return;
    }

    _paintTexture(context, offset);
  }

  void _paintTexture(PaintingContext context, Offset offset) {
    // As resizing the Android view happens asynchronously we don't know exactly when is a
    // texture frame with the new size is ready for consumption.
    // TextureLayer is unaware of the texture frame's size and always maps it to the
    // specified rect. If the rect we provide has a different size from the current texture frame's
    // size the texture frame will be scaled.
    // To prevent unwanted scaling artifacts while resizing we freeze the texture frame, until
    // we know that a frame with the new size is in the buffer.
    // This guarantees that the size of the texture frame we're painting is always
    // _currentAndroidViewSize.
    context.addLayer(new TextureLayer(
      rect: offset & _currentAndroidViewSize,
      textureId: _viewController.textureId,
      freeze: _state == _PlatformViewState.resizing,
    ));
  }

  @override
  bool hitTest(HitTestResult result, { Offset position }) {
    if (hitTestBehavior == PlatformViewHitTestBehavior.transparent || !size.contains(position))
      return false;
    result.add(new BoxHitTestEntry(this, position));
    return hitTestBehavior == PlatformViewHitTestBehavior.opaque;
  }

  @override
  bool hitTestSelf(Offset position) => hitTestBehavior != PlatformViewHitTestBehavior.transparent;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    _motionEventsDispatcher.handlePointerEvent(event);
  }
}

typedef Offset _GlobalToLocal(Offset point);

// Composes a stream of PointerEvent objects into AndroidMotionEvent objects
// and dispatches them to the associated embedded Android view.
class _MotionEventsDispatcher {
  _MotionEventsDispatcher(this.globalToLocal, this.viewController);

  final Map<int, AndroidPointerCoords> pointerPositions = <int, AndroidPointerCoords>{};
  final Map<int, AndroidPointerProperties> pointerProperties = <int, AndroidPointerProperties>{};
  final _GlobalToLocal globalToLocal;
  final AndroidViewController viewController;

  int nextPointerId = 0;
  int downTimeMillis;

  void handlePointerEvent(PointerEvent event) {
    if (event is PointerDownEvent) {
      if (nextPointerId == 0)
        downTimeMillis = event.timeStamp.inMilliseconds;
      pointerProperties[event.pointer] = propertiesFor(event, nextPointerId++);
    }
    pointerPositions[event.pointer] = coordsFor(event);

    dispatchPointerEvent(event);

    if (event is PointerUpEvent) {
      pointerPositions.remove(event.pointer);
      pointerProperties.remove(event.pointer);
      if (pointerProperties.isEmpty) {
        nextPointerId = 0;
        downTimeMillis = null;
      }
    }
    if (event is PointerCancelEvent) {
      pointerPositions.clear();
      pointerProperties.clear();
      nextPointerId = 0;
      downTimeMillis = null;
    }
  }

  void dispatchPointerEvent(PointerEvent event) {
    final List<int> pointers = pointerPositions.keys.toList();
    final int pointerIdx = pointers.indexOf(event.pointer);
    final int numPointers = pointers.length;

    // Android MotionEvent objects can batch information on multiple pointers.
    // Flutter breaks these such batched events into multiple PointerEvent objects.
    // When there are multiple active pointers we accumulate the information for all pointers
    // as we get PointerEvents, and only send it to the embedded Android view when
    // we see the last pointer. This way we achieve the same batching as Android.
    if(isSinglePointerAction(event) && pointerIdx < numPointers - 1)
      return;

    int action;
    switch(event.runtimeType){
      case PointerDownEvent:
        action = numPointers == 1 ? AndroidViewController.kActionDown
            : AndroidViewController.pointerAction(pointerIdx, AndroidViewController.kActionPointerDown);
        break;
      case PointerUpEvent:
        action = numPointers == 1 ? AndroidViewController.kActionUp
            : AndroidViewController.pointerAction(pointerIdx, AndroidViewController.kActionPointerUp);
        break;
      case PointerMoveEvent:
        action = AndroidViewController.kActionMove;
        break;
      case PointerCancelEvent:
        action = AndroidViewController.kActionCancel;
        break;
      default:
        return;
    }

    final AndroidMotionEvent androidMotionEvent = new AndroidMotionEvent(
        downTime: downTimeMillis,
        eventTime: event.timeStamp.inMilliseconds,
        action: action,
        pointerCount: pointerPositions.length,
        pointerProperties: pointers.map((int i) => pointerProperties[i]).toList(),
        pointerCoords: pointers.map((int i) => pointerPositions[i]).toList(),
        metaState: 0,
        buttonState: 0,
        xPrecision: 1.0,
        yPrecision: 1.0,
        deviceId: 0,
        edgeFlags: 0,
        source: 0,
        flags: 0
    );
    viewController.sendMotionEvent(androidMotionEvent);
  }

  AndroidPointerCoords coordsFor(PointerEvent event) {
    final Offset position = globalToLocal(event.position);
    return new AndroidPointerCoords(
        orientation: event.orientation,
        pressure: event.pressure,
        // Currently the engine omits the pointer size, for now I'm fixing this to 0.33 which is roughly
        // what I typically see on Android.
        //
        // TODO(amirh): Use the original pointer's size.
        // https://github.com/flutter/flutter/issues/20300
        size: 0.333,
        toolMajor: event.radiusMajor,
        toolMinor: event.radiusMinor,
        touchMajor: event.radiusMajor,
        touchMinor: event.radiusMinor,
        x: position.dx,
        y: position.dy
    );
  }

  AndroidPointerProperties propertiesFor(PointerEvent event, int pointerId) {
    int toolType = AndroidPointerProperties.kToolTypeUnknown;
    switch(event.kind) {
      case PointerDeviceKind.touch:
        toolType = AndroidPointerProperties.kToolTypeFinger;
        break;
      case PointerDeviceKind.mouse:
        toolType = AndroidPointerProperties.kToolTypeMouse;
        break;
      case PointerDeviceKind.stylus:
        toolType = AndroidPointerProperties.kToolTypeStylus;
        break;
      case PointerDeviceKind.invertedStylus:
        toolType = AndroidPointerProperties.kToolTypeEraser;
        break;
      case PointerDeviceKind.unknown:
        toolType = AndroidPointerProperties.kToolTypeUnknown;
        break;
    }
    return new AndroidPointerProperties(id: pointerId, toolType: toolType);
  }

  bool isSinglePointerAction(PointerEvent event) =>
      !(event is PointerDownEvent) && !(event is PointerUpEvent);
}

