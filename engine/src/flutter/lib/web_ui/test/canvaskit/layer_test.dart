// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'common.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('CanvasKit', () {
    setUpCanvasKitTest();

    // Regression test for https://github.com/flutter/flutter/issues/63715
    test('TransformLayer prerolls correctly', () async {
      final EnginePlatformDispatcher dispatcher =
          ui.window.platformDispatcher as EnginePlatformDispatcher;

      final CkPicture picture =
          paintPicture(const ui.Rect.fromLTRB(0, 0, 60, 60), (CkCanvas canvas) {
        canvas.drawRect(const ui.Rect.fromLTRB(0, 0, 60, 60),
            CkPaint()..style = ui.PaintingStyle.fill);
      });

      final LayerSceneBuilder sb = LayerSceneBuilder();
      sb.pushClipRect(const ui.Rect.fromLTRB(15, 15, 30, 30));

      // Intentionally use a perspective transform, which triggered the
      // https://github.com/flutter/flutter/issues/63715 bug.
      sb.pushTransform(
          Float64List.fromList(Matrix4.identity().storage
            ..[15] = 2,
      ));

      sb.addPicture(ui.Offset.zero, picture);
      final LayerTree layerTree = sb.build().layerTree;
      dispatcher.rasterizer!.draw(layerTree);
      final ClipRectEngineLayer clipRect = layerTree.rootLayer.debugLayers.single as ClipRectEngineLayer;
      expect(clipRect.paintBounds, const ui.Rect.fromLTRB(15, 15, 30, 30));

      final TransformEngineLayer transform = clipRect.debugLayers.single as TransformEngineLayer;
      expect(transform.paintBounds, const ui.Rect.fromLTRB(0, 0, 30, 30));
    });

    test('can push a leaf layer without a container layer', () async {
      final CkPictureRecorder recorder = CkPictureRecorder();
      recorder.beginRecording(ui.Rect.zero);
      LayerSceneBuilder().addPicture(ui.Offset.zero, recorder.endRecording());
    });

    // TODO(hterkelsen): https://github.com/flutter/flutter/issues/60040
  }, skip: isIosSafari);
}
