// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/time.dart';
import '../base/utils.dart';
import '../cache.dart';
import '../context/tool_context.dart';
import '../dart/pub.dart';
import '../git.dart';
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
  }) : _toolContext = toolContext,
       _commandRunner = commandRunner ?? UpgradeCommandRunner(toolContext: toolContext),
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

  final ToolContext _toolContext;
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
    final FileSystem fs = _toolContext.fs;
    final Git git = _toolContext.git;
    final Platform platform = _toolContext.platform;
    final FlutterVersion flutterVersion = _toolContext.flutterVersion;

    _commandRunner.workingDirectory =
        stringArg('working-directory') ?? _toolContext.cache.flutterRoot;
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
          : FlutterVersion(flutterRoot: _commandRunner.workingDirectory!, fs: fs, git: git),
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
  UpgradeCommandRunner({
    required ToolContext toolContext,
    PersistentToolState? persistentToolState,
    Pub? pub,
  }) : _toolContext = toolContext,
       _injectedPersistentToolState = persistentToolState,
       _injectedPub = pub;

  final ToolContext _toolContext;
  final PersistentToolState? _injectedPersistentToolState;
  final Pub? _injectedPub;

  PersistentToolState get _persistentToolState =>
      _injectedPersistentToolState ??
      PersistentToolState(
        fileSystem: _toolContext.fs,
        logger: _toolContext.logger,
        platform: _toolContext.platform,
      );

  Pub get _pub =>
      _injectedPub ??
      Pub(
        fileSystem: _toolContext.fs,
        logger: _toolContext.logger,
        processManager: _toolContext.processManager,
        platform: _toolContext.platform,
        botDetector: _toolContext.botDetector,
        stdio: _toolContext.stdio,
      );

  String? workingDirectory; // set in runCommand() above

  @visibleForTesting
  SystemClock get clock => _clock ?? _toolContext.systemClock;
  set clock(SystemClock value) => _clock = value;
  SystemClock? _clock;

  Future<FlutterCommandResult> runCommand(
    UpgradePhase phase, {
    required bool force,
    required bool testFlow,
    required GitTagVersion gitTagVersion,
    required FlutterVersion flutterVersion,
    required bool verifyOnly,
  }) async {
    final Logger logger = _toolContext.logger;
    switch (phase) {
      case _FirstHalf():
        await _runCommandFirstHalf(
          startedAt: clock.now(),
          force: force,
          gitTagVersion: gitTagVersion,
          flutterVersion: flutterVersion,
          testFlow: testFlow,
          verifyOnly: verifyOnly,
        );
      case _SecondHalf(:final DateTime? upgradeStartedAt):
        await _runCommandSecondHalf(flutterVersion);
        if (upgradeStartedAt != null) {
          final Duration execution = clock.now().difference(upgradeStartedAt);
          logger.printStatus('Took ${getElapsedAsMinutesOrSeconds(execution)}');
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
    final Logger logger = _toolContext.logger;
    final Git git = _toolContext.git;
    final Cache cache = _toolContext.cache;

    final FlutterVersion upstreamVersion = await fetchLatestVersion(localVersion: flutterVersion);
    // It's possible for a given framework revision to have multiple tags (i.e., due to a release
    // rollback). Verify the upstream version tag isn't newer than the current tag.
    if (flutterVersion.frameworkRevision == upstreamVersion.frameworkRevision &&
        flutterVersion.gitTagVersion.gitTag.compareTo(upstreamVersion.gitTagVersion.gitTag) >= 0) {
      logger.printStatus('Flutter is already up to date on channel ${flutterVersion.channel}');
      logger.printStatus('$flutterVersion');
      return;
    } else if (verifyOnly) {
      logger.printStatus(
        'A new version of Flutter is available on channel ${flutterVersion.channel}\n',
      );
      logger.printStatus(
        'The latest version: ${upstreamVersion.frameworkVersion} (revision ${upstreamVersion.frameworkRevisionShort})',
        emphasis: true,
      );
      logger.printStatus(
        'Your current version: ${flutterVersion.frameworkVersion} (revision ${flutterVersion.frameworkRevisionShort})\n',
      );
      logger.printStatus('To upgrade now, run "flutter upgrade".');
      if (flutterVersion.channel == 'stable') {
        logger.printStatus('\nSee the announcement and release notes:');
        logger.printStatus('https://docs.flutter.dev/release/release-notes');
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
    await ChannelCommand.upgradeChannel(flutterVersion, logger: logger, git: git, cache: cache);
    logger.printStatus(
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
    _persistentToolState.updateLastActiveVersion(flutterVersion.frameworkRevision, channel);
  }

  @visibleForTesting
  Future<void> flutterUpgradeContinue({required DateTime startedAt}) async {
    final FileSystem fs = _toolContext.fs;
    final Platform platform = _toolContext.platform;
    final ProcessUtils processUtils = _toolContext.processUtils;

    final int code = await processUtils.stream(
      [
        fs.path.join(workingDirectory ?? _toolContext.cache.flutterRoot, 'bin', 'flutter'),
        'upgrade',
        '--continue',
        '--continue-started-at',
        startedAt.toIso8601String(),
        '--no-version-check',
      ],
      allowReentrantFlutter: true,
      environment: Map<String, String>.of(platform.environment),
    );
    if (code != 0) {
      throwToolExit(null, exitCode: code);
    }
  }

  // This method should only be called if the upgrade command is invoked
  // re-entrantly with the `--continue` flag
  Future<void> _runCommandSecondHalf(FlutterVersion flutterVersion) async {
    final FileSystem fs = _toolContext.fs;
    final Logger logger = _toolContext.logger;
    final Platform platform = _toolContext.platform;
    final ProcessUtils processUtils = _toolContext.processUtils;

    // Make sure the welcome message re-display is delayed until the end.
    _persistentToolState.setShouldRedisplayWelcomeMessage(false);
    await precacheArtifacts(
      workingDirectory: workingDirectory,
      fileSystem: fs,
      logger: logger,
      platform: platform,
      processUtils: processUtils,
    );
    await updatePackages(flutterVersion);
    await runDoctor();
    // Force the welcome message to re-display following the upgrade.
    _persistentToolState.setShouldRedisplayWelcomeMessage(true);
    if (flutterVersion.channel == 'master' || flutterVersion.channel == 'main') {
      logger.printStatus(
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
    final Git git = _toolContext.git;
    try {
      final RunResult result = await git.run(
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
    final FileSystem fs = _toolContext.fs;
    final Git git = _toolContext.git;
    final Platform platform = _toolContext.platform;

    String revision;
    try {
      // Fetch upstream branch's commits and tags
      await git.run(['fetch', '--tags'], throwOnError: true, workingDirectory: workingDirectory);
      // Get the latest commit revision of the upstream
      final RunResult result = await git.run(
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
      platform: platform,
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
      fs: fs,
      git: git,
      platform: platform,
    );
  }

  /// Attempts a hard reset to the given revision.
  ///
  /// This is a reset instead of fast forward because if we are on a release
  /// branch with cherry picks, there may not be a direct fast-forward route
  /// to the next release.
  @visibleForTesting
  Future<void> attemptReset(String newRevision) async {
    final Git git = _toolContext.git;
    try {
      await git.run(
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
    final FileSystem fs = _toolContext.fs;
    final Logger logger = _toolContext.logger;

    logger.printStatus('');
    logger.printStatus(flutterVersion.toString());
    final String? projectRoot = findProjectRoot(fs);
    if (projectRoot != null) {
      logger.printStatus('');
      await _pub.get(
        context: PubContext.pubUpgrade,
        project: FlutterProject.fromDirectory(fs.directory(projectRoot)),
        upgrade: true,
      );
    }
  }

  /// Run flutter doctor in case requirements have changed.
  @protected
  Future<void> runDoctor() async {
    final FileSystem fs = _toolContext.fs;
    final Logger logger = _toolContext.logger;
    final ProcessUtils processUtils = _toolContext.processUtils;

    logger.printStatus('');
    logger.printStatus('Running flutter doctor...');
    await processUtils.stream(
      [fs.path.join('bin', 'flutter'), '--no-version-check', 'doctor'],
      workingDirectory: workingDirectory,
      allowReentrantFlutter: true,
    );
  }
}

Future<void> precacheArtifacts({
  String? workingDirectory,
  required FileSystem fileSystem,
  required Logger logger,
  required Platform platform,
  required ProcessUtils processUtils,
}) async {
  logger.printStatus('');
  logger.printStatus('Upgrading engine...');
  final int code = await processUtils.stream(
    <String>[
      fileSystem.path.join('bin', 'flutter'),
      '--no-color',
      '--no-version-check',
      'precache',
    ],
    allowReentrantFlutter: true,
    environment: Map<String, String>.of(platform.environment),
    workingDirectory: workingDirectory,
  );
  if (code != 0) {
    throwToolExit(null, exitCode: code);
  }
}
