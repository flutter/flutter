// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/devtools_launcher.dart';
import 'package:flutter_tools/src/globals_null_migrated.dart' as globals;
import 'package:flutter_tools/src/persistent_tool_state.dart';
import 'package:flutter_tools/src/resident_runner.dart';

import '../src/common.dart';
import '../src/fake_http_client.dart';
import '../src/fake_process_manager.dart';

void main() {
  BufferLogger logger;
  FakePlatform platform;
  PersistentToolState persistentToolState;

  Cache.flutterRoot = '';
  const String devtoolsVersion = '1.2.3';
  final MemoryFileSystem fakefs = MemoryFileSystem.test()
    ..directory('bin').createSync()
    ..directory('bin/internal').createSync()
    ..file('bin/internal/devtools.version').writeAsStringSync(devtoolsVersion);

  setUp(() {
    logger = BufferLogger.test();
    platform = FakePlatform(environment: <String, String>{});

    final Directory tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_devtools_launcher_test.');
    persistentToolState = PersistentToolState.test(
      directory: tempDir,
      logger: logger,
    );
  });

   testWithoutContext('DevtoolsLauncher does not launch devtools if unable to reach pub.dev and there is no activated package', () async {
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      dartExecutable: 'dart',
      fileSystem: fakefs,
      logger: logger,
      platform: platform,
      persistentToolState: persistentToolState,
      httpClient: FakeHttpClient.list(<FakeRequest>[
        FakeRequest(
          Uri.https('pub.dev', ''),
          method: HttpMethod.head,
          response: const FakeResponse(statusCode: HttpStatus.internalServerError),
        ),
      ]),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'dart',
            'pub',
            'global',
            'list',
          ],
          stdout: 'foobar 0.9.6',
        ),
      ]),
    );

    final DevToolsServerAddress address = await launcher.serve();
    expect(address, isNull);
  });

  testWithoutContext('DevtoolsLauncher launches devtools if unable to reach pub.dev but there is an activated package', () async {
    final Completer<void> completer = Completer<void>();
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      dartExecutable: 'dart',
      fileSystem: fakefs,
      logger: logger,
      platform: platform,
      persistentToolState: persistentToolState,
      httpClient: FakeHttpClient.list(<FakeRequest>[
        FakeRequest(
          Uri.https('pub.dev', ''),
          method: HttpMethod.head,
          response: const FakeResponse(statusCode: HttpStatus.internalServerError),
        ),
      ]),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'dart',
            'pub',
            'global',
            'list',
          ],
          stdout: 'devtools 0.9.6',
        ),
        FakeCommand(
          command: const <String>[
            'dart',
            'pub',
            'global',
            'run',
            'devtools',
            '--no-launch-browser',
          ],
          stdout: 'Serving DevTools at http://127.0.0.1:9100\n',
          completer: completer,
        ),
      ]),
    );

    final DevToolsServerAddress address = await launcher.serve();
    expect(address.host, '127.0.0.1');
    expect(address.port, 9100);
  });

  testWithoutContext('DevtoolsLauncher pings PUB_HOSTED_URL instead of pub.dev for online check', () async {
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      dartExecutable: 'dart',
      fileSystem: fakefs,
      logger: logger,
      platform: FakePlatform(environment: <String, String>{
        'PUB_HOSTED_URL': 'https://pub2.dev'
      }),
      persistentToolState: persistentToolState,
      httpClient: FakeHttpClient.list(<FakeRequest>[
        FakeRequest(
          Uri.https('pub2.dev', ''),
          method: HttpMethod.head,
          response: const FakeResponse(statusCode: HttpStatus.internalServerError),
        ),
      ]),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'dart',
            'pub',
            'global',
            'list',
          ],
          stdout: 'foobar 0.9.6',
        ),
      ]),
    );

    final DevToolsServerAddress address = await launcher.serve();
    expect(address, isNull);
  });

  testWithoutContext('DevtoolsLauncher handles an invalid PUB_HOSTED_URL', () async {
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      dartExecutable: 'dart',
      fileSystem: fakefs,
      logger: logger,
      platform: FakePlatform(environment: <String, String>{
        'PUB_HOSTED_URL': r'not_an_http_url'
      }),
      persistentToolState: persistentToolState,
      httpClient: FakeHttpClient.list(<FakeRequest>[]),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'dart',
            'pub',
            'global',
            'list',
          ],
          stdout: 'foobar 0.9.6',
        ),
      ]),
    );

    final DevToolsServerAddress address = await launcher.serve();
    expect(address, isNull);
    expect(logger.errorText, contains('PUB_HOSTED_URL was set to an invalid URL: "not_an_http_url".'));
  });

  testWithoutContext('DevtoolsLauncher launches DevTools through pub and saves the URI', () async {
    final Completer<void> completer = Completer<void>();
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      dartExecutable: 'dart',
      fileSystem: fakefs,
      logger: logger,
      platform: platform,
      persistentToolState: persistentToolState,
      httpClient: FakeHttpClient.any(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'dart',
            'pub',
            'global',
            'list',
          ],
          stdout: 'devtools $devtoolsVersion',
        ),
        const FakeCommand(
          command: <String>[
            'dart',
            'pub',
            'global',
            'activate',
            'devtools',
            devtoolsVersion,
          ],
          stdout: 'Activated DevTools $devtoolsVersion',
        ),
        FakeCommand(
          command: const <String>[
            'dart',
            'pub',
            'global',
            'run',
            'devtools',
            '--no-launch-browser',
          ],
          stdout: 'Serving DevTools at http://127.0.0.1:9100\n',
          completer: completer,
        ),
      ]),
    );

    final DevToolsServerAddress address = await launcher.serve();
    expect(address.host, '127.0.0.1');
    expect(address.port, 9100);
  });

  testWithoutContext('DevtoolsLauncher launches DevTools in browser', () async {
    final Completer<void> completer = Completer<void>();
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      dartExecutable: 'dart',
      fileSystem: fakefs,
      logger: logger,
      platform: platform,
      persistentToolState: persistentToolState,
      httpClient: FakeHttpClient.any(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'dart',
            'pub',
            'global',
            'list',
          ],
          stdout: '',
        ),
        const FakeCommand(
          command: <String>[
            'dart',
            'pub',
            'global',
            'activate',
            'devtools',
            devtoolsVersion,
          ],
          stdout: 'Activated DevTools $devtoolsVersion',
        ),
        const FakeCommand(
          command: <String>[
            'dart',
            'pub',
            'global',
            'list',
          ],
          stdout: 'devtools $devtoolsVersion',
        ),
        FakeCommand(
          command: const <String>[
            'dart',
            'pub',
            'global',
            'run',
            'devtools',
            '--no-launch-browser',
          ],
          stdout: 'Serving DevTools at http://127.0.0.1:9100\n',
          completer: completer,
        ),
      ]),
    );

    final DevToolsServerAddress address = await launcher.serve();
    expect(address.host, '127.0.0.1');
    expect(address.port, 9100);
  });

  testWithoutContext('DevtoolsLauncher does not launch a new DevTools instance if one is already active', () async {
    final Completer<void> completer = Completer<void>();
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      dartExecutable: 'dart',
      fileSystem: fakefs,
      logger: logger,
      platform: platform,
      persistentToolState: persistentToolState,
      httpClient: FakeHttpClient.any(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'dart',
            'pub',
            'global',
            'list',
          ],
          stdout: 'devtools $devtoolsVersion',
        ),
        const FakeCommand(
          command: <String>[
            'dart',
            'pub',
            'global',
            'activate',
            'devtools',
            devtoolsVersion,
          ],
          stdout: 'Activated DevTools $devtoolsVersion',
        ),
        FakeCommand(
          command: const <String>[
            'dart',
            'pub',
            'global',
            'run',
            'devtools',
            '--no-launch-browser',
          ],
          stdout: 'Serving DevTools at http://127.0.0.1:9100\n',
          completer: completer,
        ),
      ]),
    );

    DevToolsServerAddress address = await launcher.serve();
    expect(address.host, '127.0.0.1');
    expect(address.port, 9100);

    // Call `serve` again and verify that the already running server is returned.
    address = await launcher.serve();
    expect(address.host, '127.0.0.1');
    expect(address.port, 9100);
  });

  testWithoutContext('DevtoolsLauncher does not activate DevTools if it was recently activated', () async {
    persistentToolState.lastDevToolsActivation = DateTime.now();
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      dartExecutable: 'dart',
      fileSystem: fakefs,
      logger: logger,
      platform: platform,
      persistentToolState: persistentToolState,
      httpClient: FakeHttpClient.any(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'dart',
            'pub',
            'global',
            'list',
          ],
          stdout: 'devtools $devtoolsVersion',
        ),
        const FakeCommand(
          command: <String>[
            'dart',
            'pub',
            'global',
            'run',
            'devtools',
            '--no-launch-browser',
          ],
          stdout: 'Serving DevTools at http://127.0.0.1:9100\n',
        ),
      ]),
    );

    await launcher.serve();
  });

  testWithoutContext('DevtoolsLauncher can launch devtools with a memory profile', () async {
    persistentToolState.lastDevToolsActivation = DateTime.now();
    final FakeProcessManager processManager = FakeProcessManager.list(<FakeCommand>[
      const FakeCommand(
        command: <String>[
          'dart',
          'pub',
          'global',
          'list',
        ],
        stdout: 'devtools $devtoolsVersion',
      ),
      const FakeCommand(
        command: <String>[
          'dart',
          'pub',
          'global',
          'run',
          'devtools',
          '--no-launch-browser',
          '--vm-uri=localhost:8181/abcdefg',
          '--profile-memory=foo'
        ],
        stdout: 'Serving DevTools at http://127.0.0.1:9100\n',
      ),
    ]);
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      dartExecutable: 'dart',
      fileSystem: fakefs,
      logger: logger,
      platform: platform,
      persistentToolState: persistentToolState,
      httpClient: FakeHttpClient.any(),
      processManager: processManager,
    );

    await launcher.launch(Uri.parse('localhost:8181/abcdefg'), additionalArguments: <String>['--profile-memory=foo']);

    expect(launcher.processStart, completes);
    expect(processManager, hasNoRemainingExpectations);
  });

  testWithoutContext('DevtoolsLauncher prints error if exception is thrown during activate', () async {
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      dartExecutable: 'dart',
      fileSystem: fakefs,
      logger: logger,
      platform: platform,
      persistentToolState: persistentToolState,
      httpClient: FakeHttpClient.any(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'dart',
            'pub',
            'global',
            'list',
          ],
          stdout: 'devtools $devtoolsVersion',
        ),
        const FakeCommand(
          command: <String>[
            'dart',
            'pub',
            'global',
            'activate',
            'devtools',
            devtoolsVersion,
          ],
          stderr: 'Error - could not activate devtools',
          exitCode: 1,
        ),
        const FakeCommand(
          command: <String>[
            'dart',
            'pub',
            'global',
            'run',
            'devtools',
            '--no-launch-browser',
            '--vm-uri=http://127.0.0.1:1234/abcdefg',
          ],
          exception: ProcessException('pub', <String>[]),
        )
      ]),
    );

    await launcher.launch(Uri.parse('http://127.0.0.1:1234/abcdefg'));

    expect(logger.errorText, contains('Error running `pub global activate devtools`:\nError - could not activate devtools'));
  });

  testWithoutContext('DevtoolsLauncher prints error if exception is thrown during launch', () async {
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      dartExecutable: 'dart',
      fileSystem: fakefs,
      logger: logger,
      platform: platform,
      persistentToolState: persistentToolState,
      httpClient: FakeHttpClient.any(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'dart',
            'pub',
            'global',
            'list',
          ],
          stdout: 'devtools $devtoolsVersion',
        ),
        const FakeCommand(
          command: <String>[
            'dart',
            'pub',
            'global',
            'activate',
            'devtools',
            devtoolsVersion,
          ],
          stdout: 'Activated DevTools $devtoolsVersion',
        ),
        const FakeCommand(
          command: <String>[
            'dart',
            'pub',
            'global',
            'run',
            'devtools',
            '--no-launch-browser',
            '--vm-uri=http://127.0.0.1:1234/abcdefg',
          ],
          exception: ProcessException('pub', <String>[]),
        )
      ]),
    );

    await launcher.launch(Uri.parse('http://127.0.0.1:1234/abcdefg'));

    expect(logger.errorText, contains('Failed to launch DevTools: ProcessException'));
  });

  testWithoutContext('DevtoolsLauncher prints trace if connecting to pub.dev throws', () async {
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      dartExecutable: 'dart',
      fileSystem: fakefs,
      logger: logger,
      platform: platform,
      persistentToolState: persistentToolState,
      httpClient: FakeHttpClient.list(<FakeRequest>[
        FakeRequest(
          Uri.https('pub.dev', ''),
          method: HttpMethod.head,
          responseError: Exception('Connection failed.'),
        ),
      ]),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'dart',
            'pub',
            'global',
            'list',
          ],
          stdout: 'foobar 0.9.6',
        ),
      ]),
    );

    await launcher.launch(Uri.parse('http://127.0.0.1:1234/abcdefg'));

    expect(logger.traceText, contains('Skipping devtools launch because connecting to pub.dev failed with Exception: Connection failed.'));
  });

  testWithoutContext('DevtoolsLauncher prints trace if connecting to pub.dev returns non-OK status code', () async {
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      dartExecutable: 'dart',
      fileSystem: fakefs,
      logger: logger,
      platform: platform,
      persistentToolState: persistentToolState,
      httpClient: FakeHttpClient.list(<FakeRequest>[
        FakeRequest(
          Uri.https('pub.dev', ''),
          method: HttpMethod.head,
          response: const FakeResponse(
            statusCode: HttpStatus.forbidden
          ),
        ),
      ]),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'dart',
            'pub',
            'global',
            'list',
          ],
          stdout: 'foobar 0.9.6',
        ),
      ]),
    );

    await launcher.launch(Uri.parse('http://127.0.0.1:1234/abcdefg'));

    expect(logger.traceText, contains('Skipping devtools launch because pub.dev responded with HTTP status code 403 instead of 200.'));
  });
}
