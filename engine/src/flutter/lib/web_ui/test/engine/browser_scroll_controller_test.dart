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

  group('findPlatformViewAtPoint', () {
    test('returns null when no platform views exist', () {
      final DomElement? result = controller.findPlatformViewAtPoint(100, 100);
      expect(result, isNull);
    });

    test('returns null when point is outside all platform views', () {
      final DomElement pvElement = createDomHTMLDivElement();
      pvElement.style
        ..width = '100px'
        ..height = '100px'
        ..position = 'absolute'
        ..left = '0px'
        ..top = '0px';
      view.dom.platformViewsHost.append(pvElement);

      final DomElement? result = controller.findPlatformViewAtPoint(9999, 9999);
      expect(result, isNull);
    });

    test('finds platform view at given coordinates', () {
      final DomElement pvElement = createDomHTMLDivElement();
      pvElement.style
        ..width = '200px'
        ..height = '200px'
        ..position = 'absolute'
        ..left = '0px'
        ..top = '0px';
      view.dom.platformViewsHost.append(pvElement);

      final DomRect rect = pvElement.getBoundingClientRect();
      if (rect.width > 0 && rect.height > 0) {
        final DomElement? result = controller.findPlatformViewAtPoint(
          rect.left + 10,
          rect.top + 10,
        );
        expect(result, pvElement);
      }
    });

    test('ignores zero-size elements', () {
      final DomElement pvElement = createDomHTMLDivElement();
      pvElement.style
        ..width = '0px'
        ..height = '0px';
      view.dom.platformViewsHost.append(pvElement);

      final DomElement? result = controller.findPlatformViewAtPoint(0, 0);
      expect(result, isNull);
    });

    test('selects correct element when multiple PVs exist', () {
      final DomElement pv1 = createDomHTMLDivElement();
      pv1.style
        ..width = '100px'
        ..height = '100px'
        ..position = 'absolute'
        ..left = '0px'
        ..top = '0px';
      view.dom.platformViewsHost.append(pv1);

      final DomElement pv2 = createDomHTMLDivElement();
      pv2.style
        ..width = '100px'
        ..height = '100px'
        ..position = 'absolute'
        ..left = '200px'
        ..top = '200px';
      view.dom.platformViewsHost.append(pv2);

      final DomRect rect2 = pv2.getBoundingClientRect();
      if (rect2.width > 0 && rect2.height > 0) {
        final DomElement? result = controller.findPlatformViewAtPoint(
          rect2.left + 10,
          rect2.top + 10,
        );
        expect(result, pv2);
      }
    });
  });

  group('handlePlatformViewWheel', () {
    test('does not throw when target has no scrollable', () {
      final DomElement pvElement = createDomHTMLDivElement();
      pvElement.style
        ..width = '200px'
        ..height = '200px';
      view.dom.platformViewsHost.append(pvElement);

      controller.handlePlatformViewWheel(pvElement, 50);
    });

    test('scrolls inner scrollable when it has overflow content', () {
      final DomElement pvElement = createDomHTMLDivElement();
      pvElement.style
        ..width = '200px'
        ..height = '100px';

      final DomElement scrollableDiv = createDomHTMLDivElement();
      scrollableDiv.style
        ..width = '100%'
        ..height = '100%'
        ..overflow = 'auto';

      final DomElement tallContent = createDomHTMLDivElement();
      tallContent.style.height = '500px';
      scrollableDiv.append(tallContent);
      pvElement.append(scrollableDiv);
      view.dom.platformViewsHost.append(pvElement);

      controller.handlePlatformViewWheel(pvElement, 30);
    });

    test('walks down to find scrollable descendant', () {
      final DomElement pvElement = createDomHTMLDivElement();
      pvElement.style
        ..width = '200px'
        ..height = '100px';

      final DomElement wrapper = createDomHTMLDivElement();
      wrapper.style
        ..width = '100%'
        ..height = '100%';

      final DomElement scrollableDiv = createDomHTMLDivElement();
      scrollableDiv.style
        ..width = '100%'
        ..height = '100%'
        ..overflow = 'auto';

      final DomElement tallContent = createDomHTMLDivElement();
      tallContent.style.height = '500px';
      scrollableDiv.append(tallContent);
      wrapper.append(scrollableDiv);
      pvElement.append(wrapper);
      view.dom.platformViewsHost.append(pvElement);

      controller.handlePlatformViewWheel(pvElement, 30);
    });
  });

  group('containingPlatformView', () {
    test('returns the direct child of pvHost that contains a leaf target', () {
      final DomElement pvHost = view.dom.platformViewsHost;
      final DomElement pv = createDomHTMLDivElement();
      final DomElement inner = createDomHTMLDivElement();
      final DomElement leaf = createDomHTMLDivElement();
      inner.append(leaf);
      pv.append(inner);
      pvHost.append(pv);

      expect(controller.containingPlatformView(leaf, pvHost), pv);
    });

    test('returns the pv itself when target is the pv', () {
      final DomElement pvHost = view.dom.platformViewsHost;
      final DomElement pv = createDomHTMLDivElement();
      pvHost.append(pv);

      expect(controller.containingPlatformView(pv, pvHost), pv);
    });

    test('returns null when target is outside any platform view', () {
      final DomElement pvHost = view.dom.platformViewsHost;
      final DomElement stray = createDomHTMLDivElement();
      domDocument.body!.append(stray);

      expect(controller.containingPlatformView(stray, pvHost), isNull);

      stray.remove();
    });

    test('selects the containing pv, not a sibling pv', () {
      // Regression: previously the touch-start fallback walked all of
      // pvHost, which could return a scrollable from a different platform
      // view than the one the user actually touched. This test guards the
      // scoping helper so touches on pvA resolve to pvA, not pvB.
      final DomElement pvHost = view.dom.platformViewsHost;

      final DomElement pvA = createDomHTMLDivElement();
      final DomElement pvALeaf = createDomHTMLDivElement();
      pvA.append(pvALeaf);
      pvHost.append(pvA);

      final DomElement pvB = createDomHTMLDivElement();
      pvHost.append(pvB);

      expect(controller.containingPlatformView(pvALeaf, pvHost), pvA);
      expect(controller.containingPlatformView(pvB, pvHost), pvB);
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

  // Regression tests that require a FullPageEmbeddingStrategy, because only
  // that strategy returns `supportsBrowserScrolling == true` and actually
  // attaches the platform-view touch-chaining listeners in `enable()`.
  // Full-page setup mutates <body> styles, so each test here saves and
  // restores them to avoid cross-test contamination.
  group('full-page: enable/disable cycle cleanup', () {
    late EngineFlutterView fullPageView;
    late BrowserScrollController fullPageController;
    late Map<String, String> savedBodyStyles;

    setUp(() {
      savedBodyStyles = {};
      for (final prop in const [
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
      // Null hostElement -> FullPageEmbeddingStrategy under the hood.
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

    test('disable removes capture-phase platform-view touchstart listener', () {
      // Add a platform-view child so `isPlatformViewTarget` returns true
      // for events dispatched from it.
      final DomElement pvElement = createDomHTMLDivElement();
      pvElement.style
        ..width = '100px'
        ..height = '100px';
      fullPageView.dom.platformViewsHost.append(pvElement);

      // Attach then detach the platform-view touch chaining listeners.
      fullPageController.enable();
      fullPageController.disable();

      // If `_detachPlatformViewTouchChaining` fails to match the capture
      // flag in `removeEventListener`, the touchstart capture listener
      // is still attached and would fire on this synthetic event,
      // latching `_pvTouchActive = true` on the controller.
      pvElement.dispatchEvent(createDomEvent('Event', 'touchstart'));

      // Re-enable and provide a content height so scrolling is possible.
      fullPageController.enable();
      fullPageController.updateContentHeight(2000);

      // `scrollTo` is a no-op while `_pvTouchActive` is true. If the
      // stale listener fired above, scrollTop stays 0. With a correct
      // remove, `_pvTouchActive` was never set, so scrollTo succeeds.
      fullPageController.scrollTo(100);

      expect(
        fullPageView.dom.rootElement.scrollTop,
        greaterThan(0),
        reason:
            'scrollTo was blocked by a leaked _pvTouchActive=true from a '
            'stale capture-phase touchstart listener. Check that '
            '_detachPlatformViewTouchChaining passes capture=true to '
            'removeEventListener so it matches the addEventListener call.',
      );
    });
  });
}
