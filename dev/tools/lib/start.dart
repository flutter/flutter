// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

import './globals.dart';
import './proto/conductor_state.pb.dart' as pb;
import './repository.dart';
import './state.dart';
import './stdio.dart';

/// Command to print the status of the current Flutter release.
class StartCommand extends Command<void> {
  StartCommand({
    @required this.checkouts,
    @required this.stdio,
  })  : platform = checkouts.platform,
        fileSystem = checkouts.fileSystem {
    final String defaultPath = defaultStateFilePath(platform);
    argParser.addOption(
      'release-channel',
      help: 'The target release channel for the release.',
      allowed: <String>['stable', 'beta', 'dev'],
    );
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
  String get name => 'start';

  @override
  String get description => 'Start a new Flutter release.';

  @override
  void run() {
    if (!argResults.wasParsed('release-channel')) {
      throw ConductorException(
          'The command line option `--release-channel` must be provided');
    }
    final File stateFile = checkouts.fileSystem.file(argResults['state-file']);
    if (stateFile.existsSync()) {
      stdio.printError(
          'Error! A persistent state file already found at ${argResults['state-file']}.');
      stdio.printError('Run `conductor abort` to cancel previous release.');
    } else {
      final pb.ConductorState state = pb.ConductorState();
      state.releaseChannel = argResults['release-channel'] as String;
      // TODO

      stateFile.writeAsStringSync(state.writeToJson(), flush: true);
    }
  }
}
