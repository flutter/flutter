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

  /// The index to the next frame to be decoded.
  int _nextFrameIndex = 0;

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

    // If the object has been deleted then resurrected, it may already have
    // iterated over some frames. We need to skip over them.
    for (int i = 0; i < _nextFrameIndex; i++) {
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
    final int durationMillis = skiaObject.decodeNextFrame();
    final Duration duration = Duration(milliseconds: durationMillis);
    final CkImage image = CkImage(skiaObject.makeImageAtCurrentFrame());
    _nextFrameIndex = (_nextFrameIndex + 1) % _frameCount;
    return Future<ui.FrameInfo>.value(AnimatedImageFrameInfo(duration, image));
  }
}
