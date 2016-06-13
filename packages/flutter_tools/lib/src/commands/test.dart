// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/src/executable.dart' as executable; // ignore: implementation_imports

import '../base/logger.dart';
import '../dart/package_map.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';
import '../test/flutter_platform.dart' as loader;
import '../toolchain.dart';

class TestCommand extends FlutterCommand {
  TestCommand() {
    usesPubOption();
  }

  @override
  String get name => 'test';

  @override
  String get description => 'Run Flutter unit tests for the current project.';

  @override
  bool get requiresProjectRoot => false;

  @override
  Validator projectRootValidator = () {
    if (!FileSystemEntity.isFileSync('pubspec.yaml')) {
      printError(
        'Error: No pubspec.yaml file found in the current working directory.\n'
        'Run this command from the root of your project. Test files must be\n'
        'called *_test.dart and must reside in the package\'s \'test\'\n'
        'directory (or one of its subdirectories).');
      return false;
    }
    return true;
  };

  Iterable<String> _findTests(Directory directory) {
    return directory.listSync(recursive: true, followLinks: false)
                    .where((FileSystemEntity entity) => entity.path.endsWith('_test.dart') &&
                      FileSystemEntity.isFileSync(entity.path))
                    .map((FileSystemEntity entity) => path.absolute(entity.path));
  }

  Directory get _currentPackageTestDir {
    // We don't scan the entire package, only the test/ subdirectory, so that
    // files with names like like "hit_test.dart" don't get run.
    return new Directory('test');
  }

  Future<int> _runTests(List<String> testArgs, Directory testDirectory) async {
    Directory currentDirectory = Directory.current;
    try {
      if (testDirectory != null) {
        printTrace('switching to directory $testDirectory to run tests');
        PackageMap.globalPackagesPath = path.normalize(path.absolute(PackageMap.globalPackagesPath));
        Directory.current = testDirectory;
      }
      printTrace('running test package with arguments: $testArgs');
      await executable.main(testArgs);
      printTrace('test package returned with exit code $exitCode');
      return exitCode;
    } finally {
      Directory.current = currentDirectory;
    }
  }

  @override
  Future<int> runInProject() async {
    List<String> testArgs = argResults.rest.map((String testPath) => path.absolute(testPath)).toList();

    if (!projectRootValidator())
      return 1;

    Directory testDir;

    if (testArgs.isEmpty) {
      testDir = _currentPackageTestDir;
      if (!testDir.existsSync()) {
        printError("Test directory '${testDir.path}' not found.");
        return 1;
      }

      testArgs.addAll(_findTests(testDir));
    }

    testArgs.insert(0, '--');
    if (!terminal.supportsColor)
      testArgs.insert(0, '--no-color');

    loader.installHook();
    loader.shellPath = tools.getHostToolPath(HostTool.SkyShell);
    if (!FileSystemEntity.isFileSync(loader.shellPath)) {
        printError('Cannot find Flutter shell at ${loader.shellPath}');
      return 1;
    }
    return await _runTests(testArgs, testDir);
  }
}
