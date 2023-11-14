// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')
library;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => doTests);
}

void doTests() {
  group('Factory', () {
    test('Creates a FullPage instance when hostElement is null', () async {
      final DimensionsProvider provider = DimensionsProvider.create();

      expect(provider, isA<FullPageDimensionsProvider>());
    });

    test('Creates a CustomElement instance when hostElement is not null',
        () async {
      final DomElement element = createDomElement('some-random-element');
      final DimensionsProvider provider = DimensionsProvider.create(
        hostElement: element,
      );

      expect(provider, isA<CustomElementDimensionsProvider>());
    });
  });

  group('getDevicePixelRatio', () {
    test('Returns the correct pixelRatio', () async {
      // Override the DPI to something known, but weird...
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(33930);

      final DimensionsProvider provider = DimensionsProvider.create();

      expect(provider.getDevicePixelRatio(), 33930);
    });
  });
}
