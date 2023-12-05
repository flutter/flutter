// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'hr_time.dart';
import 'performance_timeline.dart';

@JS('LargestContentfulPaint')
@staticInterop
class LargestContentfulPaint implements PerformanceEntry {}

extension LargestContentfulPaintExtension on LargestContentfulPaint {
  external JSObject toJSON();
  external DOMHighResTimeStamp get renderTime;
  external DOMHighResTimeStamp get loadTime;
  external int get size;
  external String get id;
  external String get url;
  external Element? get element;
}
