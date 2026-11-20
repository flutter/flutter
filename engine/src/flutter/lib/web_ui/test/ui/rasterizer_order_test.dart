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

      await rasterizer.draw(layerTree, view.physicalSize, null);

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

      await rasterizer.draw(layerTree, view.physicalSize, null);

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
      await rasterizer.draw(layerTree, const ui.Size(100, 200), null);

      expect(mockEmbedder.frameSizeDuringOptimize, const BitmapSize(100, 200));
      expect(rasterizer.sizeDuringPrepare, const BitmapSize(100, 200));
      expect(rasterizer.sizeDuringRasterize, const BitmapSize(100, 200));

      // Frame 2: 300x400
      await rasterizer.draw(layerTree, const ui.Size(300, 400), null);

      expect(mockEmbedder.frameSizeDuringOptimize, const BitmapSize(300, 400));
      expect(rasterizer.sizeDuringPrepare, const BitmapSize(300, 400));
      expect(rasterizer.sizeDuringRasterize, const BitmapSize(300, 400));
    });

    test('uses passed frameSize rather than view.physicalSize', () async {
      final view = EngineFlutterView(
        EnginePlatformDispatcher.instance,
        domDocument.createElement('div'),
      );
      final rasterizer = OrderVerifyingRasterizer(view);
      final MockViewEmbedder mockEmbedder = rasterizer.viewEmbedder;

      final rootLayer = RootLayer();
      final layerTree = LayerTree(rootLayer);

      // Simulate a host element constrained to 360x260 while the framework
      // renders a 680x260 frame via viewConstraints.
      view.debugPhysicalSizeOverride = const ui.Size(360, 260);
      view.debugForceResize();

      await rasterizer.draw(layerTree, const ui.Size(680, 260), null);

      expect(view.physicalSize, const ui.Size(360, 260));
      expect(mockEmbedder.frameSizeDuringOptimize, const BitmapSize(680, 260));
      expect(rasterizer.sizeDuringPrepare, const BitmapSize(680, 260));
      expect(rasterizer.sizeDuringRasterize, const BitmapSize(680, 260));
    });

    test('skips drawing when frameSize is empty or rounds to 0 physical pixels', () async {
      final view = EngineFlutterView(
        EnginePlatformDispatcher.instance,
        domDocument.createElement('div'),
      );
      final rasterizer = OrderVerifyingRasterizer(view);
      final MockViewEmbedder mockEmbedder = rasterizer.viewEmbedder;

      final rootLayer = RootLayer();
      final layerTree = LayerTree(rootLayer);

      for (final size in const <ui.Size>[
        ui.Size.zero,
        ui.Size(0, double.infinity),
        ui.Size(360, 0.2),
        ui.Size(0.4, 260),
      ]) {
        await rasterizer.draw(layerTree, size, null);
      }

      expect(mockEmbedder.optimizeCompositionCalled, isFalse);
      expect(rasterizer.prepareToDrawCalled, isFalse);
      expect(rasterizer.rasterizeCalled, isFalse);
      expect(rasterizer.currentFrameSize, BitmapSize.zero);
    });
  });
}
