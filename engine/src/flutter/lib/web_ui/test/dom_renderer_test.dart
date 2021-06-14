// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
@JS()
library dom_renderer_test; // We need this to mess with the ShadowDOM.

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
    DomRenderer();
    expect(html.document.body!.attributes['flt-renderer'],
        'html (requested explicitly)');
    expect(html.document.body!.attributes['flt-build-mode'], 'debug');
  });

  test('creating elements works', () {
    final DomRenderer renderer = DomRenderer();
    final html.Element element = renderer.createElement('div');
    expect(element, isNotNull);
  });

  test('can append children to parents', () {
    final DomRenderer renderer = DomRenderer();
    final html.Element parent = renderer.createElement('div');
    final html.Element child = renderer.createElement('div');
    renderer.append(parent, child);
    expect(parent.children, hasLength(1));
  });

  test('can set text on elements', () {
    final DomRenderer renderer = DomRenderer();
    final html.Element element = renderer.createElement('div');
    renderer.setText(element, 'Hello World');
    expect(element.text, 'Hello World');
  });

  test('can set attributes on elements', () {
    final DomRenderer renderer = DomRenderer();
    final html.Element element = renderer.createElement('div');
    renderer.setElementAttribute(element, 'id', 'foo');
    expect(element.id, 'foo');
  });

  test('can add classes to elements', () {
    final DomRenderer renderer = DomRenderer();
    final html.Element element = renderer.createElement('div');
    renderer.addElementClass(element, 'foo');
    renderer.addElementClass(element, 'bar');
    expect(element.classes, <String>['foo', 'bar']);
  });

  test('can remove classes from elements', () {
    final DomRenderer renderer = DomRenderer();
    final html.Element element = renderer.createElement('div');
    renderer.addElementClass(element, 'foo');
    renderer.addElementClass(element, 'bar');
    expect(element.classes, <String>['foo', 'bar']);
    renderer.removeElementClass(element, 'foo');
    expect(element.classes, <String>['bar']);
  });

  test('can set style properties on elements', () {
    final DomRenderer renderer = DomRenderer();
    final html.Element element = renderer.createElement('div');
    DomRenderer.setElementStyle(element, 'color', 'red');
    expect(element.style.color, 'red');
  });

  test('can remove style properties from elements', () {
    final DomRenderer renderer = DomRenderer();
    final html.Element element = renderer.createElement('div');
    DomRenderer.setElementStyle(element, 'color', 'blue');
    expect(element.style.color, 'blue');
    DomRenderer.setElementStyle(element, 'color', null);
    expect(element.style.color, '');
  });

  test('elements can have children', () {
    final DomRenderer renderer = DomRenderer();
    final html.Element element = renderer.createElement('div');
    renderer.createElement('div', parent: element);
    expect(element.children, hasLength(1));
  });

  test('can detach elements', () {
    final DomRenderer renderer = DomRenderer();
    final html.Element element = renderer.createElement('div');
    final html.Element child = renderer.createElement('div', parent: element);
    renderer.detachElement(child);
    expect(element.children, isEmpty);
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

    final DomRenderer renderer = DomRenderer();
    renderer.reset();
  },
      // TODO(nurhan): https://github.com/flutter/flutter/issues/46638
      // TODO(nurhan): https://github.com/flutter/flutter/issues/50828
      skip: (browserEngine == BrowserEngine.firefox ||
          browserEngine == BrowserEngine.edge));

  test('accesibility placeholder is attached after creation', () {
    final DomRenderer renderer = DomRenderer();

    expect(
      renderer.glassPaneShadow?.querySelectorAll('flt-semantics-placeholder'),
      isNotEmpty,
    );
  });

  test('renders a shadowRoot by default', () {
    final DomRenderer renderer = DomRenderer();

    HostNode hostNode = renderer.glassPaneShadow!;

    expect(hostNode.node, isA<html.ShadowRoot>());
  });

  test('starts without shadowDom available too', () {
    final dynamic oldAttachShadow = attachShadow;
    expect(oldAttachShadow, isNotNull);

    attachShadow = null; // Break ShadowDOM

    final DomRenderer renderer = DomRenderer();

    HostNode hostNode = renderer.glassPaneShadow!;

    expect(hostNode.node, isA<html.Element>());
    expect(
      (hostNode.node as html.Element).tagName,
      equalsIgnoringCase('flt-element-host-node'),
    );

    attachShadow = oldAttachShadow; // Restore ShadowDOM
  });
}

@JS('Element.prototype.attachShadow')
external dynamic get attachShadow;

@JS('Element.prototype.attachShadow')
external set attachShadow(dynamic x);
