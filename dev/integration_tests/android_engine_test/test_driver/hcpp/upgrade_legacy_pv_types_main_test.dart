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
    // Clear logcat before the test so we only see logs from this run.
    await io.Process.run('adb', <String>['logcat', '-c']);

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
    // Dump logcat filtered to the PlatformViewsChannel tag.
    final io.ProcessResult result = await io.Process.run('adb', <String>[
      'logcat',
      '-d',
      '-s',
      'PlatformViewsChannel:*',
    ]);
    final logcat = result.stdout as String;

    // We created 3 platform views.
    final int hcppCount = 'Using HCPP platform view rendering strategy.'.allMatches(logcat).length;
    final int legacyCount = 'Using legacy platform view rendering strategy.'
        .allMatches(logcat)
        .length;

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
