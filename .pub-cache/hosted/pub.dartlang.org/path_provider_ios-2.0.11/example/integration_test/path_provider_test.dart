// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getTemporaryDirectory', (WidgetTester tester) async {
    final PathProviderPlatform provider = PathProviderPlatform.instance;
    final String? result = await provider.getTemporaryPath();
    _verifySampleFile(result, 'temporaryDirectory');
  });

  testWidgets('getApplicationDocumentsDirectory', (WidgetTester tester) async {
    final PathProviderPlatform provider = PathProviderPlatform.instance;
    final String? result = await provider.getApplicationDocumentsPath();
    _verifySampleFile(result, 'applicationDocuments');
  });

  testWidgets('getApplicationSupportDirectory', (WidgetTester tester) async {
    final PathProviderPlatform provider = PathProviderPlatform.instance;
    final String? result = await provider.getApplicationSupportPath();
    _verifySampleFile(result, 'applicationSupport');
  });

  testWidgets('getLibraryDirectory', (WidgetTester tester) async {
    final PathProviderPlatform provider = PathProviderPlatform.instance;
    final String? result = await provider.getLibraryPath();
    _verifySampleFile(result, 'library');
  });

  testWidgets('getExternalStorageDirectory', (WidgetTester tester) async {
    final PathProviderPlatform provider = PathProviderPlatform.instance;
    expect(() => provider.getExternalStoragePath(),
        throwsA(isInstanceOf<UnsupportedError>()));
  });

  testWidgets('getExternalCacheDirectories', (WidgetTester tester) async {
    final PathProviderPlatform provider = PathProviderPlatform.instance;
    expect(() => provider.getExternalCachePaths(),
        throwsA(isInstanceOf<UnsupportedError>()));
  });
}

/// Verify a file called [name] in [directoryPath] by recreating it with test
/// contents when necessary.
void _verifySampleFile(String? directoryPath, String name) {
  expect(directoryPath, isNotNull);
  if (directoryPath == null) {
    return;
  }
  final Directory directory = Directory(directoryPath);
  final File file = File('${directory.path}${Platform.pathSeparator}$name');

  if (file.existsSync()) {
    file.deleteSync();
    expect(file.existsSync(), isFalse);
  }

  file.writeAsStringSync('Hello world!');
  expect(file.readAsStringSync(), 'Hello world!');
  expect(directory.listSync(), isNotEmpty);
  file.deleteSync();
}
