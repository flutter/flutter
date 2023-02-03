// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';

typedef LeaksObtainer = void Function(Leaks foundLeaks);

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
/// If you use [testWidgets], pass [tester] to avoid async issues in leak processing.
/// Pass null otherwise.
///
/// Pass [leaksObtainer] if you want to get leak information before
/// the method failure.
Future<void> withFlutterLeakTracking(
  DartAsyncCallback callback, {
  required WidgetTester? tester,
  StackTraceCollectionConfig stackTraceCollectionConfig =
      const StackTraceCollectionConfig(),
  Duration? timeoutForFinalGarbageCollection,
  LeaksObtainer? leaksObtainer,
}) async {
  // The method is copied (with improvements) from
  // `package:leak_tracker/test/test_infra/flutter_helpers.dart`.

  // The method is not combined with [testWidgets], because the combining will
  // impact VSCode's ability to recognize tests.

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
    final AsyncCodeRunner asyncCodeRunner = tester == null
        ? (DartAsyncCallback action) async => action()
        : (DartAsyncCallback action) async => tester.runAsync(action);
    try {
      final Leaks leaks = await withLeakTracking(
        callback,
        asyncCodeRunner: asyncCodeRunner,
        stackTraceCollectionConfig: stackTraceCollectionConfig,
        shouldThrowOnLeaks: false,
        timeoutForFinalGarbageCollection: timeoutForFinalGarbageCollection,
      );
      if (leaksObtainer != null) {
        leaksObtainer(leaks);
      }
      expect(leaks, isLeakFree);
    } finally {
      MemoryAllocations.instance.removeListener(flutterEventToLeakTracker);
    }
  });
}
