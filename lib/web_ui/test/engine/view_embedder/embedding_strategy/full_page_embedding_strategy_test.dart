// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')
library;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/dom.dart';
import 'package:ui/src/engine/view_embedder/embedding_strategy/full_page_embedding_strategy.dart';

void main() {
  internalBootstrapBrowserTest(() => doTests);
}

void doTests() {
  late FullPageEmbeddingStrategy strategy;
  late DomElement target;

  group('initialize', () {
    setUp(() {
      strategy = FullPageEmbeddingStrategy();
      target = domDocument.body!;
      final DomHTMLMetaElement meta = createDomHTMLMetaElement();
      meta
        ..id = 'my_viewport_meta_for_testing'
        ..name = 'viewport'
        ..content = 'width=device-width, initial-scale=1.0, '
            'maximum-scale=1.0, user-scalable=no';
      domDocument.head!.append(meta);
    });

    test('Prepares target environment', () {
      DomElement? userMeta =
          domDocument.querySelector('#my_viewport_meta_for_testing');

      expect(userMeta, isNotNull);

      strategy.initialize(
        hostElementAttributes: <String, String>{
          'key-for-testing': 'value-for-testing',
        },
      );

      expect(target.getAttribute('key-for-testing'), 'value-for-testing',
          reason:
              'Should add attributes as key=value into target element.');
      expect(target.getAttribute('flt-embedding'), 'full-page',
          reason:
              'Should identify itself as a specific key=value into the target element.');

      // Locate the viewport metas again...
      userMeta = domDocument.querySelector('#my_viewport_meta_for_testing');

      final DomElement? flutterMeta =
          domDocument.querySelector('meta[name="viewport"]');

      expect(userMeta, isNull,
          reason: 'Should delete previously existing viewport meta tags.');
      expect(flutterMeta, isNotNull);
      expect(flutterMeta!.hasAttribute('flt-viewport'), isTrue,
          reason: 'Should install flutter viewport meta tag.');
    });
  });

  group('attachGlassPane', () {
    setUp(() {
      strategy = FullPageEmbeddingStrategy();
      strategy.initialize();
    });

    test('Should attach glasspane into embedder target (body)', () async {
      final DomElement glassPane = createDomElement('some-tag-for-tests');
      final DomCSSStyleDeclaration style = glassPane.style;

      expect(glassPane.isConnected, isFalse);
      expect(style.position, '',
          reason: 'Should not have any specific position.');
      expect(style.top, '',
          reason:
              'Should not have any top/right/bottom/left positioning/inset.');

      strategy.attachGlassPane(glassPane);

      // Assert injection into <body>
      expect(glassPane.isConnected, isTrue,
          reason: 'Should inject glassPane into the document.');
      expect(glassPane.parent, domDocument.body,
          reason: 'Should inject glassPane into the <body>');

      final DomCSSStyleDeclaration styleAfter = glassPane.style;

      // Assert required styling to cover the viewport
      expect(styleAfter.position, 'absolute',
          reason: 'Should be absolutely positioned.');
      expect(styleAfter.top, '0px', reason: 'Should cover the whole viewport.');
      expect(styleAfter.right, '0px',
          reason: 'Should cover the whole viewport.');
      expect(styleAfter.bottom, '0px',
          reason: 'Should cover the whole viewport.');
      expect(styleAfter.left, '0px',
          reason: 'Should cover the whole viewport.');
    });
  });

  group('attachResourcesHost', () {
    late DomElement glassPane;
    setUp(() {
      glassPane = createDomElement('some-tag-for-tests');
      strategy = FullPageEmbeddingStrategy();
      strategy.initialize();
      strategy.attachGlassPane(glassPane);
    });

    test(
        'Should attach resources host into target (body), `nextTo` other element',
        () async {
      final DomElement resources = createDomElement('resources-host-element');

      expect(resources.isConnected, isFalse);

      strategy.attachResourcesHost(resources, nextTo: glassPane);

      expect(resources.isConnected, isTrue,
          reason: 'Should inject resources host somewhere in the document.');
      expect(resources.parent, domDocument.body,
          reason: 'Should inject resources host into the <body>');
      expect(resources.nextSibling, glassPane,
          reason: 'Should be injected `nextTo` the passed element.');
    });
  });
}
