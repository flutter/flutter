// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpClient, ProcessResult;

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_goldens_client/skia_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

void main() {
  test('502 retry', () async {
    final List<String> log = <String>[];
    await runZoned(
      zoneSpecification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
          log.add(line);
        },
        createTimer: (Zone self, ZoneDelegate parent, Zone zone, Duration duration, void Function() f) {
          log.add('created timer for $duration');
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
          fs.directory('/'),
        );
        print('start'); // ignore: avoid_print
        await skiaClient.tryjobAdd('test', fs.file('golden'));
        print('end'); // ignore: avoid_print
        expect(log, <String>[
          'start',
          'goldctl imgtest add --work-dir /temp --test-name t --png-file golden',
          'Transient failure from Skia Gold, retrying in 5 seconds.',
          '',
          'stdout from gold:',
          '  502\n',
          'created timer for 0:00:05.000000',
          'goldctl imgtest add --work-dir /temp --test-name t --png-file golden',
          'end'
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
    log.add(command.join(' '));
    _index += 1;
    switch (_index) {
      case 1: return ProcessResult(0, 1, '502', '');
      case 2: return ProcessResult(0, 0, '200', '');
      default: throw StateError('unexpected call to run');
    }
  }
}
class FakeHttpClient extends Fake implements HttpClient { }
