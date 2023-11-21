import 'package:flutter/foundation.dart';
import 'package:leak_tracker/leak_tracker.dart';
import 'package:leak_tracker_testing/leak_tracker_testing.dart';

import 'widget_tester.dart';



WidgetTesterCallback maybeWrapWithLeakTracking(
  String description,
  WidgetTesterCallback callback,
  LeakTesting? leakTesting,
) {
  final LeakTesting settings = leakTesting ?? LeakTesting.settings;

  if (settings.ignore) {
    return callback;
  }

  if (!checkPlatformAndMayBePrintWarning(platformName: defaultTargetPlatform.name, isBrowser: kIsWeb)) {
    return callback;
  }

  _setUpLeakTracking();

  Future<void> wrappedCallBack(WidgetTester tester) async {
    final PhaseSettings phase = PhaseSettings(
      name: description,
      leakDiagnosticConfig: settings.leakDiagnosticConfig,
      ignoredLeaks: settings.ignoredLeaks,
      baselining: settings.baselining,
      ignoreLeaks: settings.ignore,
    );

    LeakTracking.phase = phase;
    await callback(tester);
    LeakTracking.phase = const PhaseSettings.ignored();
  }

  return wrappedCallBack;
}


/////////////
// Should be moved to leak_tracker:


void mayBeSetupLeakTrackingForTest(LeakTesting settings, String testDescription) {
  if (settings.ignore) return;

  if (!checkPlatformAndMayBePrintWarning(platformName: defaultTargetPlatform.name, isBrowser: kIsWeb)) {
    return;
  }

  _setUpLeakTracking();

  final PhaseSettings phase = PhaseSettings(
      name: testDescription,
      leakDiagnosticConfig: settings.leakDiagnosticConfig,
      ignoredLeaks: settings.ignoredLeaks,
      baselining: settings.baselining,
      ignoreLeaks: settings.ignore,
  );

  LeakTracking.phase = phase;
}

void _dispatchFlutterEventToLeakTracker(ObjectEvent event) {
  return LeakTracking.dispatchObjectEvent(event.toMap());
}

/// Handler for memory leaks found by `testWidgets`.
///
/// Set it to analyse the leaks programmatically.
/// The handler is invoked on tear down of the test run.
/// The default reporter fails in case of found leaks.
///
/// Used to test leak tracking functionality of `testWidgets`.
LeaksCallback experimentalCollectedLeaksReporter = (Leaks leaks) => expect(leaks, isLeakFree);



bool _notSupportedWarningPrinted = false;

/// Checks if platform supported and, if no, prints warning if the warning is needed.
///
/// Warning is printed one time if `LeakTracking.warnForNotSupportedPlatforms` is true.
bool checkPlatformAndMayBePrintWarning({required String platformName, required bool isBrowser}) {
  final isSupported = !isBrowser;

  if (isSupported) return true;

  final shouldPrintWarning = LeakTracking.warnForUnsupportedPlatforms && !_notSupportedWarningPrinted;

  if (!shouldPrintWarning) return false;

  _notSupportedWarningPrinted = true;
  debugPrint(
    "Leak tracking is not supported on the platform '$platformName'.\n"
    'To turn off this message, set `LeakTracking.warnForNotSupportedPlatforms` to false.',
  );

  return false;
}


void _setUpLeakTracking() {
  assert(!LeakTracking.isStarted);

  LeakTracking.phase = const PhaseSettings.ignored();
  LeakTracking.start(config: LeakTrackingConfig.passive());
  MemoryAllocations.instance.addListener(_dispatchFlutterEventToLeakTracker);
}

/// Should be invoked after all tests.
Future<void> maybeTearDownLeakTracking() async {
  if (!LeakTracking.isStarted) {
    return;
  }

  MemoryAllocations.instance.removeListener(_dispatchFlutterEventToLeakTracker);

  LeakTracking.declareNotDisposedObjectsAsLeaks();
  await forceGC(fullGcCycles: defaultNumberOfGcCycles);
  final Leaks leaks = await LeakTracking.collectLeaks();
  LeakTracking.stop();

  if (leaks.total == 0) {
    return;
  }
  experimentalCollectedLeaksReporter(leaks);
}
