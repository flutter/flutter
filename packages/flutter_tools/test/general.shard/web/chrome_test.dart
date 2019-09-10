// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process_manager.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/mocks.dart';
import '../../src/testbed.dart';

void main() {
  Testbed testbed;

  setUp(() {
    final MockPlatform platform = MockPlatform();
    when(platform.isWindows).thenReturn(false);
    final MockFileSystem mockFileSystem = MockFileSystem();
    testbed = Testbed(overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(),
      Platform: () => platform,
      OperatingSystemUtils: () => MockOperatingSystemUtils(),
      FileSystem: () => mockFileSystem,
    });
  });

  test('can launch chrome and connect to the devtools', () => testbed.run(() async {
    when(os.findFreePort()).thenAnswer((Invocation invocation) async {
      return 1234;
    });
    when(platform.environment).thenReturn(<String, String>{
      kChromeEnvironment: 'example_chrome'
    });
    final Directory mockDirectory = MockDirectory();
    when(fs.systemTempDirectory).thenReturn(mockDirectory);
    when(mockDirectory.createTempSync(any)).thenReturn(mockDirectory);
    when(mockDirectory.path).thenReturn('example');
    when(processManager.start(<String>[
      'example_chrome',
      '--user-data-dir=example',
      '--remote-debugging-port=1234',
      '--disable-background-timer-throttling',
      '--disable-extensions',
      '--disable-popup-blocking',
      '--bwsi',
      '--no-first-run',
      '--no-default-browser-check',
      '--disable-default-apps',
      '--disable-translate',
      'example_url'
    ])).thenAnswer((Invocation invocation) async {
      return FakeProcess(
        exitCode: Completer<int>().future,
        stdout: const Stream<List<int>>.empty(),
        stderr: Stream<List<int>>.fromIterable(<List<int>>[
          utf8.encode('\n\nDevTools listening\n\n')
        ]),
      );
    });

    await chromeLauncher.launch('example_url', skipCheck: true);
  }));
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockPlatform extends Mock implements Platform {}
class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {}
class MockFileSystem extends Mock implements FileSystem {}
class MockDirectory extends Mock implements Directory {}
