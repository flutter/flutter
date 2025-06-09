// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../framework/utils.dart';

const String _dartCommand = 'dart';
const String _scriptFilePath = 'tools/bin/generate_gradle_lockfiles.dart';

/// Runs the gradle lockfiles check script and verifies that all lockfiles
/// are staged within git.
///
/// It executes `dev/tools/bin/generate_gradle_lockfiles.dart --no-gradle-generation`
/// to ensure Gradle lockfiles are consistent. It then checks `git status` for
/// any `.lockfile` files that are modified, new, or deleted but not staged.
///
/// Parameters:
///  - `flutterRootOverride`: Optional Flutter root path. Defaults to `flutterRoot`.
///
/// Throws an [Exception] if:
///  - `git status` fails (in a way that `eval` cannot recover output).
///  - Unstaged or modified `.lockfile` files are present.
Future<void> runGradleLockFilesCheck({
  ExecFunction execFn = exec,
  EvalFunction evalFn = eval,
  bool shouldPrintOutput = true,
}) async {
  print('Running gradle lockfiles check');
  bool needStashPop = true;

  try {
    final String stashOutput = await _getGitStashOutput(
      printOutput: shouldPrintOutput,
      evalFn: evalFn,
    );
    if (stashOutput.isNotEmpty && stashOutput.contains('No local changes to save')) {
      needStashPop = false;
    }

    await execFn(
      _dartCommand,
      <String>[_scriptFilePath, '--no-gradle-generation'],
      canFail: false,
      workingDirectory: flutterDirectory.path,
    );

    final String gitStatus = await _getGitStatusOutput(
      evalFn: evalFn,
      printOutput: shouldPrintOutput,
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
      print('Gradle lock files are up to date and correctly staged.');
      return;
    }

    final StringBuffer message = StringBuffer();
    message.writeln(
      'Gradle lockfiles are not up to date, or new/modified lockfiles are not staged.',
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
  } catch (e) {
    rethrow;
  } finally {
    if (needStashPop) {
      await execFn(
        'git',
        <String>['stash', 'pop'],
        canFail: true,
        workingDirectory: flutterDirectory.path,
      );
    } else {
      await execFn(
        'git',
        <String>['restore', '.'],
        canFail: true,
        workingDirectory: flutterDirectory.path,
      );
    }
  }
}

Set<String> _getFileChangesFromGitStatus(String currentGitState) {
  final Set<String> fileChanges = <String>{};
  final List<String> lines = currentGitState.split('\n');
  fileChanges.addAll(lines.map((String e) => e.trim()).where((String e) => e.isNotEmpty));
  return fileChanges;
}

Future<String> _getGitStatusOutput({required bool printOutput, EvalFunction evalFn = eval}) async {
  final String gitStatusOutput = await evalFn(
    'git',
    <String>['status', '--porcelain', '--untracked-files=all'],
    canFail: false,
    printStdout: printOutput,
    printStderr: printOutput,
  );
  return gitStatusOutput;
}

Future<String> _getGitStashOutput({required bool printOutput, EvalFunction evalFn = eval}) async {
  final String gitStatusOutput = await evalFn(
    'git',
    <String>['stash'],
    canFail: false,
    printStdout: printOutput,
    printStderr: printOutput,
  );
  return gitStatusOutput;
}
