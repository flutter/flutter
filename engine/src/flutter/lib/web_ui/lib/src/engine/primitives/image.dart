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
  /// Increments the reference count of the optional [imageSource] and any
  /// sources in [imageTracker] to prevent them from being eagerly closed until
  /// [box] is disposed or collected.
  EngineImage(
    BackendImage backendImage,
    this.width,
    this.height, {
    this.imageSource,
    PictureImageTracker? imageTracker,
  }) : imageTracker = _retainTracker(imageTracker) {
    // Retain the image source for the lifetime of the shared reference box so
    // both explicit disposal and GC finalization release it deterministically.
    imageSource?.retain();
    // Wrap the backend image in a reference-counted box.
    box = CountedRef<EngineImage, BackendImage>(
      backendImage,
      this,
      'BackendImage',
      onDispose: _createDisposer(imageSource, this.imageTracker),
      onDisposed: _notifyDisposed,
    );
    // Initialize the debug stack trace.
    _init();
    // Notify the creation listeners.
    ui.Image.onCreate?.call(this);
  }

  /// Creates a clone of an existing [EngineImage] sharing the same [box].
  ///
  /// Increments the reference count of [box], which retains [imageSource] and
  /// [imageTracker] until all clones sharing [box] are disposed or collected.
  EngineImage.cloneOf(this.box, this.width, this.height, {this.imageSource, this.imageTracker}) {
    // Initialize the debug stack trace.
    _init();
    // Reference the shared box.
    box.ref(this);
  }

  static PictureImageTracker? _retainTracker(PictureImageTracker? tracker) {
    if (tracker == null || tracker.isEmpty) {
      return null;
    }
    return PictureImageTracker()..recordFrom(tracker);
  }

  static void _disposeBackendImage(BackendImage backendImage) {
    backendImage.dispose();
  }

  /// Builds the [UniqueRef] disposal callback without capturing `this`, so
  /// [DomFinalizationRegistry]'s strongly held [UniqueRef] does not retain
  /// [box] and prevent garbage collection.
  static void Function(BackendImage) _createDisposer(
    ImageSource? source,
    PictureImageTracker? tracker,
  ) {
    if (source == null && tracker == null) {
      return _disposeBackendImage;
    }
    return _createTrackedDisposer(source, tracker);
  }

  static void Function(BackendImage) _createTrackedDisposer(
    ImageSource? source,
    PictureImageTracker? tracker,
  ) {
    return (BackendImage backendImage) {
      try {
        backendImage.dispose();
      } finally {
        try {
          source?.release();
        } finally {
          tracker?.releaseAll();
        }
      }
    };
  }

  /// Notifies [ui.Image.onDispose] listeners when the last handle is disposed.
  static void _notifyDisposed(EngineImage image) {
    ui.Image.onDispose?.call(image);
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

  /// Retained [ImageSource]s from a recorded picture when this image is backed
  /// by a deferred picture (such as `SkwasmPicture.toImageSync`).
  final PictureImageTracker? imageTracker;

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
    return EngineImage.cloneOf(
      box,
      width,
      height,
      imageSource: imageSource,
      imageTracker: imageTracker,
    );
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
    if (_disposed) {
      throw StateError('Cannot call toByteData on a disposed image.');
    }

    // Clone the image to prevent use-after-free vulnerabilities.
    // If the image is disposed by the user during asynchronous bounds of this method,
    // cloneImage holds a separate reference on the underlying box, keeping the backend
    // pointers fully alive and valid until this method completes.
    final EngineImage cloneImage = clone();
    try {
      final ImageSource? source = cloneImage.imageSource;
      final bool isSourceDetached =
          source == null ||
          (source is ImageBitmapImageSource && source.imageBitmap.width == 0) ||
          (source is VideoFrameImageSource && source.videoFrame.displayWidth == 0);

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
          final String? formatStr = videoFrame.format;
          if (formatStr == 'RGBA' ||
              formatStr == 'RGBX' ||
              formatStr == 'BGRA' ||
              formatStr == 'BGRX') {
            return await readPixelsFromVideoFrame(videoFrame, format);
          }
        case final CanvasImageSourceWrapper s:
          return await readPixelsFromDomImageSource(s.canvasImageSource, format, s.width, s.height);
        case null:
          break;
      }

      // Asynchronous, non-blocking PNG encoding fallback using OffscreenCanvas.
      //
      // Extracting raw pixels from a GPU-backed image (where imageSource is null)
      // requires a synchronous readPixels call, which causes a severe WebGL GPU
      // stall and blocks the browser main thread. Thus, we only use this fallback
      // for CPU-backed images (where imageSource is not null).
      if (format == ui.ImageByteFormat.png && !isSourceDetached) {
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
          clampedBytes.toJS,
          cloneImage.width,
          cloneImage.height,
        );
        context.putImageData(imageData, 0, 0);

        // Convert the canvas contents to a PNG blob asynchronously.
        final DomBlob blob = await offscreenCanvas.convertToBlob();
        final arrayBuffer = (await blob.arrayBuffer().toDart)! as JSArrayBuffer;

        // Reclaim browser resources eagerly by zeroing the offscreen canvas.
        offscreenCanvas.width = 0;
        offscreenCanvas.height = 0;
        return ByteData.view(arrayBuffer.toDart);
      }

      // On backends which do not support encoding to PNG directly from a surface,
      // we draw the image to a picture, resize the offscreen surface, and
      // rasterize the picture to a DomImageBitmap. The resulting bitmap is then
      // transferred to an OffscreenCanvas and encoded to a PNG blob asynchronously,
      // avoiding main-thread GPU stalls.
      if (format == ui.ImageByteFormat.png &&
          isSourceDetached &&
          !renderer.pictureToImageSurface.supportsPngEncoding) {
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.drawImage(cloneImage, ui.Offset.zero, ui.Paint());
        final ui.Picture picture = recorder.endRecording();

        final List<DomImageBitmap> bitmaps =
            await (renderer.pictureToImageSurface as OffscreenSurface).rasterizeToImageBitmaps(
              BitmapSize(cloneImage.width, cloneImage.height),
              <ui.Picture>[picture],
            );
        final DomImageBitmap bitmap = bitmaps.single;

        final DomOffscreenCanvas offscreenCanvas = createDomOffscreenCanvas(
          bitmap.width,
          bitmap.height,
        );
        final context =
            offscreenCanvas.getContext('bitmaprenderer')! as DomImageBitmapRenderingContext;
        context.transferFromImageBitmap(bitmap);
        final DomBlob blob = await offscreenCanvas.convertToBlob();
        final arrayBuffer = (await blob.arrayBuffer().toDart)! as JSArrayBuffer;

        context.transferFromImageBitmap(null);
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
