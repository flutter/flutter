// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/darwin/darwin.dart';

import '../src/common.dart';

void main() {
  group('FlutterDarwinPlatform', () {
    group('iOS', () {
      testWithoutContext('deployment target is 13.0', () {
        expect(FlutterDarwinPlatform.ios.deploymentTarget().toString(), '13.0');
      });
      testWithoutContext('debug artifactName', () {
        expect(FlutterDarwinPlatform.ios.artifactName(BuildMode.debug), 'ios');
      });
      testWithoutContext('profile artifactName', () {
        expect(FlutterDarwinPlatform.ios.artifactName(BuildMode.profile), 'ios-profile');
      });
      testWithoutContext('release artifactName', () {
        expect(FlutterDarwinPlatform.ios.artifactName(BuildMode.release), 'ios-release');
      });
      testWithoutContext('fromTargetPlatform', () {
        expect(
          FlutterDarwinPlatform.fromTargetPlatform(TargetPlatform.ios),
          FlutterDarwinPlatform.ios,
        );
        expect(FlutterDarwinPlatform.fromTargetPlatform(TargetPlatform.android), null);
      });
    });
    group('macOS', () {
      testWithoutContext('deployment target is 10.15', () {
        expect(FlutterDarwinPlatform.macos.deploymentTarget().toString(), '10.15');
      });

      testWithoutContext('debug artifactName', () {
        expect(FlutterDarwinPlatform.macos.artifactName(BuildMode.debug), 'darwin-x64');
      });
      testWithoutContext('profile artifactName', () {
        expect(FlutterDarwinPlatform.macos.artifactName(BuildMode.profile), 'darwin-x64-profile');
      });
      testWithoutContext('release artifactName', () {
        expect(FlutterDarwinPlatform.macos.artifactName(BuildMode.release), 'darwin-x64-release');
      });
      testWithoutContext('fromTargetPlatform', () {
        expect(
          FlutterDarwinPlatform.fromTargetPlatform(TargetPlatform.darwin),
          FlutterDarwinPlatform.macos,
        );
        expect(FlutterDarwinPlatform.fromTargetPlatform(TargetPlatform.android), null);
      });
    });
  });
}
