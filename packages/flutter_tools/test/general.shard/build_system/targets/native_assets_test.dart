// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/exceptions.dart';
import 'package:flutter_tools/src/build_system/targets/native_assets.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';

void main() {
  late FakeProcessManager processManager;
  late Environment iosEnvironment;
  late Artifacts artifacts;
  late FileSystem fileSystem;
  late Logger logger;

  setUp(() {
    processManager = FakeProcessManager.empty();
    logger = BufferLogger.test();
    artifacts = Artifacts.test();
    fileSystem = MemoryFileSystem.test();
    iosEnvironment = Environment.test(
      fileSystem.currentDirectory,
      defines: <String, String>{
        kBuildMode: BuildMode.profile.cliName,
        kTargetPlatform: getNameForTargetPlatform(TargetPlatform.ios),
        kIosArchs: 'arm64',
        kSdkRoot: 'path/to/iPhoneOS.sdk',
      },
      inputs: <String, String>{},
      artifacts: artifacts,
      processManager: processManager,
      fileSystem: fileSystem,
      logger: logger,
    );
    iosEnvironment.buildDir.createSync(recursive: true);
  });

  testWithoutContext('NativeAssets throws error if missing target platform',
      () async {
    iosEnvironment.defines.remove(kTargetPlatform);
    expect(const NativeAssets().build(iosEnvironment),
        throwsA(isA<MissingDefineException>()));
  });

  testUsingContext('NativeAssets throws error if missing ios archs', () async {
    iosEnvironment.defines.remove(kIosArchs);
    expect(const NativeAssets().build(iosEnvironment),
        throwsA(isA<MissingDefineException>()));
  });

  testUsingContext('NativeAssets throws error if missing sdk root', () async {
    iosEnvironment.defines.remove(kSdkRoot);
    expect(const NativeAssets().build(iosEnvironment),
        throwsA(isA<MissingDefineException>()));
  });

  testUsingContext('NativeAssets no throw if all info is supplied', () async {
    // Won't build any native assets as there aren't any in the test project dir.
    await const NativeAssets().build(iosEnvironment);
  });

  // TODO(dacoharkes): Use dependency injection to use FakeNativeAssetsBuildRunner
  // for testing the NativeAssets Target.
  // [Target] mentions dependency injection, but doesn't detail how to
  // inject a dependency.
}
