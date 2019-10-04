// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'events.dart';
import 'pointer_router.dart';

/// Signature for listening to [PointerEnterEvent] events.
///
/// Used by [MouseTrackerAnnotation], [Listener] and [RenderPointerListener].
typedef PointerEnterEventListener = void Function(PointerEnterEvent event);

/// Signature for listening to [PointerExitEvent] events.
///
/// Used by [MouseTrackerAnnotation], [Listener] and [RenderPointerListener].
typedef PointerExitEventListener = void Function(PointerExitEvent event);

/// Signature for listening to [PointerHoverEvent] events.
///
/// Used by [MouseTrackerAnnotation], [Listener] and [RenderPointerListener].
typedef PointerHoverEventListener = void Function(PointerHoverEvent event);

class _MouseState {
  _MouseState({
    @required PointerEvent mostRecentEvent ,
  }) : assert(mostRecentEvent != null),
       _mostRecentEvent = mostRecentEvent ;

  // The list of annotations that contains this device during the last frame.
  Set<MouseTrackerAnnotation> lastAnnotations = <MouseTrackerAnnotation>{};

  // The most recent mouse event observed for this device observed.
  //
  // The [mostRecentEvent] is never null.
  PointerEvent get mostRecentEvent {
    assert(_mostRecentEvent != null);
    return _mostRecentEvent;
  }
  set mostRecentEvent(PointerEvent value) {
    assert(value != null);
    _mostRecentEvent = value;
  }
  PointerEvent _mostRecentEvent;

  // Whether this device should be removed the next time it's updated.
  bool pendingRemoval;
}

/// The annotation object used to annotate layers that are interested in mouse
/// movements.
///
/// This is added to a layer and managed by the [Listener] widget.
class MouseTrackerAnnotation {
  /// Creates an annotation that can be used to find layers interested in mouse
  /// movements.
  const MouseTrackerAnnotation({this.onEnter, this.onHover, this.onExit});

  /// Triggered when a pointer has entered the bounding box of the annotated
  /// layer.
  final PointerEnterEventListener onEnter;

  /// Triggered when a pointer has moved within the bounding box of the
  /// annotated layer.
  final PointerHoverEventListener onHover;

  /// Triggered when a pointer has exited the bounding box of the annotated
  /// layer.
  final PointerExitEventListener onExit;

  @override
  String toString() {
    final String none = (onEnter == null && onExit == null && onHover == null) ? ' <none>' : '';
    return '[$runtimeType${hashCode.toRadixString(16)}$none'
        '${onEnter == null ? '' : ' onEnter'}'
        '${onHover == null ? '' : ' onHover'}'
        '${onExit == null ? '' : ' onExit'}]';
  }
}

/// Describes a function that finds an annotation given an offset in logical
/// coordinates.
///
/// It is used by the [MouseTracker] to fetch annotations for the mouse
/// position.
typedef MouseDetectorAnnotationFinder = Iterable<MouseTrackerAnnotation> Function(Offset offset);

/// Keeps state about which objects are interested in tracking mouse positions
/// and notifies them when a mouse pointer enters, moves, or leaves an annotated
/// region that they are interested in.
///
/// This class is a [ChangeNotifier] that notifies its listeners if the value of
/// [mouseIsConnected] changes.
///
/// Owned by the [RendererBinding] class.
class MouseTracker extends ChangeNotifier {
  /// Creates a mouse tracker to keep track of mouse locations.
  ///
  /// All of the parameters must not be null.
  MouseTracker(this._router, this.annotationFinder)
      : assert(_router != null),
        assert(annotationFinder != null) {
    _router.addGlobalRoute(_handleEvent);
  }

  @override
  void dispose() {
    super.dispose();
    _router.removeGlobalRoute(_handleEvent);
  }

  // The pointer router that the mouse tracker listens to for events.
  // The router notifies [MouseTracker] of new mouse events.
  final PointerRouter _router;

  /// Find annotations at a given logical coordinate.
  ///
  /// [MouseTracker] uses this callback to know which annotations are affected
  /// by each device.
  final MouseDetectorAnnotationFinder annotationFinder;

  // Tracks the state of each mouse device. See [_MouseState] for the
  // information it provides.
  //
  // It is a source-of-truth for the list of connected mouse devices, except
  // for the ones whose `pendedRemoval` is true, which will be removed as soon
  // as the next position check.
  final Map<int, _MouseState> _mouseStates = <int, _MouseState>{};

  // The number of attached annotations. When it's 0, [_sendMouseNotifications]
  // is disabled.
  int _annotationCount = 0;
  bool get _hasAttachedAnnotations => _annotationCount > 0;

  // The number of mouse devices that have pended removal.
  int _pendingRemovalCount = 0;

  /// Whether or not a mouse is connected and has produced events.
  bool get mouseIsConnected => _mouseStates.length > _pendingRemovalCount;

  /// Notify [MouseTracker] that a new mouse tracker annotation has started to
  /// take effect.
  ///
  /// This triggers [MouseTracker] to schedule a mouse position check during the
  /// post frame to see if this new annotation might trigger enter events.
  ///
  /// The [MouseTracker] also uses this to track the number of attached
  /// annotations, and will skip mouse position checks if there is no
  /// annotations attached.
  ///
  /// This is typically called when the [AnnotatedRegion] containing this
  /// annotation has been added to the layer tree.
  void attachAnnotation(MouseTrackerAnnotation annotation) {
    // Schedule a check so that we test this new annotation to see if any mouse
    // is currently inside its region. It has to happen after the frame is
    // complete so that the annotation layer has been added before the check.
    if (mouseIsConnected) {
      _scheduleMousePositionCheck();
    }
    _annotationCount++;
  }

  /// Notify [MouseTracker] that a mouse tracker annotation that was previously
  /// attached has stopped taking effect.
  ///
  /// This triggers [MouseTracker] to perform a mouse position check immediately
  /// to see if this annotation removal might trigger exit events.
  ///
  /// The [MouseTracker] also uses this to track the number of attached
  /// annotations, and will skip mouse position checks if there is no
  /// annotations attached.
  ///
  /// This is typically called when the [AnnotatedRegion] containing this
  /// annotation has been removed from the layer tree.
  void detachAnnotation(MouseTrackerAnnotation annotation) {
    _mouseStates.forEach((int device, _MouseState mouseState) {
      if (mouseState.lastAnnotations.contains(annotation)) {
        if (annotation.onExit != null) {
          final PointerEvent event = mouseState.mostRecentEvent;
          assert(event != null);
          annotation.onExit(PointerExitEvent.fromMouseEvent(event));
        }
        mouseState.lastAnnotations.remove(annotation);
      }
    });
    _annotationCount--;
  }

  bool _scheduledPostFramePositionCheck = false;
  // Schedules a position check at the end of this frame for those annotations
  // that have been added.
  void _scheduleMousePositionCheck() {
    // If we're not tracking anything, then there is no point in registering a
    // frame callback or scheduling a frame. By definition there are no active
    // annotations that need exiting, either.
    if (_hasAttachedAnnotations && !_scheduledPostFramePositionCheck) {
      _scheduledPostFramePositionCheck = true;
      SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
        sendMouseNotifications(null);
        _scheduledPostFramePositionCheck = false;
      });
    }
  }

  void _setPendingRemoval(int device, bool value) {
    final _MouseState mouseState = _mouseStates[device];
    assert(mouseState != null);
    if (mouseState.pendingRemoval != value) {
      mouseState.pendingRemoval = value;
      _pendingRemovalCount += value ? 1 : -1;
    }
  }

  // Handler for events coming from the PointerRouter.
  void _handleEvent(PointerEvent event) {
    if (event.kind != PointerDeviceKind.mouse) {
      return;
    }
    final int deviceId = event.device;
    if (event is PointerAddedEvent) {
      _addMouseEvent(deviceId, event);
      // Adding the device again means it's not being removed during this frame.
      _setPendingRemoval(deviceId, false);
      sendMouseNotifications(<int>{deviceId});
    } else if (event is PointerRemovedEvent) {
      _removeMouseEvent(deviceId, event);
      // If the mouse was removed, then we need to schedule one more check to
      // exit any annotations that were active.
      sendMouseNotifications(<int>{deviceId});
    } else if (event is PointerMoveEvent ||
               event is PointerHoverEvent ||
               event is PointerDownEvent) {
      final _MouseState mouseState = _mouseStates[deviceId];
      assert(mouseState != null);
      final PointerEvent previousEvent = mouseState.mostRecentEvent;
      mouseState.mostRecentEvent = event;
      if (previousEvent is PointerAddedEvent || previousEvent.position != event.position) {
        // Only send notifications if we have our first event, or if the
        // location of the mouse has changed, and only if there are tracked annotations.
        sendMouseNotifications(<int>{deviceId});
      }
    }
  }

  /// Collect the latest states of the given mouse devices, and notify those
  /// who are interested of the state changes if applicable.
  ///
  /// Only those devices of [deviceIds] are updated. If [deviceIds] is null,
  /// then all devices are updated.
  ///
  /// This is called synchronously in most cases, except for when a new annotation
  /// is attached, which is called in a post frame callback.
  ///
  /// This function is only public to allow for proper testing of the
  /// MouseTracker. Do not call in other contexts.
  @visibleForTesting
  void sendMouseNotifications(Iterable<int> deviceIds) {
    if (!_hasAttachedAnnotations) {
      return;
    }

    for (int deviceId in deviceIds ?? _mouseStates.keys) {
      final _MouseState mouseState = _mouseStates[deviceId];
      assert(mouseState != null);
      final PointerEvent mostRecentEvent = mouseState.mostRecentEvent;

      // Order is important for mouse event callbacks. The `findAnnotations`
      // returns annotations in the visual order from front to back. We call
      // it the "visual order", and the opposite one "reverse visual order".
      // The algorithm here is explained in https://github.com/flutter/flutter/issues/41420

      // The annotations that contains this device in the coming frame in
      // visual order.
      final Set<MouseTrackerAnnotation> nextAnnotations =
        mouseState.pendingRemoval
        ? const <MouseTrackerAnnotation>{}
        : annotationFinder(mouseState.mostRecentEvent.position).toSet();

      // The annotations that contains this device in the previous frame in
      // visual order.
      final Set<MouseTrackerAnnotation> lastAnnotations = mouseState.lastAnnotations;

      // Send exit events in visual order.
      final Iterable<MouseTrackerAnnotation> exitingAnnotations = lastAnnotations
        .difference(nextAnnotations);
      for (final MouseTrackerAnnotation annotation in exitingAnnotations ) {
        if (annotation.onExit != null) {
          annotation.onExit(PointerExitEvent.fromMouseEvent(mostRecentEvent));
        }
      }

      // Send enter events in reverse visual order.
      final Iterable<MouseTrackerAnnotation> enteringAnnotations = nextAnnotations
        .difference(lastAnnotations).toList().reversed.toList();
      for (final MouseTrackerAnnotation annotation in enteringAnnotations) {
        if (annotation.onEnter != null) {
          annotation.onEnter(PointerEnterEvent.fromMouseEvent(mostRecentEvent));
        }
      }

      // Send hover events in reverse visual order.
      if (mostRecentEvent is PointerHoverEvent) {
        for (final MouseTrackerAnnotation annotation in nextAnnotations) {
          if (annotation.onHover != null) {
            annotation.onHover(mostRecentEvent);
          }
        }
      }

      mouseState.lastAnnotations = nextAnnotations;
      if (mouseState.pendingRemoval) {
        _mouseStates.remove(deviceId);
        _pendingRemovalCount--;
      }
    }
  }

  void _addMouseEvent(int deviceId, PointerEvent event) {
    final bool wasConnected = mouseIsConnected;
    assert(!_mouseStates.containsKey(deviceId)
        || _mouseStates[deviceId].pendingRemoval,
      'Unexpected request to add device $deviceId, which has already been '
      'added and is not pending removal.');
    _mouseStates.putIfAbsent(deviceId, () => _MouseState(mostRecentEvent: event));
    // Adding the device again means it's not being removed during this frame.
    _setPendingRemoval(deviceId, false);
    if (mouseIsConnected != wasConnected) {
      notifyListeners();
    }
  }

  void _removeMouseEvent(int deviceId, PointerEvent event) {
    final bool wasConnected = mouseIsConnected;
    assert(_mouseStates.containsKey(deviceId),
      'Unexpected request to remove device $deviceId, which has not been '
      'added yet.');
    assert(event is PointerRemovedEvent);
    _setPendingRemoval(deviceId, true);
    _mouseStates[deviceId].mostRecentEvent = event;
    if (mouseIsConnected != wasConnected) {
      notifyListeners();
    }
  }
}
