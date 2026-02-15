// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = fileSystem.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  test('Dart identifiers are obfuscated with build apk --obfuscate', () async {
    const projectName = 'hello_world';
    await processManager.run(<String>[
      flutterBin,
      'create',
      projectName,
    ], workingDirectory: tempDir.path);
    final String projectPath = tempDir.childDirectory(projectName).path;

    await processManager.run(<String>[
      flutterBin,
      'build',
      'apk',
      '--target-platform=android-arm',
      '--obfuscate',
      '--split-debug-info=foo/',
      '--ci',
    ], workingDirectory: projectPath);

    final File outputApkDirectory = fileSystem.file(
      fileSystem.path.join(
        projectPath,
        'build',
        'app',
        'outputs',
        'apk',
        'release',
        'app-release.apk',
      ),
    );

    expect(outputApkDirectory, exists);
    // Expect "hello_world" is not present in the compiled output.
    // This fails without the --obfuscate flag.
    expect(_containsSymbol(outputApkDirectory, 'lib/armeabi-v7a/libapp.so', projectName), false);
  });

  test('Dart identifiers are obfuscated with build aar --obfuscate', () async {
    const moduleName = 'hello_module';
    await processManager.run(<String>[
      flutterBin,
      'create',
      '-t',
      'module',
      moduleName,
      '--ci',
    ], workingDirectory: tempDir.path);
    final String projectPath = tempDir.childDirectory(moduleName).path;

    await processManager.run(<String>[
      flutterBin,
      'build',
      'aar',
      '--target-platform=android-arm',
      '--obfuscate',
      '--split-debug-info=foo/',
      '--no-debug',
      '--no-profile',
    ], workingDirectory: projectPath);

    final File outputAarDirectory = fileSystem.file(
      fileSystem.path.join(
        projectPath,
        'build',
        'host',
        'outputs',
        'repo',
        'com',
        'example',
        moduleName,
        'flutter_release',
        '1.0',
        'flutter_release-1.0.aar',
      ),
    );

    expect(outputAarDirectory, exists);
    // Expect "hello_module" is not present in the compiled output.
    // This fails without the --obfuscate flag.
    expect(_containsSymbol(outputAarDirectory, 'jni/armeabi-v7a/libapp.so', moduleName), false);
  });
}

bool _containsSymbol(File outputArchive, String libappPath, String symbol) {
  final Archive archive = ZipDecoder().decodeBytes(outputArchive.readAsBytesSync());
  final ArchiveFile? libapp = archive.findFile(libappPath);
  expect(libapp, isNotNull);

  final libappBytes = libapp!.content as Uint8List;
  final String libappStrings = utf8.decode(libappBytes, allowMalformed: true);

  return libappStrings.contains(symbol);
}
