// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_devicelab/common.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/host_agent.dart';
import 'package:flutter_devicelab/framework/ios.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

/// Tests that the Flutter module project template works and supports
/// adding Flutter to an existing iOS app.
Future<void> main() async {
  await task(() async {
    // this variable cannot be `late`, as we reference it in the `finally` block
    // which may execute before this field has been initialized
    String? simulatorDeviceId;
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

      // Copy test dart files to new module app.
      final Directory flutterModuleLibSource = Directory(path.join(flutterDirectory.path, 'dev', 'integration_tests', 'ios_host_app', 'flutterapp', 'lib'));
      final Directory flutterModuleLibDestination = Directory(path.join(projectDir.path, 'lib'));

      // These test files don't have a .dart prefix so the analyzer will ignore them. They aren't in a
      // package and don't work on their own outside of the test module just created.
      final File main = File(path.join(flutterModuleLibSource.path, 'main'));
      main.copySync(path.join(flutterModuleLibDestination.path, 'main.dart'));

      final File marquee = File(path.join(flutterModuleLibSource.path, 'marquee'));
      marquee.copySync(path.join(flutterModuleLibDestination.path, 'marquee.dart'));

      section('Build ephemeral host app in release mode without CocoaPods');

      await inDirectory(projectDir, () async {
        await flutter(
          'build',
          options: <String>['ios', '--no-codesign'],
        );
      });

      checkDirectoryExists(path.join(projectDir.path, '.ios', 'Flutter', 'engine', 'Flutter.xcframework'));

      final Directory ephemeralIOSHostApp = Directory(path.join(
        projectDir.path,
        'build',
        'ios',
        'iphoneos',
        'Runner.app',
      ));

      if (!exists(ephemeralIOSHostApp)) {
        return TaskResult.failure('Failed to build ephemeral host .app');
      }

      if (!await _isAppAotBuild(ephemeralIOSHostApp)) {
        return TaskResult.failure(
          'Ephemeral host app ${ephemeralIOSHostApp.path} was not a release build as expected'
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

      checkDirectoryExists(path.join(projectDir.path, '.ios', 'Flutter', 'engine', 'Flutter.xcframework'));

      if (!exists(ephemeralIOSHostApp)) {
        return TaskResult.failure('Failed to build ephemeral host .app');
      }

      if (!await _isAppAotBuild(ephemeralIOSHostApp)) {
        return TaskResult.failure(
          'Ephemeral host app ${ephemeralIOSHostApp.path} was not a profile build as expected'
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

      final Directory ephemeralSimulatorHostApp = Directory(path.join(
        projectDir.path,
        'build',
        'ios',
        'iphonesimulator',
        'Runner.app',
      ));

      if (!exists(ephemeralSimulatorHostApp)) {
        return TaskResult.failure('Failed to build ephemeral host .app');
      }
      checkFileExists(path.join(ephemeralSimulatorHostApp.path, 'Frameworks', 'Flutter.framework', 'Flutter'));

      if (!exists(File(path.join(
        ephemeralSimulatorHostApp.path,
        'Frameworks',
        'App.framework',
        'flutter_assets',
        'isolate_snapshot_data',
      )))) {
        return TaskResult.failure(
          'Ephemeral host app ${ephemeralSimulatorHostApp.path} was not a debug build as expected'
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
        // One dynamic framework, one static framework, and one that does not support iOS.
        '\ndependencies:\n  device_info: 0.4.2+4\n  google_sign_in: 4.5.1\n  android_alarm_manager: 0.4.5+11\n',
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
          options: <String>['ios', '--no-codesign', '-v'],
        );
      });
      checkDirectoryExists(path.join(projectDir.path, '.ios', 'Flutter', 'engine', 'Flutter.xcframework'));

      final bool ephemeralHostAppWithCocoaPodsBuilt = exists(ephemeralIOSHostApp);

      if (!ephemeralHostAppWithCocoaPodsBuilt) {
        return TaskResult.failure('Failed to build ephemeral host .app with CocoaPods');
      }

      final File podfileLockFile = File(path.join(projectDir.path, '.ios', 'Podfile.lock'));
      final String podfileLockOutput = podfileLockFile.readAsStringSync();
      if (!podfileLockOutput.contains(':path: Flutter')
        || !podfileLockOutput.contains(':path: Flutter/FlutterPluginRegistrant')
        || !podfileLockOutput.contains(':path: ".symlinks/plugins/device_info/ios"')
        || !podfileLockOutput.contains(':path: ".symlinks/plugins/google_sign_in/ios"')
        || podfileLockOutput.contains('android_alarm_manager')) {
        print(podfileLockOutput);
        return TaskResult.failure('Building ephemeral host app Podfile.lock does not contain expected pods');
      }

      checkFileExists(path.join(ephemeralIOSHostApp.path, 'Frameworks', 'device_info.framework', 'device_info'));
      checkFileExists(path.join(ephemeralIOSHostApp.path, 'Frameworks', 'Flutter.framework', 'Flutter'));

      // Static, no embedded framework.
      checkDirectoryNotExists(path.join(ephemeralIOSHostApp.path, 'Frameworks', 'google_sign_in.framework'));

      // Android-only, no embedded framework.
      checkDirectoryNotExists(path.join(ephemeralIOSHostApp.path, 'Frameworks', 'android_alarm_manager.framework'));

      section('Clean and pub get module');

      await inDirectory(projectDir, () async {
        await flutter('clean');
      });

      await inDirectory(projectDir, () async {
        await flutter('pub', options: <String>['get']);
      });

      section('Add to existing iOS Objective-C app');

      final Directory objectiveCHostApp = Directory(path.join(tempDir.path, 'hello_host_app'));
      mkdir(objectiveCHostApp);
      recursiveCopy(
        Directory(path.join(flutterDirectory.path, 'dev', 'integration_tests', 'ios_host_app')),
        objectiveCHostApp,
      );

      final File objectiveCAnalyticsOutputFile = File(path.join(tempDir.path, 'analytics-objc.log'));
      final Directory objectiveCBuildDirectory = Directory(path.join(tempDir.path, 'build-objc'));

      section('Build iOS Objective-C host app');
      await inDirectory(objectiveCHostApp, () async {
        await exec(
          'pod',
          <String>['install'],
          environment: <String, String>{
            'LANG': 'en_US.UTF-8',
          },
        );

        final File hostPodfileLockFile = File(path.join(objectiveCHostApp.path, 'Podfile.lock'));
        final String hostPodfileLockOutput = hostPodfileLockFile.readAsStringSync();
        if (!hostPodfileLockOutput.contains(':path: "../hello/.ios/Flutter/engine"')
            || !hostPodfileLockOutput.contains(':path: "../hello/.ios/Flutter/FlutterPluginRegistrant"')
            || !hostPodfileLockOutput.contains(':path: "../hello/.ios/.symlinks/plugins/device_info/ios"')
            || !hostPodfileLockOutput.contains(':path: "../hello/.ios/.symlinks/plugins/google_sign_in/ios"')
            || hostPodfileLockOutput.contains('android_alarm_manager')) {
          print(hostPodfileLockOutput);
          throw TaskResult.failure('Building host app Podfile.lock does not contain expected pods');
        }

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

      checkFileExists(path.join(
        objectiveCBuildDirectory.path,
        'Host.app',
        'Frameworks',
        'Flutter.framework',
        'Flutter',
      ));

      checkFileExists(path.join(
        objectiveCBuildDirectory.path,
        'Host.app',
        'Frameworks',
        'App.framework',
        'flutter_assets',
        'isolate_snapshot_data',
      ));

      section('Check the NOTICE file is correct');

      final String licenseFilePath = path.join(
        objectiveCBuildDirectory.path,
        'Host.app',
        'Frameworks',
        'App.framework',
        'flutter_assets',
        'NOTICES.Z',
      );
      checkFileExists(licenseFilePath);

      await inDirectory(objectiveCBuildDirectory, () async {
        final Uint8List licenseData = File(licenseFilePath).readAsBytesSync();
        final String licenseString = utf8.decode(gzip.decode(licenseData));
        if (!licenseString.contains('skia') || !licenseString.contains('Flutter Authors')) {
          return TaskResult.failure('License content missing');
        }
      });

      section('Check that the host build sends the correct analytics');

      final String objectiveCAnalyticsOutput = objectiveCAnalyticsOutputFile.readAsStringSync();
      if (!objectiveCAnalyticsOutput.contains('cd24: ios')
          || !objectiveCAnalyticsOutput.contains('cd25: true')
          || !objectiveCAnalyticsOutput.contains('viewName: assemble')) {
        return TaskResult.failure(
          'Building outer Objective-C app produced the following analytics: "$objectiveCAnalyticsOutput" '
          'but not the expected strings: "cd24: ios", "cd25: true", "viewName: assemble"'
        );
      }

      section('Run platform unit tests');

      final String resultBundleTemp = Directory.systemTemp.createTempSync('flutter_module_test_ios_xcresult.').path;
      await testWithNewIOSSimulator('TestAdd2AppSim', (String deviceId) async {
        simulatorDeviceId = deviceId;
        final String resultBundlePath = path.join(resultBundleTemp, 'result');

        final int testResultExit = await exec(
          'xcodebuild',
          <String>[
            '-workspace',
            'Host.xcworkspace',
            '-scheme',
            'Host',
            '-configuration',
            'Debug',
            '-destination',
            'id=$deviceId',
            '-resultBundlePath',
            resultBundlePath,
            'test',
            'CODE_SIGNING_ALLOWED=NO',
            'CODE_SIGNING_REQUIRED=NO',
            'CODE_SIGN_IDENTITY=-',
            'EXPANDED_CODE_SIGN_IDENTITY=-',
            'COMPILER_INDEX_STORE_ENABLE=NO',
          ],
          workingDirectory: objectiveCHostApp.path,
          canFail: true,
        );

        if (testResultExit != 0) {
          final Directory? dumpDirectory = hostAgent.dumpDirectory;
          if (dumpDirectory != null) {
            // Zip the test results to the artifacts directory for upload.
            await inDirectory(resultBundleTemp, () {
              final String zipPath = path.join(dumpDirectory.path,
                  'module_test_ios-objc-${DateTime.now().toLocal().toIso8601String()}.zip');
              return exec(
                'zip',
                <String>[
                  '-r',
                  '-9',
                  zipPath,
                  'result.xcresult',
                ],
                canFail: true, // Best effort to get the logs.
              );
            });
          }

          throw TaskResult.failure('Platform unit tests failed');
        }
      });

      section('Fail building existing Objective-C iOS app if flutter script fails');
      final String xcodebuildOutput = await inDirectory<String>(objectiveCHostApp, () =>
        eval(
          'xcodebuild',
          <String>[
            '-workspace',
            'Host.xcworkspace',
            '-scheme',
            'Host',
            '-configuration',
            'Debug',
            'FLUTTER_ENGINE=bogus', // Force a Flutter error.
            'CODE_SIGNING_ALLOWED=NO',
            'CODE_SIGNING_REQUIRED=NO',
            'CODE_SIGN_IDENTITY=-',
            'EXPANDED_CODE_SIGN_IDENTITY=-',
            'CONFIGURATION_BUILD_DIR=${objectiveCBuildDirectory.path}',
            'COMPILER_INDEX_STORE_ENABLE=NO',
          ],
          canFail: true,
        )
      );

      if (!xcodebuildOutput.contains('flutter --verbose --local-engine-src-path=bogus assemble') || // Verbose output
          !xcodebuildOutput.contains('Unable to detect a Flutter engine build directory in bogus') ||
          !xcodebuildOutput.contains('Command PhaseScriptExecution failed with a nonzero exit code')) {
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
        await exec(
          'pod',
          <String>['install'],
          environment: <String, String>{
            'LANG': 'en_US.UTF-8',
          },
        );
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
          || !swiftAnalyticsOutput.contains('viewName: assemble')) {
        return TaskResult.failure(
          'Building outer Swift app produced the following analytics: "$swiftAnalyticsOutput" '
          'but not the expected strings: "cd24: ios", "cd25: true", "viewName: assemble"'
        );
      }

      return TaskResult.success(null);
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      unawaited(removeIOSimulator(simulatorDeviceId));
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
