// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/iproxy.dart';
import 'package:flutter_tools/src/project.dart';

import '../../src/common.dart';
import '../../src/context.dart';

// FlutterProject still depends on context.
void main() {
  FileSystem fileSystem;

  // This setup is required to inject the context.
  setUp(() {
    fileSystem = MemoryFileSystem.test();
  });

  testUsingContext('IOSDevice.isSupportedForProject is true on module project', () async {
    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync(r'''
name: example
flutter:
  module: {}
  ''');
    fileSystem.file('.packages').writeAsStringSync('\n');
    final FlutterProject flutterProject =
      FlutterProject.fromDirectory(fileSystem.currentDirectory);
    final IOSDevice device = setUpIOSDevice(fileSystem);

    expect(device.isSupportedForProject(flutterProject), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('IOSDevice.isSupportedForProject is true with editable host app', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').writeAsStringSync('\n');
    fileSystem.directory('ios').createSync();
    final FlutterProject flutterProject =
      FlutterProject.fromDirectory(fileSystem.currentDirectory);
    final IOSDevice device = setUpIOSDevice(fileSystem);

    expect(device.isSupportedForProject(flutterProject), true);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });


  testUsingContext('IOSDevice.isSupportedForProject is false with no host app and no module', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file('.packages').writeAsStringSync('\n');
    final FlutterProject flutterProject =
      FlutterProject.fromDirectory(fileSystem.currentDirectory);
    final IOSDevice device = setUpIOSDevice(fileSystem);

    expect(device.isSupportedForProject(flutterProject), false);
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });
}

IOSDevice setUpIOSDevice(FileSystem fileSystem) {
  return IOSDevice(
    'test',
    fileSystem: fileSystem,
    logger: BufferLogger.test(),
    iosDeploy: null, // not used in this test
    iMobileDevice: null, // not used in this test
    platform: FakePlatform(operatingSystem: 'macos'),
    name: 'iPhone 1',
    sdkVersion: '13.3',
    cpuArchitecture: DarwinArch.arm64,
    iProxy: IProxy.test(logger: BufferLogger.test(), processManager: FakeProcessManager.any()),
    interfaceType: IOSDeviceInterface.usb,
  );
}
