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

void main(List<String> args) {
  final ArgParser parser = ArgParser()
    ..addOption('linter-entrypoint', mandatory: true)
    ..addMultiOption('rules');
  final ArgResults results = parser.parse(args);

  final String linterEntrypoint = results['linter-entrypoint'] as String;
  final List<String> rules = results['rules'] as List<String>;
  final IssueReport report = lintDirRecursively(
    fs.directory('lib/src/web/file_generators'),
    fs.file(linterEntrypoint),
    rules,
  );
  print(report);
}

IssueReport lintDirRecursively(
  Directory dir,
  File linterEntrypoint,
  List<String> rules,
) {
  final IssueReport report = IssueReport();

  for (final FileSystemEntity entity in dir.listSync(recursive: true)) {
    if (entity is! File) {
      print('skipping $entity');
      continue;
    }
    lintFile(linterEntrypoint, entity, rules, report);
  }

  return report;
}

void lintFile(
  File linterEntrypoint,
  File sourceFile,
  List<String> rules,
  IssueReport report,
) {
  final String dart = io.Platform.resolvedExecutable;
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
    buffer.write('\n${issues.length} total issues in ${visitedFiles.length} files.');
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
