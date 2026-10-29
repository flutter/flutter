// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')
library;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/dom.dart';
import 'package:ui/src/engine/util.dart';
import 'package:ui/src/engine/view_embedder/embedding_strategy/full_page_embedding_strategy.dart';

void main() {
  internalBootstrapBrowserTest(() => doTests);
}

void doTests() {
  group('initialize', () {
    test('Prepares target environment', () {
      final warnings = <String>[];
      final void Function(String) oldPrintWarning = printWarning;
      printWarning = (String message) {
        warnings.add(message);
      };

      final DomElement target = domDocument.body!;
      final DomHTMLMetaElement meta = createDomHTMLMetaElement();
      meta
        ..id = 'my_viewport_meta_for_testing'
        ..name = 'viewport'
        ..content =
            'width=device-width, initial-scale=1.0, '
            'maximum-scale=1.0, user-scalable=no';
      domDocument.head!.append(meta);

      DomElement? userMeta = domDocument.querySelector('#my_viewport_meta_for_testing');

      expect(userMeta, isNotNull);

      // ignore: unused_local_variable
      final strategy = FullPageEmbeddingStrategy();

      expect(
        target.getAttribute('flt-embedding'),
        'full-page',
        reason: 'Should identify itself as a specific key=value into the target element.',
      );

      // Locate the viewport metas again...
      userMeta = domDocument.querySelector('#my_viewport_meta_for_testing');

      final DomElement? flutterMeta = domDocument.querySelector('meta[name="viewport"]');

      expect(userMeta, isNull, reason: 'Should delete previously existing viewport meta tags.');
      expect(flutterMeta, isNotNull);
      expect(
        flutterMeta!.hasAttribute('flt-viewport'),
        isTrue,
        reason: 'Should install flutter viewport meta tag.',
      );
      expect(warnings, hasLength(1), reason: 'Should print a warning to the user.');
      expect(warnings.single, contains(RegExp(r'Found an existing.*meta.*viewport')));

      printWarning = oldPrintWarning;
    });
  });

  group('viewport-fit', () {
    setUp(() {
      // Start from a page with no viewport meta tag at all, so leftovers from
      // other tests can't influence the result.
      for (final DomElement meta in domDocument.head!.querySelectorAll('meta[name="viewport"]')) {
        meta.remove();
      }
    });

    tearDown(() {
      for (final DomElement meta in domDocument.head!.querySelectorAll('meta[name="viewport"]')) {
        meta.remove();
      }
    });

    // Runs the strategy against a page that declares one viewport meta tag per
    // entry of [contents] (a null entry declares a tag with no `content`
    // attribute at all), and returns the `content` of the tag that the engine
    // leaves behind.
    String applyViewportMetas(List<String?> contents) {
      for (final content in contents) {
        final DomHTMLMetaElement meta = createDomHTMLMetaElement()..name = 'viewport';
        if (content != null) {
          meta.content = content;
        }
        domDocument.head!.append(meta);
      }

      final void Function(String) oldPrintWarning = printWarning;
      // Restored with `addTearDown` rather than after the call below, so that a
      // throwing constructor can't leave the rest of the suite with a stubbed
      // `printWarning` that swallows every warning the engine emits.
      addTearDown(() => printWarning = oldPrintWarning);
      printWarning = (_) {};
      FullPageEmbeddingStrategy();

      return domDocument.querySelector('meta[name="viewport"]')!.getAttribute('content')!;
    }

    String applyViewportMeta(String content) => applyViewportMetas(<String?>[content]);

    test('is preserved from the tag authored by the app', () {
      expect(
        applyViewportMeta('width=device-width, initial-scale=1.0, viewport-fit=cover'),
        'width=device-width, initial-scale=1.0, maximum-scale=5.0, viewport-fit=cover',
        reason: 'Should keep the safe area opt-in of the app.',
      );
    });

    test('is preserved regardless of spacing and casing', () {
      expect(
        applyViewportMeta('width=device-width,VIEWPORT-FIT = Contain'),
        'width=device-width, initial-scale=1.0, maximum-scale=5.0, viewport-fit=contain',
      );
    });

    test('is preserved from a semicolon-separated content', () {
      // Browsers accept `;` as a descriptor separator, so the engine has to
      // understand it too.
      expect(
        applyViewportMeta('width=device-width; initial-scale=1.0; viewport-fit=cover'),
        'width=device-width, initial-scale=1.0, maximum-scale=5.0, viewport-fit=cover',
      );
    });

    test('is preserved from a space-separated content', () {
      expect(
        applyViewportMeta('width=device-width initial-scale=1.0 viewport-fit=cover'),
        'width=device-width, initial-scale=1.0, maximum-scale=5.0, viewport-fit=cover',
      );
    });

    test('is not added when the app does not ask for it', () {
      expect(
        applyViewportMeta('width=device-width, initial-scale=1.0'),
        'width=device-width, initial-scale=1.0, maximum-scale=5.0',
        reason: 'Should not change the layout of apps that never opted in.',
      );
    });

    test('is not added for a tag with no content attribute', () {
      expect(
        applyViewportMetas(<String?>[null]),
        'width=device-width, initial-scale=1.0, maximum-scale=5.0',
      );
    });

    test('is dropped when the app declares a value the engine does not know', () {
      expect(
        applyViewportMeta('viewport-fit=coverr'),
        'width=device-width, initial-scale=1.0, maximum-scale=5.0',
      );
    });

    test('is taken from the last tag of the page, as the browser does', () {
      // A page whose last viewport meta tag declares no `viewport-fit` is not
      // laid out full-bleed by the browser, no matter what the earlier tags
      // said, so the engine must not opt it in either.
      expect(
        applyViewportMetas(<String?>[
          'width=device-width, viewport-fit=cover',
          'width=device-width, initial-scale=1.0',
        ]),
        'width=device-width, initial-scale=1.0, maximum-scale=5.0',
      );

      expect(
        applyViewportMetas(<String?>[
          'width=device-width, initial-scale=1.0',
          'width=device-width, viewport-fit=cover',
        ]),
        'width=device-width, initial-scale=1.0, maximum-scale=5.0, viewport-fit=cover',
      );
    });

    test('is read back from the tag that the engine itself wrote', () {
      applyViewportMeta('width=device-width, viewport-fit=cover');

      // The tag authored by the app is long gone; this run can only read the
      // tag left behind by the previous one. This is what makes the value
      // survive a hot restart: the tag of the previous run is still on the page
      // when `_applyViewportMeta` reads it, and only gets swept away by the
      // `registerElementForCleanup` call at the end of that same method.
      FullPageEmbeddingStrategy();

      expect(
        domDocument.querySelector('meta[name="viewport"]')!.getAttribute('content'),
        'width=device-width, initial-scale=1.0, maximum-scale=5.0, viewport-fit=cover',
      );
    });

    test('is not acquired by an app that never declared one', () {
      applyViewportMeta('width=device-width, initial-scale=1.0');

      FullPageEmbeddingStrategy();

      expect(
        domDocument.querySelector('meta[name="viewport"]')!.getAttribute('content'),
        'width=device-width, initial-scale=1.0, maximum-scale=5.0',
      );
    });
  });

  group('attachViewRoot', () {
    test('Should attach glasspane into embedder target (body)', () async {
      final strategy = FullPageEmbeddingStrategy();

      final DomElement glassPane = createDomElement('some-tag-for-tests');
      final DomCSSStyleDeclaration style = glassPane.style;

      expect(glassPane.isConnected, isFalse);
      expect(style.position, '', reason: 'Should not have any specific position.');
      expect(style.top, '', reason: 'Should not have any top/right/bottom/left positioning/inset.');

      strategy.attachViewRoot(glassPane);

      // Assert injection into <body>
      expect(glassPane.isConnected, isTrue, reason: 'Should inject glassPane into the document.');
      expect(glassPane.parent, domDocument.body, reason: 'Should inject glassPane into the <body>');

      final DomCSSStyleDeclaration styleAfter = glassPane.style;

      // Assert required styling to cover the viewport
      expect(styleAfter.position, 'absolute', reason: 'Should be absolutely positioned.');
      expect(styleAfter.top, '0px', reason: 'Should cover the whole viewport.');
      expect(styleAfter.right, '0px', reason: 'Should cover the whole viewport.');
      expect(styleAfter.bottom, '0px', reason: 'Should cover the whole viewport.');
      expect(styleAfter.left, '0px', reason: 'Should cover the whole viewport.');
    });
  });
}
