// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../artifacts.dart';
import '../../base/file_system.dart';
import '../../globals.dart';
import '../build_system.dart';

// Copies all of the input files to the correct copy dir.
Future<void> copyLinuxAssets(Map<String, ChangeType> updates,
    Environment environment) async {
  final String basePath = artifacts.getArtifactPath(Artifact.linuxDesktopPath);
  for (String input in updates.keys) {
    final String outputPath = fs.path.join(
      environment.projectDir.path,
      'linux',
      'flutter',
      fs.path.relative(input, from: basePath),
    );
    final File destinationFile = fs.file(outputPath);
    if (!destinationFile.parent.existsSync()) {
      destinationFile.parent.createSync(recursive: true);
    }
    fs.file(input).copySync(destinationFile.path);
  }
}

/// Copies the Linux desktop embedding files to the copy directory.
const Target unpackLinux = Target(
  name: 'unpack_linux',
  inputs: <Source>[
    Source.artifact(Artifact.linuxDesktopPath),
  ],
  outputs: <Source>[
    Source.pattern('{PROJECT_DIR}/linux/flutter/libflutter_linux.so'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/flutter_export.h'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/flutter_messenger.h'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/flutter_plugin_registrar.h'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/flutter_texture_registrar.h'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/flutter_glfw.h'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/icudtl.dat'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/cpp_client_wrapper/*'),
  ],
  dependencies: <Target>[],
  buildAction: copyLinuxAssets,
);
