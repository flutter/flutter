// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:test/test.dart';

import '../src/context.dart';

void main() {
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
    });

    testUsingContext('parse sdk N', () {
      sdkDir = _createSdkDirectory(withAndroidN: true);
      final AndroidSdk sdk = new AndroidSdk(sdkDir.path);

      expect(sdk.latestVersion, isNotNull);
      expect(sdk.latestVersion.sdkLevel, 24);
    });
  });

  group('android_sdk AndroidSdkVersion', () {
    testUsingContext('parse normal', () {
      final AndroidSdk sdk = new AndroidSdk('.');
      final AndroidSdkVersion ver = new AndroidSdkVersion(sdk,
        platformVersionName: 'android-23', buildToolsVersion: new Version.parse('23.0.0'));
      expect(ver.sdkLevel, 23);
    });

    testUsingContext('parse android n', () {
      final AndroidSdk sdk = new AndroidSdk('.');
      final AndroidSdkVersion ver = new AndroidSdkVersion(sdk,
        platformVersionName: 'android-N', buildToolsVersion: new Version.parse('24.0.0'));
      expect(ver.sdkLevel, 24);
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
  if (withAndroidN)
    _createSdkFile(dir, 'platforms/android-N/android.jar');

  return dir;
}

void _createSdkFile(Directory dir, String filePath) {
  final File file = fs.file(fs.path.join(dir.path, filePath));
  file.createSync(recursive: true);
}
