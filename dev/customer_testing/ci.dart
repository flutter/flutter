// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

/// To run this script, either:
///
/// ```sh
/// cd dev/customer_testing
/// dart ci.dart [--include=<glob>]... [--exclude=<glob>]... [sha]
/// ```
///
/// Or:
///
/// ```sh
/// ./dev/customer_testing/ci.sh [args...]
/// ./dev/customer_testing/ci.bat [args...]
/// ```
///
/// `--include` and `--exclude` are globs matched against `registry/*.test`
/// file names, used to split the registry across CI shards.
void main(List<String> args) async {
  final argParser = ArgParser()
    ..addMultiOption(
      'include',
      help: 'Only run registry files whose name matches this glob. Can be repeated.',
      valueHelp: 'glob',
    )
    ..addMultiOption(
      'exclude',
      help: 'Skip registry files whose name matches this glob. Can be repeated.',
      valueHelp: 'glob',
    );

  final ArgResults parsedArgs;
  try {
    parsedArgs = argParser.parse(args);
  } on ArgParserException catch (error) {
    io.stderr.writeln(error.message);
    io.stderr.writeln('Usage: dart ci.dart [--include=<glob>]... [--exclude=<glob>]... [sha]');
    io.exitCode = 1;
    return;
  }

  final String sha;
  if (parsedArgs.rest.isEmpty) {
    sha = io.File('tests.version').readAsStringSync().trim();
  } else if (parsedArgs.rest.length == 1) {
    sha = parsedArgs.rest.first;
  } else {
    io.stderr.writeln('Usage: dart ci.dart [--include=<glob>]... [--exclude=<glob>]... [sha]');
    io.exitCode = 1;
    return;
  }
  final List<Glob> includes = parsedArgs.multiOption('include').map(Glob.new).toList();
  final List<Glob> excludes = parsedArgs.multiOption('exclude').map(Glob.new).toList();

  final String flutterRootPath = p.canonicalize('../../');
  final testsCacheDir = io.Directory(p.join(flutterRootPath, 'bin', 'cache', 'pkg', 'tests'));

  if (testsCacheDir.existsSync()) {
    io.stderr.writeln('Cleaning up existing repo: ${testsCacheDir.path}');
    testsCacheDir.deleteSync(recursive: true);
  }

  io.stderr.writeln('Cloning flutter/tests');
  final io.Process clone = await io.Process.start('git', <String>[
    'clone',
    '--depth',
    '1',
    'https://github.com/flutter/tests.git',
    testsCacheDir.path,
  ], mode: io.ProcessStartMode.inheritStdio);
  if ((await clone.exitCode) != 0) {
    io.exitCode = 1;
    return;
  }

  io.stderr.writeln('Fetching/checking out $sha');
  final io.Process fetch = await io.Process.start(
    'git',
    <String>['fetch', 'origin', sha],
    mode: io.ProcessStartMode.inheritStdio,
    workingDirectory: testsCacheDir.path,
  );
  if ((await fetch.exitCode) != 0) {
    io.exitCode = 1;
    return;
  }
  final io.Process checkout = await io.Process.start(
    'git',
    <String>['checkout', sha],
    mode: io.ProcessStartMode.inheritStdio,
    workingDirectory: testsCacheDir.path,
  );
  if ((await checkout.exitCode) != 0) {
    io.exitCode = 1;
    return;
  }

  final registryDir = io.Directory(p.join(testsCacheDir.path, 'registry'));
  // run_tests.dart parses its arguments as globs, so avoid backslashes.
  final List<String> testFiles =
      registryDir
          .listSync()
          .whereType<io.File>()
          .map((io.File file) => p.basename(file.path))
          .where((String name) {
            return p.extension(name) == '.test' &&
                (includes.isEmpty || includes.any((Glob glob) => glob.matches(name))) &&
                !excludes.any((Glob glob) => glob.matches(name));
          })
          .map((String name) => p.posix.joinAll(<String>[...p.split(registryDir.path), name]))
          .toList()
        ..sort();
  if (testFiles.isEmpty) {
    io.stderr.writeln(
      'No registry files matched --include=$includes --exclude=$excludes in ${registryDir.path}',
    );
    io.exitCode = 1;
    return;
  }

  io.stderr.writeln('Running tests...');
  final io.Process test = await io.Process.start('dart', <String>[
    '--enable-asserts',
    'run_tests.dart',
    '--skip-on-fetch-failure',
    '--skip-template',
    ...testFiles,
  ], mode: io.ProcessStartMode.inheritStdio);
  if ((await test.exitCode) != 0) {
    io.exitCode = 1;
    return;
  }
}
