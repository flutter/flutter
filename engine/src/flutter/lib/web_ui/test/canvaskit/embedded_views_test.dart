// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
import 'dart:async';
import 'dart:html' as html;

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

import 'common.dart';

const MethodCodec codec = StandardMethodCodec();
final EngineSingletonFlutterWindow window =
    EngineSingletonFlutterWindow(0, EnginePlatformDispatcher.instance);

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('HtmlViewEmbedder', () {
    setUpCanvasKitTest();

    test('embeds interactive platform views', () async {
      ui.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (viewId) => html.DivElement()..id = 'view-0',
      );
      await _createPlatformView(0, 'test-platform-view');

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;
      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      dispatcher.rasterizer!.draw(sb.build().layerTree);
      expect(
        domRenderer.sceneElement!
            .querySelectorAll('#view-0')
            .single
            .style
            .pointerEvents,
        'auto',
      );
    });

    test('clips platform views with RRects', () async {
      ui.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (viewId) => html.DivElement()..id = 'view-0',
      );
      await _createPlatformView(0, 'test-platform-view');

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;
      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.pushClipRRect(ui.RRect.fromLTRBR(0, 0, 10, 10, ui.Radius.circular(3)));
      sb.addPlatformView(0, width: 10, height: 10);
      dispatcher.rasterizer!.draw(sb.build().layerTree);
      expect(
        domRenderer.sceneElement!.querySelectorAll('#sk_path_defs').single,
        isNotNull,
      );
      expect(
        domRenderer.sceneElement!
            .querySelectorAll('#sk_path_defs')
            .single
            .querySelectorAll('clipPath')
            .single,
        isNotNull,
      );
      expect(
        domRenderer.sceneElement!
            .querySelectorAll('flt-clip')
            .single
            .style
            .clipPath,
        'url("#svgClip1")',
      );
    });
    test('correctly transforms platform views', () async {
      ui.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (viewId) => html.DivElement()..id = 'view-0',
      );
      await _createPlatformView(0, 'test-platform-view');

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;
      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      Matrix4 scaleMatrix = Matrix4.identity()
        ..scale(5, 5)
        ..translate(100, 100);
      sb.pushTransform(scaleMatrix.toFloat64());
      sb.pushOffset(3, 3);
      sb.addPlatformView(0, width: 10, height: 10);
      dispatcher.rasterizer!.draw(sb.build().layerTree);
      expect(
        domRenderer.sceneElement!
            .querySelectorAll('#view-0')
            .single
            .style
            .transform,
        // We should apply the scale matrix first, then the offset matrix.
        // So the translate should be 515 (5 * 100 + 5 * 3), and not
        // 503 (5 * 100 + 3).
        'matrix3d(5, 0, 0, 0, 0, 5, 0, 0, 0, 0, 5, 0, 515, 515, 0, 1)',
      );
    });

    test('renders overlays on top of platform views', () async {
      expect(OverlayCache.instance.debugLength, 0);
      final CkPicture testPicture = paintPicture(
        ui.Rect.fromLTRB(0, 0, 10, 10),
        (CkCanvas canvas) {
          canvas.drawCircle(ui.Offset(5, 5), 5, CkPaint());
        }
      );

      // Initialize all platform views to be used in the test.
      final List<int> platformViewIds = <int>[];
      for (int i = 0; i < OverlayCache.kDefaultCacheSize * 2; i++) {
        ui.platformViewRegistry.registerViewFactory(
          'test-platform-view',
          (viewId) => html.DivElement()..id = 'view-$i',
        );
        await _createPlatformView(i, 'test-platform-view');
        platformViewIds.add(i);
      }

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;

      void renderTestScene({ required int viewCount }) {
        LayerSceneBuilder sb = LayerSceneBuilder();
        sb.pushOffset(0, 0);
        for (int i = 0; i < viewCount; i++) {
          sb.addPicture(ui.Offset.zero, testPicture);
          sb.addPlatformView(i, width: 10, height: 10);
        }
        dispatcher.rasterizer!.draw(sb.build().layerTree);
      }

      int countCanvases() {
        return domRenderer.sceneElement!.querySelectorAll('canvas').length;
      }

      // Frame 1:
      //   Render: up to cache size platform views.
      //   Expect: main canvas plus platform view overlays; empty cache.
      renderTestScene(viewCount: OverlayCache.kDefaultCacheSize);
      expect(countCanvases(), OverlayCache.kDefaultCacheSize + 1);
      expect(OverlayCache.instance.debugLength, 0);

      // Frame 2:
      //   Render: zero platform views.
      //   Expect: main canvas, no overlays; overlays in the cache.
      await Future<void>.delayed(Duration.zero);
      renderTestScene(viewCount: 0);
      expect(countCanvases(), 1);
      expect(OverlayCache.instance.debugLength, 5);

      // Frame 3:
      //   Render: less than cache size platform views.
      //   Expect: overlays reused; cache shrinks.
      await Future<void>.delayed(Duration.zero);
      renderTestScene(viewCount: OverlayCache.kDefaultCacheSize - 2);
      expect(countCanvases(), OverlayCache.kDefaultCacheSize - 1);
      expect(OverlayCache.instance.debugLength, 2);

      // Frame 4:
      //   Render: more platform views than max cache size.
      //   Expect: cache empty (everything reused).
      await Future<void>.delayed(Duration.zero);
      renderTestScene(viewCount: OverlayCache.kDefaultCacheSize * 2);
      expect(countCanvases(), OverlayCache.kDefaultCacheSize * 2 + 1);
      expect(OverlayCache.instance.debugLength, 0);

      // Frame 5:
      //   Render: zero platform views.
      //   Expect: main canvas, no overlays; cache full but does not exceed limit.
      await Future<void>.delayed(Duration.zero);
      renderTestScene(viewCount: 0);
      expect(countCanvases(), 1);
      expect(OverlayCache.instance.debugLength, 5);

      // Frame 6:
      //   Render: deleted platform views.
      //   Expect: error.
      for (final int id in platformViewIds) {
        final codec = StandardMethodCodec();
        final Completer<void> completer = Completer<void>();
        ui.window.sendPlatformMessage(
          'flutter/platform_views',
          codec.encodeMethodCall(MethodCall(
            'dispose',
            id,
          )),
          completer.complete,
        );
        await completer.future;
      }

      try {
        renderTestScene(viewCount: platformViewIds.length);
        fail('Expected to throw');
      } on AssertionError catch (error) {
        expect(
          error.toString(),
          'Assertion failed: "Cannot render platform view 0. It has not been created, or it has been deleted."',
        );
      }
    });
    // TODO: https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}

// Sends a platform message to create a Platform View with the given id and viewType.
Future<void> _createPlatformView(int id, String viewType) {
  final completer = Completer<void>();
  window.sendPlatformMessage(
    'flutter/platform_views',
    codec.encodeMethodCall(MethodCall(
      'create',
      <String, dynamic>{
        'id': id,
        'viewType': viewType,
      },
    )),
    (dynamic _) => completer.complete(),
  );
  return completer.future;
}
