// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:meta/meta.dart';

// The test_api package is not for general use... it's literally for our use.
// ignore: deprecated_member_use
import 'package:test_api/test_api.dart' as test_package;

/// Wrapper for [testWidgets] with leak tracking.
///
/// This method is temporarty with the plan:
///
/// 1. For each occurence of [testWidgets] in flutter framework, do one of three:
/// * replace [testWidgets] with [testWidgetsWithLeakTracking]
/// * comment why leak tracking is not needed
/// * link bug about memory leak
///
/// 2. Enable [testWidgets] to track leaks, disabled by default for users,
/// and enabled by default for flutter framework.
///
/// 3. Replace [testWidgetsWithLeakTracking] with [testWidgets]
///
/// See https://github.com/flutter/devtools/issues/3951 for details.
@isTest
void testWidgetsWithLeakTracking(
  String description,
  WidgetTesterCallback callback, {
  bool? skip,
  test_package.Timeout? timeout,
  bool semanticsEnabled = true,
  TestVariant<Object?> variant = const DefaultTestVariant(),
  dynamic tags,
  LeakTrackingTestConfig leakTrackingConfig = const LeakTrackingTestConfig(),
}) {
  Future<void> wrappedCallback(WidgetTester tester) async {
    await _withFlutterLeakTracking(
      () async => callback(tester),
      tester,
      leakTrackingConfig,
    );
  }

  testWidgets(
    description,
    wrappedCallback,
    skip: skip,
    timeout: timeout,
    semanticsEnabled: semanticsEnabled,
    variant: variant,
    tags: tags,
  );
}

bool _webWarningPrinted = false;

/// Wrapper for [withLeakTracking] with Flutter specific functionality.
///
/// The method will fail if wrapped code contains memory leaks.
///
/// See details in documentation for `withLeakTracking` at
/// https://github.com/dart-lang/leak_tracker/blob/main/lib/src/orchestration.dart#withLeakTracking
///
/// The Flutter related enhancements are:
/// 1. Listens to [MemoryAllocations] events.
/// 2. Uses `tester.runAsync` for leak detection if [tester] is provided.
///
/// Pass [config] to troubleshoot leaks. See [LeakTrackingTestConfig] for details.
Future<void> _withFlutterLeakTracking(
  DartAsyncCallback callback,
  WidgetTester tester,
  LeakTrackingTestConfig config,
) async {
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
    Future<void> asyncCodeRunner(DartAsyncCallback action) async => tester.runAsync(action);

    try {
      final Leaks leaks = await withLeakTracking(
        callback,
        asyncCodeRunner: asyncCodeRunner,
        stackTraceCollectionConfig: config.stackTraceCollectionConfig,
        shouldThrowOnLeaks: false,
      );

      if (leaks.total > 0) {
        config.onLeaks?.call(leaks);
        if (config.failTestOnLeaks) {
          expect(leaks, isLeakFree);
        }
      }
    } finally {
      MemoryAllocations.instance.removeListener(flutterEventToLeakTracker);
    }
  });
}
