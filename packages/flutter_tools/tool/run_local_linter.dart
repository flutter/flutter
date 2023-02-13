// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as path;
import 'package:process/process.dart';

const LocalFileSystem fs = LocalFileSystem();
const LocalProcessManager processManager = LocalProcessManager();
final String dart = io.Platform.resolvedExecutable;
final Directory tempDir =
    fs.systemTempDirectory.createTempSync('flutter_tools.run_local_linter');

void main(List<String> args) {
  try {
    _main(args);
  } finally {
    try {
      tempDir.deleteSync(recursive: true);
    } on FileSystemException {
      // ignore
    }
  }
}

void _main(List<String> args) {
  final ArgParser parser = ArgParser()
    ..addOption('linter-entrypoint', mandatory: true)
    ..addMultiOption('rules');
  final ArgResults results = parser.parse(args);

  final String linterEntrypoint = results['linter-entrypoint'] as String;
  final List<String> rules = results['rules'] as List<String>;
  if (rules.isEmpty) {
    throw Exception('Must provide one or more --rules');
  }

  final Directory rootDir;
  if (results.rest.isEmpty) {
    rootDir = fs.directory('.');
  } else if (results.rest.length == 1) {
    rootDir = fs.directory(results.rest.first);
    if (!rootDir.existsSync()) {
      throw Exception(
          'The argument ${results.rest.first} is not a valid directory on disk.');
    }
  } else {
    throw Exception(
        'Too many arguments passed (expected 0 or 1): ${results.rest}');
  }
  final File linter = precompileLinter(linterEntrypoint);
  print('Starting recursive lint of $rootDir...\n');
  lintDirRecursively(
    rootDir,
    linter,
    rules,
  );
}

File precompileLinter(String linterEntrypoint) {
  final File snapshot = tempDir.childFile('linter-snapshot.jit');
  print('Precompiling $linterEntrypoint to ${snapshot.path}...');
  final io.ProcessResult result = processManager.runSync(
    <String>[
      dart,
      'compile',
      'jit-snapshot',
      '--output',
      snapshot.path,
      linterEntrypoint,
      'help'
    ],
  );
  if (result.exitCode != 0) {
    throw Exception(
        'Compiling JIT snapshot failed with code ${result.exitCode}\nSTDOUT: ${result.stdout}\nSTDERR: ${result.stderr}');
  }
  return snapshot;
}

void lintDirRecursively(
  Directory dir,
  File linterEntrypoint,
  List<String> rules,
) {
  final Iterable<String> allFiles = dir
      .listSync(recursive: true)
      .whereType<File>()
      .map((File file) => file.path);

  final io.ProcessResult result = processManager.runSync(
    <String>[
      dart,
      linterEntrypoint.path,
      ...allFiles,
      '--rules=${rules.join(',')}',
      '--machine',
    ],
  );

  if (result.exitCode == 0) {
    print('No issues found.');
    return;
  }
  final String stderr = result.stderr as String;
  if (stderr.isNotEmpty) {
    throw Exception(
      'Linter failed with code ${result.exitCode}\nSTDERR: $stderr\nSTDOUT: ${result.stdout}',
    );
  }
  final Iterable<Issue> issues = (result.stdout as String)
      .split('\n')
      .map<Issue?>((String line) => Issue.maybe(line))
      .whereType<Issue>();
  issues.forEach(print);
  print('\n${issues.length} total issues in ${allFiles.length} files.');
}

/// A single issue caught by the linter.
class Issue {
  Issue._({
    required this.rule,
    required this.library,
    required this.line,
    required this.col,
  });

  /// Parses a line of output from `dart linter.dart --machine`.
  ///
  /// Will return null if the line does not represent a linter issue.
  ///
  /// The format looks like:
  ///
  /// INFO|LINT|rule_name|/path/to/library.dart|288|30|356|Lint message.
  /// INFO|LINT|rule_name|/path/to/library.dart|973|12|463|Lint message.
  ///
  /// 1 file analyzed, 2 issues found, in 6987 ms.
  static Issue? maybe(String line) {
    final RegExpMatch? match = _pattern.firstMatch(line);
    if (match == null) {
      return null;
    }
    try {
      return Issue._(
        rule: match.group(3)!,
        library: _shortenLibraryPath(match.group(4)!),
        line: int.parse(match.group(5)!),
        col: int.parse(match.group(6)!),
      );
    } on TypeError {
      throw Exception('Failed to parse the line $line\n${match.group(0)}');
    }
  }

  static final RegExp _pattern = RegExp(
      r'([A-Z]+)\|([A-Z]+)\|([a-z_]+)\|(.*)\|(\d+)\|(\d+)\|(\d+)\|(.*)$');
  final String library;
  final String rule;
  final int line;
  final int col;

  static String _shortenLibraryPath(String absolutePath) {
    final List<String> components = path.split(absolutePath);
    final int rootIndex = components.indexOf('flutter_tools');
    return '//${components.sublist(rootIndex + 1).join(path.separator)}';
  }

  @override
  String toString() {
    return '$library $line:$col\t- $rule';
  }
}
