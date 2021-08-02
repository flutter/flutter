// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:fixnum/fixnum.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import './git.dart';
import './globals.dart';
import './proto/conductor_state.pb.dart' as pb;
import './proto/conductor_state.pbenum.dart' show ReleasePhase;
import './repository.dart';
import './state.dart';
import './stdio.dart';
import './version.dart';

const String kCandidateOption = 'candidate-branch';
const String kDartRevisionOption = 'dart-revision';
const String kEngineCherrypicksOption = 'engine-cherrypicks';
const String kEngineUpstreamOption = 'engine-upstream';
const String kFrameworkCherrypicksOption = 'framework-cherrypicks';
const String kFrameworkMirrorOption = 'framework-mirror';
const String kFrameworkUpstreamOption = 'framework-upstream';
const String kIncrementOption = 'increment';
const String kEngineMirrorOption = 'engine-mirror';
const String kReleaseOption = 'release-channel';
const String kStateOption = 'state-file';

/// Command to print the status of the current Flutter release.
class StartCommand extends Command<void> {
  StartCommand({
    required this.checkouts,
    required this.flutterRoot,
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
    argParser.addMultiOption(
      kEngineCherrypicksOption,
      help: 'Engine cherrypick hashes to be applied.',
      defaultsTo: <String>[],
    );
    argParser.addMultiOption(
      kFrameworkCherrypicksOption,
      help: 'Framework cherrypick hashes to be applied.',
      defaultsTo: <String>[],
    );
    argParser.addOption(
      kDartRevisionOption,
      help: 'New Dart revision to cherrypick.',
    );
    argParser.addOption(
      kIncrementOption,
      help: 'Specifies which part of the x.y.z version number to increment. Required.',
      valueHelp: 'level',
      allowed: <String>['y', 'z', 'm', 'n'],
      allowedHelp: <String, String>{
        'y': 'Indicates the first dev release after a beta release.',
        'z': 'Indicates a hotfix to a stable release.',
        'm': 'Indicates a standard dev release.',
        'n': 'Indicates a hotfix to a dev or beta release.',
      },
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
  late final String conductorVersion;

  @override
  String get name => 'start';

  @override
  String get description => 'Initialize a new Flutter release.';

  @override
  void run() {
    final ArgResults argumentResults = argResults!;
    if (!platform.isMacOS && !platform.isLinux) {
      throw ConductorException(
        'Error! This tool is only supported on macOS and Linux',
      );
    }

    final File stateFile = checkouts.fileSystem.file(
      getValueFromEnvOrArgs(kStateOption, argumentResults, platform.environment),
    );
    if (stateFile.existsSync()) {
      throw ConductorException(
          'Error! A persistent state file already found at ${argResults![kStateOption]}.\n\n'
          'Run `conductor clean` to cancel a previous release.');
    }
    final String frameworkUpstream = getValueFromEnvOrArgs(
      kFrameworkUpstreamOption,
      argumentResults,
      platform.environment,
    )!;
    final String frameworkMirror = getValueFromEnvOrArgs(
      kFrameworkMirrorOption,
      argumentResults,
      platform.environment,
    )!;
    final String engineUpstream = getValueFromEnvOrArgs(
      kEngineUpstreamOption,
      argumentResults,
      platform.environment,
    )!;
    final String engineMirror = getValueFromEnvOrArgs(
      kEngineMirrorOption,
      argumentResults,
      platform.environment,
    )!;
    final String candidateBranch = getValueFromEnvOrArgs(
      kCandidateOption,
      argumentResults,
      platform.environment,
    )!;
    final String releaseChannel = getValueFromEnvOrArgs(
      kReleaseOption,
      argumentResults,
      platform.environment,
    )!;
    final List<String> frameworkCherrypickRevisions = getValuesFromEnvOrArgs(
      kFrameworkCherrypicksOption,
      argumentResults,
      platform.environment,
    );
    final List<String> engineCherrypickRevisions = getValuesFromEnvOrArgs(
      kEngineCherrypicksOption,
      argumentResults,
      platform.environment,
    );
    final String? dartRevision = getValueFromEnvOrArgs(
      kDartRevisionOption,
      argumentResults,
      platform.environment,
      allowNull: true,
    );
    final String incrementLetter = getValueFromEnvOrArgs(
      kIncrementOption,
      argumentResults,
      platform.environment,
    )!;

    if (!releaseCandidateBranchRegex.hasMatch(candidateBranch)) {
      throw ConductorException(
        'Invalid release candidate branch "$candidateBranch". Text should '
        'match the regex pattern /${releaseCandidateBranchRegex.pattern}/.',
      );
    }

    final Int64 unixDate = Int64(DateTime.now().millisecondsSinceEpoch);
    final pb.ConductorState state = pb.ConductorState();

    state.releaseChannel = releaseChannel;
    state.createdDate = unixDate;
    state.lastUpdatedDate = unixDate;
    state.incrementLevel = incrementLetter;

    final EngineRepository engine = EngineRepository(
      checkouts,
      initialRef: candidateBranch,
      upstreamRemote: Remote(
        name: RemoteName.upstream,
        url: engineUpstream,
      ),
      mirrorRemote: Remote(
        name: RemoteName.mirror,
        url: engineMirror,
      ),
    );

    // Create a new branch so that we don't accidentally push to upstream
    // candidateBranch.
    final String workingBranchName = 'cherrypicks-$candidateBranch';
    engine.newBranch(workingBranchName);

    if (dartRevision != null && dartRevision.isNotEmpty) {
      engine.updateDartRevision(dartRevision);
      engine.commit('Update Dart SDK to $dartRevision', addFirst: true);
    }
    final List<pb.Cherrypick> engineCherrypicks = _sortCherrypicks(
      repository: engine,
      cherrypicks: engineCherrypickRevisions,
      upstreamRef: EngineRepository.defaultBranch,
      releaseRef: candidateBranch,
    ).map((String revision) => pb.Cherrypick(
      trunkRevision: revision,
      state: pb.CherrypickState.PENDING,
    )).toList();

    for (final pb.Cherrypick cherrypick in engineCherrypicks) {
      final String revision = cherrypick.trunkRevision;
      final bool success = engine.canCherryPick(revision);
      stdio.printTrace(
        'Attempt to cherrypick $revision ${success ? 'succeeded' : 'failed'}',
      );
      if (success) {
        engine.cherryPick(revision);
        cherrypick.state = pb.CherrypickState.COMPLETED;
      } else {
        cherrypick.state = pb.CherrypickState.PENDING_WITH_CONFLICT;
      }
    }
    final String engineHead = engine.reverseParse('HEAD');
    state.engine = pb.Repository(
      candidateBranch: candidateBranch,
      workingBranch: workingBranchName,
      startingGitHead: engineHead,
      currentGitHead: engineHead,
      checkoutPath: engine.checkoutDirectory.path,
      cherrypicks: engineCherrypicks,
      dartRevision: dartRevision,
      upstream: pb.Remote(name: 'upstream', url: engine.upstreamRemote.url),
      mirror: pb.Remote(name: 'mirror', url: engine.mirrorRemote!.url),
    );
    final FrameworkRepository framework = FrameworkRepository(
      checkouts,
      initialRef: candidateBranch,
      upstreamRemote: Remote(
        name: RemoteName.upstream,
        url: frameworkUpstream,
      ),
      mirrorRemote: Remote(
        name: RemoteName.mirror,
        url: frameworkMirror,
      ),
    );
    framework.newBranch(workingBranchName);
    final List<pb.Cherrypick> frameworkCherrypicks = _sortCherrypicks(
      repository: framework,
      cherrypicks: frameworkCherrypickRevisions,
      upstreamRef: FrameworkRepository.defaultBranch,
      releaseRef: candidateBranch,
    ).map((String revision) => pb.Cherrypick(
      trunkRevision: revision,
      state: pb.CherrypickState.PENDING,
    )).toList();

    for (final pb.Cherrypick cherrypick in frameworkCherrypicks) {
      final String revision = cherrypick.trunkRevision;
      final bool success = framework.canCherryPick(revision);
      stdio.printTrace(
        'Attempt to cherrypick $cherrypick ${success ? 'succeeded' : 'failed'}',
      );
      if (success) {
        framework.cherryPick(revision);
        cherrypick.state = pb.CherrypickState.COMPLETED;
      } else {
        cherrypick.state = pb.CherrypickState.PENDING_WITH_CONFLICT;
      }
    }

    // Get framework version
    final Version lastVersion = Version.fromString(framework.getFullTag(framework.upstreamRemote.name, candidateBranch, exact: false));
    Version nextVersion;
    if (incrementLetter == 'm') {
      nextVersion = Version.fromCandidateBranch(candidateBranch);
    } else {
      nextVersion = Version.increment(lastVersion, incrementLetter);
    }
    state.releaseVersion = nextVersion.toString();

    final String frameworkHead = framework.reverseParse('HEAD');
    state.framework = pb.Repository(
      candidateBranch: candidateBranch,
      workingBranch: workingBranchName,
      startingGitHead: frameworkHead,
      currentGitHead: frameworkHead,
      checkoutPath: framework.checkoutDirectory.path,
      cherrypicks: frameworkCherrypicks,
      upstream: pb.Remote(name: 'upstream', url: framework.upstreamRemote.url),
      mirror: pb.Remote(name: 'mirror', url: framework.mirrorRemote!.url),
    );

    state.currentPhase = ReleasePhase.APPLY_ENGINE_CHERRYPICKS;

    state.conductorVersion = conductorVersion;

    stdio.printTrace('Writing state to file ${stateFile.path}...');

    writeStateToFile(stateFile, state, stdio.logs);

    stdio.printStatus(presentState(state));
  }

  // To minimize merge conflicts, sort the commits by rev-list order.
  List<String> _sortCherrypicks({
    required Repository repository,
    required List<String> cherrypicks,
    required String upstreamRef,
    required String releaseRef,
  }) {
    if (cherrypicks.isEmpty) {
      return cherrypicks;
    }

    // Input cherrypick hashes that failed to be parsed by git.
    final List<String> unknownCherrypicks = <String>[];
    // Full 40-char hashes parsed by git.
    final List<String> validatedCherrypicks = <String>[];
    // Final, validated, sorted list of cherrypicks to be applied.
    final List<String> sortedCherrypicks = <String>[];
    for (final String cherrypick in cherrypicks) {
      try {
        final String fullRef = repository.reverseParse(cherrypick);
        validatedCherrypicks.add(fullRef);
      } on GitException {
        // Catch this exception so that we can validate the rest.
        unknownCherrypicks.add(cherrypick);
      }
    }

    final String branchPoint = repository.branchPoint(
      '${repository.upstreamRemote.name}/$upstreamRef',
      '${repository.upstreamRemote.name}/$releaseRef',
    );

    // `git rev-list` returns newest first, so reverse this list
    final List<String> upstreamRevlist = repository.revList(<String>[
      '--ancestry-path',
      '$branchPoint..$upstreamRef',
    ]).reversed.toList();

    stdio.printStatus('upstreamRevList:\n${upstreamRevlist.join('\n')}\n');
    stdio.printStatus('validatedCherrypicks:\n${validatedCherrypicks.join('\n')}\n');
    for (final String upstreamRevision in upstreamRevlist) {
      if (validatedCherrypicks.contains(upstreamRevision)) {
        validatedCherrypicks.remove(upstreamRevision);
        sortedCherrypicks.add(upstreamRevision);
        if (unknownCherrypicks.isEmpty && validatedCherrypicks.isEmpty) {
          return sortedCherrypicks;
        }
      }
    }

    // We were given input cherrypicks that were not present in the upstream
    // rev-list
    stdio.printError(
      'The following ${repository.name} cherrypicks were not found in the '
      'upstream $upstreamRef branch:',
    );
    for (final String cp in <String>[...validatedCherrypicks, ...unknownCherrypicks]) {
      stdio.printError('\t$cp');
    }
    throw ConductorException(
      '${validatedCherrypicks.length + unknownCherrypicks.length} unknown cherrypicks provided!',
    );
  }
}
