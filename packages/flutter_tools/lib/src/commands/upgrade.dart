// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/os.dart';
import '../base/process.dart';
import '../cache.dart';
import '../dart/pub.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../version.dart';
import 'channel.dart';

class UpgradeCommand extends FlutterCommand {
  UpgradeCommand() {
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
        help: 'For the second half of the upgrade flow requiring the new version of Flutter. Should not be invoked manually, but re-entrantly by the standard upgrade command.',
      );
  }

  @override
  final String name = 'upgrade';

  @override
  final String description = 'Upgrade your copy of Flutter.';

  @override
  bool get shouldUpdateCache => false;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.universal,
  };

  @override
  Future<FlutterCommandResult> runCommand() async {
    final UpgradeCommandRunner upgradeCommandRunner = UpgradeCommandRunner();
    await upgradeCommandRunner.runCommand(
      argResults['force'],
      argResults['continue'],
      GitTagVersion.determine(),
      FlutterVersion.instance,
    );
    return null;
  }
}


@visibleForTesting
class UpgradeCommandRunner {
  Future<FlutterCommandResult> runCommand(
    bool force,
    bool continueFlow,
    GitTagVersion gitTagVersion,
    FlutterVersion flutterVersion,
  ) async {
    if (!continueFlow) {
      await runCommandFirstHalf(force, gitTagVersion, flutterVersion);
    } else {
      await runCommandSecondHalf(flutterVersion);
    }
    return null;
  }

  Future<void> runCommandFirstHalf(
    bool force,
    GitTagVersion gitTagVersion,
    FlutterVersion flutterVersion,
  ) async {
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
    await resetChanges(gitTagVersion);
    await upgradeChannel(flutterVersion);
    await attemptFastForward();
    await flutterUpgradeContinue();
  }

  Future<void> flutterUpgradeContinue() async {
    final int code = await processUtils.stream(
      <String>[
        fs.path.join('bin', 'flutter'),
        'upgrade',
        '--continue',
        '--no-version-check',
      ],
      workingDirectory: Cache.flutterRoot,
      allowReentrantFlutter: true,
    );
    if (code != 0) {
      throwToolExit(null, exitCode: code);
    }
  }

  // This method should only be called if the upgrade command is invoked
  // re-entrantly with the `--continue` flag
  Future<void> runCommandSecondHalf(FlutterVersion flutterVersion) async {
    await precacheArtifacts();
    await updatePackages(flutterVersion);
    await runDoctor();
  }

  Future<bool> hasUncomittedChanges() async {
    try {
      final RunResult result = await processUtils.run(
        <String>['git', 'status', '-s'],
        throwOnError: true,
        workingDirectory: Cache.flutterRoot,
      );
      return result.stdout.trim().isNotEmpty;
    } on ProcessException catch (error) {
      throwToolExit(
        'The tool could not verify the status of the current flutter checkout. '
        'This might be due to git not being installed or an internal error.'
        'If it is okay to ignore potential local changes, then re-run this'
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
      await processUtils.run(
        <String>[ 'git', 'rev-parse', '@{u}'],
        throwOnError: true,
        workingDirectory: Cache.flutterRoot,
      );
    } catch (e) {
      throwToolExit(
        'Unable to upgrade Flutter: no origin repository configured. '
        'Run \'git remote add origin '
        'https://github.com/flutter/flutter\' in ${Cache.flutterRoot}',
      );
    }
  }

  /// Attempts to reset to the last known tag or branch. This should restore the
  /// history to something that is compatible with the regular upgrade
  /// process.
  Future<void> resetChanges(GitTagVersion gitTagVersion) async {
    // We only got here by using --force.
    String tag;
    if (gitTagVersion == const GitTagVersion.unknown()) {
      tag = 'v0.0.0';
    } else {
      tag = 'v${gitTagVersion.x}.${gitTagVersion.y}.${gitTagVersion.z}';
    }
    try {
      await processUtils.run(
        <String>['git', 'reset', '--hard', tag],
        throwOnError: true,
        workingDirectory: Cache.flutterRoot,
      );
    } on ProcessException catch (error) {
      throwToolExit(
        'Unable to upgrade Flutter: The tool could not update to the version $tag. '
        'This may be due to git not being installed or an internal error.'
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
    printStatus('Upgrading Flutter from ${Cache.flutterRoot}...');
    await ChannelCommand.upgradeChannel();
  }

  /// Attempts to rebase the upstream onto the local branch.
  ///
  /// If there haven't been any hot fixes or local changes, this is equivalent
  /// to a fast-forward.
  Future<void> attemptFastForward() async {
    final int code = await processUtils.stream(
      <String>['git', 'pull', '--ff'],
      workingDirectory: Cache.flutterRoot,
      mapFunction: (String line) => matchesGitLine(line) ? null : line,
    );
    if (code != 0) {
      throwToolExit(null, exitCode: code);
    }
  }

  /// Update the engine repository and precache all artifacts.
  ///
  /// Check for and download any engine and pkg/ updates. We run the 'flutter'
  /// shell script re-entrantly here so that it will download the updated
  /// Dart and so forth if necessary.
  Future<void> precacheArtifacts() async {
    printStatus('');
    printStatus('Upgrading engine...');
    final int code = await processUtils.stream(
      <String>[
        fs.path.join('bin', 'flutter'), '--no-color', '--no-version-check', 'precache',
      ],
      workingDirectory: Cache.flutterRoot,
      allowReentrantFlutter: true,
    );
    if (code != 0) {
      throwToolExit(null, exitCode: code);
    }
  }

  /// Update the user's packages.
  Future<void> updatePackages(FlutterVersion flutterVersion) async {
    printStatus('');
    printStatus(flutterVersion.toString());
    final String projectRoot = findProjectRoot();
    if (projectRoot != null) {
      printStatus('');
      await pubGet(context: PubContext.pubUpgrade, directory: projectRoot, upgrade: true, checkLastModified: false);
    }
  }

  /// Run flutter doctor in case requirements have changed.
  Future<void> runDoctor() async {
    printStatus('');
    printStatus('Running flutter doctor...');
    await processUtils.stream(
      <String>[
        fs.path.join('bin', 'flutter'), '--no-version-check', 'doctor',
      ],
      workingDirectory: Cache.flutterRoot,
      allowReentrantFlutter: true,
    );
  }

  //  dev/benchmarks/complex_layout/lib/main.dart        |  24 +-
  static final RegExp _gitDiffRegex = RegExp(r' (\S+)\s+\|\s+\d+ [+-]+');

  //  rename {packages/flutter/doc => dev/docs}/styles.html (92%)
  //  delete mode 100644 doc/index.html
  //  create mode 100644 examples/flutter_gallery/lib/gallery/demo.dart
  static final RegExp _gitChangedRegex = RegExp(r' (rename|delete mode|create mode) .+');

  static bool matchesGitLine(String line) {
    return _gitDiffRegex.hasMatch(line)
      || _gitChangedRegex.hasMatch(line)
      || line == 'Fast-forward';
  }
}
