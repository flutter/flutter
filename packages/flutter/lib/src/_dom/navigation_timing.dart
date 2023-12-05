// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'hr_time.dart';
import 'resource_timing.dart';

typedef NavigationTimingType = String;

@JS('PerformanceNavigationTiming')
@staticInterop
class PerformanceNavigationTiming implements PerformanceResourceTiming {}

extension PerformanceNavigationTimingExtension on PerformanceNavigationTiming {
  external JSObject toJSON();
  external DOMHighResTimeStamp get unloadEventStart;
  external DOMHighResTimeStamp get unloadEventEnd;
  external DOMHighResTimeStamp get domInteractive;
  external DOMHighResTimeStamp get domContentLoadedEventStart;
  external DOMHighResTimeStamp get domContentLoadedEventEnd;
  external DOMHighResTimeStamp get domComplete;
  external DOMHighResTimeStamp get loadEventStart;
  external DOMHighResTimeStamp get loadEventEnd;
  external NavigationTimingType get type;
  external int get redirectCount;
  external DOMHighResTimeStamp get criticalCHRestart;
  external DOMHighResTimeStamp get activationStart;
}

@JS('PerformanceTiming')
@staticInterop
class PerformanceTiming {}

extension PerformanceTimingExtension on PerformanceTiming {
  external JSObject toJSON();
  external int get navigationStart;
  external int get unloadEventStart;
  external int get unloadEventEnd;
  external int get redirectStart;
  external int get redirectEnd;
  external int get fetchStart;
  external int get domainLookupStart;
  external int get domainLookupEnd;
  external int get connectStart;
  external int get connectEnd;
  external int get secureConnectionStart;
  external int get requestStart;
  external int get responseStart;
  external int get responseEnd;
  external int get domLoading;
  external int get domInteractive;
  external int get domContentLoadedEventStart;
  external int get domContentLoadedEventEnd;
  external int get domComplete;
  external int get loadEventStart;
  external int get loadEventEnd;
}

@JS('PerformanceNavigation')
@staticInterop
class PerformanceNavigation {
  external static int get TYPE_NAVIGATE;
  external static int get TYPE_RELOAD;
  external static int get TYPE_BACK_FORWARD;
  external static int get TYPE_RESERVED;
}

extension PerformanceNavigationExtension on PerformanceNavigation {
  external JSObject toJSON();
  external int get type;
  external int get redirectCount;
}
