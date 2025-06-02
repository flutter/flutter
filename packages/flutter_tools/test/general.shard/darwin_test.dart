// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/darwin/darwin.dart';

import '../src/common.dart';

void main() {
  group('DarwinPlatform', () {
    testWithoutContext('ios deployment target is 13.0', () {
      expect(DarwinPlatform.ios.deploymentTarget().toString(), '13.0');
    });
    testWithoutContext('ios debug artifactName', () {
      expect(DarwinPlatform.ios.artifactName(BuildMode.debug), 'ios');
    });
    testWithoutContext('ios profile artifactName', () {
      expect(DarwinPlatform.ios.artifactName(BuildMode.profile), 'ios-profile');
    });
    testWithoutContext('ios release artifactName', () {
      expect(DarwinPlatform.ios.artifactName(BuildMode.release), 'ios-release');
    });
  });
}
