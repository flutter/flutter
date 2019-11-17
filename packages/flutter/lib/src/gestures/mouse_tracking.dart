// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection' show LinkedHashSet;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'events.dart';
import 'pointer_router.dart';

/// Signature for listening to [PointerEnterEvent] events.
///
/// Used by [MouseTrackerAnnotation], [MouseRegion] and [RenderMouseRegion].
typedef PointerEnterEventListener = void Function(PointerEnterEvent event);

/// Signature for listening to [PointerExitEvent] events.
///
/// Used by [MouseTrackerAnnotation], [MouseRegion] and [RenderMouseRegion].
typedef PointerExitEventListener = void Function(PointerExitEvent event);

/// Signature for listening to [PointerHoverEvent] events.
///
/// Used by [MouseTrackerAnnotation], [MouseRegion] and [RenderMouseRegion].
typedef PointerHoverEventListener = void Function(PointerHoverEvent event);

/// The annotation object used to annotate layers that are interested in mouse
/// movements.
///
/// This is added to a layer and managed by the [MouseRegion] widget.
class MouseTrackerAnnotation {
  /// Creates an annotation that can be used to find layers interested in mouse
  /// movements.
  const MouseTrackerAnnotation({this.onEnter, this.onHover, this.onExit});

  /// Triggered when a mouse pointer, with or without buttons pressed, has
  /// entered the annotated region.
  ///
  /// This callback is triggered when the pointer has started to be contained
  /// by the annotationed region for any reason.
  ///
  /// More specifically, the callback is triggered by the following cases:
  ///
  ///  * A new annotated region has appeared under a pointer.
  ///  * An existing annotated region has moved to under a pointer.
  ///  * A new pointer has been added to somewhere within an annotated region.
  ///  * An existing pointer has moved into an annotated region.
  ///
  /// This callback is not always matched by an [onExit].
  ///
  /// See also:
  ///
  ///  * [MouseRegion.onEnter], which uses this callback.
  ///  * [onExit], which is triggered when a mouse pointer exits the region.
  final PointerEnterEventListener onEnter;

  /// Triggered when a pointer has moved within the annotated region without
  /// buttons pressed.
  ///
  /// This is not triggered if the region under the pointer moves without
  /// the pointer moving.
  final PointerHoverEventListener onHover;

  /// Triggered when a mouse pointer, with or without buttons pressed, has
  /// exited the annotated region when the annotated region still exists.
  ///
  /// This callback is triggered when the pointer has stopped to be contained
  /// by the region, except when it's caused by the removal of the render object
  /// that owns the annotation. More specifically, the callback is triggered by
  /// the following cases:
  ///
  ///  * An annotated region that used to contain a pointer has moved away.
  ///  * A pointer that used to be within an annotated region has been removed.
  ///  * A pointer that used to be within an annotated region has moved away.
  ///
  /// And is __not__ triggered by the following case,
  ///
  ///  * An annotated region that used to contain a pointer has disappeared.
  ///
  /// The last case is when [onExit] does not match an earlier [onEnter].
  /// This design is because the last case is very likely to be handled
  /// improperly and crash the app (such as calling `setState` of the disposed
  /// widget). Also, the last case can already be achieved by using the event
  /// that causes the removal, or simply overriding [Widget.dispose] or
  /// [RenderObject.detach].
  ///
  /// Technically, whether [onExit] will be called is controlled by
  /// [MouseTracker.attachAnnotation] and [MouseTracker.detachAnnotation].
  ///
  /// See also:
  ///
  ///  * [MouseRegion.onExit], which uses this callback.
  ///  * [onEnter], which is triggered when a mouse pointer enters the region.
  final PointerExitEventListener onExit;

  @override
  String toString() {
    final List<String> callbacks = <String>[];
    if (onEnter != null)
      callbacks.add('enter');
    if (onHover != null)
      callbacks.add('hover');
    if (onExit != null)
      callbacks.add('exit');
    final String describeCallbacks = callbacks.isEmpty
      ? '<none>'
      : callbacks.join(' ');
    return '${describeIdentity(this)}(callbacks: $describeCallbacks)';
  }
}

/// Signature for searching for [MouseTrackerAnnotation]s at the given offset.
///
/// It is used by the [MouseTracker] to fetch annotations for the mouse
/// position.
typedef MouseDetectorAnnotationFinder = Iterable<MouseTrackerAnnotation> Function(Offset offset);

typedef _CollectionHandler = void Function(Map<int, _MouseState> _mergedStates);

// Various states of each connected mouse device.
//
// It is used by [MouseTracker] to compute which callbacks should be triggered
// by each event.
class _MouseState {
  _MouseState({
    @required PointerAddedEvent initialEvent,
  }) : assert(initialEvent != null),
       _handledEvent = initialEvent;

  // The list of annotations that contains this device during the current frame.
  //
  // It uses [LinkedHashSet] to keep the insertion order.
  LinkedHashSet<MouseTrackerAnnotation> get annotations => _annotations;
  LinkedHashSet<MouseTrackerAnnotation> _annotations = LinkedHashSet<MouseTrackerAnnotation>();

  LinkedHashSet<MouseTrackerAnnotation> replaceAnnotations(LinkedHashSet<MouseTrackerAnnotation> value) {
    final LinkedHashSet<MouseTrackerAnnotation> previous = _annotations;
    _annotations = value;
    return previous;
  }

  // The most recent processed mouse event observed from this device.
  PointerEvent get handledEvent => _handledEvent;
  PointerEvent _handledEvent;
  set handledEvent(PointerEvent value) {
    assert(value != null);
    _handledEvent = value;
  }

  int get device => handledEvent.device;

  @override
  String toString() {
    String describeEvent(PointerEvent event) {
      return event == null ? 'null' : '${describeIdentity(event)}';
    }
    final String describeHandledEvent = 'handledEvent: ${describeEvent(handledEvent)}';
    final String describeAnnotations = 'annotations: [list of ${annotations.length}]';
    return '${describeIdentity(this)}($describeHandledEvent, $describeAnnotations)';
  }
}

/// Maintains the relationship between mouse devices and
/// [MouseTrackerAnnotation]s, and notifies interested callbacks of the changes
/// thereof.
///
/// This class is a [ChangeNotifier] that notifies its listeners if the value of
/// [mouseIsConnected] changes.
///
/// An instance of [MouseTracker] is owned by the global singleton of
/// [RendererBinding].
class MouseTracker extends ChangeNotifier {
  /// Creates a mouse tracker to keep track of mouse locations.
  ///
  /// The first parameter is a [PointerRouter], which [MouseTracker] will
  /// subscribe to and receive events from. Usually it is the global singleton
  /// instance [GestureBinding.pointerRouter].
  ///
  /// The second parameter is a function with which the [MouseTracker] can
  /// search for [MouseTrackerAnnotation]s at a given position.
  /// Usually it is [Layer.findAllAnnotations] of the root layer.
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

  /// Find annotations at a given offset in global logical coordinate space
  /// in visual order from front to back.
  ///
  /// [MouseTracker] uses this callback to know which annotations are affected
  /// by each device.
  ///
  /// The annotations should be returned in visual order from front to
  /// back, so that the callbacks are called in an correct order.
  final MouseDetectorAnnotationFinder annotationFinder;

  // The pointer router that the mouse tracker listens to, and receives new
  // mouse events from.
  final PointerRouter _router;

  // The collection of annotations that are currently being tracked.
  // It is operated on by [attachAnnotation] and [detachAnnotation].
  final Set<MouseTrackerAnnotation> _trackedAnnotations = <MouseTrackerAnnotation>{};

  // Tracks the state of connected mouse devices.
  //
  // It is the source of truth for the list of connected mouse devices.
  final Map<int, _MouseState> _mouseStates = <int, _MouseState>{};

  static bool _shouldMarkStateDirty(_MouseState state, PointerEvent value) {
    if (state == null)
      return true;
    assert(value != null);
    final PointerEvent lastEvent = state.handledEvent;
    assert(value.device == lastEvent.device);
    // An Added can only follow a Removed, and a Removed can only be followed
    // by an Added
    assert((value is PointerAddedEvent) == (lastEvent is PointerRemovedEvent));

    // Ignore events that are unrelated to mouse tracking
    if (value is PointerSignalEvent)
      return false;
    return lastEvent is PointerAddedEvent
      || value is PointerRemovedEvent
      || lastEvent.position != value.position;
  }

  // Handler for events coming from the PointerRouter.
  void _handleEvent(PointerEvent event) {
    if (event.kind != PointerDeviceKind.mouse)
      return;
    if (event is PointerSignalEvent)
      return;
    final int device = event.device;
    final _MouseState existingState = _mouseStates[device];
    final PointerEvent handledEvent = existingState?.handledEvent;
    if (!_shouldMarkStateDirty(existingState, event))
      return;

    _collectionPhase(
      newEvent: event,
      task: (Map<int, _MouseState> mergedStates) {
        final _MouseState mouseState = mergedStates[device];
        assert(mouseState != null);
        final LinkedHashSet<MouseTrackerAnnotation> nextAnnotations = _findAnnotations(mouseState);
        final LinkedHashSet<MouseTrackerAnnotation> lastAnnotations = mouseState.replaceAnnotations(nextAnnotations);
        _dispatchDeviceCallbacks(
          lastAnnotations: lastAnnotations,
          nextAnnotations: nextAnnotations,
          handledEvent: handledEvent,
          latestEvent: event,
          trackedAnnotations: _trackedAnnotations,
        );
      },
    );
  }

  LinkedHashSet<MouseTrackerAnnotation> _findAnnotations(_MouseState state) {
    final Offset globalPosition = state.handledEvent.position;
    final int device = state.device;
    return (_mouseStates.containsKey(device) && _trackedAnnotations.isNotEmpty)
      ? LinkedHashSet<MouseTrackerAnnotation>.from(annotationFinder(globalPosition))
      : <MouseTrackerAnnotation>{};
  }

  bool _hasScheduledPostFrameCheck = false;
  void _schedulePostFrameCheck() {
    assert(!_duringCollection);
    SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
      assert(_hasScheduledPostFrameCheck);
      _hasScheduledPostFrameCheck = false;
      _updateDevices();
    });
  }

  bool get _duringBuildPhase {
    return SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks;
  }

  bool _duringCollection = false;
  void _collectionPhase({
    PointerEvent newEvent,
    @required _CollectionHandler task,
  }) {
    assert(task != null);
    assert(!_duringBuildPhase);
    assert(!_duringCollection);
    final bool mouseWasConnected = mouseIsConnected;

    // Create new state based on new event if necessary, 
    // and update handledEvent
    if (newEvent != null) {
      final _MouseState existingState = _mouseStates[newEvent.device];
      if (existingState == null) {
        assert(newEvent is PointerAddedEvent);
        final _MouseState newState = _MouseState(initialEvent: newEvent);
        _mouseStates[newState.device] = newState;
      } else {
        existingState.handledEvent = newEvent;
      }
    }
    final Map<int, _MouseState> mergedStates = Map<int, _MouseState>.from(_mouseStates);

    // Update mouseState to the latest devices that have not been removed, so
    // that [mouseIsConnected], which is decided by `_mouseStates`, is correct
    // during the callbacks.
    if (newEvent is PointerRemovedEvent) {
      final _MouseState removedState = _mouseStates.remove(newEvent.device);
      assert(removedState != null);
    }

    assert(() {
      _duringCollection = true;
      return true;
    }());
    task(mergedStates);
    assert(() {
      _duringCollection = false;
      return true;
    }());

    if (mouseWasConnected != mouseIsConnected)
      notifyListeners();
  }

  void _updateDevices() {
    _collectionPhase(task: (Map<int, _MouseState> mergedStates) {
      final List<int> dirtyDevices = _mouseStates.keys.toList();

      for (int device in dirtyDevices) {
        final _MouseState mouseState = mergedStates[device];
        assert(mouseState != null);

        final LinkedHashSet<MouseTrackerAnnotation> nextAnnotations = _findAnnotations(mouseState);
        final LinkedHashSet<MouseTrackerAnnotation> lastAnnotations = mouseState.replaceAnnotations(nextAnnotations);
        _dispatchDeviceCallbacks(
          lastAnnotations: lastAnnotations,
          nextAnnotations: nextAnnotations,
          handledEvent: mouseState.handledEvent,
          latestEvent: mouseState.handledEvent,
          trackedAnnotations: _trackedAnnotations,
        );
      }
    });
  }

  // Dispatch callbacks related to a device after all necessary information
  // has been collected.
  //
  // The `unhandledEvent` can be null. Other arguments must not be null.
  static void _dispatchDeviceCallbacks({
    @required LinkedHashSet<MouseTrackerAnnotation> lastAnnotations,
    @required LinkedHashSet<MouseTrackerAnnotation> nextAnnotations,
    @required PointerEvent handledEvent,
    @required PointerEvent latestEvent,
    @required Set<MouseTrackerAnnotation> trackedAnnotations,
  }) {
    assert(lastAnnotations != null);
    assert(nextAnnotations != null);
    assert(latestEvent != null);
    assert(trackedAnnotations != null);
    // Order is important for mouse event callbacks. The `findAnnotations`
    // returns annotations in the visual order from front to back. We call
    // it the "visual order", and the opposite one "reverse visual order".
    // The algorithm here is explained in
    // https://github.com/flutter/flutter/issues/41420

    // Send exit events in visual order.
    final Iterable<MouseTrackerAnnotation> exitingAnnotations =
      lastAnnotations.difference(nextAnnotations);
    for (final MouseTrackerAnnotation annotation in exitingAnnotations) {
      final bool attached = trackedAnnotations.contains(annotation);
      // Exit is not sent if annotation is no longer attached, because this
      // trigger may cause crashes and has safer alternatives. See
      // [MouseRegion.onExit] for details.
      if (annotation.onExit != null && attached) {
        annotation.onExit(PointerExitEvent.fromMouseEvent(latestEvent));
      }
    }

    // Send enter events in reverse visual order.
    final Iterable<MouseTrackerAnnotation> enteringAnnotations =
      nextAnnotations.difference(lastAnnotations).toList().reversed;
    for (final MouseTrackerAnnotation annotation in enteringAnnotations) {
      assert(trackedAnnotations.contains(annotation));
      if (annotation.onEnter != null) {
        annotation.onEnter(PointerEnterEvent.fromMouseEvent(latestEvent));
      }
    }

    // Send hover events in reverse visual order.
    // For now the order between the hover events is designed this way for no
    // solid reasons but to keep it aligned with enter events for simplicity.
    if (latestEvent is PointerHoverEvent) {
      final Iterable<MouseTrackerAnnotation> hoveringAnnotations =
        nextAnnotations.toList().reversed;
      for (final MouseTrackerAnnotation annotation in hoveringAnnotations) {
        // Deduplicate: Trigger hover if it's a newly hovered annotation
        // or the position has changed
        if (!lastAnnotations.contains(annotation)
            || handledEvent is! PointerHoverEvent
            || latestEvent.position != handledEvent.position) {
          if (annotation.onHover != null) {
            annotation.onHover(latestEvent);
          }
        }
      }
    }
  }

  /// Mark all devices as dirty, and schedule a callback that is executed in the
  /// upcoming post-frame phase to check their updates.
  ///
  /// Checking a device means to collect the annotations that the pointer
  /// hovers, and triggers necessary callbacks accordingly.
  ///
  /// This callback must be called in scheduler's persistent callback phase,
  /// and is typically called by [RendererBinding]'s drawing method. This is
  /// because every new frame can change the position of annotations.
  void schedulePostFrameCheck() {
    assert(_duringBuildPhase);
    if (!_hasScheduledPostFrameCheck) {
      _hasScheduledPostFrameCheck = true;
      _schedulePostFrameCheck();
    }
  }

  /// Whether or not a mouse is connected and has produced events.
  bool get mouseIsConnected => _mouseStates.isNotEmpty;

  /// Checks if the given [MouseTrackerAnnotation] is attached to this
  /// [MouseTracker].
  ///
  /// This function is only public to allow for proper testing of the
  /// MouseTracker. Do not call in other contexts.
  @visibleForTesting
  bool isAnnotationAttached(MouseTrackerAnnotation annotation) {
    return _trackedAnnotations.contains(annotation);
  }

  /// Notify [MouseTracker] that a new [MouseTrackerAnnotation] has started to
  /// take effect.
  ///
  /// This method should be called as soon as the render object that owns this
  /// annotation is added to the render tree, so that whether the annotation is
  /// attached is kept in sync with whether its owner object is mounted.
  ///
  /// {@template flutter.mouseTracker.attachAnnotation}
  /// This method does not cause any immediate effect, since the state it
  /// changes is used during a post-frame callback or while handling certain
  /// pointer events.
  ///
  /// The state of annotation attachment determines whether an exit event is
  /// caused by movement or by the disposal of its owner render object,
  /// preventing some common patterns causing crashes. See [MouseTracker.onExit]
  /// for its application.
  ///
  /// The [MouseTracker] also uses this to track the number of attached
  /// annotations, and will skip mouse position checks if there is no
  /// annotations attached.
  /// {@endtemplate}
  void attachAnnotation(MouseTrackerAnnotation annotation) {
    assert(!_duringCollection);
    _trackedAnnotations.add(annotation);
  }

  /// Notify [MouseTracker] that a mouse tracker annotation that was previously
  /// attached has stopped taking effect.
  ///
  /// This method should be called as soon as the render object that owns this
  /// annotation is removed from the render tree, so that whether the annotation
  /// is attached is kept in sync with whether its owner object is mounted.
  ///
  /// {@macro flutter.mouseTracker.attachAnnotation}
  void detachAnnotation(MouseTrackerAnnotation annotation) {
    assert(!_duringCollection);
    _trackedAnnotations.remove(annotation);
  }
}
