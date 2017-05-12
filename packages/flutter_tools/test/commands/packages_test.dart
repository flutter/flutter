// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/packages.dart';
import 'package:test/test.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('packages', () {
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

    Future<String> runCommand(String verb, { List<String> args }) async {
      final String projectPath = await createProject(temp);

      final PackagesCommand command = new PackagesCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);

      final List<String> commandArgs = <String>['packages', verb];
      if (args != null)
        commandArgs.addAll(args);
      commandArgs.add(projectPath);

      await runner.run(commandArgs);

      return projectPath;
    }

    void expectExists(String projectPath, String relPath) {
      expect(fs.isFileSync(fs.path.join(projectPath, relPath)), true);
    }

    // Verify that we create a project that is well-formed.
    testUsingContext('get', () async {
      final String projectPath = await runCommand('get');
      expectExists(projectPath, 'lib/main.dart');
      expectExists(projectPath, '.packages');
    });

    testUsingContext('get --offline', () async {
      final String projectPath = await runCommand('get', args: <String>['--offline']);
      expectExists(projectPath, 'lib/main.dart');
      expectExists(projectPath, '.packages');
    });

    testUsingContext('upgrade', () async {
      final String projectPath = await runCommand('upgrade');
      expectExists(projectPath, 'lib/main.dart');
      expectExists(projectPath, '.packages');
    });
  });
}
