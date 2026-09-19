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
/// constructors. The browsers this code path targets, mobile Safari and mobile
/// Chrome, both do.
final bool touchConstructorsSupported =
    globalContext.has('Touch') && globalContext.has('TouchEvent');

EnginePlatformDispatcher get dispatcher => EnginePlatformDispatcher.instance;

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  EngineFlutterWindow createFullPageView() => EngineFlutterView.implicit(dispatcher, null);

  void dispatchTouch(DomElement target, String type, int identifier, {double y = 10}) {
    final DomTouch touch = createDomTouch(<String, dynamic>{
      'identifier': identifier,
      'target': target,
      'clientX': 10,
      'clientY': y,
    });
    target.dispatchEvent(
      DomTouchEvent(
        type,
        <String, dynamic>{
          'bubbles': true,
          'changedTouches': <DomTouch>[touch],
        }.toJSAnyDeep,
      ),
    );
  }

  DomPointerEvent createPointer(String type, {double y = 10, String pointerType = 'touch'}) {
    return createDomPointerEvent(type, <String, dynamic>{
      'bubbles': true,
      'cancelable': true,
      'pointerId': 1,
      'pointerType': pointerType,
      'button': 0,
      'buttons': 1,
      'clientX': 10,
      'clientY': y,
      'pressure': 0.5,
    });
  }

  DomElement? findSpacer() => domDocument.documentElement!.querySelector('flt-scroll-spacer');

  group('$AddressBarController lifecycle', () {
    EngineFlutterView? view;

    // Dispose through tearDown so a failing expectation cannot leak the spacer
    // into the following tests.
    tearDown(() {
      view?.dispose();
      PointerBinding.debugResetGlobalState();
      view = null;
      ui_web.browser.debugOperatingSystemOverride = null;
    });

    test('does nothing outside Android and iOS', () {
      for (final ui_web.OperatingSystem os in ui_web.OperatingSystem.values) {
        if (os == ui_web.OperatingSystem.android || os == ui_web.OperatingSystem.iOs) {
          continue;
        }
        ui_web.browser.debugOperatingSystemOverride = os;
        view = createFullPageView();

        expect(findSpacer(), isNull, reason: '$os');
        expect(domDocument.body!.style.getPropertyValue('touch-action'), 'none', reason: '$os');

        view!.dispose();
        PointerBinding.debugResetGlobalState();
        view = null;
      }
    });

    test('does nothing for a custom element view, even on mobile', () {
      ui_web.browser.debugOperatingSystemOverride = ui_web.OperatingSystem.android;
      final DomElement host = createDomHTMLDivElement();
      domDocument.body!.append(host);
      addTearDown(() => host.remove());
      view = EngineFlutterView(dispatcher, host);

      expect(findSpacer(), isNull);
    });

    test('makes the page scrollable, with a snap target', () {
      ui_web.browser.debugOperatingSystemOverride = ui_web.OperatingSystem.android;
      view = createFullPageView();

      expect(domDocument.body!.style.overflowY, 'auto');
      expect(domDocument.body!.style.getPropertyValue('touch-action'), 'pan-y');
      expect(domDocument.body!.style.height, '100vh');

      final DomElement? spacer = findSpacer();
      expect(spacer, isNotNull);
      expect(spacer!.children, hasLength(1));
      expect(spacer.children.single.style.getPropertyValue('scroll-snap-align'), 'start');
    });

    test('snaps by proximity on Android and mandatorily on iOS', () {
      // `proximity` is the default strictness, so the browser drops it when
      // serializing `y proximity`, leaving `y`.
      ui_web.browser.debugOperatingSystemOverride = ui_web.OperatingSystem.android;
      view = createFullPageView();
      expect(domDocument.documentElement!.style.getPropertyValue('scroll-snap-type'), 'y');

      view!.dispose();
      PointerBinding.debugResetGlobalState();
      ui_web.browser.debugOperatingSystemOverride = ui_web.OperatingSystem.iOs;
      view = createFullPageView();
      expect(
        domDocument.documentElement!.style.getPropertyValue('scroll-snap-type'),
        'y mandatory',
      );
    });
  });

  group('$AddressBarController touch input pipeline', () {
    late EngineFlutterWindow view;
    late DomElement root;
    late double dpr;
    late List<ui.PointerDataPacket> packets;

    setUp(() {
      ui_web.browser.debugOperatingSystemOverride = ui_web.OperatingSystem.android;
      view = createFullPageView();
      root = view.dom.rootElement;
      dpr = view.devicePixelRatio;
      packets = <ui.PointerDataPacket>[];
      dispatcher.onPointerDataPacket = packets.add;
    });

    tearDown(() {
      dispatcher.onPointerDataPacket = null;
      view.dispose();
      PointerBinding.debugResetGlobalState();
      ui_web.browser.debugOperatingSystemOverride = null;
    });

    test('a tap produces a touch-kind pointer sequence', () {
      dispatchTouch(root, 'touchstart', 7, y: 20);
      dispatchTouch(root, 'touchend', 7, y: 20);

      final List<ui.PointerData> data = allPointerDataOf(packets);
      expect(data.map((ui.PointerData d) => d.change), <ui.PointerChange>[
        ui.PointerChange.add,
        ui.PointerChange.down,
        ui.PointerChange.up,
        ui.PointerChange.remove,
      ]);
      expect(data[1].kind, ui.PointerDeviceKind.touch);
      expect(data[1].device, 7);
      expect(data[1].physicalX, 10 * dpr);
      expect(data[1].physicalY, 20 * dpr);
    });

    test('touchmove carries the movement where no raw update arrives', () {
      // Safari does not implement `pointerrawupdate`.
      dispatchTouch(root, 'touchstart', 13);
      dispatchTouch(root, 'touchmove', 13, y: 30);

      expect(movesOf(packets), hasLength(1));
      expect(movesOf(packets).single.physicalY, 30 * dpr);
    });

    test('a raw update takes the contact over from touchmove', () {
      // Both report the same movement, the `touchmove` late.
      dispatchTouch(root, 'touchstart', 14);
      root.dispatchEvent(createPointer('pointerrawupdate', y: 30));
      dispatchTouch(root, 'touchmove', 14, y: 30);

      expect(movesOf(packets), hasLength(1));
      expect(movesOf(packets).single.physicalY, 30 * dpr);
    });

    test('movement outlives the pointercancel the browser fires', () {
      // Under `pan-y` the browser takes a vertical drag over and cancels the
      // pointer. `pointermove` stops there; `pointerrawupdate` does not.
      dispatchTouch(root, 'touchstart', 12);
      root.dispatchEvent(createPointer('pointercancel', y: 20));
      root.dispatchEvent(createPointer('pointerrawupdate', y: 40));

      expect(movesOf(packets), hasLength(1));
      expect(movesOf(packets).single.physicalY, 40 * dpr);
    });

    test('positions do not skew by the page scroll offset', () {
      // The spacer keeps the page scrolled away from 0 on devices.
      domDocument.documentElement!.scrollTop = 60;
      addTearDown(() {
        domDocument.documentElement!.scrollTop = 0;
      });

      dispatchTouch(root, 'touchstart', 81, y: 20);
      final ui.PointerData down = allPointerDataOf(packets).last;
      expect(down.physicalX, 10 * dpr);
      expect(down.physicalY, 20 * dpr);
    });

    test('touch events flip the gesture mode to pointerEvents', () {
      EngineSemantics.instance.debugResetGestureMode();
      addTearDown(EngineSemantics.instance.debugResetGestureMode);
      expect(EngineSemantics.instance.gestureMode, GestureMode.browserGestures);

      dispatchTouch(root, 'touchstart', 71);

      expect(EngineSemantics.instance.gestureMode, GestureMode.pointerEvents);
    });
  }, skip: !touchConstructorsSupported);

  group('$AddressBarController switched-mode pointer events', () {
    late EngineFlutterWindow view;
    late DomElement child;
    late List<ui.PointerDataPacket> packets;

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

    test('touch pointer events are withheld from PointerBinding, not from the view', () {
      final received = <String>[];
      child.addEventListener(
        'pointerdown',
        createDomEventListener((DomEvent event) => received.add(event.type)),
      );

      child.dispatchEvent(createPointer('pointerdown'));

      // Platform views and native text fields are descendants of the view root,
      // so the interception has to run after them.
      expect(received, <String>['pointerdown']);
      expect(packets, isEmpty);
    });

    test('mouse pointer events pass through to PointerBinding', () {
      child.dispatchEvent(createPointer('pointerdown', pointerType: 'mouse'));

      final List<ui.PointerData> data = allPointerDataOf(packets);
      expect(data, isNotEmpty);
      expect(data.last.change, ui.PointerChange.down);
      expect(data.last.kind, ui.PointerDeviceKind.mouse);
    });
  });
}

List<ui.PointerData> allPointerDataOf(List<ui.PointerDataPacket> packets) =>
    packets.expand((ui.PointerDataPacket packet) => packet.data).toList();

List<ui.PointerData> movesOf(List<ui.PointerDataPacket> packets) => allPointerDataOf(
  packets,
).where((ui.PointerData data) => data.change == ui.PointerChange.move).toList();
