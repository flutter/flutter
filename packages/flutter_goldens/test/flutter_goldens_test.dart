// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_goldens/flutter_goldens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import 'json_templates.dart';

const String _kFlutterRoot = '/flutter';

// 1x1 transparent pixel
const List<int> _kTestPngBytes =
<int>[137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0,
  1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 11, 73, 68, 65, 84,
  120, 1, 99, 97, 0, 2, 0, 0, 25, 0, 5, 144, 240, 54, 245, 0, 0, 0, 0, 73, 69,
  78, 68, 174, 66, 96, 130];

// 1x1 colored pixel
const List<int> _kFailPngBytes =
<int>[137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0,
  1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84,
  120, 1, 99, 249, 207, 240, 255, 63, 0, 7, 18, 3, 2, 164, 147, 160, 197, 0,
  0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130];

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
      String testName;
      String pullRequestNumber;
      String expectation;
      Uri url;
      MockHttpClientRequest mockHttpRequest;

      setUp(() {
        testName = 'flutter.golden_test.1.png';
        pullRequestNumber = '1234';
        expectation = '55109a4bed52acc780530f7a9aeff6c0';
        mockHttpRequest = MockHttpClientRequest();
      });

      test('validates SkiaDigest', () {
        final Map<String, dynamic> skiaJson = json.decode(digestResponseTemplate()) as Map<String, dynamic>;
        final SkiaGoldDigest digest = SkiaGoldDigest.fromJson(skiaJson['digest'] as Map<String, dynamic>);
        expect(
          digest.isValid(
            platform,
            'flutter.golden_test.1',
            expectation,
          ),
          isTrue,
        );
      });

      test('invalidates bad SkiaDigest - platform', () {
        final Map<String, dynamic> skiaJson = json.decode(
          digestResponseTemplate(platform: 'linux'),
        ) as Map<String, dynamic>;
        final SkiaGoldDigest digest = SkiaGoldDigest.fromJson(skiaJson['digest'] as Map<String, dynamic>);
        expect(
          digest.isValid(
            platform,
            'flutter.golden_test.1',
            expectation,
          ),
          isFalse,
        );
      });

      test('invalidates bad SkiaDigest - test name', () {
        final Map<String, dynamic> skiaJson = json.decode(
          digestResponseTemplate(testName: 'flutter.golden_test.2'),
        ) as Map<String, dynamic>;
        final SkiaGoldDigest digest = SkiaGoldDigest.fromJson(skiaJson['digest'] as Map<String, dynamic>);
        expect(
          digest.isValid(
            platform,
            'flutter.golden_test.1',
            expectation,
          ),
          isFalse,
        );
      });

      test('invalidates bad SkiaDigest - expectation', () {
        final Map<String, dynamic> skiaJson = json.decode(
          digestResponseTemplate(expectation: '1deg543sf645erg44awqcc78'),
        ) as Map<String, dynamic>;
        final SkiaGoldDigest digest = SkiaGoldDigest.fromJson(skiaJson['digest'] as Map<String, dynamic>);
        expect(
          digest.isValid(
            platform,
            'flutter.golden_test.1',
            expectation,
          ),
          isFalse,
        );
      });

      test('invalidates bad SkiaDigest - status', () {
        final Map<String, dynamic> skiaJson = json.decode(
          digestResponseTemplate(status: 'negative'),
        ) as Map<String, dynamic>;
        final SkiaGoldDigest digest = SkiaGoldDigest.fromJson(skiaJson['digest'] as Map<String, dynamic>);
        expect(
          digest.isValid(
            platform,
            'flutter.golden_test.1',
            expectation,
          ),
          isFalse,
        );
      });

      test('sets up expectations', () async {
        url = Uri.parse('https://flutter-gold.skia.org/json/expectations/commit/HEAD');
        final MockHttpClientResponse mockHttpResponse = MockHttpClientResponse(
          utf8.encode(rawExpectationsTemplate())
        );
        when(mockHttpClient.getUrl(url))
          .thenAnswer((_) => Future<MockHttpClientRequest>.value(mockHttpRequest));
        when(mockHttpRequest.close())
          .thenAnswer((_) => Future<MockHttpClientResponse>.value(mockHttpResponse));

        await skiaClient.getExpectations();
        expect(skiaClient.expectations, isNotNull);
        expect(
          skiaClient.expectations['flutter.golden_test.1'],
          contains(expectation),
        );
      });

      test('detects invalid digests SkiaDigest', () {
        const String testName = 'flutter.golden_test.2';
        final Map<String, dynamic> skiaJson = json.decode(digestResponseTemplate()) as Map<String, dynamic>;
        final SkiaGoldDigest digest = SkiaGoldDigest.fromJson(skiaJson['digest'] as Map<String, dynamic>);
        expect(digest.isValid(platform, testName, expectation), isFalse);
      });

      test('image bytes are processed properly', () async {
        final Uri imageUrl = Uri.parse(
          'https://flutter-gold.skia.org/img/images/$expectation.png'
        );
        final MockHttpClientRequest mockImageRequest = MockHttpClientRequest();
        final MockHttpImageResponse mockImageResponse = MockHttpImageResponse(
          imageResponseTemplate()
        );
        when(mockHttpClient.getUrl(imageUrl))
          .thenAnswer((_) => Future<MockHttpClientRequest>.value(mockImageRequest));
        when(mockImageRequest.close())
          .thenAnswer((_) => Future<MockHttpImageResponse>.value(mockImageResponse));

        final List<int> masterBytes = await skiaClient.getImageBytes(expectation);

        expect(masterBytes, equals(_kTestPngBytes));
      });

      group('ignores', () {
        Uri url;
        MockHttpClientRequest mockHttpRequest;
        MockHttpClientResponse mockHttpResponse;

        setUp(() {
          url = Uri.parse('https://flutter-gold.skia.org/json/ignores');
          mockHttpRequest = MockHttpClientRequest();
          mockHttpResponse = MockHttpClientResponse(utf8.encode(
              ignoreResponseTemplate(
                pullRequestNumber: pullRequestNumber,
                expires: DateTime.now()
                  .add(const Duration(days: 1))
                  .toString(),
                otherTestName: 'unrelatedTest.1'
              )
          ));
          when(mockHttpClient.getUrl(url))
            .thenAnswer((_) => Future<MockHttpClientRequest>.value(mockHttpRequest));
          when(mockHttpRequest.close())
            .thenAnswer((_) => Future<MockHttpClientResponse>.value(mockHttpResponse));
        });

        test('returns true for ignored test and ignored pull request number', () async {
          expect(
            await skiaClient.testIsIgnoredForPullRequest(
              pullRequestNumber,
              testName,
            ),
            isTrue,
          );
        });

        test('returns true for ignored test and not ignored pull request number', () async {
          expect(
            await skiaClient.testIsIgnoredForPullRequest(
              '5678',
              testName,
            ),
            isTrue,
          );
        });

        test('returns false for not ignored test and ignored pull request number', () async {
         expect(
            await skiaClient.testIsIgnoredForPullRequest(
              pullRequestNumber,
              'failure.png',
            ),
            isFalse,
          );
        });

        test('throws exception for expired ignore', () async {
          mockHttpResponse = MockHttpClientResponse(utf8.encode(
            ignoreResponseTemplate(
              pullRequestNumber: pullRequestNumber,
            )
          ));
          when(mockHttpRequest.close())
            .thenAnswer((_) => Future<MockHttpClientResponse>.value(mockHttpResponse));
          final Future<bool> test = skiaClient.testIsIgnoredForPullRequest(
            pullRequestNumber,
            testName,
          );
          expect(
            test,
            throwsException,
          );
        });

        test('throws exception for first expired ignore among multiple', () async {
          mockHttpResponse = MockHttpClientResponse(utf8.encode(
            ignoreResponseTemplate(
              pullRequestNumber: pullRequestNumber,
              otherExpires: DateTime.now()
                .add(const Duration(days: 1))
                .toString(),
            )
          ));
          when(mockHttpRequest.close())
            .thenAnswer((_) => Future<MockHttpClientResponse>.value(mockHttpResponse));
          final Future<bool> test = skiaClient.testIsIgnoredForPullRequest(
            pullRequestNumber,
            testName,
          );
          expect(
            test,
            throwsException,
          );
        });

        test('throws exception for later expired ignore among multiple', () async {
          mockHttpResponse = MockHttpClientResponse(utf8.encode(
            ignoreResponseTemplate(
              pullRequestNumber: pullRequestNumber,
              expires: DateTime.now()
                .add(const Duration(days: 1))
                .toString(),
            )
          ));
          when(mockHttpRequest.close())
            .thenAnswer((_) => Future<MockHttpClientResponse>.value(mockHttpResponse));
          final Future<bool> test = skiaClient.testIsIgnoredForPullRequest(
            pullRequestNumber,
            testName,
          );
          expect(
            test,
            throwsException,
          );
        });
      });

      group('digest parsing', () {
        Uri url;
        MockHttpClientRequest mockHttpRequest;
        MockHttpClientResponse mockHttpResponse;

        setUp(() {
          url = Uri.parse(
            'https://flutter-gold.skia.org/json/details?'
              'test=flutter.golden_test.1&digest=$expectation'
          );
          mockHttpRequest = MockHttpClientRequest();
          when(mockHttpClient.getUrl(url))
            .thenAnswer((_) => Future<MockHttpClientRequest>.value(mockHttpRequest));
        });

        test('succeeds when valid', () async {
          mockHttpResponse = MockHttpClientResponse(utf8.encode(digestResponseTemplate()));
          when(mockHttpRequest.close())
            .thenAnswer((_) => Future<MockHttpClientResponse>.value(mockHttpResponse));
          expect(
            await skiaClient.isValidDigestForExpectation(
              expectation,
              testName,
            ),
            isTrue,
          );
        });

        test('fails when invalid', () async {
          mockHttpResponse = MockHttpClientResponse(utf8.encode(
            digestResponseTemplate(platform: 'linux')
          ));
          when(mockHttpRequest.close())
            .thenAnswer((_) => Future<MockHttpClientResponse>.value(mockHttpResponse));
          expect(
            await skiaClient.isValidDigestForExpectation(
              expectation,
              testName,
            ),
            isFalse,
          );
        });
      });
    });
  });

  group('FlutterGoldenFileComparator', () {
    FlutterSkiaGoldFileComparator comparator;

    setUp(() {
      final Directory basedir = fs.directory('flutter/test/library/')
        ..createSync(recursive: true);
      comparator = FlutterSkiaGoldFileComparator(
        basedir.uri,
        MockSkiaGoldClient(),
        fs: fs,
        platform: platform,
      );
    });

    test('calculates the basedir correctly from defaultComparator', () async {
      final MockLocalFileComparator defaultComparator = MockLocalFileComparator();
      final Directory flutterRoot = fs.directory(platform.environment['FLUTTER_ROOT'])
        ..createSync(recursive: true);
      when(defaultComparator.basedir).thenReturn(flutterRoot.childDirectory('baz').uri);

      final Directory basedir = FlutterGoldenFileComparator.getBaseDirectory(
        defaultComparator,
        platform,
      );
      expect(
        basedir.uri,
        fs.directory('/flutter/bin/cache/pkg/skia_goldens/baz').uri,
      );
    });

    test('ignores version number', () {
      final Uri key = comparator.getTestUri(Uri.parse('foo.png'), 1);
      expect(key, Uri.parse('foo.png'));
    });

    group('Post-Submit', () {
      final MockSkiaGoldClient mockSkiaClient = MockSkiaGoldClient();

      setUp(() {
        final Directory basedir = fs.directory('flutter/test/library/')
          ..createSync(recursive: true);
        comparator = FlutterSkiaGoldFileComparator(
          basedir.uri,
          mockSkiaClient,
          fs: fs,
          platform: platform,
        );
      });

      group('correctly determines testing environment', () {
        test('returns true', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'CIRRUS_CI': 'true',
              'CIRRUS_PR': '',
              'CIRRUS_BRANCH': 'master',
              'GOLD_SERVICE_ACCOUNT': 'service account...',
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterSkiaGoldFileComparator.isAvailableForEnvironment(platform),
            isTrue,
          );
        });

        test('returns false - PR active', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'CIRRUS_CI': 'true',
              'CIRRUS_PR': '1234',
              'CIRRUS_BRANCH': 'master',
              'GOLD_SERVICE_ACCOUNT': 'service account...',
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterSkiaGoldFileComparator.isAvailableForEnvironment(platform),
            isFalse,
          );
        });

        test('returns false - no service account', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'CIRRUS_CI': 'true',
              'CIRRUS_PR': '',
              'CIRRUS_BRANCH': 'master',
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterSkiaGoldFileComparator.isAvailableForEnvironment(platform),
            isFalse,
          );
        });

        test('returns false - not on cirrus', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'SWARMING_ID' : '1234567890',
              'GOLD_SERVICE_ACCOUNT': 'service account...'
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterSkiaGoldFileComparator.isAvailableForEnvironment(platform),
            isFalse,
          );
        });

        test('returns false - not on master', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'CIRRUS_CI': 'true',
              'CIRRUS_PR': '',
              'CIRRUS_BRANCH': 'hotfix',
              'GOLD_SERVICE_ACCOUNT': 'service account...'
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterSkiaGoldFileComparator.isAvailableForEnvironment(platform),
            isFalse,
          );
        });
      });
    });

    group('Pre-Submit', () {
      FlutterPreSubmitFileComparator comparator;
      final MockSkiaGoldClient mockSkiaClient = MockSkiaGoldClient();

      setUp(() {
        final Directory basedir = fs.directory('flutter/test/library/')
          ..createSync(recursive: true);
        comparator = FlutterPreSubmitFileComparator(
          basedir.uri,
          mockSkiaClient,
          fs: fs,
          platform: FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'CIRRUS_CI' : 'true',
              'CIRRUS_PR' : '1234',
              'GOLD_SERVICE_ACCOUNT' : 'service account...'
            },
            operatingSystem: 'macos'
          ),
        );

        when(mockSkiaClient.getImageBytes('55109a4bed52acc780530f7a9aeff6c0'))
          .thenAnswer((_) => Future<List<int>>.value(_kTestPngBytes));
        when(mockSkiaClient.expectations)
          .thenReturn(expectationsTemplate());
        when(mockSkiaClient.cleanTestName('library.flutter.golden_test.1.png'))
          .thenReturn('flutter.golden_test.1');
        when(mockSkiaClient.isValidDigestForExpectation(
          '55109a4bed52acc780530f7a9aeff6c0',
          'library.flutter.golden_test.1.png',
        ))
          .thenAnswer((_) => Future<bool>.value(false));
      });
      group('correctly determines testing environment', () {
        test('returns true', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'CIRRUS_CI': 'true',
              'CIRRUS_PR': '1234',
              'GOLD_SERVICE_ACCOUNT' : 'service account...',
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterPreSubmitFileComparator.isAvailableForEnvironment(platform),
            isTrue,
          );
        });

        test('returns false - no PR', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'CIRRUS_CI': 'true',
              'CIRRUS_PR': '',
              'GOLD_SERVICE_ACCOUNT' : 'service account...',
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterPreSubmitFileComparator.isAvailableForEnvironment(platform),
            isFalse,
          );
        });

        test('returns false - no service account', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'CIRRUS_CI': 'true',
              'CIRRUS_PR': '1234',
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterPreSubmitFileComparator.isAvailableForEnvironment(platform),
            isFalse,
          );
        });

        test('returns false - not on Cirrus', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterPreSubmitFileComparator.isAvailableForEnvironment(platform),
            isFalse,
          );
        });
      });

      test('comparison passes test that is ignored for this PR', () async {
        when(mockSkiaClient.getImageBytes('55109a4bed52acc780530f7a9aeff6c0'))
          .thenAnswer((_) => Future<List<int>>.value(_kTestPngBytes));
        when(mockSkiaClient.testIsIgnoredForPullRequest(
          '1234',
          'library.flutter.golden_test.1.png',
        ))
          .thenAnswer((_) => Future<bool>.value(true));
        expect(
          await comparator.compare(
            Uint8List.fromList(_kFailPngBytes),
            Uri.parse('flutter.golden_test.1.png'),
          ),
          isTrue,
        );
      });

      test('fails test that is not ignored', () async {
        when(mockSkiaClient.getImageBytes('55109a4bed52acc780530f7a9aeff6c0'))
          .thenAnswer((_) => Future<List<int>>.value(_kTestPngBytes));
        when(mockSkiaClient.testIsIgnoredForPullRequest(
          '1234',
          'library.flutter.golden_test.1.png',
        ))
          .thenAnswer((_) => Future<bool>.value(false));
        expect(
          await comparator.compare(
            Uint8List.fromList(_kFailPngBytes),
            Uri.parse('flutter.golden_test.1.png'),
          ),
          isFalse,
        );
      });

      test('passes non-existent baseline for new test', () async {
        expect(
          await comparator.compare(
            Uint8List.fromList(_kFailPngBytes),
            Uri.parse('flutter.new_golden_test.1.png'),
          ),
          isTrue,
        );
      });
    });

    group('Skipping', () {
      group('correctly determines testing environment', () {
        test('returns true on LUCI', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'SWARMING_TASK_ID' : '1234567890',
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterSkippingGoldenFileComparator.isAvailableForEnvironment(platform),
            isTrue,
          );
        });

        test('returns true on Cirrus', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'CIRRUS_CI' : 'yep',
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterSkippingGoldenFileComparator.isAvailableForEnvironment(platform),
            isTrue,
          );
        });
        test('returns false', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterSkippingGoldenFileComparator.isAvailableForEnvironment(
              platform),
            isFalse,
          );
        });
      });
    });

    group('Local', () {
      FlutterLocalFileComparator comparator;
      final MockSkiaGoldClient mockSkiaClient = MockSkiaGoldClient();

      setUp(() async {
        final Directory basedir = fs.directory('flutter/test/library/')
          ..createSync(recursive: true);
        comparator = FlutterLocalFileComparator(
          basedir.uri,
          mockSkiaClient,
          fs: fs,
          platform: FakePlatform(
            environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot},
            operatingSystem: 'macos'
          ),
        );

        when(mockSkiaClient.getImageBytes('55109a4bed52acc780530f7a9aeff6c0'))
          .thenAnswer((_) => Future<List<int>>.value(_kTestPngBytes));
        when(mockSkiaClient.expectations)
          .thenReturn(expectationsTemplate());
        when(mockSkiaClient.cleanTestName('library.flutter.golden_test.1.png'))
          .thenReturn('flutter.golden_test.1');
        when(mockSkiaClient.isValidDigestForExpectation(
          '55109a4bed52acc780530f7a9aeff6c0',
          'library.flutter.golden_test.1.png',
        ))
          .thenAnswer((_) => Future<bool>.value(false));
      });

      test('passes when bytes match', () async {
        expect(
          await comparator.compare(
            Uint8List.fromList(_kTestPngBytes),
            Uri.parse('flutter.golden_test.1.png'),
          ),
          isTrue,
        );
      });

      test('passes non-existent baseline for new test', () async {
        expect(
          await comparator.compare(
            Uint8List.fromList(_kFailPngBytes),
            Uri.parse('flutter.new_golden_test.1'),
          ),
          isTrue,
        );
      });

      test('compare properly awaits validation & output before failing.', () async {
        final Completer<bool> completer = Completer<bool>();
        when(mockSkiaClient.isValidDigestForExpectation(
          '55109a4bed52acc780530f7a9aeff6c0',
          'library.flutter.golden_test.1.png',
        ))
          .thenAnswer((_) => completer.future);
        final Future<bool> result = comparator.compare(
          Uint8List.fromList(_kFailPngBytes),
          Uri.parse('flutter.golden_test.1.png'),
        );
        bool shouldThrow = true;
        result.then((_) {
          if (shouldThrow)
            fail('Compare completed before validation completed!');
        });
        await Future<void>.value();
        shouldThrow = false;
        completer.complete(Future<bool>.value(false));
      });

      test('returns FlutterSkippingGoldenFileComparator when network connection is unavailable', () async {
        final MockDirectory mockDirectory = MockDirectory();
        when(mockDirectory.existsSync()).thenReturn(true);
        when(mockDirectory.uri).thenReturn(Uri.parse('/flutter'));
        when(mockSkiaClient.getExpectations())
          .thenAnswer((_) => throw const OSError());
        final FlutterGoldenFileComparator comparator = await FlutterLocalFileComparator.fromDefaultComparator(
          platform,
          goldens: mockSkiaClient,
          baseDirectory: mockDirectory,
        );
        expect(comparator.runtimeType, FlutterSkippingGoldenFileComparator);
      });
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}

class MockSkiaGoldClient extends Mock implements SkiaGoldClient {}

class MockLocalFileComparator extends Mock implements LocalFileComparator {}

class MockDirectory extends Mock implements Directory {}

class MockHttpClient extends Mock implements HttpClient {}

class MockHttpClientRequest extends Mock implements HttpClientRequest {}

class MockHttpClientResponse extends Mock implements HttpClientResponse {
  MockHttpClientResponse(this.response);

  final List<int> response;

  @override
  StreamSubscription<List<int>> listen(
    void onData(List<int> event), {
      Function onError,
      void onDone(),
      bool cancelOnError,
    }) {
    return Stream<List<int>>.fromFuture(Future<List<int>>.value(response))
      .listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

class MockHttpImageResponse extends Mock implements HttpClientResponse {
  MockHttpImageResponse(this.response);

  final List<List<int>> response;

  @override
  Future<void> forEach(void action(List<int> element)) async {
    response.forEach(action);
  }
}
