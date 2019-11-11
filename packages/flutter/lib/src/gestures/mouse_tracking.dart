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
/// Used by [MouseTrackerAnnotation], [Listener] and [RenderPointerListener].
typedef PointerEnterEventListener = void Function(PointerEnterEvent event);

/// Signature for listening to [PointerExitEvent] events.
///
/// Used by [MouseTrackerAnnotation], [Listener] and [RenderPointerListener].
typedef PointerExitEventListener = void Function(PointerExitEvent event);

typedef PointerExitOrDisposeEventListener = void Function(bool disposed, PointerExitEvent event);

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
  const MouseTrackerAnnotation({this.onEnter, this.onHover, this.onExit, this.onExitOrDispose});

  /// Triggered when a pointer has entered the bounding box of the annotated
  /// layer.
  final PointerEnterEventListener onEnter;

  /// Triggered when a pointer has moved within the bounding box of the
  /// annotated layer.
  final PointerHoverEventListener onHover;

  /// Triggered when a pointer has exited the bounding box of the annotated
  /// layer.
  final PointerExitEventListener onExit;

  final PointerExitOrDisposeEventListener onExitOrDispose;

  @override
  String toString() {
    final List<String> callbacks = <String>[];
    if (onEnter != null)
      callbacks.add('enter');
    if (onHover != null)
      callbacks.add('hover');
    if (onExit != null)
      callbacks.add('exit');
    if (onExitOrDispose != null)
      callbacks.add('exitOrDispose');
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

// Various states of each connected mouse device.
//
// It is used by [MouseTracker] to compute which callbacks should be triggered
// by each event.
class _MouseState {
  _MouseState({
    @required PointerEvent mostRecentEvent,
  }) : assert(mostRecentEvent != null),
       _mostRecentEvent = mostRecentEvent;

  // The list of annotations that contains this device during the current frame.
  //
  // It uses [LinkedHashSet] to keep the insertion order.
  LinkedHashSet<MouseTrackerAnnotation> lastAnnotations = LinkedHashSet<MouseTrackerAnnotation>();

  // The most recent mouse event observed from this device.
  //
  // The [mostRecentEvent] is never null.
  PointerEvent get mostRecentEvent => _mostRecentEvent;
  PointerEvent _mostRecentEvent;
  set mostRecentEvent(PointerEvent value) {
    assert(value != null);
    assert(value.device == _mostRecentEvent.device);
    // New value shouldn't be an Add, unless it immediately follows a Remove
    assert(value is! PointerAddedEvent || _mostRecentEvent is PointerRemovedEvent);
    _mostRecentEvent = value;
  }

  int get device => _mostRecentEvent.device;

  @override
  String toString() {
    final String describeEvent = '${_mostRecentEvent.runtimeType}(device: ${_mostRecentEvent.device})';
    final String describeAnnotations = '[list of ${lastAnnotations.length}]';
    return '${describeIdentity(this)}(event: $describeEvent, annotations: $describeAnnotations)';
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

  // Tracks the state of mouse devices that are newly connected during this
  // frame.
  final Map<int, _MouseState> _newMouseStates = <int, _MouseState>{};

  _MouseState _getMouseState(int device) {
    final _MouseState state = _mouseStates[device];
    final _MouseState newState = _newMouseStates[device];
    assert(state == null || newState == null);
    return state ?? newState;
  }

  // Returns the mouse state of a device. If it doesn't exist, create one using
  // `mostRecentEvent`, and store it in `_newMouseStates`.
  //
  // Returns true if it is newly created.
  bool _putMouseStateIfAbsent(int device, PointerEvent mostRecentEvent) {
    _MouseState result = _getMouseState(device);
    if (result == null) {
      result = _MouseState(mostRecentEvent: mostRecentEvent);
      _newMouseStates[device] = result;
      return true;
    }
    return false;
  }

  // Handler for events coming from the PointerRouter.
  void _handleEvent(PointerEvent event) {
    if (event.kind != PointerDeviceKind.mouse)
      return;
    if (event is PointerSignalEvent)
      return;
    final int device = event.device;
    final bool isNewState = _putMouseStateIfAbsent(device, event);
    final _MouseState mouseState = _getMouseState(device);
    assert(mouseState != null);
    final PointerEvent previousEvent = mouseState.mostRecentEvent;
    if (!isNewState)
      mouseState.mostRecentEvent = event;
    if (event is PointerAddedEvent
        || event is PointerRemovedEvent
        || previousEvent is PointerAddedEvent
        || event.position != previousEvent.position) {
      _markDeviceAsDirty(event.device);
    }
  }

  final Set<int> _dirtyDevices = <int>{};
  bool _allDevicesAreDirty = false;
  bool get _hasDirtyDevices => _dirtyDevices.isNotEmpty || _allDevicesAreDirty;

  void _markDeviceAsDirty(int device) {
    final bool hadDirtyDevices = _hasDirtyDevices;
    _dirtyDevices.add(device);
    if (!hadDirtyDevices)
      _updateDirtyDevices();
  }

  void _markAllDevicesAsDirty() {
    final bool hadDirtyDevices = _hasDirtyDevices;
    _allDevicesAreDirty = true;
    if (!hadDirtyDevices)
      _schedulePostFrameCheck();
  }

  void _clearDirtyBit() {
    _dirtyDevices.clear();
    _allDevicesAreDirty = false;
    assert(!_hasDirtyDevices);
  }

  void _schedulePostFrameCheck() {
    SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
      assert(_hasDirtyDevices);
      _updateDirtyDevices();
    });
  }

  void _updateDirtyDevices() {
    final List<int> dirtyDevices = (_allDevicesAreDirty ? _mouseStates.keys : _dirtyDevices).toList();
    print('_updateDirtyDevices $dirtyDevices $_mouseStates $_newMouseStates');
    _clearDirtyBit();
    final bool mouseWasConnected = mouseIsConnected;
    // Update mouseState to the latest devices that have not been removed so
    // that [mouseIsConnected] is correct during the callbacks.
    // Keep `mergedStates` for use in the callbacks later.
    final Map<int, _MouseState> mergedStates = Map<int, _MouseState>.fromEntries(
      _mouseStates.entries.followedBy(_newMouseStates.entries),
    );
    _newMouseStates.clear();
    _mouseStates
      ..clear()
      ..addEntries(
        mergedStates.entries.where((MapEntry<int, _MouseState> entry) {
          return entry.value.mostRecentEvent is! PointerRemovedEvent;
        }),
      );
    for (int device in dirtyDevices) {
      final _MouseState mouseState = mergedStates[device];
      assert(mouseState != null);
      _updateDevice(mouseState, _mouseStates.containsKey(mouseState.device));
    }

    if (mouseWasConnected != mouseIsConnected)
      notifyListeners();

    assert(!_hasDirtyDevices);
  }

  void _updateDevice(_MouseState mouseState, bool connected) {
    final LinkedHashSet<MouseTrackerAnnotation> nextAnnotations =
        (connected && _trackedAnnotations.isNotEmpty)
        ? LinkedHashSet<MouseTrackerAnnotation>.from(
            annotationFinder(mouseState.mostRecentEvent.position)
          )
        : <MouseTrackerAnnotation>{};

    _dispatchDeviceCallbacks(
      lastAnnotations: mouseState.lastAnnotations,
      nextAnnotations: nextAnnotations,
      mostRecentEvent: mouseState.mostRecentEvent,
    );

    mouseState.lastAnnotations = nextAnnotations;
  }

  // Dispatch callbacks related to a device after all necessary information
  // has been collected.
  void _dispatchDeviceCallbacks({
    @required LinkedHashSet<MouseTrackerAnnotation> lastAnnotations,
    @required LinkedHashSet<MouseTrackerAnnotation> nextAnnotations,
    @required PointerEvent mostRecentEvent,
  }) {
    // Order is important for mouse event callbacks. The `findAnnotations`
    // returns annotations in the visual order from front to back. We call
    // it the "visual order", and the opposite one "reverse visual order".
    // The algorithm here is explained in
    // https://github.com/flutter/flutter/issues/41420

    // Send exit events in visual order.
    final Iterable<MouseTrackerAnnotation> exitingAnnotations =
      lastAnnotations.difference(nextAnnotations);
    for (final MouseTrackerAnnotation annotation in exitingAnnotations) {
      final bool attached = isAnnotationAttached(annotation);
      if (annotation.onExit != null && attached) {
        annotation.onExit(PointerExitEvent.fromMouseEvent(mostRecentEvent));
      }
      if (annotation.onExitOrDispose != null) {
        annotation.onExitOrDispose(!attached, PointerExitEvent.fromMouseEvent(mostRecentEvent));
      }
    }

    // Send enter events in reverse visual order.
    final Iterable<MouseTrackerAnnotation> enteringAnnotations =
      nextAnnotations.difference(lastAnnotations).toList().reversed;
    for (final MouseTrackerAnnotation annotation in enteringAnnotations) {
      if (annotation.onEnter != null) {
        annotation.onEnter(PointerEnterEvent.fromMouseEvent(mostRecentEvent));
      }
    }

    // Send hover events in reverse visual order.
    // For now the order between the hover events is designed this way for no
    // solid reasons but to keep it aligned with enter events for simplicity.
    if (mostRecentEvent is PointerHoverEvent) {
      final Iterable<MouseTrackerAnnotation> hoveringAnnotations =
        nextAnnotations.toList().reversed;
      for (final MouseTrackerAnnotation annotation in hoveringAnnotations) {
        if (annotation.onHover != null) {
          annotation.onHover(mostRecentEvent);
        }
      }
    }
  }

  void schedulePostFrameCheck() {
    _markAllDevicesAsDirty();
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

  /// Notify [MouseTracker] that a new mouse tracker annotation has started to
  /// take effect.
  ///
  /// This should be called as soon as the layer that owns this annotation is
  /// added to the layer tree.
  ///
  /// This triggers [MouseTracker] to schedule a mouse position check during the
  /// post frame to see if this new annotation might trigger enter events.
  ///
  /// The [MouseTracker] also uses this to track the number of attached
  /// annotations, and will skip mouse position checks if there is no
  /// annotations attached.
  void attachAnnotation(MouseTrackerAnnotation annotation) {
    // Schedule a check so that we test this new annotation to see if any mouse
    // is currently inside its region. It has to happen after the frame is
    // complete so that the annotation layer has been added before the check.
    _trackedAnnotations.add(annotation);
  }


  /// Notify [MouseTracker] that a mouse tracker annotation that was previously
  /// attached has stopped taking effect.
  ///
  /// This should be called as soon as the layer that owns this annotation is
  /// removed from the layer tree. An assertion error will be thrown if the
  /// associated layer is not removed and receives another mouse hit.
  ///
  /// This triggers [MouseTracker] to perform a mouse position check immediately
  /// to see if this annotation removal triggers any exit events.
  ///
  /// The [MouseTracker] also uses this to track the number of attached
  /// annotations, and will skip mouse position checks if there is no
  /// annotations attached.
  void detachAnnotation(MouseTrackerAnnotation annotation) {
    _trackedAnnotations.remove(annotation);
  }
}
