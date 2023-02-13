// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:process/process.dart';

const LocalFileSystem fs = LocalFileSystem();
const LocalProcessManager processManager = LocalProcessManager();

void main(List<String> args) {
  final ArgParser parser = ArgParser()
      ..addOption('linter-entrypoint',
        mandatory: true)
      ..addMultiOption('rules');
  final ArgResults results = parser.parse(args);

  final String linterEntrypoint = results['linter-entrypoint'] as String;
  final List<String> rules = results['rules'] as List<String>;
  final IssueReport? report = lintFile('lib/src/vmservice.dart', linterEntrypoint, rules);
  print(report);
}

IssueReport? lintFile(String filePath, String linterEntrypointPath, List<String> rules) {
  final String dart = io.Platform.resolvedExecutable;
  final File linterEntrypoint = fs.file(linterEntrypointPath);
  if (!linterEntrypoint.existsSync()) {
    throw Exception('Expected ${linterEntrypoint.absolute.path} to exist, but it did not.');
  }
  final File sourceFile = fs.file(filePath);
  if (!sourceFile.existsSync()) {
    throw Exception('Expected $filePath to exist, but it did not.');
  }
  if (rules.isEmpty) {
    throw Exception('Must provide one or more --rules');
  }

  final io.ProcessResult result = processManager.runSync(
    <String>[
      dart,
      linterEntrypointPath,
      filePath,
      '--rules=${rules.join(',')}',
      '--machine',
    ],
  );
  if (result.exitCode != 0) {
    return IssueReport(result.stdout as String);
  }
  return null;
}

class IssueReport {
  IssueReport(this.blob);

  final String blob;
}
