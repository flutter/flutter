// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: omit_obvious_local_variable_types

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/downgrade.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/git.dart';
import 'package:flutter_tools/src/persistent_tool_state.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  late FileSystem fileSystem;
  late BufferLogger bufferLogger;
  late FakeTerminal terminal;
  late FakeProcessManager processManager;
  late FakeStdio stdio;

  // Initialize testOverrides eagerly here in main() because testUsingContext
  // evaluates its 'overrides' parameter during test declaration, before setUp() runs.
  // The closures lazy-evaluate the late variables, which is safe because they
  // are called only when the tests actually execute (after setUp() has run).
  final testOverrides = <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => processManager,
  };

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

  DowngradeCommand setUpCommand({
    PersistentToolState? persistentToolState,
    FlutterVersion? flutterVersion,
    Terminal? terminalOverride,
    Stdio? stdioOverride,
    Logger? logger,
  }) {
    final Logger effectiveLogger = logger ?? bufferLogger;
    final command = DowngradeCommand(
      toolContext: FakeToolContext(
        fs: fileSystem,
        logger: effectiveLogger,
        platform: FakePlatform(),
        persistentToolState:
            persistentToolState ??
            PersistentToolState.test(
              directory: fileSystem.currentDirectory,
              logger: effectiveLogger,
            ),
        terminal: (terminalOverride ?? terminal) as AnsiTerminal,
        stdio: stdioOverride ?? stdio,
        flutterVersion: flutterVersion ?? FakeFlutterVersion(),
        processManager: processManager,
        git: Git(
          currentPlatform: FakePlatform(),
          runProcessWith: ProcessUtils(processManager: processManager, logger: effectiveLogger),
        ),
      ),
    );
    command.applicationPackages = FakeApplicationPackageFactory();
    return command;
  }

  testUsingContext('Downgrade exits on unknown channel', () async {
    final FakeFlutterVersion fakeFlutterVersion = FakeFlutterVersion(
      branch: 'WestSideStory',
    ); // an unknown branch
    fileSystem.currentDirectory
        .childFile('.flutter_tool_state')
        .writeAsStringSync('{"last-active-master-version":"invalid"}');
    final DowngradeCommand command = setUpCommand(flutterVersion: fakeFlutterVersion);

    expect(
      createTestCommandRunner(command).run(const ['downgrade']),
      throwsToolExit(message: 'Flutter is not currently on a known channel.'),
    );
  }, overrides: testOverrides);

  for (final positionalArguments in <List<String>>[
    <String>['3.19.0'],
    <String>['3.19.0', 'extra'],
    <String>['more', 'additional', 'arguments'],
  ]) {
    testUsingContext(
      'Downgrade exits on unexpected positional arguments: ${positionalArguments.join(' ')}',
      () async {
        final FakeFlutterVersion fakeFlutterVersion = FakeFlutterVersion();
        final DowngradeCommand command = setUpCommand(flutterVersion: fakeFlutterVersion);

        expect(
          createTestCommandRunner(command).run(<String>['downgrade', ...positionalArguments]),
          throwsToolExit(
            message: downgradePositionalArgumentErrorMessage(positionalArguments),
            exitCode: 2,
          ),
        );
      },
      overrides: testOverrides,
    );
  }

  testUsingContext('Downgrade exits on no recorded version', () async {
    final FakeFlutterVersion fakeFlutterVersion = FakeFlutterVersion(branch: 'beta');
    fileSystem.currentDirectory
        .childFile('.flutter_tool_state')
        .writeAsStringSync('{"last-active-master-version":"abcd"}');
    processManager.addCommands(const [
      FakeCommand(command: ['git', 'describe', '--tags', 'abcd'], stdout: 'v1.2.3'),
    ]);
    final DowngradeCommand command = setUpCommand(flutterVersion: fakeFlutterVersion);

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
  }, overrides: testOverrides);

  testUsingContext('Downgrade exits on unknown recorded version', () async {
    final FakeFlutterVersion fakeFlutterVersion = FakeFlutterVersion();
    fileSystem.currentDirectory
        .childFile('.flutter_tool_state')
        .writeAsStringSync('{"last-active-master-version":"invalid"}');
    processManager.addCommands(const [
      FakeCommand(command: ['git', 'describe', '--tags', 'invalid'], exitCode: 1),
    ]);
    final DowngradeCommand command = setUpCommand(flutterVersion: fakeFlutterVersion);

    expect(
      createTestCommandRunner(command).run(const ['downgrade']),
      throwsToolExit(message: 'Failed to parse version for downgrade'),
    );
  }, overrides: testOverrides);

  testUsingContext('Downgrade prompts for user input when terminal is attached - y', () async {
    processManager.addCommands(const [
      FakeCommand(command: ['git', 'describe', '--tags', 'g6b00b5e88']),
      FakeCommand(command: ['git', 'reset', '--hard', 'g6b00b5e88']),
      FakeCommand(command: ['git', 'checkout', 'master', '--']),
    ]);
    final FakeFlutterVersion fakeFlutterVersion = FakeFlutterVersion();
    stdio.hasTerminal = true;
    fileSystem.currentDirectory
        .childFile('.flutter_tool_state')
        .writeAsStringSync('{"last-active-master-version":"g6b00b5e88"}');
    final DowngradeCommand command = setUpCommand(flutterVersion: fakeFlutterVersion);

    terminal.addPrompt(const ['y', 'n'], 'y');

    await createTestCommandRunner(command).run(const ['downgrade']);

    expect(bufferLogger.statusText, contains('Success'));
  }, overrides: testOverrides);

  testUsingContext('Downgrade prompts for user input when terminal is attached - n', () async {
    processManager.addCommands(const [
      FakeCommand(command: ['git', 'describe', '--tags', 'g6b00b5e88']),
      FakeCommand(command: ['git', 'reset', '--hard', 'g6b00b5e88']),
      FakeCommand(command: ['git', 'checkout', 'master', '--']),
    ]);
    final FakeFlutterVersion fakeFlutterVersion = FakeFlutterVersion();
    stdio.hasTerminal = true;
    fileSystem.currentDirectory
        .childFile('.flutter_tool_state')
        .writeAsStringSync('{"last-active-master-version":"g6b00b5e88"}');
    final DowngradeCommand command = setUpCommand(flutterVersion: fakeFlutterVersion);

    terminal.addPrompt(const ['y', 'n'], 'n');

    await createTestCommandRunner(command).run(const ['downgrade']);

    expect(bufferLogger.statusText, isNot(contains('Success')));
  }, overrides: testOverrides);

  testUsingContext('Downgrade does not prompt when there is no terminal', () async {
    processManager.addCommands(const [
      FakeCommand(command: ['git', 'describe', '--tags', 'g6b00b5e88']),
      FakeCommand(command: ['git', 'reset', '--hard', 'g6b00b5e88']),
      FakeCommand(command: ['git', 'checkout', 'master', '--']),
    ]);
    final FakeFlutterVersion fakeFlutterVersion = FakeFlutterVersion();
    stdio.hasTerminal = false;
    fileSystem.currentDirectory
        .childFile('.flutter_tool_state')
        .writeAsStringSync('{"last-active-master-version":"g6b00b5e88"}');
    final DowngradeCommand command = setUpCommand(flutterVersion: fakeFlutterVersion);

    await createTestCommandRunner(command).run(const ['downgrade']);

    expect(bufferLogger.statusText, contains('Success'));
  }, overrides: testOverrides);

  testUsingContext('Downgrade performs correct git commands', () async {
    final FakeFlutterVersion fakeFlutterVersion = FakeFlutterVersion();
    stdio.hasTerminal = false;
    fileSystem.currentDirectory
        .childFile('.flutter_tool_state')
        .writeAsStringSync('{"last-active-master-version":"g6b00b5e88"}');
    processManager.addCommands(const [
      FakeCommand(command: ['git', 'describe', '--tags', 'g6b00b5e88'], stdout: 'v1.2.3'),
      FakeCommand(command: ['git', 'reset', '--hard', 'g6b00b5e88']),
      FakeCommand(command: ['git', 'checkout', 'master', '--']),
    ]);
    final DowngradeCommand command = setUpCommand(flutterVersion: fakeFlutterVersion);

    await createTestCommandRunner(command).run(const ['downgrade']);

    expect(bufferLogger.statusText, contains('Success'));
  }, overrides: testOverrides);

  testUsingContext(
    'DowngradeCommand resolves all dependencies from ToolContext and does not fall back to Zone',
    () async {
      // 1. Create a working FakeToolContext with functional fakes.
      final workingFileSystem = MemoryFileSystem.test();
      final workingLogger = BufferLogger.test();
      final workingTerminal = FakeTerminal();
      final workingStdio = FakeStdio();
      final workingProcessManager = FakeProcessManager.empty();
      final workingFlutterVersion = FakeFlutterVersion();

      // Disable terminal to bypass prompting (matches "performs correct git commands" case)
      workingStdio.hasTerminal = false;

      // Setup working file system state BEFORE constructing PersistentToolState
      // so it loads the correct state on construction.
      workingFileSystem.currentDirectory
          .childFile('.flutter_tool_state')
          .writeAsStringSync('{"last-active-master-version":"g6b00b5e88"}');

      final workingPersistentToolState = PersistentToolState.test(
        directory: workingFileSystem.currentDirectory,
        logger: workingLogger,
      );

      workingProcessManager.addCommands(const [
        FakeCommand(command: ['git', 'describe', '--tags', 'g6b00b5e88'], stdout: 'v1.2.3'),
        FakeCommand(command: ['git', 'reset', '--hard', 'g6b00b5e88']),
        FakeCommand(command: ['git', 'checkout', 'master', '--']),
      ]);

      final command = DowngradeCommand(
        toolContext: FakeToolContext(
          fs: workingFileSystem,
          logger: workingLogger,
          platform: FakePlatform(),
          persistentToolState: workingPersistentToolState,
          terminal: workingTerminal,
          stdio: workingStdio,
          flutterVersion: workingFlutterVersion,
          processManager: workingProcessManager,
          git: Git(
            currentPlatform: FakePlatform(),
            runProcessWith: ProcessUtils(
              processManager: workingProcessManager,
              logger: workingLogger,
            ),
          ),
        ),
      );
      command.applicationPackages = FakeApplicationPackageFactory();

      // Run the command. It should succeed using the working fakes.
      await createTestCommandRunner(command).run(const ['downgrade']);

      // Verify it used the working fakes
      expect(workingLogger.statusText, contains('Success'));

      // Verify it did NOT use the Zone fakes (bufferLogger should not contain 'Success')
      expect(bufferLogger.statusText, isNot(contains('Success')));
    },
    overrides: testOverrides,
  );
}

class FakeTerminal extends Fake implements AnsiTerminal {
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
}

class FakeToolContext extends Fake implements ToolContext {
  FakeToolContext({
    required this.fs,
    required this.logger,
    required this.platform,
    required this.persistentToolState,
    required this.terminal,
    required this.stdio,
    required this.flutterVersion,
    required this.processManager,
    required this.git,
  });

  @override
  final FileSystem fs;

  @override
  final Logger logger;

  @override
  final Platform platform;

  @override
  final PersistentToolState persistentToolState;

  @override
  final AnsiTerminal terminal;

  @override
  final Stdio stdio;

  @override
  final FlutterVersion flutterVersion;

  @override
  final ProcessManager processManager;

  @override
  final Git git;
}

class FakeApplicationPackageFactory extends Fake implements ApplicationPackageFactory {}
