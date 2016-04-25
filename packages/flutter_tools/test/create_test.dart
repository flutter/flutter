// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'src/common.dart';
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
    testUsingContext('project', () async {
      return _createAndAnalyzeProject(temp, <String>[]);
    });

    testUsingContext('project with-driver-test', () async {
      return _createAndAnalyzeProject(temp, <String>['--with-driver-test']);
    });

    // Verify that we can regenerate over an existing project.
    testUsingContext('can re-gen over existing project', () async {
      ArtifactStore.flutterRoot = '../..';

      CreateCommand command = new CreateCommand();
      CommandRunner runner = createTestCommandRunner(command);

      int code = await runner.run(<String>['create', '--no-pub', temp.path]);
      expect(code, equals(0));

      code = await runner.run(<String>['create', '--no-pub', temp.path]);
      expect(code, equals(0));
    });

    // Verify that we fail with an error code when the file exists.
    testUsingContext('fails when file exists', () async {
      ArtifactStore.flutterRoot = '../..';
      CreateCommand command = new CreateCommand();
      CommandRunner runner = createTestCommandRunner(command);
      File existingFile = new File("${temp.path.toString()}/bad");
      if (!existingFile.existsSync()) existingFile.createSync();
      int code = await runner.run(<String>['create', existingFile.path]);
      expect(code, equals(1));
    });
  });
}

Future<Null> _createAndAnalyzeProject(Directory dir, List<String> createArgs) async {
  ArtifactStore.flutterRoot = '../..';
  CreateCommand command = new CreateCommand();
  CommandRunner runner = createTestCommandRunner(command);
  List<String> args = <String>['create'];
  args.addAll(createArgs);
  args.add(dir.path);
  int code = await runner.run(args);
  expect(code, equals(0));

  String mainPath = path.join(dir.path, 'lib', 'main.dart');
  expect(new File(mainPath).existsSync(), true);
  String flutterToolsPath = path.absolute(path.join('bin', 'flutter_tools.dart'));
  ProcessResult exec = Process.runSync(
    'dart', <String>[flutterToolsPath, 'analyze'],
    workingDirectory: dir.path
  );
  if (exec.exitCode != 0) {
    print(exec.stdout);
    print(exec.stderr);
  }
  expect(exec.exitCode, 0);
}
