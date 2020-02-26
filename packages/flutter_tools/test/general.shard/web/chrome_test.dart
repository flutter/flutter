// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:platform/platform.dart';

import '../../src/common.dart';
import '../../src/mocks.dart';
import '../../src/testbed.dart';

void main() {
  Testbed testbed;
  Completer<int> exitCompleter;

  setUp(() {
    final MockPlatform platform = MockPlatform();
    final MockOperatingSystemUtils os = MockOperatingSystemUtils();
    exitCompleter = Completer<int>.sync();
    when(platform.isWindows).thenReturn(false);
    testbed = Testbed(overrides: <Type, Generator>{
      ProcessManager: () => MockProcessManager(),
      Platform: () => platform,
      OperatingSystemUtils: () => os,
    }, setup: () {
      when(os.findFreePort()).thenAnswer((Invocation invocation) async {
        return 1234;
      });
      when(platform.environment).thenReturn(<String, String>{
        kChromeEnvironment: 'example_chrome',
      });
      when(globals.processManager.start(any))
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

  List<String> expectChromeArgs({int debugPort = 1234}) {
    return <String>[
      'example_chrome',
      '--remote-debugging-port=$debugPort',
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
  }

  test('can launch chrome and connect to the devtools', () => testbed.run(() async {
    await globals.chromeLauncher.launch('example_url', skipCheck: true);

    final VerificationResult result = verify(globals.processManager.start(captureAny));
    expect(result.captured.single, containsAll(expectChromeArgs()));
    expect(result.captured.single, isNot(contains('--window-size=2400,1800')));
  }));

  test('can launch chrome with a custom debug port', () => testbed.run(() async {
    await globals.chromeLauncher.launch('example_url', skipCheck: true, debugPort: 10000);
    final VerificationResult result = verify(globals.processManager.start(captureAny));

    expect(result.captured.single, containsAll(expectChromeArgs(debugPort: 10000)));
    expect(result.captured.single, isNot(contains('--window-size=2400,1800')));
  }));

  test('can launch chrome headless', () => testbed.run(() async {
    await globals.chromeLauncher.launch('example_url', skipCheck: true, headless: true);
    final VerificationResult result = verify(globals.processManager.start(captureAny));

    expect(result.captured.single, containsAll(expectChromeArgs()));
    expect(result.captured.single, contains('--window-size=2400,1800'));
  }));


  test('can seed chrome temp directory with existing preferences', () => testbed.run(() async {
    final Directory dataDir = globals.fs.directory('chrome-stuff');
    final File preferencesFile = dataDir
      .childDirectory('Default')
      .childFile('preferences');
    preferencesFile
      ..createSync(recursive: true)
      ..writeAsStringSync('example');

    await globals.chromeLauncher.launch('example_url', skipCheck: true, dataDir: dataDir);
    final VerificationResult result = verify(globals.processManager.start(captureAny));
    final String arg = (result.captured.single as List<String>)
      .firstWhere((String arg) => arg.startsWith('--user-data-dir='));
    final Directory tempDirectory = globals.fs.directory(arg.split('=')[1]);
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
