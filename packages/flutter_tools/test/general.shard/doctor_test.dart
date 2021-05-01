// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/linux/linux_doctor.dart';
import 'package:flutter_tools/src/web/web_validator.dart';
import 'package:flutter_tools/src/windows/visual_studio_validator.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fakes.dart';

void main() {
  testUsingContext('doctor validators includes linux desktop when features are enabled on linux', () {
    expect(FlutterDoctorValidatorsProvider().validators,
        contains(isA<LinuxDoctorValidator>()));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(
      isLinuxEnabled: true,
    ),
    Platform: () => FakePlatform(operatingSystem: 'linux'),
  });

  testUsingContext('doctor validators includes windows desktop when features are enabled on windows', () {
    expect(FlutterDoctorValidatorsProvider().validators,
        contains(isA<VisualStudioValidator>()));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(
      isWindowsEnabled: true,
    ),
    Platform: () => FakePlatform(operatingSystem: 'windows'),
  });

  testUsingContext('doctor validators does not include linux desktop when features are disabled on linux', () {
    expect(FlutterDoctorValidatorsProvider().validators,
        isNot(contains(isA<LinuxDoctorValidator>())));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(
      isLinuxEnabled: false,
    ),
    Platform: () => FakePlatform(operatingSystem: 'linux'),
  });

  testUsingContext('doctor validators does not include windows desktop when features are disabled on windows', () {
    expect(FlutterDoctorValidatorsProvider().validators,
        isNot(contains(isA<VisualStudioValidator>())));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(
      isWindowsEnabled: false,
    ),
    Platform: () => FakePlatform(operatingSystem: 'windows'),
  });

  testUsingContext('doctor validators includes web when feature is enabled', () {
    expect(FlutterDoctorValidatorsProvider().validators,
        contains(isA<ChromiumValidator>()));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(
      isWebEnabled: true,
    ),
  });

  testUsingContext('doctor validators does not include web when feature is disabled', () {
    expect(FlutterDoctorValidatorsProvider().validators,
        isNot(contains(isA<ChromiumValidator>())));
  }, overrides: <Type, Generator>{
    FeatureFlags: () => TestFeatureFlags(
      isWebEnabled: false,
    ),
  });
}
