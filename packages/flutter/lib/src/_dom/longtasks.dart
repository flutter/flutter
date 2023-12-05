// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'performance_timeline.dart';

@JS('PerformanceLongTaskTiming')
@staticInterop
class PerformanceLongTaskTiming implements PerformanceEntry {}

extension PerformanceLongTaskTimingExtension on PerformanceLongTaskTiming {
  external JSObject toJSON();
  external JSArray get attribution;
}

@JS('TaskAttributionTiming')
@staticInterop
class TaskAttributionTiming implements PerformanceEntry {}

extension TaskAttributionTimingExtension on TaskAttributionTiming {
  external JSObject toJSON();
  external String get containerType;
  external String get containerSrc;
  external String get containerId;
  external String get containerName;
}
