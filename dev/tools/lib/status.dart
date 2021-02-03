// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

import './repository.dart';
import './state.dart';
import './stdio.dart';

/// Command to print the status of the current Flutter release.
class StatusCommand extends Command<void> {
  StatusCommand({
    @required this.checkouts,
    @required this.stdio,
    }) : platform = checkouts.platform, fileSystem = checkouts.fileSystem {
    argParser.addOption(
        'state-file',
        defaultsTo: fileSystem.path.join(platform.environment['HOME'], kStateFileName),
        help: 'Path to persistent state file. Defaults to \$HOME/$kStateFileName',
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
      final State state = State.fromFile(stateFile);
      presentState(state);
    } else {
      stdio.printStatus('No persistent state file found at ${argResults['state-file']}.');
    }
  }

  @visibleForTesting
  void presentState(State state) {
    stdio.printStatus('\nFlutter Conductor Status\n');
    stdio.printStatus('Release channel:\t\t${state.releaseChannel}');
    stdio.printStatus('Release candidate branch:\t${state.candidateBranch}');
  }
}
