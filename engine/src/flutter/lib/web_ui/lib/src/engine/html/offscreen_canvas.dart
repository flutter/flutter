// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'package:ui/src/engine.dart';

/// Polyfill for html.OffscreenCanvas that is not supported on some browsers.
class OffScreenCanvas {
  html.OffscreenCanvas? offScreenCanvas;
  html.CanvasElement? canvasElement;
  int width;
  int height;
  static bool? _supported;

  OffScreenCanvas(this.width, this.height) {
    if (OffScreenCanvas.supported) {
      offScreenCanvas = html.OffscreenCanvas(width, height);
    } else {
      canvasElement = html.CanvasElement(
        width: width,
        height: height,
      );
      canvasElement!.className = 'gl-canvas';
      final double cssWidth = width / EnginePlatformDispatcher.browserDevicePixelRatio;
      final double cssHeight = height / EnginePlatformDispatcher.browserDevicePixelRatio;
      canvasElement!.style
        ..position = 'absolute'
        ..width = '${cssWidth}px'
        ..height = '${cssHeight}px';
    }
  }

  void dispose() {
    offScreenCanvas = null;
    canvasElement = null;
  }

  /// Returns CanvasRenderContext2D or OffscreenCanvasRenderingContext2D to
  /// paint into.
  Object? getContext2d() {
    return (offScreenCanvas != null
        ? offScreenCanvas!.getContext('2d')
        : canvasElement!.getContext('2d'));
  }

  /// Feature detection for transferToImageBitmap on OffscreenCanvas.
  bool get transferToImageBitmapSupported =>
      js_util.hasProperty(offScreenCanvas!, 'transferToImageBitmap');

  /// Creates an ImageBitmap object from the most recently rendered image
  /// of the OffscreenCanvas.
  ///
  /// !Warning API still in experimental status, feature detect before using.
  Object? transferToImageBitmap() {
    return js_util.callMethod(offScreenCanvas!, 'transferToImageBitmap',
        <dynamic>[]);
  }

  /// Draws canvas contents to a rendering context.
  void transferImage(Object targetContext) {
    // Actual size of canvas may be larger than viewport size. Use
    // source/destination to draw part of the image data.
    js_util.callMethod(targetContext, 'drawImage',
        <dynamic>[offScreenCanvas ?? canvasElement!, 0, 0, width, height,
          0, 0, width, height]);
  }

  /// Converts canvas contents to an image and returns as data url.
  Future<String> toDataUrl() {
    final Completer<String> completer = Completer<String>();
    if (offScreenCanvas != null) {
      offScreenCanvas!.convertToBlob().then((html.Blob value) {
        final fileReader = html.FileReader();
        fileReader.onLoad.listen((event) {
          completer.complete(js_util.getProperty(
              js_util.getProperty(event, 'target')!, 'result')!);
        });
        fileReader.readAsDataUrl(value);
      });
      return completer.future;
    } else {
      return Future.value(canvasElement!.toDataUrl());
    }
  }

  /// Draws an image to canvas for both offscreen canvas canvas context2d.
  void drawImage(Object image, int x, int y, int width, int height) {
    js_util.callMethod(
        getContext2d()!, 'drawImage', <dynamic>[image, x, y, width, height]);
  }

  /// Feature detects OffscreenCanvas.
  static bool get supported => _supported ??=
      js_util.hasProperty(html.window, 'OffscreenCanvas');
}
