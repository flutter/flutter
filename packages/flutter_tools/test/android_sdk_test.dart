// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'src/context.dart';

void main() {
  group('android_sdk AndroidSdk', () {
    Directory sdkDir;

    tearDown(() {
      sdkDir?.deleteSync(recursive: true);
    });

    testUsingContext('parse sdk', () {
      sdkDir = _createSdkDirectory();
      AndroidSdk sdk = new AndroidSdk(sdkDir.path);

      expect(sdk.latestVersion, isNotNull);
      expect(sdk.latestVersion.sdkLevel, 23);
    });

    testUsingContext('parse sdk N', () {
      sdkDir = _createSdkDirectory(withAndroidN: true);
      AndroidSdk sdk = new AndroidSdk(sdkDir.path);

      expect(sdk.latestVersion, isNotNull);
      expect(sdk.latestVersion.sdkLevel, 24);
    });
  });

  group('android_sdk AndroidSdkVersion', () {
    testUsingContext('parse normal', () {
      AndroidSdk sdk = new AndroidSdk('.');
      AndroidSdkVersion ver = new AndroidSdkVersion(sdk,
        platformVersionName: 'android-23', buildToolsVersionName: '23.0.0');
      expect(ver.sdkLevel, 23);
    });

    testUsingContext('parse android n', () {
      AndroidSdk sdk = new AndroidSdk('.');
      AndroidSdkVersion ver = new AndroidSdkVersion(sdk,
        platformVersionName: 'android-N', buildToolsVersionName: '24.0.0');
      expect(ver.sdkLevel, 24);
    });
  });
}

Directory _createSdkDirectory({ bool withAndroidN: false }) {
  Directory dir = fs.systemTempDirectory.createTempSync('android-sdk');

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
  File file = fs.file(path.join(dir.path, filePath));
  file.createSync(recursive: true);
}
