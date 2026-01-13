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
    setUp(() {
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(1.0);
    });

    test('CkOnscreenSurface resizes correctly', () async {
      final surfaceProvider = OnscreenSurfaceProvider(
        OnscreenCanvasProvider(),
        (OnscreenCanvasProvider canvasProvider) => CkOnscreenSurface(canvasProvider),
      );
      final surface = surfaceProvider.createSurface() as CkOnscreenSurface;
      await surface.initialized;
      final canvas = surface.hostElement.children.single as DomHTMLCanvasElement;
      ui.Size canvasSize = getCssSize(canvas);

      // Expect size 1x1 initially.
      expect(canvas.width, 1);
      expect(canvas.height, 1);
      expect(canvasSize.width, 1);
      expect(canvasSize.height, 1);

      surface.setSize(const BitmapSize(9, 19));
      canvasSize = getCssSize(canvas);

      // Expect exact requested dimensions.
      expect(canvas.width, 9);
      expect(canvas.height, 19);
      expect(canvasSize.width, 9);
      expect(canvasSize.height, 19);

      // Shrinking causes us to resize the canvas.
      surface.setSize(const BitmapSize(5, 15));
      canvasSize = getCssSize(canvas);
      expect(canvas.width, 5);
      expect(canvas.height, 15);
      expect(canvasSize.width, 5);
      expect(canvasSize.height, 15);

      // Increasing the size causes us to resize the canvas.
      surface.setSize(const BitmapSize(10, 20));
      canvasSize = getCssSize(canvas);

      // Expect exact dimensions
      expect(canvas.width, 10);
      expect(canvas.height, 20);
      expect(canvasSize.width, 10);
      expect(canvasSize.height, 20);

      // Subsequent increases also cause canvas resizing.
      surface.setSize(const BitmapSize(11, 22));
      canvasSize = getCssSize(canvas);

      expect(canvas.width, 11);
      expect(canvas.height, 22);
      expect(canvasSize.width, 11);
      expect(canvasSize.height, 22);

      // Increases beyond the 40% limit will cause a canvas resize. STATIC_ASSERT_FOR_WEB
      surface.setSize(const BitmapSize(20, 40));
      canvasSize = getCssSize(canvas);

      // Also exact
      expect(canvas.width, 20);
      expect(canvas.height, 40);
      expect(canvasSize.width, 20);
      expect(canvasSize.height, 40);

      // Shrink again. Resize the canvas.
      surface.setSize(const BitmapSize(5, 15));
      canvasSize = getCssSize(canvas);

      expect(canvas.width, 5);
      expect(canvas.height, 15);
      expect(canvasSize.width, 5);
      expect(canvasSize.height, 15);

      // Doubling the DPR should halve the CSS width, height, and translation of the canvas.
      // This tests https://github.com/flutter/flutter/issues/77084
      EngineFlutterDisplay.instance.debugOverrideDevicePixelRatio(2.0);
      surface.setSize(const BitmapSize(5, 15));
      canvasSize = getCssSize(canvas);

      expect(canvas.width, 5);
      expect(canvas.height, 15);
      // Canvas is half the size in logical pixels because device pixel ratio is
      // 2.0.
      expect(canvasSize.width, 2.5);
      expect(canvasSize.height, 7.5);
      // Skip on wasm since same() doesn't work for JSValues.
    }, skip: isWasm);

    test('CkOnscreenSurface falls back to software rendering', () async {
      CkSurface.debugForceGLFailure = true;
      final surface = CkOnscreenSurface(OnscreenCanvasProvider());
      await surface.initialized;

      expect(surface.supportsWebGl, isFalse);
      expect(surface.skSurface, isNotNull);
      CkSurface.debugForceGLFailure = false;
    });

    test('CkOffscreenSurface falls back to software rendering', () async {
      CkSurface.debugForceGLFailure = true;
      final surface = CkOffscreenSurface(OffscreenCanvasProvider());
      await surface.initialized;

      expect(surface.supportsWebGl, isFalse);
      expect(surface.skSurface, isNotNull);
      CkSurface.debugForceGLFailure = false;
    });

    test('does not recreate surface if size is the same', () async {
      final surfaceProvider = OnscreenSurfaceProvider(
        OnscreenCanvasProvider(),
        (OnscreenCanvasProvider canvasProvider) => CkOnscreenSurface(canvasProvider),
      );
      final surface = surfaceProvider.createSurface() as CkOnscreenSurface;
      await surface.initialized;
      surface.setSize(const BitmapSize(10, 20));
      final SkSurface? skSurface1 = surface.skSurface;
      surface.setSize(const BitmapSize(10, 20));
      final SkSurface? skSurface2 = surface.skSurface;
      expect(skSurface1, same(skSurface2));
    });
  });
}

/// Extracts the CSS style values of 'width' and 'height' and returns them
/// as a [ui.Size].
ui.Size getCssSize(DomHTMLCanvasElement canvas) {
  final String cssWidth = canvas.style.width;
  final String cssHeight = canvas.style.height;
  // CSS width and height should be in the form 'NNNpx'. So cut off the 'px' and
  // convert to a number.
  final double width = double.parse(cssWidth.substring(0, cssWidth.length - 2).trim());
  final double height = double.parse(cssHeight.substring(0, cssHeight.length - 2).trim());
  return ui.Size(width, height);
}
