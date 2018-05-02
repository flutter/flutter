// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:file/memory.dart';
import 'package:flutter_goldens/flutter_goldens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

const String _kFlutterRoot = '/flutter';
const String _kRepositoryRoot = '$_kFlutterRoot/bin/cache/pkg/goldens';
const String _kVersionFile = '$_kFlutterRoot/bin/internal/goldens.version';
const String _kGoldensVersion = '123456abcdef';

void main() {
  MemoryFileSystem fs;
  FakePlatform platform;
  FakeProcessManager process;

  setUp(() {
    fs = new MemoryFileSystem();
    platform = new FakePlatform(environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot});
    process = new FakeProcessManager();
    fs.directory(_kFlutterRoot).createSync(recursive: true);
    fs.directory(_kRepositoryRoot).createSync(recursive: true);
    fs.file(_kVersionFile).createSync(recursive: true);
    fs.file(_kVersionFile).writeAsStringSync(_kGoldensVersion);
  });

  group('GoldensClient', () {
    GoldensClient goldens;

    setUp(() {
      goldens = new GoldensClient(
        fs: fs,
        platform: platform,
        process: process,
      );
    });

    group('prepare', () {
      test('performs minimal work if versions match', () async {
        when(process.run(typed(captureAny), workingDirectory: typed(captureAny, named: 'workingDirectory')))
            .thenAnswer((_) => new Future<io.ProcessResult>.value(io.ProcessResult(123, 0, _kGoldensVersion, '')));
        await goldens.prepare();

        // Verify that we only spawned `git rev-parse HEAD`
        final VerificationResult revParse =
            verify(process.run(typed(captureAny), workingDirectory: typed(captureAny, named: 'workingDirectory')));
        revParse.called(1);
        expect(revParse.captured.first, <String>['git', 'rev-parse', 'HEAD']);
        expect(revParse.captured.last, _kRepositoryRoot);
      });
    });
  });

  group('FlutterRepoComparator', () {});
}

class FakeProcessManager extends Mock implements ProcessManager {}
