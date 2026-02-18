// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' as io;

import 'package:android_driver_extensions/native_driver.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

/// Smoke test: verifies that when HCPP (surface control) is enabled, all three
/// legacy platform view creation APIs (HC via initExpensiveAndroidView, TLHC
/// via initSurfaceAndroidView, and TLHC/VD via initAndroidView) are
/// transparently upgraded to HCPP mode without crashing.
///
/// Verifies the HCPP code path was taken by inspecting engine-side logcat
/// output, rather than exposing a "which mode am I in" API to Dart.
void main() async {
  late final FlutterDriver flutterDriver;
  late final NativeDriver nativeDriver;

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

  test('verify that HCPP is supported and enabled', () async {
    final response = json.decode(await flutterDriver.requestData('')) as Map<String, Object?>;
    expect(response['supported'], true);
  }, timeout: Timeout.none);

  test('all three platform view types render without crashing', () async {
    final health = await flutterDriver.checkHealth();
    expect(health.status, HealthStatus.ok);
  }, timeout: Timeout.none);

  test('all three platform view types dispose without crashing', () async {
    await flutterDriver.tap(find.byValueKey('ToggleViews'));
    await Future<void>.delayed(const Duration(seconds: 1));

    final health = await flutterDriver.checkHealth();
    expect(health.status, HealthStatus.ok);
  }, timeout: Timeout.none);

  test('verify HCPP was used for all views via logcat', () async {
    // Dump logcat filtered to the PlatformViewsChannel tag.
    final io.ProcessResult result = await io.Process.run('adb', <String>[
      'logcat',
      '-d',
      '-s',
      'PlatformViewsChannel:*',
    ]);
    final String logcat = result.stdout as String;

    // We created 3 platform views — expect 3 HCPP log lines.
    final int hcppCount = 'Using HCPP platform view rendering strategy.'.allMatches(logcat).length;
    final int legacyCount = 'Using legacy platform view rendering strategy.'
        .allMatches(logcat)
        .length;

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
  }, timeout: Timeout.none);
}
