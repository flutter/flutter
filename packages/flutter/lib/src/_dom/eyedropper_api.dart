// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';

@JS()
@staticInterop
@anonymous
class ColorSelectionResult {
  external factory ColorSelectionResult({String sRGBHex});
}

extension ColorSelectionResultExtension on ColorSelectionResult {
  external set sRGBHex(String value);
  external String get sRGBHex;
}

@JS()
@staticInterop
@anonymous
class ColorSelectionOptions {
  external factory ColorSelectionOptions({AbortSignal signal});
}

extension ColorSelectionOptionsExtension on ColorSelectionOptions {
  external set signal(AbortSignal value);
  external AbortSignal get signal;
}

@JS('EyeDropper')
@staticInterop
class EyeDropper {
  external factory EyeDropper();
}

extension EyeDropperExtension on EyeDropper {
  external JSPromise open([ColorSelectionOptions options]);
}
