// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
@JS()
library embedder_test; // We need this to mess with the ShadowDOM.

import 'package:js/js.dart';
import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  test('populates flt-renderer and flt-build-mode', () {
    FlutterViewEmbedder();
    expect(domDocument.body!.getAttribute('flt-renderer'),
        'html (requested explicitly)');
    expect(domDocument.body!.getAttribute('flt-build-mode'), 'debug');
  });

  test('innerHeight/innerWidth are equal to visualViewport height and width',
      () {
    if (domWindow.visualViewport != null) {
      expect(domWindow.visualViewport!.width, domWindow.innerWidth);
      expect(domWindow.visualViewport!.height, domWindow.innerHeight);
    }
  });

  test('replaces viewport meta tags during style reset', () {
    final DomHTMLMetaElement existingMeta = createDomHTMLMetaElement()
      ..name = 'viewport'
      ..content = 'foo=bar';
    domDocument.head!.append(existingMeta);
    expect(existingMeta.isConnected, isTrue);

    final FlutterViewEmbedder embedder = FlutterViewEmbedder();
    embedder.reset();
  },
      // TODO(ferhat): https://github.com/flutter/flutter/issues/46638
      // TODO(ferhat): https://github.com/flutter/flutter/issues/50828
      skip: browserEngine == BrowserEngine.firefox ||
          browserEngine == BrowserEngine.edge);

  test('accesibility placeholder is attached after creation', () {
    final FlutterViewEmbedder embedder = FlutterViewEmbedder();

    expect(
      embedder.glassPaneShadow?.querySelectorAll('flt-semantics-placeholder'),
      isNotEmpty,
    );
  });

  test('renders a shadowRoot by default', () {
    final FlutterViewEmbedder embedder = FlutterViewEmbedder();
    final HostNode hostNode = embedder.glassPaneShadow!;
    expect(domInstanceOfString(hostNode.node, 'ShadowRoot'), isTrue);
  });

  test('starts without shadowDom available too', () {
    final dynamic oldAttachShadow = attachShadow;
    expect(oldAttachShadow, isNotNull);

    attachShadow = null; // Break ShadowDOM

    final FlutterViewEmbedder embedder = FlutterViewEmbedder();
    final HostNode hostNode = embedder.glassPaneShadow!;
    expect(domInstanceOfString(hostNode.node, 'Element'), isTrue);
    expect(
      (hostNode.node as DomElement).tagName,
      equalsIgnoringCase('flt-element-host-node'),
    );
    attachShadow = oldAttachShadow; // Restore ShadowDOM
  });

  test('should add/remove global resource', () {
    final FlutterViewEmbedder embedder = FlutterViewEmbedder();
    final DomHTMLDivElement resource = createDomHTMLDivElement();
    embedder.addResource(resource);
    final DomElement? resourceRoot = resource.parent;
    expect(resourceRoot, isNotNull);
    expect(resourceRoot!.childNodes.length, 1);
    embedder.removeResource(resource);
    expect(resourceRoot.childNodes.length, 0);
  });

  test('hide placeholder text for textfield', () {
    final FlutterViewEmbedder embedder = FlutterViewEmbedder();
    final DomHTMLInputElement regularTextField = createDomHTMLInputElement();
    regularTextField.placeholder = 'Now you see me';
    embedder.addResource(regularTextField);

    regularTextField.focus();
    DomCSSStyleDeclaration? style = domWindow.getComputedStyle(
        embedder.glassPaneShadow!.querySelector('input')!,
        '::placeholder');
    expect(style, isNotNull);
    expect(style.opacity, isNot('0'));

    final DomHTMLInputElement textField = createDomHTMLInputElement();
    textField.placeholder = 'Now you dont';
    textField.classList.add('flt-text-editing');
    embedder.addResource(textField);

    textField.focus();
    style = domWindow.getComputedStyle(
        embedder.glassPaneShadow!.querySelector('input.flt-text-editing')!,
        '::placeholder');
    expect(style, isNotNull);
    expect(style.opacity, '0');
  }, skip: browserEngine != BrowserEngine.firefox);
}

@JS('Element.prototype.attachShadow')
external dynamic get attachShadow;

@JS('Element.prototype.attachShadow')
external set attachShadow(dynamic x);
