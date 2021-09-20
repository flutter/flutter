// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/ios.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

/// Tests that iOS .xcframeworks can be built.
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
    '\ndependencies:\n  device_info: 0.4.1\n  package_info: 0.4.0+9\n  connectivity: 3.0.3\n',
  );
  pubspec.writeAsStringSync(content, flush: true);
  await inDirectory(projectDir, () async {
    await flutter(
      'packages',
      options: <String>['get'],
    );
  });

  // First, build the module in Debug to copy the debug version of Flutter.xcframework.
  // This proves "flutter build ios-framework" re-copies the relevant Flutter.xcframework,
  // otherwise building plugins with bitcode will fail linking because the debug version
  // of Flutter.xcframework does not contain bitcode.
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
        '--verbose',
        '--output=$outputDirectoryName',
        '--obfuscate',
        '--split-debug-info=symbols',
      ],
    );
  });

  final String outputPath = path.join(projectDir.path, outputDirectoryName);

  checkFileExists(path.join(
    outputPath,
    'Debug',
    'Flutter.xcframework',
    'ios-arm64_armv7',
    'Flutter.framework',
    'Flutter',
  ));

  final String debugAppFrameworkPath = path.join(
    outputPath,
    'Debug',
    'App.xcframework',
    'ios-arm64_armv7',
    'App.framework',
    'App',
  );
  checkFileExists(debugAppFrameworkPath);

  checkFileExists(path.join(
    outputPath,
    'Debug',
    'App.xcframework',
    'ios-arm64_armv7',
    'App.framework',
    'Info.plist',
  ));

  section('Check debug build has Dart snapshot as asset');

  checkFileExists(path.join(
    outputPath,
    'Debug',
    'App.xcframework',
    'ios-arm64_x86_64-simulator',
    'App.framework',
    'flutter_assets',
    'vm_snapshot_data',
  ));

  section('Check obfuscation symbols');

  checkFileExists(path.join(
    projectDir.path,
    'symbols',
    'app.ios-arm64.symbols',
  ));

  checkFileExists(path.join(
    projectDir.path,
    'symbols',
    'app.ios-armv7.symbols',
  ));

  section('Check debug build has no Dart AOT');

  final String aotSymbols = await _dylibSymbols(debugAppFrameworkPath);

  if (aotSymbols.contains('architecture') ||
      aotSymbols.contains('_kDartVmSnapshot')) {
    throw TaskResult.failure('Debug App.framework contains AOT');
  }

  section('Check profile, release builds has Dart AOT dylib');

  for (final String mode in <String>['Profile', 'Release']) {
    final String appFrameworkPath = path.join(
      outputPath,
      mode,
      'App.xcframework',
      'ios-arm64_armv7',
      'App.framework',
      'App',
    );

    await _checkBitcode(appFrameworkPath, mode);

    final String aotSymbols = await _dylibSymbols(appFrameworkPath);

    if (!aotSymbols.contains('_kDartVmSnapshot')) {
      throw TaskResult.failure('$mode App.framework missing Dart AOT');
    }

    checkFileNotExists(path.join(
      outputPath,
      mode,
      'App.xcframework',
      'ios-arm64_armv7',
      'App.framework',
      'flutter_assets',
      'vm_snapshot_data',
    ));

    checkFileExists(path.join(
      outputPath,
      mode,
      'App.xcframework',
      'ios-arm64_x86_64-simulator',
      'App.framework',
      'App',
    ));

    checkFileExists(path.join(
      outputPath,
      mode,
      'App.xcframework',
      'ios-arm64_x86_64-simulator',
      'App.framework',
      'Info.plist',
    ));
  }

  section("Check all modes' engine dylib");

  for (final String mode in <String>['Debug', 'Profile', 'Release']) {
    final String engineFrameworkPath = path.join(
      outputPath,
      mode,
      'Flutter.xcframework',
      'ios-arm64_armv7',
      'Flutter.framework',
      'Flutter',
    );

    await _checkBitcode(engineFrameworkPath, mode);

    checkFileExists(path.join(
      outputPath,
      mode,
      'Flutter.xcframework',
      'ios-arm64_x86_64-simulator',
      'Flutter.framework',
      'Flutter',
    ));

    checkFileExists(path.join(
      outputPath,
      mode,
      'Flutter.xcframework',
      'ios-arm64_x86_64-simulator',
      'Flutter.framework',
      'Headers',
      'Flutter.h',
    ));
  }

  section('Check all modes have plugins');

  for (final String mode in <String>['Debug', 'Profile', 'Release']) {
    final String pluginFrameworkPath = path.join(
      outputPath,
      mode,
      'device_info.xcframework',
      'ios-arm64_armv7',
      'device_info.framework',
      'device_info',
    );
    await _checkBitcode(pluginFrameworkPath, mode);
    if (!await _linksOnFlutter(pluginFrameworkPath)) {
      throw TaskResult.failure('$pluginFrameworkPath does not link on Flutter');
    }

    final String transitiveDependencyFrameworkPath = path.join(
      outputPath,
      mode,
      'Reachability.xcframework',
      'ios-arm64_armv7',
      'Reachability.framework',
      'Reachability',
    );
    if (await _linksOnFlutter(transitiveDependencyFrameworkPath)) {
      throw TaskResult.failure('Transitive dependency $transitiveDependencyFrameworkPath unexpectedly links on Flutter');
    }

    checkFileExists(path.join(
      outputPath,
      mode,
      'device_info.xcframework',
      'ios-arm64_armv7',
      'device_info.framework',
      'Headers',
      'DeviceInfoPlugin.h',
    ));

    if (mode != 'Debug') {
      checkDirectoryExists(path.join(
        outputPath,
        mode,
        'device_info.xcframework',
        'ios-arm64_armv7',
        'dSYMs',
        'device_info.framework.dSYM',
      ));
    }

    final String simulatorFrameworkPath = path.join(
      outputPath,
      mode,
      'device_info.xcframework',
      'ios-arm64_x86_64-simulator',
      'device_info.framework',
      'device_info',
    );

    final String simulatorFrameworkHeaderPath = path.join(
      outputPath,
      mode,
      'device_info.xcframework',
      'ios-arm64_x86_64-simulator',
      'device_info.framework',
      'Headers',
      'DeviceInfoPlugin.h',
    );

    checkFileExists(simulatorFrameworkPath);
    checkFileExists(simulatorFrameworkHeaderPath);
  }

  checkDirectoryExists(path.join(
    outputPath,
    'Release',
    'device_info.xcframework',
    'ios-arm64_armv7',
    'BCSymbolMaps',
  ));

  section('Check all modes have generated plugin registrant');

  for (final String mode in <String>['Debug', 'Profile', 'Release']) {
    if (!isModule) {
      continue;
    }
    final String registrantFrameworkPath = path.join(
      outputPath,
      mode,
      'FlutterPluginRegistrant.xcframework',
      'ios-arm64_armv7',
      'FlutterPluginRegistrant.framework',
      'FlutterPluginRegistrant',
    );
    await _checkBitcode(registrantFrameworkPath, mode);

    checkFileExists(path.join(
      outputPath,
      mode,
      'FlutterPluginRegistrant.xcframework',
      'ios-arm64_armv7',
      'FlutterPluginRegistrant.framework',
      'Headers',
      'GeneratedPluginRegistrant.h',
    ));
    final String simulatorHeaderPath = path.join(
      outputPath,
      mode,
      'FlutterPluginRegistrant.xcframework',
      'ios-arm64_x86_64-simulator',
      'FlutterPluginRegistrant.framework',
      'Headers',
      'GeneratedPluginRegistrant.h',
    );
    checkFileExists(simulatorHeaderPath);
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
      'App.xcframework',
    ));

    if (Directory(path.join(
          cocoapodsOutputPath,
          mode,
          'FlutterPluginRegistrant.xcframework',
        )).existsSync() !=
        isModule) {
      throw TaskResult.failure(
          'Unexpected FlutterPluginRegistrant.xcframework.');
    }

    checkDirectoryExists(path.join(
      cocoapodsOutputPath,
      mode,
      'device_info.xcframework',
    ));

    checkDirectoryExists(path.join(
      cocoapodsOutputPath,
      mode,
      'package_info.xcframework',
    ));

    checkDirectoryExists(path.join(
      cocoapodsOutputPath,
      mode,
      'connectivity.xcframework',
    ));

    checkDirectoryExists(path.join(
      cocoapodsOutputPath,
      mode,
      'Reachability.xcframework',
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

Future<void> _checkBitcode(String frameworkPath, String mode) async {
  checkFileExists(frameworkPath);

  // Bitcode only needed in Release mode for archiving.
  if (mode == 'Release' && !await containsBitcode(frameworkPath)) {
    throw TaskResult.failure('$frameworkPath does not contain bitcode');
  }
}

Future<String> _dylibSymbols(String pathToDylib) {
  return eval('nm', <String>[
    '-g',
    pathToDylib,
    '-arch',
    'arm64',
  ]);
}

Future<bool> _linksOnFlutter(String pathToBinary) async {
  final String loadCommands = await eval('otool', <String>[
    '-l',
    '-arch',
    'arm64',
    pathToBinary,
  ]);
  return loadCommands.contains('Flutter.framework');
}
