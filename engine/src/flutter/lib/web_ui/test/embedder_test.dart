// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
@JS()
library embedder_test; // We need this to mess with the ShadowDOM.

import 'dart:html' as html;

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
    expect(html.document.body!.attributes['flt-renderer'],
        'html (requested explicitly)');
    expect(html.document.body!.attributes['flt-build-mode'], 'debug');
  });

  test('innerHeight/innerWidth are equal to visualViewport height and width',
      () {
    if (html.window.visualViewport != null) {
      expect(html.window.visualViewport!.width, html.window.innerWidth);
      expect(html.window.visualViewport!.height, html.window.innerHeight);
    }
  });

  test('replaces viewport meta tags during style reset', () {
    final html.MetaElement existingMeta = html.MetaElement()
      ..name = 'viewport'
      ..content = 'foo=bar';
    html.document.head!.append(existingMeta);
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
    expect(hostNode.node, isA<html.ShadowRoot>());
  });

  test('starts without shadowDom available too', () {
    final dynamic oldAttachShadow = attachShadow;
    expect(oldAttachShadow, isNotNull);

    attachShadow = null; // Break ShadowDOM

    final FlutterViewEmbedder embedder = FlutterViewEmbedder();
    final HostNode hostNode = embedder.glassPaneShadow!;
    expect(hostNode.node, isA<html.Element>());
    expect(
      (hostNode.node as html.Element).tagName,
      equalsIgnoringCase('flt-element-host-node'),
    );
    attachShadow = oldAttachShadow; // Restore ShadowDOM
  });

  test('should add/remove global resource', () {
    final FlutterViewEmbedder embedder = FlutterViewEmbedder();
    final html.DivElement resource = html.DivElement();
    embedder.addResource(resource);
    final html.Element? resourceRoot = resource.parent;
    expect(resourceRoot, isNotNull);
    expect(resourceRoot!.childNodes.length, 1);
    embedder.removeResource(resource);
    expect(resourceRoot.childNodes.length, 0);
  });

  test('hide placeholder text for textfield', () {
    final FlutterViewEmbedder embedder = FlutterViewEmbedder();
    final html.InputElement regularTextField = html.InputElement();
    regularTextField.placeholder = 'Now you see me';
    embedder.addResource(regularTextField);

    regularTextField.focus();
    html.CssStyleDeclaration? style = embedder.glassPaneShadow?.querySelector('input')?.getComputedStyle('::placeholder');
    expect(style, isNotNull);
    expect(style?.opacity, isNot('0'));

    final html.InputElement textField = html.InputElement();
    textField.placeholder = 'Now you dont';
    textField.classes.add('flt-text-editing');
    embedder.addResource(textField);

    textField.focus();
    style = embedder.glassPaneShadow?.querySelector('input.flt-text-editing')?.getComputedStyle('::placeholder');
    expect(style, isNotNull);
    expect(style?.opacity, '0');
  }, skip: browserEngine != BrowserEngine.firefox);
}

@JS('Element.prototype.attachShadow')
external dynamic get attachShadow;

@JS('Element.prototype.attachShadow')
external set attachShadow(dynamic x);
