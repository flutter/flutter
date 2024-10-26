// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/file.dart' show File;
import 'package:meta/meta.dart' show visibleForTesting;

import 'context.dart';
import 'enums.dart';
import 'git.dart';
import 'globals.dart';
import 'repository.dart';
import 'state.dart' as state_import;

const String kStateOption = 'state-file';
const String kYesFlag = 'yes';

/// Command to proceed from one [pb.ReleasePhase] to the next.
///
/// After `conductor start`, the rest of the release steps are initiated by the
/// user via `conductor next`. Thus this command's behavior is conditional upon
/// which phase of the release the user is currently in. This is implemented
/// with a switch case statement.
class NextCommand extends Command<void> {
  NextCommand({
    required this.checkouts,
  }) {
    final String defaultPath = state_import.defaultStateFilePath(checkouts.platform);
    argParser.addOption(
      kStateOption,
      defaultsTo: defaultPath,
      help: 'Path to persistent state file. Defaults to $defaultPath',
    );
    argParser.addFlag(
      kYesFlag,
      help: 'Auto-accept any confirmation prompts.',
      hide: true, // primarily for integration testing
    );
    argParser.addFlag(
      kForceFlag,
      help: 'Force push when updating remote git branches.',
    );
  }

  final Checkouts checkouts;

  @override
  String get name => 'next';

  @override
  String get description => 'Proceed to the next release phase.';

  @override
  Future<void> run() async {
    final File stateFile = checkouts.fileSystem.file(argResults![kStateOption]);
    if (!stateFile.existsSync()) {
      throw ConductorException(
          'No persistent state file found at ${stateFile.path}.',
      );
    }
    final ConductorState state = state_import.readStateFromFile(stateFile);

    await NextContext(
      autoAccept: argResults![kYesFlag] as bool,
      checkouts: checkouts,
      force: argResults![kForceFlag] as bool,
      stateFile: stateFile,
    ).run(state);
  }
}

/// Utility class for proceeding to the next step in a release.
///
/// Any calls to functions that cause side effects are wrapped in methods to
/// allow overriding in unit tests.
class NextContext extends Context {
  const NextContext({
    required this.autoAccept,
    required this.force,
    required super.checkouts,
    required super.stateFile,
  });

  final bool autoAccept;
  final bool force;

  Future<void> run(ConductorState state) async {
    switch (state.currentPhase) {
      case ReleasePhase.VERIFY_ENGINE_CI:
        stdio.printStatus('You must validate post-submit CI for your engine PR and merge it');
        if (!autoAccept) {
          final bool response = await prompt(
            'Has CI passed for the engine PR?\n\n'
            '${state_import.luciConsoleLink(state.releaseChannel, 'engine')}'
          );
          if (!response) {
            stdio.printError('Aborting command.');
            updateState(state, stdio.logs);
            return;
          }
        }

      case ReleasePhase.PUBLISH_VERSION:
        final String command = '''
          tool-proxy-cli --tool_proxy=/abns/dart-eng-tool-proxy/prod-dart-eng-tool-proxy-tool-proxy.annealed-tool-proxy \\
          --block_on_mpa -I flutter_release \\
          :git_branch ${state.framework.candidateBranch} \\
          :release_channel ${state.releaseChannel} \\
          :tag ${state.releaseVersion} \\
          :force false
        ''';
        stdio.printStatus('Please ensure that you have merged your framework PR');
        stdio.printStatus('and post-submit CI has finished successfully.\n');
        stdio.printStatus('Run the following command, and ask a Googler');
        stdio.printStatus('to review the request\n\n$command');

      case ReleasePhase.VERIFY_RELEASE:
        stdio.printStatus(
            'The current status of packaging builds can be seen at:\n'
            '\t$kLuciPackagingConsoleLink',
        );
        if (!autoAccept) {
          final bool response = await prompt(
              'Have all packaging builds finished successfully and post release announcements been completed?');
          if (!response) {
            stdio.printError('Aborting command.');
            updateState(state, stdio.logs);
            return;
          }
        }

      case ReleasePhase.RELEASE_COMPLETED:
        throw ConductorException('This release is finished.');
    }
    final ReleasePhase getNextPhase = nextPhase(state.currentPhase);
    stdio.printStatus('\nUpdating phase from ${state.currentPhase} to $getNextPhase...\n');
    state.currentPhase = getNextPhase;
    stdio.printStatus(state_import.phaseInstructions(state));

    updateState(state, stdio.logs);
  }

  /// Push the working branch to the user's mirror.
  ///
  /// [repository] represents the actual Git repository on disk, and is used to
  /// call `git push`, while [pbRepository] represents the user-specified
  /// configuration for the repository, and is used to read the name of the
  /// working branch and the mirror's remote name.
  ///
  /// May throw either a [ConductorException] if the user already has a branch
  /// of the same name on their mirror, or a [GitException] for any other
  /// failures from the underlying git process call.
  @visibleForTesting
  Future<void> pushWorkingBranch(Repository repository, RepositoryState repoState) async {
    try {
      await repository.pushRef(
          fromRef: 'HEAD',
          // Explicitly create new branch
          toRef: 'refs/heads/${repoState.workingBranch}',
          remote: repoState.mirror.name,
          force: force,
      );
    } on GitException catch (exception) {
      if (exception.type == GitExceptionType.PushRejected && !force) {
        throw ConductorException(
          'Push failed because the working branch named '
          '${repoState.workingBranch} already exists on your mirror. '
          'Re-run this command with --force to overwrite the remote branch.\n'
          '${exception.message}',
        );
      }
      rethrow;
    }
  }
}
