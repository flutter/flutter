// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:leak_tracker/leak_tracker.dart';

import 'leak_tracking.dart';
import 'test_async_utils.dart';
import 'widget_tester.dart';

/// Wrapper for [withLeakTracking] with Flutter specific functionality.
///
/// The method will fail if wrapped code contains memory leaks.
///
/// See details in documentation for `withLeakTracking` at
/// https://github.com/dart-lang/leak_tracker/blob/main/lib/src/orchestration.dart#withLeakTracking
///
/// The Flutter related enhancements are:
/// 1. Listens to [MemoryAllocations] events.
/// 2. Uses `asyncCodeRunner` for async call for leak detection.
Future<void> withFlutterLeakTracking(
  DartAsyncCallback callback, {
  required AsyncCodeRunner asyncCodeRunner,
  LeakTrackingTestConfig? config,
}) async {
  // Leak tracker does not work for web platform.
  if (kIsWeb) {
    await callback();
    return;
  }

  void flutterEventToLeakTracker(ObjectEvent event) {
    return dispatchObjectEvent(event.toMap());
  }

  return TestAsyncUtils.guard<void>(() async {
    MemoryAllocations.instance.addListener(flutterEventToLeakTracker);
    try {
      final Leaks leaks = await withLeakTracking(
        callback,
        asyncCodeRunner: asyncCodeRunner,
        stackTraceCollectionConfig: config?.stackTraceCollectionConfig ?? const StackTraceCollectionConfig(),
        shouldThrowOnLeaks: false,
        timeoutForFinalGarbageCollection: config?.timeoutForFinalGarbageCollection,
      );

      config?.onLeaks?.call(leaks);

      expect(leaks, isLeakFree);
    } finally {
      MemoryAllocations.instance.removeListener(flutterEventToLeakTracker);
    }
  });
}
