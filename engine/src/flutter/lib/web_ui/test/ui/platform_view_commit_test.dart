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
        PlatformViewManager.instance.registerFactory(
          'commit-test',
          (int id) => createDomHTMLDivElement(),
        );
        PlatformViewManager.instance.renderContent('commit-test', 1, null);
      });

      tearDown(() {
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
          await rasterizer.draw(scene.layerTree, null);
        } finally {
          scene.dispose();
          picture.dispose();
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
        await rasterizer.reached.future;
        expect(scene.children, orderedEquals(children));
        expect(slot.style.width, '20px');
        expect(scene.querySelectorAll('flt-clip'), isEmpty);
        rasterizer.release();
        await pending;

        expect(slot.style.width, '40px');
        expect(scene.querySelectorAll('flt-clip'), hasLength(1));
        expect(slot.isConnected, isTrue);
        expect(rasterizer.commits, 2);
      });

      test('entering and leaving a platform view retains the old DOM until ready', () async {
        await draw(platformView: false);
        for (final entering in <bool>[true, false]) {
          final List<DomElement> previous = rasterizer.sceneElement.children.toList();
          rasterizer.hold();
          final Future<void> pending = draw(platformView: entering);
          await rasterizer.reached.future;
          expect(rasterizer.sceneElement.children, orderedEquals(previous));
          rasterizer.release();
          await pending;
          expect(
            rasterizer.sceneElement.querySelectorAll('flt-platform-view-slot'),
            hasLength(entering ? 1 : 0),
          );
        }
      });

      test('a rasterization failure preserves the DOM and permits the next frame', () async {
        await draw(platformView: false);
        final List<DomElement> previous = rasterizer.sceneElement.children.toList();
        rasterizer.failNextFrame = true;
        await expectLater(draw(), throwsStateError);
        expect(rasterizer.sceneElement.children, orderedEquals(previous));
        expect(rasterizer.commits, 1);
        await draw(width: 40);
        expect(
          rasterizer.sceneElement.querySelector('flt-platform-view-slot')!.style.width,
          '40px',
        );
        expect(rasterizer.commits, 2);
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
  int commits = 0;

  void hold() {
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
  Future<void> prepareToDraw() {
    delegate.currentFrameSize = currentFrameSize;
    return delegate.prepareToDraw();
  }

  @override
  Future<void> rasterize(
    List<DisplayCanvas> canvases,
    List<ui.Picture> pictures,
    FrameTimingRecorder? recorder,
  ) async {
    final Completer<void>? release = _release;
    if (release != null) {
      reached.complete();
      await release.future;
    }
    if (failNextFrame) {
      failNextFrame = false;
      throw StateError('Simulated rasterization failure.');
    }
    await delegate.rasterize(canvases, pictures, recorder);
  }

  @override
  void commitFrame() {
    commits++;
    delegate.commitFrame();
  }

  @override
  void dispose() {
    super.dispose();
    delegate.dispose();
  }
}
