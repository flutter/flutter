// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

/// Instantiates a [ui.Codec] backed by an `SkAnimatedImage` from Skia.
ui.Codec skiaInstantiateImageCodec(Uint8List list,
    [int? width, int? height, int? format, int? rowBytes]) {
  return CkAnimatedImage.decodeFromBytes(list);
}

/// Instantiates a [ui.Codec] backed by an `SkAnimatedImage` from Skia after
/// requesting from URI.
Future<ui.Codec> skiaInstantiateWebImageCodec(
    String uri, WebOnlyImageCodecChunkCallback? chunkCallback) {
  Completer<ui.Codec> completer = Completer<ui.Codec>();
  //TODO: Switch to using MakeImageFromCanvasImageSource when animated images are supported.
  html.HttpRequest.request(uri, responseType: "arraybuffer",
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
    final CkAnimatedImage codec = CkAnimatedImage.decodeFromBytes(list);
    completer.complete(codec);
  }, onError: (dynamic error) {
    completer.completeError(error);
  });
  return completer.future;
}

/// The CanvasKit implementation of [ui.Codec].
///
/// Wraps `SkAnimatedImage`.
class CkAnimatedImage extends ManagedSkiaObject<SkAnimatedImage> implements ui.Codec {
  /// Decodes an image from a list of encoded bytes.
  CkAnimatedImage.decodeFromBytes(this._bytes);

  final Uint8List _bytes;

  @override
  SkAnimatedImage createDefault() {
    final SkAnimatedImage? animatedImage = canvasKit.MakeAnimatedImageFromEncoded(_bytes);
    if (animatedImage == null) {
      throw Exception('Failed to decode image');
    }
    return animatedImage;
  }

  @override
  SkAnimatedImage resurrect() => createDefault();

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
    return skiaObject.getFrameCount();
  }

  @override
  int get repetitionCount {
    assert(_debugCheckIsNotDisposed());
    return skiaObject.getRepetitionCount();
  }

  @override
  Future<ui.FrameInfo> getNextFrame() {
    assert(_debugCheckIsNotDisposed());
    final int durationMillis = skiaObject.decodeNextFrame();
    final Duration duration = Duration(milliseconds: durationMillis);
    final CkImage image = CkImage(skiaObject.getCurrentFrame());
    return Future<ui.FrameInfo>.value(AnimatedImageFrameInfo(duration, image));
  }
}

/// A [ui.Image] backed by an `SkImage` from Skia.
class CkImage implements ui.Image, StackTraceDebugger {
  CkImage(SkImage skImage) {
    if (assertionsEnabled) {
      _debugStackTrace = StackTrace.current;
    }
    if (browserSupportsFinalizationRegistry) {
      box = SkiaObjectBox<CkImage, SkImage>(this, skImage);
    } else {
      // If finalizers are not supported we need to be able to resurrect the
      // image if it was temporarily deleted. To do that, we keep the original
      // pixels and ask the SkiaObjectBox to make an image from them when
      // resurrecting.
      //
      // IMPORTANT: the alphaType, colorType, and colorSpace passed to
      // _encodeImage and to canvasKit.MakeImage must be the same. Otherwise
      // Skia will misinterpret the pixels and corrupt the image.
      final ByteData originalBytes = _encodeImage(
        skImage: skImage,
        format: ui.ImageByteFormat.rawRgba,
        alphaType: canvasKit.AlphaType.Premul,
        colorType: canvasKit.ColorType.RGBA_8888,
        colorSpace: SkColorSpaceSRGB,
      );
      box = SkiaObjectBox<CkImage, SkImage>.resurrectable(this, skImage, () {
        return canvasKit.MakeImage(
          originalBytes.buffer.asUint8List(),
          width,
          height,
          canvasKit.AlphaType.Premul,
          canvasKit.ColorType.RGBA_8888,
          SkColorSpaceSRGB,
        );
      });
    }
  }

  CkImage.cloneOf(this.box) {
    if (assertionsEnabled) {
      _debugStackTrace = StackTrace.current;
    }
    box.ref(this);
  }

  @override
  StackTrace get debugStackTrace => _debugStackTrace!;
  StackTrace? _debugStackTrace;

  // Use a box because `SkImage` may be deleted either due to this object
  // being garbage-collected, or by an explicit call to [delete].
  late final SkiaObjectBox<CkImage, SkImage> box;

  /// The underlying Skia image object.
  ///
  /// Do not store the returned value. It is memory-managed by [SkiaObjectBox].
  /// Storing it may result in use-after-free bugs.
  SkImage get skImage => box.skiaObject;

  bool _disposed = false;

  bool _debugCheckIsNotDisposed() {
    assert(!_disposed, 'This image has been disposed.');
    return true;
  }

  @override
  void dispose() {
    assert(
      !_disposed,
      'Cannot dispose an image that has already been disposed.',
    );
    _disposed = true;
    box.unref(this);
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
  CkImage clone() {
    assert(_debugCheckIsNotDisposed());
    return CkImage.cloneOf(box);
  }

  @override
  bool isCloneOf(ui.Image other) {
    assert(_debugCheckIsNotDisposed());
    return other is CkImage && other.skImage.isAliasOf(skImage);
  }

  @override
  List<StackTrace>? debugGetOpenHandleStackTraces() =>
      box.debugGetStackTraces();

  @override
  int get width {
    assert(_debugCheckIsNotDisposed());
    return skImage.width();
  }

  @override
  int get height {
    assert(_debugCheckIsNotDisposed());
    return skImage.height();
  }

  @override
  Future<ByteData> toByteData({
    ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba,
  }) {
    assert(_debugCheckIsNotDisposed());
    return Future<ByteData>.value(_encodeImage(
      skImage: skImage,
      format: format,
      alphaType: canvasKit.AlphaType.Premul,
      colorType: canvasKit.ColorType.RGBA_8888,
      colorSpace: SkColorSpaceSRGB,
    ));
  }

  static ByteData _encodeImage({
    required SkImage skImage,
    required ui.ImageByteFormat format,
    required SkAlphaType alphaType,
    required SkColorType colorType,
    required ColorSpace colorSpace,
  }) {
    Uint8List bytes;

    if (format == ui.ImageByteFormat.rawRgba) {
      final SkImageInfo imageInfo = SkImageInfo(
        alphaType: alphaType,
        colorType: colorType,
        colorSpace: colorSpace,
        width: skImage.width(),
        height: skImage.height(),
      );
      bytes = skImage.readPixels(imageInfo, 0, 0);
    } else {
      final SkData skData = skImage.encodeToData(); //defaults to PNG 100%
      // make a copy that we can return
      bytes = Uint8List.fromList(canvasKit.getDataBytes(skData));
      skData.delete();
    }

    return bytes.buffer.asByteData(0, bytes.length);
  }

  @override
  String toString() {
    assert(_debugCheckIsNotDisposed());
    return '[$width\u00D7$height]';
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
