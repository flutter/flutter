// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'mediacapture_streams.dart';

typedef ConstrainPoint2D = JSObject;
typedef RedEyeReduction = String;
typedef FillLightMode = String;
typedef MeteringMode = String;

@JS('ImageCapture')
@staticInterop
class ImageCapture {
  external factory ImageCapture(MediaStreamTrack videoTrack);
}

extension ImageCaptureExtension on ImageCapture {
  external JSPromise takePhoto([PhotoSettings photoSettings]);
  external JSPromise getPhotoCapabilities();
  external JSPromise getPhotoSettings();
  external JSPromise grabFrame();
  external MediaStreamTrack get track;
}

@JS()
@staticInterop
@anonymous
class PhotoCapabilities {
  external factory PhotoCapabilities({
    RedEyeReduction redEyeReduction,
    MediaSettingsRange imageHeight,
    MediaSettingsRange imageWidth,
    JSArray fillLightMode,
  });
}

extension PhotoCapabilitiesExtension on PhotoCapabilities {
  external set redEyeReduction(RedEyeReduction value);
  external RedEyeReduction get redEyeReduction;
  external set imageHeight(MediaSettingsRange value);
  external MediaSettingsRange get imageHeight;
  external set imageWidth(MediaSettingsRange value);
  external MediaSettingsRange get imageWidth;
  external set fillLightMode(JSArray value);
  external JSArray get fillLightMode;
}

@JS()
@staticInterop
@anonymous
class PhotoSettings {
  external factory PhotoSettings({
    FillLightMode fillLightMode,
    num imageHeight,
    num imageWidth,
    bool redEyeReduction,
  });
}

extension PhotoSettingsExtension on PhotoSettings {
  external set fillLightMode(FillLightMode value);
  external FillLightMode get fillLightMode;
  external set imageHeight(num value);
  external num get imageHeight;
  external set imageWidth(num value);
  external num get imageWidth;
  external set redEyeReduction(bool value);
  external bool get redEyeReduction;
}

@JS()
@staticInterop
@anonymous
class MediaSettingsRange {
  external factory MediaSettingsRange({
    num max,
    num min,
    num step,
  });
}

extension MediaSettingsRangeExtension on MediaSettingsRange {
  external set max(num value);
  external num get max;
  external set min(num value);
  external num get min;
  external set step(num value);
  external num get step;
}

@JS()
@staticInterop
@anonymous
class ConstrainPoint2DParameters {
  external factory ConstrainPoint2DParameters({
    JSArray exact,
    JSArray ideal,
  });
}

extension ConstrainPoint2DParametersExtension on ConstrainPoint2DParameters {
  external set exact(JSArray value);
  external JSArray get exact;
  external set ideal(JSArray value);
  external JSArray get ideal;
}

@JS()
@staticInterop
@anonymous
class Point2D {
  external factory Point2D({
    num x,
    num y,
  });
}

extension Point2DExtension on Point2D {
  external set x(num value);
  external num get x;
  external set y(num value);
  external num get y;
}
