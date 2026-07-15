// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:android_driver_extensions/native_driver.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

/// Mirrors the [`android.view.View`](https://developer.android.com/reference/android/view/View)
/// `SYSTEM_UI_FLAG_*` constants used by the `PlatformPlugin` Android embedding
/// code. These are stable platform values.
const int _kFlagHideNavigation = 0x2; // SYSTEM_UI_FLAG_HIDE_NAVIGATION
const int _kFlagFullscreen = 0x4; // SYSTEM_UI_FLAG_FULLSCREEN
const int _kFlagImmersive = 0x800; // SYSTEM_UI_FLAG_IMMERSIVE
const int _kFlagImmersiveSticky = 0x1000; // SYSTEM_UI_FLAG_IMMERSIVE_STICKY

/// Edge-to-edge mode requires Android 10 (API 29) or later.
const int _kEdgeToEdgeMinSdk = 29;

late FlutterDriver flutterDriver;
late NativeDriver nativeDriver;

Future<void> _applyMode(String mode) async {
  await flutterDriver.requestData('applyMode:$mode');
}

Future<int> _systemUiVisibility() async {
  final String raw = await flutterDriver.requestData('getSystemUiVisibility');
  final decoded = json.decode(raw) as Map<String, Object?>;
  return decoded['systemUiVisibility']! as int;
}

Future<int> _transitionAndRead(String from, String to) async {
  await _applyMode(from);
  await _applyMode(to);
  return _systemUiVisibility();
}

void main() {
  setUpAll(() async {
    flutterDriver = await FlutterDriver.connect();
    nativeDriver = await AndroidNativeDriver.connect(flutterDriver);
  });

  tearDownAll(() async {
    await nativeDriver.close();
    await flutterDriver.close();
  });

  group('SystemUiMode transitions', () {
    test(
      'immersiveSticky → edgeToEdge clears FULLSCREEN/HIDE_NAVIGATION (regression for #186723)',
      () async {
        final int sdk = await nativeDriver.sdkVersion;
        if (sdk < _kEdgeToEdgeMinSdk) {
          markTestSkipped('edgeToEdge requires API $_kEdgeToEdgeMinSdk+, device is API $sdk');
          return;
        }
        final int flags = await _transitionAndRead('immersiveSticky', 'edgeToEdge');
        expect(
          flags & (_kFlagFullscreen | _kFlagHideNavigation),
          0,
          reason:
              'After switching to edgeToEdge, FULLSCREEN/HIDE_NAVIGATION must not '
              'persist from the prior immersiveSticky mode. systemUiVisibility=0x'
              '${flags.toRadixString(16)}',
        );
      },
      timeout: Timeout.none,
    );

    test('immersive → edgeToEdge clears FULLSCREEN/HIDE_NAVIGATION', () async {
      final int sdk = await nativeDriver.sdkVersion;
      if (sdk < _kEdgeToEdgeMinSdk) {
        markTestSkipped('edgeToEdge requires API $_kEdgeToEdgeMinSdk+, device is API $sdk');
        return;
      }
      final int flags = await _transitionAndRead('immersive', 'edgeToEdge');
      expect(flags & (_kFlagFullscreen | _kFlagHideNavigation), 0);
    }, timeout: Timeout.none);

    test('leanBack → edgeToEdge clears FULLSCREEN/HIDE_NAVIGATION', () async {
      final int sdk = await nativeDriver.sdkVersion;
      if (sdk < _kEdgeToEdgeMinSdk) {
        markTestSkipped('edgeToEdge requires API $_kEdgeToEdgeMinSdk+, device is API $sdk');
        return;
      }
      final int flags = await _transitionAndRead('leanBack', 'edgeToEdge');
      expect(flags & (_kFlagFullscreen | _kFlagHideNavigation), 0);
    }, timeout: Timeout.none);

    test('edgeToEdge → immersive sets IMMERSIVE | FULLSCREEN | HIDE_NAVIGATION', () async {
      final int sdk = await nativeDriver.sdkVersion;
      if (sdk < _kEdgeToEdgeMinSdk) {
        markTestSkipped('edgeToEdge requires API $_kEdgeToEdgeMinSdk+, device is API $sdk');
        return;
      }
      final int flags = await _transitionAndRead('edgeToEdge', 'immersive');
      const int expected = _kFlagImmersive | _kFlagFullscreen | _kFlagHideNavigation;
      expect(flags & expected, expected);
    }, timeout: Timeout.none);

    test(
      'edgeToEdge → immersiveSticky sets IMMERSIVE_STICKY | FULLSCREEN | HIDE_NAVIGATION',
      () async {
        final int sdk = await nativeDriver.sdkVersion;
        if (sdk < _kEdgeToEdgeMinSdk) {
          markTestSkipped('edgeToEdge requires API $_kEdgeToEdgeMinSdk+, device is API $sdk');
          return;
        }
        final int flags = await _transitionAndRead('edgeToEdge', 'immersiveSticky');
        const int expected = _kFlagImmersiveSticky | _kFlagFullscreen | _kFlagHideNavigation;
        expect(flags & expected, expected);
      },
      timeout: Timeout.none,
    );

    test('edgeToEdge → leanBack sets FULLSCREEN | HIDE_NAVIGATION (no IMMERSIVE)', () async {
      final int sdk = await nativeDriver.sdkVersion;
      if (sdk < _kEdgeToEdgeMinSdk) {
        markTestSkipped('edgeToEdge requires API $_kEdgeToEdgeMinSdk+, device is API $sdk');
        return;
      }
      final int flags = await _transitionAndRead('edgeToEdge', 'leanBack');
      const int hideMask = _kFlagFullscreen | _kFlagHideNavigation;
      expect(flags & hideMask, hideMask);
      expect(flags & (_kFlagImmersive | _kFlagImmersiveSticky), 0);
    }, timeout: Timeout.none);
  });
}
