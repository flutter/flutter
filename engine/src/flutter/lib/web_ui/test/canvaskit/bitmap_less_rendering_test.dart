// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('Bitmap-less rendering', () {
    setUpCanvasKitTest(withImplicitView: true);

    setUpAll(() {
      debugDisableCreateImageBitmapSupport = true;
    });

    tearDownAll(() {
      debugDisableCreateImageBitmapSupport = false;
    });

    test(
      'throws when createImageBitmap is not supported but rasterizeToImageBitmaps is called',
      () async {
        final CkOffscreenSurface surface = CkOffscreenSurface(OffscreenCanvasProvider());
        final List<ui.Picture> pictures = <ui.Picture>[];
        pictures.add(_createPicture());

        expect(() => surface.rasterizeToImageBitmaps(pictures), throwsUnsupportedError);
      },
    );

    test('does not throw when rasterizing with a Rasterizer', () async {
      final ui.SceneBuilder builder = ui.SceneBuilder();
      builder.addPicture(ui.Offset.zero, _createPicture());
      final ui.Scene scene = builder.build();
      final LayerTree layerTree = (scene as LayerScene).layerTree;

      final OffscreenCanvasRasterizer rasterizer = OffscreenCanvasRasterizer(
        (OffscreenCanvasProvider canvasProvider) => CkOffscreenSurface(canvasProvider),
      );

      final OffscreenCanvasViewRasterizer viewRasterizer = rasterizer.createViewRasterizer(
        EnginePlatformDispatcher.instance.implicitView!,
      );
      await viewRasterizer.draw(layerTree, null);
    });
  });
}

ui.Picture _createPicture() {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);
  canvas.drawRect(const ui.Rect.fromLTRB(0, 0, 10, 10), ui.Paint());
  return recorder.endRecording();
}
