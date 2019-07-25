// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../globals.dart';
import '../project.dart';
import '../runner/flutter_command.dart';

class CleanCommand extends FlutterCommand {
  CleanCommand() {
    requiresPubspecYaml();
  }

  @override
  final String name = 'clean';

  @override
  final String description = 'Delete the build/ and .dart_tool/ directories.';

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FlutterProject flutterProject = FlutterProject.current();
    final Directory buildDir = fs.directory(getBuildDirectory());

    printStatus("Deleting '${buildDir.path}${fs.path.separator}'.");
    if (buildDir.existsSync()) {
      try {
        buildDir.deleteSync(recursive: true);
      } on FileSystemException catch (error) {
        if (platform.isWindows) {
          _windowsDeleteFailure(buildDir.path);
        }
        throwToolExit(error.toString());
      }
    }

    printStatus("Deleting '${flutterProject.dartTool.path}${fs.path.separator}'.");
    if (flutterProject.dartTool.existsSync()) {
      try {
        flutterProject.dartTool.deleteSync(recursive: true);
      } on FileSystemException catch (error) {
        if (platform.isWindows) {
          _windowsDeleteFailure(flutterProject.dartTool.path);
        }
        throwToolExit(error.toString());
      }
    }
    return const FlutterCommandResult(ExitStatus.success);
  }

  void _windowsDeleteFailure(String path) {
    printError(
      'Failed to remove $path. '
      'A program may still be using a file in the directory or the directory itself. '
      'To find and stop such a program, see: '
      'https://superuser.com/questions/1333118/cant-delete-empty-folder-because-it-is-used');
  }
}

