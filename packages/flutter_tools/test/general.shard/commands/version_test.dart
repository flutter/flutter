// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/version.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart' show MockProcess;

void main() {
  group('version', () {
    setUpAll(() {
      Cache.disableLocking();
    });

    testUsingContext('version ls', () async {
      final VersionCommand command = VersionCommand();
      await createTestCommandRunner(command).run(<String>['version']);
      expect(testLogger.statusText, equals('v10.0.0\r\nv20.0.0\n' ''));
    }, overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(),
    });

    testUsingContext('version switch', () async {
      const String version = '10.0.0';
      final VersionCommand command = VersionCommand();
      final Future<void> runCommand = createTestCommandRunner(command).run(<String>['version', version]);
      await Future.wait<void>(<Future<void>>[runCommand]);
      expect(testLogger.statusText, contains('Switching Flutter to version $version'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(),
    });

    testUsingContext('switch to not supported version without force', () async {
      const String version = '1.1.5';
      final VersionCommand command = VersionCommand();
      final Future<void> runCommand = createTestCommandRunner(command).run(<String>['version', version]);
      await Future.wait<void>(<Future<void>>[runCommand]);
      expect(testLogger.errorText, contains('Version command is not supported in'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(),
    });

    testUsingContext('switch to not supported version with force', () async {
      const String version = '1.1.5';
      final VersionCommand command = VersionCommand();
      final Future<void> runCommand = createTestCommandRunner(command).run(<String>['version', '--force', version]);
      await Future.wait<void>(<Future<void>>[runCommand]);
      expect(testLogger.statusText, contains('Switching Flutter to version $version with force'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(),
    });

    testUsingContext('exit tool if can\'t get the tags', () async {
      final VersionCommand command = VersionCommand();

      try {
        await command.getTags();
        fail('ToolExit expected');
      } catch(e) {
        expect(e, isInstanceOf<ToolExit>());
      }
    }, overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(failGitTag: true),
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {
  MockProcessManager({ this.failGitTag = false });

  String version = '';

  bool failGitTag;

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
      return ProcessResult(0, 0, 'v10.0.0\r\nv20.0.0', '');
    }
    if (command[0] == 'git' && command[1] == 'checkout') {
      version = command[2];
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
        'git describe --match v*.*.* --first-parent --long --tags') {
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
