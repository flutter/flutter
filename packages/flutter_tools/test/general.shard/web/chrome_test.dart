// Copyright 2014 The Flutter Authors. All rights reserved.
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
  Completer<int> exitCompleter;

  setUp(() {
    final MockPlatform platform = MockPlatform();
    exitCompleter = Completer<int>.sync();
    when(platform.isWindows).thenReturn(false);
    testbed = Testbed(overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(),
      Platform: () => platform,
      OperatingSystemUtils: () => MockOperatingSystemUtils(),
    }, setup: () {
      when(os.findFreePort()).thenAnswer((Invocation invocation) async {
        return 1234;
      });
      when(platform.environment).thenReturn(<String, String>{
        kChromeEnvironment: 'example_chrome',
      });
      when(processManager.start(any))
        .thenAnswer((Invocation invocation) async {
        return FakeProcess(
          exitCode: exitCompleter.future,
          stdout: const Stream<List<int>>.empty(),
          stderr: Stream<List<int>>.fromIterable(<List<int>>[
            utf8.encode('\n\nDevTools listening\n\n'),
          ]),
        );
      });
    });
  });

  tearDown(() {
    resetChromeForTesting();
  });

  test('can launch chrome and connect to the devtools', () => testbed.run(() async {
    const List<String> expected = <String>[
      'example_chrome',
      '--remote-debugging-port=1234',
      '--disable-background-timer-throttling',
      '--disable-extensions',
      '--disable-popup-blocking',
      '--bwsi',
      '--no-first-run',
      '--no-default-browser-check',
      '--disable-default-apps',
      '--disable-translate',
      'example_url',
    ];

    await chromeLauncher.launch('example_url', skipCheck: true);
    final VerificationResult result = verify(processManager.start(captureAny));

    expect(result.captured.single, containsAll(expected));
  }));

  test('can seed chrome temp directory with existing preferences', () => testbed.run(() async {
    final Directory dataDir = fs.directory('chrome-stuff');
    final File preferencesFile = dataDir
      .childDirectory('Default')
      .childFile('preferences');
    preferencesFile
      ..createSync(recursive: true)
      ..writeAsStringSync('example');

    await chromeLauncher.launch('example_url', skipCheck: true, dataDir: dataDir);
    final VerificationResult result = verify(processManager.start(captureAny));
    final String arg = (result.captured.single as List<String>)
      .firstWhere((String arg) => arg.startsWith('--user-data-dir='));
    final Directory tempDirectory = fs.directory(arg.split('=')[1]);
    final File tempFile = tempDirectory
      .childDirectory('Default')
      .childFile('preferences');

    expect(tempFile.existsSync(), true);
    expect(tempFile.readAsStringSync(), 'example');

    // write crash to file:
    tempFile.writeAsStringSync('"exit_type":"Crashed"');
    exitCompleter.complete(0);

    // writes non-crash back to dart_tool
    expect(preferencesFile.readAsStringSync(), '"exit_type":"Normal"');
  }));
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockPlatform extends Mock implements Platform {}
class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {}

