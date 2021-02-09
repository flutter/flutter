// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

import './globals.dart';
import './repository.dart';
import './state.dart';
import './stdio.dart';

const String kYesFlag = 'yes';
const String kStateOption = 'state-file';

/// Command to clean up persistent state file.
///
/// If the release was not completed, this command will abort the release.
class CleanCommand extends Command<void> {
  CleanCommand({
    @required this.checkouts,
  })  : platform = checkouts.platform,
        fileSystem = checkouts.fileSystem,
        stdio = checkouts.stdio {
    final String defaultPath = defaultStateFilePath(platform);
    argParser.addFlag(
      kYesFlag,
      help: 'Override confirmation checks.',
    );
    argParser.addOption(
      kStateOption,
      defaultsTo: defaultPath,
      help: 'Path to persistent state file. Defaults to $defaultPath',
    );
  }

  final Checkouts checkouts;
  final FileSystem fileSystem;
  final Platform platform;
  final Stdio stdio;

  @override
  String get name => 'clean';

  @override
  String get description => 'Cleanup persistent state file. '
      'This will abort a work in progress release.';

  @override
  void run() {
    final File stateFile = checkouts.fileSystem.file(argResults['state-file']);
    if (!stateFile.existsSync()) {
      throw ConductorException(
          'No persistent state file found at ${stateFile.path}!');
    }

    // TODO use flag
    stdio.printStatus('Deleting file ${stateFile.path}...');
    stateFile.deleteSync();
  }
}
