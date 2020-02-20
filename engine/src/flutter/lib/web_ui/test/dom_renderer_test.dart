// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:html' as html;

import 'package:ui/src/engine.dart';
import 'package:test/test.dart';

void main() {
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
    renderer.setElementStyle(element, 'color', 'red');
    expect(element.style.color, 'red');
  });
  test('can remove style properties from elements', () {
    final DomRenderer renderer = DomRenderer();
    final html.Element element = renderer.createElement('div');
    renderer.setElementStyle(element, 'color', 'blue');
    expect(element.style.color, 'blue');
    renderer.setElementStyle(element, 'color', null);
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
  test('can reattach detached elements', () {
    final DomRenderer renderer = DomRenderer();
    final html.Element element = renderer.createElement('div');
    final html.Element child = renderer.createElement('div', parent: element);
    final html.Element otherChild =
        renderer.createElement('foo', parent: element);
    renderer.detachElement(child);
    expect(element.children, hasLength(1));
    renderer.attachBeforeElement(element, otherChild, child);
    expect(element.children, hasLength(2));
  });
  test('insert two elements in the middle of a child list', () {
    final DomRenderer renderer = DomRenderer();
    final html.Element parent = renderer.createElement('div');
    renderer.createElement('a', parent: parent);
    final html.Element childD = renderer.createElement('d', parent: parent);
    expect(parent.innerHtml, '<a></a><d></d>');
    final html.Element childB = renderer.createElement('b', parent: parent);
    final html.Element childC = renderer.createElement('c', parent: parent);
    renderer.attachBeforeElement(parent, childD, childB);
    renderer.attachBeforeElement(parent, childD, childC);
    expect(parent.innerHtml, '<a></a><b></b><c></c><d></d>');
  });

  test('innerHeight/innerWidth are equal to visualViewport height and width',
      () {
    if (html.window.visualViewport != null) {
      expect(html.window.visualViewport.width, html.window.innerWidth);
      expect(html.window.visualViewport.height, html.window.innerHeight);
    }
  });

  test('replaces viewport meta tags during style reset', () {
    final html.MetaElement existingMeta = html.MetaElement()
      ..name = 'viewport'
      ..content = 'foo=bar';
    html.document.head.append(existingMeta);
    expect(existingMeta.isConnected, true);

    final DomRenderer renderer = DomRenderer();
    renderer.reset();
  },
      // TODO(nurhan): https://github.com/flutter/flutter/issues/46638
      // TODO(nurhan): https://github.com/flutter/flutter/issues/50828
      skip: (browserEngine == BrowserEngine.firefox ||
          browserEngine == BrowserEngine.edge));

  test('accesibility placeholder is attached after creation', () {
    DomRenderer();

    expect(html.document.getElementsByTagName('flt-semantics-placeholder'),
        isNotEmpty);
  });
}
