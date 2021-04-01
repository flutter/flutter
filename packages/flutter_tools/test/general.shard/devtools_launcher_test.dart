// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/devtools_launcher.dart';
import 'package:flutter_tools/src/globals_null_migrated.dart' as globals;
import 'package:flutter_tools/src/persistent_tool_state.dart';
import 'package:flutter_tools/src/resident_runner.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fake_http_client.dart';

void main() {
  BufferLogger logger;
  FakePlatform platform;
  PersistentToolState persistentToolState;

  setUp(() {
    logger = BufferLogger.test();
    platform = FakePlatform(environment: <String, String>{});

    final Directory tempDir = globals.fs.systemTempDirectory.createTempSync('devtools_launcher_test');
    persistentToolState = PersistentToolState.test(
      directory: tempDir,
      logger: logger,
    );
  });

   testWithoutContext('DevtoolsLauncher does not launch devtools if unable to reach pub.dev', () async {
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      pubExecutable: 'pub',
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
      processManager: FakeProcessManager.list(<FakeCommand>[]),
    );

    final DevToolsServerAddress address = await launcher.serve();
    expect(address, isNull);
  });

  testWithoutContext('DevtoolsLauncher pings PUB_HOSTED_URL instead of pub.dev for online check', () async {
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      pubExecutable: 'pub',
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
      processManager: FakeProcessManager.list(<FakeCommand>[]),
    );

    final DevToolsServerAddress address = await launcher.serve();
    expect(address, isNull);
  });

  testWithoutContext('DevtoolsLauncher handles an invalid PUB_HOSTED_URL', () async {
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      pubExecutable: 'pub',
      logger: logger,
      platform: FakePlatform(environment: <String, String>{
        'PUB_HOSTED_URL': r'not_an_http_url'
      }),
      persistentToolState: persistentToolState,
      httpClient: FakeHttpClient.list(<FakeRequest>[]),
      processManager: FakeProcessManager.list(<FakeCommand>[]),
    );

    final DevToolsServerAddress address = await launcher.serve();
    expect(address, isNull);
    expect(logger.errorText, contains('PUB_HOSTED_URL was set to an invalid URL: "not_an_http_url".'));
  });

  testWithoutContext('DevtoolsLauncher launches DevTools through pub and saves the URI', () async {
    final Completer<void> completer = Completer<void>();
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      pubExecutable: 'pub',
      logger: logger,
      platform: platform,
      persistentToolState: persistentToolState,
      httpClient: FakeHttpClient.any(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'pub',
            'global',
            'activate',
            'devtools',
          ],
          stdout: 'Activated DevTools 0.9.5',
        ),
        const FakeCommand(
          command: <String>[
            'pub',
            'global',
            'list',
          ],
          stdout: 'devtools 0.9.6',
        ),
        FakeCommand(
          command: const <String>[
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
      pubExecutable: 'pub',
      logger: logger,
      platform: platform,
      persistentToolState: persistentToolState,
      httpClient: FakeHttpClient.any(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'pub',
            'global',
            'activate',
            'devtools',
          ],
          stdout: 'Activated DevTools 0.9.5',
        ),
        const FakeCommand(
          command: <String>[
            'pub',
            'global',
            'list',
          ],
          stdout: 'devtools 0.9.6',
        ),
        FakeCommand(
          command: const <String>[
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
      pubExecutable: 'pub',
      logger: logger,
      platform: platform,
      persistentToolState: persistentToolState,
      httpClient: FakeHttpClient.any(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'pub',
            'global',
            'activate',
            'devtools',
          ],
          stdout: 'Activated DevTools 0.9.5',
        ),
        const FakeCommand(
          command: <String>[
            'pub',
            'global',
            'list',
          ],
          stdout: 'devtools 0.9.6',
        ),
        FakeCommand(
          command: const <String>[
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
    persistentToolState.lastDevToolsActivationTime = DateTime.now();
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      pubExecutable: 'pub',
      logger: logger,
      platform: platform,
      persistentToolState: persistentToolState,
      httpClient: FakeHttpClient.any(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'pub',
            'global',
            'list',
          ],
          stdout: 'devtools 0.9.6',
        ),
        const FakeCommand(
          command: <String>[
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

  testWithoutContext('DevtoolsLauncher prints error if exception is thrown during activate', () async {
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      pubExecutable: 'pub',
      logger: logger,
      platform: platform,
      persistentToolState: persistentToolState,
      httpClient: FakeHttpClient.any(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'pub',
            'global',
            'activate',
            'devtools',
          ],
          stderr: 'Error - could not activate devtools',
          exitCode: 1,
        ),
        const FakeCommand(
          command: <String>[
            'pub',
            'global',
            'list',
          ],
          stdout: 'devtools 0.9.6',
        ),
        const FakeCommand(
          command: <String>[
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
      pubExecutable: 'pub',
      logger: logger,
      platform: platform,
      persistentToolState: persistentToolState,
      httpClient: FakeHttpClient.any(),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>[
            'pub',
            'global',
            'activate',
            'devtools',
          ],
          stdout: 'Activated DevTools 0.9.5',
        ),
        const FakeCommand(
          command: <String>[
            'pub',
            'global',
            'list',
          ],
          stdout: 'devtools 0.9.6',
        ),
        const FakeCommand(
          command: <String>[
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
}
