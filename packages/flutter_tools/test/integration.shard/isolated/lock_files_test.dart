// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/file.dart';

import '../../src/common.dart';
import '../test_utils.dart';
import 'native_assets_test_utils.dart';

const packageName = 'simple_app';

void main() {
  test('ensure that there can be two flutter modules in a single gradle project', () async {
    await inTempDir((Directory tempDirectory) async {
      final ProcessResult createResult = processManager.runSync(<String>[
        flutterBin,
        'create',
        '--platforms',
        'android',
        packageName,
      ], workingDirectory: tempDirectory.path);
      if (createResult.exitCode != 0) {
        throw Exception(
          'flutter create failed: ${createResult.exitCode}\n${createResult.stderr}\n${createResult.stdout}',
        );
      }
      final Directory projectDirectory = tempDirectory.childDirectory(packageName);
      final Directory androidDirectory = projectDirectory.childDirectory('android');
      final Directory exampleDirectory = androidDirectory.childDirectory('example');

      await moveFile(androidDirectory.childFile('build.gradle.kts'), projectDirectory);
      await moveFile(androidDirectory.childFile('settings.gradle.kts'), projectDirectory);
      await moveFile(androidDirectory.childFile('local.properties'), projectDirectory);
      await moveFile(androidDirectory.childFile('gradle.properties'), projectDirectory);
      await copyDirectory(androidDirectory.childDirectory('app'), exampleDirectory);

      // Add new example module
      final IOSink ioSink =
          projectDirectory.childFile('settings.gradle.kts').openWrite(mode: FileMode.append)
            ..write('project(":app").projectDir = File(rootDir, "android/app/")\n')
            ..write('include(":example")\n')
            ..write('project(":example").projectDir = File(rootDir, "android/example/")\n');
      await ioSink.close();

      // Change the build directory
      final String buildGradle = projectDirectory.childFile('build.gradle.kts').readAsStringSync();
      final String newBuildGradle = buildGradle.replaceAll('.dir("../../build")', '');
      projectDirectory.childFile('build.gradle.kts').writeAsStringSync(newBuildGradle);

      final ProcessResult buildResult = processManager.runSync(<String>[
        flutterBin,
        'build',
        'apk',
      ], workingDirectory: projectDirectory.path);
      if (buildResult.exitCode != 0) {
        throw Exception(
          'flutter build failed: ${buildResult.exitCode}\n${buildResult.stderr}\n${buildResult.stdout}',
        );
      }
    });
  });
}

Future<void> copyDirectory(Directory source, Directory destination) async {
  if (!await source.exists()) {
    throw Exception('Source directory does not exists');
  }
  if (await destination.exists()) {
    throw Exception('Target directory already exists');
  }
  await destination.create(recursive: true);

  await for (final FileSystemEntity entity in source.list(recursive: true)) {
    final String relativePath = fileSystem.path.relative(entity.path, from: source.path);
    final String destinationPath = fileSystem.path.join(destination.path, relativePath);

    if (entity is Directory) {
      final Directory newDirectory = destination.childDirectory(destinationPath);
      if (!await newDirectory.exists()) {
        await newDirectory.create(recursive: true);
      }
    } else if (entity is File) {
      await entity.copy(destinationPath);
    }
  }
}

Future<void> moveFile(File sourceFile, Directory destination) async {
  if (!sourceFile.existsSync()) {
    throw Exception('Source file (${sourceFile.path}) does not exists');
  }
  final File destinationFile = destination.childFile(sourceFile.basename);
  if (destinationFile.existsSync()) {
    throw Exception('Target file (${destinationFile.path}) already exists');
  }
  try {
    await sourceFile.rename(destinationFile.path);
  } on FileSystemException {
    await sourceFile.copy(destinationFile.path);
    await sourceFile.delete();
  }
}
