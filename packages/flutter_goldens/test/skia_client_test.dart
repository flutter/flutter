// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpClient, ProcessResult;

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_goldens/skia_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

void main() {
  test('502 retry', () async {
    final List<String> log = <String>[];
    await runZoned(
      zoneSpecification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
          fail('unexpected print: "$line"');
        },
        createTimer: (Zone self, ZoneDelegate parent, Zone zone, Duration duration, void Function() f) {
          log.add('CREATED TIMER: $duration');
          return parent.createTimer(zone, Duration.zero, f);
        },
      ),
      () async {
        final FileSystem fs;
        final SkiaGoldClient skiaClient = SkiaGoldClient(
          fs: fs = MemoryFileSystem(),
          process: FakeProcessManager(log),
          platform: FakePlatform(
            environment: const <String, String>{
              'GOLDCTL': 'goldctl',
            },
          ),
          httpClient: FakeHttpClient(),
          log: log.add,
          fs.directory('/'),
        );
        log.add('START'); // ignore: avoid_print
        await skiaClient.tryjobAdd('test', fs.file('golden'));
        log.add('END'); // ignore: avoid_print
        expect(log, <String>[
          'START',
          'EXEC: goldctl imgtest add --work-dir /temp --test-name t --png-file golden',
          'Transient failure (exit code 1) from Skia Gold.',
          '',
          'stdout from gold:',
          '  test resulted in a 502: 502 Bad Gateway',
          '  ',
          '',
          'Retrying in 5 seconds.',
          'CREATED TIMER: 0:00:05.000000',
          'EXEC: goldctl imgtest add --work-dir /temp --test-name t --png-file golden',
          'END',
        ]);
      },
    );
  });
}

class FakeProcessManager extends Fake implements ProcessManager {
  FakeProcessManager(this.log);

  final List<String> log;
  int _index = 0;

  @override
  Future<ProcessResult> run(List<Object> command, {
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stderrEncoding,
    Encoding? stdoutEncoding,
    String? workingDirectory,
  }) async {
    log.add('EXEC: ${command.join(' ')}');
    _index += 1;
    switch (_index) {
      case 1: return ProcessResult(0, 1, 'test resulted in a 502: 502 Bad Gateway\n', '');
      case 2: return ProcessResult(0, 0, '200', '');
      default: throw StateError('unexpected call to run');
    }
  }
}

class FakeHttpClient extends Fake implements HttpClient { }
