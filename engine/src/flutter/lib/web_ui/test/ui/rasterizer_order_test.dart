// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

class MockViewEmbedder extends PlatformViewEmbedder {
  MockViewEmbedder(super.sceneHost, super.rasterizer);

  bool optimizeCompositionCalled = false;
  BitmapSize? frameSizeDuringOptimize;
  BitmapSize? _capturedFrameSize;

  @override
  set frameSize(BitmapSize size) {
    _capturedFrameSize = size;
    super.frameSize = size;
  }

  @override
  void optimizeComposition() {
    optimizeCompositionCalled = true;
    frameSizeDuringOptimize = _capturedFrameSize;
  }

  @override
  Future<void> submitFrame(FrameTimingRecorder? recorder) async {
    await rasterizer.rasterize(<DisplayCanvas>[], <ui.Picture>[], recorder);
  }

  @override
  Iterable<LayerCanvas> getOptimizedCanvases() => <LayerCanvas>[];
}

class OrderVerifyingRasterizer extends ViewRasterizer {
  OrderVerifyingRasterizer(super.view);

  bool prepareToDrawCalled = false;
  bool rasterizeCalled = false;

  // We track the state of these flags when each method is called
  bool? optimizeCompositionCalledDuringPrepare;
  bool? prepareToDrawCalledDuringRasterize;
  BitmapSize? sizeDuringPrepare;
  BitmapSize? sizeDuringRasterize;

  late final MockViewEmbedder _viewEmbedder = MockViewEmbedder(sceneElement, this);

  @override
  MockViewEmbedder get viewEmbedder => _viewEmbedder;

  @override
  DisplayCanvasFactory<DisplayCanvas> get displayFactory => throw UnimplementedError();

  @override
  Future<void> prepareToDraw() async {
    prepareToDrawCalled = true;
    sizeDuringPrepare = currentFrameSize;
    optimizeCompositionCalledDuringPrepare = viewEmbedder.optimizeCompositionCalled;
  }

  @override
  Future<void> rasterize(
    List<DisplayCanvas> displayCanvases,
    List<ui.Picture> pictures,
    FrameTimingRecorder? recorder,
  ) async {
    rasterizeCalled = true;
    sizeDuringRasterize = currentFrameSize;
    prepareToDrawCalledDuringRasterize = prepareToDrawCalled;
  }
}

void testMain() {
  group('Rasterizer order', () {
    setUpUnitTests();

    test('calls prepareToDraw after raster (optimizeComposition) and before rasterize', () async {
      final view = EngineFlutterView(
        EnginePlatformDispatcher.instance,
        domDocument.createElement('div'),
      );
      final rasterizer = OrderVerifyingRasterizer(view);

      final rootLayer = RootLayer();
      final layerTree = LayerTree(rootLayer);

      // physicalSize must be non-empty for draw() to proceed
      view.debugPhysicalSizeOverride = const ui.Size(100, 100);
      view.debugForceResize();

      await rasterizer.draw(layerTree, null);

      final MockViewEmbedder mockEmbedder = rasterizer.viewEmbedder;

      expect(
        mockEmbedder.optimizeCompositionCalled,
        isTrue,
        reason: 'optimizeComposition should be called',
      );
      expect(rasterizer.prepareToDrawCalled, isTrue, reason: 'prepareToDraw should be called');
      expect(rasterizer.rasterizeCalled, isTrue, reason: 'rasterize should be called');

      expect(
        rasterizer.optimizeCompositionCalledDuringPrepare,
        isTrue,
        reason: 'optimizeComposition (part of raster) should have been called before prepareToDraw',
      );

      expect(
        rasterizer.prepareToDrawCalledDuringRasterize,
        isTrue,
        reason: 'prepareToDraw should have been called before rasterize (part of submitFrame)',
      );
    });

    test('currentFrameSize is updated before prepareToDraw', () async {
      final view = EngineFlutterView(
        EnginePlatformDispatcher.instance,
        domDocument.createElement('div'),
      );
      final rasterizer = OrderVerifyingRasterizer(view);

      final rootLayer = RootLayer();
      final layerTree = LayerTree(rootLayer);

      view.debugPhysicalSizeOverride = const ui.Size(123, 456);
      view.debugForceResize();

      await rasterizer.draw(layerTree, null);

      expect(rasterizer.sizeDuringPrepare, const BitmapSize(123, 456));
    });

    test('renders two frames at different sizes and uses the correct size for each', () async {
      final view = EngineFlutterView(
        EnginePlatformDispatcher.instance,
        domDocument.createElement('div'),
      );
      final rasterizer = OrderVerifyingRasterizer(view);
      final MockViewEmbedder mockEmbedder = rasterizer.viewEmbedder;

      final rootLayer = RootLayer();
      final layerTree = LayerTree(rootLayer);

      // Frame 1: 100x200
      view.debugPhysicalSizeOverride = const ui.Size(100, 200);
      view.debugForceResize();
      await rasterizer.draw(layerTree, null);

      expect(mockEmbedder.frameSizeDuringOptimize, const BitmapSize(100, 200));
      expect(rasterizer.sizeDuringPrepare, const BitmapSize(100, 200));
      expect(rasterizer.sizeDuringRasterize, const BitmapSize(100, 200));

      // Frame 2: 300x400
      view.debugPhysicalSizeOverride = const ui.Size(300, 400);
      view.debugForceResize();
      await rasterizer.draw(layerTree, null);

      expect(mockEmbedder.frameSizeDuringOptimize, const BitmapSize(300, 400));
      expect(rasterizer.sizeDuringPrepare, const BitmapSize(300, 400));
      expect(rasterizer.sizeDuringRasterize, const BitmapSize(300, 400));
    });
  });
}
