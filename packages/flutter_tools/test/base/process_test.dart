// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/mocks.dart' show MockProcess, MockProcessManager;

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

    MockProcess Function(List<String>) processMetaFactory(List<String> stdout, {List<String> stderr = const <String>[]}) {
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
      Platform: () => FakePlatform.fromPlatform(const LocalPlatform())..stdoutSupportsAnsi = false
    });
  });
}

class PlainMockProcessManager extends Mock implements ProcessManager {}