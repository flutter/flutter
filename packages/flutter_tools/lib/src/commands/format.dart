// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import '../artifacts.dart';
import '../base/common.dart';
import '../globals.dart' as globals;
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
    argParser.addOption('line-length',
      abbr: 'l',
      help: 'Wrap lines longer than this length.',
      valueHelp: 'characters',
      defaultsTo: '80',
    );
  }

  @override
  final String name = 'format';

  @override
  List<String> get aliases => const <String>['dartfmt'];

  @override
  final String description = 'Format one or more Dart files.';

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

    final String dartSdk = globals.artifacts.getArtifactPath(Artifact.engineDartSdkPath);
    final String dartBinary = globals.artifacts.getArtifactPath(Artifact.engineDartBinary);
    final List<String> command = <String>[
      dartBinary,
      globals.fs.path.join(dartSdk, 'bin', 'snapshots', 'dartfmt.dart.snapshot'),
      if (boolArg('dry-run')) '-n',
      if (boolArg('machine')) '-m',
      if (argResults['line-length'] != null) '-l ${argResults['line-length']}',
      if (!boolArg('dry-run') && !boolArg('machine')) '-w',
      if (boolArg('set-exit-if-changed')) '--set-exit-if-changed',
      ...argResults.rest,
    ];

    final int result = await globals.processUtils.stream(command);
    if (result != 0) {
      throwToolExit('Formatting failed: $result', exitCode: result);
    }

    return FlutterCommandResult.success();
  }
}
