// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/ios.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  deviceOperatingSystem = DeviceOperatingSystem.ios;
  await task(() async {
    String? simulatorDeviceId;
    TaskResult? result;

    try {
      await testWithNewIOSSimulator('UniversalLinkTestSim', (String deviceId) async {
        simulatorDeviceId = deviceId;

        final String projectDir = path.join(
          flutterDirectory.path,
          'dev',
          'integration_tests',
          'ios_universal_link',
        );

        await inDirectory(projectDir, () async {
          await flutter('build', options: <String>['ios', '--simulator']);
        });

        final String appPath = path.join(
          projectDir,
          'build',
          'ios',
          'iphonesimulator',
          'Runner.app',
        );

        if (!Directory(appPath).existsSync()) {
          result = TaskResult.failure('Failed to build iOS app. Missing at $appPath');
          return;
        }

        // 2. Install the app on the simulator
        await exec('xcrun', <String>[
          'devicectl',
          'device',
          'install',
          'app',
          '--device',
          deviceId,
          appPath,
        ]);

        print('Launching app via universal link...');

        // Launch the app via universal link with --console to capture native stdout/stderr.
        final Process process = await startProcess('xcrun', <String>[
          'devicectl',
          'device',
          'process',
          'launch',
          '--device',
          deviceId,
          '--console',
          '--payload-url',
          'https://flutter-dashboard.appspot.com/invalid_route',
          'com.google.experimental0.dev', // Bundle ID from the static project
        ]);

        var linkReceived = false;
        final completer = Completer<void>();

        unawaited(
          process.exitCode.then((int code) {
            if (!completer.isCompleted) {
              print('Process exited early with code $code');
              completer.complete();
            }
          }),
        );

        void handleLine(String line, String prefix) {
          print('[$prefix] $line');
          if (line.contains(
            'Engine sent: pushRouteInformation {location: https://flutter-dashboard.appspot.com/invalid_route',
          )) {
            linkReceived = true;
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        }

        process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((String line) => handleLine(line, 'stdout'));
        process.stderr
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((String line) => handleLine(line, 'stderr'));

        // Wait for the link or timeout
        try {
          await completer.future.timeout(const Duration(minutes: 2));
        } catch (e) {
          print('Timeout waiting for universal link route to be printed.');
        }

        process.kill();

        if (!linkReceived) {
          result = TaskResult.failure('App did not receive the universal link route.');
          return;
        }

        result = TaskResult.success(null, benchmarkScoreKeys: <String>[]);
      });
    } finally {
      await removeIOSSimulator(simulatorDeviceId);
    }

    return result ?? TaskResult.failure('Test failed to set a result');
  });
}
