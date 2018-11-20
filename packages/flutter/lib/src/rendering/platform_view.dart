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

bool _factoryTypesSetEquals<T>(Set<Factory<T>> a, Set<Factory<T>> b) {
  if (a == b) {
    return true;
  }
  if (a == null ||  b == null) {
    return false;
  }
  return setEquals(_factoriesTypeSet(a), _factoriesTypeSet(b));
}

Set<Type> _factoriesTypeSet<T>(Set<Factory<T>> factories) {
  return factories.map<Type>((Factory<T> factory) => factory.type).toSet();
}

/// A render object for an Android view.
///
/// Requires Android API level 20 or greater.
///
/// [RenderAndroidView] is responsible for sizing, displaying and passing touch events to an
/// Android [View](https://developer.android.com/reference/android/view/View).
///
/// {@template flutter.rendering.platformView.layout}
/// The render object's layout behavior is to fill all available space, the parent of this object must
/// provide bounded layout constraints.
/// {@endtemplate}
///
/// {@template flutter.rendering.platformView.gestures}
/// The render object participates in Flutter's [GestureArena]s, and dispatches touch events to the
/// platform view iff it won the arena. Specific gestures that should be dispatched to the platform
/// view can be specified with factories in the `gestureRecognizers` constructor parameter or
/// by calling `updateGestureRecognizers`. If the set of gesture recognizers is empty, the gesture
/// will be dispatched to the platform view iff it was not claimed by any other gesture recognizer.
/// {@endtemplate}
///
/// See also:
///  * [AndroidView] which is a widget that is used to show an Android view.
///  * [PlatformViewsService] which is a service for controlling platform views.
class RenderAndroidView extends RenderBox {

  /// Creates a render object for an Android view.
  RenderAndroidView({
    @required AndroidViewController viewController,
    @required this.hitTestBehavior,
    @required Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers,
  }) : assert(viewController != null),
       assert(hitTestBehavior != null),
       assert(gestureRecognizers != null),
       _viewController = viewController
  {
    _motionEventsDispatcher = _MotionEventsDispatcher(globalToLocal, viewController);
    updateGestureRecognizers(gestureRecognizers);
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

  /// {@template flutter.rendering.platformView.updateGestureRecognizers}
  /// Updates which gestures should be forwarded to the platform view.
  ///
  /// Gesture recognizers created by factories in this set participate in the gesture arena for each
  /// pointer that was put down on the render box. If any of the recognizers on this list wins the
  /// gesture arena, the entire pointer event sequence starting from the pointer down event
  /// will be dispatched to the Android view.
  ///
  /// The `gestureRecognizers` property must not contain more than one factory with the same [Factory.type].
  ///
  /// Setting a new set of gesture recognizer factories with the same [Factory.type]s as the current
  /// set has no effect, because the factories' constructors would have already been called with the previous set.
  /// {@endtemplate}
  ///
  /// Any active gesture arena the Android view participates in is rejected when the
  /// set of gesture recognizers is changed.
  void updateGestureRecognizers(Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers) {
    assert(gestureRecognizers != null);
    assert(
    _factoriesTypeSet(gestureRecognizers).length == gestureRecognizers.length,
    'There were multiple gesture recognizer factories for the same type, there must only be a single '
        'gesture recognizer factory for each gesture recognizer type.',);
    if (_factoryTypesSetEquals(gestureRecognizers, _gestureRecognizer?.gestureRecognizerFactories)) {
      return;
    }
    _gestureRecognizer?.dispose();
    _gestureRecognizer = _AndroidViewGestureRecognizer(_motionEventsDispatcher, gestureRecognizers);
  }

  @override
  bool get sizedByParent => true;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool get isRepaintBoundary => true;

  _MotionEventsDispatcher _motionEventsDispatcher;

  _AndroidViewGestureRecognizer _gestureRecognizer;

  @override
  void performResize() {
    size = constraints.biggest;
    _sizePlatformView();
  }

  Size _currentAndroidViewSize;

  Future<void> _sizePlatformView() async {
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
    context.addLayer(TextureLayer(
      rect: offset & _currentAndroidViewSize,
      textureId: _viewController.textureId,
      freeze: _state == _PlatformViewState.resizing,
    ));
  }

  @override
  bool hitTest(HitTestResult result, { Offset position }) {
    if (hitTestBehavior == PlatformViewHitTestBehavior.transparent || !size.contains(position))
      return false;
    result.add(BoxHitTestEntry(this, position));
    return hitTestBehavior == PlatformViewHitTestBehavior.opaque;
  }

  @override
  bool hitTestSelf(Offset position) => hitTestBehavior != PlatformViewHitTestBehavior.transparent;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (event is PointerDownEvent) {
      _gestureRecognizer.addPointer(event);
    }
  }

  @override
  void detach() {
    _gestureRecognizer.reset();
    super.detach();
  }
}

/// A render object for an iOS UIKit UIView.
///
/// {@template flutter.rendering.platformView.preview}
/// Embedding UIViews is still in release preview, to enable the preview for an iOS app add a boolean
/// field with the key 'io.flutter.embedded_views_preview' and the value set to 'YES' to the
/// application's Info.plist file. A list of open issued with embedding UIViews is available on
/// [Github](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3A%22a%3A+platform-views%22+label%3A%22%E2%8C%BA%E2%80%AC+platform-ios%22)
/// {@endtemplate}
///
/// [RenderUiKitView] is responsible for sizing and displaying an iOS
/// [UIView](https://developer.apple.com/documentation/uikit/uiview).
///
/// UIViews are added as sub views of the FlutterView and are composited by Quartz.
///
/// {@macro flutter.rendering.platformView.layout}
///
/// {@macro flutter.rendering.platformView.gestures}
///
/// See also:
///  * [UiKitView] which is a widget that is used to show a UIView.
///  * [PlatformViewsService] which is a service for controlling platform views.
class RenderUiKitView extends RenderBox {
  /// Creates a render object for an iOS UIView.
  ///
  /// The `viewId`, `hitTestBehavior`, and `gestureRecognizers` parameters must not be null.
  RenderUiKitView({
    @required UiKitViewController viewController,
    @required this.hitTestBehavior,
    @required Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers,
  }) : assert(viewController != null),
       assert(hitTestBehavior != null),
       assert(gestureRecognizers != null),
       _viewController = viewController {
    updateGestureRecognizers(gestureRecognizers);
  }


  /// The unique identifier of the UIView controlled by this controller.
  ///
  /// Typically generated by [PlatformViewsRegistry.getNextPlatformViewId], the UIView
  /// must have been created by calling [PlatformViewsService.initUiKitView].
  UiKitViewController get viewController => _viewController;
  UiKitViewController _viewController;
  set viewController(UiKitViewController viewId) {
    assert(viewId != null);
    _viewController = viewId;
    markNeedsPaint();
  }

  /// How to behave during hit testing.
  // The implicit setter is enough here as changing this value will just affect
  // any newly arriving events there's nothing we need to invalidate.
  PlatformViewHitTestBehavior hitTestBehavior;

  /// {@macro flutter.rendering.platformView.updateGestureRecognizers}
  void updateGestureRecognizers(Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers) {
    assert(gestureRecognizers != null);
    assert(
    _factoriesTypeSet(gestureRecognizers).length == gestureRecognizers.length,
    'There were multiple gesture recognizer factories for the same type, there must only be a single '
        'gesture recognizer factory for each gesture recognizer type.',);
    if (_factoryTypesSetEquals(gestureRecognizers, _gestureRecognizer?.gestureRecognizerFactories)) {
      return;
    }
    _gestureRecognizer?.dispose();
    _gestureRecognizer = _UiKitViewGestureRecognizer(viewController, gestureRecognizers);
  }

  @override
  bool get sizedByParent => true;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool get isRepaintBoundary => true;

  _UiKitViewGestureRecognizer _gestureRecognizer;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.addLayer(PlatformViewLayer(
      rect: offset & size,
      viewId: _viewController.id,
    ));
  }

  @override
  bool hitTest(HitTestResult result, { Offset position }) {
    if (hitTestBehavior == PlatformViewHitTestBehavior.transparent || !size.contains(position))
      return false;
    result.add(BoxHitTestEntry(this, position));
    return hitTestBehavior == PlatformViewHitTestBehavior.opaque;
  }

  @override
  bool hitTestSelf(Offset position) => hitTestBehavior != PlatformViewHitTestBehavior.transparent;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    if (event is PointerDownEvent) {
      _gestureRecognizer.addPointer(event);
    }
  }

  @override
  void detach() {
    _gestureRecognizer.reset();
    super.detach();
  }
}

// This recognizer constructs gesture recognizers from a set of gesture recognizer factories
// it was give, adds all of them to a gesture arena team with the _UiKitViewGesturrRecognizer
// as the team captain.
// When the team wins a gesture the recognizer notifies the engine that it should release
// the touch sequence to the embedded UIView.
class _UiKitViewGestureRecognizer extends OneSequenceGestureRecognizer {
  _UiKitViewGestureRecognizer(this.controller, this.gestureRecognizerFactories) {
    team = GestureArenaTeam();
    team.captain = this;
    _gestureRecognizers = gestureRecognizerFactories.map(
      (Factory<OneSequenceGestureRecognizer> recognizerFactory) {
        return recognizerFactory.constructor()..team = team;
      },
    ).toSet();
  }


  // We use OneSequenceGestureRecognizers as they support gesture arena teams.
  // TODO(amirh): get a list of GestureRecognizers here.
  // https://github.com/flutter/flutter/issues/20953
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizerFactories;
  Set<OneSequenceGestureRecognizer> _gestureRecognizers;

  final UiKitViewController controller;

  @override
  void addPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer);
    for (OneSequenceGestureRecognizer recognizer in _gestureRecognizers) {
      recognizer.addPointer(event);
    }
  }

  @override
  String get debugDescription => 'UIKit view';

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  void handleEvent(PointerEvent event) {
    stopTrackingIfPointerNoLongerDown(event);
  }

  @override
  void acceptGesture(int pointer) {
    controller.acceptGesture();
  }

  @override
  void rejectGesture(int pointer) {
    // Currently the engine rejects the gesture when the sequence is done.
    // This doesn't work well with gesture recognizers that recognize after the sequence
    // has ended.
    // TODO(amirh): trigger an engine gesture reject here.
    // https://github.com/flutter/flutter/issues/24076
  }

  void reset() {
    resolve(GestureDisposition.rejected);
  }
}

// This recognizer constructs gesture recognizers from a set of gesture recognizer factories
// it was give, adds all of them to a gesture arena team with the _AndroidViewGestureRecognizer
// as the team captain.
// As long as ta gesture arena is unresolved the recognizer caches all pointer events.
// When the team wins the recognizer sends all the cached point events to the embedded Android view, and
// sets itself to a "forwarding mode" where it will forward any new pointer event to the Android view.
class _AndroidViewGestureRecognizer extends OneSequenceGestureRecognizer {
  _AndroidViewGestureRecognizer(this.dispatcher, this.gestureRecognizerFactories) {
    team = GestureArenaTeam();
    team.captain = this;
    _gestureRecognizers = gestureRecognizerFactories.map(
      (Factory<OneSequenceGestureRecognizer> recognizerFactory) {
        return recognizerFactory.constructor()..team = team;
      },
    ).toSet();
  }

  final _MotionEventsDispatcher dispatcher;

  // Maps a pointer to a list of its cached pointer events.
  // Before the arena for a pointer is resolved all events are cached here, if we win the arena
  // the cached events are dispatched to the view, if we lose the arena we clear the cache for
  // the pointer.
  final Map<int, List<PointerEvent>> cachedEvents = <int, List<PointerEvent>> {};

  // Pointer for which we have already won the arena, events for pointers in this set are
  // immediately dispatched to the Android view.
  final Set<int> forwardedPointers = Set<int>();

  // We use OneSequenceGestureRecognizers as they support gesture arena teams.
  // TODO(amirh): get a list of GestureRecognizers here.
  // https://github.com/flutter/flutter/issues/20953
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizerFactories;
  Set<OneSequenceGestureRecognizer> _gestureRecognizers;

  @override
  void addPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer);
    for (OneSequenceGestureRecognizer recognizer in _gestureRecognizers) {
      recognizer.addPointer(event);
    }
  }

  @override
  String get debugDescription => 'Android view';

  @override
  void didStopTrackingLastPointer(int pointer) {}

  @override
  void handleEvent(PointerEvent event) {
    if (!forwardedPointers.contains(event.pointer)) {
      cacheEvent(event);
    } else {
      dispatcher.handlePointerEvent(event);
    }
    stopTrackingIfPointerNoLongerDown(event);
  }

  @override
  void acceptGesture(int pointer) {
    flushPointerCache(pointer);
    forwardedPointers.add(pointer);
  }

  @override
  void rejectGesture(int pointer) {
    stopTrackingPointer(pointer);
    cachedEvents.remove(pointer);
  }

  void cacheEvent(PointerEvent event) {
    if (!cachedEvents.containsKey(event.pointer)) {
      cachedEvents[event.pointer] = <PointerEvent> [];
    }
    cachedEvents[event.pointer].add(event);
  }

  void flushPointerCache(int pointer) {
    cachedEvents.remove(pointer)?.forEach(dispatcher.handlePointerEvent);
  }

  @override
  void stopTrackingPointer(int pointer) {
    super.stopTrackingPointer(pointer);
    forwardedPointers.remove(pointer);
  }

  void reset() {
    forwardedPointers.forEach(super.stopTrackingPointer);
    forwardedPointers.clear();
    cachedEvents.keys.forEach(super.stopTrackingPointer);
    cachedEvents.clear();
    resolve(GestureDisposition.rejected);
  }
}

typedef _GlobalToLocal = Offset Function(Offset point);

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

    // This value must match the value in engine's FlutterView.java.
    // This flag indicates whether the original Android pointer events were batched together.
    const int kPointerDataFlagBatched = 1;

    // Android MotionEvent objects can batch information on multiple pointers.
    // Flutter breaks these such batched events into multiple PointerEvent objects.
    // When there are multiple active pointers we accumulate the information for all pointers
    // as we get PointerEvents, and only send it to the embedded Android view when
    // we see the last pointer. This way we achieve the same batching as Android.
    if (event.platformData == kPointerDataFlagBatched ||
        (isSinglePointerAction(event) && pointerIdx < numPointers - 1))
      return;

    int action;
    switch (event.runtimeType) {
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

    final AndroidMotionEvent androidMotionEvent = AndroidMotionEvent(
        downTime: downTimeMillis,
        eventTime: event.timeStamp.inMilliseconds,
        action: action,
        pointerCount: pointerPositions.length,
        pointerProperties: pointers.map<AndroidPointerProperties>((int i) => pointerProperties[i]).toList(),
        pointerCoords: pointers.map<AndroidPointerCoords>((int i) => pointerPositions[i]).toList(),
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
    return AndroidPointerCoords(
        orientation: event.orientation,
        pressure: event.pressure,
        size: event.size,
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
    return AndroidPointerProperties(id: pointerId, toolType: toolType);
  }

  bool isSinglePointerAction(PointerEvent event) =>
      !(event is PointerDownEvent) && !(event is PointerUpEvent);
}

