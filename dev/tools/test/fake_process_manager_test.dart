// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'fake_process_manager.dart';

void main() {
  group('ArchivePublisher', () {
    FakeProcessManager processManager;
    final List<String> stdinCaptured = <String>[];

    void _captureStdin(String item) {
      stdinCaptured.add(item);
    }

    setUp(() async {
      processManager = new FakeProcessManager(stdinResults: _captureStdin);
    });

    tearDown(() async {});

    test('start works', () async {
      final Map<String, List<String>> calls = <String, List<String>>{
        'gsutil acl get gs://flutter_infra/releases/releases.json': <String>['output1'],
        'gsutil cat gs://flutter_infra/releases/releases.json': <String>['test'],
      };
      processManager.setResults(calls);
      for (String key in calls.keys) {
        final Process process = await processManager.start(key.split(' '));
        String output = '';
        process.stdout.listen((List<int> item) {
          output += utf8.decode(item);
        });
        await process.exitCode;
        expect(output, equals(calls[key][0]));
      }
      processManager.verifyCalls(calls.keys);
    });

    test('run works', () async {
      final Map<String, List<String>> calls = <String, List<String>>{
        'gsutil acl get gs://flutter_infra/releases/releases.json': <String>['output1'],
        'gsutil cat gs://flutter_infra/releases/releases.json': <String>['test'],
      };
      processManager.setResults(calls);
      for (String key in calls.keys) {
        final ProcessResult result = await processManager.run(key.split(' '));
        expect(result.stdout, equals(calls[key][0]));
      }
      processManager.verifyCalls(calls.keys);
    });

    test('runSync works', () async {
      final Map<String, List<String>> calls = <String, List<String>>{
        'gsutil acl get gs://flutter_infra/releases/releases.json': <String>['output1'],
        'gsutil cat gs://flutter_infra/releases/releases.json': <String>['test'],
      };
      processManager.setResults(calls);
      for (String key in calls.keys) {
        final ProcessResult result = processManager.runSync(key.split(' '));
        expect(result.stdout, equals(calls[key][0]));
      }
      processManager.verifyCalls(calls.keys);
    });

    test('captures stdin', () async {
      final Map<String, List<String>> calls = <String, List<String>>{
        'gsutil acl get gs://flutter_infra/releases/releases.json': <String>['output1'],
        'gsutil cat gs://flutter_infra/releases/releases.json': <String>['test'],
      };
      processManager.setResults(calls);
      for (String key in calls.keys) {
        final Process process = await processManager.start(key.split(' '));
        String output = '';
        process.stdout.listen((List<int> item) {
          output += utf8.decode(item);
        });
        final String testInput = '${calls[key][0]} input';
        process.stdin.add(testInput.codeUnits);
        await process.exitCode;
        expect(output, equals(calls[key][0]));
        expect(stdinCaptured.last, equals(testInput));
      }
      processManager.verifyCalls(calls.keys);
    });
  });
}
