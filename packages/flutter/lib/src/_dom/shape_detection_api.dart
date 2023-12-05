// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'geometry.dart';
import 'html.dart';

typedef LandmarkType = String;
typedef BarcodeFormat = String;

@JS('FaceDetector')
@staticInterop
class FaceDetector {
  external factory FaceDetector([FaceDetectorOptions faceDetectorOptions]);
}

extension FaceDetectorExtension on FaceDetector {
  external JSPromise detect(ImageBitmapSource image);
}

@JS()
@staticInterop
@anonymous
class FaceDetectorOptions {
  external factory FaceDetectorOptions({
    int maxDetectedFaces,
    bool fastMode,
  });
}

extension FaceDetectorOptionsExtension on FaceDetectorOptions {
  external set maxDetectedFaces(int value);
  external int get maxDetectedFaces;
  external set fastMode(bool value);
  external bool get fastMode;
}

@JS()
@staticInterop
@anonymous
class DetectedFace {
  external factory DetectedFace({
    required DOMRectReadOnly boundingBox,
    required JSArray? landmarks,
  });
}

extension DetectedFaceExtension on DetectedFace {
  external set boundingBox(DOMRectReadOnly value);
  external DOMRectReadOnly get boundingBox;
  external set landmarks(JSArray? value);
  external JSArray? get landmarks;
}

@JS()
@staticInterop
@anonymous
class Landmark {
  external factory Landmark({
    required JSArray locations,
    LandmarkType type,
  });
}

extension LandmarkExtension on Landmark {
  external set locations(JSArray value);
  external JSArray get locations;
  external set type(LandmarkType value);
  external LandmarkType get type;
}

@JS('BarcodeDetector')
@staticInterop
class BarcodeDetector {
  external factory BarcodeDetector(
      [BarcodeDetectorOptions barcodeDetectorOptions]);

  external static JSPromise getSupportedFormats();
}

extension BarcodeDetectorExtension on BarcodeDetector {
  external JSPromise detect(ImageBitmapSource image);
}

@JS()
@staticInterop
@anonymous
class BarcodeDetectorOptions {
  external factory BarcodeDetectorOptions({JSArray formats});
}

extension BarcodeDetectorOptionsExtension on BarcodeDetectorOptions {
  external set formats(JSArray value);
  external JSArray get formats;
}

@JS()
@staticInterop
@anonymous
class DetectedBarcode {
  external factory DetectedBarcode({
    required DOMRectReadOnly boundingBox,
    required String rawValue,
    required BarcodeFormat format,
    required JSArray cornerPoints,
  });
}

extension DetectedBarcodeExtension on DetectedBarcode {
  external set boundingBox(DOMRectReadOnly value);
  external DOMRectReadOnly get boundingBox;
  external set rawValue(String value);
  external String get rawValue;
  external set format(BarcodeFormat value);
  external BarcodeFormat get format;
  external set cornerPoints(JSArray value);
  external JSArray get cornerPoints;
}
