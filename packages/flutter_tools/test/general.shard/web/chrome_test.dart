// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

const List<String> kChromeArgs = <String>[
  '--disable-background-timer-throttling',
  '--disable-extensions',
  '--disable-popup-blocking',
  '--bwsi',
  '--no-first-run',
  '--no-default-browser-check',
  '--disable-default-apps',
  '--disable-translate',
];

const String kDevtoolsStderr = '\n\nDevTools listening\n\n';

void main() {
  ChromiumLauncher chromeLauncher;
  FileSystem fileSystem;
  Platform platform;
  FakeProcessManager processManager;
  OperatingSystemUtils operatingSystemUtils;

  setUp(() {
    operatingSystemUtils = MockOperatingSystemUtils();
    when(operatingSystemUtils.findFreePort())
        .thenAnswer((Invocation invocation) async {
      return 1234;
    });
    platform = FakePlatform(operatingSystem: 'macos', environment: <String, String>{
      kChromeEnvironment: 'example_chrome',
    });
    fileSystem = MemoryFileSystem.test();
    processManager = FakeProcessManager.list(<FakeCommand>[]);
    chromeLauncher = ChromiumLauncher(
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      operatingSystemUtils: operatingSystemUtils,
      browserFinder: findChromeExecutable,
      logger: BufferLogger.test(),
    );
  });

  testWithoutContext('can launch chrome and connect to the devtools', () async {
    expect(
      () async => await _testLaunchChrome(
        '/.tmp_rand0/flutter_tools_chrome_device.rand0',
        processManager,
        chromeLauncher,
      ),
      returnsNormally,
    );
  });

  testWithoutContext('cannot have two concurrent instances of chrome', () async {
    await _testLaunchChrome(
      '/.tmp_rand0/flutter_tools_chrome_device.rand0',
      processManager,
      chromeLauncher,
    );

    expect(
      () async => await _testLaunchChrome(
        '/.tmp_rand0/flutter_tools_chrome_device.rand1',
        processManager,
        chromeLauncher,
      ),
      throwsToolExit(),
    );
  });

  testWithoutContext('can launch new chrome after stopping a previous chrome', () async {
    final Chromium chrome = await _testLaunchChrome(
      '/.tmp_rand0/flutter_tools_chrome_device.rand0',
      processManager,
      chromeLauncher,
    );
    await chrome.close();

    expect(
      () async => await _testLaunchChrome(
        '/.tmp_rand0/flutter_tools_chrome_device.rand1',
        processManager,
        chromeLauncher,
      ),
      returnsNormally,
    );
  });

  testWithoutContext('can launch chrome with a custom debug port', () async {
    processManager.addCommand(const FakeCommand(
      command: <String>[
        'example_chrome',
        '--user-data-dir=/.tmp_rand0/flutter_tools_chrome_device.rand0',
        '--remote-debugging-port=10000',
        ...kChromeArgs,
        'example_url',
      ],
      stderr: kDevtoolsStderr,
    ));

    expect(
      () async => await chromeLauncher.launch(
        'example_url',
        skipCheck: true,
        debugPort: 10000,
      ),
      returnsNormally,
    );
  });

  testWithoutContext('can launch chrome headless', () async {
    processManager.addCommand(const FakeCommand(
      command: <String>[
        'example_chrome',
        '--user-data-dir=/.tmp_rand0/flutter_tools_chrome_device.rand0',
        '--remote-debugging-port=1234',
        ...kChromeArgs,
        '--headless',
        '--disable-gpu',
        '--no-sandbox',
        '--window-size=2400,1800',
        'example_url',
      ],
      stderr: kDevtoolsStderr,
    ));

    expect(
      () async => await chromeLauncher.launch(
        'example_url',
        skipCheck: true,
        headless: true,
      ),
      returnsNormally,
    );
  });

  testWithoutContext('can seed chrome temp directory with existing session data', () async {
    final Completer<void> exitCompleter = Completer<void>.sync();
    final Directory dataDir = fileSystem.directory('chrome-stuff');

    final File preferencesFile = dataDir
      .childDirectory('Default')
      .childFile('preferences');
    preferencesFile
      ..createSync(recursive: true)
      ..writeAsStringSync('"exit_type":"Crashed"');

    final Directory localStorageContentsDirectory = dataDir
        .childDirectory('Default')
        .childDirectory('Local Storage')
        .childDirectory('leveldb');
    localStorageContentsDirectory.createSync(recursive: true);
    localStorageContentsDirectory.childFile('LOCK').writeAsBytesSync(<int>[]);
    localStorageContentsDirectory.childFile('LOG').writeAsStringSync('contents');

    processManager.addCommand(FakeCommand(command: const <String>[
      'example_chrome',
      '--user-data-dir=/.tmp_rand0/flutter_tools_chrome_device.rand0',
      '--remote-debugging-port=1234',
      ...kChromeArgs,
      'example_url',
    ], completer: exitCompleter));

    await chromeLauncher.launch(
      'example_url',
      skipCheck: true,
      cacheDir: dataDir,
    );

    exitCompleter.complete();
    await Future<void>.delayed(const Duration(microseconds: 1));

    // writes non-crash back to dart_tool
    expect(preferencesFile.readAsStringSync(), '"exit_type":"Normal"');

    // validate local storage
    final Directory storageDir = fileSystem
        .directory('.tmp_rand0/flutter_tools_chrome_device.rand0')
        .childDirectory('Default')
        .childDirectory('Local Storage')
        .childDirectory('leveldb');

    expect(storageDir.existsSync(), true);

    expect(storageDir.childFile('LOCK'), exists);
    expect(storageDir.childFile('LOCK').readAsBytesSync(), hasLength(0));

    expect(storageDir.childFile('LOG'), exists);
    expect(storageDir.childFile('LOG').readAsStringSync(), 'contents');
  });
}

class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {}

Future<Chromium> _testLaunchChrome(String userDataDir, FakeProcessManager processManager, ChromiumLauncher chromeLauncher) {
  processManager.addCommand(FakeCommand(
    command: <String>[
      'example_chrome',
      '--user-data-dir=$userDataDir',
      '--remote-debugging-port=1234',
      ...kChromeArgs,
      'example_url',
    ],
    stderr: kDevtoolsStderr,
  ));

  return chromeLauncher.launch(
    'example_url',
    skipCheck: true,
  );
}
