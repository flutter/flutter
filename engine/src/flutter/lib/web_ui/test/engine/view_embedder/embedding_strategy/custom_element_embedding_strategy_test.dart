// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/dom.dart';
import 'package:ui/src/engine/view_embedder/embedding_strategy/custom_element_embedding_strategy.dart';

void main() {
  internalBootstrapBrowserTest(() => doTests);
}

void doTests() {
  late CustomElementEmbeddingStrategy strategy;
  late DomElement target;

  group('initialize', () {
    setUp(() {
      target = createDomElement('this-is-the-target');
      domDocument.body!.append(target);
      strategy = CustomElementEmbeddingStrategy(target);
    });

    tearDown(() {
      target.remove();
    });

    test('Prepares target environment', () {
      strategy.initialize(
        hostElementAttributes: <String, String>{
          'key-for-testing': 'value-for-testing',
        },
      );

      expect(target.getAttribute('key-for-testing'), 'value-for-testing',
          reason:
              'Should add attributes as key=value into target element.');
      expect(target.getAttribute('flt-embedding'), 'custom-element',
          reason:
              'Should identify itself as a specific key=value into the target element.');
    });
  });

  group('attachGlassPane', () {
    setUp(() {
      target = createDomElement('this-is-the-target');
      domDocument.body!.append(target);
      strategy = CustomElementEmbeddingStrategy(target);
      strategy.initialize();
    });

    tearDown(() {
      target.remove();
    });

    test('Should attach glasspane into embedder target (body)', () async {
      final DomElement glassPane = createDomElement('some-tag-for-tests');
      final DomCSSStyleDeclaration style = glassPane.style;

      expect(glassPane.isConnected, isFalse);
      expect(style.position, '',
          reason: 'Should not have any specific position.');
      expect(style.width, '', reason: 'Should not have any size set.');

      strategy.attachGlassPane(glassPane);

      // Assert injection into <body>
      expect(glassPane.isConnected, isTrue,
          reason: 'Should inject glassPane into the document.');
      expect(glassPane.parent, target,
          reason: 'Should inject glassPane into the target element');

      final DomCSSStyleDeclaration styleAfter = glassPane.style;

      // Assert required styling to cover the viewport
      expect(styleAfter.position, 'relative',
          reason: 'Should be relatively positioned.');
      expect(styleAfter.display, 'block', reason: 'Should be display:block.');
      expect(styleAfter.width, '100%',
          reason: 'Should take 100% of the available width');
      expect(styleAfter.height, '100%',
          reason: 'Should take 100% of the available height');
      expect(styleAfter.overflow, 'hidden',
          reason: 'Should hide the occasional oversized canvas elements.');
    });
  });

  group('attachResourcesHost', () {
    late DomElement glassPane;

    setUp(() {
      target = createDomElement('this-is-the-target');
      glassPane = createDomElement('woah-a-glasspane');
      domDocument.body!.append(target);
      strategy = CustomElementEmbeddingStrategy(target);
      strategy.initialize();
      strategy.attachGlassPane(glassPane);
    });

    tearDown(() {
      target.remove();
    });

    test(
        'Should attach resources host into target (body), `nextTo` other element',
        () async {
      final DomElement resources = createDomElement('resources-host-element');

      expect(resources.isConnected, isFalse);

      strategy.attachResourcesHost(resources, nextTo: glassPane);

      expect(resources.isConnected, isTrue,
          reason: 'Should inject resources host somewhere in the document.');
      expect(resources.parent, target,
          reason: 'Should inject the resources into the target element');
      expect(resources.nextSibling, glassPane,
          reason: 'Should be injected `nextTo` the passed element.');
    });
  });

  group('context menu', () {
    setUp(() {
      target = createDomElement('this-is-the-target');
      domDocument.body!.append(target);
      strategy = CustomElementEmbeddingStrategy(target);
      strategy.initialize();
    });

    tearDown(() {
      target.remove();
    });

    test('disableContextMenu and enableContextMenu can toggle the context menu', () {
      // When the app starts, contextmenu events are not prevented.
      DomEvent event = createDomEvent('Event', 'contextmenu');
      expect(event.defaultPrevented, isFalse);
      target.dispatchEvent(event);
      expect(event.defaultPrevented, isFalse);

      // Disabling the context menu causes contextmenu events to be prevented.
      strategy.disableContextMenu();
      event = createDomEvent('Event', 'contextmenu');
      expect(event.defaultPrevented, isFalse);
      target.dispatchEvent(event);
      expect(event.defaultPrevented, isTrue);

      // Disabling again has no effect.
      strategy.disableContextMenu();
      event = createDomEvent('Event', 'contextmenu');
      expect(event.defaultPrevented, isFalse);
      target.dispatchEvent(event);
      expect(event.defaultPrevented, isTrue);

      // Dispatching on a DOM element outside of target's subtree has no effect.
      event = createDomEvent('Event', 'contextmenu');
      expect(event.defaultPrevented, isFalse);
      domDocument.body!.dispatchEvent(event);
      expect(event.defaultPrevented, isFalse);

      // Enabling the context menu means that contextmenu events are back to not
      // being prevented.
      strategy.enableContextMenu();
      event = createDomEvent('Event', 'contextmenu');
      expect(event.defaultPrevented, isFalse);
      target.dispatchEvent(event);
      expect(event.defaultPrevented, isFalse);

      // Enabling again has no effect.
      strategy.enableContextMenu();
      event = createDomEvent('Event', 'contextmenu');
      expect(event.defaultPrevented, isFalse);
      target.dispatchEvent(event);
      expect(event.defaultPrevented, isFalse);
    });
  });
}
