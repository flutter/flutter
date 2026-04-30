// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')
library;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/dom.dart';
import 'package:ui/src/engine/view_embedder/embedding_strategy/custom_element_embedding_strategy.dart';
import 'package:ui/src/engine/view_embedder/embedding_strategy/embedding_strategy.dart';
import 'package:ui/src/engine/view_embedder/embedding_strategy/full_page_embedding_strategy.dart';

void main() {
  internalBootstrapBrowserTest(() => doTests);
}

void doTests() {
  group('Factory', () {
    test('Creates a FullPage instance when hostElement is null', () async {
      final strategy = EmbeddingStrategy.create();

      expect(strategy, isA<FullPageEmbeddingStrategy>());
    });

    test('Creates a CustomElement instance when hostElement is not null', () async {
      final DomElement element = createDomElement('some-random-element');
      final strategy = EmbeddingStrategy.create(hostElement: element);

      expect(strategy, isA<CustomElementEmbeddingStrategy>());
    });
  });

  group('Browser scrolling support', () {
    test('FullPageEmbeddingStrategy supports browser scrolling', () {
      final strategy = EmbeddingStrategy.create();
      expect(strategy.supportsBrowserScrolling, isTrue);
    });

    test('CustomElementEmbeddingStrategy does not support browser scrolling', () {
      final DomElement element = createDomElement('some-element');
      final strategy = EmbeddingStrategy.create(hostElement: element);
      expect(strategy.supportsBrowserScrolling, isFalse);
    });

    test('FullPage enableBrowserScrolling sets overflow:auto on rootElement', () {
      final strategy = EmbeddingStrategy.create() as FullPageEmbeddingStrategy;
      final DomElement rootElement = createDomElement('flutter-view');
      domDocument.body!.append(rootElement);

      strategy.enableBrowserScrolling(rootElement);

      expect(rootElement.style.overflow, 'auto');

      strategy.disableBrowserScrolling(rootElement);
      rootElement.remove();
    });

    test('FullPage enableBrowserScrolling sets touch-action:pan-y on rootElement', () {
      final strategy = EmbeddingStrategy.create() as FullPageEmbeddingStrategy;
      final DomElement rootElement = createDomElement('flutter-view');
      domDocument.body!.append(rootElement);

      strategy.enableBrowserScrolling(rootElement);

      final String touchAction = rootElement.style.getPropertyValue('touch-action');
      expect(touchAction, 'pan-y');

      strategy.disableBrowserScrolling(rootElement);
      rootElement.remove();
    });

    test('FullPage enableBrowserScrolling creates scroll height placeholder', () {
      final strategy = EmbeddingStrategy.create() as FullPageEmbeddingStrategy;
      final DomElement rootElement = createDomElement('flutter-view');
      domDocument.body!.append(rootElement);

      strategy.enableBrowserScrolling(rootElement);

      final DomElement? placeholder = rootElement.querySelector('[flt-scroll-placeholder]');
      expect(placeholder, isNotNull);

      strategy.disableBrowserScrolling(rootElement);
      rootElement.remove();
    });

    test('FullPage updateScrollContentHeight sets placeholder height', () {
      final strategy = EmbeddingStrategy.create() as FullPageEmbeddingStrategy;
      final DomElement rootElement = createDomElement('flutter-view');
      domDocument.body!.append(rootElement);

      strategy.enableBrowserScrolling(rootElement);
      strategy.updateScrollContentHeight(5000);

      final DomElement? placeholder = rootElement.querySelector('[flt-scroll-placeholder]');
      expect(placeholder, isNotNull);
      expect(placeholder!.style.height, '5000px');

      strategy.disableBrowserScrolling(rootElement);
      rootElement.remove();
    });

    test('FullPage updateScrollContentHeight is no-op before enable', () {
      final strategy = EmbeddingStrategy.create() as FullPageEmbeddingStrategy;
      strategy.updateScrollContentHeight(5000);
    });

    test('FullPage disableBrowserScrolling restores inline child styles', () {
      final strategy = EmbeddingStrategy.create() as FullPageEmbeddingStrategy;
      final DomElement rootElement = createDomElement('flutter-view');
      domDocument.body!.append(rootElement);

      // Mimic StyleManager.styleSemanticsHost applying inline position.
      final DomElement semanticsHost = createDomElement('flt-semantics-host');
      semanticsHost.style.position = 'absolute';
      rootElement.append(semanticsHost);

      // Mimic a child without inline position.
      final DomElement glassPane = createDomElement('flt-glass-pane');
      rootElement.append(glassPane);

      strategy.enableBrowserScrolling(rootElement);
      expect(semanticsHost.style.position, 'sticky');
      expect(glassPane.style.position, 'sticky');

      strategy.disableBrowserScrolling(rootElement);
      expect(semanticsHost.style.position, 'absolute');
      expect(glassPane.style.position, '');

      rootElement.remove();
    });

    test('FullPage disableBrowserScrolling restores hostElement touch-action', () {
      final strategy = EmbeddingStrategy.create() as FullPageEmbeddingStrategy;
      final DomElement rootElement = createDomElement('flutter-view');
      domDocument.body!.append(rootElement);

      strategy.enableBrowserScrolling(rootElement);
      expect(strategy.hostElement.style.getPropertyValue('touch-action'), 'pan-y');

      strategy.disableBrowserScrolling(rootElement);
      // _setHostStyles, called from disable, restores touch-action: none.
      // The class invariant for non-browser-scroll mode is none, matching
      // the constructor.
      expect(strategy.hostElement.style.getPropertyValue('touch-action'), 'none');

      rootElement.remove();
    });

    test('CustomElement enableBrowserScrolling is a no-op', () {
      final DomElement element = createDomElement('some-element');
      final strategy = EmbeddingStrategy.create(hostElement: element);
      final DomElement rootElement = createDomElement('flutter-view');

      strategy.enableBrowserScrolling(rootElement);
      expect(strategy.supportsBrowserScrolling, isFalse);
    });
  });
}
