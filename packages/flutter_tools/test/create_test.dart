// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'src/context.dart';

void main() {
  group('create', () {
    Directory temp;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('flutter_tools');
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    // Verify that we create a project that is well-formed.
    testUsingContext('flutter-simple', () async {
      ArtifactStore.flutterRoot = '../..';
      CreateCommand command = new CreateCommand();
      CommandRunner runner = new CommandRunner('test_flutter', '')
        ..addCommand(command);
      await runner.run(['create', temp.path])
        .then((int code) => expect(code, equals(0)));

      String mainPath = path.join(temp.path, 'lib', 'main.dart');
      expect(new File(mainPath).existsSync(), true);
      ProcessResult exec = Process.runSync(
        sdkBinaryName('dartanalyzer'), ['--fatal-warnings', mainPath],
        workingDirectory: temp.path
      );
      if (exec.exitCode != 0) {
        print(exec.stdout);
        print(exec.stderr);
      }
      expect(exec.exitCode, 0);
    },
    // This test can take a while due to network requests.
    timeout: new Timeout(new Duration(minutes: 2)));

    // Verify that we can regenerate over an existing project.
    testUsingContext('can re-gen over existing project', () async {
      ArtifactStore.flutterRoot = '../..';
      CreateCommand command = new CreateCommand();
      CommandRunner runner = new CommandRunner('test_flutter', '')
        ..addCommand(command);

      await runner.run(['create', '--no-pub', temp.path])
        .then((int code) => expect(code, equals(0)));
      await runner.run(['create', '--no-pub', temp.path])
        .then((int code) => expect(code, equals(0)));
    });

    // Verify that we fail with an error code when the file exists.
    testUsingContext('fails when file exists', () async {
      ArtifactStore.flutterRoot = '../..';
      CreateCommand command = new CreateCommand();
      CommandRunner runner = new CommandRunner('test_flutter', '')
        ..addCommand(command);
      File existingFile = new File("${temp.path.toString()}/bad");
      if (!existingFile.existsSync()) existingFile.createSync();
      await runner.run(['create', existingFile.path])
        .then((int code) => expect(code, equals(1)));
    });
  });
}
