// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

@JS('FontMetrics')
@staticInterop
class FontMetrics {}

extension FontMetricsExtension on FontMetrics {
  external num get width;
  external JSArray get advances;
  external num get boundingBoxLeft;
  external num get boundingBoxRight;
  external num get height;
  external num get emHeightAscent;
  external num get emHeightDescent;
  external num get boundingBoxAscent;
  external num get boundingBoxDescent;
  external num get fontBoundingBoxAscent;
  external num get fontBoundingBoxDescent;
  external Baseline get dominantBaseline;
  external JSArray get baselines;
  external JSArray get fonts;
}

@JS('Baseline')
@staticInterop
class Baseline {}

extension BaselineExtension on Baseline {
  external String get name;
  external num get value;
}

@JS('Font')
@staticInterop
class Font {}

extension FontExtension on Font {
  external String get name;
  external int get glyphsRendered;
}
