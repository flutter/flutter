// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// The library contains Flutter specific helper methods for
// the package https://github.com/dart-lang/leak_tracker.
// The methods cannot become part of the package, because
// the package is pure Dart one.

import 'package:leak_tracker/leak_tracker.dart';

Future<Leaks> withLeakTracking(
  Future<void> Function() callback, {
  bool throwOnLeaks = true,
  Duration? timeoutForFinalGarbageCollection,
  StackTraceCollectionConfig stackTraceCollectionConfig =
      const StackTraceCollectionConfig(),
}) async {
  enableLeakTracking(
    resetIfEnabled: true,
    config: LeakTrackingConfiguration.passive(
      stackTraceCollectionConfig: stackTraceCollectionConfig,
    ),
  );

  await callback();

  await _forceGC(
    gcCycles: gcCountBuffer,
    timeout: timeoutForFinalGarbageCollection,
  );

  final result = collectLeaks();

  try {
    if (result.total > 0 && throwOnLeaks) {
      throw MemoryLeaksDetectedError(result);
    }
  } finally {
    disableLeakTracking();
  }

  return result;
}
