// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show base64;
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// An abstract wrapper representing a transferable source of pixels.
///
/// Implementations wrap concrete web/browser APIs, such as an HTML `img` element,
/// an `ImageBitmap`, or a `VideoFrame`. It handles reference counting to ensure
/// that resource disposal occurs exactly when all consumers have released it.
sealed class ImageSource {
  /// The underlying canvas-compatible image source.
  DomCanvasImageSource get canvasImageSource;

  /// The width of the image source in pixels.
  int get width;

  /// The height of the image source in pixels.
  int get height;

  /// The current reference count of this image source.
  ///
  /// This field is read-only. Use [retain] to increment the count and [release]
  /// to decrement it.
  int get refCount => _refCount;
  int _refCount = 0;

  /// Indicates whether the resource has been closed/released.
  ///
  /// This is only used for debugging and unit testing.
  @visibleForTesting
  bool debugIsClosed = false;

  /// Increments the reference count of this image source.
  void retain() {
    _refCount++;
  }

  /// Decrements the reference count of this image source.
  ///
  /// When the reference count drops to 0, the underlying browser resource is
  /// closed and freed.
  void release() {
    assert(_refCount > 0, 'Cannot release an image source that has not been retained.');
    if (_refCount <= 0) {
      return;
    }
    _refCount--;
    // Close the image if [refCount] fell to 0.
    close();
  }

  /// Closes the image source manually if the current [refCount] is 0.
  ///
  /// This is used primarily in test environments. Calling [close] is a no-op
  /// if [refCount] is greater than 0.
  void close() {
    if (_refCount == 0) {
      _doClose();
      debugIsClosed = true;
    }
  }

  /// Abstract hook overridden by subclasses to release the specific native resource.
  void _doClose();
}

/// An [ImageSource] implementation wrapping a WebCodecs [VideoFrame].
class VideoFrameImageSource extends ImageSource {
  /// Creates a [VideoFrameImageSource] wrapping the given [videoFrame].
  VideoFrameImageSource(this.videoFrame);

  /// The wrapped WebCodecs [VideoFrame] object.
  final VideoFrame videoFrame;

  @override
  void _doClose() {
    // Do nothing. Skia will close the VideoFrame when the SkImage is disposed.
  }

  @override
  int get height => videoFrame.displayHeight.toInt();

  @override
  int get width => videoFrame.displayWidth.toInt();

  @override
  DomCanvasImageSource get canvasImageSource => videoFrame;
}

/// An [ImageSource] implementation wrapping an HTML `<img>` element.
class ImageElementImageSource extends ImageSource {
  /// Creates an [ImageElementImageSource] wrapping the given [imageElement].
  ImageElementImageSource(this.imageElement);

  /// The wrapped HTML `<img>` element.
  final DomHTMLImageElement imageElement;

  @override
  void _doClose() {
    // Clear the src attribute of the image element to release associated memory.
    imageElement.src = '';
  }

  @override
  int get height => imageElement.naturalHeight.toInt();

  @override
  int get width => imageElement.naturalWidth.toInt();

  @override
  DomCanvasImageSource get canvasImageSource => imageElement;
}

/// An [ImageSource] implementation wrapping an HTML5 [DomImageBitmap].
class ImageBitmapImageSource extends ImageSource {
  /// Creates an [ImageBitmapImageSource] wrapping the given [imageBitmap].
  ImageBitmapImageSource(this.imageBitmap);

  /// The wrapped [DomImageBitmap] object.
  final DomImageBitmap imageBitmap;

  @override
  void _doClose() {
    // Eagerly close the image bitmap to free GPU/browser resources.
    imageBitmap.close();
  }

  @override
  int get height => imageBitmap.height;

  @override
  int get width => imageBitmap.width;

  @override
  DomCanvasImageSource get canvasImageSource => imageBitmap;
}

/// Reads and decodes pixel data from a [VideoFrame], converting to the requested [format].
Future<ByteData> readPixelsFromVideoFrame(VideoFrame videoFrame, ui.ImageByteFormat format) async {
  // If PNG format is requested, encode the video frame as a PNG.
  if (format == ui.ImageByteFormat.png) {
    final Uint8List png = await encodeDomImageSourceAsPng(
      videoFrame,
      videoFrame.displayWidth.toInt(),
      videoFrame.displayHeight.toInt(),
    );
    return png.buffer.asByteData();
  }

  // Retrieve the raw video frame bytes unmodified from the browser.
  final ByteBuffer pixels = await readVideoFramePixelsUnmodified(videoFrame);

  // Check if the pixels are already in the right format and if so, return them directly.
  if (_shouldReadPixelsUnmodified(videoFrame, format)) {
    return pixels.asByteData();
  }

  // Convert BGR formats (BGRA/BGRX) to RGBA.
  final isBgrx = videoFrame.format == 'BGRX';
  final bool isBgrFrame = videoFrame.format == 'BGRA' || isBgrx;
  if (isBgrFrame) {
    // Perform standard straight or raw RGBA conversion.
    if (format == ui.ImageByteFormat.rawStraightRgba || isBgrx) {
      _bgrToStraightRgba(pixels, isBgrx);
      return pixels.asByteData();
    } else if (format == ui.ImageByteFormat.rawRgba) {
      _bgrToRawRgba(pixels);
      return pixels.asByteData();
    }
  }

  // Last resort: return the pixels unmodified.
  return pixels.asByteData();
}

/// Reads pixel data from a general canvas-compatible DOM image source.
Future<ByteData> readPixelsFromDomImageSource(
  DomCanvasImageSource imageSource,
  ui.ImageByteFormat format,
  int width,
  int height,
) async {
  // If PNG format is requested, convert the source to a PNG.
  if (format == ui.ImageByteFormat.png) {
    final Uint8List png = await encodeDomImageSourceAsPng(imageSource, width, height);
    return png.buffer.asByteData();
  }

  // Retrieve the raw unmodified pixels using a 2D canvas readback.
  final ByteBuffer pixels = readDomImageSourcePixelsUnmodified(imageSource, width, height);
  return pixels.asByteData();
}

/// Mutates the [pixels], converting them from BGRX/BGRA to RGBA.
void _bgrToStraightRgba(ByteBuffer pixels, bool isBgrx) {
  final Uint8List pixelBytes = pixels.asUint8List();
  for (var i = 0; i < pixelBytes.length; i += 4) {
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
    if (isBgrx) {
      pixelBytes[i + 3] = 255;
    }
  }
}

/// Based on Chromium's SetRGBAPremultiply.
@pragma('dart2js:tryInline')
int _premultiply(int value, int alpha) {
  if (alpha == 255) {
    return value;
  }
  const int kRoundFractionControl = 257 * 128;
  return (value * alpha * 257 + kRoundFractionControl) >> 16;
}

/// Mutates the [pixels], converting them from BGRX/BGRA to RGBA with
/// premultiplied alpha.
void _bgrToRawRgba(ByteBuffer pixels) {
  // Swaps the Red and Blue channels to convert the layout from BGRA to RGBA,
  // while simultaneously premultiplying the color channels by the alpha channel
  // (as required by the rawRgba image byte format).
  final Uint8List pixelBytes = pixels.asUint8List();
  for (var i = 0; i < pixelBytes.length; i += 4) {
    final int a = pixelBytes[i + 3];
    final int r = _premultiply(pixelBytes[i + 2], a);
    final int g = _premultiply(pixelBytes[i + 1], a);
    final int b = _premultiply(pixelBytes[i], a);

    pixelBytes[i] = r;
    pixelBytes[i + 1] = g;
    pixelBytes[i + 2] = b;
  }
}

/// Mutates the [pixels] in-place, converting them from premultiplied alpha
/// RGBA layout to straight/unpremultiplied RGBA layout.
void unpremultiplyRawRgba(Uint8List pixels) {
  assert(pixels.length % 4 == 0, 'Pixel buffer length must be a multiple of 4.');
  for (var i = 0; i < pixels.length; i += 4) {
    final int a = pixels[i + 3];
    if (a == 0) {
      pixels[i] = 0;
      pixels[i + 1] = 0;
      pixels[i + 2] = 0;
    } else if (a < 255) {
      // Divide the color channel by the alpha value to unpremultiply it.
      // Adding 'a ~/ 2' (half the divisor) before dividing by 'a' performs
      // correct integer rounding to the nearest integer instead of truncating,
      // which prevents color-channel drift and banding.
      pixels[i] = ((pixels[i] * 255 + a ~/ 2) ~/ a).clamp(0, 255);
      pixels[i + 1] = ((pixels[i + 1] * 255 + a ~/ 2) ~/ a).clamp(0, 255);
      pixels[i + 2] = ((pixels[i + 2] * 255 + a ~/ 2) ~/ a).clamp(0, 255);
    }
  }
}

/// Determines if the pixels of a video frame can be read without conversion.
bool _shouldReadPixelsUnmodified(VideoFrame videoFrame, ui.ImageByteFormat format) {
  if (format == ui.ImageByteFormat.rawUnmodified) {
    return true;
  }

  // Do not convert if the requested format is RGBA and the video frame is
  // encoded as either RGBA or RGBX.
  final bool isRgbFrame = videoFrame.format == 'RGBA' || videoFrame.format == 'RGBX';
  return format == ui.ImageByteFormat.rawStraightRgba && isRgbFrame;
}

/// Asynchronously extracts the unmodified pixel buffer of a WebCodecs [VideoFrame].
Future<ByteBuffer> readVideoFramePixelsUnmodified(VideoFrame videoFrame) async {
  final int size = videoFrame.allocationSize().toInt();

  // In dart2wasm, Uint8List is not the same as a JS Uint8Array. So we
  // explicitly construct the JS object here.
  final destination = JSUint8Array.withLength(size);
  final JSPromise<JSAny?> copyPromise = videoFrame.copyTo(destination);
  await copyPromise.toDart;

  // In dart2wasm, `toDart` incurs a copy here. On JS backends, this is a
  // no-op.
  return destination.toDart.buffer;
}

/// Synchronously extracts raw pixels from any DOM canvas-compatible image source.
ByteBuffer readDomImageSourcePixelsUnmodified(
  DomCanvasImageSource imageSource,
  int width,
  int height,
) {
  // Create an offscreen canvas element to render the image source.
  final DomHTMLCanvasElement htmlCanvas = createDomCanvasElement(width: width, height: height);
  final ctx = htmlCanvas.getContext('2d')! as DomCanvasRenderingContext2D;
  ctx.drawImage(imageSource, 0, 0);

  // Retrieve the rendered pixel data.
  final DomImageData imageData = ctx.getImageData(0, 0, width, height);

  // Resize the canvas to 0x0 to cause the browser to reclaim its memory
  // eagerly.
  htmlCanvas.width = 0;
  htmlCanvas.height = 0;
  return imageData.data.buffer;
}

/// Asynchronously encodes a DOM canvas-compatible image source into a PNG byte stream.
Future<Uint8List> encodeDomImageSourceAsPng(
  DomCanvasImageSource imageSource,
  int width,
  int height,
) async {
  // Setup a canvas element for rendering.
  final DomHTMLCanvasElement canvas = createDomCanvasElement(width: width, height: height);
  final DomCanvasRenderingContext2D ctx = canvas.context2D;
  ctx.drawImage(imageSource, 0, 0);

  // Extract base64-encoded PNG data URL.
  final String pngBase64 = canvas.toDataURL().substring('data:image/png;base64,'.length);

  // Resize the canvas to 0x0 to cause the browser to reclaim its memory
  // eagerly.
  canvas.width = 0;
  canvas.height = 0;
  return base64.decode(pngBase64);
}

/// An [ImageSource] implementation wrapping a generic [DomCanvasImageSource]
/// (such as an HTMLCanvasElement, OffscreenCanvas, SVGImageElement, or HTMLVideoElement)
/// that does not require manual resource cleanup.
class CanvasImageSourceWrapper extends ImageSource {
  CanvasImageSourceWrapper(this.canvasImageSource, this.width, this.height);

  @override
  final DomCanvasImageSource canvasImageSource;

  @override
  final int width;

  @override
  final int height;

  @override
  void _doClose() {
    // Generic canvas image sources do not require manual resource disposal.
  }
}
