// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/src/enums.dart';
import 'package:path_provider_platform_interface/src/method_channel_path_provider.dart';
import 'package:platform/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const String kTemporaryPath = 'temporaryPath';
  const String kApplicationSupportPath = 'applicationSupportPath';
  const String kLibraryPath = 'libraryPath';
  const String kApplicationDocumentsPath = 'applicationDocumentsPath';
  const String kExternalCachePaths = 'externalCachePaths';
  const String kExternalStoragePaths = 'externalStoragePaths';
  const String kDownloadsPath = 'downloadsPath';

  group('$MethodChannelPathProvider', () {
    late MethodChannelPathProvider methodChannelPathProvider;
    final List<MethodCall> log = <MethodCall>[];

    setUp(() async {
      methodChannelPathProvider = MethodChannelPathProvider();

      methodChannelPathProvider.methodChannel
          .setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'getTemporaryDirectory':
            return kTemporaryPath;
          case 'getApplicationSupportDirectory':
            return kApplicationSupportPath;
          case 'getLibraryDirectory':
            return kLibraryPath;
          case 'getApplicationDocumentsDirectory':
            return kApplicationDocumentsPath;
          case 'getExternalStorageDirectories':
            return <String>[kExternalStoragePaths];
          case 'getExternalCacheDirectories':
            return <String>[kExternalCachePaths];
          case 'getDownloadsDirectory':
            return kDownloadsPath;
          default:
            return null;
        }
      });
    });

    setUp(() {
      methodChannelPathProvider.setMockPathProviderPlatform(
          FakePlatform(operatingSystem: 'android'));
    });

    tearDown(() {
      log.clear();
    });

    test('getTemporaryPath', () async {
      final String? path = await methodChannelPathProvider.getTemporaryPath();
      expect(
        log,
        <Matcher>[isMethodCall('getTemporaryDirectory', arguments: null)],
      );
      expect(path, kTemporaryPath);
    });

    test('getApplicationSupportPath', () async {
      final String? path =
          await methodChannelPathProvider.getApplicationSupportPath();
      expect(
        log,
        <Matcher>[
          isMethodCall('getApplicationSupportDirectory', arguments: null)
        ],
      );
      expect(path, kApplicationSupportPath);
    });

    test('getLibraryPath android fails', () async {
      try {
        await methodChannelPathProvider.getLibraryPath();
        fail('should throw UnsupportedError');
      } catch (e) {
        expect(e, isUnsupportedError);
      }
    });

    test('getLibraryPath iOS succeeds', () async {
      methodChannelPathProvider
          .setMockPathProviderPlatform(FakePlatform(operatingSystem: 'ios'));

      final String? path = await methodChannelPathProvider.getLibraryPath();
      expect(
        log,
        <Matcher>[isMethodCall('getLibraryDirectory', arguments: null)],
      );
      expect(path, kLibraryPath);
    });

    test('getLibraryPath macOS succeeds', () async {
      methodChannelPathProvider
          .setMockPathProviderPlatform(FakePlatform(operatingSystem: 'macos'));

      final String? path = await methodChannelPathProvider.getLibraryPath();
      expect(
        log,
        <Matcher>[isMethodCall('getLibraryDirectory', arguments: null)],
      );
      expect(path, kLibraryPath);
    });

    test('getApplicationDocumentsPath', () async {
      final String? path =
          await methodChannelPathProvider.getApplicationDocumentsPath();
      expect(
        log,
        <Matcher>[
          isMethodCall('getApplicationDocumentsDirectory', arguments: null)
        ],
      );
      expect(path, kApplicationDocumentsPath);
    });

    test('getExternalCachePaths android succeeds', () async {
      final List<String>? result =
          await methodChannelPathProvider.getExternalCachePaths();
      expect(
        log,
        <Matcher>[isMethodCall('getExternalCacheDirectories', arguments: null)],
      );
      expect(result!.length, 1);
      expect(result.first, kExternalCachePaths);
    });

    test('getExternalCachePaths non-android fails', () async {
      methodChannelPathProvider
          .setMockPathProviderPlatform(FakePlatform(operatingSystem: 'ios'));

      try {
        await methodChannelPathProvider.getExternalCachePaths();
        fail('should throw UnsupportedError');
      } catch (e) {
        expect(e, isUnsupportedError);
      }
    });

    for (final StorageDirectory? type in <StorageDirectory?>[
      null,
      ...StorageDirectory.values
    ]) {
      test('getExternalStoragePaths (type: $type) android succeeds', () async {
        final List<String>? result =
            await methodChannelPathProvider.getExternalStoragePaths(type: type);
        expect(
          log,
          <Matcher>[
            isMethodCall(
              'getExternalStorageDirectories',
              arguments: <String, dynamic>{'type': type?.index},
            )
          ],
        );

        expect(result!.length, 1);
        expect(result.first, kExternalStoragePaths);
      });

      test('getExternalStoragePaths (type: $type) non-android fails', () async {
        methodChannelPathProvider
            .setMockPathProviderPlatform(FakePlatform(operatingSystem: 'ios'));

        try {
          await methodChannelPathProvider.getExternalStoragePaths();
          fail('should throw UnsupportedError');
        } catch (e) {
          expect(e, isUnsupportedError);
        }
      });
    } // end of for-loop

    test('getDownloadsPath macos succeeds', () async {
      methodChannelPathProvider
          .setMockPathProviderPlatform(FakePlatform(operatingSystem: 'macos'));
      final String? result = await methodChannelPathProvider.getDownloadsPath();
      expect(
        log,
        <Matcher>[isMethodCall('getDownloadsDirectory', arguments: null)],
      );
      expect(result, kDownloadsPath);
    });

    test('getDownloadsPath  non-macos fails', () async {
      methodChannelPathProvider.setMockPathProviderPlatform(
          FakePlatform(operatingSystem: 'android'));
      try {
        await methodChannelPathProvider.getDownloadsPath();
        fail('should throw UnsupportedError');
      } catch (e) {
        expect(e, isUnsupportedError);
      }
    });
  });
}
