// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('foundation debug variables can be reset with addTearDown', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    debugDoublePrecision = 3;
    debugBrightnessOverride = Brightness.dark;
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      debugDoublePrecision = null;
      debugBrightnessOverride = null;
    });

    expect(defaultTargetPlatform, TargetPlatform.macOS);
    expect(debugDoublePrecision, 3);
    expect(debugBrightnessOverride, Brightness.dark);
  });

  testWidgets('autoUpdateGoldenFiles can be reset with addTearDown', (WidgetTester tester) async {
    final bool original = autoUpdateGoldenFiles;
    autoUpdateGoldenFiles = true;
    addTearDown(() {
      autoUpdateGoldenFiles = original;
    });

    expect(autoUpdateGoldenFiles, isTrue);
  });

  testWidgets('ErrorWidget.builder can be reset with addTearDown', (WidgetTester tester) async {
    final ErrorWidgetBuilder original = ErrorWidget.builder;
    ErrorWidget.builder = (FlutterErrorDetails details) => Container();
    addTearDown(() {
      ErrorWidget.builder = original;
    });
  });

  testWidgets('shouldPropagateDevicePointerEvents can be reset with addTearDown', (
    WidgetTester tester,
  ) async {
    final bool original = tester.binding.shouldPropagateDevicePointerEvents;
    tester.binding.shouldPropagateDevicePointerEvents = true;
    addTearDown(() {
      tester.binding.shouldPropagateDevicePointerEvents = original;
    });
  });

  test('direct runTest invariant failure throws in postTest and cleans up binding', () async {
    final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
    await binding.runTest(() async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    }, () {});

    expect(
      () => binding.postTest(),
      throwsA(
        isA<FlutterError>().having(
          (FlutterError e) => e.message,
          'message',
          'The value of a foundation debug variable was changed by the test.',
        ),
      ),
    );
    // Ensure cleanup still happened despite postTest throwing
    expect(binding.inTest, isFalse);
    debugDefaultTargetPlatformOverride = null;
  });

  test('direct runTest with failed test body skips invariant check in postTest', () async {
    final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
    final TestExceptionReporter oldReporter = reportTestException;
    reportTestException = (FlutterErrorDetails details, String testDescription) {};
    addTearDown(() {
      reportTestException = oldReporter;
    });

    await binding.runTest(() async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      throw Exception('test failed');
    }, () {});

    // postTest should NOT throw invariant error because the test body failed
    expect(() => binding.postTest(), returnsNormally);
    expect(binding.inTest, isFalse);
    debugDefaultTargetPlatformOverride = null;
  });
}
