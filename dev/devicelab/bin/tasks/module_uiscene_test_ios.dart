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
/// e.g. `../../bin/cache/dart-sdk/bin/dart bin/test_runner.dart test -t module_uiscene_test_ios --local-engine ios_debug_sim_unopt_arm64 --local-engine-host host_debug --task-args destination=/path/to/copy/destination`
Future<void> main(List<String> args) async {
  const String kDestination = 'destination';
  const String kTestName = 'name';
  const String kXcodeProjecType = 'type';
  final ArgParser argParser = ArgParser()
    ..addOption(kDestination)
    ..addOption(kTestName)
    ..addOption(kXcodeProjecType);

  await task(() async {
    final ArgResults argResults = argParser.parse(args);
    final String? destination = argResults.option(kDestination);
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

    final String? testName = argResults.option(kTestName);

    XcodeProjectType? projectType;
    final String? projectTypeName = argResults.option(kXcodeProjecType);
    if (projectTypeName?.toLowerCase() == 'swiftui') {
      projectType = XcodeProjectType.SwiftUI;
    } else if (projectTypeName?.toLowerCase() == 'uikit-swift') {
      projectType = XcodeProjectType.UIKitSwift;
    }
    List<XcodeProjectType> projectTypesToTest = XcodeProjectType.values;
    if (projectType != null) {
      projectTypesToTest = <XcodeProjectType>[projectType];
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

      int testCount = 0;
      int testFailedCount = 0;
      await testWithNewIOSSimulator(
        'TestAdd2AppSim',
        deviceTypeId: 'com.apple.CoreSimulator.SimDeviceType.iPad-Pro-11-inch-3rd-generation',
        (String deviceId) async {
          for (final XcodeProjectType xcodeProjectType in projectTypesToTest) {
            final (String xcodeProjectName, Directory xcodeProjectDir) = await _createNativeApp(
              destinationDir: destinationDir,
              templatesDir: templatesDir,
              xcodeProjectType: xcodeProjectType,
            );

            simulatorDeviceId = deviceId;
            final Scenarios scenarios = Scenarios();
            final Map<String, Map<String, String>> scenariosMap = scenarios.scenarios(
              xcodeProjectType,
            );
            for (final String scenarioName in scenariosMap.keys) {
              if (testName != null && scenarioName != testName) {
                continue;
              }
              final List<FileReplacements> replacements = FileReplacements.fromScenario(
                scenariosMap[scenarioName]!,
                templatesDir: templatesDir,
                xcodeProjectDir: xcodeProjectDir,
                pluginDir: pluginDir,
                appDir: appDir,
              );

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
                xcodeProjectName: xcodeProjectName,
              );
              testCount++;
              if (result != 0) {
                testFailedCount++;
              }

              // Reset files to original between scenarios unless we're targetting a specific test.
              if (testName == null) {
                for (final FileReplacements replacement in replacements) {
                  replacement.reset();
                }
              }
            }
          }
        },
      );

      if (testFailedCount > 0) {
        return TaskResult.failure(
          '$testFailedCount out of $testCount native tests failed. Search the logs for "** TEST FAILED **"',
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
    options: <String>['--org', 'dev.flutter.devicelab', '--template=module', moduleName],
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
      'dev.flutter.devicelab',
      '--template=plugin',
      '--platform=ios',
      pluginName,
    ],
    workingDirectory: destinationDir.path,
  );
  return Directory(path.join(destinationDir.path, pluginName));
}

Future<(String, Directory)> _createNativeApp({
  required Directory templatesDir,
  required Directory destinationDir,
  required XcodeProjectType xcodeProjectType,
}) async {
  section('Create Xcode Project');

  final String xcodeProjectName;

  switch (xcodeProjectType) {
    case XcodeProjectType.UIKitSwift:
      xcodeProjectName = 'NativeUIKitSwiftExperiment';
    case XcodeProjectType.SwiftUI:
      xcodeProjectName = 'NativeSwiftUIExperiment';
  }
  // Copy Xcode project
  final Directory xcodeProjectDir = Directory(path.join(destinationDir.path, xcodeProjectName));
  xcodeProjectDir.createSync(recursive: true);
  final Directory xcodeProjectTemplate = Directory(path.join(templatesDir.path, xcodeProjectName));
  recursiveCopy(xcodeProjectTemplate, xcodeProjectDir);

  return (xcodeProjectName, xcodeProjectDir);
}

Future<void> _installPlugins({
  required Directory appDir,
  required Directory xcodeProjectDir,
}) async {
  // Poke the pubspec to reset the fingerprinter to ensure the module is re-generated.
  // See [_regenerateModuleFromTemplateIfNeeded] in packages/flutter_tools/lib/src/xcode_project.dart.
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
    <String>['install', '--verbose'],
    environment: <String, String>{
      // See https://github.com/flutter/flutter/issues/10873.
      // CocoaPods analytics adds a lot of latency.
      'COCOAPODS_DISABLE_STATS': 'true',
      'LANG': 'en_US.UTF-8',
    },
    workingDirectory: xcodeProjectDir.path,
  );
}

class FileReplacements {
  FileReplacements(this.templatePath, this.destinationPath);

  final String templatePath;
  final String destinationPath;
  String? originalContent;

  static List<FileReplacements> fromScenario(
    Map<String, String> replacementMap, {
    required Directory templatesDir,
    required Directory xcodeProjectDir,
    required Directory pluginDir,
    required Directory appDir,
  }) {
    final List<FileReplacements> replacements = <FileReplacements>[];
    for (final String source in replacementMap.keys) {
      final String destination = replacementMap[source]!;
      final String sourcePath = source.replaceFirst(r'$TEMPLATE_DIR', templatesDir.path);
      final String destinationPath = destination
          .replaceFirst(r'$XCODE_PROJ_DIR', xcodeProjectDir.path)
          .replaceFirst(r'$PLUGIN_DIR', pluginDir.path)
          .replaceFirst(r'$APP_DIR', appDir.path);
      replacements.add(FileReplacements(sourcePath, destinationPath));
    }
    return replacements;
  }

  void replace() {
    final File templateFile = File(templatePath);
    final File destinationFile = File(destinationPath);
    if (!destinationFile.existsSync()) {
      File(destinationPath).createSync(recursive: true);
    } else {
      originalContent = destinationFile.readAsStringSync();
    }
    templateFile.copySync(destinationPath);
  }

  void reset() {
    final File destinationFile = File(destinationPath);
    if (originalContent != null) {
      destinationFile.writeAsStringSync(originalContent!);
    } else {
      if (destinationFile.existsSync()) {
        destinationFile.deleteSync(recursive: true);
      }
    }
  }
}

Future<int> _testNativeApp({
  required Directory templatesDir,
  required String scenarioName,
  required Directory xcodeProjectDir,
  required String deviceId,
  required String xcodeProjectName,
}) async {
  final String resultBundleTemp = Directory.systemTemp
      .createTempSync('flutter_module_test_ios_xcresult.')
      .path;
  final String resultBundlePath = path.join(resultBundleTemp, 'result');
  final int testResultExit = await exec(
    'xcodebuild',
    <String>[
      '-workspace',
      '$xcodeProjectName.xcworkspace',
      '-scheme',
      xcodeProjectName,
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

enum XcodeProjectType { UIKitSwift, SwiftUI }

class Scenarios {
  Scenarios();

  Map<String, Map<String, String>> scenarios(XcodeProjectType projectType) {
    switch (projectType) {
      case XcodeProjectType.UIKitSwift:
        return uiKitSwiftScenarios;
      case XcodeProjectType.SwiftUI:
        return swiftUIScenarios;
    }
  }

  /// A map of scenario names to a map of file replacements.
  ///
  /// Each scenario is a different configuration for testing the Flutter module
  /// in a native iOS app. The file replacements are used to set up the
  /// specific configuration for each scenario.
  late Map<String, Map<String, String>> uiKitSwiftScenarios = <String, Map<String, String>>{
    ...basicLifecycleScenarios,
    ...stateRestorationScenarios,
    ...implicitEngineDelegateScenarios,
    ...multiSceneScenarios,
  };

  late Map<String, Map<String, String>> swiftUIScenarios = <String, Map<String, String>>{
    'SwiftUI-FlutterSceneDelegate': <String, String>{
      ...sharedAppLifecycleFiles,
      ...sharedPluginLifecycleFiles,
      r'$TEMPLATE_DIR/native/Info-migrated-no-config.plist':
          r'$XCODE_PROJ_DIR/NativeSwiftUIExperiment/NativeSwiftUIExperiment-Info.plist',
      r'$TEMPLATE_DIR/native/SwiftUIApp-FlutterSceneDelegate.swift':
          r'$XCODE_PROJ_DIR/NativeSwiftUIExperiment/NativeSwiftUIExperimentApp.swift',
      r'$TEMPLATE_DIR/native/SwiftUIApp-ContentView.swift':
          r'$XCODE_PROJ_DIR/NativeSwiftUIExperiment/ContentView.swift',
      r'$TEMPLATE_DIR/flutterplugin/ios/LifecyclePlugin-migrated.swift':
          r'$PLUGIN_DIR/ios/Classes/MyPlugin.swift',
      r'$TEMPLATE_DIR/native/UITests-SceneEvents-NoApplicationEvents.swift':
          r'$XCODE_PROJ_DIR/NativeSwiftUIExperimentUITests/NativeSwiftUIExperimentUITests.swift',
    },
    'SwiftUI-FlutterSceneLifeCycleProvider': <String, String>{
      ...sharedAppLifecycleFiles,
      ...sharedPluginLifecycleFiles,
      r'$TEMPLATE_DIR/native/Info-migrated-no-config.plist':
          r'$XCODE_PROJ_DIR/NativeSwiftUIExperiment/NativeSwiftUIExperiment-Info.plist',
      r'$TEMPLATE_DIR/native/SwiftUIApp-FlutterSceneLifeCycleProvider.swift':
          r'$XCODE_PROJ_DIR/NativeSwiftUIExperiment/NativeSwiftUIExperimentApp.swift',
      r'$TEMPLATE_DIR/native/SwiftUIApp-ContentView.swift':
          r'$XCODE_PROJ_DIR/NativeSwiftUIExperiment/ContentView.swift',
      r'$TEMPLATE_DIR/flutterplugin/ios/LifecyclePlugin-migrated.swift':
          r'$PLUGIN_DIR/ios/Classes/MyPlugin.swift',
      r'$TEMPLATE_DIR/native/UITests-SceneEvents-NoApplicationEvents.swift':
          r'$XCODE_PROJ_DIR/NativeSwiftUIExperimentUITests/NativeSwiftUIExperimentUITests.swift',
    },
  };

  late Map<String, Map<String, String>> basicLifecycleScenarios = <String, Map<String, String>>{
    // When both the app and the plugin have migrated to scenes, we expect scene events.
    'AppMigrated-FlutterSceneDelegate-PluginMigrated': <String, String>{
      ...sharedLifecycleFiles,
      r'$TEMPLATE_DIR/native/SceneDelegate-FlutterSceneDelegate.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/SceneDelegate.swift',
      r'$TEMPLATE_DIR/flutterplugin/ios/LifecyclePlugin-migrated.swift':
          r'$PLUGIN_DIR/ios/Classes/MyPlugin.swift',
      r'$TEMPLATE_DIR/native/UITests-SceneEvents.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperimentUITests/NativeUIKitSwiftExperimentUITests.swift',
    },

    // When the app has migrated but the plugin hasn't, we expect application events to be used as
    // a fallback.
    'AppMigrated-FlutterSceneDelegate-PluginNotMigrated': <String, String>{
      ...sharedLifecycleFiles,
      r'$TEMPLATE_DIR/native/SceneDelegate-FlutterSceneDelegate.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/SceneDelegate.swift',
      r'$TEMPLATE_DIR/flutterplugin/ios/LifecyclePlugin-unmigrated.swift':
          r'$PLUGIN_DIR/ios/Classes/MyPlugin.swift',
      r'$TEMPLATE_DIR/native/UITests-ApplicationEvents-AppMigrated.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperimentUITests/NativeUIKitSwiftExperimentUITests.swift',
    },

    // When both the app and the plugin have migrated to scenes, we expect scene events.
    'AppMigrated-FlutterSceneLifeCycleProvider-PluginMigrated': <String, String>{
      ...sharedLifecycleFiles,
      r'$TEMPLATE_DIR/native/SceneDelegate-FlutterSceneLifeCycleProvider.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/SceneDelegate.swift',
      r'$TEMPLATE_DIR/flutterplugin/ios/LifecyclePlugin-migrated.swift':
          r'$PLUGIN_DIR/ios/Classes/MyPlugin.swift',
      r'$TEMPLATE_DIR/native/UITests-SceneEvents.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperimentUITests/NativeUIKitSwiftExperimentUITests.swift',
    },

    // When the app has migrated but the plugin hasn't, we expect application events to be used as
    // a fallback.
    'AppMigrated-FlutterSceneLifeCycleProvider-PluginNotMigrated': <String, String>{
      ...sharedLifecycleFiles,
      r'$TEMPLATE_DIR/native/SceneDelegate-FlutterSceneLifeCycleProvider.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/SceneDelegate.swift',
      r'$TEMPLATE_DIR/flutterplugin/ios/LifecyclePlugin-unmigrated.swift':
          r'$PLUGIN_DIR/ios/Classes/MyPlugin.swift',
      r'$TEMPLATE_DIR/native/UITests-ApplicationEvents-AppMigrated.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperimentUITests/NativeUIKitSwiftExperimentUITests.swift',
    },

    // When the app has not migrated, but the plugin supports both, we expect application events.
    'AppNotMigrated-FlutterSceneDelegate-PluginMigrated': <String, String>{
      ...sharedLifecycleFiles,
      r'$TEMPLATE_DIR/native/Info-unmigrated.plist':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/Info.plist',
      r'$TEMPLATE_DIR/flutterplugin/ios/LifecyclePlugin-migrated.swift':
          r'$PLUGIN_DIR/ios/Classes/MyPlugin.swift',
      r'$TEMPLATE_DIR/native/UITests-ApplicationEvents-AppNotMigrated.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperimentUITests/NativeUIKitSwiftExperimentUITests.swift',
    },

    // When the app and plugin have not migrated, we expect application events.
    'AppNotMigrated-FlutterSceneDelegate-PluginNotMigrated': <String, String>{
      ...sharedLifecycleFiles,
      r'$TEMPLATE_DIR/native/Info-unmigrated.plist':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/Info.plist',
      r'$TEMPLATE_DIR/flutterplugin/ios/LifecyclePlugin-unmigrated.swift':
          r'$PLUGIN_DIR/ios/Classes/MyPlugin.swift',
      r'$TEMPLATE_DIR/native/UITests-ApplicationEvents-AppNotMigrated.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperimentUITests/NativeUIKitSwiftExperimentUITests.swift',
    },
  };

  late Map<String, Map<String, String>> multiSceneScenarios = <String, Map<String, String>>{
    // When multi scene is enabled and the rootViewController is a FlutterViewController, we
    // expect all scene events without manual registration.
    'MultiSceneEnabled-FlutterSceneDelegate-RootViewController': <String, String>{
      ...sharedAppLifecycleFiles,
      ...sharedPluginLifecycleFiles,
      r'$TEMPLATE_DIR/native/Info-MultiSceneEnabled-Storyboard.plist':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/Info.plist',
      r'$TEMPLATE_DIR/native/AppDelegate-FlutterAppDelegate.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/AppDelegate.swift',
      r'$TEMPLATE_DIR/native/Main-FlutterViewController.storyboard':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/Base.lproj/Main.storyboard',
      r'$TEMPLATE_DIR/native/SceneDelegate-FlutterSceneDelegate.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/SceneDelegate.swift',
      r'$TEMPLATE_DIR/flutterplugin/ios/LifecyclePlugin-migrated.swift':
          r'$PLUGIN_DIR/ios/Classes/MyPlugin.swift',
      r'$TEMPLATE_DIR/native/UITests-SceneEvents.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperimentUITests/NativeUIKitSwiftExperimentUITests.swift',
    },

    // When multi scene is enabled and the ViewController is created programatically with a
    // manually registered FlutterEngine, we expect all scene events.
    'MultiSceneEnabled-FlutterSceneDelegate-ManualRegistration-NoStoryboard': <String, String>{
      ...sharedAppLifecycleFiles,
      ...sharedPluginLifecycleFiles,
      r'$TEMPLATE_DIR/native/Info-MultiSceneEnabled-NoStoryboard.plist':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/Info.plist',
      r'$TEMPLATE_DIR/native/AppDelegate-FlutterAppDelegate.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/AppDelegate.swift',
      r'$TEMPLATE_DIR/native/SceneDelegate-FlutterSceneDelegate-MultiScene-NoStoryboard.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/SceneDelegate.swift',
      r'$TEMPLATE_DIR/native/ViewController-FlutterEngineFromSceneDelegate-NoStoryboard.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/ViewController.swift',
      r'$TEMPLATE_DIR/flutterplugin/ios/LifecyclePlugin-migrated.swift':
          r'$PLUGIN_DIR/ios/Classes/MyPlugin.swift',
      r'$TEMPLATE_DIR/native/UITests-SceneEvents-NoApplicationEvents.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperimentUITests/NativeUIKitSwiftExperimentUITests.swift',
    },

    // When multi scene is enabled and the ViewController is created via Storyboard with a
    // manually registered FlutterEngine, we expect all scene events.
    'MultiSceneEnabled-FlutterSceneDelegate-ManualRegistration-Storyboard': <String, String>{
      ...sharedAppLifecycleFiles,
      ...sharedPluginLifecycleFiles,
      r'$TEMPLATE_DIR/native/Info-MultiSceneEnabled-Storyboard.plist':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/Info.plist',
      r'$TEMPLATE_DIR/native/AppDelegate-FlutterAppDelegate.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/AppDelegate.swift',
      r'$TEMPLATE_DIR/native/SceneDelegate-FlutterSceneDelegate-MultiScene-Storyboard.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/SceneDelegate.swift',
      r'$TEMPLATE_DIR/native/ViewController-FlutterEngineFromSceneDelegate-Storyboard.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/ViewController.swift',
      r'$TEMPLATE_DIR/flutterplugin/ios/LifecyclePlugin-migrated.swift':
          r'$PLUGIN_DIR/ios/Classes/MyPlugin.swift',
      r'$TEMPLATE_DIR/native/UITests-SceneEvents-NoApplicationEvents.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperimentUITests/NativeUIKitSwiftExperimentUITests.swift',
    },
  };

  late Map<String, Map<String, String>> stateRestorationScenarios = <String, Map<String, String>>{
    // State restoration work both when migrated and when not.
    'AppMigrated-StateRestoration': <String, String>{...sharedStateRestorationFiles},
    'AppNotMigrated-StateRestoration': <String, String>{
      ...sharedStateRestorationFiles,
      r'$TEMPLATE_DIR/native/Info-unmigrated.plist':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/Info.plist',
    },
  };

  late Map<String, Map<String, String>>
  implicitEngineDelegateScenarios = <String, Map<String, String>>{
    // When using an implicit FlutterEngine created by the storyboard, we expect plugins to
    // receive application launch events and scene events.
    'FlutterImplicitEngineDelegate-AppMigrated-StoryboardFlutterViewController': <String, String>{
      ...sharedAppLifecycleFiles,
      ...sharedPluginLifecycleFiles,
      r'$TEMPLATE_DIR/native/SceneDelegate-FlutterSceneDelegate.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/SceneDelegate.swift',
      r'$TEMPLATE_DIR/flutterplugin/ios/LifecyclePlugin-migrated.swift':
          r'$PLUGIN_DIR/ios/Classes/MyPlugin.swift',
      r'$TEMPLATE_DIR/native/Main-FlutterViewController.storyboard':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/Base.lproj/Main.storyboard',
      r'$TEMPLATE_DIR/native/AppDelegate-FlutterImplicitEngineDelegate.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/AppDelegate.swift',
      r'$TEMPLATE_DIR/native/UITests-SceneEvents-ApplicationLaunchEvents.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperimentUITests/NativeUIKitSwiftExperimentUITests.swift',
    },

    // When registering plugins with the AppDelegate's self (and therefore the FlutterLaunchEngine)
    // alongside the FlutterImplicitEngineDelegate, we expect application events starting where
    // registration occurs, such as `application:didFinishingLaunchingWithOptions`.
    'FlutterImplicitEngineDelegateWithLaunchEngine-AppMigrated-StoryboardFlutterViewController':
        <String, String>{
          ...sharedAppLifecycleFiles,
          ...sharedPluginLifecycleFiles,
          r'$TEMPLATE_DIR/native/SceneDelegate-FlutterSceneDelegate.swift':
              r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/SceneDelegate.swift',
          r'$TEMPLATE_DIR/flutterplugin/ios/LifecyclePlugin-migrated.swift':
              r'$PLUGIN_DIR/ios/Classes/MyPlugin.swift',
          r'$TEMPLATE_DIR/native/Main-FlutterViewController.storyboard':
              r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/Base.lproj/Main.storyboard',
          r'$TEMPLATE_DIR/native/AppDelegate-FlutterImplicitEngineDelegateWithLaunchEngine.swift':
              r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/AppDelegate.swift',
          r'$TEMPLATE_DIR/native/UITests-SceneEvents.swift':
              r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperimentUITests/NativeUIKitSwiftExperimentUITests.swift',
        },

    // When the app has not migrated to scenes, storyboard is instantiated earlier in the lifecycle.
    // So when using an implicit FlutterEngine created by the storyboard, we expect plugins to
    // receive all application events.
    'FlutterImplicitEngineDelegate-AppNotMigrated-StoryboardFlutterViewController': <String, String>{
      ...sharedAppLifecycleFiles,
      ...sharedPluginLifecycleFiles,
      r'$TEMPLATE_DIR/native/Info-unmigrated.plist':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/Info.plist',
      r'$TEMPLATE_DIR/native/SceneDelegate-FlutterSceneDelegate.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/SceneDelegate.swift',
      r'$TEMPLATE_DIR/flutterplugin/ios/LifecyclePlugin-migrated.swift':
          r'$PLUGIN_DIR/ios/Classes/MyPlugin.swift',
      r'$TEMPLATE_DIR/native/AppDelegate-FlutterImplicitEngineDelegate.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/AppDelegate.swift',
      r'$TEMPLATE_DIR/native/Main-FlutterViewController.storyboard':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/Base.lproj/Main.storyboard',
      r'$TEMPLATE_DIR/native/UITests-ApplicationEvents-FlutterImplicitEngineDelegate.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperimentUITests/NativeUIKitSwiftExperimentUITests.swift',
    },

    // When using an implicit FlutterEngine, created by the FlutterViewController in another
    // ViewController, we expect plugins to be registered after the FlutterViewController is
    // created, which results in the `application:didFinishLaunchingWithOptions:` and
    // `scene:willConnectToSession:options:` events being missed. This is not a expected use case
    // but it could be utilized.
    'FlutterImplicitEngineDelegate-AppMigrated-ImplicitFlutterEngine': <String, String>{
      ...sharedAppLifecycleFiles,
      ...sharedPluginLifecycleFiles,
      r'$TEMPLATE_DIR/native/SceneDelegate-FlutterSceneDelegate.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/SceneDelegate.swift',
      r'$TEMPLATE_DIR/flutterplugin/ios/LifecyclePlugin-migrated.swift':
          r'$PLUGIN_DIR/ios/Classes/MyPlugin.swift',
      r'$TEMPLATE_DIR/native/AppDelegate-FlutterImplicitEngineDelegate.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/AppDelegate.swift',
      r'$TEMPLATE_DIR/native/ViewController-ImplicitFlutterEngine.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/ViewController.swift',
      r'$TEMPLATE_DIR/native/UITests-SceneEventsNoConnect-NoApplicationEvents.swift':
          r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperimentUITests/NativeUIKitSwiftExperimentUITests.swift',
    },
  };

  late Map<String, String> sharedLifecycleFiles = <String, String>{
    ...sharedAppLifecycleFiles,
    ...sharedPluginLifecycleFiles,
    r'$TEMPLATE_DIR/native/AppDelegate-FlutterAppDelegate-FlutterEngine.swift':
        r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/AppDelegate.swift',
    r'$TEMPLATE_DIR/native/ViewController-FlutterEngineFromAppDelegate.swift':
        r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/ViewController.swift',
  };

  late Map<String, String> sharedAppLifecycleFiles = <String, String>{
    r'$TEMPLATE_DIR/flutterapp/lib/main-LifeCycleTest': r'$APP_DIR/lib/main.dart',
    r'$TEMPLATE_DIR/flutterapp/pubspec-LifeCycleTest.yaml': r'$APP_DIR/pubspec.yaml',
  };

  late Map<String, String> sharedPluginLifecycleFiles = <String, String>{
    r'$TEMPLATE_DIR/flutterplugin/lib/lifecycle_plugin': r'$PLUGIN_DIR/lib/my_plugin.dart',
    r'$TEMPLATE_DIR/flutterplugin/lib/lifecycle_plugin_method_channel':
        r'$PLUGIN_DIR/lib/my_plugin_method_channel.dart',
    r'$TEMPLATE_DIR/flutterplugin/lib/lifecycle_plugin_platform_interface':
        r'$PLUGIN_DIR/lib/my_plugin_platform_interface.dart',
  };

  late Map<String, String> sharedStateRestorationFiles = <String, String>{
    r'$TEMPLATE_DIR/flutterapp/lib/main-StateRestorationTest': r'$APP_DIR/lib/main.dart',
    r'$TEMPLATE_DIR/native/AppDelegate-FlutterAppDelegate-FlutterEngine.swift':
        r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/AppDelegate.swift',
    r'$TEMPLATE_DIR/native/SceneDelegate-FlutterSceneDelegate.swift':
        r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/SceneDelegate.swift',
    r'$TEMPLATE_DIR/native/Main-FlutterViewController-RestorationId.storyboard':
        r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperiment/Base.lproj/Main.storyboard',
    r'$TEMPLATE_DIR/native/UITests-StateRestoration.swift':
        r'$XCODE_PROJ_DIR/NativeUIKitSwiftExperimentUITests/NativeUIKitSwiftExperimentUITests.swift',
  };
}
