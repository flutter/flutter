// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

// TODO(gspencergoog): Remove this tag once this test's state leaks/test
// dependencies have been fixed.
// https://github.com/flutter/flutter/issues/85160
// Fails with "flutter test --test-randomize-ordering-seed=20210723"
@Tags(<String>['no-shuffle'])

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/channel.dart';
import 'package:flutter_tools/src/globals_null_migrated.dart' as globals;
import 'package:flutter_tools/src/version.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/test_flutter_command_runner.dart';

void main() {
  group('channel', () {
    FakeProcessManager fakeProcessManager;

    setUp(() {
      fakeProcessManager = FakeProcessManager.empty();
    });

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
      final ChannelCommand command = ChannelCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);

      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>['git', 'branch', '-r'],
          stdout: 'origin/beta\n'
              'origin/master\n'
              'origin/dev\n'
              'origin/stable\n',
        ),
      );

      await runner.run(<String>['channel']);
      expect(fakeProcessManager.hasRemainingExpectations, isFalse);
      expect(testLogger.errorText, hasLength(0));
      // format the status text for a simpler assertion.
      final Iterable<String> rows = testLogger.statusText
        .split('\n')
        .map((String line) => line.substring(2)); // remove '* ' or '  ' from output
      expect(rows, containsAllInOrder(kOfficialChannels));

      // clear buffer for next process
      testLogger.clear();

      // Extra branches.
      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>['git', 'branch', '-r'],
          stdout: 'origin/beta\n'
              'origin/master\n'
              'origin/dependabot/bundler\n'
              'origin/dev\n'
              'origin/v1.4.5-hotfixes\n'
              'origin/stable\n',
        ),
      );

      await runner.run(<String>['channel']);
      expect(fakeProcessManager.hasRemainingExpectations, isFalse);
      expect(rows, containsAllInOrder(kOfficialChannels));
      expect(testLogger.errorText, hasLength(0));
      // format the status text for a simpler assertion.
      final Iterable<String> rows2 = testLogger.statusText
        .split('\n')
        .map((String line) => line.substring(2)); // remove '* ' or '  ' from output
      expect(rows2, containsAllInOrder(kOfficialChannels));

      // clear buffer for next process
      testLogger.clear();

      // Missing branches.
      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>['git', 'branch', '-r'],
          stdout: 'origin/beta\n'
              'origin/dependabot/bundler\n'
              'origin/v1.4.5-hotfixes\n'
              'origin/stable\n',
        ),
      );

      await runner.run(<String>['channel']);
      expect(fakeProcessManager.hasRemainingExpectations, isFalse);
      expect(testLogger.errorText, hasLength(0));
      // check if available official channels are in order of stability
      int prev = -1;
      int next = -1;
      for (final String branch in kOfficialChannels) {
        next = testLogger.statusText.indexOf(branch);
        if (next != -1) {
          expect(prev < next, isTrue);
          prev = next;
        }
      }

    }, overrides: <Type, Generator>{
      ProcessManager: () => fakeProcessManager,
      FileSystem: () => MemoryFileSystem.test(),
    });

    testUsingContext('removes duplicates', () async {
      fakeProcessManager.addCommand(
        const FakeCommand(
          command: <String>['git', 'branch', '-r'],
          stdout: 'origin/dev\n'
              'origin/beta\n'
              'origin/stable\n'
              'upstream/dev\n'
              'upstream/beta\n'
              'upstream/stable\n',
        ),
      );

      final ChannelCommand command = ChannelCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['channel']);

      expect(fakeProcessManager.hasRemainingExpectations, isFalse);
      expect(testLogger.errorText, hasLength(0));

      // format the status text for a simpler assertion.
      final Iterable<String> rows = testLogger.statusText
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line?.isNotEmpty == true)
        .skip(1); // remove `Flutter channels:` line

      expect(rows, <String>['dev', 'beta', 'stable', 'Currently not on an official channel.']);
    }, overrides: <Type, Generator>{
      ProcessManager: () => fakeProcessManager,
      FileSystem: () => MemoryFileSystem.test(),
    });

    testUsingContext('can switch channels', () async {
      fakeProcessManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>['git', 'fetch'],
        ),
        const FakeCommand(
          command: <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/beta'],
        ),
        const FakeCommand(
            command: <String>['git', 'checkout', 'beta', '--']
        ),
      ]);

      final ChannelCommand command = ChannelCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['channel', 'beta']);

      expect(fakeProcessManager.hasRemainingExpectations, isFalse);
      expect(
        testLogger.statusText,
        containsIgnoringWhitespace("Switching to flutter channel 'beta'..."),
      );
      expect(testLogger.errorText, hasLength(0));

      fakeProcessManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>['git', 'fetch'],
        ),
        const FakeCommand(
          command: <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/stable'],
        ),
        const FakeCommand(
            command: <String>['git', 'checkout', 'stable', '--']
        ),
      ]);

      await runner.run(<String>['channel', 'stable']);

      expect(fakeProcessManager.hasRemainingExpectations, isFalse);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => fakeProcessManager,
    });

    testUsingContext('switching channels prompts to run flutter upgrade', () async {
      fakeProcessManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>['git', 'fetch'],
        ),
        const FakeCommand(
          command: <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/beta'],
        ),
        const FakeCommand(
            command: <String>['git', 'checkout', 'beta', '--']
        ),
      ]);

      final ChannelCommand command = ChannelCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['channel', 'beta']);

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
      expect(fakeProcessManager.hasRemainingExpectations, isFalse);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => fakeProcessManager,
    });

    // This verifies that bug https://github.com/flutter/flutter/issues/21134
    // doesn't return.
    testUsingContext('removes version stamp file when switching channels', () async {
      fakeProcessManager.addCommands(<FakeCommand>[
        const FakeCommand(
          command: <String>['git', 'fetch'],
        ),
        const FakeCommand(
          command: <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/beta'],
        ),
        const FakeCommand(
          command: <String>['git', 'checkout', 'beta', '--']
        ),
      ]);

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

      expect(testLogger.statusText, isNot(contains('A new version of Flutter')));
      expect(testLogger.errorText, hasLength(0));
      expect(versionCheckFile.existsSync(), isFalse);
      expect(fakeProcessManager.hasRemainingExpectations, isFalse);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      ProcessManager: () => fakeProcessManager,
    });
  });
}
