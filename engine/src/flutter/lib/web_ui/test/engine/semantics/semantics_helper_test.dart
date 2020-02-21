// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;

import 'package:ui/src/engine.dart';

import 'package:test/test.dart';

void main() {
  group('$DesktopSemanticsEnabler', () {
    DesktopSemanticsEnabler desktopSemanticsEnabler;
    html.Element _placeholder;

    setUp(() {
      desktopSemanticsEnabler = DesktopSemanticsEnabler();
    });

    tearDown(() {
      if (_placeholder != null) {
        _placeholder.remove();
      }
      if (desktopSemanticsEnabler?.semanticsActivationTimer != null) {
        desktopSemanticsEnabler.semanticsActivationTimer.cancel();
        desktopSemanticsEnabler.semanticsActivationTimer = null;
      }
    });

    test('prepare accesibility placeholder', () async {
      _placeholder = desktopSemanticsEnabler.prepareAccesibilityPlaceholder();

      expect(_placeholder.getAttribute('role'), 'button');
      expect(_placeholder.getAttribute('aria-live'), 'true');
      expect(_placeholder.getAttribute('tabindex'), '0');

      html.document.body.append(_placeholder);

      expect(html.document.getElementsByTagName('flt-semantics-placeholder'),
          isNotEmpty);

      expect(_placeholder.getBoundingClientRect().height, 1);
      expect(_placeholder.getBoundingClientRect().width, 1);
      expect(_placeholder.getBoundingClientRect().top, -1);
      expect(_placeholder.getBoundingClientRect().left, -1);
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50590
        skip: browserEngine == BrowserEngine.webkit);

    test('Not relevant events should be forwarded to the framework', () async {
      // Prework. Attach the placeholder to dom.
      _placeholder = desktopSemanticsEnabler.prepareAccesibilityPlaceholder();
      html.document.body.append(_placeholder);

      html.Event event = html.MouseEvent('mousemove');
      bool shouldForwardToFramework =
          desktopSemanticsEnabler.tryEnableSemantics(event);

      expect(shouldForwardToFramework, true);

      // Pointer events are not defined in webkit.
      if (browserEngine != BrowserEngine.webkit) {
        event = html.PointerEvent('pointermove');
        shouldForwardToFramework =
            desktopSemanticsEnabler.tryEnableSemantics(event);

        expect(shouldForwardToFramework, true);
      }
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50754
        skip: browserEngine == BrowserEngine.edge);

    test(
        'Relevants events targeting placeholder should not be forwarded to the framework',
        () async {
      // Prework. Attach the placeholder to dom.
      _placeholder = desktopSemanticsEnabler.prepareAccesibilityPlaceholder();
      html.document.body.append(_placeholder);

      html.Event event = html.MouseEvent('mousedown');
      _placeholder.dispatchEvent(event);

      bool shouldForwardToFramework =
          desktopSemanticsEnabler.tryEnableSemantics(event);

      expect(shouldForwardToFramework, false);
    });

    test(
        'After max number of relevant events, events should be forwarded to the framework',
        () async {
      // Prework. Attach the placeholder to dom.
      _placeholder = desktopSemanticsEnabler.prepareAccesibilityPlaceholder();
      html.document.body.append(_placeholder);

      html.Event event = html.MouseEvent('mousedown');
      _placeholder.dispatchEvent(event);

      bool shouldForwardToFramework =
          desktopSemanticsEnabler.tryEnableSemantics(event);

      expect(shouldForwardToFramework, false);

      // Send max number of events;
      for (int i = 1; i <= kMaxSemanticsActivationAttempts; i++) {
        event = html.MouseEvent('mousedown');
        _placeholder.dispatchEvent(event);

        shouldForwardToFramework =
            desktopSemanticsEnabler.tryEnableSemantics(event);
      }

      expect(shouldForwardToFramework, true);
    });
  });

  group('$MobileSemanticsEnabler', () {
    MobileSemanticsEnabler mobileSemanticsEnabler;
    html.Element _placeholder;

    setUp(() {
      mobileSemanticsEnabler = MobileSemanticsEnabler();
    });

    tearDown(() {
      if (_placeholder != null) {
        _placeholder.remove();
      }
    });

    test('prepare accesibility placeholder', () async {
      _placeholder = mobileSemanticsEnabler.prepareAccesibilityPlaceholder();

      expect(_placeholder.getAttribute('role'), 'button');

      html.document.body.append(_placeholder);

      // Placeholder should cover all the screen on a mobile device.
      final num bodyHeight = html.window.innerHeight;
      final num bodyWidht = html.window.innerWidth;

      expect(_placeholder.getBoundingClientRect().height, bodyHeight);
      expect(_placeholder.getBoundingClientRect().width, bodyWidht);
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50590
        skip: browserEngine == BrowserEngine.webkit);

    test('Not relevant events should be forwarded to the framework', () async {
      final html.Event event = html.TouchEvent('touchcancel');
      bool shouldForwardToFramework =
          mobileSemanticsEnabler.tryEnableSemantics(event);

      expect(shouldForwardToFramework, true);
    },
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50590
        // TODO(nurhan): https://github.com/flutter/flutter/issues/46638
        // TODO(nurhan): https://github.com/flutter/flutter/issues/50754
        skip: browserEngine != BrowserEngine.blink);
  });
}
