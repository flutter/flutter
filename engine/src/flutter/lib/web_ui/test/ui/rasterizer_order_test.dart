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

class OrderVerifyingRasterizer extends ViewRasterizer {
  OrderVerifyingRasterizer(super.view);

  bool prepareToDrawCalled = false;
  bool rasterizeCalled = false;

  bool? prepareToDrawCalledDuringRasterize;
  BitmapSize? sizeDuringPrepare;
  BitmapSize? sizeDuringRasterize;

  @override
  DisplayCanvasFactory<DisplayCanvas> get displayFactory => throw UnimplementedError();

  @override
  Future<void> prepareToDraw() async {
    prepareToDrawCalled = true;
    sizeDuringPrepare = currentFrameSize;
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

  @override
  Future<void> draw(LayerTree layerTree, FrameTimingRecorder? recorder) async {
    final ui.Size frameSize = view.physicalSize;
    if (frameSize.isEmpty) {
      return;
    }
    currentFrameSize = BitmapSize.fromSize(frameSize);
    await prepareToDraw();
    await rasterize(<DisplayCanvas>[], <ui.Picture>[], recorder);
  }
}

void testMain() {
  group('Rasterizer order', () {
    setUpUnitTests();

    test('calls prepareToDraw before rasterize', () async {
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

      expect(rasterizer.prepareToDrawCalled, isTrue, reason: 'prepareToDraw should be called');
      expect(rasterizer.rasterizeCalled, isTrue, reason: 'rasterize should be called');
      expect(
        rasterizer.prepareToDrawCalledDuringRasterize,
        isTrue,
        reason: 'prepareToDraw should have been called before rasterize',
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

      final rootLayer = RootLayer();
      final layerTree = LayerTree(rootLayer);

      // Frame 1: 100x200
      view.debugPhysicalSizeOverride = const ui.Size(100, 200);
      view.debugForceResize();
      await rasterizer.draw(layerTree, null);

      expect(rasterizer.sizeDuringPrepare, const BitmapSize(100, 200));
      expect(rasterizer.sizeDuringRasterize, const BitmapSize(100, 200));

      // Frame 2: 300x400
      view.debugPhysicalSizeOverride = const ui.Size(300, 400);
      view.debugForceResize();
      await rasterizer.draw(layerTree, null);

      expect(rasterizer.sizeDuringPrepare, const BitmapSize(300, 400));
      expect(rasterizer.sizeDuringRasterize, const BitmapSize(300, 400));
    });
  });
}
