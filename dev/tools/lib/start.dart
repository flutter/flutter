// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show jsonEncode;

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:fixnum/fixnum.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

import './globals.dart';
import './proto/conductor_state.pb.dart' as pb;
import './proto/conductor_state.pbenum.dart' show ReleasePhase;
import './repository.dart';
import './state.dart';
import './stdio.dart';

const String kCandidateOption = 'candidate-branch';
const String kReleaseOption = 'release-channel';
const String kStateOption = 'state-file';
const String kFrameworkOption = 'framework-upstream';
const String kEngineOption = 'engine-upstream';

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
      kFrameworkOption,
      defaultsTo: FrameworkRepository.defaultUpstream,
      help: 'Configurable Framework repo upstream. Primarily for testing.',
      hide: true,
    );
    argParser.addOption(
      kEngineOption,
      defaultsTo: EngineRepository.defaultUpstream,
      help: 'Configurable Engine repo upstream. Primarily for testing.',
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
    final String candidateBranch = argResults[kCandidateOption] as String;
    final File stateFile = checkouts.fileSystem.file(argResults['state-file']);
    if (stateFile.existsSync()) {
      throw ConductorException(
        'Error! A persistent state file already found at ${argResults[kStateOption]}.\n\n'
        'Run `conductor cleanup` to cancel a previous release.'
      );
    }
    if (!argResults.wasParsed(kReleaseOption)) {
      throw ConductorException(
          'The command line option `--$kReleaseOption` must be provided');
    }
    if (!argResults.wasParsed(kCandidateOption) || candidateBranch.trim().isEmpty) {
      throw ConductorException(
          'The command line option `--$kCandidateOption` must be provided');
    } else if (!releaseCandidateBranchRegex.hasMatch(candidateBranch)) {
      throw ConductorException(
        'Invalid release candidate branch "$candidateBranch". '
        'Text should match the regex pattern /${releaseCandidateBranchRegex.pattern}/.'
      );
    }
    final Int64 unixDate = Int64(DateTime.now().millisecondsSinceEpoch);
    final pb.ConductorState state = pb.ConductorState();

    state.releaseChannel = argResults[kReleaseOption] as String;
    state.createdDate = unixDate;
    state.lastUpdatedDate = unixDate;

    final EngineRepository engine = EngineRepository(
      checkouts,
      initialRef: candidateBranch,
    );
    final String engineHead = engine.reverseParse('HEAD');
    state.engine = pb.Repository(
      candidateBranch: candidateBranch,
      startingGitHead: engineHead,
      currentGitHead: engineHead,
      checkoutPath: engine.checkoutDirectory.path,
    );
    final FrameworkRepository framework = FrameworkRepository(
      checkouts,
      initialRef: candidateBranch,
    );
    final String frameworkHead = framework.reverseParse('HEAD');
    state.framework = pb.Repository(
      candidateBranch: candidateBranch,
      startingGitHead: frameworkHead,
      currentGitHead: frameworkHead,
      checkoutPath: framework.checkoutDirectory.path,
    );

    state.currentPhase = ReleasePhase.INITIALIZED;

    stdio.printTrace('Writing state to file ${stateFile.path}...');

    state.logs.addAll(stdio.logs);

    stateFile.writeAsStringSync(
      jsonEncode(state.toProto3Json()),
      flush: true,
    );

    presentState(stdio, state);
  }
}
