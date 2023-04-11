// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';

/// Handler to collect leak information.
///
/// [leaks] contains information about found leaks.
typedef LeaksCallback = void Function(Leaks leaks);

/// Configuration for leak trecking in unit tests.
///
/// The configuration is needed only for test debugging.
class LeakTrackingFlutterTestConfig {

  /// Creates a new instance of [LeakTrackingFlutterTestConfig].
  LeakTrackingFlutterTestConfig({
    this.stackTraceCollectionConfig = const StackTraceCollectionConfig(),
    this.timeoutForFinalGarbageCollection,
    this.onLeaks,
    this.failTestOnLeaks = true,
  });

  /// When to collect stack trace information.
  final StackTraceCollectionConfig stackTraceCollectionConfig;

  /// Timout for final garbage collection.
  ///
  /// If null, will wait infinitely.
  final Duration? timeoutForFinalGarbageCollection;

  /// Handler to obtain details about collected leaks.
  final LeaksCallback? onLeaks;

  /// If true, the test will fail if leaks are found.
  final bool failTestOnLeaks;
}
