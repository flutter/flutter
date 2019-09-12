// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/windows/application_package.dart';
import 'package:flutter_tools/src/windows/windows_device.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group(WindowsDevice, () {
    final WindowsDevice device = WindowsDevice();
    final MockPlatform notWindows = MockPlatform();
    final MockProcessManager mockProcessManager = MockProcessManager();
    const String flutterToolBinary = 'flutter.exe';

    when(notWindows.isWindows).thenReturn(false);
    when(notWindows.environment).thenReturn(const <String, String>{});
    when(mockProcessManager.runSync(
      <String>['powershell', '-script="Get-CimInstance Win32_Process"'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenAnswer((Invocation invocation) {
      // The flutter tool process is returned as output to the powershell script
      final MockProcessResult result = MockProcessResult();
      when(result.exitCode).thenReturn(0);
      when<String>(result.stdout).thenReturn('$pid  $flutterToolBinary');
      when<String>(result.stderr).thenReturn('');
      return result;
    });
    when(mockProcessManager.run(
      <String>['Taskkill', '/PID', '$pid', '/F'],
      workingDirectory: anyNamed('workingDirectory'),
      environment: anyNamed('environment'),
    )).thenThrow(Exception('Flutter tool process has been killed'));

    testUsingContext('defaults', () async {
      final PrebuiltWindowsApp windowsApp = PrebuiltWindowsApp(executable: 'foo');
      expect(await device.targetPlatform, TargetPlatform.windows_x64);
      expect(device.name, 'Windows');
      expect(await device.installApp(windowsApp), true);
      expect(await device.uninstallApp(windowsApp), true);
      expect(await device.isLatestBuildInstalled(windowsApp), true);
      expect(await device.isAppInstalled(windowsApp), true);
      expect(await device.stopApp(windowsApp), false);
      expect(device.category, Category.desktop);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    test('noop port forwarding', () async {
      final WindowsDevice device = WindowsDevice();
      final DevicePortForwarder portForwarder = device.portForwarder;
      final int result = await portForwarder.forward(2);
      expect(result, 2);
      expect(portForwarder.forwardedPorts.isEmpty, true);
    });

    testUsingContext('No devices listed if platform unsupported', () async {
      expect(await WindowsDevices().devices, <Device>[]);
    }, overrides: <Type, Generator>{
      Platform: () => notWindows,
    });

    testUsingContext('isSupportedForProject is true with editable host app', () async {
      fs.file('pubspec.yaml').createSync();
      fs.file('.packages').createSync();
      fs.directory('windows').createSync();
      final FlutterProject flutterProject = FlutterProject.current();

      expect(WindowsDevice().isSupportedForProject(flutterProject), true);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
    });

    testUsingContext('isSupportedForProject is false with no host app', () async {
      fs.file('pubspec.yaml').createSync();
      fs.file('.packages').createSync();
      final FlutterProject flutterProject = FlutterProject.current();

      expect(WindowsDevice().isSupportedForProject(flutterProject), false);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
    });

    testUsingContext('The current running process is not killed when stopping the app', () async {
      // The name of the executable is the same as the flutter tool one
      final PrebuiltWindowsApp windowsApp = PrebuiltWindowsApp(executable: flutterToolBinary);
      expect(await device.stopApp(windowsApp), false);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });
  });
}

class MockPlatform extends Mock implements Platform {}

class MockFileSystem extends Mock implements FileSystem {}

class MockFile extends Mock implements File {}

class MockProcessManager extends Mock implements ProcessManager {}

class MockProcess extends Mock implements Process {}

class MockProcessResult extends Mock implements ProcessResult {}
