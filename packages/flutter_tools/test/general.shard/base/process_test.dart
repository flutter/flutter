// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart' show FakeProcess, MockProcess, MockProcessManager;

void main() {
  group('process exceptions', () {
    ProcessManager mockProcessManager;

    setUp(() {
      mockProcessManager = PlainMockProcessManager();
    });

    testUsingContext('runCheckedAsync exceptions should be ProcessException objects', () async {
      when(mockProcessManager.run(<String>['false']))
          .thenAnswer((Invocation invocation) => Future<ProcessResult>.value(ProcessResult(0, 1, '', '')));
      expect(() async => await runCheckedAsync(<String>['false']), throwsA(isInstanceOf<ProcessException>()));
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
      await runCommandAndStreamOutput(<String>['command']);
      expect(mockLogger.statusText, equals('${testString[0]}\n'));
      expect(mockLogger.errorText, equals('${testString[0]}\n'));
    }, overrides: <Type, Generator>{
      Logger: () => mockLogger,
      ProcessManager: () => mockProcessManager,
      OutputPreferences: () => OutputPreferences(wrapText: true, wrapColumn: 40),
      Platform: () => FakePlatform.fromPlatform(const LocalPlatform())..stdoutSupportsAnsi = false,
    });
  });

  group('runCommandAndStreamOutput', () {
    ProcessManager mockProcessManager;
    const Utf8Encoder utf8 = Utf8Encoder();

    setUp(() {
      mockProcessManager = PlainMockProcessManager();
    });

    testUsingContext('detach after detachFilter matches', () async {
      // Create a fake process which outputs three lines ("foo", "bar" and "baz")
      // to stdout, nothing to stderr, and doesn't exit.
      final Process fake = FakeProcess(
        exitCode: Completer<int>().future,
        stdout: Stream<List<int>>.fromIterable(
          <String>['foo\n', 'bar\n', 'baz\n'].map(utf8.convert)),
        stderr: const Stream<List<int>>.empty());

      when(mockProcessManager.start(<String>['test1'])).thenAnswer((_) => Future<Process>.value(fake));

      // Detach when we see "bar", and check that:
      //  - mapFunction still gets run on "baz",
      //  - we don't wait for the process to terminate (it never will),
      //  - we get an exit-code of 0 back, and
      //  - onDetach is called with the correct Process.
      bool seenBaz = false;
      String mapFunction(String line) {
        seenBaz = seenBaz || line == 'baz';
        return line;
      }

      bool onDetachCalled = false;
      Future<void> onDetach(Process p) async {
        onDetachCalled = true;
        expect(p, fake);
      }

      final int exitCode = await runCommandAndStreamOutput(
        <String>['test1'], mapFunction: mapFunction,
        detachFilter: RegExp('.*baz.*'),
        onDetach: onDetach,
      );

      expect(exitCode, 0);
      expect(seenBaz, true);
      expect(onDetachCalled, true);
    }, overrides: <Type, Generator>{ProcessManager: () => mockProcessManager});

    testUsingContext('onExit called', () async {
      // Create a fake process which exits immediately.
      final Process fake = FakeProcess(
        exitCode: Future<int>.value(0),
        stdout: const Stream<List<int>>.empty(),
        stderr: const Stream<List<int>>.empty());

      when(mockProcessManager.start(<String>['test1'])).thenAnswer((_) => Future<Process>.value(fake));

      bool onExitCalled = false;
      Future<void> onExit(Process p) async {
        onExitCalled = true;
        expect(p, fake);
      }

      final int exitCode = await runCommandAndStreamOutput(
        <String>['test1'],
        onExit: onExit
      );

      expect(exitCode, 0);
      expect(onExitCalled, true);
    }, overrides: <Type, Generator>{ProcessManager: () => mockProcessManager});
  });
}

class PlainMockProcessManager extends Mock implements ProcessManager {}
