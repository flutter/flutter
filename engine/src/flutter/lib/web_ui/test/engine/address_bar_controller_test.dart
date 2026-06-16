// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

/// Desktop Safari and Firefox do not expose the `Touch`/`TouchEvent`
/// constructors, so tests that synthesize Touch Events can only run on
/// Chromium-based browsers. The browsers this code path targets (mobile
/// Safari and mobile Chrome) both support Touch Events.
final bool touchConstructorsSupported =
    globalContext.has('Touch') && globalContext.has('TouchEvent');

EnginePlatformDispatcher get dispatcher => EnginePlatformDispatcher.instance;

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  EngineFlutterWindow createFullPageView() => EngineFlutterView.implicit(dispatcher, null);

  DomTouch createTouch({
    required int identifier,
    required DomEventTarget target,
    required double clientX,
    required double clientY,
  }) {
    return createDomTouch(<String, dynamic>{
      'identifier': identifier,
      'target': target,
      'clientX': clientX,
      'clientY': clientY,
    });
  }

  DomTouchEvent createTouchEvent(String type, List<DomTouch> touches) {
    return DomTouchEvent(
      type,
      <String, dynamic>{'bubbles': true, 'cancelable': true, 'changedTouches': touches}.toJSAnyDeep,
    );
  }

  void dispatchTouch(
    DomElement target,
    String type,
    int identifier, {
    double x = 10,
    double y = 10,
  }) {
    target.dispatchEvent(
      createTouchEvent(type, <DomTouch>[
        createTouch(identifier: identifier, target: target, clientX: x, clientY: y),
      ]),
    );
  }

  DomElement? findSpacer() => domDocument.documentElement!.querySelector('flt-scroll-spacer');

  group('$AddressBarController lifecycle', () {
    EngineFlutterView? view;

    // Dispose through tearDown so a failing expectation cannot leak the
    // view's DOM (e.g. the spacer) into the following tests.
    tearDown(() {
      view?.dispose();
      PointerBinding.debugResetGlobalState();
      view = null;
      ui_web.browser.debugOperatingSystemOverride = null;
    });

    test('does nothing on a desktop OS', () {
      ui_web.browser.debugOperatingSystemOverride = ui_web.OperatingSystem.macOs;
      view = createFullPageView();

      expect(findSpacer(), isNull);
      expect(domDocument.body!.style.getPropertyValue('touch-action'), 'none');
    });

    test('does nothing for a custom element view, even on mobile', () {
      ui_web.browser.debugOperatingSystemOverride = ui_web.OperatingSystem.android;
      final DomElement host = createDomHTMLDivElement();
      domDocument.body!.append(host);
      addTearDown(() => host.remove());
      view = EngineFlutterView(dispatcher, host);

      expect(findSpacer(), isNull);
    });

    test('on Android, makes the page scrollable with two top snap targets', () {
      ui_web.browser.debugOperatingSystemOverride = ui_web.OperatingSystem.android;
      view = createFullPageView();

      expect(domDocument.body!.style.overflowY, 'auto');
      expect(domDocument.body!.style.getPropertyValue('touch-action'), 'pan-y');
      // `proximity` is the default snap strictness, so the browser drops it when
      // serializing `y proximity`, leaving `y`.
      expect(domDocument.documentElement!.style.getPropertyValue('scroll-snap-type'), 'y');

      final DomElement? spacer = findSpacer();
      expect(spacer, isNotNull);
      // 100vh + snapDistance (100) + 1px pull-to-refresh guard +
      // collapseMargin (100). Browsers normalize the order of calc() terms,
      // so the assertion cannot compare the full string.
      expect(spacer!.style.height, allOf(contains('100vh'), contains('201px')));

      final List<DomElement> snapTargets = spacer.children.toList();
      expect(snapTargets, hasLength(2));
      expect(snapTargets[0].style.top, '1px');
      expect(snapTargets[1].style.top, '101px');
      for (final snapTarget in snapTargets) {
        expect(snapTarget.style.getPropertyValue('scroll-snap-align'), 'start');
      }
    });

    test('on iOS, uses a single mid-point snap target', () {
      ui_web.browser.debugOperatingSystemOverride = ui_web.OperatingSystem.iOs;
      view = createFullPageView();

      expect(domDocument.body!.style.overflowY, 'auto');
      expect(domDocument.body!.style.getPropertyValue('touch-action'), 'pan-y');
      expect(
        domDocument.documentElement!.style.getPropertyValue('scroll-snap-type'),
        'y mandatory',
      );

      final DomElement? spacer = findSpacer();
      expect(spacer, isNotNull);
      expect(spacer!.style.height, '10000px');

      final List<DomElement> snapTargets = spacer.children.toList();
      expect(snapTargets, hasLength(1));
      expect(snapTargets[0].style.top, '5000px');
    });

    test('dispose removes the spacer and restores full-page styles', () {
      ui_web.browser.debugOperatingSystemOverride = ui_web.OperatingSystem.android;
      view = createFullPageView();
      expect(findSpacer(), isNotNull);

      view!.dispose();

      expect(findSpacer(), isNull);
      expect(domDocument.body!.style.overflowY, 'hidden');
      expect(domDocument.body!.style.getPropertyValue('touch-action'), 'none');
      expect(domDocument.documentElement!.style.getPropertyValue('scroll-snap-type'), '');
      expect(domDocument.documentElement!.style.getPropertyValue('scrollbar-width'), '');
    });
  });

  group('$AddressBarController touch input pipeline', () {
    late EngineFlutterWindow view;
    late List<ui.PointerDataPacket> packets;

    setUp(() {
      ui_web.browser.debugOperatingSystemOverride = ui_web.OperatingSystem.android;
      view = createFullPageView();
      packets = <ui.PointerDataPacket>[];
      dispatcher.onPointerDataPacket = packets.add;
    });

    tearDown(() {
      dispatcher.onPointerDataPacket = null;
      view.dispose();
      PointerBinding.debugResetGlobalState();
      ui_web.browser.debugOperatingSystemOverride = null;
    });

    test('touchstart produces an add and a touch-kind down', () {
      final DomElement root = view.dom.rootElement;
      final double dpr = view.devicePixelRatio;
      dispatchTouch(root, 'touchstart', 7, y: 20);

      final List<ui.PointerData> data = allPointerDataOf(packets);
      expect(data, hasLength(2));
      expect(data[0].change, ui.PointerChange.add);
      expect(data[1].change, ui.PointerChange.down);
      expect(data[1].kind, ui.PointerDeviceKind.touch);
      expect(data[1].device, 7);
      expect(data[1].physicalX, 10 * dpr);
      expect(data[1].physicalY, 20 * dpr);
      expect(data[1].buttons, 1);

      // End the gesture so no pointer state leaks into other tests.
      dispatchTouch(root, 'touchend', 7, y: 20);
    });

    test('a full tap gesture ends with up and a synthesized remove', () {
      final DomElement root = view.dom.rootElement;
      dispatchTouch(root, 'touchstart', 11);
      dispatchTouch(root, 'touchmove', 11, y: 30);
      dispatchTouch(root, 'touchend', 11, y: 30);

      final List<ui.PointerChange> changes = allPointerDataOf(
        packets,
      ).map((ui.PointerData data) => data.change).toList();
      expect(changes, <ui.PointerChange>[
        ui.PointerChange.add,
        ui.PointerChange.down,
        ui.PointerChange.move,
        ui.PointerChange.up,
        ui.PointerChange.remove,
      ]);
    });

    test('touchcancel sends cancel', () {
      final DomElement root = view.dom.rootElement;
      dispatchTouch(root, 'touchstart', 21);
      dispatchTouch(root, 'touchcancel', 21);

      final List<ui.PointerChange> changes = allPointerDataOf(
        packets,
      ).map((ui.PointerData data) => data.change).toList();
      expect(changes, <ui.PointerChange>[
        ui.PointerChange.add,
        ui.PointerChange.down,
        ui.PointerChange.cancel,
        ui.PointerChange.remove,
      ]);
    });

    test('move, end, and cancel of unknown identifiers are ignored', () {
      final DomElement root = view.dom.rootElement;
      dispatchTouch(root, 'touchmove', 99);
      dispatchTouch(root, 'touchend', 99);
      dispatchTouch(root, 'touchcancel', 99);

      expect(packets, isEmpty);
    });

    test('multi-touch produces an independent pointer per identifier', () {
      final DomElement root = view.dom.rootElement;
      root.dispatchEvent(
        createTouchEvent('touchstart', <DomTouch>[
          createTouch(identifier: 31, target: root, clientX: 10, clientY: 10),
          createTouch(identifier: 32, target: root, clientX: 50, clientY: 50),
        ]),
      );

      final List<ui.PointerData> data = allPointerDataOf(packets);
      final Iterable<ui.PointerData> downs = data.where(
        (ui.PointerData datum) => datum.change == ui.PointerChange.down,
      );
      expect(downs.map((ui.PointerData datum) => datum.device), <int>[31, 32]);

      root.dispatchEvent(
        createTouchEvent('touchend', <DomTouch>[
          createTouch(identifier: 31, target: root, clientX: 10, clientY: 10),
          createTouch(identifier: 32, target: root, clientX: 50, clientY: 50),
        ]),
      );
    });

    test('positions stay client-relative while the page is scrolled', () {
      final DomElement root = view.dom.rootElement;
      final double dpr = view.devicePixelRatio;
      // The spacer keeps the page scrolled away from 0 on devices (~5000 on
      // iOS); positions must not skew by the scroll offset.
      domDocument.documentElement!.scrollTop = 60;
      addTearDown(() {
        domDocument.documentElement!.scrollTop = 0;
      });

      dispatchTouch(root, 'touchstart', 81, y: 20);
      dispatchTouch(root, 'touchend', 81, y: 20);

      final List<ui.PointerData> data = allPointerDataOf(packets);
      expect(data[1].change, ui.PointerChange.down);
      expect(data[1].physicalX, 10 * dpr);
      expect(data[1].physicalY, 20 * dpr);
    });

    test('a touch on a child element gets view-relative coordinates', () {
      // The pointer position is the finger's location in the view, regardless
      // of which descendant the touch lands on (not relative to that element).
      final DomElement child = createDomElement('div');
      child.style
        ..position = 'absolute'
        ..left = '40px'
        ..top = '30px';
      view.dom.rootElement.append(child);
      addTearDown(() => child.remove());

      final double dpr = view.devicePixelRatio;
      final DomRect rootRect = view.dom.rootElement.getBoundingClientRect();

      dispatchTouch(child, 'touchstart', 95, x: 60, y: 50);

      final ui.PointerData down = allPointerDataOf(
        packets,
      ).firstWhere((ui.PointerData d) => d.change == ui.PointerChange.down);
      expect(down.physicalX, closeTo((60 - rootRect.x) * dpr, 0.5));
      expect(down.physicalY, closeTo((50 - rootRect.y) * dpr, 0.5));

      dispatchTouch(child, 'touchend', 95, x: 60, y: 50);
    });

    test('a touch coinciding with an active stylus is skipped', () {
      final DomElement root = view.dom.rootElement;
      // A stylus surfaces as a 'pen' Pointer event (which PointerBinding
      // handles) plus a Touch event at the same point. The touch must not be
      // translated into a second pointer.
      root.dispatchEvent(
        createDomPointerEvent('pointerdown', <String, dynamic>{
          'bubbles': true,
          'pointerId': 5,
          'pointerType': 'pen',
          'button': 0,
          'buttons': 1,
          'clientX': 30.0,
          'clientY': 40.0,
        }),
      );
      // Ignore any pointer data PointerBinding emitted for the pen itself.
      packets.clear();

      dispatchTouch(root, 'touchstart', 71, x: 30, y: 40);
      expect(packets, isEmpty);

      // A finger at a different point is still translated.
      dispatchTouch(root, 'touchstart', 72, x: 200, y: 200);
      expect(
        allPointerDataOf(packets).where((ui.PointerData d) => d.change == ui.PointerChange.down),
        isNotEmpty,
      );
      dispatchTouch(root, 'touchend', 72, x: 200, y: 200);

      // Release the pen so no pointer state leaks into other tests.
      root.dispatchEvent(
        createDomPointerEvent('pointerup', <String, dynamic>{
          'bubbles': true,
          'pointerId': 5,
          'pointerType': 'pen',
          'button': 0,
          'buttons': 0,
          'clientX': 30.0,
          'clientY': 40.0,
        }),
      );
    });

    test('a touch at a lifted stylus position is translated again', () {
      final DomElement root = view.dom.rootElement;
      // Pen down at (30, 40): a coinciding touch is skipped as a duplicate.
      root.dispatchEvent(
        createDomPointerEvent('pointerdown', <String, dynamic>{
          'bubbles': true,
          'pointerId': 8,
          'pointerType': 'pen',
          'button': 0,
          'buttons': 1,
          'clientX': 30.0,
          'clientY': 40.0,
        }),
      );
      packets.clear();
      dispatchTouch(root, 'touchstart', 81, x: 30, y: 40);
      expect(packets, isEmpty);
      dispatchTouch(root, 'touchend', 81, x: 30, y: 40);

      // Lifting the pen clears the tracked contact.
      root.dispatchEvent(
        createDomPointerEvent('pointerup', <String, dynamic>{
          'bubbles': true,
          'pointerId': 8,
          'pointerType': 'pen',
          'button': 0,
          'buttons': 0,
          'clientX': 30.0,
          'clientY': 40.0,
        }),
      );
      packets.clear();

      // A touch at the same point is no longer treated as a stylus duplicate.
      dispatchTouch(root, 'touchstart', 82, x: 30, y: 40);
      expect(
        allPointerDataOf(packets).where((ui.PointerData d) => d.change == ui.PointerChange.down),
        isNotEmpty,
      );
      dispatchTouch(root, 'touchend', 82, x: 30, y: 40);
    });

    test('dispose synthesizes cancel for active touches', () {
      dispatchTouch(view.dom.rootElement, 'touchstart', 51);
      packets.clear();

      view.dispose();

      final List<ui.PointerChange> changes = allPointerDataOf(
        packets,
      ).map((ui.PointerData data) => data.change).toList();
      expect(changes, <ui.PointerChange>[ui.PointerChange.cancel, ui.PointerChange.remove]);
    });

    test('a cancel issued while debouncing flushes in order behind the down', () async {
      // With semantics on, a tap on a tappable element is held by the
      // ClickDebouncer. If the view is disposed during that window, the cancel
      // must queue behind the still-pending `down` and flush in order. Routing
      // it straight to the dispatcher would race ahead of the queued `down` and
      // strand the framework with a phantom pointer.
      EngineSemantics.instance.semanticsEnabled = true;
      addTearDown(() => EngineSemantics.instance.semanticsEnabled = false);
      view.dom.rootElement.setAttribute('flt-tappable', '');

      dispatchTouch(view.dom.rootElement, 'touchstart', 61);
      // The debouncer holds the down; nothing reaches the framework yet.
      expect(packets, isEmpty);

      view.dispose();
      // The cancel is queued behind the down, not sent ahead of it.
      expect(packets, isEmpty);

      // Let the 200ms debounce timer flush the queued sequence.
      await Future<void>.delayed(const Duration(milliseconds: 250));

      final List<ui.PointerChange> changes = allPointerDataOf(
        packets,
      ).map((ui.PointerData data) => data.change).toList();
      expect(changes, <ui.PointerChange>[
        ui.PointerChange.add,
        ui.PointerChange.down,
        ui.PointerChange.cancel,
        ui.PointerChange.remove,
      ]);
    });
  }, skip: !touchConstructorsSupported);

  group('$AddressBarController switched-mode pointer events', () {
    late EngineFlutterWindow view;
    late List<ui.PointerDataPacket> packets;
    late DomElement child;

    setUp(() {
      ui_web.browser.debugOperatingSystemOverride = ui_web.OperatingSystem.android;
      view = createFullPageView();
      child = createDomElement('div');
      view.dom.rootElement.append(child);
      packets = <ui.PointerDataPacket>[];
      dispatcher.onPointerDataPacket = packets.add;
    });

    tearDown(() {
      dispatcher.onPointerDataPacket = null;
      child.remove();
      view.dispose();
      PointerBinding.debugResetGlobalState();
      ui_web.browser.debugOperatingSystemOverride = null;
    });

    test('touch-type pointer events are dropped by PointerBinding', () {
      child.dispatchEvent(
        createDomPointerEvent('pointerdown', <String, dynamic>{
          'bubbles': true,
          'pointerId': 12,
          'button': 0,
          'buttons': 1,
          'clientX': 10.0,
          'clientY': 10.0,
          'pointerType': 'touch',
        }),
      );

      expect(packets, isEmpty);
    });

    test('touch pointerdown on the root element keeps the focus side effects', () {
      final DomPointerEvent event = createDomPointerEvent('pointerdown', <String, dynamic>{
        'bubbles': true,
        'cancelable': true,
        'pointerId': 13,
        'button': 0,
        'buttons': 1,
        'clientX': 10.0,
        'clientY': 10.0,
        'pointerType': 'touch',
      });
      view.dom.rootElement.dispatchEvent(event);

      expect(packets, isEmpty);
      expect(event.defaultPrevented, isTrue);
    });

    test('mouse pointer events pass through to PointerBinding', () {
      child.dispatchEvent(
        createDomPointerEvent('pointerdown', <String, dynamic>{
          'bubbles': true,
          'pointerId': 1,
          'button': 0,
          'buttons': 1,
          'clientX': 10.0,
          'clientY': 10.0,
          'pointerType': 'mouse',
        }),
      );

      final List<ui.PointerData> data = allPointerDataOf(packets);
      expect(data, isNotEmpty);
      expect(data.last.change, ui.PointerChange.down);
      expect(data.last.kind, ui.PointerDeviceKind.mouse);

      // Release the mouse button so no pointer state leaks into other tests.
      child.dispatchEvent(
        createDomPointerEvent('pointerup', <String, dynamic>{
          'bubbles': true,
          'pointerId': 1,
          'button': 0,
          'buttons': 0,
          'clientX': 10.0,
          'clientY': 10.0,
          'pointerType': 'mouse',
        }),
      );
    });
  });

  group('$AddressBarController semantics integration', () {
    final testTime = DateTime(2018, 12, 17);
    late EngineFlutterWindow view;
    late List<ui.PointerChange> pointerChanges;
    late List<({ui.SemanticsAction type, int nodeId})> semanticsActions;

    setUp(() {
      ui_web.browser.debugOperatingSystemOverride = ui_web.OperatingSystem.android;
      view = createFullPageView();
      pointerChanges = <ui.PointerChange>[];
      semanticsActions = <({ui.SemanticsAction type, int nodeId})>[];
      dispatcher.onPointerDataPacket = (ui.PointerDataPacket packet) {
        for (final ui.PointerData data in packet.data) {
          pointerChanges.add(data.change);
        }
      };
      dispatcher.onSemanticsActionEvent = (ui.SemanticsActionEvent event) {
        semanticsActions.add((type: event.type, nodeId: event.nodeId));
      };
      EngineSemantics.instance
        ..debugOverrideTimestampFunction(() => testTime)
        ..semanticsEnabled = true;
    });

    tearDown(() {
      EngineSemantics.instance.semanticsEnabled = false;
      dispatcher.onPointerDataPacket = null;
      dispatcher.onSemanticsActionEvent = null;
      view.dispose();
      PointerBinding.debugResetGlobalState();
      ui_web.browser.debugOperatingSystemOverride = null;
    });

    test('a touch tap on a tappable node sends one tap action and no pointer events', () async {
      final DomElement tappable = createDomElement('flt-semantics');
      tappable.setAttribute('flt-tappable', '');
      view.dom.semanticsHost.appendChild(tappable);

      dispatchTouch(tappable, 'touchstart', 61);
      // The ClickDebouncer starts debouncing at the end of the event loop.
      await Future<void>.delayed(Duration.zero);
      expect(PointerBinding.clickDebouncer.isDebouncing, isTrue);

      dispatchTouch(tappable, 'touchend', 61);
      final DomEvent click = createDomMouseEvent('click', <Object?, Object?>{
        'clientX': 10,
        'clientY': 10,
      });
      PointerBinding.clickDebouncer.onClick(click, view.viewId, 42, true);

      expect(semanticsActions, <({ui.SemanticsAction type, int nodeId})>[
        (type: ui.SemanticsAction.tap, nodeId: 42),
      ]);
      // The debounced touch-derived pointer events were dropped in favor of
      // the tap action, so the button is not activated twice.
      expect(pointerChanges, isEmpty);
    });

    test('touch events flip the gesture mode to pointerEvents', () {
      final DomElement root = view.dom.rootElement;
      EngineSemantics.instance.debugResetGestureMode();
      expect(EngineSemantics.instance.gestureMode, GestureMode.browserGestures);

      dispatchTouch(root, 'touchstart', 71);

      expect(EngineSemantics.instance.gestureMode, GestureMode.pointerEvents);

      dispatchTouch(root, 'touchend', 71);
    });
  }, skip: !touchConstructorsSupported);
}

List<ui.PointerData> allPointerDataOf(List<ui.PointerDataPacket> packets) =>
    packets.expand((ui.PointerDataPacket packet) => packet.data).toList();
