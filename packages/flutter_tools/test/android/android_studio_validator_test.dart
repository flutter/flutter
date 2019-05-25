// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/android/android_studio_validator.dart';
import 'package:flutter_tools/src/base/platform.dart';

import '../src/common.dart';
import '../src/context.dart';

const String home = '/home/me';

Platform linuxPlatform() {
  return FakePlatform.fromPlatform(const LocalPlatform())
    ..operatingSystem = 'linux'
    ..environment = <String, String>{'HOME': home};
}

void main() {
  group('NoAndroidStudioValidator', () {
    testUsingContext('shows Android Studio as "not available" when not available.', () async {
      final NoAndroidStudioValidator validator = NoAndroidStudioValidator();
      expect((await validator.validate()).type, equals(ValidationType.notAvailable));
    }, overrides: <Type, Generator>{
      // Custom home paths are not supported on macOS nor Windows yet,
      // so we force the platform to fake Linux here.
      Platform: () => linuxPlatform(),
    });
  });
}
