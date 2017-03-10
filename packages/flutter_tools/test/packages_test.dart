// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/commands/packages.dart';
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('packages', () {
    Directory temp;

    setUp(() {
      temp = fs.systemTempDirectory.createTempSync('flutter_tools');
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    Future<Null> createProject() async {
      final CreateCommand command = new CreateCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);

      await runner.run(<String>['create', '--no-pub', temp.path]);
    }

    Future<Null> runCommand(String verb, { List<String> args }) async {
      await createProject();

      final PackagesCommand command = new PackagesCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);

      final List<String> commandArgs = <String>['packages', verb];
      if (args != null)
        commandArgs.addAll(args);
      commandArgs.add(temp.path);

      await runner.run(commandArgs);
    }

    void expectExists(String relPath) {
      expect(fs.isFileSync('${temp.path}/$relPath'), true);
    }

    // Verify that we create a project that is well-formed.
    testUsingContext('get', () async {
      await runCommand('get');
      expectExists('lib/main.dart');
      expectExists('.packages');
    });

    testUsingContext('get --offline', () async {
      await runCommand('get', args: <String>['--offline']);
      expectExists('lib/main.dart');
      expectExists('.packages');
    });

    testUsingContext('upgrade', () async {
      await runCommand('upgrade');
      expectExists('lib/main.dart');
      expectExists('.packages');
    });
  });
}
