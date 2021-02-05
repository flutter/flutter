// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:fixnum/fixnum.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

import './globals.dart';
import './proto/conductor_state.pb.dart' as pb;
import './repository.dart';
import './state.dart';
import './stdio.dart';

const String kCandidateOption = 'candidate-branch';
const String kReleaseOption = 'release-channel';
const String kStateOption = 'state-file';

/// Command to print the status of the current Flutter release.
class StartCommand extends Command<void> {
  StartCommand({
    @required this.checkouts,
    @required this.stdio,
  })  : platform = checkouts.platform,
        fileSystem = checkouts.fileSystem {
    final String defaultPath = defaultStateFilePath(platform);
    argParser.addOption(
      kCandidateOption,
      help: 'The candidate branch the release will be based on.',
    );
    argParser.addOption(
      kReleaseOption,
      help: 'The target release channel for the release.',
      allowed: <String>['stable', 'beta', 'dev'],
    );
    argParser.addOption(
      kStateOption,
      defaultsTo: defaultPath,
      help: 'Path to persistent state file. Defaults to $defaultPath',
    );
  }

  final Checkouts checkouts;
  final FileSystem fileSystem;
  final Platform platform;
  final Stdio stdio;

  @override
  String get name => 'start';

  @override
  String get description => 'Start a new Flutter release.';

  @override
  void run() {
    if (!argResults.wasParsed(kReleaseOption)) {
      throw ConductorException(
          'The command line option `--$kReleaseOption` must be provided');
    }
    if (!argResults.wasParsed(kCandidateOption)) {
      throw ConductorException(
          'The command line option `--$kCandidateOption` must be provided');
    } else if (!releaseCandidateBranchRegex.hasMatch(argResults[kCandidateOption] as String)) {
      throw ConductorException(
        'Invalid release candidate branch "${argResults[kCandidateOption]}". '
        'Text should match the regex pattern /${releaseCandidateBranchRegex.pattern}/.'
      );
    }
    final File stateFile = checkouts.fileSystem.file(argResults['state-file']);
    if (stateFile.existsSync()) {
      throw ConductorException(
        'Error! A persistent state file already found at ${argResults[kStateOption]}.\n\n'
        'Run `conductor abort` to cancel a previous release.'
      );
    }
    final Int64 unixDate = Int64(DateTime.now().millisecondsSinceEpoch);
    final pb.ConductorState state = pb.ConductorState();

    state.releaseChannel = argResults[kReleaseOption] as String;
    state.createdDate = unixDate;
    state.lastUpdatedDate = unixDate;
    state.framework = pb.Repository(candidateBranch: argResults[kCandidateOption] as String);
    state.engine = pb.Repository(candidateBranch: argResults[kCandidateOption] as String);

    stdio.printTrace('Writing state to file ${stateFile.path}...');
    stateFile.writeAsStringSync(state.writeToJson(), flush: true);
  }
}
