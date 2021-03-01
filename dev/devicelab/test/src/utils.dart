// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:collection/collection.dart' show ListEquality, MapEquality;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';

import '../common.dart';

const ProcessManager processManager = LocalProcessManager();

Future<ProcessResult> runScript(List<String> testNames,
    [List<String> otherArgs = const <String>[]]) async {
  final String dart = path.absolute(
      path.join('..', '..', 'bin', 'cache', 'dart-sdk', 'bin', 'dart'));
  final ProcessResult scriptProcess = processManager.runSync(<String>[
    dart,
    'bin/run.dart',
    ...otherArgs,
    for (final String testName in testNames) ...<String>['-t', testName],
  ]);
  return scriptProcess;
}

Future<void> expectScriptResult(List<String> testNames, int expectedExitCode, {
  String deviceId,
  List<String> taskArgs,
}) async {
  final List<String> args = <String>[
    if (deviceId != null)
      '-d', deviceId,
    ...?taskArgs
  ];
  final ProcessResult result = await runScript(testNames, args);
  expect(result.exitCode, expectedExitCode,
      reason:
          '[ stderr from test process ]\n\n${result.stderr}\n\n[ end of stderr ]'
          '\n\n[ stdout from test process ]\n\n${result.stdout}\n\n[ end of stdout ]');
}


CommandArgs cmd({
  String command,
  List<String> arguments,
  Map<String, String> environment,
}) {
  return CommandArgs(
    command: command,
    arguments: arguments,
    environment: environment,
  );
}

typedef ExitErrorFactory = dynamic Function();

@immutable
class CommandArgs {
  const CommandArgs({ this.command, this.arguments, this.environment });

  final String command;
  final List<String> arguments;
  final Map<String, String> environment;

  @override
  String toString() => 'CommandArgs(command: $command, arguments: $arguments, environment: $environment)';

  @override
  bool operator==(Object other) {
    if (other.runtimeType != CommandArgs)
      return false;
    return other is CommandArgs
        && other.command == command
        && const ListEquality<String>().equals(other.arguments, arguments)
        && const MapEquality<String, String>().equals(other.environment, environment);
  }

  @override
  int get hashCode => 17 * (17 * command.hashCode + _hashArguments) + _hashEnvironment;

  int get _hashArguments => arguments != null
    ? const ListEquality<String>().hash(arguments)
    : null.hashCode;

  int get _hashEnvironment => environment != null
    ? const MapEquality<String, String>().hash(environment)
    : null.hashCode;
}
