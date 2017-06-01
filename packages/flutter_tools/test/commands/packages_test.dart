// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/packages.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  Cache.disableLocking();
  group('packages get/upgrade', () {
    Directory temp;

    setUp(() {
      temp = fs.systemTempDirectory.createTempSync('flutter_tools');
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    Future<String> runCommand(String verb, { List<String> args }) async {
      final String projectPath = await createProject(temp);

      final PackagesCommand command = new PackagesCommand();
      final CommandRunner<Null> runner = createTestCommandRunner(command);

      final List<String> commandArgs = <String>['packages', verb];
      if (args != null)
        commandArgs.addAll(args);
      commandArgs.add(projectPath);

      await runner.run(commandArgs);

      return projectPath;
    }

    void expectExists(String projectPath, String relPath) {
      expect(fs.isFileSync(fs.path.join(projectPath, relPath)), true);
    }

    // Verify that we create a project that is well-formed.
    testUsingContext('get', () async {
      final String projectPath = await runCommand('get');
      expectExists(projectPath, 'lib/main.dart');
      expectExists(projectPath, '.packages');
    });

    testUsingContext('get --offline', () async {
      final String projectPath = await runCommand('get', args: <String>['--offline']);
      expectExists(projectPath, 'lib/main.dart');
      expectExists(projectPath, '.packages');
    });

    testUsingContext('upgrade', () async {
      final String projectPath = await runCommand('upgrade');
      expectExists(projectPath, 'lib/main.dart');
      expectExists(projectPath, '.packages');
    });
  });

  group('packages test/pub', () {
    final List<List<dynamic>> log = <List<dynamic>>[];
    testUsingContext('test', () async {
      log.clear();
      await createTestCommandRunner(new PackagesCommand()).run(<String>['packages', 'test']);
      expect(log, hasLength(1));
      expect(log[0], hasLength(3));
      expect(log[0][0], matches(r'dart-sdk[\\/]bin[\\/]pub'));
      expect(log[0][1], 'run');
      expect(log[0][2], 'test');
    }, overrides: <Type, Generator>{
      ProcessManager: () {
        return new MockProcessManager((List<dynamic> command) {
          log.add(command);
        });
      },
    });
    testUsingContext('run', () async {
      log.clear();
      await createTestCommandRunner(new PackagesCommand()).run(<String>['packages', '--verbose', 'pub', 'run', '--foo', 'bar']);
      expect(log, hasLength(1));
      expect(log[0], hasLength(4));
      expect(log[0][0], matches(r'dart-sdk[\\/]bin[\\/]pub'));
      expect(log[0][1], 'run');
      expect(log[0][2], '--foo');
      expect(log[0][3], 'bar');
    }, overrides: <Type, Generator>{
      ProcessManager: () {
        return new MockProcessManager((List<dynamic> command) {
          log.add(command);
        });
      },
    });
  });
}

typedef void StartCallback(List<dynamic> command);

class MockProcessManager implements ProcessManager {
  MockProcessManager(this.onStart);

  final StartCallback onStart;

  @override
  Future<Process> start(
    List<dynamic> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment: true,
    bool runInShell: false,
    ProcessStartMode mode: ProcessStartMode.NORMAL,
  }) {
    onStart(command);
    return new Future<Process>.value(new MockProcess());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockProcess implements Process {
  @override
  Stream<List<int>> get stdout => new MockStream<List<int>>();

  @override
  Stream<List<int>> get stderr => new MockStream<List<int>>();

  @override
  Future<int> get exitCode => new Future<int>.value(0);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockStream<T> implements Stream<T> {
  @override
  Stream<S> transform<S>(StreamTransformer<T, S> streamTransformer) => new MockStream<S>();

  @override
  Stream<T> where(bool test(T event)) => new MockStream<T>();

  @override
  StreamSubscription<T> listen(void onData(T event), {Function onError, void onDone(), bool cancelOnError}) {
    return new MockStreamSubscription<T>();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockStreamSubscription<T> implements StreamSubscription<T> {
  @override
  Future<E> asFuture<E>([E futureValue]) => new Future<E>.value();

  @override
  Future<Null> cancel() => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
