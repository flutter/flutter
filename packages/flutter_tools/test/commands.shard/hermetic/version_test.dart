// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/version.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart' show MockProcess;

void main() {
  group('version', () {
    MockStdio mockStdio;
    MockVersion mockVersion;

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      mockStdio = MockStdio();
      mockVersion = MockVersion();
      when(mockStdio.stdinHasTerminal).thenReturn(false);
      when(mockStdio.hasTerminal).thenReturn(false);
    });

    testUsingContext('version ls', () async {
      final VersionCommand command = VersionCommand();
      await createTestCommandRunner(command).run(<String>[
        'version',
        '--no-pub',
      ]);
      expect(testLogger.statusText, equals(
        '[!] The "version" command is deprecated '
            'and will be removed in a future version of Flutter. '
            'See https://flutter.dev/docs/development/tools/sdk/releases '
            'for previous releases of Flutter.\n\n'
        'v10.0.0\r\nv20.0.0\r\n30.0.0-dev.0.0\r\n31.0.0-0.0.pre\n'
      ));
    }, overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(),
      Stdio: () => mockStdio,
      FlutterVersion: () => mockVersion,
    });

    testUsingContext('version switch prompt is accepted', () async {
      when(mockStdio.stdinHasTerminal).thenReturn(true);
      const String version = 'v10.0.0';
      final VersionCommand command = VersionCommand();
      when(globals.terminal.promptForCharInput(<String>['y', 'n'],
        logger: anyNamed('logger'),
        prompt: 'Are you sure you want to proceed?')
      ).thenAnswer((Invocation invocation) async => 'y');

      await createTestCommandRunner(command).run(<String>[
        'version',
        '--no-pub',
        version,
      ]);
      expect(testLogger.statusText, contains('Switching Flutter to version $version'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(),
      Stdio: () => mockStdio,
      AnsiTerminal: () => MockTerminal(),
      FlutterVersion: () => mockVersion,
    });

    testUsingContext('old dev version switch prompt is accepted', () async {
      when(mockStdio.stdinHasTerminal).thenReturn(true);
      const String version = '30.0.0-dev.0.0';
      final VersionCommand command = VersionCommand();
      when(globals.terminal.promptForCharInput(<String>['y', 'n'],
        logger: anyNamed('logger'),
        prompt: 'Are you sure you want to proceed?')
      ).thenAnswer((Invocation invocation) async => 'y');

      await createTestCommandRunner(command).run(<String>[
        'version',
        '--no-pub',
        version,
      ]);
      expect(testLogger.statusText, contains('Switching Flutter to version $version'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(),
      Stdio: () => mockStdio,
      AnsiTerminal: () => MockTerminal(),
      FlutterVersion: () => mockVersion,
    });

    testUsingContext('dev version switch prompt is accepted', () async {
      when(mockStdio.stdinHasTerminal).thenReturn(true);
      const String version = '31.0.0-0.0.pre';
      final VersionCommand command = VersionCommand();
      when(globals.terminal.promptForCharInput(<String>['y', 'n'],
        logger: anyNamed('logger'),
        prompt: 'Are you sure you want to proceed?')
      ).thenAnswer((Invocation invocation) async => 'y');

      await createTestCommandRunner(command).run(<String>[
        'version',
        '--no-pub',
        version,
      ]);
      expect(testLogger.statusText, contains('Switching Flutter to version $version'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(),
      Stdio: () => mockStdio,
      AnsiTerminal: () => MockTerminal(),
      FlutterVersion: () => mockVersion,
    });

    testUsingContext('version switch prompt is declined', () async {
      when(mockStdio.stdinHasTerminal).thenReturn(true);
      const String version = '10.0.0';
      final VersionCommand command = VersionCommand();
      when(globals.terminal.promptForCharInput(<String>['y', 'n'],
        logger: anyNamed('logger'),
        prompt: 'Are you sure you want to proceed?')
      ).thenAnswer((Invocation invocation) async => 'n');

      await createTestCommandRunner(command).run(<String>[
        'version',
        '--no-pub',
        version,
      ]);
      expect(testLogger.statusText, isNot(contains('Switching Flutter to version $version')));
    }, overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(),
      Stdio: () => mockStdio,
      AnsiTerminal: () => MockTerminal(),
      FlutterVersion: () => mockVersion,
    });

    testUsingContext('switch to not supported version without force', () async {
      const String version = '1.1.5';
      final VersionCommand command = VersionCommand();
      await createTestCommandRunner(command).run(<String>[
        'version',
        '--no-pub',
        version,
      ]);
      expect(testLogger.errorText, contains('Version command is not supported in'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(),
      Stdio: () => mockStdio,
      FlutterVersion: () => mockVersion,
    });

    testUsingContext('switch to not supported version with force', () async {
      const String version = '1.1.5';
      final VersionCommand command = VersionCommand();
      await createTestCommandRunner(command).run(<String>[
        'version',
        '--no-pub',
        '--force',
        version,
      ]);
      expect(testLogger.statusText, contains('Switching Flutter to version $version with force'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(),
      Stdio: () => mockStdio,
      FlutterVersion: () => mockVersion,
    });

    testUsingContext('tool exit on confusing version', () async {
      const String version = 'master';
      final VersionCommand command = VersionCommand();
      expect(() async =>
        await createTestCommandRunner(command).run(<String>[
          'version',
          '--no-pub',
          version,
        ]),
        throwsToolExit(),
      );
    }, overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(),
      Stdio: () => mockStdio,
      FlutterVersion: () => mockVersion,
    });

    testUsingContext("exit tool if can't get the tags", () async {
      final VersionCommand command = VersionCommand();
      try {
        await command.getTags();
        fail('ToolExit expected');
      } on Exception catch (e) {
        expect(e, isA<ToolExit>());
      }
    }, overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(failGitTag: true),
      Stdio: () => mockStdio,
      FlutterVersion: () => mockVersion,
    });

    testUsingContext('Does not run pub when outside a project', () async {
      final VersionCommand command = VersionCommand();
      await createTestCommandRunner(command).run(<String>[
        'version',
      ]);
      expect(testLogger.statusText, contains('v10.0.0\r\nv20.0.0\r\n30.0.0-dev.0.0\r\n31.0.0-0.0.pre\n'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(),
      Stdio: () => mockStdio,
      FlutterVersion: () => mockVersion,
    });

    testUsingContext('Fetches upstream tags', () async {
      final VersionCommand command = VersionCommand();
      await createTestCommandRunner(command).run(<String>[
        'version',
      ]);
      verify(mockVersion.fetchTagsAndUpdate()).called(1);
    }, overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(),
      Stdio: () => mockStdio,
      FlutterVersion: () => mockVersion,
    });
  });
}

class MockVersion extends Mock implements FlutterVersion {}
class MockTerminal extends Mock implements AnsiTerminal {}
class MockStdio extends Mock implements Stdio {}
class MockProcessManager extends Mock implements ProcessManager {
  MockProcessManager({
    this.failGitTag = false,
    this.latestCommitFails = false,
  });

  String version = '';

  final bool failGitTag;
  final bool latestCommitFails;

  @override
  Future<ProcessResult> run(
    List<dynamic> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding stdoutEncoding = systemEncoding,
    Encoding stderrEncoding = systemEncoding,
  }) async {
    if (command[0] == 'git' && command[1] == 'tag') {
      if (failGitTag) {
        return ProcessResult(0, 1, '', '');
      }
      return ProcessResult(0, 0, 'v10.0.0\r\nv20.0.0\r\n30.0.0-dev.0.0\r\n31.0.0-0.0.pre', '');
    }
    if (command[0] == 'git' && command[1] == 'checkout') {
      version = (command[2] as String).replaceFirst(RegExp('^v'), '');
    }

    return ProcessResult(0, 0, '', '');
  }

  @override
  ProcessResult runSync(
    List<dynamic> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding stdoutEncoding = systemEncoding,
    Encoding stderrEncoding = systemEncoding,
  }) {
    final String commandStr = command.join(' ');
    if (commandStr == FlutterVersion.gitLog(<String>['-n', '1', '--pretty=format:%H']).join(' ')) {
      return ProcessResult(0, 0, '000000000000000000000', '');
    }
    if (commandStr ==
        'git describe --match *.*.* --first-parent --long --tags') {
      if (version.isNotEmpty) {
        return ProcessResult(0, 0, '$version-0-g00000000', '');
      }
    }
    return ProcessResult(0, 0, '', '');
  }

  @override
  Future<Process> start(
    List<dynamic> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    final Completer<Process> completer = Completer<Process>();
    completer.complete(MockProcess());
    return completer.future;
  }
}
