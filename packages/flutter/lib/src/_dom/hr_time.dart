// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'event_timing.dart';
import 'html.dart';
import 'navigation_timing.dart';
import 'performance_timeline.dart';
import 'user_timing.dart';

typedef DOMHighResTimeStamp = num;
typedef EpochTimeStamp = int;

@JS('Performance')
@staticInterop
class Performance implements EventTarget {}

extension PerformanceExtension on Performance {
  external DOMHighResTimeStamp now();
  external JSObject toJSON();
  external JSPromise measureUserAgentSpecificMemory();
  external PerformanceEntryList getEntries();
  external PerformanceEntryList getEntriesByType(String type);
  external PerformanceEntryList getEntriesByName(
    String name, [
    String type,
  ]);
  external void clearResourceTimings();
  external void setResourceTimingBufferSize(int maxSize);
  external PerformanceMark mark(
    String markName, [
    PerformanceMarkOptions markOptions,
  ]);
  external void clearMarks([String markName]);
  external PerformanceMeasure measure(
    String measureName, [
    JSAny startOrMeasureOptions,
    String endMark,
  ]);
  external void clearMeasures([String measureName]);
  external EventCounts get eventCounts;
  external int get interactionCount;
  external DOMHighResTimeStamp get timeOrigin;
  external PerformanceTiming get timing;
  external PerformanceNavigation get navigation;
  external set onresourcetimingbufferfull(EventHandler value);
  external EventHandler get onresourcetimingbufferfull;
}
