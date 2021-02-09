// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:fixnum/fixnum.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

import './proto/conductor_state.pb.dart' as pb;
import './proto/conductor_state.pbenum.dart' show ReleasePhase;
import './repository.dart';
import './state.dart';
import './stdio.dart';

const String kStateOption = 'state-file';
const String kOverrideNextOption = 'override-next';

/// Command to print the status of the current Flutter release.
class NextCommand extends Command<void> {
  NextCommand({
    @required this.checkouts,
  })  : platform = checkouts.platform,
        fileSystem = checkouts.fileSystem,
        stdio = checkouts.stdio {
    final String defaultPath = defaultStateFilePath(platform);
    argParser.addOption(
      kStateOption,
      defaultsTo: defaultPath,
      help: 'Path to persistent state file. Defaults to $defaultPath',
    );
    argParser.addOption(
      kOverrideNextOption,
      allowed: ReleasePhase.values.map((ReleasePhase phase) => phase.value.toString()).toList(),
      help: 'Override the next phase. For testing.',
      //hide: true,
    );
}

  final Checkouts checkouts;
  final FileSystem fileSystem;
  final Platform platform;
  final Stdio stdio;

  @override
  String get name => 'next';

  @override
  String get description => 'Proceed to the next step of the release.';

  @override
  void run() {
    final File stateFile = checkouts.fileSystem.file(argResults[kStateOption]);
    if (!stateFile.existsSync()) {
      stdio.printStatus(
          'No persistent state file found at ${argResults[kStateOption]}.');
      return;
    }
    final pb.ConductorState state = pb.ConductorState();
    state.mergeFromProto3Json(jsonDecode(stateFile.readAsStringSync()));

    final Int64 unixDate = Int64(DateTime.now().millisecondsSinceEpoch);

    state.lastUpdatedDate = unixDate;

    ReleasePhase currentPhase = getNextPhase(state.lastPhase);
    if (argResults[kOverrideNextOption] != null) {
      final String phaseArg = argResults[kOverrideNextOption] as String;
      final int phaseInt = int.parse(phaseArg);
      currentPhase = ReleasePhase.valueOf(phaseInt);
      stdio.printTrace('Overriding next phase to ${currentPhase.name}');
    }

    switch (currentPhase) {
      case ReleasePhase.INITIALIZED:
        assert(false); // should be unreachable
        break;
      case ReleasePhase.ENGINE_CHERRYPICKS_APPLIED:
      case ReleasePhase.ENGINE_BINARIES_CODESIGNED:
      case ReleasePhase.FRAMEWORK_CHERRYPICKS_APPLIED:
      case ReleasePhase.VERSION_PUBLISHED:
      case ReleasePhase.CHANNEL_PUBLISHED:
      case ReleasePhase.RELEASE_VERIFIED:
    }

    state.lastPhase = currentPhase;

    stdio.printTrace('Writing state to file ${stateFile.path}...');

    state.logs.addAll(stdio.logs);
    stateFile.writeAsStringSync(
      jsonEncode(state.toProto3Json()),
      flush: true,
    );

    presentState(stdio, state);
  }
}
