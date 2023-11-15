// May be content of this file will go to leak_tracker.

void configureLeakTracking() {

}

void tearDownLeakTracking() {

}

/// Signature for callback to [testWidgets] and [benchmarkWidgets].
typedef WidgetTesterCallback = Future<void> Function(WidgetTester widgetTester);

WidgetTesterCallback wrapWithLeakTracking(
  String description,
  WidgetTesterCallback callback,
  LeakTesting? leakTesting,
) {


  // This cannot be done just once, because, if a test file starts with a group,
  // the tear down will happen after group, not after all tests.
  // It cannot be done in `tearDown`, because user defined tear down, that may do disposal
  // will happen after `tearDown` defined here.
  // This is done unconditionally, even if settings.ignore is true,
  // because settings.ignore may be different for different tests
  // and it is not known at this point if there are tests with leak tracking enabled.
  tearDownAll(() async {
    await _mayBeFinalizeLeakTracking();
  });

  Future<void> wrappedCallBack(WidgetTester tester) async {
    final LeakTesting settings = leakTesting ?? LeakTesting.settings;

    if (settings.ignore) {
      await callback(tester);
      return;
    }

    if (!_isPlatformSupported) {
      _maybePrintPlatformWarning();
      await callback(tester);
      return;
    }

    final PhaseSettings phase = PhaseSettings(
      name: description,
      leakDiagnosticConfig: settings.leakDiagnosticConfig,
      ignoredLeaks: settings.ignoredLeaks,
      baselining: settings.baselining,
      ignoreLeaks: settings.ignore,
    );

    if (!LeakTracking.isStarted) {
      _setUpLeakTracking();
    }

    LeakTracking.phase = phase;
    await callback(tester);
    LeakTracking.phase = const PhaseSettings.ignored();
  }

  return wrappedCallBack;
}

