// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Tags(<String>['flutter-test-driver'])
library;

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/web/web_device.dart' show GoogleChromeDevice;

import '../integration.shard/test_data/basic_project.dart';
import '../integration.shard/test_driver.dart';
import '../integration.shard/test_utils.dart';
import '../src/common.dart';

void main() {
  late Directory tempDir;
  final project = BasicProjectWithUnaryMain();
  late FlutterRunTestDriver flutter;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
    await project.setUpIn(tempDir);
    flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await flutter.stop();
    tryToDelete(tempDir);
  });

  testWithoutContext('flutter run works on chrome devices with a unary main function', () async {
    await flutter.run(
      device: GoogleChromeDevice.kChromeDeviceId,
      additionalCommandArgs: <String>['--verbose', '--no-web-resources-cdn'],
    );
  });

  testWithoutContext(
    'flutter run --wasm --machine works on chrome devices with a unary main function',
    () async {
      // Regression test for https://github.com/flutter/flutter/issues/174330
      await flutter.run(
        device: GoogleChromeDevice.kChromeDeviceId,
        wasm: true,
        additionalCommandArgs: <String>['--verbose', '--no-web-resources-cdn'],
      );
      expect(await flutter.stop(), 0, reason: 'Flutter tool exited unexpectedly');
    },
  );
}
