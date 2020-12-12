// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'common.dart';

import 'fake_process_manager.dart';

void main() {
  group('ArchivePublisher', () {
    FakeProcessManager processManager;
    final List<String> stdinCaptured = <String>[];

    void _captureStdin(String item) {
      stdinCaptured.add(item);
    }

    setUp(() async {
      processManager = FakeProcessManager(stdinResults: _captureStdin);
    });

    tearDown(() async {});

    test('start works', () async {
      final Map<String, List<ProcessResult>> calls = <String, List<ProcessResult>>{
        'gsutil acl get gs://flutter_infra/releases/releases.json': <ProcessResult>[
          ProcessResult(0, 0, 'output1', ''),
        ],
        'gsutil cat gs://flutter_infra/releases/releases.json': <ProcessResult>[
          ProcessResult(0, 0, 'output2', ''),
        ],
      };
      processManager.fakeResults = calls;
      for (final String key in calls.keys) {
        final Process process = await processManager.start(key.split(' '));
        String output = '';
        process.stdout.listen((List<int> item) {
          output += utf8.decode(item);
        });
        await process.exitCode;
        expect(output, equals(calls[key][0].stdout));
      }
      processManager.verifyCalls(calls.keys.toList());
    });

    test('run works', () async {
      final Map<String, List<ProcessResult>> calls = <String, List<ProcessResult>>{
        'gsutil acl get gs://flutter_infra/releases/releases.json': <ProcessResult>[
          ProcessResult(0, 0, 'output1', ''),
        ],
        'gsutil cat gs://flutter_infra/releases/releases.json': <ProcessResult>[
          ProcessResult(0, 0, 'output2', ''),
        ],
      };
      processManager.fakeResults = calls;
      for (final String key in calls.keys) {
        final ProcessResult result = await processManager.run(key.split(' '));
        expect(result.stdout, equals(calls[key][0].stdout));
      }
      processManager.verifyCalls(calls.keys.toList());
    });

    test('runSync works', () async {
      final Map<String, List<ProcessResult>> calls = <String, List<ProcessResult>>{
        'gsutil acl get gs://flutter_infra/releases/releases.json': <ProcessResult>[
          ProcessResult(0, 0, 'output1', ''),
        ],
        'gsutil cat gs://flutter_infra/releases/releases.json': <ProcessResult>[
          ProcessResult(0, 0, 'output2', ''),
        ],
      };
      processManager.fakeResults = calls;
      for (final String key in calls.keys) {
        final ProcessResult result = processManager.runSync(key.split(' '));
        expect(result.stdout, equals(calls[key][0].stdout));
      }
      processManager.verifyCalls(calls.keys.toList());
    });

    test('captures stdin', () async {
      final Map<String, List<ProcessResult>> calls = <String, List<ProcessResult>>{
        'gsutil acl get gs://flutter_infra/releases/releases.json': <ProcessResult>[
          ProcessResult(0, 0, 'output1', ''),
        ],
        'gsutil cat gs://flutter_infra/releases/releases.json': <ProcessResult>[
          ProcessResult(0, 0, 'output2', ''),
        ],
      };
      processManager.fakeResults = calls;
      for (final String key in calls.keys) {
        final Process process = await processManager.start(key.split(' '));
        String output = '';
        process.stdout.listen((List<int> item) {
          output += utf8.decode(item);
        });
        final String testInput = '${calls[key][0].stdout} input';
        process.stdin.add(testInput.codeUnits);
        await process.exitCode;
        expect(output, equals(calls[key][0].stdout));
        expect(stdinCaptured.last, equals(testInput));
      }
      processManager.verifyCalls(calls.keys.toList());
    });
  });
}
