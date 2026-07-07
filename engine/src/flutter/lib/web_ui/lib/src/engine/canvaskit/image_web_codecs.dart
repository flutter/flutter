// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Uses the `ImageDecoder` class supplied by the browser.
//
// See also:
//
//  * `image_wasm_codecs.dart`, which uses codecs supplied by the CanvasKit WASM bundle.

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// Image decoder backed by the browser's `ImageDecoder`.
class CkBrowserImageDecoder extends BrowserImageDecoder {
  CkBrowserImageDecoder._({
    required super.contentType,
    required super.dataSource,
    required super.debugSource,
  });

  static Future<CkBrowserImageDecoder> create({
    required Uint8List data,
    required String contentType,
    required String debugSource,
  }) async {
    final decoder = CkBrowserImageDecoder._(
      contentType: contentType,
      dataSource: data.toJS,
      debugSource: debugSource,
    );

    // Call once to initialize the decoder and populate late fields.
    await decoder.initialize();
    return decoder;
  }

  @override
  ui.Image generateImageFromVideoFrame(VideoFrame frame) {
    SkImage? skImage;
    if (CanvasKitRenderer.instance.isSoftware) {
      final int width = frame.displayWidth.toInt();
      final int height = frame.displayHeight.toInt();
      final DomHTMLCanvasElement canvas = createDomCanvasElement(width: width, height: height);
      final DomCanvasRenderingContext2D ctx = canvas.context2D;
      ctx.drawImage(frame, 0, 0);
      skImage = canvasKit.MakeImageFromCanvasImageSource(canvas);
    } else {
      skImage = canvasKit.MakeLazyImageFromTextureSourceWithInfo(
        frame,
        SkPartialImageInfo(
          alphaType: canvasKit.AlphaType.Premul,
          colorType: canvasKit.ColorType.RGBA_8888,
          colorSpace: SkColorSpaceSRGB,
          width: frame.displayWidth,
          height: frame.displayHeight,
        ),
      );
    }
    if (skImage == null) {
      throw ImageCodecException(
        "Failed to create image from pixel data decoded using the browser's ImageDecoder.",
      );
    }

    return EngineImage(
      CkImageDelegate(skImage),
      skImage.width().toInt(),
      skImage.height().toInt(),
      imageSource: VideoFrameImageSource(frame),
    );
  }
}
