// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:test/src/executable.dart' as executable;

import '../artifacts.dart';
import '../build_configuration.dart';
import '../test/loader.dart' as loader;
import 'flutter_command.dart';

final Logger _logging = new Logger('flutter_tools.test');

class TestCommand extends FlutterCommand {
  String get name => 'test';
  String get description => 'Runs Flutter unit tests for the current project. At least one of --debug and --release must be set.';

  bool get requiresProjectRoot => false;

  String getShellPath(TargetPlatform platform, String buildPath) {
    switch (platform) {
      case TargetPlatform.linux:
        return path.join(buildPath, 'sky_shell');
      case TargetPlatform.mac:
        return path.join(buildPath, 'SkyShell.app', 'Contents', 'MacOS', 'SkyShell');
      default:
        throw new Exception('Unsupported platform.');
    }
  }

  @override
  Future<int> runInProject() async {
    List<String> testArgs = argResults.rest.toList();
    Directory flutterDir = new Directory(path.join(ArtifactStore.flutterRoot, 'packages/unit')); // see https://github.com/flutter/flutter/issues/50
    Directory testDir = new Directory(path.join(flutterDir.path, 'test'));
    if (testArgs.isEmpty) {
      testArgs.addAll(testDir.listSync(recursive: true, followLinks: false)
                             .where((FileSystemEntity entity) => entity.path.endsWith('_test.dart') && FileSystemEntity.isFileSync(entity.path))
                             .map((FileSystemEntity entity) => path.absolute(entity.path)));
    }
    testArgs.insert(0, '--');
    if (Platform.environment['TERM'] == 'dumb')
      testArgs.insert(0, '--no-color');
    List<BuildConfiguration> configs = buildConfigurations;
    bool foundOne = false;
    String currentDirectory = Directory.current.path;
    Directory.current = flutterDir.path;
    loader.installHook();
    for (BuildConfiguration config in configs) {
      if (!config.testable)
        continue;
      foundOne = true;
      loader.shellPath = path.join(currentDirectory, getShellPath(config.targetPlatform, config.buildDir));
      if (!FileSystemEntity.isFileSync(loader.shellPath)) {
          _logging.severe('Cannot find Flutter shell at ${loader.shellPath}');
        return 1;
      }
      await executable.main(testArgs);
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