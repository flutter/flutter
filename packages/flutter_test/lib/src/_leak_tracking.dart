// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:leak_tracker/leak_tracker.dart';

import 'leak_tracking.dart';
import 'test_async_utils.dart';
import 'widget_tester.dart';

bool _webWarningPrinted = false;

/// Runs [callback] and verifies that it does not leak memory.
///
/// The method will fail with test matcher error if wrapped code contains memory leaks.
///
/// The function is a unit test friendly wrapper for [withLeakTracking] with Flutter specific functionality.
/// See more details at
/// https://github.com/dart-lang/leak_tracker#flutter-tests
///
/// The Flutter related enhancements are:
/// 1. Listens to [MemoryAllocations] events.
/// 2. Uses [tester.runAsync] for async call for leak detection.
///
/// Customize [config], if test fails and troubleshooting is needed. See
/// details at [LeakTrackingFlutterTestConfig].
Future<void> withFlutterLeakTracking(
  DartAsyncCallback callback, {
  required WidgetTester tester,
  LeakTrackingFlutterTestConfig config = const LeakTrackingFlutterTestConfig(),
}) async {
  // Leak tracker does not work for web platform.
  if (kIsWeb) {
    if (!_webWarningPrinted) {
      _webWarningPrinted = true;
      debugPrint('Leak tracking is not supported on web platform.');
    }
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
        asyncCodeRunner: tester.runAsync,
        stackTraceCollectionConfig: config.stackTraceCollectionConfig,
        shouldThrowOnLeaks: false,
      );

      if (leaks.total == 0) {
        return;
      }

      config.onLeaks?.call(leaks);

      if (config.failTestOnLeaks) {
        expect(leaks, isLeakFree);
      }
    } finally {
      MemoryAllocations.instance.removeListener(flutterEventToLeakTracker);
    }
  });
}
