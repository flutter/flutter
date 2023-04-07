// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:leak_tracker/leak_tracker.dart';

/// Handler to collect stack trace information.
typedef LeaksCallback = void Function(Leaks foundLeaks);

/// Configuration for leak trecking in unit tests.
class LeakTrackingTestConfig {

  /// Creates a new instance of [LeakTrackingTestConfig].
  LeakTrackingTestConfig(
    this.stackTraceCollectionConfig,
    this.timeoutForFinalGarbageCollection,
    this.onLeaks,
  );

  /// When to collect stack trace information.
  final StackTraceCollectionConfig? stackTraceCollectionConfig;

  /// Timout for final garbage collection.
  final Duration? timeoutForFinalGarbageCollection;

  /// Handler to obtain details about collected leaks.
  final LeaksCallback? onLeaks;
}
