// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/process.dart';
import '../globals.dart' as globals;
import '../runner/flutter_command.dart';

class FormatCommand extends FlutterCommand {
  @override
  ArgParser get argParser => _argParser;
  final ArgParser _argParser = ArgParser.allowAnything();

  @override
  final String name = 'format';

  @override
  List<String> get aliases => const <String>['dartfmt'];

  @override
  final String description = 'Format one or more dart files.';

  @override
  String get invocation => '${runner.executableName} $name <one or more paths>';

  @override
  bool get shouldUpdateCache => false;

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String dartBinary = globals.artifacts.getArtifactPath(Artifact.engineDartBinary);
    globals.printError(
      '"flutter format" is deprecated and will be removed in a'
      ' future release, use "dart format" instead.'
    );
    final List<String> command = <String>[
      dartBinary,
      'format',
      ...argResults.rest,
    ];

    final int result = await processUtils.stream(command);
    if (result != 0) {
      throwToolExit('', exitCode: result);
    }
    return FlutterCommandResult.success();
  }
}
