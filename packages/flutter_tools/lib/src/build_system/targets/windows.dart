// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../base/file_system.dart';
import '../../build_info.dart';
import '../build_system.dart';

/// List all input files under `cpp_client_wrapper`.
List<File> listClientWrapperInput(Environment environment) {
  return environment
    .cacheDir
    .childDirectory(getNameForTargetPlatform(environment.targetPlatform))
    .childDirectory('cpp_client_wrapper')
    .listSync(recursive: true)
    .whereType<File>()
    .toList();
}

/// List all expected output files under `cpp_client_wrapper`.
List<File> listClientWrapperOutput(Environment environment) {
  return environment
    .copyDir
    .childDirectory('cpp_client_wrapper')
    .listSync(recursive: true)
    .whereType<File>()
    .toList();
}

/// Copies all of the input files to the correct copy dir.
Future<void> copyDesktopAssets(List<FileSystemEntity> inputs, Environment environment) async {
  for (File input in inputs) {
    // Sort of a hack until I figure out the best way to structure this.
    String outputPath;
    if (input.path.contains('cpp_client_wrapper')) {
      final Iterable<String> parts = fs.path
        .split(input.path)
        .skipWhile((String segment) => segment != 'cpp_client_wrapper');
      outputPath = fs.path.joinAll(<String>[
        environment.copyDir.path,
        ...parts,
      ]);
    } else {
      outputPath = fs.path.join(environment.copyDir.path, input.basename);
    }
    final File destinationFile = fs.file(outputPath);
    if (!destinationFile.parent.existsSync()) {
      destinationFile.parent.createSync(recursive: true);
    }
    input.copySync(destinationFile.path);
  }
}

/// Copies the Windows desktop embedder files to the copy directory.
// TODO(jonahwilliams): replace list assets with specific file paths.
const Target unpackWindows = Target(
  name: 'unpack_windows',
  inputs: <Source>[
    Source.pattern('{CACHE_DIR}/{platform}/flutter_windows.dll'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_windows.dll.exp'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_windows.dll.lib'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_windows.dll.pdb'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_export.h'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_messenger.h'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_plugin_registrar.h'),
    Source.pattern('{CACHE_DIR}/{platform}/flutter_glfw.h'),
    Source.pattern('{CACHE_DIR}/{platform}/icudtl.dat'),
    Source.function(listClientWrapperInput),
  ],
  outputs: <Source>[
    Source.pattern('{COPY_DIR}/flutter_windows.dll'),
    Source.pattern('{COPY_DIR}/flutter_windows.dll.exp'),
    Source.pattern('{COPY_DIR}/flutter_windows.dll.lib'),
    Source.pattern('{COPY_DIR}/flutter_windows.dll.pdb'),
    Source.pattern('{COPY_DIR}/flutter_export.h'),
    Source.pattern('{COPY_DIR}/flutter_messenger.h'),
    Source.pattern('{COPY_DIR}/flutter_plugin_registrar.h'),
    Source.pattern('{COPY_DIR}/flutter_glfw.h'),
    Source.pattern('{COPY_DIR}/icudtl.dat'),
    Source.function(listClientWrapperOutput),
  ],
  dependencies: <Target>[],
  platforms: <TargetPlatform>[
    TargetPlatform.windows_x64,
  ],
  invocation: copyDesktopAssets,
);
