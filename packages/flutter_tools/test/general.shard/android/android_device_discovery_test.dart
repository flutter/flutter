// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/android/android_device_discovery.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_workflow.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/testbed.dart';

void main() {
  testWithoutContext('AndroidDevices returns empty device list and diagnostics on null adb', () async {
    final AndroidDevices androidDevices = AndroidDevices(
      androidSdk: MockAndroidSdk(null),
      logger: BufferLogger.test(),
      androidWorkflow: AndroidWorkflow(
        androidSdk: MockAndroidSdk(null),
        featureFlags: TestFeatureFlags(),
      ),
      processManager: FakeProcessManager.list(<FakeCommand>[]),
      fileSystem: MemoryFileSystem.test(),
      platform: FakePlatform(),
    );

    expect(await androidDevices.pollingGetDevices(), isEmpty);
    expect(await androidDevices.getDiagnostics(), isEmpty);
  });

  testWithoutContext('AndroidDevices returns empty device list and diagnostics on null Android SDK', () async {
    final AndroidDevices androidDevices = AndroidDevices(
      androidSdk: null,
      logger: BufferLogger.test(),
      androidWorkflow: AndroidWorkflow(
        androidSdk: MockAndroidSdk(null),
        featureFlags: TestFeatureFlags(),
      ),
      processManager: FakeProcessManager.list(<FakeCommand>[]),
      fileSystem: MemoryFileSystem.test(),
      platform: FakePlatform(),
    );

    expect(await androidDevices.pollingGetDevices(), isEmpty);
    expect(await androidDevices.getDiagnostics(), isEmpty);
  });

  testWithoutContext('AndroidDevices throwsToolExit on missing adb path', () {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      FakeCommand(
        command: const <String>['adb', 'devices', '-l'],
        onRun: () {
          throw ArgumentError('adb');
        }
      )
    ]);
    final AndroidDevices androidDevices = AndroidDevices(
      androidSdk: MockAndroidSdk(),
      logger: BufferLogger.test(),
      androidWorkflow: AndroidWorkflow(
        androidSdk: MockAndroidSdk(),
        featureFlags: TestFeatureFlags(),
      ),
      processManager: processManager,
      fileSystem: MemoryFileSystem.test(),
      platform: FakePlatform(),
    );

    expect(androidDevices.pollingGetDevices(),
      throwsToolExit(message: RegExp('Unable to find "adb"')));
  });

  testWithoutContext('AndroidDevices throwsToolExit on failing adb', () {
    final ProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>['adb', 'devices', '-l'],
        exitCode: 1,
      )
    ]);
    final AndroidDevices androidDevices = AndroidDevices(
      androidSdk: MockAndroidSdk(),
      logger: BufferLogger.test(),
      androidWorkflow: AndroidWorkflow(
        androidSdk: MockAndroidSdk(),
        featureFlags: TestFeatureFlags(),
      ),
      processManager: processManager,
      fileSystem: MemoryFileSystem.test(),
      platform: FakePlatform(),
    );

    expect(androidDevices.pollingGetDevices(),
      throwsToolExit(message: RegExp('Unable to run "adb"')));
  });

  testWithoutContext('AndroidDevices is disabled if feature is disabled', () {
    final AndroidDevices androidDevices = AndroidDevices(
      androidSdk: MockAndroidSdk(),
      logger: BufferLogger.test(),
      androidWorkflow: AndroidWorkflow(
        androidSdk: MockAndroidSdk(),
        featureFlags: TestFeatureFlags(
          isAndroidEnabled: false,
        ),
      ),
      processManager: FakeProcessManager.any(),
      fileSystem: MemoryFileSystem.test(),
      platform: FakePlatform(),
    );

    expect(androidDevices.supportsPlatform, false);
  });

  testWithoutContext('physical devices', () {
    final List<AndroidDevice> devices = <AndroidDevice>[];
    AndroidDevices.parseADBDeviceOutput('''
List of devices attached
05a02bac               device usb:336592896X product:razor model:Nexus_7 device:flo

''',
    devices: devices,
    androidSdk: MockAndroidSdk(),
    logger: BufferLogger.test(),
    processManager: FakeProcessManager.any(),
    timeoutConfiguration: const TimeoutConfiguration(),
    platform: FakePlatform(),
    fileSystem: MemoryFileSystem.test(),
  );

    expect(devices, hasLength(1));
    expect(devices.first.name, 'Nexus 7');
    expect(devices.first.category, Category.mobile);
  });

  testWithoutContext('emulators and short listings', () {
    final List<AndroidDevice> devices = <AndroidDevice>[];
    AndroidDevices.parseADBDeviceOutput('''
List of devices attached
localhost:36790        device
0149947A0D01500C       device usb:340787200X
emulator-5612          host features:shell_2

''',
    devices: devices,
    androidSdk: MockAndroidSdk(),
    logger: BufferLogger.test(),
    processManager: FakeProcessManager.any(),
    timeoutConfiguration: const TimeoutConfiguration(),
    platform: FakePlatform(),
    fileSystem: MemoryFileSystem.test(),
  );

    expect(devices, hasLength(3));
    expect(devices.first.name, 'localhost:36790');
  });

  testWithoutContext('android n', () {
    final List<AndroidDevice> devices = <AndroidDevice>[];
    AndroidDevices.parseADBDeviceOutput('''
List of devices attached
ZX1G22JJWR             device usb:3-3 product:shamu model:Nexus_6 device:shamu features:cmd,shell_v2
''',
    devices: devices,
    androidSdk: MockAndroidSdk(),
    logger: BufferLogger.test(),
    processManager: FakeProcessManager.any(),
    timeoutConfiguration: const TimeoutConfiguration(),
    platform: FakePlatform(),
    fileSystem: MemoryFileSystem.test(),
  );

    expect(devices, hasLength(1));
    expect(devices.first.name, 'Nexus 6');
  });

  testWithoutContext('adb error message', () {
    final List<AndroidDevice> devices = <AndroidDevice>[];
    final List<String> diagnostics = <String>[];
    AndroidDevices.parseADBDeviceOutput('''
It appears you do not have 'Android SDK Platform-tools' installed.
Use the 'android' tool to install them:
  android update sdk --no-ui --filter 'platform-tools'
''', devices: devices,
     diagnostics: diagnostics,
     timeoutConfiguration: const TimeoutConfiguration(),
     processManager: FakeProcessManager.any(),
     platform: FakePlatform(),
     logger: BufferLogger.test(),
     fileSystem: MemoryFileSystem.test(),
     androidSdk: MockAndroidSdk(),
    );

    expect(devices, isEmpty);
    expect(diagnostics, hasLength(1));
    expect(diagnostics.first, contains('you do not have'));
  });
}

class MockAndroidSdk extends Mock implements AndroidSdk {
  MockAndroidSdk([this.adbPath = 'adb']);

  @override
  final String adbPath;
}
