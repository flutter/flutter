// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:args/command_runner.dart';
import 'package:file/file.dart' show File;
import 'package:meta/meta.dart' show required, visibleForTesting;
import 'package:platform/platform.dart';

import './globals.dart';
import './proto/conductor_state.pb.dart' as pb;
import './proto/conductor_state.pbenum.dart';
import './repository.dart';
import './state.dart';
import './stdio.dart';

const String kStateOption = 'state-file';
const String kYesFlag = 'yes';

class NextCommand extends Command<void> {
  NextCommand({
    @required this.checkouts,
  })  : platform = checkouts.platform {
    final String defaultPath = defaultStateFilePath(platform);
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
  }

  final Checkouts checkouts;
  final Platform platform;

  @override
  String get name => 'next';

  @override
  String get description => 'Proceed to the next release phase.';

  @override
  void run() {
    runNext(
      autoAccept: argResults[kYesFlag] as bool,
      checkouts: checkouts,
      platform: platform,
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
  } else if (firstChar == 'N') {
    return false;
  } else {
    throw ConductorException(
      'Unknown user input (expected "y" or "n"): $response',
    );
  }
}

@visibleForTesting
void runNext({
  @required bool autoAccept,
  @required Checkouts checkouts,
  @required Platform platform,
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
      bool allEngineCherrypicksVerified = true;
      for (final pb.Cherrypick cherrypick in state.engine.cherrypicks) {
        if (!finishedStates.contains(cherrypick.state)) {
          allEngineCherrypicksVerified = false;
          break;
        }
      }
      // At this time, the conductor tool only knows about cherrypicks that it
      // has auto-applied. To proceed to the next phase when some cherrypicks
      // were applied manually, the user will have to confirm.
      if (allEngineCherrypicksVerified == false && autoAccept == false) {
        final bool response = prompt('Did you apply and merge all engine cherrypicks?', stdio);
        if (!response) {
          stdio.printError('Aborting command.');
          return;
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
          return;
        }
      }
      break;
    case pb.ReleasePhase.APPLY_FRAMEWORK_CHERRYPICKS:
      bool allFrameworkCherrypicksVerified = true;
      for (final pb.Cherrypick cherrypick in state.framework.cherrypicks) {
        if (!finishedStates.contains(cherrypick.state)) {
          allFrameworkCherrypicksVerified = false;
          break;
        }
      }
      if (allFrameworkCherrypicksVerified == false && autoAccept == false) {
        final bool response = prompt('Did you apply and merge all framework cherrypicks?', stdio);
        if (!response) {
          stdio.printError('Aborting command.');
          return;
        }
      }
      break;
    case pb.ReleasePhase.PUBLISH_VERSION:
      final Remote upstream = Remote(
        name: RemoteName.upstream,
        url: state.framework.upstream.url,
      );
      final FrameworkRepository framework = FrameworkRepository(
        checkouts,
        initialRef: state.framework.candidateBranch,
        fetchRemote: upstream,
      );
      final String headRevision = framework.reverseParse('HEAD');
      if (autoAccept == false) {
        final bool response = prompt(
          'Has CI passed for the framework PR?',
          stdio,
        );
        if (!response) {
          stdio.printError('Aborting command.');
          return;
        }
      }
      framework.tag(headRevision, state.releaseVersion, upstream.name);
      break;
    case pb.ReleasePhase.PUBLISH_CHANNEL:
      break;
    case pb.ReleasePhase.VERIFY_RELEASE:
      break;
    case pb.ReleasePhase.RELEASE_COMPLETED:
      throw ConductorException('This release is finished.');
      break;
  }
  final ReleasePhase nextPhase = getNextPhase(state.currentPhase);
  stdio.printStatus('Updating phase from ${state.currentPhase} to $nextPhase');
  state.currentPhase = nextPhase;

  writeStateToFile(stateFile, state);
}
