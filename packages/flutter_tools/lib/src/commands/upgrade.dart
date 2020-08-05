// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/io.dart';
import '../base/os.dart';
import '../base/process.dart';
import '../base/time.dart';
import '../cache.dart';
import '../dart/pub.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';
import '../version.dart';
import 'channel.dart';

class UpgradeCommand extends FlutterCommand {
  UpgradeCommand([UpgradeCommandRunner commandRunner])
    : _commandRunner = commandRunner ?? UpgradeCommandRunner() {
    argParser
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Force upgrade the flutter branch, potentially discarding local changes.',
        negatable: false,
      )
      ..addFlag(
        'continue',
        hide: true,
        negatable: false,
        help: 'For the second half of the upgrade flow requiring the new '
              'version of Flutter. Should not be invoked manually, but '
              're-entrantly by the standard upgrade command.',
      )
      ..addOption(
        'working-directory',
        hide: true,
        help: 'Override the upgrade working directoy for integration testing.'
      );
  }

  final UpgradeCommandRunner _commandRunner;

  @override
  final String name = 'upgrade';

  @override
  final String description = 'Upgrade your copy of Flutter.';

  @override
  bool get shouldUpdateCache => false;

  @override
  Future<FlutterCommandResult> runCommand() {
    _commandRunner.workingDirectory = stringArg('working-directory') ?? Cache.flutterRoot;
    return _commandRunner.runCommand(
      force: boolArg('force'),
      continueFlow: boolArg('continue'),
      testFlow: stringArg('working-directory') != null,
      gitTagVersion: GitTagVersion.determine(processUtils),
      flutterVersion: stringArg('working-directory') == null
        ? globals.flutterVersion
        : FlutterVersion(const SystemClock(), _commandRunner.workingDirectory),
    );
  }
}

@visibleForTesting
class UpgradeCommandRunner {

  String workingDirectory;

  Future<FlutterCommandResult> runCommand({
    @required bool force,
    @required bool continueFlow,
    @required bool testFlow,
    @required GitTagVersion gitTagVersion,
    @required FlutterVersion flutterVersion,
  }) async {
    if (!continueFlow) {
      await runCommandFirstHalf(
        force: force,
        gitTagVersion: gitTagVersion,
        flutterVersion: flutterVersion,
        testFlow: testFlow,
      );
    } else {
      await runCommandSecondHalf(flutterVersion);
    }
    return FlutterCommandResult.success();
  }

  Future<void> runCommandFirstHalf({
    @required bool force,
    @required GitTagVersion gitTagVersion,
    @required FlutterVersion flutterVersion,
    @required bool testFlow,
  }) async {
    final String upstreamRevision = await fetchRemoteRevision();
    if (flutterVersion.frameworkRevision == upstreamRevision) {
      globals.printStatus('Flutter is already up to date on channel ${flutterVersion.channel}');
      globals.printStatus('$flutterVersion');
      return;
    }
    if (!force && gitTagVersion == const GitTagVersion.unknown()) {
      // If the commit is a recognized branch and not master,
      // explain that we are avoiding potential damage.
      if (flutterVersion.channel != 'master' && FlutterVersion.officialChannels.contains(flutterVersion.channel)) {
        throwToolExit(
          'Unknown flutter tag. Abandoning upgrade to avoid destroying local '
          'changes. It is recommended to use git directly if not working on '
          'an official channel.'
        );
      // Otherwise explain that local changes can be lost.
      } else {
        throwToolExit(
          'Unknown flutter tag. Abandoning upgrade to avoid destroying local '
          'changes. If it is okay to remove local changes, then re-run this '
          'command with --force.'
        );
      }
    }
    // If there are uncommitted changes we might be on the right commit but
    // we should still warn.
    if (!force && await hasUncomittedChanges()) {
      throwToolExit(
        'Your flutter checkout has local changes that would be erased by '
        'upgrading. If you want to keep these changes, it is recommended that '
        'you stash them via "git stash" or else commit the changes to a local '
        'branch. If it is okay to remove local changes, then re-run this '
        'command with --force.'
      );
    }
    recordState(flutterVersion);
    await upgradeChannel(flutterVersion);
    await attemptReset(upstreamRevision);
    if (!testFlow) {
      await flutterUpgradeContinue();
    }
  }

  void recordState(FlutterVersion flutterVersion) {
    final Channel channel = getChannelForName(flutterVersion.channel);
    if (channel == null) {
      return;
    }
    globals.persistentToolState.updateLastActiveVersion(flutterVersion.frameworkRevision, channel);
  }

  Future<void> flutterUpgradeContinue() async {
    final int code = await processUtils.stream(
      <String>[
        globals.fs.path.join('bin', 'flutter'),
        'upgrade',
        '--continue',
        '--no-version-check',
      ],
      workingDirectory: workingDirectory,
      allowReentrantFlutter: true,
      environment: Map<String, String>.of(globals.platform.environment),
    );
    if (code != 0) {
      throwToolExit(null, exitCode: code);
    }
  }

  // This method should only be called if the upgrade command is invoked
  // re-entrantly with the `--continue` flag
  Future<void> runCommandSecondHalf(FlutterVersion flutterVersion) async {
    // Make sure the welcome message re-display is delayed until the end.
    globals.persistentToolState.redisplayWelcomeMessage = false;
    await precacheArtifacts();
    await updatePackages(flutterVersion);
    await runDoctor();
    // Force the welcome message to re-display following the upgrade.
    globals.persistentToolState.redisplayWelcomeMessage = true;
  }

  Future<bool> hasUncomittedChanges() async {
    try {
      final RunResult result = await processUtils.run(
        <String>['git', 'status', '-s'],
        throwOnError: true,
        workingDirectory: workingDirectory,
      );
      return result.stdout.trim().isNotEmpty;
    } on ProcessException catch (error) {
      throwToolExit(
        'The tool could not verify the status of the current flutter checkout. '
        'This might be due to git not being installed or an internal error. '
        'If it is okay to ignore potential local changes, then re-run this '
        'command with --force.'
        '\nError: $error.'
      );
    }
    return false;
  }

  /// Returns the remote HEAD revision.
  ///
  /// Exits tool if there is no upstream.
  Future<String> fetchRemoteRevision() async {
    String revision;
    try {
      // Fetch upstream branch's commits and tags
      await processUtils.run(
        <String>['git', 'fetch', '--tags'],
        throwOnError: true,
        workingDirectory: workingDirectory,
      );
      // '@{u}' means upstream HEAD
      final RunResult result = await processUtils.run(
          <String>[ 'git', 'rev-parse', '--verify', '@{u}'],
          throwOnError: true,
          workingDirectory: workingDirectory,
      );
      revision = result.stdout.trim();
    } on Exception catch (e) {
      final String errorString = e.toString();
      if (errorString.contains('fatal: HEAD does not point to a branch')) {
        throwToolExit(
          'You are not currently on a release branch. Use git to '
          'check out an official branch (\'stable\', \'beta\', \'dev\', or \'master\') '
          'and retry, for example:\n'
          '  git checkout stable'
        );
      } else if (errorString.contains('fatal: no upstream configured for branch')) {
        throwToolExit(
          'Unable to upgrade Flutter: no origin repository configured. '
          'Run \'git remote add origin '
          'https://github.com/flutter/flutter\' in $workingDirectory');
      } else {
        throwToolExit(errorString);
      }
    }
    return revision;
  }

  /// Attempts to upgrade the channel.
  ///
  /// If the user is on a deprecated channel, attempts to migrate them off of
  /// it.
  Future<void> upgradeChannel(FlutterVersion flutterVersion) async {
    globals.printStatus('Upgrading Flutter from $workingDirectory...');
    await ChannelCommand.upgradeChannel();
  }

  /// Attempts a hard reset to the given revision.
  ///
  /// This is a reset instead of fast forward because if we are on a release
  /// branch with cherry picks, there may not be a direct fast-forward route
  /// to the next release.
  Future<void> attemptReset(String newRevision) async {
    try {
      await processUtils.run(
        <String>['git', 'reset', '--hard', newRevision],
        throwOnError: true,
        workingDirectory: workingDirectory,
      );
    } on ProcessException catch (e) {
      throwToolExit(e.message, exitCode: e.errorCode);
    }
  }

  /// Update the engine repository and precache all artifacts.
  ///
  /// Check for and download any engine and pkg/ updates. We run the 'flutter'
  /// shell script re-entrantly here so that it will download the updated
  /// Dart and so forth if necessary.
  Future<void> precacheArtifacts() async {
    globals.printStatus('');
    globals.printStatus('Upgrading engine...');
    final int code = await processUtils.stream(
      <String>[
        globals.fs.path.join('bin', 'flutter'), '--no-color', '--no-version-check', 'precache',
      ],
      workingDirectory: workingDirectory,
      allowReentrantFlutter: true,
      environment: Map<String, String>.of(globals.platform.environment),
    );
    if (code != 0) {
      throwToolExit(null, exitCode: code);
    }
  }

  /// Update the user's packages.
  Future<void> updatePackages(FlutterVersion flutterVersion) async {
    globals.printStatus('');
    globals.printStatus(flutterVersion.toString());
    final String projectRoot = findProjectRoot();
    if (projectRoot != null) {
      globals.printStatus('');
      await pub.get(
        context: PubContext.pubUpgrade,
        directory: projectRoot,
        upgrade: true,
        checkLastModified: false,
        generateSyntheticPackage: false,
      );
    }
  }

  /// Run flutter doctor in case requirements have changed.
  Future<void> runDoctor() async {
    globals.printStatus('');
    globals.printStatus('Running flutter doctor...');
    await processUtils.stream(
      <String>[
        globals.fs.path.join('bin', 'flutter'), '--no-version-check', 'doctor',
      ],
      workingDirectory: workingDirectory,
      allowReentrantFlutter: true,
    );
  }
}
