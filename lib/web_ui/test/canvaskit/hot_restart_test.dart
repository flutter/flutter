// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import 'package:ui/ui.dart' as ui;

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('initialize', () {
    test(
        're-uses the same initialized instance if it is already set on the window',
        () async {
      expect(windowFlutterCanvasKit, isNull);

      DomRenderer();
      await ui.webOnlyInitializePlatform(
          assetManager: WebOnlyMockAssetManager());
      expect(windowFlutterCanvasKit, isNotNull);

      var firstCanvasKitInstance = windowFlutterCanvasKit;

      // Triggers a reset of the CanvasKit script element.
      DomRenderer();
      await ui.webOnlyInitializePlatform(
          assetManager: WebOnlyMockAssetManager());
      // The instance is the same.
      expect(firstCanvasKitInstance, windowFlutterCanvasKit);
    });
    // TODO: https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}
