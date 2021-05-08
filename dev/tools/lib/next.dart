// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:args/command_runner.dart';
import 'package:file/file.dart' show File;
import 'package:meta/meta.dart' show required;
import 'package:platform/platform.dart';

import './globals.dart';
import './proto/conductor_state.pb.dart' as pb;
import './repository.dart';
import './state.dart';
import './stdio.dart';

const String kStateOption = 'state-file';

class NextCommand extends Command<void> {
  NextCommand({
    @required this.checkouts,
  }) : platform = checkouts.platform, stdio = checkouts.stdio {
    final String defaultPath = defaultStateFilePath(platform);
    argParser.addOption(
      kStateOption,
      defaultsTo: defaultPath,
      help: 'Path to persistent state file. Defaults to $defaultPath',
    );
  }

  final Checkouts checkouts;
  final Platform platform;
  final Stdio stdio;

  @override
  String get name => 'next';

  @override
  String get description => 'Proceed to the next release phase.';

  @override
  void run() {
    final File stateFile = checkouts.fileSystem.file(argResults[kStateOption]);
    if (!stateFile.existsSync()) {
      stdio.printStatus(
        'No persistent state file found at ${argResults[kStateOption]}.',
      );
      return;
    }
    final pb.ConductorState state = pb.ConductorState();
    switch (state.lastPhase) {
      case pb.ReleasePhase.INITIALIZE:
        break;
      case pb.ReleasePhase.APPLY_ENGINE_CHERRYPICKS:
        break;
      case pb.ReleasePhase.CODESIGN_ENGINE_BINARIES:
        break;
      case pb.ReleasePhase.APPLY_FRAMEWORK_CHERRYPICKS:
        break;
      case pb.ReleasePhase.PUBLISH_VERSION:
        break;
      case pb.ReleasePhase.PUBLISH_CHANNEL:
        break;
      case pb.ReleasePhase.VERIFY_RELEASE:
        throw ConductorException('This release is finished.');
        break;
    }
  }
}
