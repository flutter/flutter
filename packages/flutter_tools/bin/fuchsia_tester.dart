// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/args.dart';
import 'package:process/process.dart';
import 'package:test/src/executable.dart'
    as test; // ignore: implementation_imports

import '../lib/src/base/common.dart';
import '../lib/src/base/config.dart';
import '../lib/src/base/context.dart';
import '../lib/src/base/file_system.dart';
import '../lib/src/base/io.dart';
import '../lib/src/base/logger.dart';
import '../lib/src/base/os.dart';
import '../lib/src/base/platform.dart';
import '../lib/src/cache.dart';
import '../lib/src/dart/package_map.dart';
import '../lib/src/globals.dart';
import '../lib/src/test/flutter_platform.dart' as loader;
import '../lib/src/usage.dart';

// Note: this was largely inspired by lib/src/commands/test.dart.

const String _kOptionPackages = "packages";
const String _kOptionShell = "shell";
const String _kOptionTestDirectory = "test-directory";
const List<String> _kRequiredOptions = const <String>[
  _kOptionPackages,
  _kOptionShell,
  _kOptionTestDirectory,
];

Future<Null> main(List<String> args) async {
  final AppContext executableContext = new AppContext();
  executableContext.setVariable(Logger, new StdoutLogger());
  executableContext.runInZone(() {
    // Initialize the context with some defaults.
    context.putIfAbsent(Platform, () => const LocalPlatform());
    context.putIfAbsent(FileSystem, () => const LocalFileSystem());
    context.putIfAbsent(ProcessManager, () => const LocalProcessManager());
    context.putIfAbsent(Logger, () => new StdoutLogger());
    context.putIfAbsent(Cache, () => new Cache());
    context.putIfAbsent(Config, () => new Config());
    context.putIfAbsent(OperatingSystemUtils, () => new OperatingSystemUtils());
    context.putIfAbsent(Usage, () => new Usage());
    return run(args);
  });
}

Iterable<String> _findTests(Directory directory) {
  return directory
      .listSync(recursive: true, followLinks: false)
      .where((FileSystemEntity entity) =>
          entity.path.endsWith('_test.dart') && fs.isFileSync(entity.path))
      .map((FileSystemEntity entity) => fs.path.absolute(entity.path));
}

Future<Null> run(List<String> args) async {
  final ArgParser parser = new ArgParser()
    ..addOption(_kOptionPackages, help: 'The .packages file')
    ..addOption(_kOptionShell, help: 'The Flutter shell binary')
    ..addOption(_kOptionTestDirectory, help: 'Directory containing the tests');
  final ArgResults argResults = parser.parse(args);
  if (_kRequiredOptions
      .any((String option) => !argResults.options.contains(option))) {
    printError('Missing option! All options must be specified.');
    exit(1);
  }
  final Directory tempDirectory =
      fs.systemTempDirectory.createTempSync('fuchsia_tester');
  try {
    Cache.flutterRoot = tempDirectory.path;
    final Directory testDirectory =
        fs.directory(argResults[_kOptionTestDirectory]);
    final Iterable<String> tests = _findTests(testDirectory);

    final List<String> testArgs = <String>[];
    testArgs.add('--');
    testArgs.addAll(tests);

    final String shellPath = argResults[_kOptionShell];
    if (!fs.isFileSync(shellPath)) {
      throwToolExit('Cannot find Flutter shell at $shellPath');
    }
    loader.installHook(
      shellPath: shellPath,
    );

    PackageMap.globalPackagesPath =
        fs.path.normalize(fs.path.absolute(argResults[_kOptionPackages]));
    fs.currentDirectory = testDirectory;

    await test.main(testArgs);
    exit(exitCode);
  } finally {
    tempDirectory.deleteSync(recursive: true);
  }
}
