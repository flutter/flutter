// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:test/test.dart';

import '../src/context.dart';

void main() {
  MemoryFileSystem fs;

  setUp(() {
    fs = new MemoryFileSystem();
  });

  group('android_sdk AndroidSdk', () {
    Directory sdkDir;

    tearDown(() {
      sdkDir?.deleteSync(recursive: true);
    });

    testUsingContext('parse sdk', () {
      sdkDir = _createSdkDirectory();
      final AndroidSdk sdk = new AndroidSdk(sdkDir.path);

      expect(sdk.latestVersion, isNotNull);
      expect(sdk.latestVersion.sdkLevel, 23);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
    });

    testUsingContext('parse sdk N', () {
      sdkDir = _createSdkDirectory(withAndroidN: true);
      final AndroidSdk sdk = new AndroidSdk(sdkDir.path);

      expect(sdk.latestVersion, isNotNull);
      expect(sdk.latestVersion.sdkLevel, 24);
    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
    });
  });
}

Directory _createSdkDirectory({ bool withAndroidN: false }) {
  final Directory dir = fs.systemTempDirectory.createTempSync('android-sdk');

  _createSdkFile(dir, 'platform-tools/adb');

  _createSdkFile(dir, 'build-tools/19.1.0/aapt');
  _createSdkFile(dir, 'build-tools/22.0.1/aapt');
  _createSdkFile(dir, 'build-tools/23.0.2/aapt');
  if (withAndroidN)
    _createSdkFile(dir, 'build-tools/24.0.0-preview/aapt');

  _createSdkFile(dir, 'platforms/android-22/android.jar');
  _createSdkFile(dir, 'platforms/android-23/android.jar');
  if (withAndroidN) {
    _createSdkFile(dir, 'platforms/android-N/android.jar');
    _createSdkFile(dir, 'platforms/android-N/build.prop', contents: _buildProp);
  }

  return dir;
}

void _createSdkFile(Directory dir, String filePath, { String contents }) {
  final File file = dir.childFile(filePath);
  file.createSync(recursive: true);
  if (contents != null) {
    file.writeAsStringSync(contents, flush: true);
  }
}

const String _buildProp = r'''
ro.build.version.incremental=1624448
ro.build.version.sdk=24
ro.build.version.codename=REL
''';
