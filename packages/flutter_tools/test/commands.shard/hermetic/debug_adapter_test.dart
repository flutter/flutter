// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/debug_adapter.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';

import '../../src/common.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  group('DebugAdapterCommand', () {
    setUpAll(() {
      Cache.disableLocking();
    });
    testWithoutContext('has correct properties', () {
      final command = DebugAdapterCommand(toolContext: FakeToolContext());

      expect(command.name, 'debug-adapter');
      expect(command.aliases, <String>['debug_adapter']);
      expect(command.category, FlutterCommandCategory.tools);
      expect(command.hidden, true);

      final verboseCommand = DebugAdapterCommand(toolContext: FakeToolContext(), verboseHelp: true);
      expect(verboseCommand.hidden, false);
    });

    testWithoutContext('runs and shuts down when input stream closes', () async {
      final fs = MemoryFileSystem.test();
      final logger = BufferLogger.test();
      final stdio = FakeStdio();

      final command = DebugAdapterCommand(
        toolContext: FakeToolContext(
          fs: fs,
          logger: logger,
          platform: FakePlatform(),
          stdio: stdio,
        ),
      );

      final CommandRunner<void> runner = createTestCommandRunner(command);
      unawaited((stdio.stdin as FakeStdin).controller.close());
      await runner.run(<String>['debug-adapter']);
    });
  });
}
