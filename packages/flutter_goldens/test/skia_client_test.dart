// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// See also dev/automated_tests/flutter_test/flutter_gold_test.dart

import 'dart:convert';
import 'dart:io' hide Directory;

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_goldens/src/flutter_goldens_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';

import 'utils/fakes.dart';
import 'utils/json_templates.dart';

const String _kFlutterRoot = '/flutter';

void main() {
  late SkiaGoldClient skiaClient;
  late Directory workDirectory;
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

  test('web HTML test', () async {
    platform = FakePlatform(
        environment: <String, String>{
          'GOLDCTL': 'goldctl',
          'FLUTTER_ROOT': _kFlutterRoot,
          'FLUTTER_TEST_BROWSER': 'Chrome',
          'FLUTTER_WEB_RENDERER': 'html',
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

    final File goldenFile = fs.file('/workDirectory/temp/golden_file_test.png')
      ..createSync(recursive: true);

    const RunInvocation goldctlInvocation = RunInvocation(
      <String>[
        'goldctl',
        'imgtest', 'add',
        '--work-dir', '/workDirectory/temp',
        '--test-name', 'golden_file_test',
        '--png-file', '/workDirectory/temp/golden_file_test.png',
        '--passfail',
        '--add-test-optional-key', 'image_matching_algorithm:fuzzy',
        '--add-test-optional-key', 'fuzzy_max_different_pixels:20',
        '--add-test-optional-key', 'fuzzy_pixel_delta_threshold:4',
      ],
      null,
    );
    process.processResults[goldctlInvocation] = ProcessResult(123, 0, '', '');
    final Map<String, dynamic> keys = <String, dynamic>{
      'Platform' : 'macos-browser',
      'CI' : 'luci',
      'markedFlaky' : 'false',
      'Browser' : 'Chrome',
      'WebRenderer' : 'html',
    };

    expect(
      skiaClient.getKeysJSON(),
      json.encode(keys),
    );
    expect(
      await skiaClient.imgtestAdd('golden_file_test.png', goldenFile),
      isTrue,
    );
  });

  test('isFlaky sets right args - img test', () async {
    platform = FakePlatform(
        environment: <String, String>{
          'GOLDCTL': 'goldctl',
          'FLUTTER_ROOT': _kFlutterRoot,
          'FLUTTER_TEST_BROWSER': 'Chrome',
          'FLUTTER_WEB_RENDERER': 'html',
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

    final File goldenFile = fs.file('/workDirectory/temp/golden_file_test.png')
      ..createSync(recursive: true);

    const RunInvocation goldctlInvocation = RunInvocation(
      <String>[
        'goldctl',
        'imgtest', 'add',
        '--work-dir', '/workDirectory/temp',
        '--test-name', 'golden_file_test',
        '--png-file', '/workDirectory/temp/golden_file_test.png',
        '--passfail',
        '--add-test-optional-key', 'image_matching_algorithm:fuzzy',
        '--add-test-optional-key', 'fuzzy_max_different_pixels:1000000000',
        '--add-test-optional-key', 'fuzzy_pixel_delta_threshold:1020',
      ],
      null,
    );
    process.processResults[goldctlInvocation] = ProcessResult(123, 0, '', '');
    final Map<String, dynamic> keys = <String, dynamic>{
      'Platform' : 'macos-browser',
      'CI' : 'luci',
      'markedFlaky' : 'false',
      'Browser' : 'Chrome',
      'WebRenderer' : 'html',
    };

    expect(
      skiaClient.getKeysJSON(),
      json.encode(keys),
    );
    expect(
      await skiaClient.imgtestAdd('golden_file_test.png', goldenFile, isFlaky: true),
      isTrue,
    );
  });

  test('isFlaky sets right args - try job', () async {
    platform = FakePlatform(
        environment: <String, String>{
          'GOLDCTL': 'goldctl',
          'FLUTTER_ROOT': _kFlutterRoot,
          'FLUTTER_TEST_BROWSER': 'Chrome',
          'FLUTTER_WEB_RENDERER': 'html',
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

    final File goldenFile = fs.file('/workDirectory/temp/golden_file_test.png')
      ..createSync(recursive: true);

    const RunInvocation goldctlInvocation = RunInvocation(
      <String>[
        'goldctl',
        'imgtest', 'add',
        '--work-dir', '/workDirectory/temp',
        '--test-name', 'golden_file_test',
        '--png-file', '/workDirectory/temp/golden_file_test.png',
        '--add-test-optional-key', 'image_matching_algorithm:fuzzy',
        '--add-test-optional-key', 'fuzzy_max_different_pixels:1000000000',
        '--add-test-optional-key', 'fuzzy_pixel_delta_threshold:1020',
      ],
      null,
    );
    process.processResults[goldctlInvocation] = ProcessResult(123, 0, '', '');
    final Map<String, dynamic> keys = <String, dynamic>{
      'Platform' : 'macos-browser',
      'CI' : 'luci',
      'markedFlaky' : 'false',
      'Browser' : 'Chrome',
      'WebRenderer' : 'html',
    };

    expect(
      skiaClient.getKeysJSON(),
      json.encode(keys),
    );
    await skiaClient.tryjobAdd('golden_file_test.png', goldenFile, isFlaky: true);
  });

  test('web CanvasKit test', () async {
    platform = FakePlatform(
        environment: <String, String>{
          'GOLDCTL': 'goldctl',
          'FLUTTER_ROOT': _kFlutterRoot,
          'FLUTTER_TEST_BROWSER': 'Chrome',
          'FLUTTER_WEB_RENDERER': 'canvaskit',
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

    final File goldenFile = fs.file('/workDirectory/temp/golden_file_test.png')
      ..createSync(recursive: true);

    const RunInvocation goldctlInvocation = RunInvocation(
      <String>[
        'goldctl',
        'imgtest', 'add',
        '--work-dir', '/workDirectory/temp',
        '--test-name', 'golden_file_test',
        '--png-file', '/workDirectory/temp/golden_file_test.png',
        '--passfail',
      ],
      null,
    );
    process.processResults[goldctlInvocation] = ProcessResult(123, 0, '', '');
    final Map<String, dynamic> keys = <String, dynamic>{
      'Platform' : 'macos-browser',
      'CI' : 'luci',
      'markedFlaky' : 'false',
      'Browser' : 'Chrome',
      'WebRenderer' : 'canvaskit',
    };

    expect(
      skiaClient.getKeysJSON(),
      json.encode(keys),
    );
    expect(
      await skiaClient.imgtestAdd('golden_file_test.png', goldenFile),
      isTrue,
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

    process.fallbackProcessResult = ProcessResult(123, 1, 'Fallback failure', 'Fallback failure');

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
    process.processResults[goldctlInvocation] = ProcessResult(123, 1, 'Expected failure', 'Expected failure');
    process.fallbackProcessResult = ProcessResult(123, 1, 'Fallback failure', 'Fallback failure');

    expect(
      skiaClient.imgtestInit(),
      throwsException,
    );
  });

  test('Only calls init once', () async {
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
        '--commit', '1234',
        '--keys-file', '/workDirectory/keys.json',
        '--failure-file', '/workDirectory/failures.json',
        '--passfail',
      ],
      null,
    );
    process.processResults[gitInvocation] = ProcessResult(1234, 0, '1234', '');
    process.processResults[goldctlInvocation] = ProcessResult(5678, 0, '5678', '');
    process.fallbackProcessResult = ProcessResult(123, 1, 'Fallback failure', 'Fallback failure');

    // First call
    await skiaClient.imgtestInit();

    // Remove fake process result.
    // If the init call is executed again, the fallback process will throw.
    process.processResults.remove(goldctlInvocation);

    // Second call
    await skiaClient.imgtestInit();
  });

  test('Only calls tryjob init once', () async {
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
        '--commit', '1234',
        '--keys-file', '/workDirectory/keys.json',
        '--failure-file', '/workDirectory/failures.json',
        '--passfail',
        '--crs', 'github',
        '--patchset_id', '1234',
        '--changelist', '49815',
        '--cis', 'buildbucket',
        '--jobid', '8885996262141582672',
      ],
      null,
    );
    process.processResults[gitInvocation] = ProcessResult(1234, 0, '1234', '');
    process.processResults[goldctlInvocation] = ProcessResult(5678, 0, '5678', '');
    process.fallbackProcessResult = ProcessResult(123, 1, 'Fallback failure', 'Fallback failure');

    // First call
    await skiaClient.tryjobInit();

    // Remove fake process result.
    // If the init call is executed again, the fallback process will throw.
    process.processResults.remove(goldctlInvocation);

    // Second call
    await skiaClient.tryjobInit();
  });

  test('throws for error state from imgtestAdd', () {
    final File goldenFile = fs.file('/workDirectory/temp/golden_file_test.png')
      ..createSync(recursive: true);
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

    const RunInvocation goldctlInvocation = RunInvocation(
      <String>[
        'goldctl',
        'imgtest', 'add',
        '--work-dir', '/workDirectory/temp',
        '--test-name', 'golden_file_test',
        '--png-file', '/workDirectory/temp/golden_file_test.png',
        '--passfail',
      ],
      null,
    );
    process.processResults[goldctlInvocation] = ProcessResult(123, 1, 'Expected failure', 'Expected failure');
    process.fallbackProcessResult = ProcessResult(123, 1, 'Fallback failure', 'Fallback failure');

    expect(
      skiaClient.imgtestAdd('golden_file_test', goldenFile),
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

  test('Creates traceID correctly', () async {
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
      equals('ae18c7a6aa48e0685525dfe8fdf79003'),
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
      equals('e9d5c296c48e7126808520e9cc191243'),
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
      equals('9968695b9ae78cdb77cbb2be621ca2d6'),
    );
  });

  test('throws for error state from imgtestAdd', () {
    final File goldenFile = fs.file('/workDirectory/temp/golden_file_test.png')
      ..createSync(recursive: true);
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

    const RunInvocation goldctlInvocation = RunInvocation(
      <String>[
        'goldctl',
        'imgtest', 'add',
        '--work-dir', '/workDirectory/temp',
        '--test-name', 'golden_file_test',
        '--png-file', '/workDirectory/temp/golden_file_test.png',
        '--passfail',
      ],
      null,
    );
    process.processResults[goldctlInvocation] = ProcessResult(123, 1, 'Expected failure', 'Expected failure');
    process.fallbackProcessResult = ProcessResult(123, 1, 'Fallback failure', 'Fallback failure');

    expect(
      skiaClient.imgtestAdd('golden_file_test', goldenFile),
      throwsA(
        isA<SkiaException>().having((SkiaException error) => error.message,
          'message',
          contains('result-state.json'),
        ),
      ),
    );
  });

  test('throws for error state from tryjobAdd', () {
    final File goldenFile = fs.file('/workDirectory/temp/golden_file_test.png')
      ..createSync(recursive: true);
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

    const RunInvocation goldctlInvocation = RunInvocation(
      <String>[
        'goldctl',
        'imgtest', 'add',
        '--work-dir', '/workDirectory/temp',
        '--test-name', 'golden_file_test',
        '--png-file', '/workDirectory/temp/golden_file_test.png',
        '--passfail',
      ],
      null,
    );
    process.processResults[goldctlInvocation] = ProcessResult(123, 1, 'Expected failure', 'Expected failure');
    process.fallbackProcessResult = ProcessResult(123, 1, 'Fallback failure', 'Fallback failure');

    expect(
      skiaClient.tryjobAdd('golden_file_test', goldenFile),
      throwsA(
        isA<SkiaException>().having((SkiaException error) => error.message,
          'message',
          contains('result-state.json'),
        ),
      ),
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
      expect(masterBytes, equals(kTestPngBytes));
    });
  });
}
