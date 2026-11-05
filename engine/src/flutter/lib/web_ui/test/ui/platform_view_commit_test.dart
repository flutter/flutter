// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';
import 'utils.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  setUpUnitTests();
  for (final forceMultiSurface in <bool>[false, if (isCanvasKit) true]) {
    group('force CanvasKit multi-surface: $forceMultiSurface', () {
      late EngineFlutterView view;
      late _PausedViewRasterizer rasterizer;
      late DomElement host;

      setUp(() {
        debugOverrideJsConfiguration(
          <String, Object>{'canvasKitForceMultiSurfaceRasterizer': forceMultiSurface}.jsify()
              as JsFlutterConfiguration?,
        );
        renderer.rasterizer.dispose();
        renderer.debugResetRasterizer();
        host = createDomHTMLDivElement();
        domDocument.body!.append(host);
        view = EngineFlutterView(EnginePlatformDispatcher.instance, host);
        view.debugPhysicalSizeOverride = const ui.Size(100, 100);
        view.debugForceResize();
        rasterizer = _PausedViewRasterizer(view, renderer.rasterizer.createViewRasterizer(view));
        renderer.rasterizers[view.viewId] = rasterizer;
        PlatformViewManager.instance.registerFactory(
          'commit-test',
          (int id) => createDomHTMLDivElement(),
        );
        PlatformViewManager.instance.renderContent('commit-test', 1, null);
      });

      tearDown(() {
        debugOverlayOptimizationBounds = false;
        EnginePlatformDispatcher.instance.onReportTimings = null;
        FrameTimingRecorder.debugResetFrameTimings();
        rasterizer.dispose();
        view.dispose();
        host.remove();
        PlatformViewManager.instance.debugClear();
        renderer.rasterizer.dispose();
        debugOverrideJsConfiguration(null);
        renderer.debugResetRasterizer();
      });

      Future<void> draw({double width = 20, bool clipped = false, bool platformView = true}) async {
        final recorder = ui.PictureRecorder();
        ui.Canvas(recorder).drawRect(
          const ui.Rect.fromLTWH(0, 0, 100, 100),
          ui.Paint()..color = const ui.Color(0xFFFF0000),
        );
        final ui.Picture picture = recorder.endRecording();
        final builder = ui.SceneBuilder()..addPicture(ui.Offset.zero, picture);
        if (platformView) {
          if (clipped) {
            builder.pushClipRect(const ui.Rect.fromLTWH(0, 0, 50, 50));
          }
          builder.addPlatformView(1, width: width, height: 20);
          if (clipped) {
            builder.pop();
          }
          builder.addPicture(ui.Offset.zero, picture);
        }
        final scene = builder.build() as LayerScene;
        try {
          await renderer.renderScene(scene, view);
        } finally {
          scene.dispose();
          picture.dispose();
        }
      }

      Future<void> whilePaused(Future<void> pending, void Function() check) async {
        try {
          await Future.any(<Future<void>>[rasterizer.reached.future, pending]);
          check();
        } finally {
          rasterizer.release();
          await pending;
        }
      }

      test('platform view size and clip chain change only after rasterization', () async {
        await draw();
        final DomElement scene = rasterizer.sceneElement;
        final List<DomElement> children = scene.children.toList();
        final DomElement slot = scene.querySelector('flt-platform-view-slot')!;
        expect(slot.style.width, '20px');

        rasterizer.hold();
        final Future<void> pending = draw(width: 40, clipped: true);
        await whilePaused(pending, () {
          expect(scene.children, orderedEquals(children));
          expect(slot.style.width, '20px');
          expect(scene.querySelectorAll('flt-clip'), isEmpty);
        });

        expect(slot.style.width, '40px');
        expect(scene.querySelectorAll('flt-clip'), hasLength(1));
        expect(slot.isConnected, isTrue);
      });

      test('entering and leaving a platform view retains the old DOM until ready', () async {
        await draw(platformView: false);
        for (final entering in <bool>[true, false]) {
          final List<DomElement> previous = rasterizer.sceneElement.children.toList();
          rasterizer.hold();
          final Future<void> pending = draw(platformView: entering);
          await whilePaused(pending, () {
            expect(rasterizer.sceneElement.children, orderedEquals(previous));
          });
          expect(
            rasterizer.sceneElement.querySelectorAll('flt-platform-view-slot'),
            hasLength(entering ? 1 : 0),
          );
        }
      });

      test('disposal during preparation does not submit a cleared frame', () async {
        await draw();
        EnginePlatformDispatcher.instance.onReportTimings = (List<ui.FrameTiming> timings) {
          fail('A canceled frame must not report timings.');
        };
        rasterizer.hold(preparation: true);
        final Future<void> pending = draw(width: 40);
        await whilePaused(pending, rasterizer.dispose);
        expect(FrameTimingRecorder.debugFrameTimings, isEmpty);
        expect(rasterizer.sceneElement.children, isEmpty);
      });

      test('drawing a disposed view does not prepare or commit a frame', () async {
        rasterizer.dispose();
        await draw();
        expect(rasterizer.preparations, 0);
        expect(rasterizer.sceneElement.children, isEmpty);
      });

      test('a rasterization failure preserves the DOM and permits the next frame', () async {
        await draw(platformView: false);
        final List<DomElement> previous = rasterizer.sceneElement.children.toList();
        final Composition previousComposition = rasterizer.viewEmbedder.debugActiveComposition;
        rasterizer.failNextFrame = true;
        await expectLater(draw(), throwsStateError);
        expect(rasterizer.sceneElement.children, orderedEquals(previous));
        expect(rasterizer.viewEmbedder.debugActiveComposition, same(previousComposition));
        await draw(width: 40);
        expect(
          rasterizer.sceneElement.querySelector('flt-platform-view-slot')!.style.width,
          '40px',
        );
      });

      test('allocation failure releases earlier canvases and permits the next frame', () async {
        rasterizer.failOverlayAfter = 1;
        await expectLater(draw(), throwsStateError);
        expect(rasterizer.allocatedCanvases, hasLength(1));
        expect(rasterizer.displayFactory.isLive(rasterizer.allocatedCanvases.single), isFalse);
        expect(rasterizer.sceneElement.children, isEmpty);
        await draw(width: 40);
        expect(rasterizer.sceneElement.querySelectorAll('flt-platform-view-slot'), hasLength(1));
        expect(
          rasterizer.sceneElement.querySelector('flt-platform-view-slot')!.style.width,
          '40px',
        );
      });

      for (final afterRasterization in <bool>[false, true]) {
        test(
          'disposal while rasterization is pending (after drawing: $afterRasterization)',
          () async {
            await draw();
            EnginePlatformDispatcher.instance.onReportTimings = (List<ui.FrameTiming> timings) {
              fail('A canceled frame must not report timings.');
            };
            rasterizer.hold(afterRasterization: afterRasterization);
            final Future<void> pending = draw(width: 40);
            await whilePaused(pending, () {
              rasterizer.dispose();
              expect(rasterizer.sceneElement.children, isEmpty);
            });
            expect(FrameTimingRecorder.debugFrameTimings, isEmpty);
            expect(rasterizer.viewEmbedder.debugActiveComposition.entities, isEmpty);
            if (isCanvasKit && forceMultiSurface) {
              for (final CkOnscreenSurface canvas
                  in rasterizer.lastCanvases.cast<CkOnscreenSurface>()) {
                expect(canvas.skSurface, isNull);
              }
            }
          },
        );
      }

      test('disposal at a rasterizer await does not use destroyed surfaces', () async {
        await draw();
        rasterizer.disposeAfterRasterizeStarts = true;
        await draw(width: 40);
        expect(rasterizer.sceneElement.children, isEmpty);
        expect(rasterizer.viewEmbedder.debugActiveComposition.entities, isEmpty);
      });

      test('disposal during the first frame releases temporary canvases', () async {
        rasterizer.hold();
        final Future<void> pending = draw();
        await whilePaused(pending, rasterizer.dispose);
        expect(rasterizer.allocatedCanvases, hasLength(2));
        for (final DisplayCanvas canvas in rasterizer.allocatedCanvases) {
          expect(rasterizer.displayFactory.isLive(canvas), isFalse);
          if (canvas is CkOnscreenSurface) {
            expect(canvas.skSurface, isNull);
          }
        }
        expect(rasterizer.sceneElement.children, isEmpty);
      });

      test('disposal while drawing debug bounds does not publish a canvas', () async {
        debugOverlayOptimizationBounds = true;
        rasterizer.hold(skip: 1);
        final Future<void> pending = draw();
        await whilePaused(pending, rasterizer.dispose);
        expect(rasterizer.sceneElement.children, isEmpty);
        expect(rasterizer.viewEmbedder.debugBoundsCanvas, isNull);
      });

      test('a view removed during rasterization can be recreated with the same ID', () async {
        await draw();
        rasterizer.hold();
        final Future<void> pending = draw(width: 40);
        await whilePaused(pending, () => PlatformViewManager.instance.clearPlatformView(1));
        expect(
          rasterizer.viewEmbedder.debugActiveComposition.entities
              .whereType<CompositionPlatformView>(),
          isEmpty,
        );
        PlatformViewManager.instance.renderContent('commit-test', 1, null);
        await draw(width: 40);
        final DomElement slot = rasterizer.sceneElement.querySelector('flt-platform-view-slot')!;
        expect(slot.style.width, '40px');
        expect(slot.isConnected, isTrue);
      });
    });
  }
}

class _PausedViewRasterizer extends ViewRasterizer {
  _PausedViewRasterizer(super.view, this.delegate);
  final ViewRasterizer delegate;
  Completer<void>? _release;
  late Completer<void> reached;
  bool failNextFrame = false;
  int? failOverlayAfter;
  final List<DisplayCanvas> allocatedCanvases = <DisplayCanvas>[];
  List<DisplayCanvas> lastCanvases = <DisplayCanvas>[];
  bool disposeAfterRasterizeStarts = false;
  int preparations = 0;
  bool _holdPreparation = false;
  bool _holdAfterRasterization = false;
  int _rasterizationsToSkip = 0;

  void hold({bool preparation = false, bool afterRasterization = false, int skip = 0}) {
    _holdPreparation = preparation;
    _holdAfterRasterization = afterRasterization;
    _rasterizationsToSkip = skip;
    reached = Completer<void>();
    _release = Completer<void>();
  }

  void release() {
    _release!.complete();
    _release = null;
  }

  @override
  DisplayCanvasFactory<DisplayCanvas> get displayFactory => delegate.displayFactory;

  @override
  DisplayCanvas getOverlay() {
    if (failOverlayAfter == 0) {
      failOverlayAfter = null;
      throw StateError('Simulated overlay allocation failure.');
    }
    if (failOverlayAfter != null) {
      failOverlayAfter = failOverlayAfter! - 1;
    }
    final DisplayCanvas canvas = super.getOverlay();
    allocatedCanvases.add(canvas);
    return canvas;
  }

  @override
  Future<void> prepareToDraw() async {
    preparations++;
    delegate.currentFrameSize = currentFrameSize;
    await delegate.prepareToDraw();
    final Completer<void>? release = _release;
    if (_holdPreparation && release != null) {
      reached.complete();
      await release.future;
    }
  }

  @override
  Future<void> rasterize(
    List<DisplayCanvas> canvases,
    List<ui.Picture> pictures,
    FrameTimingRecorder? recorder,
  ) async {
    lastCanvases = canvases;
    if (_rasterizationsToSkip > 0) {
      _rasterizationsToSkip--;
      await delegate.rasterize(canvases, pictures, recorder);
      return;
    }
    final Completer<void>? release = _release;
    if (!_holdPreparation && !_holdAfterRasterization && release != null) {
      reached.complete();
      await release.future;
    }
    if (failNextFrame) {
      failNextFrame = false;
      throw StateError('Simulated rasterization failure.');
    }
    final Future<void> pending = delegate.rasterize(canvases, pictures, recorder);
    if (disposeAfterRasterizeStarts) {
      disposeAfterRasterizeStarts = false;
      dispose();
    }
    await pending;
    if (_holdAfterRasterization && release != null) {
      reached.complete();
      await release.future;
    }
  }

  @override
  void dispose() {
    super.dispose();
    delegate.dispose();
  }
}
