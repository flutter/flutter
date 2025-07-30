// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/tester/flutter_tester.dart';
import 'package:flutter_tools/src/web/web_device.dart' show GoogleChromeDevice;

import '../../src/common.dart';
import '../test_driver.dart';
import '../test_utils.dart';
import 'hot_reload_with_asset.dart';

void testAll({bool chrome = false, List<String> additionalCommandArgs = const <String>[]}) {
  group('chrome: $chrome'
      '${additionalCommandArgs.isEmpty ? '' : ' with args: $additionalCommandArgs'}', () {
    late Directory tempDir;
    final project = HotReloadWithAssetProject();
    late FlutterRunTestDriver flutter;

    setUp(() async {
      tempDir = createResolvedTempDirectorySync('hot_reload_test.');
      await project.setUpIn(tempDir);
      flutter = FlutterRunTestDriver(tempDir);
    });

    tearDown(() async {
      await flutter.stop();
      tryToDelete(tempDir);
    });

    testWithoutContext('hot reload/restart do not need to sync assets on reload', () async {
      final onFirstLoad = Completer<void>();
      final onSecondLoad = Completer<void>();
      final onThirdLoad = Completer<void>();

      flutter.stdout.listen((String line) {
        // If the asset fails to load, this message will be printed instead.
        // this indicates that the devFS was not able to locate the asset
        // after the hot reload.
        if (line.contains('FAILED TO LOAD')) {
          fail('Did not load asset: $line');
        }
        if (line.contains('LOADED DATA')) {
          onFirstLoad.complete();
        }
        if (line.contains('SECOND DATA')) {
          onSecondLoad.complete();
        }
        if (line.contains('THIRD DATA')) {
          onThirdLoad.complete();
        }
      });
      flutter.stdout.listen(printOnFailure);
      await flutter.run(
        device: chrome ? GoogleChromeDevice.kChromeDeviceId : FlutterTesterDevices.kTesterDeviceId,
        additionalCommandArgs: additionalCommandArgs,
      );
      await onFirstLoad.future;

      project.replaceHotReloadPrint('SECOND DATA');
      await flutter.hotReload();
      await onSecondLoad.future;

      project.replaceHotReloadPrint('THIRD DATA');
      await flutter.hotRestart();
      await onThirdLoad.future;
    });
  });
}
