// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../globals.dart';
import '../runner/flutter_command.dart';
import '../base/process.dart' show RunResult, processUtils;
import '../artifacts.dart' show Artifact;

class DartCommand extends FlutterCommand {
  @override
  String get description => 'Run the Flutter Dart SDK for use.';

  @override
  String get name => 'dart';

  @override
  String get invocation =>
      '${runner.executableName} $name <dart file or snapshot dart file> [args]';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final String engineDartPath =
        artifacts.getArtifactPath(Artifact.engineDartBinary);
    final List<String> runList = <String>[engineDartPath];
    if (argResults.arguments.isNotEmpty) {
      final List<String> args = <String>[...argResults.arguments];
      final String dartFileToRun = args[0];
      args.remove(dartFileToRun);
      runList.add(dartFileToRun);
      runList.addAll(args);
    }
    final RunResult run = processUtils.runSync(runList);
    print(run);

    return const FlutterCommandResult(ExitStatus.success);
  }
}
