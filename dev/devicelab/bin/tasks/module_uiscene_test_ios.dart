// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/host_agent.dart';
import 'package:flutter_devicelab/framework/ios.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

/// This test creates a Flutter module, Flutter plugin, and native iOS app.
/// It adds the plugin as a dependency and embeds the Flutter module into the native iOS app.
/// Additional scenarios can be added in [Scenarios.scenarios].
///
/// To run this test locally, follow instructions in dev/devicelab/README.md.
/// The `--local-engine` and `--local-engine-host` flags can be used to run with a local engine.
///
/// `--task-args destination=[/path/to/copy/destination]` can be used to override the destination
/// of the generated apps/plugins.
///
/// e.g. `../../bin/cache/dart-sdk/bin/dart bin/test_runner.dart test -t module_uiscene_test_ios --local-engine ios_debug_sim_unopt_arm64 --local-engine-host host_debug --task-args destination=/Users/vashworth/Development/flutter/dev/integration_tests/ios_add2app_uiscene/temp`
Future<void> main(List<String> args) async {
  final ArgParser argParser = ArgParser()..addOption('destination');

  await task(() async {
    final ArgResults argResults = argParser.parse(args);
    final String? destination = argResults.option('destination');
    final Directory destinationDir;
    bool destinationOverride = false;
    if (destination != null) {
      destinationOverride = true;
      destinationDir = Directory(destination);
      if (destinationDir.existsSync()) {
        destinationDir.deleteSync(recursive: true);
      }
      destinationDir.createSync(recursive: true);
    } else {
      destinationDir = Directory.systemTemp.createTempSync('flutter_module_test.');
    }

    String? simulatorDeviceId;
    final Directory templatesDir = Directory(
      path.join(flutterDirectory.path, 'dev', 'integration_tests', 'ios_add2app_uiscene'),
    );

    try {
      final Directory appDir = await _createFlutterModuleApp(
        destinationDir: destinationDir,
        templatesDir: templatesDir,
      );
      final Directory pluginDir = await _createFlutterPlugin(
        destinationDir: destinationDir,
        templatesDir: templatesDir,
      );
      final Directory xcodeProjectDir = await _createNativeApp(
        destinationDir: destinationDir,
        templatesDir: templatesDir,
        xcodeProjectType: XcodeProjectType.UIKitSwift,
      );

      bool testFailed = false;

      await testWithNewIOSSimulator('TestAdd2AppSim', (String deviceId) async {
        simulatorDeviceId = deviceId;
        final Scenarios scenarios = Scenarios(
          xcodeProjectDir: xcodeProjectDir,
          templatesDir: templatesDir,
          pluginDir: pluginDir,
          appDir: appDir,
        );
        for (final String scenarioName in scenarios.scenarios.keys) {
          final List<FileReplacements> replacements = scenarios.scenarios[scenarioName]!;
          for (final FileReplacements replacement in replacements) {
            replacement.replace();
          }

          section('Test Scenario $scenarioName');

          await _installPlugins(appDir: appDir, xcodeProjectDir: xcodeProjectDir);
          final int result = await _testNativeApp(
            deviceId: simulatorDeviceId!,
            scenarioName: scenarioName,
            templatesDir: templatesDir,
            xcodeProjectDir: xcodeProjectDir,
          );
          if (result != 0) {
            testFailed = true;
          }
        }
      });

      if (testFailed) {
        return TaskResult.failure(
          'One or more native tests failed. Search the logs for "** TEST FAILED **"',
        );
      }
      return TaskResult.success(null);
    } catch (e, stackTrace) {
      print(e);
      print('Task exception stack trace:\n$stackTrace');
      return TaskResult.failure(e.toString());
    } finally {
      unawaited(removeIOSSimulator(simulatorDeviceId));
      if (!destinationOverride) {
        rmTree(destinationDir);
      }
    }
  });
}

Future<Directory> _createFlutterModuleApp({
  required Directory templatesDir,
  required Directory destinationDir,
}) async {
  section('Create Flutter Module');

  const String moduleName = 'my_module';
  await flutter(
    'create',
    options: <String>['--org', 'io.flutter.devicelab', '--template=module', moduleName],
    workingDirectory: destinationDir.path,
  );
  return Directory(path.join(destinationDir.path, moduleName));
}

Future<Directory> _createFlutterPlugin({
  required Directory templatesDir,
  required Directory destinationDir,
}) async {
  section('Create Flutter Plugin');

  const String pluginName = 'my_plugin';
  await flutter(
    'create',
    options: <String>[
      '--org',
      'io.flutter.devicelab',
      '--template=plugin',
      '--platform=ios',
      pluginName,
    ],
    workingDirectory: destinationDir.path,
  );
  return Directory(path.join(destinationDir.path, pluginName));
}

Future<Directory> _createNativeApp({
  required Directory templatesDir,
  required Directory destinationDir,
  required XcodeProjectType xcodeProjectType,
}) async {
  section('Create Xcode Project');

  final String xcodeProjectName;

  switch (xcodeProjectType) {
    case XcodeProjectType.UIKitSwift:
      xcodeProjectName = 'xcode_uikit_swift';
    case XcodeProjectType.UIKitObjC:
      // TODO(vashworth): add Objective C integration test
      throw UnimplementedError();
    case XcodeProjectType.SwiftUI:
      // TODO(vashworth): add SwiftUI integration test
      throw UnimplementedError();
  }
  // Copy Xcode project
  final Directory xcodeProjectDir = Directory(path.join(destinationDir.path, xcodeProjectName));
  xcodeProjectDir.createSync(recursive: true);
  final Directory xcodeProjectTemplate = Directory(path.join(templatesDir.path, xcodeProjectName));
  recursiveCopy(xcodeProjectTemplate, xcodeProjectDir);

  return xcodeProjectDir;
}

Future<void> _installPlugins({
  required Directory appDir,
  required Directory xcodeProjectDir,
}) async {
  // Poke the pubspec to make sure the tooling generates an updated Podfile.
  final File pubspec = File(path.join(appDir.path, 'pubspec.yaml'));
  pubspec.writeAsStringSync(pubspec.readAsStringSync());

  await flutter(
    'build',
    options: <String>['ios', '--config-only', '-v'],
    workingDirectory: appDir.path,
  );
  await flutter('pub', options: <String>['get'], workingDirectory: appDir.path);

  await eval(
    'pod',
    <String>['install'],
    environment: <String, String>{'LANG': 'en_US.UTF-8'},
    workingDirectory: xcodeProjectDir.path,
    printStdout: false,
    printStderr: false,
  );
}

class FileReplacements {
  FileReplacements(this.templatePath, this.destinationPath);

  final String templatePath;
  final String destinationPath;

  void replace() {
    final File templateFile = File(templatePath);
    templateFile.copySync(destinationPath);
  }
}

Future<int> _testNativeApp({
  required Directory templatesDir,
  required String scenarioName,
  required Directory xcodeProjectDir,
  required String deviceId,
}) async {
  final String resultBundleTemp = Directory.systemTemp
      .createTempSync('flutter_module_test_ios_xcresult.')
      .path;
  final String resultBundlePath = path.join(resultBundleTemp, 'result');
  final int testResultExit = await exec(
    'xcodebuild',
    <String>[
      '-workspace',
      'xcode_uikit_swift.xcworkspace',
      '-scheme',
      'xcode_uikit_swift',
      '-configuration',
      'Debug',
      '-destination',
      'id=$deviceId',
      '-resultBundlePath',
      resultBundlePath,
      'test',
      '-parallel-testing-enabled',
      'NO',
      'COMPILER_INDEX_STORE_ENABLE=NO',
    ],
    workingDirectory: xcodeProjectDir.path,
    canFail: true,
  );

  if (testResultExit != 0) {
    await _uploadTestResults(scenarioName: scenarioName, resultBundlePath: resultBundleTemp);
  }
  return testResultExit;
}

Future<void> _uploadTestResults({
  required String scenarioName,
  required String resultBundlePath,
}) async {
  final Directory? dumpDirectory = hostAgent.dumpDirectory;
  if (dumpDirectory != null) {
    // Zip the test results to the artifacts directory for upload.
    final String zipName =
        'module_uiscene_test_ios-$scenarioName-${DateTime.now().toLocal().toIso8601String()}.zip';
    await inDirectory(resultBundlePath, () {
      final String zipPath = path.join(dumpDirectory.path, zipName);
      return exec(
        'zip',
        <String>['-r', '-9', '-q', zipPath, 'result.xcresult'],
        canFail: true, // Best effort to get the logs.
      );
    });
  }
}

enum XcodeProjectType { UIKitSwift, UIKitObjC, SwiftUI }

class Scenarios {
  Scenarios({
    required this.templatesDir,
    required this.xcodeProjectDir,
    required this.pluginDir,
    required this.appDir,
  });

  final Directory templatesDir;
  final Directory xcodeProjectDir;
  final Directory pluginDir;
  final Directory appDir;

  late Map<String, List<FileReplacements>> scenarios = <String, List<FileReplacements>>{
    // When both the app and the plugin has migrated to scenes,
    // we expect scene events.
    'AppMigrated-FlutterSceneDelegate-PluginMigrated': <FileReplacements>[
      ...sharedLifecycleFiles,
      FileReplacements(
        path.join(templatesDir.path, 'native', 'SceneDelegate-FlutterSceneDelegate.swift'),
        path.join(xcodeProjectDir.path, 'xcode_uikit_swift', 'SceneDelegate.swift'),
      ),
      FileReplacements(
        path.join(templatesDir.path, 'flutterplugin', 'ios', 'LifecyclePlugin-migrated.swift'),
        path.join(pluginDir.path, 'ios', 'Classes', 'MyPlugin.swift'),
      ),
      FileReplacements(
        path.join(templatesDir.path, 'native', 'UITests-SceneEvents.swift'),
        path.join(
          xcodeProjectDir.path,
          'xcode_uikit_swiftUITests',
          'xcode_uikit_swiftUITests.swift',
        ),
      ),
    ],

    // When the app has migrated but the plugin hasn't,
    // we expect application events to be used as a fallback.
    'AppMigrated-FlutterSceneDelegate-PluginNotMigrated': <FileReplacements>[
      FileReplacements(
        path.join(templatesDir.path, 'native', 'SceneDelegate-FlutterSceneDelegate.swift'),
        path.join(xcodeProjectDir.path, 'xcode_uikit_swift', 'SceneDelegate.swift'),
      ),
      FileReplacements(
        path.join(templatesDir.path, 'flutterplugin', 'ios', 'LifecyclePlugin-unmigrated.swift'),
        path.join(pluginDir.path, 'ios', 'Classes', 'MyPlugin.swift'),
      ),
      FileReplacements(
        path.join(templatesDir.path, 'native', 'UITests-ApplicationEvents-AppMigrated.swift'),
        path.join(
          xcodeProjectDir.path,
          'xcode_uikit_swiftUITests',
          'xcode_uikit_swiftUITests.swift',
        ),
      ),
    ],

    // When both the app and the plugin has migrated to scenes,
    // we expect scene events.
    'AppMigrated-FlutterSceneLifeCycleProvider-PluginMigrated': <FileReplacements>[
      FileReplacements(
        path.join(templatesDir.path, 'native', 'SceneDelegate-FlutterSceneLifeCycleProvider.swift'),
        path.join(xcodeProjectDir.path, 'xcode_uikit_swift', 'SceneDelegate.swift'),
      ),
      FileReplacements(
        path.join(templatesDir.path, 'flutterplugin', 'ios', 'LifecyclePlugin-migrated.swift'),
        path.join(pluginDir.path, 'ios', 'Classes', 'MyPlugin.swift'),
      ),
      FileReplacements(
        path.join(templatesDir.path, 'native', 'UITests-SceneEvents.swift'),
        path.join(
          xcodeProjectDir.path,
          'xcode_uikit_swiftUITests',
          'xcode_uikit_swiftUITests.swift',
        ),
      ),
    ],

    // When the app has migrated but the plugin hasn't,
    // we expect application events to be used as a fallback.
    'AppMigrated-FlutterSceneLifeCycleProvider-PluginNotMigrated': <FileReplacements>[
      FileReplacements(
        path.join(templatesDir.path, 'native', 'SceneDelegate-FlutterSceneLifeCycleProvider.swift'),
        path.join(xcodeProjectDir.path, 'xcode_uikit_swift', 'SceneDelegate.swift'),
      ),
      FileReplacements(
        path.join(templatesDir.path, 'flutterplugin', 'ios', 'LifecyclePlugin-unmigrated.swift'),
        path.join(pluginDir.path, 'ios', 'Classes', 'MyPlugin.swift'),
      ),
      FileReplacements(
        path.join(templatesDir.path, 'native', 'UITests-ApplicationEvents-AppMigrated.swift'),
        path.join(
          xcodeProjectDir.path,
          'xcode_uikit_swiftUITests',
          'xcode_uikit_swiftUITests.swift',
        ),
      ),
    ],

    // When the app has not migrated, but the plugin has, we expect no events.
    'AppNotMigrated-FlutterSceneDelegate-PluginMigrated': <FileReplacements>[
      FileReplacements(
        path.join(templatesDir.path, 'native', 'Info-unmigrated.plist'),
        path.join(xcodeProjectDir.path, 'xcode_uikit_swift', 'Info.plist'),
      ),
      FileReplacements(
        path.join(templatesDir.path, 'flutterplugin', 'ios', 'LifecyclePlugin-migrated.swift'),
        path.join(pluginDir.path, 'ios', 'Classes', 'MyPlugin.swift'),
      ),
      FileReplacements(
        path.join(templatesDir.path, 'native', 'UITests-ApplicationEvents-AppNotMigrated.swift'),
        path.join(
          xcodeProjectDir.path,
          'xcode_uikit_swiftUITests',
          'xcode_uikit_swiftUITests.swift',
        ),
      ),
    ],

    // When the app and plugin have not migrated, we expect application events.
    'AppNotMigrated-FlutterSceneDelegate-PluginNotMigrated': <FileReplacements>[
      FileReplacements(
        path.join(templatesDir.path, 'native', 'Info-unmigrated.plist'),
        path.join(xcodeProjectDir.path, 'xcode_uikit_swift', 'Info.plist'),
      ),
      FileReplacements(
        path.join(templatesDir.path, 'flutterplugin', 'ios', 'LifecyclePlugin-unmigrated.swift'),
        path.join(pluginDir.path, 'ios', 'Classes', 'MyPlugin.swift'),
      ),
      FileReplacements(
        path.join(templatesDir.path, 'native', 'UITests-ApplicationEvents-AppNotMigrated.swift'),
        path.join(
          xcodeProjectDir.path,
          'xcode_uikit_swiftUITests',
          'xcode_uikit_swiftUITests.swift',
        ),
      ),
    ],
  };

  late List<FileReplacements> sharedLifecycleFiles = <FileReplacements>[
    FileReplacements(
      path.join(templatesDir.path, 'flutterapp', 'lib', 'main-LifeCycleTest'),
      path.join(appDir.path, 'lib', 'main.dart'),
    ),
    FileReplacements(
      path.join(templatesDir.path, 'flutterapp', 'pubspec-LifeCycleTest.yaml'),
      path.join(appDir.path, 'pubspec.yaml'),
    ),
    FileReplacements(
      path.join(templatesDir.path, 'flutterplugin', 'lib', 'lifecycle_plugin'),
      path.join(pluginDir.path, 'lib', 'my_plugin.dart'),
    ),
    FileReplacements(
      path.join(templatesDir.path, 'flutterplugin', 'lib', 'lifecycle_plugin_method_channel'),
      path.join(pluginDir.path, 'lib', 'my_plugin_method_channel.dart'),
    ),
    FileReplacements(
      path.join(templatesDir.path, 'flutterplugin', 'lib', 'lifecycle_plugin_platform_interface'),
      path.join(pluginDir.path, 'lib', 'my_plugin_platform_interface.dart'),
    ),
    FileReplacements(
      path.join(templatesDir.path, 'native', 'AppDelegate-FlutterAppDelegate-FlutterEngine.swift'),
      path.join(xcodeProjectDir.path, 'xcode_uikit_swift', 'AppDelegate.swift'),
    ),
    FileReplacements(
      path.join(templatesDir.path, 'native', 'ViewController-FlutterEngineFromAppDelegate.swift'),
      path.join(xcodeProjectDir.path, 'xcode_uikit_swift', 'ViewController.swift'),
    ),
  ];
}
