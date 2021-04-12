// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io' hide Directory;
import 'dart:typed_data';
import 'dart:ui' show hashValues, hashList;

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_goldens/flutter_goldens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
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

Future<void> testWithOutput(String name, Future<void> Function() body, String expectedOutput) async {
  test(name, () async {
    final StringBuffer output = StringBuffer();
    void _recordPrint(Zone self, ZoneDelegate parent, Zone zone, String line) {
      output.write(line);
    }
    await runZoned<Future<void>>(body, zoneSpecification: ZoneSpecification(print: _recordPrint));
    expect(output.toString(), expectedOutput);
  });
}

void main() {
  late MemoryFileSystem fs;
  late FakePlatform platform;
  late FakeProcessManager process;
  late FakeHttpClient fakeHttpClient;

  setUp(() {
    fs = MemoryFileSystem();
    platform = FakePlatform(
      environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot},
      operatingSystem: 'macos'
    );
    process = FakeProcessManager();
    fakeHttpClient = FakeHttpClient();
    fs.directory(_kFlutterRoot).createSync(recursive: true);
  });

  group('SkiaGoldClient', () {
    late SkiaGoldClient skiaClient;
    late Directory workDirectory;

    setUp(() {
      workDirectory = fs.directory('/workDirectory')
        ..createSync(recursive: true);
      skiaClient = SkiaGoldClient(
        workDirectory,
        fs: fs,
        process: process,
        platform: platform,
        httpClient: fakeHttpClient,
      );
    });

    test('auth performs minimal work if already authorized', () async {
      final File authFile = fs.file('/workDirectory/temp/auth_opt.json')
        ..createSync(recursive: true);
      authFile.writeAsStringSync(authTemplate());
      process.fallbackProcessResult = ProcessResult(123, 0, '', '');
      await skiaClient.auth();

      expect(process.workingDirectories, isEmpty);
    });

    test('gsutil is checked when authorization file is present', () async {
      final File authFile = fs.file('/workDirectory/temp/auth_opt.json')
        ..createSync(recursive: true);
      authFile.writeAsStringSync(authTemplate(gsutil: true));
      expect(
        await skiaClient.clientIsAuthorized(),
        isFalse,
      );
    });

    test('throws for error state from auth', () async {
      platform = FakePlatform(
        environment: <String, String>{
          'FLUTTER_ROOT': _kFlutterRoot,
          'GOLD_SERVICE_ACCOUNT' : 'Service Account',
          'GOLDCTL' : 'goldctl',
        },
        operatingSystem: 'macos'
      );

      skiaClient = SkiaGoldClient(
        workDirectory,
        fs: fs,
        process: process,
        platform: platform,
        httpClient: fakeHttpClient,
      );

      process.fallbackProcessResult = ProcessResult(123, 1, 'fail', 'fail');

      expect(
        skiaClient.auth(),
        throwsException,
      );
    });

    test('throws for error state from init', () {
      platform = FakePlatform(
        environment: <String, String>{
          'FLUTTER_ROOT': _kFlutterRoot,
          'GOLDCTL' : 'goldctl',
        },
        operatingSystem: 'macos'
      );

      skiaClient = SkiaGoldClient(
        workDirectory,
        fs: fs,
        process: process,
        platform: platform,
        httpClient: fakeHttpClient,
      );

      process.fallbackProcessResult = ProcessResult(123, 1, 'fail', 'fail');

      const RunInvocation gitInvocation = RunInvocation(
        <String>['git', 'rev-parse', 'HEAD'],
        '/flutter',
      );
      const RunInvocation goldctlInvocation = RunInvocation(
        <String>[
          'goldctl',
          'imgtest', 'init',
          '--instance', 'flutter',
          '--work-dir', '/workDirectory/temp',
          '--commit', '12345678',
          '--keys-file', '/workDirectory/keys.json',
          '--failure-file', '/workDirectory/failures.json',
          '--passfail',
        ],
        null,
      );
      process.processResults[gitInvocation] = ProcessResult(12345678, 0, '12345678', '');
      process.processResults[goldctlInvocation] = ProcessResult(123, 1, 'fail', 'fail');

      expect(
        skiaClient.imgtestInit(),
        throwsException,
      );
    });

    test('correctly inits tryjob for luci', () async {
      platform = FakePlatform(
        environment: <String, String>{
          'FLUTTER_ROOT': _kFlutterRoot,
          'GOLDCTL' : 'goldctl',
          'SWARMING_TASK_ID' : '4ae997b50dfd4d11',
          'LOGDOG_STREAM_PREFIX' : 'buildbucket/cr-buildbucket.appspot.com/8885996262141582672',
          'GOLD_TRYJOB' : 'refs/pull/49815/head',
        },
        operatingSystem: 'macos'
      );

      skiaClient = SkiaGoldClient(
        workDirectory,
        fs: fs,
        process: process,
        platform: platform,
        httpClient: fakeHttpClient,
      );

      final List<String> ciArguments = skiaClient.getCIArguments();

      expect(
        ciArguments,
        equals(
          <String>[
            '--changelist', '49815',
            '--cis', 'buildbucket',
            '--jobid', '8885996262141582672',
          ],
        ),
      );
    });

    test('Creates traceID correctly', () {
      String traceID;
      platform = FakePlatform(
        environment: <String, String>{
          'FLUTTER_ROOT': _kFlutterRoot,
          'GOLDCTL' : 'goldctl',
          'SWARMING_TASK_ID' : '4ae997b50dfd4d11',
          'LOGDOG_STREAM_PREFIX' : 'buildbucket/cr-buildbucket.appspot.com/8885996262141582672',
          'GOLD_TRYJOB' : 'refs/pull/49815/head',
        },
        operatingSystem: 'linux'
      );

      skiaClient = SkiaGoldClient(
        workDirectory,
        fs: fs,
        process: process,
        platform: platform,
        httpClient: fakeHttpClient,
      );

      traceID = skiaClient.getTraceID('flutter.golden.1');

      expect(
        traceID,
        equals(',CI=luci,Platform=linux,name=flutter.golden.1,source_type=flutter,'),
      );

      // Browser
      platform = FakePlatform(
        environment: <String, String>{
          'FLUTTER_ROOT': _kFlutterRoot,
          'GOLDCTL' : 'goldctl',
          'SWARMING_TASK_ID' : '4ae997b50dfd4d11',
          'LOGDOG_STREAM_PREFIX' : 'buildbucket/cr-buildbucket.appspot.com/8885996262141582672',
          'GOLD_TRYJOB' : 'refs/pull/49815/head',
          'FLUTTER_TEST_BROWSER' : 'chrome',
        },
        operatingSystem: 'linux'
      );

      skiaClient = SkiaGoldClient(
        workDirectory,
        fs: fs,
        process: process,
        platform: platform,
        httpClient: fakeHttpClient,
      );

      traceID = skiaClient.getTraceID('flutter.golden.1');

      expect(
        traceID,
        equals(',Browser=chrome,CI=luci,Platform=linux,name=flutter.golden.1,source_type=flutter,'),
      );

      // Locally - should defer to luci traceID
      platform = FakePlatform(
        environment: <String, String>{
          'FLUTTER_ROOT': _kFlutterRoot,
        },
        operatingSystem: 'macos'
      );

      skiaClient = SkiaGoldClient(
        workDirectory,
        fs: fs,
        process: process,
        platform: platform,
        httpClient: fakeHttpClient,
      );

      traceID = skiaClient.getTraceID('flutter.golden.1');

      expect(
        traceID,
        equals(',CI=luci,Platform=macos,name=flutter.golden.1,source_type=flutter,'),
      );
    });

    group('Request Handling', () {
      const String expectation = '55109a4bed52acc780530f7a9aeff6c0';

      test('image bytes are processed properly', () async {
        final Uri imageUrl = Uri.parse(
          'https://flutter-gold.skia.org/img/images/$expectation.png'
        );
        final FakeHttpClientRequest fakeImageRequest = FakeHttpClientRequest();
        final FakeHttpImageResponse fakeImageResponse = FakeHttpImageResponse(
          imageResponseTemplate()
        );

        fakeHttpClient.request = fakeImageRequest;
        fakeImageRequest.response = fakeImageResponse;

        final List<int> masterBytes = await skiaClient.getImageBytes(expectation);

        expect(fakeHttpClient.lastUri, imageUrl);
        expect(masterBytes, equals(_kTestPngBytes));
      });
    });
  });

  group('FlutterGoldenFileComparator', () {
    late FlutterPostSubmitFileComparator comparator;

    setUp(() {
      final Directory basedir = fs.directory('flutter/test/library/')
        ..createSync(recursive: true);
      comparator = FlutterPostSubmitFileComparator(
        basedir.uri,
        FakeSkiaGoldClient(),
        fs: fs,
        platform: platform,
      );
    });

    test('calculates the basedir correctly from defaultComparator for local testing', () async {
      final FakeLocalFileComparator defaultComparator = FakeLocalFileComparator();
      final Directory flutterRoot = fs.directory(platform.environment['FLUTTER_ROOT'])
        ..createSync(recursive: true);
      defaultComparator.basedir = flutterRoot.childDirectory('baz').uri;

      final Directory basedir = FlutterGoldenFileComparator.getBaseDirectory(
        defaultComparator,
        platform,
        local: true,
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
      final FakeSkiaGoldClient fakeSkiaClient = FakeSkiaGoldClient();

      setUp(() {
        final Directory basedir = fs.directory('flutter/test/library/')
          ..createSync(recursive: true);
        comparator = FlutterPostSubmitFileComparator(
          basedir.uri,
          fakeSkiaClient,
          fs: fs,
          platform: platform,
        );
      });

      group('correctly determines testing environment', () {
        test('returns true for configured Luci', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'SWARMING_TASK_ID' : '12345678990',
              'GOLDCTL' : 'goldctl',
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterPostSubmitFileComparator.isAvailableForEnvironment(platform),
            isTrue,
          );
        });

        test('returns false - GOLDCTL not present', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'SWARMING_TASK_ID' : '12345678990',
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterPostSubmitFileComparator.isAvailableForEnvironment(platform),
            isFalse,
          );
        });

        test('returns false - GOLD_TRYJOB active', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'SWARMING_TASK_ID' : '12345678990',
              'GOLDCTL' : 'goldctl',
              'GOLD_TRYJOB' : 'git/ref/12345/head'
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterPostSubmitFileComparator.isAvailableForEnvironment(platform),
            isFalse,
          );
        });

        test('returns false - on Cirrus', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'CIRRUS_CI': 'true',
              'CIRRUS_PR': '',
              'CIRRUS_BRANCH': 'master',
              'GOLD_SERVICE_ACCOUNT': 'service account...'
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterPostSubmitFileComparator.isAvailableForEnvironment(platform),
            isFalse,
          );
        });
      });
    });

    group('Pre-Submit', () {
      group('correctly determines testing environment', () {
        test('returns true for Luci', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'SWARMING_TASK_ID' : '12345678990',
              'GOLDCTL' : 'goldctl',
              'GOLD_TRYJOB' : 'git/ref/12345/head'
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterPreSubmitFileComparator.isAvailableForEnvironment(platform),
            isTrue,
          );
        });

        test('returns false - not on Luci', () {
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

        test('returns false - GOLDCTL missing', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'SWARMING_TASK_ID' : '12345678990',
              'GOLD_TRYJOB' : 'git/ref/12345/head'
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterPreSubmitFileComparator.isAvailableForEnvironment(platform),
            isFalse,
          );
        });

        test('returns false - GOLD_TRYJOB missing', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'SWARMING_TASK_ID' : '12345678990',
              'GOLDCTL' : 'goldctl',
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterPreSubmitFileComparator.isAvailableForEnvironment(platform),
            isFalse,
          );
        });

        test('returns false - on Cirrus', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'CIRRUS_CI': 'true',
              'CIRRUS_PR': '',
              'CIRRUS_BRANCH': 'master',
              'GOLD_SERVICE_ACCOUNT': 'service account...'
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterPostSubmitFileComparator.isAvailableForEnvironment(platform),
            isFalse,
          );
        });
      });
    });

    group('Skipping', () {
      group('correctly determines testing environment', () {
        test('returns true on Cirrus builds', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'CIRRUS_CI' : 'yep',
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterSkippingFileComparator.isAvailableForEnvironment(platform),
            isTrue,
          );
        });

        test('returns true on irrelevant LUCI builds', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'SWARMING_TASK_ID' : '1234567890',
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterSkippingFileComparator.isAvailableForEnvironment(platform),
            isTrue,
          );
        });

        test('returns false - no CI', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
            },
            operatingSystem: 'macos'
          );
          expect(
            FlutterSkippingFileComparator.isAvailableForEnvironment(
              platform),
            isFalse,
          );
        });
      });
    });

    group('Local', () {
      late FlutterLocalFileComparator comparator;
      final FakeSkiaGoldClient fakeSkiaClient = FakeSkiaGoldClient();

      setUp(() async {
        final Directory basedir = fs.directory('flutter/test/library/')
          ..createSync(recursive: true);
        comparator = FlutterLocalFileComparator(
          basedir.uri,
          fakeSkiaClient,
          fs: fs,
          platform: FakePlatform(
            environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot},
            operatingSystem: 'macos'
          ),
        );

        const String hash = '55109a4bed52acc780530f7a9aeff6c0';
        fakeSkiaClient.expectationForTestValues['flutter.golden_test.1'] = hash;
        fakeSkiaClient.expectationForTestValues['flutter.new_golden_test.1'] = '';
        fakeSkiaClient.imageBytesValues[hash] =_kTestPngBytes;
        fakeSkiaClient.cleanTestNameValues['library.flutter.golden_test.1.png'] = 'flutter.golden_test.1';
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

      testWithOutput('passes non-existent baseline for new test, null expectation', () async {
        expect(
          await comparator.compare(
            Uint8List.fromList(_kFailPngBytes),
            Uri.parse('flutter.new_golden_test.1'),
          ),
          isTrue,
        );
      }, 'No expectations provided by Skia Gold for test: library.flutter.new_golden_test.1. '
         'This may be a new test. If this is an unexpected result, check https://flutter-gold.skia.org.\n'
         'Validate image output found at flutter/test/library/'
      );

      testWithOutput('passes non-existent baseline for new test, empty expectation', () async {
        expect(
          await comparator.compare(
            Uint8List.fromList(_kFailPngBytes),
            Uri.parse('flutter.new_golden_test.2'),
          ),
          isTrue,
        );
      }, 'No expectations provided by Skia Gold for test: library.flutter.new_golden_test.2. '
        'This may be a new test. If this is an unexpected result, check https://flutter-gold.skia.org.\n'
        'Validate image output found at flutter/test/library/'
      );

      test('compare properly awaits validation & output before failing.', () async {
        final Completer<bool> completer = Completer<bool>();
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
        final FakeDirectory fakeDirectory = FakeDirectory();
        fakeDirectory.existsSyncValue = true;
        fakeDirectory.uri = Uri.parse('/flutter');

        fakeSkiaClient.getExpectationForTestThrowable = const OSError("Can't reach Gold");

        FlutterGoldenFileComparator comparator = await FlutterLocalFileComparator.fromDefaultComparator(
          platform,
          goldens: fakeSkiaClient,
          baseDirectory: fakeDirectory,
        );
        expect(comparator.runtimeType, FlutterSkippingFileComparator);

        fakeSkiaClient.getExpectationForTestThrowable =  const SocketException("Can't reach Gold");

        comparator = await FlutterLocalFileComparator.fromDefaultComparator(
          platform,
          goldens: fakeSkiaClient,
          baseDirectory: fakeDirectory,
        );
        expect(comparator.runtimeType, FlutterSkippingFileComparator);
      });
    });
  });
}

@immutable
class RunInvocation {
  const RunInvocation(this.command, this.workingDirectory);

  final List<String> command;
  final String? workingDirectory;

  @override
  int get hashCode => hashValues(hashList(command), workingDirectory);

  bool _commandEquals(List<String> other) {
    if (other == command) {
      return true;
    }
    if (other.length != command.length) {
      return false;
    }
    for (int index = 0; index < other.length; index += 1) {
      if (other[index] != command[index]) {
        return false;
      }
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is RunInvocation
        && _commandEquals(other.command)
        && other.workingDirectory == workingDirectory;
  }

  @override
  String toString() => '$command ($workingDirectory)';
}

class FakeProcessManager extends Fake implements ProcessManager {
  Map<RunInvocation, ProcessResult> processResults = <RunInvocation, ProcessResult>{};

  /// Used if [processResults] does not contain a matching invocation.
  ProcessResult? fallbackProcessResult;

  final List<String?> workingDirectories = <String?>[];

  @override
  Future<ProcessResult> run(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding stdoutEncoding = systemEncoding,
    Encoding stderrEncoding = systemEncoding,
  }) async {
    workingDirectories.add(workingDirectory);
    final ProcessResult? result = processResults[RunInvocation(command.cast<String>(), workingDirectory)];
    if (result == null && fallbackProcessResult == null) {
      // Throwing here might gobble up the exception message if a test fails.
      print('ProcessManager.run was called with $command ($workingDirectory) unexpectedly - $processResults.');
      fail('See above.');
    }
    return result ?? fallbackProcessResult!;
  }
}

class FakeSkiaGoldClient extends Fake implements SkiaGoldClient {
  Map<String, String> expectationForTestValues = <String, String>{};
  Object? getExpectationForTestThrowable;
  @override
  Future<String> getExpectationForTest(String testName) async {
    if (getExpectationForTestThrowable != null) {
      throw getExpectationForTestThrowable!;
    }
    return expectationForTestValues[testName] ?? '';
  }

  Map<String, List<int>> imageBytesValues = <String, List<int>>{};
  @override
  Future<List<int>> getImageBytes(String imageHash) async => imageBytesValues[imageHash]!;

  Map<String, String> cleanTestNameValues = <String, String>{};
  @override
  String cleanTestName(String fileName) => cleanTestNameValues[fileName] ?? '';
}

class FakeLocalFileComparator extends Fake implements LocalFileComparator {
  @override
  late Uri basedir;
}

class FakeDirectory extends Fake implements Directory {
  late bool existsSyncValue;
  @override
  bool existsSync() => existsSyncValue;

  @override
  late Uri uri;
}

class FakeHttpClient extends Fake implements HttpClient {
  late Uri lastUri;
  late FakeHttpClientRequest request;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    lastUri = url;
    return request;
  }
}

class FakeHttpClientRequest extends Fake implements HttpClientRequest {
  late FakeHttpImageResponse response;

  @override
  Future<HttpClientResponse> close() async {
    return response;
  }
}

class FakeHttpClientResponse extends Fake implements HttpClientResponse {
  FakeHttpClientResponse(this.response);

  final List<int> response;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
      Function? onError,
      void Function()? onDone,
      bool? cancelOnError,
    }) {
    return Stream<List<int>>.fromFuture(Future<List<int>>.value(response))
      .listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

class FakeHttpImageResponse extends Fake implements HttpClientResponse {
  FakeHttpImageResponse(this.response);

  final List<List<int>> response;

  @override
  Future<void> forEach(void Function(List<int> element) action) async {
    response.forEach(action);
  }
}
