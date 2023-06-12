// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show Directory;

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

const String kTemporaryPath = 'temporaryPath';
const String kApplicationSupportPath = 'applicationSupportPath';
const String kDownloadsPath = 'downloadsPath';
const String kLibraryPath = 'libraryPath';
const String kApplicationDocumentsPath = 'applicationDocumentsPath';
const String kExternalCachePath = 'externalCachePath';
const String kExternalStoragePath = 'externalStoragePath';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('PathProvider full implementation', () {
    setUp(() async {
      PathProviderPlatform.instance = FakePathProviderPlatform();
    });

    test('getTemporaryDirectory', () async {
      final Directory result = await getTemporaryDirectory();
      expect(result.path, kTemporaryPath);
    });

    test('getApplicationSupportDirectory', () async {
      final Directory result = await getApplicationSupportDirectory();
      expect(result.path, kApplicationSupportPath);
    });

    test('getLibraryDirectory', () async {
      final Directory result = await getLibraryDirectory();
      expect(result.path, kLibraryPath);
    });

    test('getApplicationDocumentsDirectory', () async {
      final Directory result = await getApplicationDocumentsDirectory();
      expect(result.path, kApplicationDocumentsPath);
    });

    test('getExternalStorageDirectory', () async {
      final Directory? result = await getExternalStorageDirectory();
      expect(result?.path, kExternalStoragePath);
    });

    test('getExternalCacheDirectories', () async {
      final List<Directory>? result = await getExternalCacheDirectories();
      expect(result?.length, 1);
      expect(result?.first.path, kExternalCachePath);
    });

    test('getExternalStorageDirectories', () async {
      final List<Directory>? result = await getExternalStorageDirectories();
      expect(result?.length, 1);
      expect(result?.first.path, kExternalStoragePath);
    });

    test('getDownloadsDirectory', () async {
      final Directory? result = await getDownloadsDirectory();
      expect(result?.path, kDownloadsPath);
    });
  });

  group('PathProvider null implementation', () {
    setUp(() async {
      PathProviderPlatform.instance = AllNullFakePathProviderPlatform();
    });

    test('getTemporaryDirectory throws on null', () async {
      expect(getTemporaryDirectory(),
          throwsA(isA<MissingPlatformDirectoryException>()));
    });

    test('getApplicationSupportDirectory throws on null', () async {
      expect(getApplicationSupportDirectory(),
          throwsA(isA<MissingPlatformDirectoryException>()));
    });

    test('getLibraryDirectory throws on null', () async {
      expect(getLibraryDirectory(),
          throwsA(isA<MissingPlatformDirectoryException>()));
    });

    test('getApplicationDocumentsDirectory throws on null', () async {
      expect(getApplicationDocumentsDirectory(),
          throwsA(isA<MissingPlatformDirectoryException>()));
    });

    test('getExternalStorageDirectory passes null through', () async {
      final Directory? result = await getExternalStorageDirectory();
      expect(result, isNull);
    });

    test('getExternalCacheDirectories passes null through', () async {
      final List<Directory>? result = await getExternalCacheDirectories();
      expect(result, isNull);
    });

    test('getExternalStorageDirectories passes null through', () async {
      final List<Directory>? result = await getExternalStorageDirectories();
      expect(result, isNull);
    });

    test('getDownloadsDirectory passses null through', () async {
      final Directory? result = await getDownloadsDirectory();
      expect(result, isNull);
    });
  });
}

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async {
    return kTemporaryPath;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    return kApplicationSupportPath;
  }

  @override
  Future<String?> getLibraryPath() async {
    return kLibraryPath;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return kApplicationDocumentsPath;
  }

  @override
  Future<String?> getExternalStoragePath() async {
    return kExternalStoragePath;
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    return <String>[kExternalCachePath];
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    return <String>[kExternalStoragePath];
  }

  @override
  Future<String?> getDownloadsPath() async {
    return kDownloadsPath;
  }
}

class AllNullFakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async {
    return null;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    return null;
  }

  @override
  Future<String?> getLibraryPath() async {
    return null;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return null;
  }

  @override
  Future<String?> getExternalStoragePath() async {
    return null;
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    return null;
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    return null;
  }

  @override
  Future<String?> getDownloadsPath() async {
    return null;
  }
}
