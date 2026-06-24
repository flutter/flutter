// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/io.dart';
import '../base/os.dart';
import '../base/process.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../context/tool_context.dart';
import '../dart/pub.dart';
import '../persistent_tool_state.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import '../version.dart';
import 'channel.dart';

// The official docs to install Flutter.
const _flutterInstallDocs = 'https://flutter.dev/setup';

class UpgradeCommand extends FlutterCommand {
  UpgradeCommand({
    required ToolContext toolContext,
    required bool verboseHelp,
    UpgradeCommandRunner? commandRunner,
  }) : _commandRunner = commandRunner ?? UpgradeCommandRunner(toolContext: toolContext),
       super(toolContext: toolContext) {
    argParser
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Force upgrade the flutter branch, potentially discarding local changes.',
        negatable: false,
      )
      ..addFlag(
        'continue',
        hide: !verboseHelp,
        help:
            'Trigger the second half of the upgrade flow. This should not be invoked '
            'manually. It is used re-entrantly by the standard upgrade command after '
            'the new version of Flutter is available, to hand off the upgrade process '
            'from the old version to the new version.',
      )
      ..addOption(
        'continue-started-at',
        hide: !verboseHelp,
        help:
            'If "--continue" is provided, an ISO 8601 timestamp of the time that the '
            'initial upgrade command was started. This should not be invoked manually.',
      )
      ..addOption(
        'working-directory',
        hide: !verboseHelp,
        help:
            'Override the upgrade working directory. '
            'This is only intended to enable integration testing of the tool itself.',
        // Also notably, this will override the FakeFlutterVersion if any is set!
      )
      ..addFlag(
        'verify-only',
        help: 'Checks for any new Flutter updates, without actually fetching them.',
        negatable: false,
      );
  }

  final UpgradeCommandRunner _commandRunner;

  @override
  final name = 'upgrade';

  @override
  final description = 'Upgrade your copy of Flutter.';

  @override
  final String category = FlutterCommandCategory.sdk;

  @override
  bool get shouldUpdateCache => false;

  UpgradePhase _parsePhaseFromContinueArg() {
    if (!boolArg('continue')) {
      return const UpgradePhase.firstHalf();
    } else {
      final DateTime? upgradeStartedAt;
      if (stringArg('continue-started-at') case final String iso8601String) {
        upgradeStartedAt = DateTime.parse(iso8601String);
      } else {
        upgradeStartedAt = null;
      }
      return UpgradePhase.secondHalf(upgradeStartedAt: upgradeStartedAt);
    }
  }

  @override
  Future<FlutterCommandResult> runCommand() {
    _commandRunner.workingDirectory = stringArg('working-directory') ?? Cache.flutterRoot!;
    return _commandRunner.runCommand(
      _parsePhaseFromContinueArg(),
      force: boolArg('force'),
      testFlow: stringArg('working-directory') != null,
      gitTagVersion: GitTagVersion.determine(
        platform,
        git: git,
        workingDirectory: _commandRunner.workingDirectory,
      ),
      flutterVersion: stringArg('working-directory') == null
          ? flutterVersion
          : FlutterVersion(flutterRoot: _commandRunner.workingDirectory!, fs: fileSystem, git: git),
      verifyOnly: boolArg('verify-only'),
    );
  }
}

@immutable
sealed class UpgradePhase {
  const factory UpgradePhase.firstHalf() = _FirstHalf;
  const factory UpgradePhase.secondHalf({required DateTime? upgradeStartedAt}) = _SecondHalf;
}

final class _FirstHalf implements UpgradePhase {
  const _FirstHalf();
}

final class _SecondHalf implements UpgradePhase {
  const _SecondHalf({required this.upgradeStartedAt});

  /// What time the original `flutter upgrade` command started at.
  ///
  /// If omitted, the initiating client was too old to know to pass this value.
  final DateTime? upgradeStartedAt;
}

@visibleForTesting
class UpgradeCommandRunner {
  UpgradeCommandRunner({required ToolContext toolContext}) : _toolContext = toolContext;

  final ToolContext _toolContext;

  String? workingDirectory; // set in runCommand() above

  Future<FlutterCommandResult> runCommand(
    UpgradePhase phase, {
    required bool force,
    required bool testFlow,
    required GitTagVersion gitTagVersion,
    required FlutterVersion flutterVersion,
    required bool verifyOnly,
  }) async {
    switch (phase) {
      case _FirstHalf():
        await _runCommandFirstHalf(
          startedAt: _toolContext.systemClock.now(),
          force: force,
          gitTagVersion: gitTagVersion,
          flutterVersion: flutterVersion,
          testFlow: testFlow,
          verifyOnly: verifyOnly,
        );
      case _SecondHalf(:final DateTime? upgradeStartedAt):
        await _runCommandSecondHalf(flutterVersion);
        if (upgradeStartedAt != null) {
          final Duration execution = _toolContext.systemClock.now().difference(upgradeStartedAt);
          _toolContext.logger.printStatus('Took ${getElapsedAsMinutesOrSeconds(execution)}');
        }
    }
    return FlutterCommandResult.success();
  }

  Future<void> _runCommandFirstHalf({
    required DateTime startedAt,
    required bool force,
    required GitTagVersion gitTagVersion,
    required FlutterVersion flutterVersion,
    required bool testFlow,
    required bool verifyOnly,
  }) async {
    final FlutterVersion upstreamVersion = await fetchLatestVersion(localVersion: flutterVersion);
    // It's possible for a given framework revision to have multiple tags (i.e., due to a release
    // rollback). Verify the upstream version tag isn't newer than the current tag.
    if (flutterVersion.frameworkRevision == upstreamVersion.frameworkRevision &&
        flutterVersion.gitTagVersion.gitTag.compareTo(upstreamVersion.gitTagVersion.gitTag) >= 0) {
      _toolContext.logger.printStatus(
        'Flutter is already up to date on channel ${flutterVersion.channel}',
      );
      _toolContext.logger.printStatus('$flutterVersion');
      return;
    } else if (verifyOnly) {
      _toolContext.logger.printStatus(
        'A new version of Flutter is available on channel ${flutterVersion.channel}\n',
      );
      _toolContext.logger.printStatus(
        'The latest version: ${upstreamVersion.frameworkVersion} (revision ${upstreamVersion.frameworkRevisionShort})',
        emphasis: true,
      );
      _toolContext.logger.printStatus(
        'Your current version: ${flutterVersion.frameworkVersion} (revision ${flutterVersion.frameworkRevisionShort})\n',
      );
      _toolContext.logger.printStatus('To upgrade now, run "flutter upgrade".');
      if (flutterVersion.channel == 'stable') {
        _toolContext.logger.printStatus('\nSee the announcement and release notes:');
        _toolContext.logger.printStatus('https://docs.flutter.dev/release/release-notes');
      }
      return;
    }
    if (!force && gitTagVersion == const GitTagVersion.unknown()) {
      // If the commit is a recognized branch and not master,
      // explain that we are avoiding potential damage.
      if (flutterVersion.channel != 'master' &&
          kOfficialChannels.contains(flutterVersion.channel)) {
        throwToolExit(
          'Unknown flutter tag. Abandoning upgrade to avoid destroying local '
          'changes. It is recommended to use git directly if not working on '
          'an official channel.',
        );
        // Otherwise explain that local changes can be lost.
      } else {
        throwToolExit(
          'Unknown flutter tag. Abandoning upgrade to avoid destroying local '
          'changes. If it is okay to remove local changes, then re-run this '
          'command with "--force".',
        );
      }
    }
    // If there are uncommitted changes we might be on the right commit but
    // we should still warn.
    if (!force && await hasUncommittedChanges(flutterVersion)) {
      throwToolExit(
        'Your flutter checkout has local changes that would be erased by '
        'upgrading. If you want to keep these changes, it is recommended that '
        'you stash them via "git stash" or else commit the changes to a local '
        'branch. If it is okay to remove local changes, then re-run this '
        'command with "--force".',
      );
    }
    recordState(flutterVersion);
    await ChannelCommand.upgradeChannel(
      currentVersion: flutterVersion,
      git: _toolContext.git,
      logger: _toolContext.logger,
    );
    _toolContext.logger.printStatus(
      'Upgrading Flutter to ${upstreamVersion.frameworkVersion} from ${flutterVersion.frameworkVersion} in $workingDirectory...',
    );
    await attemptReset(upstreamVersion.frameworkRevision);

    // Regenerate the version file based on the latest branch state during the second half.
    flutterVersion.deleteVersionFile();

    if (!testFlow) {
      await flutterUpgradeContinue(startedAt: startedAt);
    }
  }

  void recordState(FlutterVersion flutterVersion) {
    final Channel? channel = getChannelForName(flutterVersion.channel);
    if (channel == null) {
      return;
    }
    _toolContext.persistentToolState.updateLastActiveVersion(
      flutterVersion.frameworkRevision,
      channel,
    );
  }

  @visibleForTesting
  Future<void> flutterUpgradeContinue({required DateTime startedAt}) async {
    final int code = await _toolContext.processUtils.stream(
      [
        _toolContext.fs.path.join('bin', 'flutter'),
        'upgrade',
        '--continue',
        '--continue-started-at',
        startedAt.toIso8601String(),
        '--no-version-check',
      ],
      workingDirectory: workingDirectory,
      allowReentrantFlutter: true,
      environment: Map<String, String>.of(_toolContext.platform.environment),
    );
    if (code != 0) {
      throwToolExit(null, exitCode: code);
    }
  }

  // This method should only be called if the upgrade command is invoked
  // re-entrantly with the `--continue` flag
  Future<void> _runCommandSecondHalf(FlutterVersion flutterVersion) async {
    // Make sure the welcome message re-display is delayed until the end.
    final PersistentToolState persistentToolState = _toolContext.persistentToolState;
    persistentToolState.setShouldRedisplayWelcomeMessage(false);
    await precacheArtifacts(_toolContext, workingDirectory);
    await updatePackages(flutterVersion);
    await runDoctor();
    // Force the welcome message to re-display following the upgrade.
    persistentToolState.setShouldRedisplayWelcomeMessage(true);
    if (_toolContext.flutterVersion.channel == 'master' ||
        _toolContext.flutterVersion.channel == 'main') {
      _toolContext.logger.printStatus(
        '\n'
        'This channel is intended for Flutter contributors. '
        'This channel is not as thoroughly tested as the "beta" and "stable" channels. '
        'We do not recommend using this channel for normal use as it more likely to contain serious regressions.\n'
        '\n'
        'For information on contributing to Flutter, see our contributing guide:\n'
        '    https://github.com/flutter/flutter/blob/main/CONTRIBUTING.md\n'
        '\n'
        'For the most up to date stable version of flutter, consider using the "beta" channel instead. '
        'The Flutter "beta" channel enjoys all the same automated testing as the "stable" channel, '
        'but is updated roughly once a month instead of once a quarter.\n'
        'To change channel, run the "flutter channel beta" command.',
      );
    }
  }

  @protected
  @visibleForTesting
  Future<bool> hasUncommittedChanges(FlutterVersion version) async {
    try {
      final RunResult result = await _toolContext.git.run(
        ['status', '-s'],
        throwOnError: true,
        workingDirectory: workingDirectory,
      );
      final String output = result.stdout.trim();
      if (output.isEmpty) {
        return false;
      }

      // On non-stable channels, we ignore changes to pubspec.lock files.
      if (version.channel != 'stable') {
        final List<String> lines = output.split('\n');
        var hasOtherChanges = false;
        for (final line in lines) {
          final String trimmed = line.trim();
          if (trimmed.isEmpty) {
            continue;
          }
          // Check if the file is pubspec.lock. We check for a leading space or
          // directory separator to avoid matching files like 'another_pubspec.lock'.
          if (trimmed.endsWith(' pubspec.lock') || trimmed.endsWith('/pubspec.lock')) {
            continue;
          }
          hasOtherChanges = true;
          break;
        }
        return hasOtherChanges;
      }

      return true;
    } on ProcessException catch (error) {
      throwToolExit(
        'The tool could not verify the status of the current flutter checkout. '
        'This might be due to git not being installed or an internal error. '
        'If it is okay to ignore potential local changes, then re-run this '
        'command with "--force".\n'
        'Error: $error.',
      );
    }
  }

  /// Returns the remote HEAD flutter version.
  ///
  /// Exits tool if HEAD isn't pointing to a branch, or there is no upstream.
  @visibleForTesting
  Future<FlutterVersion> fetchLatestVersion({required FlutterVersion localVersion}) async {
    String revision;
    try {
      // Fetch upstream branch's commits and tags
      await _toolContext.git.run(
        ['fetch', '--tags'],
        throwOnError: true,
        workingDirectory: workingDirectory,
      );
      // Get the latest commit revision of the upstream
      final RunResult result = await _toolContext.git.run(
        ['rev-parse', '--verify', kGitTrackingUpstream],
        throwOnError: true,
        workingDirectory: workingDirectory,
      );
      revision = result.stdout.trim();
    } on Exception catch (e) {
      final errorString = e.toString();
      if (errorString.contains('fatal: HEAD does not point to a branch')) {
        throwToolExit(
          'Unable to upgrade Flutter: Your Flutter checkout is currently not '
          'on a release branch.\n'
          'Use "flutter channel" to switch to an official channel, and retry. '
          'Alternatively, re-install Flutter by going to $_flutterInstallDocs.',
        );
      } else if (errorString.contains('fatal: no upstream configured for branch')) {
        throwToolExit(
          'Unable to upgrade Flutter: The current Flutter branch/channel is '
          'not tracking any remote repository.\n'
          'Re-install Flutter by going to $_flutterInstallDocs.',
        );
      } else {
        throwToolExit(errorString);
      }
    }
    // At this point the current checkout should be on HEAD of a branch having
    // an upstream. Check whether this upstream is "standard".
    final VersionCheckError? error = VersionUpstreamValidator(
      version: localVersion,
      platform: _toolContext.platform,
    ).run();
    if (error != null) {
      throwToolExit(
        'Unable to upgrade Flutter: '
        '${error.message}\n'
        'Reinstalling Flutter may fix this issue. Visit $_flutterInstallDocs '
        'for instructions.',
      );
    }
    return FlutterVersion.fromRevision(
      flutterRoot: workingDirectory!,
      frameworkRevision: revision,
      fs: _toolContext.fs,
      git: _toolContext.git,
    );
  }

  /// Attempts a hard reset to the given revision.
  ///
  /// This is a reset instead of fast forward because if we are on a release
  /// branch with cherry picks, there may not be a direct fast-forward route
  /// to the next release.
  @visibleForTesting
  Future<void> attemptReset(String newRevision) async {
    try {
      await _toolContext.git.run(
        ['reset', '--hard', newRevision],
        throwOnError: true,
        workingDirectory: workingDirectory,
      );
    } on ProcessException catch (e) {
      throwToolExit(e.message, exitCode: e.errorCode);
    }
  }

  /// Update the user's packages.
  @protected
  Future<void> updatePackages(FlutterVersion flutterVersion) async {
    _toolContext.logger.printStatus('');
    _toolContext.logger.printStatus(flutterVersion.toString());
    final String? projectRoot = findProjectRoot(_toolContext.fs);
    if (projectRoot != null) {
      _toolContext.logger.printStatus('');
      await pub.get(
        context: PubContext.pubUpgrade,
        project: FlutterProject.fromDirectory(_toolContext.fs.directory(projectRoot)),
        upgrade: true,
      );
    }
  }

  /// Run flutter doctor in case requirements have changed.
  @protected
  Future<void> runDoctor() async {
    _toolContext.logger.printStatus('');
    _toolContext.logger.printStatus('Running flutter doctor...');
    await _toolContext.processUtils.stream(
      [_toolContext.fs.path.join('bin', 'flutter'), '--no-version-check', 'doctor'],
      workingDirectory: workingDirectory,
      allowReentrantFlutter: true,
    );
  }
}

/// Update the engine repository and precache all artifacts.
///
/// Check for and download any engine and pkg/ updates. We run the 'flutter'
/// shell script reentrantly here so that it will download the updated
/// Dart and so forth if necessary.
Future<void> precacheArtifacts(ToolContext toolContext, [String? workingDirectory]) async {
  toolContext.logger.printStatus('');
  toolContext.logger.printStatus('Upgrading engine...');
  final int code = await toolContext.processUtils.stream(
    [toolContext.fs.path.join('bin', 'flutter'), '--no-color', '--no-version-check', 'precache'],
    allowReentrantFlutter: true,
    environment: Map<String, String>.of(toolContext.platform.environment),
    workingDirectory: workingDirectory,
  );
  if (code != 0) {
    throwToolExit(null, exitCode: code);
  }
}
