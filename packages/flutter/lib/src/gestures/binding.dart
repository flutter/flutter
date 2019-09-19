// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui show PointerDataPacket;

import 'package:flutter/foundation.dart';

import 'arena.dart';
import 'converter.dart';
import 'debug.dart';
import 'events.dart';
import 'hit_test.dart';
import 'pointer_router.dart';
import 'pointer_signal_resolver.dart';

/// A binding for the gesture subsystem.
///
/// ## Lifecycle of pointer events and the gesture arena
///
/// ### [PointerDownEvent]
///
/// When a [PointerDownEvent] is received by the [GestureBinding] (from
/// [Window.onPointerDataPacket], as interpreted by the
/// [PointerEventConverter]), a [hitTest] is performed to determine which
/// [HitTestTarget] nodes are affected. (Other bindings are expected to
/// implement [hitTest] to defer to [HitTestable] objects. For example, the
/// rendering layer defers to the [RenderView] and the rest of the render object
/// hierarchy.)
///
/// The affected nodes then are given the event to handle ([dispatchEvent] calls
/// [HitTestTarget.handleEvent] for each affected node). If any have relevant
/// [GestureRecognizer]s, they provide the event to them using
/// [GestureRecognizer.addPointer]. This typically causes the recognizer to
/// register with the [PointerRouter] to receive notifications regarding the
/// pointer in question.
///
/// Once the hit test and dispatching logic is complete, the event is then
/// passed to the aforementioned [PointerRouter], which passes it to any objects
/// that have registered interest in that event.
///
/// Finally, the [gestureArena] is closed for the given pointer
/// ([GestureArenaManager.close]), which begins the process of selecting a
/// gesture to win that pointer.
///
/// ### Other events
///
/// A pointer that is [PointerEvent.down] may send further events, such as
/// [PointerMoveEvent], [PointerUpEvent], or [PointerCancelEvent]. These are
/// sent to the same [HitTestTarget] nodes as were found when the down event was
/// received (even if they have since been disposed; it is the responsibility of
/// those objects to be aware of that possibility).
///
/// Then, the events are routed to any still-registered entrants in the
/// [PointerRouter]'s table for that pointer.
///
/// When a [PointerUpEvent] is received, the [GestureArenaManager.sweep] method
/// is invoked to force the gesture arena logic to terminate if necessary.
mixin GestureBinding on BindingBase implements HitTestable, HitTestDispatcher, HitTestTarget {
  @override
  void initInstances() {
    super.initInstances();
    _instance = this;
    window.onPointerDataPacket = _handlePointerDataPacket;
  }

  @override
  void unlocked() {
    super.unlocked();
    _flushPointerEventQueue();
  }

  /// The singleton instance of this object.
  static GestureBinding get instance => _instance;
  static GestureBinding _instance;

  final Queue<PointerEvent> _pendingPointerEvents = Queue<PointerEvent>();

  void _handlePointerDataPacket(ui.PointerDataPacket packet) {
    // We convert pointer data to logical pixels so that e.g. the touch slop can be
    // defined in a device-independent manner.
    _pendingPointerEvents.addAll(PointerEventConverter.expand(packet.data, window.devicePixelRatio));
    if (!locked)
      _flushPointerEventQueue();
  }

  /// Dispatch a [PointerCancelEvent] for the given pointer soon.
  ///
  /// The pointer event will be dispatched before the next pointer event and
  /// before the end of the microtask but not within this function call.
  void cancelPointer(int pointer) {
    if (_pendingPointerEvents.isEmpty && !locked)
      scheduleMicrotask(_flushPointerEventQueue);
    _pendingPointerEvents.addFirst(PointerCancelEvent(pointer: pointer));
  }

  void _flushPointerEventQueue() {
    assert(!locked);
    while (_pendingPointerEvents.isNotEmpty)
      _handlePointerEvent(_pendingPointerEvents.removeFirst());
  }

  /// A router that routes all pointer events received from the engine.
  final PointerRouter pointerRouter = PointerRouter();

  /// The gesture arenas used for disambiguating the meaning of sequences of
  /// pointer events.
  final GestureArenaManager gestureArena = GestureArenaManager();

  /// The resolver used for determining which widget handles a pointer
  /// signal event.
  final PointerSignalResolver pointerSignalResolver = PointerSignalResolver();

  /// State for all pointers which are currently down.
  ///
  /// The state of hovering pointers is not tracked because that would require
  /// hit-testing on every frame.
  final Map<int, HitTestResult> _hitTests = <int, HitTestResult>{};

  void _handlePointerEvent(PointerEvent event) {
    assert(!locked);
    HitTestResult hitTestResult;
    if (event is PointerDownEvent || event is PointerSignalEvent) {
      assert(!_hitTests.containsKey(event.pointer));
      hitTestResult = HitTestResult();
      hitTest(hitTestResult, event.position);
      if (event is PointerDownEvent) {
        _hitTests[event.pointer] = hitTestResult;
      }
      assert(() {
        if (debugPrintHitTestResults)
          debugPrint('$event: $hitTestResult');
        return true;
      }());
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      hitTestResult = _hitTests.remove(event.pointer);
    } else if (event.down) {
      // Because events that occur with the pointer down (like
      // PointerMoveEvents) should be dispatched to the same place that their
      // initial PointerDownEvent was, we want to re-use the path we found when
      // the pointer went down, rather than do hit detection each time we get
      // such an event.
      hitTestResult = _hitTests[event.pointer];
    }
    assert(() {
      if (debugPrintMouseHoverEvents && event is PointerHoverEvent)
        debugPrint('$event');
      return true;
    }());
    if (hitTestResult != null ||
        event is PointerHoverEvent ||
        event is PointerAddedEvent ||
        event is PointerRemovedEvent) {
      dispatchEvent(event, hitTestResult);
    }
  }

  /// Determine which [HitTestTarget] objects are located at a given position.
  @override // from HitTestable
  void hitTest(HitTestResult result, Offset position) {
    result.add(HitTestEntry(this));
  }

  /// Dispatch an event to a hit test result's path.
  ///
  /// This sends the given event to every [HitTestTarget] in the entries of the
  /// given [HitTestResult], and catches exceptions that any of the handlers
  /// might throw. The [hitTestResult] argument may only be null for
  /// [PointerHoverEvent], [PointerAddedEvent], or [PointerRemovedEvent] events.
  @override // from HitTestDispatcher
  void dispatchEvent(PointerEvent event, HitTestResult hitTestResult) {
    assert(!locked);
    // No hit test information implies that this is a hover or pointer
    // add/remove event.
    if (hitTestResult == null) {
      assert(event is PointerHoverEvent || event is PointerAddedEvent || event is PointerRemovedEvent);
      try {
        pointerRouter.route(event);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetailsForPointerEventDispatcher(
          exception: exception,
          stack: stack,
          library: 'gesture library',
          context: ErrorDescription('while dispatching a non-hit-tested pointer event'),
          event: event,
          hitTestEntry: null,
          informationCollector: () sync* {
            yield DiagnosticsProperty<PointerEvent>('Event', event, style: DiagnosticsTreeStyle.errorProperty);
          },
        ));
      }
      return;
    }
    for (HitTestEntry entry in hitTestResult.path) {
      try {
        entry.target.handleEvent(event.transformed(entry.transform), entry);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetailsForPointerEventDispatcher(
          exception: exception,
          stack: stack,
          library: 'gesture library',
          context: ErrorDescription('while dispatching a pointer event'),
          event: event,
          hitTestEntry: entry,
          informationCollector: () sync* {
            yield DiagnosticsProperty<PointerEvent>('Event', event, style: DiagnosticsTreeStyle.errorProperty);
            yield DiagnosticsProperty<HitTestTarget>('Target', entry.target, style: DiagnosticsTreeStyle.errorProperty);
          },
        ));
      }
    }
  }

  @override // from HitTestTarget
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    pointerRouter.route(event);
    if (event is PointerDownEvent) {
      gestureArena.close(event.pointer);
    } else if (event is PointerUpEvent) {
      gestureArena.sweep(event.pointer);
    } else if (event is PointerSignalEvent) {
      pointerSignalResolver.resolve(event);
    }
  }
}

/// Variant of [FlutterErrorDetails] with extra fields for the gesture
/// library's binding's pointer event dispatcher ([GestureBinding.dispatchEvent]).
///
/// See also [FlutterErrorDetailsForPointerRouter], which is also used by the
/// gesture library.
class FlutterErrorDetailsForPointerEventDispatcher extends FlutterErrorDetails {
  /// Creates a [FlutterErrorDetailsForPointerEventDispatcher] object with the given
  /// arguments setting the object's properties.
  ///
  /// The gesture library calls this constructor when catching an exception
  /// that will subsequently be reported using [FlutterError.onError].
  const FlutterErrorDetailsForPointerEventDispatcher({
    dynamic exception,
    StackTrace stack,
    String library,
    DiagnosticsNode context,
    this.event,
    this.hitTestEntry,
    InformationCollector informationCollector,
    bool silent = false,
  }) : super(
    exception: exception,
    stack: stack,
    library: library,
    context: context,
    informationCollector: informationCollector,
    silent: silent
  );

  /// The pointer event that was being routed when the exception was raised.
  final PointerEvent event;

  /// The hit test result entry for the object whose handleEvent method threw
  /// the exception. May be null if no hit test entry is associated with the
  /// event (e.g. hover and pointer add/remove events).
  ///
  /// The target object itself is given by the [HitTestEntry.target] property of
  /// the hitTestEntry object.
  final HitTestEntry hitTestEntry;
}
