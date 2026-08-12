// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/downgrade.dart';
import 'package:flutter_tools/src/persistent_tool_state.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  late FileSystem fileSystem;
  late BufferLogger bufferLogger;
  late FakeTerminal terminal;
  late FakeProcessManager processManager;
  late FakeStdio stdio;

  setUpAll(() {
    Cache.disableLocking();
  });

  tearDownAll(() {
    Cache.enableLocking();
  });

  setUp(() {
    stdio = FakeStdio();
    processManager = FakeProcessManager.empty();
    terminal = FakeTerminal();
    fileSystem = MemoryFileSystem.test();
    bufferLogger = BufferLogger.test(terminal: terminal);
  });

  DowngradeCommand createCommand({
    FakeFlutterVersion? flutterVersion,
    PersistentToolState? persistentToolState,
  }) {
    final toolContext = FakeToolContext(
      fs: fileSystem,
      logger: bufferLogger,
      processManager: processManager,
      stdio: stdio,
      flutterVersion: flutterVersion ?? FakeFlutterVersion(),
    );
    return DowngradeCommand(
      toolContext: toolContext,
      persistentToolState:
          persistentToolState ??
          PersistentToolState.test(directory: fileSystem.currentDirectory, logger: bufferLogger),
      terminal: terminal,
      stdio: stdio,
      flutterVersion: flutterVersion,
    );
  }

  testWithoutContext('Downgrade exits on unknown channel', () async {
    final fakeFlutterVersion = FakeFlutterVersion(branch: 'WestSideStory'); // an unknown branch
    fileSystem.currentDirectory
        .childFile('.flutter_tool_state')
        .writeAsStringSync('{"last-active-master-version":"invalid"}');
    final DowngradeCommand command = createCommand(flutterVersion: fakeFlutterVersion);

    expect(
      createTestCommandRunner(command).run(const ['downgrade']),
      throwsToolExit(message: 'Flutter is not currently on a known channel.'),
    );
  });

  for (final positionalArguments in <List<String>>[
    <String>['3.19.0'],
    <String>['3.19.0', 'extra'],
    <String>['more', 'additional', 'arguments'],
  ]) {
    testWithoutContext(
      'Downgrade exits on unexpected positional arguments: ${positionalArguments.join(' ')}',
      () async {
        final fakeFlutterVersion = FakeFlutterVersion();
        final DowngradeCommand command = createCommand(flutterVersion: fakeFlutterVersion);

        expect(
          createTestCommandRunner(command).run(<String>['downgrade', ...positionalArguments]),
          throwsToolExit(
            message: downgradePositionalArgumentErrorMessage(positionalArguments),
            exitCode: 2,
          ),
        );
      },
    );
  }

  testWithoutContext('Downgrade exits on no recorded version', () async {
    final fakeFlutterVersion = FakeFlutterVersion(branch: 'beta');
    fileSystem.currentDirectory
        .childFile('.flutter_tool_state')
        .writeAsStringSync('{"last-active-master-version":"abcd"}');
    processManager.addCommands(const [
      FakeCommand(command: ['git', 'describe', '--tags', 'abcd'], stdout: 'v1.2.3'),
    ]);
    final DowngradeCommand command = createCommand(flutterVersion: fakeFlutterVersion);

    expect(
      createTestCommandRunner(command).run(const ['downgrade']),
      throwsToolExit(
        message: '''
It looks like you haven't run "flutter upgrade" on channel "beta".

"flutter downgrade" undoes the last "flutter upgrade".

To switch to a specific Flutter version, see: https://flutter.dev/to/switch-flutter-version

Channel "master" was previously on: v1.2.3.''',
      ),
    );
  });

  testWithoutContext('Downgrade exits on unknown recorded version', () async {
    final fakeFlutterVersion = FakeFlutterVersion();
    fileSystem.currentDirectory
        .childFile('.flutter_tool_state')
        .writeAsStringSync('{"last-active-master-version":"invalid"}');
    processManager.addCommands(const [
      FakeCommand(command: ['git', 'describe', '--tags', 'invalid'], exitCode: 1),
    ]);
    final DowngradeCommand command = createCommand(flutterVersion: fakeFlutterVersion);

    expect(
      createTestCommandRunner(command).run(const ['downgrade']),
      throwsToolExit(message: 'Failed to parse version for downgrade'),
    );
  });

  testWithoutContext('Downgrade prompts for user input when terminal is attached - y', () async {
    processManager.addCommands(const [
      FakeCommand(command: ['git', 'describe', '--tags', 'g6b00b5e88']),
      FakeCommand(command: ['git', 'reset', '--hard', 'g6b00b5e88']),
      FakeCommand(command: ['git', 'checkout', 'master', '--']),
    ]);
    final fakeFlutterVersion = FakeFlutterVersion();
    stdio.hasTerminal = true;
    fileSystem.currentDirectory
        .childFile('.flutter_tool_state')
        .writeAsStringSync('{"last-active-master-version":"g6b00b5e88"}');
    final DowngradeCommand command = createCommand(flutterVersion: fakeFlutterVersion);

    terminal.addPrompt(const ['y', 'n'], 'y');

    await createTestCommandRunner(command).run(const ['downgrade']);

    expect(bufferLogger.statusText, contains('Success'));
  });

  testWithoutContext('Downgrade prompts for user input when terminal is attached - n', () async {
    processManager.addCommands(const [
      FakeCommand(command: ['git', 'describe', '--tags', 'g6b00b5e88']),
      FakeCommand(command: ['git', 'reset', '--hard', 'g6b00b5e88']),
      FakeCommand(command: ['git', 'checkout', 'master', '--']),
    ]);
    final fakeFlutterVersion = FakeFlutterVersion();
    stdio.hasTerminal = true;
    fileSystem.currentDirectory
        .childFile('.flutter_tool_state')
        .writeAsStringSync('{"last-active-master-version":"g6b00b5e88"}');
    final DowngradeCommand command = createCommand(flutterVersion: fakeFlutterVersion);

    terminal.addPrompt(const ['y', 'n'], 'n');

    await createTestCommandRunner(command).run(const ['downgrade']);

    expect(bufferLogger.statusText, isNot(contains('Success')));
  });

  testWithoutContext('Downgrade does not prompt when there is no terminal', () async {
    processManager.addCommands(const [
      FakeCommand(command: ['git', 'describe', '--tags', 'g6b00b5e88']),
      FakeCommand(command: ['git', 'reset', '--hard', 'g6b00b5e88']),
      FakeCommand(command: ['git', 'checkout', 'master', '--']),
    ]);
    final fakeFlutterVersion = FakeFlutterVersion();
    stdio.hasTerminal = false;
    fileSystem.currentDirectory
        .childFile('.flutter_tool_state')
        .writeAsStringSync('{"last-active-master-version":"g6b00b5e88"}');
    final DowngradeCommand command = createCommand(flutterVersion: fakeFlutterVersion);

    await createTestCommandRunner(command).run(const ['downgrade']);

    expect(bufferLogger.statusText, contains('Success'));
  });

  testWithoutContext('Downgrade performs correct git commands', () async {
    final fakeFlutterVersion = FakeFlutterVersion();
    stdio.hasTerminal = false;
    fileSystem.currentDirectory
        .childFile('.flutter_tool_state')
        .writeAsStringSync('{"last-active-master-version":"g6b00b5e88"}');
    processManager.addCommands(const [
      FakeCommand(command: ['git', 'describe', '--tags', 'g6b00b5e88'], stdout: 'v1.2.3'),
      FakeCommand(command: ['git', 'reset', '--hard', 'g6b00b5e88']),
      FakeCommand(command: ['git', 'checkout', 'master', '--']),
    ]);
    final DowngradeCommand command = createCommand(flutterVersion: fakeFlutterVersion);

    await createTestCommandRunner(command).run(const ['downgrade']);

    expect(bufferLogger.statusText, contains('Success'));
  });
}

class FakeTerminal extends Fake implements Terminal {
  @override
  bool usesTerminalUi = false;

  void addPrompt(List<String> characters, String selected) {
    _characters = characters;
    _selected = selected;
  }

  List<String>? _characters;
  late String _selected;

  @override
  Future<String> promptForCharInput(
    List<String> acceptedCharacters, {
    Logger? logger,
    String? prompt,
    int? defaultChoiceIndex,
    bool displayAcceptedCharacters = true,
  }) async {
    expect(acceptedCharacters, _characters);
    return _selected;
  }
}

class FakeStdio extends Fake implements Stdio {
  @override
  bool hasTerminal = true;

  @override
  int? terminalColumns = 80;

  @override
  int? terminalLines = 24;
}
