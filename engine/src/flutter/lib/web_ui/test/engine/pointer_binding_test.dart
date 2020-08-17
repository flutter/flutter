// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;
import 'dart:js_util' as js_util;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

const int _kNoButtonChange = -1;
const PointerSupportDetector _defaultSupportDetector = PointerSupportDetector();

List<ui.PointerData> _allPointerData(List<ui.PointerDataPacket> packets) {
  return packets.expand((ui.PointerDataPacket packet) => packet.data).toList();
}

typedef _ContextTestBody<T> = void Function(T);

void _testEach<T extends _BasicEventContext>(
  Iterable<T> contexts,
  String description,
  _ContextTestBody<T> body,
) {
  for (T context in contexts) {
    if (context.isSupported) {
      test('${context.name} $description', () {
        body(context);
      });
    }
  }
}

/// Some methods in this class are skipped for iOS-Safari.
/// TODO: https://github.com/flutter/flutter/issues/60033
bool get isIosSafari => (browserEngine == BrowserEngine.webkit &&
    operatingSystem == OperatingSystem.iOs);

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  html.Element glassPane = domRenderer.glassPaneElement;

  setUp(() {
    // Touching domRenderer creates PointerBinding.instance.
    domRenderer;

    ui.window.onPointerDataPacket = null;
  });

  test('_PointerEventContext generates expected events', () {
    if (!_PointerEventContext().isSupported) {
      return;
    }

    html.PointerEvent expectCorrectType(html.Event e) {
      expect(e.runtimeType, equals(html.PointerEvent));
      return e;
    }

    List<html.PointerEvent> expectCorrectTypes(List<html.Event> events) {
      return events.map(expectCorrectType).toList();
    }

    final _PointerEventContext context = _PointerEventContext();
    html.PointerEvent event;
    List<html.PointerEvent> events;

    event = expectCorrectType(context.primaryDown(clientX: 100, clientY: 101));
    expect(event.type, equals('pointerdown'));
    expect(event.pointerId, equals(1));
    expect(event.button, equals(0));
    expect(event.buttons, equals(1));
    expect(event.client.x, equals(100));
    expect(event.client.y, equals(101));

    event = expectCorrectType(
        context.mouseDown(clientX: 110, clientY: 111, button: 2, buttons: 2));
    expect(event.type, equals('pointerdown'));
    expect(event.pointerId, equals(1));
    expect(event.button, equals(2));
    expect(event.buttons, equals(2));
    expect(event.client.x, equals(110));
    expect(event.client.y, equals(111));

    events = expectCorrectTypes(context.multiTouchDown(<_TouchDetails>[
      _TouchDetails(pointer: 100, clientX: 120, clientY: 121),
      _TouchDetails(pointer: 101, clientX: 122, clientY: 123),
    ]));
    expect(events.length, equals(2));
    expect(events[0].type, equals('pointerdown'));
    expect(events[0].pointerId, equals(100));
    expect(events[0].button, equals(0));
    expect(events[0].buttons, equals(1));
    expect(events[0].client.x, equals(120));
    expect(events[0].client.y, equals(121));
    expect(events[1].type, equals('pointerdown'));
    expect(events[1].pointerId, equals(101));
    expect(events[1].button, equals(0));
    expect(events[1].buttons, equals(1));
    expect(events[1].client.x, equals(122));
    expect(events[1].client.y, equals(123));

    event = expectCorrectType(context.primaryMove(clientX: 200, clientY: 201));
    expect(event.type, equals('pointermove'));
    expect(event.pointerId, equals(1));
    expect(event.button, equals(-1));
    expect(event.buttons, equals(1));
    expect(event.client.x, equals(200));
    expect(event.client.y, equals(201));

    event = expectCorrectType(context.mouseMove(
        clientX: 210, clientY: 211, button: _kNoButtonChange, buttons: 6));
    expect(event.type, equals('pointermove'));
    expect(event.pointerId, equals(1));
    expect(event.button, equals(-1));
    expect(event.buttons, equals(6));
    expect(event.client.x, equals(210));
    expect(event.client.y, equals(211));

    event = expectCorrectType(
        context.mouseMove(clientX: 212, clientY: 213, button: 2, buttons: 6));
    expect(event.type, equals('pointermove'));
    expect(event.pointerId, equals(1));
    expect(event.button, equals(2));
    expect(event.buttons, equals(6));
    expect(event.client.x, equals(212));
    expect(event.client.y, equals(213));

    event = expectCorrectType(
        context.mouseMove(clientX: 214, clientY: 215, button: 2, buttons: 1));
    expect(event.type, equals('pointermove'));
    expect(event.pointerId, equals(1));
    expect(event.button, equals(2));
    expect(event.buttons, equals(1));
    expect(event.client.x, equals(214));
    expect(event.client.y, equals(215));

    events = expectCorrectTypes(context.multiTouchMove(<_TouchDetails>[
      _TouchDetails(pointer: 102, clientX: 220, clientY: 221),
      _TouchDetails(pointer: 103, clientX: 222, clientY: 223),
    ]));
    expect(events.length, equals(2));
    expect(events[0].type, equals('pointermove'));
    expect(events[0].pointerId, equals(102));
    expect(events[0].button, equals(-1));
    expect(events[0].buttons, equals(1));
    expect(events[0].client.x, equals(220));
    expect(events[0].client.y, equals(221));
    expect(events[1].type, equals('pointermove'));
    expect(events[1].pointerId, equals(103));
    expect(events[1].button, equals(-1));
    expect(events[1].buttons, equals(1));
    expect(events[1].client.x, equals(222));
    expect(events[1].client.y, equals(223));

    event = expectCorrectType(context.primaryUp(clientX: 300, clientY: 301));
    expect(event.type, equals('pointerup'));
    expect(event.pointerId, equals(1));
    expect(event.button, equals(0));
    expect(event.buttons, equals(0));
    expect(event.client.x, equals(300));
    expect(event.client.y, equals(301));

    event = expectCorrectType(
        context.mouseUp(clientX: 310, clientY: 311, button: 2));
    expect(event.type, equals('pointerup'));
    expect(event.pointerId, equals(1));
    expect(event.button, equals(2));
    expect(event.buttons, equals(0));
    expect(event.client.x, equals(310));
    expect(event.client.y, equals(311));

    events = expectCorrectTypes(context.multiTouchUp(<_TouchDetails>[
      _TouchDetails(pointer: 104, clientX: 320, clientY: 321),
      _TouchDetails(pointer: 105, clientX: 322, clientY: 323),
    ]));
    expect(events.length, equals(2));
    expect(events[0].type, equals('pointerup'));
    expect(events[0].pointerId, equals(104));
    expect(events[0].button, equals(0));
    expect(events[0].buttons, equals(0));
    expect(events[0].client.x, equals(320));
    expect(events[0].client.y, equals(321));
    expect(events[1].type, equals('pointerup'));
    expect(events[1].pointerId, equals(105));
    expect(events[1].button, equals(0));
    expect(events[1].buttons, equals(0));
    expect(events[1].client.x, equals(322));
    expect(events[1].client.y, equals(323));

    event = expectCorrectType(context.hover(clientX: 400, clientY: 401));
    expect(event.type, equals('pointermove'));
    expect(event.pointerId, equals(1));
    expect(event.button, equals(-1));
    expect(event.buttons, equals(0));
    expect(event.client.x, equals(400));
    expect(event.client.y, equals(401));

    events = expectCorrectTypes(context.multiTouchCancel(<_TouchDetails>[
      _TouchDetails(pointer: 106, clientX: 500, clientY: 501),
      _TouchDetails(pointer: 107, clientX: 502, clientY: 503),
    ]));
    expect(events.length, equals(2));
    expect(events[0].type, equals('pointercancel'));
    expect(events[0].pointerId, equals(106));
    expect(events[0].button, equals(0));
    expect(events[0].buttons, equals(0));
    expect(events[0].client.x, equals(0));
    expect(events[0].client.y, equals(0));
    expect(events[1].type, equals('pointercancel'));
    expect(events[1].pointerId, equals(107));
    expect(events[1].button, equals(0));
    expect(events[1].buttons, equals(0));
    expect(events[1].client.x, equals(0));
    expect(events[1].client.y, equals(0));
  });

  test('_TouchEventContext generates expected events', () {
    if (!_TouchEventContext().isSupported) {
      return;
    }

    html.TouchEvent expectCorrectType(html.Event e) {
      expect(e.runtimeType, equals(html.TouchEvent));
      return e;
    }

    List<html.TouchEvent> expectCorrectTypes(List<html.Event> events) {
      return events.map(expectCorrectType).toList();
    }

    final _TouchEventContext context = _TouchEventContext();
    html.TouchEvent event;
    List<html.TouchEvent> events;

    event = expectCorrectType(context.primaryDown(clientX: 100, clientY: 101));
    expect(event.type, equals('touchstart'));
    expect(event.changedTouches.length, equals(1));
    expect(event.changedTouches[0].identifier, equals(1));
    expect(event.changedTouches[0].client.x, equals(100));
    expect(event.changedTouches[0].client.y, equals(101));

    events = expectCorrectTypes(context.multiTouchDown(<_TouchDetails>[
      _TouchDetails(pointer: 100, clientX: 120, clientY: 121),
      _TouchDetails(pointer: 101, clientX: 122, clientY: 123),
    ]));
    expect(events.length, equals(1));
    expect(events[0].type, equals('touchstart'));
    expect(events[0].changedTouches.length, equals(2));
    expect(events[0].changedTouches[0].identifier, equals(100));
    expect(events[0].changedTouches[0].client.x, equals(120));
    expect(events[0].changedTouches[0].client.y, equals(121));
    expect(events[0].changedTouches[1].identifier, equals(101));
    expect(events[0].changedTouches[1].client.x, equals(122));
    expect(events[0].changedTouches[1].client.y, equals(123));

    event = expectCorrectType(context.primaryMove(clientX: 200, clientY: 201));
    expect(event.type, equals('touchmove'));
    expect(event.changedTouches.length, equals(1));
    expect(event.changedTouches[0].identifier, equals(1));
    expect(event.changedTouches[0].client.x, equals(200));
    expect(event.changedTouches[0].client.y, equals(201));

    events = expectCorrectTypes(context.multiTouchMove(<_TouchDetails>[
      _TouchDetails(pointer: 102, clientX: 220, clientY: 221),
      _TouchDetails(pointer: 103, clientX: 222, clientY: 223),
    ]));
    expect(events.length, equals(1));
    expect(events[0].type, equals('touchmove'));
    expect(events[0].changedTouches.length, equals(2));
    expect(events[0].changedTouches[0].identifier, equals(102));
    expect(events[0].changedTouches[0].client.x, equals(220));
    expect(events[0].changedTouches[0].client.y, equals(221));
    expect(events[0].changedTouches[1].identifier, equals(103));
    expect(events[0].changedTouches[1].client.x, equals(222));
    expect(events[0].changedTouches[1].client.y, equals(223));

    event = expectCorrectType(context.primaryUp(clientX: 300, clientY: 301));
    expect(event.type, equals('touchend'));
    expect(event.changedTouches.length, equals(1));
    expect(event.changedTouches[0].identifier, equals(1));
    expect(event.changedTouches[0].client.x, equals(300));
    expect(event.changedTouches[0].client.y, equals(301));

    events = expectCorrectTypes(context.multiTouchUp(<_TouchDetails>[
      _TouchDetails(pointer: 104, clientX: 320, clientY: 321),
      _TouchDetails(pointer: 105, clientX: 322, clientY: 323),
    ]));
    expect(events.length, equals(1));
    expect(events[0].type, equals('touchend'));
    expect(events[0].changedTouches.length, equals(2));
    expect(events[0].changedTouches[0].identifier, equals(104));
    expect(events[0].changedTouches[0].client.x, equals(320));
    expect(events[0].changedTouches[0].client.y, equals(321));
    expect(events[0].changedTouches[1].identifier, equals(105));
    expect(events[0].changedTouches[1].client.x, equals(322));
    expect(events[0].changedTouches[1].client.y, equals(323));

    events = expectCorrectTypes(context.multiTouchCancel(<_TouchDetails>[
      _TouchDetails(pointer: 104, clientX: 320, clientY: 321),
      _TouchDetails(pointer: 105, clientX: 322, clientY: 323),
    ]));
    expect(events.length, equals(1));
    expect(events[0].type, equals('touchcancel'));
    expect(events[0].changedTouches.length, equals(2));
    expect(events[0].changedTouches[0].identifier, equals(104));
    expect(events[0].changedTouches[0].client.x, equals(320));
    expect(events[0].changedTouches[0].client.y, equals(321));
    expect(events[0].changedTouches[1].identifier, equals(105));
    expect(events[0].changedTouches[1].client.x, equals(322));
    expect(events[0].changedTouches[1].client.y, equals(323));
  });

  test('_MouseEventContext generates expected events', () {
    if (!_MouseEventContext().isSupported) {
      return;
    }

    html.MouseEvent expectCorrectType(html.Event e) {
      expect(e.runtimeType, equals(html.MouseEvent));
      return e;
    }

    final _MouseEventContext context = _MouseEventContext();
    html.MouseEvent event;

    event = expectCorrectType(context.primaryDown(clientX: 100, clientY: 101));
    expect(event.type, equals('mousedown'));
    expect(event.button, equals(0));
    expect(event.buttons, equals(1));
    expect(event.client.x, equals(100));
    expect(event.client.y, equals(101));

    event = expectCorrectType(
        context.mouseDown(clientX: 110, clientY: 111, button: 2, buttons: 2));
    expect(event.type, equals('mousedown'));
    expect(event.button, equals(2));
    expect(event.buttons, equals(2));
    expect(event.client.x, equals(110));
    expect(event.client.y, equals(111));

    event = expectCorrectType(context.primaryMove(clientX: 200, clientY: 201));
    expect(event.type, equals('mousemove'));
    expect(event.button, equals(0));
    expect(event.buttons, equals(1));
    expect(event.client.x, equals(200));
    expect(event.client.y, equals(201));

    event = expectCorrectType(context.mouseMove(
        clientX: 210, clientY: 211, button: _kNoButtonChange, buttons: 6));
    expect(event.type, equals('mousemove'));
    expect(event.button, equals(0));
    expect(event.buttons, equals(6));
    expect(event.client.x, equals(210));
    expect(event.client.y, equals(211));

    event = expectCorrectType(
        context.mouseMove(clientX: 212, clientY: 213, button: 2, buttons: 6));
    expect(event.type, equals('mousedown'));
    expect(event.button, equals(2));
    expect(event.buttons, equals(6));
    expect(event.client.x, equals(212));
    expect(event.client.y, equals(213));

    event = expectCorrectType(
        context.mouseMove(clientX: 214, clientY: 215, button: 2, buttons: 1));
    expect(event.type, equals('mouseup'));
    expect(event.button, equals(2));
    expect(event.buttons, equals(1));
    expect(event.client.x, equals(214));
    expect(event.client.y, equals(215));

    event = expectCorrectType(context.primaryUp(clientX: 300, clientY: 301));
    expect(event.type, equals('mouseup'));
    expect(event.button, equals(0));
    expect(event.buttons, equals(0));
    expect(event.client.x, equals(300));
    expect(event.client.y, equals(301));

    event = expectCorrectType(
        context.mouseUp(clientX: 310, clientY: 311, button: 2));
    expect(event.type, equals('mouseup'));
    expect(event.button, equals(2));
    expect(event.buttons, equals(0));
    expect(event.client.x, equals(310));
    expect(event.client.y, equals(311));

    event = expectCorrectType(context.hover(clientX: 400, clientY: 401));
    expect(event.type, equals('mousemove'));
    expect(event.button, equals(0));
    expect(event.buttons, equals(0));
    expect(event.client.x, equals(400));
    expect(event.client.y, equals(401));
  });

  // ALL ADAPTERS

  _testEach<_BasicEventContext>(
    [
      _PointerEventContext(),
      _MouseEventContext(),
      _TouchEventContext(),
    ],
    'can receive pointer events on the glass pane',
    (_BasicEventContext context) {
      PointerBinding.instance.debugOverrideDetector(context);
      ui.PointerDataPacket receivedPacket;
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        receivedPacket = packet;
      };

      glassPane.dispatchEvent(context.primaryDown());

      expect(receivedPacket, isNotNull);
      expect(receivedPacket.data[0].buttons, equals(1));
    },
  );

  _testEach<_BasicEventContext>(
    [
      _PointerEventContext(),
      _MouseEventContext(),
      _TouchEventContext(),
    ],
    'does create an add event if got a pointerdown',
    (_BasicEventContext context) {
      PointerBinding.instance.debugOverrideDetector(context);
      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      glassPane.dispatchEvent(context.primaryDown());

      expect(packets, hasLength(1));
      expect(packets.single.data, hasLength(2));

      expect(packets.single.data[0].change, equals(ui.PointerChange.add));
      expect(packets.single.data[1].change, equals(ui.PointerChange.down));
    },
  );

  _testEach<_ButtonedEventMixin>(
    [
      if (!isIosSafari) _PointerEventContext(),
      if (!isIosSafari) _MouseEventContext(),
    ],
    'correctly detects events on the semantics placeholder',
    (_ButtonedEventMixin context) {
      PointerBinding.instance.debugOverrideDetector(context);
      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      final html.Element semanticsPlaceholder =
          html.Element.tag('flt-semantics-placeholder');
      glassPane.append(semanticsPlaceholder);

      // Press on the semantics placeholder.
      semanticsPlaceholder.dispatchEvent(context.primaryDown(
        clientX: 10.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].physicalX, equals(10.0));
      expect(packets[0].data[1].physicalY, equals(10.0));
      packets.clear();

      // Drag on the semantics placeholder.
      semanticsPlaceholder.dispatchEvent(context.primaryMove(
        clientX: 12.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].physicalX, equals(12.0));
      expect(packets[0].data[0].physicalY, equals(10.0));
      packets.clear();

      // Keep dragging.
      semanticsPlaceholder.dispatchEvent(context.primaryMove(
        clientX: 15.0,
        clientY: 10.0,
      ));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].physicalX, equals(15.0));
      expect(packets[0].data[0].physicalY, equals(10.0));
      packets.clear();

      // Release the pointer on the semantics placeholder.
      html.window.dispatchEvent(context.primaryUp(
        clientX: 100.0,
        clientY: 200.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].physicalX, equals(100.0));
      expect(packets[0].data[0].physicalY, equals(200.0));
      expect(packets[0].data[1].change, equals(ui.PointerChange.up));
      expect(packets[0].data[1].physicalX, equals(100.0));
      expect(packets[0].data[1].physicalY, equals(200.0));
      packets.clear();

      semanticsPlaceholder.remove();
    },
  );

  // BUTTONED ADAPTERS

  _testEach<_ButtonedEventMixin>(
    [
      _PointerEventContext(),
      _MouseEventContext(),
    ],
    'creates an add event if the first pointer activity is a hover',
    (_ButtonedEventMixin context) {
      PointerBinding.instance.debugOverrideDetector(context);
      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      glassPane.dispatchEvent(context.hover());

      expect(packets, hasLength(1));
      expect(packets.single.data, hasLength(2));

      expect(packets.single.data[0].change, equals(ui.PointerChange.add));
      expect(packets.single.data[0].synthesized, equals(true));
      expect(packets.single.data[1].change, equals(ui.PointerChange.hover));
    },
  );

  _testEach<_ButtonedEventMixin>(
    [
      _PointerEventContext(),
      _MouseEventContext(),
    ],
    'sends a pointermove event instead of the second pointerdown in a row',
    (_ButtonedEventMixin context) {
      PointerBinding.instance.debugOverrideDetector(context);
      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      glassPane.dispatchEvent(context.primaryDown(
        clientX: 10.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      // An add will be synthesized.
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, equals(true));
      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      packets.clear();

      glassPane.dispatchEvent(context.primaryDown(
        clientX: 20.0,
        clientY: 20.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].buttons, equals(1));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    [
      if (!isIosSafari) _PointerEventContext(),
      if (!isIosSafari) _MouseEventContext(),
    ],
    'does synthesize add or hover or move for scroll',
    (_ButtonedEventMixin context) {
      PointerBinding.instance.debugOverrideDetector(context);
      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      glassPane.dispatchEvent(html.WheelEvent(
        'wheel',
        button: 1,
        clientX: 10,
        clientY: 10,
        deltaX: 10,
        deltaY: 10,
      ));

      glassPane.dispatchEvent(html.WheelEvent(
        'wheel',
        button: 1,
        clientX: 20,
        clientY: 50,
        deltaX: 10,
        deltaY: 10,
      ));

      glassPane.dispatchEvent(context.mouseDown(
        button: 0,
        buttons: 1,
        clientX: 20.0,
        clientY: 50.0,
      ));

      glassPane.dispatchEvent(html.WheelEvent(
        'wheel',
        button: 1,
        clientX: 30,
        clientY: 60,
        deltaX: 10,
        deltaY: 10,
      ));

      expect(packets, hasLength(4));

      // An add will be synthesized.
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].pointerIdentifier, equals(0));
      expect(packets[0].data[0].synthesized, equals(true));
      expect(packets[0].data[0].physicalX, equals(10.0));
      expect(packets[0].data[0].physicalY, equals(10.0));
      expect(packets[0].data[0].physicalDeltaX, equals(0.0));
      expect(packets[0].data[0].physicalDeltaY, equals(0.0));

      expect(packets[0].data[1].change, equals(ui.PointerChange.hover));
      expect(
          packets[0].data[1].signalKind, equals(ui.PointerSignalKind.scroll));
      expect(packets[0].data[1].pointerIdentifier, equals(0));
      expect(packets[0].data[1].synthesized, equals(false));
      expect(packets[0].data[1].physicalX, equals(10.0));
      expect(packets[0].data[1].physicalY, equals(10.0));
      expect(packets[0].data[1].physicalDeltaX, equals(0.0));
      expect(packets[0].data[1].physicalDeltaY, equals(0.0));

      // A hover will be synthesized.
      expect(packets[1].data, hasLength(2));
      expect(packets[1].data[0].change, equals(ui.PointerChange.hover));
      expect(packets[1].data[0].pointerIdentifier, equals(0));
      expect(packets[1].data[0].synthesized, equals(true));
      expect(packets[1].data[0].physicalX, equals(20.0));
      expect(packets[1].data[0].physicalY, equals(50.0));
      expect(packets[1].data[0].physicalDeltaX, equals(10.0));
      expect(packets[1].data[0].physicalDeltaY, equals(40.0));

      expect(packets[1].data[1].change, equals(ui.PointerChange.hover));
      expect(
          packets[1].data[1].signalKind, equals(ui.PointerSignalKind.scroll));
      expect(packets[1].data[1].pointerIdentifier, equals(0));
      expect(packets[1].data[1].synthesized, equals(false));
      expect(packets[1].data[1].physicalX, equals(20.0));
      expect(packets[1].data[1].physicalY, equals(50.0));
      expect(packets[1].data[1].physicalDeltaX, equals(0.0));
      expect(packets[1].data[1].physicalDeltaY, equals(0.0));

      // No synthetic pointer data for down event.
      expect(packets[2].data, hasLength(1));
      expect(packets[2].data[0].change, equals(ui.PointerChange.down));
      expect(packets[2].data[0].signalKind, equals(ui.PointerSignalKind.none));
      expect(packets[2].data[0].pointerIdentifier, equals(1));
      expect(packets[2].data[0].synthesized, equals(false));
      expect(packets[2].data[0].physicalX, equals(20.0));
      expect(packets[2].data[0].physicalY, equals(50.0));
      expect(packets[2].data[0].physicalDeltaX, equals(0.0));
      expect(packets[2].data[0].physicalDeltaY, equals(0.0));

      // A move will be synthesized instead of hover because the button is currently down.
      expect(packets[3].data, hasLength(2));
      expect(packets[3].data[0].change, equals(ui.PointerChange.move));
      expect(packets[3].data[0].pointerIdentifier, equals(1));
      expect(packets[3].data[0].synthesized, equals(true));
      expect(packets[3].data[0].physicalX, equals(30.0));
      expect(packets[3].data[0].physicalY, equals(60.0));
      expect(packets[3].data[0].physicalDeltaX, equals(10.0));
      expect(packets[3].data[0].physicalDeltaY, equals(10.0));

      expect(packets[3].data[1].change, equals(ui.PointerChange.hover));
      expect(
          packets[3].data[1].signalKind, equals(ui.PointerSignalKind.scroll));
      expect(packets[3].data[1].pointerIdentifier, equals(1));
      expect(packets[3].data[1].synthesized, equals(false));
      expect(packets[3].data[1].physicalX, equals(30.0));
      expect(packets[3].data[1].physicalY, equals(60.0));
      expect(packets[3].data[1].physicalDeltaX, equals(0.0));
      expect(packets[3].data[1].physicalDeltaY, equals(0.0));
    },
  );

  _testEach<_ButtonedEventMixin>(
    [
      if (!isIosSafari) _PointerEventContext(),
      if (!isIosSafari) _MouseEventContext()
    ],
    'does calculate delta and pointer identifier correctly',
    (_ButtonedEventMixin context) {
      PointerBinding.instance.debugOverrideDetector(context);
      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      glassPane.dispatchEvent(context.hover(
        clientX: 10.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].pointerIdentifier, equals(0));
      expect(packets[0].data[0].synthesized, equals(true));
      expect(packets[0].data[0].physicalX, equals(10.0));
      expect(packets[0].data[0].physicalY, equals(10.0));
      expect(packets[0].data[0].physicalDeltaX, equals(0.0));
      expect(packets[0].data[0].physicalDeltaY, equals(0.0));

      expect(packets[0].data[1].change, equals(ui.PointerChange.hover));
      expect(packets[0].data[1].pointerIdentifier, equals(0));
      expect(packets[0].data[1].synthesized, equals(false));
      expect(packets[0].data[1].physicalX, equals(10.0));
      expect(packets[0].data[1].physicalY, equals(10.0));
      expect(packets[0].data[1].physicalDeltaX, equals(0.0));
      expect(packets[0].data[1].physicalDeltaY, equals(0.0));
      packets.clear();

      glassPane.dispatchEvent(context.hover(
        clientX: 20.0,
        clientY: 20.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.hover));
      expect(packets[0].data[0].pointerIdentifier, equals(0));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].physicalX, equals(20.0));
      expect(packets[0].data[0].physicalY, equals(20.0));
      expect(packets[0].data[0].physicalDeltaX, equals(10.0));
      expect(packets[0].data[0].physicalDeltaY, equals(10.0));
      packets.clear();

      glassPane.dispatchEvent(context.primaryDown(
        clientX: 20.0,
        clientY: 20.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.down));
      expect(packets[0].data[0].pointerIdentifier, equals(1));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].physicalX, equals(20.0));
      expect(packets[0].data[0].physicalY, equals(20.0));
      expect(packets[0].data[0].physicalDeltaX, equals(0.0));
      expect(packets[0].data[0].physicalDeltaY, equals(0.0));
      packets.clear();

      glassPane.dispatchEvent(context.primaryMove(
        clientX: 40.0,
        clientY: 30.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].pointerIdentifier, equals(1));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].physicalX, equals(40.0));
      expect(packets[0].data[0].physicalY, equals(30.0));
      expect(packets[0].data[0].physicalDeltaX, equals(20.0));
      expect(packets[0].data[0].physicalDeltaY, equals(10.0));
      packets.clear();

      glassPane.dispatchEvent(context.primaryUp(
        clientX: 40.0,
        clientY: 30.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].pointerIdentifier, equals(1));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].physicalX, equals(40.0));
      expect(packets[0].data[0].physicalY, equals(30.0));
      expect(packets[0].data[0].physicalDeltaX, equals(0.0));
      expect(packets[0].data[0].physicalDeltaY, equals(0.0));
      packets.clear();

      glassPane.dispatchEvent(context.hover(
        clientX: 20.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.hover));
      expect(packets[0].data[0].pointerIdentifier, equals(1));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].physicalX, equals(20.0));
      expect(packets[0].data[0].physicalY, equals(10.0));
      expect(packets[0].data[0].physicalDeltaX, equals(-20.0));
      expect(packets[0].data[0].physicalDeltaY, equals(-20.0));
      packets.clear();

      glassPane.dispatchEvent(context.primaryDown(
        clientX: 20.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.down));
      expect(packets[0].data[0].pointerIdentifier, equals(2));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].physicalX, equals(20.0));
      expect(packets[0].data[0].physicalY, equals(10.0));
      expect(packets[0].data[0].physicalDeltaX, equals(0.0));
      expect(packets[0].data[0].physicalDeltaY, equals(0.0));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    [
      if (!isIosSafari) _PointerEventContext(),
      if (!isIosSafari) _MouseEventContext(),
    ],
    'correctly converts buttons of down, move and up events',
    (_ButtonedEventMixin context) {
      PointerBinding.instance.debugOverrideDetector(context);
      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Add and hover

      glassPane.dispatchEvent(context.hover(
        clientX: 10,
        clientY: 11,
      ));

      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, equals(true));
      expect(packets[0].data[0].physicalX, equals(10));
      expect(packets[0].data[0].physicalY, equals(11));

      expect(packets[0].data[1].change, equals(ui.PointerChange.hover));
      expect(packets[0].data[1].synthesized, equals(false));
      expect(packets[0].data[1].physicalX, equals(10));
      expect(packets[0].data[1].physicalY, equals(11));
      expect(packets[0].data[1].buttons, equals(0));
      packets.clear();

      glassPane.dispatchEvent(context.mouseDown(
        button: 0,
        buttons: 1,
        clientX: 10.0,
        clientY: 11.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.down));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].physicalX, equals(10));
      expect(packets[0].data[0].physicalY, equals(11));
      expect(packets[0].data[0].buttons, equals(1));
      packets.clear();

      glassPane.dispatchEvent(context.mouseMove(
        button: _kNoButtonChange,
        buttons: 1,
        clientX: 20.0,
        clientY: 21.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].physicalX, equals(20));
      expect(packets[0].data[0].physicalY, equals(21));
      expect(packets[0].data[0].buttons, equals(1));
      packets.clear();

      glassPane.dispatchEvent(context.mouseUp(
        button: 0,
        clientX: 20.0,
        clientY: 21.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].physicalX, equals(20));
      expect(packets[0].data[0].physicalY, equals(21));
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();

      // Drag with secondary button
      glassPane.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 2,
        clientX: 20.0,
        clientY: 21.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.down));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].physicalX, equals(20));
      expect(packets[0].data[0].physicalY, equals(21));
      expect(packets[0].data[0].buttons, equals(2));
      packets.clear();

      glassPane.dispatchEvent(context.mouseMove(
        button: _kNoButtonChange,
        buttons: 2,
        clientX: 30.0,
        clientY: 31.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].physicalX, equals(30));
      expect(packets[0].data[0].physicalY, equals(31));
      expect(packets[0].data[0].buttons, equals(2));
      packets.clear();

      glassPane.dispatchEvent(context.mouseUp(
        button: 2,
        clientX: 30.0,
        clientY: 31.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].physicalX, equals(30));
      expect(packets[0].data[0].physicalY, equals(31));
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();

      // Drag with middle button
      glassPane.dispatchEvent(context.mouseDown(
        button: 1,
        buttons: 4,
        clientX: 30.0,
        clientY: 31.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.down));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].physicalX, equals(30));
      expect(packets[0].data[0].physicalY, equals(31));
      expect(packets[0].data[0].buttons, equals(4));
      packets.clear();

      glassPane.dispatchEvent(context.mouseMove(
        button: _kNoButtonChange,
        buttons: 4,
        clientX: 40.0,
        clientY: 41.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].physicalX, equals(40));
      expect(packets[0].data[0].physicalY, equals(41));
      expect(packets[0].data[0].buttons, equals(4));
      packets.clear();

      glassPane.dispatchEvent(context.mouseUp(
        button: 1,
        clientX: 40.0,
        clientY: 41.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].physicalX, equals(40));
      expect(packets[0].data[0].physicalY, equals(41));
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    [
      _PointerEventContext(),
      _MouseEventContext(),
    ],
    'correctly handles button changes during a down sequence',
    (_ButtonedEventMixin context) {
      PointerBinding.instance.debugOverrideDetector(context);
      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Press LMB.
      glassPane.dispatchEvent(context.mouseDown(
        button: 0,
        buttons: 1,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, equals(true));

      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].synthesized, equals(false));
      expect(packets[0].data[1].buttons, equals(1));
      packets.clear();

      // Press MMB.
      glassPane.dispatchEvent(context.mouseMove(
        button: 1,
        buttons: 5,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].buttons, equals(5));
      packets.clear();

      // Release LMB.
      glassPane.dispatchEvent(context.mouseMove(
        button: 0,
        buttons: 4,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].buttons, equals(4));
      packets.clear();

      // Release MMB.
      glassPane.dispatchEvent(context.mouseUp(
        button: 1,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    [
      if (!isIosSafari) _PointerEventContext(),
      if (!isIosSafari) _MouseEventContext(),
    ],
    'synthesizes a pointerup event when pointermove comes before the up',
    (_ButtonedEventMixin context) {
      PointerBinding.instance.debugOverrideDetector(context);
      // This can happen when the user pops up the context menu by right
      // clicking, then dismisses it with a left click.

      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      glassPane.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 2,
        clientX: 10,
        clientY: 11,
      ));

      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, equals(true));
      expect(packets[0].data[0].physicalX, equals(10));
      expect(packets[0].data[0].physicalY, equals(11));

      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].synthesized, equals(false));
      expect(packets[0].data[1].physicalX, equals(10));
      expect(packets[0].data[1].physicalY, equals(11));
      expect(packets[0].data[1].buttons, equals(2));
      packets.clear();

      glassPane.dispatchEvent(context.mouseMove(
        button: _kNoButtonChange,
        buttons: 2,
        clientX: 20.0,
        clientY: 21.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].physicalX, equals(20));
      expect(packets[0].data[0].physicalY, equals(21));
      expect(packets[0].data[0].buttons, equals(2));
      packets.clear();

      glassPane.dispatchEvent(context.mouseMove(
        button: _kNoButtonChange,
        buttons: 2,
        clientX: 20.0,
        clientY: 21.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].physicalX, equals(20));
      expect(packets[0].data[0].physicalY, equals(21));
      expect(packets[0].data[0].buttons, equals(2));
      packets.clear();

      glassPane.dispatchEvent(context.mouseUp(
        button: 2,
        clientX: 20.0,
        clientY: 21.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].physicalX, equals(20));
      expect(packets[0].data[0].physicalY, equals(21));
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    [
      _PointerEventContext(),
      _MouseEventContext(),
    ],
    'correctly handles uncontinuous button changes during a down sequence',
    (_ButtonedEventMixin context) {
      PointerBinding.instance.debugOverrideDetector(context);
      // This can happen with the following gesture sequence:
      //
      //  - Pops up the context menu by right clicking, but holds RMB;
      //  - Clicks LMB;
      //  - Releases RMB.

      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Press RMB and hold, popping up the context menu.
      glassPane.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 2,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, equals(true));

      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].synthesized, equals(false));
      expect(packets[0].data[1].buttons, equals(2));
      packets.clear();

      // Press LMB. The event will have "button: -1" here, despite the change
      // in "buttons", probably because the "press" gesture was absorbed by
      // dismissing the context menu.
      glassPane.dispatchEvent(context.mouseMove(
        button: _kNoButtonChange,
        buttons: 3,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].buttons, equals(3));
      packets.clear();

      // Release LMB.
      glassPane.dispatchEvent(context.mouseMove(
        button: 0,
        buttons: 2,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].buttons, equals(2));
      packets.clear();

      // Release RMB.
      glassPane.dispatchEvent(context.mouseUp(
        button: 2,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    [
      _PointerEventContext(),
      _MouseEventContext(),
    ],
    'handles RMB click when the browser sends it as a move',
    (_ButtonedEventMixin context) {
      PointerBinding.instance.debugOverrideDetector(context);
      // When the user clicks the RMB and moves the mouse quickly (before the
      // context menu shows up), the browser sends a move event before down.
      // The move event will have "button:-1, buttons:2".

      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Press RMB and hold, popping up the context menu.
      glassPane.dispatchEvent(context.mouseMove(
        button: -1,
        buttons: 2,
        clientX: 10.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, equals(true));

      expect(packets[0].data[1].change, equals(ui.PointerChange.hover));
      expect(packets[0].data[1].synthesized, equals(false));
      expect(packets[0].data[1].buttons, equals(0));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    [
      _PointerEventContext(),
      _MouseEventContext(),
    ],
    'correctly handles hover after RMB click',
    (_ButtonedEventMixin context) {
      PointerBinding.instance.debugOverrideDetector(context);
      // This can happen with the following gesture sequence:
      //
      //  - Pops up the context menu by right clicking, but holds RMB;
      //  - Move the pointer to hover.

      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Press RMB and hold, popping up the context menu.
      glassPane.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 2,
        clientX: 10.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, equals(true));

      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].synthesized, equals(false));
      expect(packets[0].data[1].buttons, equals(2));
      packets.clear();

      // Move the mouse. The event will have "buttons: 0" because RMB was
      // released but the browser didn't send a pointerup/mouseup event.
      // The hover is also triggered at a different position.
      glassPane.dispatchEvent(context.hover(
        clientX: 20.0,
        clientY: 20.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].buttons, equals(2));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    [
      _PointerEventContext(),
      _MouseEventContext(),
    ],
    'correctly handles LMB click after RMB click',
    (_ButtonedEventMixin context) {
      PointerBinding.instance.debugOverrideDetector(context);
      // This can happen with the following gesture sequence:
      //
      //  - Pops up the context menu by right clicking, but holds RMB;
      //  - Clicks LMB in a different location;
      //  - Release LMB.
      //
      // The LMB click occurs in a different location because when RMB is
      // clicked, and the contextmenu is shown, the browser stops sending
      // `pointermove`/`mousemove` events. Then when the LMB click comes in, it
      // could be in a different location without any `*move` events in between.

      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Press RMB and hold, popping up the context menu.
      glassPane.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 2,
        clientX: 10.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, equals(true));

      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].synthesized, equals(false));
      expect(packets[0].data[1].buttons, equals(2));
      packets.clear();

      // Press LMB.
      glassPane.dispatchEvent(context.mouseDown(
        button: 0,
        buttons: 3,
        clientX: 20.0,
        clientY: 20.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].buttons, equals(3));
      packets.clear();

      // Release LMB.
      glassPane.dispatchEvent(context.primaryUp(
        clientX: 20.0,
        clientY: 20.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    [
      _PointerEventContext(),
      _MouseEventContext(),
    ],
    'correctly handles two consecutive RMB clicks with no up in between',
    (_ButtonedEventMixin context) {
      PointerBinding.instance.debugOverrideDetector(context);
      // This can happen with the following gesture sequence:
      //
      //  - Pops up the context menu by right clicking, but holds RMB;
      //  - Clicks RMB again in a different location;

      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Press RMB and hold, popping up the context menu.
      glassPane.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 2,
        clientX: 10.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, equals(true));
      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].synthesized, equals(false));
      expect(packets[0].data[1].buttons, equals(2));
      packets.clear();

      // Press RMB again. In Chrome, when RMB is clicked again while the
      // context menu is still active, it sends a pointerdown/mousedown event
      // with "buttons:0".
      glassPane.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 0,
        clientX: 20.0,
        clientY: 20.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].buttons, equals(2));
      packets.clear();

      // Release RMB.
      glassPane.dispatchEvent(context.mouseUp(
        button: 2,
        clientX: 20.0,
        clientY: 20.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    [
      _PointerEventContext(),
      _MouseEventContext(),
    ],
    'correctly handles two consecutive RMB clicks with up in between',
    (_ButtonedEventMixin context) {
      PointerBinding.instance.debugOverrideDetector(context);
      // This can happen with the following gesture sequence:
      //
      //  - Pops up the context menu by right clicking, but doesn't hold RMB;
      //  - Clicks RMB again in a different location;
      //
      // This seems to be happening sometimes when using RMB on the Mac trackpad.

      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Press RMB, popping up the context menu.
      glassPane.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 2,
        clientX: 10.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, equals(true));
      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].synthesized, equals(false));
      expect(packets[0].data[1].buttons, equals(2));
      packets.clear();

      // RMB up.
      glassPane.dispatchEvent(context.mouseUp(
        button: 2,
        clientX: 10.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();

      // Press RMB again. In Chrome, when RMB is clicked again while the
      // context menu is still active, it sends a pointerdown/mousedown event
      // with "buttons:0".
      glassPane.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 0,
        clientX: 20.0,
        clientY: 20.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.hover));
      expect(packets[0].data[0].synthesized, equals(true));
      expect(packets[0].data[0].buttons, equals(0));
      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].synthesized, equals(false));
      expect(packets[0].data[1].buttons, equals(2));
      packets.clear();

      // Release RMB.
      glassPane.dispatchEvent(context.mouseUp(
        button: 2,
        clientX: 20.0,
        clientY: 20.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    [
      _PointerEventContext(),
      _MouseEventContext(),
    ],
    'correctly handles two consecutive RMB clicks in two different locations',
    (_ButtonedEventMixin context) {
      PointerBinding.instance.debugOverrideDetector(context);
      // This can happen with the following gesture sequence:
      //
      //  - Pops up the context menu by right clicking;
      //  - The browser sends RMB up event;
      //  - Click RMB again in a different location;
      //
      // This scenario happens occasionally. I'm still not sure why, but in some
      // cases, the browser actually sends an `up` event for the RMB click even
      // when the context menu is shown.

      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Press RMB and hold, popping up the context menu.
      glassPane.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 2,
        clientX: 10.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, equals(true));
      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].synthesized, equals(false));
      expect(packets[0].data[1].buttons, equals(2));
      packets.clear();

      // Release RMB.
      glassPane.dispatchEvent(context.mouseUp(
        button: 2,
        clientX: 10.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();

      // Press RMB again, in a different location.
      glassPane.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 2,
        clientX: 20.0,
        clientY: 20.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.hover));
      expect(packets[0].data[0].synthesized, equals(true));
      expect(packets[0].data[0].buttons, equals(0));
      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].synthesized, equals(false));
      expect(packets[0].data[1].buttons, equals(2));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    [
      if (!isIosSafari) _PointerEventContext(),
      if (!isIosSafari) _MouseEventContext(),
    ],
    'correctly detects up event outside of glasspane',
    (_ButtonedEventMixin context) {
      PointerBinding.instance.debugOverrideDetector(context);
      // This can happen when the up event occurs while the mouse is outside the
      // browser window.

      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Press and drag around.
      glassPane.dispatchEvent(context.primaryDown(
        clientX: 10.0,
        clientY: 10.0,
      ));
      glassPane.dispatchEvent(context.primaryMove(
        clientX: 12.0,
        clientY: 10.0,
      ));
      glassPane.dispatchEvent(context.primaryMove(
        clientX: 15.0,
        clientY: 10.0,
      ));
      glassPane.dispatchEvent(context.primaryMove(
        clientX: 20.0,
        clientY: 10.0,
      ));
      packets.clear();

      // Move outside the glasspane.
      html.window.dispatchEvent(context.primaryMove(
        clientX: 900.0,
        clientY: 1900.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].physicalX, equals(900.0));
      expect(packets[0].data[0].physicalY, equals(1900.0));
      packets.clear();

      // Release outside the glasspane.
      html.window.dispatchEvent(context.primaryUp(
        clientX: 1000.0,
        clientY: 2000.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].physicalX, equals(1000.0));
      expect(packets[0].data[0].physicalY, equals(2000.0));
      expect(packets[0].data[1].change, equals(ui.PointerChange.up));
      expect(packets[0].data[1].physicalX, equals(1000.0));
      expect(packets[0].data[1].physicalY, equals(2000.0));
      packets.clear();
    },
  );

  // MULTIPOINTER ADAPTERS

  _testEach<_MultiPointerEventMixin>(
    [
      if (!isIosSafari) _PointerEventContext(),
      if (!isIosSafari) _TouchEventContext(),
    ],
    'treats each pointer separately',
    (_MultiPointerEventMixin context) {
      PointerBinding.instance.debugOverrideDetector(context);
      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      List<ui.PointerData> data;
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Two pointers down
      context.multiTouchDown(<_TouchDetails>[
        _TouchDetails(pointer: 2, clientX: 100, clientY: 101),
        _TouchDetails(pointer: 3, clientX: 200, clientY: 201),
      ]).forEach(glassPane.dispatchEvent);
      if (context.runtimeType == _PointerEventContext) {
        expect(packets.length, 2);
        expect(packets[0].data.length, 2);
        expect(packets[1].data.length, 2);
      } else if (context.runtimeType == _TouchEventContext) {
        expect(packets.length, 1);
        expect(packets[0].data.length, 4);
      } else {
        assert(false, 'Unexpected context type ${context.runtimeType}');
      }

      data = _allPointerData(packets);
      expect(data, hasLength(4));
      expect(data[0].change, equals(ui.PointerChange.add));
      expect(data[0].synthesized, equals(true));
      expect(data[0].device, equals(2));
      expect(data[0].physicalX, equals(100));
      expect(data[0].physicalY, equals(101));

      expect(data[1].change, equals(ui.PointerChange.down));
      expect(data[1].device, equals(2));
      expect(data[1].buttons, equals(1));
      expect(data[1].physicalX, equals(100));
      expect(data[1].physicalY, equals(101));
      expect(data[1].physicalDeltaX, equals(0));
      expect(data[1].physicalDeltaY, equals(0));

      expect(data[2].change, equals(ui.PointerChange.add));
      expect(data[2].synthesized, equals(true));
      expect(data[2].device, equals(3));
      expect(data[2].physicalX, equals(200));
      expect(data[2].physicalY, equals(201));

      expect(data[3].change, equals(ui.PointerChange.down));
      expect(data[3].device, equals(3));
      expect(data[3].buttons, equals(1));
      expect(data[3].physicalX, equals(200));
      expect(data[3].physicalY, equals(201));
      expect(data[3].physicalDeltaX, equals(0));
      expect(data[3].physicalDeltaY, equals(0));
      packets.clear();

      // Two pointers move
      context.multiTouchMove(<_TouchDetails>[
        _TouchDetails(pointer: 3, clientX: 300, clientY: 302),
        _TouchDetails(pointer: 2, clientX: 400, clientY: 402),
      ]).forEach(glassPane.dispatchEvent);
      if (context.runtimeType == _PointerEventContext) {
        expect(packets.length, 2);
        expect(packets[0].data.length, 1);
        expect(packets[1].data.length, 1);
      } else if (context.runtimeType == _TouchEventContext) {
        expect(packets.length, 1);
        expect(packets[0].data.length, 2);
      } else {
        assert(false, 'Unexpected context type ${context.runtimeType}');
      }

      data = _allPointerData(packets);
      expect(data, hasLength(2));
      expect(data[0].change, equals(ui.PointerChange.move));
      expect(data[0].device, equals(3));
      expect(data[0].buttons, equals(1));
      expect(data[0].physicalX, equals(300));
      expect(data[0].physicalY, equals(302));
      expect(data[0].physicalDeltaX, equals(100));
      expect(data[0].physicalDeltaY, equals(101));

      expect(data[1].change, equals(ui.PointerChange.move));
      expect(data[1].device, equals(2));
      expect(data[1].buttons, equals(1));
      expect(data[1].physicalX, equals(400));
      expect(data[1].physicalY, equals(402));
      expect(data[1].physicalDeltaX, equals(300));
      expect(data[1].physicalDeltaY, equals(301));
      packets.clear();

      // One pointer up
      context.multiTouchUp(<_TouchDetails>[
        _TouchDetails(pointer: 3, clientX: 300, clientY: 302),
      ]).forEach(glassPane.dispatchEvent);
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].device, equals(3));
      expect(packets[0].data[0].buttons, equals(0));
      expect(packets[0].data[0].physicalX, equals(300));
      expect(packets[0].data[0].physicalY, equals(302));
      expect(packets[0].data[0].physicalDeltaX, equals(0));
      expect(packets[0].data[0].physicalDeltaY, equals(0));

      expect(packets[0].data[1].change, equals(ui.PointerChange.remove));
      expect(packets[0].data[1].device, equals(3));
      expect(packets[0].data[1].buttons, equals(0));
      expect(packets[0].data[1].physicalX, equals(300));
      expect(packets[0].data[1].physicalY, equals(302));
      expect(packets[0].data[1].physicalDeltaX, equals(0));
      expect(packets[0].data[1].physicalDeltaY, equals(0));
      packets.clear();

      // Another pointer up
      context.multiTouchUp(<_TouchDetails>[
        _TouchDetails(pointer: 2, clientX: 400, clientY: 402),
      ]).forEach(glassPane.dispatchEvent);
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].device, equals(2));
      expect(packets[0].data[0].buttons, equals(0));
      expect(packets[0].data[0].physicalX, equals(400));
      expect(packets[0].data[0].physicalY, equals(402));
      expect(packets[0].data[0].physicalDeltaX, equals(0));
      expect(packets[0].data[0].physicalDeltaY, equals(0));

      expect(packets[0].data[1].change, equals(ui.PointerChange.remove));
      expect(packets[0].data[1].device, equals(2));
      expect(packets[0].data[1].buttons, equals(0));
      expect(packets[0].data[1].physicalX, equals(400));
      expect(packets[0].data[1].physicalY, equals(402));
      expect(packets[0].data[1].physicalDeltaX, equals(0));
      expect(packets[0].data[1].physicalDeltaY, equals(0));
      packets.clear();

      // Again two pointers down (reuse pointer ID)
      context.multiTouchDown(<_TouchDetails>[
        _TouchDetails(pointer: 3, clientX: 500, clientY: 501),
        _TouchDetails(pointer: 2, clientX: 600, clientY: 601),
      ]).forEach(glassPane.dispatchEvent);
      if (context.runtimeType == _PointerEventContext) {
        expect(packets.length, 2);
        expect(packets[0].data.length, 2);
        expect(packets[1].data.length, 2);
      } else if (context.runtimeType == _TouchEventContext) {
        expect(packets.length, 1);
        expect(packets[0].data.length, 4);
      } else {
        assert(false, 'Unexpected context type ${context.runtimeType}');
      }

      data = _allPointerData(packets);
      expect(data, hasLength(4));
      expect(data[0].change, equals(ui.PointerChange.add));
      expect(data[0].synthesized, equals(true));
      expect(data[0].device, equals(3));
      expect(data[0].physicalX, equals(500));
      expect(data[0].physicalY, equals(501));

      expect(data[1].change, equals(ui.PointerChange.down));
      expect(data[1].device, equals(3));
      expect(data[1].buttons, equals(1));
      expect(data[1].physicalX, equals(500));
      expect(data[1].physicalY, equals(501));
      expect(data[1].physicalDeltaX, equals(0));
      expect(data[1].physicalDeltaY, equals(0));

      expect(data[2].change, equals(ui.PointerChange.add));
      expect(data[2].synthesized, equals(true));
      expect(data[2].device, equals(2));
      expect(data[2].physicalX, equals(600));
      expect(data[2].physicalY, equals(601));

      expect(data[3].change, equals(ui.PointerChange.down));
      expect(data[3].device, equals(2));
      expect(data[3].buttons, equals(1));
      expect(data[3].physicalX, equals(600));
      expect(data[3].physicalY, equals(601));
      expect(data[3].physicalDeltaX, equals(0));
      expect(data[3].physicalDeltaY, equals(0));
      packets.clear();
    },
  );

  _testEach<_MultiPointerEventMixin>(
    [
      if (!isIosSafari) _PointerEventContext(),
      if (!isIosSafari) _TouchEventContext(),
    ],
    'correctly parses cancel event',
    (_MultiPointerEventMixin context) {
      PointerBinding.instance.debugOverrideDetector(context);
      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Two pointers down
      context.multiTouchDown(<_TouchDetails>[
        _TouchDetails(pointer: 2, clientX: 100, clientY: 101),
        _TouchDetails(pointer: 3, clientX: 200, clientY: 201),
      ]).forEach(glassPane.dispatchEvent);
      packets.clear(); // Down event is tested in other tests.

      // One pointer cancel
      context.multiTouchCancel(<_TouchDetails>[
        _TouchDetails(pointer: 3, clientX: 300, clientY: 302),
      ]).forEach(glassPane.dispatchEvent);
      expect(packets.length, 1);
      expect(packets[0].data.length, 2);
      expect(packets[0].data[0].change, equals(ui.PointerChange.cancel));
      expect(packets[0].data[0].device, equals(3));
      expect(packets[0].data[0].buttons, equals(0));
      expect(packets[0].data[0].physicalX, equals(200));
      expect(packets[0].data[0].physicalY, equals(201));
      expect(packets[0].data[0].physicalDeltaX, equals(0));
      expect(packets[0].data[0].physicalDeltaY, equals(0));

      expect(packets[0].data[1].change, equals(ui.PointerChange.remove));
      expect(packets[0].data[1].device, equals(3));
      expect(packets[0].data[1].buttons, equals(0));
      expect(packets[0].data[1].physicalX, equals(200));
      expect(packets[0].data[1].physicalY, equals(201));
      expect(packets[0].data[1].physicalDeltaX, equals(0));
      expect(packets[0].data[1].physicalDeltaY, equals(0));
      packets.clear();
    },
  );

  // POINTER ADAPTER

  _testEach<_PointerEventContext>(
    [
      if (!isIosSafari) _PointerEventContext(),
    ],
    'does not synthesize pointer up if from different device',
    (_PointerEventContext context) {
      PointerBinding.instance.debugOverrideDetector(context);
      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      context.multiTouchDown(<_TouchDetails>[
        _TouchDetails(pointer: 1, clientX: 100, clientY: 101),
      ]).forEach(glassPane.dispatchEvent);
      expect(packets, hasLength(1));
      // An add will be synthesized.
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, equals(true));
      expect(packets[0].data[0].device, equals(1));
      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].device, equals(1));
      packets.clear();

      context.multiTouchDown(<_TouchDetails>[
        _TouchDetails(pointer: 2, clientX: 200, clientY: 202),
      ]).forEach(glassPane.dispatchEvent);
      // An add will be synthesized.
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, equals(true));
      expect(packets[0].data[0].device, equals(2));
      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].device, equals(2));
      packets.clear();
    },
  );

  // TOUCH ADAPTER

  _testEach(
    [
      if (!isIosSafari) _TouchEventContext(),
    ],
    'does calculate delta and pointer identifier correctly',
    (_TouchEventContext context) {
      // Mouse and Pointer are in another test since these tests can involve hovering
      PointerBinding.instance.debugOverrideDetector(context);
      List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      context.multiTouchDown(<_TouchDetails>[
        _TouchDetails(pointer: 1, clientX: 20, clientY: 20),
      ]).forEach(glassPane.dispatchEvent);
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].pointerIdentifier, equals(1));
      expect(packets[0].data[0].synthesized, equals(true));
      expect(packets[0].data[0].physicalX, equals(20.0));
      expect(packets[0].data[0].physicalY, equals(20.0));
      expect(packets[0].data[0].physicalDeltaX, equals(0.0));
      expect(packets[0].data[0].physicalDeltaY, equals(0.0));

      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].pointerIdentifier, equals(1));
      expect(packets[0].data[1].synthesized, equals(false));
      expect(packets[0].data[1].physicalX, equals(20.0));
      expect(packets[0].data[1].physicalY, equals(20.0));
      expect(packets[0].data[1].physicalDeltaX, equals(0.0));
      expect(packets[0].data[1].physicalDeltaY, equals(0.0));
      packets.clear();

      context.multiTouchMove(<_TouchDetails>[
        _TouchDetails(pointer: 1, clientX: 40, clientY: 30),
      ]).forEach(glassPane.dispatchEvent);
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].pointerIdentifier, equals(1));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].physicalX, equals(40.0));
      expect(packets[0].data[0].physicalY, equals(30.0));
      expect(packets[0].data[0].physicalDeltaX, equals(20.0));
      expect(packets[0].data[0].physicalDeltaY, equals(10.0));
      packets.clear();

      context.multiTouchUp(<_TouchDetails>[
        _TouchDetails(pointer: 1, clientX: 40, clientY: 30),
      ]).forEach(glassPane.dispatchEvent);
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].pointerIdentifier, equals(1));
      expect(packets[0].data[0].synthesized, equals(false));
      expect(packets[0].data[0].physicalX, equals(40.0));
      expect(packets[0].data[0].physicalY, equals(30.0));
      expect(packets[0].data[0].physicalDeltaX, equals(0.0));
      expect(packets[0].data[0].physicalDeltaY, equals(0.0));

      expect(packets[0].data[1].change, equals(ui.PointerChange.remove));
      expect(packets[0].data[1].pointerIdentifier, equals(1));
      expect(packets[0].data[1].synthesized, equals(true));
      expect(packets[0].data[1].physicalX, equals(40.0));
      expect(packets[0].data[1].physicalY, equals(30.0));
      expect(packets[0].data[1].physicalDeltaX, equals(0.0));
      expect(packets[0].data[1].physicalDeltaY, equals(0.0));
      packets.clear();

      context.multiTouchDown(<_TouchDetails>[
        _TouchDetails(pointer: 2, clientX: 20, clientY: 10),
      ]).forEach(glassPane.dispatchEvent);
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].pointerIdentifier, equals(2));
      expect(packets[0].data[0].synthesized, equals(true));
      expect(packets[0].data[0].physicalX, equals(20.0));
      expect(packets[0].data[0].physicalY, equals(10.0));
      expect(packets[0].data[0].physicalDeltaX, equals(0.0));
      expect(packets[0].data[0].physicalDeltaY, equals(0.0));

      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].pointerIdentifier, equals(2));
      expect(packets[0].data[1].synthesized, equals(false));
      expect(packets[0].data[1].physicalX, equals(20.0));
      expect(packets[0].data[1].physicalY, equals(10.0));
      expect(packets[0].data[1].physicalDeltaX, equals(0.0));
      expect(packets[0].data[1].physicalDeltaY, equals(0.0));
      packets.clear();
    },
  );
}

abstract class _BasicEventContext implements PointerSupportDetector {
  String get name;

  bool get isSupported;

  // Generate an event that is:
  //
  //  * For mouse, a left click
  //  * For touch, a touch down
  html.Event primaryDown({double clientX, double clientY});

  // Generate an event that is:
  //
  //  * For mouse, a drag with LMB down
  //  * For touch, a touch drag
  html.Event primaryMove({double clientX, double clientY});

  // Generate an event that is:
  //
  //  * For mouse, release LMB
  //  * For touch, a touch up
  html.Event primaryUp({double clientX, double clientY});
}

mixin _ButtonedEventMixin on _BasicEventContext {
  // Generate an event that is a mouse down with the specific buttons.
  html.Event mouseDown(
      {double clientX, double clientY, int button, int buttons});

  // Generate an event that is a mouse drag with the specific buttons, or button
  // changes during the drag.
  //
  // If there is no button change, assign `button` with _kNoButtonChange.
  html.Event mouseMove(
      {double clientX, double clientY, int button, int buttons});

  // Generate an event that releases all mouse buttons.
  html.Event mouseUp({double clientX, double clientY, int button});

  html.Event hover({double clientX, double clientY}) {
    return mouseMove(
      buttons: 0,
      button: _kNoButtonChange,
      clientX: clientX,
      clientY: clientY,
    );
  }

  @override
  html.Event primaryDown({double clientX, double clientY}) {
    return mouseDown(
      buttons: 1,
      button: 0,
      clientX: clientX,
      clientY: clientY,
    );
  }

  @override
  html.Event primaryMove({double clientX, double clientY}) {
    return mouseMove(
      buttons: 1,
      button: _kNoButtonChange,
      clientX: clientX,
      clientY: clientY,
    );
  }

  @override
  html.Event primaryUp({double clientX, double clientY}) {
    return mouseUp(
      button: 0,
      clientX: clientX,
      clientY: clientY,
    );
  }
}

class _TouchDetails {
  const _TouchDetails({this.pointer, this.clientX, this.clientY});

  final int pointer;
  final double clientX;
  final double clientY;
}

mixin _MultiPointerEventMixin on _BasicEventContext {
  List<html.Event> multiTouchDown(List<_TouchDetails> touches);
  List<html.Event> multiTouchMove(List<_TouchDetails> touches);
  List<html.Event> multiTouchUp(List<_TouchDetails> touches);
  List<html.Event> multiTouchCancel(List<_TouchDetails> touches);

  @override
  html.Event primaryDown({double clientX, double clientY}) {
    return multiTouchDown(<_TouchDetails>[
      _TouchDetails(
        pointer: 1,
        clientX: clientX,
        clientY: clientY,
      ),
    ])[0];
  }

  @override
  html.Event primaryMove({double clientX, double clientY}) {
    return multiTouchMove(<_TouchDetails>[
      _TouchDetails(
        pointer: 1,
        clientX: clientX,
        clientY: clientY,
      ),
    ])[0];
  }

  @override
  html.Event primaryUp({double clientX, double clientY}) {
    return multiTouchUp(<_TouchDetails>[
      _TouchDetails(
        pointer: 1,
        clientX: clientX,
        clientY: clientY,
      ),
    ])[0];
  }
}

// A test context for `_TouchAdapter`, including its name, PointerSupportDetector
// to override, and how to generate events.
class _TouchEventContext extends _BasicEventContext
    with _MultiPointerEventMixin
    implements PointerSupportDetector {
  _TouchEventContext() {
    _target = html.document.createElement('div');
  }

  @override
  String get name => 'TouchAdapter';

  @override
  bool get isSupported => _defaultSupportDetector.hasTouchEvents;

  @override
  bool get hasPointerEvents => false;

  @override
  bool get hasTouchEvents => true;

  @override
  bool get hasMouseEvents => false;

  html.EventTarget _target;

  html.Touch _createTouch({
    int identifier,
    double clientX,
    double clientY,
  }) {
    return html.Touch(<String, dynamic>{
      'identifier': identifier,
      'clientX': clientX,
      'clientY': clientY,
      'target': _target,
    });
  }

  html.TouchEvent _createTouchEvent(
      String eventType, List<_TouchDetails> touches) {
    return html.TouchEvent(
      eventType,
      <String, dynamic>{
        'changedTouches': touches
            .map(
              (_TouchDetails details) => _createTouch(
                identifier: details.pointer,
                clientX: details.clientX,
                clientY: details.clientY,
              ),
            )
            .toList(),
      },
    );
  }

  @override
  List<html.Event> multiTouchDown(List<_TouchDetails> touches) {
    return <html.Event>[_createTouchEvent('touchstart', touches)];
  }

  @override
  List<html.Event> multiTouchMove(List<_TouchDetails> touches) {
    return <html.Event>[_createTouchEvent('touchmove', touches)];
  }

  @override
  List<html.Event> multiTouchUp(List<_TouchDetails> touches) {
    return <html.Event>[_createTouchEvent('touchend', touches)];
  }

  @override
  List<html.Event> multiTouchCancel(List<_TouchDetails> touches) {
    return <html.Event>[_createTouchEvent('touchcancel', touches)];
  }
}

// A test context for `_MouseAdapter`, including its name, PointerSupportDetector
// to override, and how to generate events.
//
// For the difference between MouseEvent and PointerEvent, see _MouseAdapter.
class _MouseEventContext extends _BasicEventContext
    with _ButtonedEventMixin
    implements PointerSupportDetector {
  @override
  String get name => 'MouseAdapter';

  @override
  bool get isSupported => _defaultSupportDetector.hasMouseEvents;

  @override
  bool get hasPointerEvents => false;

  @override
  bool get hasTouchEvents => false;

  @override
  bool get hasMouseEvents => true;

  @override
  html.Event mouseDown(
      {double clientX, double clientY, int button, int buttons}) {
    return _createMouseEvent(
      'mousedown',
      buttons: buttons,
      button: button,
      clientX: clientX,
      clientY: clientY,
    );
  }

  @override
  html.Event mouseMove(
      {double clientX, double clientY, int button, int buttons}) {
    final bool hasButtonChange = button != _kNoButtonChange;
    final bool changeIsButtonDown =
        hasButtonChange && (buttons & convertButtonToButtons(button)) != 0;
    final String adjustedType = !hasButtonChange
        ? 'mousemove'
        : changeIsButtonDown ? 'mousedown' : 'mouseup';
    final int adjustedButton = hasButtonChange ? button : 0;
    return _createMouseEvent(
      adjustedType,
      buttons: buttons,
      button: adjustedButton,
      clientX: clientX,
      clientY: clientY,
    );
  }

  @override
  html.Event mouseUp({double clientX, double clientY, int button}) {
    return _createMouseEvent(
      'mouseup',
      buttons: 0,
      button: button,
      clientX: clientX,
      clientY: clientY,
    );
  }

  html.MouseEvent _createMouseEvent(
    String type, {
    int buttons,
    int button,
    double clientX,
    double clientY,
  }) {
    final Function jsMouseEvent =
        js_util.getProperty(html.window, 'MouseEvent');
    final List<dynamic> eventArgs = <dynamic>[
      type,
      <String, dynamic>{
        'buttons': buttons,
        'button': button,
        'clientX': clientX,
        'clientY': clientY,
      }
    ];
    return js_util.callConstructor(jsMouseEvent, js_util.jsify(eventArgs));
  }
}

// A test context for `_PointerAdapter`, including its name, PointerSupportDetector
// to override, and how to generate events.
//
// For the difference between MouseEvent and PointerEvent, see _MouseAdapter.
class _PointerEventContext extends _BasicEventContext
    with _ButtonedEventMixin
    implements PointerSupportDetector, _MultiPointerEventMixin {
  @override
  String get name => 'PointerAdapter';

  @override
  bool get isSupported => _defaultSupportDetector.hasPointerEvents;

  @override
  bool get hasPointerEvents => true;

  @override
  bool get hasTouchEvents => false;

  @override
  bool get hasMouseEvents => false;

  @override
  List<html.Event> multiTouchDown(List<_TouchDetails> touches) {
    return touches
        .map((_TouchDetails details) => _downWithFullDetails(
              pointer: details.pointer,
              buttons: 1,
              button: 0,
              clientX: details.clientX,
              clientY: details.clientY,
              pointerType: 'touch',
            ))
        .toList();
  }

  @override
  html.Event mouseDown(
      {double clientX, double clientY, int button, int buttons}) {
    return _downWithFullDetails(
      pointer: 1,
      buttons: buttons,
      button: button,
      clientX: clientX,
      clientY: clientY,
      pointerType: 'mouse',
    );
  }

  html.Event _downWithFullDetails(
      {double clientX,
      double clientY,
      int button,
      int buttons,
      int pointer,
      String pointerType}) {
    return html.PointerEvent('pointerdown', <String, dynamic>{
      'pointerId': pointer,
      'button': button,
      'buttons': buttons,
      'clientX': clientX,
      'clientY': clientY,
      'pointerType': pointerType,
    });
  }

  @override
  List<html.Event> multiTouchMove(List<_TouchDetails> touches) {
    return touches
        .map((_TouchDetails details) => _moveWithFullDetails(
              pointer: details.pointer,
              buttons: 1,
              button: _kNoButtonChange,
              clientX: details.clientX,
              clientY: details.clientY,
              pointerType: 'touch',
            ))
        .toList();
  }

  @override
  html.Event mouseMove(
      {double clientX, double clientY, int button, int buttons}) {
    return _moveWithFullDetails(
      pointer: 1,
      buttons: buttons,
      button: button,
      clientX: clientX,
      clientY: clientY,
      pointerType: 'mouse',
    );
  }

  html.Event _moveWithFullDetails(
      {double clientX,
      double clientY,
      int button,
      int buttons,
      int pointer,
      String pointerType}) {
    return html.PointerEvent('pointermove', <String, dynamic>{
      'pointerId': pointer,
      'button': button,
      'buttons': buttons,
      'clientX': clientX,
      'clientY': clientY,
      'pointerType': pointerType,
    });
  }

  @override
  List<html.Event> multiTouchUp(List<_TouchDetails> touches) {
    return touches
        .map((_TouchDetails details) => _upWithFullDetails(
              pointer: details.pointer,
              button: 0,
              clientX: details.clientX,
              clientY: details.clientY,
              pointerType: 'touch',
            ))
        .toList();
  }

  @override
  html.Event mouseUp({double clientX, double clientY, int button}) {
    return _upWithFullDetails(
      pointer: 1,
      button: button,
      clientX: clientX,
      clientY: clientY,
      pointerType: 'mouse',
    );
  }

  html.Event _upWithFullDetails(
      {double clientX,
      double clientY,
      int button,
      int pointer,
      String pointerType}) {
    return html.PointerEvent('pointerup', <String, dynamic>{
      'pointerId': pointer,
      'button': button,
      'buttons': 0,
      'clientX': clientX,
      'clientY': clientY,
      'pointerType': pointerType,
    });
  }

  @override
  List<html.Event> multiTouchCancel(List<_TouchDetails> touches) {
    return touches
        .map((_TouchDetails details) =>
            html.PointerEvent('pointercancel', <String, dynamic>{
              'pointerId': details.pointer,
              'button': 0,
              'buttons': 0,
              'clientX': 0,
              'clientY': 0,
              'pointerType': 'touch',
            }))
        .toList();
  }
}
