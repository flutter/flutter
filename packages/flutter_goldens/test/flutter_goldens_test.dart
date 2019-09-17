// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:file/file.dart';
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
  MockProcessManager process;

  setUp(() {
    fs = MemoryFileSystem();
    platform = FakePlatform(environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot});
    process = MockProcessManager();
    fs.directory(_kFlutterRoot).createSync(recursive: true);
    fs.directory(_kRepositoryRoot).createSync(recursive: true);
    fs.file(_kVersionFile).createSync(recursive: true);
    fs.file(_kVersionFile).writeAsStringSync(_kGoldensVersion);
  });

  group('SkiaGoldClient', () {
    SkiaGoldClient goldens;

    // Mock HttpClient calls
    // - request for digest
    //   - digests > 1 = triage breakdown
    //   - digests == 0 new test
    //   - digest validation
    // - request for image bytes
    // - request for ignores
    // Add templates
    // - skia Gold responses
    //   - digest
    //   - image bytes
    //   - ignores
    // - test image bytes

    setUp(() {
      final Directory workDirectory = fs.directory('/workDirectory')
        ..createSync(recursive: true);
      goldens = SkiaGoldClient(
        workDirectory,
        fs: fs,
        process: process,
        platform: platform,
      );
    });

    group('auth', () {
      test('performs minimal work if already authorized', () async {
        fs.file('/workDirectory/temp/auth_opt.json')
          ..createSync(recursive: true);
        when(process.run(any))
          .thenAnswer((_) => Future<io.ProcessResult>
            .value(io.ProcessResult(123, 0, '', '')));
        await goldens.auth();

        // Verify that we spawned no process calls
        verifyNever(process.run(
            captureAny,
            workingDirectory: captureAnyNamed('workingDirectory'),
        ));
      });
    });
  });

  group('FlutterGoldenFileComparator', () {
    test('calculates the basedir correctly', () async {
      final MockLocalFileComparator defaultComparator = MockLocalFileComparator();
      final Directory flutterRoot = fs.directory(platform.environment['FLUTTER_ROOT'])
        ..createSync(recursive: true);
      when(defaultComparator.basedir).thenReturn(flutterRoot.childDirectory('baz').uri);
      final Directory basedir = FlutterGoldenFileComparator.getBaseDirectory(defaultComparator, platform);
      expect(basedir.uri, fs.directory('/flutter/bin/cache/pkg/skia_goldens/baz').uri);
    });
  });

  group('FlutterSkiaGoldFileComparator', () {
    FlutterSkiaGoldFileComparator comparator;

    setUp(() {
      final Directory flutterRoot = fs.directory('/path/to/flutter')..createSync(recursive: true);
      final Directory goldensRoot = flutterRoot.childDirectory('bin/cache/goldens')..createSync(recursive: true);
      final Directory testDirectory = goldensRoot.childDirectory('test/foo/bar')..createSync(recursive: true);
      comparator = FlutterSkiaGoldFileComparator(
        testDirectory.uri,
        MockSkiaGoldClient(),
        fs: fs,
        platform: platform,
      );
    });

    group('getTestUri', () {
      test('ignores version number', () {
        final Uri key = comparator.getTestUri(Uri.parse('foo.png'), 1);
        expect(key, Uri.parse('foo.png'));
      });
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockSkiaGoldClient extends Mock implements SkiaGoldClient {}
class MockLocalFileComparator extends Mock implements LocalFileComparator {}
