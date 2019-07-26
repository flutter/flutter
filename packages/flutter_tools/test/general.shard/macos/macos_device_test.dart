// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/macos/application_package.dart';
import 'package:flutter_tools/src/macos/macos_device.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

void main() {
  group(MacOSDevice, () {
    final MockPlatform notMac = MockPlatform();
    final MacOSDevice device = MacOSDevice();
    final MockProcessManager mockProcessManager = MockProcessManager();
    when(notMac.isMacOS).thenReturn(false);
    when(notMac.environment).thenReturn(const <String, String>{});
    when(mockProcessManager.run(any)).thenAnswer((Invocation invocation) async {
      return ProcessResult(0, 1, '', '');
    });

    testUsingContext('defaults', () async {
      final MockMacOSApp mockMacOSApp = MockMacOSApp();
      expect(await device.targetPlatform, TargetPlatform.darwin_x64);
      expect(device.name, 'macOS');
      expect(await device.installApp(mockMacOSApp), true);
      expect(await device.uninstallApp(mockMacOSApp), true);
      expect(await device.isLatestBuildInstalled(mockMacOSApp), true);
      expect(await device.isAppInstalled(mockMacOSApp), true);
      expect(await device.stopApp(mockMacOSApp), false);
      expect(device.category, Category.desktop);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('stopApp', () async {
      const String psOut = r'''
tester    17193   0.0  0.2  4791128  37820   ??  S     2:27PM   0:00.09 /Applications/foo
''';
      final MockMacOSApp mockMacOSApp = MockMacOSApp();
      when(mockMacOSApp.executable).thenReturn('tester');
      when(mockProcessManager.run(<String>['ps', 'aux'])).thenAnswer((Invocation invocation) async {
        return ProcessResult(1, 0, psOut, '');
      });
      when(mockProcessManager.run(<String>['kill', '17193'])).thenAnswer((Invocation invocation) async {
        return ProcessResult(2, 0, '', '');
      });
      expect(await device.stopApp(mockMacOSApp), true);
      verify(mockProcessManager.run(<String>['kill', '17193']));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    group('startApp', () {
      MockMacOSApp macOSApp;
      MockFileSystem mockFileSystem;
      MockProcessManager mockProcessManager;
      MockFile mockFile;


      setUp(() {
        macOSApp = MockMacOSApp();
        mockFileSystem = MockFileSystem();
        mockProcessManager = MockProcessManager();
        mockFile = MockFile();
        when(mockFileSystem.file('test')).thenReturn(mockFile);
        when(mockFile.existsSync()).thenReturn(true);
        when(macOSApp.executable).thenReturn('test');
        when(mockProcessManager.start(<String>['test'])).thenAnswer((Invocation invocation) async {
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
      });

      testUsingContext('can run from prebuilt application', () async {
        final LaunchResult result = await device.startApp(macOSApp, prebuiltApplication: true);
        expect(result.started, true);
        expect(result.observatoryUri, Uri.parse('http://127.0.0.1/0'));
      }, overrides: <Type, Generator>{
        FileSystem: () => mockFileSystem,
        ProcessManager: () => mockProcessManager,
      });
    });

    test('noop port forwarding', () async {
      final MacOSDevice device = MacOSDevice();
      final DevicePortForwarder portForwarder = device.portForwarder;
      final int result = await portForwarder.forward(2);
      expect(result, 2);
      expect(portForwarder.forwardedPorts.isEmpty, true);
    });

    testUsingContext('No devices listed if platform unsupported', () async {
      expect(await MacOSDevices().devices, <Device>[]);
    }, overrides: <Type, Generator>{
      Platform: () => notMac,
    });

    testUsingContext('isSupportedForProject is true with editable host app', () async {
      fs.file('pubspec.yaml').createSync();
      fs.file('.packages').createSync();
      fs.directory('macos').createSync();
      final FlutterProject flutterProject = FlutterProject.current();

      expect(MacOSDevice().isSupportedForProject(flutterProject), true);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
    });

    testUsingContext('isSupportedForProject is false with no host app', () async {
      fs.file('pubspec.yaml').createSync();
      fs.file('.packages').createSync();
      final FlutterProject flutterProject = FlutterProject.current();

      expect(MacOSDevice().isSupportedForProject(flutterProject), false);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
    });
  });
}

class MockPlatform extends Mock implements Platform {}

class MockMacOSApp extends Mock implements PrebuiltMacOSApp {}

class MockFileSystem extends Mock implements FileSystem {}

class MockFile extends Mock implements File {}

class MockProcessManager extends Mock implements ProcessManager {}

class MockProcess extends Mock implements Process {}
