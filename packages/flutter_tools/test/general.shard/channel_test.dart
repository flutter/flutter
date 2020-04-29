// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' hide File;

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/commands/channel.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

void main() {
  group('channel', () {
    final MockProcessManager mockProcessManager = MockProcessManager();

    setUpAll(() {
      Cache.disableLocking();
    });

    Future<void> simpleChannelTest(List<String> args) async {
      final ChannelCommand command = ChannelCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(args);
      expect(testLogger.errorText, hasLength(0));
      // The bots may return an empty list of channels (network hiccup?)
      // and when run locally the list of branches might be different
      // so we check for the header text rather than any specific channel name.
      expect(
        testLogger.statusText,
        containsIgnoringWhitespace('Flutter channels:'),
      );
    }

    testUsingContext('list', () async {
      await simpleChannelTest(<String>['channel']);
    });

    testUsingContext('verbose list', () async {
      await simpleChannelTest(<String>['channel', '-v']);
    });

    testUsingContext('sorted by stability', () async {
      final Process processAll = createMockProcess(
          stdout: 'origin/beta\n'
                  'origin/master\n'
                  'origin/dev\n'
                  'origin/stable\n');
      final Process processWithExtra = createMockProcess(
          stdout: 'origin/beta\n'
                  'origin/master\n'
                  'origin/dependabot/bundler\n'
                  'origin/dev\n'
                  'origin/v1.4.5-hotfixes\n'
                  'origin/stable\n');
      final Process processWithMissing = createMockProcess(
          stdout: 'origin/beta\n'
                  'origin/dependabot/bundler\n'
                  'origin/v1.4.5-hotfixes\n'
                  'origin/stable\n');

      final ChannelCommand command = ChannelCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);

      when(mockProcessManager.start(
        <String>['git', 'branch', '-r'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<Process>.value(processAll));
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
        .map((String line) => line.substring(2)); // remove '* ' or '  ' from output
      expect(rows, containsAllInOrder(FlutterVersion.officialChannels));

      // clear buffer for next process
      testLogger.clear();

      when(mockProcessManager.start(
        <String>['git', 'branch', '-r'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<Process>.value(processWithExtra));
      await runner.run(<String>['channel']);
      verify(mockProcessManager.start(
        <String>['git', 'branch', '-r'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).called(1);
      expect(testLogger.errorText, hasLength(0));
      // format the status text for a simpler assertion.
      final Iterable<String> rows2 = testLogger.statusText
        .split('\n')
        .map((String line) => line.substring(2)); // remove '* ' or '  ' from output
      expect(rows2, containsAllInOrder(FlutterVersion.officialChannels));

      // clear buffer for next process
      testLogger.clear();

      when(mockProcessManager.start(
        <String>['git', 'branch', '-r'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<Process>.value(processWithMissing));
      await runner.run(<String>['channel']);
      verify(mockProcessManager.start(
        <String>['git', 'branch', '-r'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).called(1);
      expect(testLogger.errorText, hasLength(0));
      // check if available official channels are in order of stability
      int prev = -1;
      int next = -1;
      for (final String branch in FlutterVersion.officialChannels) {
        next = testLogger.statusText.indexOf(branch);
        if (next != -1) {
          expect(prev < next, isTrue);
          prev = next;
        }
      }

    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
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

      expect(
        testLogger.statusText,
        containsIgnoringWhitespace("Switching to flutter channel 'beta'..."),
      );
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
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('switching channels prompts to run flutter upgrade', () async {
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

      expect(
        testLogger.statusText,
        containsIgnoringWhitespace("Successfully switched to flutter channel 'beta'."),
      );
      expect(
        testLogger.statusText,
        containsIgnoringWhitespace(
          "To ensure that you're on the latest build "
          "from this channel, run 'flutter upgrade'"),
      );
      expect(testLogger.errorText, hasLength(0));
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => mockProcessManager,
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

      final File versionCheckFile = globals.cache.getStampFileFor(
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
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => mockProcessManager,
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}

class MockProcess extends Mock implements Process {}
