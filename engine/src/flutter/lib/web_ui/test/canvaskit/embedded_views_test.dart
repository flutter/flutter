// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import 'common.dart';
import 'test_data.dart';

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
      final Rasterizer rasterizer = CanvasKitRenderer.instance.rasterizer;
      ui_web.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => createDomHTMLDivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      rasterizer.draw(sb.build().layerTree);

      // The platform view is now split in two parts. The contents live
      // as a child of the glassPane, and the slot lives in the glassPane
      // shadow root. The slot is the one that has pointer events auto.
      final DomElement contents = flutterViewEmbedder.glassPaneElement
          .querySelector('#view-0')!;
      final DomElement slot = flutterViewEmbedder.sceneElement!
          .querySelector('slot')!;
      final DomElement contentsHost = contents.parent!;
      final DomElement slotHost = slot.parent!;

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
      final Rasterizer rasterizer = CanvasKitRenderer.instance.rasterizer;
      ui_web.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => createDomHTMLDivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.pushClipRRect(
          ui.RRect.fromLTRBR(0, 0, 10, 10, const ui.Radius.circular(3)));
      sb.addPlatformView(0, width: 10, height: 10);
      rasterizer.draw(sb.build().layerTree);

      expect(
        flutterViewEmbedder.sceneElement!
            .querySelectorAll('#sk_path_defs')
            .single,
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
      expect(
        flutterViewEmbedder.sceneElement!
            .querySelectorAll('flt-clip')
            .single
            .style
            .width,
        '100%',
      );
      expect(
        flutterViewEmbedder.sceneElement!
            .querySelectorAll('flt-clip')
            .single
            .style
            .height,
        '100%',
      );
    });

    test('correctly transforms platform views', () async {
      final Rasterizer rasterizer = CanvasKitRenderer.instance.rasterizer;
      ui_web.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => createDomHTMLDivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      final Matrix4 scaleMatrix = Matrix4.identity()
        ..scale(5, 5)
        ..translate(100, 100);
      sb.pushTransform(scaleMatrix.toFloat64());
      sb.pushOffset(3, 3);
      sb.addPlatformView(0, width: 10, height: 10);
      rasterizer.draw(sb.build().layerTree);

      // Transformations happen on the slot element.
      final DomElement slotHost = flutterViewEmbedder.sceneElement!
          .querySelector('flt-platform-view-slot')!;

      expect(
        slotHost.style.transform,
        // We should apply the scale matrix first, then the offset matrix.
        // So the translate should be 515 (5 * 100 + 5 * 3), and not
        // 503 (5 * 100 + 3).
        'matrix3d(5, 0, 0, 0, 0, 5, 0, 0, 0, 0, 5, 0, 515, 515, 0, 1)',
      );
    });

    test('correctly offsets platform views', () async {
      ui_web.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => createDomHTMLDivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.addPlatformView(0, offset: const ui.Offset(3, 4), width: 5, height: 6);
      CanvasKitRenderer.instance.rasterizer.draw(sb.build().layerTree);

      final DomElement slotHost = flutterViewEmbedder.sceneElement!
          .querySelector('flt-platform-view-slot')!;
      final DomCSSStyleDeclaration style = slotHost.style;

      expect(style.transform, 'matrix(1, 0, 0, 1, 3, 4)');
      expect(style.width, '5px');
      expect(style.height, '6px');

      final DomRect slotRect = slotHost.getBoundingClientRect();
      expect(slotRect.left, 3);
      expect(slotRect.top, 4);
      expect(slotRect.right, 8);
      expect(slotRect.bottom, 10);
    });

    // Returns the list of CSS transforms applied to the ancestor chain of
    // elements starting from `viewHost`, up until and excluding <flt-scene>.
    List<String> getTransformChain(DomElement viewHost) {
      final List<String> chain = <String>[];
      DomElement? element = viewHost;
      while (element != null && element.tagName.toLowerCase() != 'flt-scene') {
        chain.add(element.style.transform);
        element = element.parent;
      }
      return chain;
    }

    test('correctly offsets when clip chain length is changed', () async {
      ui_web.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => createDomHTMLDivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

      LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(3, 3);
      sb.pushClipRect(ui.Rect.largest);
      sb.pushOffset(6, 6);
      sb.addPlatformView(0, width: 10, height: 10);
      sb.pop();
      CanvasKitRenderer.instance.rasterizer.draw(sb.build().layerTree);

      // Transformations happen on the slot element.
      DomElement slotHost = flutterViewEmbedder.sceneElement!
          .querySelector('flt-platform-view-slot')!;

      expect(
        getTransformChain(slotHost),
        <String>[
          'matrix(1, 0, 0, 1, 6, 6)',
          'matrix(1, 0, 0, 1, 3, 3)',
        ],
      );

      sb = LayerSceneBuilder();
      sb.pushOffset(3, 3);
      sb.pushClipRect(ui.Rect.largest);
      sb.pushOffset(6, 6);
      sb.pushClipRect(ui.Rect.largest);
      sb.pushOffset(9, 9);
      sb.addPlatformView(0, width: 10, height: 10);
      CanvasKitRenderer.instance.rasterizer.draw(sb.build().layerTree);

      // Transformations happen on the slot element.
      slotHost = flutterViewEmbedder.sceneElement!
          .querySelector('flt-platform-view-slot')!;

      expect(
        getTransformChain(slotHost),
        <String>[
          'matrix(1, 0, 0, 1, 9, 9)',
          'matrix(1, 0, 0, 1, 6, 6)',
          'matrix(1, 0, 0, 1, 3, 3)',
        ],
      );
    });

    test('converts device pixels to logical pixels (no clips)', () async {
      window.debugOverrideDevicePixelRatio(4);
      ui_web.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => createDomHTMLDivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(1, 1);
      sb.pushOffset(2, 2);
      sb.pushOffset(3, 3);
      sb.addPlatformView(0, width: 10, height: 10);
      CanvasKitRenderer.instance.rasterizer.draw(sb.build().layerTree);

      // Transformations happen on the slot element.
      final DomElement slotHost = flutterViewEmbedder.sceneElement!
          .querySelector('flt-platform-view-slot')!;

      expect(
        getTransformChain(slotHost),
        <String>['matrix(0.25, 0, 0, 0.25, 1.5, 1.5)'],
      );
    });

    test('converts device pixels to logical pixels (with clips)', () async {
      window.debugOverrideDevicePixelRatio(4);
      ui_web.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => createDomHTMLDivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(3, 3);
      sb.pushClipRect(ui.Rect.largest);
      sb.pushOffset(6, 6);
      sb.pushClipRect(ui.Rect.largest);
      sb.pushOffset(9, 9);
      sb.addPlatformView(0, width: 10, height: 10);
      CanvasKitRenderer.instance.rasterizer.draw(sb.build().layerTree);

      // Transformations happen on the slot element.
      final DomElement slotHost = flutterViewEmbedder.sceneElement!
          .querySelector('flt-platform-view-slot')!;

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
      expect(configuration.canvasKitMaximumSurfaces, 8);
      final CkPicture testPicture =
          paintPicture(const ui.Rect.fromLTRB(0, 0, 10, 10), (CkCanvas canvas) {
        canvas.drawCircle(const ui.Offset(5, 5), 5, CkPaint());
      });

      // Initialize all platform views to be used in the test.
      final List<int> platformViewIds = <int>[];
      for (int i = 0; i < 16; i++) {
        ui_web.platformViewRegistry.registerViewFactory(
          'test-platform-view',
          (int viewId) => createDomHTMLDivElement()..id = 'view-$i',
        );
        await createPlatformView(i, 'test-platform-view');
        platformViewIds.add(i);
      }

      void renderTestScene({required int viewCount}) {
        final LayerSceneBuilder sb = LayerSceneBuilder();
        sb.pushOffset(0, 0);
        for (int i = 0; i < viewCount; i++) {
          sb.addPicture(ui.Offset.zero, testPicture);
          sb.addPlatformView(i, width: 10, height: 10);
        }
        CanvasKitRenderer.instance.rasterizer.draw(sb.build().layerTree);
      }

      // Frame 1:
      //   Render: up to cache size platform views.
      //   Expect: main canvas plus platform view overlays.
      renderTestScene(viewCount: 8);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
      ]);

      // Frame 2:
      //   Render: zero platform views.
      //   Expect: main canvas, no overlays.
      await Future<void>.delayed(Duration.zero);
      renderTestScene(viewCount: 0);
      _expectSceneMatches(<_EmbeddedViewMarker>[_overlay]);

      // Frame 3:
      //   Render: less than cache size platform views.
      //   Expect: overlays reused.
      await Future<void>.delayed(Duration.zero);
      renderTestScene(viewCount: 6);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
      ]);

      // Frame 4:
      //   Render: more platform views than max cache size.
      //   Expect: main canvas, backup overlay, maximum overlays.
      await Future<void>.delayed(Duration.zero);
      renderTestScene(viewCount: 16);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _platformView,
        _platformView,
        _platformView,
        _platformView,
        _platformView,
        _platformView,
        _platformView,
        _platformView,
      ]);

      // Frame 5:
      //   Render: zero platform views.
      //   Expect: main canvas, no overlays.
      await Future<void>.delayed(Duration.zero);
      renderTestScene(viewCount: 0);
      _expectSceneMatches(<_EmbeddedViewMarker>[_overlay]);

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
      _expectSceneMatches(<_EmbeddedViewMarker>[_overlay]);
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
        ui_web.platformViewRegistry.registerViewFactory(
          'test-platform-view',
          (int viewId) => createDomHTMLDivElement()..id = 'view-$i',
        );
        await createPlatformView(i, 'test-platform-view');
        platformViewIds.add(i);
      }

      void renderTestScene(List<int> views) {
        final LayerSceneBuilder sb = LayerSceneBuilder();
        sb.pushOffset(0, 0);
        for (final int view in views) {
          sb.addPicture(ui.Offset.zero, testPicture);
          sb.addPlatformView(view, width: 10, height: 10);
        }
        CanvasKitRenderer.instance.rasterizer.draw(sb.build().layerTree);
      }

      // Frame 1:
      //   Render: Views 1-10
      //   Expect: main canvas plus platform view overlays; empty cache.
      renderTestScene(<int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
      expect(SurfaceFactory.instance.numAvailableOverlays, 0);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _platformView,
        _platformView,
      ]);

      // Frame 2:
      //   Render: Views 2-11
      //   Expect: main canvas plus platform view overlays; empty cache.
      await Future<void>.delayed(Duration.zero);
      renderTestScene(<int>[2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);
      expect(SurfaceFactory.instance.numAvailableOverlays, 0);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _platformView,
        _platformView,
      ]);

      // Frame 3:
      //   Render: Views 3-12
      //   Expect: main canvas plus platform view overlays; empty cache.
      await Future<void>.delayed(Duration.zero);
      renderTestScene(<int>[3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _platformView,
        _platformView,
      ]);

      // Frame 4:
      //   Render: Views 3-12 again (same as last frame)
      //   Expect: main canvas plus platform view overlays; empty cache.
      await Future<void>.delayed(Duration.zero);
      renderTestScene(<int>[3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
        _platformView,
        _platformView,
        _platformView,
      ]);

      // TODO(yjbanov): skipped due to https://github.com/flutter/flutter/issues/73867
    }, skip: isSafari);

    test('embeds and disposes of a platform view', () async {
      ui_web.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => createDomHTMLDivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

      LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      CanvasKitRenderer.instance.rasterizer.draw(sb.build().layerTree);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _overlay,
      ]);

      expect(
        flutterViewEmbedder.glassPaneElement
            .querySelector('flt-platform-view'),
        isNotNull,
      );

      await disposePlatformView(0);

      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      CanvasKitRenderer.instance.rasterizer.draw(sb.build().layerTree);

      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
      ]);

      expect(
        flutterViewEmbedder.glassPaneElement
            .querySelector('flt-platform-view'),
        isNull,
      );
    });

    test('does not crash when resizing the window after textures have been registered', () async {
      ui_web.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => createDomHTMLDivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

      final CkBrowserImageDecoder image = await CkBrowserImageDecoder.create(
        data: kAnimatedGif,
        debugSource: 'test',
      );
      final ui.FrameInfo frame = await image.getNextFrame();
      final CkImage ckImage = frame.image as CkImage;

      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      final CkPictureRecorder recorder = CkPictureRecorder();
      final CkCanvas canvas = recorder.beginRecording(ui.Rect.largest);
      canvas.drawImage(ckImage, ui.Offset.zero, CkPaint());
      final CkPicture picture = recorder.endRecording();
      sb.addPicture(ui.Offset.zero, picture);
      sb.addPlatformView(0, width: 10, height: 10);

      window.debugPhysicalSizeOverride = const ui.Size(100, 100);
      window.debugForceResize();
      CanvasKitRenderer.instance.rasterizer.draw(sb.build().layerTree);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _overlay,
      ]);

      window.debugPhysicalSizeOverride = const ui.Size(200, 200);
      window.debugForceResize();
      CanvasKitRenderer.instance.rasterizer.draw(sb.build().layerTree);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _overlay,
      ]);

      window.debugPhysicalSizeOverride = null;
      window.debugForceResize();
    // ImageDecoder is not supported in Safari or Firefox.
    }, skip: isSafari || isFirefox);

    test('removed the DOM node of an unrendered platform view', () async {
      final Rasterizer rasterizer = CanvasKitRenderer.instance.rasterizer;
      ui_web.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => createDomHTMLDivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

      LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      CanvasKitRenderer.instance.rasterizer.draw(sb.build().layerTree);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _overlay,
      ]);

      expect(
        flutterViewEmbedder.glassPaneElement
            .querySelector('flt-platform-view'),
        isNotNull,
      );

      // Render a frame with a different platform view.
      await createPlatformView(1, 'test-platform-view');
      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(1, width: 10, height: 10);
      rasterizer.draw(sb.build().layerTree);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _overlay,
      ]);

      expect(
          flutterViewEmbedder.glassPaneElement
              .querySelectorAll('flt-platform-view'),
          hasLength(2));

      // Render a frame without a platform view, but also without disposing of
      // the platform view.
      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      CanvasKitRenderer.instance.rasterizer.draw(sb.build().layerTree);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
      ]);

      // The actual contents of the platform view are kept in the dom, until
      // it's actually disposed of!
      expect(
          flutterViewEmbedder.glassPaneElement
              .querySelectorAll('flt-platform-view'),
          hasLength(2));
    });

    test(
        'removes old SVG clip definitions from the DOM when the view is recomposited',
        () async {
      final Rasterizer rasterizer = CanvasKitRenderer.instance.rasterizer;
      ui_web.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => createDomHTMLDivElement()..id = 'test-view',
      );
      await createPlatformView(0, 'test-platform-view');

      void renderTestScene() {
        final LayerSceneBuilder sb = LayerSceneBuilder();
        sb.pushOffset(0, 0);
        sb.pushClipRRect(
            ui.RRect.fromLTRBR(0, 0, 10, 10, const ui.Radius.circular(3)));
        sb.addPlatformView(0, width: 10, height: 10);
        rasterizer.draw(sb.build().layerTree);
      }

      final DomNode skPathDefs = flutterViewEmbedder.sceneElement!
          .querySelector('#sk_path_defs')!;

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

    test('does not crash when a prerolled platform view is not composited',
        () async {
      final Rasterizer rasterizer = CanvasKitRenderer.instance.rasterizer;
      ui_web.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => createDomHTMLDivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.pushClipRect(ui.Rect.zero);
      sb.addPlatformView(0, width: 10, height: 10);
      sb.pop();
      // The below line should not throw an error.
      rasterizer.draw(sb.build().layerTree);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
      ]);
    });

    test('does not crash when overlays are disabled', () async {
      final Rasterizer rasterizer = CanvasKitRenderer.instance.rasterizer;
      HtmlViewEmbedder.debugDisableOverlays = true;
      ui_web.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => createDomHTMLDivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');

      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      sb.pop();
      // The below line should not throw an error.
      rasterizer.draw(sb.build().layerTree);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
      ]);
      HtmlViewEmbedder.debugDisableOverlays = false;
    });

    test('works correctly with max overlays == 2', () async {
      final Rasterizer rasterizer = CanvasKitRenderer.instance.rasterizer;
      debugOverrideJsConfiguration(
        <String, Object?>{
          'canvasKitMaximumSurfaces': 2,
        }.jsify() as JsFlutterConfiguration?
      );
      expect(configuration.canvasKitMaximumSurfaces, 2);
      expect(configuration.canvasKitVariant, isNot(CanvasKitVariant.auto));

      SurfaceFactory.instance.debugClear();

      expect(SurfaceFactory.instance.maximumSurfaces, 2);
      expect(SurfaceFactory.instance.maximumOverlays, 1);

      ui_web.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => createDomHTMLDivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');
      await createPlatformView(1, 'test-platform-view');

      LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      sb.pop();
      // The below line should not throw an error.
      rasterizer.draw(sb.build().layerTree);

      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _overlay,
      ]);

      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.addPlatformView(0, width: 10, height: 10);
      sb.pop();
      // The below line should not throw an error.
      rasterizer.draw(sb.build().layerTree);

      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _overlay,
        _platformView,
      ]);

      // Reset configuration
      debugOverrideJsConfiguration(null);
    });

    test(
        'correctly renders when overlays are disabled and a subset '
        'of views is used', () async {
      final Rasterizer rasterizer = CanvasKitRenderer.instance.rasterizer;
      HtmlViewEmbedder.debugDisableOverlays = true;
      ui_web.platformViewRegistry.registerViewFactory(
        'test-platform-view',
        (int viewId) => createDomHTMLDivElement()..id = 'view-0',
      );
      await createPlatformView(0, 'test-platform-view');
      await createPlatformView(1, 'test-platform-view');

      LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.pop();
      // The below line should not throw an error.
      rasterizer.draw(sb.build().layerTree);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _platformView,
      ]);

      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.pop();
      // The below line should not throw an error.
      rasterizer.draw(sb.build().layerTree);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
      ]);

      HtmlViewEmbedder.debugDisableOverlays = false;
    });

    test('does not create overlays for invisible platform views', () async {
      final Rasterizer rasterizer = CanvasKitRenderer.instance.rasterizer;
      ui_web.platformViewRegistry.registerViewFactory(
          'test-visible-view',
          (int viewId) =>
              createDomHTMLDivElement()..className = 'visible-platform-view');
      ui_web.platformViewRegistry.registerViewFactory(
        'test-invisible-view',
        (int viewId) =>
            createDomHTMLDivElement()..className = 'invisible-platform-view',
        isVisible: false,
      );
      await createPlatformView(0, 'test-visible-view');
      await createPlatformView(1, 'test-invisible-view');
      await createPlatformView(2, 'test-visible-view');
      await createPlatformView(3, 'test-invisible-view');
      await createPlatformView(4, 'test-invisible-view');
      await createPlatformView(5, 'test-invisible-view');
      await createPlatformView(6, 'test-invisible-view');

      expect(platformViewManager.isInvisible(0), isFalse);
      expect(platformViewManager.isInvisible(1), isTrue);

      LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.pop();
      rasterizer.draw(sb.build().layerTree);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
      ], reason: 'Invisible view alone renders on top of base overlay.');

      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.pop();
      rasterizer.draw(sb.build().layerTree);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _platformView,
        _overlay,
      ], reason: 'Overlay created after a group containing a visible view.');

      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.addPlatformView(2, width: 10, height: 10);
      sb.pop();
      rasterizer.draw(sb.build().layerTree);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _platformView,
        _overlay,
        _platformView,
        _overlay,
      ], reason: 'Overlays created after each group containing a visible view.');

      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.addPlatformView(2, width: 10, height: 10);
      sb.addPlatformView(3, width: 10, height: 10);
      sb.pop();
      rasterizer.draw(sb.build().layerTree);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _platformView,
        _overlay,
        _platformView,
        _platformView,
        _overlay,
      ], reason: 'Invisible views grouped in with visible views.');

      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.addPlatformView(2, width: 10, height: 10);
      sb.addPlatformView(3, width: 10, height: 10);
      sb.addPlatformView(4, width: 10, height: 10);
      sb.pop();
      rasterizer.draw(sb.build().layerTree);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _platformView,
        _overlay,
        _platformView,
        _platformView,
        _platformView,
        _overlay,
      ]);

      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(0, width: 10, height: 10);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.addPlatformView(2, width: 10, height: 10);
      sb.addPlatformView(3, width: 10, height: 10);
      sb.addPlatformView(4, width: 10, height: 10);
      sb.addPlatformView(5, width: 10, height: 10);
      sb.pop();
      rasterizer.draw(sb.build().layerTree);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _platformView,
        _overlay,
        _platformView,
        _platformView,
        _platformView,
        _platformView,
        _overlay,
      ]);

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
      rasterizer.draw(sb.build().layerTree);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _platformView,
        _overlay,
        _platformView,
        _platformView,
        _platformView,
        _platformView,
        _platformView,
        _overlay,
      ]);

      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.addPlatformView(3, width: 10, height: 10);
      sb.addPlatformView(4, width: 10, height: 10);
      sb.addPlatformView(5, width: 10, height: 10);
      sb.addPlatformView(6, width: 10, height: 10);
      sb.pop();
      rasterizer.draw(sb.build().layerTree);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _platformView,
        _platformView,
        _platformView,
        _platformView,
      ], reason: 'Many invisible views can be rendered on top of the base overlay.');

      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.addPlatformView(2, width: 10, height: 10);
      sb.addPlatformView(3, width: 10, height: 10);
      sb.addPlatformView(4, width: 10, height: 10);
      sb.pop();
      rasterizer.draw(sb.build().layerTree);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _platformView,
        _platformView,
        _platformView,
        _overlay,
      ]);

      sb = LayerSceneBuilder();
      sb.pushOffset(0, 0);
      sb.addPlatformView(4, width: 10, height: 10);
      sb.addPlatformView(3, width: 10, height: 10);
      sb.addPlatformView(2, width: 10, height: 10);
      sb.addPlatformView(1, width: 10, height: 10);
      sb.pop();
      rasterizer.draw(sb.build().layerTree);
      _expectSceneMatches(<_EmbeddedViewMarker>[
        _overlay,
        _platformView,
        _platformView,
        _platformView,
        _platformView,
        _overlay,
      ]);
    });
  });
}

// Used to test that the platform views and overlays are in the correct order in
// the scene.
enum _EmbeddedViewMarker {
  overlay,
  platformView,
}

_EmbeddedViewMarker get _overlay => _EmbeddedViewMarker.overlay;
_EmbeddedViewMarker get _platformView => _EmbeddedViewMarker.platformView;

const Map<String, _EmbeddedViewMarker> _tagToViewMarker = <String, _EmbeddedViewMarker>{
  'flt-canvas-container': _EmbeddedViewMarker.overlay,
  'flt-platform-view-slot': _EmbeddedViewMarker.platformView,
};

void _expectSceneMatches(List<_EmbeddedViewMarker> expectedMarkers, {
  String? reason,
}) {
  // Convert the scene elements to its corresponding array of _EmbeddedViewMarker
  final List<_EmbeddedViewMarker> sceneElements = flutterViewEmbedder
      .sceneElement!.children
      .where((DomElement element) => element.tagName != 'svg')
      .map((DomElement element) => _tagToViewMarker[element.tagName.toLowerCase()]!)
      .toList();

  expect(sceneElements, expectedMarkers, reason: reason);
}
