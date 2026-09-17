// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  setUpCanvasKitTest(withImplicitView: true);

  test('always uses SingleSurfaceRasterizer', () {
    expect(
      CanvasKitRenderer.instance.rasterizer.runtimeType.toString(),
      equals('SingleSurfaceRasterizer'),
    );
  });

  test('ignores canvasKitForceMultiSurfaceRasterizer and uses SingleSurfaceRasterizer', () {
    debugOverrideJsConfiguration(
      <String, Object?>{'canvasKitForceMultiSurfaceRasterizer': true}.jsify()
          as JsFlutterConfiguration?,
    );
    CanvasKitRenderer.instance.debugResetRasterizer();
    expect(
      CanvasKitRenderer.instance.rasterizer.runtimeType.toString(),
      equals('SingleSurfaceRasterizer'),
    );
  });
}
