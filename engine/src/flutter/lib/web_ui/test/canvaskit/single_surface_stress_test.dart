// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import 'common.dart';

EngineFlutterWindow get implicitView => EnginePlatformDispatcher.instance.implicitView!;

SingleSurfaceRasterizer get singleSurfaceRasterizer =>
    CanvasKitRenderer.instance.rasterizer as SingleSurfaceRasterizer;

SingleSurfaceViewRasterizer getImplicitViewRasterizer() =>
    singleSurfaceRasterizer.createViewRasterizer(implicitView);

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> createPlatformView(int id, String viewType) {
  final completer = Completer<void>();
  const MethodCodec codec = StandardMethodCodec();
  ui.PlatformDispatcher.instance.sendPlatformMessage(
    'flutter/platform_views',
    codec.encodeMethodCall(MethodCall('create', <String, dynamic>{'id': id, 'viewType': viewType})),
    (dynamic _) => completer.complete(),
  );
  return completer.future;
}

ui.Picture drawTestPicture([ui.Color color = const ui.Color(0xFF00FF00)]) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 100, 100), ui.Paint()..color = color);
  return recorder.endRecording();
}

void testMain() {
  group('SingleSurfaceRasterizer hostile stress tests', () {
    setUpCanvasKitTest(withImplicitView: true);

    tearDown(() {
      implicitView.debugPhysicalSizeOverride = null;
      implicitView.debugForceResize();
      PlatformViewManager.instance.debugClear();
      renderer.debugClear();
    });

    group('Null & Empty Boundary States', () {
      test('handles zero and empty frame dimensions without throwing', () async {
        implicitView.debugPhysicalSizeOverride = ui.Size.zero;
        implicitView.debugForceResize();
        expect(implicitView.physicalSize.isEmpty, isTrue);

        final sb1 = ui.SceneBuilder();
        sb1.pushOffset(0, 0);
        sb1.addPicture(ui.Offset.zero, drawTestPicture());
        await CanvasKitRenderer.instance.renderScene(sb1.build(), implicitView);

        // Zero width with non-zero height
        implicitView.debugPhysicalSizeOverride = const ui.Size(0, 400);
        implicitView.debugForceResize();
        expect(implicitView.physicalSize.isEmpty, isTrue);

        final sb2 = ui.SceneBuilder();
        sb2.pushOffset(0, 0);
        sb2.addPicture(ui.Offset.zero, drawTestPicture());
        await CanvasKitRenderer.instance.renderScene(sb2.build(), implicitView);

        // Non-zero width with zero height
        implicitView.debugPhysicalSizeOverride = const ui.Size(400, 0);
        implicitView.debugForceResize();
        expect(implicitView.physicalSize.isEmpty, isTrue);

        final sb3 = ui.SceneBuilder();
        sb3.pushOffset(0, 0);
        sb3.addPicture(ui.Offset.zero, drawTestPicture());
        await CanvasKitRenderer.instance.renderScene(sb3.build(), implicitView);

        // Restore valid physical size and verify normal rendering resumes cleanly
        implicitView.debugPhysicalSizeOverride = const ui.Size(400, 400);
        implicitView.debugForceResize();
        expect(implicitView.physicalSize.isEmpty, isFalse);

        final sb4 = ui.SceneBuilder();
        sb4.pushOffset(0, 0);
        sb4.addPicture(ui.Offset.zero, drawTestPicture());
        await CanvasKitRenderer.instance.renderScene(sb4.build(), implicitView);
      });

      test('handles platform view with zero or negative width and height', () async {
        const platformViewType = 'test-zero-neg-pv';
        ui_web.platformViewRegistry.registerViewFactory(platformViewType, (int viewId) {
          final DomElement element = createDomHTMLDivElement();
          element.id = 'pv-$viewId';
          return element;
        });
        await createPlatformView(20, platformViewType);

        implicitView.debugPhysicalSizeOverride = const ui.Size(400, 400);
        implicitView.debugForceResize();

        // Zero width and zero height
        final sbZero = ui.SceneBuilder();
        sbZero.pushOffset(0, 0);
        sbZero.addPlatformView(20);
        await CanvasKitRenderer.instance.renderScene(sbZero.build(), implicitView);

        // Negative width and height
        final sbNeg = ui.SceneBuilder();
        sbNeg.pushOffset(0, 0);
        sbNeg.addPlatformView(20, width: -100, height: -50);
        await CanvasKitRenderer.instance.renderScene(sbNeg.build(), implicitView);

        // Mixed dimensions (positive width, negative height)
        final sbMixed = ui.SceneBuilder();
        sbMixed.pushOffset(0, 0);
        sbMixed.addPlatformView(20, width: 50, height: -50);
        await CanvasKitRenderer.instance.renderScene(sbMixed.build(), implicitView);

        // Normal dimensions
        final sbNormal = ui.SceneBuilder();
        sbNormal.pushOffset(0, 0);
        sbNormal.addPlatformView(20, width: 50, height: 50);
        await CanvasKitRenderer.instance.renderScene(sbNormal.build(), implicitView);
      });

      test('handles platform view with unregistered viewId gracefully', () async {
        const unregisteredViewId = 987654;
        expect(PlatformViewManager.instance.getSlottedContent(unregisteredViewId), isNull);

        implicitView.debugPhysicalSizeOverride = const ui.Size(400, 400);
        implicitView.debugForceResize();

        // Frame 1: render scene with unregistered viewId
        final sb1 = ui.SceneBuilder();
        sb1.pushOffset(0, 0);
        sb1.addPlatformView(unregisteredViewId, width: 100, height: 100);
        await CanvasKitRenderer.instance.renderScene(sb1.build(), implicitView);

        // Frame 2: render scene without that viewId
        final sb2 = ui.SceneBuilder();
        sb2.pushOffset(0, 0);
        sb2.addPicture(ui.Offset.zero, drawTestPicture());
        await CanvasKitRenderer.instance.renderScene(sb2.build(), implicitView);
      });
    });

    group('Lifecycle & Rapid Disposal / Re-entrancy', () {
      test('repeatedly disposing and recreating textures in PlatformViewTextureCache', () {
        final SingleSurfaceViewRasterizer rasterizer = getImplicitViewRasterizer();
        final PlatformViewTextureCache cache = rasterizer.surface.textureCache;

        for (var iteration = 0; iteration < 50; iteration++) {
          final WebGLTexture tex1 = cache.getOrCreateTexture(1);
          final WebGLTexture tex2 = cache.getOrCreateTexture(2);
          final WebGLTexture tex3 = cache.getOrCreateTexture(3);

          expect(cache.getOrCreateTexture(1), same(tex1));
          expect(cache.getOrCreateTexture(2), same(tex2));
          expect(cache.getOrCreateTexture(3), same(tex3));

          cache.disposeView(1);
          cache.disposeView(2);

          final WebGLTexture newTex1 = cache.getOrCreateTexture(1);
          expect(newTex1, isNotNull);

          cache.dispose();
        }
      });

      test('re-entrant cleanup and idempotent dispose calls', () {
        final testView = EngineFlutterView(
          EnginePlatformDispatcher.instance,
          createDomElement('div'),
        );
        final SingleSurfaceViewRasterizer testRasterizer = singleSurfaceRasterizer
            .createViewRasterizer(testView);

        testRasterizer.surface.textureCache.getOrCreateTexture(1);
        testRasterizer.surface.textureCache.getOrCreateTexture(2);

        expect(() => testRasterizer.dispose(), returnsNormally);
        expect(() => testRasterizer.dispose(), returnsNormally);
        expect(() => testRasterizer.dispose(), returnsNormally);

        expect(() => testRasterizer.surface.textureCache.dispose(), returnsNormally);
        expect(() => testRasterizer.surface.textureCache.dispose(), returnsNormally);

        expect(() => testRasterizer.surface.dispose(), returnsNormally);
        expect(() => testRasterizer.surface.dispose(), returnsNormally);
      });

      test('platform view removed from scene clears geometry and detaches from DOM', () async {
        const platformViewType = 'test-lifecycle-pv';
        ui_web.platformViewRegistry.registerViewFactory(platformViewType, (int viewId) {
          final DomElement element = createDomHTMLDivElement();
          element.id = 'pv-$viewId';
          return element;
        });
        await createPlatformView(42, platformViewType);

        final SingleSurfaceViewRasterizer rasterizer = getImplicitViewRasterizer();
        final DomElement element = PlatformViewManager.instance.getSlottedContent(42)!;
        final canvasElement = rasterizer.surface.canvas as DomElement;

        implicitView.debugPhysicalSizeOverride = const ui.Size(400, 400);
        implicitView.debugForceResize();

        // Frame 1: Scene with view 42
        final sb1 = ui.SceneBuilder();
        sb1.pushOffset(0, 0);
        sb1.addPlatformView(42, width: 100, height: 100);
        await CanvasKitRenderer.instance.renderScene(sb1.build(), implicitView);

        expect(element.parent, equals(canvasElement));
        expect(element.getAttribute('drawable'), isNotNull);

        // Frame 2: Scene WITHOUT view 42
        final sb2 = ui.SceneBuilder();
        sb2.pushOffset(0, 0);
        sb2.addPicture(ui.Offset.zero, drawTestPicture());
        await CanvasKitRenderer.instance.renderScene(sb2.build(), implicitView);

        expect(element.parent, isNull, reason: 'Element should be detached from DOM');

        // Frame 3: Scene with view 42 re-added
        final sb3 = ui.SceneBuilder();
        sb3.pushOffset(0, 0);
        sb3.addPlatformView(42, width: 100, height: 100);
        await CanvasKitRenderer.instance.renderScene(sb3.build(), implicitView);

        expect(
          element.parent,
          equals(canvasElement),
          reason: 'Element should be re-attached to DOM',
        );
      });
    });

    group('Concurrency & Microtask Turn Ordering', () {
      test('rapid sequential frame rasterizations in the same microtask turn', () async {
        implicitView.debugPhysicalSizeOverride = const ui.Size(400, 400);
        implicitView.debugForceResize();

        final futures = <Future<void>>[];
        for (var i = 0; i < 20; i++) {
          final sb = ui.SceneBuilder();
          sb.pushOffset(0, 0);
          sb.addPicture(ui.Offset.zero, drawTestPicture(ui.Color(0xFF000000 + i)));
          futures.add(CanvasKitRenderer.instance.renderScene(sb.build(), implicitView));
        }

        await Future.wait(futures);

        final SingleSurfaceViewRasterizer rasterizer = getImplicitViewRasterizer();
        final drawFutures = <Future<void>>[];
        for (var i = 0; i < 10; i++) {
          final sb = ui.SceneBuilder();
          sb.pushOffset(0, 0);
          sb.addPicture(ui.Offset.zero, drawTestPicture());
          final scene = sb.build() as LayerScene;
          drawFutures.add(rasterizer.draw(scene.layerTree, null));
        }

        await Future.wait(drawFutures);
      });

      test('interleaving multiple platform views with Flutter draw operations across rapid frame dispatches', () async {
        const platformViewType = 'test-interleaving-pv';
        ui_web.platformViewRegistry.registerViewFactory(platformViewType, (int viewId) {
          final DomElement element = createDomHTMLDivElement();
          element.id = 'interleaving-pv-$viewId';
          return element;
        });
        await createPlatformView(201, platformViewType);
        await createPlatformView(202, platformViewType);
        await createPlatformView(203, platformViewType);

        final SingleSurfaceViewRasterizer rasterizer = getImplicitViewRasterizer();
        final canvasElement = rasterizer.surface.canvas as DomElement;
        final DomElement el201 = PlatformViewManager.instance.getSlottedContent(201)!;
        final DomElement el202 = PlatformViewManager.instance.getSlottedContent(202)!;
        final DomElement el203 = PlatformViewManager.instance.getSlottedContent(203)!;

        implicitView.debugPhysicalSizeOverride = const ui.Size(400, 400);
        implicitView.debugForceResize();

        final sb1 = ui.SceneBuilder();
        sb1.pushOffset(0, 0);
        sb1.addPicture(ui.Offset.zero, drawTestPicture(const ui.Color(0xFF111111)));
        sb1.addPlatformView(201, width: 50, height: 50);
        sb1.addPicture(const ui.Offset(50, 50), drawTestPicture(const ui.Color(0xFF222222)));
        sb1.addPlatformView(202, width: 50, height: 50);

        final sb2 = ui.SceneBuilder();
        sb2.pushOffset(0, 0);
        sb2.addPlatformView(202, width: 60, height: 60);
        sb2.addPicture(ui.Offset.zero, drawTestPicture(const ui.Color(0xFF333333)));
        sb2.addPlatformView(203, width: 60, height: 60);

        final sb3 = ui.SceneBuilder();
        sb3.pushOffset(0, 0);
        sb3.addPicture(ui.Offset.zero, drawTestPicture(const ui.Color(0xFF444444)));

        final sb4 = ui.SceneBuilder();
        sb4.pushOffset(0, 0);
        sb4.addPlatformView(201, width: 70, height: 70);
        sb4.addPlatformView(203, width: 70, height: 70);
        sb4.addPicture(ui.Offset.zero, drawTestPicture(const ui.Color(0xFF555555)));

        final sb5 = ui.SceneBuilder();
        sb5.pushOffset(0, 0);
        sb5.addPicture(ui.Offset.zero, drawTestPicture(const ui.Color(0xFF666666)));
        sb5.addPlatformView(201, width: 80, height: 80);
        sb5.addPicture(const ui.Offset(10, 10), drawTestPicture(const ui.Color(0xFF777777)));
        sb5.addPlatformView(202, width: 80, height: 80);
        sb5.addPicture(const ui.Offset(20, 20), drawTestPicture(const ui.Color(0xFF888888)));
        sb5.addPlatformView(203, width: 80, height: 80);

        final Future<void> f1 = CanvasKitRenderer.instance.renderScene(sb1.build(), implicitView);
        final Future<void> f2 = CanvasKitRenderer.instance.renderScene(sb2.build(), implicitView);
        final Future<void> f3 = CanvasKitRenderer.instance.renderScene(sb3.build(), implicitView);
        final Future<void> f4 = CanvasKitRenderer.instance.renderScene(sb4.build(), implicitView);
        final Future<void> f5 = CanvasKitRenderer.instance.renderScene(sb5.build(), implicitView);

        await Future.wait(<Future<void>>[f1, f2, f3, f4, f5]);

        expect(el201.parent, equals(canvasElement));
        expect(el202.parent, equals(canvasElement));
        expect(el203.parent, equals(canvasElement));

        final sb6 = ui.SceneBuilder();
        sb6.pushOffset(0, 0);
        sb6.addPicture(ui.Offset.zero, drawTestPicture(const ui.Color(0xFF999999)));
        await CanvasKitRenderer.instance.renderScene(sb6.build(), implicitView);

        expect(el201.parent, isNull);
        expect(el202.parent, isNull);
        expect(el203.parent, isNull);
      });
    });
  });
}
