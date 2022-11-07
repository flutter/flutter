// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// See also dev/automated_tests/flutter_test/flutter_gold_test.dart

import 'dart:io' hide Directory;

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_goldens/src/flutter_goldens_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform/platform.dart';

import 'utils/fakes.dart';

const String _kFlutterRoot = '/flutter';

void main() {
  late MemoryFileSystem fs;
  late FakePlatform platform;

  setUp(() {
    fs = MemoryFileSystem();
    platform = FakePlatform(
      environment: <String, String>{'FLUTTER_ROOT': _kFlutterRoot},
      operatingSystem: 'macos'
    );
    fs.directory(_kFlutterRoot).createSync(recursive: true);
  });

  group('FlutterGoldenFileComparator', () {
    late FlutterGoldenFileComparator comparator;

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

    test('adds namePrefix', () async {
      const String libraryName = 'sidedishes';
      const String namePrefix = 'tomatosalad';
      const String fileName = 'lettuce.png';
      final FakeSkiaGoldClient fakeSkiaClient = FakeSkiaGoldClient();
      final Directory basedir = fs.directory('flutter/test/$libraryName/')
        ..createSync(recursive: true);
      final FlutterGoldenFileComparator comparator = FlutterPostSubmitFileComparator(
        basedir.uri,
        fakeSkiaClient,
        fs: fs,
        platform: platform,
        namePrefix: namePrefix,
      );
      await comparator.compare(
        Uint8List.fromList(kTestPngBytes),
        Uri.parse(fileName),
      );
      expect(fakeSkiaClient.testNames.single, '$namePrefix.$libraryName.$fileName');
    });

    group('Post-Submit', () {
      late FakeSkiaGoldClient fakeSkiaClient;

      setUp(() {
        fakeSkiaClient = FakeSkiaGoldClient();
        final Directory basedir = fs.directory('flutter/test/library/')
          ..createSync(recursive: true);
        comparator = FlutterPostSubmitFileComparator(
          basedir.uri,
          fakeSkiaClient,
          fs: fs,
          platform: platform,
        );
      });

      test('asserts .png format', () async {
        await expectLater(
          () async {
            return comparator.compare(
              Uint8List.fromList(kTestPngBytes),
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
      });

      test('calls init during compare', () {
        expect(fakeSkiaClient.initCalls, 0);
        comparator.compare(
          Uint8List.fromList(kTestPngBytes),
          Uri.parse('flutter.golden_test.1.png'),
        );
        expect(fakeSkiaClient.initCalls, 1);
      });

      test('Passes on flaky flag to client, resets after comparing', () {
        // Not flaky
        expect(comparator.getAndResetFlakyMode(), isFalse);
        comparator.enableFlakyMode();
        expect(fakeSkiaClient.calledWithFlaky, 0);
        comparator.compare(
          Uint8List.fromList(kTestPngBytes),
          Uri.parse('flutter.golden_test.1.png'),
        );
        expect(fakeSkiaClient.calledWithFlaky, 1);
        // Flaky flag was reset during compare.
        expect(comparator.getAndResetFlakyMode(), isFalse);
      });

      test('does not call init in during construction', () {
        expect(fakeSkiaClient.initCalls, 0);
        FlutterPostSubmitFileComparator.fromDefaultComparator(
          platform,
          goldens: fakeSkiaClient,
        );
        expect(fakeSkiaClient.initCalls, 0);
      });

      group('correctly determines testing environment', () {
        test('returns true for configured Luci', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'SWARMING_TASK_ID' : '12345678990',
              'GOLDCTL' : 'goldctl',
            },
            operatingSystem: 'macos',
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
            operatingSystem: 'macos',
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
              'GOLD_TRYJOB' : 'git/ref/12345/head',
            },
            operatingSystem: 'macos',
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
              'GOLD_SERVICE_ACCOUNT': 'service account...',
            },
            operatingSystem: 'macos',
          );
          expect(
            FlutterPostSubmitFileComparator.isAvailableForEnvironment(platform),
            isFalse,
          );
        });
      });
    });

    group('Pre-Submit', () {
      late FakeSkiaGoldClient fakeSkiaClient;

      setUp(() {
        fakeSkiaClient = FakeSkiaGoldClient();
        final Directory basedir = fs.directory('flutter/test/library/')
          ..createSync(recursive: true);
        comparator = FlutterPreSubmitFileComparator(
          basedir.uri,
          fakeSkiaClient,
          fs: fs,
          platform: platform,
        );
      });

      test('asserts .png format', () async {
        await expectLater(
          () async {
            return comparator.compare(
              Uint8List.fromList(kTestPngBytes),
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
      });

      test('calls init during compare', () {
        expect(fakeSkiaClient.tryInitCalls, 0);
        comparator.compare(
          Uint8List.fromList(kTestPngBytes),
          Uri.parse('flutter.golden_test.1.png'),
        );
        expect(fakeSkiaClient.tryInitCalls, 1);
      });

      test('Passes on flaky flag to client, resets after comparing', () {
        // Not flaky
        expect(comparator.getAndResetFlakyMode(), isFalse);
        comparator.enableFlakyMode();
        expect(fakeSkiaClient.calledWithFlaky, 0);
        comparator.compare(
          Uint8List.fromList(kTestPngBytes),
          Uri.parse('flutter.golden_test.1.png'),
        );
        // Init & add were called with flaky set.
        expect(fakeSkiaClient.calledWithFlaky, 1);
        // Flaky flag was reset during compare.
        expect(comparator.getAndResetFlakyMode(), isFalse);
      });

      test('does not call init in during construction', () {
        expect(fakeSkiaClient.tryInitCalls, 0);
        FlutterPostSubmitFileComparator.fromDefaultComparator(
          platform,
          goldens: fakeSkiaClient,
        );
        expect(fakeSkiaClient.tryInitCalls, 0);
      });

      group('correctly determines testing environment', () {
        test('returns true for Luci', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'SWARMING_TASK_ID' : '12345678990',
              'GOLDCTL' : 'goldctl',
              'GOLD_TRYJOB' : 'git/ref/12345/head',
            },
            operatingSystem: 'macos',
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
            operatingSystem: 'macos',
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
              'GOLD_TRYJOB' : 'git/ref/12345/head',
            },
            operatingSystem: 'macos',
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
            operatingSystem: 'macos',
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
              'GOLD_SERVICE_ACCOUNT': 'service account...',
            },
            operatingSystem: 'macos',
          );
          expect(
            FlutterPostSubmitFileComparator.isAvailableForEnvironment(platform),
            isFalse,
          );
        });
      });
    });

    group('Skipping', () {
      test('Resets flaky flag after comparing', () {
        // Not flaky
        expect(comparator.getAndResetFlakyMode(), isFalse);
        // Set flaky
        comparator.enableFlakyMode();
        comparator.compare(
          Uint8List.fromList(kTestPngBytes),
          Uri.parse('flutter.golden_test.1.png'),
        );
        // Flaky flag was reset during compare.
        expect(comparator.getAndResetFlakyMode(), isFalse);
      });

      group('correctly determines testing environment', () {
        test('returns true on Cirrus builds', () {
          platform = FakePlatform(
            environment: <String, String>{
              'FLUTTER_ROOT': _kFlutterRoot,
              'CIRRUS_CI' : 'yep',
            },
            operatingSystem: 'macos',
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
            operatingSystem: 'macos',
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
            operatingSystem: 'macos',
          ),
        );

        const String hash = '55109a4bed52acc780530f7a9aeff6c0';
        fakeSkiaClient.expectationForTestValues['flutter.golden_test.1'] = hash;
        fakeSkiaClient.imageBytesValues[hash] =kTestPngBytes;
        fakeSkiaClient.cleanTestNameValues['library.flutter.golden_test.1.png'] = 'flutter.golden_test.1';
      });

      test('asserts .png format', () async {
        await expectLater(
          () async {
            return comparator.compare(
              Uint8List.fromList(kTestPngBytes),
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
      });

      test('passes when bytes match', () async {
        expect(
          await comparator.compare(
            Uint8List.fromList(kTestPngBytes),
            Uri.parse('flutter.golden_test.1.png'),
          ),
          isTrue,
        );
      });

      test('Passes when flaky', () {
        // Not flaky
        expect(comparator.getAndResetFlakyMode(), isFalse);
        comparator.enableFlakyMode();
        comparator.compare(
          Uint8List.fromList(kTestPngBytes),
          Uri.parse('flutter.golden_test.1.png'),
        );
        // Flaky flag was reset during compare.
        expect(comparator.getAndResetFlakyMode(), isFalse);
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
        // reset property or it will carry on to other tests
        fakeSkiaClient.getExpectationForTestThrowable = null;
      });
    });
  });
}
