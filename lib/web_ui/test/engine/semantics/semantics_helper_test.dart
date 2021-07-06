// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/browser_detection.dart';
import 'package:ui/src/engine/pointer_binding.dart';
import 'package:ui/src/engine/semantics.dart';

const PointerSupportDetector _defaultSupportDetector = PointerSupportDetector();

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('$DesktopSemanticsEnabler', () {
    late DesktopSemanticsEnabler desktopSemanticsEnabler;
    late html.Element? _placeholder;

    setUp(() {
      EngineSemanticsOwner.instance.semanticsEnabled = false;
      desktopSemanticsEnabler = DesktopSemanticsEnabler();
      _placeholder = desktopSemanticsEnabler.prepareAccessibilityPlaceholder();
      html.document.body!.append(_placeholder!);
    });

    tearDown(() {
      expect(_placeholder, isNotNull,
          reason: 'Expected the test to create a placeholder');
      _placeholder!.remove();
      EngineSemanticsOwner.instance.semanticsEnabled = false;
    });

    test('prepare accesibility placeholder', () async {
      expect(_placeholder!.getAttribute('role'), 'button');
      expect(_placeholder!.getAttribute('aria-live'), 'true');
      expect(_placeholder!.getAttribute('tabindex'), '0');

      html.document.body!.append(_placeholder!);

      expect(html.document.getElementsByTagName('flt-semantics-placeholder'),
          isNotEmpty);

      expect(_placeholder!.getBoundingClientRect().height, 1);
      expect(_placeholder!.getBoundingClientRect().width, 1);
      expect(_placeholder!.getBoundingClientRect().top, -1);
      expect(_placeholder!.getBoundingClientRect().left, -1);
    });

    test('Not relevant events should be forwarded to the framework', () async {
      // Attach the placeholder to dom.
      html.document.body!.append(_placeholder!);

      html.Event event = html.MouseEvent('mousemove');
      bool shouldForwardToFramework =
          desktopSemanticsEnabler.tryEnableSemantics(event);

      expect(shouldForwardToFramework, isTrue);

      // Pointer events are not defined in webkit.
      if (browserEngine != BrowserEngine.webkit) {
        event = html.PointerEvent('pointermove');
        shouldForwardToFramework =
            desktopSemanticsEnabler.tryEnableSemantics(event);

        expect(shouldForwardToFramework, isTrue);
      }
    });

    test(
        'Relevants events targeting placeholder should not be forwarded to the framework',
        () async {
      html.Event event = html.MouseEvent('mousedown');
      _placeholder!.dispatchEvent(event);

      bool shouldForwardToFramework =
          desktopSemanticsEnabler.tryEnableSemantics(event);

      expect(shouldForwardToFramework, isFalse);
    });

    test('disposes of the placeholder', () {
      html.document.body!.append(_placeholder!);

      expect(_placeholder!.isConnected, isTrue);
      desktopSemanticsEnabler.dispose();
      expect(_placeholder!.isConnected, isFalse);
    });
  }, skip: isMobile);

  group(
    '$MobileSemanticsEnabler',
    () {
      late MobileSemanticsEnabler mobileSemanticsEnabler;
      html.Element? _placeholder;

      setUp(() {
        EngineSemanticsOwner.instance.semanticsEnabled = false;
        mobileSemanticsEnabler = MobileSemanticsEnabler();
        _placeholder = mobileSemanticsEnabler.prepareAccessibilityPlaceholder();
        html.document.body!.append(_placeholder!);
      });

      tearDown(() {
        _placeholder!.remove();
        EngineSemanticsOwner.instance.semanticsEnabled = false;
      });

      test('prepare accesibility placeholder', () async {
        expect(_placeholder!.getAttribute('role'), 'button');

        // Placeholder should cover all the screen on a mobile device.
        final num bodyHeight = html.window.innerHeight!;
        final num bodyWidht = html.window.innerWidth!;

        expect(_placeholder!.getBoundingClientRect().height, bodyHeight);
        expect(_placeholder!.getBoundingClientRect().width, bodyWidht);
      });

      test('Non-relevant events should be forwarded to the framework',
          () async {
        html.Event event;
        if (_defaultSupportDetector.hasPointerEvents) {
          event = html.PointerEvent('pointermove');
        } else if (_defaultSupportDetector.hasTouchEvents) {
          event = html.TouchEvent('touchcancel');
        } else {
          event = html.MouseEvent('mousemove');
        }

        bool shouldForwardToFramework =
            mobileSemanticsEnabler.tryEnableSemantics(event);

        expect(shouldForwardToFramework, isTrue);
      });

      test('Enables semantics when receiving a relevant event', () {
        expect(mobileSemanticsEnabler.semanticsActivationTimer, isNull);

        // Send a click off center
        _placeholder!.dispatchEvent(html.MouseEvent(
          'click',
          clientX: 0,
          clientY: 0,
        ));
        expect(mobileSemanticsEnabler.semanticsActivationTimer, isNull);

        // Send a click at center
        final html.Rectangle<num> activatingElementRect =
            _placeholder!.getBoundingClientRect();
        final int midX = (activatingElementRect.left +
                (activatingElementRect.right - activatingElementRect.left) / 2)
            .toInt();
        final int midY = (activatingElementRect.top +
                (activatingElementRect.bottom - activatingElementRect.top) / 2)
            .toInt();
        _placeholder!.dispatchEvent(html.MouseEvent(
          'click',
          clientX: midX,
          clientY: midY,
        ));
        expect(mobileSemanticsEnabler.semanticsActivationTimer, isNotNull);
      });
    },
    // We can run `MobileSemanticsEnabler` tests in mobile browsers and in desktop Chrome.
    skip: isDesktop && browserEngine != BrowserEngine.blink,
  );
}
