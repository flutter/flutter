// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_ios/path_provider_ios.dart';
import 'messages_test.g.dart';

class _Api implements TestPathProviderApi {
  String? applicationDocumentsPath;
  String? applicationSupportPath;
  String? libraryPath;
  String? temporaryPath;

  @override
  String? getApplicationDocumentsPath() => applicationDocumentsPath;

  @override
  String? getApplicationSupportPath() => applicationSupportPath;

  @override
  String? getLibraryPath() => libraryPath;

  @override
  String? getTemporaryPath() => temporaryPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PathProviderIOS', () {
    late PathProviderIOS pathProvider;
    // These unit tests use the actual filesystem, since an injectable
    // filesystem would add a runtime dependency to the package, so everything
    // is contained to a temporary directory.
    late Directory testRoot;

    late String temporaryPath;
    late String applicationSupportPath;
    late String libraryPath;
    late String applicationDocumentsPath;
    late _Api api;

    setUp(() async {
      pathProvider = PathProviderIOS();

      testRoot = Directory.systemTemp.createTempSync();
      final String basePath = testRoot.path;
      temporaryPath = p.join(basePath, 'temporary', 'path');
      applicationSupportPath =
          p.join(basePath, 'application', 'support', 'path');
      libraryPath = p.join(basePath, 'library', 'path');
      applicationDocumentsPath =
          p.join(basePath, 'application', 'documents', 'path');

      api = _Api();
      api.applicationDocumentsPath = applicationDocumentsPath;
      api.applicationSupportPath = applicationSupportPath;
      api.libraryPath = libraryPath;
      api.temporaryPath = temporaryPath;
      TestPathProviderApi.setup(api);
    });

    tearDown(() {
      testRoot.deleteSync(recursive: true);
    });

    test('getTemporaryPath', () async {
      final String? path = await pathProvider.getTemporaryPath();
      expect(path, temporaryPath);
    });

    test('getApplicationSupportPath', () async {
      final String? path = await pathProvider.getApplicationSupportPath();
      expect(path, applicationSupportPath);
    });

    test('getApplicationSupportPath creates the directory if necessary',
        () async {
      final String? path = await pathProvider.getApplicationSupportPath();
      expect(Directory(path!).existsSync(), isTrue);
    });

    test('getLibraryPath', () async {
      final String? path = await pathProvider.getLibraryPath();
      expect(path, libraryPath);
    });

    test('getApplicationDocumentsPath', () async {
      final String? path = await pathProvider.getApplicationDocumentsPath();
      expect(path, applicationDocumentsPath);
    });

    test('getDownloadsPath throws', () async {
      expect(pathProvider.getDownloadsPath(), throwsA(isUnsupportedError));
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
