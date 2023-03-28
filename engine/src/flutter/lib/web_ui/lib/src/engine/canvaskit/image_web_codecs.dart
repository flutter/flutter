// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Uses the `ImageDecoder` class supplied by the browser.
//
// See also:
//
//  * `image_wasm_codecs.dart`, which uses codecs supplied by the CanvasKit WASM bundle.

import 'dart:async';
import 'dart:convert' show base64;
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:ui/ui.dart' as ui;

import '../alarm_clock.dart';
import '../dom.dart';
import '../safe_browser_api.dart';
import '../util.dart';
import 'canvaskit_api.dart';
import 'image.dart';

Duration _kDefaultWebDecoderExpireDuration = const Duration(seconds: 3);
Duration _kWebDecoderExpireDuration = _kDefaultWebDecoderExpireDuration;

/// Overrides the inactivity duration after which the web decoder is closed.
///
/// This should only be used in tests.
void debugOverrideWebDecoderExpireDuration(Duration override) {
  _kWebDecoderExpireDuration = override;
}

/// Restores the web decoder inactivity expiry duration to its original value.
///
/// This should only be used in tests.
void debugRestoreWebDecoderExpireDuration() {
  _kWebDecoderExpireDuration = _kDefaultWebDecoderExpireDuration;
}

/// Image decoder backed by the browser's `ImageDecoder`.
class CkBrowserImageDecoder implements ui.Codec {
  CkBrowserImageDecoder._({
    required this.contentType,
    required this.data,
    required this.debugSource,
  });

  static Future<CkBrowserImageDecoder> create({
    required Uint8List data,
    required String debugSource,
  }) async {
    // ImageDecoder does not detect image type automatically. It requires us to
    // tell it what the image type is.
    final String? contentType = detectContentType(data);

    if (contentType == null) {
      final String fileHeader;
      if (data.isNotEmpty) {
        fileHeader = '[${bytesToHexString(data.sublist(0, math.min(10, data.length)))}]';
      } else {
        fileHeader = 'empty';
      }
      throw ImageCodecException(
        'Failed to detect image file format using the file header.\n'
        'File header was $fileHeader.\n'
        'Image source: $debugSource'
      );
    }

    final CkBrowserImageDecoder decoder = CkBrowserImageDecoder._(
      contentType: contentType,
      data: data,
      debugSource: debugSource,
    );

    // Call once to initialize the decoder and populate late fields.
    await decoder._getOrCreateWebDecoder();
    return decoder;
  }

  final String contentType;
  final Uint8List data;
  final String debugSource;

  @override
  late int frameCount;

  @override
  late int repetitionCount;

  /// Whether this decoder has been disposed of.
  ///
  /// Once this turns true it stays true forever, and this decoder becomes
  /// unusable.
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;

    // This releases all resources, including any currently running decoding work.
    _cachedWebDecoder?.close();
    _cachedWebDecoder = null;
  }

  void _debugCheckNotDisposed() {
    assert(
      !_isDisposed,
      'Cannot use this image decoder. It has been disposed of.'
    );
  }

  /// The index of the frame that will be decoded on the next call of [getNextFrame];
  int _nextFrameIndex = 0;

  /// Creating a new decoder is expensive, so we cache the decoder for reuse.
  ///
  /// This decoder is closed and the field is nulled out after some time of
  /// inactivity.
  ImageDecoder? _cachedWebDecoder;

  /// The underlying image decoder used to decode images.
  ///
  /// This value is volatile. It may be closed or become null any time.
  ///
  ///
  /// This is only meant to be used in tests.
  @visibleForTesting
  ImageDecoder? get debugCachedWebDecoder => _cachedWebDecoder;

  final AlarmClock _cacheExpirationClock = AlarmClock(() => DateTime.now());

  Future<ImageDecoder> _getOrCreateWebDecoder() async {
    if (_cachedWebDecoder != null) {
      // Give the cached value some time for reuse, e.g. if the image is
      // currently animating.
      _cacheExpirationClock.datetime = DateTime.now().add(_kWebDecoderExpireDuration);
      return _cachedWebDecoder!;
    }

    // Null out the callback so the clock doesn't try to expire the decoder
    // while it's initializing. There's no way to tell how long the
    // initialization will take place. We just let it proceed at its own pace.
    _cacheExpirationClock.callback = null;
    try {
      final ImageDecoder webDecoder = ImageDecoder(ImageDecoderOptions(
        type: contentType.toJS,
        data: data.toJS,

        // Flutter always uses premultiplied alpha when decoding.
        premultiplyAlpha: 'premultiply'.toJS,
        // "default" gives the browser the liberty to convert to display-appropriate
        // color space, typically SRGB, which is what we want.
        colorSpaceConversion: 'default'.toJS,

        // Flutter doesn't give the developer a way to customize this, so if this
        // is an animated image we should prefer the animated track.
        preferAnimation: true.toJS,
      ));

      await promiseToFuture<void>(webDecoder.tracks.ready);

      // Flutter doesn't have an API for progressive loading of images, so we
      // wait until the image is fully decoded.
      // package:js bindings don't work with getters that return a Promise, which
      // is why js_util is used instead.
      await promiseToFuture<void>(getJsProperty(webDecoder, 'completed'));
      frameCount = webDecoder.tracks.selectedTrack!.frameCount.toInt();

      // We coerce the DOM's `repetitionCount` into an int by explicitly
      // handling `infinity`. Note: This will still throw if the DOM returns a
      // `NaN.
      final double rawRepetitionCount = webDecoder.tracks.selectedTrack!.repetitionCount;
      repetitionCount = rawRepetitionCount == double.infinity ? -1 :
          rawRepetitionCount.toInt();
      _cachedWebDecoder = webDecoder;

      // Expire the decoder if it's not used for several seconds. If the image is
      // not animated, it could mean that the framework has cached the frame and
      // therefore doesn't need the decoder any more, or it could mean that the
      // widget is gone and it's time to collect resources associated with it.
      // If it's an animated image it means the animation has stopped, otherwise
      // we'd see calls to [getNextFrame] which would update the expiry date on
      // the decoder. If the animation is stopped for long enough, it's better
      // to collect resources. If and when the animation resumes, a new decoder
      // will be instantiated.
      _cacheExpirationClock.callback = () {
        _cachedWebDecoder?.close();
        _cachedWebDecoder = null;
        _cacheExpirationClock.callback = null;
      };
      _cacheExpirationClock.datetime = DateTime.now().add(_kWebDecoderExpireDuration);

      return webDecoder;
    } catch (error) {
      if (domInstanceOfString(error, 'DOMException')) {
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
        'Original browser error: $error'
      );
    }
  }

  @override
  Future<ui.FrameInfo> getNextFrame() async {
    _debugCheckNotDisposed();
    final ImageDecoder webDecoder = await _getOrCreateWebDecoder();
    final DecodeResult result = await promiseToFuture<DecodeResult>(
      webDecoder.decode(DecodeOptions(frameIndex: _nextFrameIndex.toJS)),
    );
    final VideoFrame frame = result.image;
    _nextFrameIndex = (_nextFrameIndex + 1) % frameCount;

    final SkImage? skImage = canvasKit.MakeLazyImageFromTextureSource(
      frame,
      SkPartialImageInfo(
        alphaType: canvasKit.AlphaType.Premul,
        colorType: canvasKit.ColorType.RGBA_8888,
        colorSpace: SkColorSpaceSRGB,
        width: frame.displayWidth,
        height: frame.displayHeight,
      ),
    );

    // Duration can be null if the image is not animated. However, Flutter
    // requires a non-null value. 0 indicates that the frame is meant to be
    // displayed indefinitely, which is fine for a static image.
    final Duration duration = Duration(microseconds: frame.duration?.toInt() ?? 0);

    if (skImage == null) {
      throw ImageCodecException(
        "Failed to create image from pixel data decoded using the browser's ImageDecoder.",
      );
    }

    final CkImage image = CkImage(skImage, videoFrame: frame);
    return Future<ui.FrameInfo>.value(AnimatedImageFrameInfo(duration, image));
  }
}

/// Represents an image file format, such as PNG or JPEG.
class ImageFileFormat {
  const ImageFileFormat(this.header, this.contentType);

  /// First few bytes in the file that uniquely identify the image file format.
  ///
  /// Null elements are treated as wildcard values and are not checked. This is
  /// used to detect formats whose header is split up into multiple disjoint
  /// parts, such that the first part is not unique enough to identify the
  /// format. For example, without this, WebP may be confused with .ani
  /// (animated cursor), .cda, and other formats that start with "RIFF".
  final List<int?> header;

  /// The value that's passed as [_ImageDecoderOptions.type].
  ///
  /// The server typically also uses this value as the "Content-Type" header,
  /// but servers are not required to correctly detect the type. This value
  /// is also known as MIME type.
  final String contentType;

  /// All image file formats known to the Flutter Web engine.
  ///
  /// This list may need to be changed as browsers adopt new formats, and drop
  /// support for obsolete ones.
  ///
  /// This list is checked linearly from top to bottom when detecting an image
  /// type. It should therefore contain the most popular file formats at the
  /// top, and less popular towards the bottom.
  static const List<ImageFileFormat> values = <ImageFileFormat>[
    // ICO is not supported in Chrome. It is deemed too simple and too specific. See also:
    //   https://source.chromium.org/chromium/chromium/src/+/main:third_party/blink/renderer/modules/webcodecs/image_decoder_external.cc;l=38;drc=fd8802b593110ea18a97ef044f8a40dd24a622ec

    // PNG
    ImageFileFormat(<int?>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A], 'image/png'),

    // GIF87a
    ImageFileFormat(<int?>[0x47, 0x49, 0x46, 0x38, 0x37, 0x61], 'image/gif'),

    // GIF89a
    ImageFileFormat(<int?>[0x47, 0x49, 0x46, 0x38, 0x39, 0x61], 'image/gif'),

    // JPEG
    ImageFileFormat(<int?>[0xFF, 0xD8, 0xFF], 'image/jpeg'),

    // WebP
    ImageFileFormat(<int?>[0x52, 0x49, 0x46, 0x46, null, null, null, null, 0x57, 0x45, 0x42, 0x50], 'image/webp'),

    // BMP
    ImageFileFormat(<int?>[0x42, 0x4D], 'image/bmp'),
  ];
}

/// Function signature of [debugContentTypeDetector], which is the same as the
/// signature of [detectContentType].
typedef DebugContentTypeDetector = String? Function(Uint8List);

/// If not null, replaced the functionality of [detectContentType] with its own.
///
/// This is useful in tests, for example, to test unsupported content types.
DebugContentTypeDetector? debugContentTypeDetector;

/// Detects the image file format and returns the corresponding "Content-Type"
/// value (a.k.a. MIME type).
///
/// The returned value can be passed to `ImageDecoder` when decoding an image.
///
/// Returns null if [data] cannot be mapped to a known content type.
String? detectContentType(Uint8List data) {
  if (debugContentTypeDetector != null) {
    return debugContentTypeDetector!.call(data);
  }

  formatLoop: for (final ImageFileFormat format in ImageFileFormat.values) {
    if (data.length < format.header.length) {
      continue;
    }

    for (int i = 0; i < format.header.length; i++) {
      final int? magicByte = format.header[i];
      if (magicByte == null) {
        // Wildcard, accepts everything.
        continue;
      }

      final int headerByte = data[i];
      if (headerByte != magicByte) {
        continue formatLoop;
      }
    }

    return format.contentType;
  }

  if (isAvif(data)) {
    return 'image/avif';
  }

  return null;
}

/// A string of bytes that every AVIF image contains somehwere in its first 16
/// bytes.
///
/// This signature is necessary but not sufficient, which may lead to false
/// positives. For example, the file may be HEIC or a video. This is OK,
/// because in the worst case, the image decoder fails to decode the file.
/// This is something we must anticipate regardless of this detection logic.
/// The codec must already protect itself from downloaded files lying about
/// their contents.
///
/// The alternative would be to implement a more precise detection, which would
/// add complexity and code size. This is how Chromium does it:
///
/// https://source.chromium.org/chromium/chromium/src/+/main:third_party/blink/renderer/platform/image-decoders/avif/avif_image_decoder.cc;l=504;drc=fd8802b593110ea18a97ef044f8a40dd24a622ec
final List<int> _avifSignature = 'ftyp'.codeUnits;

/// Optimistically detects whether [data] is an AVIF image file.
bool isAvif(Uint8List data) {
  firstByteLoop: for (int i = 0; i < 16; i += 1) {
    for (int j = 0; j < _avifSignature.length; j += 1) {
      if (i + j >= data.length) {
        // Reached EOF without finding the signature.
        return false;
      }
      if (data[i + j] != _avifSignature[j]) {
        continue firstByteLoop;
      }
    }
    return true;
  }
  return false;
}

Future<ByteData> readPixelsFromVideoFrame(VideoFrame videoFrame, ui.ImageByteFormat format) async {
  if (format == ui.ImageByteFormat.png) {
    final Uint8List png = await encodeVideoFrameAsPng(videoFrame);
    return png.buffer.asByteData();
  }

  final ByteBuffer pixels = await readVideoFramePixelsUnmodified(videoFrame);

  // Check if the pixels are already in the right format and if so, return the
  // original pixels without modification.
  if (_shouldReadPixelsUnmodified(videoFrame, format)) {
    return pixels.asByteData();
  }

  // At this point we know we want to read unencoded pixels, and that the video
  // frame is _not_ using the same format as the requested one.
  final bool isBgrFrame = videoFrame.format == 'BGRA' || videoFrame.format == 'BGRX';
  if (format == ui.ImageByteFormat.rawRgba && isBgrFrame) {
    _bgrToRgba(pixels);
    return pixels.asByteData();
  }

  // Last resort, just return the original pixels.
  return pixels.asByteData();
}

/// Mutates the [pixels], converting them from BGRX/BGRA to RGBA.
void _bgrToRgba(ByteBuffer pixels) {
  final int pixelCount = pixels.lengthInBytes ~/ 4;
  final Uint8List pixelBytes = pixels.asUint8List();
  for (int i = 0; i < pixelCount; i += 4) {
    // It seems even in little-endian machines the BGR_ pixels are encoded as
    // big-endian, i.e. the blue byte is written into the lowest byte in the
    // memory address space.
    final int b = pixelBytes[i];
    final int r = pixelBytes[i + 2];

    // So far the codec has reported 255 for the X component, so there's no
    // special treatment for alpha. This may need to change if we ever face
    // codecs that do something different.
    pixelBytes[i] = r;
    pixelBytes[i + 2] = b;
  }
}

bool _shouldReadPixelsUnmodified(VideoFrame videoFrame, ui.ImageByteFormat format) {
  if (format == ui.ImageByteFormat.rawUnmodified) {
    return true;
  }

  // Do not convert if the requested format is RGBA and the video frame is
  // encoded as either RGBA or RGBX.
  final bool isRgbFrame = videoFrame.format == 'RGBA' || videoFrame.format == 'RGBX';
  return format == ui.ImageByteFormat.rawRgba && isRgbFrame;
}

Future<ByteBuffer> readVideoFramePixelsUnmodified(VideoFrame videoFrame) async {
  final int size = videoFrame.allocationSize().toInt();
  final Uint8List destination = Uint8List(size);
  final JsPromise copyPromise = videoFrame.copyTo(destination);
  await promiseToFuture<void>(copyPromise);
  return destination.buffer;
}

Future<Uint8List> encodeVideoFrameAsPng(VideoFrame videoFrame) async {
  final int width = videoFrame.displayWidth.toInt();
  final int height = videoFrame.displayHeight.toInt();
  final DomCanvasElement canvas = createDomCanvasElement(width: width, height:
      height);
  final DomCanvasRenderingContext2D ctx = canvas.context2D;
  ctx.drawImage(videoFrame, 0, 0);
  final String pngBase64 = canvas.toDataURL().substring('data:image/png;base64,'.length);
  return base64.decode(pngBase64);
}
