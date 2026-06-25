// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

/// An engine implementation of the [ui.Codec] interface.
///
/// This codec delegates to a concrete sub-codec depending on how the image
/// source is loaded (e.g. browser image decoder, static image, or a Skia/Skwasm backend animated image).
abstract class EngineCodec implements ui.Codec {
  /// Creates an [EngineCodec] that uses a browser-provided [BrowserImageDecoder]
  /// to decode frames.
  ///
  /// This is the preferred path for web browsers supporting the modern native
  /// `ImageDecoder` API, allowing highly efficient progressive and animated
  /// decoding offloaded to the browser.
  factory EngineCodec.browser(
    BrowserImageDecoder decoder, {
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling,
  }) = _BrowserEngineCodec;

  /// Creates an [EngineCodec] for a single static [ImageSource].
  ///
  /// Used for static images that have already been decoded or represent a static
  /// DOM asset (like an `HTMLImageElement` or `ImageBitmap`), bypassing multi-frame
  /// animation machinery.
  factory EngineCodec.staticImage(
    ImageSource source, {
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling,
  }) = _StaticEngineCodec;

  /// Creates an [EngineCodec] that wraps a Skia/Skwasm [BackendAnimatedImage].
  ///
  /// Used for animated formats (like GIF or WebP) or unsupported formats where
  /// native browser decoders are unavailable, falling back to C++ Skia or WASM
  /// C++ decoding.
  factory EngineCodec.skia(
    BackendAnimatedImage backendAnimatedImage, {
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling,
  }) = _SkiaEngineCodec;

  /// Protected constructor for subclasses.
  EngineCodec._();
}

/// An [EngineCodec] that decodes frames using the browser's [BrowserImageDecoder].
///
/// This class orchestrates a multi-step asynchronous pipeline that decodes frames
/// using the browser's native `ImageDecoder` and resizes them natively on the CPU
/// using `createImageBitmap` if target dimensions are requested.
/// An [EngineCodec] that decodes frames using the browser's [BrowserImageDecoder].
///
/// This class orchestrates a multi-step asynchronous pipeline that decodes frames
/// using the browser's native `ImageDecoder` and resizes them natively on the CPU
/// using `createImageBitmap` if target dimensions are requested.
class _BrowserEngineCodec extends EngineCodec {
  _BrowserEngineCodec(
    BrowserImageDecoder browserDecoder, {
    this.targetWidth,
    this.targetHeight,
    this.allowUpscaling = true,
  }) : super._() {
    _ref = UniqueRef<BrowserImageDecoder>(
      this,
      browserDecoder,
      'BrowserCodec',
      onDispose: (BrowserImageDecoder decoder) => decoder.dispose(),
    );
  }

  late final UniqueRef<BrowserImageDecoder> _ref;
  final int? targetWidth;
  final int? targetHeight;
  final bool allowUpscaling;
  bool _disposed = false;

  @override
  int get frameCount => _ref.nativeObject.frameCount;

  @override
  int get repetitionCount => _ref.nativeObject.repetitionCount;

  @override
  void dispose() {
    _disposed = true;
    _ref.dispose();
  }

  @override
  Future<ui.FrameInfo> getNextFrame() async {
    if (_disposed) {
      throw StateError('Cannot call getNextFrame() after dispose()');
    }
    try {
      // Decode the next raw frame from the browser decoder.
      // This is an asynchronous operation, during which the codec could be disposed.
      final VideoFrame frame = await _ref.nativeObject.getNextFrame();

      // Async Safety Check: If the codec was disposed while awaiting the frame decode,
      // we MUST close the native VideoFrame immediately. Failing to do so would
      // leak the underlying browser-allocated GPU/system memory.
      if (_disposed) {
        frame.close();
        throw StateError('Codec disposed during getNextFrame()');
      }
      final duration = Duration(microseconds: frame.duration?.toInt() ?? 0);

      final int originalWidth = frame.displayWidth.toInt();
      final int originalHeight = frame.displayHeight.toInt();
      final BitmapSize? scaledSize = scaledImageSize(
        originalWidth,
        originalHeight,
        targetWidth,
        targetHeight,
      );

      final int destWidth = scaledSize?.width ?? originalWidth;
      final int destHeight = scaledSize?.height ?? originalHeight;

      final ui.Image image;
      if (scaledSize != null) {
        // Scale the frame natively.
        // We use the browser's high-performance native scale API which creates a
        // scaled ImageBitmap directly. This is asynchronous and yields the thread.
        final DomImageBitmap bitmap;
        try {
          bitmap = await scaleImageSource(
            frame,
            originalWidth,
            originalHeight,
            destWidth,
            destHeight,
          );
        } finally {
          frame.close();
        }

        // Async Safety Check: Check if disposed during the scale operation.
        // If so, close the newly created scaled bitmap to prevent leaks.
        if (_disposed) {
          bitmap.close();
          throw StateError('Codec disposed during getNextFrame()');
        }

        // Upload the scaled bitmap to the GPU.
        try {
          image = await renderer.createImageFromTextureSource(
            bitmap,
            width: destWidth,
            height: destHeight,
            transferOwnership: true,
          );
        } catch (e) {
          bitmap.close();
          rethrow;
        }
      } else {
        // Upload the original unscaled frame directly to the GPU.
        try {
          image = await renderer.createImageFromTextureSource(
            frame,
            width: destWidth,
            height: destHeight,
            transferOwnership: true,
          );
        } catch (e) {
          frame.close();
          rethrow;
        }
      }

      // Async Safety Check: Check if disposed during the GPU texture upload.
      // If so, dispose of the wrapped image.
      if (_disposed) {
        image.dispose();
        throw StateError('Codec disposed during getNextFrame()');
      }
      return AnimatedImageFrameInfo(duration, image);
    } catch (e) {
      if (_disposed) {
        throw StateError('Codec disposed during getNextFrame()');
      }
      rethrow;
    }
  }
}

/// An [EngineCodec] that wraps a single static [ImageSource].
///
/// This codec is optimized for static images. Since static images do not animate,
/// [frameCount] is always 1, and the single frame is resolved synchronously
/// by querying the backend factory.
class _StaticEngineCodec extends EngineCodec {
  _StaticEngineCodec(
    this._staticImageSource, {
    this.targetWidth,
    this.targetHeight,
    this.allowUpscaling = true,
  }) : super._() {
    // Retain the underlying image source to increment its reference count.
    // This guarantees that the native image data (such as an ImageBitmap) remains
    // alive in memory as long as this codec exists.
    _staticImageSource.retain();
  }

  final ImageSource _staticImageSource;
  final int? targetWidth;
  final int? targetHeight;
  final bool allowUpscaling;
  bool _disposed = false;

  @override
  int get frameCount => 1;

  @override
  int get repetitionCount => 0;

  @override
  void dispose() {
    _disposed = true;
    // Release our reference to the image source. If the reference count drops to 0,
    // the native resources (like the ImageBitmap) will be closed and freed.
    _staticImageSource.release();
  }

  @override
  Future<ui.FrameInfo> getNextFrame() {
    if (_disposed) {
      return Future<ui.FrameInfo>.error(StateError('Cannot call getNextFrame() after dispose()'));
    }
    // Synchronously instruct the backend renderer to convert the normalized
    // DOM asset into a backend-specific representation (e.g., uploading to a GPU texture).
    final BackendImage backendImage = renderer.createImageFromImageSource(_staticImageSource);
    final ui.Image image = EngineImage(
      backendImage,
      _staticImageSource.width,
      _staticImageSource.height,
      imageSource: _staticImageSource,
    );
    return Future<ui.FrameInfo>.value(AnimatedImageFrameInfo(Duration.zero, image));
  }
}

/// An [EngineCodec] that wraps a Skia/Skwasm [BackendAnimatedImage].
///
/// This codec is used when the browser's native `ImageDecoder` is unavailable,
/// routing decoding work through WASM Skia (CanvasKit) or C++ FFI (Skwasm).
///
/// Resizing animated images differs fundamentally between backends:
/// 1. Skwasm supports native C++ resizing (via `SkAndroidCodec` scaling) during
///    decoding, so no frontend scaling is required.
/// 2. CanvasKit's WASM animated image decoder does not support native scaling.
///    Therefore, it decodes frames at their original size, and the frontend must
///    perform an expensive frame-by-frame resize fallback using `scaleImageIfNeeded`
///    (drawing onto a canvas via `ui.PictureRecorder`).
class _SkiaEngineCodec extends EngineCodec {
  _SkiaEngineCodec(
    BackendAnimatedImage backendAnimatedImage, {
    this.targetWidth,
    this.targetHeight,
    this.allowUpscaling = true,
  }) : super._() {
    _ref = UniqueRef<BackendAnimatedImage>(
      this,
      backendAnimatedImage,
      'SkiaCodec',
      onDispose: (BackendAnimatedImage image) => image.dispose(),
    );
    if ((targetWidth != null || targetHeight != null) &&
        _ref.nativeObject.frameCount > 1 &&
        !renderer.supportsResizingAnimatedImages) {
      printWarning(
        'targetWidth and targetHeight for multi-frame images are not natively supported by the current renderer. '
        'Scaling will fall back to expensive frame-by-frame canvas drawing.',
      );
    }
  }

  late final UniqueRef<BackendAnimatedImage> _ref;
  final int? targetWidth;
  final int? targetHeight;
  final bool allowUpscaling;
  bool _disposed = false;

  @override
  int get frameCount => _ref.nativeObject.frameCount;

  @override
  int get repetitionCount => _ref.nativeObject.repetitionCount;

  @override
  void dispose() {
    _disposed = true;
    _ref.dispose();
  }

  @override
  Future<ui.FrameInfo> getNextFrame() async {
    if (_disposed) {
      throw StateError('Cannot call getNextFrame() after dispose()');
    }
    try {
      // Extract the next frame from the native backend.
      final BackendFrameInfo backendFrame = await _ref.nativeObject.getNextFrame();

      // Async Safety Check: If the codec was disposed while the backend was
      // decoding the frame, we must dispose of the backend image immediately
      // to prevent native memory leaks.
      if (_disposed) {
        backendFrame.image.dispose();
        throw StateError('Codec disposed during getNextFrame()');
      }
      ui.Image image = EngineImage(
        backendFrame.image,
        backendFrame.image.width,
        backendFrame.image.height,
      );

      // Apply the frontend canvas-scaling fallback if the backend does not support
      // native resizing of animated images on decode.
      if (targetWidth != null || targetHeight != null) {
        try {
          image = scaleImageIfNeeded(
            image,
            targetWidth: targetWidth,
            targetHeight: targetHeight,
            allowUpscaling: allowUpscaling,
          );
        } catch (e) {
          image.dispose();
          rethrow;
        }
      }
      return AnimatedImageFrameInfo(backendFrame.duration, image);
    } catch (e) {
      if (_disposed) {
        throw StateError('Codec disposed during getNextFrame()');
      }
      rethrow;
    }
  }
}
