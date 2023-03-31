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
  final DomElement rootNode = domDocument.createElement('div');
  domDocument.body!.append(rootNode);

  group('ShadowDomHostNode', () {
    final HostNode hostNode = ShadowDomHostNode(rootNode, '14px monospace');
    final DomElement renderHost = domDocument.querySelector('flt-render-host')!;

    test('Initializes and attaches a shadow root', () {
      expect(domInstanceOfString(hostNode.node, 'ShadowRoot'), isTrue);
      expect((hostNode.node as DomShadowRoot).host, renderHost);
      expect(hostNode.node, renderHost.shadowRoot);

      // The shadow root should be initialized with correct parameters.
      expect(renderHost.shadowRoot!.mode, 'open');
      if (browserEngine != BrowserEngine.firefox &&
          browserEngine != BrowserEngine.webkit) {
        // Older versions of Safari and Firefox don't support this flag yet.
        // See: https://caniuse.com/mdn-api_shadowroot_delegatesfocus
        expect(renderHost.shadowRoot!.delegatesFocus, isFalse);
      }
    });

    test('Attaches a stylesheet to the shadow root', () {
      final DomElement? style =
          hostNode.querySelector('#flt-internals-stylesheet');

      expect(style, isNotNull);
      expect(style!.tagName, equalsIgnoringCase('style'));
    });

    test('(Self-test) hasCssRule can extract rules', () {
      final DomElement? style =
          hostNode.querySelector('#flt-internals-stylesheet');

      final bool hasRule = hasCssRule(style,
          selector: '.flt-text-editing::placeholder',
          declaration: 'opacity: 0');

      final bool hasFakeRule = hasCssRule(style,
          selector: 'input::selection', declaration: 'color: #fabada;');

      expect(hasRule, isTrue);
      expect(hasFakeRule, isFalse);
    });

    test('Attaches outrageous text styles to flt-scene-host', () {
      final DomElement? style =
          hostNode.querySelector('#flt-internals-stylesheet');

      final bool hasColorRed = hasCssRule(style,
          selector: 'flt-scene-host', declaration: 'color: red');

      bool hasFont = false;
      if (isSafari) {
        // Safari expands the shorthand rules, so we check for all we've set (separately).
        hasFont = hasCssRule(style,
                selector: 'flt-scene-host',
                declaration: 'font-family: monospace') &&
            hasCssRule(style,
                selector: 'flt-scene-host', declaration: 'font-size: 14px');
      } else {
        hasFont = hasCssRule(style,
            selector: 'flt-scene-host', declaration: 'font: 14px monospace');
      }

      expect(hasColorRed, isTrue,
          reason: 'Should make foreground color red within scene host.');
      expect(hasFont, isTrue, reason: 'Should pass default css font.');
    });

    test('Attaches styling to remove password reveal icons on Edge', () {
      final DomElement? style =
          hostNode.querySelector('#flt-internals-stylesheet');

      // Check that style.sheet! contains input::-ms-reveal rule
      final bool hidesRevealIcons = hasCssRule(style,
          selector: 'input::-ms-reveal', declaration: 'display: none');

      final bool codeRanInFakeyBrowser = hasCssRule(style,
          selector: 'input.fallback-for-fakey-browser-in-ci',
          declaration: 'display: none');

      if (codeRanInFakeyBrowser) {
        print('Please, fix https://github.com/flutter/flutter/issues/116302');
      }

      expect(hidesRevealIcons || codeRanInFakeyBrowser, isTrue,
          reason: 'In Edge, stylesheet must contain "input::-ms-reveal" rule.');
    }, skip: !isEdge);

    test('Does not attach the Edge-specific style tag on non-Edge browsers',
        () {
      final DomElement? style =
          hostNode.querySelector('#flt-internals-stylesheet');

      // Check that style.sheet! contains input::-ms-reveal rule
      final bool hidesRevealIcons = hasCssRule(style,
          selector: 'input::-ms-reveal', declaration: 'display: none');

      expect(hidesRevealIcons, isFalse);
    }, skip: isEdge);

    test(
        'Attaches styles to hide the autofill overlay for browsers that support it',
        () {
      final DomElement? style =
          hostNode.querySelector('#flt-internals-stylesheet');
      final String vendorPrefix = (isSafari || isFirefox) ? '' : '-webkit-';
      final bool autofillOverlay = hasCssRule(style,
          selector: '.transparentTextEditing:${vendorPrefix}autofill',
          declaration: 'opacity: 0 !important');
      final bool autofillOverlayHovered = hasCssRule(style,
          selector: '.transparentTextEditing:${vendorPrefix}autofill:hover',
          declaration: 'opacity: 0 !important');
      final bool autofillOverlayFocused = hasCssRule(style,
          selector: '.transparentTextEditing:${vendorPrefix}autofill:focus',
          declaration: 'opacity: 0 !important');
      final bool autofillOverlayActive = hasCssRule(style,
          selector: '.transparentTextEditing:${vendorPrefix}autofill:active',
          declaration: 'opacity: 0 !important');

      expect(autofillOverlay, isTrue);
      expect(autofillOverlayHovered, isTrue);
      expect(autofillOverlayFocused, isTrue);
      expect(autofillOverlayActive, isTrue);
    }, skip: !browserHasAutofillOverlay());

    _runDomTests(hostNode);
  });

  group('ElementHostNode', () {
    final HostNode hostNode = ElementHostNode(rootNode, '');

    test('Initializes and attaches a child element', () {
      expect(domInstanceOfString(hostNode.node, 'Element'), isTrue);
      expect((hostNode.node as DomElement).shadowRoot, isNull);
      expect(hostNode.node.parentNode, rootNode);
    });

    _runDomTests(hostNode);
  });
}

// The common test suite that all types of HostNode implementations need to pass.
void _runDomTests(HostNode hostNode) {
  group('DOM operations', () {
    final DomElement target = domDocument.createElement('div')..id = 'yep';

    setUp(() {
      hostNode.appendAll(<DomNode>[
        domDocument.createElement('div'),
        target,
        domDocument.createElement('flt-span'),
        domDocument.createElement('div'),
      ]);
    });

    tearDown(() {
      hostNode.node.clearChildren();
    });

    test('querySelector', () {
      final DomElement? found = hostNode.querySelector('#yep');

      expect(found, target);
    });

    test('.contains and .append', () {
      final DomElement another = domDocument.createElement('div')
        ..id = 'another';

      expect(hostNode.contains(target), isTrue);
      expect(hostNode.contains(another), isFalse);
      expect(hostNode.contains(null), isFalse);

      hostNode.append(another);
      expect(hostNode.contains(another), isTrue);
    });

    test('querySelectorAll', () {
      final List<DomNode> found = hostNode.querySelectorAll('div').toList();

      expect(found.length, 3);
      expect(found[1], target);
    });
  });
}

/// Finds out whether a given CSS Rule ([selector] { [declaration]; }) exists in a [styleSheet].
bool hasCssRule(
  DomElement? styleSheet, {
  required String selector,
  required String declaration,
}) {
  assert(styleSheet != null);
  assert((styleSheet! as DomHTMLStyleElement).sheet != null);

  // regexr.com/740ff
  final RegExp ruleLike =
      RegExp('[^{]*(?:$selector)[^{]*{[^}]*(?:$declaration)[^}]*}');

  final DomCSSStyleSheet sheet =
      (styleSheet! as DomHTMLStyleElement).sheet! as DomCSSStyleSheet;

  // Check that the cssText of any rule matches the ruleLike RegExp.
  return sheet.cssRules
      .map((DomCSSRule rule) => rule.cssText)
      .any((String rule) => ruleLike.hasMatch(rule));
}
