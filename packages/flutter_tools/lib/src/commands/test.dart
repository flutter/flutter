// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:test/src/executable.dart' as executable;

import 'flutter_command.dart';
import '../test/loader.dart' as loader;

final Logger _logging = new Logger('sky_tools.test');

class TestCommand extends FlutterCommand {
  final String name = 'test';
  final String description = 'Runs Flutter unit tests for the current project (requires a local build of the engine).';

  TestCommand() {
    argParser.addOption('build-dir', defaultsTo: '../../../engine/src/out/Debug');
  }

  String get _shellPath {
    if (Platform.isLinux)
      return path.join(argResults['build-dir'], 'sky_shell');
    if (Platform.isMacOS)
      return path.join(argResults['build-dir'], 'SkyShell.app', 'Contents', 'MacOS', 'SkyShell');
    throw new Exception('Unsupported platform.');
  }

  @override
  Future<int> runInProject() async {
    loader.shellPath = _shellPath;
    if (!FileSystemEntity.isFileSync(loader.shellPath)) {
      _logging.severe('Cannot find Flutter Shell at ${loader.shellPath}');
      return 1;
    }
    loader.installHook();
    await executable.main(argResults.rest);
    return exitCode;
  }
}
