// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('browser')

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine/dom.dart';
import 'package:ui/src/engine/view_embedder/dimensions_provider/custom_element_dimensions_provider.dart';
import 'package:ui/src/engine/view_embedder/dimensions_provider/dimensions_provider.dart';
import 'package:ui/src/engine/view_embedder/dimensions_provider/full_page_dimensions_provider.dart';
import 'package:ui/src/engine/window.dart';

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
      window.debugOverrideDevicePixelRatio(33930);

      final DimensionsProvider provider = DimensionsProvider.create();

      expect(provider.getDevicePixelRatio(), 33930);
    });
  });
}
