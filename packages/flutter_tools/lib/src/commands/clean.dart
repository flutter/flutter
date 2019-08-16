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
    final Directory buildDir = fs.directory(getBuildDirectory());
    _deleteFile(buildDir);

    final FlutterProject flutterProject = FlutterProject.current();
    _deleteFile(flutterProject.dartTool);

    final Directory androidEphemeralDirectory = flutterProject.android.ephemeralDirectory;
    _deleteFile(androidEphemeralDirectory);

    final Directory iosEphemeralDirectory = flutterProject.ios.ephemeralDirectory;
    _deleteFile(iosEphemeralDirectory);

    return const FlutterCommandResult(ExitStatus.success);
  }

  void _deleteFile(FileSystemEntity file) {
    final String path = file.path;
    printStatus("Deleting '$path${fs.path.separator}'.");
    if (file.existsSync()) {
      try {
        file.deleteSync(recursive: true);
      } on FileSystemException catch (error) {
        if (platform.isWindows) {
          printError(
            'Failed to remove $path. '
            'A program may still be using a file in the directory or the directory itself. '
            'To find and stop such a program, see: '
            'https://superuser.com/questions/1333118/cant-delete-empty-folder-because-it-is-used');
        }
        throwToolExit(error.toString());
      }
    }
  }
}

