// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:yaml/yaml.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {

  late Directory tempDir;

  setUp(()  {
    Cache.flutterRoot = getFlutterRoot();
    tempDir = createResolvedTempDirectorySync('android_plugin_version_number.');
  });

  tearDown(() async {
    tryToDelete(tempDir);
  });

  test('plugins obtain version number from pubspec.lock.', () async {
    final String flutterBin = fileSystem.path.join(
      getFlutterRoot(),
      'bin',
      'flutter',
    );
    // create flutter module project
    ProcessResult result = processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'create',
      '--template=module',
      'flutter_project'
    ], workingDirectory: tempDir.path);

    if (result.exitCode != 0) {
      log(result.exitCode);
      print("Create project from template failed:\n${result.stderr}");
    }

    final String projectPath = fileSystem.path.join(tempDir.path, 'flutter_project');

    final File modulePubspec = fileSystem.file(fileSystem.path.join(projectPath, 'pubspec.yaml'));
    String pubspecContent = modulePubspec.readAsStringSync();
    pubspecContent = pubspecContent.replaceFirst(
      'dependencies:',
      '''
dependencies:
  image_picker_android: any''',
    );
    modulePubspec.writeAsStringSync(pubspecContent);

    // Run flutter build apk to build module example project
    result = processManager.runSync(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'aar',
      '--no-profile',
      '--no-debug',
      '--target-platform=android-arm64',
    ], workingDirectory: projectPath);

    if (result.exitCode != 0) {
      log(result.exitCode);
      print("Build aar failed:\n${result.stderr}");
    }

    final File pubspecLock = fileSystem.file(fileSystem.path.join(projectPath, 'pubspec.lock'));

    var pubspecLockInfo = loadYaml(pubspecLock.readAsStringSync());
    var imagePickerVersion = pubspecLockInfo['packages']['image_picker_android']['version'];

    // Check outputDir existed
    final Directory outputDir = fileSystem.directory(fileSystem.path.join(
        projectPath, 'build', 'host', 'outputs', 'repo'
        , 'io', 'flutter', 'plugins', 'imagepicker'
        , 'image_picker_android_release', imagePickerVersion
    ));
    expect(outputDir, exists);

  });
}
