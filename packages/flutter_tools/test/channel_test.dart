// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/channel.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:process/process.dart';

import 'src/common.dart';
import 'src/context.dart';

void main() {
  group('channel', () {
    final MockProcessManager mockProcessManager = new MockProcessManager();

    setUpAll(() {
      Cache.disableLocking();
    });

    testUsingContext('list', () async {
      final ChannelCommand command = new ChannelCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);
      await runner.run(<String>['channel']);
      expect(testLogger.errorText, hasLength(0));
      // The bots may return an empty list of channels (network hiccup?)
      // and when run locally the list of branches might be different
      // so we check for the header text rather than any specific channel name.
      expect(testLogger.statusText, contains('Flutter channels:'));
    });

    testUsingContext('removes duplicates', () async {
      final Stream<List<int>> stdout = new Stream<List<int>>.fromIterable(<List<int>>[
        utf8.encode(
          'origin/dev\n'
          'origin/beta\n'
          'upstream/dev\n'
          'upstream/beta\n'
        ),
      ]);
      final Process process = new MockProcess();

      when(process.stdout).thenReturn(stdout);
      when(process.stderr).thenReturn(const Stream<List<int>>.empty());
      when(process.exitCode).thenReturn(new Future<int>.value(0));
      when(mockProcessManager.start(
        <String>['git', 'branch', '-r'],
        workingDirectory: typed(any, named: 'workingDirectory'),
        environment: typed(any, named: 'environment')))
      .thenReturn(new Future<Process>.value(process));

      final ChannelCommand command = new ChannelCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);
      await runner.run(<String>['channel']);

      verify(mockProcessManager.start(<String>['git', 'branch', '-r'],
          workingDirectory: typed(any, named: 'workingDirectory'),
          environment: typed(any, named: 'environment'))).called(1);

      expect(testLogger.errorText, hasLength(0));

      // format the status text for a simpler assertion.
      final Iterable<String> rows = testLogger.statusText
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line?.isNotEmpty == true)
        .skip(1); // remove `Flutter channels:` line

      expect(rows, <String>['dev', 'beta']);
    }, overrides: <Type, Generator>{
      ProcessManager: () =>  mockProcessManager,
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}

class MockProcess extends Mock implements Process {}