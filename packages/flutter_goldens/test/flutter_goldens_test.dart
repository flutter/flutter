// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_goldens/flutter_goldens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

const String _kFlutterRoot = '/flutter';
const String _kGoldensVersion = '123456abcdef';

// 1x1 transparent pixel
//const List<int> _kTestPngBytes =
//<int>[137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0,
//  1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 11, 73, 68, 65, 84,
//  120, 1, 99, 97, 0, 2, 0, 0, 25, 0, 5, 144, 240, 54, 245, 0, 0, 0, 0, 73, 69,
//  78, 68, 174, 66, 96, 130];

void main() {
  MemoryFileSystem fs;
  FakePlatform platform;
  MockProcessManager process;
  MockHttpClient mockHttpClient;

  setUp(() {
    fs = MemoryFileSystem();
    platform = FakePlatform(
      environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot},
      operatingSystem: 'macos'
    );
    process = MockProcessManager();
    mockHttpClient = MockHttpClient();
    fs.directory(_kFlutterRoot).createSync(recursive: true);
  });

  group('SkiaGoldClient', () {
    SkiaGoldClient skiaClient;

    setUp(() {
      final Directory workDirectory = fs.directory('/workDirectory')
        ..createSync(recursive: true);
      skiaClient = SkiaGoldClient(
        workDirectory,
        fs: fs,
        process: process,
        platform: platform,
        httpClient: mockHttpClient,
      );
    });

    group('auth', () {
      test('performs minimal work if already authorized', () async {
        fs.file('/workDirectory/temp/auth_opt.json')
          ..createSync(recursive: true);
        when(process.run(any))
          .thenAnswer((_) => Future<ProcessResult>
            .value(ProcessResult(123, 0, '', '')));
        await skiaClient.auth();

        verifyNever(process.run(
            captureAny,
            workingDirectory: captureAnyNamed('workingDirectory'),
        ));
      });
    });

    group('Request Handling', () {
      test('throws for triage breakdown when digests > 1', () async {
        const String testName = 'flutter.golden_test.1.png';
        final Uri url = Uri.parse(
          'https://flutter-gold.skia.org/json/search?source_type%3Dflutter'
            '&head=true&include=true&pos=true&neg=false&unt=false'
            '&query=Platform%3Dmacos%26name%3Dflutter.golden_test.1%26'
        );

        final MockHttpClientRequest mockHttpRequest = MockHttpClientRequest();
        final MockHttpClientResponse mockHttpResponse = MockHttpClientResponse(
          utf8.encode(digestResponseTemplate(includeExtraDigests: true))
        );
        when(mockHttpClient.getUrl(url))
          .thenAnswer((_) => Future<MockHttpClientRequest>.value(mockHttpRequest));
        when(mockHttpRequest.close())
          .thenAnswer((_) => Future<MockHttpClientResponse>.value(mockHttpResponse));

        try {
          await skiaClient.getMasterBytes(testName);
          fail('TestFailure expected but not thrown.');
        } catch (error) {
          expect(error.stderr, contains('There is more than one digest available'));
        }
      });

      test('returns signal bytes for new tests without a baseline', () async {
//        const String testName = 'flutter.golden_test.1.png';
//        final Uri url = Uri.parse(
//          'https://flutter-gold.skia.org/json/search?source_type%3Dflutter'
//            '&head=true&include=true&pos=true&neg=false&unt=false'
//            '&query=Platform%3Dmacos%26name%3Dflutter.golden_test.1%26'
//        );
//
//        final MockHttpClientRequest mockHttpRequest = MockHttpClientRequest();
//        final MockHttpClientResponse mockHttpResponse = MockHttpClientResponse(
//          utf8.encode(digestResponseTemplate(returnEmptyDigest: true))
//        );
//        when(mockHttpClient.getUrl(url))
//          .thenAnswer((_) => Future<MockHttpClientRequest>.value(mockHttpRequest));
//        when(mockHttpRequest.close())
//          .thenAnswer((_) => Future<MockHttpClientResponse>.value(mockHttpResponse));
//
//        final List<int> imageBytes = await skiaClient.getMasterBytes(testName);
//        expect(imageBytes, <int>[0]);
      });

      test('validates SkiaDigest', () {

      });

      test('throws for invalid SkiaDigest', () {

      });

      test('image bytes are decoded properly', () {

      });
    });
  });

  group('FlutterGoldenFileComparator', () {
    FlutterSkiaGoldFileComparator comparator;

    setUp(() {
      comparator = FlutterSkiaGoldFileComparator(
        Uri.parse('flutter/test'),
        MockSkiaGoldClient(),
        fs: fs,
        platform: platform,
      );
    });

    test('calculates the basedir correctly', () async {
      final MockLocalFileComparator defaultComparator = MockLocalFileComparator();
      final Directory flutterRoot = fs.directory(platform.environment['FLUTTER_ROOT'])
        ..createSync(recursive: true);
      when(defaultComparator.basedir).thenReturn(flutterRoot.childDirectory('baz').uri);
      final Directory basedir = FlutterGoldenFileComparator.getBaseDirectory(defaultComparator, platform);
      expect(basedir.uri, fs.directory('/flutter/bin/cache/pkg/skia_goldens/baz').uri);
    });

    test('ignores version number', () {
      final Uri key = comparator.getTestUri(Uri.parse('foo.png'), 1);
      expect(key, Uri.parse('foo.png'));
    });

    test('prefixes golden file names with associated libraries', () {

    });

    group('FlutterSkiaGoldFileComparator', () {
      test('correctly determines testing environment', () {

      });

      test('throws for non-existent golden file', () async {
//        try {
//          await comparator.compare(Uint8List.fromList(<int>[1, 2, 3]), Uri.parse('test.png'));
//          fail('TestFailure expected but not thrown');
//        } on TestFailure catch (error) {
//          expect(error.message, contains('Could not be compared against non-existent file'));
//        }
      });
    });

    group('FlutterPreSubmitFileComparator', () {
      test('correctly determines testing environment', () {

      });

      test('passes test that is ignored for this PR', () {

      });

      test('fails test that is not ignored for this PR', () {

      });

      test('fails test that is ignored, but not for given PR', () {

      });

      test('passes non-existent baseline for new test', () {

      });
    });

    group('FlutterLocalFileComparator', () {
      test('correctly determines testing environment', () {

      });

      test('passes non-existent baseline for new test', () {

      });
    });
  });
}


class MockProcessManager extends Mock implements ProcessManager {}

class MockSkiaGoldClient extends Mock implements SkiaGoldClient {}

class MockLocalFileComparator extends Mock implements LocalFileComparator {}

class MockHttpClient extends Mock implements HttpClient {}

class MockHttpClientRequest extends Mock implements HttpClientRequest {}

class MockHttpClientResponse extends Mock implements HttpClientResponse {
  MockHttpClientResponse(this.response);

  final Uint8List response;

  @override
  StreamSubscription<Uint8List> listen(
    void onData(Uint8List event), {
      Function onError,
      void onDone(),
      bool cancelOnError,
    }) {
    return Stream<Uint8List>.fromFuture(Future<Uint8List>.value(response))
      .listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

String digestResponseTemplate({
  bool includeExtraDigests = false,
  bool returnEmptyDigest = false,
}) {
  return '''
  {
  "digests": [${returnEmptyDigest ? '' : '''
    {
      "test": "cupertino.text_field_cursor_test.cupertino.1",
      "digest": "88e2cc3398bd55b55df35cfe14d557c1",
      "status": "positive",
      "paramset": {
        "Platform": [
          "macos"
        ],
        "ext": [
          "png"
        ],
        "name": [
          "cupertino.text_field_cursor_test.cupertino.1"
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
                "s": 0
              },
              {
                "x": 1,
                "y": 0,
                "s": 0
              },
              {
                "x": 2,
                "y": 0,
                "s": 0
              },
              {
                "x": 3,
                "y": 0,
                "s": 0
              }
            ],
            "label": ",Platform=macos,name=cupertino.text_field_cursor_test.cupertino.1,source_type=flutter,",
            "params": {
              "Platform": "macos",
              "ext": "png",
              "name": "cupertino.text_field_cursor_test.cupertino.1",
              "source_type": "flutter"
            }
          }
        ],
        "digests": [
          {
            "digest": "88e2cc3398bd55b55df35cfe14d557c1",
            "status": "positive"
          }
        ]
      },
      "closestRef": "pos",
      "refDiffs": {
        "neg": null,
        "pos": {
          "numDiffPixels": 541,
          "pixelDiffPercent": 4.663793,
          "maxRGBADiffs": [
            0,
            128,
            255,
            112
          ],
          "dimDiffer": false,
          "diffs": {
            "combined": 1.6742188,
            "percent": 4.663793,
            "pixel": 541
          },
          "digest": "e4ac039c7b3112d7dada8e7c0a4e0501",
          "status": "positive",
          "paramset": {
            "Platform": [
              "windows"
            ],
            "ext": [
              "png"
            ],
            "name": [
              "cupertino.text_field_cursor_test.cupertino.1"
            ],
            "source_type": [
              "flutter"
            ]
          },
          "n": 191
        }
      }
    }${includeExtraDigests ? ''',
    {
      "test": "cupertino.text_field_cursor_test.cupertino.1",
      "digest": "88e2cc3398bd55b55df35cfe14d557c1",
      "status": "positive",
      "paramset": {
        "Platform": [
          "macos"
        ],
        "ext": [
          "png"
        ],
        "name": [
          "cupertino.text_field_cursor_test.cupertino.1"
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
                "s": 0
              }
            ],
            "label": ",Platform=macos,name=cupertino.text_field_cursor_test.cupertino.1,source_type=flutter,",
            "params": {
              "Platform": "macos",
              "ext": "png",
              "name": "cupertino.text_field_cursor_test.cupertino.1",
              "source_type": "flutter"
            }
          }
        ],
        "digests": [
          {
            "digest": "88e2cc3398bd55b55df35cfe14d557c1",
            "status": "positive"
          }
        ]
      },
      "closestRef": "pos",
      "refDiffs": {
        "neg": null,
        "pos": {
          "numDiffPixels": 541,
          "pixelDiffPercent": 4.663793,
          "maxRGBADiffs": [
            0,
            128,
            255,
            112
          ],
          "dimDiffer": false,
          "diffs": {
            "combined": 1.6742188,
            "percent": 4.663793,
            "pixel": 541
          },
          "digest": "e4ac039c7b3112d7dada8e7c0a4e0501",
          "status": "positive",
          "paramset": {
            "Platform": [
              "windows"
            ],
            "ext": [
              "png"
            ],
            "name": [
              "cupertino.text_field_cursor_test.cupertino.1"
            ],
            "source_type": [
              "flutter"
            ]
          },
          "n": 191
        }
      }
    }
    ''' : ''} '''}
  ],
  "offset": 0,
  "size": 1,
  "commits": [
    {
      "commit_time": 1567412442,
      "hash": "2b7e59b9c0267d3f90ddd8b2cb10c1431c79137d",
      "author": "engine-flutter-autoroll (engine-flutter-autoroll@skia.org)"
    },
    {
      "commit_time": 1567418861,
      "hash": "ec1ea2b38ab1773f2c412e303a8cda0792a980ca",
      "author": "engine-flutter-autoroll (engine-flutter-autoroll@skia.org)"
    },
    {
      "commit_time": 1567434521,
      "hash": "d30e4228afd633e4f6d2ed217a926e8983161379",
      "author": "engine-flutter-autoroll (engine-flutter-autoroll@skia.org)"
    }
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