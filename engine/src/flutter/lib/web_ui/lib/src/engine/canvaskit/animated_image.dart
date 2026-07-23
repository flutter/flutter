// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Uses image codecs supplied by the CanvasKit WASM bundle.
///
/// See also:
///
///  * `image_web_codecs.dart`, which uses the `ImageDecoder` supplied by the browser.
library animated_image;

import 'dart:async';
import 'dart:typed_data';

import 'package:ui/src/engine.dart';

/// The CanvasKit implementation of [BackendAnimatedImage].
///
/// This class acts as a simple, backend-specific adapter around CanvasKit's
/// native [SkAnimatedImage]. It delegates frame extraction and metadata queries
/// directly to the native object, and deletes the native WebAssembly object when
/// explicitly disposed.
class CkAnimatedImage implements BackendAnimatedImage {
  /// Decodes an animated image from a list of encoded bytes.
  CkAnimatedImage.decodeFromBytes(this._bytes, this.src, {this.targetWidth, this.targetHeight}) {
    skAnimatedImage = createSkAnimatedImage();
  }

  /// The underlying native Skia animated image object.
  late final SkAnimatedImage skAnimatedImage;
  final String src;
  final Uint8List _bytes;
  int _frameCount = 0;
  int _repetitionCount = -1;

  /// The target width requested by the user.
  ///
  /// Note: CanvasKit's WASM animated image decoder does not support native resizing
  /// during decode. The shared frontend (`_SkiaEngineCodec`) will apply a canvas-based
  /// scaling fallback if these dimensions are specified.
  final int? targetWidth;

  /// The target height requested by the user.
  final int? targetHeight;

  /// Invokes CanvasKit to instantiate the native decoder and read initial metadata.
  SkAnimatedImage createSkAnimatedImage() {
    final SkAnimatedImage? animatedImage = canvasKit.MakeAnimatedImageFromEncoded(_bytes);
    if (animatedImage == null) {
      throw ImageCodecException(
        'Failed to decode image data.\n'
        'Image source: $src',
      );
    }

    _frameCount = animatedImage.getFrameCount().toInt();
    _repetitionCount = animatedImage.getRepetitionCount().toInt();

    return animatedImage;
  }

  bool _disposed = false;
  bool get debugDisposed => _disposed;

  bool _debugCheckIsNotDisposed() {
    assert(!_disposed, 'This image has been disposed.');
    return true;
  }

  @override
  void dispose() {
    assert(!_disposed, 'Cannot dispose a codec that has already been disposed.');
    _disposed = true;
    skAnimatedImage.delete();
  }

  @override
  int get frameCount {
    assert(_debugCheckIsNotDisposed());
    return _frameCount;
  }

  @override
  int get repetitionCount {
    assert(_debugCheckIsNotDisposed());
    return _repetitionCount;
  }

  @override
  Future<BackendFrameInfo> getNextFrame() {
    assert(_debugCheckIsNotDisposed());

    // Query the display duration for the current frame.
    final int frameDurationMs = skAnimatedImage.currentFrameDuration().toInt();

    // Extract the current frame as a static SkImage and wrap it.
    final SkImage skImage = skAnimatedImage.makeImageAtCurrentFrame();

    final currentFrame = BackendFrameInfo(
      duration: Duration(milliseconds: frameDurationMs),
      image: CkImageDelegate(skImage),
    );

    // Advance the native decoder so the next frame is ready on the next call.
    skAnimatedImage.decodeNextFrame();

    return Future<BackendFrameInfo>.value(currentFrame);
  }
}
