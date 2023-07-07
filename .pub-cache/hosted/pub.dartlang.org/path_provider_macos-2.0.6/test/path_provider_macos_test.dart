// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_macos/path_provider_macos.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PathProviderMacOS', () {
    late PathProviderMacOS pathProvider;
    late List<MethodCall> log;
    // These unit tests use the actual filesystem, since an injectable
    // filesystem would add a runtime dependency to the package, so everything
    // is contained to a temporary directory.
    late Directory testRoot;

    late String temporaryPath;
    late String applicationSupportPath;
    late String libraryPath;
    late String applicationDocumentsPath;
    late String downloadsPath;

    setUp(() async {
      pathProvider = PathProviderMacOS();

      testRoot = Directory.systemTemp.createTempSync();
      final String basePath = testRoot.path;
      temporaryPath = p.join(basePath, 'temporary', 'path');
      applicationSupportPath =
          p.join(basePath, 'application', 'support', 'path');
      libraryPath = p.join(basePath, 'library', 'path');
      applicationDocumentsPath =
          p.join(basePath, 'application', 'documents', 'path');
      downloadsPath = p.join(basePath, 'downloads', 'path');

      log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProvider.methodChannel,
              (MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'getTemporaryDirectory':
            return temporaryPath;
          case 'getApplicationSupportDirectory':
            return applicationSupportPath;
          case 'getLibraryDirectory':
            return libraryPath;
          case 'getApplicationDocumentsDirectory':
            return applicationDocumentsPath;
          case 'getDownloadsDirectory':
            return downloadsPath;
          default:
            return null;
        }
      });
    });

    tearDown(() {
      testRoot.deleteSync(recursive: true);
    });

    test('getTemporaryPath', () async {
      final String? path = await pathProvider.getTemporaryPath();
      expect(
        log,
        <Matcher>[isMethodCall('getTemporaryDirectory', arguments: null)],
      );
      expect(path, temporaryPath);
    });

    test('getApplicationSupportPath', () async {
      final String? path = await pathProvider.getApplicationSupportPath();
      expect(
        log,
        <Matcher>[
          isMethodCall('getApplicationSupportDirectory', arguments: null)
        ],
      );
      expect(path, applicationSupportPath);
    });

    test('getApplicationSupportPath creates the directory if necessary',
        () async {
      final String? path = await pathProvider.getApplicationSupportPath();
      expect(Directory(path!).existsSync(), isTrue);
    });

    test('getLibraryPath', () async {
      final String? path = await pathProvider.getLibraryPath();
      expect(
        log,
        <Matcher>[isMethodCall('getLibraryDirectory', arguments: null)],
      );
      expect(path, libraryPath);
    });

    test('getApplicationDocumentsPath', () async {
      final String? path = await pathProvider.getApplicationDocumentsPath();
      expect(
        log,
        <Matcher>[
          isMethodCall('getApplicationDocumentsDirectory', arguments: null)
        ],
      );
      expect(path, applicationDocumentsPath);
    });

    test('getDownloadsPath', () async {
      final String? result = await pathProvider.getDownloadsPath();
      expect(
        log,
        <Matcher>[isMethodCall('getDownloadsDirectory', arguments: null)],
      );
      expect(result, downloadsPath);
    });

    test('getExternalCachePaths throws', () async {
      expect(pathProvider.getExternalCachePaths(), throwsA(isUnsupportedError));
    });

    test('getExternalStoragePath throws', () async {
      expect(
          pathProvider.getExternalStoragePath(), throwsA(isUnsupportedError));
    });

    test('getExternalStoragePaths throws', () async {
      expect(
          pathProvider.getExternalStoragePaths(), throwsA(isUnsupportedError));
    });
  });
}
