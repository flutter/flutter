// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';

import '../tools/bin/find_commit.dart' hide main;
import 'run_tests.dart' hide main;

const FileSystem fs = LocalFileSystem();

/// Utility function to run a [Process] and return [Process.stdout].
///
/// Throws [ProcessException] is [Process.exitCode] is non-0.
String cmd(
  String executable,
  List<String> args, {
  Directory? workingDirectory,
}) {
  workingDirectory ??= fs.currentDirectory;
  print('Executing $executable ${args.join(' ')} in ${workingDirectory.path}');
  final ProcessResult result = Process.runSync(
    executable,
    args,
    workingDirectory: workingDirectory.path,
  );
  print(result.stdout);

  if (result.exitCode != 0) {
    print(result.stderr);
    throw ProcessException(executable, args, result.stderr as String, result.exitCode);
  }

  return result.stdout as String;
}

Future<void> main(List<String> args) async {
  // This script does not assume that "flutter update-packages" has been run,
  // to allow CIs to save time by skipping that step since only a minimal set
  // of dependencies are necessary to run the flutter/tests tests.
  //
  // Only customer_testing (this directory) and tools are needed.
  final String dart = fs.currentDirectory.parent.parent.childDirectory('bin').childFile('dart').path;
  cmd(dart, <String>['pub', 'get'], workingDirectory: fs.currentDirectory.parent.childDirectory('tools'));

  // Next is updating the flutter/tests checkout
  //
  // This relies on tools/bin/find_commit.dart to pull the version of flutter/tests
  // that was contemporary at the time of the current flutter checkout. This enables
  // the tests to run on release branches without being affected by breaking changes.
  //
  // This also prevents trunk from suddenly failing when tests are revved on flutter/tests.
  // If you rerun a passing customer_tests shard, it should still pass, even if the tests
  // are rolled to a new version.
  final Directory testsCheckout = fs.currentDirectory.parent.parent
      .childDirectory('bin')
      .childDirectory('cache')
      .childDirectory('pkg')
      .childDirectory('tests');
  if (testsCheckout.existsSync()) {
    testsCheckout.deleteSync(recursive: true);
  }
  testsCheckout.createSync(recursive: true);
  cmd('git', <String>['clone', 'https://github.com/flutter/tests.git'], workingDirectory: testsCheckout.parent);
  // Find where the current framework tree diverged from flutter/tests.
  // If flutter/tests has no commits after this framework checkout, it will revv to tip of tree.
  final String gitRevision = findCommit(
    primaryRepoDirectory: fs.currentDirectory.path,
    primaryBranch: git(fs.currentDirectory.path, <String>['rev-parse', '--abbrev-ref', 'HEAD']).trim(),
    primaryTrunk: 'master',
    secondaryRepoDirectory: testsCheckout.path,
    secondaryBranch: 'master',
  );
  // Check out the relevant flutter/tests revision
  cmd('git', <String>[
    '-C',
    testsCheckout.path,
    'checkout',
    gitRevision,
  ]);

  await run(args);
}
