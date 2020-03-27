// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/web/chrome.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

import '../../src/common.dart';
import '../../src/context.dart';

const List<String> _kChromeArgs = <String>[
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
  ChromeLauncher chromeLauncher;
  FileSystem fileSystem;
  Platform platform;
  FakeProcessManager processManager;
  OperatingSystemUtils operatingSystemUtils;
  Logger logger;

  setUp(() {
    logger = BufferLogger.test();
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
    chromeLauncher = ChromeLauncher(
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      operatingSystemUtils: operatingSystemUtils,
      logger: logger,
    );
  });

  tearDown(() {
    resetChromeForTesting();
  });

  test('can launch chrome and connect to the devtools', () async {
    await testLaunchChrome('/.tmp_rand0/flutter_tools_chrome_device.rand0', processManager, chromeLauncher);
  });

  test('cannot have two concurrent instances of chrome', () async {
    await testLaunchChrome('/.tmp_rand0/flutter_tools_chrome_device.rand0', processManager, chromeLauncher);
    bool pass = false;
    try {
      await testLaunchChrome('/.tmp_rand0/flutter_tools_chrome_device.rand1', processManager, chromeLauncher);
    } on ToolExit catch (_) {
      pass = true;
    }
    expect(pass, isTrue);
  });

  test('can launch new chrome after stopping a previous chrome', () async {
    final Chrome  chrome = await testLaunchChrome('/.tmp_rand0/flutter_tools_chrome_device.rand0', processManager, chromeLauncher);
    await chrome.close();
    await testLaunchChrome('/.tmp_rand0/flutter_tools_chrome_device.rand1', processManager, chromeLauncher);
  });

  test('can launch chrome with a custom debug port', () async {
    processManager.addCommand(const FakeCommand(
      command: <String>[
        'example_chrome',
        '--user-data-dir=/.tmp_rand1/flutter_tools_chrome_device.rand1',
        '--remote-debugging-port=10000',
        ..._kChromeArgs,
        'example_url',
      ],
      stderr: kDevtoolsStderr,
    ));

    await chromeLauncher.launch(
      'example_url',
      skipCheck: true,
      debugPort: 10000,
    );
  });

  test('can launch chrome headless', () async {
    processManager.addCommand(const FakeCommand(
      command: <String>[
        'example_chrome',
        '--user-data-dir=/.tmp_rand1/flutter_tools_chrome_device.rand1',
        '--remote-debugging-port=1234',
        ..._kChromeArgs,
        '--headless',
        '--disable-gpu',
        '--no-sandbox',
        '--window-size=2400,1800',
        'example_url',
      ],
      stderr: kDevtoolsStderr,
    ));

    await chromeLauncher.launch(
      'example_url',
      skipCheck: true,
      headless: true,
    );
  });

  test('can seed chrome temp directory with existing session data', () async {
    final Completer<void> exitCompleter = Completer<void>.sync();
    final Directory dataDir = fileSystem.directory('chrome-stuff');

    final File preferencesFile = dataDir
      .childDirectory('Default')
      .childFile('preferences');
    preferencesFile
      ..createSync(recursive: true)
      ..writeAsStringSync('example');

    final Directory localStorageContentsDirectory = dataDir
        .childDirectory('Default')
        .childDirectory('Local Storage')
        .childDirectory('leveldb');
    localStorageContentsDirectory.createSync(recursive: true);
    localStorageContentsDirectory.childFile('LOCK').writeAsBytesSync(<int>[]);
    localStorageContentsDirectory.childFile('LOG').writeAsStringSync('contents');

    processManager.addCommand(FakeCommand(command: const <String>[
      'example_chrome',
      '--user-data-dir=/.tmp_rand1/flutter_tools_chrome_device.rand1',
      '--remote-debugging-port=1234',
      ..._kChromeArgs,
      'example_url',
    ], completer: exitCompleter));

    await chromeLauncher.launch(
      'example_url',
      skipCheck: true,
      cacheDir: dataDir,
    );

    // validate preferences
    final File tempFile = fileSystem
      .directory('.tmp_rand1/flutter_tools_chrome_device.rand1')
      .childDirectory('Default')
      .childFile('preferences');

    expect(tempFile.existsSync(), true);
    expect(tempFile.readAsStringSync(), 'example');

    // write crash to file:
    tempFile.writeAsStringSync('"exit_type":"Crashed"');
    exitCompleter.complete();

    // writes non-crash back to dart_tool
    expect(preferencesFile.readAsStringSync(), '"exit_type":"Normal"');

    // validate local storage
    final Directory storageDir = fileSystem
        .directory('.tmp_rand1/flutter_tools_chrome_device.rand1')
        .childDirectory('Default')
        .childDirectory('Local Storage')
        .childDirectory('leveldb');

    expect(storageDir.existsSync(), true);

    expect(storageDir.childFile('LOCK').existsSync(), true);
    expect(storageDir.childFile('LOCK').readAsBytesSync(), hasLength(0));

    expect(storageDir.childFile('LOG').existsSync(), true);
    expect(storageDir.childFile('LOG').readAsStringSync(), 'contents');
  });
}

class MockOperatingSystemUtils extends Mock implements OperatingSystemUtils {}

Future<Chrome> testLaunchChrome(String userDataDir, FakeProcessManager processManager, ChromeLauncher chromeLauncher) {
  processManager.addCommand(FakeCommand(
    command: <String>[
      'example_chrome',
      '--user-data-dir=$userDataDir',
      '--remote-debugging-port=1234',
      ..._kChromeArgs,
      'example_url',
    ],
    stderr: kDevtoolsStderr,
  ));

  return chromeLauncher.launch(
    'example_url',
    skipCheck: true,
  );
}
