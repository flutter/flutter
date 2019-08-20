// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:flutter_tools/src/build_info.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  setUpAll(() { });

  group('Validate build number', () {
    setUp(() async { });

    testUsingContext('CFBundleVersion for iOS', () async {
      String buildName = validatedBuildNumberForPlatform(TargetPlatform.ios, 'xyz');
      expect(buildName, '0');
      buildName = validatedBuildNumberForPlatform(TargetPlatform.ios, '0.0.1');
      expect(buildName, '0.0.1');
      buildName = validatedBuildNumberForPlatform(TargetPlatform.ios, '123.xyz');
      expect(buildName, '123');
      buildName = validatedBuildNumberForPlatform(TargetPlatform.ios, '123.456.xyz');
      expect(buildName, '123.456');
    });

    testUsingContext('versionCode for Android', () async {
      String buildName = validatedBuildNumberForPlatform(TargetPlatform.android_arm, '123.abc+-');
      expect(buildName, '123');
      buildName = validatedBuildNumberForPlatform(TargetPlatform.android_arm, 'abc');
      expect(buildName, '1');
    });
  });

  group('Validate build name', () {
    setUp(() async { });

    testUsingContext('CFBundleShortVersionString for iOS', () async {
      String buildName = validatedBuildNameForPlatform(TargetPlatform.ios, 'xyz');
      expect(buildName, '0.0.0');
      buildName = validatedBuildNameForPlatform(TargetPlatform.ios, '0.0.1');
      expect(buildName, '0.0.1');
      buildName = validatedBuildNameForPlatform(TargetPlatform.ios, '123.456.xyz');
      expect(buildName, '123.456.0');
      buildName = validatedBuildNameForPlatform(TargetPlatform.ios, '123.xyz');
      expect(buildName, '123.0.0');
    });

    testUsingContext('versionName for Android', () async {
      String buildName = validatedBuildNameForPlatform(TargetPlatform.android_arm, '123.abc+-');
      expect(buildName, '123.abc+-');
      buildName = validatedBuildNameForPlatform(TargetPlatform.android_arm, 'abc+-');
      expect(buildName, 'abc+-');
    });
  });
}
