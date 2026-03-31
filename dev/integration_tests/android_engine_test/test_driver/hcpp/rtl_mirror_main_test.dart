// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'package:android_driver_extensions/native_driver.dart';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() async {
  late final FlutterDriver flutterDriver;
  late final NativeDriver nativeDriver;

  setUpAll(() async {
    flutterDriver = await FlutterDriver.connect();
    nativeDriver = await AndroidNativeDriver.connect(flutterDriver);
    await flutterDriver.waitUntilFirstFrameRasterized();
  });

  tearDownAll(() async {
    await nativeDriver.close();
    await flutterDriver.close();
  });

  test(
    'tapping blue box on the right at physical coordinates does not mirror to red platform view on the left',
    () async {
      // 1. Get location properties.
      final response = json.decode(await flutterDriver.requestData('')) as Map<String, Object?>;
      final double devicePixelRatio = (response['devicePixelRatio']! as num).toDouble();
      expect(devicePixelRatio, isPositive);

      final DriverOffset center = await flutterDriver.getCenter(find.byValueKey('blue_box'));
      final int physicalX = (center.dx * devicePixelRatio).round();
      final int physicalY = (center.dy * devicePixelRatio).round();

      // 2. Verify initial state.
      final String initialState = await flutterDriver.requestData('red_tapped');
      expect(initialState, 'false');

      // 3. Tapping the blue box on the right using a physical ADB tap.
      // This bypasses accessibility and native view lookups, as well as
      // flutter driver tap dispatching as it is the only way to reproduce
      // https://github.com/flutter/flutter/issues/182823.
      print('Sending adb tap to physical coordinates: ($physicalX, $physicalY)');
      final ProcessResult result = await Process.run('adb', <String>[
        'shell',
        'input',
        'tap',
        '$physicalX',
        '$physicalY',
      ]);
      if (result.exitCode != 0) {
        fail('Failed to send adb tap: ${result.stderr}');
      }

      // 4. Check results.
      final String redTapped = await flutterDriver.requestData('red_tapped');
      expect(
        redTapped,
        'false',
        reason:
            'Physical tap on the right (blue box) should NOT have triggered the left box (red platform view) tap handler.',
      );

      final String blueTapped = await flutterDriver.requestData('blue_tapped');
      expect(
        blueTapped,
        'true',
        reason: 'Physical tap on the right SHOULD have triggered the blue box tap handler.',
      );

      // 5. Sanity check: Tap the red box natively.
      await flutterDriver.tap(find.byValueKey('red_box_overlay'));
      final String redTappedAfter = await flutterDriver.requestData('red_tapped');
      expect(
        redTappedAfter,
        'true',
        reason: 'Directly tapping the red box SHOULD trigger its tap handler.',
      );
    },
    timeout: Timeout.none,
  );
}
