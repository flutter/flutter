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
  group('MultiView Sizing', () {
    setUpUnitTests(withImplicitView: true);

    test('canvases for multiple views have correct sizes', () async {
      // Create two views with different sizes.
      final DomElement host1 = createDomElement('view-1');
      host1.style
        ..width = '100px'
        ..height = '100px'
        ..display = 'block';
      domDocument.body!.append(host1);
      final view1 = EngineFlutterView(EnginePlatformDispatcher.instance, host1);
      EnginePlatformDispatcher.instance.viewManager.registerView(view1);

      final DomElement host2 = createDomElement('view-2');
      host2.style
        ..width = '200px'
        ..height = '200px'
        ..display = 'block';
      domDocument.body!.append(host2);
      final view2 = EngineFlutterView(EnginePlatformDispatcher.instance, host2);
      EnginePlatformDispatcher.instance.viewManager.registerView(view2);

      // Create a simple scene.
      ui.Scene createScene(ui.Color color, ui.Size size) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder, ui.Offset.zero & size);
        canvas.drawRect(ui.Offset.zero & size, ui.Paint()..color = color);
        final ui.Picture picture = recorder.endRecording();
        final sb = ui.SceneBuilder();
        sb.addPicture(ui.Offset.zero, picture);
        return sb.build();
      }

      final ui.Scene scene1 = createScene(const ui.Color(0xFFFF0000), const ui.Size(100, 100));
      final ui.Scene scene2 = createScene(const ui.Color(0xFF00FF00), const ui.Size(200, 200));

      // Render both scenes.
      // We render them in the same turn to increase chance of interference if there's no locking.
      final Future<void> r1 = renderer.renderScene(scene1, view1);
      final Future<void> r2 = renderer.renderScene(scene2, view2);
      await Future.wait(<Future<void>>[r1, r2]);

      // Verify canvas sizes.
      DomHTMLCanvasElement getCanvas(EngineFlutterView view) {
        final DomElement? canvas = view.dom.renderingHost.querySelector('canvas');
        if (canvas == null) {
          throw Exception('Canvas not found for view ${view.viewId}');
        }
        return canvas as DomHTMLCanvasElement;
      }

      final DomHTMLCanvasElement canvas1 = getCanvas(view1);
      final DomHTMLCanvasElement canvas2 = getCanvas(view2);

      final double dpr = EngineFlutterDisplay.instance.devicePixelRatio;
      expect(canvas1.width, 100 * dpr);
      expect(canvas1.height, 100 * dpr);
      expect(canvas2.width, 200 * dpr);
      expect(canvas2.height, 200 * dpr);

      host1.remove();
      host2.remove();
    });
  });
}
