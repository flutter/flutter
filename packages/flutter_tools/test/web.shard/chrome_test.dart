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

import '../src/common.dart';
import '../src/fake_process_manager.dart';
import '../src/fakes.dart';

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

const List<String> kCodeCache = <String>[
  'Cache',
  'Code Cache',
  'GPUCache',
];

const String kDevtoolsStderr = '\n\nDevTools listening\n\n';

void main() {
  late FileExceptionHandler exceptionHandler;
  late ChromiumLauncher chromeLauncher;
  late FileSystem fileSystem;
  late Platform platform;
  late FakeProcessManager processManager;
  late OperatingSystemUtils operatingSystemUtils;

  setUp(() {
    exceptionHandler = FileExceptionHandler();
    operatingSystemUtils = FakeOperatingSystemUtils();
    platform = FakePlatform(operatingSystem: 'macos', environment: <String, String>{
      kChromeEnvironment: 'example_chrome',
    });
    fileSystem = MemoryFileSystem.test(opHandle: exceptionHandler.opHandle);
    processManager = FakeProcessManager.empty();
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
    await expectReturnsNormallyLater(
      _testLaunchChrome(
        '/.tmp_rand0/flutter_tools_chrome_device.rand0',
        processManager,
        chromeLauncher,
      )
    );
  });

  testWithoutContext('cannot have two concurrent instances of chrome', () async {
    await _testLaunchChrome(
      '/.tmp_rand0/flutter_tools_chrome_device.rand0',
      processManager,
      chromeLauncher,
    );

    await expectToolExitLater(
      _testLaunchChrome(
        '/.tmp_rand0/flutter_tools_chrome_device.rand1',
        processManager,
        chromeLauncher,
      ),
      contains('Only one instance of chrome can be started'),
    );
  });

  testWithoutContext('can launch new chrome after stopping a previous chrome', () async {
    final Chromium chrome = await _testLaunchChrome(
      '/.tmp_rand0/flutter_tools_chrome_device.rand0',
      processManager,
      chromeLauncher,
    );
    await chrome.close();

    await expectReturnsNormallyLater(
      _testLaunchChrome(
        '/.tmp_rand0/flutter_tools_chrome_device.rand1',
        processManager,
        chromeLauncher,
      )
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

    // Create cache dir that the Chrome launcher will attempt to persist, and a file
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

    // Create cache dir that the Chrome launcher will attempt to persist.
    fileSystem.directory('/.tmp_rand0/flutter_tools_chrome_device.rand0/Default/Local Storage')
      .createSync(recursive: true);

    await chrome.close(); // does not exit with error.
    expect(logger.errorText, contains('Failed to restore Chrome preferences'));
  });

  testWithoutContext('can launch Chrome on x86_64 macOS', () async {
    final OperatingSystemUtils macOSUtils = FakeOperatingSystemUtils(hostPlatform: HostPlatform.darwin_x64);
    final ChromiumLauncher chromiumLauncher = ChromiumLauncher(
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      operatingSystemUtils: macOSUtils,
      browserFinder: findChromeExecutable,
      logger: BufferLogger.test(),
    );

    processManager.addCommands(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'example_chrome',
          '--user-data-dir=/.tmp_rand0/flutter_tools_chrome_device.rand0',
          '--remote-debugging-port=12345',
          ...kChromeArgs,
          'example_url',
        ],
        stderr: kDevtoolsStderr,
      )
    ]);

    await expectReturnsNormallyLater(
      chromiumLauncher.launch(
        'example_url',
        skipCheck: true,
      )
    );
  });

  testWithoutContext('can launch x86_64 Chrome on ARM macOS', () async {
    final OperatingSystemUtils macOSUtils = FakeOperatingSystemUtils(hostPlatform: HostPlatform.darwin_arm);
    final ChromiumLauncher chromiumLauncher = ChromiumLauncher(
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      operatingSystemUtils: macOSUtils,
      browserFinder: findChromeExecutable,
      logger: BufferLogger.test(),
    );

    processManager.addCommands(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'file',
          'example_chrome',
        ],
        stdout: 'Mach-O 64-bit executable x86_64',
      ),
      const FakeCommand(
        command: <String>[
          'example_chrome',
          '--user-data-dir=/.tmp_rand0/flutter_tools_chrome_device.rand0',
          '--remote-debugging-port=12345',
          ...kChromeArgs,
          'example_url',
        ],
        stderr: kDevtoolsStderr,
      )
    ]);

    await expectReturnsNormallyLater(
      chromiumLauncher.launch(
        'example_url',
        skipCheck: true,
      )
    );
  });

  testWithoutContext('can launch ARM Chrome natively on ARM macOS when installed', () async {
    final OperatingSystemUtils macOSUtils = FakeOperatingSystemUtils(hostPlatform: HostPlatform.darwin_arm);
    final ChromiumLauncher chromiumLauncher = ChromiumLauncher(
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      operatingSystemUtils: macOSUtils,
      browserFinder: findChromeExecutable,
      logger: BufferLogger.test(),
    );

    processManager.addCommands(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'file',
          'example_chrome',
        ],
        stdout: 'Mach-O 64-bit executable arm64',
      ),
      const FakeCommand(
        command: <String>[
          '/usr/bin/arch',
          '-arm64',
          'example_chrome',
          '--user-data-dir=/.tmp_rand0/flutter_tools_chrome_device.rand0',
          '--remote-debugging-port=12345',
          ...kChromeArgs,
          'example_url',
        ],
        stderr: kDevtoolsStderr,
      ),
    ]);

    await expectReturnsNormallyLater(
      chromiumLauncher.launch(
        'example_url',
        skipCheck: true,
      )
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

    await expectReturnsNormallyLater(
      chromeLauncher.launch(
        'example_url',
        skipCheck: true,
        debugPort: 10000,
      )
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

    await expectReturnsNormallyLater(
      chromeLauncher.launch(
        'example_url',
        skipCheck: true,
        headless: true,
      )
    );
  });

  testWithoutContext('can seed chrome temp directory with existing session data, excluding Cache folder', () async {
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
    // Create Cache directories that should be skipped
    for (final String cache in kCodeCache) {
      dataDir
        .childDirectory('Default')
        .childDirectory(cache)
        .createSync(recursive: true);
    }

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

    expect(defaultContentDir, exists);

    // Validate cache dirs are not copied.
    for (final String cache in kCodeCache) {
      expect(fileSystem
        .directory('.tmp_rand0/flutter_tools_chrome_device.rand0')
        .childDirectory('Default')
        .childDirectory(cache), isNot(exists));
    }
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
                "<= GL(dl_tls_generation)' failed!",
      ));
    }

    // Succeed on the 4th try.
    processManager.addCommand(const FakeCommand(
      command: args,
      stderr: kDevtoolsStderr,
    ));

    await expectReturnsNormallyLater(
      chromeLauncher.launch(
        'example_url',
        skipCheck: true,
        headless: true,
      )
    );
  });

  testWithoutContext('can retry launch when chrome fails to start', () async {
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

    // Pretend to random error 3 times.
    for (int i = 0; i < 3; i++) {
      processManager.addCommand(const FakeCommand(
        command: args,
        stderr: 'BLAH BLAH',
      ));
    }

    // Succeed on the 4th try.
    processManager.addCommand(const FakeCommand(
      command: args,
      stderr: kDevtoolsStderr,
    ));

    await expectReturnsNormallyLater(
      chromeLauncher.launch(
        'example_url',
        skipCheck: true,
        headless: true,
      )
    );
  });

  testWithoutContext('gives up retrying when an error happens more than 3 times', () async {
    final BufferLogger logger = BufferLogger.test();
    final ChromiumLauncher chromiumLauncher = ChromiumLauncher(
      fileSystem: fileSystem,
      platform: platform,
      processManager: processManager,
      operatingSystemUtils: operatingSystemUtils,
      browserFinder: findChromeExecutable,
      logger: logger,
    );
    for (int i = 0; i < 4; i++) {
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
    }

    await expectToolExitLater(
      chromiumLauncher.launch(
        'example_url',
        skipCheck: true,
        headless: true,
      ),
      contains('Failed to launch browser.'),
    );
    expect(logger.errorText, contains('nothing in the std error indicating glibc error'));
  });

  testWithoutContext('Logs an error and exits if connection check fails.', () async {
    final BufferLogger logger = BufferLogger.test();
    final ChromiumLauncher chromiumLauncher = ChromiumLauncher(
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

    await expectToolExitLater(
      chromiumLauncher.launch(
        'example_url',
      ),
      contains('Unable to connect to Chrome debug port:'),
    );
    expect(logger.errorText, contains('SocketException'));
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
