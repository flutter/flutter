// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../base/io.dart';
import '../../base/process_manager.dart';
import '../build_system.dart';

/// Copy the macOS framework to the correct copy dir by invoking 'cp -R'.
///
/// The shelling out is done to avoid complications with preserving special
/// files (e.g., symbolic links) in the framework structure.
///
/// Removes any previous version of the framework that already exists in the
/// target directory.
Future<void> copyFramework(Map<String, ChangeType> updates,
    Environment environment) async {
  // Ensure that the path is a framework, to minimize the potential for
  // catastrophic deletion bugs with bad arguments.
  if (fs.path.extension(updates.keys.single) != '.framework') {
    throw Exception('Attempted to delete a non-framework directory: ${updates.keys.single}');
  }
  final Directory input = fs.directory(updates.keys.single);
  final Directory targetDirectory = environment
    .projectDir
    .childDirectory('macos')
    .childDirectory('Flutter')
    .childDirectory('FlutterMacOS.framework');
  if (targetDirectory.existsSync()) {
    targetDirectory.deleteSync(recursive: true);
  }

  final ProcessResult result = processManager
      .runSync(<String>['cp', '-R', input.path, targetDirectory.path]);
  if (result.exitCode != 0) {
    throw Exception(
      'Failed to copy framework (exit ${result.exitCode}:\n'
      '${result.stdout}\n---\n${result.stderr}',
    );
  }
}

/// Copies the macOS desktop framework to the copy directory.
const Target unpackMacos = Target(
  name: 'unpack_macos',
  inputs: <Source>[
    Source.pattern('{CACHE_DIR}/{platform}/FlutterMacOS.framework/'),
  ],
  outputs: <Source>[
    Source.pattern('{PROJECT_DIR}/macos/Flutter/FlutterMacOS.framework/'),
  ],
  dependencies: <Target>[],
  platforms: <BuildPlatform>[
    BuildPlatform.macos,
  ],
  invocation: copyFramework,
);
