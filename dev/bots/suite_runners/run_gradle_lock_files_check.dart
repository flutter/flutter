// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../run_command.dart';
import '../utils.dart';

const String _dartCommand = 'dart';
const String _scriptFilePath = 'tools/bin/generate_gradle_lockfiles.dart';

/// Runs the gradle lockfiles check script and verifies that all lockfiles
/// are staged within git.
///
/// It executes `dev/tools/bin/generate_gradle_lockfiles.dart --no-gradle-generation`
/// to ensure Gradle lockfiles are consistent. It then checks `git status` for
/// any `.lockfile` files that are modified, new, or deleted but not staged.
///
///
/// Parameters:
///  - `runCommand`: Callable to execute shell commands. Defaults to `runCommand`.
///  - `outputMode`: Command output mode. Defaults to `OutputMode.print`.
///  - `flutterRootOverride`: Optional Flutter root path. Defaults to `flutterRoot`.
///
/// Throws an [Exception] if:
///  - `git status` fails.
///  - Unstaged or modified `.lockfile` files are present.
Future<void> runGradleLockFilesCheck({
  RunCommandCallable runCommand = runCommand,
  OutputMode outputMode = OutputMode.print,
  String? flutterRootOverride,
}) async {
  final String effectiveFlutterRoot = flutterRootOverride ?? flutterRoot;
  printProgress('${green}Running gradle lockfiles check$reset');

  await runCommand(
    _dartCommand,
    <String>[_scriptFilePath, '--no-gradle-generation'],
    workingDirectory: effectiveFlutterRoot,
    expectNonZeroExit: false,
    outputMode: outputMode,
  );

  final String gitStatus = await _getGitStatusOutput(
    workingDirectory: effectiveFlutterRoot,
    runCommand: runCommand,
    outputMode: outputMode,
  );
  final Set<String> fileChanges = _getFileChangesFromGitStatus(gitStatus);
  final Set<String> filesNeedTracking = <String>{};

  if (fileChanges.isNotEmpty) {
    for (final String fileChange in fileChanges) {
      if (fileChange.endsWith('.lockfile')) {
        filesNeedTracking.add(fileChange);
      }
    }
  }

  if (filesNeedTracking.isEmpty) {
    printProgress('${green}Gradle lock files are up to date and correctly staged.$reset');
    return;
  }

  final StringBuffer message = StringBuffer();
  message.writeln(
    '${red}Gradle lockfiles are not up to date, or new/modified lockfiles are not staged.$reset',
  );

  message.writeln(
    "\nPlease run `$_dartCommand $_scriptFilePath` locally (if you haven't already),",
  );
  message.writeln(
    'then `git add` the files listed below and commit the changes to your pull request.',
  );

  for (final String file in filesNeedTracking) {
    message.writeln('  $file');
  }
  throw Exception(message.toString());
}

Set<String> _getFileChangesFromGitStatus(String currentGitState) {
  final Set<String> fileChanges = <String>{};
  final List<String> lines = currentGitState.split('\n');
  fileChanges.addAll(lines.map((String e) => e.trim()).where((String e) => e.isNotEmpty));
  return fileChanges;
}

Future<String> _getGitStatusOutput({
  required String workingDirectory,
  required RunCommandCallable runCommand,
  OutputMode outputMode = OutputMode.print,
}) async {
  final CommandResult result = await runCommand(
    'git',
    <String>['status', '--porcelain', '--untracked-files=all'],
    workingDirectory: workingDirectory,
    expectNonZeroExit: false,
    outputMode: outputMode,
  );

  final String? flattenedStdout = result.flattenedStdout;
  if (flattenedStdout == null) {
    throw Exception('Could not get git status output.');
  }

  return flattenedStdout;
}
