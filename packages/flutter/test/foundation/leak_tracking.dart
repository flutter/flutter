// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:meta/meta.dart';

/// Set of objects.
///
/// Does not hold the objects from garbafge collection.
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
    final result = _objectCodes.contains(_toCode(hashCode, type));
    return result;
  }
}

@visibleForTesting
class TestAdjustments {
  final WeakSet heldObjects = WeakSet();
}

extension LeakTrackerAdjustments on WidgetTester {
  static final Expando<TestAdjustments> _abjustmentsExpando = Expando<TestAdjustments>();

  T addHeldObject<T  extends Object>(T object){
    _adjustments.heldObjects.add(object);
    return object;
  }

  bool isHeld(Object object){
    return _adjustments.heldObjects.contains(
      identityHashCode(object),
      object.runtimeType.toString(),
    );
  }

  TestAdjustments get _adjustments {
    if (_abjustmentsExpando[this] == null) {
      _abjustmentsExpando[this] = TestAdjustments();
    }
    return _abjustmentsExpando[this]!;
  }
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
/// and may be enabled by default for flutter framework.
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
        stackTraceCollectionConfig: config.stackTraceCollectionConfig,
        shouldThrowOnLeaks: false,
      );

      leaks = LeakCleaner(config, tester._adjustments).clean(leaks);

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

/// Cleans leaks that are allowed by [config] and [adjustments].
@visibleForTesting
class LeakCleaner {
  LeakCleaner(this.config, this.adjustments);

  final LeakTrackingTestConfig config;
  final TestAdjustments adjustments;

  Leaks clean(Leaks leaks) {
    final result =  Leaks(<LeakType, List<LeakReport>>{
      for (LeakType leakType in leaks.byType.keys)
        leakType: leaks.byType[leakType]!.where((LeakReport leak) => !_isLeakAllowed(leakType, leak)).toList()
    });
    return result;
  }

  bool _isLeakAllowed(LeakType leakType, LeakReport leak) {
    switch (leakType) {
      case LeakType.notDisposed:
        final result = config.notDisposedAllowList.contains(leak.type);
        return result;
      case LeakType.notGCed:
      case LeakType.gcedLate:
        final result = config.notGCedAllowList.contains(leak.type) ||
            adjustments.heldObjects.contains(leak.code, leak.type);
        return result;
    }
  }
}
