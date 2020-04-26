// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/desktop_device.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart';

/// A trivial subclass of DesktopDevice for testing the shared functionality.
class FakeDesktopDevice extends DesktopDevice {
  FakeDesktopDevice() : super(
      'dummy',
      platformType: PlatformType.linux,
      ephemeral: false,
  );

  /// The [mainPath] last passed to [buildForDevice].
  String lastBuiltMainPath;

  /// The [buildInfo] last passed to [buildForDevice].
  BuildInfo lastBuildInfo;

  @override
  String get name => 'dummy';

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.tester;

  @override
  bool isSupported() => true;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) => true;

  @override
  Future<void> buildForDevice(
    ApplicationPackage package, {
    String mainPath,
    BuildInfo buildInfo,
  }) async {
    lastBuiltMainPath = mainPath;
    lastBuildInfo = buildInfo;
  }

  // Dummy implementation that just returns the build mode name.
  @override
  String executablePathForDevice(ApplicationPackage package, BuildMode buildMode) {
    return buildMode == null ? 'null' : getNameForBuildMode(buildMode);
  }
}

/// A desktop device that returns a null executable path, for failure testing.
class NullExecutableDesktopDevice extends FakeDesktopDevice {
  @override
  String executablePathForDevice(ApplicationPackage package, BuildMode buildMode) {
    return null;
  }
}

class MockAppplicationPackage extends Mock implements ApplicationPackage {}

class MockFileSystem extends Mock implements FileSystem {}

class MockFile extends Mock implements File {}

class MockProcessManager extends Mock implements ProcessManager {}

void main() {
  group('Basic info', () {
    test('Category is desktop', () async {
      final FakeDesktopDevice device = FakeDesktopDevice();
      expect(device.category, Category.desktop);
    });

    test('Not an emulator', () async {
      final FakeDesktopDevice device = FakeDesktopDevice();
      expect(await device.isLocalEmulator, false);
      expect(await device.emulatorId, null);
    });

    testUsingContext('Uses OS name as SDK name', () async {
      final FakeDesktopDevice device = FakeDesktopDevice();
      expect(await device.sdkNameAndVersion, globals.os.name);
    });
  });

  group('Install', () {
    test('Install checks always return true', () async {
      final FakeDesktopDevice device = FakeDesktopDevice();
      expect(await device.isAppInstalled(null), true);
      expect(await device.isLatestBuildInstalled(null), true);
      expect(device.category, Category.desktop);
    });

    test('Install and uninstall are no-ops that report success', () async {
      final FakeDesktopDevice device = FakeDesktopDevice();
      final MockAppplicationPackage package = MockAppplicationPackage();
      expect(await device.uninstallApp(package), true);
      expect(await device.isAppInstalled(package), true);
      expect(await device.isLatestBuildInstalled(package), true);

      expect(await device.installApp(package), true);
      expect(await device.isAppInstalled(package), true);
      expect(await device.isLatestBuildInstalled(package), true);
      expect(device.category, Category.desktop);
    });
  });

  group('Starting and stopping application', () {
    final MockFileSystem mockFileSystem = MockFileSystem();
    final MockProcessManager mockProcessManager = MockProcessManager();

    // Configures mock environment so that startApp will be able to find and
    // run an FakeDesktopDevice exectuable with for the given mode.
    void setUpMockExecutable(FakeDesktopDevice device, BuildMode mode, {Future<int> exitFuture}) {
      final String executableName = device.executablePathForDevice(null, mode);
      final MockFile mockFile = MockFile();
      when(mockFileSystem.file(executableName)).thenReturn(mockFile);
      when(mockFile.existsSync()).thenReturn(true);
      when(mockProcessManager.start(<String>[executableName])).thenAnswer((Invocation invocation) async {
        return FakeProcess(
          exitCode: Completer<int>().future,
          stdout: Stream<List<int>>.fromIterable(<List<int>>[
            utf8.encode('Observatory listening on http://127.0.0.1/0\n'),
          ]),
          stderr: const Stream<List<int>>.empty(),
        );
      });
      when(mockProcessManager.run(any)).thenAnswer((Invocation invocation) async {
        return ProcessResult(0, 1, '', '');
      });
    }

    test('Stop without start is a successful no-op', () async {
      final FakeDesktopDevice device = FakeDesktopDevice();
    final MockAppplicationPackage package = MockAppplicationPackage();
      expect(await device.stopApp(package), true);
    });

    testUsingContext('Can run from prebuilt application', () async {
      final FakeDesktopDevice device = FakeDesktopDevice();
      final MockAppplicationPackage package = MockAppplicationPackage();
      setUpMockExecutable(device, null);
      final LaunchResult result = await device.startApp(package, prebuiltApplication: true);
      expect(result.started, true);
      expect(result.observatoryUri, Uri.parse('http://127.0.0.1/0'));
    }, overrides: <Type, Generator>{
      FileSystem: () => mockFileSystem,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('Null executable path fails gracefully', () async {
      final NullExecutableDesktopDevice device = NullExecutableDesktopDevice();
      final MockAppplicationPackage package = MockAppplicationPackage();
      final LaunchResult result = await device.startApp(package, prebuiltApplication: true);
      expect(result.started, false);
      expect(testLogger.errorText, contains('Unable to find executable to run'));
    });

    testUsingContext('stopApp kills process started by startApp', () async {
      final FakeDesktopDevice device = FakeDesktopDevice();
      final MockAppplicationPackage package = MockAppplicationPackage();
      setUpMockExecutable(device, null);
      final LaunchResult result = await device.startApp(package, prebuiltApplication: true);
      expect(result.started, true);
      expect(await device.stopApp(package), true);
    }, overrides: <Type, Generator>{
      FileSystem: () => mockFileSystem,
      ProcessManager: () => mockProcessManager,
    });
  });

  test('Port forwarder is a no-op', () async {
    final FakeDesktopDevice device = FakeDesktopDevice();
    final DevicePortForwarder portForwarder = device.portForwarder;
    final int result = await portForwarder.forward(2);
    expect(result, 2);
    expect(portForwarder.forwardedPorts.isEmpty, true);
  });
}
