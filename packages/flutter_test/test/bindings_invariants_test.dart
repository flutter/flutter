// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Generates test cases for a debug variable or test setting.
//
// The `name` argument is the identifier of the variable or setting being tested.
//
// The `mutateAndGetReset` callback modifies the variable or setting and
// returns a [VoidCallback] that restores it to its original value.
//
// The `expectedErrorMessage` is the message expected on the [FlutterError]
// reported by [TestWidgetsFlutterBinding.postTest] when the variable is left
// modified.
void _testDebugVariable({
  required String name,
  required VoidCallback Function(TestWidgetsFlutterBinding binding) mutateAndGetReset,
  required String expectedErrorMessage,
}) {
  group('$name:', () {
    // Verifies that the variable can be mutated in [testWidgets] and cleanly
    // reset via [addTearDown] without triggering invariant failures.
    testWidgets('can be reset with addTearDown', (WidgetTester tester) async {
      final VoidCallback reset = mutateAndGetReset(tester.binding);
      addTearDown(reset);
    });

    // Verifies that when mutated during a test without being reset,
    // [TestWidgetsFlutterBinding.postTest] catches the invariant failure, reports
    // it via [reportTestException] with [expectedErrorMessage], and finishes
    // cleaning up the binding state without throwing.
    test('direct runTest with unreset it reports exception in postTest', () async {
      FlutterErrorDetails? reportedError;
      final TestExceptionReporter oldReporter = reportTestException;
      reportTestException = (FlutterErrorDetails details, String testDescription) {
        reportedError = details;
      };
      addTearDown(() {
        reportTestException = oldReporter;
      });

      final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
      late final VoidCallback reset;
      await binding.runTest(() async {
        reset = mutateAndGetReset(binding);
      }, () {});

      expect(() => binding.postTest(), returnsNormally);
      expect(reportedError, isNotNull);
      expect((reportedError!.exception as FlutterError).message, expectedErrorMessage);
      expect(binding.inTest, isFalse);
      reset();
    });
  });
}

void main() {
  const foundationErrorMessage =
      'The value of a foundation debug variable was changed by the test.';

  _testDebugVariable(
    name: 'debugDefaultTargetPlatformOverride',
    mutateAndGetReset: (TestWidgetsFlutterBinding binding) {
      final TargetPlatform? original = debugDefaultTargetPlatformOverride;
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      return () => debugDefaultTargetPlatformOverride = original;
    },
    expectedErrorMessage: foundationErrorMessage,
  );

  _testDebugVariable(
    name: 'debugDoublePrecision',
    mutateAndGetReset: (TestWidgetsFlutterBinding binding) {
      final int? original = debugDoublePrecision;
      debugDoublePrecision = 3;
      return () => debugDoublePrecision = original;
    },
    expectedErrorMessage: foundationErrorMessage,
  );

  _testDebugVariable(
    name: 'debugBrightnessOverride',
    mutateAndGetReset: (TestWidgetsFlutterBinding binding) {
      final Brightness? original = debugBrightnessOverride;
      debugBrightnessOverride = Brightness.dark;
      return () => debugBrightnessOverride = original;
    },
    expectedErrorMessage: foundationErrorMessage,
  );

  _testDebugVariable(
    name: 'autoUpdateGoldenFiles',
    mutateAndGetReset: (TestWidgetsFlutterBinding binding) {
      final bool original = autoUpdateGoldenFiles;
      autoUpdateGoldenFiles = !original;
      return () => autoUpdateGoldenFiles = original;
    },
    expectedErrorMessage: 'The value of autoUpdateGoldenFiles was changed by the test.',
  );

  _testDebugVariable(
    name: 'ErrorWidget.builder',
    mutateAndGetReset: (TestWidgetsFlutterBinding binding) {
      final ErrorWidgetBuilder original = ErrorWidget.builder;
      ErrorWidget.builder = (FlutterErrorDetails details) => Container();
      return () => ErrorWidget.builder = original;
    },
    expectedErrorMessage: 'The value of ErrorWidget.builder was changed by the test.',
  );

  _testDebugVariable(
    name: 'shouldPropagateDevicePointerEvents',
    mutateAndGetReset: (TestWidgetsFlutterBinding binding) {
      final bool original = binding.shouldPropagateDevicePointerEvents;
      binding.shouldPropagateDevicePointerEvents = !original;
      return () => binding.shouldPropagateDevicePointerEvents = original;
    },
    expectedErrorMessage:
        'The value of shouldPropagateDevicePointerEvents was changed by the test.',
  );

  _testDebugVariable(
    name: 'reportTestException',
    mutateAndGetReset: (TestWidgetsFlutterBinding binding) {
      final TestExceptionReporter original = reportTestException;
      reportTestException = (FlutterErrorDetails details, String testDescription) {};
      return () => reportTestException = original;
    },
    expectedErrorMessage: 'The value of reportTestException was changed by the test.',
  );

  // Verifies that when a test body fails, [TestWidgetsFlutterBinding._runTestBody]
  // leaves the widget tree intact for inspection (does not unmount it to
  // `_postTestMessage`) and [TestWidgetsFlutterBinding.postTest] skips invariant
  // verification to avoid spurious secondary errors.
  test('direct runTest with failed test body skips invariant check and preserves widget tree in postTest', () async {
    final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
    final TestExceptionReporter oldReporter = reportTestException;
    reportTestException = (FlutterErrorDetails details, String testDescription) {};
    addTearDown(() {
      reportTestException = oldReporter;
    });

    await binding.runTest(() async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      runApp(const Placeholder());
      throw Exception('test failed');
    }, () {});

    // postTest should NOT throw invariant error because the test body failed.
    expect(() => binding.postTest(), returnsNormally);
    expect(binding.inTest, isFalse);
    // The widget tree from the test is preserved for inspection rather than
    // being unmounted and replaced with _postTestMessage.
    expect(find.byType(Placeholder), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
