// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/file_system.dart';
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
  Future<FlutterCommandResult> runCommand() async {
    final FlutterProject flutterProject = await FlutterProject.current();
    final List<Directory> dirs = <Directory>[
      fs.directory(getBuildDirectory()),         // build/
      fs.directory(getAndroidBuildDirectory(flutterProject.isModule)),  // android/app/build/
      flutterProject.dartTool,                   // .dartTool/
    ];

    for (final Directory dir in dirs) {
      printStatus("Deleting '${dir.path}${fs.path.separator}'.");
      if (dir.existsSync()) {
        try {
          dir.deleteSync(recursive: true);
        } catch (error) {
          throwToolExit(error.toString());
        }
      }
    }

    return const FlutterCommandResult(ExitStatus.success);
  }
}

