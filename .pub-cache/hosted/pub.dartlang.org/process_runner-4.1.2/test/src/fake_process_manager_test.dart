// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart' as test_package show TypeMatcher;
import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

import 'fake_process_manager.dart';

test_package.TypeMatcher<T> isInstanceOf<T>() => isA<T>();

void main() {
  group('ArchivePublisher', () {
    final List<String> stdinCaptured = <String>[];
    void _captureStdin(String item) {
      stdinCaptured.add(item);
    }

    FakeProcessManager processManager = FakeProcessManager(_captureStdin);

    setUp(() async {
      processManager = FakeProcessManager(_captureStdin);
    });

    tearDown(() async {});

    test('start works', () async {
      final Map<FakeInvocationRecord, List<ProcessResult>> calls =
          <FakeInvocationRecord, List<ProcessResult>>{
        FakeInvocationRecord(<String>['command', 'arg1', 'arg2']): <ProcessResult>[
          ProcessResult(0, 0, 'output1', ''),
        ],
        FakeInvocationRecord(<String>['command2', 'arg1', 'arg2']): <ProcessResult>[
          ProcessResult(0, 0, 'output2', ''),
        ],
      };
      processManager.fakeResults = calls;
      for (final FakeInvocationRecord key in calls.keys) {
        final Process process = await processManager.start(key.invocation);
        String output = '';
        process.stdout.listen((List<int> item) {
          output += utf8.decode(item);
        });
        await process.exitCode;
        expect(output, equals((calls[key] ?? <ProcessResult>[])[0].stdout));
      }
      processManager.verifyCalls(calls.keys.toList());
    });

    test('run works', () async {
      final Map<FakeInvocationRecord, List<ProcessResult>> calls =
          <FakeInvocationRecord, List<ProcessResult>>{
        FakeInvocationRecord(<String>['command', 'arg1', 'arg2']): <ProcessResult>[
          ProcessResult(0, 0, 'output1', ''),
        ],
        FakeInvocationRecord(<String>['command2', 'arg1', 'arg2']): <ProcessResult>[
          ProcessResult(0, 0, 'output2', ''),
        ],
      };
      processManager.fakeResults = calls;
      for (final FakeInvocationRecord key in calls.keys) {
        final ProcessResult result = await processManager.run(key.invocation);
        expect(result.stdout, equals((calls[key] ?? <ProcessResult>[])[0].stdout));
      }
      processManager.verifyCalls(calls.keys.toList());
    });

    test('runSync works', () async {
      final Map<FakeInvocationRecord, List<ProcessResult>> calls =
          <FakeInvocationRecord, List<ProcessResult>>{
        FakeInvocationRecord(<String>['command', 'arg1', 'arg2']): <ProcessResult>[
          ProcessResult(0, 0, 'output1', ''),
        ],
        FakeInvocationRecord(<String>['command2', 'arg1', 'arg2']): <ProcessResult>[
          ProcessResult(0, 0, 'output2', ''),
        ],
      };
      processManager.fakeResults = calls;
      for (final FakeInvocationRecord key in calls.keys) {
        final ProcessResult result = processManager.runSync(key.invocation);
        expect(result.stdout, equals((calls[key] ?? <ProcessResult>[])[0].stdout));
      }
      processManager.verifyCalls(calls.keys.toList());
    });

    test('captures stdin', () async {
      final Map<FakeInvocationRecord, List<ProcessResult>> calls =
          <FakeInvocationRecord, List<ProcessResult>>{
        FakeInvocationRecord(<String>['command', 'arg1', 'arg2']): <ProcessResult>[
          ProcessResult(0, 0, 'output1', ''),
        ],
        FakeInvocationRecord(<String>['command2', 'arg1', 'arg2']): <ProcessResult>[
          ProcessResult(0, 0, 'output2', ''),
        ],
      };
      processManager.fakeResults = calls;
      for (final FakeInvocationRecord key in calls.keys) {
        final Process process = await processManager.start(key.invocation);
        String output = '';
        process.stdout.listen((List<int> item) {
          output += utf8.decode(item);
        });
        final String testInput = '${(calls[key] ?? <ProcessResult>[])[0].stdout} input';
        process.stdin.add(testInput.codeUnits);
        await process.exitCode;
        expect(output, equals((calls[key] ?? <ProcessResult>[])[0].stdout));
        expect(stdinCaptured.last, equals(testInput));
      }
      processManager.verifyCalls(calls.keys.toList());
    });
  });
}
