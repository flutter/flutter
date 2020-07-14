// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


part of engine;

/// Instantiates a [ui.Codec] backed by an `SkImage` from Skia.
void skiaInstantiateImageCodec(Uint8List list, Callback<ui.Codec> callback,
    [int? width, int? height, int? format, int? rowBytes]) {
  final SkAnimatedImage skAnimatedImage = canvasKitJs.MakeAnimatedImageFromEncoded(list);
  final CkAnimatedImage animatedImage = CkAnimatedImage(skAnimatedImage);
  final CkAnimatedImageCodec codec = CkAnimatedImageCodec(animatedImage);
  callback(codec);
}

/// A wrapper for `SkAnimatedImage`.
class CkAnimatedImage implements ui.Image {
  final SkAnimatedImage _skAnimatedImage;

  CkAnimatedImage(this._skAnimatedImage);

  @override
  void dispose() {
    _skAnimatedImage.delete();
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
  late final js.JsObject legacyJsObject = _jsObjectWrapper.wrapSkImage(skImage);

  CkImage(this.skImage);

  @override
  void dispose() {
    skImage.delete();
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
  CkAnimatedImage? animatedImage;

  CkAnimatedImageCodec(this.animatedImage);

  @override
  void dispose() {
    animatedImage!.dispose();
    animatedImage = null;
  }

  @override
  int get frameCount => animatedImage!.frameCount;

  @override
  int get repetitionCount => animatedImage!.repetitionCount;

  @override
  Future<ui.FrameInfo> getNextFrame() {
    final Duration duration = animatedImage!.decodeNextFrame();
    final CkImage image = animatedImage!.currentFrameAsImage;
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
