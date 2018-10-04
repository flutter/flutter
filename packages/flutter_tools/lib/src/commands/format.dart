// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/process.dart';
import '../dart/sdk.dart';
import '../runner/flutter_command.dart';

class FormatCommand extends FlutterCommand {
  FormatCommand() {
    argParser.addFlag('dry-run',
      abbr: 'n',
      help: 'Show which files would be modified but make no changes.',
      defaultsTo: false,
      negatable: false,
    );
    argParser.addFlag('set-exit-if-changed',
      help: 'Return exit code 1 if there are any formatting changes.',
      defaultsTo: false,
      negatable: false,
    );
    argParser.addFlag('machine',
      abbr: 'm',
      help: 'Produce machine-readable JSON output.',
      defaultsTo: false,
      negatable: false,
    );
  }

  @override
  final String name = 'format';

  @override
  List<String> get aliases => const <String>['dartfmt'];

  @override
  final String description = 'Format one or more dart files.';

  @override
  String get invocation => '${runner.executableName} $name <one or more paths>';

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (argResults.rest.isEmpty) {
      throwToolExit(
        'No files specified to be formatted.\n'
        '\n'
        'To format all files in the current directory tree:\n'
        '${runner.executableName} $name .\n'
        '\n'
        '$usage'
      );
    }

    final String dartfmt = sdkBinaryName('dartfmt');
    final List<String> command = <String>[dartfmt];

    if (argResults['dry-run']) {
      command.add('-n');
    }
    if (argResults['machine']) {
      command.add('-m');
    }
    if (!argResults['dry-run'] && !argResults['machine']) {
      command.add('-w');
    }

    if (argResults['set-exit-if-changed']) {
      command.add('--set-exit-if-changed');
    }

    command..addAll(argResults.rest);

    final int result = await runCommandAndStreamOutput(command);
    if (result != 0)
      throwToolExit('Formatting failed: $result', exitCode: result);

    return null;
  }
}
