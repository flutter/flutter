// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/web/chrome.dart';

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
  FileExceptionHandler exceptionHandler;
  ChromiumLauncher chromeLauncher;
  FileSystem fileSystem;
  Platform platform;
  FakeProcessManager processManager;
  OperatingSystemUtils operatingSystemUtils;

  setUp(() {
    exceptionHandler = FileExceptionHandler();
    operatingSystemUtils = FakeOperatingSystemUtils();
    platform = FakePlatform(operatingSystem: 'macos', environment: <String, String>{
      kChromeEnvironment: 'example_chrome',
    });
    fileSystem = MemoryFileSystem.test(opHandle: exceptionHandler.opHandle);
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
      () async => _testLaunchChrome(
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
      () async => _testLaunchChrome(
        '/.tmp_rand0/flutter_tools_chrome_device.rand1',
        processManager,
        chromeLauncher,
      ),
      throwsToolExit(message: 'Only one instance of chrome can be started'),
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
      () async => _testLaunchChrome(
        '/.tmp_rand0/flutter_tools_chrome_device.rand1',
        processManager,
        chromeLauncher,
      ),
      returnsNormally,
    );
  });

  testWithoutContext('does not crash if saving profile information fails due to a file system exception.', () async {
    final BufferLogger logger = BufferLogger.test();
    chromeLauncher = ChromiumLauncher(
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      operatingSystemUtils: operatingSystemUtils,
      browserFinder: findChromeExecutable,
      logger: logger,
    );
    processManager.addCommand(const FakeCommand(
      command: <String>[
        'example_chrome',
        '--user-data-dir=/.tmp_rand0/flutter_tools_chrome_device.rand0',
        '--remote-debugging-port=12345',
        ...kChromeArgs,
        'example_url',
      ],
      stderr: kDevtoolsStderr,
    ));

    final Chromium chrome = await chromeLauncher.launch(
      'example_url',
      skipCheck: true,
      cacheDir: fileSystem.currentDirectory,
    );

    // Create cache dir that the Chrome launcher will atttempt to persist, and a file
    // that will thrown an exception when it is read.
    const String directoryPrefix = '/.tmp_rand0/flutter_tools_chrome_device.rand0/Default';
    fileSystem.directory('$directoryPrefix/Local Storage')
      .createSync(recursive: true);
    final File file = fileSystem.file('$directoryPrefix/Local Storage/foo')
      ..createSync(recursive: true);
    exceptionHandler.addError(
      file,
      FileSystemOp.read,
      const FileSystemException(),
    );

    await chrome.close(); // does not exit with error.
    expect(logger.errorText, contains('Failed to save Chrome preferences'));
  });

  testWithoutContext('does not crash if restoring profile information fails due to a file system exception.', () async {
    final BufferLogger logger = BufferLogger.test();
    final File file = fileSystem.file('/Default/foo')
      ..createSync(recursive: true);
    exceptionHandler.addError(
      file,
      FileSystemOp.read,
      const FileSystemException(),
    );
    chromeLauncher = ChromiumLauncher(
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      operatingSystemUtils: operatingSystemUtils,
      browserFinder: findChromeExecutable,
      logger: logger,
    );

    processManager.addCommand(const FakeCommand(
      command: <String>[
        'example_chrome',
        '--user-data-dir=/.tmp_rand0/flutter_tools_chrome_device.rand0',
        '--remote-debugging-port=12345',
        ...kChromeArgs,
        'example_url',
      ],
      stderr: kDevtoolsStderr,
    ));

    fileSystem.currentDirectory.childDirectory('Default').createSync();
    final Chromium chrome = await chromeLauncher.launch(
      'example_url',
      skipCheck: true,
      cacheDir: fileSystem.currentDirectory,
    );

    // Create cache dir that the Chrome launcher will atttempt to persist.
    fileSystem.directory('/.tmp_rand0/flutter_tools_chrome_device.rand0/Default/Local Storage')
      .createSync(recursive: true);

    await chrome.close(); // does not exit with error.
    expect(logger.errorText, contains('Failed to restore Chrome preferences'));
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
      () async => chromeLauncher.launch(
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
        '--remote-debugging-port=12345',
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
      () async => chromeLauncher.launch(
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

    final Directory defaultContentDirectory = dataDir
        .childDirectory('Default')
        .childDirectory('Foo');
        defaultContentDirectory.createSync(recursive: true);

    processManager.addCommand(FakeCommand(
      command: const <String>[
        'example_chrome',
        '--user-data-dir=/.tmp_rand0/flutter_tools_chrome_device.rand0',
        '--remote-debugging-port=12345',
        ...kChromeArgs,
        'example_url',
      ],
      completer: exitCompleter,
      stderr: kDevtoolsStderr,
    ));

    await chromeLauncher.launch(
      'example_url',
      skipCheck: true,
      cacheDir: dataDir,
    );

    exitCompleter.complete();
    await Future<void>.delayed(const Duration(milliseconds: 1));

    // writes non-crash back to dart_tool
    expect(preferencesFile.readAsStringSync(), '"exit_type":"Normal"');


    // validate any Default content is copied
    final Directory defaultContentDir = fileSystem
        .directory('.tmp_rand0/flutter_tools_chrome_device.rand0')
        .childDirectory('Default')
        .childDirectory('Foo');

    expect(defaultContentDir.existsSync(), true);
  });

  testWithoutContext('can retry launch when glibc bug happens', () async {
    const List<String> args = <String>[
      'example_chrome',
      '--user-data-dir=/.tmp_rand0/flutter_tools_chrome_device.rand0',
      '--remote-debugging-port=12345',
      ...kChromeArgs,
      '--headless',
      '--disable-gpu',
      '--no-sandbox',
      '--window-size=2400,1800',
      'example_url',
    ];

    // Pretend to hit glibc bug 3 times.
    for (int i = 0; i < 3; i++) {
      processManager.addCommand(const FakeCommand(
        command: args,
        stderr: 'Inconsistency detected by ld.so: ../elf/dl-tls.c: 493: '
                '_dl_allocate_tls_init: Assertion `listp->slotinfo[cnt].gen '
                '<= GL(dl_tls_generation)\' failed!',
      ));
    }

    // Succeed on the 4th try.
    processManager.addCommand(const FakeCommand(
      command: args,
      stderr: kDevtoolsStderr,
    ));

    expect(
      () async => chromeLauncher.launch(
        'example_url',
        skipCheck: true,
        headless: true,
      ),
      returnsNormally,
    );
  });

  testWithoutContext('gives up retrying when a non-glibc error happens', () async {
    processManager.addCommand(const FakeCommand(
      command: <String>[
        'example_chrome',
        '--user-data-dir=/.tmp_rand0/flutter_tools_chrome_device.rand0',
        '--remote-debugging-port=12345',
        ...kChromeArgs,
        '--headless',
        '--disable-gpu',
        '--no-sandbox',
        '--window-size=2400,1800',
        'example_url',
      ],
      stderr: 'nothing in the std error indicating glibc error',
    ));

    expect(
      () async => chromeLauncher.launch(
        'example_url',
        skipCheck: true,
        headless: true,
      ),
      throwsToolExit(message: 'Failed to launch browser.'),
    );
  });
}

Future<Chromium> _testLaunchChrome(String userDataDir, FakeProcessManager processManager, ChromiumLauncher chromeLauncher) {
  processManager.addCommand(FakeCommand(
    command: <String>[
      'example_chrome',
      '--user-data-dir=$userDataDir',
      '--remote-debugging-port=12345',
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
