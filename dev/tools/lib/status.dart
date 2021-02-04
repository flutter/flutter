// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

import './proto/conductor_state.pb.dart' as pb;
import './repository.dart';
import './state.dart';
import './stdio.dart';

/// Command to print the status of the current Flutter release.
class StatusCommand extends Command<void> {
  StatusCommand({
    @required this.checkouts,
    @required this.stdio,
    }) : platform = checkouts.platform, fileSystem = checkouts.fileSystem {
    final String defaultPath = defaultStateFilePath(platform);
    argParser.addOption(
        'state-file',
        defaultsTo: defaultPath,
        help: 'Path to persistent state file. Defaults to $defaultPath',
    );
  }

  final Checkouts checkouts;
  final FileSystem fileSystem;
  final Platform platform;
  final Stdio stdio;

  @override
  String get name => 'status';

  @override
  String get description => 'Print status of current release.';

  @override
  void run() {
    final File stateFile = checkouts.fileSystem.file(argResults['state-file']);
    if (stateFile.existsSync()) {
      final pb.ConductorState state = pb.ConductorState.fromJson(stateFile.readAsStringSync());
      presentState(stdio, state);
    } else {
      stdio.printStatus('No persistent state file found at ${argResults['state-file']}.');
    }
  }
}
