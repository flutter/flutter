// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;
import 'dart:typed_data';

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

  group('GoldensClient', () {
    GoldensRepositoryClient goldens;

    setUp(() {
      goldens = GoldensRepositoryClient(
        fs: fs,
        process: process,
        platform: platform,
      );
    });

    group('prepare', () {
      test('performs minimal work if versions match', () async {
        when(process.run(any, workingDirectory: anyNamed('workingDirectory')))
            .thenAnswer((_) => Future<io.ProcessResult>.value(io.ProcessResult(123, 0, _kGoldensVersion, '')));
        await goldens.prepare();

        // Verify that we only spawned `git rev-parse HEAD`
        final VerificationResult verifyProcessRun =
            verify(process.run(captureAny, workingDirectory: captureAnyNamed('workingDirectory')));
        verifyProcessRun.called(1);
        expect(verifyProcessRun.captured.first, <String>['git', 'rev-parse', 'HEAD']);
        expect(verifyProcessRun.captured.last, _kRepositoryRoot);
      });
    });
  });

  group('SkiaGoldClient', () {
    SkiaGoldClient goldens;

    setUp(() {
      goldens = SkiaGoldClient(
        fs: fs,
        process: process,
        platform: platform,
      );
    });

    group('auth', () {
      test('performs minimal work if already authorized', () async {
        final Directory workDirectory = fs.directory('/workDirectory')..createSync(recursive: true);
        fs.file('/workDirectory/temp/auth_opt.json')..createSync(recursive: true);
        when(process.run(any)).thenAnswer((_) => Future<io.ProcessResult>.value(io.ProcessResult(123, 0, '', '')));
        await goldens.auth(workDirectory);

        // Verify that we spawned no process calls
        final VerificationResult verifyProcessRun =
          verifyNever(process.run(captureAny, workingDirectory: captureAnyNamed('workingDirectory')));
        expect(verifyProcessRun.callCount, 0);
      });
    });
  });

  group('FlutterGoldenFileComparator', () {
    test('calculates the basedir correctly', () async {
      final MockSkiaGoldClient goldens = MockSkiaGoldClient();
      final MockLocalFileComparator defaultComparator = MockLocalFileComparator();
      final Directory flutterRoot = fs.directory('/foo')..createSync(recursive: true);
      final Directory goldensRoot = flutterRoot.childDirectory('bar')..createSync(recursive: true);
      when(goldens.fs).thenReturn(fs);
      when(goldens.flutterRoot).thenReturn(flutterRoot);
      when(goldens.comparisonRoot).thenReturn(goldensRoot);
      when(defaultComparator.basedir).thenReturn(flutterRoot.childDirectory('baz').uri);
      final Directory basedir = FlutterGoldenFileComparator.getBaseDirectory(goldens, defaultComparator);
      expect(basedir.uri, fs.directory('/foo/bar/baz').uri);
    });
  });

  group('FlutterGoldensRepositoryFileComparator', () {
    MemoryFileSystem fs;
    FlutterGoldensRepositoryFileComparator comparator;

    setUp(() {
      fs = MemoryFileSystem();
      platform = FakePlatform(
        operatingSystem: 'linux',
        environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot},
      );
      final Directory flutterRoot = fs.directory('/path/to/flutter')..createSync(recursive: true);
      final Directory goldensRoot = flutterRoot.childDirectory('bin/cache/goldens')..createSync(recursive: true);
      final Directory testDirectory = goldensRoot.childDirectory('test/foo/bar')..createSync(recursive: true);
      comparator = FlutterGoldensRepositoryFileComparator(
        testDirectory.uri,
        fs: fs,
        platform: platform,
      );
    });

    group('compare', () {
      test('throws if golden file is not found', () async {
        try {
          await comparator.compare(Uint8List.fromList(<int>[1, 2, 3]), Uri.parse('test.png'));
          fail('TestFailure expected but not thrown');
        } on TestFailure catch (error) {
          expect(error.message, contains('Could not be compared against non-existent file'));
        }
      });

      test('returns false if golden bytes do not match', () async {
        final File goldenFile = fs.file('/path/to/flutter/bin/cache/goldens/test/foo/bar/test.png')
          ..createSync(recursive: true);
        goldenFile.writeAsBytesSync(<int>[4, 5, 6], flush: true);
        final bool result = await comparator.compare(Uint8List.fromList(<int>[1, 2, 3]), Uri.parse('test.png'));
        expect(result, isFalse);
      });

      test('returns true if golden bytes match', () async {
        final File goldenFile = fs.file('/path/to/flutter/bin/cache/goldens/test/foo/bar/test.png')
          ..createSync(recursive: true);
        goldenFile.writeAsBytesSync(<int>[1, 2, 3], flush: true);
        final bool result = await comparator.compare(Uint8List.fromList(<int>[1, 2, 3]), Uri.parse('test.png'));
        expect(result, isTrue);
      });
    });

    group('update', () {
      test('creates golden file if it does not already exist', () async {
        final File goldenFile = fs.file('/path/to/flutter/bin/cache/goldens/test/foo/bar/test.png');
        expect(goldenFile.existsSync(), isFalse);
        await comparator.update(Uri.parse('test.png'), Uint8List.fromList(<int>[1, 2, 3]));
        expect(goldenFile.existsSync(), isTrue);
        expect(goldenFile.readAsBytesSync(), <int>[1, 2, 3]);
      });

      test('overwrites golden bytes if golden file already exist', () async {
        final File goldenFile = fs.file('/path/to/flutter/bin/cache/goldens/test/foo/bar/test.png')
          ..createSync(recursive: true);
        goldenFile.writeAsBytesSync(<int>[4, 5, 6], flush: true);
        await comparator.update(Uri.parse('test.png'), Uint8List.fromList(<int>[1, 2, 3]));
        expect(goldenFile.readAsBytesSync(), <int>[1, 2, 3]);
      });
    });

    group('getTestUri', () {
      test('incorporates version number', () {
        final Uri key = comparator.getTestUri(Uri.parse('foo.png'), 1);
        expect(key, Uri.parse('foo.1.png'));
      });
      test('ignores null version number', () {
        final Uri key = comparator.getTestUri(Uri.parse('foo.png'), null);
        expect(key, Uri.parse('foo.png'));
      });
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
class MockGoldensRepositoryClient extends Mock implements GoldensRepositoryClient {}
class MockSkiaGoldClient extends Mock implements SkiaGoldClient {}
class MockLocalFileComparator extends Mock implements LocalFileComparator {}
