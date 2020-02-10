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
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

void main() {
  FileSystem fileSystem;
  BufferLogger bufferLogger;
  AnsiTerminal terminal;
  ProcessManager processManager;
  MockStdio mockStdio;
  FlutterVersion flutterVersion;

  setUpAll(() {
    Cache.disableLocking();
  });

  tearDownAll(() {
    Cache.enableLocking();
  });

  setUp(() {
    flutterVersion = MockFlutterVersion();
    mockStdio = MockStdio();
    processManager = FakeProcessManager.any();
    terminal = MockTerminal();
    fileSystem = MemoryFileSystem.test();
    bufferLogger = BufferLogger(terminal: terminal, outputPreferences: OutputPreferences.test());
  });

  testUsingContext('Downgrade exits on unknown channel', () async {
    fileSystem.currentDirectory.childFile('.flutter_tool_state')
      .writeAsStringSync('{"last-active-master-version":"invalid"}');
    final DowngradeCommand command = DowngradeCommand(
      persistentToolState: PersistentToolState.test(directory: fileSystem.currentDirectory, logger: bufferLogger),
      processManager: processManager,
      terminal: terminal,
      stdio: mockStdio,
      flutterVersion: flutterVersion,
      logger: bufferLogger,
    );
    applyMocksToCommand(command);

    expect(createTestCommandRunner(command).run(const <String>['downgrade']),
      throwsToolExit(message: 'Flutter is not currently on a known channel.'));
  });

  testUsingContext('Downgrade exits on unknown recorded version', () async {
    when(flutterVersion.channel).thenReturn('master');
    fileSystem.currentDirectory.childFile('.flutter_tool_state')
      .writeAsStringSync('{"last-active-master-version":"invalid"}');
    final DowngradeCommand command = DowngradeCommand(
      persistentToolState: PersistentToolState.test(directory: fileSystem.currentDirectory, logger: bufferLogger),
      processManager: processManager,
      terminal: terminal,
      stdio: mockStdio,
      flutterVersion: flutterVersion,
      logger: bufferLogger,
    );
    applyMocksToCommand(command);

    expect(createTestCommandRunner(command).run(const <String>['downgrade']),
      throwsToolExit(message: 'There is no previously recorded version for channel "master."'));
  });

   testUsingContext('Downgrade prompts for user input when terminal is attached - y', () async {
    when(flutterVersion.channel).thenReturn('master');
    when(mockStdio.hasTerminal).thenReturn(true);
    fileSystem.currentDirectory.childFile('.flutter_tool_state')
      .writeAsStringSync('{"last-active-master-version":"v1.15.2-40-g6b00b5e88"}');
    final DowngradeCommand command = DowngradeCommand(
      persistentToolState: PersistentToolState.test(directory: fileSystem.currentDirectory, logger: bufferLogger),
      processManager: processManager,
      terminal: terminal,
      stdio: mockStdio,
      flutterVersion: flutterVersion,
      logger: bufferLogger,
    );
    applyMocksToCommand(command);

    when(terminal.promptForCharInput(
      const <String>['y', 'n'],
      prompt: anyNamed('prompt'),
      logger: anyNamed('logger'),
    )).thenAnswer((Invocation invocation) async => 'y');

    await createTestCommandRunner(command).run(const <String>['downgrade']);

    verify(terminal.promptForCharInput(
      const <String>['y', 'n'],
      prompt: anyNamed('prompt'),
      logger: anyNamed('logger'),
    )).called(1);
    expect(bufferLogger.statusText, contains('Success'));
  });

   testUsingContext('Downgrade prompts for user input when terminal is attached - n', () async {
    when(flutterVersion.channel).thenReturn('master');
    when(mockStdio.hasTerminal).thenReturn(true);
    fileSystem.currentDirectory.childFile('.flutter_tool_state')
      .writeAsStringSync('{"last-active-master-version":"v1.15.2-40-g6b00b5e88"}');
    final DowngradeCommand command = DowngradeCommand(
      persistentToolState: PersistentToolState.test(directory: fileSystem.currentDirectory, logger: bufferLogger),
      processManager: processManager,
      terminal: terminal,
      stdio: mockStdio,
      flutterVersion: flutterVersion,
      logger: bufferLogger,
    );
    applyMocksToCommand(command);

    when(terminal.promptForCharInput(
      const <String>['y', 'n'],
      prompt: anyNamed('prompt'),
      logger: anyNamed('logger'),
    )).thenAnswer((Invocation invocation) async => 'n');

    await createTestCommandRunner(command).run(const <String>['downgrade']);

    verify(terminal.promptForCharInput(
      const <String>['y', 'n'],
      prompt: anyNamed('prompt'),
      logger: anyNamed('logger'),
    )).called(1);
    expect(bufferLogger.statusText, isNot(contains('Success')));
  });

  testUsingContext('Downgrade does not prompt when there is no terminal', () async {
    when(flutterVersion.channel).thenReturn('master');
    when(mockStdio.hasTerminal).thenReturn(false);
    fileSystem.currentDirectory.childFile('.flutter_tool_state')
      .writeAsStringSync('{"last-active-master-version":"v1.15.2-40-g6b00b5e88"}');
    final DowngradeCommand command = DowngradeCommand(
      persistentToolState: PersistentToolState.test(directory: fileSystem.currentDirectory, logger: bufferLogger),
      processManager: processManager,
      terminal: terminal,
      stdio: mockStdio,
      flutterVersion: flutterVersion,
      logger: bufferLogger,
    );
    applyMocksToCommand(command);

    await createTestCommandRunner(command).run(const <String>['downgrade']);

    verifyNever(terminal.promptForCharInput(
      const <String>['y', 'n'],
      prompt: anyNamed('prompt'),
      logger: anyNamed('logger'),
    ));
    expect(bufferLogger.statusText, contains('Success'));
  });
}

class MockTerminal extends Mock implements AnsiTerminal {}
class MockStdio extends Mock implements Stdio {}
