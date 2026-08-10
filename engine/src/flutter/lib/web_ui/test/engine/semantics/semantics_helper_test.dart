// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/browser_detection.dart';
import 'package:ui/src/engine/dom.dart';
import 'package:ui/src/engine/semantics.dart';
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('$DesktopSemanticsEnabler', () {
    late DesktopSemanticsEnabler desktopSemanticsEnabler;
    late DomElement? placeholder;

    setUp(() {
      EngineSemantics.instance.semanticsEnabled = false;
      desktopSemanticsEnabler = DesktopSemanticsEnabler();
      placeholder = desktopSemanticsEnabler.addPlaceholder();
      domDocument.body!.append(placeholder!);
    });

    tearDown(() {
      expect(placeholder, isNotNull, reason: 'Expected the test to create a placeholder');
      placeholder!.remove();
      EngineSemantics.instance.semanticsEnabled = false;
    });

    test('prepare accessibility placeholder', () async {
      expect(placeholder!.getAttribute('role'), 'button');
      expect(placeholder!.getAttribute('aria-live'), 'polite');
      expect(placeholder!.getAttribute('tabindex'), '0');

      domDocument.body!.append(placeholder!);

      expect(domDocument.getElementsByTagName('flt-semantics-placeholder'), isNotEmpty);

      expect(placeholder!.getBoundingClientRect().height, 1);
      expect(placeholder!.getBoundingClientRect().width, 1);
      expect(placeholder!.getBoundingClientRect().top, -1);
      expect(placeholder!.getBoundingClientRect().left, -1);
    });

    test('Not relevant events should be forwarded to the framework', () async {
      // Attach the placeholder to dom.
      domDocument.body!.append(placeholder!);

      DomEvent event = createDomEvent('Event', 'mousemove');
      bool shouldForwardToFramework = desktopSemanticsEnabler.tryEnableSemantics(event);

      expect(shouldForwardToFramework, isTrue);

      // Pointer events are not defined in webkit.
      if (ui_web.browser.browserEngine != ui_web.BrowserEngine.webkit) {
        event = createDomEvent('Event', 'pointermove');
        shouldForwardToFramework = desktopSemanticsEnabler.tryEnableSemantics(event);

        expect(shouldForwardToFramework, isTrue);
      }
    });

    test('Tab key should not enable semantics', () async {
      final testSemanticsEnabler = FakeSemanticsEnabler();

      // Tab should not enable semantics
      {
        final DomKeyboardEvent event = createDomKeyboardEvent('keydown', <String, Object>{
          'key': 'Tab',
        });
        expect(testSemanticsEnabler.shouldEnableSemantics(event), isTrue);
        expect(testSemanticsEnabler.tryEnableSemanticsCallCount, 0);
      }

      // Enter key is allowed to try to enable semantics
      {
        final DomKeyboardEvent event = createDomKeyboardEvent('keydown', <String, Object>{
          'key': 'Enter',
        });
        expect(testSemanticsEnabler.shouldEnableSemantics(event), isFalse);
        expect(testSemanticsEnabler.tryEnableSemanticsCallCount, 1);
      }
    });

    test(
      'Relevant events targeting placeholder should not be forwarded to the framework',
      () async {
        final DomEvent event = createDomEvent('Event', 'mousedown');
        placeholder!.dispatchEvent(event);

        final bool shouldForwardToFramework = desktopSemanticsEnabler.tryEnableSemantics(event);

        expect(shouldForwardToFramework, isFalse);
      },
    );

    test('Can update placeholder label', () {
      const testLabel = 'Test label for placeholder';
      desktopSemanticsEnabler.updatePlaceholderLabel(testLabel);
      expect(placeholder!.getAttribute('aria-label'), testLabel);

      const anotherLabel = 'Another label for placeholder';
      desktopSemanticsEnabler.dispose();
      expect(() => desktopSemanticsEnabler.updatePlaceholderLabel(anotherLabel), returnsNormally);
    });

    test('disposes of the placeholder', () {
      domDocument.body!.append(placeholder!);

      expect(placeholder!.isConnected, isTrue);
      desktopSemanticsEnabler.dispose();
      expect(placeholder!.isConnected, isFalse);
    });

    test('shares one page-level placeholder across views', () {
      // The desktop placeholder must stay out of the <flutter-view> and be the
      // first thing in the body. Once browser focus enters a view, Flutter's
      // focus traversal can consume Tab and never hand it back, which would
      // leave a nested placeholder unreachable by keyboard.
      final enabler = DesktopSemanticsEnabler();
      final DomElement firstView = _createFakeViewElement(left: 0, top: 0, width: 100, height: 80);
      final DomElement secondView = _createFakeViewElement(
        left: 200,
        top: 0,
        width: 100,
        height: 80,
      );

      enabler.addPlaceholderForView(firstView);
      enabler.addPlaceholderForView(secondView);

      expect(enabler.placeholders, hasLength(1));
      final DomElement shared = enabler.placeholders.single;
      expect(shared.parent, domDocument.body);
      expect(domDocument.body!.children.first, shared);
      expect(firstView.querySelector('flt-semantics-placeholder'), isNull);
      expect(secondView.querySelector('flt-semantics-placeholder'), isNull);

      // The placeholder outlives any single view, and goes when the last one
      // does.
      enabler.removePlaceholderForView(firstView);
      expect(shared.isConnected, isTrue);
      enabler.removePlaceholderForView(secondView);
      expect(shared.isConnected, isFalse);
      expect(enabler.placeholders, isEmpty);

      firstView.remove();
      secondView.remove();
    });
  }, skip: isMobile);

  group(
    '$MobileSemanticsEnabler',
    () {
      late MobileSemanticsEnabler mobileSemanticsEnabler;
      DomElement? placeholder;

      setUp(() {
        EngineSemantics.instance.semanticsEnabled = false;
        mobileSemanticsEnabler = MobileSemanticsEnabler();
        placeholder = mobileSemanticsEnabler.addPlaceholder();
        domDocument.body!.append(placeholder!);
      });

      tearDown(() {
        placeholder!.remove();
        EngineSemantics.instance.semanticsEnabled = false;
      });

      test('prepare accessibility placeholder', () async {
        expect(placeholder!.getAttribute('role'), 'button');

        // The placeholder covers the view it is attached to, and nothing
        // beyond it. A placeholder that stretched over the whole page would
        // swallow taps aimed at the HTML content around an embedded view.
        // See https://github.com/flutter/flutter/issues/152838
        final DomElement view = _createFakeViewElement(left: 10, top: 20, width: 200, height: 100);
        view.append(placeholder!);

        final DomRect rect = placeholder!.getBoundingClientRect();
        expect(rect.left, 10);
        expect(rect.top, 20);
        expect(rect.width, 200);
        expect(rect.height, 100);

        view.remove();
      });

      test('puts a placeholder inside each view, and only inside', () {
        // The symptom reported in https://github.com/flutter/flutter/issues/152838:
        // a placeholder stretched over the page is what the browser hit-tests,
        // so taps never reach the host page's own content.
        placeholder!.remove();
        mobileSemanticsEnabler.dispose();

        final DomElement firstView = _createFakeViewElement(
          left: 0,
          top: 200,
          width: 100,
          height: 80,
        );
        final DomElement secondView = _createFakeViewElement(
          left: 200,
          top: 200,
          width: 100,
          height: 80,
        );
        mobileSemanticsEnabler.addPlaceholderForView(firstView);
        mobileSemanticsEnabler.addPlaceholderForView(secondView);

        // One per view, attached by the enabler itself rather than by the test.
        expect(mobileSemanticsEnabler.placeholders, hasLength(2));
        expect(firstView.children.first.tagName.toLowerCase(), 'flt-semantics-placeholder');
        expect(secondView.children.first.tagName.toLowerCase(), 'flt-semantics-placeholder');

        // Neither one reaches the top-left of the page, where host HTML would
        // sit in the reported bug.
        expect(domDocument.elementFromPoint(5, 5), isNot(firstView.children.first));
        expect(domDocument.elementFromPoint(5, 5), isNot(secondView.children.first));

        // Disposing one view leaves the other view's placeholder alone.
        final DomElement secondPlaceholder = secondView.children.first;
        mobileSemanticsEnabler.removePlaceholderForView(firstView);
        expect(mobileSemanticsEnabler.placeholders, <DomElement>[secondPlaceholder]);
        expect(secondPlaceholder.isConnected, isTrue);

        firstView.remove();
        secondView.remove();
      });

      test('registering the same view twice is a no-op', () {
        placeholder!.remove();
        mobileSemanticsEnabler.dispose();

        final DomElement view = _createFakeViewElement(left: 0, top: 0, width: 100, height: 80);
        mobileSemanticsEnabler.addPlaceholderForView(view);
        final DomElement first = mobileSemanticsEnabler.placeholders.single;
        mobileSemanticsEnabler.addPlaceholderForView(view);

        // A second registration must not strand the first placeholder, which
        // would stay tracked and attached with nothing referencing it.
        expect(mobileSemanticsEnabler.placeholders, <DomElement>[first]);
        expect(view.querySelectorAll('flt-semantics-placeholder'), hasLength(1));

        mobileSemanticsEnabler.removePlaceholderForView(view);
        expect(mobileSemanticsEnabler.placeholders, isEmpty);
        expect(first.isConnected, isFalse);

        view.remove();
      });

      test('activates from the placeholder of any view', () {
        // The placeholder created in `setUp` covers the whole page. This one
        // covers a small view away from the page origin, so a tap in the
        // middle of it is only near the center of this second placeholder.
        //
        // The view is deliberately not at (0, 0). The activation point and the
        // placeholder's rect must be compared in the same coordinate system,
        // and a view at the origin would hide a mismatch between the two.
        final DomElement view = _createFakeViewElement(left: 40, top: 60, width: 100, height: 80);
        final DomElement secondPlaceholder = mobileSemanticsEnabler.addPlaceholder();
        view.append(secondPlaceholder);

        expect(mobileSemanticsEnabler.semanticsActivationTimer, isNull);

        final DomRect rect = secondPlaceholder.getBoundingClientRect();
        secondPlaceholder.dispatchEvent(
          createDomMouseEvent('click', <Object?, Object?>{
            'clientX': (rect.left + rect.width / 2).toInt(),
            'clientY': (rect.top + rect.height / 2).toInt(),
          }),
        );
        expect(mobileSemanticsEnabler.semanticsActivationTimer, isNotNull);

        view.remove();
      });

      test('Non-relevant events should be forwarded to the framework', () async {
        final DomEvent event = createDomPointerEvent('pointermove');

        final bool shouldForwardToFramework = mobileSemanticsEnabler.tryEnableSemantics(event);

        expect(shouldForwardToFramework, isTrue);
      });

      test('Can update placeholder label', () {
        const testLabel = 'Test label for placeholder';
        mobileSemanticsEnabler.updatePlaceholderLabel(testLabel);
        expect(placeholder!.getAttribute('aria-label'), testLabel);

        const anotherLabel = 'Another label for placeholder';
        mobileSemanticsEnabler.dispose();
        expect(() => mobileSemanticsEnabler.updatePlaceholderLabel(anotherLabel), returnsNormally);
      });

      test('applies the label to every placeholder, old and new', () {
        // A view created after the app customized the message must still get
        // that message, and updating it later must reach every view.
        const testLabel = 'Test label for placeholder';
        ui_web.accessibilityPlaceholderMessage = testLabel;
        addTearDown(() => ui_web.accessibilityPlaceholderMessage = 'Enable accessibility');

        final DomElement laterPlaceholder = mobileSemanticsEnabler.addPlaceholder();
        expect(laterPlaceholder.getAttribute('aria-label'), testLabel);

        const anotherLabel = 'Another label for placeholder';
        mobileSemanticsEnabler.updatePlaceholderLabel(anotherLabel);
        expect(placeholder!.getAttribute('aria-label'), anotherLabel);
        expect(laterPlaceholder.getAttribute('aria-label'), anotherLabel);
      });

      test('Enables semantics when receiving a relevant event', () {
        expect(mobileSemanticsEnabler.semanticsActivationTimer, isNull);

        // Send a click off center
        // Use fractional coordinates to avoid triggering assistive technology detection logic.
        // The platform dispatcher's _isIntegerCoordinateNavigation() method
        // detects assistive technology clicks by checking for integer coordinates.
        placeholder!.dispatchEvent(
          createDomMouseEvent('click', <Object?, Object?>{'clientX': 0.5, 'clientY': 0.5}),
        );
        expect(mobileSemanticsEnabler.semanticsActivationTimer, isNull);

        // Send a click at center
        final DomRect activatingElementRect = placeholder!.getBoundingClientRect();
        final int midX =
            (activatingElementRect.left +
                    (activatingElementRect.right - activatingElementRect.left) / 2)
                .toInt();
        final int midY =
            (activatingElementRect.top +
                    (activatingElementRect.bottom - activatingElementRect.top) / 2)
                .toInt();
        placeholder!.dispatchEvent(
          createDomMouseEvent('click', <Object?, Object?>{'clientX': midX, 'clientY': midY}),
        );
        expect(mobileSemanticsEnabler.semanticsActivationTimer, isNotNull);
      });
    },
    // We can run `MobileSemanticsEnabler` tests in mobile browsers and in desktop Chrome.
    skip: isDesktop && ui_web.browser.browserEngine != ui_web.BrowserEngine.blink,
  );
}

/// Creates a positioned stand-in for a `<flutter-view>` element and attaches it
/// to the document.
DomElement _createFakeViewElement({
  required int left,
  required int top,
  required int width,
  required int height,
}) {
  final DomElement view = createDomElement('flutter-view');
  view.style
    ..position = 'absolute'
    ..left = '${left}px'
    ..top = '${top}px'
    ..width = '${width}px'
    ..height = '${height}px';
  domDocument.body!.append(view);
  return view;
}

class FakeSemanticsEnabler extends SemanticsEnabler {
  // Forces the "still waiting" state without creating a placeholder, so that
  // `shouldEnableSemantics` reaches `tryEnableSemantics`.
  @override
  bool get isWaitingToEnableSemantics => true;

  @override
  void addPlaceholderForView(DomElement viewRoot) {
    throw UnimplementedError();
  }

  @override
  void removePlaceholderForView(DomElement viewRoot) {
    throw UnimplementedError();
  }

  int tryEnableSemanticsCallCount = 0;

  @override
  bool tryEnableSemantics(DomEvent event) {
    tryEnableSemanticsCallCount += 1;
    return false;
  }
}
