// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('process exceptions', () {
    ProcessManager mockProcessManager;

    setUp(() {
      mockProcessManager = MockProcessManager();
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
}

class MockProcessManager extends Mock implements ProcessManager {}
