// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/file_system.dart';
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
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'force upgrade the flutter branch, potentially discarding local changes.',
      negatable: false,
    );
  }

  @override
  final String name = 'upgrade';

  @override
  final String description = 'Upgrade your copy of Flutter.';

  @override
  bool get shouldUpdateCache => false;

  @override
  Future<FlutterCommandResult> runCommand() async {
    final UpgradeCommandRunner upgradeCommandRunner = UpgradeCommandRunner();
    await upgradeCommandRunner.runCommand(argResults['force'], GitTagVersion.determine(), FlutterVersion.instance);
    return null;
  }
}


@visibleForTesting
class UpgradeCommandRunner {
  Future<FlutterCommandResult> runCommand(bool force, GitTagVersion gitTagVersion, FlutterVersion flutterVersion) async {
    await verifyUpstreamConfigured();
    if (!force && gitTagVersion == const GitTagVersion.unknown()) {
      // If the commit is a recognized branch and not master,
      // explain that we are avoiding potential damage.
      if (flutterVersion.channel != 'master' && FlutterVersion.officialChannels.contains(flutterVersion.channel)) {
        throwToolExit(
          'Unknown flutter tag. Abandoning upgrade to avoid destroying local '
          'changes. It is recommended to use git directly if not working off of '
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
    final String stashName = await maybeStash(gitTagVersion);
    await upgradeChannel(flutterVersion);
    await attemptRebase();
    await precacheArtifacts();
    await updatePackages(flutterVersion);
    await runDoctor();
    await applyStash(stashName);
    return null;
  }

  /// Check if there is an upstream repository configured.
  ///
  /// Exits tool if there is no upstream.
  Future<void> verifyUpstreamConfigured() async {
    try {
      await runCheckedAsync(<String>[
        'git', 'rev-parse', '@{u}',
      ], workingDirectory: Cache.flutterRoot);
    } catch (e) {
      throwToolExit(
        'Unable to upgrade Flutter: no upstream repository configured. '
        'Run \'git remote add upstream '
        'https://github.com/flutter/flutter\' in ${Cache.flutterRoot}',
      );
    }
  }

  /// Attempt to stash any local changes.
  ///
  /// Returns the stash name if any changes were stashed. Exits tool if
  /// `git stash` returns a non-zero exit code.
  Future<String> maybeStash(GitTagVersion gitTagVersion) async {
    try {
      final RunResult runResult = await runCheckedAsync(<String>[
        'git', 'status', '-s',
      ]);
      // If there are no local changes, skip the stash.
      if (runResult.stdout.trim().isEmpty) {
        return null;
      }
    } catch (e) {
      throwToolExit('Failed to check git status: $e');
    }
    final String stashName = 'flutter-upgrade-from-v${gitTagVersion.x}.${gitTagVersion.y}.${gitTagVersion.z}';
    try {
      final RunResult runResult = await runCheckedAsync(<String>[
        'git', 'stash', 'push', '-m', stashName
      ]);
      // output message will contain stash name if any changes were stashed..
      if (runResult.stdout.contains(stashName)) {
        return stashName;
      }
    } catch (e) {
      throwToolExit('Failed to stash local changes: $e');
    }
    return null;
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
  Future<void> attemptRebase() async {
    final int code = await runCommandAndStreamOutput(
      <String>['git', 'pull', '--rebase'],
      workingDirectory: Cache.flutterRoot,
      mapFunction: (String line) => matchesGitLine(line) ? null : line,
    );
    if (code != 0) {
      printError('git rebase failed');
      final int undoCode = await runCommandAndStreamOutput(
        <String>['git', 'rebase', '--abort'],
        workingDirectory: Cache.flutterRoot,
        mapFunction: (String line) => matchesGitLine(line) ? null : line,
      );
      if (undoCode != 0) {
        printError(
          'Failed to apply rebase: The flutter installation at'
          ' ${Cache.flutterRoot} may be corrupted. A reinstallation of Flutter '
          'is recommended'
        );
      }
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
    final int code = await runCommandAndStreamOutput(
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
    await runCommandAndStreamOutput(
      <String>[
        fs.path.join('bin', 'flutter'), '--no-version-check', 'doctor',
      ],
      workingDirectory: Cache.flutterRoot,
      allowReentrantFlutter: true,
    );
  }

  /// Pop stash changes if [stashName] is non-null and contained in stash.
  Future<void> applyStash(String stashName) async {
    if (stashName == null) {
      return;
    }
    try {
      final RunResult result = await runCheckedAsync(<String>[
        'git', 'stash', 'list'
      ]);
      if (!result.stdout.contains(stashName)) {
        // print the same warning as if this threw.
        throw Exception();
      }
      await runCheckedAsync(<String>[
        'git', 'stash', 'pop',
      ]);
    } catch (e) {
      printError('Failed to re-apply local changes. State may have been lost.');
    }
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
