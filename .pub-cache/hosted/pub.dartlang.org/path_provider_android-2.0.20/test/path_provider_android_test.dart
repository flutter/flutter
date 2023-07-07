// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_android/messages.g.dart' as messages;
import 'package:path_provider_android/path_provider_android.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'messages_test.g.dart';

const String kTemporaryPath = 'temporaryPath';
const String kApplicationSupportPath = 'applicationSupportPath';
const String kLibraryPath = 'libraryPath';
const String kApplicationDocumentsPath = 'applicationDocumentsPath';
const String kExternalCachePaths = 'externalCachePaths';
const String kExternalStoragePaths = 'externalStoragePaths';
const String kDownloadsPath = 'downloadsPath';

class _Api implements TestPathProviderApi {
  @override
  String? getApplicationDocumentsPath() => kApplicationDocumentsPath;

  @override
  String? getApplicationSupportPath() => kApplicationSupportPath;

  @override
  List<String?> getExternalCachePaths() => <String>[kExternalCachePaths];

  @override
  String? getExternalStoragePath() => kExternalStoragePaths;

  @override
  List<String?> getExternalStoragePaths(messages.StorageDirectory directory) =>
      <String>[kExternalStoragePaths];

  @override
  String? getTemporaryPath() => kTemporaryPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PathProviderAndroid', () {
    late PathProviderAndroid pathProvider;

    setUp(() async {
      pathProvider = PathProviderAndroid();
      TestPathProviderApi.setup(_Api());
    });

    test('getTemporaryPath', () async {
      final String? path = await pathProvider.getTemporaryPath();
      expect(path, kTemporaryPath);
    });

    test('getApplicationSupportPath', () async {
      final String? path = await pathProvider.getApplicationSupportPath();
      expect(path, kApplicationSupportPath);
    });

    test('getLibraryPath fails', () async {
      try {
        await pathProvider.getLibraryPath();
        fail('should throw UnsupportedError');
      } catch (e) {
        expect(e, isUnsupportedError);
      }
    });

    test('getApplicationDocumentsPath', () async {
      final String? path = await pathProvider.getApplicationDocumentsPath();
      expect(path, kApplicationDocumentsPath);
    });

    test('getExternalCachePaths succeeds', () async {
      final List<String>? result = await pathProvider.getExternalCachePaths();
      expect(result!.length, 1);
      expect(result.first, kExternalCachePaths);
    });

    for (final StorageDirectory? type in <StorageDirectory?>[
      ...StorageDirectory.values
    ]) {
      test('getExternalStoragePaths (type: $type) android succeeds', () async {
        final List<String>? result =
            await pathProvider.getExternalStoragePaths(type: type);
        expect(result!.length, 1);
        expect(result.first, kExternalStoragePaths);
      });
    } // end of for-loop

    test('getDownloadsPath fails', () async {
      try {
        await pathProvider.getDownloadsPath();
        fail('should throw UnsupportedError');
      } catch (e) {
        expect(e, isUnsupportedError);
      }
    });
  });
}
