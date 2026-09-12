// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;

import 'package:android_driver_extensions/native_driver.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

/// Smoke test: verifies that when HCPP is enabled, all three
/// legacy platform view creation APIs (HC via initExpensiveAndroidView,
/// TLHC with HC fallback via initSurfaceAndroidView, and
/// TLHC with VD fallback via initAndroidView) are upgraded to HCPP mode
/// without crashing. When HCPP is disabled via --no-enable-hcpp,
/// verifies that all three fall back to their legacy creation strategies.
void main() async {
  late final FlutterDriver flutterDriver;
  late final NativeDriver nativeDriver;
  final expectHcpp = io.Platform.environment['EXPECT_HCPP'] != 'false';

  setUpAll(() async {
    flutterDriver = await FlutterDriver.connect();
    nativeDriver = await AndroidNativeDriver.connect(flutterDriver);
    await flutterDriver.waitUntilFirstFrameRasterized();
  });

  tearDownAll(() async {
    await nativeDriver.close();
    await flutterDriver.close();
  });

  test('verify that HCPP is ${expectHcpp ? "supported and enabled" : "disabled"}', () async {
    final response = json.decode(await flutterDriver.requestData('')) as Map<String, Object?>;
    expect(response['supported'], expectHcpp);
  }, timeout: Timeout.none);

  test('all three platform view types render without crashing', () async {
    final Health health = await flutterDriver.checkHealth();
    expect(health.status, HealthStatus.ok);
  }, timeout: Timeout.none);

  test('all three platform view types dispose without crashing', () async {
    await flutterDriver.tap(find.byValueKey('ToggleViews'));
    await Future<void>.delayed(const Duration(seconds: 1));

    final Health health = await flutterDriver.checkHealth();
    expect(health.status, HealthStatus.ok);
  }, timeout: Timeout.none);

  test('verify platform view rendering strategy via logcat', () async {
    // Poll logcat until expected log entries appear or timeout expires.
    // 500ms polling interval avoids hammering adb while remaining responsive.
    // 30-second timeout accommodates slower emulators in CI under high load.
    const pollInterval = Duration(milliseconds: 500);
    const maxPollDuration = Duration(seconds: 30);
    final stopwatch = Stopwatch()..start();
    var hcppCount = 0;
    var legacyCount = 0;
    var logcat = '';

    while (stopwatch.elapsed < maxPollDuration) {
      final io.ProcessResult result = await io.Process.run('adb', <String>[
        'logcat',
        '-d',
        '-s',
        'PlatformViewsChannel:*',
      ]);
      logcat = result.stdout as String;

      // We expect 3 platform views to be created.
      hcppCount = 'Using HCPP platform view rendering strategy.'.allMatches(logcat).length;
      legacyCount = 'Using legacy platform view rendering strategy.'.allMatches(logcat).length;

      if (expectHcpp && hcppCount >= 3) {
        break;
      }
      if (!expectHcpp && legacyCount >= 3) {
        break;
      }
      await Future<void>.delayed(pollInterval);
    }

    if (expectHcpp) {
      expect(
        hcppCount,
        3,
        reason:
            'Expected 3 HCPP creations (one per view type), '
            'got $hcppCount. Logcat:\n$logcat',
      );
      expect(
        legacyCount,
        0,
        reason:
            'Expected 0 legacy creations, '
            'got $legacyCount. Logcat:\n$logcat',
      );
    } else {
      expect(
        hcppCount,
        0,
        reason:
            'Expected 0 HCPP creations when HCPP is disabled, '
            'got $hcppCount. Logcat:\n$logcat',
      );
      expect(
        legacyCount,
        3,
        reason:
            'Expected 3 legacy creations when HCPP is disabled, '
            'got $legacyCount. Logcat:\n$logcat',
      );
    }
  }, timeout: Timeout.none);
}
