// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/shell_completion.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  group('shell_completion', () {
    late FakeStdio fakeStdio;
    late MemoryFileSystem fs;
    late FakeToolContext toolContext;

    setUp(() {
      Cache.disableLocking();
      fakeStdio = FakeStdio()..stdout.terminalColumns = 80;
      fs = MemoryFileSystem.test();
      toolContext = FakeToolContext(
        fs: fs,
        stdio: fakeStdio,
        processManager: FakeProcessManager.any(),
      );
    });

    testWithoutContext('generates bash initialization script to stdout', () async {
      final command = ShellCompletionCommand(toolContext: toolContext);
      await createTestCommandRunner(command).run(<String>['bash-completion']);
      expect(fakeStdio.writtenToStdout.length, equals(1));
      expect(fakeStdio.writtenToStdout.first, contains('__flutter_completion'));
    });

    testWithoutContext('generates bash initialization script to stdout with arg', () async {
      final command = ShellCompletionCommand(toolContext: toolContext);
      await createTestCommandRunner(command).run(<String>['bash-completion', '-']);
      expect(fakeStdio.writtenToStdout.length, equals(1));
      expect(fakeStdio.writtenToStdout.first, contains('__flutter_completion'));
    });

    testWithoutContext('generates bash initialization script to output file', () async {
      final command = ShellCompletionCommand(toolContext: toolContext);
      const outputFile = 'bash-setup.sh';
      await createTestCommandRunner(command).run(<String>['bash-completion', outputFile]);
      expect(fs.isFileSync(outputFile), isTrue);
      expect(fs.file(outputFile).readAsStringSync(), contains('__flutter_completion'));
    });

    testWithoutContext("won't overwrite existing output file", () async {
      final command = ShellCompletionCommand(toolContext: toolContext);
      const outputFile = 'bash-setup.sh';
      fs.file(outputFile).createSync();
      await expectLater(
        () => createTestCommandRunner(command).run(<String>['bash-completion', outputFile]),
        throwsA(
          isA<ToolExit>()
              .having((ToolExit error) => error.exitCode, 'exitCode', anyOf(isNull, 1))
              .having((ToolExit error) => error.message, 'message', contains('Use --overwrite')),
        ),
      );
      expect(fs.isFileSync(outputFile), isTrue);
      expect(fs.file(outputFile).readAsStringSync(), isEmpty);
    });

    testWithoutContext('will overwrite existing output file if given --overwrite', () async {
      final command = ShellCompletionCommand(toolContext: toolContext);
      const outputFile = 'bash-setup.sh';
      fs.file(outputFile).createSync();
      await createTestCommandRunner(
        command,
      ).run(<String>['bash-completion', '--overwrite', outputFile]);
      expect(fs.isFileSync(outputFile), isTrue);
      expect(fs.file(outputFile).readAsStringSync(), contains('__flutter_completion'));
    });
  });
}
