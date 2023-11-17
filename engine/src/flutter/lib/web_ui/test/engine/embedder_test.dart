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
  setUpAll(() {
    ensureImplicitViewInitialized();
  });

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
      skip: browserEngine == BrowserEngine.firefox);

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
}
