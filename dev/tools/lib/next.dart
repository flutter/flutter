// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show jsonDecode, jsonEncode;

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:fixnum/fixnum.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import './git.dart';
import './globals.dart' as globals;
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
    @required this.flutterRoot,
  })  : platform = checkouts.platform,
        processManager = checkouts.processManager,
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
      allowed: ReleasePhase.values
          .map((ReleasePhase phase) => phase.value.toString())
          .toList(),
      help: 'Override the next phase. For testing. Use numeric enum values.',
      hide: true,
    );
    final Git git = Git(processManager);
    conductorVersion = git.getOutput(
      <String>['rev-parse', 'HEAD'],
      'look up the current revision.',
      workingDirectory: flutterRoot.path,
    ).trim();

    assert(conductorVersion.isNotEmpty);
  }

  /// The root directory of the Flutter repository that houses the Conductor.
  ///
  /// This directory is used to check the git revision of the Conductor.
  final Directory flutterRoot;
  final Checkouts checkouts;
  final FileSystem fileSystem;
  final Platform platform;
  final ProcessManager processManager;
  final Stdio stdio;

  /// Git revision for the currently running Conductor.
  String conductorVersion;

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

    if (state.conductorVersion != conductorVersion) {
      throw globals.ConductorException(
          'You are using conductor version $conductorVersion while the current '
          'release was started with version ${state.conductorVersion}!');
    }

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
      case ReleasePhase.INITIALIZE:
        assert(false); // should be unreachable
        break;
      case ReleasePhase.APPLY_ENGINE_CHERRYPICKS:
        // TODO push should be
        // `git push --set-upstream $REMOTE_NAME HEAD:cherrypicks-CANDIDATE_BRANCH_NAME`
      case ReleasePhase.CODESIGN_ENGINE_BINARIES:
      case ReleasePhase.APPLY_FRAMEWORK_CHERRYPICKS:
      case ReleasePhase.PUBLISH_VERSION:
      case ReleasePhase.PUBLISH_CHANNEL:
      case ReleasePhase.VERIFY_RELEASE:
        assert(false, 'Unimplemented phase ${currentPhase.name}');
        break;
    }

    state.lastPhase = currentPhase;

    stdio.printTrace('Writing state to file ${stateFile.path}...');

    state.logs.addAll(stdio.logs);
    stateFile.writeAsStringSync(
      jsonEncode(state.toProto3Json()),
      flush: true,
    );

    stdio.printStatus(presentState(state));
  }
}
