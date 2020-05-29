// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/shell_completion.dart';
import 'package:process/process.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

void main() {
  group('shell_completion', () {
    MockStdio mockStdio;

    setUp(() {
      Cache.disableLocking();
      mockStdio = MockStdio()..stdout.terminalColumns = 80;
    });

    testUsingContext('generates bash initialization script to stdout', () async {
      final ShellCompletionCommand command = ShellCompletionCommand();
      await createTestCommandRunner(command).run(<String>['bash-completion']);
      expect(mockStdio.writtenToStdout.length, equals(1));
      expect(mockStdio.writtenToStdout.first, contains('__flutter_completion'));
    }, overrides: <Type, Generator>{
      Stdio: () => mockStdio,
    });

    testUsingContext('generates bash initialization script to stdout with arg', () async {
      final ShellCompletionCommand command = ShellCompletionCommand();
      await createTestCommandRunner(command).run(<String>['bash-completion', '-']);
      expect(mockStdio.writtenToStdout.length, equals(1));
      expect(mockStdio.writtenToStdout.first, contains('__flutter_completion'));
    }, overrides: <Type, Generator>{
      Stdio: () => mockStdio,
    });

    testUsingContext('generates bash initialization script to output file', () async {
      final ShellCompletionCommand command = ShellCompletionCommand();
      const String outputFile = 'bash-setup.sh';
      await createTestCommandRunner(command).run(
        <String>['bash-completion', outputFile],
      );
      expect(globals.fs.isFileSync(outputFile), isTrue);
      expect(globals.fs.file(outputFile).readAsStringSync(), contains('__flutter_completion'));
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
      Stdio: () => mockStdio,
    });

    testUsingContext("won't overwrite existing output file ", () async {
      final ShellCompletionCommand command = ShellCompletionCommand();
      const String outputFile = 'bash-setup.sh';
      globals.fs.file(outputFile).createSync();
      try {
        await createTestCommandRunner(command).run(
          <String>['bash-completion', outputFile],
        );
        fail('Expect ToolExit exception');
      } on ToolExit catch (error) {
        expect(error.exitCode ?? 1, 1);
        expect(error.message, contains('Use --overwrite'));
      }
      expect(globals.fs.isFileSync(outputFile), isTrue);
      expect(globals.fs.file(outputFile).readAsStringSync(), isEmpty);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
      Stdio: () => mockStdio,
    });

    testUsingContext('will overwrite existing output file if given --overwrite', () async {
      final ShellCompletionCommand command = ShellCompletionCommand();
      const String outputFile = 'bash-setup.sh';
      globals.fs.file(outputFile).createSync();
      await createTestCommandRunner(command).run(
        <String>['bash-completion', '--overwrite', outputFile],
      );
      expect(globals.fs.isFileSync(outputFile), isTrue);
      expect(globals.fs.file(outputFile).readAsStringSync(), contains('__flutter_completion'));
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
      Stdio: () => mockStdio,
    });
  });
}
