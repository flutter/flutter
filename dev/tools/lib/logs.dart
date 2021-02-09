// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show jsonDecode;

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

import './globals.dart' show ConductorException;
import './proto/conductor_state.pb.dart' as pb;
import './state.dart';
import './stdio.dart';

/// Command to print the logs from the current Flutter release.
class LogsCommand extends Command<void> {
  LogsCommand({
    @required this.fileSystem,
    @required this.platform,
    @required this.stdio,
  }) {
    final String defaultPath = defaultStateFilePath(platform);
    argParser.addOption(
      'state-file',
      defaultsTo: defaultPath,
      help: 'Path to persistent state file. Defaults to $defaultPath',
    );
  }

  final FileSystem fileSystem;
  final Platform platform;
  final Stdio stdio;

  @override
  String get name => 'logs';

  @override
  String get description => 'Print the logs of the current release.';

  @override
  void run() {
    final File stateFile = fileSystem.file(argResults['state-file']);
    if (!stateFile.existsSync()) {
      throw ConductorException('No persistent state file found at ${stateFile.path}.');
    }
    final pb.ConductorState state = pb.ConductorState()
      ..mergeFromProto3Json(
        jsonDecode(stateFile.readAsStringSync()),
      );
    state.logs.forEach(stdio.printStatus);
  }
}
