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
    GoldensClient goldens;

    setUp(() {
      goldens = GoldensClient(
        fs: fs,
        platform: platform,
        process: process,
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

  group('FlutterGoldenFileComparator', () {
    MemoryFileSystem fs;
    FlutterGoldenFileComparator comparator;

    setUp(() {
      fs = MemoryFileSystem();
      final Directory flutterRoot = fs.directory('/path/to/flutter')..createSync(recursive: true);
      final Directory goldensRoot = flutterRoot.childDirectory('bin/cache/goldens')..createSync(recursive: true);
      final Directory testDirectory = goldensRoot.childDirectory('test/foo/bar')..createSync(recursive: true);
      comparator = FlutterGoldenFileComparator(testDirectory.uri, fs: fs);
    });

    group('fromDefaultComparator', () {
      test('calculates the basedir correctly', () async {
        final MockGoldensClient goldens = MockGoldensClient();
        final MockLocalFileComparator defaultComparator = MockLocalFileComparator();
        final Directory flutterRoot = fs.directory('/foo')..createSync(recursive: true);
        final Directory goldensRoot = flutterRoot.childDirectory('bar')..createSync(recursive: true);
        when(goldens.fs).thenReturn(fs);
        when(goldens.flutterRoot).thenReturn(flutterRoot);
        when(goldens.repositoryRoot).thenReturn(goldensRoot);
        when(defaultComparator.basedir).thenReturn(flutterRoot.childDirectory('baz').uri);
        comparator = await FlutterGoldenFileComparator.fromDefaultComparator(
            goldens: goldens, defaultComparator: defaultComparator);
        expect(comparator.basedir, fs.directory('/foo/bar/baz').uri);
      });
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
  });
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockGoldensClient extends Mock implements GoldensClient {}
class MockLocalFileComparator extends Mock implements LocalFileComparator {}
