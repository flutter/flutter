// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/commands/debug_adapter.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:test/fake.dart';

import '../../src/context.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  group('debug-adapter', () {
    testUsingContext('starts and shuts down cleanly when stdin is closed', () async {
      final testStdio = TestStdio();
      final fs = MemoryFileSystem.test();
      final logger = BufferLogger.test();
      final platform = FakePlatform();

      final command = DebugAdapterCommand(
        toolContext: FakeToolContext(stdio: testStdio, fs: fs, logger: logger, platform: platform),
      );

      final Future<void> runnerFuture = createTestCommandRunner(
        command,
      ).run(<String>['debug-adapter']);

      // Close the stdin stream to simulate the client disconnecting.
      await testStdio.stdinController.close();

      // The command should exit cleanly.
      await expectLater(runnerFuture, completes);
    });

    testUsingContext(
      'resolves dependencies directly from injected ToolContext instead of Zone',
      () async {
        final testStdio = TestStdio();
        final activeFs = MemoryFileSystem.test();
        final activeLogger = BufferLogger.test();
        final activePlatform = FakePlatform();

        final command = DebugAdapterCommand(
          toolContext: FakeToolContext(
            stdio: testStdio,
            fs: activeFs,
            logger: activeLogger,
            platform: activePlatform,
          ),
        );

        // Verify command getters resolve to the injected instances.
        expect(command.stdio, testStdio);
        expect(command.fileSystem, activeFs);
        expect(command.logger, activeLogger);
        expect(command.platform, activePlatform);

        // Trigger the onError handler to verify it prints to our injected logger,
        // and not the Zone's logger.
        final Future<void> runnerFuture = createTestCommandRunner(
          command,
        ).run(<String>['debug-adapter']);

        // We trigger an error by adding an error directly to the stdin stream.
        // This flows through the packet transformer and triggers the stream's onError callback.
        testStdio.stdinController.addError(ArgumentError('invalid input'));

        // Wait a short duration to allow the server to process the error and invoke onError.
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Close stdin so it shuts down.
        await testStdio.stdinController.close();
        await runnerFuture;

        // The error should be in the active logger, not the Zone's logger.
        expect(
          activeLogger.errorText,
          contains('Input could not be parsed as a Debug Adapter Protocol message.'),
        );

        final zoneLogger = globals.logger as BufferLogger;
        expect(
          zoneLogger.errorText,
          isNot(contains('Input could not be parsed as a Debug Adapter Protocol message.')),
        );
      },
      overrides: <Type, Generator>{
        // Override the Zone's logger to verify it's NOT used.
        Logger: () => BufferLogger.test(),
      },
    );
  });
}

class FakeToolContext extends Fake implements ToolContext {
  FakeToolContext({
    required this.stdio,
    required this.fs,
    required this.logger,
    required this.platform,
  });

  @override
  final Stdio stdio;

  @override
  final FileSystem fs;

  @override
  final Logger logger;

  @override
  final Platform platform;
}

class TestStdio extends Fake implements Stdio {
  final stdinController = StreamController<List<int>>();
  final stdoutController = StreamController<List<int>>();

  @override
  Stream<List<int>> get stdin => stdinController.stream;

  @override
  Stdout get stdout => TestStdout(stdoutController);
}

class TestStdout extends Fake implements Stdout {
  TestStdout(this.controller);
  final StreamController<List<int>> controller;

  @override
  IOSink get nonBlocking => TestIOSink(controller);
}

class TestIOSink extends Fake implements IOSink {
  TestIOSink(this.controller);
  final StreamController<List<int>> controller;

  @override
  void add(List<int> data) {
    if (!controller.isClosed) {
      controller.add(data);
    }
  }

  @override
  Future<void> close() async {}

  @override
  Future<void> get done => Future<void>.value();
}
