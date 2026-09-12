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
  int? appPid;

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
    appPid = response['pid'] as int?;
  }, timeout: Timeout.none);

  test('all three platform view types render without crashing', () async {
    final Health health = await flutterDriver.checkHealth();
    expect(health.status, HealthStatus.ok);
  }, timeout: Timeout.none);

  test('all three platform view types dispose without crashing', () async {
    await flutterDriver.tap(find.byValueKey('ToggleViews'));
    // 1-second delay allows platform view disposal animations and unparenting to settle.
    await Future<void>.delayed(const Duration(seconds: 1));

    final Health health = await flutterDriver.checkHealth();
    expect(health.status, HealthStatus.ok);
  }, timeout: Timeout.none);

  test('verify platform view rendering strategy via logcat', () async {
    // Ensure we have the application PID to isolate this process's logcat entries.
    if (appPid == null) {
      final response = json.decode(await flutterDriver.requestData('')) as Map<String, Object?>;
      appPid = response['pid'] as int?;
    }

    // Poll logcat until expected log entries appear or timeout expires.
    // 500ms polling interval avoids hammering adb while remaining responsive.
    // 30-second timeout accommodates slower emulators in CI under high load.
    const pollInterval = Duration(milliseconds: 500);
    const maxPollDuration = Duration(seconds: 30);
    // Three platform views are created: HC, TLHC with HC fallback, and TLHC with VD fallback.
    const expectedViewCount = 3;
    const expectedZeroCount = 0;
    final stopwatch = Stopwatch()..start();
    var hcppCount = 0;
    var legacyCount = 0;
    var rawLogcat = '';
    var filteredLogcat = '';

    while (stopwatch.elapsed < maxPollDuration) {
      final io.ProcessResult result = await io.Process.run('adb', <String>[
        'logcat',
        '-d',
        '-s',
        'PlatformViewsChannel:*',
      ]);
      rawLogcat = result.stdout as String;

      // Filter logcat lines to only include entries from the current application process.
      // On Android, logcat threadtime format includes the PID as a discrete column (e.g., " 7500 ").
      // Also match brief/process format delimiters (e.g., "(7500)", "( 7500)") defensively.
      final Iterable<String> lines = rawLogcat.split('\n').where((String line) {
        if (appPid == null) {
          return true;
        }
        return line.contains(' $appPid ') ||
            line.contains(' $appPid:') ||
            line.contains('($appPid)') ||
            line.contains('( $appPid)');
      });
      filteredLogcat = lines.join('\n');

      hcppCount = 'Using HCPP platform view rendering strategy.'.allMatches(filteredLogcat).length;
      legacyCount = 'Using legacy platform view rendering strategy.'
          .allMatches(filteredLogcat)
          .length;

      if (expectHcpp && hcppCount >= expectedViewCount) {
        break;
      }
      if (!expectHcpp && legacyCount >= expectedViewCount) {
        break;
      }
      await Future<void>.delayed(pollInterval);
    }

    if (expectHcpp) {
      expect(
        hcppCount,
        expectedViewCount,
        reason:
            'Expected $expectedViewCount HCPP creations (one per view type), '
            'got $hcppCount. Filtered logcat:\n$filteredLogcat\nRaw logcat:\n$rawLogcat',
      );
      expect(
        legacyCount,
        expectedZeroCount,
        reason:
            'Expected $expectedZeroCount legacy creations, '
            'got $legacyCount. Filtered logcat:\n$filteredLogcat\nRaw logcat:\n$rawLogcat',
      );
    } else {
      expect(
        hcppCount,
        expectedZeroCount,
        reason:
            'Expected $expectedZeroCount HCPP creations when HCPP is disabled, '
            'got $hcppCount. Filtered logcat:\n$filteredLogcat\nRaw logcat:\n$rawLogcat',
      );
      expect(
        legacyCount,
        expectedViewCount,
        reason:
            'Expected $expectedViewCount legacy creations when HCPP is disabled, '
            'got $legacyCount. Filtered logcat:\n$filteredLogcat\nRaw logcat:\n$rawLogcat',
      );
    }
  }, timeout: Timeout.none);
}
