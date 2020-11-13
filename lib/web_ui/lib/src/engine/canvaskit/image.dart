// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
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

/// Instantiates a [ui.Codec] backed by an `SkAnimatedImage` from Skia after
/// requesting from URI.
Future<ui.Codec> skiaInstantiateWebImageCodec(
    String src, WebOnlyImageCodecChunkCallback? chunkCallback) {
  Completer<ui.Codec> completer = Completer<ui.Codec>();
  //TODO: Switch to using MakeImageFromCanvasImageSource when animated images are supported.
  html.HttpRequest.request(src, responseType: "arraybuffer",
      onProgress: (html.ProgressEvent event) {
    if (event.lengthComputable) {
      chunkCallback?.call(event.loaded!, event.total!);
    }
  }).then((html.HttpRequest response) {
    if (response.status != 200) {
      completer.completeError(Exception(
          'Network image request failed with status: ${response.status}'));
    }
    final Uint8List list =
        new Uint8List.view((response.response as ByteBuffer));
    final SkAnimatedImage skAnimatedImage =
        canvasKit.MakeAnimatedImageFromEncoded(list);
    final CkAnimatedImage animatedImage = CkAnimatedImage(skAnimatedImage);
    final CkAnimatedImageCodec codec = CkAnimatedImageCodec(animatedImage);
    completer.complete(codec);
  }, onError: (dynamic error) {
    completer.completeError(error);
  });
  return completer.future;
}

/// A wrapper for `SkAnimatedImage`.
class CkAnimatedImage implements ui.Image {
  // Use a box because `SkImage` may be deleted either due to this object
  // being garbage-collected, or by an explicit call to [delete].
  late final SkiaObjectBox<SkAnimatedImage> box;

  SkAnimatedImage get _skAnimatedImage => box.skObject;

  CkAnimatedImage(SkAnimatedImage skAnimatedImage) {
    box = SkiaObjectBox<SkAnimatedImage>(this, skAnimatedImage);
  }

  CkAnimatedImage.cloneOf(SkiaObjectBox<SkAnimatedImage> boxToClone) {
    box = boxToClone.clone(this);
  }

  bool _disposed = false;
  @override
  void dispose() {
    box.delete();
    _disposed = true;
  }

  @override
  bool get debugDisposed {
    if (assertionsEnabled) {
      return _disposed;
    }
    throw StateError(
        'Image.debugDisposed is only available when asserts are enabled.');
  }

  ui.Image clone() => CkAnimatedImage.cloneOf(box);

  @override
  bool isCloneOf(ui.Image other) {
    return other is CkAnimatedImage &&
        other._skAnimatedImage.isAliasOf(_skAnimatedImage);
  }

  @override
  List<StackTrace>? debugGetOpenHandleStackTraces() =>
      box.debugGetStackTraces();

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
    Uint8List bytes;

    if (format == ui.ImageByteFormat.rawRgba) {
      final SkImageInfo imageInfo = SkImageInfo(
        alphaType: canvasKit.AlphaType.Premul,
        colorType: canvasKit.ColorType.RGBA_8888,
        colorSpace: SkColorSpaceSRGB,
        width: width,
        height: height,
      );
      bytes = _skAnimatedImage.readPixels(imageInfo, 0, 0);
    } else {
      // Defaults to PNG 100%.
      final SkData skData = _skAnimatedImage.encodeToData();
      // Make a copy that we can return.
      bytes = Uint8List.fromList(canvasKit.getSkDataBytes(skData));
    }

    final ByteData data = bytes.buffer.asByteData(0, bytes.length);
    return Future<ByteData>.value(data);
  }

  @override
  String toString() => '[$width\u00D7$height]';
}

/// A [ui.Image] backed by an `SkImage` from Skia.
class CkImage implements ui.Image {
  // Use a box because `SkImage` may be deleted either due to this object
  // being garbage-collected, or by an explicit call to [delete].
  late final SkiaObjectBox<SkImage> box;

  SkImage get skImage => box.skObject;

  CkImage(SkImage skImage) {
    box = SkiaObjectBox<SkImage>(this, skImage);
  }

  CkImage.cloneOf(SkiaObjectBox<SkImage> boxToClone) {
    box = boxToClone.clone(this);
  }

  bool _disposed = false;
  @override
  void dispose() {
    box.delete();
    assert(() {
      _disposed = true;
      return true;
    }());
  }

  @override
  bool get debugDisposed {
    if (assertionsEnabled) {
      return _disposed;
    }
    throw StateError(
        'Image.debugDisposed is only available when asserts are enabled.');
  }

  @override
  ui.Image clone() => CkImage.cloneOf(box);

  @override
  bool isCloneOf(ui.Image other) {
    return other is CkImage && other.skImage.isAliasOf(skImage);
  }

  @override
  List<StackTrace>? debugGetOpenHandleStackTraces() =>
      box.debugGetStackTraces();

  @override
  int get width => skImage.width();

  @override
  int get height => skImage.height();

  @override
  Future<ByteData> toByteData(
      {ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba}) {
    Uint8List bytes;

    if (format == ui.ImageByteFormat.rawRgba) {
      final SkImageInfo imageInfo = SkImageInfo(
        alphaType: canvasKit.AlphaType.Premul,
        colorType: canvasKit.ColorType.RGBA_8888,
        colorSpace: SkColorSpaceSRGB,
        width: width,
        height: height,
      );
      bytes = skImage.readPixels(imageInfo, 0, 0);
    } else {
      final SkData skData = skImage.encodeToData(); //defaults to PNG 100%
      // make a copy that we can return
      bytes = Uint8List.fromList(canvasKit.getSkDataBytes(skData));
    }

    final ByteData data = bytes.buffer.asByteData(0, bytes.length);
    return Future<ByteData>.value(data);
  }

  @override
  String toString() => '[$width\u00D7$height]';
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
