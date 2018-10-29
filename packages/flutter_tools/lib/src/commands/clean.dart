// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/file_system.dart';
import '../build_info.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class CleanCommand extends FlutterCommand {
  CleanCommand() {
    requiresPubspecYaml();
  }

  @override
  final String name = 'clean';

  @override
  final String description = 'Delete the build/ directory.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    final Directory buildDir = fs.directory(getBuildDirectory());
    printStatus("Deleting '${buildDir.path}${fs.path.separator}'.");

    if (!buildDir.existsSync())
      return null;

    try {
      buildDir.deleteSync(recursive: true);
    } catch (error) {
      throwToolExit(error.toString());
    }

    return null;
  }
}
