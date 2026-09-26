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

void testMain() {
  setUpUnitTests(withImplicitView: true);

  test('Picture computes bounds during preroll', () {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(const ui.Rect.fromLTWH(200, 200, 10, 10), ui.Paint());
    final ui.Picture picture = recorder.endRecording();

    final pictureLayer = PictureLayer(picture as LayerPicture, ui.Offset.zero, false, false);
    final rootLayer = RootLayer()..children.add(pictureLayer);

    final prerollVisitor = PrerollVisitor();
    rootLayer.accept(prerollVisitor);

    expect(pictureLayer.paintBounds, const ui.Rect.fromLTWH(200, 200, 10, 10));
    expect(pictureLayer.isCulled, isFalse);
  });

  test('Picture inside clip computes bounds during preroll', () {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 10, 10), ui.Paint());
    final ui.Picture picture = recorder.endRecording();

    final pictureLayer = PictureLayer(picture as LayerPicture, const ui.Offset(5, 5), false, false);

    final clipRectLayer = ClipRectEngineLayer(
      const ui.Rect.fromLTWH(0, 0, 20, 20),
      ui.Clip.hardEdge,
    )..children.add(pictureLayer);

    final rootLayer = RootLayer()..children.add(clipRectLayer);

    final prerollVisitor = PrerollVisitor();
    rootLayer.accept(prerollVisitor);

    expect(pictureLayer.paintBounds, const ui.Rect.fromLTWH(5, 5, 10, 10));
    expect(clipRectLayer.paintBounds, const ui.Rect.fromLTWH(5, 5, 10, 10));
  });

  test('Disposed picture is culled and does not throw during preroll and debug info', () {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 10, 10), ui.Paint());
    final ui.Picture picture = recorder.endRecording();
    picture.dispose();

    final pictureLayer = PictureLayer(
      picture as LayerPicture,
      const ui.Offset(10, 10),
      false,
      false,
    );
    final rootLayer = RootLayer()..children.add(pictureLayer);

    final prerollVisitor = PrerollVisitor();
    expect(() => rootLayer.accept(prerollVisitor), returnsNormally);
    expect(pictureLayer.paintBounds, ui.Rect.zero);
    expect(pictureLayer.isCulled, isTrue);

    final debugInfoVisitor = DebugInfoVisitor();
    late Map<String, dynamic> debugInfo;
    expect(() => debugInfo = rootLayer.accept(debugInfoVisitor), returnsNormally);
    expect(debugInfo['children'], hasLength(1));
    final pictureDebugInfo = (debugInfo['children'] as List<dynamic>).first as Map<String, dynamic>;
    expect(pictureDebugInfo['type'], 'picture');
    expect(pictureDebugInfo['localBounds'], <String, dynamic>{
      'left': 0.0,
      'top': 0.0,
      'right': 0.0,
      'bottom': 0.0,
    });
  });

  test('LayerTree handles disposed pictures gracefully across all phases', () {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 10, 10), ui.Paint());
    final ui.Picture picture = recorder.endRecording();
    picture.dispose();

    final pictureLayer = PictureLayer(picture as LayerPicture, const ui.Offset(5, 5), false, false);
    final rootLayer = RootLayer()..children.add(pictureLayer);

    final layerTree = LayerTree(rootLayer);
    final frame = Frame();

    expect(() => layerTree.preroll(frame), returnsNormally);
    expect(() => layerTree.measure(frame, const BitmapSize(100, 100)), returnsNormally);
    expect(() => layerTree.dumpDebugInfo(), returnsNormally);
    expect(() => layerTree.flatten(const ui.Size(100, 100)), returnsNormally);
  });
}
