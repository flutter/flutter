// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_util' as js_util;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'keyboard_converter_test.dart';

const int _kNoButtonChange = -1;
const PointerSupportDetector _defaultSupportDetector = PointerSupportDetector();

List<ui.PointerData> _allPointerData(List<ui.PointerDataPacket> packets) {
  return packets.expand((ui.PointerDataPacket packet) => packet.data).toList();
}

typedef _ContextTestBody<T> = void Function(T);

void _testEach<T extends _BasicEventContext>(
  Iterable<T> contexts,
  String description,
  _ContextTestBody<T> body, {
    Object? skip,
  }
) {
  for (final T context in contexts) {
    if (context.isSupported) {
      test('${context.name} $description', () {
        body(context);
      }, skip: skip);
    }
  }
}

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  ensureFlutterViewEmbedderInitialized();
  final DomElement rootElement =
      EnginePlatformDispatcher.instance.implicitView!.dom.rootElement;
  late double dpi;

  setUp(() {
    ui.window.onPointerDataPacket = null;
    dpi = window.devicePixelRatio;
  });

  KeyboardConverter createKeyboardConverter(List<ui.KeyData> keyDataList) {
    return KeyboardConverter((ui.KeyData key) {
      keyDataList.add(key);
      return true;
    }, OperatingSystem.linux);
  }

  test('ios workaround', () {
    debugEmulateIosSafari = true;
    addTearDown(() {
      debugEmulateIosSafari = false;
    });

    final MockSafariPointerEventWorkaround mockSafariPointer =
        MockSafariPointerEventWorkaround();
    SafariPointerEventWorkaround.instance = mockSafariPointer;
    final List<ui.KeyData> keyDataList = <ui.KeyData>[];
    final KeyboardConverter keyboardConverter = createKeyboardConverter(keyDataList);
    final PointerBinding instance = PointerBinding(createDomHTMLDivElement(), keyboardConverter);
    expect(mockSafariPointer.workAroundInvoked, isIosSafari);
    instance.dispose();
  }, skip: !isSafari);

  test('_PointerEventContext generates expected events', () {
    if (!_PointerEventContext().isSupported) {
      return;
    }

    DomPointerEvent expectCorrectType(DomEvent e) {
      expect(domInstanceOfString(e, 'PointerEvent'), isTrue);
      return e as DomPointerEvent;
    }

    List<DomPointerEvent> expectCorrectTypes(List<DomEvent> events) {
      return events.map(expectCorrectType).toList();
    }

    final _PointerEventContext context = _PointerEventContext();
    DomPointerEvent event;
    List<DomPointerEvent> events;

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

    events = expectCorrectTypes(context.multiTouchDown(const <_TouchDetails>[
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

    events = expectCorrectTypes(context.multiTouchMove(const <_TouchDetails>[
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

    event = expectCorrectType(context.mouseLeave(clientX: 1000, clientY: 2000, buttons: 6));
    expect(event.type, equals('pointerleave'));
    expect(event.pointerId, equals(1));
    expect(event.button, equals(0));
    expect(event.buttons, equals(6));
    expect(event.client.x, equals(1000));
    expect(event.client.y, equals(2000));

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

    events = expectCorrectTypes(context.multiTouchUp(const <_TouchDetails>[
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

    events = expectCorrectTypes(context.multiTouchCancel(const <_TouchDetails>[
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

    context.pressAllModifiers();
    event = expectCorrectType(context.primaryDown(clientX: 100, clientY: 101));
    expect(event.getModifierState('Alt'), true);
    expect(event.getModifierState('Control'), true);
    expect(event.getModifierState('Meta'), true);
    expect(event.getModifierState('Shift'), true);
    context.unpressAllModifiers();
    event = expectCorrectType(context.primaryDown(clientX: 100, clientY: 101));
    expect(event.getModifierState('Alt'), false);
    expect(event.getModifierState('Control'), false);
    expect(event.getModifierState('Meta'), false);
    expect(event.getModifierState('Shift'), false);
  });

  test('_TouchEventContext generates expected events', () {
    if (!_TouchEventContext().isSupported) {
      return;
    }

    DomTouchEvent expectCorrectType(DomEvent e) {
      expect(domInstanceOfString(e, 'TouchEvent'), isTrue);
      return e as DomTouchEvent;
    }

    List<DomTouchEvent> expectCorrectTypes(List<DomEvent> events) {
      return events.map(expectCorrectType).toList();
    }

    final _TouchEventContext context = _TouchEventContext();
    DomTouchEvent event;
    List<DomTouchEvent> events;

    event = expectCorrectType(context.primaryDown(clientX: 100, clientY: 101));
    expect(event.type, equals('touchstart'));
    expect(event.changedTouches.length, equals(1));
    expect(event.changedTouches.first.identifier, equals(1));
    expect(event.changedTouches.first.client.x, equals(100));
    expect(event.changedTouches.first.client.y, equals(101));

    events = expectCorrectTypes(context.multiTouchDown(const <_TouchDetails>[
      _TouchDetails(pointer: 100, clientX: 120, clientY: 121),
      _TouchDetails(pointer: 101, clientX: 122, clientY: 123),
    ]));
    expect(events.length, equals(1));
    expect(events[0].type, equals('touchstart'));
    expect(events[0].changedTouches.length, equals(2));
    expect(events[0].changedTouches.first.identifier, equals(100));
    expect(events[0].changedTouches.first.client.x, equals(120));
    expect(events[0].changedTouches.first.client.y, equals(121));
    expect(events[0].changedTouches.elementAt(1).identifier, equals(101));
    expect(events[0].changedTouches.elementAt(1).client.x, equals(122));
    expect(events[0].changedTouches.elementAt(1).client.y, equals(123));

    event = expectCorrectType(context.primaryMove(clientX: 200, clientY: 201));
    expect(event.type, equals('touchmove'));
    expect(event.changedTouches.length, equals(1));
    expect(event.changedTouches.first.identifier, equals(1));
    expect(event.changedTouches.first.client.x, equals(200));
    expect(event.changedTouches.first.client.y, equals(201));

    events = expectCorrectTypes(context.multiTouchMove(const <_TouchDetails>[
      _TouchDetails(pointer: 102, clientX: 220, clientY: 221),
      _TouchDetails(pointer: 103, clientX: 222, clientY: 223),
    ]));
    expect(events.length, equals(1));
    expect(events[0].type, equals('touchmove'));
    expect(events[0].changedTouches.length, equals(2));
    expect(events[0].changedTouches.first.identifier, equals(102));
    expect(events[0].changedTouches.first.client.x, equals(220));
    expect(events[0].changedTouches.first.client.y, equals(221));
    expect(events[0].changedTouches.elementAt(1).identifier, equals(103));
    expect(events[0].changedTouches.elementAt(1).client.x, equals(222));
    expect(events[0].changedTouches.elementAt(1).client.y, equals(223));

    event = expectCorrectType(context.primaryUp(clientX: 300, clientY: 301));
    expect(event.type, equals('touchend'));
    expect(event.changedTouches.length, equals(1));
    expect(event.changedTouches.first.identifier, equals(1));
    expect(event.changedTouches.first.client.x, equals(300));
    expect(event.changedTouches.first.client.y, equals(301));

    events = expectCorrectTypes(context.multiTouchUp(const <_TouchDetails>[
      _TouchDetails(pointer: 104, clientX: 320, clientY: 321),
      _TouchDetails(pointer: 105, clientX: 322, clientY: 323),
    ]));
    expect(events.length, equals(1));
    expect(events[0].type, equals('touchend'));
    expect(events[0].changedTouches.length, equals(2));
    expect(events[0].changedTouches.first.identifier, equals(104));
    expect(events[0].changedTouches.first.client.x, equals(320));
    expect(events[0].changedTouches.first.client.y, equals(321));
    expect(events[0].changedTouches.elementAt(1).identifier, equals(105));
    expect(events[0].changedTouches.elementAt(1).client.x, equals(322));
    expect(events[0].changedTouches.elementAt(1).client.y, equals(323));

    events = expectCorrectTypes(context.multiTouchCancel(const <_TouchDetails>[
      _TouchDetails(pointer: 104, clientX: 320, clientY: 321),
      _TouchDetails(pointer: 105, clientX: 322, clientY: 323),
    ]));
    expect(events.length, equals(1));
    expect(events[0].type, equals('touchcancel'));
    expect(events[0].changedTouches.length, equals(2));
    expect(events[0].changedTouches.first.identifier, equals(104));
    expect(events[0].changedTouches.first.client.x, equals(320));
    expect(events[0].changedTouches.first.client.y, equals(321));
    expect(events[0].changedTouches.elementAt(1).identifier, equals(105));
    expect(events[0].changedTouches.elementAt(1).client.x, equals(322));
    expect(events[0].changedTouches.elementAt(1).client.y, equals(323));

    context.pressAllModifiers();
    event = expectCorrectType(context.primaryDown(clientX: 100, clientY: 101));
    expect(event.altKey, true);
    expect(event.ctrlKey, true);
    expect(event.metaKey, true);
    expect(event.shiftKey, true);
    context.unpressAllModifiers();
    event = expectCorrectType(context.primaryDown(clientX: 100, clientY: 101));
    expect(event.altKey, false);
    expect(event.ctrlKey, false);
    expect(event.metaKey, false);
    expect(event.shiftKey, false);
  });

  test('_MouseEventContext generates expected events', () {
    if (!_MouseEventContext().isSupported) {
      return;
    }

    DomMouseEvent expectCorrectType(DomEvent e) {
      expect(domInstanceOfString(e, 'MouseEvent'), isTrue);
      return e as DomMouseEvent;
    }

    final _MouseEventContext context = _MouseEventContext();
    DomMouseEvent event;

    event = expectCorrectType(context.primaryDown(clientX: 100, clientY: 101));
    expect(event.type, equals('mousedown'));
    expect(event.button, equals(0));
    expect(event.buttons, equals(1));
    expect(event.client.x, equals(100));
    expect(event.client.y, equals(101));
    expect(event.offset.x, equals(100));
    expect(event.offset.y, equals(101));

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

    event = expectCorrectType(context.mouseLeave(clientX: 1000, clientY: 2000, buttons: 6));
    expect(event.type, equals('mouseleave'));
    expect(event.button, equals(0));
    expect(event.buttons, equals(6));
    expect(event.client.x, equals(1000));
    expect(event.client.y, equals(2000));

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

    context.pressAllModifiers();
    event = expectCorrectType(context.primaryDown(clientX: 100, clientY: 101));
    expect(event.getModifierState('Alt'), true);
    expect(event.getModifierState('Control'), true);
    expect(event.getModifierState('Meta'), true);
    expect(event.getModifierState('Shift'), true);
    context.unpressAllModifiers();
    event = expectCorrectType(context.primaryDown(clientX: 100, clientY: 101));
    expect(event.getModifierState('Alt'), false);
    expect(event.getModifierState('Control'), false);
    expect(event.getModifierState('Meta'), false);
    expect(event.getModifierState('Shift'), false);
  });

  // ALL ADAPTERS

  // The reason we listen for pointer events in the bubble phase instead of the
  // capture phase is to allow platform views and native text fields to receive
  // the event first. This way, they can potentially handle the event and stop
  // its propagation to prevent Flutter from receiving and handling it.
  _testEach(
    <_BasicEventContext>[
      _PointerEventContext(),
      _MouseEventContext(),
      _TouchEventContext(),
    ],
    'event listeners are attached to the bubble phase',
    (_BasicEventContext context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      final DomElement child = createDomHTMLDivElement();
      rootElement.append(child);

      final DomEventListener stopPropagationListener = createDomEventListener((DomEvent event) {
        event.stopPropagation();
      });

      // The event reaches `PointerBinding` as expected.
      child.dispatchEvent(context.primaryDown());
      expect(packets, isNotEmpty);
      packets.clear();

      // The child stops propagation so the event doesn't reach `PointerBinding`.
      final DomEvent event = context.primaryDown();
      child.addEventListener(event.type, stopPropagationListener);
      child.dispatchEvent(event);
      expect(packets, isEmpty);
      packets.clear();

      child.remove();
    },
  );

  _testEach<_BasicEventContext>(
    <_BasicEventContext>[
      _PointerEventContext(),
      _MouseEventContext(),
      _TouchEventContext(),
    ],
    'can receive pointer events on the app root',
    (_BasicEventContext context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      ui.PointerDataPacket? receivedPacket;
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        receivedPacket = packet;
      };

      rootElement.dispatchEvent(context.primaryDown());

      expect(receivedPacket, isNotNull);
      expect(receivedPacket!.data[0].buttons, equals(1));
    },
  );

  _testEach<_BasicEventContext>(
    <_BasicEventContext>[
      _PointerEventContext(),
      _MouseEventContext(),
      _TouchEventContext(),
    ],
    'does create an add event if got a pointerdown',
    (_BasicEventContext context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      rootElement.dispatchEvent(context.primaryDown());

      expect(packets, hasLength(1));
      expect(packets.single.data, hasLength(2));

      expect(packets.single.data[0].change, equals(ui.PointerChange.add));
      expect(packets.single.data[1].change, equals(ui.PointerChange.down));
    },
  );

  _testEach<_BasicEventContext>(
    <_BasicEventContext>[
      _PointerEventContext(),
      _MouseEventContext(),
      _TouchEventContext(),
    ],
    'synthesize modifier keys left down event if left or right are not pressed',
    (_BasicEventContext context) {
      PointerBinding.instance!.debugOverrideDetector(context);

      // Should synthesize a modifier left key down event when DOM event indicates
      // that the modifier key is pressed and known pressing state doesn't contain
      // the modifier left key nor the modifier right key.
      void shouldSynthesizeLeftDownIfNotPressed(String key) {
        final int physicalLeft = kWebToPhysicalKey['${key}Left']!;
        final int physicalRight = kWebToPhysicalKey['${key}Right']!;
        final int logicalLeft = kWebLogicalLocationMap[key]![kLocationLeft]!;

        final List<ui.KeyData> keyDataList = <ui.KeyData>[];
        final KeyboardConverter keyboardConverter = createKeyboardConverter(keyDataList);
        PointerBinding.instance!.debugOverrideKeyboardConverter(keyboardConverter);

        expect(keyboardConverter.keyIsPressed(physicalLeft), false);
        expect(keyboardConverter.keyIsPressed(physicalRight), false);
        rootElement.dispatchEvent(context.primaryDown());
        expect(keyDataList.length, 1);
        expectKeyData(keyDataList.last,
          type: ui.KeyEventType.down,
          deviceType: ui.KeyEventDeviceType.keyboard,
          physical: physicalLeft,
          logical: logicalLeft,
          character: null,
          synthesized: true,
        );
      }

      context.altPressed = true;
      shouldSynthesizeLeftDownIfNotPressed('Alt');
      context.unpressAllModifiers();
      context.ctrlPressed = true;
      shouldSynthesizeLeftDownIfNotPressed('Control');
      context.unpressAllModifiers();
      context.metaPressed = true;
      shouldSynthesizeLeftDownIfNotPressed('Meta');
      context.unpressAllModifiers();
      context.shiftPressed = true;
      shouldSynthesizeLeftDownIfNotPressed('Shift');
      context.unpressAllModifiers();
    },
  );

  _testEach<_BasicEventContext>(
    <_BasicEventContext>[
      _PointerEventContext(),
      _MouseEventContext(),
      _TouchEventContext(),
    ],
    'should not synthesize modifier keys down event if left or right are pressed',
    (_BasicEventContext context) {
      PointerBinding.instance!.debugOverrideDetector(context);

      // Should not synthesize a modifier down event when DOM event indicates
      // that the modifier key is pressed and known pressing state contains
      // the modifier left key.
      void shouldNotSynthesizeDownIfLeftPressed(String key, int modifiers) {
        final int physicalLeft = kWebToPhysicalKey['${key}Left']!;
        final int physicalRight = kWebToPhysicalKey['${key}Right']!;

        final List<ui.KeyData> keyDataList = <ui.KeyData>[];
        final KeyboardConverter keyboardConverter = createKeyboardConverter(keyDataList);
        PointerBinding.instance!.debugOverrideKeyboardConverter(keyboardConverter);

        keyboardConverter.handleEvent(keyDownEvent('${key}Left', key, modifiers, kLocationLeft));
        expect(keyboardConverter.keyIsPressed(physicalLeft), true);
        expect(keyboardConverter.keyIsPressed(physicalRight), false);
        keyDataList.clear(); // Remove key data generated by handleEvent

        rootElement.dispatchEvent(context.primaryDown());
        expect(keyDataList.length, 0);
      }

      // Should not synthesize a modifier down event when DOM event indicates
      // that the modifier key is pressed and known pressing state contains
      // the modifier right key.
      void shouldNotSynthesizeDownIfRightPressed(String key, int modifiers) {
        final int physicalLeft = kWebToPhysicalKey['${key}Left']!;
        final int physicalRight = kWebToPhysicalKey['${key}Right']!;

        final List<ui.KeyData> keyDataList = <ui.KeyData>[];
        final KeyboardConverter keyboardConverter = createKeyboardConverter(keyDataList);
        PointerBinding.instance!.debugOverrideKeyboardConverter(keyboardConverter);

        keyboardConverter.handleEvent(keyDownEvent('${key}Right', key, modifiers, kLocationRight));
        expect(keyboardConverter.keyIsPressed(physicalLeft), false);
        expect(keyboardConverter.keyIsPressed(physicalRight), true);
        keyDataList.clear(); // Remove key data generated by handleEvent

        rootElement.dispatchEvent(context.primaryDown());
        expect(keyDataList.length, 0);
      }

      context.altPressed = true;
      shouldNotSynthesizeDownIfLeftPressed('Alt', kAlt);
      shouldNotSynthesizeDownIfRightPressed('Alt', kAlt);
      context.unpressAllModifiers();
      context.ctrlPressed = true;
      shouldNotSynthesizeDownIfLeftPressed('Control', kCtrl);
      shouldNotSynthesizeDownIfRightPressed('Control', kCtrl);
      context.unpressAllModifiers();
      context.metaPressed = true;
      shouldNotSynthesizeDownIfLeftPressed('Meta', kMeta);
      shouldNotSynthesizeDownIfRightPressed('Meta', kMeta);
      context.unpressAllModifiers();
      context.shiftPressed = true;
      shouldNotSynthesizeDownIfLeftPressed('Shift', kShift);
      shouldNotSynthesizeDownIfRightPressed('Shift', kShift);
      context.unpressAllModifiers();
    },
  );

  _testEach<_BasicEventContext>(
    <_BasicEventContext>[
      _PointerEventContext(),
      _MouseEventContext(),
      _TouchEventContext(),
    ],
    'synthesize modifier keys up event if left or right are pressed',
    (_BasicEventContext context) {
      PointerBinding.instance!.debugOverrideDetector(context);

      // Should synthesize a modifier left key up event when DOM event indicates
      // that the modifier key is not pressed and known pressing state contains
      // the modifier left key.
      void shouldSynthesizeLeftUpIfLeftPressed(String key, int modifiers) {
        final int physicalLeft = kWebToPhysicalKey['${key}Left']!;
        final int physicalRight = kWebToPhysicalKey['${key}Right']!;
        final int logicalLeft = kWebLogicalLocationMap[key]![kLocationLeft]!;

        final List<ui.KeyData> keyDataList = <ui.KeyData>[];
        final KeyboardConverter keyboardConverter = createKeyboardConverter(keyDataList);
        PointerBinding.instance!.debugOverrideKeyboardConverter(keyboardConverter);

        keyboardConverter.handleEvent(keyDownEvent('${key}Left', key, modifiers, kLocationLeft));
        expect(keyboardConverter.keyIsPressed(physicalLeft), true);
        expect(keyboardConverter.keyIsPressed(physicalRight), false);
        keyDataList.clear(); // Remove key data generated by handleEvent

        rootElement.dispatchEvent(context.primaryDown());
        expect(keyDataList.length, 1);
        expectKeyData(keyDataList.last,
          type: ui.KeyEventType.up,
          deviceType: ui.KeyEventDeviceType.keyboard,
          physical: physicalLeft,
          logical: logicalLeft,
          character: null,
          synthesized: true,
        );
        expect(keyboardConverter.keyIsPressed(physicalLeft), false);
      }

      // Should synthesize a modifier right key up event when DOM event indicates
      // that the modifier key is not pressed and known pressing state contains
      // the modifier right key.
      void shouldSynthesizeRightUpIfRightPressed(String key, int modifiers) {
        final int physicalLeft = kWebToPhysicalKey['${key}Left']!;
        final int physicalRight = kWebToPhysicalKey['${key}Right']!;
        final int logicalRight = kWebLogicalLocationMap[key]![kLocationRight]!;

        final List<ui.KeyData> keyDataList = <ui.KeyData>[];
        final KeyboardConverter keyboardConverter = createKeyboardConverter(keyDataList);
        PointerBinding.instance!.debugOverrideKeyboardConverter(keyboardConverter);

        keyboardConverter.handleEvent(keyDownEvent('${key}Right', key, modifiers, kLocationRight));
        expect(keyboardConverter.keyIsPressed(physicalLeft), false);
        expect(keyboardConverter.keyIsPressed(physicalRight), true);
        keyDataList.clear(); // Remove key data generated by handleEvent

        rootElement.dispatchEvent(context.primaryDown());
        expect(keyDataList.length, 1);
        expectKeyData(keyDataList.last,
          type: ui.KeyEventType.up,
          deviceType: ui.KeyEventDeviceType.keyboard,
          physical: physicalRight,
          logical: logicalRight,
          character: null,
          synthesized: true,
        );
        expect(keyboardConverter.keyIsPressed(physicalRight), false);
      }

      context.altPressed = false;
      shouldSynthesizeLeftUpIfLeftPressed('Alt', kAlt);
      shouldSynthesizeRightUpIfRightPressed('Alt', kAlt);
      context.ctrlPressed = false;
      shouldSynthesizeLeftUpIfLeftPressed('Control', kCtrl);
      shouldSynthesizeRightUpIfRightPressed('Control', kCtrl);
      context.metaPressed = false;
      shouldSynthesizeLeftUpIfLeftPressed('Meta', kMeta);
      shouldSynthesizeRightUpIfRightPressed('Meta', kMeta);
      context.shiftPressed = false;
      shouldSynthesizeLeftUpIfLeftPressed('Shift', kShift);
      shouldSynthesizeRightUpIfRightPressed('Shift', kShift);
    },
  );

  _testEach<_BasicEventContext>(
    <_BasicEventContext>[
      _PointerEventContext(),
      _MouseEventContext(),
      _TouchEventContext(),
    ],
    'should not synthesize modifier keys up event if left or right are not pressed',
    (_BasicEventContext context) {
      PointerBinding.instance!.debugOverrideDetector(context);

      // Should not synthesize a modifier up event when DOM event indicates
      // that the modifier key is not pressed and known pressing state does
      // not contain the modifier left key nor the modifier right key.
      void shouldNotSynthesizeUpIfNotPressed(String key) {
        final int physicalLeft = kWebToPhysicalKey['${key}Left']!;
        final int physicalRight = kWebToPhysicalKey['${key}Right']!;

        final List<ui.KeyData> keyDataList = <ui.KeyData>[];
        final KeyboardConverter keyboardConverter = createKeyboardConverter(keyDataList);
        PointerBinding.instance!.debugOverrideKeyboardConverter(keyboardConverter);

        expect(keyboardConverter.keyIsPressed(physicalLeft), false);
        expect(keyboardConverter.keyIsPressed(physicalRight), false);
        keyDataList.clear(); // Remove key data generated by handleEvent

        rootElement.dispatchEvent(context.primaryDown());
        expect(keyDataList.length, 0);
      }

      context.altPressed = false;
      shouldNotSynthesizeUpIfNotPressed('Alt');
      context.ctrlPressed = false;
      shouldNotSynthesizeUpIfNotPressed('Control');
      context.metaPressed = false;
      shouldNotSynthesizeUpIfNotPressed('Meta');
      context.shiftPressed = false;
      shouldNotSynthesizeUpIfNotPressed('Shift');
    },
  );

  _testEach<_BasicEventContext>(
    <_BasicEventContext>[
      _PointerEventContext(),
      _MouseEventContext(),
      _TouchEventContext(),
    ],
    'should synthesize modifier keys up event for AltGraph',
    (_BasicEventContext context) {
      PointerBinding.instance!.debugOverrideDetector(context);

      final List<ui.KeyData> keyDataList = <ui.KeyData>[];
      final KeyboardConverter keyboardConverter = createKeyboardConverter(keyDataList);
      PointerBinding.instance!.debugOverrideKeyboardConverter(keyboardConverter);

      final int physicalAltRight = kWebToPhysicalKey['AltRight']!;
      final int logicalAltGraph = kWebLogicalLocationMap['AltGraph']![0]!;

      // Simulate pressing `AltGr` key.
      keyboardConverter.handleEvent(keyDownEvent('AltRight', 'AltGraph'));
      expect(keyboardConverter.keyIsPressed(physicalAltRight), true);
      keyDataList.clear(); // Remove key data generated by handleEvent.

      rootElement.dispatchEvent(context.primaryDown());
      expect(keyDataList.length, 1);
      expectKeyData(keyDataList.last,
        type: ui.KeyEventType.up,
        deviceType: ui.KeyEventDeviceType.keyboard,
        physical: physicalAltRight,
        logical: logicalAltGraph,
        character: null,
        synthesized: true,
      );
      expect(keyboardConverter.keyIsPressed(physicalAltRight), false);
    },
  );

  _testEach<_ButtonedEventMixin>(
    <_ButtonedEventMixin>[
      if (!isIosSafari) _PointerEventContext(),
      if (!isIosSafari) _MouseEventContext(),
    ],
    'correctly detects events on the semantics placeholder',
    (_ButtonedEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      final DomElement semanticsPlaceholder =
          createDomElement('flt-semantics-placeholder');
      rootElement.append(semanticsPlaceholder);

      // Press on the semantics placeholder.
      semanticsPlaceholder.dispatchEvent(context.primaryDown(
        clientX: 10.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].physicalX, equals(10.0 * dpi));
      expect(packets[0].data[1].physicalY, equals(10.0 * dpi));
      packets.clear();

      // Drag on the semantics placeholder.
      semanticsPlaceholder.dispatchEvent(context.primaryMove(
        clientX: 12.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].physicalX, equals(12.0 * dpi));
      expect(packets[0].data[0].physicalY, equals(10.0 * dpi));
      packets.clear();

      // Keep dragging.
      semanticsPlaceholder.dispatchEvent(context.primaryMove(
        clientX: 15.0,
        clientY: 10.0,
      ));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].physicalX, equals(15.0 * dpi));
      expect(packets[0].data[0].physicalY, equals(10.0 * dpi));
      packets.clear();

      // Release the pointer on the semantics placeholder.
      rootElement.dispatchEvent(context.primaryUp(
        clientX: 100.0,
        clientY: 200.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].physicalX, equals(100.0 * dpi));
      expect(packets[0].data[0].physicalY, equals(200.0 * dpi));
      expect(packets[0].data[1].change, equals(ui.PointerChange.up));
      expect(packets[0].data[1].physicalX, equals(100.0 * dpi));
      expect(packets[0].data[1].physicalY, equals(200.0 * dpi));
      packets.clear();

      semanticsPlaceholder.remove();
    },
    skip: isFirefox, // https://bugzilla.mozilla.org/show_bug.cgi?id=1804190
  );

  // BUTTONED ADAPTERS

  _testEach<_ButtonedEventMixin>(
    <_ButtonedEventMixin>[
      _PointerEventContext(),
      _MouseEventContext(),
    ],
    'creates an add event if the first pointer activity is a hover',
    (_ButtonedEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      rootElement.dispatchEvent(context.hover());

      expect(packets, hasLength(1));
      expect(packets.single.data, hasLength(2));

      expect(packets.single.data[0].change, equals(ui.PointerChange.add));
      expect(packets.single.data[0].synthesized, isTrue);
      expect(packets.single.data[1].change, equals(ui.PointerChange.hover));
    },
  );

  _testEach<_ButtonedEventMixin>(
    <_ButtonedEventMixin>[
      _PointerEventContext(),
      _MouseEventContext(),
    ],
    'sends a pointermove event instead of the second pointerdown in a row',
    (_ButtonedEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      rootElement.dispatchEvent(context.primaryDown(
        clientX: 10.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      // An add will be synthesized.
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, isTrue);
      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      packets.clear();

      rootElement.dispatchEvent(context.primaryDown(
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
    <_ButtonedEventMixin>[
      if (!isIosSafari) _PointerEventContext(),
      if (!isIosSafari) _MouseEventContext(),
    ],
    'does synthesize add or hover or move for scroll',
    (_ButtonedEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      rootElement.dispatchEvent(context.wheel(
        buttons: 0,
        clientX: 10,
        clientY: 10,
        deltaX: 10,
        deltaY: 10,
      ));

      rootElement.dispatchEvent(context.wheel(
        buttons: 0,
        clientX: 20,
        clientY: 50,
        deltaX: 10,
        deltaY: 10,
      ));

      rootElement.dispatchEvent(context.mouseDown(
        button: 0,
        buttons: 1,
        clientX: 20.0,
        clientY: 50.0,
      ));

      rootElement.dispatchEvent(context.wheel(
        buttons: 1,
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
      expect(packets[0].data[0].synthesized, isTrue);
      expect(packets[0].data[0].physicalX, equals(10.0 * dpi));
      expect(packets[0].data[0].physicalY, equals(10.0 * dpi));
      expect(packets[0].data[0].physicalDeltaX, equals(0.0));
      expect(packets[0].data[0].physicalDeltaY, equals(0.0));

      expect(packets[0].data[1].change, equals(ui.PointerChange.hover));
      expect(
          packets[0].data[1].signalKind, equals(ui.PointerSignalKind.scroll));
      expect(packets[0].data[1].pointerIdentifier, equals(0));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].physicalX, equals(10.0 * dpi));
      expect(packets[0].data[1].physicalY, equals(10.0 * dpi));
      expect(packets[0].data[1].physicalDeltaX, equals(0.0));
      expect(packets[0].data[1].physicalDeltaY, equals(0.0));

      // A hover will be synthesized.
      expect(packets[1].data, hasLength(2));
      expect(packets[1].data[0].change, equals(ui.PointerChange.hover));
      expect(packets[1].data[0].pointerIdentifier, equals(0));
      expect(packets[1].data[0].synthesized, isTrue);
      expect(packets[1].data[0].physicalX, equals(20.0 * dpi));
      expect(packets[1].data[0].physicalY, equals(50.0 * dpi));
      expect(packets[1].data[0].physicalDeltaX, equals(10.0 * dpi));
      expect(packets[1].data[0].physicalDeltaY, equals(40.0 * dpi));

      expect(packets[1].data[1].change, equals(ui.PointerChange.hover));
      expect(
          packets[1].data[1].signalKind, equals(ui.PointerSignalKind.scroll));
      expect(packets[1].data[1].pointerIdentifier, equals(0));
      expect(packets[1].data[1].synthesized, isFalse);
      expect(packets[1].data[1].physicalX, equals(20.0 * dpi));
      expect(packets[1].data[1].physicalY, equals(50.0 * dpi));
      expect(packets[1].data[1].physicalDeltaX, equals(0.0));
      expect(packets[1].data[1].physicalDeltaY, equals(0.0));

      // No synthetic pointer data for down event.
      expect(packets[2].data, hasLength(1));
      expect(packets[2].data[0].change, equals(ui.PointerChange.down));
      expect(packets[2].data[0].signalKind, equals(ui.PointerSignalKind.none));
      expect(packets[2].data[0].pointerIdentifier, equals(1));
      expect(packets[2].data[0].synthesized, isFalse);
      expect(packets[2].data[0].physicalX, equals(20.0 * dpi));
      expect(packets[2].data[0].physicalY, equals(50.0 * dpi));
      expect(packets[2].data[0].physicalDeltaX, equals(0.0));
      expect(packets[2].data[0].physicalDeltaY, equals(0.0));

      // A move will be synthesized instead of hover because the button is currently down.
      expect(packets[3].data, hasLength(2));
      expect(packets[3].data[0].change, equals(ui.PointerChange.move));
      expect(packets[3].data[0].pointerIdentifier, equals(1));
      expect(packets[3].data[0].synthesized, isTrue);
      expect(packets[3].data[0].physicalX, equals(30.0 * dpi));
      expect(packets[3].data[0].physicalY, equals(60.0 * dpi));
      expect(packets[3].data[0].physicalDeltaX, equals(10.0 * dpi));
      expect(packets[3].data[0].physicalDeltaY, equals(10.0 * dpi));

      expect(packets[3].data[1].change, equals(ui.PointerChange.hover));
      expect(
          packets[3].data[1].signalKind, equals(ui.PointerSignalKind.scroll));
      expect(packets[3].data[1].pointerIdentifier, equals(1));
      expect(packets[3].data[1].synthesized, isFalse);
      expect(packets[3].data[1].physicalX, equals(30.0 * dpi));
      expect(packets[3].data[1].physicalY, equals(60.0 * dpi));
      expect(packets[3].data[1].physicalDeltaX, equals(0.0));
      expect(packets[3].data[1].physicalDeltaY, equals(0.0));
    },
  );

  _testEach<_ButtonedEventMixin>(
    <_ButtonedEventMixin>[
      if (!isIosSafari) _PointerEventContext(),
      if (!isIosSafari) _MouseEventContext(),
    ],
    'converts scroll delta to physical pixels (Firefox)',
    (_ButtonedEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);

      const double dpi = 2.5;
      debugOperatingSystemOverride = OperatingSystem.macOs;
      debugBrowserEngineOverride = BrowserEngine.firefox;
      window.debugOverrideDevicePixelRatio(dpi);

      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      rootElement.dispatchEvent(context.wheel(
        buttons: 0,
        clientX: 10,
        clientY: 10,
        deltaX: 10,
        deltaY: 10,
      ));

      expect(packets, hasLength(1));


      // An add will be synthesized.
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      // Scroll deltas should be multiplied by `dpi`.
      expect(packets[0].data[0].scrollDeltaX, equals(10.0 * dpi));
      expect(packets[0].data[0].scrollDeltaY, equals(10.0 * dpi));

      expect(packets[0].data[1].change, equals(ui.PointerChange.hover));
      expect(packets[0].data[1].signalKind, equals(ui.PointerSignalKind.scroll));
      // Scroll deltas should be multiplied by `dpi`.
      expect(packets[0].data[0].scrollDeltaX, equals(10.0 * dpi));
      expect(packets[0].data[0].scrollDeltaY, equals(10.0 * dpi));

      window.debugOverrideDevicePixelRatio(1.0);
      debugOperatingSystemOverride = null;
      debugBrowserEngineOverride = null;
    },
  );

  _testEach<_ButtonedEventMixin>(
    <_ButtonedEventMixin>[
      if (!isIosSafari) _PointerEventContext(),
      if (!isIosSafari) _MouseEventContext(),
    ],
    'scroll delta are already in physical pixels (Chrome)',
    (_ButtonedEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);

      const double dpi = 2.5;
      debugOperatingSystemOverride = OperatingSystem.macOs;
      debugBrowserEngineOverride = BrowserEngine.blink;
      window.debugOverrideDevicePixelRatio(dpi);

      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      rootElement.dispatchEvent(context.wheel(
        buttons: 0,
        clientX: 10,
        clientY: 10,
        deltaX: 10,
        deltaY: 10,
      ));

      expect(packets, hasLength(1));


      // An add will be synthesized.
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      // Scroll deltas should NOT be multiplied by `dpi`.
      expect(packets[0].data[0].scrollDeltaX, equals(10.0));
      expect(packets[0].data[0].scrollDeltaY, equals(10.0));

      expect(packets[0].data[1].change, equals(ui.PointerChange.hover));
      expect(packets[0].data[1].signalKind, equals(ui.PointerSignalKind.scroll));
      // Scroll deltas should NOT be multiplied by `dpi`.
      expect(packets[0].data[0].scrollDeltaX, equals(10.0));
      expect(packets[0].data[0].scrollDeltaY, equals(10.0));

      window.debugOverrideDevicePixelRatio(1.0);
      debugOperatingSystemOverride = null;
      debugBrowserEngineOverride = null;
    },
  );

  _testEach<_ButtonedEventMixin>(
    <_ButtonedEventMixin>[
      if (!isIosSafari) _PointerEventContext(),
      if (!isIosSafari) _MouseEventContext(),
    ],
    'does set pointer device kind based on delta precision and wheelDelta',
    (_ButtonedEventMixin context) {
      if (isFirefox) {
        // Firefox does not support trackpad events, as they cannot be
        // disambiguated from smoothed mouse wheel events.
        return;
      }
      PointerBinding.instance!.debugOverrideDetector(context);
      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      rootElement.dispatchEvent(context.wheel(
        buttons: 0,
        clientX: 10,
        clientY: 10,
        deltaX: 119,
        deltaY: 119,
        wheelDeltaX: -357,
        wheelDeltaY: -357,
        timeStamp: 0,
      ));

      rootElement.dispatchEvent(context.wheel(
        buttons: 0,
        clientX: 10,
        clientY: 10,
        deltaX: 120,
        deltaY: 120,
        wheelDeltaX: -360,
        wheelDeltaY: -360,
        timeStamp: 10,
      ));

      rootElement.dispatchEvent(context.wheel(
        buttons: 0,
        clientX: 10,
        clientY: 10,
        deltaX: 120,
        deltaY: 120,
        wheelDeltaX: -360,
        wheelDeltaY: -360,
        timeStamp: 20,
      ));

      rootElement.dispatchEvent(context.wheel(
        buttons: 0,
        clientX: 10,
        clientY: 10,
        deltaX: 119,
        deltaY: 119,
        wheelDeltaX: -357,
        wheelDeltaY: -357,
        timeStamp: 1000,
      ));

      rootElement.dispatchEvent(context.wheel(
        buttons: 0,
        clientX: 10,
        clientY: 10,
        deltaX: -120,
        deltaY: -120,
        wheelDeltaX: 360,
        wheelDeltaY: 360,
        timeStamp: 1010,
      ));

      rootElement.dispatchEvent(context.wheel(
        buttons: 0,
        clientX: 10,
        clientY: 10,
        deltaX: 0,
        deltaY: -120,
        wheelDeltaX: 0,
        wheelDeltaY: 360,
        timeStamp: 2000,
      ));

      rootElement.dispatchEvent(context.wheel(
        buttons: 0,
        clientX: 10,
        clientY: 10,
        deltaX: 0,
        deltaY: 40,
        wheelDeltaX: 0,
        wheelDeltaY: -360,
        timeStamp: 3000,
      ));

      expect(packets, hasLength(7));

      // An add will be synthesized.
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].pointerIdentifier, equals(0));
      expect(packets[0].data[0].synthesized, isTrue);
      expect(packets[0].data[0].physicalX, equals(10.0 * dpi));
      expect(packets[0].data[0].physicalY, equals(10.0 * dpi));
      expect(packets[0].data[0].physicalDeltaX, equals(0.0));
      expect(packets[0].data[0].physicalDeltaY, equals(0.0));
      // Because the delta is not in increments of 120 and has matching wheelDelta,
      // it will be a trackpad event.
      expect(packets[0].data[1].change, equals(ui.PointerChange.hover));
      expect(
          packets[0].data[1].signalKind, equals(ui.PointerSignalKind.scroll));
      expect(
          packets[0].data[1].kind, equals(ui.PointerDeviceKind.trackpad));
      expect(packets[0].data[1].device, equals(-2));
      expect(packets[0].data[1].pointerIdentifier, equals(0));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].physicalX, equals(10.0 * dpi));
      expect(packets[0].data[1].physicalY, equals(10.0 * dpi));
      expect(packets[0].data[1].physicalDeltaX, equals(0.0));
      expect(packets[0].data[1].physicalDeltaY, equals(0.0));
      expect(packets[0].data[1].scrollDeltaX, equals(119.0));
      expect(packets[0].data[1].scrollDeltaY, equals(119.0));

      // Because the delta is in increments of 120, but is similar to the
      // previous event, it will be a trackpad event.
      expect(packets[1].data[0].change, equals(ui.PointerChange.hover));
      expect(
          packets[1].data[0].signalKind, equals(ui.PointerSignalKind.scroll));
      expect(
          packets[1].data[0].kind, equals(ui.PointerDeviceKind.trackpad));
      expect(packets[1].data[0].device, equals(-2));
      expect(packets[1].data[0].pointerIdentifier, equals(0));
      expect(packets[1].data[0].synthesized, isFalse);
      expect(packets[1].data[0].physicalX, equals(10.0 * dpi));
      expect(packets[1].data[0].physicalY, equals(10.0 * dpi));
      expect(packets[1].data[0].physicalDeltaX, equals(0.0));
      expect(packets[1].data[0].physicalDeltaY, equals(0.0));
      expect(packets[1].data[0].scrollDeltaX, equals(120.0));
      expect(packets[1].data[0].scrollDeltaY, equals(120.0));

      // Because the delta is in increments of 120, but is again similar to the
      // previous event, it will be a trackpad event.
      expect(packets[2].data[0].change, equals(ui.PointerChange.hover));
      expect(
          packets[2].data[0].signalKind, equals(ui.PointerSignalKind.scroll));
      expect(
          packets[2].data[0].kind, equals(ui.PointerDeviceKind.trackpad));
      expect(packets[2].data[0].device, equals(-2));
      expect(packets[2].data[0].pointerIdentifier, equals(0));
      expect(packets[2].data[0].synthesized, isFalse);
      expect(packets[2].data[0].physicalX, equals(10.0 * dpi));
      expect(packets[2].data[0].physicalY, equals(10.0 * dpi));
      expect(packets[2].data[0].physicalDeltaX, equals(0.0));
      expect(packets[2].data[0].physicalDeltaY, equals(0.0));
      expect(packets[2].data[0].scrollDeltaX, equals(120.0));
      expect(packets[2].data[0].scrollDeltaY, equals(120.0));

      // Because the delta is not in increments of 120 and has matching wheelDelta,
      // it will be a trackpad event.
      expect(packets[3].data[0].change, equals(ui.PointerChange.hover));
      expect(
          packets[3].data[0].signalKind, equals(ui.PointerSignalKind.scroll));
      expect(
          packets[3].data[0].kind, equals(ui.PointerDeviceKind.trackpad));
      expect(packets[3].data[0].device, equals(-2));
      expect(packets[3].data[0].pointerIdentifier, equals(0));
      expect(packets[3].data[0].synthesized, isFalse);
      expect(packets[3].data[0].physicalX, equals(10.0 * dpi));
      expect(packets[3].data[0].physicalY, equals(10.0 * dpi));
      expect(packets[3].data[0].physicalDeltaX, equals(0.0));
      expect(packets[3].data[0].physicalDeltaY, equals(0.0));
      expect(packets[3].data[0].scrollDeltaX, equals(119.0));
      expect(packets[3].data[0].scrollDeltaY, equals(119.0));

      // Because the delta is in increments of 120, and is not similar to the
      // previous event, but occurred soon after the previous event, it will be
      // a trackpad event.
      expect(packets[4].data[0].change, equals(ui.PointerChange.hover));
      expect(
          packets[4].data[0].signalKind, equals(ui.PointerSignalKind.scroll));
      expect(
          packets[4].data[0].kind, equals(ui.PointerDeviceKind.trackpad));
      expect(packets[4].data[0].device, equals(-2));
      expect(packets[4].data[0].pointerIdentifier, equals(0));
      expect(packets[4].data[0].synthesized, isFalse);
      expect(packets[4].data[0].physicalX, equals(10.0 * dpi));
      expect(packets[4].data[0].physicalY, equals(10.0 * dpi));
      expect(packets[4].data[0].physicalDeltaX, equals(0.0));
      expect(packets[4].data[0].physicalDeltaY, equals(0.0));
      expect(packets[4].data[0].scrollDeltaX, equals(-120.0));
      expect(packets[4].data[0].scrollDeltaY, equals(-120.0));

      // An add will be synthesized.
      expect(packets[5].data, hasLength(2));
      expect(packets[5].data[0].change, equals(ui.PointerChange.add));
      expect(
          packets[5].data[0].signalKind, equals(ui.PointerSignalKind.none));
      expect(
          packets[5].data[0].kind, equals(ui.PointerDeviceKind.mouse));
      expect(packets[5].data[0].device, equals(-1));
      expect(packets[5].data[0].pointerIdentifier, equals(0));
      expect(packets[5].data[0].synthesized, isTrue);
      expect(packets[5].data[0].physicalX, equals(10.0 * dpi));
      expect(packets[5].data[0].physicalY, equals(10.0 * dpi));
      expect(packets[5].data[0].physicalDeltaX, equals(0.0));
      expect(packets[5].data[0].physicalDeltaY, equals(0.0));
      expect(packets[5].data[0].scrollDeltaX, equals(0.0));
      expect(packets[5].data[0].scrollDeltaY, equals(-120.0));
      // Because the delta is in increments of 120, and is not similar to
      // the previous event, and occurred long after the previous event, it will
      // be a mouse event.
      expect(packets[5].data[1].change, equals(ui.PointerChange.hover));
      expect(
          packets[5].data[1].signalKind, equals(ui.PointerSignalKind.scroll));
      expect(
          packets[5].data[1].kind, equals(ui.PointerDeviceKind.mouse));
      expect(packets[5].data[1].device, equals(-1));
      expect(packets[5].data[1].pointerIdentifier, equals(0));
      expect(packets[5].data[1].synthesized, isFalse);
      expect(packets[5].data[1].physicalX, equals(10.0 * dpi));
      expect(packets[5].data[1].physicalY, equals(10.0 * dpi));
      expect(packets[5].data[1].physicalDeltaX, equals(0.0));
      expect(packets[5].data[1].physicalDeltaY, equals(0.0));
      expect(packets[5].data[1].scrollDeltaX, equals(0.0));
      expect(packets[5].data[1].scrollDeltaY, equals(-120.0));

      // Because the delta is not in increments of 120 and has non-matching
      // wheelDelta, it will be a mouse event.
      expect(packets[6].data, hasLength(1));
      expect(packets[6].data[0].change, equals(ui.PointerChange.hover));
      expect(
          packets[6].data[0].signalKind, equals(ui.PointerSignalKind.scroll));
      expect(
          packets[6].data[0].kind, equals(ui.PointerDeviceKind.mouse));
      expect(packets[6].data[0].device, equals(-1));
      expect(packets[6].data[0].pointerIdentifier, equals(0));
      expect(packets[6].data[0].synthesized, isFalse);
      expect(packets[6].data[0].physicalX, equals(10.0 * dpi));
      expect(packets[6].data[0].physicalY, equals(10.0 * dpi));
      expect(packets[6].data[0].physicalDeltaX, equals(0.0));
      expect(packets[6].data[0].physicalDeltaY, equals(0.0));
      expect(packets[6].data[0].scrollDeltaX, equals(0.0));
      expect(packets[6].data[0].scrollDeltaY, equals(40.0));
    },
  );

  _testEach<_ButtonedEventMixin>(
    <_ButtonedEventMixin>[
      if (!isIosSafari) _PointerEventContext(),
      if (!isIosSafari) _MouseEventContext(),
    ],
    'does choose scroll vs scale based on ctrlKey',
    (_ButtonedEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      rootElement.dispatchEvent(context.wheel(
        buttons: 0,
        clientX: 10,
        clientY: 10,
        deltaX: 0,
        deltaY: 120,
      ));

      rootElement.dispatchEvent(context.wheel(
        buttons: 0,
        clientX: 10,
        clientY: 10,
        deltaX: 0,
        deltaY: 100,
        ctrlKey: true,
      ));

      debugOperatingSystemOverride = OperatingSystem.macOs;
      KeyboardBinding.instance?.converter.handleEvent(keyDownEvent('ControlLeft', 'Control', kCtrl));

      rootElement.dispatchEvent(context.wheel(
        buttons: 0,
        clientX: 10,
        clientY: 10,
        deltaX: 0,
        deltaY: 240,
        ctrlKey: true,
      ));

      KeyboardBinding.instance?.converter.handleEvent(keyUpEvent('ControlLeft', 'Control', kCtrl));

      expect(packets, hasLength(3));

      // An add will be synthesized.
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].pointerIdentifier, equals(0));
      expect(packets[0].data[0].synthesized, isTrue);
      expect(packets[0].data[0].physicalX, equals(10.0 * dpi));
      expect(packets[0].data[0].physicalY, equals(10.0 * dpi));
      expect(packets[0].data[0].physicalDeltaX, equals(0.0));
      expect(packets[0].data[0].physicalDeltaY, equals(0.0));
      // Because ctrlKey is not pressed, it will be a scroll.
      expect(packets[0].data[1].change, equals(ui.PointerChange.hover));
      expect(
          packets[0].data[1].signalKind, equals(ui.PointerSignalKind.scroll));
      expect(
          packets[0].data[1].kind, equals(ui.PointerDeviceKind.mouse));
      expect(packets[0].data[1].pointerIdentifier, equals(0));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].physicalX, equals(10.0 * dpi));
      expect(packets[0].data[1].physicalY, equals(10.0 * dpi));
      expect(packets[0].data[1].physicalDeltaX, equals(0.0));
      expect(packets[0].data[1].physicalDeltaY, equals(0.0));
      expect(packets[0].data[1].scrollDeltaX, equals(0.0));
      expect(packets[0].data[1].scrollDeltaY, equals(120.0));

      // Because ctrlKey is pressed, it will be a scale.
      expect(packets[1].data, hasLength(1));
      expect(packets[1].data[0].change, equals(ui.PointerChange.hover));
      expect(
          packets[1].data[0].signalKind, equals(ui.PointerSignalKind.scale));
      expect(
          packets[1].data[0].kind, equals(ui.PointerDeviceKind.mouse));
      expect(packets[1].data[0].pointerIdentifier, equals(0));
      expect(packets[1].data[0].synthesized, isFalse);
      expect(packets[1].data[0].physicalX, equals(10.0 * dpi));
      expect(packets[1].data[0].physicalY, equals(10.0 * dpi));
      expect(packets[1].data[0].physicalDeltaX, equals(0.0));
      expect(packets[1].data[0].physicalDeltaY, equals(0.0));
      expect(packets[1].data[0].scale, closeTo(0.60653065971, 1e-10)); // math.exp(-100/200)

      // [macOS only]: Because ctrlKey is true, but the key is pressed physically, it will be a scroll.
      expect(packets[2].data, hasLength(1));
      expect(packets[2].data[0].change, equals(ui.PointerChange.hover));
      expect(
          packets[2].data[0].signalKind, equals(ui.PointerSignalKind.scroll));
      expect(
          packets[2].data[0].kind, equals(ui.PointerDeviceKind.mouse));
      expect(packets[2].data[0].pointerIdentifier, equals(0));
      expect(packets[2].data[0].synthesized, isFalse);
      expect(packets[2].data[0].physicalX, equals(10.0 * dpi));
      expect(packets[2].data[0].physicalY, equals(10.0 * dpi));
      expect(packets[2].data[0].physicalDeltaX, equals(0.0));
      expect(packets[2].data[0].physicalDeltaY, equals(0.0));
      expect(packets[2].data[0].scrollDeltaX, equals(0.0));
      expect(packets[2].data[0].scrollDeltaY, equals(240.0));

      debugOperatingSystemOverride = null;
    },
  );

  _testEach<_ButtonedEventMixin>(
    <_ButtonedEventMixin>[
      if (!isIosSafari) _PointerEventContext(),
      if (!isIosSafari) _MouseEventContext()
    ],
    'does calculate delta and pointer identifier correctly',
    (_ButtonedEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      rootElement.dispatchEvent(context.hover(
        clientX: 10.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].pointerIdentifier, equals(0));
      expect(packets[0].data[0].synthesized, isTrue);
      expect(packets[0].data[0].physicalX, equals(10.0 * dpi));
      expect(packets[0].data[0].physicalY, equals(10.0 * dpi));
      expect(packets[0].data[0].physicalDeltaX, equals(0.0));
      expect(packets[0].data[0].physicalDeltaY, equals(0.0));

      expect(packets[0].data[1].change, equals(ui.PointerChange.hover));
      expect(packets[0].data[1].pointerIdentifier, equals(0));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].physicalX, equals(10.0 * dpi));
      expect(packets[0].data[1].physicalY, equals(10.0 * dpi));
      expect(packets[0].data[1].physicalDeltaX, equals(0.0));
      expect(packets[0].data[1].physicalDeltaY, equals(0.0));
      packets.clear();

      rootElement.dispatchEvent(context.hover(
        clientX: 20.0,
        clientY: 20.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.hover));
      expect(packets[0].data[0].pointerIdentifier, equals(0));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].physicalX, equals(20.0 * dpi));
      expect(packets[0].data[0].physicalY, equals(20.0 * dpi));
      expect(packets[0].data[0].physicalDeltaX, equals(10.0 * dpi));
      expect(packets[0].data[0].physicalDeltaY, equals(10.0 * dpi));
      packets.clear();

      rootElement.dispatchEvent(context.primaryDown(
        clientX: 20.0,
        clientY: 20.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.down));
      expect(packets[0].data[0].pointerIdentifier, equals(1));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].physicalX, equals(20.0 * dpi));
      expect(packets[0].data[0].physicalY, equals(20.0 * dpi));
      expect(packets[0].data[0].physicalDeltaX, equals(0.0));
      expect(packets[0].data[0].physicalDeltaY, equals(0.0));
      packets.clear();

      rootElement.dispatchEvent(context.primaryMove(
        clientX: 40.0,
        clientY: 30.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].pointerIdentifier, equals(1));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].physicalX, equals(40.0 * dpi));
      expect(packets[0].data[0].physicalY, equals(30.0 * dpi));
      expect(packets[0].data[0].physicalDeltaX, equals(20.0 * dpi));
      expect(packets[0].data[0].physicalDeltaY, equals(10.0 * dpi));
      packets.clear();

      rootElement.dispatchEvent(context.primaryUp(
        clientX: 40.0,
        clientY: 30.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].pointerIdentifier, equals(1));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].physicalX, equals(40.0 * dpi));
      expect(packets[0].data[0].physicalY, equals(30.0 * dpi));
      expect(packets[0].data[0].physicalDeltaX, equals(0.0));
      expect(packets[0].data[0].physicalDeltaY, equals(0.0));
      packets.clear();

      rootElement.dispatchEvent(context.hover(
        clientX: 20.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.hover));
      expect(packets[0].data[0].pointerIdentifier, equals(1));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].physicalX, equals(20.0 * dpi));
      expect(packets[0].data[0].physicalY, equals(10.0 * dpi));
      expect(packets[0].data[0].physicalDeltaX, equals(-20.0 * dpi));
      expect(packets[0].data[0].physicalDeltaY, equals(-20.0 * dpi));
      packets.clear();

      rootElement.dispatchEvent(context.primaryDown(
        clientX: 20.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.down));
      expect(packets[0].data[0].pointerIdentifier, equals(2));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].physicalX, equals(20.0 * dpi));
      expect(packets[0].data[0].physicalY, equals(10.0 * dpi));
      expect(packets[0].data[0].physicalDeltaX, equals(0.0));
      expect(packets[0].data[0].physicalDeltaY, equals(0.0));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    <_ButtonedEventMixin>[
      if (!isIosSafari) _PointerEventContext(),
      if (!isIosSafari) _MouseEventContext(),
    ],
    'correctly converts buttons of down, move, leave, and up events',
    (_ButtonedEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Add and hover

      rootElement.dispatchEvent(context.hover(
        clientX: 10,
        clientY: 11,
      ));

      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, isTrue);
      expect(packets[0].data[0].physicalX, equals(10 * dpi));
      expect(packets[0].data[0].physicalY, equals(11 * dpi));

      expect(packets[0].data[1].change, equals(ui.PointerChange.hover));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].physicalX, equals(10 * dpi));
      expect(packets[0].data[1].physicalY, equals(11 * dpi));
      expect(packets[0].data[1].buttons, equals(0));
      packets.clear();

      rootElement.dispatchEvent(context.mouseDown(
        button: 0,
        buttons: 1,
        clientX: 10.0,
        clientY: 11.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.down));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].physicalX, equals(10 * dpi));
      expect(packets[0].data[0].physicalY, equals(11 * dpi));
      expect(packets[0].data[0].buttons, equals(1));
      packets.clear();

      rootElement.dispatchEvent(context.mouseMove(
        button: _kNoButtonChange,
        buttons: 1,
        clientX: 20.0,
        clientY: 21.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].physicalX, equals(20 * dpi));
      expect(packets[0].data[0].physicalY, equals(21 * dpi));
      expect(packets[0].data[0].buttons, equals(1));
      packets.clear();

      rootElement.dispatchEvent(context.mouseUp(
        button: 0,
        clientX: 20.0,
        clientY: 21.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].physicalX, equals(20 * dpi));
      expect(packets[0].data[0].physicalY, equals(21 * dpi));
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();

      // Drag with secondary button
      rootElement.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 2,
        clientX: 20.0,
        clientY: 21.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.down));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].physicalX, equals(20 * dpi));
      expect(packets[0].data[0].physicalY, equals(21 * dpi));
      expect(packets[0].data[0].buttons, equals(2));
      packets.clear();

      rootElement.dispatchEvent(context.mouseMove(
        button: _kNoButtonChange,
        buttons: 2,
        clientX: 30.0,
        clientY: 31.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].physicalX, equals(30 * dpi));
      expect(packets[0].data[0].physicalY, equals(31 * dpi));
      expect(packets[0].data[0].buttons, equals(2));
      packets.clear();

      rootElement.dispatchEvent(context.mouseUp(
        button: 2,
        clientX: 30.0,
        clientY: 31.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].physicalX, equals(30 * dpi));
      expect(packets[0].data[0].physicalY, equals(31 * dpi));
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();

      // Drag with middle button
      rootElement.dispatchEvent(context.mouseDown(
        button: 1,
        buttons: 4,
        clientX: 30.0,
        clientY: 31.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.down));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].physicalX, equals(30 * dpi));
      expect(packets[0].data[0].physicalY, equals(31 * dpi));
      expect(packets[0].data[0].buttons, equals(4));
      packets.clear();

      rootElement.dispatchEvent(context.mouseMove(
        button: _kNoButtonChange,
        buttons: 4,
        clientX: 40.0,
        clientY: 41.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].physicalX, equals(40 * dpi));
      expect(packets[0].data[0].physicalY, equals(41 * dpi));
      expect(packets[0].data[0].buttons, equals(4));
      packets.clear();

      rootElement.dispatchEvent(context.mouseUp(
        button: 1,
        clientX: 40.0,
        clientY: 41.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].physicalX, equals(40 * dpi));
      expect(packets[0].data[0].physicalY, equals(41 * dpi));
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();

      // Leave

      rootElement.dispatchEvent(context.mouseLeave(
        buttons: 1,
        clientX: 1000.0,
        clientY: 2000.0,
      ));
      expect(packets, isEmpty);
      packets.clear();

      rootElement.dispatchEvent(context.mouseLeave(
        buttons: 0,
        clientX: 1000.0,
        clientY: 2000.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.hover));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].physicalX, equals(1000 * dpi));
      expect(packets[0].data[0].physicalY, equals(2000 * dpi));
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    <_ButtonedEventMixin>[
      _PointerEventContext(),
      _MouseEventContext(),
    ],
    'correctly handles button changes during a down sequence',
    (_ButtonedEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Press LMB.
      rootElement.dispatchEvent(context.mouseDown(
        button: 0,
        buttons: 1,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, isTrue);

      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].buttons, equals(1));
      packets.clear();

      // Press MMB.
      rootElement.dispatchEvent(context.mouseMove(
        button: 1,
        buttons: 5,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].buttons, equals(5));
      packets.clear();

      // Release LMB.
      rootElement.dispatchEvent(context.mouseMove(
        button: 0,
        buttons: 4,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].buttons, equals(4));
      packets.clear();

      // Release MMB.
      rootElement.dispatchEvent(context.mouseUp(
        button: 1,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    <_ButtonedEventMixin>[
      if (!isIosSafari) _PointerEventContext(),
      if (!isIosSafari) _MouseEventContext(),
    ],
    'synthesizes a pointerup event when pointermove comes before the up',
    (_ButtonedEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      // This can happen when the user pops up the context menu by right
      // clicking, then dismisses it with a left click.

      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      rootElement.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 2,
        clientX: 10,
        clientY: 11,
      ));

      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, isTrue);
      expect(packets[0].data[0].physicalX, equals(10 * dpi));
      expect(packets[0].data[0].physicalY, equals(11 * dpi));

      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].physicalX, equals(10 * dpi));
      expect(packets[0].data[1].physicalY, equals(11 * dpi));
      expect(packets[0].data[1].buttons, equals(2));
      packets.clear();

      rootElement.dispatchEvent(context.mouseMove(
        button: _kNoButtonChange,
        buttons: 2,
        clientX: 20.0,
        clientY: 21.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].physicalX, equals(20 * dpi));
      expect(packets[0].data[0].physicalY, equals(21 * dpi));
      expect(packets[0].data[0].buttons, equals(2));
      packets.clear();

      rootElement.dispatchEvent(context.mouseMove(
        button: _kNoButtonChange,
        buttons: 2,
        clientX: 20.0,
        clientY: 21.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].physicalX, equals(20 * dpi));
      expect(packets[0].data[0].physicalY, equals(21 * dpi));
      expect(packets[0].data[0].buttons, equals(2));
      packets.clear();

      rootElement.dispatchEvent(context.mouseUp(
        button: 2,
        clientX: 20.0,
        clientY: 21.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].physicalX, equals(20 * dpi));
      expect(packets[0].data[0].physicalY, equals(21 * dpi));
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    <_ButtonedEventMixin>[
      _PointerEventContext(),
      _MouseEventContext(),
    ],
    'correctly handles uncontinuous button changes during a down sequence',
    (_ButtonedEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      // This can happen with the following gesture sequence:
      //
      //  - Pops up the context menu by right clicking, but holds RMB;
      //  - Clicks LMB;
      //  - Releases RMB.

      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Press RMB and hold, popping up the context menu.
      rootElement.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 2,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, isTrue);

      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].buttons, equals(2));
      packets.clear();

      // Press LMB. The event will have "button: -1" here, despite the change
      // in "buttons", probably because the "press" gesture was absorbed by
      // dismissing the context menu.
      rootElement.dispatchEvent(context.mouseMove(
        button: _kNoButtonChange,
        buttons: 3,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].buttons, equals(3));
      packets.clear();

      // Release LMB.
      rootElement.dispatchEvent(context.mouseMove(
        button: 0,
        buttons: 2,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].buttons, equals(2));
      packets.clear();

      // Release RMB.
      rootElement.dispatchEvent(context.mouseUp(
        button: 2,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    <_ButtonedEventMixin>[
      _PointerEventContext(),
    ],
    'correctly handles missing right mouse button up when followed by move',
    (_ButtonedEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      // This can happen with the following gesture sequence:
      //
      //  - Pops up the context menu by right clicking;
      //  - Clicks LMB to close context menu.
      //  - Moves mouse.

      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Press RMB popping up the context menu, then release by LMB down and up.
      // Browser won't send up event in that case.
      rootElement.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 2,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, isTrue);

      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].buttons, equals(2));
      packets.clear();

      // User now hovers.
      rootElement.dispatchEvent(context.mouseMove(
        button: _kNoButtonChange,
        buttons: 0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].buttons, equals(0));
      expect(packets[0].data[1].change, equals(ui.PointerChange.hover));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].buttons, equals(0));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    <_ButtonedEventMixin>[
      _PointerEventContext(),
      _MouseEventContext(),
    ],
    'handles RMB click when the browser sends it as a move',
    (_ButtonedEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      // When the user clicks the RMB and moves the mouse quickly (before the
      // context menu shows up), the browser sends a move event before down.
      // The move event will have "button:-1, buttons:2".

      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Press RMB and hold, popping up the context menu.
      rootElement.dispatchEvent(context.mouseMove(
        button: -1,
        buttons: 2,
        clientX: 10.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, isTrue);

      expect(packets[0].data[1].change, equals(ui.PointerChange.hover));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].buttons, equals(0));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    <_ButtonedEventMixin>[
      _PointerEventContext(),
      _MouseEventContext(),
    ],
    'correctly handles hover after RMB click',
    (_ButtonedEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      // This can happen with the following gesture sequence:
      //
      //  - Pops up the context menu by right clicking, but holds RMB;
      //  - Move the pointer to hover.

      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Press RMB and hold, popping up the context menu.
      rootElement.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 2,
        clientX: 10.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, isTrue);

      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].buttons, equals(2));
      packets.clear();

      // Move the mouse. The event will have "buttons: 0" because RMB was
      // released but the browser didn't send a pointerup/mouseup event.
      // The hover is also triggered at a different position.
      rootElement.dispatchEvent(context.hover(
        clientX: 20.0,
        clientY: 20.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(3));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, isTrue);
      expect(packets[0].data[0].buttons, equals(2));
      expect(packets[0].data[1].change, equals(ui.PointerChange.up));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].buttons, equals(0));
      expect(packets[0].data[2].change, equals(ui.PointerChange.hover));
      expect(packets[0].data[2].synthesized, isFalse);
      expect(packets[0].data[2].buttons, equals(0));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    <_ButtonedEventMixin>[
      _PointerEventContext(),
      _MouseEventContext(),
    ],
    'correctly handles LMB click after RMB click',
    (_ButtonedEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);
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

      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Press RMB and hold, popping up the context menu.
      rootElement.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 2,
        clientX: 10.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, isTrue);

      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].buttons, equals(2));
      packets.clear();

      // Press LMB.
      rootElement.dispatchEvent(context.mouseDown(
        button: 0,
        buttons: 3,
        clientX: 20.0,
        clientY: 20.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].buttons, equals(3));
      packets.clear();

      // Release LMB.
      rootElement.dispatchEvent(context.primaryUp(
        clientX: 20.0,
        clientY: 20.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    <_ButtonedEventMixin>[
      _PointerEventContext(),
      _MouseEventContext(),
    ],
    'correctly handles two consecutive RMB clicks with no up in between',
    (_ButtonedEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      // This can happen with the following gesture sequence:
      //
      //  - Pops up the context menu by right clicking, but holds RMB;
      //  - Clicks RMB again in a different location;

      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Press RMB and hold, popping up the context menu.
      rootElement.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 2,
        clientX: 10.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, isTrue);
      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].buttons, equals(2));
      packets.clear();

      // Press RMB again. In Chrome, when RMB is clicked again while the
      // context menu is still active, it sends a pointerdown/mousedown event
      // with "buttons:0". We convert this to pointer up, pointer down.
      rootElement.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 0,
        clientX: 20.0,
        clientY: 20.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(3));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].synthesized, isTrue);
      expect(packets[0].data[0].buttons, equals(2));
      expect(packets[0].data[0].physicalX, equals(20.0 * dpi));
      expect(packets[0].data[0].physicalY, equals(20.0 * dpi));
      expect(packets[0].data[1].change, equals(ui.PointerChange.up));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].buttons, equals(0));
      expect(packets[0].data[2].change, equals(ui.PointerChange.down));
      expect(packets[0].data[2].synthesized, isFalse);
      expect(packets[0].data[2].buttons, equals(2));
      packets.clear();

      // Release RMB.
      rootElement.dispatchEvent(context.mouseUp(
        button: 2,
        clientX: 20.0,
        clientY: 20.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    <_ButtonedEventMixin>[
      _PointerEventContext(),
      _MouseEventContext(),
    ],
    'correctly handles two consecutive RMB clicks with up in between',
    (_ButtonedEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      // This can happen with the following gesture sequence:
      //
      //  - Pops up the context menu by right clicking, but doesn't hold RMB;
      //  - Clicks RMB again in a different location;
      //
      // This seems to be happening sometimes when using RMB on the Mac trackpad.

      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Press RMB, popping up the context menu.
      rootElement.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 2,
        clientX: 10.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, isTrue);
      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].buttons, equals(2));
      packets.clear();

      // RMB up.
      rootElement.dispatchEvent(context.mouseUp(
        button: 2,
        clientX: 10.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();

      // Press RMB again. In Chrome, when RMB is clicked again while the
      // context menu is still active, it sends a pointerdown/mousedown event
      // with "buttons:0".
      rootElement.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 0,
        clientX: 20.0,
        clientY: 20.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.hover));
      expect(packets[0].data[0].synthesized, isTrue);
      expect(packets[0].data[0].buttons, equals(0));
      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].buttons, equals(2));
      packets.clear();

      // Release RMB.
      rootElement.dispatchEvent(context.mouseUp(
        button: 2,
        clientX: 20.0,
        clientY: 20.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    <_ButtonedEventMixin>[
      _PointerEventContext(),
      _MouseEventContext(),
    ],
    'correctly handles two consecutive RMB clicks in two different locations',
    (_ButtonedEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      // This can happen with the following gesture sequence:
      //
      //  - Pops up the context menu by right clicking;
      //  - The browser sends RMB up event;
      //  - Click RMB again in a different location;
      //
      // This scenario happens occasionally. I'm still not sure why, but in some
      // cases, the browser actually sends an `up` event for the RMB click even
      // when the context menu is shown.

      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Press RMB and hold, popping up the context menu.
      rootElement.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 2,
        clientX: 10.0,
        clientY: 10.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, isTrue);
      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].buttons, equals(2));
      packets.clear();

      // Release RMB.
      rootElement.dispatchEvent(context.mouseUp(
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
      rootElement.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 2,
        clientX: 20.0,
        clientY: 20.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.hover));
      expect(packets[0].data[0].synthesized, isTrue);
      expect(packets[0].data[0].buttons, equals(0));
      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].buttons, equals(2));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    <_ButtonedEventMixin>[
      _PointerEventContext(),
      _MouseEventContext(),
    ],
    'handles overlapping left/right down and up events',
    (_ButtonedEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      // This can happen with the following gesture sequence:
      //
      //     LMB:   down-------------------up
      //     RMB:              down------------------up
      // Flutter:   down-------move-------move-------up

      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Press and hold LMB.
      rootElement.dispatchEvent(context.mouseDown(
        button: 0,
        buttons: 1,
        clientX: 5.0,
        clientY: 100.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, isTrue);
      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].buttons, equals(1));
      expect(packets[0].data[1].physicalX, equals(5.0 * dpi));
      expect(packets[0].data[1].physicalY, equals(100.0 * dpi));
      packets.clear();

      // Press and hold RMB. The pointer is already down, so we only send a move
      // to update the position of the pointer.
      rootElement.dispatchEvent(context.mouseDown(
        button: 2,
        buttons: 3,
        clientX: 20.0,
        clientY: 100.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].buttons, equals(3));
      expect(packets[0].data[0].physicalX, equals(20.0 * dpi));
      expect(packets[0].data[0].physicalY, equals(100.0 * dpi));
      packets.clear();

      // Release LMB. The pointer is still down (RMB), so we only send a move to
      // update the position of the pointer.
      rootElement.dispatchEvent(context.mouseUp(
        button: 0,
        buttons: 2,
        clientX: 30.0,
        clientY: 100.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].buttons, equals(2));
      expect(packets[0].data[0].physicalX, equals(30.0 * dpi));
      expect(packets[0].data[0].physicalY, equals(100.0 * dpi));
      packets.clear();

      // Release RMB. There's no more buttons down, so we send an up event.
      rootElement.dispatchEvent(context.mouseUp(
        button: 2,
        buttons: 0,
        clientX: 30.0,
        clientY: 100.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].buttons, equals(0));
      packets.clear();
    },
  );

  _testEach<_ButtonedEventMixin>(
    <_ButtonedEventMixin>[
      if (!isIosSafari) _PointerEventContext(),
      if (!isIosSafari) _MouseEventContext(),
    ],
    'correctly detects up event outside of flutterViewElement',
    (_ButtonedEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      // This can happen when the up event occurs while the mouse is outside the
      // browser window.

      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Press and drag around.
      rootElement.dispatchEvent(context.primaryDown(
        clientX: 10.0,
        clientY: 10.0,
      ));
      rootElement.dispatchEvent(context.primaryMove(
        clientX: 12.0,
        clientY: 10.0,
      ));
      rootElement.dispatchEvent(context.primaryMove(
        clientX: 15.0,
        clientY: 10.0,
      ));
      rootElement.dispatchEvent(context.primaryMove(
        clientX: 20.0,
        clientY: 10.0,
      ));
      packets.clear();

      // Move outside the flutterViewElement.
      rootElement.dispatchEvent(context.primaryMove(
        clientX: 900.0,
        clientY: 1900.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].physicalX, equals(900.0 * dpi));
      expect(packets[0].data[0].physicalY, equals(1900.0 * dpi));
      packets.clear();

      // Release outside the flutterViewElement.
      rootElement.dispatchEvent(context.primaryUp(
        clientX: 1000.0,
        clientY: 2000.0,
      ));
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].physicalX, equals(1000.0 * dpi));
      expect(packets[0].data[0].physicalY, equals(2000.0 * dpi));
      expect(packets[0].data[1].change, equals(ui.PointerChange.up));
      expect(packets[0].data[1].physicalX, equals(1000.0 * dpi));
      expect(packets[0].data[1].physicalY, equals(2000.0 * dpi));
      packets.clear();
    },
  );

  // MULTIPOINTER ADAPTERS

  _testEach<_MultiPointerEventMixin>(
    <_MultiPointerEventMixin>[
      if (!isIosSafari) _PointerEventContext(),
      if (!isIosSafari) _TouchEventContext(),
    ],
    'treats each pointer separately',
    (_MultiPointerEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      List<ui.PointerData> data;
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Two pointers down
      context.multiTouchDown(const <_TouchDetails>[
        _TouchDetails(pointer: 2, clientX: 100, clientY: 101),
        _TouchDetails(pointer: 3, clientX: 200, clientY: 201),
      ]).forEach(rootElement.dispatchEvent);
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
      expect(data[0].synthesized, isTrue);
      expect(data[0].device, equals(2));
      expect(data[0].physicalX, equals(100 * dpi));
      expect(data[0].physicalY, equals(101 * dpi));

      expect(data[1].change, equals(ui.PointerChange.down));
      expect(data[1].device, equals(2));
      expect(data[1].buttons, equals(1));
      expect(data[1].physicalX, equals(100 * dpi));
      expect(data[1].physicalY, equals(101 * dpi));
      expect(data[1].physicalDeltaX, equals(0));
      expect(data[1].physicalDeltaY, equals(0));

      expect(data[2].change, equals(ui.PointerChange.add));
      expect(data[2].synthesized, isTrue);
      expect(data[2].device, equals(3));
      expect(data[2].physicalX, equals(200 * dpi));
      expect(data[2].physicalY, equals(201 * dpi));

      expect(data[3].change, equals(ui.PointerChange.down));
      expect(data[3].device, equals(3));
      expect(data[3].buttons, equals(1));
      expect(data[3].physicalX, equals(200 * dpi));
      expect(data[3].physicalY, equals(201 * dpi));
      expect(data[3].physicalDeltaX, equals(0));
      expect(data[3].physicalDeltaY, equals(0));
      packets.clear();

      // Two pointers move
      context.multiTouchMove(const <_TouchDetails>[
        _TouchDetails(pointer: 3, clientX: 300, clientY: 302),
        _TouchDetails(pointer: 2, clientX: 400, clientY: 402),
      ]).forEach(rootElement.dispatchEvent);
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
      expect(data[0].physicalX, equals(300 * dpi));
      expect(data[0].physicalY, equals(302 * dpi));
      expect(data[0].physicalDeltaX, equals(100 * dpi));
      expect(data[0].physicalDeltaY, equals(101 * dpi));

      expect(data[1].change, equals(ui.PointerChange.move));
      expect(data[1].device, equals(2));
      expect(data[1].buttons, equals(1));
      expect(data[1].physicalX, equals(400 * dpi));
      expect(data[1].physicalY, equals(402 * dpi));
      expect(data[1].physicalDeltaX, equals(300 * dpi));
      expect(data[1].physicalDeltaY, equals(301 * dpi));
      packets.clear();

      // One pointer up
      context.multiTouchUp(const <_TouchDetails>[
        _TouchDetails(pointer: 3, clientX: 300, clientY: 302),
      ]).forEach(rootElement.dispatchEvent);
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].device, equals(3));
      expect(packets[0].data[0].buttons, equals(0));
      expect(packets[0].data[0].physicalX, equals(300 * dpi));
      expect(packets[0].data[0].physicalY, equals(302 * dpi));
      expect(packets[0].data[0].physicalDeltaX, equals(0));
      expect(packets[0].data[0].physicalDeltaY, equals(0));

      expect(packets[0].data[1].change, equals(ui.PointerChange.remove));
      expect(packets[0].data[1].device, equals(3));
      expect(packets[0].data[1].buttons, equals(0));
      expect(packets[0].data[1].physicalX, equals(300 * dpi));
      expect(packets[0].data[1].physicalY, equals(302 * dpi));
      expect(packets[0].data[1].physicalDeltaX, equals(0));
      expect(packets[0].data[1].physicalDeltaY, equals(0));
      packets.clear();

      // Another pointer up
      context.multiTouchUp(const <_TouchDetails>[
        _TouchDetails(pointer: 2, clientX: 400, clientY: 402),
      ]).forEach(rootElement.dispatchEvent);
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].device, equals(2));
      expect(packets[0].data[0].buttons, equals(0));
      expect(packets[0].data[0].physicalX, equals(400 * dpi));
      expect(packets[0].data[0].physicalY, equals(402 * dpi));
      expect(packets[0].data[0].physicalDeltaX, equals(0));
      expect(packets[0].data[0].physicalDeltaY, equals(0));

      expect(packets[0].data[1].change, equals(ui.PointerChange.remove));
      expect(packets[0].data[1].device, equals(2));
      expect(packets[0].data[1].buttons, equals(0));
      expect(packets[0].data[1].physicalX, equals(400 * dpi));
      expect(packets[0].data[1].physicalY, equals(402 * dpi));
      expect(packets[0].data[1].physicalDeltaX, equals(0));
      expect(packets[0].data[1].physicalDeltaY, equals(0));
      packets.clear();

      // Again two pointers down (reuse pointer ID)
      context.multiTouchDown(const <_TouchDetails>[
        _TouchDetails(pointer: 3, clientX: 500, clientY: 501),
        _TouchDetails(pointer: 2, clientX: 600, clientY: 601),
      ]).forEach(rootElement.dispatchEvent);
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
      expect(data[0].synthesized, isTrue);
      expect(data[0].device, equals(3));
      expect(data[0].physicalX, equals(500 * dpi));
      expect(data[0].physicalY, equals(501 * dpi));

      expect(data[1].change, equals(ui.PointerChange.down));
      expect(data[1].device, equals(3));
      expect(data[1].buttons, equals(1));
      expect(data[1].physicalX, equals(500 * dpi));
      expect(data[1].physicalY, equals(501 * dpi));
      expect(data[1].physicalDeltaX, equals(0));
      expect(data[1].physicalDeltaY, equals(0));

      expect(data[2].change, equals(ui.PointerChange.add));
      expect(data[2].synthesized, isTrue);
      expect(data[2].device, equals(2));
      expect(data[2].physicalX, equals(600 * dpi));
      expect(data[2].physicalY, equals(601 * dpi));

      expect(data[3].change, equals(ui.PointerChange.down));
      expect(data[3].device, equals(2));
      expect(data[3].buttons, equals(1));
      expect(data[3].physicalX, equals(600 * dpi));
      expect(data[3].physicalY, equals(601 * dpi));
      expect(data[3].physicalDeltaX, equals(0));
      expect(data[3].physicalDeltaY, equals(0));
      packets.clear();
    },
  );

  _testEach<_MultiPointerEventMixin>(
    <_MultiPointerEventMixin>[
      if (!isIosSafari) _PointerEventContext(),
      if (!isIosSafari) _TouchEventContext(),
    ],
    'correctly parses cancel event',
    (_MultiPointerEventMixin context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      // Two pointers down
      context.multiTouchDown(const <_TouchDetails>[
        _TouchDetails(pointer: 2, clientX: 100, clientY: 101),
        _TouchDetails(pointer: 3, clientX: 200, clientY: 201),
      ]).forEach(rootElement.dispatchEvent);
      packets.clear(); // Down event is tested in other tests.

      // One pointer cancel
      context.multiTouchCancel(const <_TouchDetails>[
        _TouchDetails(pointer: 3, clientX: 300, clientY: 302),
      ]).forEach(rootElement.dispatchEvent);
      expect(packets.length, 1);
      expect(packets[0].data.length, 2);
      expect(packets[0].data[0].change, equals(ui.PointerChange.cancel));
      expect(packets[0].data[0].device, equals(3));
      expect(packets[0].data[0].buttons, equals(0));
      expect(packets[0].data[0].physicalX, equals(200 * dpi));
      expect(packets[0].data[0].physicalY, equals(201 * dpi));
      expect(packets[0].data[0].physicalDeltaX, equals(0));
      expect(packets[0].data[0].physicalDeltaY, equals(0));

      expect(packets[0].data[1].change, equals(ui.PointerChange.remove));
      expect(packets[0].data[1].device, equals(3));
      expect(packets[0].data[1].buttons, equals(0));
      expect(packets[0].data[1].physicalX, equals(200 * dpi));
      expect(packets[0].data[1].physicalY, equals(201 * dpi));
      expect(packets[0].data[1].physicalDeltaX, equals(0));
      expect(packets[0].data[1].physicalDeltaY, equals(0));
      packets.clear();
    },
  );

  // POINTER ADAPTER

  _testEach<_PointerEventContext>(
    <_PointerEventContext>[
      if (!isIosSafari) _PointerEventContext(),
    ],
    'does not synthesize pointer up if from different device',
    (_PointerEventContext context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      context.multiTouchDown(const <_TouchDetails>[
        _TouchDetails(pointer: 1, clientX: 100, clientY: 101),
      ]).forEach(rootElement.dispatchEvent);
      expect(packets, hasLength(1));
      // An add will be synthesized.
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, isTrue);
      expect(packets[0].data[0].device, equals(1));
      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].device, equals(1));
      packets.clear();

      context.multiTouchDown(const <_TouchDetails>[
        _TouchDetails(pointer: 2, clientX: 200, clientY: 202),
      ]).forEach(rootElement.dispatchEvent);
      // An add will be synthesized.
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].synthesized, isTrue);
      expect(packets[0].data[0].device, equals(2));
      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].device, equals(2));
      packets.clear();
    },
  );

  _testEach<_PointerEventContext>(
    <_PointerEventContext>[
      if (!isIosSafari) _PointerEventContext(),
    ],
    'ignores pointer up or pointer cancel events for unknown device',
    (_PointerEventContext context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      context.multiTouchUp(const <_TouchDetails>[
        _TouchDetails(pointer: 23, clientX: 200, clientY: 202),
      ]).forEach(rootElement.dispatchEvent);
      expect(packets, hasLength(0));

      context.multiTouchCancel(const <_TouchDetails>[
        _TouchDetails(pointer: 24, clientX: 200, clientY: 202),
      ]).forEach(rootElement.dispatchEvent);
      expect(packets, hasLength(0));
    },
  );

  _testEach<_PointerEventContext>(
    <_PointerEventContext>[
      _PointerEventContext(),
    ],
    'handles random pointer id on up events',
    (_PointerEventContext context) {
      PointerBinding.instance!.debugOverrideDetector(context);
      // This happens with pens that are simulated with mouse events
      // (e.g. Wacom). It sends events with the pointer type "mouse", and
      // assigns a random pointer ID to each event.
      //
      // For more info, see: https://github.com/flutter/flutter/issues/75559

      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      rootElement.dispatchEvent(context.mouseDown(
        pointerId: 12,
        button: 0,
        buttons: 1,
        clientX: 10.0,
        clientY: 10.0,
      ));

      expect(packets, hasLength(1));
      expect(packets.single.data, hasLength(2));

      expect(packets.single.data[0].change, equals(ui.PointerChange.add));
      expect(packets.single.data[0].synthesized, isTrue);
      expect(packets.single.data[1].change, equals(ui.PointerChange.down));
      packets.clear();

      expect(
        () {
          rootElement.dispatchEvent(context.mouseUp(
            pointerId: 41,
            button: 0,
            buttons: 0,
            clientX: 10.0,
            clientY: 10.0,
          ));
        },
        returnsNormally,
      );

      expect(packets, hasLength(1));
      expect(packets.single.data, hasLength(1));

      expect(packets.single.data[0].change, equals(ui.PointerChange.up));
    },
  );

  // TOUCH ADAPTER

  _testEach<_TouchEventContext>(
    <_TouchEventContext>[
      if (!isIosSafari) _TouchEventContext(),
    ],
    'does calculate delta and pointer identifier correctly',
    (_TouchEventContext context) {
      // Mouse and Pointer are in another test since these tests can involve hovering
      PointerBinding.instance!.debugOverrideDetector(context);
      final List<ui.PointerDataPacket> packets = <ui.PointerDataPacket>[];
      ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
        packets.add(packet);
      };

      context.multiTouchDown(const <_TouchDetails>[
        _TouchDetails(pointer: 1, clientX: 20, clientY: 20),
      ]).forEach(rootElement.dispatchEvent);
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].pointerIdentifier, equals(1));
      expect(packets[0].data[0].synthesized, isTrue);
      expect(packets[0].data[0].physicalX, equals(20.0 * dpi));
      expect(packets[0].data[0].physicalY, equals(20.0 * dpi));
      expect(packets[0].data[0].physicalDeltaX, equals(0.0));
      expect(packets[0].data[0].physicalDeltaY, equals(0.0));

      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].pointerIdentifier, equals(1));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].physicalX, equals(20.0 * dpi));
      expect(packets[0].data[1].physicalY, equals(20.0 * dpi));
      expect(packets[0].data[1].physicalDeltaX, equals(0.0));
      expect(packets[0].data[1].physicalDeltaY, equals(0.0));
      packets.clear();

      context.multiTouchMove(const <_TouchDetails>[
        _TouchDetails(pointer: 1, clientX: 40, clientY: 30),
      ]).forEach(rootElement.dispatchEvent);
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(1));
      expect(packets[0].data[0].change, equals(ui.PointerChange.move));
      expect(packets[0].data[0].pointerIdentifier, equals(1));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].physicalX, equals(40.0 * dpi));
      expect(packets[0].data[0].physicalY, equals(30.0 * dpi));
      expect(packets[0].data[0].physicalDeltaX, equals(20.0 * dpi));
      expect(packets[0].data[0].physicalDeltaY, equals(10.0 * dpi));
      packets.clear();

      context.multiTouchUp(const <_TouchDetails>[
        _TouchDetails(pointer: 1, clientX: 40, clientY: 30),
      ]).forEach(rootElement.dispatchEvent);
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.up));
      expect(packets[0].data[0].pointerIdentifier, equals(1));
      expect(packets[0].data[0].synthesized, isFalse);
      expect(packets[0].data[0].physicalX, equals(40.0 * dpi));
      expect(packets[0].data[0].physicalY, equals(30.0 * dpi));
      expect(packets[0].data[0].physicalDeltaX, equals(0.0));
      expect(packets[0].data[0].physicalDeltaY, equals(0.0));

      expect(packets[0].data[1].change, equals(ui.PointerChange.remove));
      expect(packets[0].data[1].pointerIdentifier, equals(1));
      expect(packets[0].data[1].synthesized, isTrue);
      expect(packets[0].data[1].physicalX, equals(40.0 * dpi));
      expect(packets[0].data[1].physicalY, equals(30.0 * dpi));
      expect(packets[0].data[1].physicalDeltaX, equals(0.0));
      expect(packets[0].data[1].physicalDeltaY, equals(0.0));
      packets.clear();

      context.multiTouchDown(const <_TouchDetails>[
        _TouchDetails(pointer: 2, clientX: 20, clientY: 10),
      ]).forEach(rootElement.dispatchEvent);
      expect(packets, hasLength(1));
      expect(packets[0].data, hasLength(2));
      expect(packets[0].data[0].change, equals(ui.PointerChange.add));
      expect(packets[0].data[0].pointerIdentifier, equals(2));
      expect(packets[0].data[0].synthesized, isTrue);
      expect(packets[0].data[0].physicalX, equals(20.0 * dpi));
      expect(packets[0].data[0].physicalY, equals(10.0 * dpi));
      expect(packets[0].data[0].physicalDeltaX, equals(0.0));
      expect(packets[0].data[0].physicalDeltaY, equals(0.0));

      expect(packets[0].data[1].change, equals(ui.PointerChange.down));
      expect(packets[0].data[1].pointerIdentifier, equals(2));
      expect(packets[0].data[1].synthesized, isFalse);
      expect(packets[0].data[1].physicalX, equals(20.0 * dpi));
      expect(packets[0].data[1].physicalY, equals(10.0 * dpi));
      expect(packets[0].data[1].physicalDeltaX, equals(0.0));
      expect(packets[0].data[1].physicalDeltaY, equals(0.0));
      packets.clear();
    },
  );

  group('ClickDebouncer', () {
    _testClickDebouncer();
  });
}

typedef CapturedSemanticsEvent = ({
  ui.SemanticsAction type,
  int nodeId,
});

void _testClickDebouncer() {
  final DateTime testTime = DateTime(2018, 12, 17);
  late List<ui.PointerChange> pointerPackets;
  late List<CapturedSemanticsEvent> semanticsActions;
  late _PointerEventContext context;
  late PointerBinding binding;

  void testWithSemantics(
    String description,
    Future<void> Function() body,
  ) {
    test(
      description,
      () async {
        EngineSemanticsOwner.instance
          ..debugOverrideTimestampFunction(() => testTime)
          ..semanticsEnabled = true;
        await body();
        EngineSemanticsOwner.instance.semanticsEnabled = false;
      },
    );
  }

  setUp(() {
    context = _PointerEventContext();
    pointerPackets = <ui.PointerChange>[];
    semanticsActions = <CapturedSemanticsEvent>[];
    ui.window.onPointerDataPacket = (ui.PointerDataPacket packet) {
      for (final ui.PointerData data in packet.data) {
        pointerPackets.add(data.change);
      }
    };
    EnginePlatformDispatcher.instance.onSemanticsActionEvent = (ui.SemanticsActionEvent event) {
      semanticsActions.add((type: event.type, nodeId: event.nodeId));
    };
    binding = PointerBinding.instance!;
    binding.debugOverrideDetector(context);
    binding.clickDebouncer.reset();
  });

  tearDown(() {
    binding.clickDebouncer.reset();
  });

  test('Forwards to framework when semantics is off', () {
    expect(EnginePlatformDispatcher.instance.semanticsEnabled, false);
    expect(binding.clickDebouncer.isDebouncing, false);
    binding.flutterViewElement.dispatchEvent(context.primaryDown());
    expect(pointerPackets, <ui.PointerChange>[
      ui.PointerChange.add,
      ui.PointerChange.down,
    ]);
    expect(binding.clickDebouncer.isDebouncing, false);
    expect(semanticsActions, isEmpty);
  });

  testWithSemantics('Forwards to framework when not debouncing', () async {
    expect(EnginePlatformDispatcher.instance.semanticsEnabled, true);
    expect(binding.clickDebouncer.isDebouncing, false);

    // This test DOM element is missing the `flt-tappable` attribute on purpose
    // so that the debouncer does not debounce events and simply lets
    // everything through.
    final DomElement testElement = createDomElement('flt-semantics');
    EnginePlatformDispatcher.instance.implicitView!.dom.semanticsHost.appendChild(testElement);

    testElement.dispatchEvent(context.primaryDown());
    testElement.dispatchEvent(context.primaryUp());
    expect(binding.clickDebouncer.isDebouncing, false);

    expect(pointerPackets, <ui.PointerChange>[
      ui.PointerChange.add,
      ui.PointerChange.down,
      ui.PointerChange.up,
    ]);
    expect(semanticsActions, isEmpty);
  });

  testWithSemantics('Accumulates pointer events starting from pointerdown', () async {
    expect(EnginePlatformDispatcher.instance.semanticsEnabled, true);
    expect(binding.clickDebouncer.isDebouncing, false);

    final DomElement testElement = createDomElement('flt-semantics');
    testElement.setAttribute('flt-tappable', '');
    EnginePlatformDispatcher.instance.implicitView!.dom.semanticsHost.appendChild(testElement);

    testElement.dispatchEvent(context.primaryDown());
    expect(
      reason: 'Should start debouncing at first pointerdown',
      binding.clickDebouncer.isDebouncing,
      true,
    );

    testElement.dispatchEvent(context.primaryUp());
    expect(
      reason: 'Should still be debouncing after pointerup',
      binding.clickDebouncer.isDebouncing,
      true,
    );

    expect(
      reason: 'Events are withheld from the framework while debouncing',
      pointerPackets,
      <ui.PointerChange>[],
    );
    expect(
      binding.clickDebouncer.debugState!.target,
      testElement,
    );
    expect(
      binding.clickDebouncer.debugState!.timer.isActive,
      isTrue,
    );
    expect(
      binding.clickDebouncer.debugState!.queue.map<String>((QueuedEvent e) => e.event.type),
      <String>['pointerdown', 'pointerup'],
    );

    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(
      reason: 'Should stop debouncing after timer expires.',
      binding.clickDebouncer.isDebouncing,
      false,
    );
    expect(
      reason: 'Queued up events should be flushed to the framework.',
      pointerPackets,
      <ui.PointerChange>[
        ui.PointerChange.add,
        ui.PointerChange.down,
        ui.PointerChange.up,
      ],
    );
    expect(semanticsActions, isEmpty);
  });

  testWithSemantics('Flushes events to framework when target changes', () async {
    expect(EnginePlatformDispatcher.instance.semanticsEnabled, true);
    expect(binding.clickDebouncer.isDebouncing, false);

    final DomElement testElement = createDomElement('flt-semantics');
    testElement.setAttribute('flt-tappable', '');
    EnginePlatformDispatcher.instance.implicitView!.dom.semanticsHost.appendChild(testElement);

    testElement.dispatchEvent(context.primaryDown());
    expect(
      reason: 'Should start debouncing at first pointerdown',
      binding.clickDebouncer.isDebouncing,
      true,
    );

    final DomElement newTarget = createDomElement('flt-semantics');
    newTarget.setAttribute('flt-tappable', '');
    EnginePlatformDispatcher.instance.implicitView!.dom.semanticsHost.appendChild(newTarget);
    newTarget.dispatchEvent(context.primaryUp());

    expect(
      reason: 'Should stop debouncing when target changes.',
      binding.clickDebouncer.isDebouncing,
      false,
    );
    expect(
      reason: 'The state should be cleaned up after stopping debouncing.',
      binding.clickDebouncer.debugState,
      isNull,
    );
    expect(
      reason: 'Queued up events should be flushed to the framework.',
      pointerPackets,
      <ui.PointerChange>[
        ui.PointerChange.add,
        ui.PointerChange.down,
        ui.PointerChange.up,
      ],
    );
    expect(semanticsActions, isEmpty);
  });

  testWithSemantics('Forwards click to framework when not debouncing but listening', () async {
    expect(binding.clickDebouncer.isDebouncing, false);

    final DomElement testElement = createDomElement('flt-semantics');
    testElement.setAttribute('flt-tappable', '');
    EnginePlatformDispatcher.instance.implicitView!.dom.semanticsHost.appendChild(testElement);

    final DomEvent click = createDomMouseEvent(
      'click',
      <Object?, Object?>{
        'clientX': testElement.getBoundingClientRect().x,
        'clientY': testElement.getBoundingClientRect().y,
      }
    );

    binding.clickDebouncer.onClick(click, 42, true);
    expect(binding.clickDebouncer.isDebouncing, false);
    expect(pointerPackets, isEmpty);
    expect(semanticsActions, <CapturedSemanticsEvent>[
      (type: ui.SemanticsAction.tap, nodeId: 42)
    ]);
  });

  testWithSemantics('Forwards click to framework when debouncing and listening', () async {
    expect(binding.clickDebouncer.isDebouncing, false);

    final DomElement testElement = createDomElement('flt-semantics');
    testElement.setAttribute('flt-tappable', '');
    EnginePlatformDispatcher.instance.implicitView!.dom.semanticsHost.appendChild(testElement);
    testElement.dispatchEvent(context.primaryDown());
    expect(binding.clickDebouncer.isDebouncing, true);

    final DomEvent click = createDomMouseEvent(
      'click',
      <Object?, Object?>{
        'clientX': testElement.getBoundingClientRect().x,
        'clientY': testElement.getBoundingClientRect().y,
      }
    );

    binding.clickDebouncer.onClick(click, 42, true);
    expect(pointerPackets, isEmpty);
    expect(semanticsActions, <CapturedSemanticsEvent>[
      (type: ui.SemanticsAction.tap, nodeId: 42)
    ]);
  });

  testWithSemantics('Dedupes click if debouncing but not listening', () async {
    expect(binding.clickDebouncer.isDebouncing, false);

    final DomElement testElement = createDomElement('flt-semantics');
    testElement.setAttribute('flt-tappable', '');
    EnginePlatformDispatcher.instance.implicitView!.dom.semanticsHost.appendChild(testElement);
    testElement.dispatchEvent(context.primaryDown());
    expect(binding.clickDebouncer.isDebouncing, true);

    final DomEvent click = createDomMouseEvent(
      'click',
      <Object?, Object?>{
        'clientX': testElement.getBoundingClientRect().x,
        'clientY': testElement.getBoundingClientRect().y,
      }
    );

    binding.clickDebouncer.onClick(click, 42, false);
    expect(
      reason: 'When tappable declares that it is not listening to click events '
              'the debouncer flushes the pointer events to the framework and '
              'lets it sort it out.',
      pointerPackets,
      <ui.PointerChange>[
        ui.PointerChange.add,
        ui.PointerChange.down,
      ],
    );
    expect(semanticsActions, isEmpty);
  });

  testWithSemantics('Dedupes click if pointer down/up flushed recently', () async {
    expect(EnginePlatformDispatcher.instance.semanticsEnabled, true);
    expect(binding.clickDebouncer.isDebouncing, false);

    final DomElement testElement = createDomElement('flt-semantics');
    testElement.setAttribute('flt-tappable', '');
    EnginePlatformDispatcher.instance.implicitView!.dom.semanticsHost.appendChild(testElement);

    testElement.dispatchEvent(context.primaryDown());

    // Simulate the user holding the pointer down for some time before releasing,
    // such that the pointerup event happens close to timer expiration. This
    // will create the situation that the click event arrives just after the
    // pointerup is flushed. Forwarding the click to the framework would look
    // like a double-click, so the click event is deduped.
    await Future<void>.delayed(const Duration(milliseconds: 190));

    testElement.dispatchEvent(context.primaryUp());
    expect(binding.clickDebouncer.isDebouncing, true);
    expect(
      reason: 'Timer has not expired yet',
      pointerPackets, isEmpty,
    );

    // Wait for the timer to expire to make sure pointer events are flushed.
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(
      reason: 'Queued up events should be flushed to the framework because the '
              'time expired before the click event arrived.',
      pointerPackets,
      <ui.PointerChange>[
        ui.PointerChange.add,
        ui.PointerChange.down,
        ui.PointerChange.up,
      ],
    );

    final DomEvent click = createDomMouseEvent(
      'click',
      <Object?, Object?>{
        'clientX': testElement.getBoundingClientRect().x,
        'clientY': testElement.getBoundingClientRect().y,
      }
    );
    binding.clickDebouncer.onClick(click, 42, true);

    expect(
      reason: 'Because the DOM click event was deduped.',
      semanticsActions,
      isEmpty,
    );
  });


  testWithSemantics('Forwards click if enough time passed after the last flushed pointerup', () async {
    expect(EnginePlatformDispatcher.instance.semanticsEnabled, true);
    expect(binding.clickDebouncer.isDebouncing, false);

    final DomElement testElement = createDomElement('flt-semantics');
    testElement.setAttribute('flt-tappable', '');
    EnginePlatformDispatcher.instance.implicitView!.dom.semanticsHost.appendChild(testElement);

    testElement.dispatchEvent(context.primaryDown());

    // Simulate the user holding the pointer down for some time before releasing,
    // such that the pointerup event happens close to timer expiration. This
    // makes it possible for the click to arrive early. However, this test in
    // particular will delay the click to check that the delay is checked
    // correctly. The inverse situation was already tested in the previous test.
    await Future<void>.delayed(const Duration(milliseconds: 190));

    testElement.dispatchEvent(context.primaryUp());
    expect(binding.clickDebouncer.isDebouncing, true);
    expect(
      reason: 'Timer has not expired yet',
      pointerPackets, isEmpty,
    );

    // Wait for the timer to expire to make sure pointer events are flushed.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(
      reason: 'Queued up events should be flushed to the framework because the '
              'time expired before the click event arrived.',
      pointerPackets,
      <ui.PointerChange>[
        ui.PointerChange.add,
        ui.PointerChange.down,
        ui.PointerChange.up,
      ],
    );

    final DomEvent click = createDomMouseEvent(
      'click',
      <Object?, Object?>{
        'clientX': testElement.getBoundingClientRect().x,
        'clientY': testElement.getBoundingClientRect().y,
      }
    );
    binding.clickDebouncer.onClick(click, 42, true);

    expect(
      reason: 'The DOM click should still be sent to the framework because it '
              'happened far enough from the last pointerup that it is unlikely '
              'to be a duplicate.',
      semanticsActions,
      <CapturedSemanticsEvent>[
        (type: ui.SemanticsAction.tap, nodeId: 42)
      ],
    );
  });
}

class MockSafariPointerEventWorkaround implements SafariPointerEventWorkaround {
  bool workAroundInvoked = false;

  @override
  void workAroundMissingPointerEvents() {
    workAroundInvoked = true;
  }
}

abstract class _BasicEventContext implements PointerSupportDetector {
  String get name;

  bool get isSupported;

  // Accepted modifier keys are 'Alt', 'Control', 'Meta' and 'Shift'.
  // https://www.w3.org/TR/uievents-key/#keys-modifier defines more modifiers,
  // but only the four main modifiers could be set from MouseEvent, PointerEvent
  // and TouchEvent constructors.
  bool altPressed = false;
  bool ctrlPressed = false;
  bool metaPressed = false;
  bool shiftPressed = false;

  // Generate an event that is:
  //
  //  * For mouse, a left click
  //  * For touch, a touch down
  DomEvent primaryDown({double clientX, double clientY});

  // Generate an event that is:
  //
  //  * For mouse, a drag with LMB down
  //  * For touch, a touch drag
  DomEvent primaryMove({double clientX, double clientY});

  // Generate an event that is:
  //
  //  * For mouse, release LMB
  //  * For touch, a touch up
  DomEvent primaryUp({double clientX, double clientY});

  void pressAllModifiers() {
    altPressed = true;
    ctrlPressed = true;
    metaPressed = true;
    shiftPressed = true;
  }

  void unpressAllModifiers() {
    altPressed = false;
    ctrlPressed = false;
    metaPressed = false;
    shiftPressed = false;
  }
}

mixin _ButtonedEventMixin on _BasicEventContext {
  // Generate an event that is a mouse down with the specific buttons.
  DomEvent mouseDown(
      {double? clientX, double? clientY, int? button, int? buttons});

  // Generate an event that is a mouse drag with the specific buttons, or button
  // changes during the drag.
  //
  // If there is no button change, assign `button` with _kNoButtonChange.
  DomEvent mouseMove(
      {double? clientX,
      double? clientY,
      required int button,
      required int buttons});

  // Generate an event that moves the mouse outside of the tracked area.
  DomEvent mouseLeave({double? clientX, double? clientY, required int buttons});

  // Generate an event that releases all mouse buttons.
  DomEvent mouseUp({double? clientX, double? clientY, int? button, int? buttons});

  DomEvent hover({double? clientX, double? clientY}) {
    return mouseMove(
      buttons: 0,
      button: _kNoButtonChange,
      clientX: clientX,
      clientY: clientY,
    );
  }

  @override
  DomEvent primaryDown({double? clientX, double? clientY}) {
    return mouseDown(
      buttons: 1,
      button: 0,
      clientX: clientX,
      clientY: clientY,
    );
  }

  @override
  DomEvent primaryMove({double? clientX, double? clientY}) {
    return mouseMove(
      buttons: 1,
      button: _kNoButtonChange,
      clientX: clientX,
      clientY: clientY,
    );
  }

  @override
  DomEvent primaryUp({double? clientX, double? clientY}) {
    return mouseUp(
      button: 0,
      clientX: clientX,
      clientY: clientY,
    );
  }

  DomEvent wheel({
    required int? buttons,
    required double? clientX,
    required double? clientY,
    required double? deltaX,
    required double? deltaY,
    double? wheelDeltaX,
    double? wheelDeltaY,
    int? timeStamp,
    bool ctrlKey = false,
  }) {
    final DomEvent event = createDomWheelEvent('wheel', <String, Object>{
        if (buttons != null) 'buttons': buttons,
        if (clientX != null) 'clientX': clientX,
        if (clientY != null) 'clientY': clientY,
        if (deltaX != null) 'deltaX': deltaX,
        if (deltaY != null) 'deltaY': deltaY,
        if (wheelDeltaX != null) 'wheelDeltaX': wheelDeltaX,
        if (wheelDeltaY != null) 'wheelDeltaY': wheelDeltaY,
        'ctrlKey': ctrlKey,
    });
    // timeStamp can't be set in the constructor, need to override the getter.
    if (timeStamp != null) {
      js_util.callMethod<void>(
        objectConstructor,
        'defineProperty',
        <dynamic>[
          event,
          'timeStamp',
          js_util.jsify(<String, dynamic>{
            'value': timeStamp,
            'configurable': true
          })
        ]
      );
    }
    return event;
  }
}

class _TouchDetails {
  const _TouchDetails({this.pointer, this.clientX, this.clientY});

  final int? pointer;
  final double? clientX;
  final double? clientY;
}

mixin _MultiPointerEventMixin on _BasicEventContext {
  List<DomEvent> multiTouchDown(List<_TouchDetails> touches);
  List<DomEvent> multiTouchMove(List<_TouchDetails> touches);
  List<DomEvent> multiTouchUp(List<_TouchDetails> touches);
  List<DomEvent> multiTouchCancel(List<_TouchDetails> touches);

  @override
  DomEvent primaryDown({double? clientX, double? clientY}) {
    return multiTouchDown(<_TouchDetails>[
      _TouchDetails(
        pointer: 1,
        clientX: clientX,
        clientY: clientY,
      ),
    ])[0];
  }

  @override
  DomEvent primaryMove({double? clientX, double? clientY}) {
    return multiTouchMove(<_TouchDetails>[
      _TouchDetails(
        pointer: 1,
        clientX: clientX,
        clientY: clientY,
      ),
    ])[0];
  }

  @override
  DomEvent primaryUp({double? clientX, double? clientY}) {
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
  _TouchEventContext() : _target = domDocument.createElement('div');

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

  final DomEventTarget _target;

  DomTouch _createTouch({
    int? identifier,
    double? clientX,
    double? clientY,
  }) {
    return createDomTouch(<String, dynamic>{
      'identifier': identifier,
      'clientX': clientX,
      'clientY': clientY,
      'target': _target,
    });
  }

  DomTouchEvent _createTouchEvent(
      String eventType, List<_TouchDetails> touches) {
    return createDomTouchEvent(
      eventType,
      <String, dynamic>{
        'bubbles': true,
        'changedTouches': touches
            .map(
              (_TouchDetails details) => _createTouch(
                identifier: details.pointer,
                clientX: details.clientX,
                clientY: details.clientY,
              ),
            )
            .toList(),
        'altKey': altPressed,
        'ctrlKey': ctrlPressed,
        'metaKey': metaPressed,
        'shiftKey': shiftPressed,
      },
    );
  }

  @override
  List<DomEvent> multiTouchDown(List<_TouchDetails> touches) {
    return <DomEvent>[_createTouchEvent('touchstart', touches)];
  }

  @override
  List<DomEvent> multiTouchMove(List<_TouchDetails> touches) {
    return <DomEvent>[_createTouchEvent('touchmove', touches)];
  }

  @override
  List<DomEvent> multiTouchUp(List<_TouchDetails> touches) {
    return <DomEvent>[_createTouchEvent('touchend', touches)];
  }

  @override
  List<DomEvent> multiTouchCancel(List<_TouchDetails> touches) {
    return <DomEvent>[_createTouchEvent('touchcancel', touches)];
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
  DomEvent mouseDown({
    double? clientX,
    double? clientY,
    int? button,
    int? buttons,
  }) {
    return _createMouseEvent(
      'mousedown',
      buttons: buttons,
      button: button,
      clientX: clientX,
      clientY: clientY,
    );
  }

  @override
  DomEvent mouseMove({
    double? clientX,
    double? clientY,
    required int button,
    required int buttons,
  }) {
    final bool hasButtonChange = button != _kNoButtonChange;
    final bool changeIsButtonDown =
        hasButtonChange && (buttons & convertButtonToButtons(button)) != 0;
    final String adjustedType = !hasButtonChange
        ? 'mousemove'
        : changeIsButtonDown
            ? 'mousedown'
            : 'mouseup';
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
  DomEvent mouseLeave({
    double? clientX,
    double? clientY,
    required int buttons,
  }) {
    return _createMouseEvent(
      'mouseleave',
      buttons: buttons,
      button: 0,
      clientX: clientX,
      clientY: clientY,
    );
  }

  @override
  DomEvent mouseUp({
    double? clientX,
    double? clientY,
    int? button,
    int? buttons,
  }) {
    return _createMouseEvent(
      'mouseup',
      buttons: buttons,
      button: button,
      clientX: clientX,
      clientY: clientY,
    );
  }

  DomMouseEvent _createMouseEvent(
    String type, {
    int? buttons,
    int? button,
    double? clientX,
    double? clientY,
  }) {
    return createDomMouseEvent(type, <String, Object>{
      if (buttons != null) 'buttons': buttons,
      if (button != null) 'button': button,
      if (clientX != null) 'clientX': clientX,
      if (clientY != null) 'clientY': clientY,
      'bubbles': true,
      'altKey': altPressed,
      'ctrlKey': ctrlPressed,
      'metaKey': metaPressed,
      'shiftKey': shiftPressed,
    });
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
  List<DomEvent> multiTouchDown(List<_TouchDetails> touches) {
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
  DomEvent mouseDown({
    double? clientX,
    double? clientY,
    int? button,
    int? buttons,
    int? pointerId = 1,
  }) {
    return _downWithFullDetails(
      pointer: pointerId,
      buttons: buttons,
      button: button,
      clientX: clientX,
      clientY: clientY,
      pointerType: 'mouse',
    );
  }

  DomEvent _downWithFullDetails({
    double? clientX,
    double? clientY,
    int? button,
    int? buttons,
    int? pointer,
    String? pointerType,
  }) {
    return createDomPointerEvent('pointerdown', <String, dynamic>{
      'bubbles': true,
      'pointerId': pointer,
      'button': button,
      'buttons': buttons,
      'clientX': clientX,
      'clientY': clientY,
      'pointerType': pointerType,
      'altKey': altPressed,
      'ctrlKey': ctrlPressed,
      'metaKey': metaPressed,
      'shiftKey': shiftPressed,
    });
  }

  @override
  List<DomEvent> multiTouchMove(List<_TouchDetails> touches) {
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
  DomEvent mouseMove({
    double? clientX,
    double? clientY,
    required int button,
    required int buttons,
    int pointerId = 1,
  }) {
    return _moveWithFullDetails(
      pointer: pointerId,
      buttons: buttons,
      button: button,
      clientX: clientX,
      clientY: clientY,
      pointerType: 'mouse',
    );
  }

  DomEvent _moveWithFullDetails({
    double? clientX,
    double? clientY,
    int? button,
    int? buttons,
    int? pointer,
    String? pointerType,
  }) {
    return createDomPointerEvent('pointermove', <String, dynamic>{
      'bubbles': true,
      'pointerId': pointer,
      'button': button,
      'buttons': buttons,
      'clientX': clientX,
      'clientY': clientY,
      'pointerType': pointerType,
    });
  }

  @override
  DomEvent mouseLeave({
    double? clientX,
    double? clientY,
    required int buttons,
    int pointerId = 1,
  }) {
    return _leaveWithFullDetails(
      pointer: pointerId,
      buttons: buttons,
      button: 0,
      clientX: clientX,
      clientY: clientY,
      pointerType: 'mouse',
    );
  }

  DomEvent _leaveWithFullDetails({
    double? clientX,
    double? clientY,
    int? button,
    int? buttons,
    int? pointer,
    String? pointerType,
  }) {
    return createDomPointerEvent('pointerleave', <String, dynamic>{
      'bubbles': true,
      'pointerId': pointer,
      'button': button,
      'buttons': buttons,
      'clientX': clientX,
      'clientY': clientY,
      'pointerType': pointerType,
    });
  }

  @override
  List<DomEvent> multiTouchUp(List<_TouchDetails> touches) {
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
  DomEvent mouseUp({
    double? clientX,
    double? clientY,
    int? button,
    int? buttons,
    int? pointerId = 1,
  }) {
    return _upWithFullDetails(
      pointer: pointerId,
      button: button,
      buttons: buttons,
      clientX: clientX,
      clientY: clientY,
      pointerType: 'mouse',
    );
  }

  DomEvent _upWithFullDetails({
    double? clientX,
    double? clientY,
    int? button,
    int? buttons,
    int? pointer,
    String? pointerType,
  }) {
    return createDomPointerEvent('pointerup', <String, dynamic>{
      'bubbles': true,
      'pointerId': pointer,
      'button': button,
      'buttons': buttons,
      'clientX': clientX,
      'clientY': clientY,
      'pointerType': pointerType,
    });
  }

  @override
  List<DomEvent> multiTouchCancel(List<_TouchDetails> touches) {
    return touches
        .map((_TouchDetails details) =>
            createDomPointerEvent('pointercancel', <String, dynamic>{
              'bubbles': true,
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
