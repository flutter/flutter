// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:platform/platform.dart';

import './globals.dart';
import './proto/conductor_state.pb.dart' as pb;
import './proto/conductor_state.pbenum.dart' show ReleasePhase;
import './stdio.dart' show Stdio;

const String kStateFileName = '.flutter_conductor_state.json';

String defaultStateFilePath(Platform platform) {
  assert(platform.environment['HOME'] != null);
  return <String>[
    platform.environment['HOME'],
    kStateFileName,
  ].join(platform.pathSeparator);
}

void presentState(Stdio stdio, pb.ConductorState state) {
  stdio.printStatus('Conductor version: ${state.conductorVersion}');
  stdio.printStatus('Release channel: ${state.releaseChannel}');
  stdio.printStatus('');
  stdio.printStatus(
      'Release started at: ${DateTime.fromMillisecondsSinceEpoch(state.createdDate.toInt())}');
  stdio.printStatus(
      'Last updated at: ${DateTime.fromMillisecondsSinceEpoch(state.lastUpdatedDate.toInt())}');
  stdio.printStatus('');
  stdio.printStatus('Engine Repo');
  stdio.printStatus('\tCandidate branch: ${state.engine.candidateBranch}');
  stdio.printStatus('\tStarting git HEAD: ${state.engine.startingGitHead}');
  stdio.printStatus('\tCurrent git HEAD: ${state.engine.currentGitHead}');
  stdio.printStatus('\tPath to checkout: ${state.engine.checkoutPath}');
  stdio.printStatus('Framework Repo');
  stdio.printStatus('\tCandidate branch: ${state.framework.candidateBranch}');
  stdio.printStatus('\tStarting git HEAD: ${state.framework.startingGitHead}');
  stdio.printStatus('\tCurrent git HEAD: ${state.framework.currentGitHead}');
  stdio.printStatus('\tPath to checkout: ${state.framework.checkoutPath}');
  stdio.printStatus('');
  stdio.printStatus('Last completed step: ${state.lastPhase.name}');
  if (state.lastPhase == ReleasePhase.RELEASE_VERIFIED) {
    stdio.printStatus(
      '${state.releaseChannel} release ${state.releaseVersion} has been published and verified.\n',
    );
    return;
  }
  stdio.printStatus('');
  stdio.printStatus('Next steps:');
  stdio.printStatus(nextPhaseMessage(state));
  stdio.printStatus('');
  stdio.printStatus('Issue `conductor next` when you are ready to proceed.');
}

String nextPhaseMessage(pb.ConductorState state) {
  switch (state.lastPhase) {
    case ReleasePhase.INITIALIZED:
      if (state.engine.cherrypicks.isEmpty) {
        return <String>[
          'There are no engine cherrypicks, so issue `conductor next` to continue',
          'to the next step.',
        ].join('\n');
      }
      return <String>[
        'You must now manually apply the following engine cherrypicks to the checkout',
        'at ${state.engine.checkoutPath} in order:',
        for (final String cherrypick in state.engine.cherrypicks)
          '\t$cherrypick',
        'See $kReleaseDocumentationUrl for more information.',
      ].join('\n');
    case ReleasePhase.ENGINE_CHERRYPICKS_APPLIED:
      return <String>[
        'You must verify Engine CI builds are successful and then codesign the',
        'binaries at revision ${state.engine.currentGitHead}.',
      ].join('\n');
    case ReleasePhase.ENGINE_BINARIES_CODESIGNED:
      return <String>[
        'You must now manually apply the following framework cherrypicks to the checkout',
        'at ${state.framework.checkoutPath} in order:',
        for (final String cherrypick in state.framework.cherrypicks)
          '\t$cherrypick',
      ].join('\n');
    case ReleasePhase.FRAMEWORK_CHERRYPICKS_APPLIED:
      return <String>[
        'You must verify Framework CI builds are successful.',
        'See $kReleaseDocumentationUrl for more information.',
      ].join('\n');
    case ReleasePhase.VERSION_PUBLISHED:
      return 'Issue `conductor next` to publish your release to the release branch.';
    case ReleasePhase.CHANNEL_PUBLISHED:
      return <String>[
        'Release archive packages must be verified on cloud storage. Issue',
        '`conductor next` to check if they are ready.',
      ].join('\n');
    case ReleasePhase.RELEASE_VERIFIED:
      return 'This release has been completed.';
  }
  assert(false);
  return ''; // For analyzer
}

/// Returns the next phase in the ReleasePhase enum.
///
/// Will throw a [ConductorException] if [ReleasePhase.RELEASE_VERIFIED] is
/// passed as an argument, as there is no next phase.
ReleasePhase getNextPhase(ReleasePhase currentPhase) {
  assert(currentPhase != null);
  if (currentPhase == ReleasePhase.RELEASE_VERIFIED) {
    throw ConductorException('There is no next ReleasePhase!');
  }
  return ReleasePhase.valueOf(currentPhase.value + 1);
}
