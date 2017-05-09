// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/dart/sdk.dart';
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('create', () {
    Directory temp;
    Directory projectDir;

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      temp = fs.systemTempDirectory.createTempSync('flutter_tools');
      projectDir = temp.childDirectory('flutter_project');
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    // Verify that we create a project that is well-formed.
    testUsingContext('project', () async {
      return _createAndAnalyzeProject(
        projectDir,
        <String>[],
        fs.path.join(projectDir.path, 'lib', 'main.dart'),
      );
    });

    testUsingContext('project with-driver-test', () async {
      return _createAndAnalyzeProject(
        projectDir,
        <String>['--with-driver-test'],
        fs.path.join(projectDir.path, 'lib', 'main.dart'),
      );
    });

    testUsingContext('plugin project', () async {
      return _createAndAnalyzeProject(
        projectDir,
        <String>['--plugin'],
        fs.path.join(projectDir.path, 'example', 'lib', 'main.dart'),
      );
    });

    // Verify content and formatting
    testUsingContext('content', () async {
      Cache.flutterRoot = '../..';

      final CreateCommand command = new CreateCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);

      await runner.run(<String>['create', '--no-pub', projectDir.path]);

      void expectExists(String relPath) {
        expect(fs.isFileSync('${projectDir.path}/$relPath'), true);
      }

      expectExists('lib/main.dart');
      for (FileSystemEntity file in projectDir.listSync(recursive: true)) {
        if (file is File && file.path.endsWith('.dart')) {
          final String original = file.readAsStringSync();

          final Process process = await Process.start(
            sdkBinaryName('dartfmt'),
            <String>[file.path],
            workingDirectory: projectDir.path,
          );
          final String formatted =
              await process.stdout.transform(UTF8.decoder).join();

          expect(original, formatted, reason: file.path);
        }
      }

      // Generated Xcode settings
      final String xcodeConfigPath =
          fs.path.join('ios', 'Flutter', 'Generated.xcconfig');
      expectExists(xcodeConfigPath);
      final File xcodeConfigFile =
          fs.file(fs.path.join(projectDir.path, xcodeConfigPath));
      final String xcodeConfig = xcodeConfigFile.readAsStringSync();
      expect(xcodeConfig, contains('FLUTTER_ROOT='));
      expect(xcodeConfig, contains('FLUTTER_APPLICATION_PATH='));
      expect(xcodeConfig, contains('FLUTTER_FRAMEWORK_DIR='));
    });

    // Verify that we can regenerate over an existing project.
    testUsingContext('can re-gen over existing project', () async {
      Cache.flutterRoot = '../..';

      final CreateCommand command = new CreateCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);

      await runner.run(<String>['create', '--no-pub', projectDir.path]);

      await runner.run(<String>['create', '--no-pub', projectDir.path]);
    });

    // Verify that we help the user correct an option ordering issue
    testUsingContext('produces sensible error message', () async {
      Cache.flutterRoot = '../..';

      final CreateCommand command = new CreateCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);

      expect(
          runner.run(<String>['create', projectDir.path, '--pub']),
          throwsToolExit(exitCode: 2, message: 'Try moving --pub')
      );
    });

    // Verify that we fail with an error code when the file exists.
    testUsingContext('fails when file exists', () async {
      Cache.flutterRoot = '../..';
      final CreateCommand command = new CreateCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);
      final File existingFile = fs.file("${projectDir.path.toString()}/bad");
      if (!existingFile.existsSync())
        existingFile.createSync(recursive: true);
      expect(
          runner.run(<String>['create', existingFile.path]),
          throwsToolExit(message: 'file exists')
      );
    });

    testUsingContext('fails when invalid package name', () async {
      Cache.flutterRoot = '../..';
      final CreateCommand command = new CreateCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);
      expect(
          runner.run(<String>['create', fs.path.join(projectDir.path, 'invalidName')]),
          throwsToolExit(message: '"invalidName" is not a valid Dart package name.')
      );
    });
  });
}

Future<Null> _createAndAnalyzeProject(
  Directory dir,
  List<String> createArgs,
  String mainPath,
) async {
  Cache.flutterRoot = '../..';
  final CreateCommand command = new CreateCommand();
  final CommandRunner<Null> runner = createTestCommandRunner(command);
  final List<String> args = <String>['create'];
  args.addAll(createArgs);
  args.add(dir.path);
  await runner.run(args);

  expect(fs.file(mainPath).existsSync(), true);
  final String flutterToolsPath = fs.path.absolute(fs.path.join(
    'bin',
    'flutter_tools.dart',
  ));
  final ProcessResult exec = Process.runSync(
    '$dartSdkPath/bin/dart',
    <String>[flutterToolsPath, 'analyze'],
    workingDirectory: dir.path,
  );
  if (exec.exitCode != 0) {
    print(exec.stdout);
    print(exec.stderr);
  }
  expect(exec.exitCode, 0);
}
