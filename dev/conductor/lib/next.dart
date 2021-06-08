// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:convert' show jsonDecode;

import 'package:args/command_runner.dart';
import 'package:file/file.dart' show File;
import 'package:meta/meta.dart' show required, visibleForTesting;
import 'package:platform/platform.dart';

import './globals.dart';
import './proto/conductor_state.pb.dart' as pb;
import './proto/conductor_state.pbenum.dart' show CherrypickState;
import './repository.dart';
import './state.dart';
import './stdio.dart';

const String kStateOption = 'state-file';
const String kYesFlag = 'yes';

class NextCommand extends Command<void> {
  NextCommand({
    @required this.checkouts,
  }) : platform = checkouts.platform, stdio = checkouts.stdio {
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
  final Stdio stdio;

  bool get autoAccept => argResults[kYesFlag] as bool;

  @override
  String get name => 'next';

  @override
  String get description => 'Proceed to the next release phase.';

  @override
  void run() {
    const List<CherrypickState> finishedStates = <CherrypickState>[
      CherrypickState.COMPLETED,
      CherrypickState.ABANDONED,
    ];
    final File stateFile = checkouts.fileSystem.file(argResults[kStateOption]);
    if (!stateFile.existsSync()) {
      throw ConductorException(
        'No persistent state file found at ${argResults[kStateOption]}.',
      );
    }

    final pb.ConductorState state = readStateFromFile(stateFile);
    stdio.printTrace(state.toString());
    switch (state.lastPhase) {
      case pb.ReleasePhase.INITIALIZE:
        // At this time, the conductor tool will only know if a cherrypick has
        // been applied 
        bool allCherrypicksVerifiedApplied = true;
        for (final pb.Cherrypick cherrypick in state.engine.cherrypicks) {
          if (!finishedStates.contains(cherrypick.state)) {
            allCherrypicksVerifiedApplied = false;
            break;
          }
        }
        if (allCherrypicksVerifiedApplied == false) {
          final bool response = prompt('Did you apply all engine cherrypicks?');
          if (!response) {
            stdio.printError('Aborting command.');
            return;
          }
        }
        break;
      case pb.ReleasePhase.APPLY_ENGINE_CHERRYPICKS:
        if (platform.isMacOS) {
          throw ConductorException('TODO: actually test this'); // TODO
        } else {
          final bool response = prompt(
            'Have binaries for the engine commit been codesigned?',
          );
          if (!response) {
            stdio.printError('Aborting command.');
            return;
          }
        }
        break;
      case pb.ReleasePhase.CODESIGN_ENGINE_BINARIES:
        break;
      case pb.ReleasePhase.APPLY_FRAMEWORK_CHERRYPICKS:
        break;
      case pb.ReleasePhase.PUBLISH_VERSION:
        break;
      case pb.ReleasePhase.PUBLISH_CHANNEL:
        break;
      case pb.ReleasePhase.VERIFY_RELEASE:
        throw ConductorException('This release is finished.');
        break;
    }
    final pb.ReleasePhase nextPhase = getNextPhase(state.lastPhase);
    state.lastPhase = nextPhase;

    writeStateToFile(stateFile, state);
  }

  /// Prompt the user for a boolean value.
  ///
  /// If the force flag is provided, this method will immediately return true.
  /// Otherwise, it will print [message] and read a line from STDIN and check if
  /// it starts with a `y` or a `n`. This method will throw a
  /// [ConductorException] if the provided input matches neither.
  @visibleForTesting
  bool prompt(String message) {
    if (autoAccept) {
      return true;
    }
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
}
