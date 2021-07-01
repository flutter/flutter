// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:file/file.dart' show File;
import 'package:platform/platform.dart';

import './globals.dart';
import './proto/conductor_state.pb.dart' as pb;
import './proto/conductor_state.pbenum.dart' show ReleasePhase;

const String kStateFileName = '.flutter_conductor_state.json';

String luciConsoleLink(String channel, String groupName) {
  assert(
    <String>['stable', 'beta', 'dev', 'master'].contains(channel),
    'channel $channel not recognized',
  );
  assert(
    <String>['framework', 'engine', 'devicelab'].contains(groupName),
    'group named $groupName not recognized',
  );
  final String consoleName = channel == 'master' ? groupName : '${channel}_$groupName';
  return 'https://ci.chromium.org/p/flutter/g/$consoleName/console';
}

String defaultStateFilePath(Platform platform) {
  assert(platform.environment['HOME'] != null);
  return <String>[
    platform.environment['HOME'],
    kStateFileName,
  ].join(platform.pathSeparator);
}

String presentState(pb.ConductorState state) {
  final StringBuffer buffer = StringBuffer();
  buffer.writeln('Conductor version: ${state.conductorVersion}');
  buffer.writeln('Release channel: ${state.releaseChannel}');
  buffer.writeln('Release version: ${state.releaseVersion}');
  buffer.writeln('');
  buffer.writeln(
      'Release started at: ${DateTime.fromMillisecondsSinceEpoch(state.createdDate.toInt())}');
  buffer.writeln(
      'Last updated at: ${DateTime.fromMillisecondsSinceEpoch(state.lastUpdatedDate.toInt())}');
  buffer.writeln('');
  buffer.writeln('Engine Repo');
  buffer.writeln('\tCandidate branch: ${state.engine.candidateBranch}');
  buffer.writeln('\tStarting git HEAD: ${state.engine.startingGitHead}');
  buffer.writeln('\tCurrent git HEAD: ${state.engine.currentGitHead}');
  buffer.writeln('\tPath to checkout: ${state.engine.checkoutPath}');
  buffer.writeln('\tPost-submit LUCI dashboard: ${luciConsoleLink(state.releaseChannel, 'engine')}');
  if (state.engine.cherrypicks.isNotEmpty) {
    buffer.writeln('${state.engine.cherrypicks.length} Engine Cherrypicks:');
    for (final pb.Cherrypick cherrypick in state.engine.cherrypicks) {
      buffer.writeln('\t${cherrypick.trunkRevision} - ${cherrypick.state}');
    }
  } else {
    buffer.writeln('0 Engine cherrypicks.');
  }
  if (state.engine.dartRevision != null && state.engine.dartRevision.isNotEmpty) {
    buffer.writeln('New Dart SDK revision: ${state.engine.dartRevision}');
  }
  buffer.writeln('Framework Repo');
  buffer.writeln('\tCandidate branch: ${state.framework.candidateBranch}');
  buffer.writeln('\tStarting git HEAD: ${state.framework.startingGitHead}');
  buffer.writeln('\tCurrent git HEAD: ${state.framework.currentGitHead}');
  buffer.writeln('\tPath to checkout: ${state.framework.checkoutPath}');
  buffer.writeln('\tPost-submit LUCI dashboard: ${luciConsoleLink(state.releaseChannel, 'framework')}');
  buffer.writeln('\tDevicelab LUCI dashboard: ${luciConsoleLink(state.releaseChannel, 'devicelab')}');
  if (state.framework.cherrypicks.isNotEmpty) {
    buffer.writeln('${state.framework.cherrypicks.length} Framework Cherrypicks:');
    for (final pb.Cherrypick cherrypick in state.framework.cherrypicks) {
      buffer.writeln('\t${cherrypick.trunkRevision} - ${cherrypick.state}');
    }
  } else {
    buffer.writeln('0 Framework cherrypicks.');
  }
  buffer.writeln('');
  if (state.currentPhase == ReleasePhase.VERIFY_RELEASE) {
    buffer.writeln(
      '${state.releaseChannel} release ${state.releaseVersion} has been published and verified.\n',
    );
    return buffer.toString();
  }
  buffer.writeln('The current phase is:');
  buffer.writeln(presentPhases(state.currentPhase));

  buffer.writeln(phaseInstructions(state));
  buffer.writeln('');
  buffer.writeln('Issue `conductor next` when you are ready to proceed.');
  return buffer.toString();
}

String presentPhases(ReleasePhase currentPhase) {
  final StringBuffer buffer = StringBuffer();
  bool phaseCompleted = true;

  for (final ReleasePhase phase in ReleasePhase.values) {
    if (phase == currentPhase) {
      // This phase will execute the next time `conductor next` is run.
      buffer.writeln('> ${phase.name} (current)');
      phaseCompleted = false;
    } else if (phaseCompleted) {
      // This phase was already completed.
      buffer.writeln('✓ ${phase.name}');
    } else {
      // This phase has not been completed yet.
      buffer.writeln('  ${phase.name}');
    }
  }
  return buffer.toString();
}

String phaseInstructions(pb.ConductorState state) {
  switch (state.currentPhase) {
    case ReleasePhase.APPLY_ENGINE_CHERRYPICKS:
      if (state.engine.cherrypicks.isEmpty) {
        return <String>[
          'There are no engine cherrypicks, so issue `conductor next` to continue',
          'to the next step.',
        ].join('\n');
      }
      return <String>[
        'You must now manually apply the following engine cherrypicks to the checkout',
        'at ${state.engine.checkoutPath} in order:',
        for (final pb.Cherrypick cherrypick in state.engine.cherrypicks)
          '\t${cherrypick.trunkRevision}',
        'See $kReleaseDocumentationUrl for more information.',
      ].join('\n');
    case ReleasePhase.CODESIGN_ENGINE_BINARIES:
      return <String>[
        'You must verify Engine CI builds are successful and then codesign the',
        'binaries at revision ${state.engine.currentGitHead}.',
      ].join('\n');
    case ReleasePhase.APPLY_FRAMEWORK_CHERRYPICKS:
      final List<pb.Cherrypick> outstandingCherrypicks = state.framework.cherrypicks.where(
        (pb.Cherrypick cp) {
          return cp.state == pb.CherrypickState.PENDING || cp.state == pb.CherrypickState.PENDING_WITH_CONFLICT;
        },
      ).toList();
      return <String>[
        'You must now manually apply the following framework cherrypicks to the checkout',
        'at ${state.framework.checkoutPath} in order:',
        for (final pb.Cherrypick cherrypick in outstandingCherrypicks)
          '\t${cherrypick.trunkRevision}',
      ].join('\n');
    case ReleasePhase.PUBLISH_VERSION:
      return <String>[
        'You must verify Framework CI builds are successful.',
        'See $kReleaseDocumentationUrl for more information.',
      ].join('\n');
    case ReleasePhase.PUBLISH_CHANNEL:
      return 'Issue `conductor next` to publish your release to the release branch.';
    case ReleasePhase.VERIFY_RELEASE:
      return 'Release archive packages must be verified on cloud storage.';
    case ReleasePhase.RELEASE_COMPLETED:
      return 'This release has been completed.';
  }
  assert(false);
  return ''; // For analyzer
}

/// Returns the next phase in the ReleasePhase enum.
///
/// Will throw a [ConductorException] if [ReleasePhase.RELEASE_COMPLETED] is
/// passed as an argument, as there is no next phase.
ReleasePhase getNextPhase(ReleasePhase previousPhase) {
  assert(previousPhase != null);
  if (previousPhase == ReleasePhase.RELEASE_COMPLETED) {
    throw ConductorException('There is no next ReleasePhase!');
  }
  return ReleasePhase.valueOf(previousPhase.value + 1);
}

void writeStateToFile(File file, pb.ConductorState state, List<String> logs) {
  state.logs.addAll(logs);
  file.writeAsStringSync(
    jsonEncode(state.toProto3Json()),
    flush: true,
  );
}

pb.ConductorState readStateFromFile(File file) {
  final pb.ConductorState state = pb.ConductorState();
  final String stateAsString = file.readAsStringSync();
  state.mergeFromProto3Json(
    jsonDecode(stateAsString),
  );
  return state;
}
