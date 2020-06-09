// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'dart:ui' show PointerChange;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../flutter_test_alternative.dart';

typedef HandleEventCallback = void Function(PointerEvent event);

class _TestGestureFlutterBinding extends BindingBase
    with SchedulerBinding, ServicesBinding, GestureBinding, SemanticsBinding, RendererBinding {
  @override
  void initInstances() {
    super.initInstances();
    postFrameCallbacks = <void Function(Duration)>[];
  }

  SchedulerPhase _overridePhase;
  @override
  SchedulerPhase get schedulerPhase => _overridePhase ?? super.schedulerPhase;

  // Mannually schedule a postframe check.
  //
  // In real apps this is done by the renderer binding, but in tests we have to
  // bypass the phase assertion of [MouseTracker.schedulePostFrameCheck].
  void scheduleMouseTrackerPostFrameCheck() {
    final SchedulerPhase lastPhase = _overridePhase;
    _overridePhase = SchedulerPhase.persistentCallbacks;
    mouseTracker.schedulePostFrameCheck();
    _overridePhase = lastPhase;
  }

  List<void Function(Duration)> postFrameCallbacks;

  // Proxy post-frame callbacks.
  @override
  void addPostFrameCallback(void Function(Duration) callback) {
    postFrameCallbacks.add(callback);
  }

  void flushPostFrameCallbacks(Duration duration) {
    for (final void Function(Duration) callback in postFrameCallbacks) {
      callback(duration);
    }
    postFrameCallbacks.clear();
  }
}

_TestGestureFlutterBinding _binding = _TestGestureFlutterBinding();
MouseTracker get _mouseTracker => RendererBinding.instance.mouseTracker;

void _ensureTestGestureBinding() {
  _binding ??= _TestGestureFlutterBinding();
  assert(GestureBinding.instance != null);
}

void main() {
  void _setUpMouseAnnotationFinder(MouseDetectorAnnotationFinder annotationFinder) {
    final MouseTracker mouseTracker = MouseTracker(
      GestureBinding.instance.pointerRouter,
      annotationFinder,
    );
    RendererBinding.instance.initMouseTracker(mouseTracker);
  }

  // Set up a trivial test environment that includes one annotation.
  // This annotation records the enter, hover, and exit events it receives to
  // `logEvents`.
  // This annotation also contains a cursor with a value of `testCursor`.
  // The mouse tracker records the cursor requests it receives to `logCursors`.
  MouseTrackerAnnotation _setUpWithOneAnnotation({List<PointerEvent> logEvents}) {
    final MouseTrackerAnnotation annotation = MouseTrackerAnnotation(
      onEnter: (PointerEnterEvent event) {
        if (logEvents != null)
          logEvents.add(event);
      },
      onHover: (PointerHoverEvent event) {
        if (logEvents != null)
          logEvents.add(event);
      },
      onExit: (PointerExitEvent event) {
        if (logEvents != null)
          logEvents.add(event);
      },
    );
    _setUpMouseAnnotationFinder(
      (Offset position) sync* {
        yield annotation;
      },
    );
    return annotation;
  }

  setUp(() {
    _ensureTestGestureBinding();
    _binding.postFrameCallbacks.clear();
  });

  test('MouseTrackerAnnotation has correct toString', () {
    final MouseTrackerAnnotation annotation1 = MouseTrackerAnnotation(
      onEnter: (_) {},
      onExit: (_) {},
      onHover: (_) {},
    );
    expect(
      annotation1.toString(),
      equals('MouseTrackerAnnotation#${shortHash(annotation1)}(callbacks: [enter, hover, exit])'),
    );

    const MouseTrackerAnnotation annotation2 = MouseTrackerAnnotation();
    expect(
      annotation2.toString(),
      equals('MouseTrackerAnnotation#${shortHash(annotation2)}(callbacks: <none>)'),
    );

    final MouseTrackerAnnotation annotation3 = MouseTrackerAnnotation(
      onEnter: (_) {},
      cursor: SystemMouseCursors.grab,
    );
    expect(
      annotation3.toString(),
      equals('MouseTrackerAnnotation#${shortHash(annotation3)}(callbacks: [enter], cursor: SystemMouseCursor(grab))'),
    );
  });

  test('should detect enter, hover, and exit from Added, Hover, and Removed events', () {
    final List<PointerEvent> events = <PointerEvent>[];
    _setUpWithOneAnnotation(logEvents: events);

    final List<bool> listenerLogs = <bool>[];
    _mouseTracker.addListener(() {
      listenerLogs.add(_mouseTracker.mouseIsConnected);
    });

    expect(_mouseTracker.mouseIsConnected, isFalse);

    // Pointer enters the annotation.
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.add, const Offset(0.0, 0.0)),
    ]));

    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerEnterEvent(position: Offset(0.0, 0.0)),
    ]));
    expect(listenerLogs, <bool>[true]);
    events.clear();
    listenerLogs.clear();

    // Pointer hovers the annotation.
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.hover, const Offset(1.0, 101.0)),
    ]));
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerHoverEvent(position: Offset(1.0, 101.0)),
    ]));
    expect(_mouseTracker.mouseIsConnected, isTrue);
    expect(listenerLogs, isEmpty);
    events.clear();

    // Pointer is removed while on the annotation.
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.remove, const Offset(1.0, 101.0)),
    ]));
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerExitEvent(position: Offset(1.0, 101.0)),
    ]));
    expect(listenerLogs, <bool>[false]);
    events.clear();
    listenerLogs.clear();

    // Pointer is added on the annotation.
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.add, const Offset(0.0, 301.0)),
    ]));
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerEnterEvent(position: Offset(0.0, 301.0)),
    ]));
    expect(listenerLogs, <bool>[true]);
    events.clear();
    listenerLogs.clear();
  });

  test('should correctly handle multiple devices', () {
    final List<PointerEvent> events = <PointerEvent>[];
    _setUpWithOneAnnotation(logEvents: events);

    expect(_mouseTracker.mouseIsConnected, isFalse);

    // The first mouse is added on the annotation.
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.add, const Offset(0.0, 0.0)),
      _pointerData(PointerChange.hover, const Offset(0.0, 1.0)),
    ]));
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerEnterEvent(position: Offset(0.0, 0.0)),
      const PointerHoverEvent(position: Offset(0.0, 1.0)),
    ]));
    expect(_mouseTracker.mouseIsConnected, isTrue);
    events.clear();

    // The second mouse is added on the annotation.
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.add, const Offset(0.0, 401.0), device: 1),
      _pointerData(PointerChange.hover, const Offset(1.0, 401.0), device: 1),
    ]));
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerEnterEvent(position: Offset(0.0, 401.0), device: 1),
      const PointerHoverEvent(position: Offset(1.0, 401.0), device: 1),
    ]));
    expect(_mouseTracker.mouseIsConnected, isTrue);
    events.clear();

    // The first mouse moves on the annotation.
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.hover, const Offset(0.0, 101.0)),
    ]));
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerHoverEvent(position: Offset(0.0, 101.0)),
    ]));
    expect(_mouseTracker.mouseIsConnected, isTrue);
    events.clear();

    // The second mouse moves on the annotation.
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.hover, const Offset(1.0, 501.0), device: 1),
    ]));
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerHoverEvent(position: Offset(1.0, 501.0), device: 1),
    ]));
    expect(_mouseTracker.mouseIsConnected, isTrue);
    events.clear();

    // The first mouse is removed while on the annotation.
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.remove, const Offset(0.0, 101.0)),
    ]));
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerExitEvent(position: Offset(0.0, 101.0)),
    ]));
    expect(_mouseTracker.mouseIsConnected, isTrue);
    events.clear();

    // The second mouse still moves on the annotation.
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.hover, const Offset(1.0, 601.0), device: 1),
    ]));
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerHoverEvent(position: Offset(1.0, 601.0), device: 1),
    ]));
    expect(_mouseTracker.mouseIsConnected, isTrue);
    events.clear();

    // The second mouse is removed while on the annotation.
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.remove, const Offset(1.0, 601.0), device: 1),
    ]));
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerExitEvent(position: Offset(1.0, 601.0), device: 1),
    ]));
    expect(_mouseTracker.mouseIsConnected, isFalse);
    events.clear();
  });

  test('should not handle non-hover events', () {
    final List<PointerEvent> events = <PointerEvent>[];
    _setUpWithOneAnnotation(logEvents: events);

    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.add, const Offset(0.0, 101.0)),
      _pointerData(PointerChange.down, const Offset(0.0, 101.0)),
    ]));
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      // This Enter event is triggered by the [PointerAddedEvent] The
      // [PointerDownEvent] is ignored by [MouseTracker].
      const PointerEnterEvent(position: Offset(0.0, 101.0)),
    ]));
    events.clear();

    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.move, const Offset(0.0, 201.0)),
    ]));
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
    ]));
    events.clear();

    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.up, const Offset(0.0, 301.0)),
    ]));
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
    ]));
    events.clear();
  });

  test('should correctly handle when the annotation appears or disappears on the pointer', () {
    bool isInHitRegion;
    final List<Object> events = <PointerEvent>[];
    final MouseTrackerAnnotation annotation = MouseTrackerAnnotation(
      onEnter: (PointerEnterEvent event) => events.add(event),
      onHover: (PointerHoverEvent event) => events.add(event),
      onExit: (PointerExitEvent event) => events.add(event),
    );
    _setUpMouseAnnotationFinder((Offset position) sync* {
      if (isInHitRegion) {
        yield annotation;
      }
    });

    isInHitRegion = false;

    // Connect a mouse when there is no annotation.
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.add, const Offset(0.0, 100.0)),
    ]));
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
    ]));
    expect(_mouseTracker.mouseIsConnected, isTrue);
    events.clear();

    // Adding an annotation should trigger Enter event.
    isInHitRegion = true;
    _binding.scheduleMouseTrackerPostFrameCheck();
    expect(_binding.postFrameCallbacks, hasLength(1));

    _binding.flushPostFrameCallbacks(Duration.zero);
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerEnterEvent(position: Offset(0.0, 100.0)),
    ]));
    events.clear();

    // Removing an annotation should trigger events.
    isInHitRegion = false;
    _binding.scheduleMouseTrackerPostFrameCheck();
    expect(_binding.postFrameCallbacks, hasLength(1));

    _binding.flushPostFrameCallbacks(Duration.zero);
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerExitEvent(position: Offset(0.0, 100.0)),
    ]));
    expect(_binding.postFrameCallbacks, hasLength(0));
  });

  test('should correctly handle when the annotation moves in or out of the pointer', () {
    bool isInHitRegion;
    final List<Object> events = <PointerEvent>[];
    final MouseTrackerAnnotation annotation = MouseTrackerAnnotation(
      onEnter: (PointerEnterEvent event) => events.add(event),
      onHover: (PointerHoverEvent event) => events.add(event),
      onExit: (PointerExitEvent event) => events.add(event),
    );
    _setUpMouseAnnotationFinder((Offset position) sync* {
      if (isInHitRegion) {
        yield annotation;
      }
    });

    isInHitRegion = false;

    // Connect a mouse.
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.add, const Offset(0.0, 100.0)),
    ]));
    events.clear();

    // During a frame, the annotation moves into the pointer.
    isInHitRegion = true;
    expect(_binding.postFrameCallbacks, hasLength(0));
    _binding.scheduleMouseTrackerPostFrameCheck();
    expect(_binding.postFrameCallbacks, hasLength(1));

    _binding.flushPostFrameCallbacks(Duration.zero);
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerEnterEvent(position: Offset(0.0, 100.0)),
    ]));
    events.clear();

    expect(_binding.postFrameCallbacks, hasLength(0));

    // During a frame, the annotation moves out of the pointer.
    isInHitRegion = false;
    expect(_binding.postFrameCallbacks, hasLength(0));
    _binding.scheduleMouseTrackerPostFrameCheck();
    expect(_binding.postFrameCallbacks, hasLength(1));

    _binding.flushPostFrameCallbacks(Duration.zero);
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerExitEvent(position: Offset(0.0, 100.0)),
    ]));
    expect(_binding.postFrameCallbacks, hasLength(0));
  });

  test('should correctly handle when the pointer is added or removed on the annotation', () {
    bool isInHitRegion;
    final List<Object> events = <PointerEvent>[];
    final MouseTrackerAnnotation annotation = MouseTrackerAnnotation(
      onEnter: (PointerEnterEvent event) => events.add(event),
      onHover: (PointerHoverEvent event) => events.add(event),
      onExit: (PointerExitEvent event) => events.add(event),
    );
    _setUpMouseAnnotationFinder((Offset position) sync* {
      if (isInHitRegion) {
        yield annotation;
      }
    });

    isInHitRegion = false;

    // Connect a mouse in the region. Should trigger Enter.
    isInHitRegion = true;
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.add, const Offset(0.0, 100.0)),
    ]));

    expect(_binding.postFrameCallbacks, hasLength(0));
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerEnterEvent(position: Offset(0.0, 100.0)),
    ]));
    events.clear();

    // Disconnect the mouse from the region. Should trigger Exit.
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.remove, const Offset(0.0, 100.0)),
    ]));
    expect(_binding.postFrameCallbacks, hasLength(0));
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerExitEvent(position: Offset(0.0, 100.0)),
    ]));
  });

  test('should correctly handle when the pointer moves in or out of the annotation', () {
    bool isInHitRegion;
    final List<Object> events = <PointerEvent>[];
    final MouseTrackerAnnotation annotation = MouseTrackerAnnotation(
      onEnter: (PointerEnterEvent event) => events.add(event),
      onHover: (PointerHoverEvent event) => events.add(event),
      onExit: (PointerExitEvent event) => events.add(event),
    );
    _setUpMouseAnnotationFinder((Offset position) sync* {
      if (isInHitRegion) {
        yield annotation;
      }
    });

    isInHitRegion = false;
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.add, const Offset(200.0, 100.0)),
    ]));

    expect(_binding.postFrameCallbacks, hasLength(0));
    events.clear();

    // Moves the mouse into the region. Should trigger Enter.
    isInHitRegion = true;
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.hover, const Offset(0.0, 100.0)),
    ]));
    expect(_binding.postFrameCallbacks, hasLength(0));
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerEnterEvent(position: Offset(0.0, 100.0)),
      const PointerHoverEvent(position: Offset(0.0, 100.0)),
    ]));
    events.clear();

    // Moves the mouse out of the region. Should trigger Exit.
    isInHitRegion = false;
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.hover, const Offset(200.0, 100.0)),
    ]));
    expect(_binding.postFrameCallbacks, hasLength(0));
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerExitEvent(position: Offset(200.0, 100.0)),
    ]));
  });

  test('should not schedule postframe callbacks when no mouse is connected', () {
    _setUpMouseAnnotationFinder((Offset position) sync* {
    });

    // Connect a touch device, which should not be recognized by MouseTracker
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.add, const Offset(0.0, 100.0), kind: PointerDeviceKind.touch),
    ]));
    expect(_mouseTracker.mouseIsConnected, isFalse);

    expect(_binding.postFrameCallbacks, hasLength(0));
  });

  test('should not flip out if not all mouse events are listened to', () {
    bool isInHitRegionOne = true;
    bool isInHitRegionTwo = false;
    final MouseTrackerAnnotation annotation1 = MouseTrackerAnnotation(
      onEnter: (PointerEnterEvent event) {}
    );
    final MouseTrackerAnnotation annotation2 = MouseTrackerAnnotation(
      onExit: (PointerExitEvent event) {}
    );
    _setUpMouseAnnotationFinder((Offset position) sync* {
      if (isInHitRegionOne)
        yield annotation1;
      else if (isInHitRegionTwo)
        yield annotation2;
    });

    isInHitRegionOne = false;
    isInHitRegionTwo = true;
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.add, const Offset(0.0, 101.0)),
      _pointerData(PointerChange.hover, const Offset(1.0, 101.0)),
    ]));

    // Passes if no errors are thrown.
  });

  test('should trigger callbacks between parents and children in correct order', () {
    // This test simulates the scenario of a layer being the child of another.
    //
    //   ———————————
    //   |A        |
    //   |  —————— |
    //   |  |B   | |
    //   |  —————— |
    //   ———————————

    bool isInB;
    final List<String> logs = <String>[];
    final MouseTrackerAnnotation annotationA = MouseTrackerAnnotation(
      onEnter: (PointerEnterEvent event) => logs.add('enterA'),
      onExit: (PointerExitEvent event) => logs.add('exitA'),
      onHover: (PointerHoverEvent event) => logs.add('hoverA'),
    );
    final MouseTrackerAnnotation annotationB = MouseTrackerAnnotation(
      onEnter: (PointerEnterEvent event) => logs.add('enterB'),
      onExit: (PointerExitEvent event) => logs.add('exitB'),
      onHover: (PointerHoverEvent event) => logs.add('hoverB'),
    );
    _setUpMouseAnnotationFinder((Offset position) sync* {
      // Children's annotations come before parents'.
      if (isInB) {
        yield annotationB;
        yield annotationA;
      }
    });

    // Starts out of A.
    isInB = false;
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.add, const Offset(0.0, 1.0)),
    ]));
    expect(logs, <String>[]);

    // Moves into B within one frame.
    isInB = true;
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.hover, const Offset(0.0, 10.0)),
    ]));
    expect(logs, <String>['enterA', 'enterB', 'hoverA', 'hoverB']);
    logs.clear();

    // Moves out of A within one frame.
    isInB = false;
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.hover, const Offset(0.0, 20.0)),
    ]));
    expect(logs, <String>['exitB', 'exitA']);
  });

  test('should trigger callbacks between disjoint siblings in correctly order', () {
    // This test simulates the scenario of 2 sibling layers that do not overlap
    // with each other.
    //
    //   ————————  ————————
    //   |A     |  |B     |
    //   |      |  |      |
    //   ————————  ————————

    bool isInA;
    bool isInB;
    final List<String> logs = <String>[];
    final MouseTrackerAnnotation annotationA = MouseTrackerAnnotation(
      onEnter: (PointerEnterEvent event) => logs.add('enterA'),
      onExit: (PointerExitEvent event) => logs.add('exitA'),
      onHover: (PointerHoverEvent event) => logs.add('hoverA'),
    );
    final MouseTrackerAnnotation annotationB = MouseTrackerAnnotation(
      onEnter: (PointerEnterEvent event) => logs.add('enterB'),
      onExit: (PointerExitEvent event) => logs.add('exitB'),
      onHover: (PointerHoverEvent event) => logs.add('hoverB'),
    );
    _setUpMouseAnnotationFinder((Offset position) sync* {
      if (isInA) {
        yield annotationA;
      } else if (isInB) {
        yield annotationB;
      }
    });

    // Starts within A.
    isInA = true;
    isInB = false;
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.add, const Offset(0.0, 1.0)),
    ]));
    expect(logs, <String>['enterA']);
    logs.clear();

    // Moves into B within one frame.
    isInA = false;
    isInB = true;
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.hover, const Offset(0.0, 10.0)),
    ]));
    expect(logs, <String>['exitA', 'enterB', 'hoverB']);
    logs.clear();

    // Moves into A within one frame.
    isInA = true;
    isInB = false;
    ui.window.onPointerDataPacket(ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.hover, const Offset(0.0, 1.0)),
    ]));
    expect(logs, <String>['exitB', 'enterA', 'hoverA']);
  });
}

ui.PointerData _pointerData(
  PointerChange change,
  Offset logicalPosition, {
  int device = 0,
  PointerDeviceKind kind = PointerDeviceKind.mouse,
}) {
  return ui.PointerData(
    change: change,
    physicalX: logicalPosition.dx * ui.window.devicePixelRatio,
    physicalY: logicalPosition.dy * ui.window.devicePixelRatio,
    kind: kind,
    device: device,
  );
}

class _EventCriticalFieldsMatcher extends Matcher {
  _EventCriticalFieldsMatcher(this._expected)
    : assert(_expected != null);

  final PointerEvent _expected;

  bool _matchesField(Map<dynamic, dynamic> matchState, String field,
      dynamic actual, dynamic expected) {
    if (actual != expected) {
      addStateInfo(matchState, <dynamic, dynamic>{
        'field': field,
        'expected': expected,
        'actual': actual,
      });
      return false;
    }
    return true;
  }

  @override
  bool matches(dynamic untypedItem, Map<dynamic, dynamic> matchState) {
    if (untypedItem.runtimeType != _expected.runtimeType) {
      return false;
    }

    final PointerEvent actual = untypedItem as PointerEvent;
    if (!(
      _matchesField(matchState, 'kind', actual.kind, PointerDeviceKind.mouse) &&
      _matchesField(matchState, 'position', actual.position, _expected.position) &&
      _matchesField(matchState, 'device', actual.device, _expected.device)
    )) {
      return false;
    }
    return true;
  }

  @override
  Description describe(Description description) {
    return description
      .add('event (critical fields only) ')
      .addDescriptionOf(_expected);
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item.runtimeType != _expected.runtimeType) {
      return mismatchDescription
        .add('is ')
        .addDescriptionOf(item.runtimeType)
        .add(" and doesn't match ")
        .addDescriptionOf(_expected.runtimeType);
    }
    return mismatchDescription
      .add('has ')
      .addDescriptionOf(matchState['actual'])
      .add(" at field `${matchState['field']}`, which doesn't match the expected ")
      .addDescriptionOf(matchState['expected']);
  }
}

class _EventListCriticalFieldsMatcher extends Matcher {
  _EventListCriticalFieldsMatcher(this._expected);

  final Iterable<PointerEvent> _expected;

  @override
  bool matches(dynamic untypedItem, Map<dynamic, dynamic> matchState) {
    if (untypedItem is! Iterable<PointerEvent>)
      return false;
    final Iterable<PointerEvent> item = untypedItem as Iterable<PointerEvent>;
    final Iterator<PointerEvent> iterator = item.iterator;
    if (item.length != _expected.length)
      return false;
    int i = 0;
    for (final PointerEvent e in _expected) {
      iterator.moveNext();
      final Matcher matcher = _EventCriticalFieldsMatcher(e);
      final Map<dynamic, dynamic> subState = <dynamic, dynamic>{};
      final PointerEvent actual = iterator.current;
      if (!matcher.matches(actual, subState)) {
        addStateInfo(matchState, <dynamic, dynamic>{
          'index': i,
          'expected': e,
          'actual': actual,
          'matcher': matcher,
          'state': subState,
        });
        return false;
      }
      i++;
    }
    return true;
  }

  @override
  Description describe(Description description) {
    return description
      .add('event list (critical fields only) ')
      .addDescriptionOf(_expected);
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is! Iterable<PointerEvent>) {
      return mismatchDescription
        .add('is type ${item.runtimeType} instead of Iterable<PointerEvent>');
    } else if (item.length != _expected.length) {
      return mismatchDescription
        .add('has length ${item.length} instead of ${_expected.length}');
    } else if (matchState['matcher'] == null) {
      return mismatchDescription
        .add('met unexpected fatal error');
    } else {
      mismatchDescription
        .add('has\n  ')
        .addDescriptionOf(matchState['actual'])
        .add("\nat index ${matchState['index']}, which doesn't match\n  ")
        .addDescriptionOf(matchState['expected'])
        .add('\nsince it ');
      final Description subDescription = StringDescription();
      final Matcher matcher = matchState['matcher'] as Matcher;
      matcher.describeMismatch(matchState['actual'], subDescription,
        matchState['state'] as Map<dynamic, dynamic>, verbose);
      mismatchDescription.add(subDescription.toString());
      return mismatchDescription;
    }
  }
}

Matcher _equalToEventsOnCriticalFields(List<PointerEvent> source) {
  return _EventListCriticalFieldsMatcher(source);
}
