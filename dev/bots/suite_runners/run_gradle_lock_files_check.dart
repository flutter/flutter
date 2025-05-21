// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../run_command.dart';
import '../utils.dart';

const String dartCommand = 'dart';
const String scriptFilePath = 'tools/bin/generate_gradle_lockfiles.dart';

Future<void> runGradleLockFilesCheck() async {
  printProgress('${green}Running gradle lockfiles check$reset');

  await runCommand(dartCommand, <String>[
    scriptFilePath,
    '--no-gradle-generation',
  ], workingDirectory: flutterRoot);

  final String gitStatus = await getGitStatusOutput(flutterRoot);
  final Set<String> fileChanges = getFileChangesFromGitStatus(gitStatus);
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

  message.writeln("\nPlease run `$dartCommand $scriptFilePath` locally (if you haven't already),");
  message.writeln(
    'then `git add` the files listed below and commit the changes to your pull request.',
  );

  for (final String file in filesNeedTracking) {
    message.writeln('  $file');
  }
  throw Exception(message.toString());
}

Set<String> getFileChangesFromGitStatus(String currentGitState) {
  final Set<String> fileChanges = <String>{};
  final List<String> lines = currentGitState.split('\n');
  for (final String line in lines) {
    final String trimmedLine = line.trim();
    if (trimmedLine.length > 3) {
      fileChanges.add(trimmedLine);
    }
  }
  return fileChanges;
}

Future<String> getGitStatusOutput(String workingDirectory) async {
  final CommandResult result = await runCommand(
    'git',
    <String>['status', '--porcelain', '--untracked-files=all'],
    workingDirectory: workingDirectory,
    outputMode: OutputMode.capture,
  );

  final String? flattenedStdout = result.flattenedStdout;
  if (flattenedStdout == null) {
    throw Exception('Could not get git status output.');
  }

  return flattenedStdout;
}
