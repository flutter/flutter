// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:fixnum/fixnum.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import 'context.dart';
import 'git.dart';
import 'globals.dart';
import 'proto/conductor_state.pb.dart' as pb;
import 'proto/conductor_state.pbenum.dart' show ReleasePhase;
import 'repository.dart';
import 'state.dart' as state_import;
import 'stdio.dart';
import 'version.dart';

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
    required this.conductorVersion,
  })  : platform = checkouts.platform,
        processManager = checkouts.processManager,
        fileSystem = checkouts.fileSystem,
        stdio = checkouts.stdio {
    final String defaultPath = state_import.defaultStateFilePath(platform);
    argParser.addOption(
      kCandidateOption,
      help: 'The candidate branch the release will be based on.',
    );
    argParser.addOption(
      kReleaseOption,
      help: 'The target release channel for the release.',
      allowed: kBaseReleaseChannels,
    );
    argParser.addOption(
      kFrameworkUpstreamOption,
      defaultsTo: FrameworkRepository.defaultUpstream,
      help: 'Configurable Framework repo upstream remote. Primarily for testing.',
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
      allowed: kReleaseIncrements,
      allowedHelp: <String, String>{
        'y': 'Indicates the first dev release after a beta release.',
        'z': 'Indicates a hotfix to a stable release.',
        'm': 'Indicates a standard dev release.',
        'n': 'Indicates a hotfix to a dev or beta release.',
      },
    );
    argParser.addFlag(
      kForceFlag,
      abbr: 'f',
      help: 'Override all validations of the command line inputs.',
    );
  }

  final Checkouts checkouts;

  final String conductorVersion;
  final FileSystem fileSystem;
  final Platform platform;
  final ProcessManager processManager;
  final Stdio stdio;

  @override
  String get name => 'start';

  @override
  String get description => 'Initialize a new Flutter release.';

  @override
  Future<void> run() async {
    final ArgResults argumentResults = argResults!;
    if (!platform.isMacOS && !platform.isLinux) {
      throw ConductorException(
        'Error! This tool is only supported on macOS and Linux',
      );
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
    final bool force = getBoolFromEnvOrArgs(
      kForceFlag,
      argumentResults,
      platform.environment,
    );
    final File stateFile = checkouts.fileSystem.file(
      getValueFromEnvOrArgs(kStateOption, argumentResults, platform.environment),
    );

    final StartContext context = StartContext(
      candidateBranch: candidateBranch,
      checkouts: checkouts,
      dartRevision: dartRevision,
      engineCherrypickRevisions: engineCherrypickRevisions,
      engineMirror: engineMirror,
      engineUpstream: engineUpstream,
      conductorVersion: conductorVersion,
      frameworkCherrypickRevisions: frameworkCherrypickRevisions,
      frameworkMirror: frameworkMirror,
      frameworkUpstream: frameworkUpstream,
      incrementLetter: incrementLetter,
      processManager: processManager,
      releaseChannel: releaseChannel,
      stateFile: stateFile,
      force: force,
    );
    return context.run();
  }
}

/// Context for starting a new release.
///
/// This is a frontend-agnostic implementation.
class StartContext extends Context {
  StartContext({
    required this.candidateBranch,
    required this.dartRevision,
    required this.engineCherrypickRevisions,
    required this.engineMirror,
    required this.engineUpstream,
    required this.frameworkCherrypickRevisions,
    required this.frameworkMirror,
    required this.frameworkUpstream,
    required this.conductorVersion,
    required this.incrementLetter,
    required this.processManager,
    required this.releaseChannel,
    required Checkouts checkouts,
    required File stateFile,
    this.force = false,
  }) : git = Git(processManager),
  engine = EngineRepository(
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
  ), framework = FrameworkRepository(
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
  ),
  super(
    checkouts: checkouts,
    stateFile: stateFile,
  );

  final String candidateBranch;
  final String? dartRevision;
  final List<String> engineCherrypickRevisions;
  final String engineMirror;
  final String engineUpstream;
  final List<String> frameworkCherrypickRevisions;
  final String frameworkMirror;
  final String frameworkUpstream;
  final String conductorVersion;
  final String incrementLetter;
  final Git git;
  final ProcessManager processManager;
  final String releaseChannel;

  /// If validations should be overridden.
  final bool force;

  final EngineRepository engine;
  final FrameworkRepository framework;

  Future<void> run() async {
    if (stateFile.existsSync()) {
      throw ConductorException('Error! A persistent state file already found at ${stateFile.path}.\n\n'
          'Run `conductor clean` to cancel a previous release.');
    }
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

    // Create a new branch so that we don't accidentally push to upstream
    // candidateBranch.
    final String workingBranchName = 'cherrypicks-$candidateBranch';
    await engine.newBranch(workingBranchName);

    if (dartRevision != null && dartRevision!.isNotEmpty) {
      await engine.updateDartRevision(dartRevision!);
      await engine.commit('Update Dart SDK to $dartRevision', addFirst: true);
    }
    final List<pb.Cherrypick> engineCherrypicks = (await _sortCherrypicks(
      repository: engine,
      cherrypicks: engineCherrypickRevisions,
      upstreamRef: EngineRepository.defaultBranch,
      releaseRef: candidateBranch,
    )).map((String revision) => pb.Cherrypick(
      trunkRevision: revision,
      state: pb.CherrypickState.PENDING,
    )).toList();

    for (final pb.Cherrypick cherrypick in engineCherrypicks) {
      final String revision = cherrypick.trunkRevision;
      final bool success = await engine.canCherryPick(revision);
      stdio.printTrace(
        'Attempt to cherrypick $revision ${success ? 'succeeded' : 'failed'}',
      );
      if (success) {
        await engine.cherryPick(revision);
        cherrypick.state = pb.CherrypickState.COMPLETED;
      } else {
        cherrypick.state = pb.CherrypickState.PENDING_WITH_CONFLICT;
      }
    }
    final String engineHead = await engine.reverseParse('HEAD');
    state.engine = pb.Repository(
      candidateBranch: candidateBranch,
      workingBranch: workingBranchName,
      startingGitHead: engineHead,
      currentGitHead: engineHead,
      checkoutPath: (await engine.checkoutDirectory).path,
      cherrypicks: engineCherrypicks,
      dartRevision: dartRevision,
      upstream: pb.Remote(name: 'upstream', url: engine.upstreamRemote.url),
      mirror: pb.Remote(name: 'mirror', url: engine.mirrorRemote!.url),
    );

    await framework.newBranch(workingBranchName);
    final List<pb.Cherrypick> frameworkCherrypicks = (await _sortCherrypicks(
      repository: framework,
      cherrypicks: frameworkCherrypickRevisions,
      upstreamRef: FrameworkRepository.defaultBranch,
      releaseRef: candidateBranch,
    )).map((String revision) => pb.Cherrypick(
      trunkRevision: revision,
      state: pb.CherrypickState.PENDING,
    )).toList();

    for (final pb.Cherrypick cherrypick in frameworkCherrypicks) {
      final String revision = cherrypick.trunkRevision;
      final bool success = await framework.canCherryPick(revision);
      stdio.printTrace(
        'Attempt to cherrypick $cherrypick ${success ? 'succeeded' : 'failed'}',
      );
      if (success) {
        await framework.cherryPick(revision);
        cherrypick.state = pb.CherrypickState.COMPLETED;
      } else {
        cherrypick.state = pb.CherrypickState.PENDING_WITH_CONFLICT;
      }
    }

    // Get framework version
    final Version lastVersion = Version.fromString(await framework.getFullTag(
      framework.upstreamRemote.name,
      candidateBranch,
      exact: false,
    ));
    // [force] means we know this would fail but need to publish anyway
    if (!force) {
      lastVersion.ensureValid(candidateBranch, incrementLetter);
    }

    Version nextVersion = calculateNextVersion(lastVersion);
    nextVersion = await ensureBranchPointTagged(nextVersion, framework);

    state.releaseVersion = nextVersion.toString();

    final String frameworkHead = await framework.reverseParse('HEAD');
    state.framework = pb.Repository(
      candidateBranch: candidateBranch,
      workingBranch: workingBranchName,
      startingGitHead: frameworkHead,
      currentGitHead: frameworkHead,
      checkoutPath: (await framework.checkoutDirectory).path,
      cherrypicks: frameworkCherrypicks,
      upstream: pb.Remote(name: 'upstream', url: framework.upstreamRemote.url),
      mirror: pb.Remote(name: 'mirror', url: framework.mirrorRemote!.url),
    );

    state.currentPhase = ReleasePhase.APPLY_ENGINE_CHERRYPICKS;

    state.conductorVersion = conductorVersion;

    stdio.printTrace('Writing state to file ${stateFile.path}...');

    updateState(state, stdio.logs);

    stdio.printStatus(state_import.presentState(state));
  }

  /// Determine this release's version number from the [lastVersion] and the [incrementLetter].
  Version calculateNextVersion(Version lastVersion) {
    if (incrementLetter == 'm') {
      return Version.fromCandidateBranch(candidateBranch);
    }
    if (incrementLetter == 'z') {
      if (lastVersion.type == VersionType.stable) {
        return Version.increment(lastVersion, incrementLetter);
      }
      // This is the first stable release, so hardcode the z as 0
      return Version(
        x: lastVersion.x,
        y: lastVersion.y,
        z: 0,
        type: VersionType.stable,
      );
    }
    return Version.increment(lastVersion, incrementLetter);
  }

  /// Ensures the branch point [candidateBranch] and `master` has a version tag.
  ///
  /// This is necessary for version reporting for users on the `master` channel
  /// to be correct.
  Future<Version> ensureBranchPointTagged(
    Version requestedVersion,
    FrameworkRepository framework,
  ) async {
    if (incrementLetter != 'm') {
      // in this case, there must have been a previous tagged release, so skip
      // tagging the branch point
      return requestedVersion;
    }
    final String branchPoint = await framework.branchPoint(
      candidateBranch,
      FrameworkRepository.defaultBranch,
    );
    final bool response = await prompt(
      'About to tag the release candidate branch branchpoint of $branchPoint '
      'as $requestedVersion and push it to ${framework.upstreamRemote.url}. '
      'Is this correct?',
    );

    if (!response) {
      throw ConductorException('Aborting command.');
    }

    stdio.printStatus('Applying the tag $requestedVersion at the branch point $branchPoint');

    await framework.tag(
      branchPoint,
      requestedVersion.toString(),
      frameworkUpstream,
    );
    final Version nextVersion = Version.increment(requestedVersion, 'n');
    stdio.printStatus('The actual release will be version $nextVersion.');
    return nextVersion;
  }

  // To minimize merge conflicts, sort the commits by rev-list order.
  Future<List<String>> _sortCherrypicks({
    required Repository repository,
    required List<String> cherrypicks,
    required String upstreamRef,
    required String releaseRef,
  }) async {
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
        final String fullRef = await repository.reverseParse(cherrypick);
        validatedCherrypicks.add(fullRef);
      } on GitException {
        // Catch this exception so that we can validate the rest.
        unknownCherrypicks.add(cherrypick);
      }
    }

    final String branchPoint = await repository.branchPoint(
      '${repository.upstreamRemote.name}/$upstreamRef',
      '${repository.upstreamRemote.name}/$releaseRef',
    );

    // `git rev-list` returns newest first, so reverse this list
    final List<String> upstreamRevlist = (await repository.revList(<String>[
      '--ancestry-path',
      '$branchPoint..$upstreamRef',
    ])).reversed.toList();

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
