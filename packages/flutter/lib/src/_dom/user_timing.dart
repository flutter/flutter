// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'hr_time.dart';
import 'performance_timeline.dart';

@JS()
@staticInterop
@anonymous
class PerformanceMarkOptions {
  external factory PerformanceMarkOptions({
    JSAny? detail,
    DOMHighResTimeStamp startTime,
  });
}

extension PerformanceMarkOptionsExtension on PerformanceMarkOptions {
  external set detail(JSAny? value);
  external JSAny? get detail;
  external set startTime(DOMHighResTimeStamp value);
  external DOMHighResTimeStamp get startTime;
}

@JS()
@staticInterop
@anonymous
class PerformanceMeasureOptions {
  external factory PerformanceMeasureOptions({
    JSAny? detail,
    JSAny start,
    DOMHighResTimeStamp duration,
    JSAny end,
  });
}

extension PerformanceMeasureOptionsExtension on PerformanceMeasureOptions {
  external set detail(JSAny? value);
  external JSAny? get detail;
  external set start(JSAny value);
  external JSAny get start;
  external set duration(DOMHighResTimeStamp value);
  external DOMHighResTimeStamp get duration;
  external set end(JSAny value);
  external JSAny get end;
}

@JS('PerformanceMark')
@staticInterop
class PerformanceMark implements PerformanceEntry {
  external factory PerformanceMark(
    String markName, [
    PerformanceMarkOptions markOptions,
  ]);
}

extension PerformanceMarkExtension on PerformanceMark {
  external JSAny? get detail;
}

@JS('PerformanceMeasure')
@staticInterop
class PerformanceMeasure implements PerformanceEntry {}

extension PerformanceMeasureExtension on PerformanceMeasure {
  external JSAny? get detail;
}
