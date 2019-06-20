// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../build_system.dart';

// Copies all of the input files to the correct copy dir.
Future<void> copyLinuxAssets(Map<String, ChangeType> updates,
  Environment environment) async {
  final String basePath = fs.path.join(
    environment.cacheDir.absolute.path,
    'linux-x64',
  );
  for (String input in updates.keys) {
    final String outputPath = fs.path.join(
      environment.projectDir.path,
      'windows',
      'linux-x64',
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
    Source.pattern('{CACHE_DIR}/{platform}/libflutter_linux.so'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_export.h'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_messenger.h'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_plugin_registrar.h'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_glfw.h'),
    Source.pattern('{CACHE_DIR}/{platform}/icudtl.dat'),
    Source.pattern('{CACHE_DIR}/{platform}/cpp_client_wrapper/*'),
  ],
  outputs: <Source>[
    Source.pattern('{PROJECT_DIR}/linux/flutter/libflutter_linux.so'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/flutter_export.h'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/flutter_messenger.h'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/flutter_plugin_registrar.h'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/flutter_glfw.h'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/icudtl.dat'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/cpp_client_wrapper/*'),
  ],
  dependencies: <Target>[],
  platforms: <BuildPlatform>[
    BuildPlatform.linux,
  ],
  invocation: copyLinuxAssets,
);
