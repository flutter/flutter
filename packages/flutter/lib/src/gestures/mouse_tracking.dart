// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection' show HashSet;
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
class MouseTrackerAnnotation extends Diagnosticable {
  /// Creates an annotation that can be used to find layers interested in mouse
  /// movements.
  ///
  /// The [key] is required and must not be null. Other arguments are optional.
  const MouseTrackerAnnotation({
    this.onEnter,
    this.onHover,
    this.onExit,
    @required this.key,
  }) : assert(key != null);

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
  /// This callback is not always matched by an [onExit]. If the render object
  /// that owns the annotation is disposed while being hovered by a pointer,
  /// the [onExit] callback of that annotation will never called, despite
  /// the earlier call of [onEnter]. For more details, see [onExit].
  ///
  /// See also:
  ///
  ///  * [MouseRegion.onEnter], which uses this callback.
  ///  * [onExit], which is triggered when a mouse pointer exits the region.
  final PointerEnterEventListener onEnter;

  /// Triggered when a pointer has moved within the annotated region without
  /// buttons pressed.
  ///
  /// This callback is triggered when:
  ///
  ///  * An annotation that did not contain the pointer has moved to under a
  ///    pointer that has no buttons pressed.
  ///  * A pointer has moved onto, or moved within an annotation without buttons
  ///    pressed.
  ///
  /// This callback is not triggered when:
  ///
  ///  * An annotation that is containing the pointer has moved, and still
  ///    contains the pointer.
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
  /// The last case is the only case when [onExit] does not match an earlier
  /// [onEnter].
  /// {@template flutter.mouseTracker.onExit}
  /// This design is because the last case is very likely to be
  /// handled improperly and cause exceptions (such as calling `setState` of the
  /// disposed widget). There are a few ways to mitigate this limit:
  ///
  ///  * If the state of hovering is contained within a widget that
  ///    unconditionally attaches the annotation (as long as a mouse is
  ///    connected), then this will not be a concern, since when the annotation
  ///    is disposed the state is no longer used.
  ///  * If you're accessible to the condition that controls whether the
  ///    annotation is attached, then you can call the callback when that
  ///    condition goes from true to false.
  ///  * In the cases where the solutions above won't work, you can always
  ///    override [State.dispose] or [RenderObject.detach].
  /// {@endtemplate}
  ///
  /// Technically, whether [onExit] will be called is controlled by
  /// [MouseTracker.attachAnnotation] and [MouseTracker.detachAnnotation].
  ///
  /// See also:
  ///
  ///  * [MouseRegion.onExit], which uses this callback.
  ///  * [onEnter], which is triggered when a mouse pointer enters the region.
  final PointerExitEventListener onExit;

  /// Controls how one annotation replaces another annotation during an
  /// annotation search.
  ///
  /// During the process of determining pointer entrance and exit, two
  /// annotations are considered equal if the two annotations have [key]s that
  /// are equal by [operator==].
  ///
  /// The [key] must not be null.
  ///
  /// See also:
  ///
  ///  * [UniqueKey], [ObjectKey], and [ValueKey], which are common classes of
  ///    keys.
  final Key key;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagsSummary<Function>(
      'callbacks',
      <String, Function> {
        'enter': onEnter,
        'hover': onHover,
        'exit': onExit,
      },
      ifEmpty: '<none>',
    ));
    properties.add(DiagnosticsProperty<Key>('key', key));
  }
}

/// Signature for searching for [MouseTrackerAnnotation]s at the given offset.
///
/// It is used by the [MouseTracker] to fetch annotations for the mouse
/// position.
typedef MouseDetectorAnnotationFinder = Iterable<MouseTrackerAnnotation> Function(Offset offset);

typedef _UpdatedDeviceHandler = void Function(_MouseState mouseState, List<MouseTrackerAnnotation> previousAnnotations);

// Various states of a connected mouse device used by [MouseTracker].
class _MouseState {
  _MouseState({
    @required PointerEvent initialEvent,
  }) : assert(initialEvent != null),
       _latestEvent = initialEvent;

  // The list of annotations that contains this device.
  List<MouseTrackerAnnotation> get annotations => _annotations;
  List<MouseTrackerAnnotation> _annotations = <MouseTrackerAnnotation>[];

  List<MouseTrackerAnnotation> replaceAnnotations(List<MouseTrackerAnnotation> value) {
    final List<MouseTrackerAnnotation> previous = _annotations;
    _annotations = value;
    return previous;
  }

  // The most recently processed mouse event observed from this device.
  PointerEvent get latestEvent => _latestEvent;
  PointerEvent _latestEvent;
  set latestEvent(PointerEvent value) {
    assert(value != null);
    _latestEvent = value;
  }

  int get device => latestEvent.device;

  @override
  String toString() {
    String describeEvent(PointerEvent event) {
      return event == null ? 'null' : '${describeIdentity(event)}';
    }
    final String describeLatestEvent = 'latestEvent: ${describeEvent(latestEvent)}';
    final String describeAnnotations = 'annotations: [list of ${annotations.length}]';
    return '${describeIdentity(this)}($describeLatestEvent, $describeAnnotations)';
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
///
/// ### Details
///
/// The state of [MouseTracker] consists of 3 parts:
///
///  * The mouse devices that are connected.
///  * The annotations that are attached, i.e. whose owner render object is
///    painted on the screen.
///  * In which annotations each device is contained.
///
/// The states remain stable most of the time, and are only changed at the
/// following moments:
///
///  * An eligible [PointerEvent] has been observed, e.g. a device is added,
///    removed, or moved. In this case, the state related to this device will
///    be immediately updated.
///  * A frame has been painted. In this case, a callback will be scheduled for
///    the upcoming post-frame phase to update all devices.
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

  // The collection of annotations that are currently being tracked. It is
  // operated on by [attachAnnotation] and [detachAnnotation].
  final HashSet<Key> _trackedAnnotationKeys = HashSet<Key>();

  // Tracks the state of connected mouse devices.
  //
  // It is the source of truth for the list of connected mouse devices.
  final Map<int, _MouseState> _mouseStates = <int, _MouseState>{};

  // Whether an observed event might update a device.
  static bool _shouldMarkStateDirty(_MouseState state, PointerEvent value) {
    if (state == null)
      return true;
    assert(value != null);
    final PointerEvent lastEvent = state.latestEvent;
    assert(value.device == lastEvent.device);
    // An Added can only follow a Removed, and a Removed can only be followed
    // by an Added.
    assert((value is PointerAddedEvent) == (lastEvent is PointerRemovedEvent));

    // Ignore events that are unrelated to mouse tracking.
    if (value is PointerSignalEvent)
      return false;
    return lastEvent is PointerAddedEvent
      || value is PointerRemovedEvent
      || lastEvent.position != value.position;
  }

  // Handler for events coming from the PointerRouter.
  //
  // If the event marks the device dirty, update the device immediately.
  void _handleEvent(PointerEvent event) {
    if (event.kind != PointerDeviceKind.mouse)
      return;
    if (event is PointerSignalEvent)
      return;
    final int device = event.device;
    final _MouseState existingState = _mouseStates[device];
    if (!_shouldMarkStateDirty(existingState, event))
      return;

    final PointerEvent previousEvent = existingState?.latestEvent;
    final Offset lastHoverPosition = previousEvent is! PointerHoverEvent ? null : previousEvent.position;
    _updateDevices(
      targetEvent: event,
      handleUpdatedDevice: (_MouseState mouseState, List<MouseTrackerAnnotation> previousAnnotations) {
        assert(mouseState.device == event.device);
        _dispatchDeviceCallbacks(
          lastAnnotations: previousAnnotations,
          nextAnnotations: mouseState.annotations,
          lastHoverPosition: lastHoverPosition,
          unhandledEvent: event,
          trackedAnnotationKeys: _trackedAnnotationKeys,
        );
      },
    );
  }

  // Find the annotations that is hovered by the device of the `state`.
  //
  // If the device is not connected or there are no annotations attached, an
  // empty list is returned without calling `annotationFinder`.
  List<MouseTrackerAnnotation> _findAnnotations(_MouseState state) {
    final Offset globalPosition = state.latestEvent.position;
    final int device = state.device;
    return (_mouseStates.containsKey(device) && _trackedAnnotationKeys.isNotEmpty)
      ? List<MouseTrackerAnnotation>.from(annotationFinder(globalPosition))
      : <MouseTrackerAnnotation>[];
  }

  static bool get _duringBuildPhase {
    return SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks;
  }

  // Update all devices, despite observing no new events.
  //
  // This is called after a new frame, since annotations can be moved after
  // every frame.
  void _updateAllDevices() {
    _updateDevices(
      handleUpdatedDevice: (_MouseState mouseState, List<MouseTrackerAnnotation> previousAnnotations) {
        final PointerEvent latestEvent = mouseState.latestEvent;
        final Offset lastHoverPosition = latestEvent is PointerHoverEvent ? latestEvent.position : null;
        _dispatchDeviceCallbacks(
          lastAnnotations: previousAnnotations,
          nextAnnotations: mouseState.annotations,
          lastHoverPosition: lastHoverPosition,
          unhandledEvent: mouseState.latestEvent,
          trackedAnnotationKeys: _trackedAnnotationKeys,
        );
      }
    );
  }

  bool _duringDeviceUpdate = false;
  // Update device states with the change of a new event or a new frame, and
  // trigger `handleUpdateDevice` for each dirty device.
  //
  // This method is called either when a new event is observed (`targetEvent`
  // being non-null), or when no new event is observed but all devices are
  // marked dirty due to a new frame. It means that it will not happen that all
  // devices are marked dirty when a new event is unprocessed.
  //
  // This method is the moment where `_mouseState` is updated. Before
  // this method, `_mouseState` is in sync with the state before the event or
  // before the frame. During `handleUpdateDevice` and after this method,
  // `_mouseState` is in sync with the state after the event or after the frame.
  //
  // The dirty devices are decided as follows: if `targetEvent` is not null, the
  // dirty devices are the device that observed the event; otherwise all devices
  // are dirty.
  //
  // This method first keeps `_mouseStates` up to date. More specifically,
  //
  //  * If an event is observed, update `_mouseStates` by inserting or removing
  //    the state that corresponds to the event if needed, then update the
  //    `latestEvent` property of this mouse state.
  //  * For each mouse state that will correspond to a dirty device, update the
  //    `annotations` property with the annotations the device is contained.
  //
  // Then, for each dirty device, `handleUpdatedDevice` is called with the
  // updated state and the annotations before the update.
  //
  // Last, the method checks if `mouseIsConnected` has been changed, and notify
  // listeners if needed.
  void _updateDevices({
    PointerEvent targetEvent,
    @required _UpdatedDeviceHandler handleUpdatedDevice,
  }) {
    assert(handleUpdatedDevice != null);
    assert(!_duringBuildPhase);
    assert(!_duringDeviceUpdate);
    final bool mouseWasConnected = mouseIsConnected;

    // If new event is not null, only the device that observed this event is
    // dirty. The target device's state is inserted into or removed from
    // `_mouseStates` if needed, stored as `targetState`, and its
    // `mostRecentDevice` is updated.
    _MouseState targetState;
    if (targetEvent != null) {
      targetState = _mouseStates[targetEvent.device];
      if (targetState == null) {
        targetState = _MouseState(initialEvent: targetEvent);
        _mouseStates[targetState.device] = targetState;
      } else {
        assert(targetEvent is! PointerAddedEvent);
        targetState.latestEvent = targetEvent;
        // Update mouseState to the latest devices that have not been removed,
        // so that [mouseIsConnected], which is decided by `_mouseStates`, is
        // correct during the callbacks.
        if (targetEvent is PointerRemovedEvent)
          _mouseStates.remove(targetEvent.device);
      }
    }
    assert((targetState == null) == (targetEvent == null));

    assert(() {
      _duringDeviceUpdate = true;
      return true;
    }());
    // We can safely use `_mouseStates` here without worrying about the removed
    // state, because `targetEvent` should be null when `_mouseStates` is used.
    final Iterable<_MouseState> dirtyStates = targetEvent == null ? _mouseStates.values : <_MouseState>[targetState];
    for (_MouseState dirtyState in dirtyStates) {
      final List<MouseTrackerAnnotation> nextAnnotations = _findAnnotations(dirtyState);
      final List<MouseTrackerAnnotation> lastAnnotations = dirtyState.replaceAnnotations(nextAnnotations);
      handleUpdatedDevice(dirtyState, lastAnnotations);
    }
    assert(() {
      _duringDeviceUpdate = false;
      return true;
    }());

    if (mouseWasConnected != mouseIsConnected)
      notifyListeners();
  }

  // Dispatch callbacks related to a device after all necessary information
  // has been collected.
  //
  // The `lastHoverPosition` can be null, which means the last event is not a
  // hover. Other arguments must not be null.
  static void _dispatchDeviceCallbacks({
    @required List<MouseTrackerAnnotation> lastAnnotations,
    @required List<MouseTrackerAnnotation> nextAnnotations,
    @required Offset lastHoverPosition,
    @required PointerEvent unhandledEvent,
    @required HashSet<Key> trackedAnnotationKeys,
  }) {
    assert(lastAnnotations != null);
    assert(nextAnnotations != null);
    // lastHoverPosition can be null
    assert(unhandledEvent != null);
    assert(trackedAnnotationKeys != null);
    // Order is important for mouse event callbacks. The `findAnnotations`
    // returns annotations in the visual order from front to back. We call
    // it the "visual order", and the opposite one "reverse visual order".
    // The algorithm here is explained in
    // https://github.com/flutter/flutter/issues/41420

    final HashSet<Key> lastKeys = HashSet<Key>.from(
      lastAnnotations.map<Key>((MouseTrackerAnnotation value) => value.key),
    );
    final HashSet<Key> nextKeys = HashSet<Key>.from(
      nextAnnotations.map<Key>((MouseTrackerAnnotation value) => value.key),
    );

    // Send exit events to annotations that are in last but not in next, in
    // visual order.
    final Iterable<MouseTrackerAnnotation> exitingAnnotations = lastAnnotations.where(
      (MouseTrackerAnnotation value) => !nextKeys.contains(value.key),
    );
    for (final MouseTrackerAnnotation annotation in exitingAnnotations) {
      final bool attached = trackedAnnotationKeys.contains(annotation.key);
      // Exit is not sent if annotation is no longer attached, because this
      // trigger may cause exceptions and has safer alternatives. See
      // [MouseRegion.onExit] for details.
      if (annotation.onExit != null && attached) {
        annotation.onExit(PointerExitEvent.fromMouseEvent(unhandledEvent));
      }
    }

    // Send enter events to annotations that are not in last but in next, in
    // reverse visual order.
    final Iterable<MouseTrackerAnnotation> enteringAnnotations = nextAnnotations.reversed.where(
      (MouseTrackerAnnotation value) => !lastKeys.contains(value.key),
    );
    for (final MouseTrackerAnnotation annotation in enteringAnnotations) {
      assert(trackedAnnotationKeys.contains(annotation.key));
      if (annotation.onEnter != null) {
        annotation.onEnter(PointerEnterEvent.fromMouseEvent(unhandledEvent));
      }
    }

    // Send hover events to annotations that are in next, in reverse visual order.
    // We chose reverse visual order only to keep it aligned with enter events
    // for simplicity.
    if (unhandledEvent is PointerHoverEvent) {
      final bool pointerHasMoved = lastHoverPosition == null || lastHoverPosition != unhandledEvent.position;
      // If the hover event follows a non-hover event, or has moved since the
      // last hover, then trigger hover the callback to all annotations.
      // Otherwise, trigger the hover callback only to annotations that it
      // newly enters.
      final Iterable<MouseTrackerAnnotation> hoveringAnnotations = pointerHasMoved ? nextAnnotations.reversed : enteringAnnotations;
      for (final MouseTrackerAnnotation annotation in hoveringAnnotations) {
        if (annotation.onHover != null) {
          annotation.onHover(unhandledEvent);
        }
      }
    }
  }

  bool _hasScheduledPostFrameCheck = false;
  /// Mark all devices as dirty, and schedule a callback that is executed in the
  /// upcoming post-frame phase to check their updates.
  ///
  /// Checking a device means to collect the annotations that the pointer
  /// hovers, and triggers necessary callbacks accordingly.
  ///
  /// Although the actual callback belongs to the scheduler's post-frame phase,
  /// this method must be called in persistent callback phase to ensure that
  /// the callback is scheduled after every frame, since every frame can change
  /// the position of annotations. Typically the method is called by
  /// [RendererBinding]'s drawing method.
  void schedulePostFrameCheck() {
    assert(_duringBuildPhase);
    assert(!_duringDeviceUpdate);
    if (!mouseIsConnected)
      return;
    if (!_hasScheduledPostFrameCheck) {
      _hasScheduledPostFrameCheck = true;
      SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
        assert(_hasScheduledPostFrameCheck);
        _hasScheduledPostFrameCheck = false;
        _updateAllDevices();
      });
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
  bool isAnnotationAttached(Key annotationKey) {
    if (annotationKey == null)
      return false;
    return _trackedAnnotationKeys.contains(annotationKey);
  }

  /// Notify [MouseTracker] that a new [MouseTrackerAnnotation] with the provided
  /// `key` has started to take effect.
  ///
  /// This method is typically called by the [RenderObject] that owns an
  /// annotation, as soon as the render object is added to the render tree.
  /// It's the caller's responsibility to ensure that no annotation with the
  /// same key is attached when calling this method.
  ///
  /// {@template flutter.mouseTracker.attachAnnotation}
  /// Only the [MouseTrackerAnnotation.key] property of the annotation is used
  /// for comparison, therefore we only need same key.
  ///
  /// Render objects that call this method might want to schedule a frame as
  /// well, typically by calling [RenderObject.markNeedsPaint], because this
  /// method does not cause any immediate effect, since the state it changes is
  /// used during a post-frame callback or when handling certain pointer events.
  ///
  /// ### About annotation attachment
  ///
  /// It is the responsibility of the render object that owns the annotation to
  /// maintain the attachment of the annotation. Whether an annotation is
  /// attached should be kept in sync with whether its owner object is mounted,
  /// which is used in the following ways:
  ///
  ///  * If a pointer enters an annotation, it is asserted that the annotation
  ///    is attached.
  ///  * If a pointer stops being contained by an annotation,
  ///    the exit event is triggered only if the annotation is still attached.
  ///    This is to prevent exceptions caused calling setState of a disposed
  ///    widget. See [MouseTrackerAnnotation.onExit] for more details.
  ///  * The [MouseTracker] also uses the attachment to track the number of
  ///    attached annotations, and will skip mouse position checks if there are no
  ///    annotations attached.
  /// {@endtemplate}
  ///  * Attaching an annotation that has been attached will assert.
  void attachAnnotation(Key annotationKey) {
    assert(!_duringDeviceUpdate);
    assert(annotationKey != null);
    assert(!_trackedAnnotationKeys.contains(annotationKey));
    _trackedAnnotationKeys.add(annotationKey);
  }

  /// Notify [MouseTracker] that a new [MouseTrackerAnnotation] with the provided
  /// `key` has stopped taking effect.
  ///
  /// This method is typically called by the [RenderObject] that owns an
  /// annotation, as soon as the render object is removed from the render tree.
  /// It's the caller's responsibility to ensure that one annotation with the
  /// same key is attached when calling this method.
  ///
  /// {@macro flutter.mouseTracker.attachAnnotation}
  ///  * Detaching an annotation that has not been attached will assert.
  void detachAnnotation(Key annotationKey) {
    assert(!_duringDeviceUpdate);
    assert(annotationKey != null);
    assert(_trackedAnnotationKeys.contains(annotationKey));
    _trackedAnnotationKeys.remove(annotationKey);
  }
}
