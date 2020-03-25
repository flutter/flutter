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
      gitTagVersion: GitTagVersion.determine(globals.processUtils),
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
    await verifyUpstreamConfigured();
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
    await resetChanges(gitTagVersion);
    await upgradeChannel(flutterVersion);
    final bool alreadyUpToDate = await attemptFastForward(flutterVersion);
    if (alreadyUpToDate) {
      // If the upgrade was a no op, then do not continue with the second half.
      globals.printStatus('Flutter is already up to date on channel ${flutterVersion.channel}');
      globals.printStatus('$flutterVersion');
    } else if (!testFlow) {
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
    final int code = await globals.processUtils.stream(
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
      final RunResult result = await globals.processUtils.run(
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

  /// Check if there is an upstream repository configured.
  ///
  /// Exits tool if there is no upstream.
  Future<void> verifyUpstreamConfigured() async {
    try {
      await globals.processUtils.run(
        <String>[ 'git', 'rev-parse', '@{u}'],
        throwOnError: true,
        workingDirectory: workingDirectory,
      );
    } on Exception {
      throwToolExit(
        'Unable to upgrade Flutter: no origin repository configured. '
        "Run 'git remote add origin "
        "https://github.com/flutter/flutter' in $workingDirectory",
      );
    }
  }

  /// Attempts to reset to the last non-hotfix tag.
  ///
  /// If the git history is on a hotfix, doing a fast forward will not pick up
  /// major or minor version upgrades. By resetting to the point before the
  /// hotfix, doing a git fast forward should succeed.
  Future<void> resetChanges(GitTagVersion gitTagVersion) async {
    String tag;
    if (gitTagVersion == const GitTagVersion.unknown()) {
      tag = 'v0.0.0';
    } else {
      tag = 'v${gitTagVersion.x}.${gitTagVersion.y}.${gitTagVersion.z}';
    }
    try {
      await globals.processUtils.run(
        <String>['git', 'reset', '--hard', tag],
        throwOnError: true,
        workingDirectory: workingDirectory,
      );
    } on ProcessException catch (error) {
      throwToolExit(
        'Unable to upgrade Flutter: The tool could not update to the version $tag. '
        'This may be due to git not being installed or an internal error. '
        'Please ensure that git is installed on your computer and retry again.'
        '\nError: $error.'
      );
    }
  }

  /// Attempts to upgrade the channel.
  ///
  /// If the user is on a deprecated channel, attempts to migrate them off of
  /// it.
  Future<void> upgradeChannel(FlutterVersion flutterVersion) async {
    globals.printStatus('Upgrading Flutter from $workingDirectory...');
    await ChannelCommand.upgradeChannel();
  }

  /// Attempts to rebase the upstream onto the local branch.
  ///
  /// If there haven't been any hot fixes or local changes, this is equivalent
  /// to a fast-forward.
  ///
  /// If the fast forward lands us on the same channel and revision, then
  /// returns true, otherwise returns false.
  Future<bool> attemptFastForward(FlutterVersion oldFlutterVersion) async {
    final int code = await globals.processUtils.stream(
      <String>['git', 'pull', '--ff'],
      workingDirectory: workingDirectory,
      mapFunction: (String line) => matchesGitLine(line) ? null : line,
    );
    if (code != 0) {
      throwToolExit(null, exitCode: code);
    }

    // Check if the upgrade did anything.
    bool alreadyUpToDate = false;
    try {
      final FlutterVersion newFlutterVersion = FlutterVersion(const SystemClock(), workingDirectory);
      alreadyUpToDate = newFlutterVersion.channel == oldFlutterVersion.channel &&
        newFlutterVersion.frameworkRevision == oldFlutterVersion.frameworkRevision;
    } on Exception catch (e) {
      globals.printTrace('Failed to determine FlutterVersion after upgrade fast-forward: $e');
    }
    return alreadyUpToDate;
  }

  /// Update the engine repository and precache all artifacts.
  ///
  /// Check for and download any engine and pkg/ updates. We run the 'flutter'
  /// shell script re-entrantly here so that it will download the updated
  /// Dart and so forth if necessary.
  Future<void> precacheArtifacts() async {
    globals.printStatus('');
    globals.printStatus('Upgrading engine...');
    final int code = await globals.processUtils.stream(
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
      await pub.get(context: PubContext.pubUpgrade, directory: projectRoot, upgrade: true, checkLastModified: false);
    }
  }

  /// Run flutter doctor in case requirements have changed.
  Future<void> runDoctor() async {
    globals.printStatus('');
    globals.printStatus('Running flutter doctor...');
    await globals.processUtils.stream(
      <String>[
        globals.fs.path.join('bin', 'flutter'), '--no-version-check', 'doctor',
      ],
      workingDirectory: workingDirectory,
      allowReentrantFlutter: true,
    );
  }

  //  dev/benchmarks/complex_layout/lib/main.dart        |  24 +-
  static final RegExp _gitDiffRegex = RegExp(r' (\S+)\s+\|\s+\d+ [+-]+');

  //  rename {packages/flutter/doc => dev/docs}/styles.html (92%)
  //  delete mode 100644 doc/index.html
  //  create mode 100644 dev/integration_tests/flutter_gallery/lib/gallery/demo.dart
  static final RegExp _gitChangedRegex = RegExp(r' (rename|delete mode|create mode) .+');

  static bool matchesGitLine(String line) {
    return _gitDiffRegex.hasMatch(line)
      || _gitChangedRegex.hasMatch(line)
      || line == 'Fast-forward';
  }
}
