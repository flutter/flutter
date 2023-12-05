// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'hr_time.dart';

@JS('PerformanceServerTiming')
@staticInterop
class PerformanceServerTiming {}

extension PerformanceServerTimingExtension on PerformanceServerTiming {
  external JSObject toJSON();
  external String get name;
  external DOMHighResTimeStamp get duration;
  external String get description;
}
