// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';
import 'package:meta/meta.dart';

export 'package:leak_tracker/leak_tracker.dart' show LeakDiagnosticConfig, LeakTrackingTestConfig;

/// Set of objects, that does not hold the objects from garbage collection.
///
/// The objects are referenced by hash codes and can duplicate with low probability.
@visibleForTesting
class WeakSet {
  final Set<String> _objectCodes = <String>{};

  String _toCode(int hashCode, String type) => '$type-$hashCode';

  void add(Object object) {
    _objectCodes.add(_toCode(identityHashCode(object), object.runtimeType.toString()));
  }

  void addByCode(int hashCode, String type) {
    _objectCodes.add(_toCode(hashCode, type));
  }

  bool contains(int hashCode, String type) {
    final bool result = _objectCodes.contains(_toCode(hashCode, type));
    return result;
  }
}

/// Wrapper for [testWidgets] with memory leak tracking.
///
/// The method will fail if instrumented objects in [callback] are
/// garbage collected without being disposed.
///
/// More about leak tracking:
/// https://github.com/dart-lang/leak_tracker.
///
/// See https://github.com/flutter/devtools/issues/3951 for plans
/// on leak tracking.
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

/// Runs [callback] with leak tracking.
///
/// Wrapper for [withLeakTracking] with Flutter specific functionality.
///
/// The method will fail if wrapped code contains memory leaks.
///
/// See details in documentation for `withLeakTracking` at
/// https://github.com/dart-lang/leak_tracker/blob/main/lib/src/leak_tracking/orchestration.dart
///
/// The Flutter related enhancements are:
/// 1. Listens to [MemoryAllocations] events.
/// 2. Uses `tester.runAsync` for leak detection if [tester] is provided.
///
/// Pass [config] to troubleshoot or exempt leaks. See [LeakTrackingTestConfig]
/// for details.
Future<void> _withFlutterLeakTracking(
  DartAsyncCallback callback,
  WidgetTester tester,
  LeakTrackingTestConfig config,
) async {
  // Leak tracker does not work for web platform.
  if (kIsWeb) {
    final bool shouldPrintWarning = !_webWarningPrinted && LeakTrackingTestConfig.warnForNonSupportedPlatforms;
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
        leakDiagnosticConfig: config.leakDiagnosticConfig,
        shouldThrowOnLeaks: false,
      );

      leaks = LeakCleaner(config).clean(leaks);

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

/// Cleans leaks that are allowed by [config].
@visibleForTesting
class LeakCleaner {
  LeakCleaner(this.config);

  final LeakTrackingTestConfig config;

  static Map<(String, LeakType), int> _countByClassAndType(Leaks leaks) {
    final Map<(String, LeakType), int> result = <(String, LeakType), int>{};

    for (final MapEntry<LeakType, List<LeakReport>> entry in leaks.byType.entries) {
      for (final LeakReport leak in entry.value) {
        final (String, LeakType) classAndType = (leak.type, entry.key);
        result[classAndType] = (result[classAndType] ?? 0) + 1;
      }
    }
    return result;
  }

  Leaks clean(Leaks leaks) {
    final Map<(String, LeakType), int> countByClassAndType = _countByClassAndType(leaks);

    final Leaks result =  Leaks(<LeakType, List<LeakReport>>{
      for (final LeakType leakType in leaks.byType.keys)
        leakType: leaks.byType[leakType]!.where((LeakReport leak) => _shouldReportLeak(leakType, leak, countByClassAndType)).toList()
    });
    return result;
  }

  /// Returns true if [leak] should be reported as failure.
  bool _shouldReportLeak(LeakType leakType, LeakReport leak, Map<(String, LeakType), int> countByClassAndType) {
    // Tracking for non-GCed is temporarily disabled.
    // TODO(polina-c): turn on tracking for non-GCed after investigating existing leaks.
    if (leakType != LeakType.notDisposed) {
      return false;
    }

    final String leakingClass = leak.type;
    final (String, LeakType) classAndType = (leakingClass, leakType);

    bool isAllowedForClass(Map<String, int?> allowList) {
      if (!allowList.containsKey(leakingClass)) {
        return false;
      }
      final int? allowedCount = allowList[leakingClass];
      if (allowedCount == null) {
        return true;
      }
      return allowedCount >= countByClassAndType[classAndType]!;
    }

    switch (leakType) {
      case LeakType.notDisposed:
        return !isAllowedForClass(config.notDisposedAllowList);
      case LeakType.notGCed:
      case LeakType.gcedLate:
        return !isAllowedForClass(config.notGCedAllowList);
    }
  }
}
