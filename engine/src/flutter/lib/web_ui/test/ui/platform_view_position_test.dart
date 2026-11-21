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

  test('base onscreen canvas is not positioned as an overlay', () async {
    if (!isCanvasKit) {
      return;
    }

    // Force multi-surface mode to ensure OnscreenCanvasProvider is used.
    engine.debugOverrideJsConfiguration(
      <String, Object?>{'canvasKitForceMultiSurfaceRasterizer': true}.jsify()
          as engine.JsFlutterConfiguration?,
    );
    // Reset the renderer to ensure it is created with the new configuration.
    engine.renderer.debugResetRasterizer();
    engine.renderer.debugClear();

    // Create a scene with only Flutter content. This uses the base canvas, not
    // an overlay canvas interleaved with platform views.
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, 100, 100),
      ui.Paint()..color = const ui.Color(0xFFFF0000),
    );

    final sb = ui.SceneBuilder();
    sb.addPicture(ui.Offset.zero, recorder.endRecording());

    await renderScene(sb.build());

    final DomElement canvasElement = (implicitView as engine.EngineFlutterView).dom.sceneHost
        .querySelectorAll('canvas')
        .single;

    expect(
      canvasElement.style.position,
      isNot('absolute'),
      reason: 'Base canvas should not be styled as a platform-view overlay.',
    );

    engine.debugOverrideJsConfiguration(null);
  });

  test('Onscreen overlay canvas has position: absolute', () async {
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

    final DomElement canvasElement = (implicitView as engine.EngineFlutterView).dom.sceneHost
        .querySelectorAll('canvas')
        .single;

    expect(
      canvasElement.style.position,
      'absolute',
      reason: 'Overlay canvas should have position: absolute.',
    );

    engine.debugOverrideJsConfiguration(null);
  });

  test('Platform view slot coordinates are anchored to top-left even in RTL document', () async {
    final String? previousDir = domDocument.documentElement!.getAttribute('dir');
    try {
      domDocument.documentElement!.setAttribute('dir', 'rtl');

      const platformViewType = 'test-platform-view-rtl';
      ui_web.platformViewRegistry.registerViewFactory(platformViewType, (int viewId) {
        final DomElement element = createDomHTMLDivElement();
        element.id = 'view-rtl-$viewId';
        return element;
      });

      await createPlatformView(10, platformViewType);

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(
        const ui.Rect.fromLTWH(0, 0, 100, 100),
        ui.Paint()..color = const ui.Color(0xFFFF0000),
      );
      final ui.Picture picture = recorder.endRecording();

      final sb = ui.SceneBuilder();
      sb.pushOffset(50, 60);
      sb.addPlatformView(10, width: 100, height: 100);
      sb.addPicture(ui.Offset.zero, picture);

      await renderScene(sb.build());

      final DomElement slot = (implicitView as engine.EngineFlutterView).dom.sceneHost
          .querySelector('flt-platform-view-slot')!;

      expect(slot.style.position, 'absolute');
      expect(slot.style.top, '0px');
      expect(slot.style.left, '0px');

      final DomRect slotRect = slot.getBoundingClientRect();
      final DomRect viewRect = (implicitView as engine.EngineFlutterView).dom.rootElement
          .getBoundingClientRect();

      // In an RTL document, if slot left was not explicitly anchored to 0, it would
      // fall back to static position at the right edge of the containing block,
      // ending up far offscreen. With top: 0 and left: 0, slotRect.left matches
      // viewRect.left + 50.
      expect(slotRect.left, closeTo(viewRect.left + 50, 1.0));
      expect(slotRect.top, closeTo(viewRect.top + 60, 1.0));

      // Verify that embedded HTML element with no dir of its own inherits the
      // page's ambient RTL direction.
      final DomElement element = (implicitView as engine.EngineFlutterView).dom.platformViewsHost
          .querySelector('#view-rtl-10')!;
      expect(domWindow.getComputedStyle(element).getPropertyValue('direction'), 'rtl');
    } finally {
      if (previousDir != null) {
        domDocument.documentElement!.setAttribute('dir', previousDir);
      } else {
        domDocument.documentElement!.removeAttribute('dir');
      }
    }
  });
}
