// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12
part of engine;

/// Instantiates a [ui.Codec] backed by an `SkAnimatedImage` from Skia.
void skiaInstantiateImageCodec(Uint8List list, Callback<ui.Codec> callback,
    [int? width, int? height, int? format, int? rowBytes]) {
  final CkAnimatedImage codec = CkAnimatedImage.decodeFromBytes(list);
  callback(codec);
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
class CkAnimatedImage implements ui.Codec, StackTraceDebugger {
  /// Decodes an image from a list of encoded bytes.
  CkAnimatedImage.decodeFromBytes(Uint8List bytes) {
    if (assertionsEnabled) {
      _debugStackTrace = StackTrace.current;
    }
    final SkAnimatedImage skAnimatedImage =
        canvasKit.MakeAnimatedImageFromEncoded(bytes);
    box = SkiaObjectBox<CkAnimatedImage, SkAnimatedImage>(this, skAnimatedImage);
  }

  // Use a box because `CkAnimatedImage` may be deleted either due to this
  // object being garbage-collected, or by an explicit call to [dispose].
  late final SkiaObjectBox<CkAnimatedImage, SkAnimatedImage> box;

  @override
  StackTrace get debugStackTrace => _debugStackTrace!;
  StackTrace? _debugStackTrace;

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

    // This image is no longer usable. Bump the ref count.
    box.unref(this);
  }

  @override
  int get frameCount {
    assert(_debugCheckIsNotDisposed());
    return box.skiaObject.getFrameCount();
  }

  @override
  int get repetitionCount {
    assert(_debugCheckIsNotDisposed());
    return box.skiaObject.getRepetitionCount();
  }

  @override
  Future<ui.FrameInfo> getNextFrame() {
    assert(_debugCheckIsNotDisposed());
    final int durationMillis = box.skiaObject.decodeNextFrame();
    final Duration duration = Duration(milliseconds: durationMillis);
    final CkImage image = CkImage(box.skiaObject.getCurrentFrame());
    return Future<ui.FrameInfo>.value(AnimatedImageFrameInfo(duration, image));
  }
}

/// A [ui.Image] backed by an `SkImage` from Skia.
class CkImage implements ui.Image, StackTraceDebugger {
  CkImage(SkImage skImage) {
    if (assertionsEnabled) {
      _debugStackTrace = StackTrace.current;
    }
    box = SkiaObjectBox<CkImage, SkImage>(this, skImage);
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
  ui.Image clone() {
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
  Future<ByteData> toByteData(
      {ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba}) {
    assert(_debugCheckIsNotDisposed());
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
      bytes = Uint8List.fromList(canvasKit.getDataBytes(skData));
      skData.delete();
    }

    final ByteData data = bytes.buffer.asByteData(0, bytes.length);
    return Future<ByteData>.value(data);
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
