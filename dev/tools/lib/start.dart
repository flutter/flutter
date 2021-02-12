// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show jsonEncode;

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:fixnum/fixnum.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import './git.dart';
import './globals.dart';
import './proto/conductor_state.pb.dart' as pb;
import './proto/conductor_state.pbenum.dart' show ReleasePhase;
import './repository.dart';
import './state.dart';
import './stdio.dart';

const String kCandidateOption = 'candidate-branch';
const String kReleaseOption = 'release-channel';
const String kStateOption = 'state-file';
const String kFrameworkMirrorOption = 'framework-mirror';
const String kEngineMirrorOption = 'engine-mirror';
const String kFrameworkUpstreamOption = 'framework-upstream';
const String kEngineUpstreamOption = 'engine-upstream';

/// Command to print the status of the current Flutter release.
class StartCommand extends Command<void> {
  StartCommand({
    @required this.checkouts,
    @required this.flutterRoot,
  })  : platform = checkouts.platform,
        processManager = checkouts.processManager,
        fileSystem = checkouts.fileSystem,
        stdio = checkouts.stdio {
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
      kFrameworkUpstreamOption,
      defaultsTo: FrameworkRepository.defaultUpstream,
      help:
          'Configurable Framework repo upstream remote. Primarily for testing.',
      hide: true,
    );
    argParser.addOption(
      kEngineUpstreamOption,
      defaultsTo: EngineRepository.defaultUpstream,
      help: 'Configurable Engine repo upstream remote. Primarily for testing.',
      hide: true,
    );
    argParser.addOption(
      kFrameworkMirrorOption,
      help: 'Framework repo mirror remote.',
    );
    argParser.addOption(
      kEngineMirrorOption,
      help: 'Engine repo mirror remote.',
    );
    argParser.addOption(
      kStateOption,
      defaultsTo: defaultPath,
      help: 'Path to persistent state file. Defaults to $defaultPath',
    );

    final Git git = Git(processManager);
    conductorVersion = git.getOutput(
      <String>['rev-parse', 'HEAD'],
      'look up the current revision.',
      workingDirectory: flutterRoot.path,
    ).trim();

    assert(conductorVersion.isNotEmpty);
  }

  final Checkouts checkouts;

  /// The root directory of the Flutter repository that houses the Conductor.
  ///
  /// This directory is used to check the git revision of the Conductor.
  final Directory flutterRoot;
  final FileSystem fileSystem;
  final Platform platform;
  final ProcessManager processManager;
  final Stdio stdio;

  /// Git revision for the currently running Conductor.
  String conductorVersion;

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
          'Run `conductor cleanup` to cancel a previous release.');
    }
    final List<String> requiredArgs = <String>[
      kFrameworkMirrorOption,
      kEngineMirrorOption,
      kReleaseOption,
      kCandidateOption,
    ];
    for (final String arg in requiredArgs) {
      if (!argResults.wasParsed(arg)) {
        throw ConductorException(
            'The command line option `--$arg` must be provided -> ${argResults[arg]}');
      }
    }
    if (!releaseCandidateBranchRegex.hasMatch(candidateBranch)) {
      throw ConductorException(
          'Invalid release candidate branch "$candidateBranch". '
          'Text should match the regex pattern /${releaseCandidateBranchRegex.pattern}/.');
    }

    final Int64 unixDate = Int64(DateTime.now().millisecondsSinceEpoch);
    final pb.ConductorState state = pb.ConductorState();

    state.releaseChannel = argResults[kReleaseOption] as String;
    state.createdDate = unixDate;
    state.lastUpdatedDate = unixDate;

    final EngineRepository engine = EngineRepository(
      checkouts,
      initialRef: candidateBranch,
      pushRemote: Remote(
        name: RemoteName.mirror,
        url: argResults[kEngineMirrorOption] as String,
      ),
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

    state.lastPhase = ReleasePhase.INITIALIZED;

    state.conductorVersion = conductorVersion;

    stdio.printTrace('Writing state to file ${stateFile.path}...');

    state.logs.addAll(stdio.logs);

    stateFile.writeAsStringSync(
      jsonEncode(state.toProto3Json()),
      flush: true,
    );

    presentState(stdio, state);
  }
}
