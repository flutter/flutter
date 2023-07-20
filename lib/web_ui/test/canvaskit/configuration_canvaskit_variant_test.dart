// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import 'common.dart';

@JS('_flutter_canvaskit_variant_for_test_only')
external String? get _flutterCanvaskitVariantForTestOnly;

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  setUpCanvasKitTest();

  // This is to make sure we don't accidentally run the CanvasKit test suite in
  // auto mode. The CanvasKit variant should always be deterministic.
  test('CanvasKit tests always run with a specific variant', () {
    expect(
      configuration.canvasKitVariant,
      anyOf(CanvasKitVariant.chromium, CanvasKitVariant.full),
    );
    expect(
      _flutterCanvaskitVariantForTestOnly,
      anyOf('chromium', 'full'),
    );
  });

  // This is to make sure that the variant specified by the test harness is
  // correctly preserved during tests in the global `configuration` object.
  test('CanvasKitVariant configuration is preserved in tests', () {
    expect(
      configuration.canvasKitVariant,
      CanvasKitVariant.values.byName(_flutterCanvaskitVariantForTestOnly!),
    );
  });
}
