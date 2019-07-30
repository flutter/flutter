// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/ios.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

/// Tests that the Flutter module project template works and supports
/// adding Flutter to an existing iOS app.
Future<void> main() async {
  await task(() async {
    section('Create Flutter module project');

    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_module_test.');
    final Directory projectDir = Directory(path.join(tempDir.path, 'hello'));
    try {
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>[
            '--org',
            'io.flutter.devicelab',
            '--template=module',
            'hello',
          ],
        );
      });
      await prepareProvisioningCertificates(projectDir.path);

      section('Build ephemeral host app in release mode without CocoaPods');

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>['ios', '--no-codesign'],
        );
      });

      final Directory ephemeralReleaseHostApp = Directory(path.join(
        projectDir.path,
        'build',
        'ios',
        'iphoneos',
        'Runner.app',
      ));

      if (!exists(ephemeralReleaseHostApp)) {
        return TaskResult.failure('Failed to build ephemeral host .app');
      }

      if (!await _isAppAotBuild(ephemeralReleaseHostApp)) {
        return TaskResult.failure(
          'Ephemeral host app ${ephemeralReleaseHostApp.path} was not a release build as expected'
        );
      }

      if (await _hasDebugSymbols(ephemeralReleaseHostApp)) {
        return TaskResult.failure(
          "Ephemeral host app ${ephemeralReleaseHostApp.path}'s App.framework's "
          "debug symbols weren't stripped in release mode"
        );
      }

      section('Clean build');

      await inDirectory(projectDir, () async {
        await flutter('clean');
      });

      section('Build ephemeral host app in profile mode without CocoaPods');

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>['ios', '--no-codesign', '--profile'],
        );
      });

      final Directory ephemeralProfileHostApp = Directory(path.join(
        projectDir.path,
        'build',
        'ios',
        'iphoneos',
        'Runner.app',
      ));

      if (!exists(ephemeralProfileHostApp)) {
        return TaskResult.failure('Failed to build ephemeral host .app');
      }

      if (!await _isAppAotBuild(ephemeralProfileHostApp)) {
        return TaskResult.failure(
          'Ephemeral host app ${ephemeralProfileHostApp.path} was not a profile build as expected'
        );
      }

      if (!await _hasDebugSymbols(ephemeralProfileHostApp)) {
        return TaskResult.failure(
          "Ephemeral host app ${ephemeralProfileHostApp.path}'s App.framework does not contain debug symbols"
        );
      }

      section('Clean build');

      await inDirectory(projectDir, () async {
        await flutter('clean');
      });

      section('Build ephemeral host app in debug mode for simulator without CocoaPods');

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>['ios', '--no-codesign', '--simulator', '--debug'],
        );
      });

      final Directory ephemeralDebugHostApp = Directory(path.join(
        projectDir.path,
        'build',
        'ios',
        'iphonesimulator',
        'Runner.app',
      ));

      if (!exists(ephemeralDebugHostApp)) {
        return TaskResult.failure('Failed to build ephemeral host .app');
      }

      if (!exists(File(path.join(
        ephemeralDebugHostApp.path,
        'Frameworks',
        'App.framework',
        'flutter_assets',
        'isolate_snapshot_data',
      )))) {
        return TaskResult.failure(
          'Ephemeral host app ${ephemeralDebugHostApp.path} was not a debug build as expected'
        );
      }

      section('Clean build');

      await inDirectory(projectDir, () async {
        await flutter('clean');
      });

      section('Add plugins');

      final File pubspec = File(path.join(projectDir.path, 'pubspec.yaml'));
      String content = await pubspec.readAsString();
      content = content.replaceFirst(
        '\ndependencies:\n',
        '\ndependencies:\n  device_info:\n  package_info:\n',
      );
      await pubspec.writeAsString(content, flush: true);
      await inDirectory(projectDir, () async {
        await flutter(
          'packages',
          options: <String>['get'],
        );
      });

      section('Build ephemeral host app with CocoaPods');

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>['ios', '--no-codesign'],
        );
      });

      final bool ephemeralHostAppWithCocoaPodsBuilt = exists(Directory(path.join(
        projectDir.path,
        'build',
        'ios',
        'iphoneos',
        'Runner.app',
      )));

      if (!ephemeralHostAppWithCocoaPodsBuilt) {
        return TaskResult.failure('Failed to build ephemeral host .app with CocoaPods');
      }

      section('Clean build');

      await inDirectory(projectDir, () async {
        await flutter('clean');
      });

      section('Make iOS host app editable');

      await inDirectory(projectDir, () async {
        await flutter(
          'make-host-app-editable',
          options: <String>['ios'],
        );
      });

      section('Build editable host app');

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>['ios', '--no-codesign'],
        );
      });

      final bool editableHostAppBuilt = exists(Directory(path.join(
        projectDir.path,
        'build',
        'ios',
        'iphoneos',
        'Runner.app',
      )));

      if (!editableHostAppBuilt) {
        return TaskResult.failure('Failed to build editable host .app');
      }

      section('Add to existing iOS app');

      final Directory hostApp = Directory(path.join(tempDir.path, 'hello_host_app'));
      mkdir(hostApp);
      recursiveCopy(
        Directory(path.join(flutterDirectory.path, 'dev', 'integration_tests', 'ios_host_app')),
        hostApp,
      );

      final File analyticsOutputFile = File(path.join(tempDir.path, 'analytics.log'));

      await inDirectory(hostApp, () async {
        await exec('pod', <String>['install']);
        await exec(
          'xcodebuild',
          <String>[
            '-workspace',
            'Host.xcworkspace',
            '-scheme',
            'Host',
            '-configuration',
            'Debug',
            'CODE_SIGNING_ALLOWED=NO',
            'CODE_SIGNING_REQUIRED=NO',
            'CODE_SIGN_IDENTITY=-',
            'EXPANDED_CODE_SIGN_IDENTITY=-',
            'CONFIGURATION_BUILD_DIR=${tempDir.path}',
          ],
          environment: <String, String> {
            'FLUTTER_ANALYTICS_LOG_FILE': analyticsOutputFile.path,
          }
        );
      });

      final bool existingAppBuilt = exists(File(path.join(
        tempDir.path,
        'Host.app',
        'Host',
      )));
      if (!existingAppBuilt) {
        return TaskResult.failure('Failed to build existing app .app');
      }

      final String analyticsOutput = analyticsOutputFile.readAsStringSync();
      if (!analyticsOutput.contains('cd24: ios')
          || !analyticsOutput.contains('cd25: true')
          || !analyticsOutput.contains('viewName: build/bundle')) {
        return TaskResult.failure(
          'Building outer app produced the following analytics: "$analyticsOutput"'
          'but not the expected strings: "cd24: ios", "cd25: true", "viewName: build/bundle"'
        );
      }

      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  });
}

Future<bool> _isAppAotBuild(Directory app) async {
  final String binary = path.join(
    app.path,
    'Frameworks',
    'App.framework',
    'App'
  );

  final String symbolTable = await eval(
    'nm',
    <String> [
      '-gU',
      binary,
    ],
  );

  return symbolTable.contains('kDartIsolateSnapshotInstructions');
}

Future<bool> _hasDebugSymbols(Directory app) async {
  final String binary = path.join(
    app.path,
    'Frameworks',
    'App.framework',
    'App'
  );

  final String symbolTable = await eval(
    'dsymutil',
    <String> [
      '--dump-debug-map',
      binary,
    ],
    // The output is huge.
    printStdout: false,
  );

  // Search for some random Flutter framework Dart function which should always
  // be in App.framework.
  return symbolTable.contains('BuildOwner_reassemble');
}
