// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

void main() {
  group('static overlay performance test', () {
    late FlutterDriver driver;
    String? deviceSerial = Platform.environment['ANDROID_SERIAL'];

    setUpAll(() async {
      driver = await FlutterDriver.connect();
      await driver.waitUntilFirstFrameRasterized();
    });

    tearDownAll(() async {
      await driver.close();
    });

    Future<ProcessResult> runAdb(List<String> args) async {
      List<String> adbArgs = <String>[];
      if (deviceSerial != null) {
        adbArgs.addAll(<String>['-s', deviceSerial]);
      }
      adbArgs.addAll(args);
      return Process.run('adb', adbArgs);
    }

    test('static overlay does not trigger updateCurrentBitmap on native invalidation', () async {
      print('ANDROID_SERIAL: $deviceSerial');
      // Wait for app to settle after startup
      print('Waiting for app to settle...');
      await Future<void>.delayed(const Duration(seconds: 5));

      // Clear logcat
      print('Clearing logcat...');
      ProcessResult clearResult = await runAdb(<String>['logcat', '-c']);
      print('Clear logcat exitCode: ${clearResult.exitCode}');
      await Future<void>.delayed(const Duration(seconds: 1));

      // Start native invalidation loop
      print('Starting native invalidation loop...');
      String response = await driver.requestData('startInvalidation');
      print('Start invalidation response: $response');
      
      // Let it run for 2 seconds
      await Future<void>.delayed(const Duration(seconds: 2));

      // Stop native invalidation loop
      print('Stopping native invalidation loop...');
      response = await driver.requestData('stopInvalidation');
      print('Stop invalidation response: $response');
      await Future<void>.delayed(const Duration(seconds: 1));

      // Dump logcat and filter by tag FlutterImageView
      ProcessResult logcatResult = await runAdb(<String>['logcat', '-d', 'FlutterImageView:I', '*:S']);
      String logs = logcatResult.stdout as String;
      print('Logs captured:\n$logs');

      // Count occurrences
      int updateCount = 'updateCurrentBitmap called'.allMatches(logs).length;
      print('updateCurrentBitmap called $updateCount times');

      int onDrawCount = 'onDraw called'.allMatches(logs).length;
      print('onDraw called $onDrawCount times');

      expect(onDrawCount, greaterThan(50), reason: 'Invalidation loop should have triggered many onDraw calls');
      
      // We expect 0 updates on optimized branch.
      expect(updateCount, equals(0), reason: 'updateCurrentBitmap should not be called for static overlay');

    }, timeout: Timeout.none);
  });
}
