// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/commands/build.dart';

import '../../src/android_common.dart';
import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_build_system.dart';

void main() {
  testUsingContext('Include only supported sub commands', () {
    final logger = BufferLogger.test();
    final fs = MemoryFileSystem.test();
    final command = BuildCommand(
      androidBuilder: FakeAndroidBuilder(),
      androidContext: FakeAndroidContext(androidSdk: FakeAndroidSdk()),
      androidSdk: FakeAndroidSdk(),
      artifacts: FakeArtifacts(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      cache: FakeCache(),
      config: FakeConfig(),
      fileSystem: fs,
      fileSystemUtils: FakeFileSystemUtils(),
      flutterVersion: FakeFlutterVersion(),
      logger: logger,
      osUtils: FakeOperatingSystemUtils(),
      platform: FakePlatform(),
      plistParser: FakePlistParser(),
      processManager: FakeProcessManager.any(),
      processUtils: FakeProcessUtils(),
      templateRenderer: FakeTemplateRenderer(),
      terminal: FakeTerminal(),
      toolContext: FakeToolContext(
        artifacts: FakeArtifacts(),
        cache: FakeCache(),
        config: FakeConfig(),
        flutterVersion: FakeFlutterVersion(),
        fs: fs,
        logger: logger,
        os: FakeOperatingSystemUtils(),
        platform: FakePlatform(),
        processManager: FakeProcessManager.any(),
        processUtils: FakeProcessUtils(),
      ),
      xcode: FakeXcode(),
    );
    for (final Command<void> x in command.subcommands.values) {
      expect((x as BuildSubCommand).supported, isTrue);
    }
  });
}
