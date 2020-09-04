// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';

import '../src/common.dart';

void main() {
  BufferLogger logger;
  setUp(() {
    logger = BufferLogger.test();
  });

  group('Validate build number', () {
    testWithoutContext('CFBundleVersion for iOS', () async {
      String buildName = validatedBuildNumberForPlatform(TargetPlatform.ios, 'xyz', logger);
      expect(buildName, isNull);
      buildName = validatedBuildNumberForPlatform(TargetPlatform.ios, '0.0.1', logger);
      expect(buildName, '0.0.1');
      buildName = validatedBuildNumberForPlatform(TargetPlatform.ios, '123.xyz', logger);
      expect(buildName, '123');
      buildName = validatedBuildNumberForPlatform(TargetPlatform.ios, '123.456.xyz', logger);
      expect(buildName, '123.456');
    });

    testWithoutContext('versionCode for Android', () async {
      String buildName = validatedBuildNumberForPlatform(TargetPlatform.android_arm, '123.abc+-', logger);
      expect(buildName, '123');
      buildName = validatedBuildNumberForPlatform(TargetPlatform.android_arm, 'abc', logger);
      expect(buildName, '1');
    });
  });

  group('Validate build name', () {
    testWithoutContext('CFBundleShortVersionString for iOS', () async {
      String buildName = validatedBuildNameForPlatform(TargetPlatform.ios, 'xyz', logger);
      expect(buildName, isNull);
      buildName = validatedBuildNameForPlatform(TargetPlatform.ios, '0.0.1', logger);
      expect(buildName, '0.0.1');

      buildName = validatedBuildNameForPlatform(TargetPlatform.ios, '123.456.xyz', logger);
      expect(logger.traceText, contains('Invalid build-name'));
      expect(buildName, '123.456.0');

      buildName = validatedBuildNameForPlatform(TargetPlatform.ios, '123.xyz', logger);
      expect(buildName, '123.0.0');
    });

    testWithoutContext('versionName for Android', () async {
      String buildName = validatedBuildNameForPlatform(TargetPlatform.android_arm, '123.abc+-', logger);
      expect(buildName, '123.abc+-');
      buildName = validatedBuildNameForPlatform(TargetPlatform.android_arm, 'abc+-', logger);
      expect(buildName, 'abc+-');
    });

    testWithoutContext('build mode configuration is correct', () {
      expect(BuildMode.debug.isRelease, false);
      expect(BuildMode.debug.isPrecompiled, false);
      expect(BuildMode.debug.isJit, true);

      expect(BuildMode.profile.isRelease, false);
      expect(BuildMode.profile.isPrecompiled, true);
      expect(BuildMode.profile.isJit, false);

      expect(BuildMode.release.isRelease, true);
      expect(BuildMode.release.isPrecompiled, true);
      expect(BuildMode.release.isJit, false);

      expect(BuildMode.jitRelease.isRelease, true);
      expect(BuildMode.jitRelease.isPrecompiled, false);
      expect(BuildMode.jitRelease.isJit, true);

      expect(BuildMode.fromName('debug'), BuildMode.debug);
      expect(BuildMode.fromName('profile'), BuildMode.profile);
      expect(BuildMode.fromName('jit_release'), BuildMode.jitRelease);
      expect(BuildMode.fromName('release'), BuildMode.release);
      expect(() => BuildMode.fromName('foo'), throwsArgumentError);
    });
  });

  testWithoutContext('getNameForTargetPlatform on Darwin arches', () {
    expect(getNameForTargetPlatform(TargetPlatform.ios, darwinArch: DarwinArch.arm64), 'ios-arm64');
    expect(getNameForTargetPlatform(TargetPlatform.ios, darwinArch: DarwinArch.armv7), 'ios-armv7');
    expect(getNameForTargetPlatform(TargetPlatform.ios, darwinArch: DarwinArch.x86_64), 'ios-x86_64');
    expect(getNameForTargetPlatform(TargetPlatform.android), isNot(contains('ios')));
  });

  testWithoutContext('getIOSArchForName on Darwin arches', () {
    expect(getIOSArchForName('armv7'), DarwinArch.armv7);
    expect(getIOSArchForName('arm64'), DarwinArch.arm64);
    expect(getIOSArchForName('arm64e'), DarwinArch.arm64);
    expect(getIOSArchForName('x86_64'), DarwinArch.x86_64);
    expect(() => getIOSArchForName('bogus'), throwsException);
  });

  testWithoutContext('toEnvironmentConfig encoding of standard values', () {
    const BuildInfo buildInfo = BuildInfo(BuildMode.debug, '',
      treeShakeIcons: true,
      trackWidgetCreation: true,
      dartDefines: <String>['foo=2', 'bar=2'],
      dartObfuscation: true,
      splitDebugInfoPath: 'foo/',
      extraFrontEndOptions: <String>['--enable-experiment=non-nullable', 'bar'],
      extraGenSnapshotOptions: <String>['--enable-experiment=non-nullable', 'fizz'],
      bundleSkSLPath: 'foo/bar/baz.sksl.json',
      packagesPath: 'foo/.packages',
      codeSizeDirectory: 'foo/code-size',
    );

    expect(buildInfo.toEnvironmentConfig(), <String, String>{
      'TREE_SHAKE_ICONS': 'true',
      'TRACK_WIDGET_CREATION': 'true',
      'DART_DEFINES': 'foo%3D2,bar%3D2',
      'DART_OBFUSCATION': 'true',
      'SPLIT_DEBUG_INFO': 'foo/',
      'EXTRA_FRONT_END_OPTIONS': '--enable-experiment%3Dnon-nullable,bar',
      'EXTRA_GEN_SNAPSHOT_OPTIONS': '--enable-experiment%3Dnon-nullable,fizz',
      'BUNDLE_SKSL_PATH': 'foo/bar/baz.sksl.json',
      'PACKAGE_CONFIG': 'foo/.packages',
      'CODE_SIZE_DIRECTORY': 'foo/code-size',
    });
  });

  testWithoutContext('encodeDartDefines encodes define values with URI encode compnents', () {
    expect(encodeDartDefines(<String>['"hello"']), '%22hello%22');
    expect(encodeDartDefines(<String>['https://www.google.com']), 'https%3A%2F%2Fwww.google.com');
    expect(encodeDartDefines(<String>['2,3,4', '5']), '2%2C3%2C4,5');
    expect(encodeDartDefines(<String>['true', 'false', 'flase']), 'true,false,flase');
    expect(encodeDartDefines(<String>['1232,456', '2']), '1232%2C456,2');
  });

  testWithoutContext('decodeDartDefines decodes URI encoded dart defines', () {
    expect(decodeDartDefines(<String, String>{
      kDartDefines: '%22hello%22'
    }, kDartDefines), <String>['"hello"']);
    expect(decodeDartDefines(<String, String>{
      kDartDefines: 'https%3A%2F%2Fwww.google.com'
    }, kDartDefines), <String>['https://www.google.com']);
    expect(decodeDartDefines(<String, String>{
      kDartDefines: '2%2C3%2C4,5'
    }, kDartDefines), <String>['2,3,4', '5']);
    expect(decodeDartDefines(<String, String>{
      kDartDefines: 'true,false,flase'
    }, kDartDefines), <String>['true', 'false', 'flase']);
    expect(decodeDartDefines(<String, String>{
      kDartDefines: '1232%2C456,2'
    }, kDartDefines), <String>['1232,456', '2']);
  });
}
