// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:ui/ui.dart' as ui;

import '../dom.dart';
import '../html_image_codec.dart';
import '../safe_browser_api.dart';
import '../util.dart';
import 'canvas.dart';
import 'canvaskit_api.dart';
import 'image_wasm_codecs.dart';
import 'image_web_codecs.dart';
import 'painting.dart';
import 'picture.dart';
import 'picture_recorder.dart';
import 'skia_object_cache.dart';

/// Instantiates a [ui.Codec] backed by an `SkAnimatedImage` from Skia.
FutureOr<ui.Codec> skiaInstantiateImageCodec(Uint8List list,
    [int? targetWidth, int? targetHeight]) {
  // If we have either a target width or target height, use canvaskit to decode.
  if (browserSupportsImageDecoder && (targetWidth == null && targetHeight == null)) {
    return CkBrowserImageDecoder.create(
      data: list,
      debugSource: 'encoded image bytes',
    );
  } else {
    return CkAnimatedImage.decodeFromBytes(list, 'encoded image bytes', targetWidth: targetWidth, targetHeight: targetHeight);
  }
}

void skiaDecodeImageFromPixels(
  Uint8List pixels,
  int width,
  int height,
  ui.PixelFormat format,
  ui.ImageDecoderCallback callback, {
  int? rowBytes,
  int? targetWidth,
  int? targetHeight,
  bool allowUpscaling = true,
}) {
  if (targetWidth != null) {
    assert(allowUpscaling || targetWidth <= width);
  }
  if (targetHeight != null) {
    assert(allowUpscaling || targetHeight <= height);
  }

  // Run in a timer to avoid janking the current frame by moving the decoding
  // work outside the frame event.
  Timer.run(() {
    final SkImage? skImage = canvasKit.MakeImage(
      SkImageInfo(
        width: width.toDouble(),
        height: height.toDouble(),
        colorType: format == ui.PixelFormat.rgba8888 ? canvasKit.ColorType.RGBA_8888 : canvasKit.ColorType.BGRA_8888,
        alphaType: canvasKit.AlphaType.Premul,
        colorSpace: SkColorSpaceSRGB,
      ),
      pixels,
      (rowBytes ?? 4 * width).toDouble(),
    );

    if (skImage == null) {
      domWindow.console.warn('Failed to create image from pixels.');
      return;
    }

    if (targetWidth != null || targetHeight != null) {
      if (!validUpscale(allowUpscaling, targetWidth, targetHeight, width, height)) {
        domWindow.console.warn('Cannot apply targetWidth/targetHeight when allowUpscaling is false.');
      } else {
        return callback(scaleImage(skImage, targetWidth, targetHeight));
      }
    }
    return callback(CkImage(skImage));
  });
}

// An invalid upscale happens when allowUpscaling is false AND either the given
// targetWidth is larger than the originalWidth OR the targetHeight is larger than originalHeight.
bool validUpscale(bool allowUpscaling, int? targetWidth, int? targetHeight, int originalWidth, int originalHeight) {
  if (allowUpscaling) {
    return true;
  }
  final bool targetWidthFits;
  final bool targetHeightFits;
  if (targetWidth != null) {
    targetWidthFits = targetWidth <= originalWidth;
  } else {
    targetWidthFits = true;
  }

  if (targetHeight != null) {
    targetHeightFits = targetHeight <= originalHeight;
  } else {
    targetHeightFits = true;
  }
  return targetWidthFits && targetHeightFits;
}

/// Creates a scaled [CkImage] from an [SkImage] by drawing the [SkImage] to a canvas.
///
/// This function will only be called if either a targetWidth or targetHeight is not null
///
/// If only one of targetWidth or  targetHeight are specified, the other
/// dimension will be scaled according to the aspect ratio of the supplied
/// dimension.
///
/// If either targetWidth or targetHeight is less than or equal to zero, it
/// will be treated as if it is null.
CkImage scaleImage(SkImage image, int? targetWidth, int? targetHeight) {
    assert(targetWidth != null || targetHeight != null);
    if (targetWidth != null && targetWidth <= 0) {
      targetWidth = null;
    }
    if (targetHeight != null && targetHeight <= 0) {
      targetHeight = null;
    }
    if (targetWidth == null && targetHeight != null) {
      targetWidth = (targetHeight * (image.width() / image.height())).round();
      targetHeight = targetHeight;
    } else if (targetHeight == null && targetWidth != null) {
      targetWidth = targetWidth;
      targetHeight = targetWidth ~/ (image.width() / image.height());
    }

    assert(targetWidth != null);
    assert(targetHeight != null);

    final CkPictureRecorder recorder = CkPictureRecorder();
    final CkCanvas canvas = recorder.beginRecording(ui.Rect.largest);

    canvas.drawImageRect(
      CkImage(image),
      ui.Rect.fromLTWH(0, 0, image.width(), image.height()),
      ui.Rect.fromLTWH(0, 0, targetWidth!.toDouble(), targetHeight!.toDouble()),
      CkPaint()
    );

    final CkPicture picture = recorder.endRecording();
    final ui.Image finalImage = picture.toImageSync(
      targetWidth,
      targetHeight
    );

    final CkImage ckImage = finalImage as CkImage;
    return ckImage;
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

/// Instantiates a [ui.Codec] backed by an `SkAnimatedImage` from Skia after
/// requesting from URI.
Future<ui.Codec> skiaInstantiateWebImageCodec(
    String url, WebOnlyImageCodecChunkCallback? chunkCallback) async {
  final Uint8List list = await fetchImage(url, chunkCallback);
  if (browserSupportsImageDecoder) {
    return CkBrowserImageDecoder.create(data: list, debugSource: url);
  } else {
    return CkAnimatedImage.decodeFromBytes(list, url);
  }
}

/// Sends a request to fetch image data.
Future<Uint8List> fetchImage(String url, WebOnlyImageCodecChunkCallback? chunkCallback) async {
  try {
    final HttpFetchResponse response = await httpFetch(url);
    final int? contentLength = response.contentLength;

    if (!response.hasPayload) {
      throw ImageCodecException(
        '$_kNetworkImageMessage\n'
        'Image URL: $url\n'
        'Server response code: ${response.status}',
      );
    }

    if (chunkCallback != null && contentLength != null) {
      return readChunked(response.payload, contentLength, chunkCallback);
    } else {
      return await response.asUint8List();
    }
  } on HttpFetchError catch (_) {
    throw ImageCodecException(
      '$_kNetworkImageMessage\n'
      'Image URL: $url\n'
      'Trying to load an image from another domain? Find answers at:\n'
      'https://flutter.dev/docs/development/platform-integration/web-images',
    );
  }
}

/// Reads the [payload] in chunks using the browser's Streams API
///
/// See: https://developer.mozilla.org/en-US/docs/Web/API/Streams_API
Future<Uint8List> readChunked(HttpFetchPayload payload, int contentLength, WebOnlyImageCodecChunkCallback chunkCallback) async {
  final Uint8List result = Uint8List(contentLength);
  int position = 0;
  int cumulativeBytesLoaded = 0;
  await payload.read<Uint8List>((Uint8List chunk) {
    cumulativeBytesLoaded += chunk.lengthInBytes;
    chunkCallback(cumulativeBytesLoaded, contentLength);
    result.setAll(position, chunk);
    position += chunk.lengthInBytes;
  });
  return result;
}

/// A [ui.Image] backed by an `SkImage` from Skia.
class CkImage implements ui.Image, StackTraceDebugger {
  CkImage(SkImage skImage, { this.videoFrame }) {
    _init();
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
      final int originalWidth = skImage.width().toInt();
      final int originalHeight = skImage.height().toInt();
      box = SkiaObjectBox<CkImage, SkImage>.resurrectable(this, skImage, () {
        final SkImage? skImage = canvasKit.MakeImage(
          SkImageInfo(
            alphaType: canvasKit.AlphaType.Premul,
            colorType: canvasKit.ColorType.RGBA_8888,
            colorSpace: SkColorSpaceSRGB,
            width: originalWidth.toDouble(),
            height: originalHeight.toDouble(),
          ),
          originalBytes.buffer.asUint8List(),
          (4 * originalWidth).toDouble(),
        );
        if (skImage == null) {
          throw ImageCodecException(
            'Failed to resurrect image from pixels.'
          );
        }
        return skImage;
      });
    }
  }

  CkImage.cloneOf(this.box, {this.videoFrame}) {
    _init();
    box.ref(this);
  }

  void _init() {
    if (assertionsEnabled) {
      _debugStackTrace = StackTrace.current;
    }
    ui.Image.onCreate?.call(this);
  }

  @override
  StackTrace get debugStackTrace => _debugStackTrace;
  late StackTrace _debugStackTrace;

  // Use a box because `SkImage` may be deleted either due to this object
  // being garbage-collected, or by an explicit call to [delete].
  late final SkiaObjectBox<CkImage, SkImage> box;

  /// For browsers that support `ImageDecoder` this field holds the video frame
  /// from which this image was created.
  ///
  /// Skia owns the video frame and will close it when it's no longer used.
  /// However, Flutter co-owns the [SkImage] and therefore it's safe to access
  /// the video frame until the image is [dispose]d of.
  VideoFrame? videoFrame;

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
    ui.Image.onDispose?.call(this);
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
    return CkImage.cloneOf(box, videoFrame: videoFrame?.clone());
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
    return skImage.width().toInt();
  }

  @override
  int get height {
    assert(_debugCheckIsNotDisposed());
    return skImage.height().toInt();
  }

  @override
  Future<ByteData> toByteData({
    ui.ImageByteFormat format = ui.ImageByteFormat.rawRgba,
  }) {
    assert(_debugCheckIsNotDisposed());
    // readPixelsFromVideoFrame currently does not convert I420, I444, I422
    // videoFrame formats to RGBA
    if (videoFrame != null && videoFrame!.format != 'I420' && videoFrame!.format != 'I444' && videoFrame!.format != 'I422') {
      return readPixelsFromVideoFrame(videoFrame!, format);
    } else {
      return _readPixelsFromSkImage(format);
    }
  }

  @override
  ui.ColorSpace get colorSpace => ui.ColorSpace.sRGB;

  Future<ByteData> _readPixelsFromSkImage(ui.ImageByteFormat format) {
    final SkAlphaType alphaType = format == ui.ImageByteFormat.rawStraightRgba ? canvasKit.AlphaType.Unpremul : canvasKit.AlphaType.Premul;
    final ByteData? data = _encodeImage(
      skImage: skImage,
      format: format,
      alphaType: alphaType,
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

    if (format == ui.ImageByteFormat.rawRgba || format == ui.ImageByteFormat.rawStraightRgba) {
      final SkImageInfo imageInfo = SkImageInfo(
        alphaType: alphaType,
        colorType: colorType,
        colorSpace: colorSpace,
        width: skImage.width(),
        height: skImage.height(),
      );
      bytes = skImage.readPixels(0, 0, imageInfo);
    } else {
      bytes = skImage.encodeToBytes(); // defaults to PNG 100%
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
  AnimatedImageFrameInfo(this._duration, this._image);

  final Duration _duration;
  final CkImage _image;

  @override
  Duration get duration => _duration;

  @override
  ui.Image get image => _image;
}
