// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/ios.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

/// Tests that iOS .frameworks can be built on module projects.
Future<void> main() async {
  await task(() async {

    section('Create module project');

    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_module_test.');
    try {
      await inDirectory(tempDir, () async {
        section('Test module template');

        final Directory moduleProjectDir =
            Directory(path.join(tempDir.path, 'hello_module'));
        await flutter(
          'create',
          options: <String>[
            '--org',
            'io.flutter.devicelab',
            '--template',
            'module',
            'hello_module'
          ],
        );

        await _testBuildIosFramework(moduleProjectDir, isModule: true);

        section('Test app template');

        final Directory projectDir =
            Directory(path.join(tempDir.path, 'hello_project'));
        await flutter(
          'create',
          options: <String>['--org', 'io.flutter.devicelab', 'hello_project'],
        );

        await _testBuildIosFramework(projectDir);
      });

      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e) {
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  });
}

Future<void> _testBuildIosFramework(Directory projectDir, { bool isModule = false}) async {
  section('Add plugins');

  final File pubspec = File(path.join(projectDir.path, 'pubspec.yaml'));
  String content = pubspec.readAsStringSync();
  content = content.replaceFirst(
    '\ndependencies:\n',
    '\ndependencies:\n  device_info: 0.4.1\n  package_info: 0.4.0+9\n',
  );
  pubspec.writeAsStringSync(content, flush: true);
  await inDirectory(projectDir, () async {
    await flutter(
      'packages',
      options: <String>['get'],
    );
  });

  // First, build the module in Debug to copy the debug version of Flutter.framework.
  // This proves "flutter build ios-framework" re-copies the relevant Flutter.framework,
  // otherwise building plugins with bitcode will fail linking because the debug version
  // of Flutter.framework does not contain bitcode.
  await inDirectory(projectDir, () async {
    await flutter(
      'build',
      options: <String>[
        'ios',
        '--debug',
        '--no-codesign',
      ],
    );
  });

  // This builds all build modes' frameworks by default
  section('Build frameworks');

  const String outputDirectoryName = 'flutter-frameworks';

  await inDirectory(projectDir, () async {
    await flutter(
      'build',
      options: <String>[
        'ios-framework',
        '--universal',
        '--verbose',
        '--output=$outputDirectoryName'
      ],
    );
  });

  final String outputPath = path.join(projectDir.path, outputDirectoryName);

  section('Check debug build has Dart snapshot as asset');

  checkFileExists(path.join(
    outputPath,
    'Debug',
    'App.framework',
    'flutter_assets',
    'vm_snapshot_data',
  ));

  section('Check debug build has no Dart AOT');

  // There's still an App.framework with a dylib, but it's empty.
  checkFileExists(path.join(
    outputPath,
    'Debug',
    'App.framework',
    'App',
  ));

  final String debugAppFrameworkPath = path.join(
    outputPath,
    'Debug',
    'App.framework',
    'App',
  );
  final String aotSymbols = await dylibSymbols(debugAppFrameworkPath);

  if (aotSymbols.contains('architecture') ||
      aotSymbols.contains('_kDartVmSnapshot')) {
    throw TaskResult.failure('Debug App.framework contains AOT');
  }
  await _checkFrameworkArchs(debugAppFrameworkPath, true);

  // Xcode changed the name of this generated directory in Xcode 12.
  const String xcode11ArmDirectoryName = 'ios-armv7_arm64';
  const String xcode12ArmDirectoryName = 'ios-arm64_armv7';

  final String xcode11AppFrameworkDirectory = path.join(
    outputPath,
    'Debug',
    'App.xcframework',
    xcode11ArmDirectoryName,
    'App.framework',
    'App',
  );
  final String xcode12AppFrameworkDirectory = path.join(
    outputPath,
    'Debug',
    'App.xcframework',
    xcode12ArmDirectoryName,
    'App.framework',
    'App',
  );

  // Based on the locally installed version of Xcode.
  String localXcodeArmDirectoryName;
  if (exists(File(xcode11AppFrameworkDirectory))) {
    localXcodeArmDirectoryName = xcode11ArmDirectoryName;
  } else if (exists(File(xcode12AppFrameworkDirectory))) {
    localXcodeArmDirectoryName = xcode12ArmDirectoryName;
  } else {
    throw const FileSystemException('Expected App.framework binary to exist.');
  }

  final String xcode11FlutterFrameworkDirectory = path.join(
    outputPath,
    'Debug',
    'Flutter.xcframework',
    xcode11ArmDirectoryName,
    'Flutter.framework',
    'Flutter',
  );
  final String xcode12FlutterFrameworkDirectory = path.join(
    outputPath,
    'Debug',
    'Flutter.xcframework',
    xcode12ArmDirectoryName,
    'Flutter.framework',
    'Flutter',
  );

  // Based on the version of Xcode installed on the engine builder.
  String builderXcodeArmDirectoryName;
  if (exists(File(xcode11FlutterFrameworkDirectory))) {
    builderXcodeArmDirectoryName = xcode11ArmDirectoryName;
  } else if (exists(File(xcode12FlutterFrameworkDirectory))) {
    builderXcodeArmDirectoryName = xcode12ArmDirectoryName;
  } else {
    throw const FileSystemException('Expected Flutter.framework binary to exist.');
  }

  checkFileExists(path.join(
    outputPath,
    'Debug',
    'App.xcframework',
    'ios-x86_64-simulator',
    'App.framework',
    'App',
  ));

  section('Check profile, release builds has Dart AOT dylib');

  for (final String mode in <String>['Profile', 'Release']) {
    final String appFrameworkPath = path.join(
      outputPath,
      mode,
      'App.framework',
      'App',
    );

    await _checkFrameworkArchs(appFrameworkPath, false);
    await _checkBitcode(appFrameworkPath, mode);

    final String aotSymbols = await dylibSymbols(appFrameworkPath);

    if (!aotSymbols.contains('_kDartVmSnapshot')) {
      throw TaskResult.failure('$mode App.framework missing Dart AOT');
    }

    checkFileNotExists(path.join(
      outputPath,
      mode,
      'App.framework',
      'flutter_assets',
      'vm_snapshot_data',
    ));

    checkFileExists(path.join(
      outputPath,
      mode,
      'App.xcframework',
      localXcodeArmDirectoryName,
      'App.framework',
      'App',
    ));

    checkFileNotExists(path.join(
      outputPath,
      mode,
      'App.xcframework',
      'ios-x86_64-simulator',
      'App.framework',
      'App',
    ));
  }

  section("Check all modes' engine dylib");

  for (final String mode in <String>['Debug', 'Profile', 'Release']) {
    final String engineFrameworkPath = path.join(
      outputPath,
      mode,
      'Flutter.framework',
      'Flutter',
    );

    await _checkFrameworkArchs(engineFrameworkPath, true);
    await _checkBitcode(engineFrameworkPath, mode);

    checkFileExists(path.join(
      outputPath,
      mode,
      'Flutter.xcframework',
      builderXcodeArmDirectoryName,
      'Flutter.framework',
      'Flutter',
    ));
    checkFileExists(path.join(
      outputPath,
      mode,
      'Flutter.xcframework',
      'ios-x86_64-simulator',
      'Flutter.framework',
      'Flutter',
    ));
  }

  section("Check all modes' engine header");

  for (final String mode in <String>['Debug', 'Profile', 'Release']) {
    checkFileExists(path.join(outputPath, mode, 'Flutter.framework', 'Headers', 'Flutter.h'));
  }

  section('Check all modes have plugins');

  for (final String mode in <String>['Debug', 'Profile', 'Release']) {
    final String pluginFrameworkPath = path.join(
      outputPath,
      mode,
      'device_info.framework',
      'device_info',
    );
    await _checkFrameworkArchs(pluginFrameworkPath, mode == 'Debug');
    await _checkBitcode(pluginFrameworkPath, mode);

    checkFileExists(path.join(
      outputPath,
      mode,
      'device_info.xcframework',
      localXcodeArmDirectoryName,
      'device_info.framework',
      'device_info',
    ));

    checkFileExists(path.join(
      outputPath,
      mode,
      'device_info.xcframework',
      localXcodeArmDirectoryName,
      'device_info.framework',
      'Headers',
      'DeviceInfoPlugin.h',
    ));

    final String simulatorFrameworkPath = path.join(
      outputPath,
      mode,
      'device_info.xcframework',
      'ios-x86_64-simulator',
      'device_info.framework',
      'device_info',
    );

    final String simulatorFrameworkHeaderPath = path.join(
      outputPath,
      mode,
      'device_info.xcframework',
      'ios-x86_64-simulator',
      'device_info.framework',
      'Headers',
      'DeviceInfoPlugin.h',
    );

    if (mode == 'Debug') {
      checkFileExists(simulatorFrameworkPath);
      checkFileExists(simulatorFrameworkHeaderPath);
    } else {
      checkFileNotExists(simulatorFrameworkPath);
      checkFileNotExists(simulatorFrameworkHeaderPath);
    }
  }

  section('Check all modes have generated plugin registrant');

  for (final String mode in <String>['Debug', 'Profile', 'Release']) {
    if (!isModule) {
      continue;
    }
    final String registrantFrameworkPath = path.join(
      outputPath,
      mode,
      'FlutterPluginRegistrant.framework',
      'FlutterPluginRegistrant'
    );

    await _checkFrameworkArchs(registrantFrameworkPath, mode == 'Debug');
    await _checkBitcode(registrantFrameworkPath, mode);

    checkFileExists(path.join(
      outputPath,
      mode,
      'FlutterPluginRegistrant.framework',
      'Headers',
      'GeneratedPluginRegistrant.h',
    ));
    checkFileExists(path.join(
      outputPath,
      mode,
      'FlutterPluginRegistrant.xcframework',
      localXcodeArmDirectoryName,
      'FlutterPluginRegistrant.framework',
      'Headers',
      'GeneratedPluginRegistrant.h',
    ));
    final String simulatorHeaderPath = path.join(
      outputPath,
      mode,
      'FlutterPluginRegistrant.xcframework',
      'ios-x86_64-simulator',
      'FlutterPluginRegistrant.framework',
      'Headers',
      'GeneratedPluginRegistrant.h',
    );
    if (mode == 'Debug') {
      checkFileExists(simulatorHeaderPath);
    } else {
      checkFileNotExists(simulatorHeaderPath);
    }
  }

  // This builds all build modes' frameworks by default
  section('Build podspec');

  const String cocoapodsOutputDirectoryName = 'flutter-frameworks-cocoapods';

  await inDirectory(projectDir, () async {
    await flutter(
      'build',
      options: <String>[
        'ios-framework',
        '--cocoapods',
        '--universal',
        '--force', // Allow podspec creation on master.
        '--output=$cocoapodsOutputDirectoryName'
      ],
    );
  });

  final String cocoapodsOutputPath = path.join(projectDir.path, cocoapodsOutputDirectoryName);
  for (final String mode in <String>['Debug', 'Profile', 'Release']) {
    checkFileExists(path.join(
      cocoapodsOutputPath,
      mode,
      'Flutter.podspec',
    ));

    checkDirectoryExists(path.join(
      cocoapodsOutputPath,
      mode,
      'App.framework',
    ));

    if (Directory(path.join(
          cocoapodsOutputPath,
          mode,
          'FlutterPluginRegistrant.framework',
        )).existsSync() !=
        isModule) {
      throw TaskResult.failure(
          'Unexpected FlutterPluginRegistrant.framework.');
    }

    checkDirectoryExists(path.join(
      cocoapodsOutputPath,
      mode,
      'device_info.framework',
    ));

    checkDirectoryExists(path.join(
      cocoapodsOutputPath,
      mode,
      'package_info.framework',
    ));
  }

  if (File(path.join(
        outputPath,
        'GeneratedPluginRegistrant.h',
      )).existsSync() ==
      isModule) {
    throw TaskResult.failure('Unexpected GeneratedPluginRegistrant.h.');
  }

  if (File(path.join(
        outputPath,
        'GeneratedPluginRegistrant.m',
      )).existsSync() ==
      isModule) {
    throw TaskResult.failure('Unexpected GeneratedPluginRegistrant.m.');
  }
}

Future<void> _checkFrameworkArchs(String frameworkPath, bool shouldContainSimulator) async {
  checkFileExists(frameworkPath);

  final String archs = await fileType(frameworkPath);
  if (!archs.contains('armv7')) {
    throw TaskResult.failure('$frameworkPath armv7 architecture missing');
  }

  if (!archs.contains('arm64')) {
    throw TaskResult.failure('$frameworkPath arm64 architecture missing');
  }
  final bool containsSimulator = archs.contains('x86_64');

  // Debug should contain the simulator archs.
  // Release and Profile should not.
  if (containsSimulator != shouldContainSimulator) {
    throw TaskResult.failure(
        '$frameworkPath x86_64 architecture ${shouldContainSimulator ? 'missing' : 'present'}');
  }
}

Future<void> _checkBitcode(String frameworkPath, String mode) async {
  checkFileExists(frameworkPath);

  // Bitcode only needed in Release mode for archiving.
  if (mode == 'Release' && !await containsBitcode(frameworkPath)) {
    throw TaskResult.failure('$frameworkPath does not contain bitcode');
  }
}
