// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/macos/native_assets.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  late FakeProcessManager processManager;
  late Environment iosEnvironment;
  late Artifacts artifacts;
  late FileSystem fileSystem;
  late BufferLogger logger;

  setUp(() {
    processManager = FakeProcessManager.empty();
    logger = BufferLogger.test();
    artifacts = Artifacts.test();
    fileSystem = MemoryFileSystem.test();
    iosEnvironment = Environment.test(
      fileSystem.currentDirectory,
      inputs: <String, String>{},
      artifacts: artifacts,
      processManager: processManager,
      fileSystem: fileSystem,
      logger: logger,
    );
    iosEnvironment.buildDir.createSync(recursive: true);
  });

  testUsingContext('dry run with no package config', () async {
    expect(
      await dryRunNativeAssetsMacOS(
        projectUri: iosEnvironment.projectDir.uri,
        fileSystem: fileSystem,
      ),
      null,
    );
    expect(
      (globals.logger as BufferLogger).traceText,
      contains('No package config found. Skipping native assets compilation.'),
    );
  });

  testUsingContext('build with no package config', () async {
    await buildNativeAssetsMacOS(
      darwinArchs: <DarwinArch>[DarwinArch.arm64],
      projectUri: iosEnvironment.projectDir.uri,
      buildMode: BuildMode.debug,
      fileSystem: fileSystem,
    );
    expect(
      (globals.logger as BufferLogger).traceText,
      contains('No package config found. Skipping native assets compilation.'),
    );
  });

  testUsingContext('dry run with no package config', () async {
    await dryRunNativeAssetsMultipeOSes(
      projectUri: iosEnvironment.projectDir.uri,
      fileSystem: fileSystem,
      targetPlatforms: <TargetPlatform>[
        TargetPlatform.darwin,
        TargetPlatform.ios,
      ],
    );
    expect(
      (globals.logger as BufferLogger).traceText,
      contains('No package config found. Skipping native assets compilation.'),
    );
  });

  testUsingContext('dry run', () async {
    final File packageConfig =
        iosEnvironment.projectDir.childFile('.dart_tool/package_config.json');
    await packageConfig.parent.create();
    await packageConfig.create();
    // This tries to access the file system in PackageLayout.fromRootPackageRoot.
    // TODO(dacoharkes): Mock PackageLayout and NativeAssetsBuilder.
    expect(
        await dryRunNativeAssetsMacOS(
            projectUri: iosEnvironment.projectDir.uri, fileSystem: fileSystem),
        null);
  }, skip: true); // https://github.com/flutter/flutter/pull/130494#issuecomment-1651680227
}
