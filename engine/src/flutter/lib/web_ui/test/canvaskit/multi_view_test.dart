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
  group('CanvasKit', () {
    setUpCanvasKitTest();

    test('can render into arbitrary views', () async {
      final CkPicture picture =
          paintPicture(const ui.Rect.fromLTRB(0, 0, 60, 60), (CkCanvas canvas) {
        canvas.drawRect(const ui.Rect.fromLTRB(0, 0, 60, 60),
            CkPaint()..style = ui.PaintingStyle.fill);
      });

      final LayerSceneBuilder sb = LayerSceneBuilder();

      sb.addPicture(ui.Offset.zero, picture);
      final LayerScene scene = sb.build();
      CanvasKitRenderer.instance.renderScene(scene, implicitView);

      final EngineFlutterView anotherView = EngineFlutterView(
          EnginePlatformDispatcher.instance, createDomElement('another-view'));
      CanvasKitRenderer.instance.renderScene(scene, anotherView);
    });
  });
}
