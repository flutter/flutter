// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

/// Returns the current timestamp in microseconds from a monotonically
/// increasing clock.
///
/// This is the web implementation, which uses `window.performance.now` as the
/// source of the timestamp.
///
/// See:
///   * https://developer.mozilla.org/en-US/docs/Web/API/Performance/now
double get performanceTimestamp => 1000 * _performance.now();

@JS()
@staticInterop
class _DomPerformance {}

@JS('performance')
external _DomPerformance get _performance;

extension _DomPerformanceExtension on _DomPerformance {
  @JS()
  external double now();
}
