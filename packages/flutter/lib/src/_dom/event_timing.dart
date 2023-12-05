// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'hr_time.dart';
import 'performance_timeline.dart';

@JS('PerformanceEventTiming')
@staticInterop
class PerformanceEventTiming implements PerformanceEntry {}

extension PerformanceEventTimingExtension on PerformanceEventTiming {
  external JSObject toJSON();
  external DOMHighResTimeStamp get processingStart;
  external DOMHighResTimeStamp get processingEnd;
  external bool get cancelable;
  external Node? get target;
  external int get interactionId;
}

@JS('EventCounts')
@staticInterop
class EventCounts {}

extension EventCountsExtension on EventCounts {}
