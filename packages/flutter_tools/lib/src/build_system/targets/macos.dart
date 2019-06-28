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

const String _kInputPrefix = '{CACHE_DIR}/artifacts/engine/darwin-x64/FlutterMacOS.framework';
const String _kOutputPrefix = '{PROJECT_DIR}/macos/Flutter/FlutterMacOS.framework';

/// Copies the macOS desktop framework to the copy directory.
const Target unpackMacos = Target(
  name: 'unpack_macos',
  inputs: <Source>[
    Source.pattern('$_kInputPrefix/FlutterMacOS'),
    // Headers
    Source.pattern('$_kInputPrefix/Headers/FLEOpenGLContextHandling.h'),
    Source.pattern('$_kInputPrefix/Headers/FLEReshapeListener.h'),
    Source.pattern('$_kInputPrefix/Headers/FLEView.h'),
    Source.pattern('$_kInputPrefix/Headers/FLEViewController.h'),
    Source.pattern('$_kInputPrefix/Headers/FlutterBinaryMessenger.h'),
    Source.pattern('$_kInputPrefix/Headers/FlutterChannels.h'),
    Source.pattern('$_kInputPrefix/Headers/FlutterCodecs.h'),
    Source.pattern('$_kInputPrefix/Headers/FlutterMacOS.h'),
    Source.pattern('$_kInputPrefix/Headers/FlutterPluginMacOS.h'),
    Source.pattern('$_kInputPrefix/Headers/FlutterPluginRegisrarMacOS.h'),
    // Modules
    Source.pattern('$_kInputPrefix/Modules/module.modulemap'),
    // Resources
    Source.pattern('$_kInputPrefix/Resources/icudtl.dat'),
    Source.pattern('$_kInputPrefix/Resources/info.plist'),
    // Ignore Versions folder for now
  ],
  outputs: <Source>[
    Source.pattern('$_kOutputPrefix/FlutterMacOS'),
    // Headers
    Source.pattern('$_kOutputPrefix/Headers/FLEOpenGLContextHandling.h'),
    Source.pattern('$_kOutputPrefix/Headers/FLEReshapeListener.h'),
    Source.pattern('$_kOutputPrefix/Headers/FLEView.h'),
    Source.pattern('$_kOutputPrefix/Headers/FLEViewController.h'),
    Source.pattern('$_kOutputPrefix/Headers/FlutterBinaryMessenger.h'),
    Source.pattern('$_kOutputPrefix/Headers/FlutterChannels.h'),
    Source.pattern('$_kOutputPrefix/Headers/FlutterCodecs.h'),
    Source.pattern('$_kOutputPrefix/Headers/FlutterMacOS.h'),
    Source.pattern('$_kOutputPrefix/Headers/FlutterPluginMacOS.h'),
    Source.pattern('$_kOutputPrefix/Headers/FlutterPluginRegisrarMacOS.h'),
    // Modules
    Source.pattern('$_kOutputPrefix/Modules/module.modulemap'),
    // Resources
    Source.pattern('$_kOutputPrefix/Resources/icudtl.dat'),
    Source.pattern('$_kOutputPrefix/Resources/info.plist'),
    // Ignore Versions folder for now
  ],
  dependencies: <Target>[],
  buildAction: copyFramework,
);
