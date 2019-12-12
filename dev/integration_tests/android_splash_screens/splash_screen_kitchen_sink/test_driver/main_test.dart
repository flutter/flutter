// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  group('end-to-end test', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver?.close();
    });

    test('Flutter experience eventually appears', () async {
      final SerializableFinder fabFinder = find.byTooltip('Increment');

      // Ensure that the Flutter experience eventually becomes visible.
      // We combined two verifications for this purpose:
      //
      // 1. We verify that we can find the expected FAB, and
      //
      // 2. We verify that Android thinks the splash screen has been removed.
      await driver.waitFor(fabFinder);

      await _waitForSplashToDisappear(driver).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Splash screen never disappeared.');
        },
      );
    });
  });
}

Future<void> _waitForSplashToDisappear(FlutterDriver driver) async {
  bool waitingForSplashToDisappear = true;

  while (waitingForSplashToDisappear) {
    final String response = await driver.requestData('splash_test_log',);

    final Map<String, dynamic> splashTestLog = jsonDecode(response) as Map<String, dynamic>;
    final List<dynamic> events = splashTestLog['events'] as List<dynamic>;
    if (events.length == 3) {
      expect(
          events[0],
          equals('waiting_for_layout'),
          reason: 'Expected first splash event to be '
              '"waiting_for_layout" but it was "${events[0]}"',
      );
      expect(
          events[1],
          equals('splash_showing'),
          reason: 'Expected second splash event to be '
              '"splash_showing" but it was "${events[1]}"',
      );
      expect(
          events[2],
          equals('splash_not_showing'),
          reason: 'Expected third splash event to be '
              '"splash_not_showing" but it was "${events[2]}"',
      );
      waitingForSplashToDisappear = false;
    } else if (events.length > 3) {
      throw Exception('Expected 3 splash test events but received '
          '${events.length} events: $events');
    }
  }
}
