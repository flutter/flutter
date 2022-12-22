// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')

import 'package:js/js_util.dart';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/dom.dart';
import 'package:ui/src/engine/view_embedder/hot_restart_cache_handler.dart';

void main() {
  internalBootstrapBrowserTest(() => doTests);
}

void doTests() {
  group('Constructor', () {
    test('Creates a cache in the JS environment', () async {
      final HotRestartCacheHandler cache = HotRestartCacheHandler();

      expect(cache, isNotNull);

      final List<DomElement?>? domCache = getDomCache();

      expect(domCache, isNotNull);
      expect(domCache, isEmpty);
    });
  });

  group('registerElement', () {
    HotRestartCacheHandler? cache;
    List<DomElement?>? domCache;

    setUp(() {
      cache = HotRestartCacheHandler();
      domCache = getDomCache();
    });

    test('Registers an element in the DOM cache', () async {
      final DomElement element = createDomElement('for-test');
      cache!.registerElement(element);

      expect(domCache, hasLength(1));
      expect(domCache!.last, element);
    });

    test('Registers elements in the DOM cache', () async {
      final DomElement element = createDomElement('for-test');
      domDocument.body!.append(element);

      cache!.registerElement(element);

      expect(domCache, hasLength(1));
      expect(domCache!.last, element);
    });

    test('Clears registered elements from the DOM and the cache upon restart',
        () async {
      final DomElement element = createDomElement('for-test');
      final DomElement element2 = createDomElement('for-test-two');
      domDocument.body!.append(element);
      domDocument.body!.append(element2);

      cache!.registerElement(element);

      expect(element.isConnected, isTrue);
      expect(element2.isConnected, isTrue);

      // Simulate a hot restart...
      cache = HotRestartCacheHandler();

      expect(domCache, hasLength(0));
      expect(element.isConnected, isFalse); // Removed
      expect(element2.isConnected, isTrue);
    });
  });
}

List<DomElement?>? getDomCache() => getProperty<List<DomElement?>?>(
    domWindow, HotRestartCacheHandler.defaultCacheName);
