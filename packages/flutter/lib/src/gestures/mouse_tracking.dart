// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart' show ChangeNotifier, visibleForTesting;
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

// Used internally by the MouseTracker for accounting for which annotation is
// active on which devices inside of the MouseTracker.
class _TrackedAnnotation {
  _TrackedAnnotation(this.annotation);

  final MouseTrackerAnnotation annotation;

  /// Tracks devices that are currently active for this annotation.
  ///
  /// If the mouse pointer corresponding to the integer device ID is
  /// present in the Set, then it is currently inside of the annotated layer.
  ///
  /// This is used to detect layers that used to have the mouse pointer inside
  /// them, but now no longer do (to facilitate exit notification).
  Set<int> activeDevices = <int>{};
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
  final PointerRouter _router;

  /// Used to find annotations at a given logical coordinate.
  final MouseDetectorAnnotationFinder annotationFinder;

  // The collection of annotations that are currently being tracked. They may or
  // may not be active, depending on the value of _TrackedAnnotation.active.
  final Map<MouseTrackerAnnotation, _TrackedAnnotation> _trackedAnnotations = <MouseTrackerAnnotation, _TrackedAnnotation>{};

  /// Track an annotation so that if the mouse enters it, we send it events.
  ///
  /// This is typically called when the [AnnotatedRegion] containing this
  /// annotation has been added to the layer tree.
  void attachAnnotation(MouseTrackerAnnotation annotation) {
    _trackedAnnotations[annotation] = _TrackedAnnotation(annotation);
    // Schedule a check so that we test this new annotation to see if any mouse
    // is currently inside its region. It has to happen after the frame is
    // complete so that the annotation layer has been added before the check.
    if (mouseIsConnected) {
      _scheduleMousePositionCheck();
    }
  }

  /// Stops tracking an annotation, indicating that it has been removed from the
  /// layer tree.
  ///
  /// An assertion error will be thrown if the associated layer is not removed
  /// and receives another mouse hit.
  void detachAnnotation(MouseTrackerAnnotation annotation) {
    final _TrackedAnnotation trackedAnnotation = _findAnnotation(annotation);
    for (int deviceId in trackedAnnotation.activeDevices) {
      if (annotation.onExit != null) {
        final PointerEvent event = _lastMouseEvent[deviceId] ?? _pendingRemovals[deviceId];
        assert(event != null);
        annotation.onExit(PointerExitEvent.fromMouseEvent(event));
      }
    }
    _trackedAnnotations.remove(annotation);
  }

  bool _scheduledPostFramePositionCheck = false;
  // Schedules a position check at the end of this frame for those annotations
  // that have been added.
  void _scheduleMousePositionCheck() {
    // If we're not tracking anything, then there is no point in registering a
    // frame callback or scheduling a frame. By definition there are no active
    // annotations that need exiting, either.
    if (_trackedAnnotations.isNotEmpty && !_scheduledPostFramePositionCheck) {
      _scheduledPostFramePositionCheck = true;
      SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
        _sendMouseNotifications(_lastMouseEvent.keys);
        _scheduledPostFramePositionCheck = false;
      });
    }
  }

  // Handler for events coming from the PointerRouter.
  void _handleEvent(PointerEvent event) {
    if (event.kind != PointerDeviceKind.mouse) {
      return;
    }
    final int deviceId = event.device;
    if (event is PointerAddedEvent) {
      // If we are adding the device again, then we're not removing it anymore.
      _pendingRemovals.remove(deviceId);
      _addMouseEvent(deviceId, event);
      _sendMouseNotifications(<int>{deviceId});
      return;
    }
    if (event is PointerRemovedEvent) {
      _removeMouseEvent(deviceId, event);
      // If the mouse was removed, then we need to schedule one more check to
      // exit any annotations that were active.
      _sendMouseNotifications(<int>{deviceId});
    } else {
      if (event is PointerMoveEvent || event is PointerHoverEvent || event is PointerDownEvent) {
        final PointerEvent lastEvent = _lastMouseEvent[deviceId];
        _addMouseEvent(deviceId, event);
        if (lastEvent == null ||
            lastEvent is PointerAddedEvent || lastEvent.position != event.position) {
          // Only schedule a frame if we have our first event, or if the
          // location of the mouse has changed, and only if there are tracked annotations.
          _sendMouseNotifications(<int>{deviceId});
        }
      }
    }
  }

  _TrackedAnnotation _findAnnotation(MouseTrackerAnnotation annotation) {
    final _TrackedAnnotation trackedAnnotation = _trackedAnnotations[annotation];
    assert(
        trackedAnnotation != null,
        'Unable to find annotation $annotation in tracked annotations. '
        'Check that attachAnnotation has been called for all annotated layers.');
    return trackedAnnotation;
  }

  /// Checks if the given [MouseTrackerAnnotation] is attached to this
  /// [MouseTracker].
  ///
  /// This function is only public to allow for proper testing of the
  /// MouseTracker. Do not call in other contexts.
  @visibleForTesting
  bool isAnnotationAttached(MouseTrackerAnnotation annotation) {
    return _trackedAnnotations.containsKey(annotation);
  }

  // Tells interested objects that a mouse has entered, exited, or moved, given
  // a callback to fetch the [MouseTrackerAnnotation] associated with a global
  // offset.
  //
  // This is called from a post-frame callback when the layer tree has been
  // updated, right after rendering the frame.
  void _sendMouseNotifications(Iterable<int> deviceIds) {
    if (_trackedAnnotations.isEmpty) {
      return;
    }

    void exitAnnotation(_TrackedAnnotation trackedAnnotation, int deviceId) {
      if (trackedAnnotation.annotation?.onExit != null && trackedAnnotation.activeDevices.contains(deviceId)) {
        final PointerEvent event = _lastMouseEvent[deviceId] ?? _pendingRemovals[deviceId];
        assert(event != null);
        trackedAnnotation.annotation.onExit(PointerExitEvent.fromMouseEvent(event));
      }
      trackedAnnotation.activeDevices.remove(deviceId);
    }

    void exitAllDevices(_TrackedAnnotation trackedAnnotation) {
      if (trackedAnnotation.activeDevices.isNotEmpty) {
        final Set<int> deviceIds = trackedAnnotation.activeDevices.toSet();
        for (int deviceId in deviceIds) {
          exitAnnotation(trackedAnnotation, deviceId);
        }
      }
    }

    try {
      // This indicates that all mouse pointers were removed, or none have been
      // connected yet. If no mouse is connected, then we want to make sure that
      // all active annotations are exited.
      if (!mouseIsConnected) {
        _trackedAnnotations.values.forEach(exitAllDevices);
        return;
      }

      for (int deviceId in deviceIds) {
        final PointerEvent lastEvent = _lastMouseEvent[deviceId];
        assert(lastEvent != null);
        final Iterable<MouseTrackerAnnotation> hits = annotationFinder(lastEvent.position);

        // No annotations were found at this position for this deviceId, so send an
        // exit to all active tracked annotations, since none of them were hit.
        if (hits.isEmpty) {
          // Send an exit to all tracked animations tracking this deviceId.
          for (_TrackedAnnotation trackedAnnotation in _trackedAnnotations.values) {
            exitAnnotation(trackedAnnotation, deviceId);
          }
          continue;
        }

        final Set<_TrackedAnnotation> hitAnnotations = hits.map<_TrackedAnnotation>((MouseTrackerAnnotation hit) => _findAnnotation(hit)).toSet();
        for (_TrackedAnnotation hitAnnotation in hitAnnotations) {
          if (!hitAnnotation.activeDevices.contains(deviceId)) {
            // A tracked annotation that just became active and needs to have an enter
            // event sent to it.
            hitAnnotation.activeDevices.add(deviceId);
            if (hitAnnotation.annotation?.onEnter != null) {
              hitAnnotation.annotation.onEnter(PointerEnterEvent.fromMouseEvent(lastEvent));
            }
          }
          if (hitAnnotation.annotation?.onHover != null && lastEvent is PointerHoverEvent) {
            hitAnnotation.annotation.onHover(lastEvent);
          }

          // Tell any tracked annotations that weren't hit that they are no longer
          // active.
          for (_TrackedAnnotation trackedAnnotation in _trackedAnnotations.values) {
            if (hitAnnotations.contains(trackedAnnotation)) {
              continue;
            }
            if (trackedAnnotation.activeDevices.contains(deviceId)) {
              if (trackedAnnotation.annotation?.onExit != null) {
                trackedAnnotation.annotation.onExit(PointerExitEvent.fromMouseEvent(lastEvent));
              }
              trackedAnnotation.activeDevices.remove(deviceId);
            }
          }
        }
      }
    } finally {
      _pendingRemovals.clear();
    }
  }

  void _addMouseEvent(int deviceId, PointerEvent event) {
    final bool wasConnected = mouseIsConnected;
    if (event is PointerAddedEvent) {
      // If we are adding the device again, then we're not removing it anymore.
      _pendingRemovals.remove(deviceId);
    }
    _lastMouseEvent[deviceId] = event;
    if (mouseIsConnected != wasConnected) {
      notifyListeners();
    }
  }

  void _removeMouseEvent(int deviceId, PointerEvent event) {
    final bool wasConnected = mouseIsConnected;
    assert(event is PointerRemovedEvent);
    _pendingRemovals[deviceId] = event;
    _lastMouseEvent.remove(deviceId);
    if (mouseIsConnected != wasConnected) {
      notifyListeners();
    }
  }

  // A list of device IDs that should be removed and notified when scheduling a
  // mouse position check.
  final Map<int, PointerRemovedEvent> _pendingRemovals = <int, PointerRemovedEvent>{};

  /// The most recent mouse event observed for each mouse device ID observed.
  ///
  /// May be null if no mouse is connected, or hasn't produced an event yet.
  final Map<int, PointerEvent> _lastMouseEvent = <int, PointerEvent>{};

  /// Whether or not a mouse is connected and has produced events.
  bool get mouseIsConnected => _lastMouseEvent.isNotEmpty;
}
