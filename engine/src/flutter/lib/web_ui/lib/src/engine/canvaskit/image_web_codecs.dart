// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Uses the `ImageDecoder` class supplied by the browser.
//
// See also:
//
//  * `image_wasm_codecs.dart`, which uses codecs supplied by the CanvasKit WASM bundle.

import 'dart:async';
import 'dart:convert' show base64;
import 'dart:js_interop';
import 'dart:math' as math;
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
    required String debugSource,
  }) async {
    // ImageDecoder does not detect image type automatically. It requires us to
    // tell it what the image type is.
    final String? contentType = detectContentType(data);

    if (contentType == null) {
      final String fileHeader;
      if (data.isNotEmpty) {
        fileHeader = '[${bytesToHexString(data.sublist(0, math.min(10, data.length)))}]';
      } else {
        fileHeader = 'empty';
      }
      throw ImageCodecException(
        'Failed to detect image file format using the file header.\n'
        'File header was $fileHeader.\n'
        'Image source: $debugSource'
      );
    }

    final CkBrowserImageDecoder decoder = CkBrowserImageDecoder._(
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
    final SkImage? skImage = canvasKit.MakeLazyImageFromTextureSource(
      frame,
      SkPartialImageInfo(
        alphaType: canvasKit.AlphaType.Premul,
        colorType: canvasKit.ColorType.RGBA_8888,
        colorSpace: SkColorSpaceSRGB,
        width: frame.displayWidth,
        height: frame.displayHeight,
      ),
    );
    if (skImage == null) {
      throw ImageCodecException(
        "Failed to create image from pixel data decoded using the browser's ImageDecoder.",
      );
    }

    return CkImage(skImage, videoFrame: frame);
  }
}

Future<ByteData> readPixelsFromVideoFrame(VideoFrame videoFrame, ui.ImageByteFormat format) async {
  if (format == ui.ImageByteFormat.png) {
    final Uint8List png = await encodeVideoFrameAsPng(videoFrame);
    return png.buffer.asByteData();
  }

  final ByteBuffer pixels = await readVideoFramePixelsUnmodified(videoFrame);

  // Check if the pixels are already in the right format and if so, return the
  // original pixels without modification.
  if (_shouldReadPixelsUnmodified(videoFrame, format)) {
    return pixels.asByteData();
  }

  // At this point we know we want to read unencoded pixels, and that the video
  // frame is _not_ using the same format as the requested one.
  final bool isBgrFrame = videoFrame.format == 'BGRA' || videoFrame.format == 'BGRX';
  if (format == ui.ImageByteFormat.rawRgba && isBgrFrame) {
    _bgrToRgba(pixels);
    return pixels.asByteData();
  }

  // Last resort, just return the original pixels.
  return pixels.asByteData();
}

/// Mutates the [pixels], converting them from BGRX/BGRA to RGBA.
void _bgrToRgba(ByteBuffer pixels) {
  final int pixelCount = pixels.lengthInBytes ~/ 4;
  final Uint8List pixelBytes = pixels.asUint8List();
  for (int i = 0; i < pixelCount; i += 4) {
    // It seems even in little-endian machines the BGR_ pixels are encoded as
    // big-endian, i.e. the blue byte is written into the lowest byte in the
    // memory address space.
    final int b = pixelBytes[i];
    final int r = pixelBytes[i + 2];

    // So far the codec has reported 255 for the X component, so there's no
    // special treatment for alpha. This may need to change if we ever face
    // codecs that do something different.
    pixelBytes[i] = r;
    pixelBytes[i + 2] = b;
  }
}

bool _shouldReadPixelsUnmodified(VideoFrame videoFrame, ui.ImageByteFormat format) {
  if (format == ui.ImageByteFormat.rawUnmodified) {
    return true;
  }

  // Do not convert if the requested format is RGBA and the video frame is
  // encoded as either RGBA or RGBX.
  final bool isRgbFrame = videoFrame.format == 'RGBA' || videoFrame.format == 'RGBX';
  return format == ui.ImageByteFormat.rawRgba && isRgbFrame;
}

Future<ByteBuffer> readVideoFramePixelsUnmodified(VideoFrame videoFrame) async {
  final int size = videoFrame.allocationSize().toInt();

  // In dart2wasm, Uint8List is not the same as a JS Uint8Array. So we
  // explicitly construct the JS object here.
  final JSUint8Array destination = createUint8ArrayFromLength(size);
  final JsPromise copyPromise = videoFrame.copyTo(destination);
  await promiseToFuture<void>(copyPromise);

  // In dart2wasm, `toDart` incurs a copy here. On JS backends, this is a
  // no-op.
  return destination.toDart.buffer;
}

Future<Uint8List> encodeVideoFrameAsPng(VideoFrame videoFrame) async {
  final int width = videoFrame.displayWidth.toInt();
  final int height = videoFrame.displayHeight.toInt();
  final DomCanvasElement canvas = createDomCanvasElement(width: width, height:
      height);
  final DomCanvasRenderingContext2D ctx = canvas.context2D;
  ctx.drawImage(videoFrame, 0, 0);
  final String pngBase64 = canvas.toDataURL().substring('data:image/png;base64,'.length);
  return base64.decode(pngBase64);
}
