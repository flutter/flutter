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
        (int viewId) => html.DivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;
      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      dispatcher.rasterizer!.draw(sb.build().layerTree);

      // The platform view is now split in two parts. The contents live
      // as a child of the glassPane, and the slot lives in the glassPane
      // shadow root. The slot is the one that has pointer events auto.
      final html.Element contents =
          flutterViewEmbedder.glassPaneElement!.querySelector('#view-0')!;
      final html.Element slot =
          flutterViewEmbedder.sceneElement!.querySelector('slot')!;
      final html.Element contentsHost = contents.parent!;
      final html.Element slotHost = slot.parent!;

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
        (int viewId) => html.DivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;
      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.pushClipRRect(
          ui.RRect.fromLTRBR(0, 0, 10, 10, const ui.Radius.circular(3)));
      sb.addPlatformView(0, width: 10, height: 10);
      dispatcher.rasterizer!.draw(sb.build().layerTree);

      expect(
        flutterViewEmbedder.sceneElement!.querySelectorAll('#sk_path_defs').single,
        isNotNull,
      );
      expect(
        flutterViewEmbedder.sceneElement!
            .querySelectorAll('#sk_path_defs')
            .single
            .querySelectorAll('clipPath')
            .single,
        isNotNull,
      );
      expect(
        flutterViewEmbedder.sceneElement!
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
        (int viewId) => html.DivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;
      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      final Matrix4 scaleMatrix = Matrix4.identity()
        ..scale(5, 5)
        ..translate(100, 100);
      sb.pushTransform(scaleMatrix.toFloat64());
      sb.pushOffset(3, 3);
      sb.addPlatformView(0, width: 10, height: 10);
      dispatcher.rasterizer!.draw(sb.build().layerTree);

      // Transformations happen on the slot element.
      final html.Element slotHost =
          flutterViewEmbedder.sceneElement!.querySelector('flt-platform-view-slot')!;

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
        (int viewId) => html.DivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

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
          flutterViewEmbedder.sceneElement!.querySelector('flt-platform-view-slot')!;

      expect(
        getTransformChain(slotHost),
        <String>['matrix(0.25, 0, 0, 0.25, 1.5, 1.5)'],
      );
    });

    test('converts device pixels to logical pixels (with clips)', () async {
      window.debugOverrideDevicePixelRatio(4);
      ui.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => html.DivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

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
          flutterViewEmbedder.sceneElement!.querySelector('flt-platform-view-slot')!;

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
          paintPicture(const ui.Rect.fromLTRB(0, 0, 10, 10), (CkCanvas canvas) {
        canvas.drawCircle(const ui.Offset(5, 5), 5, CkPaint());
      });

      // Initialize all platform views to be used in the test.
      final List<int> platformViewIds = <int>[];
      for (int i = 0; i < configuration.canvasKitMaximumSurfaces * 2; i++) {
        ui.platformViewRegistry.registerViewFactory(
          'test-platform-view',
          (int viewId) => html.DivElement()..id = 'view-$i',
        );
        await createPlatformView(i, 'test-platform-view');
        platformViewIds.add(i);
      }

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;

      void renderTestScene({required int viewCount}) {
        final LayerSceneBuilder sb = LayerSceneBuilder();
        sb.pushOffset(0, 0);
        for (int i = 0; i < viewCount; i++) {
          sb.addPicture(ui.Offset.zero, testPicture);
          sb.addPlatformView(i, width: 10, height: 10);
        }
        dispatcher.rasterizer!.draw(sb.build().layerTree);
      }

      int countCanvases() {
        return flutterViewEmbedder.sceneElement!.querySelectorAll('canvas').length;
      }

      // Frame 1:
      //   Render: up to cache size platform views.
      //   Expect: main canvas plus platform view overlays.
      renderTestScene(viewCount: configuration.canvasKitMaximumSurfaces);
      expect(countCanvases(), configuration.canvasKitMaximumSurfaces);

      // Frame 2:
      //   Render: zero platform views.
      //   Expect: main canvas, no overlays.
      await Future<void>.delayed(Duration.zero);
      renderTestScene(viewCount: 0);
      expect(countCanvases(), 1);

      // Frame 3:
      //   Render: less than cache size platform views.
      //   Expect: overlays reused.
      await Future<void>.delayed(Duration.zero);
      renderTestScene(viewCount: configuration.canvasKitMaximumSurfaces - 2);
      expect(countCanvases(), configuration.canvasKitMaximumSurfaces - 1);

      // Frame 4:
      //   Render: more platform views than max cache size.
      //   Expect: main canvas, backup overlay, maximum overlays.
      await Future<void>.delayed(Duration.zero);
      renderTestScene(viewCount: configuration.canvasKitMaximumSurfaces * 2);
      expect(countCanvases(), configuration.canvasKitMaximumSurfaces);

      // Frame 5:
      //   Render: zero platform views.
      //   Expect: main canvas, no overlays.
      await Future<void>.delayed(Duration.zero);
      renderTestScene(viewCount: 0);
      expect(countCanvases(), 1);

      // Frame 6:
      //   Render: deleted platform views.
      //   Expect: error.
      for (final int id in platformViewIds) {
        const StandardMethodCodec codec = StandardMethodCodec();
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
      await createPlatformView(0, 'test-platform-view');
      renderTestScene(viewCount: 0);
      // TODO(yjbanov): skipped due to https://github.com/flutter/flutter/issues/73867
    }, skip: isSafari);

    test('correctly reuses overlays', () async {
      final CkPicture testPicture =
          paintPicture(const ui.Rect.fromLTRB(0, 0, 10, 10), (CkCanvas canvas) {
        canvas.drawCircle(const ui.Offset(5, 5), 5, CkPaint());
      });

      // Initialize all platform views to be used in the test.
      final List<int> platformViewIds = <int>[];
      for (int i = 0; i < 20; i++) {
        ui.platformViewRegistry.registerViewFactory(
          'test-platform-view',
          (int viewId) => html.DivElement()..id = 'view-$i',
        );
        await createPlatformView(i, 'test-platform-view');
        platformViewIds.add(i);
      }

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;

      void renderTestScene(List<int> views) {
        final LayerSceneBuilder sb = LayerSceneBuilder();
        sb.pushOffset(0, 0);
        for (final int view in views) {
          sb.addPicture(ui.Offset.zero, testPicture);
          sb.addPlatformView(view, width: 10, height: 10);
        }
        dispatcher.rasterizer!.draw(sb.build().layerTree);
      }

      int countCanvases() {
        return flutterViewEmbedder.sceneElement!.querySelectorAll('canvas').length;
      }

      // Frame 1:
      //   Render: Views 1-10
      //   Expect: main canvas plus platform view overlays; empty cache.
      renderTestScene(<int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
      expect(countCanvases(), configuration.canvasKitMaximumSurfaces);

      // Frame 2:
      //   Render: Views 2-11
      //   Expect: main canvas plus platform view overlays; empty cache.
      await Future<void>.delayed(Duration.zero);
      renderTestScene(<int>[2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);
      expect(countCanvases(), configuration.canvasKitMaximumSurfaces);

      // Frame 3:
      //   Render: Views 3-12
      //   Expect: main canvas plus platform view overlays; empty cache.
      await Future<void>.delayed(Duration.zero);
      renderTestScene(<int>[3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
      expect(countCanvases(), configuration.canvasKitMaximumSurfaces);

      // TODO(yjbanov): skipped due to https://github.com/flutter/flutter/issues/73867
    }, skip: isSafari);

    test('embeds and disposes of a platform view', () async {
      ui.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => html.DivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;

      LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      dispatcher.rasterizer!.draw(sb.build().layerTree);

      expect(
        flutterViewEmbedder.sceneElement!.querySelector('flt-platform-view-slot'),
        isNotNull,
      );
      expect(
        flutterViewEmbedder.glassPaneElement!.querySelector('flt-platform-view'),
        isNotNull,
      );

      await disposePlatformView(0);

      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      dispatcher.rasterizer!.draw(sb.build().layerTree);

      expect(
        flutterViewEmbedder.sceneElement!.querySelector('flt-platform-view-slot'),
        isNull,
      );
      expect(
        flutterViewEmbedder.glassPaneElement!.querySelector('flt-platform-view'),
        isNull,
      );
    });

    test('removed the DOM node of an unrendered platform view', () async {
      ui.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => html.DivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;

      LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      dispatcher.rasterizer!.draw(sb.build().layerTree);

      expect(
        flutterViewEmbedder.sceneElement!.querySelector('flt-platform-view-slot'),
        isNotNull,
      );
      expect(
        flutterViewEmbedder.glassPaneElement!.querySelector('flt-platform-view'),
        isNotNull,
      );

      // Render a frame with a different platform view.
      await createPlatformView(1, 'test-platform-view');
      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(1, width: 10, height: 10);
      dispatcher.rasterizer!.draw(sb.build().layerTree);

      expect(
          flutterViewEmbedder.sceneElement!.querySelectorAll('flt-platform-view-slot'),
          hasLength(1));
      expect(
          flutterViewEmbedder.glassPaneElement!.querySelectorAll('flt-platform-view'),
          hasLength(2));

      // Render a frame without a platform view, but also without disposing of
      // the platform view.
      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      dispatcher.rasterizer!.draw(sb.build().layerTree);

      expect(
        flutterViewEmbedder.sceneElement!.querySelector('flt-platform-view-slot'),
        isNull,
      );
      // The actual contents of the platform view are kept in the dom, until
      // it's actually disposed of!
      expect(
        flutterViewEmbedder.glassPaneElement!.querySelector('flt-platform-view'),
        isNotNull,
      );
    });

    test(
        'removes old SVG clip definitions from the DOM when the view is recomposited',
        () async {
      ui.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => html.DivElement()..id = 'test-view',
      );
      await createPlatformView(0, 'test-platform-view');

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;

      void renderTestScene() {
        final LayerSceneBuilder sb = LayerSceneBuilder();
        sb.pushOffset(0, 0);
        sb.pushClipRRect(
            ui.RRect.fromLTRBR(0, 0, 10, 10, const ui.Radius.circular(3)));
        sb.addPlatformView(0, width: 10, height: 10);
        dispatcher.rasterizer!.draw(sb.build().layerTree);
      }

      final html.Node skPathDefs =
          flutterViewEmbedder.sceneElement!.querySelector('#sk_path_defs')!;

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

    test('diffViewList works in the expected case', () {
      ViewListDiffResult? result = diffViewList(
        <int>[1, 2, 3, 4, 5],
        <int>[3, 4, 5, 6, 7],
      );
      expect(result, isNotNull);
      expect(result!.viewsToAdd, <int>[6, 7]);
      expect(result.viewsToRemove, <int>[1, 2]);
      expect(result.addToBeginning, isFalse);

      result = diffViewList(
        <int>[3, 4, 5, 6, 7],
        <int>[1, 2, 3, 4, 5],
      );
      expect(result, isNotNull);
      expect(result!.viewsToAdd, <int>[1, 2]);
      expect(result.viewsToRemove, <int>[6, 7]);
      expect(result.addToBeginning, isTrue);
      expect(result.viewToInsertBefore, 3);

      result = diffViewList(<int>[3, 4, 5], <int>[2, 3, 4, 5]);
      expect(result, isNotNull);
      expect(result!.viewsToAdd, <int>[2]);
      expect(result.viewsToRemove, <int>[]);
      expect(result.addToBeginning, isTrue);
      expect(result.viewToInsertBefore, 3);

      result = diffViewList(<int>[3, 4, 5], <int>[3, 4, 5, 6]);
      expect(result, isNotNull);
      expect(result!.viewsToAdd, <int>[6]);
      expect(result.viewsToRemove, <int>[]);
      expect(result.addToBeginning, isFalse);

      result = diffViewList(<int>[3, 4, 5, 6], <int>[3, 4, 5]);
      expect(result, isNotNull);
      expect(result!.viewsToAdd, <int>[]);
      expect(result.viewsToRemove, <int>[6]);
      expect(result.addToBeginning, isTrue);
      expect(result.viewToInsertBefore, 3);

      result = diffViewList(<int>[3, 4, 5, 6], <int>[4, 5, 6]);
      expect(result, isNotNull);
      expect(result!.viewsToAdd, <int>[]);
      expect(result.viewsToRemove, <int>[3]);
      expect(result.addToBeginning, isFalse);

      result = diffViewList(<int>[1, 2, 3], <int>[4, 5]);
      expect(result, isNull);

      result = diffViewList(<int>[1, 2, 3, 4], <int>[2, 3, 5, 4]);
      expect(result, isNull);

      result = diffViewList(<int>[3, 4], <int>[1, 2, 3, 4, 5, 6]);
      expect(result, isNull);
    });

    test('does not crash when a prerolled platform view is not composited',
        () async {
      ui.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => html.DivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;

      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.pushClipRect(ui.Rect.zero);
      sb.addPlatformView(0, width: 10, height: 10);
      sb.pop();
      // The below line should not throw an error.
      dispatcher.rasterizer!.draw(sb.build().layerTree);
      expect(
          flutterViewEmbedder.glassPaneShadow!
              .querySelectorAll('flt-platform-view-slot'),
          isEmpty);
    });

    test('does not crash when overlays are disabled', () async {
      HtmlViewEmbedder.debugDisableOverlays = true;
      ui.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => html.DivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;

      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      sb.pop();
      // The below line should not throw an error.
      dispatcher.rasterizer!.draw(sb.build().layerTree);
      expect(
          flutterViewEmbedder.glassPaneShadow!
              .querySelectorAll('flt-platform-view-slot'),
          hasLength(1));
      HtmlViewEmbedder.debugDisableOverlays = false;
    });

    test('works correctly with max overlays == 2', () async {
      debugSetConfiguration(FlutterConfiguration(
          JsFlutterConfiguration()..canvasKitMaximumSurfaces = 2));
      SurfaceFactory.instance.debugClear();

      expect(SurfaceFactory.instance.maximumSurfaces, 2);
      expect(SurfaceFactory.instance.maximumOverlays, 0);

      ui.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => html.DivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');
      await createPlatformView(1, 'test-platform-view');

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;

      LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      sb.pop();
      // The below line should not throw an error.
      dispatcher.rasterizer!.draw(sb.build().layerTree);

      expect(
          flutterViewEmbedder.glassPaneShadow!
              .querySelectorAll('flt-platform-view-slot'),
          hasLength(1));

      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.addPlatformView(0, width: 10, height: 10);
      sb.pop();
      // The below line should not throw an error.
      dispatcher.rasterizer!.draw(sb.build().layerTree);

      expect(
          flutterViewEmbedder.glassPaneShadow!
              .querySelectorAll('flt-platform-view-slot'),
          hasLength(2));

      // Reset configuration
      debugSetConfiguration(FlutterConfiguration(null));
    });

    test(
        'correctly renders when overlays are disabled and a subset '
        'of views is used', () async {
      HtmlViewEmbedder.debugDisableOverlays = true;
      ui.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => html.DivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');
      await createPlatformView(1, 'test-platform-view');

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;

      LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.pop();
      // The below line should not throw an error.
      dispatcher.rasterizer!.draw(sb.build().layerTree);

      expect(
          flutterViewEmbedder.glassPaneShadow!
              .querySelectorAll('flt-platform-view-slot'),
          hasLength(2));

      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.pop();
      // The below line should not throw an error.
      dispatcher.rasterizer!.draw(sb.build().layerTree);
      expect(
          flutterViewEmbedder.glassPaneShadow!
              .querySelectorAll('flt-platform-view-slot'),
          hasLength(1));

      HtmlViewEmbedder.debugDisableOverlays = false;
    });

    test('does not create overlays for invisible platform views', () async {
      ui.platformViewRegistry.registerViewFactory(
          'test-visible-view',
          (int viewId) =>
              html.DivElement()..className = 'visible-platform-view');
      ui.platformViewRegistry.registerViewFactory(
        'test-invisible-view',
        (int viewId) =>
            html.DivElement()..className = 'invisible-platform-view',
        isVisible: false,
      );
      await createPlatformView(0, 'test-visible-view');
      await createPlatformView(1, 'test-invisible-view');
      await createPlatformView(2, 'test-visible-view');
      await createPlatformView(3, 'test-invisible-view');
      await createPlatformView(4, 'test-invisible-view');
      await createPlatformView(5, 'test-invisible-view');
      await createPlatformView(6, 'test-invisible-view');

      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;

      int countCanvases() {
        return flutterViewEmbedder.sceneElement!.querySelectorAll('canvas').length;
      }

      expect(platformViewManager.isInvisible(0), isFalse);
      expect(platformViewManager.isInvisible(1), isTrue);

      LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.pop();
      dispatcher.rasterizer!.draw(sb.build().layerTree);
      expect(countCanvases(), 1);

      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.pop();
      dispatcher.rasterizer!.draw(sb.build().layerTree);
      expect(countCanvases(), 2);

      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.addPlatformView(2, width: 10, height: 10);
      sb.pop();
      dispatcher.rasterizer!.draw(sb.build().layerTree);
      expect(countCanvases(), 3);

      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.addPlatformView(2, width: 10, height: 10);
      sb.addPlatformView(3, width: 10, height: 10);
      sb.pop();
      dispatcher.rasterizer!.draw(sb.build().layerTree);
      expect(countCanvases(), 3);

      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.addPlatformView(2, width: 10, height: 10);
      sb.addPlatformView(3, width: 10, height: 10);
      sb.addPlatformView(4, width: 10, height: 10);
      sb.pop();
      dispatcher.rasterizer!.draw(sb.build().layerTree);
      expect(countCanvases(), 3);

      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.addPlatformView(2, width: 10, height: 10);
      sb.addPlatformView(3, width: 10, height: 10);
      sb.addPlatformView(4, width: 10, height: 10);
      sb.addPlatformView(5, width: 10, height: 10);
      sb.pop();
      dispatcher.rasterizer!.draw(sb.build().layerTree);
      expect(countCanvases(), 3);

      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.addPlatformView(2, width: 10, height: 10);
      sb.addPlatformView(3, width: 10, height: 10);
      sb.addPlatformView(4, width: 10, height: 10);
      sb.addPlatformView(5, width: 10, height: 10);
      sb.addPlatformView(6, width: 10, height: 10);
      sb.pop();
      dispatcher.rasterizer!.draw(sb.build().layerTree);
      expect(countCanvases(), 3);

      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.addPlatformView(3, width: 10, height: 10);
      sb.addPlatformView(4, width: 10, height: 10);
      sb.addPlatformView(5, width: 10, height: 10);
      sb.addPlatformView(6, width: 10, height: 10);
      sb.pop();
      dispatcher.rasterizer!.draw(sb.build().layerTree);
      expect(countCanvases(), 1);
    });
    // TODO(dit): https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}
