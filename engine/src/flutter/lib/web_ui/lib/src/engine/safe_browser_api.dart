// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// JavaScript API bindings for browser APIs.
///
/// The public surface of this API must be safe to use. In particular, using the
/// API of this library it must not be possible to execute arbitrary code from
/// strings by injecting it into HTML or URLs.

@JS()
library browser_api;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:ui/ui_web/src/ui_web.dart' as ui_web;

import 'dom.dart';

/// Parses a string [source] into a double.
///
/// Uses the JavaScript `parseFloat` function instead of Dart's [double.parse]
/// because the latter can't parse strings like "20px".
///
/// Returns `null` if it fails to parse.
double? parseFloat(String source) {
  // Using JavaScript's `parseFloat` here because it can parse values
  // like "20px", while Dart's `double.tryParse` fails.
  final double result = parseFloatImpl(source);

  if (result.isNaN) {
    return null;
  }
  return result;
}

/// Parses the font size of [element] and returns the value without a unit.
num? parseFontSize(DomElement element) {
  num? fontSize;

  if (element.has('computedStyleMap')) {
    fontSize = element
        .computedStyleMap()
        .get('font-size')
        ?.getProperty<JSNumber>('value'.toJS)
        .toDartDouble;
  }

  if (fontSize == null) {
    // Fallback to `getComputedStyle`.
    final String fontSizeString = domWindow.getComputedStyle(element).getPropertyValue('font-size');
    fontSize = parseFloat(fontSizeString);
  }

  return fontSize;
}

/// Parses the given style property [attributeName] of [element] and returns the
/// [resolved value](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_cascade/Value_processing#resolved_value) without a unit.
///
/// Returns `null` if the property value is not numeric (e.g., 'normal',
/// 'auto') or cannot be parsed.
num? parseNumericStyleProperty(DomElement element, String attributeName) {
  return parseFloat(domWindow.getComputedStyle(element).getPropertyValue(attributeName));
}

/// Provides haptic feedback.
void vibrate(int durationMs) {
  final DomNavigator navigator = domWindow.navigator;
  if (navigator.has('vibrate')) {
    navigator.vibrate(durationMs.toJS);
  }
}

@JS('window.ImageDecoder')
external JSAny? get __imageDecoderConstructor;
Object? get _imageDecoderConstructor => __imageDecoderConstructor?.toObjectShallow;

/// Environment variable that allows the developer to opt out of using browser's
/// `ImageDecoder` API, and use the WASM codecs bundled with CanvasKit.
///
/// While all reported severe issues with `ImageDecoder` have been fixed, this
/// API remains relatively new. This option will allow developers to opt out of
/// it, if they hit a severe bug that we did not anticipate.
// TODO(yjbanov): remove this flag once we're fully confident in the new API.
//                https://github.com/flutter/flutter/issues/95277
const bool _browserImageDecodingEnabled = bool.fromEnvironment(
  'BROWSER_IMAGE_DECODING_ENABLED',
  defaultValue: true,
);

/// Whether the current browser supports `ImageDecoder`.
bool browserSupportsImageDecoder = _defaultBrowserSupportsImageDecoder;

/// Sets the value of [browserSupportsImageDecoder] to its default value.
void debugResetBrowserSupportsImageDecoder() {
  browserSupportsImageDecoder = _defaultBrowserSupportsImageDecoder;
}

bool get _defaultBrowserSupportsImageDecoder =>
    _browserImageDecodingEnabled &&
    _imageDecoderConstructor != null &&
    _isBrowserImageDecoderStable;

// TODO(yjbanov): https://github.com/flutter/flutter/issues/122761
// Frequently, when a browser launches an API that other browsers already
// support, there are subtle incompatibilities that may cause apps to crash if,
// we blindly adopt the new implementation. This variable prevents us from
// picking up potentially incompatible implementations of ImageDecoder API.
// Instead, when a new browser engine launches the API, we'll evaluate it and
// enable it explicitly.
bool get _isBrowserImageDecoderStable => ui_web.browser.browserEngine == ui_web.BrowserEngine.blink;

/// Corresponds to the browser's `ImageDecoder` type.
///
/// See also:
///
///  * https://www.w3.org/TR/webcodecs/#imagedecoder-interface
@JS('window.ImageDecoder')
extension type ImageDecoder._(JSObject _) implements JSObject {
  external ImageDecoder(ImageDecoderOptions options);

  external ImageTrackList get tracks;
  external bool get complete;
  external JSPromise<JSAny?> get completed;
  external JSPromise<DecodeResult> decode(DecodeOptions options);
  external void close();
}

/// Options passed to the `ImageDecoder` constructor.
///
/// See also:
///
///  * https://www.w3.org/TR/webcodecs/#imagedecoderinit-interface
extension type ImageDecoderOptions._(JSObject _) implements JSObject {
  external ImageDecoderOptions({
    required String type,
    required JSAny data,
    required String premultiplyAlpha,
    double? desiredWidth,
    double? desiredHeight,
    required String colorSpaceConversion,
    required bool preferAnimation,
  });
}

/// The result of [ImageDecoder.decode].
///
/// See also:
///
///  * https://www.w3.org/TR/webcodecs/#imagedecoderesult-interface
extension type DecodeResult(JSObject _) implements JSObject {
  external VideoFrame get image;
  external bool get complete;
}

/// Options passed to [ImageDecoder.decode].
///
/// See also:
///
///  * https://www.w3.org/TR/webcodecs/#dictdef-imagedecodeoptions
extension type DecodeOptions._(JSObject _) implements JSObject {
  external DecodeOptions({required int frameIndex, required bool completeFramesOnly});
}

/// The only frame in a static image, or one of the frames in an animated one.
///
/// This class maps to the `VideoFrame` type provided by the browser.
///
/// See also:
///
///  * https://www.w3.org/TR/webcodecs/#videoframe-interface
extension type VideoFrame(JSObject _) implements JSObject, DomCanvasImageSource {
  external double allocationSize();

  @JS('copyTo')
  external JSPromise<JSAny?> _copyTo(JSAny destination);
  JSPromise<JSAny?> copyTo(Object destination) => _copyTo(destination.toJSAnyShallow);

  external String? get format;
  external double get codedWidth;
  external double get codedHeight;
  external double get displayWidth;
  external double get displayHeight;
  external double? get duration;
  external VideoFrame clone();
  external void close();
}

/// Corresponds to the browser's `ImageTrackList` type.
///
/// See also:
///
///  * https://www.w3.org/TR/webcodecs/#imagetracklist-interface
extension type ImageTrackList(JSObject _) implements JSObject {
  external JSPromise<JSAny?> get ready;
  external ImageTrack? get selectedTrack;
}

/// Corresponds to the browser's `ImageTrack` type.
///
/// See also:
///
///  * https://www.w3.org/TR/webcodecs/#imagetrack
extension type ImageTrack(JSObject _) implements JSObject {
  external double get repetitionCount;
  external double get frameCount;
}
