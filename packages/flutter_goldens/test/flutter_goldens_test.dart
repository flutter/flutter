// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// See also dev/automated_tests/flutter_test/flutter_gold_test.dart

import 'dart:convert';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_goldens/flutter_goldens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import 'json_templates.dart';

const String _kFlutterRoot = '/flutter';

// 1x1 transparent pixel
const List<int> _kTestPngBytes = <int>[
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0,
  1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 11, 73, 68, 65, 84,
  120, 1, 99, 97, 0, 2, 0, 0, 25, 0, 5, 144, 240, 54, 245, 0, 0, 0, 0, 73, 69,
  78, 68, 174, 66, 96, 130,
];

FileSystem createFakeFileSystem() {
  return MemoryFileSystem()
    ..directory(_kFlutterRoot).createSync(recursive: true);
}

(FileSystem, Directory) createFakeFileSystemWithWorkDirectory() {
  final FileSystem fs = createFakeFileSystem();
  final Directory workDirectory = fs.directory('/workDirectory')..createSync(recursive: true);
  return (fs, workDirectory);
}

(FileSystem, Directory) createFakeFileSystemWithLibDirectory() {
  final FileSystem fs = createFakeFileSystem();
  final Directory lib = fs.directory('$_kFlutterRoot/test/library/')..createSync(recursive: true);
  return (fs, lib);
}

void main() {
  test('SkiaGoldClient - web HTML test', () async {
    final Platform platform = FakePlatform(
      environment: <String, String>{
        'GOLDCTL': 'goldctl',
        'FLUTTER_ROOT': _kFlutterRoot,
        'FLUTTER_TEST_BROWSER': 'Chrome',
        'FLUTTER_WEB_RENDERER': 'html',
      },
      operatingSystem: 'macos'
    );
    final (FileSystem fs, Directory workDirectory) = createFakeFileSystemWithWorkDirectory();
    final FakeProcessManager process = FakeProcessManager();
    final io.HttpClient httpClient = ThrowingHttpClient();
    final SkiaGoldClient skiaClient = SkiaGoldClient(
      workDirectory,
      fs: fs,
      process: process,
      platform: platform,
      httpClient: httpClient,
      log: (String message) => fail('skia gold client printed unexpected output: "$message"'),
    );

    final File goldenFile = workDirectory.childFile('temp/golden_file_test.png')
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
    process.processResults[goldctlInvocation] = io.ProcessResult(123, 0, '', '');
    await skiaClient.imgtestAdd('golden_file_test.png', goldenFile);
  });

  test('SkiaGoldClient - web CanvasKit test', () async {
    final Platform platform = FakePlatform(
      environment: <String, String>{
        'GOLDCTL': 'goldctl',
        'FLUTTER_ROOT': _kFlutterRoot,
        'FLUTTER_TEST_BROWSER': 'Chrome',
        'FLUTTER_WEB_RENDERER': 'canvaskit',
      },
      operatingSystem: 'macos'
    );
    final (FileSystem fs, Directory workDirectory) = createFakeFileSystemWithWorkDirectory();
    final FakeProcessManager process = FakeProcessManager();
    final io.HttpClient httpClient = FakeHttpClient();
    final SkiaGoldClient skiaClient = SkiaGoldClient(
      workDirectory,
      fs: fs,
      process: process,
      platform: platform,
      httpClient: httpClient,
      log: (String message) => fail('skia gold client printed unexpected output: "$message"'),
    );

    final File goldenFile = workDirectory.childFile('temp/golden_file_test.png')
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
    process.processResults[goldctlInvocation] = io.ProcessResult(123, 0, '', '');

    await skiaClient.imgtestAdd('golden_file_test.png', goldenFile);
  });

  test('SkiaGoldClient - auth performs minimal work if already authorized', () async {
    final Platform platform = FakePlatform(
      environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot},
      operatingSystem: 'macos'
    );
    final (FileSystem fs, Directory workDirectory) = createFakeFileSystemWithWorkDirectory();
    final FakeProcessManager process = FakeProcessManager();
    final File authFile = workDirectory.childFile('temp/auth_opt.json')
      ..createSync(recursive: true);
    authFile.writeAsStringSync(authTemplate());
    process.fallbackProcessResult = io.ProcessResult(123, 0, '', '');
    final SkiaGoldClient skiaClient = SkiaGoldClient(
      workDirectory,
      fs: fs,
      process: process,
      platform: platform,
      httpClient: ThrowingHttpClient(),
      log: (String message) => fail('skia gold client printed unexpected output: "$message"'),
    );
    await skiaClient.auth();
    expect(process.workingDirectories, isEmpty);
  });

  test('SkiaGoldClient - gsutil is checked when authorization file is present', () async {
    final Platform platform = FakePlatform(
      environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot},
      operatingSystem: 'macos'
    );
    final (FileSystem fs, Directory workDirectory) = createFakeFileSystemWithWorkDirectory();
    final ProcessManager process = FakeProcessManager();
    final File authFile = workDirectory.childFile('temp/auth_opt.json')
      ..createSync(recursive: true);
    authFile.writeAsStringSync(authTemplate(gsutil: true));
    final SkiaGoldClient skiaClient = SkiaGoldClient(
      workDirectory,
      fs: fs,
      process: process,
      platform: platform,
      httpClient: ThrowingHttpClient(),
      log: (String message) => fail('skia gold client printed unexpected output: "$message"'),
    );
    expect(
      await skiaClient.clientIsAuthorized(),
      isFalse,
    );
  });

  test('SkiaGoldClient - throws for error state from auth', () async {
    final Platform platform = FakePlatform(
      environment: <String, String>{
        'FLUTTER_ROOT': _kFlutterRoot,
        'GOLD_SERVICE_ACCOUNT': 'Service Account',
        'GOLDCTL': 'goldctl',
      },
      operatingSystem: 'macos'
    );
    final (FileSystem fs, Directory workDirectory) = createFakeFileSystemWithWorkDirectory();
    final FakeProcessManager process = FakeProcessManager();
    final SkiaGoldClient skiaClient = SkiaGoldClient(
      workDirectory,
      fs: fs,
      process: process,
      platform: platform,
      httpClient: ThrowingHttpClient(),
      log: (String message) => fail('skia gold client printed unexpected output: "$message"'),
    );
    process.fallbackProcessResult = io.ProcessResult(123, 1, 'Fallback failure', 'Fallback failure');
    expect(
      skiaClient.auth(),
      throwsException,
    );
  });

  test('SkiaGoldClient - throws for error state from init', () {
    final Platform platform = FakePlatform(
      environment: <String, String>{
        'FLUTTER_ROOT': _kFlutterRoot,
        'GOLDCTL': 'goldctl',
      },
      operatingSystem: 'macos'
    );
    final (FileSystem fs, Directory workDirectory) = createFakeFileSystemWithWorkDirectory();
    final FakeProcessManager process = FakeProcessManager();
    final SkiaGoldClient skiaClient = SkiaGoldClient(
      workDirectory,
      fs: fs,
      process: process,
      platform: platform,
      httpClient: ThrowingHttpClient(),
      log: (String message) => fail('skia gold client printed unexpected output: "$message"'),
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
    process.processResults[gitInvocation] = io.ProcessResult(12345678, 0, '12345678', '');
    process.processResults[goldctlInvocation] = io.ProcessResult(123, 1, 'Expected failure', 'Expected failure');
    process.fallbackProcessResult = io.ProcessResult(123, 1, 'Fallback failure', 'Fallback failure');

    expect(
      skiaClient.imgtestInit(),
      throwsException,
    );
  });

  test('SkiaGoldClient - Only calls init once', () async {
    final Platform platform = FakePlatform(
      environment: <String, String>{
        'FLUTTER_ROOT': _kFlutterRoot,
        'GOLDCTL': 'goldctl',
      },
      operatingSystem: 'macos',
    );
    final (FileSystem fs, Directory workDirectory) = createFakeFileSystemWithWorkDirectory();
    final FakeProcessManager process = FakeProcessManager();
    final SkiaGoldClient skiaClient = SkiaGoldClient(
      workDirectory,
      fs: fs,
      process: process,
      platform: platform,
      httpClient: ThrowingHttpClient(),
      log: (String message) => fail('skia gold client printed unexpected output: "$message"'),
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
    process.processResults[gitInvocation] = io.ProcessResult(1234, 0, '1234', '');
    process.processResults[goldctlInvocation] = io.ProcessResult(5678, 0, '5678', '');
    process.fallbackProcessResult = io.ProcessResult(123, 1, 'Fallback failure', 'Fallback failure');

    // First call
    await skiaClient.imgtestInit();

    // Remove fake process result.
    // If the init call is executed again, the fallback process will throw.
    process.processResults.remove(goldctlInvocation);

    // Second call
    await skiaClient.imgtestInit();
  });

  test('SkiaGoldClient - Only calls tryjob init once', () async {
    final Platform platform = FakePlatform(
      environment: <String, String>{
        'FLUTTER_ROOT': _kFlutterRoot,
        'GOLDCTL': 'goldctl',
        'SWARMING_TASK_ID': '4ae997b50dfd4d11',
        'LOGDOG_STREAM_PREFIX': 'buildbucket/cr-buildbucket.appspot.com/8885996262141582672',
        'GOLD_TRYJOB': 'refs/pull/49815/head',
      },
      operatingSystem: 'macos'
    );
    final (FileSystem fs, Directory workDirectory) = createFakeFileSystemWithWorkDirectory();
    final FakeProcessManager process = FakeProcessManager();
    final SkiaGoldClient skiaClient = SkiaGoldClient(
      workDirectory,
      fs: fs,
      process: process,
      platform: platform,
      httpClient: ThrowingHttpClient(),
      log: (String message) => fail('skia gold client printed unexpected output: "$message"'),
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
    process.processResults[gitInvocation] = io.ProcessResult(1234, 0, '1234', '');
    process.processResults[goldctlInvocation] = io.ProcessResult(5678, 0, '5678', '');
    process.fallbackProcessResult = io.ProcessResult(123, 1, 'Fallback failure', 'Fallback failure');

    // First call
    await skiaClient.tryjobInit();

    // Remove fake process result.
    // If the init call is executed again, the fallback process will throw.
    process.processResults.remove(goldctlInvocation);

    // Second call
    await skiaClient.tryjobInit();
  });

  test('SkiaGoldClient - throws for error state from imgtestAdd', () {
    final (FileSystem fs, Directory workDirectory) = createFakeFileSystemWithWorkDirectory();
    final File goldenFile = workDirectory.childFile('temp/golden_file_test.png')
      ..createSync(recursive: true);
    final FakeProcessManager process = FakeProcessManager();
    final Platform platform = FakePlatform(
        environment: <String, String>{
          'FLUTTER_ROOT': _kFlutterRoot,
          'GOLDCTL': 'goldctl',
        },
        operatingSystem: 'macos',
    );
    final SkiaGoldClient skiaClient = SkiaGoldClient(
      workDirectory,
      fs: fs,
      process: process,
      platform: platform,
      httpClient: ThrowingHttpClient(),
      log: (String message) => fail('skia gold client printed unexpected output: "$message"'),
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
    process.processResults[goldctlInvocation] = io.ProcessResult(123, 1, 'Expected failure', 'Expected failure');
    process.fallbackProcessResult = io.ProcessResult(123, 1, 'Fallback failure', 'Fallback failure');

    expect(
      skiaClient.imgtestAdd('golden_file_test', goldenFile),
      throwsException,
    );
  });

  test('SkiaGoldClient - correctly inits tryjob for luci', () async {
    final Platform platform = FakePlatform(
      environment: <String, String>{
        'FLUTTER_ROOT': _kFlutterRoot,
        'GOLDCTL': 'goldctl',
        'SWARMING_TASK_ID': '4ae997b50dfd4d11',
        'LOGDOG_STREAM_PREFIX': 'buildbucket/cr-buildbucket.appspot.com/8885996262141582672',
        'GOLD_TRYJOB': 'refs/pull/49815/head',
      },
      operatingSystem: 'macos'
    );
    final (FileSystem fs, Directory workDirectory) = createFakeFileSystemWithWorkDirectory();
    final ProcessManager process = FakeProcessManager();
    final SkiaGoldClient skiaClient = SkiaGoldClient(
      workDirectory,
      fs: fs,
      process: process,
      platform: platform,
      httpClient: ThrowingHttpClient(),
      log: (String message) => fail('skia gold client printed unexpected output: "$message"'),
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

  test('SkiaGoldClient - Creates traceID correctly - Linux', () async {
    final Platform platform = FakePlatform(
      environment: <String, String>{
        'FLUTTER_ROOT': _kFlutterRoot,
        'GOLDCTL': 'goldctl',
        'SWARMING_TASK_ID': '4ae997b50dfd4d11',
        'LOGDOG_STREAM_PREFIX': 'buildbucket/cr-buildbucket.appspot.com/8885996262141582672',
        'GOLD_TRYJOB': 'refs/pull/49815/head',
      },
      operatingSystem: 'linux',
    );
    final (FileSystem fs, Directory workDirectory) = createFakeFileSystemWithWorkDirectory();
    final ProcessManager process = FakeProcessManager();
    final SkiaGoldClient skiaClient = SkiaGoldClient(
      workDirectory,
      fs: fs,
      process: process,
      platform: platform,
      httpClient: ThrowingHttpClient(),
      log: (String message) => fail('skia gold client printed unexpected output: "$message"'),
    );
    expect(
      skiaClient.getTraceID('flutter.golden.1'),
      equals('ae18c7a6aa48e0685525dfe8fdf79003'),
    );
  });

  test('SkiaGoldClient - Creates traceID correctly - Linux web', () async {
    final Platform platform = FakePlatform(
      environment: <String, String>{
        'FLUTTER_ROOT': _kFlutterRoot,
        'GOLDCTL': 'goldctl',
        'SWARMING_TASK_ID': '4ae997b50dfd4d11',
        'LOGDOG_STREAM_PREFIX': 'buildbucket/cr-buildbucket.appspot.com/8885996262141582672',
        'GOLD_TRYJOB': 'refs/pull/49815/head',
        'FLUTTER_TEST_BROWSER': 'chrome', // flips browser bit
      },
      operatingSystem: 'linux',
    );
    final (FileSystem fs, Directory workDirectory) = createFakeFileSystemWithWorkDirectory();
    final ProcessManager process = FakeProcessManager();
    final SkiaGoldClient skiaClient = SkiaGoldClient(
      workDirectory,
      fs: fs,
      process: process,
      platform: platform,
      httpClient: ThrowingHttpClient(),
      log: (String message) => fail('skia gold client printed unexpected output: "$message"'),
    );
    expect(
      skiaClient.getTraceID('flutter.golden.1'),
      equals('e9d5c296c48e7126808520e9cc191243'),
    );
  });

  test('SkiaGoldClient - Creates traceID correctly - Linux', () async {
    final Platform platform = FakePlatform(
      environment: <String, String>{
        'FLUTTER_ROOT': _kFlutterRoot,
        'GOLDCTL': 'goldctl',
        'SWARMING_TASK_ID': '4ae997b50dfd4d11',
        'LOGDOG_STREAM_PREFIX': 'buildbucket/cr-buildbucket.appspot.com/8885996262141582672',
        'GOLD_TRYJOB': 'refs/pull/49815/head',
      },
      operatingSystem: 'macos', // different operating system
    );
    final (FileSystem fs, Directory workDirectory) = createFakeFileSystemWithWorkDirectory();
    final ProcessManager process = FakeProcessManager();
    final SkiaGoldClient skiaClient = SkiaGoldClient(
      workDirectory,
      fs: fs,
      process: process,
      platform: platform,
      httpClient: ThrowingHttpClient(),
      log: (String message) => fail('skia gold client printed unexpected output: "$message"'),
    );
    expect(
      skiaClient.getTraceID('flutter.golden.1'),
      equals('9968695b9ae78cdb77cbb2be621ca2d6'),
    );
  });

  test('SkiaGoldClient - throws for error state from imgtestAdd', () {
    final Platform platform = FakePlatform(
        environment: <String, String>{
          'FLUTTER_ROOT': _kFlutterRoot,
          'GOLDCTL': 'goldctl',
        },
        operatingSystem: 'macos',
    );
    final (FileSystem fs, Directory workDirectory) = createFakeFileSystemWithWorkDirectory();
    final File goldenFile = workDirectory.childFile('temp/golden_file_test.png')
      ..createSync(recursive: true);
    final FakeProcessManager process = FakeProcessManager();
    final SkiaGoldClient skiaClient = SkiaGoldClient(
      workDirectory,
      fs: fs,
      process: process,
      platform: platform,
      httpClient: ThrowingHttpClient(),
      log: (String message) => fail('skia gold client printed unexpected output: "$message"'),
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
    process.processResults[goldctlInvocation] = io.ProcessResult(123, 1, 'Expected failure', 'Expected failure');
    process.fallbackProcessResult = io.ProcessResult(123, 1, 'Fallback failure', 'Fallback failure');

    expect(
      skiaClient.imgtestAdd('golden_file_test', goldenFile),
      throwsA(
        isA<SkiaException>().having((SkiaException error) => error.message,
          'message',
          'Golden test for "golden_file_test" failed for a reason unrelated to pixel comparison.\n'
          '\n'
          'imgtest add failed with exit code 1.\n'
          '\n'
          'stdout from gold:\n'
          '  Fallback failure\n'
          '\n'
          'stderr from gold:\n'
          '  Fallback failure\n',
        ),
      ),
    );
  });

  test('SkiaGoldClient - throws for error state from tryjobAdd', () {
    final Platform platform = FakePlatform(
        environment: <String, String>{
          'FLUTTER_ROOT': _kFlutterRoot,
          'GOLDCTL': 'goldctl',
        },
        operatingSystem: 'macos',
    );
    final (FileSystem fs, Directory workDirectory) = createFakeFileSystemWithWorkDirectory();
    final File goldenFile = workDirectory.childFile('temp/golden_file_test.png')
      ..createSync(recursive: true);
    final FakeProcessManager process = FakeProcessManager();
    final SkiaGoldClient skiaClient = SkiaGoldClient(
      workDirectory,
      fs: fs,
      process: process,
      platform: platform,
      httpClient: ThrowingHttpClient(),
      log: (String message) => fail('skia gold client printed unexpected output: "$message"'),
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
    process.processResults[goldctlInvocation] = io.ProcessResult(123, 1, 'Expected failure', 'Expected failure');
    process.fallbackProcessResult = io.ProcessResult(123, 1, 'Fallback failure', 'Fallback failure');

    expect(
      skiaClient.tryjobAdd('golden_file_test', goldenFile),
      throwsA(
        isA<SkiaException>().having((SkiaException error) => error.message,
          'message',
          'Golden test for "golden_file_test" failed for a reason unrelated to pixel comparison.\n'
          '\n'
          'imgtest add failed with exit code 1.\n'
          '\n'
          'stdout from gold:\n'
          '  Fallback failure\n'
          '\n'
          'stderr from gold:\n'
          '  Fallback failure\n',
        ),
      ),
    );
  });

  test('SkiaGoldClient - Request Handling - image bytes are processed properly', () async {
    const String expectation = '55109a4bed52acc780530f7a9aeff6c0';
    final Platform platform = FakePlatform(
      environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot},
      operatingSystem: 'macos'
    );
    final (FileSystem fs, Directory workDirectory) = createFakeFileSystemWithWorkDirectory();
    final ProcessManager process = FakeProcessManager();
    final Uri imageUrl = Uri.parse(
      'https://flutter-gold.skia.org/img/images/$expectation.png'
    );
    final FakeHttpClient fakeHttpClient = FakeHttpClient();
    final FakeHttpClientRequest fakeImageRequest = FakeHttpClientRequest();
    final FakeHttpImageResponse fakeImageResponse = FakeHttpImageResponse(
      imageResponseTemplate()
    );

    fakeHttpClient.request = fakeImageRequest;
    fakeImageRequest.response = fakeImageResponse;

    final SkiaGoldClient skiaClient = SkiaGoldClient(
      workDirectory,
      fs: fs,
      process: process,
      platform: platform,
      httpClient: fakeHttpClient,
      log: (String message) => fail('skia gold client printed unexpected output: "$message"'),
    );
    final List<int> masterBytes = await skiaClient.getImageBytes(expectation);

    expect(fakeHttpClient.lastUri, imageUrl);
    expect(masterBytes, equals(_kTestPngBytes));
  });

  test('FlutterGoldenFileComparator - calculates the basedir correctly from defaultComparator for local testing', () async {
    final Platform platform = FakePlatform(
      environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot},
      operatingSystem: 'macos'
    );
    final FileSystem fs = createFakeFileSystem();
    final FakeLocalFileComparator defaultComparator = FakeLocalFileComparator();
    final Directory flutterRoot = fs.directory(platform.environment['FLUTTER_ROOT'])
      ..createSync(recursive: true);
    defaultComparator.basedir = flutterRoot.childDirectory('baz').uri;

    final Directory basedir = FlutterGoldenFileComparator.getBaseDirectory(
      defaultComparator,
      platform: platform,
      fs: fs,
    );
    expect(
      basedir.uri,
      fs.directory('/flutter/bin/cache/pkg/skia_goldens/baz').uri,
    );
  });

  test('FlutterGoldenFileComparator - ignores version number', () {
    final Platform platform = FakePlatform(
      environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot},
      operatingSystem: 'macos'
    );
    final (FileSystem fs, Directory libDirectory) = createFakeFileSystemWithLibDirectory();
    final List<String> log = <String>[];
    final FlutterGoldenFileComparator comparator = FlutterPostSubmitFileComparator(
      libDirectory.uri,
      FakeSkiaGoldClient(),
      fs: fs,
      platform: platform,
      log: log.add,
    );
    final Uri key = comparator.getTestUri(Uri.parse('foo.png'), 1);
    expect(key, Uri.parse('foo.png'));
    expect(log, isEmpty);
  });

  test('FlutterGoldenFileComparator - adds namePrefix', () async {
    final Platform platform = FakePlatform(
      environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot},
      operatingSystem: 'macos'
    );
    const String libraryName = 'sidedishes';
    const String namePrefix = 'tomatosalad';
    const String fileName = 'lettuce.png';
    final FileSystem fs = createFakeFileSystem();
    final Directory basedir = fs.directory('flutter/test/$libraryName/')
      ..createSync(recursive: true);
    final FakeSkiaGoldClient fakeSkiaClient = FakeSkiaGoldClient();
    final List<String> log = <String>[];
    final FlutterGoldenFileComparator comparator = FlutterPostSubmitFileComparator(
      basedir.uri,
      fakeSkiaClient,
      fs: fs,
      platform: platform,
      log: log.add,
      namePrefix: namePrefix,
    );
    await comparator.compare(
      Uint8List.fromList(_kTestPngBytes),
      Uri.parse(fileName),
    );
    expect(fakeSkiaClient.testNames.single, '$namePrefix.$libraryName.$fileName');
    expect(log, isEmpty);
  });

  test('FlutterGoldenFileComparator - Post-Submit - asserts .png format', () async {
    final Platform platform = FakePlatform(
      environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot},
      operatingSystem: 'macos'
    );
    final (FileSystem fs, Directory libDirectory) = createFakeFileSystemWithLibDirectory();
    final FakeSkiaGoldClient fakeSkiaClient = FakeSkiaGoldClient();
    final List<String> log = <String>[];
    final FlutterGoldenFileComparator comparator = FlutterPostSubmitFileComparator(
      libDirectory.uri,
      fakeSkiaClient,
      fs: fs,
      platform: platform,
      log: log.add,
    );
    await expectLater(
      () async {
        return comparator.compare(
          Uint8List.fromList(_kTestPngBytes),
          Uri.parse('flutter.golden_test.1'),
        );
      },
      throwsA(
        isA<AssertionError>().having((AssertionError error) => error.toString(),
          'description',
          contains(
            'Golden files in the Flutter framework must end with the file '
            'extension .png.'
          ),
        ),
      ),
    );
    expect(log, isEmpty);
  });

  test('FlutterGoldenFileComparator - Post-Submit - calls init during compare', () async {
    final Platform platform = FakePlatform(
      environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot},
      operatingSystem: 'macos'
    );
    final (FileSystem fs, Directory libDirectory) = createFakeFileSystemWithLibDirectory();
    final FakeSkiaGoldClient fakeSkiaClient = FakeSkiaGoldClient();
    final List<String> log = <String>[];
    final FlutterGoldenFileComparator comparator = FlutterPostSubmitFileComparator(
      libDirectory.uri,
      fakeSkiaClient,
      fs: fs,
      platform: platform,
      log: log.add,
    );
    expect(fakeSkiaClient.initCalls, 0);
    await comparator.compare(
      Uint8List.fromList(_kTestPngBytes),
      Uri.parse('flutter.golden_test.1.png'),
    );
    expect(fakeSkiaClient.initCalls, 1);
    expect(log, isEmpty);
  });

  test('FlutterGoldenFileComparator - Post-Submit - does not call init in during construction', () {
    final Platform platform = FakePlatform(
      environment: <String, String>{
        'FLUTTER_ROOT': _kFlutterRoot,
        'GOLDCTL': 'testctl',
      },
      operatingSystem: 'macos'
    );
    final FileSystem fs = createFakeFileSystem();
    final List<String> log = <String>[];
    FlutterPostSubmitFileComparator.fromLocalFileComparator(
      localFileComparator: LocalFileComparator(Uri.parse('/test'), pathStyle: path.Style.posix),
      platform: platform,
      fs: fs,
      process: LoggingProcessManager(log),
      httpClient: ThrowingHttpClient(),
      log: (String message) => fail('skia gold client printed unexpected output: "$message"'),
    );
    expect(log, isEmpty);
  });

  test('FlutterGoldenFileComparator - Pre-Submit - asserts .png format', () async {
    final FakeSkiaGoldClient fakeSkiaClient = FakeSkiaGoldClient();
    final (FileSystem fs, Directory libDirectory) = createFakeFileSystemWithLibDirectory();
    final List<String> log = <String>[];
    final FlutterGoldenFileComparator comparator = FlutterPreSubmitFileComparator(
      libDirectory.uri,
      fakeSkiaClient,
      fs: fs,
      platform: FakePlatform(
        environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot},
        operatingSystem: 'macos',
      ),
      log: log.add,
    );
    await expectLater(
      () async {
        return comparator.compare(
          Uint8List.fromList(_kTestPngBytes),
          Uri.parse('flutter.golden_test.1'),
        );
      },
      throwsA(
        isA<AssertionError>().having((AssertionError error) => error.toString(),
          'description',
          contains(
            'Golden files in the Flutter framework must end with the file '
            'extension .png.'
          ),
        ),
      ),
    );
    expect(log, isEmpty);
  });

  test('FlutterGoldenFileComparator - Pre-Submit - calls init during compare', () async {
    final FakeSkiaGoldClient fakeSkiaClient = FakeSkiaGoldClient();
    final (FileSystem fs, Directory libDirectory) = createFakeFileSystemWithLibDirectory();
    final List<String> log = <String>[];
    final FlutterGoldenFileComparator comparator = FlutterPreSubmitFileComparator(
      libDirectory.uri,
      fakeSkiaClient,
      fs: fs,
      platform: FakePlatform(
        environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot},
        operatingSystem: 'macos',
      ),
      log: log.add,
    );
    expect(fakeSkiaClient.tryInitCalls, 0);
    await comparator.compare(
      Uint8List.fromList(_kTestPngBytes),
      Uri.parse('flutter.golden_test.1.png'),
    );
    expect(fakeSkiaClient.tryInitCalls, 1);
    expect(log, isEmpty);
  });

  test('FlutterGoldenFileComparator - Pre-Submit - does not call init in during construction', () async {
    final Platform platform = FakePlatform(
      environment: <String, String>{
        'FLUTTER_ROOT': _kFlutterRoot,
        'GOLDCTL': 'testctl',
      },
      operatingSystem: 'macos',
    );
    final FileSystem fs = createFakeFileSystem();
    final List<String> log = <String>[];
    await FlutterPostSubmitFileComparator.fromLocalFileComparator(
      localFileComparator: LocalFileComparator(Uri.parse('/test'), pathStyle: path.Style.posix),
      platform: platform,
      fs: fs,
      process: LoggingProcessManager(log),
      httpClient: FakeHttpClient(),
      log: (String message) => fail('skia gold client printed unexpected output: "$message"'),
    );
    expect(log, <String>['testctl auth --work-dir /.tmp_rand0/flutter_goldens_postsubmit.rand0/../temp --luci']);
  });

  test('FlutterGoldenFileComparator - Local - asserts .png format', () async {
    final FakeSkiaGoldClient fakeSkiaClient = FakeSkiaGoldClient();
    final (FileSystem fs, Directory libDirectory) = createFakeFileSystemWithLibDirectory();
    final List<String> log = <String>[];
    final FlutterLocalFileComparator comparator = FlutterLocalFileComparator(
      libDirectory.uri,
      fakeSkiaClient,
      fs: fs,
      platform: FakePlatform(
        environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot},
        operatingSystem: 'macos',
      ),
      log: log.add,
    );

    const String hash = '55109a4bed52acc780530f7a9aeff6c0';
    fakeSkiaClient.expectationForTestValues['flutter.golden_test.1'] = hash;
    fakeSkiaClient.imageBytesValues[hash] =_kTestPngBytes;
    fakeSkiaClient.cleanTestNameValues['library.flutter.golden_test.1.png'] = 'flutter.golden_test.1';
    await expectLater(
      () async {
        return comparator.compare(
          Uint8List.fromList(_kTestPngBytes),
          Uri.parse('flutter.golden_test.1'),
        );
      },
      throwsA(
        isA<AssertionError>().having((AssertionError error) => error.toString(),
          'description',
          contains(
            'Golden files in the Flutter framework must end with the file '
            'extension .png.'
          ),
        ),
      ),
    );
    expect(log, isEmpty);
  });

  test('FlutterGoldenFileComparator - Local - passes when bytes match', () async {
    final List<String> log = <String>[];
    final FakeSkiaGoldClient fakeSkiaClient = FakeSkiaGoldClient();
    final (FileSystem fs, Directory libDirectory) = createFakeFileSystemWithLibDirectory();
    final FlutterLocalFileComparator comparator = FlutterLocalFileComparator(
      libDirectory.uri,
      fakeSkiaClient,
      fs: fs,
      platform: FakePlatform(
        environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot},
        operatingSystem: 'macos',
      ),
      log: log.add,
    );

    const String hash = '55109a4bed52acc780530f7a9aeff6c0';
    fakeSkiaClient.expectationForTestValues['flutter.golden_test.1'] = hash;
    fakeSkiaClient.imageBytesValues[hash] =_kTestPngBytes;
    fakeSkiaClient.cleanTestNameValues['library.flutter.golden_test.1.png'] = 'flutter.golden_test.1';
    expect(
      await comparator.compare(
        Uint8List.fromList(_kTestPngBytes),
        Uri.parse('flutter.golden_test.1.png'),
      ),
      isTrue,
    );
    expect(log, isEmpty);
  });

  test('FlutterGoldenFileComparator - Local - skips when network connection is unavailable', () async {
    final FileSystem fs = createFakeFileSystem();
    final FakeProcessManager process = FakeProcessManager()
      ..fallbackProcessResult = io.ProcessResult(123, 1, 'test resulted in a 502: 502 Bad Gateway\n', '');
    final List<String> log = <String>[];
    final FlutterGoldenFileComparator comparator = await FlutterLocalFileComparator.fromLocalFileComparator(
      localFileComparator: LocalFileComparator(Uri.parse('/test'), pathStyle: path.Style.posix),
      platform: FakePlatform(
        environment: <String, String>{
          'FLUTTER_ROOT': _kFlutterRoot,
        },
        operatingSystem: 'macos',
      ),
      fs: fs,
      process: process,
      httpClient: ThrowingHttpClient(),
      log: log.add,
    );
    expect(
      await comparator.compare(
        Uint8List.fromList(_kTestPngBytes),
        Uri.parse('flutter.golden_test.1.png'),
      ),
      isTrue,
    );
    expect(log, <String>[
      'Auto-passing "pkg.flutter.golden_test.1.png" test, ignoring network error when contacting Skia.'
    ]);
  });
}

@immutable
class RunInvocation {
  const RunInvocation(this.command, this.workingDirectory);

  final List<String> command;
  final String? workingDirectory;

  @override
  int get hashCode => Object.hash(Object.hashAll(command), workingDirectory);

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
  Map<RunInvocation, io.ProcessResult> processResults = <RunInvocation, io.ProcessResult>{};

  /// Used if [processResults] does not contain a matching invocation.
  io.ProcessResult? fallbackProcessResult;

  final List<String?> workingDirectories = <String?>[];

  @override
  Future<io.ProcessResult> run(
    List<Object> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stdoutEncoding,
    Encoding? stderrEncoding,
  }) async {
    workingDirectories.add(workingDirectory);
    final io.ProcessResult? result = processResults[RunInvocation(command.cast<String>(), workingDirectory)];
    if (result == null && fallbackProcessResult == null) {
      fail('ProcessManager.run was called with $command ($workingDirectory) unexpectedly - $processResults.');
    }
    return result ?? fallbackProcessResult!;
  }
}

// See also dev/automated_tests/flutter_test/flutter_gold_test.dart
class FakeSkiaGoldClient extends Fake implements SkiaGoldClient {
  Map<String, String> expectationForTestValues = <String, String>{};
  Exception? getExpectationForTestThrowable;

  @override
  Future<String> getExpectationForTest(String testName) async {
    await null; // force this to be async
    if (getExpectationForTestThrowable != null) {
      throw getExpectationForTestThrowable!;
    }
    return expectationForTestValues[testName] ?? '';
  }

  @override
  Future<void> auth() async {
    await null; // force this to be async
  }

  final List<String> testNames = <String>[];

  int initCalls = 0;

  @override
  Future<void> imgtestInit() async {
    await null; // force this to be async
    initCalls += 1;
  }

  @override
  Future<bool> imgtestAdd(String testName, File goldenFile) async {
    await null; // force this to be async
    testNames.add(testName);
    return true;
  }

  int tryInitCalls = 0;

  @override
  Future<void> tryjobInit() async {
    await null; // force this to be async
    tryInitCalls += 1;
  }

  @override
  Future<bool> tryjobAdd(String testName, File goldenFile) async {
    await null; // force this to be async
    return true;
  }

  Map<String, List<int>> imageBytesValues = <String, List<int>>{};

  @override
  Future<List<int>> getImageBytes(String imageHash) async {
    await null; // force this to be async
    return imageBytesValues[imageHash]!;
  }

  Map<String, String> cleanTestNameValues = <String, String>{};

  @override
  String cleanTestName(String fileName) => cleanTestNameValues[fileName] ?? '';
}

class FakeLocalFileComparator extends Fake implements LocalFileComparator {
  @override
  late Uri basedir;
}

class ThrowingHttpClient extends Fake implements io.HttpClient {
  @override
  Future<io.HttpClientRequest> getUrl(Uri url) async {
    throw const io.SocketException('test error');
  }
}

class FakeHttpClient extends Fake implements io.HttpClient {
  late Uri lastUri;
  late FakeHttpClientRequest request;

  @override
  Future<io.HttpClientRequest> getUrl(Uri url) async {
    lastUri = url;
    return request;
  }
}

class FakeHttpClientRequest extends Fake implements io.HttpClientRequest {
  late FakeHttpImageResponse response;

  @override
  Future<io.HttpClientResponse> close() async {
    return response;
  }
}

class FakeHttpImageResponse extends Fake implements io.HttpClientResponse {
  FakeHttpImageResponse(this.response);

  final List<List<int>> response;

  @override
  Future<void> forEach(void Function(List<int> element) action) async {
    response.forEach(action);
  }
}

class LoggingProcessManager extends Fake implements ProcessManager {
  LoggingProcessManager(this.log);

  final List<String> log;

  @override
  Future<io.ProcessResult> run(List<Object> command, {
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding? stderrEncoding,
    Encoding? stdoutEncoding,
    String? workingDirectory,
  }) async {
    log.add(command.join(' '));
    return io.ProcessResult(0, 0, '200', '');
  }
}
