// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart' as engine;
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import '../common/rendering.dart';
import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpUnitTests(withImplicitView: true, setUpTestViewDimensions: false);

  test('Onscreen canvas has position: absolute', () async {
    // Force multi-surface mode to ensure OnscreenCanvasProvider is used.
    engine.debugOverrideJsConfiguration(
      <String, Object?>{'canvasKitForceMultiSurfaceRasterizer': true}.jsify()
          as engine.JsFlutterConfiguration?,
    );
    // Reset the renderer to ensure it is created with the new configuration.
    engine.renderer.debugResetRasterizer();
    engine.renderer.debugClear();

    const platformViewType = 'test-platform-view';
    ui_web.platformViewRegistry.registerViewFactory(platformViewType, (int viewId) {
      final DomElement element = createDomHTMLDivElement();
      element.id = 'view-$viewId';
      return element;
    });

    await createPlatformView(0, platformViewType);

    // Create a scene with a platform view and some drawing to trigger canvas creation.
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, 100, 100),
      ui.Paint()..color = const ui.Color(0xFFFF0000),
    );
    final ui.Picture picture = recorder.endRecording();

    final sb = ui.SceneBuilder();
    sb.pushOffset(0, 0);
    sb.addPlatformView(0, width: 100, height: 100);
    sb.addPicture(ui.Offset.zero, picture);

    await renderScene(sb.build());

    // Find the canvas element.
    final DomElement canvasElement = (implicitView as engine.EngineFlutterView).dom.sceneHost
        .querySelectorAll('canvas')
        .single;

    // Verify position is absolute.
    expect(
      canvasElement.style.position,
      'absolute',
      reason: 'Canvas should have position: absolute',
    );

    engine.debugOverrideJsConfiguration(null);
  });
}
