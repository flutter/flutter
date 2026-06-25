// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

/// An image decoder that delegates to the browser's modern native `ImageDecoder` API.
///
/// This decoder is highly efficient as it offloads the decoding work (including
/// frame extraction and progressive stream processing) to the browser's underlying
/// image decoding subsystem, running off the main thread where possible.
///
/// Under the hood, it configures the native decoder to use premultiplied alpha and
/// default color space conversion, aligning with Flutter's rendering expectations.
class BrowserImageDecoder {
  BrowserImageDecoder({
    required this.contentType,
    required this.dataSource,
    required this.debugSource,
  });

  final String contentType;
  final JSAny dataSource;
  final String debugSource;

  int frameCount = 0;
  int repetitionCount = 0;

  /// Whether this decoder has been disposed of.
  ///
  /// Once this turns true it stays true forever, and this decoder becomes
  /// unusable.
  bool _isDisposed = false;

  final List<void Function()> _onDisposeCallbacks = [];

  void addDisposeCallback(void Function() callback) {
    if (_isDisposed) {
      callback();
    } else {
      _onDisposeCallbacks.add(callback);
    }
  }

  void dispose() {
    _isDisposed = true;
    final errors = <Object>[];
    try {
      for (final void Function() callback in _onDisposeCallbacks) {
        try {
          callback();
        } catch (e) {
          errors.add(e);
        }
      }
    } finally {
      _onDisposeCallbacks.clear();
      _cachedWebDecoder?.close();
      _cachedWebDecoder = null;

      if (errors.isNotEmpty) {
        printWarning(
          'Failed to execute ${errors.length} dispose callback(s) in BrowserImageDecoder: '
          '${errors.join(', ')}',
        );
      }
    }
  }

  /// The index of the frame that will be decoded on the next call of [getNextFrame];
  int _nextFrameIndex = 0;

  /// Creating a new decoder is expensive, so we cache the decoder for reuse.
  ///
  // TODO(jacksongardner): Evaluate whether this complexity is necessary.
  // See https://github.com/flutter/flutter/issues/127548
  ImageDecoder? _cachedWebDecoder;

  /// The underlying image decoder used to decode images.
  ///
  /// This value is volatile. It may be closed or become null any time.
  ///
  ///
  /// This is only meant to be used in tests.
  @visibleForTesting
  ImageDecoder? get debugCachedWebDecoder => _cachedWebDecoder;

  Future<void> initialize() async {
    final ImageDecoder webDecoder = await _createWebDecoder();
    if (_isDisposed) {
      webDecoder.close();
    } else {
      _cachedWebDecoder = webDecoder;
    }
  }

  Future<ImageDecoder> _createWebDecoder() async {
    try {
      final webDecoder = ImageDecoder(
        ImageDecoderOptions(
          type: contentType,
          data: dataSource,

          // Flutter always uses premultiplied alpha when decoding.
          premultiplyAlpha: 'premultiply',
          // "default" gives the browser the liberty to convert to display-appropriate
          // color space, typically SRGB, which is what we want.
          colorSpaceConversion: 'default',

          // Flutter doesn't give the developer a way to customize this, so if this
          // is an animated image we should prefer the animated track.
          preferAnimation: true,
        ),
      );

      await webDecoder.tracks.ready.toDart;

      // Flutter doesn't have an API for progressive loading of images, so we
      // wait until the image is fully decoded.
      await webDecoder.completed.toDart;
      frameCount = webDecoder.tracks.selectedTrack!.frameCount.toInt();

      // We coerce the DOM's `repetitionCount` into an int by explicitly
      // handling `infinity`. Note: This will still throw if the DOM returns a
      // `NaN`.
      final double rawRepetitionCount = webDecoder.tracks.selectedTrack!.repetitionCount;
      repetitionCount = rawRepetitionCount == double.infinity ? -1 : rawRepetitionCount.toInt();

      return webDecoder;
    } catch (error) {
      // TODO(srujzs): Replace this with `error.isJSAny` when we have that API
      // in `dart:js_interop`.
      // https://github.com/dart-lang/sdk/issues/56905
      // ignore: invalid_runtime_check_with_js_interop_types
      if (error is JSAny && error.isA<DomException>()) {
        if ((error as DomException).name == DomException.notSupported) {
          throw ImageCodecException(
            "Image file format ($contentType) is not supported by this browser's ImageDecoder API.\n"
            'Image source: $debugSource',
          );
        }
      }
      throw ImageCodecException(
        "Failed to decode image using the browser's ImageDecoder API.\n"
        'Image source: $debugSource\n'
        'Original browser error: $error',
      );
    }
  }

  Future<VideoFrame> getNextFrame() async {
    if (_isDisposed) {
      throw ImageCodecException(
        'Cannot decode image. The image decoder has been disposed.\n'
        'Image source: $debugSource',
      );
    }
    final ImageDecoder? webDecoder = _cachedWebDecoder;
    if (webDecoder == null) {
      throw ImageCodecException(
        'Cannot decode image. The image decoder has not been initialized.\n'
        'Image source: $debugSource',
      );
    }

    final DecodeResult result = await webDecoder
        // Using `completeFramesOnly: false` to get frames even from partially decoded images.
        // Typically, this wouldn't work well in Flutter because Flutter doesn't support progressive
        // image rendering. So this could result in frames being rendered at lower quality than
        // expected.
        //
        // However, since we wait for the entire image to be decoded using [webDecoder.completed],
        // this ends up being a non-issue in practice.
        //
        // For more details, see: https://issues.chromium.org/issues/456445108
        .decode(DecodeOptions(frameIndex: _nextFrameIndex, completeFramesOnly: false))
        .toDart;
    if (_isDisposed) {
      result.image.close();
      throw ImageCodecException(
        'Cannot decode image. The image decoder has been disposed.\n'
        'Image source: $debugSource',
      );
    }
    final VideoFrame frame = result.image;
    _nextFrameIndex = (_nextFrameIndex + 1) % frameCount;
    return frame;
  }
}

/// Data for a single frame of an animated image.
class AnimatedImageFrameInfo implements ui.FrameInfo {
  AnimatedImageFrameInfo(this.duration, this.image);

  @override
  final Duration duration;

  @override
  final ui.Image image;
}

ImageType tryDetectImageType(Uint8List data, String debugSource) {
  // ImageDecoder does not detect image type automatically. It requires us to
  // tell it what the image type is.
  final ImageType? imageType = detectImageType(data);

  if (imageType == null) {
    final String fileHeader;
    if (data.isNotEmpty) {
      fileHeader = '[${bytesToHexString(data.sublist(0, math.min(10, data.length)))}]';
    } else {
      fileHeader = 'empty';
    }
    throw ImageCodecException(
      'Failed to detect image file format using the file header.\n'
      'File header was $fileHeader.\n'
      'Image source: $debugSource',
    );
  }
  return imageType;
}

/// Duplicates the network response stream to enable parallel progress tracking
/// and native image decoding.
///
/// In the web platform, a `ReadableStream` (like the HTTP response body) can only
/// have a single active reader at a time. If we read the stream in Dart to track
/// download progress (triggering [chunkCallback]), we lock the stream and prevent
/// the browser's native `ImageDecoder` from reading and decoding it.
///
/// To solve this, we use `body.tee()` to duplicate the stream at the browser level
/// into two independent, concurrent branches:
/// 1. `progressStream`: Read chunk-by-chunk in Dart to calculate cumulative bytes loaded
///    and invoke the progress callback.
/// 2. `dataStream`: Passed directly to the native `BrowserImageDecoder` for streaming decode.
///
/// We register a cancel callback in [onDisposeCallbacks] so that if the decoder is
/// disposed before the download completes, the progress reader is cancelled to prevent
/// dangling resource locks.
Future<DomReadableStream> handleProgressAndGetStream(
  DomResponse response,
  ui_web.ImageCodecChunkCallback? chunkCallback, [
  List<void Function()>? onDisposeCallbacks,
]) async {
  final DomReadableStream body = response.body;
  final String? contentLengthHeader = response.headers.get('Content-Length');
  final int? contentLength = contentLengthHeader != null ? int.tryParse(contentLengthHeader) : null;

  if (chunkCallback == null || contentLength == null) {
    return body;
  }

  final List<DomReadableStream> streams = body.tee().toDart.cast<DomReadableStream>();
  final DomReadableStream progressStream = streams[0];
  final DomReadableStream dataStream = streams[1];

  final DomStreamReader reader = progressStream.getReader();
  onDisposeCallbacks?.add(() {
    reader.cancel();
  });

  unawaited(() async {
    try {
      var cumulativeBytesLoaded = 0;
      while (true) {
        final DomStreamChunk chunk = await reader.read();
        if (chunk.done) {
          break;
        }
        final JSAny? value = chunk.value;
        if (value != null) {
          final array = value as JSUint8Array;
          cumulativeBytesLoaded += array.length;
          chunkCallback(cumulativeBytesLoaded, contentLength);
        }
      }
    } catch (e) {
      // Ignore progress stream reading errors.
    }
  }());

  return dataStream;
}

/// Consolidates the image decoding and routing strategy for in-memory byte arrays.
///
/// This function implements a tiered routing strategy to select the most efficient
/// decoding pipeline:
///
/// - **Modern Browser Path (`BrowserImageDecoder`):** If the browser supports the
///    native `ImageDecoder` API, we sniff the byte header to identify the format's
///    MIME type and delegate decoding to `BrowserImageDecoder`.
/// - **Legacy Browser Path (`createImageBitmap`):** If the native `ImageDecoder`
///    is unsupported (e.g. older browsers or Safari/Firefox fallback), but the image is
///    static (non-animated) and `createImageBitmap` is available, we load the bytes
///    as a Blob and decode/resize natively via the browser's asynchronous bitmap APIs.
/// - **Skia Fallback (`BackendAnimatedImage`):** If the browser APIs are unsupported or
///    disabled in tests, we route the raw bytes to the active backend renderer
///    (CanvasKit or Skwasm) to be decoded using Skia's C++ WASM or FFI image codecs.
///    *Note:* We aim to compile Skia without built-in image decoders where possible to
///    minimize the WebAssembly bundle size. Therefore, we prioritize native browser
///    decoders and only route to the Skia/Skwasm backend when necessary.
Future<ui.Codec> engineInstantiateImageCodec(
  Uint8List list, {
  int? targetWidth,
  int? targetHeight,
  bool allowUpscaling = true,
}) async {
  final ImageType imageType = tryDetectImageType(list, 'encoded image bytes');

  if (browserSupportsImageDecoder) {
    final decoder = BrowserImageDecoder(
      contentType: imageType.mimeType,
      dataSource: list.toJS,
      debugSource: 'encoded image bytes',
    );
    await decoder.initialize();
    return EngineCodec.browser(
      decoder,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      allowUpscaling: allowUpscaling,
    );
  } else {
    if (!imageType.isAnimated && browserSupportsCreateImageBitmap) {
      final DomBlob blob = createDomBlob(<ByteBuffer>[list.buffer]);
      final DomImageBitmap originalBitmap = await createImageBitmap(blob);
      final int originalWidth = originalBitmap.width;
      final int originalHeight = originalBitmap.height;
      final BitmapSize? scaledSize = scaledImageSize(
        originalWidth,
        originalHeight,
        targetWidth,
        targetHeight,
      );

      final int destWidth = scaledSize?.width ?? originalWidth;
      final int destHeight = scaledSize?.height ?? originalHeight;

      var bitmap = originalBitmap;
      if (scaledSize != null) {
        if (allowUpscaling || (destWidth <= originalWidth && destHeight <= originalHeight)) {
          bitmap = await scaleImageSource(
            originalBitmap,
            originalWidth,
            originalHeight,
            destWidth,
            destHeight,
          );
          originalBitmap.close();
        }
      }

      final ImageSource source = ImageBitmapImageSource(bitmap);
      return EngineCodec.staticImage(
        source,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        allowUpscaling: allowUpscaling,
      );
    } else {
      final BackendAnimatedImage backendAnimated = renderer.createAnimatedImage(
        list,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      return EngineCodec.skia(
        backendAnimated,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        allowUpscaling: allowUpscaling,
      );
    }
  }
}

const Set<String> _knownImageMimeTypes = <String>{
  'image/png',
  'image/jpeg',
  'image/jpg',
  'image/gif',
  'image/webp',
  'image/bmp',
  'image/x-icon',
  'image/vnd.microsoft.icon',
  'image/apng',
  'image/avif',
};

/// Parses and cleans the HTTP Content-Type header, returning the MIME type without parameters.
///
/// Returns null if [contentTypeHeader] is null.
String? parseMimeType(String? contentTypeHeader) {
  if (contentTypeHeader == null) {
    return null;
  }
  final int semicolonIndex = contentTypeHeader.indexOf(';');
  if (semicolonIndex != -1) {
    return contentTypeHeader.substring(0, semicolonIndex).trim().toLowerCase();
  }
  return contentTypeHeader.trim().toLowerCase();
}

/// Consolidates the progressive network image decoding and routing strategy.
///
/// This function implements the tiered network routing strategy designed to maximize
/// streaming performance and minimize memory overhead:
///
/// - **Streaming Decode (Fast Path):** We inspect the HTTP `Content-Type` header
///    from the response. If it is a known static or animated image format, and the
///    browser supports `ImageDecoder`, we stream the response body directly to the
///    native decoder without waiting for the full download. If a progress [chunkCallback]
///    is provided, we use `handleProgressAndGetStream` (`ReadableStream.tee()`) to
///    concurrently track progress and stream decode.
/// - **Buffered Decode (Fallback Path):** If the `Content-Type` header is missing,
///    generic (e.g. `application/octet-stream`), or if the browser lacks native
///    `ImageDecoder` support:
///    - We download the entire response as an `arrayBuffer`.
///    - We sniff the binary headers to detect the image format.
///    - We then fall back to the tiered in-memory routing strategy (using the browser's
///      `ImageDecoder` with the buffer, `createImageBitmap`, or Skia C++/WASM decoders).
Future<ui.Codec> engineInstantiateImageCodecFromUrl(
  Uri uri, {
  ui_web.ImageCodecChunkCallback? chunkCallback,
}) async {
  final url = uri.toString();
  final DomResponse response = await rawHttpGet(url);

  if (response.status < 200 || response.status >= 300) {
    throw ImageCodecException(
      'Failed to load network image.\n'
      'Image URL: $url\n'
      'Server response code: ${response.status}',
    );
  }

  final String? cleanContentType = parseMimeType(response.headers.get('Content-Type'));
  final bool isKnownImageMimeType =
      cleanContentType != null && _knownImageMimeTypes.contains(cleanContentType);

  if (browserSupportsImageDecoder && isKnownImageMimeType) {
    final List<void Function()> onDisposeCallbacks = [];
    final DomReadableStream stream = await handleProgressAndGetStream(
      response,
      chunkCallback,
      onDisposeCallbacks,
    );
    final decoder = BrowserImageDecoder(
      contentType: cleanContentType,
      dataSource: stream,
      debugSource: url,
    );
    onDisposeCallbacks.forEach(decoder.addDisposeCallback);
    await decoder.initialize();
    return EngineCodec.browser(decoder);
  } else {
    final ByteBuffer buffer = await response.arrayBuffer();
    final Uint8List list = buffer.asUint8List();
    final ImageType imageType = tryDetectImageType(list, url);

    if (chunkCallback != null) {
      chunkCallback(list.length, list.length);
    }

    if (browserSupportsImageDecoder) {
      final decoder = BrowserImageDecoder(
        contentType: imageType.mimeType,
        dataSource: list.toJS,
        debugSource: url,
      );
      await decoder.initialize();
      return EngineCodec.browser(decoder);
    } else if (!imageType.isAnimated && browserSupportsCreateImageBitmap) {
      final DomBlob blob = createDomBlob(<ByteBuffer>[buffer]);
      final DomImageBitmap bitmap = await createImageBitmap(blob);
      final ImageSource source = ImageBitmapImageSource(bitmap);
      return EngineCodec.staticImage(source);
    } else {
      final BackendAnimatedImage backendAnimated = renderer.createAnimatedImage(list);
      return EngineCodec.skia(backendAnimated);
    }
  }
}

BitmapSize? scaledImageSize(int width, int height, int? targetWidth, int? targetHeight) {
  if (targetWidth == width && targetHeight == height) {
    return null;
  }
  if (targetWidth == null) {
    if (targetHeight == null || targetHeight == height) {
      return null;
    }
    targetWidth = (width * targetHeight / height).round();
  } else if (targetHeight == null) {
    if (targetWidth == width) {
      return null;
    }
    targetHeight = (height * targetWidth / width).round();
  }
  return BitmapSize(targetWidth, targetHeight);
}

/// Performs a fallback image scaling operation on the frontend using a canvas.
///
/// This is used as a fallback when the native backend decoder (specifically
/// CanvasKit's WASM animated image decoder) does not support resizing/scaling during
/// the decode phase.
///
/// It draws the original [image] onto a temporary [ui.Canvas] at the [scaledSize]
/// using [ui.PictureRecorder], and compiles the recording into a new scaled [ui.Image]
/// via `toImageSync`. The original full-size [image] is eagerly disposed of immediately
/// after to prevent memory spikes.
ui.Image scaleImageIfNeeded(
  ui.Image image, {
  int? targetWidth,
  int? targetHeight,
  bool allowUpscaling = true,
}) {
  final int width = image.width;
  final int height = image.height;
  final BitmapSize? scaledSize = scaledImageSize(width, height, targetWidth, targetHeight);
  if (scaledSize == null) {
    return image;
  }
  if (!allowUpscaling && (scaledSize.width > width || scaledSize.height > height)) {
    return image;
  }

  final outputRect = ui.Rect.fromLTWH(
    0,
    0,
    scaledSize.width.toDouble(),
    scaledSize.height.toDouble(),
  );
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, outputRect);

  canvas.drawImageRect(
    image,
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    outputRect,
    ui.Paint(),
  );
  final ui.Picture picture = recorder.endRecording();
  final ui.Image finalImage = picture.toImageSync(scaledSize.width, scaledSize.height);
  picture.dispose();
  image.dispose();
  return finalImage;
}

class ImageCodecException implements Exception {
  ImageCodecException(this._message);

  final String _message;

  @override
  String toString() => 'ImageCodecException: $_message';
}

Future<DomImageBitmap> scaleImageSource(
  DomCanvasImageSource source,
  int originalWidth,
  int originalHeight,
  int destWidth,
  int destHeight,
) async {
  return createImageBitmap(
    source,
    options: ImageBitmapOptions(
      resizeWidth: destWidth,
      resizeHeight: destHeight,
      resizeQuality: 'high',
    ),
  );
}
