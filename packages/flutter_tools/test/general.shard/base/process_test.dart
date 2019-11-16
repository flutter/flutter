// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart' show MockProcess,
                                   MockProcessManager,
                                   flakyProcessFactory;

void main() {
  group('process exceptions', () {
    ProcessManager mockProcessManager;

    setUp(() {
      mockProcessManager = PlainMockProcessManager();
    });

    testUsingContext('runAsync throwOnError: exceptions should be ProcessException objects', () async {
      when(mockProcessManager.run(<String>['false'])).thenAnswer(
          (Invocation invocation) => Future<ProcessResult>.value(ProcessResult(0, 1, '', '')));
      expect(() async => await processUtils.run(<String>['false'], throwOnError: true),
             throwsA(isInstanceOf<ProcessException>()));
    }, overrides: <Type, Generator>{ProcessManager: () => mockProcessManager});
  });

  group('shutdownHooks', () {
    testUsingContext('runInExpectedOrder', () async {
      int i = 1;
      int serializeRecording1;
      int serializeRecording2;
      int postProcessRecording;
      int cleanup;

      addShutdownHook(() async {
        serializeRecording1 = i++;
      }, ShutdownStage.SERIALIZE_RECORDING);

      addShutdownHook(() async {
        cleanup = i++;
      }, ShutdownStage.CLEANUP);

      addShutdownHook(() async {
        postProcessRecording = i++;
      }, ShutdownStage.POST_PROCESS_RECORDING);

      addShutdownHook(() async {
        serializeRecording2 = i++;
      }, ShutdownStage.SERIALIZE_RECORDING);

      await runShutdownHooks();

      expect(serializeRecording1, lessThanOrEqualTo(2));
      expect(serializeRecording2, lessThanOrEqualTo(2));
      expect(postProcessRecording, 3);
      expect(cleanup, 4);
    });
  });

  group('output formatting', () {
    MockProcessManager mockProcessManager;
    BufferLogger mockLogger;

    setUp(() {
      mockProcessManager = MockProcessManager();
      mockLogger = BufferLogger();
    });

    MockProcess Function(List<String>) processMetaFactory(List<String> stdout, { List<String> stderr = const <String>[] }) {
      final Stream<List<int>> stdoutStream =
          Stream<List<int>>.fromIterable(stdout.map<List<int>>((String s) => s.codeUnits));
      final Stream<List<int>> stderrStream =
      Stream<List<int>>.fromIterable(stderr.map<List<int>>((String s) => s.codeUnits));
      return (List<String> command) => MockProcess(stdout: stdoutStream, stderr: stderrStream);
    }

    testUsingContext('Command output is not wrapped.', () async {
      final List<String> testString = <String>['0123456789' * 10];
      mockProcessManager.processFactory = processMetaFactory(testString, stderr: testString);
      await processUtils.stream(<String>['command']);
      expect(mockLogger.statusText, equals('${testString[0]}\n'));
      expect(mockLogger.errorText, equals('${testString[0]}\n'));
    }, overrides: <Type, Generator>{
      Logger: () => mockLogger,
      ProcessManager: () => mockProcessManager,
      OutputPreferences: () => OutputPreferences(wrapText: true, wrapColumn: 40),
      Platform: () => FakePlatform.fromPlatform(const LocalPlatform())..stdoutSupportsAnsi = false,
    });
  });

  group('run', () {
    const Duration delay = Duration(seconds: 2);
    MockProcessManager flakyProcessManager;
    ProcessManager mockProcessManager;

    setUp(() {
      // MockProcessManager has an implementation of start() that returns the
      // result of processFactory.
      flakyProcessManager = MockProcessManager();
      mockProcessManager = MockProcessManager();
    });

    testUsingContext(' succeeds on success', () async {
      when(mockProcessManager.run(<String>['whoohoo'])).thenAnswer((_) {
        return Future<ProcessResult>.value(ProcessResult(0, 0, '', ''));
      });
      expect((await processUtils.run(<String>['whoohoo'])).exitCode, 0);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext(' fails on failure', () async {
      when(mockProcessManager.run(<String>['boohoo'])).thenAnswer((_) {
        return Future<ProcessResult>.value(ProcessResult(0, 1, '', ''));
      });
      expect((await processUtils.run(<String>['boohoo'])).exitCode, 1);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext(' throws on failure with throwOnError', () async {
      when(mockProcessManager.run(<String>['kaboom'])).thenAnswer((_) {
        return Future<ProcessResult>.value(ProcessResult(0, 1, '', ''));
      });
      expect(() => processUtils.run(<String>['kaboom'], throwOnError: true),
             throwsA(isA<ProcessException>()));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext(' does not throw on failure with whitelist', () async {
      when(mockProcessManager.run(<String>['kaboom'])).thenAnswer((_) {
        return Future<ProcessResult>.value(ProcessResult(0, 1, '', ''));
      });
      expect(
        (await processUtils.run(
          <String>['kaboom'],
          throwOnError: true,
          whiteListFailures: (int c) => c == 1,
        )).exitCode,
        1);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext(' throws on failure when not in whitelist', () async {
      when(mockProcessManager.run(<String>['kaboom'])).thenAnswer((_) {
        return Future<ProcessResult>.value(ProcessResult(0, 2, '', ''));
      });
      expect(
        () => processUtils.run(
          <String>['kaboom'],
          throwOnError: true,
          whiteListFailures: (int c) => c == 1,
        ),
        throwsA(isA<ProcessException>()));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext(' flaky process fails without retry', () async {
      flakyProcessManager.processFactory = flakyProcessFactory(
        flakes: 1,
        delay: delay,
      );
      final RunResult result = await processUtils.run(
        <String>['dummy'],
        timeout: delay + const Duration(seconds: 1),
      );
      expect(result.exitCode, -9);
    }, overrides: <Type, Generator>{
      ProcessManager: () => flakyProcessManager,
    });

    testUsingContext(' flaky process succeeds with retry', () async {
      flakyProcessManager.processFactory = flakyProcessFactory(
        flakes: 1,
        delay: delay,
      );
      final RunResult result = await processUtils.run(
        <String>['dummy'],
        timeout: delay - const Duration(milliseconds: 500),
        timeoutRetries: 1,
      );
      expect(result.exitCode, 0);
    }, overrides: <Type, Generator>{
      ProcessManager: () => flakyProcessManager,
    });

    testUsingContext(' flaky process generates ProcessException on timeout', () async {
      final Completer<List<int>> flakyStderr = Completer<List<int>>();
      final Completer<List<int>> flakyStdout = Completer<List<int>>();
      flakyProcessManager.processFactory = flakyProcessFactory(
        flakes: 1,
        delay: delay,
        stderr: () => Stream<List<int>>.fromFuture(flakyStderr.future),
        stdout: () => Stream<List<int>>.fromFuture(flakyStdout.future),
      );
      when(flakyProcessManager.killPid(any)).thenAnswer((_) {
        // Don't let the stderr stream stop until the process is killed. This
        // ensures that runAsync() does not delay killing the process until
        // stdout and stderr are drained (which won't happen).
        flakyStderr.complete(<int>[]);
        flakyStdout.complete(<int>[]);
        return true;
      });
      expect(() => processUtils.run(
        <String>['dummy'],
        timeout: delay - const Duration(milliseconds: 500),
        timeoutRetries: 0,
      ), throwsA(isInstanceOf<ProcessException>()));
    }, overrides: <Type, Generator>{
      ProcessManager: () => flakyProcessManager,
    });
  });

  group('runSync', () {
    ProcessManager mockProcessManager;

    setUp(() {
      mockProcessManager = MockProcessManager();
    });

    testUsingContext(' succeeds on success', () async {
      when(mockProcessManager.runSync(<String>['whoohoo'])).thenReturn(
        ProcessResult(0, 0, '', '')
      );
      expect(processUtils.runSync(<String>['whoohoo']).exitCode, 0);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext(' fails on failure', () async {
      when(mockProcessManager.runSync(<String>['boohoo'])).thenReturn(
        ProcessResult(0, 1, '', '')
      );
      expect(processUtils.runSync(<String>['boohoo']).exitCode, 1);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext(' throws on failure with throwOnError', () async {
      when(mockProcessManager.runSync(<String>['kaboom'])).thenReturn(
        ProcessResult(0, 1, '', '')
      );
      expect(() => processUtils.runSync(<String>['kaboom'], throwOnError: true),
             throwsA(isA<ProcessException>()));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext(' does not throw on failure with whitelist', () async {
      when(mockProcessManager.runSync(<String>['kaboom'])).thenReturn(
        ProcessResult(0, 1, '', '')
      );
      expect(
        processUtils.runSync(
          <String>['kaboom'],
          throwOnError: true,
          whiteListFailures: (int c) => c == 1,
        ).exitCode,
        1);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext(' throws on failure when not in whitelist', () async {
      when(mockProcessManager.runSync(<String>['kaboom'])).thenReturn(
        ProcessResult(0, 2, '', '')
      );
      expect(
        () => processUtils.runSync(
          <String>['kaboom'],
          throwOnError: true,
          whiteListFailures: (int c) => c == 1,
        ),
        throwsA(isA<ProcessException>()));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext(' prints stdout and stderr to trace on success', () async {
      when(mockProcessManager.runSync(<String>['whoohoo'])).thenReturn(
        ProcessResult(0, 0, 'stdout', 'stderr')
      );
      expect(processUtils.runSync(<String>['whoohoo']).exitCode, 0);
      expect(testLogger.traceText, contains('stdout'));
      expect(testLogger.traceText, contains('stderr'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext(' prints stdout to status and stderr to error on failure with throwOnError', () async {
      when(mockProcessManager.runSync(<String>['kaboom'])).thenReturn(
        ProcessResult(0, 1, 'stdout', 'stderr')
      );
      expect(() => processUtils.runSync(<String>['kaboom'], throwOnError: true),
             throwsA(isA<ProcessException>()));
      expect(testLogger.statusText, contains('stdout'));
      expect(testLogger.errorText, contains('stderr'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext(' does not print stdout with hideStdout', () async {
      when(mockProcessManager.runSync(<String>['whoohoo'])).thenReturn(
        ProcessResult(0, 0, 'stdout', 'stderr')
      );
      expect(processUtils.runSync(<String>['whoohoo'], hideStdout: true).exitCode, 0);
      expect(testLogger.traceText.contains('stdout'), isFalse);
      expect(testLogger.traceText, contains('stderr'));
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });
  });

  group('exitsHappySync', () {
    ProcessManager mockProcessManager;

    setUp(() {
      mockProcessManager = MockProcessManager();
    });

    testUsingContext(' succeeds on success', () async {
      when(mockProcessManager.runSync(<String>['whoohoo'])).thenReturn(
        ProcessResult(0, 0, '', '')
      );
      expect(processUtils.exitsHappySync(<String>['whoohoo']), isTrue);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext(' fails on failure', () async {
      when(mockProcessManager.runSync(<String>['boohoo'])).thenReturn(
        ProcessResult(0, 1, '', '')
      );
      expect(processUtils.exitsHappySync(<String>['boohoo']), isFalse);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });
  });

  group('exitsHappy', () {
    ProcessManager mockProcessManager;

    setUp(() {
      mockProcessManager = MockProcessManager();
    });

    testUsingContext(' succeeds on success', () async {
      when(mockProcessManager.run(<String>['whoohoo'])).thenAnswer((_) {
        return Future<ProcessResult>.value(ProcessResult(0, 0, '', ''));
      });
      expect(await processUtils.exitsHappy(<String>['whoohoo']), isTrue);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext(' fails on failure', () async {
      when(mockProcessManager.run(<String>['boohoo'])).thenAnswer((_) {
        return Future<ProcessResult>.value(ProcessResult(0, 1, '', ''));
      });
      expect(await processUtils.exitsHappy(<String>['boohoo']), isFalse);
    }, overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });
  });

}

class PlainMockProcessManager extends Mock implements ProcessManager {}
