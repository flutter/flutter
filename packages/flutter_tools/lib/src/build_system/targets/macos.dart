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
// TODO(jonahwilliams): remove shell out.
Future<void> copyFramework(Map<String, ChangeType> updates,
    Environment environment) async {
  final Directory input = fs.directory(fs.path.join(
    environment.cacheDir.path,
    'artifacts',
    'engine',
    'darwin-x64',
    'FlutterMacOS.framework',
  ));
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
    Source.pattern('{CACHE_DIR}/artifacts/engine/darwin-x64/FlutterMacOS.framework/FlutterMacOS'),
    // Headers
    Source.pattern('{CACHE_DIR}/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FLEOpenGLContextHandling.h'),
    Source.pattern('{CACHE_DIR}/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FLEReshapeListener.h'),
    Source.pattern('{CACHE_DIR}/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FLEView.h'),
    Source.pattern('{CACHE_DIR}/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FLEViewController.h'),
    Source.pattern('{CACHE_DIR}/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FlutterBinaryMessenger.h'),
    Source.pattern('{CACHE_DIR}/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FlutterChannels.h'),
    Source.pattern('{CACHE_DIR}/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FlutterCodecs.h'),
    Source.pattern('{CACHE_DIR}/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FlutterMacOS.h'),
    Source.pattern('{CACHE_DIR}/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FlutterPluginMacOS.h'),
    Source.pattern('{CACHE_DIR}/artifacts/engine/darwin-x64/FlutterMacOS.framework/Headers/FlutterPluginRegisrarMacOS.h'),
    // Modules
    Source.pattern('{CACHE_DIR}/artifacts/engine/darwin-x64/FlutterMacOS.framework/Modules/module.modulemap'),
    // Resources
    Source.pattern('{CACHE_DIR}/artifacts/engine/darwin-x64/FlutterMacOS.framework/Resources/icudtl.dat'),
    Source.pattern('{CACHE_DIR}/artifacts/engine/darwin-x64/FlutterMacOS.framework/Resources/info.plist'),
    // Ignore Versions folder for now
  ],
  outputs: <Source>[
    Source.pattern('{PROJECT_DIR}/macos/Flutter/FlutterMacOS.framework/FlutterMacOS'),
    // Headers
    Source.pattern('{PROJECT_DIR}/macos/Flutter/FlutterMacOS.framework/Headers/FLEOpenGLContextHandling.h'),
    Source.pattern('{PROJECT_DIR}/macos/Flutter/FlutterMacOS.framework/Headers/FLEReshapeListener.h'),
    Source.pattern('{PROJECT_DIR}/macos/Flutter/FlutterMacOS.framework/Headers/FLEView.h'),
    Source.pattern('{PROJECT_DIR}/macos/Flutter/FlutterMacOS.framework/Headers/FLEViewController.h'),
    Source.pattern('{PROJECT_DIR}/macos/Flutter/FlutterMacOS.framework/Headers/FlutterBinaryMessenger.h'),
    Source.pattern('{PROJECT_DIR}/macos/Flutter/FlutterMacOS.framework/Headers/FlutterChannels.h'),
    Source.pattern('{PROJECT_DIR}/macos/Flutter/FlutterMacOS.framework/Headers/FlutterCodecs.h'),
    Source.pattern('{PROJECT_DIR}/macos/Flutter/FlutterMacOS.framework/Headers/FlutterMacOS.h'),
    Source.pattern('{PROJECT_DIR}/macos/Flutter/FlutterMacOS.framework/Headers/FlutterPluginMacOS.h'),
    Source.pattern('{PROJECT_DIR}/macos/Flutter/FlutterMacOS.framework/Headers/FlutterPluginRegisrarMacOS.h'),
    // Modules
    Source.pattern('{PROJECT_DIR}/macos/Flutter/FlutterMacOS.framework/Modules/module.modulemap'),
    // Resources
    Source.pattern('{PROJECT_DIR}/macos/Flutter/FlutterMacOS.framework/Resources/icudtl.dat'),
    Source.pattern('{PROJECT_DIR}/macos/Flutter/FlutterMacOS.framework/Resources/info.plist'),
    // Ignore Versions folder for now
  ],
  dependencies: <Target>[],
  buildAction: copyFramework,
);
