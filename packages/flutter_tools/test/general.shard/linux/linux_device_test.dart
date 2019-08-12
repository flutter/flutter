// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/linux/application_package.dart';
import 'package:flutter_tools/src/linux/linux_device.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group(LinuxDevice, () {
    final LinuxDevice device = LinuxDevice();
    final MockPlatform notLinux = MockPlatform();
    final MockProcessManager mockProcessManager = MockProcessManager();
    const String flutterToolCommand = 'flutter --someoption somevalue';

    when(notLinux.isLinux).thenReturn(false);
    when(mockProcessManager.run(<String>[
      'ps', 'aux',
    ])).thenAnswer((Invocation invocation) async {
      // The flutter tool process is returned as output to the ps aux command
      final MockProcessResult result = MockProcessResult();
      when(result.exitCode).thenReturn(0);
      when<String>(result.stdout).thenReturn('username  $pid  $flutterToolCommand');
      return result;
    });
    when(mockProcessManager.run(<String>[
      'kill', '$pid',
    ])).thenThrow(Exception('Flutter tool process has been killed'));

    testUsingContext('defaults', () async {
      final PrebuiltLinuxApp linuxApp = PrebuiltLinuxApp(executable: 'foo');
      expect(await device.targetPlatform, TargetPlatform.linux_x64);
      expect(device.name, 'Linux');
      expect(await device.installApp(linuxApp), true);
      expect(await device.uninstallApp(linuxApp), true);
      expect(await device.isLatestBuildInstalled(linuxApp), true);
      expect(await device.isAppInstalled(linuxApp), true);
      expect(await device.stopApp(linuxApp), true);
      expect(device.category, Category.desktop);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    test('noop port forwarding', () async {
      final LinuxDevice device = LinuxDevice();
      final DevicePortForwarder portForwarder = device.portForwarder;
      final int result = await portForwarder.forward(2);
      expect(result, 2);
      expect(portForwarder.forwardedPorts.isEmpty, true);
    });

    testUsingContext('The current running process is not killed when stopping the app', () async {
      // The name of the executable is the same as a command line argument to the flutter tool
      final PrebuiltLinuxApp linuxApp = PrebuiltLinuxApp(executable: 'somevalue');
      expect(await device.stopApp(linuxApp), true);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('No devices listed if platform unsupported', () async {
      expect(await LinuxDevices().devices, <Device>[]);
    }, overrides: <Type, Generator>{
      Platform: () => notLinux,
    });
  });

  testUsingContext('LinuxDevice.isSupportedForProject is true with editable host app', () async {
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    fs.directory('linux').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(LinuxDevice().isSupportedForProject(flutterProject), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
  });

  testUsingContext('LinuxDevice.isSupportedForProject is false with no host app', () async {
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(LinuxDevice().isSupportedForProject(flutterProject), false);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
  });
}

class MockPlatform extends Mock implements Platform {}

class MockFileSystem extends Mock implements FileSystem {}

class MockFile extends Mock implements File {}

class MockProcessManager extends Mock implements ProcessManager {}

class MockProcess extends Mock implements Process {}

class MockProcessResult extends Mock implements ProcessResult {}
