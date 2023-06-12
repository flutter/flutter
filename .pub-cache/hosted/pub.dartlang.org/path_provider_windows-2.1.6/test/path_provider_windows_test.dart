// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:ffi';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path_provider_windows/path_provider_windows.dart';
import 'package:path_provider_windows/src/path_provider_windows_real.dart'
    show languageEn, encodingCP1252, encodingUnicode;

// A fake VersionInfoQuerier that just returns preset responses.
class FakeVersionInfoQuerier implements VersionInfoQuerier {
  FakeVersionInfoQuerier(
    this.responses, {
    this.language = languageEn,
    this.encoding = encodingUnicode,
  });

  final String language;
  final String encoding;
  final Map<String, String> responses;

  String? getStringValue(
    Pointer<Uint8>? versionInfo,
    String key, {
    required String language,
    required String encoding,
  }) {
    if (language == this.language && encoding == this.encoding) {
      return responses[key];
    } else {
      return null;
    }
  }
}

void main() {
  test('registered instance', () {
    PathProviderWindows.registerWith();
    expect(PathProviderPlatform.instance, isA<PathProviderWindows>());
  });

  test('getTemporaryPath', () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    expect(await pathProvider.getTemporaryPath(), contains(r'C:\'));
  }, skip: !Platform.isWindows);

  test('getApplicationSupportPath with no version info', () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    pathProvider.versionInfoQuerier =
        FakeVersionInfoQuerier(<String, String>{});
    final String? path = await pathProvider.getApplicationSupportPath();
    expect(path, contains(r'C:\'));
    expect(path, contains(r'AppData'));
    // The last path component should be the executable name.
    expect(path, endsWith(r'flutter_tester'));
  }, skip: !Platform.isWindows);

  test('getApplicationSupportPath with full version info in CP1252', () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    pathProvider.versionInfoQuerier = FakeVersionInfoQuerier(<String, String>{
      'CompanyName': 'A Company',
      'ProductName': 'Amazing App',
    }, encoding: encodingCP1252);
    final String? path = await pathProvider.getApplicationSupportPath();
    expect(path, isNotNull);
    if (path != null) {
      expect(path, endsWith(r'AppData\Roaming\A Company\Amazing App'));
      expect(Directory(path).existsSync(), isTrue);
    }
  }, skip: !Platform.isWindows);

  test('getApplicationSupportPath with full version info in Unicode', () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    pathProvider.versionInfoQuerier = FakeVersionInfoQuerier(<String, String>{
      'CompanyName': 'A Company',
      'ProductName': 'Amazing App',
    });
    final String? path = await pathProvider.getApplicationSupportPath();
    expect(path, isNotNull);
    if (path != null) {
      expect(path, endsWith(r'AppData\Roaming\A Company\Amazing App'));
      expect(Directory(path).existsSync(), isTrue);
    }
  }, skip: !Platform.isWindows);

  test(
      'getApplicationSupportPath with full version info in Unsupported Encoding',
      () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    pathProvider.versionInfoQuerier = FakeVersionInfoQuerier(<String, String>{
      'CompanyName': 'A Company',
      'ProductName': 'Amazing App',
    }, language: '0000', encoding: '0000');
    final String? path = await pathProvider.getApplicationSupportPath();
    expect(path, contains(r'C:\'));
    expect(path, contains(r'AppData'));
    // The last path component should be the executable name.
    expect(path, endsWith(r'flutter_tester'));
  }, skip: !Platform.isWindows);

  test('getApplicationSupportPath with missing company', () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    pathProvider.versionInfoQuerier = FakeVersionInfoQuerier(<String, String>{
      'ProductName': 'Amazing App',
    });
    final String? path = await pathProvider.getApplicationSupportPath();
    expect(path, isNotNull);
    if (path != null) {
      expect(path, endsWith(r'AppData\Roaming\Amazing App'));
      expect(Directory(path).existsSync(), isTrue);
    }
  }, skip: !Platform.isWindows);

  test('getApplicationSupportPath with problematic values', () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    pathProvider.versionInfoQuerier = FakeVersionInfoQuerier(<String, String>{
      'CompanyName': r'A <Bad> Company: Name.',
      'ProductName': r'A"/Terrible\|App?*Name',
    });
    final String? path = await pathProvider.getApplicationSupportPath();
    expect(path, isNotNull);
    if (path != null) {
      expect(
          path,
          endsWith(
              r'AppData\Roaming\A _Bad_ Company_ Name\A__Terrible__App__Name'));
      expect(Directory(path).existsSync(), isTrue);
    }
  }, skip: !Platform.isWindows);

  test('getApplicationSupportPath with a completely invalid company', () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    pathProvider.versionInfoQuerier = FakeVersionInfoQuerier(<String, String>{
      'CompanyName': r'..',
      'ProductName': r'Amazing App',
    });
    final String? path = await pathProvider.getApplicationSupportPath();
    expect(path, isNotNull);
    if (path != null) {
      expect(path, endsWith(r'AppData\Roaming\Amazing App'));
      expect(Directory(path).existsSync(), isTrue);
    }
  }, skip: !Platform.isWindows);

  test('getApplicationSupportPath with very long app name', () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    final String truncatedName = 'A' * 255;
    pathProvider.versionInfoQuerier = FakeVersionInfoQuerier(<String, String>{
      'CompanyName': 'A Company',
      'ProductName': truncatedName * 2,
    });
    final String? path = await pathProvider.getApplicationSupportPath();
    expect(path, endsWith('\\$truncatedName'));
    // The directory won't exist, since it's longer than MAXPATH, so don't check
    // that here.
  }, skip: !Platform.isWindows);

  test('getApplicationDocumentsPath', () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    final String? path = await pathProvider.getApplicationDocumentsPath();
    expect(path, contains(r'C:\'));
    expect(path, contains(r'Documents'));
  }, skip: !Platform.isWindows);

  test('getDownloadsPath', () async {
    final PathProviderWindows pathProvider = PathProviderWindows();
    final String? path = await pathProvider.getDownloadsPath();
    expect(path, contains(r'C:\'));
    expect(path, contains(r'Downloads'));
  }, skip: !Platform.isWindows);
}
