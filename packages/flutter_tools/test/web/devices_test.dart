// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/web/compile.dart';
import 'package:flutter_tools/src/web/web_device.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group(WebDevice, () {
   MockWebCompiler mockWebCompiler;
   MockChromeLauncher mockChromeLauncher;
   MockPlatform mockPlatform;
   FlutterProject flutterProject;
   MockProcessManager mockProcessManager;

    setUp(() async {
      mockProcessManager = MockProcessManager();
      mockChromeLauncher = MockChromeLauncher();
      mockPlatform = MockPlatform();
      mockWebCompiler = MockWebCompiler();
      flutterProject = FlutterProject.fromPath(fs.path.join(getFlutterRoot(), 'dev', 'integration_tests', 'web'));
      when(mockWebCompiler.compileDart2js(
        target: anyNamed('target'),
        minify: anyNamed('minify'),
        enabledAssertions: anyNamed('enabledAssertions'),
      )).thenAnswer((Invocation invocation) async => 0);
      when(mockChromeLauncher.launch(any)).thenAnswer((Invocation invocation) async {
        return null;
      });
    });

    testUsingContext('can build and connect to chrome', () async {
      final WebDevice device = WebDevice();
      await device.startApp(WebApplicationPackage(flutterProject));
    }, overrides: <Type, Generator>{
      ChromeLauncher: () => mockChromeLauncher,
      WebCompiler: () => mockWebCompiler,
      Platform: () => mockPlatform,
    });

    testUsingContext('Invokes version command on non-Windows platforms', () async{
      when(mockPlatform.isWindows).thenReturn(false);
      when(mockPlatform.environment).thenReturn(<String, String>{
        kChromeEnvironment: 'chrome.foo'
      });
      when(mockProcessManager.run(<String>['chrome.foo', '--version'])).thenAnswer((Invocation invocation) async {
        return MockProcessResult(0, 'ABC');
      });
      final WebDevice webDevice = WebDevice();

      expect(await webDevice.sdkNameAndVersion, 'ABC');
    }, overrides: <Type, Generator>{
      Platform: () => mockPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('Invokes different version command on windows.', () async {
      when(mockPlatform.isWindows).thenReturn(true);
      when(mockProcessManager.run(<String>[
        'reg',
        'query',
        'HKEY_CURRENT_USER\\Software\\Google\\Chrome\\BLBeacon',
        '/v',
        'version',
      ])).thenAnswer((Invocation invocation) async {
        return MockProcessResult(0, r'HKEY_CURRENT_USER\Software\Google\Chrome\BLBeacon\ version REG_SZ 74.0.0 A');
      });
      final WebDevice webDevice = WebDevice();

      expect(await webDevice.sdkNameAndVersion, 'Google Chrome 74.0.0');
    }, overrides: <Type, Generator>{
      Platform: () => mockPlatform,
      ProcessManager: () => mockProcessManager,
    });
  });
}

class MockChromeLauncher extends Mock implements ChromeLauncher {}
class MockWebCompiler extends Mock implements WebCompiler {}
class MockPlatform extends Mock implements Platform {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockProcessResult extends Mock implements ProcessResult {
  MockProcessResult(this.exitCode, this.stdout);

  @override
  final int exitCode;

  @override
  final String stdout;
}
