// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' hide File;

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/channel.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import 'src/common.dart';
import 'src/context.dart';

Process createMockProcess({int exitCode = 0, String stdout = '', String stderr = ''}) {
  final Stream<List<int>> stdoutStream = Stream<List<int>>.fromIterable(<List<int>>[
    utf8.encode(stdout),
  ]);
  final Stream<List<int>> stderrStream = Stream<List<int>>.fromIterable(<List<int>>[
    utf8.encode(stderr),
  ]);
  final Process process = MockProcess();

  when(process.stdout).thenAnswer((_) => stdoutStream);
  when(process.stderr).thenAnswer((_) => stderrStream);
  when(process.exitCode).thenAnswer((_) => Future<int>.value(exitCode));
  return process;
}

void main() {
  group('channel', () {
    final MockProcessManager mockProcessManager = MockProcessManager();

    setUpAll(() {
      Cache.disableLocking();
    });

    testUsingContext('list', () async {
      final ChannelCommand command = ChannelCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['channel']);
      expect(testLogger.errorText, hasLength(0));
      // The bots may return an empty list of channels (network hiccup?)
      // and when run locally the list of branches might be different
      // so we check for the header text rather than any specific channel name.
      expect(testLogger.statusText, contains('Flutter channels:'));
    });

    testUsingContext('removes duplicates', () async {
      final Process process = createMockProcess(
          stdout: 'origin/dev\n'
                  'origin/beta\n'
                  'origin/stable\n'
                  'upstream/dev\n'
                  'upstream/beta\n'
                  'upstream/stable\n');
      when(mockProcessManager.start(
        <String>['git', 'branch', '-r'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<Process>.value(process));

      final ChannelCommand command = ChannelCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['channel']);

      verify(mockProcessManager.start(
        <String>['git', 'branch', '-r'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).called(1);

      expect(testLogger.errorText, hasLength(0));

      // format the status text for a simpler assertion.
      final Iterable<String> rows = testLogger.statusText
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line?.isNotEmpty == true)
        .skip(1); // remove `Flutter channels:` line

      expect(rows, <String>['dev', 'beta', 'stable']);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('can switch channels', () async {
      when(mockProcessManager.start(
        <String>['git', 'fetch'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<Process>.value(createMockProcess()));
      when(mockProcessManager.start(
        <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/beta'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<Process>.value(createMockProcess()));
      when(mockProcessManager.start(
        <String>['git', 'checkout', 'beta', '--'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<Process>.value(createMockProcess()));

      final ChannelCommand command = ChannelCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['channel', 'beta']);

      verify(mockProcessManager.start(
        <String>['git', 'fetch'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).called(1);
      verify(mockProcessManager.start(
        <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/beta'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).called(1);
      verify(mockProcessManager.start(
        <String>['git', 'checkout', 'beta', '--'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).called(1);

      expect(testLogger.statusText, contains("Switching to flutter channel 'beta'..."));
      expect(testLogger.errorText, hasLength(0));

      when(mockProcessManager.start(
        <String>['git', 'fetch'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<Process>.value(createMockProcess()));
      when(mockProcessManager.start(
        <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/stable'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<Process>.value(createMockProcess()));
      when(mockProcessManager.start(
        <String>['git', 'checkout', 'stable', '--'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<Process>.value(createMockProcess()));

      await runner.run(<String>['channel', 'stable']);

      verify(mockProcessManager.start(
        <String>['git', 'fetch'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).called(1);
      verify(mockProcessManager.start(
        <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/stable'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).called(1);
      verify(mockProcessManager.start(
        <String>['git', 'checkout', 'stable', '--'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).called(1);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      FileSystem: () => MemoryFileSystem(),
    });

    // This verifies that bug https://github.com/flutter/flutter/issues/21134
    // doesn't return.
    testUsingContext('removes version stamp file when switching channels', () async {
      when(mockProcessManager.start(
        <String>['git', 'fetch'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<Process>.value(createMockProcess()));
      when(mockProcessManager.start(
        <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/beta'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<Process>.value(createMockProcess()));
      when(mockProcessManager.start(
        <String>['git', 'checkout', 'beta', '--'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<Process>.value(createMockProcess()));

      final File versionCheckFile = Cache.instance.getStampFileFor(
        VersionCheckStamp.flutterVersionCheckStampFile,
      );

      /// Create a bogus "leftover" version check file to make sure it gets
      /// removed when the channel changes. The content doesn't matter.
      versionCheckFile.createSync(recursive: true);
      versionCheckFile.writeAsStringSync('''
        {
          "lastTimeVersionWasChecked": "2151-08-29 10:17:30.763802",
          "lastKnownRemoteVersion": "2151-09-26 15:56:19.000Z"
        }
      ''');

      final ChannelCommand command = ChannelCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['channel', 'beta']);

      verify(mockProcessManager.start(
        <String>['git', 'fetch'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).called(1);
      verify(mockProcessManager.start(
        <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/beta'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).called(1);
      verify(mockProcessManager.start(
        <String>['git', 'checkout', 'beta', '--'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).called(1);

      expect(testLogger.statusText, isNot(contains('A new version of Flutter')));
      expect(testLogger.errorText, hasLength(0));
      expect(versionCheckFile.existsSync(), isFalse);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      FileSystem: () => MemoryFileSystem(),
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}

class MockProcess extends Mock implements Process {}
