// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/screenshot.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  group('Validate screenshot options', () {
    testUsingContext('rasterizer and skia screenshots do not require a device', () async {
      // Throw a specific exception when attempting to make a VM Service connection to
      // verify that we've made it past the initial validation.
      openChannelForTesting = (String url, {CompressionOptions? compression, Logger? logger}) async {
        expect(url, 'ws://localhost:8181/ws');
        throw Exception('dummy');
      };

      await expectLater(() => createTestCommandRunner(ScreenshotCommand(fs: MemoryFileSystem.test()))
        .run(<String>['screenshot', '--type=skia', '--vm-service-url=http://localhost:8181']),
        throwsA(isException.having((Exception exception) => exception.toString(), 'message', contains('dummy'))),
      );
    });


    testUsingContext('rasterizer and skia screenshots require VM Service uri', () async {
      await expectLater(() => createTestCommandRunner(ScreenshotCommand(fs: MemoryFileSystem.test()))
        .run(<String>['screenshot', '--type=skia']),
        throwsToolExit(message: 'VM Service URI must be specified for screenshot type skia')
      );
    });

    testUsingContext('device screenshots require device', () async {
      await expectLater(() => createTestCommandRunner(ScreenshotCommand(fs: MemoryFileSystem.test()))
        .run(<String>['screenshot']),
        throwsToolExit(message: 'Must have a connected device for screenshot type device'),
      );
    });

    testUsingContext('device screenshots cannot provided VM Service', () async {
      await expectLater(() => createTestCommandRunner(ScreenshotCommand(fs: MemoryFileSystem.test()))
        .run(<String>['screenshot',  '--vm-service-url=http://localhost:8181']),
        throwsToolExit(message: 'VM Service URI cannot be provided for screenshot type device'),
      );
    });
  });

  group('Screenshot file validation', () {
    testWithoutContext('successful in pwd', () async {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      fs.file('test.png').createSync();
      fs.directory('sub_dir').createSync();
      fs.file('sub_dir/test.png').createSync();

      expect(() => ScreenshotCommand.checkOutput(fs.file('test.png'), fs),
          returnsNormally);
      expect(
          () => ScreenshotCommand.checkOutput(fs.file('sub_dir/test.png'), fs),
          returnsNormally);
    });

    testWithoutContext('failed in pwd', () async {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      fs.directory('sub_dir').createSync();

      expect(
          () => ScreenshotCommand.checkOutput(fs.file('test.png'), fs),
          throwsToolExit(
              message: 'File was not created, ensure path is valid'));
      expect(
          () => ScreenshotCommand.checkOutput(fs.file('../'), fs),
          throwsToolExit(
              message: 'File was not created, ensure path is valid'));
      expect(
          () => ScreenshotCommand.checkOutput(fs.file('.'), fs),
          throwsToolExit(
              message: 'File was not created, ensure path is valid'));
      expect(
          () => ScreenshotCommand.checkOutput(fs.file('/'), fs),
          throwsToolExit(
              message: 'File was not created, ensure path is valid'));
      expect(
          () => ScreenshotCommand.checkOutput(fs.file('sub_dir/test.png'), fs),
          throwsToolExit(
              message: 'File was not created, ensure path is valid'));
    });
  });

  group('Screenshot output validation', () {
    testWithoutContext('successful', () async {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      fs.file('test.png').createSync();

      expect(() => ScreenshotCommand.ensureOutputIsNotJsonRpcError(fs.file('test.png')),
          returnsNormally);
    });

    testWithoutContext('failed', () async {
      final MemoryFileSystem fs = MemoryFileSystem.test();
      fs.file('test.png').writeAsStringSync('{"jsonrpc":"2.0", "error":"something"}');

      expect(
          () => ScreenshotCommand.ensureOutputIsNotJsonRpcError(fs.file('test.png')),
          throwsToolExit(
              message: 'It appears the output file contains an error message, not valid output.'));
    });
  });

  group('Screenshot on iOS Core Devices', () {
    late FileSystem fileSystem;
    late FakeDeviceManager fakeDeviceManager;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      fakeDeviceManager = FakeDeviceManager();
    });

    testUsingContext('works in CI', () async {
      final ScreenshotCommand command = ScreenshotCommand(fs: fileSystem);
      final FakeIOSDevice screenshotDevice = FakeIOSDevice()
        ..supportsScreenshot = false
        ..isCoreDevice = true;
      fakeDeviceManager.attachedDevices = <Device>[screenshotDevice];

      await createTestCommandRunner(command).run(
        <String>['screenshot', '--ci'],
      );

      expect(screenshotDevice.screenshotTaken, isTrue);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      DeviceManager: () => fakeDeviceManager,
    });

    testUsingContext('does not work if not in CI', () async {
      final ScreenshotCommand command = ScreenshotCommand(fs: fileSystem);
      final FakeIOSDevice screenshotDevice = FakeIOSDevice()
        ..supportsScreenshot = false
        ..isCoreDevice = true;
      fakeDeviceManager.attachedDevices = <Device>[screenshotDevice];

      expect(
        () => createTestCommandRunner(command).run(<String>['screenshot']),
        throwsToolExit(message: 'Screenshot not supported for FakeDevice.'),
      );
      expect(screenshotDevice.screenshotTaken, isFalse);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      DeviceManager: () => fakeDeviceManager,
    });
  });
}

class FakeIOSDevice extends Fake implements IOSDevice {
  @override
  final String name = 'FakeDevice';

  @override
  bool isCoreDevice = false;

  @override
  bool supportsScreenshot = true;

  bool screenshotTaken = false;

  @override
  Future<void> takeScreenshotForCI(File outputFile) async {
    screenshotTaken = true;
  }
}
