// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:io';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/dart_plugin_registrant.dart';
import 'package:flutter_tools/src/project.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';

const String _kSamplePackageJson = '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "path_provider_linux",
      "rootUri": "/path_provider_linux",
      "packageUri": "lib/",
      "languageVersion": "2.12"
    }
  ]
}
''';

const String _kSamplePackagesFile = '''
path_provider_linux:/path_provider_linux/lib/
''';

const String _kSamplePackageJsonWindows = '''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "path_provider_linux",
      "rootUri": "file:///C:/path_provider_linux",
      "packageUri": "lib/",
      "languageVersion": "2.12"
    }
  ]
}
''';

const String _kSamplePackagesFileWindows = '''
path_provider_linux:file:///C:/path_provider_linux/lib/
''';

const String _kSamplePubspecFile = '''
name: path_provider_example
description: Demonstrates how to use the path_provider plugin.

dependencies:
  flutter:
    sdk: flutter
  path_provider_linux: 1.0.0
''';

const String _kNoPluginsRegistrant = '''
@pragma('vm:entry-point')
void _registerPlugins() {
  if (Platform.isLinux) {
  } else if (Platform.isMacOS) {
  } else if (Platform.isWindows) {
  }
}
''';

const String _kLinuxRegistrant = '''
@pragma('vm:entry-point')
void _registerPlugins() {
  if (Platform.isLinux) {
      PathProviderLinux.registerWith();
  } else if (Platform.isMacOS) {
  } else if (Platform.isWindows) {
  }
}
''';

const String _kSamplePluginPubspec = '''
name: path_provider_linux
description: linux implementation of the path_provider plugin
// version: 2.0.1
// homepage: https://github.com/flutter/plugins/tree/master/packages/path_provider/path_provider_linux

flutter:
  plugin:
    implements: path_provider
    platforms:
      linux:
        dartPluginClass: PathProviderLinux
        pluginClass: none

environment:
  sdk: ">=2.12.0-259.9.beta <3.0.0"
  flutter: ">=1.20.0"
''';

void main() {
  testWithoutContext('skipped based on environment.generateDartPluginRegistry',
      () async {
    final FileSystem fileSystem = _getFileSystem();
    final Environment environment = Environment.test(
        fileSystem.currentDirectory,
        artifacts: null,
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        generateDartPluginRegistry: false);

    expect(const DartPluginRegistrantTarget().canSkip(environment), true);

    final Environment environment2 = Environment.test(
        fileSystem.currentDirectory,
        artifacts: null,
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        generateDartPluginRegistry: true);

    expect(const DartPluginRegistrantTarget().canSkip(environment2), false);
  });

  testUsingContext("doesn't generate generated_main.dart if there aren't Dart plugins", () async {
    final FileSystem fileSystem = _getFileSystem();

    final Environment environment = Environment.test(
        fileSystem.currentDirectory,
        projectDir: fileSystem.directory('project')..createSync(),
        artifacts: null,
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        generateDartPluginRegistry: true);

    final File config = environment.projectDir
        .childDirectory('.dart_tool')
        .childFile('package_config.json');
    config.createSync(recursive: true);
    config.writeAsStringSync(Platform.isWindows ? _kSamplePackageJsonWindows : _kSamplePackageJson);

    final File pubspec = environment.projectDir.childFile('pubspec.yaml');
    pubspec.createSync();
    final File packages = environment.projectDir.childFile('.packages');
    packages.createSync();

    final File generatedMain = environment.projectDir
        .childDirectory('.dart_tool')
        .childDirectory('flutter_build')
        .childFile('generated_main.dart');

    final FlutterProject testProject = FlutterProject.fromDirectoryTest(environment.projectDir);
    await DartPluginRegistrantTarget.test(testProject).build(environment);

    expect(generatedMain.existsSync(), isFalse);
  });

  testUsingContext('regenerates generated_main.dart', () async {
    final FileSystem fileSystem = _getFileSystem();
    final Environment environment = Environment.test(
        fileSystem.currentDirectory,
        projectDir: fileSystem.directory('project')..createSync(),
        artifacts: null,
        fileSystem: fileSystem,
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
        generateDartPluginRegistry: true);
    final File config = environment.projectDir
        .childDirectory('.dart_tool')
        .childFile('package_config.json');
    config.createSync(recursive: true);
    config.writeAsStringSync(Platform.isWindows ? _kSamplePackageJsonWindows : _kSamplePackageJson);

    final File pubspec = environment.projectDir.childFile('pubspec.yaml');
    pubspec.createSync();
    pubspec.writeAsStringSync(_kSamplePubspecFile);
    final File packages = environment.projectDir.childFile('.packages');
    packages.createSync();
    packages.writeAsStringSync(Platform.isWindows ? _kSamplePackagesFileWindows : _kSamplePackagesFile);

    final File generatedMain = environment.projectDir
        .childDirectory('.dart_tool')
        .childDirectory('flutter_build')
        .childFile('generated_main.dart');
    generatedMain.createSync(recursive: true);

    final File pluginPubspec = environment.fileSystem.currentDirectory.childDirectory('path_provider_linux').childFile('pubspec.yaml');
    pluginPubspec.createSync(recursive: true);
    pluginPubspec.writeAsStringSync(_kSamplePluginPubspec);
    final FlutterProject testProject = FlutterProject.fromDirectoryTest(environment.projectDir);
    await DartPluginRegistrantTarget.test(testProject).build(environment);

    final String mainContent = generatedMain.readAsStringSync();
    expect(mainContent, contains(_kLinuxRegistrant));
  });
}

FileSystem _getFileSystem() {
  if (Platform.isWindows) {
    return MemoryFileSystem.test(style: FileSystemStyle.windows);
  }
  return MemoryFileSystem.test();
}
