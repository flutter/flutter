// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Uses image codecs supplied by the CanvasKit WASM bundle.
///
/// See also:
///
///  * `image_web_codecs.dart`, which uses the `ImageDecoder` supplied by the browser.
library image_wasm_codecs;

import 'dart:async';
import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import 'canvaskit_api.dart';
import 'image.dart';
import 'skia_object_cache.dart';

/// The CanvasKit implementation of [ui.Codec].
///
/// Wraps `SkAnimatedImage`.
class CkAnimatedImage extends ManagedSkiaObject<SkAnimatedImage>
    implements ui.Codec {
  /// Decodes an image from a list of encoded bytes.
  CkAnimatedImage.decodeFromBytes(this._bytes, this.src);

  final String src;
  final Uint8List _bytes;
  int _frameCount = 0;
  int _repetitionCount = -1;

  /// Current frame index.
  int _currentFrameIndex = 0;

  @override
  SkAnimatedImage createDefault() {
    final SkAnimatedImage? animatedImage =
        canvasKit.MakeAnimatedImageFromEncoded(_bytes);
    if (animatedImage == null) {
      throw ImageCodecException(
        'Failed to decode image data.\n'
        'Image source: $src',
      );
    }

    _frameCount = animatedImage.getFrameCount();
    _repetitionCount = animatedImage.getRepetitionCount();

    // Normally CanvasKit initializes `SkAnimatedImage` to point to the first
    // frame in the animation. However, if the Skia object has been deleted then
    // resurrected, the framework/app may already have advanced to one of the
    // subsequent frames. When that happens the value of _currentFrameIndex will
    // be something other than zero, and we need to tell the decoder to skip
    // over the previous frames to point to the current one.
    for (int i = 0; i < _currentFrameIndex; i++) {
      animatedImage.decodeNextFrame();
    }

    return animatedImage;
  }

  @override
  SkAnimatedImage resurrect() => createDefault();

  @override
  bool get isResurrectionExpensive => true;

  @override
  void delete() {
    rawSkiaObject?.delete();
  }

  bool _disposed = false;
  bool get debugDisposed => _disposed;

  bool _debugCheckIsNotDisposed() {
    assert(!_disposed, 'This image has been disposed.');
    return true;
  }

  @override
  void dispose() {
    assert(
      !_disposed,
      'Cannot dispose a codec that has already been disposed.',
    );
    _disposed = true;
    delete();
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
  Future<ui.FrameInfo> getNextFrame() {
    assert(_debugCheckIsNotDisposed());
    final SkAnimatedImage animatedImage = skiaObject;

    // SkAnimatedImage comes pre-initialized to point to the current frame (by
    // default the first frame, and, with some special resurrection logic in
    // `createDefault`, to a subsequent frame if resurrection happens in the
    // middle of animation). Flutter's `Codec` semantics is to initialize to
    // point to "just before the first frame", i.e. the first invocation of
    // `getNextFrame` returns the first frame. Therefore, we have to read the
    // current Skia frame, then advance SkAnimatedImage to the next frame, and
    // return the current frame.
    final ui.FrameInfo currentFrame = AnimatedImageFrameInfo(
      Duration(milliseconds: animatedImage.currentFrameDuration()),
      CkImage(animatedImage.makeImageAtCurrentFrame()),
    );

    animatedImage.decodeNextFrame();
    _currentFrameIndex = (_currentFrameIndex + 1) % _frameCount;
    return Future<ui.FrameInfo>.value(currentFrame);
  }
}
