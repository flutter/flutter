// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Uses the `ImageDecoder` class supplied by the browser.
///
/// See also:
///
///  * `image_wasm_codecs.dart`, which uses codecs supplied by the CanvasKit WASM bundle.
@JS()
library image_web_codecs;

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:js/js.dart';
import 'package:ui/ui.dart' as ui;

import '../browser_detection.dart';
import '../util.dart';
import 'canvaskit_api.dart';
import 'image.dart';

@JS('window.ImageDecoder')
external Object? get _imageDecoderConstructor;

/// Whether the current browser supports `ImageDecoder`.
bool browserSupportsImageDecoder =
    _imageDecoderConstructor != null && browserEngine == BrowserEngine.blink;

/// Sets the value of [browserSupportsImageDecoder] to its default value.
void debugResetBrowserSupportsImageDecoder() {
  browserSupportsImageDecoder =
      _imageDecoderConstructor != null;
}

/// Image decoder backed by the browser's `ImageDecoder`.
class CkBrowserImageDecoder implements ui.Codec {
  static Future<CkBrowserImageDecoder> create({
    required Uint8List data,
    required String debugSource,
    int? targetWidth,
    int? targetHeight,
  }) async {
    // ImageDecoder does not detect image type automatically. It requires us to
    // tell it what the image type is.
    final String? contentType = detectContentType(data);

    if (contentType == null) {
      final String fileHeader;
      if (data.isNotEmpty) {
        fileHeader = '[' + bytesToHexString(data.sublist(0, math.min(10, data.length))) + ']';
      } else {
        fileHeader = 'empty';
      }
      throw ImageCodecException(
        'Failed to detect image file format using the file header.\n'
        'File header was $fileHeader.\n'
        'Image source: $debugSource'
      );
    }

    try {
      final _ImageDecoder webDecoder = _ImageDecoder(_ImageDecoderOptions(
        type: contentType,
        data: data,

        // Flutter always uses premultiplied alpha.
        premultiplyAlpha: 'premultiply',
        desiredWidth: targetWidth,
        desiredHeight: targetHeight,

        // "default" gives the browser the liberty to convert to display-appropriate
        // color space, typically SRGB, which is what we want.
        colorSpaceConversion: 'default',

        // Flutter doesn't give the developer a way to customize this, so if this
        // is an animated image we should prefer the animated track.
        preferAnimation: true,
      ));

      await js_util.promiseToFuture<void>(webDecoder.tracks.ready);

      // Flutter doesn't have an API for progressive loading of images, so we
      // wait until the image is fully decoded.
      // package:js bindings don't work with getters that return a Promise, which
      // is why js_util is used instead.
      await js_util.promiseToFuture<void>(js_util.getProperty(webDecoder, 'completed'));
      return CkBrowserImageDecoder._(webDecoder, debugSource);
    } catch (error) {
      if (error is html.DomException) {
        if (error.name == html.DomException.NOT_SUPPORTED) {
          throw ImageCodecException(
            'Image file format ($contentType) is not supported by this browser\'s ImageDecoder API.\n'
            'Image source: $debugSource',
          );
        }
      }
      throw ImageCodecException(
        'Failed to decode image using the browser\'s ImageDecoder API.\n'
        'Image source: $debugSource\n'
        'Original browser error: $error'
      );
    }
  }

  CkBrowserImageDecoder._(this.webDecoder, this.debugSource);

  final _ImageDecoder webDecoder;
  final String debugSource;

  /// Whether this decoded has been disposed of.
  ///
  /// Once this turns true it stays true forever, and this decoder becomes
  /// unusable.
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;

    // This releases all resources, including any currently running decoding work.
    webDecoder.close();
  }

  void _debugCheckNotDisposed() {
    assert(
      !_isDisposed,
      'Cannot use this image decoder. It has been disposed of.'
    );
  }

  @override
  int get frameCount {
    _debugCheckNotDisposed();
    return webDecoder.tracks.selectedTrack!.frameCount;
  }

  /// The index of the frame that will be decoded on the next call of [getNextFrame];
  int _nextFrameIndex = 0;

  @override
  Future<ui.FrameInfo> getNextFrame() async {
    _debugCheckNotDisposed();
    final _DecodeResult result = await js_util.promiseToFuture<_DecodeResult>(
      webDecoder.decode(_DecodeOptions(frameIndex: _nextFrameIndex)),
    );
    final _VideoFrame frame = result.image;
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
    final Duration duration = Duration(microseconds: frame.duration ?? 0);

    if (skImage == null) {
      throw ImageCodecException(
        'Failed to create image from pixel data decoded using the browser\'s ImageDecoder.',
      );
    }

    final CkImage image = CkImage(skImage);
    return Future<ui.FrameInfo>.value(AnimatedImageFrameInfo(duration, image));
  }

  @override
  int get repetitionCount {
    _debugCheckNotDisposed();
    return webDecoder.tracks.selectedTrack!.repetitionCount;
  }
}

/// Corresponds to JavaScript's `Promise`.
///
/// This type doesn't need any members. Instead, it should be first converted
/// to Dart's [Future] using [promiseToFuture] then interacted with through the
/// [Future] API.
@JS()
@anonymous
class JsPromise {}

/// Corresponds to the browser's `ImageDecoder` type.
///
/// See also:
///
///  * https://www.w3.org/TR/webcodecs/#imagedecoder-interface
@JS('window.ImageDecoder')
class _ImageDecoder {
  external _ImageDecoder(_ImageDecoderOptions options);
  external _ImageTrackList get tracks;
  external bool get complete;
  external JsPromise decode(_DecodeOptions options);
  external void close();
}

/// The result of [_ImageDecoder.decode].
///
/// See also:
///
///  * https://www.w3.org/TR/webcodecs/#imagedecoderesult-interface
@JS()
@anonymous
class _DecodeResult {
  external _VideoFrame get image;
  external bool get complete;
}

/// Options passed to [_ImageDecoder.decode].
///
/// See also:
///
///  * https://www.w3.org/TR/webcodecs/#dictdef-imagedecodeoptions
@JS()
@anonymous
class _DecodeOptions {
  external factory _DecodeOptions({
    required int frameIndex,
  });
}

/// The only frame in a static image, or one of the frames in an animated one.
///
/// This class maps to the `VideoFrame` type provided by the browser.
///
/// See also:
///
///  * https://www.w3.org/TR/webcodecs/#videoframe-interface
@JS()
@anonymous
class _VideoFrame {
  external int allocationSize();
  external JsPromise copyTo(Uint8List destination);
  external String? get format;
  external int get codedWidth;
  external int get codedHeight;
  external int get displayWidth;
  external int get displayHeight;
  external int? get duration;
  external void close();
}

/// Corresponds to the browser's `ImageTrackList` type.
///
/// See also:
///
///  * https://www.w3.org/TR/webcodecs/#imagetracklist-interface
@JS()
@anonymous
class _ImageTrackList {
  external JsPromise get ready;
  external _ImageTrack? get selectedTrack;
}

/// Corresponds to the browser's `ImageTrack` type.
///
/// See also:
///
///  * https://www.w3.org/TR/webcodecs/#imagetrack
@JS()
@anonymous
class _ImageTrack {
  external int get repetitionCount;
  external int get frameCount;
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
    ImageFileFormat(<int?>[0xFF, 0xD8, 0xFF, 0xDB], 'image/jpeg'),
    ImageFileFormat(<int?>[0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01], 'image/jpeg'),
    ImageFileFormat(<int?>[0xFF, 0xD8, 0xFF, 0xEE], 'image/jpeg'),
    ImageFileFormat(<int?>[0xFF, 0xD8, 0xFF, 0xE1], 'image/jpeg'),

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

/// Options passed to the `ImageDecoder` constructor.
///
/// See also:
///
///  * https://www.w3.org/TR/webcodecs/#imagedecoderinit-interface
@JS()
@anonymous
class _ImageDecoderOptions {
  external factory _ImageDecoderOptions({
    required String type,
    required Uint8List data,
    required String premultiplyAlpha,
    required int? desiredWidth,
    required int? desiredHeight,
    required String colorSpaceConversion,
    required bool preferAnimation,
  });
}
