// May be content of this file will go to leak_tracker.

import 'package:flutter/foundation.dart';
import 'package:leak_tracker/leak_tracker.dart';

import 'widget_tester.dart';

void setUpLeakTracking() {
  assert(!LeakTracking.isStarted);

}

void maybeTearDownLeakTracking() {
  if (!LeakTracking.isStarted) {
    return;
  }
}

WidgetTesterCallback wrapWithLeakTracking(
  String description,
  WidgetTesterCallback callback,
  LeakTesting? leakTesting,
) {
  final LeakTesting settings = leakTesting ?? LeakTesting.settings;

  if (settings.ignore) {
    return callback;
  }

  if (!_isPlatformSupported) {
    _maybePrintPlatformWarning();
    return callback;
  }

  setUpLeakTracking();

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
// Should be moved to leak_tracker_flutter_testing:
// (This means one more dependency!)

bool _notSupportedWarningPrinted = false;
bool get _isPlatformSupported => !kIsWeb;
void _maybePrintPlatformWarning() {
  if (!LeakTracking.warnForUnsupportedPlatforms || _isPlatformSupported || _notSupportedWarningPrinted) {
    return;
  }
  _notSupportedWarningPrinted = true;
  debugPrint(
    'Leak tracking is not supported on this platform.\n'
    'To turn off this message, set `LeakTracking.warnForNotSupportedPlatforms` to false.',
  );
}

/////////////
// Should be moved to leak_tracker:

