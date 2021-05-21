// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:ui/src/engine.dart' show WebOnlyImageCodecChunkCallback;
import 'package:ui/ui.dart' as ui;

import '../util.dart';
import 'canvaskit_api.dart';
import 'skia_object_cache.dart';

/// Instantiates a [ui.Codec] backed by an `SkAnimatedImage` from Skia.
ui.Codec skiaInstantiateImageCodec(Uint8List list,
    [int? width, int? height, int? format, int? rowBytes]) {
  return CkAnimatedImage.decodeFromBytes(list, 'encoded image bytes');
}

/// Thrown when the web engine fails to decode an image, either due to a
/// network issue, corrupted image contents, or missing codec.
class ImageCodecException implements Exception {
  ImageCodecException(this._message);

  final String _message;

  @override
  String toString() => 'ImageCodecException: $_message';
}

const String _kNetworkImageMessage = 'Failed to load network image.';

typedef HttpRequestFactory = html.HttpRequest Function();
HttpRequestFactory httpRequestFactory = () => html.HttpRequest();
void debugRestoreHttpRequestFactory() {
  httpRequestFactory = () => html.HttpRequest();
}

/// Instantiates a [ui.Codec] backed by an `SkAnimatedImage` from Skia after
/// requesting from URI.
Future<ui.Codec> skiaInstantiateWebImageCodec(
    String url, WebOnlyImageCodecChunkCallback? chunkCallback) {
  Completer<ui.Codec> completer = Completer<ui.Codec>();

  final html.HttpRequest request = httpRequestFactory();
  request.open('GET', url, async: true);
  request.responseType = 'arraybuffer';
  if (chunkCallback != null) {
    request.onProgress.listen((html.ProgressEvent event) {
      chunkCallback.call(event.loaded!, event.total!);
    });
  }

  request.onError.listen((html.ProgressEvent event) {
    completer.completeError(ImageCodecException('$_kNetworkImageMessage\n'
        'Image URL: $url\n'
        'Trying to load an image from another domain? Find answers at:\n'
        'https://flutter.dev/docs/development/platform-integration/web-images'));
  });

  request.onLoad.listen((html.ProgressEvent event) {
    final int status = request.status!;
    final bool accepted = status >= 200 && status < 300;
    final bool fileUri = status == 0; // file:// URIs have status of 0.
    final bool notModified = status == 304;
    final bool unknownRedirect = status > 307 && status < 400;
    final bool success = accepted || fileUri || notModified || unknownRedirect;

    if (!success) {
      completer.completeError(
        ImageCodecException('$_kNetworkImageMessage\n'
            'Image URL: $url\n'
            'Server response code: $status'),
      );
      return;
    }

    try {
      final Uint8List list =
          new Uint8List.view((request.response as ByteBuffer));
      final CkAnimatedImage codec = CkAnimatedImage.decodeFromBytes(list, url);
      completer.complete(codec);
    } catch (error, stackTrace) {
      completer.completeError(error, stackTrace);
    }
  });

  request.send();
  return completer.future;
}

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
      final ByteData? originalBytes = _encodeImage(
        skImage: skImage,
        format: ui.ImageByteFormat.rawRgba,
        alphaType: canvasKit.AlphaType.Premul,
        colorType: canvasKit.ColorType.RGBA_8888,
        colorSpace: SkColorSpaceSRGB,
      );
      if (originalBytes == null) {
        printWarning('Unable to encode image to bytes. We will not '
            'be able to resurrect it once it has been garbage collected.');
        return;
      }
      final int originalWidth = skImage.width();
      final int originalHeight = skImage.height();
      box = SkiaObjectBox<CkImage, SkImage>.resurrectable(this, skImage, () {
        return canvasKit.MakeImage(
            SkImageInfo(
              alphaType: canvasKit.AlphaType.Premul,
              colorType: canvasKit.ColorType.RGBA_8888,
              colorSpace: SkColorSpaceSRGB,
              width: originalWidth,
              height: originalHeight,
            ),
            originalBytes.buffer.asUint8List(),
            4 * originalWidth);
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
    ByteData? data = _encodeImage(
      skImage: skImage,
      format: format,
      alphaType: canvasKit.AlphaType.Premul,
      colorType: canvasKit.ColorType.RGBA_8888,
      colorSpace: SkColorSpaceSRGB,
    );
    if (data == null) {
      return Future<ByteData>.error('Failed to encode the image into bytes.');
    } else {
      return Future<ByteData>.value(data);
    }
  }

  static ByteData? _encodeImage({
    required SkImage skImage,
    required ui.ImageByteFormat format,
    required SkAlphaType alphaType,
    required SkColorType colorType,
    required ColorSpace colorSpace,
  }) {
    Uint8List? bytes;

    if (format == ui.ImageByteFormat.rawRgba) {
      final SkImageInfo imageInfo = SkImageInfo(
        alphaType: alphaType,
        colorType: colorType,
        colorSpace: colorSpace,
        width: skImage.width(),
        height: skImage.height(),
      );
      bytes = skImage.readPixels(0, 0, imageInfo);
    } else {
      bytes = skImage.encodeToBytes(); //defaults to PNG 100%
    }

    return bytes?.buffer.asByteData(0, bytes.length);
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
