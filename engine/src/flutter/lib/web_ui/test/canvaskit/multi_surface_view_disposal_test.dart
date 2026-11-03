// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

// Like the tests in `test/canvaskit/surface_gl_failure_test.dart`, tests that
// lose WebGL contexts via `WEBGL_lose_context` only run on Chromium-based
// browsers.
final bool _skipContextLoss = isFirefox || isSafari;

// Regression tests for https://github.com/flutter/flutter/issues/195025.
void testMain() {
  setUpCanvasKitTest();

  group('MultiSurfaceRasterizer view disposal', () {
    final createdHostElements = <DomElement>[];
    final createdViewIds = <int>[];

    setUp(() {
      debugOverrideJsConfiguration(
        <String, Object?>{
              'fontFallbackBaseUrl': 'assets/fallback_fonts/',
              'canvasKitForceMultiSurfaceRasterizer': true,
            }.jsify()
            as JsFlutterConfiguration?,
      );
      renderer.pictureToImageSurface.dispose();
      renderer.rasterizer.dispose();
      CanvasKitRenderer.instance.debugResetRasterizer();
    });

    tearDown(() {
      createdViewIds.forEach(
        EnginePlatformDispatcher.instance.viewManager.disposeAndUnregisterView,
      );
      createdViewIds.clear();
      for (final hostElement in createdHostElements) {
        hostElement.remove();
      }
      createdHostElements.clear();
      debugOverrideJsConfiguration(null);
      renderer.pictureToImageSurface.dispose();
      renderer.rasterizer.dispose();
      CanvasKitRenderer.instance.debugResetRasterizer();
    });

    EngineFlutterView createAndRegisterView() {
      final DomElement hostElement = createDomHTMLDivElement()
        ..style.width = '100px'
        ..style.height = '100px';
      domDocument.body!.append(hostElement);
      createdHostElements.add(hostElement);

      final view = EngineFlutterView(EnginePlatformDispatcher.instance, hostElement);
      EnginePlatformDispatcher.instance.viewManager.registerView(view);
      createdViewIds.add(view.viewId);
      return view;
    }

    void disposeAndRemoveView(EngineFlutterView view) {
      final DomElement hostElement = view.embeddingStrategy.hostElement;
      EnginePlatformDispatcher.instance.viewManager.disposeAndUnregisterView(view.viewId);
      hostElement.remove();
    }

    int Function() countDeleteContextCalls() {
      final originalDeleteContext = canvasKit['deleteContext']! as JSFunction;
      var calls = 0;
      void wrappedDeleteContext(JSNumber handle) {
        calls++;
        originalDeleteContext.callAsFunction(canvasKit, handle);
      }

      canvasKit['deleteContext'] = wrappedDeleteContext.toJS;
      addTearDown(() {
        canvasKit['deleteContext'] = originalDeleteContext;
      });
      return () => calls;
    }

    ui.Scene buildBlueScene() {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawRect(
        const ui.Rect.fromLTWH(0, 0, 100, 100),
        ui.Paint()..color = const ui.Color(0xFF0000FF),
      );
      final ui.Picture picture = recorder.endRecording();
      final builder = ui.SceneBuilder()..addPicture(ui.Offset.zero, picture);
      picture.dispose();
      return builder.build();
    }

    Future<void> renderBlueBox(EngineFlutterView view) async {
      final ui.Scene scene = buildBlueScene();
      try {
        await renderer.renderScene(scene, view);
      } finally {
        scene.dispose();
      }
    }

    test('a disposed view does not rebuild its surface when its context is lost', () async {
      final EngineFlutterView view = createAndRegisterView();
      await renderBlueBox(view);

      final viewRasterizer = renderer.rasterizers[view.viewId]! as MultiSurfaceViewRasterizer;
      final baseSurface = viewRasterizer.displayFactory.baseCanvas as CkOnscreenSurface;
      final initialCanvas = baseSurface.canvas as DomHTMLCanvasElement;
      final int initialGlContext = baseSurface.glContext;
      final WebGLContext gl = initialCanvas.getGlContext(webGLVersion);

      expect(initialGlContext, greaterThan(0));
      expect(baseSurface.skSurface, isNotNull);
      expect(gl.isContextLost(), isFalse);

      disposeAndRemoveView(view);

      if (!gl.isContextLost()) {
        gl.loseContextExtension.loseContext();
      }

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(
        baseSurface.canvas.strictEquals(initialCanvas).toDart,
        isTrue,
        reason: 'The removed view acquired a new canvas after its context was lost.',
      );
      expect(baseSurface.skSurface, isNull);
      expect(baseSurface.glContext, -1);
      expect(gl.isContextLost(), isTrue);
    }, skip: _skipContextLoss);

    test('repeated removeView/addView cycles do not evict the live view context', () async {
      final _WebGlContextCounter counter = _installWebGlContextCounter();
      addTearDown(counter.restore);

      EngineFlutterView activeView = createAndRegisterView();
      await renderBlueBox(activeView);

      final contextsAfterEachCycle = <int>[];
      for (var i = 0; i < 10; i++) {
        disposeAndRemoveView(activeView);
        activeView = createAndRegisterView();
        await renderBlueBox(activeView);
        contextsAfterEachCycle.add(counter.createdCount);
      }

      final liveRasterizer = renderer.rasterizers[activeView.viewId]! as MultiSurfaceViewRasterizer;
      final liveSnapshots = <_SurfaceSnapshot>[];
      liveRasterizer.displayFactory.forEachCanvas((OnscreenSurface surface) {
        final ckSurface = surface as CkOnscreenSurface;
        final canvas = ckSurface.canvas as DomHTMLCanvasElement;
        liveSnapshots.add(
          _SurfaceSnapshot(
            surface: ckSurface,
            initialCanvas: canvas,
            initialGl: canvas.getGlContext(webGLVersion),
            initialGlContext: ckSurface.glContext,
          ),
        );
      });

      final int countBeforeIdle = counter.createdCount;
      await Future<void>.delayed(const Duration(milliseconds: 500));

      final int contextsCreatedWhileIdle = counter.createdCount - countBeforeIdle;
      final int nonLostWebGlContexts = counter.nonLostCount;
      final List<bool> liveContextsLost = liveSnapshots
          .map((_SurfaceSnapshot s) => s.initialGl.isContextLost())
          .toList();
      final List<bool> liveCanvasesReplaced = liveSnapshots
          .map((_SurfaceSnapshot s) => !s.surface.canvas.strictEquals(s.initialCanvas).toDart)
          .toList();
      final List<bool> liveGlContextsChanged = liveSnapshots
          .map((_SurfaceSnapshot s) => s.surface.glContext != s.initialGlContext)
          .toList();

      final diagnostics =
          'WebGL contexts created after each cycle: $contextsAfterEachCycle; '
          'created while idle for 500ms: $contextsCreatedWhileIdle; '
          'non-lost WebGL contexts on the page: $nonLostWebGlContexts; '
          'live view surfaces: ${liveSnapshots.length}; '
          'live contexts lost: $liveContextsLost; '
          'live canvases replaced: $liveCanvasesReplaced; '
          'live glContexts changed: $liveGlContextsChanged.';

      expect(
        contextsCreatedWhileIdle,
        0,
        reason: 'Removed views keep recreating WebGL contexts. $diagnostics',
      );
      expect(
        nonLostWebGlContexts,
        2,
        reason:
            'Only the active live view base canvas and overlay should hold '
            'non-lost WebGL contexts. $diagnostics',
      );
      expect(liveSnapshots, hasLength(2), reason: diagnostics);
      expect(
        liveContextsLost,
        everyElement(isFalse),
        reason: 'Live view WebGL contexts were lost. $diagnostics',
      );
      expect(
        liveCanvasesReplaced,
        everyElement(isFalse),
        reason: 'Live view canvases were replaced. $diagnostics',
      );
      expect(
        liveGlContextsChanged,
        everyElement(isFalse),
        reason: 'Live view GL context handles changed. $diagnostics',
      );
    }, skip: _skipContextLoss);

    test('disposing software-rendered views does not touch WebGL or fail on post-disposal recovery calls', () async {
      CkSurface.debugForceGLFailure = true;
      addTearDown(() {
        CkSurface.debugForceGLFailure = false;
      });
      final _WebGlContextCounter counter = _installWebGlContextCounter();
      addTearDown(counter.restore);
      final int Function() deleteContextCalls = countDeleteContextCalls();

      final EngineFlutterView renderedView = createAndRegisterView();
      await renderBlueBox(renderedView);
      final renderedRasterizer =
          renderer.rasterizers[renderedView.viewId]! as MultiSurfaceViewRasterizer;
      final renderedSurface = renderedRasterizer.displayFactory.baseCanvas as CkOnscreenSurface;
      final renderedCanvas = renderedSurface.canvas as DomHTMLCanvasElement;

      final EngineFlutterView unflushedView = createAndRegisterView();
      final unflushedRasterizer =
          renderer.rasterizers[unflushedView.viewId]! as MultiSurfaceViewRasterizer;
      final unflushedSurface = unflushedRasterizer.displayFactory.baseCanvas as CkOnscreenSurface;
      await unflushedSurface.initialized;
      final unflushedCanvas = unflushedSurface.canvas as DomHTMLCanvasElement;

      expect(renderedSurface.isSoftware, isTrue);
      expect(renderedSurface.glContext, -1);
      expect(renderedSurface.skSurface, isNotNull);
      expect(unflushedSurface.isSoftware, isTrue);
      expect(unflushedSurface.glContext, -1);

      disposeAndRemoveView(renderedView);
      disposeAndRemoveView(unflushedView);

      expect(renderedSurface.isDisposed, isTrue);
      expect(renderedSurface.skSurface, isNull);
      expect(renderedSurface.glContext, -1);
      expect(unflushedSurface.isDisposed, isTrue);
      expect(unflushedSurface.skSurface, isNull);
      expect(unflushedSurface.glContext, -1);
      expect(counter.createdCount, 0);
      expect(deleteContextCalls(), 0);
      expect(unflushedCanvas.getContext('2d'), isNotNull);

      renderedSurface.onContextLost();
      await renderedSurface.recreateContextForCanvas(createDomCanvasElement(width: 10, height: 10));

      expect(renderedSurface.canvas.strictEquals(renderedCanvas).toDart, isTrue);
      expect(renderedSurface.skSurface, isNull);
      expect(counter.createdCount, 0);
      expect(deleteContextCalls(), 0);
    });

    test('disposing MultiSurfaceRasterizer directly cleans up rendered views without allocating unrendered surfaces', () async {
      final EngineFlutterView renderedViewA = createAndRegisterView();
      final EngineFlutterView renderedViewB = createAndRegisterView();
      final EngineFlutterView unrenderedView = createAndRegisterView();
      await renderBlueBox(renderedViewA);
      await renderBlueBox(renderedViewB);

      final rasterizerA = renderer.rasterizers[renderedViewA.viewId]! as MultiSurfaceViewRasterizer;
      final cachedOverlay = rasterizerA.getOverlay() as CkOnscreenSurface;
      await cachedOverlay.initialized;
      rasterizerA.releaseOverlay(cachedOverlay);

      final rasterizerB = renderer.rasterizers[renderedViewB.viewId]! as MultiSurfaceViewRasterizer;
      final unrenderedRasterizer =
          renderer.rasterizers[unrenderedView.viewId]! as MultiSurfaceViewRasterizer;
      expect(unrenderedRasterizer.displayFactory.hasBaseCanvas, isFalse);

      final multiSurfaceRasterizer = renderer.rasterizer as MultiSurfaceRasterizer;
      final extraSurface =
          multiSurfaceRasterizer.createPictureToImageSurface() as CkOnscreenSurface;
      await extraSurface.initialized;

      final trackedSurfaces = <CkOnscreenSurface>[
        extraSurface,
        renderer.pictureToImageSurface as CkOnscreenSurface,
      ];
      rasterizerA.displayFactory.forEachCanvas(
        (OnscreenSurface s) => trackedSurfaces.add(s as CkOnscreenSurface),
      );
      rasterizerB.displayFactory.forEachCanvas(
        (OnscreenSurface s) => trackedSurfaces.add(s as CkOnscreenSurface),
      );
      final List<WebGLContext> trackedContexts = trackedSurfaces
          .map(
            (CkOnscreenSurface s) => (s.canvas as DomHTMLCanvasElement).getGlContext(webGLVersion),
          )
          .toList();

      final _WebGlContextCounter counter = _installWebGlContextCounter();
      addTearDown(counter.restore);

      multiSurfaceRasterizer.dispose();

      expect(counter.createdCount, 0);
      expect(unrenderedRasterizer.displayFactory.hasBaseCanvas, isFalse);
      expect(unrenderedRasterizer.displayFactory.debugSurfaceCount, 0);
      for (var i = 0; i < trackedSurfaces.length; i++) {
        expect(trackedSurfaces[i].isDisposed, isTrue);
        expect(trackedSurfaces[i].skSurface, isNull);
        expect(trackedSurfaces[i].glContext, -1);
        expect(trackedContexts[i].isContextLost(), isTrue);
      }
    }, skip: _skipContextLoss);

    test('surface disposal is idempotent, detaches from SurfaceProvider, and ignores post-disposal context recreation', () async {
      renderer.pictureToImageSurface.dispose();
      renderer.rasterizer.dispose();
      final customRasterizer = MultiSurfaceRasterizer(_TrackingCkOnscreenSurface.new);
      addTearDown(customRasterizer.dispose);
      renderer.debugOverrideRasterizer(customRasterizer);
      final int Function() deleteContextCalls = countDeleteContextCalls();

      final EngineFlutterView disposedView = createAndRegisterView();
      final EngineFlutterView liveView = createAndRegisterView();
      await renderBlueBox(disposedView);
      await renderBlueBox(liveView);

      final disposedBase =
          (renderer.rasterizers[disposedView.viewId]! as MultiSurfaceViewRasterizer)
                  .displayFactory
                  .baseCanvas
              as _TrackingCkOnscreenSurface;
      final liveBase =
          (renderer.rasterizers[liveView.viewId]! as MultiSurfaceViewRasterizer)
                  .displayFactory
                  .baseCanvas
              as _TrackingCkOnscreenSurface;
      final initialCanvas = disposedBase.canvas as DomHTMLCanvasElement;

      customRasterizer.setResourceCacheMaxBytes(1000000);
      expect(disposedBase.resourceCacheLimitUpdates, 1);
      expect(liveBase.resourceCacheLimitUpdates, 1);

      final ui.VoidCallback? providerOnDispose = disposedBase.onDispose;
      var onDisposeCount = 0;
      disposedBase.onDispose = () {
        onDisposeCount++;
        providerOnDispose?.call();
      };

      disposeAndRemoveView(disposedView);
      final int deleteCallsAfterFirstDispose = deleteContextCalls();

      expect(disposedBase.isDisposed, isTrue);
      expect(onDisposeCount, 1);
      // One `deleteContext` call each for the view's base canvas and the
      // overlay used to composite its scene.
      expect(deleteCallsAfterFirstDispose, 2);

      disposedBase.dispose();
      expect(onDisposeCount, 1);
      expect(deleteContextCalls(), deleteCallsAfterFirstDispose);

      customRasterizer.setResourceCacheMaxBytes(2000000);
      expect(disposedBase.resourceCacheLimitUpdates, 1);
      expect(liveBase.resourceCacheLimitUpdates, 2);

      final DomHTMLCanvasElement replacementCanvas = createDomCanvasElement(width: 20, height: 20);
      await disposedBase.recreateContextForCanvas(replacementCanvas);
      expect(disposedBase.canvas.strictEquals(initialCanvas).toDart, isTrue);
      expect(replacementCanvas.isConnected, isFalse);
      expect(disposedBase.skSurface, isNull);
      expect(disposedBase.glContext, -1);
    });

    test(
      'disposing a view mid-render completes queued renders without allocating zombie surfaces',
      () async {
        EnginePlatformDispatcher.instance.onReportTimings = (_) {};
        addTearDown(() {
          EnginePlatformDispatcher.instance.onReportTimings = null;
          FrameTimingRecorder.debugResetFrameTimings();
        });

        final EngineFlutterView view = createAndRegisterView();
        final viewRasterizer = renderer.rasterizers[view.viewId]! as MultiSurfaceViewRasterizer;

        final ui.Scene scene1 = buildBlueScene();
        final ui.Scene scene2 = buildBlueScene();
        addTearDown(() {
          scene1.dispose();
          scene2.dispose();
        });

        final Future<void> render1 = renderer.renderScene(scene1, view);
        expect(viewRasterizer.displayFactory.hasBaseCanvas, isTrue);
        final baseSurface = viewRasterizer.displayFactory.baseCanvas as CkOnscreenSurface;
        final Future<void> render2 = renderer.renderScene(scene2, view);
        expect(viewRasterizer.queue.current, isNotNull);
        expect(viewRasterizer.queue.next, isNotNull);

        final _WebGlContextCounter counter = _installWebGlContextCounter();
        addTearDown(counter.restore);

        disposeAndRemoveView(view);

        await Future.wait<void>(<Future<void>>[render1, render2])
            .timeout(const Duration(seconds: 2));

        expect(counter.createdCount, 0);
        expect(viewRasterizer.displayFactory.hasBaseCanvas, isFalse);
        expect(viewRasterizer.displayFactory.debugSurfaceCount, 0);
        expect(baseSurface.isDisposed, isTrue);
        expect(baseSurface.skSurface, isNull);
        expect(baseSurface.glContext, -1);

        final recorder = ui.PictureRecorder();
        ui.Canvas(recorder).drawRect(
          const ui.Rect.fromLTWH(0, 0, 10, 10),
          ui.Paint()..color = const ui.Color(0xFFFF0000),
        );
        final ui.Picture picture = recorder.endRecording();
        addTearDown(picture.dispose);

        baseSurface.setSize(const BitmapSize(50, 50));
        await baseSurface.rasterizeToCanvas(picture);

        expect(counter.createdCount, 0);
        expect(baseSurface.skSurface, isNull);
        expect(baseSurface.glContext, -1);
      },
    );
  });
}

final class _TrackingCkOnscreenSurface extends CkOnscreenSurface {
  _TrackingCkOnscreenSurface(super.canvasProvider);

  int resourceCacheLimitUpdates = 0;

  @override
  void setSkiaResourceCacheMaxBytes(int bytes) {
    resourceCacheLimitUpdates++;
    super.setSkiaResourceCacheMaxBytes(bytes);
  }
}

final class _SurfaceSnapshot {
  _SurfaceSnapshot({
    required this.surface,
    required this.initialCanvas,
    required this.initialGl,
    required this.initialGlContext,
  });

  final CkOnscreenSurface surface;
  final DomHTMLCanvasElement initialCanvas;
  final WebGLContext initialGl;
  final int initialGlContext;
}

final class _WebGlContextCounter {
  _WebGlContextCounter(this._contexts, this.restore);

  final List<WebGLContext> _contexts;
  final void Function() restore;

  int get createdCount => _contexts.length;

  int get nonLostCount => _contexts.where((WebGLContext ctx) => !ctx.isContextLost()).length;
}

_WebGlContextCounter _installWebGlContextCounter() {
  final htmlCanvasConstructor = globalContext['HTMLCanvasElement']! as JSObject;
  final prototype = htmlCanvasConstructor['prototype']! as JSObject;
  final originalGetContext = prototype['getContext']! as JSFunction;
  final contexts = <WebGLContext>[];

  JSAny? wrappedGetContext(JSObject canvas, JSString contextType, [JSAny? attributes]) {
    final JSAny? result = attributes == null
        ? originalGetContext.callAsFunction(canvas, contextType)
        : originalGetContext.callAsFunction(canvas, contextType, attributes);
    final String type = contextType.toDart;
    if ((type == 'webgl' || type == 'webgl2') && result != null) {
      final bool alreadyTracked = contexts.any(
        (WebGLContext existing) => existing.strictEquals(result).toDart,
      );
      if (!alreadyTracked) {
        contexts.add(result as WebGLContext);
      }
    }
    return result;
  }

  prototype['getContext'] = wrappedGetContext.toJSCaptureThis;
  return _WebGlContextCounter(contexts, () {
    prototype['getContext'] = originalGetContext;
  });
}
