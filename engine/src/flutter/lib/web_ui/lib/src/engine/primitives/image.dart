// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// An engine-specific implementation of the [ui.Image] interface.
///
/// This class acts as a frontend representation of an image, delegating its
/// underlying graphics resources to a [BackendImage] while managing lifecycle
/// state, reference counting, and interactions with the browser's DOM elements
/// via an optional [ImageSource].
class EngineImage implements ui.Image, StackTraceDebugger {
  /// Creates an [EngineImage] wrapping a [BackendImage].
  ///
  /// Increments the reference count of the optional [imageSource] to prevent it
  /// from being eagerly closed.
  EngineImage(BackendImage backendImage, this.width, this.height, {this.imageSource}) {
    // Wrap the backend image in a reference-counted box.
    box = CountedRef<EngineImage, BackendImage>(
      backendImage,
      this,
      'BackendImage',
      onDispose: (BackendImage backendImage) => backendImage.dispose(),
      onDisposed: (EngineImage image) {
        ui.Image.onDispose?.call(image);
      },
    );
    // Initialize the debug stack trace.
    _init();
    // Notify the creation listeners.
    ui.Image.onCreate?.call(this);
    // Retain a reference to the image source.
    imageSource?.retain();
  }

  /// Creates a clone of an existing [EngineImage] sharing the same [box].
  ///
  /// Increments the reference count of the optional [imageSource] and of the [box].
  EngineImage.cloneOf(this.box, this.width, this.height, {this.imageSource}) {
    // Initialize the debug stack trace.
    _init();
    // Reference the shared box.
    box.ref(this);
    // Retain a reference to the image source.
    imageSource?.retain();
  }

  // Initialize debug fields, such as capturing the stack trace when the image is created.
  void _init() {
    assert(() {
      _debugStackTrace = StackTrace.current;
      return true;
    }());
  }

  @override
  StackTrace get debugStackTrace => _debugStackTrace;
  late StackTrace _debugStackTrace;

  /// The reference-counted box containing the [BackendImage].
  late final CountedRef<EngineImage, BackendImage> box;

  /// The underlying [BackendImage] managed by this [EngineImage].
  BackendImage get backendImage => box.nativeObject;

  @override
  final int width;

  @override
  final int height;

  /// An optional [ImageSource] from which this image was loaded.
  final ImageSource? imageSource;

  // Track whether this image has been disposed to prevent double disposal and use-after-free bugs.
  bool _disposed = false;

  // Helper method used in assertions to check if the image has already been disposed.
  bool _debugCheckIsNotDisposed() {
    assert(!_disposed, 'This image has been disposed.');
    return true;
  }

  @override
  void dispose() {
    assert(!_disposed, 'Cannot dispose an image that has already been disposed.');

    // Protect against double disposal in release mode by returning early.
    if (_disposed) {
      return;
    }
    _disposed = true;
    box.unref(this);
    imageSource?.release();
  }

  @override
  bool get debugDisposed {
    bool? result;
    assert(() {
      result = _disposed;
      return true;
    }());
    if (result != null) {
      return result!;
    }
    throw StateError('Image.debugDisposed is only available when asserts are enabled.');
  }

  @override
  EngineImage clone() {
    assert(_debugCheckIsNotDisposed());
    return EngineImage.cloneOf(box, width, height, imageSource: imageSource);
  }

  @override
  bool isCloneOf(ui.Image other) {
    assert(_debugCheckIsNotDisposed());
    return other is EngineImage && other.backendImage.isCloneOf(backendImage);
  }

  @override
  List<StackTrace>? debugGetOpenHandleStackTraces() => box.debugGetStackTraces();

  @override
  ui.ColorSpace get colorSpace => ui.ColorSpace.sRGB;

  @override
  Future<ByteData?> toByteData({ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba}) async {
    assert(!_disposed, 'Cannot call toByteData on a disposed image.');

    // Clone the image to prevent use-after-free vulnerabilities.
    // If the image is disposed by the user during asynchronous bounds of this method,
    // cloneImage holds a separate reference on the underlying box, keeping the backend
    // pointers fully alive and valid until this method completes.
    final EngineImage cloneImage = clone();
    try {
      // Direct pixel extraction based on the type of ImageSource.
      switch (cloneImage.imageSource) {
        case final ImageElementImageSource s:
          final DomHTMLImageElement imageElement = s.imageElement;
          return await readPixelsFromDomImageSource(
            imageElement,
            format,
            imageElement.naturalWidth.toInt(),
            imageElement.naturalHeight.toInt(),
          );
        case final ImageBitmapImageSource s:
          final DomImageBitmap imageBitmap = s.imageBitmap;
          // If the ImageBitmap has been transferred to a web worker, it is detached
          // and its width becomes 0. We must fall back to surface rasterization.
          if (imageBitmap.width == 0) {
            break;
          }
          return await readPixelsFromDomImageSource(
            imageBitmap,
            format,
            imageBitmap.width,
            imageBitmap.height,
          );
        case final VideoFrameImageSource s:
          final VideoFrame videoFrame = s.videoFrame;
          // If the VideoFrame has been transferred to a web worker (e.g., in Skwasm),
          // its format becomes null and its display dimensions become 0.
          // It cannot be used on the main thread, so we fall back to surface rasterization.
          if (videoFrame.displayWidth == 0) {
            break;
          }
          if (videoFrame.format != 'I420' &&
              videoFrame.format != 'I422' &&
              videoFrame.format != 'I444') {
            return await readPixelsFromVideoFrame(videoFrame, format);
          }
        case null:
          break;
      }

      // Asynchronous, non-blocking PNG encoding fallback using OffscreenCanvas.
      if (format == ui.ImageByteFormat.png) {
        final ByteData? rawData = await renderer.pictureToImageSurface.rasterizeImage(
          cloneImage,
          ui.ImageByteFormat.rawStraightRgba,
        );
        if (rawData == null) {
          return null;
        }

        final DomOffscreenCanvas offscreenCanvas = createDomOffscreenCanvas(
          cloneImage.width,
          cloneImage.height,
        );
        final context = offscreenCanvas.getContext('2d')! as DomCanvasRenderingContext2D;

        final clampedBytes = Uint8ClampedList.view(
          rawData.buffer,
          rawData.offsetInBytes,
          rawData.lengthInBytes,
        );
        final DomImageData imageData = createDomImageData(
          clampedBytes,
          cloneImage.width,
          cloneImage.height,
        );
        context.putImageData(imageData, 0, 0);

        // Convert the canvas contents to a PNG blob asynchronously.
        final DomBlob blob = await offscreenCanvas.convertToBlob();
        final JSArrayBuffer arrayBuffer = (await blob.arrayBuffer().toDart)! as JSArrayBuffer;

        // Reclaim browser resources eagerly by zeroing the offscreen canvas.
        offscreenCanvas.width = 0;
        offscreenCanvas.height = 0;
        return ByteData.view(arrayBuffer.toDart);
      }

      // Fall back to standard backend-specific surface rasterization.
      return await renderer.pictureToImageSurface.rasterizeImage(cloneImage, format);
    } finally {
      cloneImage.dispose();
    }
  }

  @override
  String toString() {
    assert(_debugCheckIsNotDisposed());
    return '[$width\u00D7$height]';
  }
}
