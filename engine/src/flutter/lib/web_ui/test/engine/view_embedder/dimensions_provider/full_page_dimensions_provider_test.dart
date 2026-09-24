// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui show Size;

void main() {
  internalBootstrapBrowserTest(() => doTests);
}

void doTests() {
  group('computePhysicalSize', () {
    late FullPageDimensionsProvider provider;

    setUp(() {
      provider = FullPageDimensionsProvider();
    });

    test('returns visualViewport physical size (width * dpr)', () {
      const dpr = 2.5;
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(dpr);
      final expected = ui.Size(
        domWindow.visualViewport!.width! * dpr,
        domWindow.visualViewport!.height! * dpr,
      );

      final ui.Size computed = provider.computePhysicalSize();

      expect(computed, expected);
    });
  });

  group('computeKeyboardInsets', () {
    late FullPageDimensionsProvider provider;

    setUp(() {
      provider = FullPageDimensionsProvider();
    });

    test('from viewport physical size (simulated keyboard)', () {
      // Simulate a 100px tall keyboard showing...
      const dpr = 2.5;
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(dpr);
      const double keyboardGap = 100;
      final double physicalHeight = (domWindow.visualViewport!.height! + keyboardGap) * dpr;
      const double expectedBottom = keyboardGap * dpr;

      final ViewPadding computed = provider.computeKeyboardInsets(physicalHeight, false);

      expect(computed.top, 0);
      expect(computed.right, 0);
      expect(computed.bottom, expectedBottom);
      expect(computed.left, 0);
    });
  });

  group('computeSafeAreaInsets', () {
    late FullPageDimensionsProvider provider;

    setUp(() {
      // Start from a page with no viewport meta tag at all, so leftovers from
      // other tests can't influence the result.
      for (final DomElement meta in domDocument.head!.querySelectorAll('meta[name="viewport"]')) {
        meta.remove();
      }
      provider = FullPageDimensionsProvider();
    });

    tearDown(() {
      provider.close();
      for (final DomElement meta in domDocument.head!.querySelectorAll('meta[name="viewport"]')) {
        meta.remove();
      }
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(null);
    });

    // Leaves the page in the state that `FullPageEmbeddingStrategy` leaves it
    // in when the app declares `viewport-fit=[fit]` in its `index.html`.
    void declareViewportFit(ViewportFit fit) {
      final DomHTMLMetaElement meta = createDomHTMLMetaElement()
        ..setAttribute('flt-viewport', '')
        ..name = 'viewport'
        ..content =
            'width=device-width, initial-scale=1.0, maximum-scale=5.0, '
            '${fit.descriptor}';
      domDocument.head!.append(meta);
    }

    void optInToFullBleed() => declareViewportFit(ViewportFit.cover);

    // Puts values in the probe that a desktop test browser would never report
    // through `env(safe-area-inset-*)` on its own.
    void simulateSafeArea({
      required double top,
      required double right,
      required double bottom,
      required double left,
    }) {
      provider.safeAreaProbe.style
        ..setProperty('padding-top', '${top}px', 'important')
        ..setProperty('padding-right', '${right}px', 'important')
        ..setProperty('padding-bottom', '${bottom}px', 'important')
        ..setProperty('padding-left', '${left}px', 'important');
    }

    test('returns zero when the app did not opt into a full-bleed layout', () {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(2.5);
      // The values a notched phone reports in landscape.
      simulateSafeArea(top: 44, right: 62, bottom: 20, left: 62);

      final ViewPadding computed = provider.computeSafeAreaInsets();

      expect(computed.top, 0, reason: 'The browser lays the app out within the safe area.');
      expect(computed.right, 0);
      expect(computed.bottom, 0);
      expect(computed.left, 0);
    });

    test('returns zero when the browser reports no safe area', () {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(2.5);
      optInToFullBleed();

      final ViewPadding computed = provider.computeSafeAreaInsets();

      expect(computed.top, 0);
      expect(computed.right, 0);
      expect(computed.bottom, 0);
      expect(computed.left, 0);
    });

    test('returns the env(safe-area-inset-*) values, in physical pixels', () {
      const dpr = 2.5;
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(dpr);
      optInToFullBleed();
      // The values a notched phone reports in landscape.
      simulateSafeArea(top: 44, right: 62, bottom: 20, left: 62);

      final ViewPadding computed = provider.computeSafeAreaInsets();

      expect(computed.top, 44 * dpr);
      expect(computed.right, 62 * dpr);
      expect(computed.bottom, 20 * dpr);
      expect(computed.left, 62 * dpr);
    });

    test('reads the current values every time it is called', () {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);
      optInToFullBleed();
      expect(provider.computeSafeAreaInsets().bottom, 0);

      // Simulate a rotation that brings the home indicator into play.
      simulateSafeArea(top: 0, right: 0, bottom: 34, left: 0);

      expect(provider.computeSafeAreaInsets().bottom, 34);
    });

    test('measures against `env(safe-area-inset-*)`, in a hidden element', () {
      // The values below are what makes the measurement work at all, so they
      // are asserted rather than assumed. `important` keeps a stylesheet of the
      // host page from shadowing them.
      final DomCSSStyleDeclaration style = provider.safeAreaProbe.style;

      expect(style.getPropertyValue('display'), 'none');
      expect(style.getPropertyPriority('display'), 'important');
      for (final side in const <String>['top', 'right', 'bottom', 'left']) {
        expect(style.getPropertyValue('padding-$side'), 'env(safe-area-inset-$side, 0px)');
        expect(style.getPropertyPriority('padding-$side'), 'important');
      }
    });

    test('is not shadowed by an `!important` rule of the host page', () {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);
      optInToFullBleed();
      // Deliberately no `simulateSafeArea` here: overwriting the padding would
      // replace the very declaration under test. The probe keeps the
      // `env(safe-area-inset-*, 0px)` that the production code wrote, which a
      // desktop test browser resolves to the `0px` fallback.
      final DomHTMLStyleElement reset = createDomHTMLStyleElement(null);
      reset.text = '* { padding: 5px !important; }';
      domDocument.head!.append(reset);
      addTearDown(() => reset.remove());

      // 0 rather than 5: the host page's rule lost, so the value still comes
      // from `env()`. This fails if the production declarations stop being
      // `important`.
      expect(provider.computeSafeAreaInsets().bottom, 0);
    });

    test('keeps measuring after the host page detaches the probe', () {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);
      optInToFullBleed();
      simulateSafeArea(top: 0, right: 0, bottom: 34, left: 0);

      // A host page is free to empty <body>, e.g. to take a custom loading
      // indicator down.
      provider.safeAreaProbe.remove();

      expect(provider.computeSafeAreaInsets().bottom, 34);
      expect(provider.safeAreaProbe.isConnected, isTrue);
    });

    test('returns zero for a `viewport-fit` other than cover', () {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);
      simulateSafeArea(top: 44, right: 62, bottom: 20, left: 62);

      for (final fit in <ViewportFit>[ViewportFit.auto, ViewportFit.contain]) {
        for (final DomElement meta in domDocument.head!.querySelectorAll('meta[name="viewport"]')) {
          meta.remove();
        }
        declareViewportFit(fit);

        // `auto` and `contain` are preserved by the engine, but neither asks the
        // browser for a full-bleed layout, so neither unlocks the insets.
        expect(
          provider.computeSafeAreaInsets().bottom,
          0,
          reason: 'viewport-fit=${fit.name} should not report insets.',
        );
      }
    });

    test('reads the opt-in out of the tag that the engine itself writes', () {
      // The gate and the tag are written and read by different classes, so the
      // two halves are pinned together here rather than against a hand-written
      // `content` string.
      final DomHTMLMetaElement authored = createDomHTMLMetaElement()
        ..name = 'viewport'
        ..content = 'width=device-width, initial-scale=1.0, viewport-fit=cover';
      domDocument.head!.append(authored);

      FullPageEmbeddingStrategy();

      final optedIn = FullPageDimensionsProvider();
      addTearDown(optedIn.close);
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);
      optedIn.safeAreaProbe.style.setProperty('padding-bottom', '34px', 'important');

      expect(optedIn.computeSafeAreaInsets().bottom, 34);
    });

    test('reports no insets for a page that never declared `viewport-fit`', () {
      final DomHTMLMetaElement authored = createDomHTMLMetaElement()
        ..name = 'viewport'
        ..content = 'width=device-width, initial-scale=1.0';
      domDocument.head!.append(authored);

      FullPageEmbeddingStrategy();

      final notOptedIn = FullPageDimensionsProvider();
      addTearDown(notOptedIn.close);
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);
      notOptedIn.safeAreaProbe.style.setProperty('padding-bottom', '34px', 'important');

      expect(notOptedIn.computeSafeAreaInsets().bottom, 0);
    });

    test('cleans up its probe element when closed', () {
      expect(provider.safeAreaProbe.isConnected, isTrue);

      provider.close();

      expect(provider.safeAreaProbe.isConnected, isFalse);
    });
  });

  group('onResize Stream', () {
    // Needed to synthesize "resize" events
    final DomEventTarget resizeEventTarget = domWindow.visualViewport ?? domWindow;

    late FullPageDimensionsProvider provider;

    setUp(() {
      provider = FullPageDimensionsProvider();
    });

    test('funnels resize events on resizeEventTarget', () {
      final Future<Object?> event = provider.onResize.first;

      final Future<List<Object?>> events = provider.onResize.take(3).toList();

      resizeEventTarget.dispatchEvent(createDomEvent('Event', 'resize'));
      resizeEventTarget.dispatchEvent(createDomEvent('Event', 'resize'));
      resizeEventTarget.dispatchEvent(createDomEvent('Event', 'resize'));

      expect(event, completes);
      expect(events, completes);
      expect(events, completion(hasLength(3)));
    });

    test('closed by onHotRestart', () {
      // Register an onDone listener for the stream
      final completer = Completer<bool>();
      provider.onResize.listen(
        null,
        onDone: () {
          completer.complete(true);
        },
      );

      // Should close the stream
      provider.close();

      resizeEventTarget.dispatchEvent(createDomEvent('Event', 'resize'));

      expect(provider.onResize.isEmpty, completion(isTrue));
      expect(completer.future, completion(isTrue));
    });
  });
}
