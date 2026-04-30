// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  late EngineFlutterView view;
  late BrowserScrollController controller;
  late DomElement hostElement;

  setUp(() {
    hostElement = createDomHTMLDivElement();
    domDocument.body!.append(hostElement);
    view = EngineFlutterView(EnginePlatformDispatcher.instance, hostElement);
    controller = view.browserScrollController;
  });

  tearDown(() {
    view.dispose();
    hostElement.remove();
  });

  group('enable/disable', () {
    test('starts disabled', () {
      expect(controller.enabled, isFalse);
    });

    test('does not enable when strategy does not support it', () {
      controller.enable();
      expect(controller.enabled, isFalse);
    });

    test('disable when already disabled is a no-op', () {
      controller.disable();
      expect(controller.enabled, isFalse);
    });
  });

  group('dispose', () {
    test('disable is called on dispose', () {
      controller.dispose();
      expect(controller.enabled, isFalse);
    });

    test('can dispose when already disabled', () {
      controller.dispose();
      controller.dispose();
      expect(controller.enabled, isFalse);
    });
  });

  // The full-page strategy is the only one that returns
  // supportsBrowserScrolling == true, so the controller's actual scroll
  // listener wiring and notification contract can only be exercised here.
  // Body styles get mutated by enableBrowserScrolling, so each test saves
  // and restores them to avoid cross-test contamination.
  group('full-page', () {
    late EngineFlutterView fullPageView;
    late BrowserScrollController fullPageController;
    late Map<String, String> savedBodyStyles;

    setUp(() {
      savedBodyStyles = <String, String>{};
      for (final prop in const <String>[
        'position',
        'top',
        'right',
        'bottom',
        'left',
        'overflow',
        'padding',
        'margin',
        'width',
        'height',
        'touch-action',
        'user-select',
        '-webkit-user-select',
      ]) {
        savedBodyStyles[prop] = domDocument.body!.style.getPropertyValue(prop);
      }
      // Null hostElement -> FullPageEmbeddingStrategy.
      fullPageView = EngineFlutterView.implicit(EnginePlatformDispatcher.instance, null);
      fullPageController = fullPageView.browserScrollController;
    });

    tearDown(() {
      fullPageView.dispose();
      for (final MapEntry<String, String> entry in savedBodyStyles.entries) {
        if (entry.value.isEmpty) {
          domDocument.body!.style.removeProperty(entry.key);
        } else {
          domDocument.body!.style.setProperty(entry.key, entry.value);
        }
      }
    });

    test('enable activates browser scrolling on full-page view', () {
      expect(fullPageController.enabled, isFalse);
      fullPageController.enable();
      expect(fullPageController.enabled, isTrue);
      // The strategy makes flutter-view the scrollable element.
      expect(fullPageView.dom.rootElement.style.overflow, 'auto');
    });

    test('updateContentHeight sets placeholder height', () {
      fullPageController.enable();
      final DomElement? placeholder = fullPageView.dom.rootElement.querySelector(
        '[flt-scroll-placeholder]',
      );
      expect(placeholder, isNotNull);

      fullPageController.updateContentHeight(3000);
      expect(placeholder!.style.height, '3000px');
    });

    test('scroll event invokes onBrowserScroll callback', () {
      fullPageController.enable();
      fullPageController.updateContentHeight(3000);

      final received = <double>[];
      fullPageView.onBrowserScroll = received.add;

      // Simulate the browser firing a scroll event after a user-driven move.
      fullPageView.dom.rootElement.scrollTop = 150;
      fullPageView.dom.rootElement.dispatchEvent(createDomEvent('Event', 'scroll'));

      expect(received, hasLength(1));
      expect(received.first, closeTo(150, 0.5));
    });

    test('scrollTo writes scrollTop and notifies framework directly', () async {
      fullPageController.enable();
      fullPageController.updateContentHeight(3000);

      final received = <double>[];
      fullPageView.onBrowserScroll = received.add;

      fullPageController.scrollTo(150);

      // The direct notification fires synchronously, so the framework's
      // ScrollPosition.pixels stays in sync even though the browser's echo
      // scroll event is suppressed.
      expect(received, hasLength(1));
      expect(received.first, closeTo(150, 0.5));
      expect(fullPageView.dom.rootElement.scrollTop, closeTo(150, 0.5));

      // Flush the queue to confirm the browser's echoed scroll event does
      // not double-notify.
      await Future<void>.delayed(Duration.zero);
      expect(received, hasLength(1));
    });

    test('scrollBy writes scrollTop and notifies framework', () {
      fullPageController.enable();
      fullPageController.updateContentHeight(3000);
      fullPageController.scrollTo(100);

      final received = <double>[];
      fullPageView.onBrowserScroll = received.add;

      fullPageController.scrollBy(50);

      expect(received, hasLength(1));
      expect(received.first, closeTo(150, 0.5));
      expect(fullPageView.dom.rootElement.scrollTop, closeTo(150, 0.5));
    });

    test('disable removes scroll listener', () {
      fullPageController.enable();
      fullPageController.updateContentHeight(3000);
      fullPageController.disable();

      final received = <double>[];
      fullPageView.onBrowserScroll = received.add;

      fullPageView.dom.rootElement.scrollTop = 150;
      fullPageView.dom.rootElement.dispatchEvent(createDomEvent('Event', 'scroll'));

      expect(received, isEmpty);
    });
  });
}
