// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/devtools_launcher.dart';
import 'package:flutter_tools/src/resident_runner.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  testWithoutContext('DevtoolsLauncher launches DevTools through pub and saves the URI', () async {
    final Completer<void> completer = Completer<void>();
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      pubExecutable: 'pub',
      logger: BufferLogger.test(),
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
      logger: BufferLogger.test(),
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

  testWithoutContext('DevtoolsLauncher prints error if exception is thrown during activate', () async {
    final BufferLogger logger = BufferLogger.test();
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      pubExecutable: 'pub',
      logger: logger,
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
    final BufferLogger logger = BufferLogger.test();
    final DevtoolsLauncher launcher = DevtoolsServerLauncher(
      pubExecutable: 'pub',
      logger: logger,
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
