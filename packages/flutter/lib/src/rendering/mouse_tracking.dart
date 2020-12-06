// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection' show LinkedHashMap;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import 'package:vector_math/vector_math_64.dart' show Matrix4;

import 'mouse_cursor.dart';
import 'object.dart';

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

/// The annotation object used to annotate regions that are interested in mouse
/// movements.
///
/// To use an annotation, push it with [AnnotatedRegionLayer] during painting.
/// The annotation's callbacks or configurations will be used depending on the
/// relationship between annotations and mouse pointers.
///
/// A [RenderObject] who uses this class must not dispose this class in its
/// `detach`, even if it recreates a new one in `attach`, because the object
/// might be detached and attached during the same frame during a reparent, and
/// replacing the `MouseTrackerAnnotation` will cause an unnecessary `onExit` and
/// `onEnter`.
///
/// This class is also the type parameter of the annotation search started by
/// [BaseMouseTracker].
///
/// See also:
///
///  * [BaseMouseTracker], which uses [MouseTrackerAnnotation].
class MouseTrackerAnnotation with Diagnosticable {
  /// Creates an immutable [MouseTrackerAnnotation].
  ///
  /// All arguments are optional. The [cursor] must not be null.
  const MouseTrackerAnnotation({
    this.onEnter,
    this.onHover,
    this.onExit,
    this.cursor = MouseCursor.defer,
  }) : assert(cursor != null);

  /// Triggered when a mouse pointer, with or without buttons pressed, has
  /// entered the region.
  ///
  /// This callback is triggered when the pointer has started to be contained by
  /// the region, either due to a pointer event, or due to the movement or
  /// disappearance of the region. This method is always matched by a later
  /// [onExit].
  ///
  /// See also:
  ///
  ///  * [onExit], which is triggered when a mouse pointer exits the region.
  ///  * [MouseRegion.onEnter], which uses this callback.
  final PointerEnterEventListener? onEnter;

  /// Triggered when a mouse pointer has moved onto or within the region without
  /// buttons pressed.
  ///
  /// This callback is not triggered by the movement of an annotation.
  ///
  /// See also:
  ///
  ///  * [MouseRegion.onHover], which uses this callback.
  final PointerHoverEventListener? onHover;

  /// Triggered when a mouse pointer, with or without buttons pressed, has
  /// exited the region.
  ///
  /// This callback is triggered when the pointer has stopped being contained
  /// by the region, either due to a pointer event, or due to the movement or
  /// disappearance of the region. This method always matches an earlier
  /// [onEnter].
  ///
  /// See also:
  ///
  ///  * [onEnter], which is triggered when a mouse pointer enters the region.
  ///  * [MouseRegion.onExit], which uses this callback, but is not triggered in
  ///    certain cases and does not always match its earlier [MouseRegion.onEnter].
  final PointerExitEventListener? onExit;

  /// The mouse cursor for mouse pointers that are hovering over the region.
  ///
  /// When a mouse enters the region, its cursor will be changed to the [cursor].
  /// When the mouse leaves the region, the cursor will be set by the region
  /// found at the new location.
  ///
  /// Defaults to [MouseCursor.defer], deferring the choice of cursor to the next
  /// region behind it in hit-test order.
  ///
  /// See also:
  ///
  ///  * [MouseRegion.cursor], which provide values to this field.
  final MouseCursor cursor;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagsSummary<Function?>(
      'callbacks',
      <String, Function?> {
        'enter': onEnter,
        'exit': onExit,
      },
      ifEmpty: '<none>',
    ));
    properties.add(DiagnosticsProperty<MouseCursor>('cursor', cursor, defaultValue: MouseCursor.defer));
  }
}

/// Signature for searching for [MouseTrackerAnnotation]s at the given offset.
///
/// It is used by the [BaseMouseTracker] to fetch annotations for the mouse
/// position.
typedef MouseDetectorAnnotationFinder = HitTestResult Function(Offset offset);

// Various states of a connected mouse device used by [BaseMouseTracker].
class _MouseState {
  _MouseState({
    required PointerEvent initialEvent,
  }) : assert(initialEvent != null),
       _latestEvent = initialEvent;

  // The list of annotations that contains this device.
  //
  // It uses [LinkedHashMap] to keep the insertion order.
  LinkedHashMap<MouseTrackerAnnotation, Matrix4> get annotations => _annotations;
  LinkedHashMap<MouseTrackerAnnotation, Matrix4> _annotations = LinkedHashMap<MouseTrackerAnnotation, Matrix4>();

  LinkedHashMap<MouseTrackerAnnotation, Matrix4> replaceAnnotations(LinkedHashMap<MouseTrackerAnnotation, Matrix4> value) {
    assert(value != null);
    final LinkedHashMap<MouseTrackerAnnotation, Matrix4> previous = _annotations;
    _annotations = value;
    return previous;
  }

  // The most recently processed mouse event observed from this device.
  PointerEvent get latestEvent => _latestEvent;
  PointerEvent _latestEvent;

  PointerEvent replaceLatestEvent(PointerEvent value) {
    assert(value != null);
    assert(value.device == _latestEvent.device);
    final PointerEvent previous = _latestEvent;
    _latestEvent = value;
    return previous;
  }

  int get device => latestEvent.device;

  @override
  String toString() {
    final String describeLatestEvent = 'latestEvent: ${describeIdentity(latestEvent)}';
    final String describeAnnotations = 'annotations: [list of ${annotations.length}]';
    return '${describeIdentity(this)}($describeLatestEvent, $describeAnnotations)';
  }
}

/// Used by [BaseMouseTracker] to provide the details of an update of a mouse
/// device.
///
/// This class contains the information needed to handle the update that might
/// change the state of a mouse device, or the [MouseTrackerAnnotation]s that
/// the mouse device is hovering.
@immutable
class MouseTrackerUpdateDetails with Diagnosticable {
  /// When device update is triggered by a new frame.
  ///
  /// All parameters are required.
  const MouseTrackerUpdateDetails.byNewFrame({
    required this.lastAnnotations,
    required this.nextAnnotations,
    required this.previousEvent,
  }) : assert(previousEvent != null),
       assert(lastAnnotations != null),
       assert(nextAnnotations != null),
       triggeringEvent = null;

  /// When device update is triggered by a pointer event.
  ///
  /// The [lastAnnotations], [nextAnnotations], and [triggeringEvent] are
  /// required.
  const MouseTrackerUpdateDetails.byPointerEvent({
    required this.lastAnnotations,
    required this.nextAnnotations,
    this.previousEvent,
    required PointerEvent this.triggeringEvent,
  }) : assert(triggeringEvent != null),
       assert(lastAnnotations != null),
       assert(nextAnnotations != null);

  /// The annotations that the device is hovering before the update.
  ///
  /// It is never null.
  final LinkedHashMap<MouseTrackerAnnotation, Matrix4> lastAnnotations;

  /// The annotations that the device is hovering after the update.
  ///
  /// It is never null.
  final LinkedHashMap<MouseTrackerAnnotation, Matrix4> nextAnnotations;

  /// The last event that the device observed before the update.
  ///
  /// If the update is triggered by a frame, the [previousEvent] is never null,
  /// since the pointer must have been added before.
  ///
  /// If the update is triggered by a pointer event, the [previousEvent] is not
  /// null except for cases where the event is the first event observed by the
  /// pointer (which is not necessarily a [PointerAddedEvent]).
  final PointerEvent? previousEvent;

  /// The event that triggered this update.
  ///
  /// It is non-null if and only if the update is triggered by a pointer event.
  final PointerEvent? triggeringEvent;

  /// The pointing device of this update.
  int get device {
    final int result = (previousEvent ?? triggeringEvent)!.device;
    assert(result != null);
    return result;
  }

  /// The last event that the device observed after the update.
  ///
  /// The [latestEvent] is never null.
  PointerEvent get latestEvent {
    final PointerEvent result = triggeringEvent ?? previousEvent!;
    assert(result != null);
    return result;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('device', device));
    properties.add(DiagnosticsProperty<PointerEvent>('previousEvent', previousEvent));
    properties.add(DiagnosticsProperty<PointerEvent>('triggeringEvent', triggeringEvent));
    properties.add(DiagnosticsProperty<Map<MouseTrackerAnnotation, Matrix4>>('lastAnnotations', lastAnnotations));
    properties.add(DiagnosticsProperty<Map<MouseTrackerAnnotation, Matrix4>>('nextAnnotations', nextAnnotations));
  }
}

/// A base class that tracks the relationship between mouse devices and
/// [MouseTrackerAnnotation]s.
///
/// An event (not necessarily a pointer event) that might change the relationship
/// between mouse devices and [MouseTrackerAnnotation]s is called a _device
/// update_.
///
/// [MouseTracker] is notified of device updates by [updateWithEvent] or
/// [updateAllDevices], and processes effects as defined in [handleDeviceUpdate]
/// by subclasses.
///
/// This class is a [ChangeNotifier] that notifies its listeners if the value of
/// [mouseIsConnected] changes.
///
/// See also:
///
///   * [MouseTracker], which is a subclass of [BaseMouseTracker] with definition
///     of how to process mouse event callbacks and mouse cursors.
///   * [MouseTrackerCursorMixin], which is a mixin for [BaseMouseTracker] that
///     defines how to process mouse cursors.
abstract class BaseMouseTracker extends ChangeNotifier {
  /// Whether or not at least one mouse is connected and has produced events.
  bool get mouseIsConnected => _mouseStates.isNotEmpty;

  // Tracks the state of connected mouse devices.
  //
  // It is the source of truth for the list of connected mouse devices, and is
  // consists of two parts:
  //
  //  * The mouse devices that are connected.
  //  * In which annotations each device is contained.
  final Map<int, _MouseState> _mouseStates = <int, _MouseState>{};

  // Used to wrap any procedure that might change `mouseIsConnected`.
  //
  // This method records `mouseIsConnected`, runs `task`, and calls
  // [notifyListeners] at the end if the `mouseIsConnected` has changed.
  void _monitorMouseConnection(VoidCallback task) {
    final bool mouseWasConnected = mouseIsConnected;
    task();
    if (mouseWasConnected != mouseIsConnected)
      notifyListeners();
  }

  bool _debugDuringDeviceUpdate = false;
  // Used to wrap any procedure that might call [handleDeviceUpdate].
  //
  // In debug mode, this method uses `_debugDuringDeviceUpdate` to prevent
  // `_deviceUpdatePhase` being recursively called.
  void _deviceUpdatePhase(VoidCallback task) {
    assert(!_debugDuringDeviceUpdate);
    assert(() {
      _debugDuringDeviceUpdate = true;
      return true;
    }());
    task();
    assert(() {
      _debugDuringDeviceUpdate = false;
      return true;
    }());
  }

  // Whether an observed event might update a device.
  static bool _shouldMarkStateDirty(_MouseState? state, PointerEvent event) {
    if (state == null)
      return true;
    assert(event != null);
    final PointerEvent lastEvent = state.latestEvent;
    assert(event.device == lastEvent.device);
    // An Added can only follow a Removed, and a Removed can only be followed
    // by an Added.
    assert((event is PointerAddedEvent) == (lastEvent is PointerRemovedEvent));

    // Ignore events that are unrelated to mouse tracking.
    if (event is PointerSignalEvent)
      return false;
    return lastEvent is PointerAddedEvent
      || event is PointerRemovedEvent
      || lastEvent.position != event.position;
  }

  LinkedHashMap<MouseTrackerAnnotation, Matrix4> _hitTestResultToAnnotations(HitTestResult result) {
    assert(result != null);
    final LinkedHashMap<MouseTrackerAnnotation, Matrix4> annotations = <MouseTrackerAnnotation, Matrix4>{}
        as LinkedHashMap<MouseTrackerAnnotation, Matrix4>;
    for (final HitTestEntry entry in result.path) {
      if (entry.target is MouseTrackerAnnotation) {
        annotations[entry.target as MouseTrackerAnnotation] = entry.transform!;
      }
    }
    return annotations;
  }

  // Find the annotations that is hovered by the device of the `state`, and
  // their respective global transform matrices.
  //
  // If the device is not connected or not a mouse, an empty map is returned
  // without calling `hitTest`.
  LinkedHashMap<MouseTrackerAnnotation, Matrix4> _findAnnotations(_MouseState state, MouseDetectorAnnotationFinder hitTest) {
    assert(state != null);
    assert(hitTest != null);
    final Offset globalPosition = state.latestEvent.position;
    final int device = state.device;
    if (!_mouseStates.containsKey(device))
      return <MouseTrackerAnnotation, Matrix4>{} as LinkedHashMap<MouseTrackerAnnotation, Matrix4>;

    return _hitTestResultToAnnotations(hitTest(globalPosition));
  }

  /// A callback that is called on the update of a device.
  ///
  /// This method should be called only by [BaseMouseTracker], each time when the
  /// relationship between a device and annotations has changed.
  ///
  /// By default the [handleDeviceUpdate] does nothing effective. Subclasses
  /// should override this method to first call to their inherited
  /// [handleDeviceUpdate] method, and then process the update as desired.
  ///
  /// The update can be caused by two kinds of triggers:
  ///
  ///   * Triggered by the addition, movement, or removal of a pointer. Such
  ///     calls occur during the handler of the event, indicated by
  ///     `details.triggeringEvent` being non-null.
  ///   * Triggered by the appearance, movement, or disappearance of an annotation.
  ///     Such calls occur after each new frame, during the post-frame callbacks,
  ///     indicated by `details.triggeringEvent` being null.
  ///
  /// Calling of this method must be wrapped in `_deviceUpdatePhase`.
  @protected
  @mustCallSuper
  void handleDeviceUpdate(MouseTrackerUpdateDetails details) {
    assert(_debugDuringDeviceUpdate);
  }

  /// Trigger a device update with a new event and its corresponding hit test
  /// result.
  ///
  /// The [updateWithEvent] indicates that an event has been observed, and
  /// is called during the handler of the event. The `getResult` should return
  /// the hit test result at the position of the event.
  ///
  /// The [updateWithEvent] will generate the new state for the pointer based on
  /// given information, and call [handleDeviceUpdate] based on the state changes.
  void updateWithEvent(PointerEvent event, ValueGetter<HitTestResult> getResult) {
    assert(event != null);
    final HitTestResult result = event is PointerRemovedEvent ? HitTestResult() : getResult();
    assert(result != null);
    if (event.kind != PointerDeviceKind.mouse)
      return;
    if (event is PointerSignalEvent)
      return;
    final int device = event.device;
    final _MouseState? existingState = _mouseStates[device];
    if (!_shouldMarkStateDirty(existingState, event))
      return;

    _monitorMouseConnection(() {
      _deviceUpdatePhase(() {
        // Update mouseState to the latest devices that have not been removed,
        // so that [mouseIsConnected], which is decided by `_mouseStates`, is
        // correct during the callbacks.
        if (existingState == null) {
          assert(event is! PointerRemovedEvent);
          _mouseStates[device] = _MouseState(initialEvent: event);
        } else {
          assert(event is! PointerAddedEvent);
          if (event is PointerRemovedEvent)
            _mouseStates.remove(event.device);
        }
        final _MouseState targetState = _mouseStates[device] ?? existingState!;

        final PointerEvent lastEvent = targetState.replaceLatestEvent(event);
        final LinkedHashMap<MouseTrackerAnnotation, Matrix4> nextAnnotations = event is PointerRemovedEvent ?
            <MouseTrackerAnnotation, Matrix4>{} as LinkedHashMap<MouseTrackerAnnotation, Matrix4> :
            _hitTestResultToAnnotations(result);
        final LinkedHashMap<MouseTrackerAnnotation, Matrix4> lastAnnotations = targetState.replaceAnnotations(nextAnnotations);

        handleDeviceUpdate(MouseTrackerUpdateDetails.byPointerEvent(
          lastAnnotations: lastAnnotations,
          nextAnnotations: nextAnnotations,
          previousEvent: lastEvent,
          triggeringEvent: event,
        ));
      });
    });
  }

  /// Trigger a device update for all detected devices.
  ///
  /// The [updateAllDevices] is typically called during the post frame phase,
  /// indicating a frame has passed and all objects have potentially moved. The
  /// `hitTest` is a function that can acquire the hit test result at a given
  /// position, and must not be empty.
  ///
  /// For each connected device, the [updateAllDevices] will make a hit test on
  /// the device's last seen position, generate the new state for the pointer
  /// based on given information, and call [handleDeviceUpdate] based on the
  /// state changes.
  void updateAllDevices(MouseDetectorAnnotationFinder hitTest) {
    _deviceUpdatePhase(() {
      for (final _MouseState dirtyState in _mouseStates.values) {
        final PointerEvent lastEvent = dirtyState.latestEvent;
        final LinkedHashMap<MouseTrackerAnnotation, Matrix4> nextAnnotations = _findAnnotations(dirtyState, hitTest);
        final LinkedHashMap<MouseTrackerAnnotation, Matrix4> lastAnnotations = dirtyState.replaceAnnotations(nextAnnotations);

        handleDeviceUpdate(MouseTrackerUpdateDetails.byNewFrame(
          lastAnnotations: lastAnnotations,
          nextAnnotations: nextAnnotations,
          previousEvent: lastEvent,
        ));
      }
    });
  }
}

// A mixin for [BaseMouseTracker] that dispatches mouse events on device update.
//
// See also:
//
//  * [MouseTracker], which uses this mixin.
mixin _MouseTrackerEventMixin on BaseMouseTracker {
  // Handles device update and dispatches mouse event callbacks.
  static void _handleDeviceUpdateMouseEvents(MouseTrackerUpdateDetails details) {
    final PointerEvent? previousEvent = details.previousEvent;
    final PointerEvent? triggeringEvent = details.triggeringEvent;
    final PointerEvent latestEvent = details.latestEvent;

    final LinkedHashMap<MouseTrackerAnnotation, Matrix4> lastAnnotations = details.lastAnnotations;
    final LinkedHashMap<MouseTrackerAnnotation, Matrix4> nextAnnotations = details.nextAnnotations;

    // Order is important for mouse event callbacks. The `findAnnotations`
    // returns annotations in the visual order from front to back. We call
    // it the "visual order", and the opposite one "reverse visual order".
    // The algorithm here is explained in
    // https://github.com/flutter/flutter/issues/41420

    // Send exit events to annotations that are in last but not in next, in
    // visual order.
    final PointerExitEvent baseExitEvent = PointerExitEvent.fromMouseEvent(latestEvent);
    lastAnnotations.forEach((MouseTrackerAnnotation annotation, Matrix4 transform) {
      if (!nextAnnotations.containsKey(annotation))
        if (annotation.onExit != null)
          annotation.onExit!(baseExitEvent.transformed(lastAnnotations[annotation]));
    });

    // Send enter events to annotations that are not in last but in next, in
    // reverse visual order.
    final List<MouseTrackerAnnotation> enteringAnnotations = nextAnnotations.keys.where(
      (MouseTrackerAnnotation annotation) => !lastAnnotations.containsKey(annotation),
    ).toList();
    final PointerEnterEvent baseEnterEvent = PointerEnterEvent.fromMouseEvent(latestEvent);
    for (final MouseTrackerAnnotation annotation in enteringAnnotations.reversed) {
      if (annotation.onEnter != null)
        annotation.onEnter!(baseEnterEvent.transformed(nextAnnotations[annotation]));
    }

    // Send hover events to annotations that are in next, in reverse visual
    // order. The reverse visual order is chosen only because of the simplicity
    // by keeping the hover events aligned with enter events.
    if (triggeringEvent is PointerHoverEvent) {
      final Offset? hoverPositionBeforeUpdate = previousEvent is PointerHoverEvent ? previousEvent.position : null;
      final bool pointerHasMoved = hoverPositionBeforeUpdate == null || hoverPositionBeforeUpdate != triggeringEvent.position;
      // If the hover event follows a non-hover event, or has moved since the
      // last hover, then trigger the hover callback on all annotations.
      // Otherwise, trigger the hover callback only on annotations that it
      // newly enters.
      final Iterable<MouseTrackerAnnotation> hoveringAnnotations = pointerHasMoved ? nextAnnotations.keys.toList().reversed : enteringAnnotations;
      for (final MouseTrackerAnnotation annotation in hoveringAnnotations) {
        if (annotation.onHover != null) {
          annotation.onHover!(triggeringEvent.transformed(nextAnnotations[annotation]));
        }
      }
    }
  }

  @protected
  @override
  void handleDeviceUpdate(MouseTrackerUpdateDetails details) {
    super.handleDeviceUpdate(details);
    _handleDeviceUpdateMouseEvents(details);
  }
}

/// Tracks the relationship between mouse devices and annotations, and
/// triggers mouse events and cursor changes accordingly.
///
/// The [MouseTracker] tracks the relationship between mouse devices and
/// [MouseTrackerAnnotation]s, and when such relationship changes, triggers
/// the following changes if applicable:
///
///  * Dispatches mouse-related pointer events (pointer enter, hover, and exit).
///  * Notifies changes of [mouseIsConnected].
///  * Changes mouse cursors.
///
/// An instance of [MouseTracker] is owned by the global singleton of
/// [RendererBinding].
///
/// This class is a [ChangeNotifier] that notifies its listeners if the value of
/// [mouseIsConnected] changes.
///
/// See also:
///
///   * [BaseMouseTracker], which introduces more details about the timing of
///     device updates.
class MouseTracker extends BaseMouseTracker with MouseTrackerCursorMixin, _MouseTrackerEventMixin {
}
