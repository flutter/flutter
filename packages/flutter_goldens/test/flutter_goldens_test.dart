// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
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

// 1x1 transparent pixel
const List<int> _kTestPngBytes =
<int>[137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0,
  1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 11, 73, 68, 65, 84,
  120, 1, 99, 97, 0, 2, 0, 0, 25, 0, 5, 144, 240, 54, 245, 0, 0, 0, 0, 73, 69,
  78, 68, 174, 66, 96, 130];

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

String digestResponseTemplate() {
  return '''
  {
  "digests": [
    {
      "test": "flutter.golden_test.1",
      "digest": "aa748136c70cefdda646df5be0ae189d",
      "status": "positive",
      "paramset": {
        "Platform": [
          "macos"
        ],
        "ext": [
          "png"
        ],
        "name": [
          "flutter.golden_test.1"
        ],
        "source_type": [
          "flutter"
        ]
      },
      "traces": {
        "tileSize": 200,
        "traces": [
          {
            "data": [
              {
                "x": 0,
                "y": 0,
                "s": 1
              },
              {
                "x": 1,
                "y": 0,
                "s": 1
              },
              {
                "x": 2,
                "y": 0,
                "s": 1
              },
            ],
            "label": ",Platform=macos,name=flutter.golden_test.1,source_type=flutter,",
            "params": {
              "Platform": "macos",
              "ext": "png",
              "name": "flutter.golden_test.1",
              "source_type": "flutter"
            }
          }
        ],
        "digests": [
          {
            "digest": "aa748136c70cefdda646df5be0ae189d",
            "status": "positive"
          },
          {
            "digest": "0b9795b218a8e367b552dcea55c8d589",
            "status": "positive"
          }
        ]
      },
      "closestRef": "pos",
      "refDiffs": {
        "neg": null,
        "pos": {
          "numDiffPixels": 999,
          "pixelDiffPercent": 0.4995,
          "maxRGBADiffs": [
            86,
            86,
            86,
            0
          ],
          "dimDiffer": false,
          "diffs": {
            "combined": 0.381955,
            "percent": 0.4995,
            "pixel": 999
          },
          "digest": "c3312ad1479f50caf3754b42a42740c5",
          "status": "positive",
          "paramset": {
            "Platform": [
              "linux"
            ],
            "ext": [
              "png"
            ],
            "name": [
              "flutter.golden_test.1"
            ],
            "source_type": [
              "flutter"
            ]
          },
          "n": 167
        }
      }
    }
  ],
  "offset": 0,
  "size": 1,
  "commits": [
    {
      "commit_time": 1567407452,
      "hash": "7bc4074ff3887845d8a558a078ed878ab821cde9",
      "author": "Contributor A (contribA@getMail.com)"
    },
    {
      "commit_time": 1567412246,
      "hash": "43e7c5590092d9c173d032618175f991976f9e09",
      "author": "Contributor B (contribB@getMail.com)"
    },
    {
      "commit_time": 1567412442,
      "hash": "2b7e59b9c0267d3f90ddd8b2cb10c1431c79137d",
      "author": "Contributor C (contribC@getMail.com)"
    },
  ],
  "issue": null
}

  ''';
}

String ignoreResponseTemplate({String pullRequestNumber = '0000'}) {
  return '''
    [
      {
        "id": "7579425228619212078",
        "name": "contributor@getMail.com",
        "updatedBy": "contributor@getMail.com",
        "expires": "2019-09-06T21:28:18.815336Z",
        "query": "ext=png&name=widgets.golden_file_test",
        "note": "https://github.com/flutter/flutter/pull/$pullRequestNumber"
      }
    ]
  ''';
}

Stream<List<int>> imageResponseTemplate() {
  return Stream<List<int>>.fromIterable(<List<int>>[
    <int>[137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0,
      1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 11, 73, 68, 65],
    <int>[84, 120, 1, 99, 97, 0, 2, 0, 0, 25, 0, 5, 144, 240, 54, 245, 0, 0, 0,
      0, 73, 69, 78, 68, 174, 66, 96, 130],
  ]);
}