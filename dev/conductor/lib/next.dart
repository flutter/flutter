// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/file.dart' show File;
import 'package:meta/meta.dart' show visibleForTesting;
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
    required this.checkouts,
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
      autoAccept: argResults![kYesFlag] as bool,
      checkouts: checkouts,
      force: argResults![kForceFlag] as bool,
      stateFile: checkouts.fileSystem.file(argResults![kStateOption]),
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
  required bool autoAccept,
  required bool force,
  required Checkouts checkouts,
  required File stateFile,
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
      final Remote upstream = Remote(
        name: RemoteName.upstream,
        url: state.engine.upstream.url,
      );
      final EngineRepository engine = EngineRepository(
        checkouts,
        initialRef: state.engine.workingBranch,
        upstreamRemote: upstream,
        previousCheckoutLocation: state.engine.checkoutPath,
      );
      // check if the candidate branch is enabled in .ci.yaml
      if (!engine.ciYaml.enabledBranches.contains(state.engine.candidateBranch)) {
        engine.ciYaml.enableBranch(state.engine.candidateBranch);
        // commit
        final String revision = engine.commit(
          'add branch ${state.engine.candidateBranch} to enabled_branches in .ci.yaml',
          addFirst: true,
        );
        // append to list of cherrypicks so we know a PR is required
        state.engine.cherrypicks.add(pb.Cherrypick(
          appliedRevision: revision,
          state: pb.CherrypickState.COMPLETED,
        ));
      }

      if (!requiresEnginePR(state)) {
        stdio.printStatus(
          'This release has no engine cherrypicks. No Engine PR is necessary.\n',
        );
        break;
      }

      final List<pb.Cherrypick> unappliedCherrypicks = <pb.Cherrypick>[];
      for (final pb.Cherrypick cherrypick in state.engine.cherrypicks) {
        if (!finishedStates.contains(cherrypick.state)) {
          unappliedCherrypicks.add(cherrypick);
        }
      }

      if (unappliedCherrypicks.isEmpty) {
        stdio.printStatus('All engine cherrypicks have been auto-applied by the conductor.\n');
      } else {
        stdio.printStatus('There were ${unappliedCherrypicks.length} cherrypicks that were not auto-applied.');
        stdio.printStatus('These must be applied manually in the directory '
            '${state.engine.checkoutPath} before proceeding.\n');
      }
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

      engine.pushRef(
        fromRef: 'HEAD',
        // Explicitly create new branch
        toRef: 'refs/heads/${state.engine.workingBranch}',
        remote: state.engine.mirror.name,
      );

      break;
    case pb.ReleasePhase.CODESIGN_ENGINE_BINARIES:
      stdio.printStatus(<String>[
        'You must validate pre-submit CI for your engine PR, merge it, and codesign',
        'binaries before proceeding.\n',
      ].join('\n'));
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
      if (state.engine.cherrypicks.isEmpty && state.engine.dartRevision.isEmpty) {
        stdio.printStatus(
          'This release has no engine cherrypicks, and thus the engine.version file\n'
          'in the framework does not need to be updated.',
        );

        if (state.framework.cherrypicks.isEmpty) {
          stdio.printStatus(
            'This release also has no framework cherrypicks. Therefore, a framework\n'
            'pull request is not required.',
          );
          break;
        }
      }
      final Remote engineUpstreamRemote = Remote(
        name: RemoteName.upstream,
        url: state.engine.upstream.url,
      );
      final EngineRepository engine = EngineRepository(
        checkouts,
        // We explicitly want to check out the merged version from upstream
        initialRef: '${engineUpstreamRemote.name}/${state.engine.candidateBranch}',
        upstreamRemote: engineUpstreamRemote,
        previousCheckoutLocation: state.engine.checkoutPath,
      );

      final String engineRevision = engine.reverseParse('HEAD');

      final Remote upstream = Remote(
        name: RemoteName.upstream,
        url: state.framework.upstream.url,
      );
      final FrameworkRepository framework = FrameworkRepository(
        checkouts,
        initialRef: state.framework.workingBranch,
        upstreamRemote: upstream,
        previousCheckoutLocation: state.framework.checkoutPath,
      );

      // Check if the current candidate branch is enabled
      if (!framework.ciYaml.enabledBranches.contains(state.framework.candidateBranch)) {
        framework.ciYaml.enableBranch(state.framework.candidateBranch);
        // commit
        final String revision = framework.commit(
          'add branch ${state.framework.candidateBranch} to enabled_branches in .ci.yaml',
          addFirst: true,
        );
        // append to list of cherrypicks so we know a PR is required
        state.framework.cherrypicks.add(pb.Cherrypick(
          appliedRevision: revision,
          state: pb.CherrypickState.COMPLETED,
        ));
      }

      stdio.printStatus('Rolling new engine hash $engineRevision to framework checkout...');
      final bool needsCommit = framework.updateEngineRevision(engineRevision);
      if (needsCommit) {
        final String revision = framework.commit(
          'Update Engine revision to $engineRevision for ${state.releaseChannel} release ${state.releaseVersion}',
          addFirst: true,
        );
        // append to list of cherrypicks so we know a PR is required
        state.framework.cherrypicks.add(pb.Cherrypick(
          appliedRevision: revision,
          state: pb.CherrypickState.COMPLETED,
        ));
      }

      final List<pb.Cherrypick> unappliedCherrypicks = <pb.Cherrypick>[];
      for (final pb.Cherrypick cherrypick in state.framework.cherrypicks) {
        if (!finishedStates.contains(cherrypick.state)) {
          unappliedCherrypicks.add(cherrypick);
        }
      }

      if (state.framework.cherrypicks.isEmpty) {
        stdio.printStatus(
          'This release has no framework cherrypicks. However, a framework PR is still\n'
          'required to roll engine cherrypicks.',
        );
      } else if (unappliedCherrypicks.isEmpty) {
        stdio.printStatus('All framework cherrypicks were auto-applied by the conductor.');
      } else {
        stdio.printStatus(
          'There were ${unappliedCherrypicks.length} cherrypicks that were not auto-applied.',
        );
        stdio.printStatus(
          'These must be applied manually in the directory '
          '${state.framework.checkoutPath} before proceeding.\n',
        );
      }

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

      framework.pushRef(
        fromRef: 'HEAD',
        // Explicitly create new branch
        toRef: 'refs/heads/${state.framework.workingBranch}',
        remote: state.framework.mirror.name,
      );
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
        // We explicitly want to check out the merged version from upstream
        initialRef: '${upstream.name}/${state.framework.candidateBranch}',
        upstreamRemote: upstream,
        previousCheckoutLocation: state.framework.checkoutPath,
      );
      final String headRevision = framework.reverseParse('HEAD');
      if (autoAccept == false) {
        final bool response = prompt(
          'Are you ready to tag commit $headRevision as ${state.releaseVersion}\n'
          'and push to remote ${state.framework.upstream.url}?',
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
        // We explicitly want to check out the merged version from upstream
        initialRef: '${upstream.name}/${state.framework.candidateBranch}',
        upstreamRemote: upstream,
        previousCheckoutLocation: state.framework.checkoutPath,
      );
      final String headRevision = framework.reverseParse('HEAD');
      if (autoAccept == false) {
        // dryRun: true means print out git command
        framework.pushRef(
          fromRef: headRevision,
          toRef: state.releaseChannel,
          remote: state.framework.upstream.url,
          force: force,
          dryRun: true,
        );

        final bool response = prompt(
          'Are you ready to publish this release?',
          stdio,
        );
        if (!response) {
          stdio.printError('Aborting command.');
          writeStateToFile(stateFile, state, stdio.logs);
          return;
        }
      }
      framework.pushRef(
        fromRef: headRevision,
        toRef: state.releaseChannel,
        remote: state.framework.upstream.url,
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
  }
  final ReleasePhase nextPhase = getNextPhase(state.currentPhase);
  stdio.printStatus('\nUpdating phase from ${state.currentPhase} to $nextPhase...\n');
  state.currentPhase = nextPhase;
  stdio.printStatus(phaseInstructions(state));

  writeStateToFile(stateFile, state, stdio.logs);
}
