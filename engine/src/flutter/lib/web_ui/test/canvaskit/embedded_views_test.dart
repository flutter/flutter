// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';

const MethodCodec codec = StandardMethodCodec();

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('$HtmlViewEmbedder', () {
    setUpCanvasKitTest();

    setUp(() {
      window.debugOverrideDevicePixelRatio(1);
    });

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

      // The platform view is now split in two parts. The contents live
      // as a child of the glassPane, and the slot lives in the glassPane
      // shadow root. The slot is the one that has pointer events auto.
      final contents = domRenderer.glassPaneElement!.querySelector('#view-0')!;
      final slot = domRenderer.sceneElement!.querySelector('slot')!;
      final contentsHost = contents.parent!;
      final slotHost = slot.parent!;

      expect(contents, isNotNull,
          reason: 'The view from the factory is injected in the DOM.');

      expect(contentsHost.tagName, equalsIgnoringCase('flt-platform-view'));
      expect(slotHost.tagName, equalsIgnoringCase('flt-platform-view-slot'));

      expect(slotHost.style.pointerEvents, 'auto',
          reason: 'The slot reenables pointer events.');
      expect(contentsHost.getAttribute('slot'), slot.getAttribute('name'),
          reason: 'The contents and slot are correctly related.');
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

      // Transformations happen on the slot element.
      final html.Element slotHost =
          domRenderer.sceneElement!.querySelector('flt-platform-view-slot')!;

      expect(
        slotHost.style.transform,
        // We should apply the scale matrix first, then the offset matrix.
        // So the translate should be 515 (5 * 100 + 5 * 3), and not
        // 503 (5 * 100 + 3).
        'matrix3d(5, 0, 0, 0, 0, 5, 0, 0, 0, 0, 5, 0, 515, 515, 0, 1)',
      );
    });

    // Returns the list of CSS transforms applied to the ancestor chain of
    // elements starting from `viewHost`, up until and excluding <flt-scene>.
    List<String> getTransformChain(html.Element viewHost) {
      final List<String> chain = <String>[];
      html.Element? element = viewHost;
      while (element != null && element.tagName.toLowerCase() != 'flt-scene') {
        chain.add(element.style.transform);
        element = element.parent;
      }
      return chain;
    }

    test('converts device pixels to logical pixels (no clips)', () async {
      window.debugOverrideDevicePixelRatio(4);
      ui.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (viewId) => html.DivElement()..id = 'view-0',
      );
      await _createPlatformView(0, 'test-platform-view');

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;
      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(1, 1);
      sb.pushOffset(2, 2);
      sb.pushOffset(3, 3);
      sb.addPlatformView(0, width: 10, height: 10);
      dispatcher.rasterizer!.draw(sb.build().layerTree);

      // Transformations happen on the slot element.
      final html.Element slotHost =
          domRenderer.sceneElement!.querySelector('flt-platform-view-slot')!;

      expect(
        getTransformChain(slotHost),
        <String>['matrix(0.25, 0, 0, 0.25, 1.5, 1.5)'],
      );
    });

    test('converts device pixels to logical pixels (with clips)', () async {
      window.debugOverrideDevicePixelRatio(4);
      ui.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (viewId) => html.DivElement()..id = 'view-0',
      );
      await _createPlatformView(0, 'test-platform-view');

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;
      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(3, 3);
      sb.pushClipRect(ui.Rect.largest);
      sb.pushOffset(6, 6);
      sb.pushClipRect(ui.Rect.largest);
      sb.pushOffset(9, 9);
      sb.addPlatformView(0, width: 10, height: 10);
      dispatcher.rasterizer!.draw(sb.build().layerTree);

      // Transformations happen on the slot element.
      final html.Element slotHost =
          domRenderer.sceneElement!.querySelector('flt-platform-view-slot')!;

      expect(
        getTransformChain(slotHost),
        <String>[
          'matrix(1, 0, 0, 1, 9, 9)',
          'matrix(1, 0, 0, 1, 6, 6)',
          'matrix(0.25, 0, 0, 0.25, 0.75, 0.75)',
        ],
      );
    });

    test('renders overlays on top of platform views', () async {
      expect(SurfaceFactory.instance.debugCacheSize, 0);
      final CkPicture testPicture =
          paintPicture(ui.Rect.fromLTRB(0, 0, 10, 10), (CkCanvas canvas) {
        canvas.drawCircle(ui.Offset(5, 5), 5, CkPaint());
      });

      // Initialize all platform views to be used in the test.
      final List<int> platformViewIds = <int>[];
      for (int i = 0; i < HtmlViewEmbedder.maximumOverlaySurfaces * 2; i++) {
        ui.platformViewRegistry.registerViewFactory(
          'test-platform-view',
          (viewId) => html.DivElement()..id = 'view-$i',
        );
        await _createPlatformView(i, 'test-platform-view');
        platformViewIds.add(i);
      }

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;

      void renderTestScene({required int viewCount}) {
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
      renderTestScene(viewCount: HtmlViewEmbedder.maximumOverlaySurfaces);
      expect(countCanvases(), HtmlViewEmbedder.maximumOverlaySurfaces);
      expect(SurfaceFactory.instance.debugCacheSize, 0);

      // Frame 2:
      //   Render: zero platform views.
      //   Expect: main canvas, no overlays; overlays in the cache.
      await Future<void>.delayed(Duration.zero);
      renderTestScene(viewCount: 0);
      expect(countCanvases(), 1);
      // The cache contains all the surfaces except the base surface and the
      // backup surface.
      expect(SurfaceFactory.instance.debugCacheSize,
          HtmlViewEmbedder.maximumOverlaySurfaces - 2);

      // Frame 3:
      //   Render: less than cache size platform views.
      //   Expect: overlays reused; cache shrinks.
      await Future<void>.delayed(Duration.zero);
      renderTestScene(viewCount: HtmlViewEmbedder.maximumOverlaySurfaces - 2);
      expect(countCanvases(), HtmlViewEmbedder.maximumOverlaySurfaces - 1);
      expect(SurfaceFactory.instance.debugCacheSize, 0);

      // Frame 4:
      //   Render: more platform views than max cache size.
      //   Expect: main canvas, backup overlay, maximum overlays;
      //           cache empty (everything reused).
      await Future<void>.delayed(Duration.zero);
      renderTestScene(viewCount: HtmlViewEmbedder.maximumOverlaySurfaces * 2);
      expect(countCanvases(), HtmlViewEmbedder.maximumOverlaySurfaces);
      expect(SurfaceFactory.instance.debugCacheSize, 0);

      // Frame 5:
      //   Render: zero platform views.
      //   Expect: main canvas, no overlays; cache full but does not exceed limit.
      await Future<void>.delayed(Duration.zero);
      renderTestScene(viewCount: 0);
      expect(countCanvases(), 1);
      expect(SurfaceFactory.instance.debugCacheSize,
          HtmlViewEmbedder.maximumOverlaySurfaces - 2);

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
          'Assertion failed: "Cannot render platform views: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15. These views have not been created, or they have been deleted."',
        );
      }

      // Frame 7:
      //   Render: a platform view after error.
      //   Expect: success. Just checking the system is not left in a corrupted state.
      await _createPlatformView(0, 'test-platform-view');
      renderTestScene(viewCount: 0);
      // TODO(yjbanov): skipped due to https://github.com/flutter/flutter/issues/73867
    }, skip: isSafari);

    test('embeds and disposes of a platform view', () async {
      ui.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (viewId) => html.DivElement()..id = 'view-0',
      );
      await _createPlatformView(0, 'test-platform-view');

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;

      LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      dispatcher.rasterizer!.draw(sb.build().layerTree);

      expect(
        domRenderer.sceneElement!.querySelector('flt-platform-view-slot'),
        isNotNull,
      );
      expect(
        domRenderer.glassPaneElement!.querySelector('flt-platform-view'),
        isNotNull,
      );

      await _disposePlatformView(0);

      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      dispatcher.rasterizer!.draw(sb.build().layerTree);

      expect(
        domRenderer.sceneElement!.querySelector('flt-platform-view-slot'),
        isNull,
      );
      expect(
        domRenderer.glassPaneElement!.querySelector('flt-platform-view'),
        isNull,
      );
    });

    test('removed the DOM node of an unrendered platform view', () async {
      ui.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (viewId) => html.DivElement()..id = 'view-0',
      );
      await _createPlatformView(0, 'test-platform-view');

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;

      LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      dispatcher.rasterizer!.draw(sb.build().layerTree);

      expect(
        domRenderer.sceneElement!.querySelector('flt-platform-view-slot'),
        isNotNull,
      );
      expect(
        domRenderer.glassPaneElement!.querySelector('flt-platform-view'),
        isNotNull,
      );

      // Render a frame with a different platform view.
      await _createPlatformView(1, 'test-platform-view');
      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(1, width: 10, height: 10);
      dispatcher.rasterizer!.draw(sb.build().layerTree);

      expect(
          domRenderer.sceneElement!.querySelectorAll('flt-platform-view-slot'),
          hasLength(1));
      expect(
          domRenderer.glassPaneElement!.querySelectorAll('flt-platform-view'),
          hasLength(2));

      // Render a frame without a platform view, but also without disposing of
      // the platform view.
      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      dispatcher.rasterizer!.draw(sb.build().layerTree);

      expect(
        domRenderer.sceneElement!.querySelector('flt-platform-view-slot'),
        isNull,
      );
      // The actual contents of the platform view are kept in the dom, until
      // it's actually disposed of!
      expect(
        domRenderer.glassPaneElement!.querySelector('flt-platform-view'),
        isNotNull,
      );
    });

    test(
        'removes old SVG clip definitions from the DOM when the view is recomposited',
        () async {
      ui.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (viewId) => html.DivElement()..id = 'test-view',
      );
      await _createPlatformView(0, 'test-platform-view');

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;

      void renderTestScene() {
        LayerSceneBuilder sb = LayerSceneBuilder();
        sb.pushOffset(0, 0);
        sb.pushClipRRect(
            ui.RRect.fromLTRBR(0, 0, 10, 10, ui.Radius.circular(3)));
        sb.addPlatformView(0, width: 10, height: 10);
        dispatcher.rasterizer!.draw(sb.build().layerTree);
      }

      final html.Node skPathDefs =
          domRenderer.sceneElement!.querySelector('#sk_path_defs')!;

      expect(skPathDefs.childNodes, hasLength(0));

      renderTestScene();
      expect(skPathDefs.childNodes, hasLength(1));

      await Future<void>.delayed(Duration.zero);
      renderTestScene();
      expect(skPathDefs.childNodes, hasLength(1));

      await Future<void>.delayed(Duration.zero);
      renderTestScene();
      expect(skPathDefs.childNodes, hasLength(1));
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

Future<void> _disposePlatformView(int id) {
  final completer = Completer<void>();
  window.sendPlatformMessage(
    'flutter/platform_views',
    codec.encodeMethodCall(MethodCall('dispose', id)),
    (dynamic _) => completer.complete(),
  );
  return completer.future;
}
