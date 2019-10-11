// Copyright 2018 The Chromium Authors. All rights reserved.
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

class TestGestureFlutterBinding extends BindingBase with ServicesBinding, SchedulerBinding, GestureBinding, SemanticsBinding, RendererBinding {
  HandleEventCallback callback;

  @override
  void handleEvent(PointerEvent event, HitTestEntry entry) {
    super.handleEvent(event, entry);
    if (callback != null) {
      callback(event);
    }
  }
}

TestGestureFlutterBinding _binding = TestGestureFlutterBinding();

void ensureTestGestureBinding() {
  _binding ??= TestGestureFlutterBinding();
  assert(GestureBinding.instance != null);
}

void main() {
  setUp(ensureTestGestureBinding);

  final List<PointerEvent> events = <PointerEvent>[];
  final MouseTrackerAnnotation annotation = MouseTrackerAnnotation(
    onEnter: (PointerEnterEvent event) => events.add(event),
    onHover: (PointerHoverEvent event) => events.add(event),
    onExit: (PointerExitEvent event) => events.add(event),
  );
  // Only respond to some mouse events.
  final MouseTrackerAnnotation partialAnnotation = MouseTrackerAnnotation(
    onEnter: (PointerEnterEvent event) => events.add(event),
    onHover: (PointerHoverEvent event) => events.add(event),
  );
  bool isInHitRegionOne;
  bool isInHitRegionTwo;

  void clear() {
    events.clear();
  }

  setUp(() {
    clear();
    isInHitRegionOne = true;
    isInHitRegionTwo = false;
    RendererBinding.instance.initMouseTracker(
      MouseTracker(
        GestureBinding.instance.pointerRouter,
        (Offset position) sync* {
          if (isInHitRegionOne)
            yield annotation;
          else if (isInHitRegionTwo) {
            yield partialAnnotation;
          }
        },
      ),
    );
    PointerEventConverter.clearPointers();
  });

  test('receives and processes mouse hover events', () {
    final ui.PointerDataPacket packet1 = ui.PointerDataPacket(data: <ui.PointerData>[
      // Will implicitly also add a PointerAdded event.
      _pointerData(PointerChange.hover, const Offset(0.0, 0.0)),
    ]);
    final ui.PointerDataPacket packet2 = ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.hover, const Offset(1.0, 101.0)),
    ]);
    final ui.PointerDataPacket packet3 = ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.remove, const Offset(1.0, 201.0)),
    ]);
    final ui.PointerDataPacket packet4 = ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.hover, const Offset(1.0, 301.0)),
    ]);
    final ui.PointerDataPacket packet5 = ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.hover, const Offset(1.0, 401.0), device: 1),
    ]);
    RendererBinding.instance.mouseTracker.attachAnnotation(annotation);
    isInHitRegionOne = true;
    ui.window.onPointerDataPacket(packet1);
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerEnterEvent(position: Offset(0.0, 0.0)),
      const PointerHoverEvent(position: Offset(0.0, 0.0)),
    ]));
    clear();

    ui.window.onPointerDataPacket(packet2);
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerHoverEvent(position: Offset(1.0, 101.0)),
    ]));
    clear();

    ui.window.onPointerDataPacket(packet3);
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerHoverEvent(position: Offset(1.0, 201.0)),
      const PointerExitEvent(position: Offset(1.0, 201.0)),
    ]));

    clear();
    ui.window.onPointerDataPacket(packet4);
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerEnterEvent(position: Offset(1.0, 301.0)),
      const PointerHoverEvent(position: Offset(1.0, 301.0)),
    ]));

    // add in a second mouse simultaneously.
    clear();
    ui.window.onPointerDataPacket(packet5);
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerEnterEvent(position: Offset(1.0, 401.0), device: 1),
      const PointerHoverEvent(position: Offset(1.0, 401.0), device: 1),
    ]));
  });

  test('detects exit when annotated layer no longer hit', () {
    final ui.PointerDataPacket packet1 = ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.hover, const Offset(0.0, 0.0)),
      _pointerData(PointerChange.hover, const Offset(1.0, 101.0)),
    ]);
    final ui.PointerDataPacket packet2 = ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.hover, const Offset(1.0, 201.0)),
    ]);
    isInHitRegionOne = true;
    RendererBinding.instance.mouseTracker.attachAnnotation(annotation);

    ui.window.onPointerDataPacket(packet1);

    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerEnterEvent(position: Offset(0.0, 0.0)),
      const PointerHoverEvent(position: Offset(0.0, 0.0)),
      const PointerHoverEvent(position: Offset(1.0, 101.0)),
    ]));
    // Simulate layer going away by detaching it.
    clear();
    isInHitRegionOne = false;

    ui.window.onPointerDataPacket(packet2);
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerExitEvent(position: Offset(1.0, 201.0)),
    ]));

    // Actually detach annotation. Shouldn't receive hit.
    RendererBinding.instance.mouseTracker.detachAnnotation(annotation);
    clear();
    isInHitRegionOne = false;

    ui.window.onPointerDataPacket(packet2);
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
    ]));
  });

  test("don't flip out if not all mouse events are listened to", () {
    final ui.PointerDataPacket packet = ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.hover, const Offset(1.0, 101.0)),
    ]);

    isInHitRegionOne = false;
    isInHitRegionTwo = true;
    RendererBinding.instance.mouseTracker.attachAnnotation(partialAnnotation);

    ui.window.onPointerDataPacket(packet);
    RendererBinding.instance.mouseTracker.detachAnnotation(partialAnnotation);
    isInHitRegionTwo = false;

    // Passes if no errors are thrown
  });

  test('detects exit when mouse goes away', () {
    final ui.PointerDataPacket packet1 = ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.hover, const Offset(0.0, 0.0)),
      _pointerData(PointerChange.hover, const Offset(1.0, 101.0)),
    ]);
    final ui.PointerDataPacket packet2 = ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.remove, const Offset(1.0, 201.0)),
    ]);
    isInHitRegionOne = true;
    RendererBinding.instance.mouseTracker.attachAnnotation(annotation);
    ui.window.onPointerDataPacket(packet1);
    ui.window.onPointerDataPacket(packet2);
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerEnterEvent(position: Offset(0.0, 0.0)),
      const PointerHoverEvent(position: Offset(0.0, 0.0)),
      const PointerHoverEvent(position: Offset(1.0, 101.0)),
      const PointerHoverEvent(position: Offset(1.0, 201.0)),
      const PointerExitEvent(position: Offset(1.0, 201.0)),
    ]));
  });

  test('handles mouse down and move', () {
    final ui.PointerDataPacket packet1 = ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.hover, const Offset(0.0, 0.0)),
      _pointerData(PointerChange.hover, const Offset(1.0, 101.0)),
    ]);
    final ui.PointerDataPacket packet2 = ui.PointerDataPacket(data: <ui.PointerData>[
      _pointerData(PointerChange.down, const Offset(1.0, 101.0)),
      _pointerData(PointerChange.move, const Offset(1.0, 201.0)),
    ]);
    isInHitRegionOne = true;
    RendererBinding.instance.mouseTracker.attachAnnotation(annotation);
    ui.window.onPointerDataPacket(packet1);
    ui.window.onPointerDataPacket(packet2);
    expect(events, _equalToEventsOnCriticalFields(<PointerEvent>[
      const PointerEnterEvent(position: Offset(0.0, 0.0), delta: Offset(0.0, 0.0)),
      const PointerHoverEvent(position: Offset(0.0, 0.0), delta: Offset(0.0, 0.0)),
      const PointerHoverEvent(position: Offset(1.0, 101.0), delta: Offset(1.0, 101.0)),
    ]));
  });
}

ui.PointerData _pointerData(
  PointerChange change,
  Offset logicalPosition, {
  int device = 0,
}) {
  return ui.PointerData(
    change: change,
    physicalX: logicalPosition.dx * ui.window.devicePixelRatio,
    physicalY: logicalPosition.dy * ui.window.devicePixelRatio,
    kind: PointerDeviceKind.mouse,
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

    final PointerEvent actual = untypedItem;
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
        .add(' and doesn\'t match ')
        .addDescriptionOf(_expected.runtimeType);
    }
    return mismatchDescription
      .add('has ')
      .addDescriptionOf(matchState['actual'])
      .add(' at field `${matchState['field']}`, which doesn\'t match the expected ')
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
    final Iterable<PointerEvent> item = untypedItem;
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
        .add('\nat index ${matchState['index']}, which doesn\'t match\n  ')
        .addDescriptionOf(matchState['expected'])
        .add('\nsince it ');
      final Description subDescription = StringDescription();
      final Matcher matcher = matchState['matcher'];
      matcher.describeMismatch(matchState['actual'], subDescription,
        matchState['state'], verbose);
      mismatchDescription.add(subDescription.toString());
      return mismatchDescription;
    }
  }
}

Matcher _equalToEventsOnCriticalFields(List<PointerEvent> source) {
  return _EventListCriticalFieldsMatcher(source);
}
