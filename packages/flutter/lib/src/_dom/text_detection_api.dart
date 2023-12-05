// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'geometry.dart';
import 'html.dart';

@JS('TextDetector')
@staticInterop
class TextDetector {
  external factory TextDetector();
}

extension TextDetectorExtension on TextDetector {
  external JSPromise detect(ImageBitmapSource image);
}

@JS()
@staticInterop
@anonymous
class DetectedText {
  external factory DetectedText({
    required DOMRectReadOnly boundingBox,
    required String rawValue,
    required JSArray cornerPoints,
  });
}

extension DetectedTextExtension on DetectedText {
  external set boundingBox(DOMRectReadOnly value);
  external DOMRectReadOnly get boundingBox;
  external set rawValue(String value);
  external String get rawValue;
  external set cornerPoints(JSArray value);
  external JSArray get cornerPoints;
}
