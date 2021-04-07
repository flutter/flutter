// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/drive.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  FileSystem fileSystem;
  BufferLogger logger;
  Platform platform;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    platform = FakePlatform(operatingSystem: 'linux');
  });

  setUpAll(() {
    Cache.disableLocking();
  });

  tearDownAll(() {
    Cache.enableLocking();
  });


  testWithoutContext('drive --screenshot writes to expected output', () async {
    final Device screenshotDevice = ScreenshotDevice();

    await takeScreenshot(
      screenshotDevice,
      'drive_screenshots',
      fileSystem,
      logger,
      FileSystemUtils(
        fileSystem: fileSystem,
        platform: platform,
      ),
    );

    expect(logger.statusText, contains('Screenshot written to drive_screenshots/drive_01.png'));
  });

  testWithoutContext('drive --screenshot errors but does not fail if screenshot fails', () async {
    final Device screenshotDevice = ScreenshotDevice();
    fileSystem.file('drive_screenshots').createSync();

    await takeScreenshot(
      screenshotDevice,
      'drive_screenshots',
      fileSystem,
      logger,
      FileSystemUtils(
        fileSystem: fileSystem,
        platform: platform,
      ),
    );

    expect(logger.statusText, isEmpty);
    expect(logger.errorText, contains('Error taking screenshot: FileSystemException: Not a directory'));
  });

  testUsingContext('shouldRunPub is true unless user specifies --no-pub', () async {
    final DriveCommand command = DriveCommand(fileSystem: fileSystem, logger: logger, platform: platform);
    fileSystem.file('lib/main.dart').createSync(recursive: true);
    fileSystem.file('test_driver/main_test.dart').createSync(recursive: true);
    fileSystem.file('pubspec.yaml').createSync();

    try {
      await createTestCommandRunner(command).run(const <String>['drive', '--no-pub']);
    } on Exception {
      // Expected to throw
    }

    expect(command.shouldRunPub, false);

    try {
      await createTestCommandRunner(command).run(const <String>['drive']);
    } on Exception {
      // Expected to throw
    }

    expect(command.shouldRunPub, true);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
    Pub: () => FakePub(),
  });
}

class ScreenshotDevice extends Fake implements Device {
  @override
  Future<void> takeScreenshot(File outputFile) async {}
}
