import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  await task(() async {
    section('Copy test Flutter App with WatchOS Companion');

    String watchDeviceID = '';
    String phoneDeviceID = '';
    final Directory tempDir = Directory.systemTemp
        .createTempSync('ios_app_with_watch_companion_test');
    final Directory projectDir =
        Directory(path.join(tempDir.path, 'app_with_companion'));
    try {
      mkdir(projectDir);
      recursiveCopy(
        Directory(path.join(flutterDirectory.path, 'dev', 'integration_tests',
            'ios_app_with_watch_companion')),
        projectDir,
      );

      section('Create release build');

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>['ios', '--no-codesign'],
        );
      });

      final bool appReleaseBuilt = exists(Directory(path.join(
        projectDir.path,
        'build',
        'ios',
        'iphoneos',
        'Runner.app',
      )));

      if (!appReleaseBuilt) {
        return TaskResult.failure(
            'Failed to build flutter iOS app with WatchOS companion in release mode.');
      }

      section('Create debug build');

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>['ios', '--debug', '--no-codesign'],
        );
      });

      final bool appDebugBuilt = exists(Directory(path.join(
        projectDir.path,
        'build',
        'ios',
        'iphoneos',
        'Runner.app',
      )));

      if (!appDebugBuilt) {
        return TaskResult.failure(
            'Failed to build flutter iOS app with WatchOS companion in debug mode.');
      }

      section('Create build for a simulator device');

      // Create iOS simulator devices.
      phoneDeviceID = await eval(
        'xcrun',
        <String>[
          'simctl',
          'create',
          'TestFlutteriPhoneWithWatch',
          'com.apple.CoreSimulator.SimDeviceType.iPhone-11',
          'com.apple.CoreSimulator.SimRuntime.iOS-13-2'
        ],
        canFail: false,
        workingDirectory: flutterDirectory.path,
      );

      watchDeviceID = await eval(
        'xcrun',
        <String>[
          'simctl',
          'create',
          'TestFlutterWatch',
          'com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-5-44mm',
          'com.apple.CoreSimulator.SimRuntime.watchOS-6-1'
        ],
        canFail: false,
        workingDirectory: flutterDirectory.path,
      );

      // Pair watch with phone.
      await eval(
        'xcrun',
        <String>['simctl', 'pair', watchDeviceID, phoneDeviceID],
        canFail: false,
        workingDirectory: flutterDirectory.path,
      );

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>[
            'ios',
            '--debug',
            '--no-codesign',
            '-d',
            phoneDeviceID
          ],
        );
      });

      final bool appSimulatorBuilt = exists(Directory(path.join(
        projectDir.path,
        'build',
        'ios',
        'iphoneos',
        'Runner.app',
      )));

      if (!appSimulatorBuilt) {
        return TaskResult.failure(
            'Failed to build flutter iOS app with WatchOS companion in debug mode for simulated device.');
      }

      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
      // Delete simulator devices
      if (watchDeviceID != '')
        await eval(
          'xcrun',
          <String>['simctl', 'delete', phoneDeviceID],
          canFail: true,
          workingDirectory: flutterDirectory.path,
        );
      if (phoneDeviceID != '')
        await eval(
          'xcrun',
          <String>['simctl', 'delete', watchDeviceID],
          canFail: true,
          workingDirectory: flutterDirectory.path,
        );
    }
  });
}
