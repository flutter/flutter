// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/web/web_device.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group(ChromeDevice, () {
   MockChromeLauncher mockChromeLauncher;
   MockPlatform mockPlatform;
   MockProcessManager mockProcessManager;

    setUp(() async {
      mockProcessManager = MockProcessManager();
      mockChromeLauncher = MockChromeLauncher();
      mockPlatform = MockPlatform();
      when(mockChromeLauncher.launch(any)).thenAnswer((Invocation invocation) async {
        return null;
      });
    });

    test('Defaults', () async {
      final ChromeDevice chromeDevice = ChromeDevice();

      expect(chromeDevice.name, 'Chrome');
      expect(chromeDevice.id, 'chrome');
      expect(chromeDevice.supportsHotReload, true);
      expect(chromeDevice.supportsHotRestart, true);
      expect(chromeDevice.supportsStartPaused, true);
      expect(chromeDevice.supportsFlutterExit, true);
      expect(chromeDevice.supportsScreenshot, false);
      expect(await chromeDevice.isLocalEmulator, false);
    });

    testUsingContext('Invokes version command on non-Windows platforms', () async{
      when(mockPlatform.isWindows).thenReturn(false);
      when(mockProcessManager.canRun('chrome.foo')).thenReturn(true);
      when(mockProcessManager.run(<String>['chrome.foo', '--version'])).thenAnswer((Invocation invocation) async {
        return MockProcessResult(0, 'ABC');
      });
      final ChromeDevice chromeDevice = ChromeDevice();

      expect(chromeDevice.isSupported(), true);
      expect(await chromeDevice.sdkNameAndVersion, 'ABC');
    }, overrides: <Type, Generator>{
      Platform: () => mockPlatform,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('Invokes different version command on windows.', () async {
      when(mockPlatform.isWindows).thenReturn(true);
      when(mockProcessManager.canRun('chrome.foo')).thenReturn(true);
      when(mockProcessManager.run(<String>[
        'reg',
        'query',
        'HKEY_CURRENT_USER\\Software\\Google\\Chrome\\BLBeacon',
        '/v',
        'version',
      ])).thenAnswer((Invocation invocation) async {
        return MockProcessResult(0, r'HKEY_CURRENT_USER\Software\Google\Chrome\BLBeacon\ version REG_SZ 74.0.0 A');
      });
      final ChromeDevice chromeDevice = ChromeDevice();

      expect(chromeDevice.isSupported(), true);
      expect(await chromeDevice.sdkNameAndVersion, 'Google Chrome 74.0.0');
    }, overrides: <Type, Generator>{
      Platform: () => mockPlatform,
      ProcessManager: () => mockProcessManager,
    });
  });
}

class MockChromeLauncher extends Mock implements ChromeLauncher {}
class MockPlatform extends Mock implements Platform {
  @override
  Map<String, String> environment = <String, String>{'FLUTTER_WEB': 'true', kChromeEnvironment: 'chrome.foo'};
}
class MockProcessManager extends Mock implements ProcessManager {}
class MockProcessResult extends Mock implements ProcessResult {
  MockProcessResult(this.exitCode, this.stdout);

  @override
  final int exitCode;

  @override
  final String stdout;
}
