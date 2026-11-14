// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:code_assets/code_assets.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/isolated/native_assets/ios/native_assets.dart';
import 'package:flutter_tools/src/isolated/native_assets/macos/native_assets.dart';

import '../../src/common.dart';

void main() {
  for (final (
        String platform,
        String key,
        int minimum,
        AppleVersion Function(Map<String, String>) resolve,
      )
      in <(String, String, int, AppleVersion Function(Map<String, String>))>[
        ('iOS', kIosDeploymentTarget, 15, iosDeploymentVersion),
        ('macOS', kMacOSDeploymentTarget, 13, macOSDeploymentVersion),
      ]) {
    for (final value in <String?>[null, '', ' ', '0', '12.9.9']) {
      testWithoutContext('$platform retains its native-assets floor for "$value"', () {
        expect(resolve(<String, String>{key: ?value}), AppleVersion(minimum));
      });
    }
    for (final (String value, AppleVersion expected) in <(String, AppleVersion)>[
      ('17', AppleVersion(17)),
      ('17.2', AppleVersion(17, minor: 2)),
      ('17.2.1', AppleVersion(17, minor: 2, patch: 1)),
      ('17.0.1', AppleVersion(17, patch: 1)),
      (' 17.2.1 ', AppleVersion(17, minor: 2, patch: 1)),
      (
        '2147483647.2147483647.2147483647',
        AppleVersion(2147483647, minor: 2147483647, patch: 2147483647),
      ),
    ]) {
      testWithoutContext('$platform preserves "$value"', () {
        expect(resolve(<String, String>{key: value}), expected);
      });
    }
    for (final value in <String>['invalid', '-1', '16.4beta', '16.4.1.2', '17.2.2147483648']) {
      testWithoutContext('$platform rejects "$value" with an actionable error', () {
        expect(
          () => resolve(<String, String>{key: value}),
          throwsToolExit(message: 'Invalid $platform deployment target "$value"'),
        );
      });
    }
  }
}
