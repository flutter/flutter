// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
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
        '\ndependencies:\n  device_info:\n  google_maps_flutter:\n', // One dynamic and one static framework.
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

      final File podfileLockFile = File(path.join(projectDir.path, '.ios', 'Podfile.lock'));
      final String podfileLockOutput = podfileLockFile.readAsStringSync();
      if (!podfileLockOutput.contains(':path: Flutter/engine')
        || !podfileLockOutput.contains(':path: Flutter/FlutterPluginRegistrant')
        || !podfileLockOutput.contains(':path: Flutter/.symlinks/device_info/ios')
        || !podfileLockOutput.contains(':path: Flutter/.symlinks/google_maps_flutter/ios')) {
        return TaskResult.failure('Building ephemeral host app Podfile.lock does not contain expected pods');
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

      section('Add to existing iOS Objective-C app');

      final Directory objectiveCHostApp = Directory(path.join(tempDir.path, 'hello_host_app'));
      mkdir(objectiveCHostApp);
      recursiveCopy(
        Directory(path.join(flutterDirectory.path, 'dev', 'integration_tests', 'ios_host_app')),
        objectiveCHostApp,
      );

      final File objectiveCAnalyticsOutputFile = File(path.join(tempDir.path, 'analytics-objc.log'));
      final Directory objectiveCBuildDirectory = Directory(path.join(tempDir.path, 'build-objc'));
      await inDirectory(objectiveCHostApp, () async {
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
            'CONFIGURATION_BUILD_DIR=${objectiveCBuildDirectory.path}',
            'COMPILER_INDEX_STORE_ENABLE=NO',
          ],
          environment: <String, String> {
            'FLUTTER_ANALYTICS_LOG_FILE': objectiveCAnalyticsOutputFile.path,
          },
        );
      });

      final bool existingAppBuilt = exists(File(path.join(
        objectiveCBuildDirectory.path,
        'Host.app',
        'Host',
      )));
      if (!existingAppBuilt) {
        return TaskResult.failure('Failed to build existing Objective-C app .app');
      }

      final String objectiveCAnalyticsOutput = objectiveCAnalyticsOutputFile.readAsStringSync();
      if (!objectiveCAnalyticsOutput.contains('cd24: ios')
          || !objectiveCAnalyticsOutput.contains('cd25: true')
          || !objectiveCAnalyticsOutput.contains('viewName: build/bundle')) {
        return TaskResult.failure(
          'Building outer Objective-C app produced the following analytics: "$objectiveCAnalyticsOutput"'
          'but not the expected strings: "cd24: ios", "cd25: true", "viewName: build/bundle"'
        );
      }

      section('Fail building existing Objective-C iOS app if flutter script fails');
      int xcodebuildExitCode = 0;
      await inDirectory(objectiveCHostApp, () async {
        xcodebuildExitCode = await exec(
          'xcodebuild',
          <String>[
            '-workspace',
            'Host.xcworkspace',
            '-scheme',
            'Host',
            '-configuration',
            'Debug',
            'ARCHS=i386', // i386 is not supported in Debug mode.
            'CODE_SIGNING_ALLOWED=NO',
            'CODE_SIGNING_REQUIRED=NO',
            'CODE_SIGN_IDENTITY=-',
            'EXPANDED_CODE_SIGN_IDENTITY=-',
            'CONFIGURATION_BUILD_DIR=${objectiveCBuildDirectory.path}',
            'COMPILER_INDEX_STORE_ENABLE=NO',
          ],
          canFail: true,
        );
      });

      if (xcodebuildExitCode != 65) { // 65 returned on PhaseScriptExecution failure.
        return TaskResult.failure('Host Objective-C app build succeeded though flutter script failed');
      }

      section('Add to existing iOS Swift app');

      final Directory swiftHostApp = Directory(path.join(tempDir.path, 'hello_host_app_swift'));
      mkdir(swiftHostApp);
      recursiveCopy(
        Directory(path.join(flutterDirectory.path, 'dev', 'integration_tests', 'ios_host_app_swift')),
        swiftHostApp,
      );

      final File swiftAnalyticsOutputFile = File(path.join(tempDir.path, 'analytics-swift.log'));
      final Directory swiftBuildDirectory = Directory(path.join(tempDir.path, 'build-swift'));

      await inDirectory(swiftHostApp, () async {
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
            'CONFIGURATION_BUILD_DIR=${swiftBuildDirectory.path}',
            'COMPILER_INDEX_STORE_ENABLE=NO',
          ],
          environment: <String, String> {
            'FLUTTER_ANALYTICS_LOG_FILE': swiftAnalyticsOutputFile.path,
          },
        );
      });

      final bool existingSwiftAppBuilt = exists(File(path.join(
        swiftBuildDirectory.path,
        'Host.app',
        'Host',
      )));
      if (!existingSwiftAppBuilt) {
        return TaskResult.failure('Failed to build existing Swift app .app');
      }

      final String swiftAnalyticsOutput = swiftAnalyticsOutputFile.readAsStringSync();
      if (!swiftAnalyticsOutput.contains('cd24: ios')
          || !swiftAnalyticsOutput.contains('cd25: true')
          || !swiftAnalyticsOutput.contains('viewName: build/bundle')) {
        return TaskResult.failure(
          'Building outer Swift app produced the following analytics: "$swiftAnalyticsOutput"'
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
    'App',
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
    'App',
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
