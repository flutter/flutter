// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';

class FormatCommand extends FlutterCommand {
  FormatCommand({required this.verboseHelp});

  @override
  ArgParser argParser = ArgParser.allowAnything();

  final bool verboseHelp;

  @override
  final String name = 'format';

  @override
  List<String> get aliases => const <String>['dartfmt'];

  @override
  final String description = 'Format one or more Dart files.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  String get invocation => '${runner?.executableName} $name <one or more paths>';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String dartBinary = globals.artifacts!.getHostArtifact(HostArtifact.engineDartBinary).path;
    final List<String> command = <String>[
      dartBinary,
      'format',
    ];
    final List<String> rest = argResults?.rest ?? <String>[];
    if (rest.isEmpty) {
      globals.printError(
        'No files specified to be formatted.'
      );
      command.add('-h');
    } else {
      command.addAll(<String>[
        for (String arg in rest)
          if (arg == '--dry-run' || arg == '-n')
            '--output=none'
          else
            arg
      ]);
    }

    final int result = await globals.processUtils.stream(command);
    if (result != 0) {
      throwToolExit('Formatting failed: $result', exitCode: result);
    }

    return FlutterCommandResult.success();
  }
}
