// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/scheduler.dart';

import 'events.dart';
import 'pointer_router.dart';

class _MouseDetails {
  _MouseDetails({this.sourceTimeStamp, this.globalPosition});

  /// Recorded timestamp of the source pointer event that last reported its
  /// position.
  ///
  /// May be null if the mouse pointer is removed while the mouse pointer is
  /// being tracked.
  final Duration sourceTimeStamp;

  /// The pointer's global position when it triggered this event in logical
  /// pixels.
  ///
  /// May be null if the mouse pointer is removed while the mouse pointer is
  /// being tracked.
  final Offset globalPosition;

  @override
  int get hashCode => hashValues(sourceTimeStamp, globalPosition);

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return sourceTimeStamp == other.sourceTimeStamp
      && globalPosition == other.globalPosition;
  }

  @override
  String toString() => '$runtimeType(globalPosition: $globalPosition, sourceTimeStamp: $sourceTimeStamp)';
}

/// Details object for [MouseEnterCallback]s.
class MouseEnterDetails extends _MouseDetails {
  /// Creates details for a [MouseMoveCallback] call.
  ///
  /// The [globalPosition] argument must be provided and must not be null.
  MouseEnterDetails({Duration sourceTimeStamp, Offset globalPosition})
      : super(sourceTimeStamp: sourceTimeStamp, globalPosition: globalPosition);
}

/// The `details` object provides the position of the mouse pointer at the
/// time of entry.
typedef MouseEnterCallback = void Function(MouseEnterDetails details);

/// Details object for callbacks that use [MouseMoveCallback].
class MouseMoveDetails extends _MouseDetails {
  /// Creates details for a [MouseMoveCallback] call.
  ///
  /// The [globalPosition] argument must be provided and must not be null.
  MouseMoveDetails({Duration sourceTimeStamp, Offset globalPosition})
    : super(sourceTimeStamp: sourceTimeStamp, globalPosition: globalPosition);
}

/// The `details` object provides the global position of the mouse pointer.
typedef MouseMoveCallback = void Function(MouseMoveDetails details);

/// Details object for callbacks that use [MouseExitCallback].
class MouseExitDetails extends _MouseDetails {
  /// Creates details for a [MouseMoveCallback] call.
  ///
  /// The [globalPosition] argument must be provided and must not be null.
  MouseExitDetails({Duration sourceTimeStamp, Offset globalPosition})
      : super(sourceTimeStamp: sourceTimeStamp, globalPosition: globalPosition);
}

/// The `details` object provides the global position of the mouse pointer at
/// the time of exit.
typedef MouseExitCallback = void Function(MouseExitDetails details);

/// The annotation object used to annotate layers that are interested in mouse
/// movements.
///
/// This is added to a layer and managed by the [MouseDetector] widget.
class MouseDetectorAnnotation {
  /// Creates an annotation that can be used to find layers interested in mouse
  /// movements.
  ///
  /// At least one of the arguments must be non-null.
  const MouseDetectorAnnotation({this.onEnter, this.onMove, this.onExit});

  /// Triggered when a pointer has entered the bounding box of the annotated
  /// layer.
  final MouseEnterCallback onEnter;

  /// Triggered when a pointer has moved within the bounding box of the
  /// annotated layer.
  final MouseMoveCallback onMove;

  /// Triggered when a pointer has exited the bounding box of the annotated
  /// layer.
  final MouseExitCallback onExit;

  @override
  String toString() {
    final String none = (onEnter == null && onExit == null && onMove == null) ? ' <none>' : '';
    return '[$runtimeType${hashCode.toRadixString(16)}$none'
           '${onEnter == null ? '' : ' onEnter'}'
           '${onMove == null ? '' : ' onMove'}'
           '${onExit == null ? '' : ' onExit'}]';
  }
}

// Used for accounting for which annotation is active inside of the MouseTracker.
class _TrackedAnnotation {
  _TrackedAnnotation(this.annotation);

  final MouseDetectorAnnotation annotation;

  /// True if the mouse pointer is currently inside of the annotated layer.
  ///
  /// Used to detect layers that used to have the mouse pointer inside them, but
  /// now no longer do (to facilitate exit notification).
  bool active = false;
}

/// Describes a function that finds an annotation given an offset in logical
/// coordinates.
typedef MouseDetectorAnnotationFinder = MouseDetectorAnnotation Function(Offset offset);

/// Keeps state about which objects are interested in tracking mouse positions
/// and notifies them when a mouse pointer enters, moves, or leaves an annotated
/// region that they are interested in.
///
/// Owned by the [RendererBinding] class.
class MouseTracker {
  /// Creates a mouse tracker to keep track of mouse locations.
  ///
  /// All of the parameters must not be null.
  MouseTracker(PointerRouter router, this.annotationFinder)
      : assert(router != null),
        assert(annotationFinder != null) {
    router.addGlobalRoute(_handleEvent);
  }

  /// Used to find annotations at a given logical coordinate.
  final MouseDetectorAnnotationFinder annotationFinder;

  // The collection of annotations that are currently being tracked. They may or
  // may not be active, depending on the value of _TrackedAnnotation.active.
  final Map<MouseDetectorAnnotation, _TrackedAnnotation> _trackedAnnotations =
      <MouseDetectorAnnotation, _TrackedAnnotation>{};

  /// Track an annotation so that if the mouse enters it, we send it events.
  ///
  /// This is typically called when the [AnnotatedRegion] containing this
  /// annotation has been added to the layer tree.
  void attachAnnotation(MouseDetectorAnnotation annotation) {
    _trackedAnnotations[annotation] = _TrackedAnnotation(annotation);
    // Schedule a check so that we test this new annotation to see if the mouse
    // is currently inside its region.
    _scheduleMousePositionCheck();
  }

  /// Stops tracking an annotation, indicating that it has been removed from the
  /// layer tree.
  ///
  /// If the associated layer is not removed, and receives a hit, then
  /// [collectMousePositions] will assert the next time it is called.
  void detachAnnotation(MouseDetectorAnnotation annotation) {
    final _TrackedAnnotation trackedAnnotation = _findAnnotation(annotation);
    assert(trackedAnnotation != null, "Tried to detach an annotation that wasn't attached: $annotation");
    if (trackedAnnotation.active) {
      annotation.onExit(
        MouseExitDetails(
          globalPosition: _lastMouseEvent?.position,
          sourceTimeStamp: _lastMouseEvent?.timeStamp,
        ),
      );
    }
    _trackedAnnotations.remove(trackedAnnotation);
  }

  void _scheduleMousePositionCheck() {
    SchedulerBinding.instance.addPostFrameCallback((Duration _) => collectMousePositions());
    SchedulerBinding.instance.scheduleFrame();
  }

  // Handler for events coming from the PointerRouter.
  void _handleEvent(PointerEvent event) {
    if (event.kind != PointerDeviceKind.mouse) {
      return;
    }
    if (_trackedAnnotations.isEmpty) {
      // If we're not tracking anything, then there is no point in registering a
      // frame callback or scheduling a frame. By definition there are no active
      // annotations that need exiting, either.
      _lastMouseEvent = null;
      return;
    }
    if (event is PointerRemovedEvent) {
      _lastMouseEvent = null;
      // If the mouse was removed, then we need to schedule one more check to
      // exit any annotations that were active.
      _scheduleMousePositionCheck();
    } else {
      if (event is PointerMoveEvent || event is PointerHoverEvent || event is PointerDownEvent) {
        if (_lastMouseEvent == null || _lastMouseEvent.position != event.position) {
          // Only schedule a frame if we have our first event, or if the
          // location of the mouse has changed.
          _scheduleMousePositionCheck();
        }
        _lastMouseEvent = event;
      }
    }
  }

  _TrackedAnnotation _findAnnotation(MouseDetectorAnnotation annotation) {
    final _TrackedAnnotation trackedAnnotation = _trackedAnnotations[annotation];
    assert(trackedAnnotation != null,
           'Unable to find annotation $annotation in tracked annotations. '
           'Check that attachAnnotation has been called for all annotated layers.');
    return trackedAnnotation;
  }

  /// Tells interested objects that a mouse has entered, exited, or moved, given
  /// a callback to fetch the [MouseDetectorAnnotation] associated with a global
  /// offset.
  ///
  /// This is called from the [RenderView] when the layer tree has been updated,
  /// right after rendering.
  void collectMousePositions() {
    void exitAllAnnotations() {
      for (_TrackedAnnotation trackedAnnotation in _trackedAnnotations.values) {
        if (trackedAnnotation.active) {
          if (trackedAnnotation.annotation?.onExit != null) {
            trackedAnnotation.annotation.onExit(MouseExitDetails(
              globalPosition: _lastMouseEvent?.position,
              sourceTimeStamp: _lastMouseEvent?.timeStamp,
            ));
          }
          trackedAnnotation.active = false;
        }
      }
    }

    // This indicates that a mouse pointer was removed, or has not been
    // connected yet. If no mouse is connected, then we want to make sure that
    // all active annotations are exited.
    if (!mouseIsConnected) {
      exitAllAnnotations();
      return;
    }

    final MouseDetectorAnnotation hit = annotationFinder(_lastMouseEvent.position);

    // No annotation was found at this position, so send an exit to all active
    // tracked annotations, since none of them were hit.
    if (hit == null) {
      exitAllAnnotations();
      return;
    }

    final _TrackedAnnotation hitAnnotation = _findAnnotation(hit);
    if (!hitAnnotation.active) {
      // A tracked annotation that just became active and needs to have an enter
      // event sent to it.
      hitAnnotation.active = true;
      if (hitAnnotation.annotation?.onEnter != null) {
        hitAnnotation.annotation.onEnter(MouseEnterDetails(
          globalPosition: _lastMouseEvent.position,
          sourceTimeStamp: _lastMouseEvent.timeStamp,
        ));
      }
    }
    if (hitAnnotation.annotation?.onMove != null) {
      hitAnnotation.annotation.onMove(MouseMoveDetails(
        globalPosition: _lastMouseEvent.position,
        sourceTimeStamp: _lastMouseEvent.timeStamp,
      ));
    }

    // Tell any tracked annotations that weren't hit that they are no longer
    // active.
    for (_TrackedAnnotation trackedAnnotation in _trackedAnnotations.values) {
      if (hitAnnotation == trackedAnnotation) {
        continue;
      }
      if (trackedAnnotation.active) {
        if (trackedAnnotation.annotation?.onExit != null) {
          trackedAnnotation.annotation.onExit(MouseExitDetails(
            globalPosition: _lastMouseEvent.position,
            sourceTimeStamp: _lastMouseEvent.timeStamp,
          ));
        }
        trackedAnnotation.active = false;
      }
    }
  }

  /// The most recent mouse event observed.
  ///
  /// May be null if no mouse is connected, or hasn't produced an event yet.
  /// Will not be updated unless there is at least one tracked annotation.
  PointerEvent _lastMouseEvent;

  /// Whether or not a mouse is connected and has produced events.
  bool get mouseIsConnected => _lastMouseEvent != null;
}
