// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/common.dart';
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

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      temp = fs.systemTempDirectory.createTempSync('flutter_tools');
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    // Verify that we create a project that is well-formed.
    testUsingContext('project', () async {
      return _createAndAnalyzeProject(
        temp,
        <String>[],
        fs.path.join(temp.path, 'lib', 'main.dart'),
      );
    });

    testUsingContext('project with-driver-test', () async {
      return _createAndAnalyzeProject(
        temp,
        <String>['--with-driver-test'],
        fs.path.join(temp.path, 'lib', 'main.dart'),
      );
    });

    testUsingContext('plugin project', () async {
      return _createAndAnalyzeProject(
        temp,
        <String>['--plugin'],
        fs.path.join(temp.path, 'example', 'lib', 'main.dart'),
      );
    });

    // Verify content and formatting
    testUsingContext('content', () async {
      Cache.flutterRoot = '../..';

      final CreateCommand command = new CreateCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);

      await runner.run(<String>['create', '--no-pub', temp.path]);

      void expectExists(String relPath) {
        expect(fs.isFileSync('${temp.path}/$relPath'), true);
      }

      expectExists('lib/main.dart');
      for (FileSystemEntity file in temp.listSync(recursive: true)) {
        if (file is File && file.path.endsWith('.dart')) {
          final String original = file.readAsStringSync();

          final Process process = await Process.start(
            sdkBinaryName('dartfmt'),
            <String>[file.path],
            workingDirectory: temp.path,
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
          fs.file(fs.path.join(temp.path, xcodeConfigPath));
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

      await runner.run(<String>['create', '--no-pub', temp.path]);

      await runner.run(<String>['create', '--no-pub', temp.path]);
    });

    // Verify that we help the user correct an option ordering issue
    testUsingContext('produces sensible error message', () async {
      Cache.flutterRoot = '../..';

      final CreateCommand command = new CreateCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);

      try {
        await runner.run(<String>['create', temp.path, '--pub']);
        fail('expected ToolExit exception');
      } on ToolExit catch (e) {
        expect(e.exitCode, 2);
        expect(e.message, contains('Try moving --pub'));
      }
    });

    // Verify that we fail with an error code when the file exists.
    testUsingContext('fails when file exists', () async {
      Cache.flutterRoot = '../..';
      final CreateCommand command = new CreateCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);
      final File existingFile = fs.file("${temp.path.toString()}/bad");
      if (!existingFile.existsSync())
        existingFile.createSync();
      try {
        await runner.run(<String>['create', existingFile.path]);
        fail('expected ToolExit exception');
      } on ToolExit catch (e) {
        expect(e.message, contains('file exists'));
      }
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
