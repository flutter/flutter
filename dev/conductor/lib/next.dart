// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:args/command_runner.dart';
import 'package:file/file.dart' show File;
import 'package:meta/meta.dart' show required, visibleForTesting;
import './globals.dart';
import './proto/conductor_state.pb.dart' as pb;
import './proto/conductor_state.pbenum.dart';
import './repository.dart';
import './state.dart';
import './stdio.dart';

const String kStateOption = 'state-file';
const String kYesFlag = 'yes';
const String kForceFlag = 'force';

/// Command to proceed from one [pb.ReleasePhase] to the next.
class NextCommand extends Command<void> {
  NextCommand({
    @required this.checkouts,
  }) {
    final String defaultPath = defaultStateFilePath(checkouts.platform);
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
  void run() {
    runNext(
      autoAccept: argResults[kYesFlag] as bool,
      checkouts: checkouts,
      force: argResults[kForceFlag] as bool,
      stateFile: checkouts.fileSystem.file(argResults[kStateOption]),
    );
  }
}

@visibleForTesting
bool prompt(String message, Stdio stdio) {
  stdio.write('${message.trim()} (y/n) ');
  final String response = stdio.readLineSync().trim();
  final String firstChar = response[0].toUpperCase();
  if (firstChar == 'Y') {
    return true;
  }
  if (firstChar == 'N') {
    return false;
  }
  throw ConductorException(
    'Unknown user input (expected "y" or "n"): $response',
  );
}

@visibleForTesting
void runNext({
  @required bool autoAccept,
  @required bool force,
  @required Checkouts checkouts,
  @required File stateFile,
}) {
  final Stdio stdio = checkouts.stdio;
  const List<CherrypickState> finishedStates = <CherrypickState>[
    CherrypickState.COMPLETED,
    CherrypickState.ABANDONED,
  ];
  if (!stateFile.existsSync()) {
    throw ConductorException(
      'No persistent state file found at ${stateFile.path}.',
    );
  }

  final pb.ConductorState state = readStateFromFile(stateFile);

  switch (state.currentPhase) {
    case pb.ReleasePhase.APPLY_ENGINE_CHERRYPICKS:
      final List<pb.Cherrypick> unappliedCherrypicks = <pb.Cherrypick>[];
      for (final pb.Cherrypick cherrypick in state.engine.cherrypicks) {
        if (!finishedStates.contains(cherrypick.state)) {
          unappliedCherrypicks.add(cherrypick);
        }
      }

      if (state.engine.cherrypicks.isEmpty) {
        stdio.printStatus('This release has no engine cherrypicks.');
        break;
      } else if (unappliedCherrypicks.isEmpty) {
        stdio.printStatus('All engine cherrypicks have been auto-applied by '
            'the conductor.\n');
        if (autoAccept == false) {
          final bool response = prompt(
            'Are you ready to push your changes to the repository '
            '${state.engine.mirror.url}?',
            stdio,
          );
          if (!response) {
            stdio.printError('Aborting command.');
            writeStateToFile(stateFile, state, stdio.logs);
            return;
          }
        }
      } else {
        stdio.printStatus(
          'There were ${unappliedCherrypicks.length} cherrypicks that were not auto-applied.');
        stdio.printStatus('These must be applied manually in the directory '
          '${state.engine.checkoutPath} before proceeding.\n');
        if (autoAccept == false) {
          final bool response = prompt(
              'Are you ready to push your engine branch to the repository '
              '${state.engine.mirror.url}?',
            stdio,
          );
          if (!response) {
            stdio.printError('Aborting command.');
            writeStateToFile(stateFile, state, stdio.logs);
            return;
          }
        }
      }
      break;
    case pb.ReleasePhase.CODESIGN_ENGINE_BINARIES:
      if (autoAccept == false) {
        // TODO(fujino): actually test if binaries have been codesigned on macOS
        final bool response = prompt(
          'Has CI passed for the engine PR and binaries been codesigned?',
          stdio,
        );
        if (!response) {
          stdio.printError('Aborting command.');
          writeStateToFile(stateFile, state, stdio.logs);
          return;
        }
      }
      break;
    case pb.ReleasePhase.APPLY_FRAMEWORK_CHERRYPICKS:
      final List<pb.Cherrypick> unappliedCherrypicks = <pb.Cherrypick>[];
      for (final pb.Cherrypick cherrypick in state.framework.cherrypicks) {
        if (!finishedStates.contains(cherrypick.state)) {
          unappliedCherrypicks.add(cherrypick);
        }
      }

      if (state.framework.cherrypicks.isEmpty) {
        stdio.printStatus('This release has no framework cherrypicks.');
        break;
      } else if (unappliedCherrypicks.isEmpty) {
        stdio.printStatus('All framework cherrypicks have been auto-applied by '
            'the conductor.\n');
        if (autoAccept == false) {
          final bool response = prompt(
            'Are you ready to push your changes to the repository '
            '${state.framework.mirror.url}?',
            stdio,
          );
          if (!response) {
            stdio.printError('Aborting command.');
            writeStateToFile(stateFile, state, stdio.logs);
            return;
          }
        }
      } else {
        stdio.printStatus(
          'There were ${unappliedCherrypicks.length} cherrypicks that were not auto-applied.');
        stdio.printStatus('These must be applied manually in the directory '
          '${state.framework.checkoutPath} before proceeding.\n');
        if (autoAccept == false) {
          final bool response = prompt(
              'Are you ready to push your framework branch to the repository '
              '${state.framework.mirror.url}?',
            stdio,
          );
          if (!response) {
            stdio.printError('Aborting command.');
            writeStateToFile(stateFile, state, stdio.logs);
            return;
          }
        }
      }
      break;
    case pb.ReleasePhase.PUBLISH_VERSION:
      stdio.printStatus('Please ensure that you have merged your framework PR and that');
      stdio.printStatus('post-submit CI has finished successfully.\n');
      final Remote upstream = Remote(
        name: RemoteName.upstream,
        url: state.framework.upstream.url,
      );
      final FrameworkRepository framework = FrameworkRepository(
        checkouts,
        initialRef: state.framework.candidateBranch,
        upstreamRemote: upstream,
        previousCheckoutLocation: state.framework.checkoutPath,
      );
      final String headRevision = framework.reverseParse('HEAD');
      if (autoAccept == false) {
        final bool response = prompt(
          'Has CI passed for the framework PR?',
          stdio,
        );
        if (!response) {
          stdio.printError('Aborting command.');
          writeStateToFile(stateFile, state, stdio.logs);
          return;
        }
      }
      framework.tag(headRevision, state.releaseVersion, upstream.name);
      break;
    case pb.ReleasePhase.PUBLISH_CHANNEL:
      final Remote upstream = Remote(
        name: RemoteName.upstream,
        url: state.framework.upstream.url,
      );
      final FrameworkRepository framework = FrameworkRepository(
        checkouts,
        initialRef: state.framework.candidateBranch,
        upstreamRemote: upstream,
        previousCheckoutLocation: state.framework.checkoutPath,
      );
      final String headRevision = framework.reverseParse('HEAD');
      if (autoAccept == false) {
        final bool response = prompt(
            'Are you ready to publish release ${state.releaseVersion} to '
            'channel ${state.releaseChannel} at ${state.framework.upstream.url}?',
          stdio,
        );
        if (!response) {
          stdio.printError('Aborting command.');
          writeStateToFile(stateFile, state, stdio.logs);
          return;
        }
      }
      framework.updateChannel(
        headRevision,
        state.framework.upstream.url,
        state.releaseChannel,
        force: force,
      );
      break;
    case pb.ReleasePhase.VERIFY_RELEASE:
      stdio.printStatus(
        'The current status of packaging builds can be seen at:\n'
        '\t$kLuciPackagingConsoleLink',
      );
      if (autoAccept == false) {
        final bool response = prompt(
          'Have all packaging builds finished successfully?',
          stdio,
        );
        if (!response) {
          stdio.printError('Aborting command.');
          writeStateToFile(stateFile, state, stdio.logs);
          return;
        }
      }
      break;
    case pb.ReleasePhase.RELEASE_COMPLETED:
      throw ConductorException('This release is finished.');
      break;
  }
  final ReleasePhase nextPhase = getNextPhase(state.currentPhase);
  stdio.printStatus('\nUpdating phase from ${state.currentPhase} to $nextPhase...\n');
  state.currentPhase = nextPhase;
  stdio.printStatus(phaseInstructions(state));

  writeStateToFile(stateFile, state, stdio.logs);
}
