// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';

import '../src/common.dart';

const String xcodeBackendPath = 'bin/xcode_backend.sh';
const String xcodeBackendErrorHeader = '========================================================================';

// Acceptable $CONFIGURATION/$FLUTTER_BUILD_MODE values should be debug, profile, or release
const Map<String, String> unknownConfiguration = <String, String>{
  'CONFIGURATION': 'Custom',
};

// $FLUTTER_BUILD_MODE will override $CONFIGURATION
const Map<String, String> unknownFlutterBuildMode = <String, String>{
  'FLUTTER_BUILD_MODE': 'Custom',
  'CONFIGURATION': 'Debug',
};

// Can't archive a non-release build.
const Map<String, String> installWithoutRelease = <String, String>{
  'CONFIGURATION': 'Debug',
  'ACTION': 'install',
};

// Can't use a debug engine build with a release build.
const Map<String, String> localEngineDebugBuildModeRelease = <String, String>{
  'SOURCE_ROOT': '../../examples/hello_world',
  'FLUTTER_ROOT': '../..',
  'LOCAL_ENGINE': '/engine/src/out/ios_debug_unopt',
  'CONFIGURATION': 'Release'
};

// Can't use a debug build with a profile engine.
const Map<String, String> localEngineProfileBuildeModeRelease =
    <String, String>{
  'SOURCE_ROOT': '../../examples/hello_world',
  'FLUTTER_ROOT': '../..',
  'LOCAL_ENGINE': '/engine/src/out/ios_profile',
  'CONFIGURATION': 'Debug',
  'FLUTTER_BUILD_MODE': 'Debug',
};

void main() {
  Future<void> expectXcodeBackendFails(Map<String, String> environment) async {
    final ProcessResult result = await Process.run(
      xcodeBackendPath,
      <String>['build'],
      environment: environment,
    );
    expect(result.stderr, startsWith(xcodeBackendErrorHeader));
    expect(result.exitCode, isNot(0));
  }

  test('Xcode backend fails for on unsupported configuration combinations', () async {
    await expectXcodeBackendFails(unknownConfiguration);
    await expectXcodeBackendFails(unknownFlutterBuildMode);

    await expectXcodeBackendFails(installWithoutRelease);

    await expectXcodeBackendFails(localEngineDebugBuildModeRelease);
    await expectXcodeBackendFails(localEngineProfileBuildeModeRelease);
  }, skip: !platform.isMacOS);
}
