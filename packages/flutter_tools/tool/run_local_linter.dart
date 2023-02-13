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
late final Directory tempDir =
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
  final IssueReport report = lintDirRecursively(
    rootDir,
    linter,
    rules,
  );
  print(report);
}

File precompileLinter(String linterEntrypoint) {
  final File snapshot = tempDir.childFile('linter-snapshot.jit');
  print('Precompiling $linterEntrypoint to ${snapshot.path}...');
  final io.ProcessResult result = processManager.runSync(
    <String>[dart, 'compile', 'jit-snapshot', '--output', snapshot.path, linterEntrypoint],
  );
  if (result.exitCode != 0) {
    throw Exception('Compiling JIT snapshot failed with code ${result.exitCode}\nSTDOUT: ${result.stdout}\nSTDERR: ${result.stderr}');
  }
  return snapshot;
}

IssueReport lintDirRecursively(
  Directory dir,
  File linterEntrypoint,
  List<String> rules,
) {
  final IssueReport report = IssueReport();

  final List<File> allFiles =
      dir.listSync(recursive: true).whereType<File>().toList();

  // This var to be referenced from the [write] closure.
  int lastLineLength = 0;

  void write(String str) {
    io.stdout.write(str.padRight(lastLineLength));
    lastLineLength = str.length;
  }

  for (final File file in allFiles) {
    lintFile(linterEntrypoint, file, rules, report, allFiles.length, write);
  }

  // Two newlines
  print('\n');

  return report;
}

void lintFile(
  File linterEntrypoint,
  File sourceFile,
  List<String> rules,
  IssueReport report,
  int totalFiles,
  void Function(String) write,
) {
  if (!linterEntrypoint.existsSync()) {
    throw Exception(
        'Expected ${linterEntrypoint.absolute.path} to exist, but it did not.');
  }
  if (!sourceFile.existsSync()) {
    throw Exception(
        'Expected ${sourceFile.absolute.path} to exist, but it did not.');
  }
  if (rules.isEmpty) {
    throw Exception('Must provide one or more --rules');
  }

  final io.ProcessResult result = processManager.runSync(
    <String>[
      dart,
      linterEntrypoint.path,
      sourceFile.path,
      '--rules=${rules.join(',')}',
      '--machine',
    ],
  );
  report.visitedFiles.add(sourceFile.path);
  write(
    '\rLinted ${report.visitedFiles.length.toString().padLeft(3)} of '
    '$totalFiles files (${report.issues.length} issues found) - last '
    'file: ${sourceFile.path}',
  );
  if (result.exitCode != 0) {
    report.addBlob(result.stdout as String);
  }
}

class IssueReport {
  IssueReport();

  final List<String> blobs = <String>[];
  final List<Issue> issues = <Issue>[];
  final List<String> visitedFiles = <String>[];

  void addBlob(String blob) {
    blobs.add(blob);
    issues.addAll(
      blob
          .split('\n')
          .map<Issue?>((String line) => Issue.maybe(line))
          .whereType<Issue>()
          .toList(),
    );
  }

  @override
  String toString() {
    final StringBuffer buffer = StringBuffer();
    issues.forEach(buffer.writeln);
    buffer.write(
      '\n${issues.length} total issues in ${visitedFiles.length} files.',
    );
    return buffer.toString();
  }
}

class Issue {
  Issue._({
    required this.rule,
    required this.library,
    required this.line,
    required this.col,
  });
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
