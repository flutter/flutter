// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_goldens/flutter_goldens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

const String _kFlutterRoot = '/flutter';
//const String _kGoldenRoot = '$_kFlutterRoot/bin/cache/pkg/goldens';
//const String _kVersionFile = '$_kFlutterRoot/bin/internal/goldens.version';
//const String _kGoldensVersion = '123456abcdef';
// TODO(Piinks): Finish testing, https://github.com/flutter/flutter/pull/31630
void main() {
  MemoryFileSystem fs;
  FakePlatform platform;
  MockProcessManager process;
  //Directory flutter;
  //Directory golden;

  setUp(() async {
    fs = MemoryFileSystem();
    platform = FakePlatform(environment: <String, String>{
      'FLUTTER_ROOT': _kFlutterRoot,
      // TODO(Piinks): Add other env vars for testing, https://github.com/flutter/flutter/pull/31630
    });
    process = MockProcessManager();
    //flutter = await fs.directory(_kFlutterRoot).create(recursive: true);
    //golden = await fs.directory(_kGoldenRoot).create(recursive: true);
    //fs.file(_kVersionFile).createSync(recursive: true);
    //fs.file(_kVersionFile).writeAsStringSync(_kGoldensVersion);
  });

  group('SkiaGoldClient', () {
    //SkiaGoldClient skiaGold;

    setUp(() {
      //skiaGold =
        SkiaGoldClient(
        fs: fs,
        platform: platform,
        process: process,
      );
    });

    group('auth', () {
      // check for successful auth - return true
      // check for unsuccessful auth - throw NonZeroExitCode
      // check for unavailable auth (not on CI) - return false
      // check for redundant work
    });

    group('init', () {
      // check for successful init - return true
      // check for unsuccessful init - throw NonZeroExitCode
      // Check for redundant work
    });

    group('imgtest', () {

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
//        final MockSkiaGoldClient skiaGold = MockSkiaGoldClient();
//        final MockLocalFileComparator defaultComparator = MockLocalFileComparator();
//        final Directory flutterRoot = fs.directory('/foo')..createSync(recursive: true);
//        final Directory skiaGoldRoot = flutterRoot.childDirectory('bar')..createSync(recursive: true);
//        when(skiaGold.fs).thenReturn(fs);
//        when(skiaGold.flutterRoot).thenReturn(flutterRoot);
//        when(skiaGold.repositoryRoot).thenReturn(skiaGoldRoot);
//        when(defaultComparator.basedir).thenReturn(flutterRoot.childDirectory('baz').uri);
//        comparator = await FlutterGoldenFileComparator.fromDefaultComparator(
//            goldens: goldens, defaultComparator: defaultComparator);
//        expect(comparator.basedir, fs.directory('/foo/bar/baz').uri);
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

      // TODO(Piinks): This is currently disabled in flutter_goldens.dart, https://github.com/flutter/flutter/pull/31630
//      test('throws if goldctl has not been authorized', () async {
//        // See that preceding test does not leave auth behind [52]
//        try {
//          await comparator.compare(Uint8List.fromList(<int>[1, 2, 3]), Uri.parse('test.png'));
//          fail('TestFailure expected but not thrown');
//        } on TestFailure catch (error) {
//          expect(error.message, contains('Could not authorize goldctl.'));
//        }
//      });
      // TODO(Piinks): Add methods to Mock SkiaGoldClient to inform the comparator and test for proper behavior. See matcher_test.dart for model, https://github.com/flutter/flutter/pull/31630
//      test('returns false if skia gold test fails', () async {
//        final File goldenFile = fs.file('/path/to/flutter/bin/cache/goldens/test/foo/bar/test.png')
//          ..createSync(recursive: true);
//        goldenFile.writeAsBytesSync(<int>[4, 5, 6], flush: true);
//        final bool result = await comparator.compare(Uint8List.fromList(<int>[1, 2, 3]), Uri.parse('test.png'));
//        expect(result, isFalse);
//      });
//
//      test('returns true if skia gold test passes', () async {
//        final File goldenFile = fs.file('/path/to/flutter/bin/cache/goldens/test/foo/bar/test.png')
//          ..createSync(recursive: true);
//        goldenFile.writeAsBytesSync(<int>[1, 2, 3], flush: true);
//        final bool result = await comparator.compare(Uint8List.fromList(<int>[1, 2, 3]), Uri.parse('test.png'));
//        expect(result, isTrue);
//      });
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
class MockSkiaGoldClient extends Mock implements SkiaGoldClient {}
class MockLocalFileComparator extends Mock implements LocalFileComparator {}
