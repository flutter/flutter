// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:js_interop';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import '../../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('RenderCanvas', () {
    setUpUnitTests(withImplicitView: true);
    setUp(() async {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);
    });

    Future<DomImageBitmap> newBitmap(int width, int height) async {
      return createImageBitmap(createBlankDomImageData(width, height) as JSAny, (
        x: 0,
        y: 0,
        width: width,
        height: height,
      ));
    }

    // Regression test for https://github.com/flutter/flutter/issues/75286
    test('updates canvas logical size when device-pixel ratio changes', () async {
      final RenderCanvas canvas = RenderCanvas();
      canvas.render(await newBitmap(10, 16));

      expect(canvas.canvasElement.width, 10);
      expect(canvas.canvasElement.height, 16);
      expect(canvas.canvasElement.style.width, '10px');
      expect(canvas.canvasElement.style.height, '16px');

      // Increase device-pixel ratio: this makes CSS pixels bigger, so we need
      // fewer of them to cover the browser window.
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(2.0);
      canvas.render(await newBitmap(10, 16));
      expect(canvas.canvasElement.width, 10);
      expect(canvas.canvasElement.height, 16);
      expect(canvas.canvasElement.style.width, '5px');
      expect(canvas.canvasElement.style.height, '8px');

      // Decrease device-pixel ratio: this makes CSS pixels smaller, so we need
      // more of them to cover the browser window.
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(0.5);
      canvas.render(await newBitmap(10, 16));
      expect(canvas.canvasElement.width, 10);
      expect(canvas.canvasElement.height, 16);
      expect(canvas.canvasElement.style.width, '20px');
      expect(canvas.canvasElement.style.height, '32px');
    });

    test('rounds physical size to nearest integer size', () async {
      final EngineFlutterWindow implicitView = EnginePlatformDispatcher.instance.implicitView!;
      implicitView.debugPhysicalSizeOverride = const ui.Size(199.999999, 200.000001);

      final ui.SceneBuilder sceneBuilder = ui.SceneBuilder();
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final ui.Canvas canvas = ui.Canvas(recorder, ui.Rect.largest);
      canvas.drawPaint(ui.Paint()..color = const ui.Color(0xff00ff00));
      final ui.Picture picture = recorder.endRecording();
      sceneBuilder.addPicture(ui.Offset.zero, picture);
      final ui.Scene scene = sceneBuilder.build();

      await renderer.renderScene(scene, implicitView);

      expect(
        renderer.rasterizers[implicitView.viewId]!.currentFrameSize,
        const BitmapSize(200, 200),
      );

      implicitView.debugPhysicalSizeOverride = null;
      implicitView.debugForceResize();
    });

    // Regression test for https://github.com/flutter/flutter/issues/176174
    test('renderWithNoBitmapSupport clears canvas before drawing', () {
      final RenderCanvas renderCanvas = RenderCanvas();
      final DomHTMLCanvasElement canvas = renderCanvas.canvasElement;
      final DomCanvasRenderingContext2D context = canvas.context2D;
      canvas.width = 100;
      canvas.height = 100;

      // Render the first blue image
      final DomHTMLCanvasElement firstImage = createDomCanvasElement(
        width: 100,
        height: 100,
      );
      final DomCanvasRenderingContext2D firstContext = firstImage.context2D;
      firstContext.fillStyle = 'rgb(0, 0, 255)'.toJS;
      firstContext.fillRect(0, 0, 100, 100);
      renderCanvas.renderWithNoBitmapSupport(
        firstImage as DomCanvasImageSource,
        100,
        const BitmapSize(100, 100),
      );

      // Verify the center pixel is blue after first render
      final DomImageData blueData = context.getImageData(50, 50, 1, 1);
      final bluePixels = blueData.data;
      expect(bluePixels[0], equals(0));
      expect(bluePixels[1], equals(0));
      expect(bluePixels[2], equals(255));

      // Second render, only draw a red square in top-left
      final DomHTMLCanvasElement secondImage = createDomCanvasElement(
        width: 100,
        height: 100,
      );
      final DomCanvasRenderingContext2D secondContext = secondImage.context2D;
      secondContext.fillStyle = 'rgb(255, 0, 0)'.toJS;
      secondContext.fillRect(0, 0, 30, 30);
      renderCanvas.renderWithNoBitmapSupport(
        secondImage as DomCanvasImageSource,
        100,
        const BitmapSize(100, 100),
      );

      // Check center point (50, 50) - should be transparent in second image
      final DomImageData centerData = context.getImageData(50, 50, 1, 1);
      final centerPixels = centerData.data;

      // Without clearRect: would still be blue (0, 0, 255, 255) from first render
      // With clearRect: should be transparent/black (0, 0, 0, 0)
      expect(centerPixels[0], equals(0));
      expect(centerPixels[1], equals(0));
      expect(centerPixels[2], equals(0));
      expect(centerPixels[3], equals(0));

      // Check top-left corner (15, 15) - should be red from second image
      final DomImageData cornerData = context.getImageData(15, 15, 1, 1);
      final cornerPixels = cornerData.data;
      expect(cornerPixels[0], equals(255));
      expect(cornerPixels[1], equals(0));
      expect(cornerPixels[2], equals(0));
    });
  });
}
