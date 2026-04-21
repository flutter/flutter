// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/commands/build.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_build_system.dart';

void main() {
  testUsingContext('Include only supported sub commands', () {
    final logger = BufferLogger.test();
    final fs = MemoryFileSystem.test();
    final command = BuildCommand(
      androidSdk: FakeAndroidSdk(),
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      fileSystem: fs,
      logger: logger,
      osUtils: FakeOperatingSystemUtils(),
      config: FakeConfig(),
      platform: FakePlatform(),
      fileSystemUtils: FakeFileSystemUtils(),
      terminal: FakeTerminal(),
      plistParser: FakePlistParser(),
      processUtils: FakeProcessUtils(),
      processManager: FakeProcessManager.any(),
      templateRenderer: FakeTemplateRenderer(),
      xcode: FakeXcode(),
      artifacts: FakeArtifacts(),
      cache: FakeCache(),
      flutterVersion: FakeFlutterVersion(),
    );
    for (final Command<void> x in command.subcommands.values) {
      expect((x as BuildSubCommand).supported, isTrue);
    }
  });
}
