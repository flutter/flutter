// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web/web.dart' as web;
import 'package:web_e2e_tests/webdriver_pointer_actions_main.dart' as app;

/// The element the implicit view is embedded in.
web.HTMLElement get _hostElement {
  final int viewId = ui.PlatformDispatcher.instance.implicitView!.viewId;
  return ui_web.views.getHostElement(viewId)! as web.HTMLElement;
}

/// Moves the host element so that its top-left corner sits at [origin] in the
/// viewport, emulating an app embedded in a page away from the viewport origin.
///
/// Returns the host element's resulting bounding rect origin.
Offset _offsetHostElement(Offset origin) {
  _hostElement.style
    ..top = '${origin.dy}px'
    ..left = '${origin.dx}px';
  final web.DOMRect rect = _hostElement.getBoundingClientRect();
  return Offset(rect.left, rect.top);
}

void _resetHostElement() {
  _hostElement.style
    ..top = '0'
    ..left = '0';
}

/// Whether the browser hit test at [viewportPosition] lands inside the host
/// element.
bool _isOnHostElement(Offset viewportPosition) {
  final web.Element? hit = web.document.elementFromPoint(viewportPosition.dx, viewportPosition.dy);
  return hit != null && _hostElement.contains(hit);
}

/// Defines a [testWidgets] test that drives real WebDriver pointer actions.
///
/// Semantics are disabled: otherwise a real click on the button lands on its
/// semantics DOM node and taps it via a semantics action, bypassing pointer
/// events entirely.
void _testWebDriverPointerActions(String description, WidgetTesterCallback callback) {
  testWidgets(description, callback, semanticsEnabled: false);
}

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Lets Flutter widgets react to the real pointer events until the end of
  /// the current test.
  void propagateDevicePointerEvents() {
    binding.shouldPropagateDevicePointerEvents = true;
    addTearDown(() {
      binding.shouldPropagateDevicePointerEvents = false;
    });
  }

  Future<void> startApp(WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();
    await app.iframeLoaded.future.timeout(const Duration(seconds: 10));
  }

  _testWebDriverPointerActions(
    'webDriverClick delivers a real browser click to an iframe platform view',
    (WidgetTester tester) async {
      await startApp(tester);
      expect(app.iframeClicks, 0);

      await binding.webDriverClick(tester.getCenter(find.byType(HtmlElementView)));

      expect(app.iframeClicks, 1);
    },
  );

  _testWebDriverPointerActions(
    'webDriverClick reaches Flutter widgets only when device pointer events propagate',
    (WidgetTester tester) async {
      await startApp(tester);
      final Finder button = find.byKey(app.buttonKey);
      expect(binding.shouldPropagateDevicePointerEvents, isFalse);

      // The button sits above the iframe, so the browser delivers the click to
      // the Flutter view, not the iframe. The engine forwards the pointer events
      // to the framework, but the binding drops them because device pointer
      // events do not propagate by default.
      await binding.webDriverClick(tester.getCenter(button));
      await tester.pump();
      expect(app.buttonClicks.value, 0);
      expect(app.iframeClicks, 0);

      // With device pointer events propagating, the same click presses the
      // button.
      propagateDevicePointerEvents();
      await binding.webDriverClick(tester.getCenter(button));
      await tester.pump();

      expect(app.buttonClicks.value, 1);
      expect(find.text('Button clicks: 1'), findsOneWidget);
      expect(app.iframeClicks, 0);
    },
  );

  _testWebDriverPointerActions(
    'webDriverClick converts view positions when the view is offset in the page',
    (WidgetTester tester) async {
      await startApp(tester);
      addTearDown(_resetHostElement);
      expect(_offsetHostElement(const Offset(300, 200)), const Offset(300, 200));
      await tester.pumpAndSettle();
      final Offset buttonCenter = tester.getCenter(find.byKey(app.buttonKey));
      // Interpreted as a viewport position, the view position misses the view.
      expect(_isOnHostElement(buttonCenter), isFalse);
      expect(_isOnHostElement(buttonCenter + const Offset(300, 200)), isTrue);

      propagateDevicePointerEvents();
      await binding.webDriverClick(buttonCenter);
      await tester.pump();

      expect(app.buttonClicks.value, 1);
      expect(find.text('Button clicks: 1'), findsOneWidget);
    },
  );

  _testWebDriverPointerActions(
    'webDriverPointerActions animates a drag across intermediate pointer moves',
    (WidgetTester tester) async {
      await startApp(tester);
      propagateDevicePointerEvents();

      final Offset dragStart = tester.getCenter(find.byKey(app.panAreaKey)) - const Offset(100, 0);
      final Offset dragEnd = dragStart + const Offset(200, 0);

      await binding.webDriverPointerActions(<WebDriverPointerAction>[
        WebDriverPointerAction.move(dragStart.dx, dragStart.dy),
        const WebDriverPointerAction.down(),
        WebDriverPointerAction.move(
          dragEnd.dx,
          dragEnd.dy,
          duration: const Duration(milliseconds: 300),
        ),
        const WebDriverPointerAction.up(),
      ]);
      await tester.pump();

      expect(app.panStarts, 1);
      expect(app.panUpdates.length, greaterThan(1));
      expect(app.panUpdates.any((Offset p) => p.dx > dragStart.dx && p.dx < dragEnd.dx), isTrue);
      expect((app.panUpdates.last - dragEnd).distance, lessThanOrEqualTo(1.0));
      expect(app.panEnds, 1);
      expect(app.iframeClicks, 0);
    },
  );

  _testWebDriverPointerActions(
    'webDriverPointerActions keeps buttons pressed between calls for a split drag',
    (WidgetTester tester) async {
      await startApp(tester);
      propagateDevicePointerEvents();

      final Offset dragStart = tester.getCenter(find.byKey(app.panAreaKey)) - const Offset(50, 0);
      final Offset dragEnd = dragStart + const Offset(100, 0);

      await binding.webDriverPointerActions(<WebDriverPointerAction>[
        WebDriverPointerAction.move(dragStart.dx, dragStart.dy),
        const WebDriverPointerAction.down(),
        WebDriverPointerAction.move(
          dragEnd.dx,
          dragEnd.dy,
          duration: const Duration(milliseconds: 100),
        ),
      ]);
      try {
        await tester.pump();
        expect(app.panStarts, 1);
        expect(app.panUpdates, isNotEmpty);
        expect(app.panEnds, 0);
      } finally {
        await binding.webDriverPointerActions(const <WebDriverPointerAction>[
          WebDriverPointerAction.up(),
        ]);
      }
      await tester.pump();

      expect(app.panEnds, 1);
    },
  );

  _testWebDriverPointerActions(
    'webDriverPointerActions moves the pointer without pressing a button to hover',
    (WidgetTester tester) async {
      await startApp(tester);
      propagateDevicePointerEvents();

      final Offset iframeCenter = tester.getCenter(find.byType(HtmlElementView));
      await binding.webDriverPointerActions(<WebDriverPointerAction>[
        WebDriverPointerAction.move(iframeCenter.dx, iframeCenter.dy),
      ]);
      expect(app.iframeMouseMoves, greaterThan(0));
      expect(app.iframeClicks, 0);

      final Offset hoverCenter = tester.getCenter(find.byKey(app.hoverKey));
      await binding.webDriverPointerActions(<WebDriverPointerAction>[
        WebDriverPointerAction.move(hoverCenter.dx, hoverCenter.dy),
      ]);
      await tester.pump();
      expect(app.hoverEnters, 1);
      expect(app.hoverExits, 0);

      final Offset outsideHover = tester.getCenter(find.byKey(app.panAreaKey));
      await binding.webDriverPointerActions(<WebDriverPointerAction>[
        WebDriverPointerAction.move(outsideHover.dx, outsideHover.dy),
      ]);
      await tester.pump();
      expect(app.hoverEnters, 1);
      expect(app.hoverExits, 1);
      expect(app.buttonClicks.value, 0);
      expect(app.panStarts, 0);
    },
  );
}
