// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/shell_completion.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:path/path.dart' as path_package; // flutter_ignore: package_path_import
import 'package:test/fake.dart';

import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  group('shell_completion', () {
    late FakeStdio fakeStdio;
    late FileSystem fileSystem;

    setUp(() {
      Cache.disableLocking();
      fakeStdio = FakeStdio()..stdout.terminalColumns = 80;
      fileSystem = MemoryFileSystem.test();
    });

    ShellCompletionCommand createShellCompletionCommand() {
      return ShellCompletionCommand(
        toolContext: FakeToolContext(
          fs: fileSystem,
          logger: BufferLogger.test(),
          platform: FakePlatform(),
          stdio: fakeStdio,
        ),
      );
    }

    testUsingContext(
      'generates bash initialization script to stdout',
      () async {
        final ShellCompletionCommand command = createShellCompletionCommand();
        await createTestCommandRunner(command).run(<String>['bash-completion']);
        expect(fakeStdio.writtenToStdout.length, equals(1));
        expect(fakeStdio.writtenToStdout.first, contains('__flutter_completion'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
        Stdio: () => fakeStdio,
      },
    );

    testUsingContext(
      'generates bash initialization script to stdout with arg',
      () async {
        final ShellCompletionCommand command = createShellCompletionCommand();
        await createTestCommandRunner(command).run(<String>['bash-completion', '-']);
        expect(fakeStdio.writtenToStdout.length, equals(1));
        expect(fakeStdio.writtenToStdout.first, contains('__flutter_completion'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
        Stdio: () => fakeStdio,
      },
    );

    testUsingContext(
      'generates bash initialization script to output file',
      () async {
        final ShellCompletionCommand command = createShellCompletionCommand();
        const outputFile = 'bash-setup.sh';
        await createTestCommandRunner(command).run(<String>['bash-completion', outputFile]);
        expect(fileSystem.isFileSync(outputFile), isTrue);
        expect(fileSystem.file(outputFile).readAsStringSync(), contains('__flutter_completion'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
        Stdio: () => fakeStdio,
      },
    );

    testUsingContext(
      "won't overwrite existing output file ",
      () async {
        final ShellCompletionCommand command = createShellCompletionCommand();
        const outputFile = 'bash-setup.sh';
        fileSystem.file(outputFile).createSync();
        await expectLater(
          () => createTestCommandRunner(command).run(<String>['bash-completion', outputFile]),
          throwsA(
            isA<ToolExit>()
                .having((ToolExit error) => error.exitCode, 'exitCode', anyOf(isNull, 1))
                .having((ToolExit error) => error.message, 'message', contains('Use --overwrite')),
          ),
        );
        expect(fileSystem.isFileSync(outputFile), isTrue);
        expect(fileSystem.file(outputFile).readAsStringSync(), isEmpty);
      },
      overrides: <Type, Generator>{
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
        Stdio: () => fakeStdio,
      },
    );

    testUsingContext(
      'will overwrite existing output file if given --overwrite',
      () async {
        final ShellCompletionCommand command = createShellCompletionCommand();
        const outputFile = 'bash-setup.sh';
        fileSystem.file(outputFile).createSync();
        await createTestCommandRunner(
          command,
        ).run(<String>['bash-completion', '--overwrite', outputFile]);
        expect(fileSystem.isFileSync(outputFile), isTrue);
        expect(fileSystem.file(outputFile).readAsStringSync(), contains('__flutter_completion'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => MemoryFileSystem.test(),
        ProcessManager: () => FakeProcessManager.any(),
        Stdio: () => fakeStdio,
      },
    );

    testUsingContext(
      'resolves stdio and fileSystem from the injected ToolContext rather than the Zone',
      () async {
        final ShellCompletionCommand command = createShellCompletionCommand();
        const outputFile = 'bash-setup.sh';
        await createTestCommandRunner(command).run(<String>['bash-completion', outputFile]);
        expect(fileSystem.isFileSync(outputFile), isTrue);
        expect(fileSystem.file(outputFile).readAsStringSync(), contains('__flutter_completion'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => _ThrowingFileSystem(fileSystem),
        Stdio: () => _ThrowingStdio(fakeStdio),
        ProcessManager: () => FakeProcessManager.any(),
      },
    );
  });
}

class FakeToolContext extends Fake implements ToolContext {
  FakeToolContext({
    required this.fs,
    required this.logger,
    required this.platform,
    required this.stdio,
  });

  @override
  final FileSystem fs;

  @override
  final Logger logger;

  @override
  final Platform platform;

  @override
  final Stdio stdio;
}

class _ThrowingFileSystem extends Fake implements FileSystem {
  _ThrowingFileSystem(this._delegate);

  final FileSystem _delegate;

  @override
  path_package.Context get path => _delegate.path;

  @override
  Directory get currentDirectory => _delegate.currentDirectory;

  @override
  set currentDirectory(dynamic value) => _delegate.currentDirectory = value;

  @override
  Directory get systemTempDirectory => _delegate.systemTempDirectory;

  @override
  Directory directory(dynamic path) => _delegate.directory(path);

  @override
  File file(dynamic path) {
    if (path is String && path.contains('bash-setup.sh')) {
      throw UnimplementedError('Should not use Zone FileSystem to access output file!');
    }
    return _delegate.file(path);
  }

  @override
  bool isFileSync(String path) {
    if (path.contains('bash-setup.sh')) {
      throw UnimplementedError('Should not use Zone FileSystem to access output file!');
    }
    return _delegate.isFileSync(path);
  }

  @override
  FileSystemEntityType typeSync(String path, {bool followLinks = true}) {
    if (path.contains('bash-setup.sh')) {
      throw UnimplementedError('Should not use Zone FileSystem to access output file!');
    }
    return _delegate.typeSync(path, followLinks: followLinks);
  }
}

class _ThrowingStdio extends Fake implements Stdio {
  _ThrowingStdio(this._delegate);

  final Stdio _delegate;

  @override
  bool get hasTerminal => _delegate.hasTerminal;

  @override
  int? get terminalColumns => _delegate.terminalColumns;

  @override
  void stdoutWrite(String message, {void Function(String, dynamic, StackTrace)? fallback}) =>
      throw UnimplementedError('Should not use Zone Stdio');
}
