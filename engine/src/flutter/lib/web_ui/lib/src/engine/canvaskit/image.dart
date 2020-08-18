// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.10
part of engine;

/// Instantiates a [ui.Codec] backed by an `SkAnimatedImage` from Skia.
void skiaInstantiateImageCodec(Uint8List list, Callback<ui.Codec> callback,
    [int? width, int? height, int? format, int? rowBytes]) {
  final SkAnimatedImage skAnimatedImage =
      canvasKit.MakeAnimatedImageFromEncoded(list);
  final CkAnimatedImage animatedImage = CkAnimatedImage(skAnimatedImage);
  final CkAnimatedImageCodec codec = CkAnimatedImageCodec(animatedImage);
  callback(codec);
}

/// Instantiates a [ui.Codec] backed by an `SkAnimatedImage` from Skia after requesting from URI.
void skiaInstantiateWebImageCodec(String src, Callback<ui.Codec> callback,
    WebOnlyImageCodecChunkCallback? chunkCallback) {
  chunkCallback?.call(0, 100);
  //TODO: Switch to using MakeImageFromCanvasImageSource when animated images are supported.
  html.HttpRequest.request(
    src,
    responseType: "arraybuffer",
  ).then((html.HttpRequest response) {
    chunkCallback?.call(100, 100);
    final Uint8List list =
        new Uint8List.view((response.response as ByteBuffer));
    final SkAnimatedImage skAnimatedImage =
        canvasKit.MakeAnimatedImageFromEncoded(list);
    final CkAnimatedImage animatedImage = CkAnimatedImage(skAnimatedImage);
    final CkAnimatedImageCodec codec = CkAnimatedImageCodec(animatedImage);
    callback(codec);
  });
}

/// A wrapper for `SkAnimatedImage`.
class CkAnimatedImage implements ui.Image {
  final SkAnimatedImage _skAnimatedImage;

  // Use a box because `SkImage` may be deleted either due to this object
  // being garbage-collected, or by an explicit call to [delete].
  late final SkiaObjectBox box;

  CkAnimatedImage(this._skAnimatedImage) {
    box = SkiaObjectBox(this, _skAnimatedImage as SkDeletable);
  }

  @override
  void dispose() {
    box.delete();
  }

  int get frameCount => _skAnimatedImage.getFrameCount();

  /// Decodes the next frame and returns the frame duration.
  Duration decodeNextFrame() {
    final int durationMillis = _skAnimatedImage.decodeNextFrame();
    return Duration(milliseconds: durationMillis);
  }

  int get repetitionCount => _skAnimatedImage.getRepetitionCount();

  CkImage get currentFrameAsImage {
    return CkImage(_skAnimatedImage.getCurrentFrame());
  }

  @override
  int get width => _skAnimatedImage.width();

  @override
  int get height => _skAnimatedImage.height();

  @override
  Future<ByteData> toByteData(
      {ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba}) {
    throw 'unimplemented';
  }
}

/// A [ui.Image] backed by an `SkImage` from Skia.
class CkImage implements ui.Image {
  final SkImage skImage;

  // Use a box because `SkImage` may be deleted either due to this object
  // being garbage-collected, or by an explicit call to [delete].
  late final SkiaObjectBox box;

  CkImage(this.skImage) {
    box = SkiaObjectBox(this, skImage as SkDeletable);
  }

  @override
  void dispose() {
    box.delete();
  }

  @override
  int get width => skImage.width();

  @override
  int get height => skImage.height();

  @override
  Future<ByteData> toByteData(
      {ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba}) {
    throw 'unimplemented';
  }
}

/// A [Codec] that wraps an `SkAnimatedImage`.
class CkAnimatedImageCodec implements ui.Codec {
  CkAnimatedImage animatedImage;

  CkAnimatedImageCodec(this.animatedImage);

  @override
  void dispose() {
    animatedImage.dispose();
  }

  @override
  int get frameCount => animatedImage.frameCount;

  @override
  int get repetitionCount => animatedImage.repetitionCount;

  @override
  Future<ui.FrameInfo> getNextFrame() {
    final Duration duration = animatedImage.decodeNextFrame();
    final CkImage image = animatedImage.currentFrameAsImage;
    return Future<ui.FrameInfo>.value(AnimatedImageFrameInfo(duration, image));
  }
}

/// Data for a single frame of an animated image.
class AnimatedImageFrameInfo implements ui.FrameInfo {
  final Duration _duration;
  final CkImage _image;

  AnimatedImageFrameInfo(this._duration, this._image);

  @override
  Duration get duration => _duration;

  @override
  ui.Image get image => _image;
}
