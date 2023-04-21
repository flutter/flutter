// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:meta/meta.dart';

/// Configuration for leak tracking in unit tests.
class LeakTrackingTestConfig {
  /// Creates a new instance of [LeakTrackingFlutterTestConfig].
  const LeakTrackingTestConfig({
    this.stackTraceCollectionConfig = const StackTraceCollectionConfig(),
    this.onLeaks,
    this.failTestOnLeaks = true,
    this.notGcedAllowList = const <String>{},
    this.notDisposedAllowList = const <String>{},
  });

  /// If true, warning will be printed when leak tracking is
  /// requested for a non-supported platform.
  static bool warnForNonSupportedPlatforms = true;

  /// When to collect stack trace information.
  ///
  /// Knowing call stack may help to troubleshoot memory leaks.
  /// Customize this parameter to collect stack traces when needed.
  final StackTraceCollectionConfig stackTraceCollectionConfig;
  /// Handler to obtain details about collected leaks.
  ///
  /// Use the handler to process the collected leak
  /// details programmatically.
  final LeaksCallback? onLeaks;

  /// If true, the test will fail if leaks are found.
  ///
  /// When to collect stack trace information.
  /// If false, the test will not fail if leaks are
  /// found to allow for analyzing leaks after the test completes.
  final bool failTestOnLeaks;

  /// List of classes that are allowed to be not GCed after disposal.
  ///
  /// As returned by `object.runtimeType.toString()`.
  final Set<String> notGcedAllowList;

  /// List of classes that are allowed to be GCed without disposal.
  ///
  /// As returned by `object.runtimeType.toString()`.
  final Set<String> notDisposedAllowList;
}


/// Wrapper for [testWidgets] with leak tracking.
///
/// This method is temporal with the plan:
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
  Timeout? timeout,
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
/// Pass [config] to troublceshoot or exempt leaks. See [LeakTrackingTestConfig]
/// for details.
Future<void> _withFlutterLeakTracking(
  DartAsyncCallback callback,
  WidgetTester tester,
  LeakTrackingTestConfig config,
) async {
  print('!!! _withFlutterLeakTracking: ${LeakTrackingTestConfig.warnForNonSupportedPlatforms}');
  // Leak tracker does not work for web platform.
  if (kIsWeb) {
    final bool shouldPrintWarning = !_webWarningPrinted && LeakTrackingTestConfig.warnForNonSupportedPlatforms;
    print('!!! shouldPrintWarning: $shouldPrintWarning');
    if (shouldPrintWarning) {
      _webWarningPrinted = true;
      debugPrint('Leak tracking is not supported on web platform.\nTo turn off this message, set `LeakTrackingTestConfig.warnForNonSupportedPlatforms` to false.');
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
      Leaks leaks = await withLeakTracking(
        callback,
        asyncCodeRunner: asyncCodeRunner,
        stackTraceCollectionConfig: config.stackTraceCollectionConfig,
        shouldThrowOnLeaks: false,
      );

      leaks = _cleanUpLeaks(leaks, config);

      if (leaks.total > 0) {
        config.onLeaks?.call(leaks);
        if (config.failTestOnLeaks) {
          expect(leaks, isLeakFree, reason: 'Set allow lists in $LeakTrackingTestConfig to ignore leaks.');
        }
      }
    } finally {
      MemoryAllocations.instance.removeListener(flutterEventToLeakTracker);
    }
  });
}

/// Removes leaks that are allowed by [config].
Leaks _cleanUpLeaks(Leaks leaks, LeakTrackingTestConfig config) {
  final Map<LeakType, List<LeakReport>> cleaned = <LeakType, List<LeakReport>>{
    LeakType.notGCed: <LeakReport>[],
    LeakType.notDisposed: <LeakReport>[],
    LeakType.gcedLate: <LeakReport>[],
  };

  for (final LeakReport leak in leaks.notGCed) {
    if (!config.notGcedAllowList.contains(leak.type)) {
      cleaned[LeakType.notGCed]!.add(leak);
    }
  }

  for (final LeakReport leak in leaks.gcedLate) {
    if (!config.notGcedAllowList.contains(leak.type)) {
      cleaned[LeakType.gcedLate]!.add(leak);
    }
  }

  for (final LeakReport leak in leaks.notDisposed) {
    if (!config.notGcedAllowList.contains(leak.type)) {
      cleaned[LeakType.notDisposed]!.add(leak);
    }
  }
  return Leaks(cleaned);
}
