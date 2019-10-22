// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/linux/application_package.dart';
import 'package:flutter_tools/src/linux/linux_device.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  final LinuxDevice device = LinuxDevice();
  final MockPlatform notLinux = MockPlatform();

  when(notLinux.isLinux).thenReturn(false);

  testUsingContext('LinuxDevice defaults', () async {
    final PrebuiltLinuxApp linuxApp = PrebuiltLinuxApp(executable: 'foo');
    expect(await device.targetPlatform, TargetPlatform.linux_x64);
    expect(device.name, 'Linux');
    expect(await device.installApp(linuxApp), true);
    expect(await device.uninstallApp(linuxApp), true);
    expect(await device.isLatestBuildInstalled(linuxApp), true);
    expect(await device.isAppInstalled(linuxApp), true);
    expect(await device.stopApp(linuxApp), true);
    expect(device.category, Category.desktop);
  });

  testUsingContext('LinuxDevice: no devices listed if platform unsupported', () async {
    expect(await LinuxDevices().devices, <Device>[]);
  }, overrides: <Type, Generator>{
    Platform: () => notLinux,
  });

  testUsingContext('LinuxDevice.isSupportedForProject is true with editable host app', () async {
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    fs.directory('linux').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(LinuxDevice().isSupportedForProject(flutterProject), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager(<FakeCommand>[]),
  });

  testUsingContext('LinuxDevice.isSupportedForProject is false with no host app', () async {
    fs.file('pubspec.yaml').createSync();
    fs.file('.packages').createSync();
    final FlutterProject flutterProject = FlutterProject.current();

    expect(LinuxDevice().isSupportedForProject(flutterProject), false);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager(<FakeCommand>[]),
  });

  testUsingContext('LinuxDevice.executablePathForDevice uses the correct package executable', () async {
    final MockLinuxApp mockApp = MockLinuxApp();
    const String debugPath = 'debug/executable';
    const String profilePath = 'profile/executable';
    const String releasePath = 'release/executable';
    when(mockApp.executable(BuildMode.debug)).thenReturn(debugPath);
    when(mockApp.executable(BuildMode.profile)).thenReturn(profilePath);
    when(mockApp.executable(BuildMode.release)).thenReturn(releasePath);

    expect(LinuxDevice().executablePathForDevice(mockApp, BuildMode.debug), debugPath);
    expect(LinuxDevice().executablePathForDevice(mockApp, BuildMode.profile), profilePath);
    expect(LinuxDevice().executablePathForDevice(mockApp, BuildMode.release), releasePath);
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessManager: () => FakeProcessManager(<FakeCommand>[]),
  });
}

class MockPlatform extends Mock implements Platform {}

class MockLinuxApp extends Mock implements LinuxApp {}
