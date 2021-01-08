// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/devtools_launcher.dart';
import 'package:flutter_tools/src/persistent_tool_state.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:mockito/mockito.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  BufferLogger logger;
  MockPlatform platform;

  setUp(() {
    logger = BufferLogger.test();
    platform = MockPlatform();
    when(platform.environment).thenReturn(<String, String>{});
  });

  testWithoutContext('DevtoolsLauncher launches DevTools through pub and saves the URI', () async {
    final Completer<void> completer = Completer<void>();
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      pubExecutable: 'pub',
      logger: logger,
      platform: platform,
      persistentToolState: MockPersistentToolState(),
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
      persistentToolState: MockPersistentToolState(),
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
          ],
          stdout: 'Serving DevTools at http://127.0.0.1:9100\n',
          completer: completer,
        ),
      ]),
    );

    final DevToolsServerAddress address = await launcher.serve(openInBrowser: true);
    expect(address.host, '127.0.0.1');
    expect(address.port, 9100);
  });

  testWithoutContext('DevtoolsLauncher does not activate DevTools if it was recently activated', () async {
    final PersistentToolState persistentToolState = MockPersistentToolState();
    final DateTime now = DateTime.now();
    when(persistentToolState.lastDevToolsActivationTime).thenReturn(now);
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      pubExecutable: 'pub',
      logger: logger,
      platform: platform,
      persistentToolState: persistentToolState,
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
      persistentToolState: MockPersistentToolState(),
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
        FakeCommand(
            command: const <String>[
              'pub',
              'global',
              'run',
              'devtools',
              '--no-launch-browser',
              '--vm-uri=http://127.0.0.1:1234/abcdefg',
            ],
            onRun: () {
              throw const ProcessException('pub', <String>[]);
            }
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
      persistentToolState: MockPersistentToolState(),
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
              '--vm-uri=http://127.0.0.1:1234/abcdefg',
            ],
            onRun: () {
              throw const ProcessException('pub', <String>[]);
            }
        )
      ]),
    );

    await launcher.launch(Uri.parse('http://127.0.0.1:1234/abcdefg'));

    expect(logger.errorText, contains('Failed to launch DevTools: ProcessException'));
  });
}


class MockPlatform extends Mock implements Platform {}
class MockPersistentToolState extends Mock implements PersistentToolState {}
