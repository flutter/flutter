// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/upgrade.dart';
import 'package:flutter_tools/src/version.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart' show FakeFlutterVersion;
import '../../src/test_flutter_command_runner.dart';

void main() {
  FileSystem fileSystem;
  BufferLogger logger;
  FakeProcessManager processManager;
  UpgradeCommand command;
  CommandRunner<void> runner;
  FlutterVersion flutterVersion;

  setUpAll(() {
    Cache.disableLocking();
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    processManager = FakeProcessManager.empty();
    command = UpgradeCommand(
      verboseHelp: false,
    );
    runner = createTestCommandRunner(command);
  });

  testUsingContext('can auto-migrate a user from dev to beta', () async {
    const String startingTag = '3.0.0-1.2.pre';
    flutterVersion = FakeFlutterVersion(channel: 'dev');
    const String latestUpstreamTag = '3.0.0-1.3.pre';
    const String upstreamHeadRevision = 'deadbeef';
    final Completer<void> reEntryCompleter = Completer<void>();

    Future<void> reEnterTool() async {
      await runner.run(<String>['upgrade', '--continue', '--no-version-check']);
      reEntryCompleter.complete();
    }

    processManager.addCommands(<FakeCommand>[
      const FakeCommand(
        command: <String>['git', 'tag', '--points-at', 'HEAD'],
        stdout: startingTag,
      ),
      // Ensure we have upstream tags present locally
      const FakeCommand(
        command: <String>['git', 'fetch', '--tags'],
      ),
      const FakeCommand(
        command: <String>['git', 'rev-parse', '--verify', '@{u}'],
        stdout: upstreamHeadRevision,
      ),
      const FakeCommand(
        command: <String>['git', 'tag', '--points-at', upstreamHeadRevision],
        stdout: latestUpstreamTag,
      ),
      // check for uncommitted changes; empty stdout means clean checkout
      const FakeCommand(
        command: <String>['git', 'status', '-s'],
      ),

      // here the tool is upgrading the branch from dev -> beta
      const FakeCommand(
        command: <String>['git', 'fetch'],
      ),
      // test if there already exists a local beta branch; 0 exit code means yes
      const FakeCommand(
        command: <String>['git', 'show-ref', '--verify', '--quiet', 'refs/heads/beta'],
      ),
      const FakeCommand(
        command: <String>['git', 'checkout', 'beta', '--'],
      ),

      // reset instead of pull since cherrypicks from one release branch will
      // not be present on a newer one
      const FakeCommand(
        command: <String>['git', 'reset', '--hard', upstreamHeadRevision],
      ),
      // re-enter flutter command with the newer version, so that `doctor`
      // checks will be up to date
      FakeCommand(
        command: const <String>['bin/flutter', 'upgrade', '--continue', '--no-version-check'],
        onRun: reEnterTool,
        completer: reEntryCompleter,
      ),

      // commands following this are from the re-entrant `flutter upgrade --continue` call

      const FakeCommand(
        command: <String>['git', 'tag', '--points-at', 'HEAD'],
        stdout: latestUpstreamTag,
      ),
      const FakeCommand(
        command: <String>['bin/flutter', '--no-color', '--no-version-check', 'precache'],
      ),
      const FakeCommand(
        command: <String>['bin/flutter', '--no-version-check', 'doctor'],
      ),
    ]);
    await runner.run(<String>['upgrade']);
    expect(processManager, hasNoRemainingExpectations);
    expect(logger.statusText, contains("Transitioning from 'dev' to 'beta'..."));
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    FlutterVersion: () => flutterVersion,
    Logger: () => logger,
    ProcessManager: () => processManager,
  });
}
