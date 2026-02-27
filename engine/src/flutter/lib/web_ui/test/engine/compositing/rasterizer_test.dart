// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

class TestRasterizer extends Rasterizer {
  Map<EngineFlutterView, TestViewRasterizer> viewRasterizers =
      <EngineFlutterView, TestViewRasterizer>{};

  @override
  TestViewRasterizer createViewRasterizer(EngineFlutterView view) {
    return viewRasterizers.putIfAbsent(view, () => TestViewRasterizer(view));
  }

  @override
  void dispose() {
    // Do nothing
  }

  @override
  void setResourceCacheMaxBytes(int bytes) {
    // Do nothing
  }

  List<LayerTree> treesRenderedInView(EngineFlutterView view) {
    return viewRasterizers[view]!.treesRendered;
  }

  @override
  Surface createPictureToImageSurface() {
    throw UnimplementedError();
  }

  @override
  SurfaceProvider get surfaceProvider => throw UnimplementedError();
}

class TestViewRasterizer extends ViewRasterizer {
  TestViewRasterizer(super.view);

  List<LayerTree> treesRendered = <LayerTree>[];

  @override
  DisplayCanvasFactory<DisplayCanvas> get displayFactory => throw UnimplementedError();

  @override
  Future<void> prepareToDraw() {
    return Future<void>.value();
  }

  @override
  Future<void> draw(LayerTree tree, FrameTimingRecorder? recorder) async {
    treesRendered.add(tree);
    return Future<void>.value();
  }

  @override
  Future<void> rasterize(
    List<DisplayCanvas> displayCanvases,
    List<ui.Picture> pictures,
    FrameTimingRecorder? recorder,
  ) {
    // No-op
    return Future<void>.value();
  }

  @override
  Map<String, dynamic>? dumpDebugInfo() {
    return null;
  }
}

void testMain() {
  group('Rasterizer', () {
    setUpUnitTests();

    tearDown(() {
      renderer.debugResetRasterizer();
    });

    test('always renders most recent picture and skips intermediate pictures', () async {
      final testRasterizer = TestRasterizer();
      renderer.debugOverrideRasterizer(testRasterizer);

      // Create another view to render into to force the renderer to make
      // a [ViewRasterizer] for it.
      final testView = EngineFlutterView(
        EnginePlatformDispatcher.instance,
        createDomElement('test-view'),
      );
      EnginePlatformDispatcher.instance.viewManager.registerView(testView);

      final treesToRender = <LayerTree>[];
      final renderFutures = <Future<void>>[];
      for (var i = 1; i < 20; i++) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.drawRect(
          const ui.Rect.fromLTWH(0, 0, 50, 50),
          ui.Paint()..color = const ui.Color(0xff00ff00),
        );
        final ui.Picture picture = recorder.endRecording();
        final builder = ui.SceneBuilder();
        builder.addPicture(ui.Offset.zero, picture);
        final ui.Scene scene = builder.build();
        treesToRender.add((scene as LayerScene).layerTree);
        renderFutures.add(renderer.renderScene(scene, testView));
      }
      await Future.wait(renderFutures);

      // Should just render the first and last pictures and skip the one inbetween.
      final List<LayerTree> treesRendered = testRasterizer.treesRenderedInView(testView);
      expect(treesRendered.length, 2);
      expect(treesRendered.first, treesToRender.first);
      expect(treesRendered.last, treesToRender.last);
    });

    test('can render multiple frames at once into multiple views', () async {
      final testRasterizer = TestRasterizer();
      renderer.debugOverrideRasterizer(testRasterizer);

      // Create another view to render into to force the renderer to make
      // a [ViewRasterizer] for it.
      final testView1 = EngineFlutterView(
        EnginePlatformDispatcher.instance,
        createDomElement('test-view'),
      );
      EnginePlatformDispatcher.instance.viewManager.registerView(testView1);
      final testView2 = EngineFlutterView(
        EnginePlatformDispatcher.instance,
        createDomElement('test-view'),
      );
      EnginePlatformDispatcher.instance.viewManager.registerView(testView2);
      final testView3 = EngineFlutterView(
        EnginePlatformDispatcher.instance,
        createDomElement('test-view'),
      );
      EnginePlatformDispatcher.instance.viewManager.registerView(testView3);

      final treesToRender = <EngineFlutterView, List<LayerTree>>{};
      treesToRender[testView1] = <LayerTree>[];
      treesToRender[testView2] = <LayerTree>[];
      treesToRender[testView3] = <LayerTree>[];
      final renderFutures = <Future<void>>[];

      for (var i = 1; i < 20; i++) {
        for (final testView in <EngineFlutterView>[testView1, testView2, testView3]) {
          final recorder = ui.PictureRecorder();
          final canvas = ui.Canvas(recorder);
          canvas.drawRect(
            const ui.Rect.fromLTWH(0, 0, 50, 50),
            ui.Paint()..color = const ui.Color(0xff00ff00),
          );
          final ui.Picture picture = recorder.endRecording();
          final builder = ui.SceneBuilder();
          builder.addPicture(ui.Offset.zero, picture);
          final ui.Scene scene = builder.build();
          treesToRender[testView]!.add((scene as LayerScene).layerTree);
          renderFutures.add(renderer.renderScene(scene, testView));
        }
      }
      await Future.wait(renderFutures);

      // Should just render the first and last pictures and skip the one inbetween.
      final List<LayerTree> treesRenderedInView1 = testRasterizer.treesRenderedInView(testView1);
      final List<LayerTree> treesToRenderInView1 = treesToRender[testView1]!;
      expect(treesRenderedInView1.length, 2);
      expect(treesRenderedInView1.first, treesToRenderInView1.first);
      expect(treesRenderedInView1.last, treesToRenderInView1.last);

      final List<LayerTree> treesRenderedInView2 = testRasterizer.treesRenderedInView(testView2);
      final List<LayerTree> treesToRenderInView2 = treesToRender[testView2]!;
      expect(treesRenderedInView2.length, 2);
      expect(treesRenderedInView2.first, treesToRenderInView2.first);
      expect(treesRenderedInView2.last, treesToRenderInView2.last);

      final List<LayerTree> treesRenderedInView3 = testRasterizer.treesRenderedInView(testView3);
      final List<LayerTree> treesToRenderInView3 = treesToRender[testView3]!;
      expect(treesRenderedInView3.length, 2);
      expect(treesRenderedInView3.first, treesToRenderInView3.first);
      expect(treesRenderedInView3.last, treesToRenderInView3.last);
    });
  });
}
