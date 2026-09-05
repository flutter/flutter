// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

const String _kDefaultCssFont = '14px monospace';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  late DomHTMLStyleElement styleElement;

  setUp(() {
    styleElement = createDomHTMLStyleElement(null);
    applyGlobalCssRulesToSheet(styleElement, defaultCssFont: _kDefaultCssFont);
  });

  tearDown(() {
    styleElement.remove();
  });

  test('createDomHTMLStyleElement sets a nonce value, when passed', () {
    expect(styleElement.nonce, isEmpty);

    final DomHTMLStyleElement style = createDomHTMLStyleElement('a-nonce-value');
    expect(style.nonce, 'a-nonce-value');
  });

  test('(Self-test) hasCssRule can extract rules', () {
    final bool hasRule = hasCssRule(
      styleElement,
      selector: '.flt-text-editing::placeholder',
      declaration: 'opacity: 0',
    );

    final bool hasFakeRule = hasCssRule(
      styleElement,
      selector: 'input::selection',
      declaration: 'color: #fabada;',
    );

    expect(hasRule, isTrue);
    expect(hasFakeRule, isFalse);
  });

  test('Attaches styling to remove password reveal icons on Edge', () {
    // Check that style.sheet! contains input::-ms-reveal rule
    final bool hidesRevealIcons = hasCssRule(
      styleElement,
      selector: 'input::-ms-reveal',
      declaration: 'display: none',
    );

    final bool codeRanInFakeyBrowser = hasCssRule(
      styleElement,
      selector: 'input.fallback-for-fakey-browser-in-ci',
      declaration: 'display: none',
    );

    if (codeRanInFakeyBrowser) {
      print('Please, fix https://github.com/flutter/flutter/issues/116302');
    }

    expect(
      hidesRevealIcons || codeRanInFakeyBrowser,
      isTrue,
      reason: 'In Edge, stylesheet must contain "input::-ms-reveal" rule.',
    );
  }, skip: !isEdge);

  test('Does not attach the Edge-specific style tag on non-Edge browsers', () {
    // Check that style.sheet! contains input::-ms-reveal rule
    final bool hidesRevealIcons = hasCssRule(
      styleElement,
      selector: 'input::-ms-reveal',
      declaration: 'display: none',
    );

    expect(hidesRevealIcons, isFalse);
  }, skip: isEdge);

  test('Attaches styles to hide the autofill overlay for browsers that support it', () {
    final vendorPrefix = (isSafari || isFirefox) ? '' : '-webkit-';
    final bool autofillOverlay = hasCssRule(
      styleElement,
      selector: '.transparentTextEditing:${vendorPrefix}autofill',
      declaration: 'opacity: 0 !important',
    );
    final bool autofillOverlayHovered = hasCssRule(
      styleElement,
      selector: '.transparentTextEditing:${vendorPrefix}autofill:hover',
      declaration: 'opacity: 0 !important',
    );
    final bool autofillOverlayFocused = hasCssRule(
      styleElement,
      selector: '.transparentTextEditing:${vendorPrefix}autofill:focus',
      declaration: 'opacity: 0 !important',
    );
    final bool autofillOverlayActive = hasCssRule(
      styleElement,
      selector: '.transparentTextEditing:${vendorPrefix}autofill:active',
      declaration: 'opacity: 0 !important',
    );

    expect(autofillOverlay, isTrue);
    expect(autofillOverlayHovered, isTrue);
    expect(autofillOverlayFocused, isTrue);
    expect(autofillOverlayActive, isTrue);
  }, skip: !browserHasAutofillOverlay());

  // iOS auto-zooms the page when it focuses an input under 16px. The semantic
  // input sets no font size, so it inherits the browser default (11px on iOS)
  // and tapping a text field zooms the page to ~1.45x.
  // See: https://github.com/flutter/flutter/issues/192327
  test('Sets a 16px font-size on semantic inputs on iOS Safari', () {
    final DomHTMLStyleElement iosStyleElement = createDomHTMLStyleElement(null);
    debugEmulateIosSafari = true;
    try {
      applyGlobalCssRulesToSheet(iosStyleElement, defaultCssFont: _kDefaultCssFont);
    } finally {
      debugEmulateIosSafari = false;
    }

    expect(
      hasCssRule(iosStyleElement, selector: 'flt-semantics input', declaration: 'font-size: 16px'),
      isTrue,
    );
    expect(
      hasCssRule(
        iosStyleElement,
        selector: 'flt-semantics textarea',
        declaration: 'font-size: 16px',
      ),
      isTrue,
    );

    iosStyleElement.remove();
  });

  // Only iOS auto-zooms, so no other browser should pay for the override. The
  // `styleElement` under test is the one built by setUp, without the flag.
  test('Does not set the semantic input font-size on other browsers', () {
    expect(
      hasCssRule(styleElement, selector: 'flt-semantics input', declaration: 'font-size: 16px'),
      isFalse,
    );
  }, skip: isIosSafari);
}

/// Finds out whether a given CSS Rule ([selector] { [declaration]; }) exists in a [styleElement].
bool hasCssRule(
  DomHTMLStyleElement styleElement, {
  required String selector,
  required String declaration,
}) {
  domDocument.body!.append(styleElement);
  assert(styleElement.sheet != null);

  // regexr.com/740ff
  final ruleLike = RegExp('[^{]*(?:$selector)[^{]*{[^}]*(?:$declaration)[^}]*}');

  final sheet = styleElement.sheet! as DomCSSStyleSheet;

  // Check that the cssText of any rule matches the ruleLike RegExp.
  final bool result = sheet.cssRules
      .map((DomCSSRule rule) => rule.cssText)
      .any((String rule) => ruleLike.hasMatch(rule));

  styleElement.remove();
  return result;
}
