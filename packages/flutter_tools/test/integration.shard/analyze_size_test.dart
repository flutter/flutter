// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

// This test file does not use [getLocalEngineArguments] because it requires
// multiple specific artifact output types.

const String apkDebugMessage = 'A summary of your APK analysis can be found at: ';
const String iosDebugMessage = 'A summary of your iOS bundle analysis can be found at: ';
const String macOSDebugMessage = 'A summary of your macOS bundle analysis can be found at: ';
const String runDevToolsMessage = 'flutter pub global activate devtools; flutter pub global run devtools ';

void main() {
  testWithoutContext('--analyze-size flag produces expected output on hello_world for Android', () async {
    final String workingDirectory = fileSystem.path.join(getFlutterRoot(), 'examples', 'hello_world');
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'build',
      'apk',
      '--analyze-size',
      '--target-platform=android-arm64',
    ], workingDirectory: workingDirectory);

    printOnFailure('Output of flutter build apk:');
    printOnFailure(result.stdout.toString());
    printOnFailure(result.stderr.toString());
    expect(result.stdout.toString(), contains('app-release.apk (total compressed)'));

    final String line = result.stdout.toString()
      .split('\n')
      .firstWhere((String line) => line.contains(apkDebugMessage));

    final String outputFilePath = line.split(apkDebugMessage).last.trim();
    expect(fileSystem.file(fileSystem.path.join(workingDirectory, outputFilePath)), exists);
    expect(outputFilePath, contains('.flutter-devtools'));

    final String devToolsCommand = result.stdout.toString()
        .split('\n')
        .firstWhere((String line) => line.contains(runDevToolsMessage));
    final String commandArguments = devToolsCommand.split(runDevToolsMessage).last.trim();
    final String relativeAppSizePath = outputFilePath.split('.flutter-devtools/').last.trim();
    expect(commandArguments.contains('--appSizeBase=$relativeAppSizePath'), isTrue);

    expect(result.exitCode, 0);
  });

  testWithoutContext('--analyze-size flag produces expected output on hello_world for iOS', () async {
    final String workingDirectory = fileSystem.path.join(getFlutterRoot(), 'examples', 'hello_world');
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final Directory tempDir = fileSystem.systemTempDirectory.createTempSync('flutter_size_test.');
    final Directory codeSizeDir = tempDir.childDirectory('code size dir')..createSync();
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'build',
      'ios',
      '--analyze-size',
      '--code-size-directory=${codeSizeDir.path}',
      '--no-codesign',
    ], workingDirectory: workingDirectory);

    printOnFailure('Output of flutter build ios:');
    printOnFailure(result.stdout.toString());
    printOnFailure(result.stderr.toString());
    expect(result.stdout.toString(), contains('Dart AOT symbols accounted decompressed size'));

    final String line = result.stdout.toString()
      .split('\n')
      .firstWhere((String line) => line.contains(iosDebugMessage));

    final String outputFilePath = line.split(iosDebugMessage).last.trim();
    expect(fileSystem.file(fileSystem.path.join(workingDirectory, outputFilePath)), exists);

    final String devToolsCommand = result.stdout.toString()
        .split('\n')
        .firstWhere((String line) => line.contains(runDevToolsMessage));
    final String commandArguments = devToolsCommand.split(runDevToolsMessage).last.trim();
    final String relativeAppSizePath = outputFilePath.split('.flutter-devtools/').last.trim();

    expect(commandArguments.contains('--appSizeBase=$relativeAppSizePath'), isTrue);
    expect(codeSizeDir.existsSync(), true);
    expect(result.exitCode, 0);
    tempDir.deleteSync(recursive: true);
  }, skip: !platform.isMacOS); // [intended] iOS can only be built on macos.

  testWithoutContext('--analyze-size flag produces expected output on hello_world for macOS', () async {
    final String workingDirectory = fileSystem.path.join(getFlutterRoot(), 'examples', 'hello_world');
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final Directory tempDir = fileSystem.systemTempDirectory.createTempSync('flutter_size_test.');
    final Directory codeSizeDir = tempDir.childDirectory('code size dir')..createSync();

    final ProcessResult configResult = await processManager.run(<String>[
      flutterBin,
      'config',
      '--enable-macos-desktop',
    ], workingDirectory: workingDirectory);

    printOnFailure('Output of flutter config:');
    printOnFailure(configResult.stdout.toString());
    printOnFailure(configResult.stderr.toString());

    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'build',
      'macos',
      '--analyze-size',
      '--code-size-directory=${codeSizeDir.path}',
    ], workingDirectory: workingDirectory);

    printOnFailure('Output of flutter build macos:');
    printOnFailure(result.stdout.toString());
    printOnFailure(result.stderr.toString());
    expect(result.stdout.toString(), contains('Dart AOT symbols accounted decompressed size'));

    final String line = result.stdout.toString()
      .split('\n')
      .firstWhere((String line) => line.contains(macOSDebugMessage));

    final String outputFilePath = line.split(macOSDebugMessage).last.trim();
    expect(fileSystem.file(fileSystem.path.join(workingDirectory, outputFilePath)), exists);

    final String devToolsCommand = result.stdout.toString()
        .split('\n')
        .firstWhere((String line) => line.contains(runDevToolsMessage));
    final String commandArguments = devToolsCommand.split(runDevToolsMessage).last.trim();
    final String relativeAppSizePath = outputFilePath.split('.flutter-devtools/').last.trim();

    expect(commandArguments.contains('--appSizeBase=$relativeAppSizePath'), isTrue);
    expect(codeSizeDir.existsSync(), true);
    expect(result.exitCode, 0);
    tempDir.deleteSync(recursive: true);
  }, skip: !platform.isMacOS); // [intended] this is a macos only test.

  testWithoutContext('--analyze-size is only supported in release mode', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'build',
      'apk',
      '--analyze-size',
      '--target-platform=android-arm64',
      '--debug',
    ], workingDirectory: fileSystem.path.join(getFlutterRoot(), 'examples', 'hello_world'));

    printOnFailure('Output of flutter build apk:');
    printOnFailure(result.stdout.toString());
    printOnFailure(result.stderr.toString());
    expect(result.stderr.toString(), contains('"--analyze-size" can only be used on release builds'));

    expect(result.exitCode, 1);
  });

  testWithoutContext('--analyze-size is not supported in combination with --split-debug-info', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'build',
      'apk',
      '--analyze-size',
      '--target-platform=android-arm64',
      '--split-debug-info=infos',
    ], workingDirectory: fileSystem.path.join(getFlutterRoot(), 'examples', 'hello_world'));

    expect(result.stderr.toString(), contains('"--analyze-size" cannot be combined with "--split-debug-info"'));

    expect(result.exitCode, 1);
  });

  testWithoutContext('--analyze-size allows overriding the directory for code size files', () async {
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final Directory tempDir = fileSystem.systemTempDirectory.createTempSync('flutter_size_test.');

    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      'build',
      'apk',
      '--analyze-size',
      '--code-size-directory=${tempDir.path}',
      '--target-platform=android-arm64',
      '--release',
    ], workingDirectory: fileSystem.path.join(getFlutterRoot(), 'examples', 'hello_world'));

    expect(result.exitCode, 0);
    expect(tempDir.existsSync(), true);
    expect(tempDir.childFile('snapshot.arm64-v8a.json').existsSync(), true);
    expect(tempDir.childFile('trace.arm64-v8a.json').existsSync(), true);

    tempDir.deleteSync(recursive: true);
  });
}
