// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pool/pool.dart';

import '../../artifacts.dart';
import '../../asset.dart';
import '../../base/file_system.dart';
import '../../build_info.dart';
import '../../devfs.dart';
import '../../globals.dart';
import '../build_system.dart';
import '../exceptions.dart';
import 'assets.dart';
import 'dart.dart';

/// Copies the Linux desktop embedding files to the copy directory.
class UnpackLinuxDebug extends Target {
  const UnpackLinuxDebug();

  @override
  String get name => 'unpack_linux_debug';

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/linux.dart'),
    Source.artifact(Artifact.linuxDesktopPath, mode: BuildMode.debug),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.pattern('{PROJECT_DIR}/linux/flutter/ephemeral/libflutter_linux_glfw.so'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/ephemeral/flutter_export.h'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/ephemeral/flutter_messenger.h'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/ephemeral/flutter_plugin_registrar.h'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/ephemeral/flutter_glfw.h'),
    Source.pattern('{PROJECT_DIR}/linux/flutter/ephemeral/icudtl.dat'),
  ];

  @override
  List<Target> get dependencies => <Target>[];

  @override
  Future<void> build(Environment environment) async {
    final String basePath = artifacts.getArtifactPath(Artifact.linuxDesktopPath);
    for (File input in fs.directory(basePath)
        .listSync(recursive: true)
        .whereType<File>()) {
      final String outputPath = fs.path.join(
        environment.projectDir.path,
        'linux',
        'flutter',
        'ephemeral',
        fs.path.relative(input.path, from: basePath),
      );
      final File destinationFile = fs.file(outputPath);
      if (!destinationFile.parent.existsSync()) {
        destinationFile.parent.createSync(recursive: true);
      }
      fs.file(input).copySync(destinationFile.path);
    }
  }
}

/// Creates a debug bundle for the Linux desktop target.
class DebugBundleLinuxAssets extends Target {
  const DebugBundleLinuxAssets();

  @override
  String get name => 'debug_bundle_linux_assets';

  @override
  List<Target> get dependencies => const <Target>[
    KernelSnapshot(),
    UnpackLinuxDebug(),
  ];

  @override
  List<Source> get inputs => const <Source>[
    Source.pattern('{BUILD_DIR}/app.dill'),
    Source.pattern('{FLUTTER_ROOT}/packages/flutter_tools/lib/src/build_system/targets/linux.dart'),
    Source.behavior(AssetOutputBehavior('flutter_assets')),
  ];

  @override
  List<Source> get outputs => const <Source>[
    Source.behavior(AssetOutputBehavior('flutter_assets')),
    Source.pattern('{OUTPUT_DIR}/flutter_assets/kernel_blob.bin'),
    Source.pattern('{OUTPUT_DIR}/flutter_assets/AssetManifest.json'),
    Source.pattern('{OUTPUT_DIR}/flutter_assets/FontManifest.json'),
    Source.pattern('{OUTPUT_DIR}/flutter_assets/LICENSE'),
  ];

  @override
  Future<void> build(Environment environment) async {
    if (environment.defines[kBuildMode] == null) {
      throw MissingDefineException(kBuildMode, 'debug_bundle_linux_assets');
    }
    final BuildMode buildMode = getBuildModeForName(environment.defines[kBuildMode]);
    final Directory outputDirectory = environment.outputDir
      .childDirectory('flutter_assets');
    if (!outputDirectory.existsSync()) {
      outputDirectory.createSync();
    }

    // Only copy the kernel blob in debug mode.
    if (buildMode == BuildMode.debug) {
      environment.buildDir.childFile('app.dill')
        .copySync(outputDirectory.childFile('kernel_blob.bin').path);
    }

    final AssetBundle assetBundle = AssetBundleFactory.instance.createBundle();
    await assetBundle.build();
    final Pool pool = Pool(kMaxOpenFiles);
    await Future.wait<void>(
      assetBundle.entries.entries.map<Future<void>>((MapEntry<String, DevFSContent> entry) async {
        final PoolResource resource = await pool.request();
        try {
          final File file = fs.file(fs.path.join(outputDirectory.path, entry.key));
          file.parent.createSync(recursive: true);
          final DevFSContent content = entry.value;
          if (content is DevFSFileContent && content.file is File) {
            await (content.file as File).copy(file.path);
          } else {
            await file.writeAsBytes(await entry.value.contentsAsBytes());
          }
        } finally {
          resource.release();
        }
      }));
  }
}
