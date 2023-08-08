// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(polina-c): start referencing this code in leak_tracker_flutter
// https://github.com/dart-lang/leak_tracker/issues/52

import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';
import 'package:meta/meta.dart';

export 'package:leak_tracker/leak_tracker.dart' show LeakDiagnosticConfig;


void _flutterEventToLeakTracker(ObjectEvent event) {
  return LeakTracking.dispatchObjectEvent(event.toMap());
}

void _setUpTestingWithLeakTracking() {
  _printPlatformWarningIfNeeded();
  if (!_isPlatformSupported) {
    return;
  }

  LeakTracking.phase = const PhaseSettings.paused();
  LeakTracking.start(config: LeakTrackingConfig.passive());

  MemoryAllocations.instance.addListener(_flutterEventToLeakTracker);
}

bool _stopConfiguringTearDown = false;

/// Sets [tearDownAll] to tear down leak tracking if it is started.
///
/// [configureOnce] is true tear down will be created just once,
/// not for every test.
/// Multiple [tearDownAll] is needed to handle test groups that have
/// own [tearDownAll].
void configureLeakTrackingTearDown({
  LeaksCallback? onLeaks,
  bool configureOnce = false,
}) {
  if (_isPlatformSupported && !_stopConfiguringTearDown) {
    tearDownAll(() async {
      if (LeakTracking.isStarted) {
        await _tearDownTestingWithLeakTracking(onLeaks);
      }
    });
  }
  if (configureOnce) {
    _stopConfiguringTearDown = true;
  }
}

Future<void> _tearDownTestingWithLeakTracking(LeaksCallback? onLeaks) async {
  if (!LeakTracking.isStarted) {
    return;
  }
  if (!_isPlatformSupported) {
    return;
  }

  MemoryAllocations.instance.removeListener(_flutterEventToLeakTracker);
  await forceGC(fullGcCycles: 3);
  final Leaks leaks = await LeakTracking.collectLeaks();

  LeakTracking.stop();

  if (leaks.total == 0) {
    return;
  }
  if (onLeaks == null) {
    expect(leaks, isLeakFree);
  } else {
    onLeaks(leaks);
  }
}

/// Wrapper for [testWidgets] with memory leak tracking.
///
/// The test will fail if instrumented objects in [callback] are
/// garbage collected without being disposed or not garbage
/// collected soon after disposal.
///
/// [testExecutableWithLeakTracking] must be invoked
/// for this test run.
///
/// More about leak tracking:
/// https://github.com/dart-lang/leak_tracker.
@isTest
void testWidgetsWithLeakTracking(
  String description,
  WidgetTesterCallback callback, {
  bool? skip,
  Timeout? timeout,
  bool semanticsEnabled = true,
  TestVariant<Object?> variant = const DefaultTestVariant(),
  dynamic tags,
  LeakTrackingTestConfig leakTrackingTestConfig =
      const LeakTrackingTestConfig(),
}) {
  configureLeakTrackingTearDown();

  final PhaseSettings phase = PhaseSettings(
    name: description,
    leakDiagnosticConfig: leakTrackingTestConfig.leakDiagnosticConfig,
    notGCedAllowList: leakTrackingTestConfig.notGCedAllowList,
    notDisposedAllowList: leakTrackingTestConfig.notDisposedAllowList,
    allowAllNotDisposed: leakTrackingTestConfig.allowAllNotDisposed,
    allowAllNotGCed: leakTrackingTestConfig.allowAllNotGCed,
  );

  Future<void> wrappedCallBack(WidgetTester tester) async {
    if (!LeakTracking.isStarted) {
      _setUpTestingWithLeakTracking();
    }
    LeakTracking.phase = phase;
    await callback(tester);
    LeakTracking.phase = const PhaseSettings.paused();
  }

  testWidgets(
    description,
    wrappedCallBack,
    skip: skip,
    timeout: timeout,
    semanticsEnabled: semanticsEnabled,
    variant: variant,
    tags: tags,
  );
}

bool _notSupportedWarningPrinted = false;
bool get _isPlatformSupported => !kIsWeb;
void _printPlatformWarningIfNeeded() {
  if (kIsWeb) {
    final bool shouldPrintWarning = !_notSupportedWarningPrinted &&
        LeakTracking.warnForUnsupportedPlatforms;
    if (shouldPrintWarning) {
      _notSupportedWarningPrinted = true;
      debugPrint(
        'Leak tracking is not supported on web platform.\nTo turn off this message, set `LeakTracking.warnForNotSupportedPlatforms` to false.',
      );
    }
    return;
  }
  assert(_isPlatformSupported);
}

/// Configuration for leak tracking in unit tests.
///
/// Customized configuration is needed only for test debugging,
/// not for regular test runs.
class LeakTrackingTestConfig {
  /// Creates a new instance of [LeakTrackingTestConfig].
  const LeakTrackingTestConfig({
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(),
    this.notGCedAllowList = const <String, int>{},
    this.notDisposedAllowList = const <String, int>{},
    this.allowAllNotDisposed = false,
    this.allowAllNotGCed = false,
  });

  /// Creates a new instance of [LeakTrackingTestConfig] for debugging leaks.
  ///
  /// This configuration will collect stack traces on start and disposal,
  /// and retaining path for notGCed objects.
  LeakTrackingTestConfig.debug({
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(
      collectStackTraceOnStart: true,
      collectStackTraceOnDisposal: true,
      collectRetainingPathForNotGCed: true,
    ),
    this.notGCedAllowList = const <String, int>{},
    this.notDisposedAllowList = const <String, int>{},
    this.allowAllNotDisposed = false,
    this.allowAllNotGCed = false,
  });

  /// Creates a new instance of [LeakTrackingTestConfig] to collect retaining path.
  ///
  /// This configuration will not collect stack traces,
  /// and will collect retaining path for notGCed objects.
  LeakTrackingTestConfig.retainingPath({
    this.leakDiagnosticConfig = const LeakDiagnosticConfig(
      collectRetainingPathForNotGCed: true,
    ),
    this.notGCedAllowList = const <String, int>{},
    this.notDisposedAllowList = const <String, int>{},
    this.allowAllNotDisposed = false,
    this.allowAllNotGCed = false,
  });

  /// Classes that are allowed to be not garbage collected after disposal.
  ///
  /// Maps name of the class, as returned by `object.runtimeType.toString()`,
  /// to the number of instances of the class that are allowed to be not GCed.
  ///
  /// If number of instances is [null], any number of instances is allowed.
  final Map<String, int?> notGCedAllowList;

  /// Classes that are allowed to be garbage collected without being disposed.
  ///
  /// Maps name of the class, as returned by `object.runtimeType.toString()`,
  /// to the number of instances of the class that are allowed to be not disposed.
  ///
  /// If number of instances is [null], any number of instances is allowed.
  final Map<String, int?> notDisposedAllowList;

  /// If true, all notDisposed leaks will be allowed.
  final bool allowAllNotDisposed;

  /// If true, all notGCed leaks will be allowed.
  final bool allowAllNotGCed;

  /// When to collect stack trace information.
  ///
  /// Knowing call stack may help to troubleshoot memory leaks.
  /// Customize this parameter to collect stack traces when needed.
  final LeakDiagnosticConfig leakDiagnosticConfig;
}
