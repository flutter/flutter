// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

/// Calculates the amount of formatting changes in a given directory of code.
///
/// This should be run with a path to a directory. That directory should
/// contain a Git repo. The committed state of the repo should be the formatted
/// output before the change in question. Then the result of the new formatting
/// should be unstaged changes.
///
/// Uses `git diff --shortstat` to calculate the number of changed lines.
///
/// Counts the number of lines of Dart code by reading the files.
void main(List<String> arguments) {
  if (arguments.length != 1) {
    print('Usage: change_metrics.dart <dir>');
    exit(1);
  }

  var directory = arguments[0];
  var totalLines = 0;
  var totalFiles = 0;

  print('Counting lines...');
  for (var entry in Directory(directory).listSync(recursive: true)) {
    if (entry is File && entry.path.endsWith('.dart')) {
      try {
        var lines = entry.readAsLinesSync();
        totalFiles++;
        totalLines += lines.length;
      } catch (error) {
        print('Could not read ${entry.path}:\n$error');
      }
    }
  }

  print('Getting diff stats...');
  var result = Process.runSync('git', ['diff', '--shortstat'],
      // Make sure the user's local Git config doesn't affect the output.
      environment: {
        'GIT_CONFIG_NOGLOBAL': 'true',
        'GIT_CONFIG_NOSYSTEM': 'true',
      },
      workingDirectory: directory);
  if (result.exitCode != 0) {
    print('Git failure:\n${result.stdout}\n${result.stderr}');
    exit(1);
  }

  var stdout = result.stdout as String;
  var insertions = _parseGitStdout(stdout, r'(\d+) insertions');
  var deletions = _parseGitStdout(stdout, r'(\d+) deletions');
  var changes = insertions + deletions;

  print('$totalLines lines in $totalFiles files');
  print('$insertions insertions + $deletions deletions = $changes changes');
  var linesPerChange = totalLines / changes;
  print('1 changed line for every ${linesPerChange.toStringAsFixed(2)} '
      'lines of code');

  var changesPerLine = 1000.0 * changes / totalLines;
  print('${changesPerLine.toStringAsFixed(4)} '
      'changed lines for every 1,000 lines of code');
}

int _parseGitStdout(String stdout, String pattern) {
  var match = RegExp(pattern).firstMatch(stdout);
  if (match == null) {
    print('Could not parse Git output:\n$stdout');
    exit(1);
  }

  return int.parse(match[1]!);
}
