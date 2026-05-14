// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

Future<String> _requestDataWithRetry(
  FlutterDriver driver,
  String message, {
  int maxRetries = 3,
}) async {
  for (var attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      final String response = await driver.requestData(message);
      if (response.isNotEmpty) {
        // Check for an error returned from the driver extension handler.
        try {
          final data = jsonDecode(response) as Map<String, Object?>;
          if (data.containsKey('error')) {
            throw Exception('Driver extension handler reported an error: ${data['error']}');
          }
        } on FormatException {
          // Not a JSON map, which is fine for some responses.
        }
      }
      return response;
    } catch (e) {
      if (attempt == maxRetries) {
        rethrow;
      }

      await Future<void>.delayed(Duration(milliseconds: 100 * attempt));
    }
  }
  throw StateError('Should not reach here');
}

void main() {
  group('end-to-end test', () {
    late final FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
      await _requestDataWithRetry(driver, jsonEncode({'type': 'ping'}));
    });

    tearDownAll(() async {
      await driver.close();
    });

    test('Can set and get title', () async {
      await _requestDataWithRetry(
        driver,
        jsonEncode({'type': 'set_title', 'title': 'Hello World'}),
      );
      final String response = await _requestDataWithRetry(
        driver,
        jsonEncode({'type': 'get_title'}),
      );
      final data = jsonDecode(response) as Map<String, Object?>;
      expect(data['title'], 'Hello World');
    }, timeout: Timeout.none);

    test('Initial controller size is correct', () async {
      final String response = await _requestDataWithRetry(driver, jsonEncode({'type': 'get_size'}));
      final data = jsonDecode(response) as Map<String, Object?>;
      expect(data['width'], 640);
      expect(data['height'], 480);
    }, timeout: Timeout.none);

    test('Can set and get size', () async {
      await _requestDataWithRetry(
        driver,
        jsonEncode({'type': 'set_size', 'width': 800, 'height': 600}),
      );
      final String response = await _requestDataWithRetry(driver, jsonEncode({'type': 'get_size'}));
      final data = jsonDecode(response) as Map<String, Object?>;
      expect(data['width'], 800);
      expect(data['height'], 600);
    }, timeout: Timeout.none);

    test('Can set and get fullscreen', () async {
      await _requestDataWithRetry(driver, jsonEncode({'type': 'set_fullscreen'}));
      String response = await _requestDataWithRetry(driver, jsonEncode({'type': 'get_fullscreen'}));
      var data = jsonDecode(response) as Map<String, Object?>;
      expect(data['isFullscreen'], true);

      await _requestDataWithRetry(driver, jsonEncode({'type': 'unset_fullscreen'}));
      response = await _requestDataWithRetry(driver, jsonEncode({'type': 'get_fullscreen'}));
      data = jsonDecode(response) as Map<String, Object?>;
      expect(data['isFullscreen'], false);
    }, timeout: Timeout.none);

    test('Can set and get maximized', () async {
      await _requestDataWithRetry(driver, jsonEncode({'type': 'set_maximized'}));
      String response = await _requestDataWithRetry(driver, jsonEncode({'type': 'get_maximized'}));
      var data = jsonDecode(response) as Map<String, Object?>;
      expect(data['isMaximized'], true);

      await _requestDataWithRetry(driver, jsonEncode({'type': 'unset_maximized'}));
      response = await _requestDataWithRetry(driver, jsonEncode({'type': 'get_maximized'}));
      data = jsonDecode(response) as Map<String, Object?>;
      expect(data['isMaximized'], false);
    }, timeout: Timeout.none);

    test(
      'Can set and get minimized',
      () async {
        await _requestDataWithRetry(driver, jsonEncode({'type': 'set_minimized'}));
        String response = await _requestDataWithRetry(
          driver,
          jsonEncode({'type': 'get_minimized'}),
        );
        var data = jsonDecode(response) as Map<String, Object?>;
        expect(data['isMinimized'], true);

        await _requestDataWithRetry(driver, jsonEncode({'type': 'unset_minimized'}));
        response = await _requestDataWithRetry(driver, jsonEncode({'type': 'get_minimized'}));
        data = jsonDecode(response) as Map<String, Object?>;
        expect(data['isMinimized'], false);
      },
      timeout: Timeout.none,
      onPlatform: {'linux': const Skip('isMinimized is not supported on Wayland')},
    );

    test(
      'Can set and get activated',
      () async {
        await _requestDataWithRetry(
          driver,
          jsonEncode({'type': 'set_minimized'}),
        ); // Minimize first so that the window is not active
        await _requestDataWithRetry(driver, jsonEncode({'type': 'set_activated'}));
        final String response = await _requestDataWithRetry(
          driver,
          jsonEncode({'type': 'get_activated'}),
        );
        final data = jsonDecode(response) as Map<String, Object?>;
        expect(data['isActivated'], true);
      },
      timeout: Timeout.none,
      onPlatform: {'linux': const Skip('isMinimized is not supported on Wayland')},
    );

    test('Can open dialog', () async {
      await _requestDataWithRetry(driver, jsonEncode({'type': 'open_dialog'}));
      await driver.waitFor(find.byValueKey('close_dialog'), timeout: const Duration(seconds: 10));
      await _requestDataWithRetry(driver, jsonEncode({'type': 'close_dialog'}));
    }, timeout: Timeout.none);

    test(
      'Can set constraints and see the resize',
      () async {
        await _requestDataWithRetry(
          driver,
          jsonEncode({
            'type': 'set_constraints',
            'min_width': 0,
            'min_height': 0,
            'max_width': 500,
            'max_height': 501,
          }),
        );
        final String response = await _requestDataWithRetry(
          driver,
          jsonEncode({'type': 'get_size'}),
        );
        final data = jsonDecode(response) as Map<String, Object?>;
        expect(data['width'], 500);
        expect(data['height'], 501);
      },
      timeout: Timeout.none,
      onPlatform: {'linux': const Skip('Unable to exactly set dimensions on Linux')},
    );

    test(
      'Can set constraints and see the resize (Linux)',
      () async {
        await _requestDataWithRetry(
          driver,
          jsonEncode({
            'type': 'set_constraints',
            'min_width': 0,
            'min_height': 0,
            'max_width': 500,
            'max_height': 501,
          }),
        );
        final String response = await _requestDataWithRetry(
          driver,
          jsonEncode({'type': 'get_size'}),
        );
        final data = jsonDecode(response) as Map<String, Object?>;
        // On Linux setting the constraints limits the window including the decorations,
        // but the returned size is the usable area and always smaller.
        expect(data['width'], lessThanOrEqualTo(500));
        expect(data['height'], lessThanOrEqualTo(501));
      },
      timeout: Timeout.none,
      testOn: 'linux',
    );
  });
}
