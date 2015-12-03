// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/src/executable.dart' as executable;

import '../artifacts.dart';
import '../base/logging.dart';
import '../build_configuration.dart';
import '../runner/flutter_command.dart';
import '../test/loader.dart' as loader;

class TestCommand extends FlutterCommand {
  String get name => 'test';
  String get description => 'Runs Flutter unit tests for the current project. At least one of --debug and --release must be set.';

  bool get requiresProjectRoot => false;

  String get projectRootValidationErrorMessage {
    return 'Error: No pubspec.yaml file found.\n'
      'If you wish to run the tests in the flutter repo, pass --flutter-repo before\n'
      'any test paths. Otherwise, run this command from the root of your project.';
  }

  Future<String> _getShellPath(BuildConfiguration config) async {
    if (config.type == BuildType.prebuilt) {
      Artifact artifact = ArtifactStore.getArtifact(
        type: ArtifactType.shell, targetPlatform: config.targetPlatform);
      return await ArtifactStore.getPath(artifact);
    } else {
      switch (config.targetPlatform) {
        case TargetPlatform.linux:
          return path.join(config.buildDir, 'sky_shell');
        case TargetPlatform.mac:
          return path.join(config.buildDir, 'SkyShell.app', 'Contents', 'MacOS', 'SkyShell');
        default:
          throw new Exception('Unsupported platform.');
      }
    }
  }

  TestCommand() {
    argParser.addFlag('flutter-repo', help: 'Run tests from the Flutter repository instead of the current directory.', defaultsTo: false);
  }

  Iterable<String> _findTests(Directory directory) {
    return directory.listSync(recursive: true, followLinks: false)
                    .where((FileSystemEntity entity) => entity.path.endsWith('_test.dart') && FileSystemEntity.isFileSync(entity.path))
                    .map((FileSystemEntity entity) => path.absolute(entity.path));
  }

  Directory get _flutterUnitTestDir {
    return new Directory(path.join(ArtifactStore.flutterRoot, 'packages', 'unit', 'test'));
  }

  Future<int> _runTests(List<String> testArgs, Directory testDirectory) async {
    Directory currentDirectory = Directory.current;
    try {
      Directory.current = testDirectory;
      return await executable.main(testArgs);
    } finally {
      Directory.current = currentDirectory;
    }
  }

  @override
  Future<int> runInProject() async {
    List<String> testArgs = argResults.rest.map((String testPath) => path.absolute(testPath)).toList();

    final bool runFlutterTests = argResults['flutter-repo'];
    if (!runFlutterTests && !validateProjectRoot())
      return 1;

    // If we're running the flutter tests, we want to use the packages directory
    // from the unit package in order to find the proper shell binary.
    if (runFlutterTests && ArtifactStore.packageRoot == 'packages')
      ArtifactStore.packageRoot = path.join(ArtifactStore.flutterRoot, 'packages', 'unit', 'packages');

    Directory testDir = runFlutterTests ? _flutterUnitTestDir : Directory.current;

    if (testArgs.isEmpty)
      testArgs.addAll(_findTests(testDir));

    testArgs.insert(0, '--');
    if (Platform.environment['TERM'] == 'dumb')
      testArgs.insert(0, '--no-color');
    List<BuildConfiguration> configs = buildConfigurations;
    bool foundOne = false;
    loader.installHook();
    for (BuildConfiguration config in configs) {
      if (!config.testable)
        continue;
      foundOne = true;
      loader.shellPath = path.absolute(await _getShellPath(config));
      if (!FileSystemEntity.isFileSync(loader.shellPath)) {
          logging.severe('Cannot find Flutter shell at ${loader.shellPath}');
        return 1;
      }
      await _runTests(testArgs, testDir);
      if (exitCode != 0)
        return exitCode;
    }
    if (!foundOne) {
      stderr.writeln('At least one of --debug or --release must be set, to specify the local build products to test.');
      return 1;
    }

    return 0;
  }
}
