// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_macos/messages.g.dart';
import 'package:path_provider_macos/path_provider_macos.dart';

import 'messages_test.g.dart';
import 'path_provider_macos_test.mocks.dart';

@GenerateMocks(<Type>[TestPathProviderApi])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PathProviderMacOS', () {
    late PathProviderMacOS pathProvider;
    late MockTestPathProviderApi mockApi;
    // These unit tests use the actual filesystem, since an injectable
    // filesystem would add a runtime dependency to the package, so everything
    // is contained to a temporary directory.
    late Directory testRoot;

    setUp(() async {
      testRoot = Directory.systemTemp.createTempSync();
      pathProvider = PathProviderMacOS();
      mockApi = MockTestPathProviderApi();
      TestPathProviderApi.setup(mockApi);
    });

    tearDown(() {
      testRoot.deleteSync(recursive: true);
    });

    test('getTemporaryPath', () async {
      final String temporaryPath = p.join(testRoot.path, 'temporary', 'path');
      when(mockApi.getDirectoryPath(DirectoryType.temp))
          .thenReturn(temporaryPath);

      final String? path = await pathProvider.getTemporaryPath();

      verify(mockApi.getDirectoryPath(DirectoryType.temp));
      expect(path, temporaryPath);
    });

    test('getApplicationSupportPath', () async {
      final String applicationSupportPath =
          p.join(testRoot.path, 'application', 'support', 'path');
      when(mockApi.getDirectoryPath(DirectoryType.applicationSupport))
          .thenReturn(applicationSupportPath);

      final String? path = await pathProvider.getApplicationSupportPath();

      verify(mockApi.getDirectoryPath(DirectoryType.applicationSupport));
      expect(path, applicationSupportPath);
    });

    test('getApplicationSupportPath creates the directory if necessary',
        () async {
      final String applicationSupportPath =
          p.join(testRoot.path, 'application', 'support', 'path');
      when(mockApi.getDirectoryPath(DirectoryType.applicationSupport))
          .thenReturn(applicationSupportPath);

      final String? path = await pathProvider.getApplicationSupportPath();

      expect(Directory(path!).existsSync(), isTrue);
    });

    test('getLibraryPath', () async {
      final String libraryPath = p.join(testRoot.path, 'library', 'path');
      when(mockApi.getDirectoryPath(DirectoryType.library))
          .thenReturn(libraryPath);

      final String? path = await pathProvider.getLibraryPath();

      verify(mockApi.getDirectoryPath(DirectoryType.library));
      expect(path, libraryPath);
    });

    test('getApplicationDocumentsPath', () async {
      final String applicationDocumentsPath =
          p.join(testRoot.path, 'application', 'documents', 'path');
      when(mockApi.getDirectoryPath(DirectoryType.applicationDocuments))
          .thenReturn(applicationDocumentsPath);

      final String? path = await pathProvider.getApplicationDocumentsPath();

      verify(mockApi.getDirectoryPath(DirectoryType.applicationDocuments));
      expect(path, applicationDocumentsPath);
    });

    test('getDownloadsPath', () async {
      final String downloadsPath = p.join(testRoot.path, 'downloads', 'path');
      when(mockApi.getDirectoryPath(DirectoryType.downloads))
          .thenReturn(downloadsPath);

      final String? result = await pathProvider.getDownloadsPath();

      verify(mockApi.getDirectoryPath(DirectoryType.downloads));
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
