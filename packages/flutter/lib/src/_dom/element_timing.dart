// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'geometry.dart';
import 'hr_time.dart';
import 'performance_timeline.dart';

@JS('PerformanceElementTiming')
@staticInterop
class PerformanceElementTiming implements PerformanceEntry {}

extension PerformanceElementTimingExtension on PerformanceElementTiming {
  external JSObject toJSON();
  external DOMHighResTimeStamp get renderTime;
  external DOMHighResTimeStamp get loadTime;
  external DOMRectReadOnly get intersectionRect;
  external String get identifier;
  external int get naturalWidth;
  external int get naturalHeight;
  external String get id;
  external Element? get element;
  external String get url;
}
