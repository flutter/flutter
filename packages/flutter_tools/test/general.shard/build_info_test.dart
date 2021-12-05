// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';

import '../src/common.dart';

void main() {
  late BufferLogger logger;
  setUp(() {
    logger = BufferLogger.test();
  });

  group('Validate build number', () {
    testWithoutContext('CFBundleVersion for iOS', () async {
      String? buildName = validatedBuildNumberForPlatform(TargetPlatform.ios, 'xyz', logger);
      expect(buildName, isNull);
      buildName = validatedBuildNumberForPlatform(TargetPlatform.ios, '0.0.1', logger);
      expect(buildName, '0.0.1');
      buildName = validatedBuildNumberForPlatform(TargetPlatform.ios, '123.xyz', logger);
      expect(buildName, '123');
      buildName = validatedBuildNumberForPlatform(TargetPlatform.ios, '123.456.xyz', logger);
      expect(buildName, '123.456');
    });

    testWithoutContext('versionCode for Android', () async {
      String? buildName = validatedBuildNumberForPlatform(TargetPlatform.android_arm, '123.abc+-', logger);
      expect(buildName, '123');
      buildName = validatedBuildNumberForPlatform(TargetPlatform.android_arm, 'abc', logger);
      expect(buildName, '1');
    });
  });

  group('Validate build name', () {
    testWithoutContext('CFBundleShortVersionString for iOS', () async {
      String? buildName = validatedBuildNameForPlatform(TargetPlatform.ios, 'xyz', logger);
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
      String? buildName = validatedBuildNameForPlatform(TargetPlatform.android_arm, '123.abc+-', logger);
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

  testWithoutContext('toBuildSystemEnvironment encoding of standard values', () {
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
      fileSystemRoots: <String>['test5', 'test6'],
      fileSystemScheme: 'scheme',
    );

    expect(buildInfo.toBuildSystemEnvironment(), <String, String>{
      'BuildMode': 'debug',
      'DartDefines': 'Zm9vPTI=,YmFyPTI=',
      'DartObfuscation': 'true',
      'ExtraFrontEndOptions': '--enable-experiment=non-nullable,bar',
      'ExtraGenSnapshotOptions': '--enable-experiment=non-nullable,fizz',
      'SplitDebugInfo': 'foo/',
      'TrackWidgetCreation': 'true',
      'TreeShakeIcons': 'true',
      'BundleSkSLPath': 'foo/bar/baz.sksl.json',
      'CodeSizeDirectory': 'foo/code-size',
      'FileSystemRoots': 'test5,test6',
      'FileSystemScheme': 'scheme',
    });
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
      // These values are ignored by toEnvironmentConfig
      androidProjectArgs: <String>['foo=bar', 'fizz=bazz']
    );

    expect(buildInfo.toEnvironmentConfig(), <String, String>{
      'TREE_SHAKE_ICONS': 'true',
      'TRACK_WIDGET_CREATION': 'true',
      'DART_DEFINES': 'Zm9vPTI=,YmFyPTI=',
      'DART_OBFUSCATION': 'true',
      'SPLIT_DEBUG_INFO': 'foo/',
      'EXTRA_FRONT_END_OPTIONS': '--enable-experiment=non-nullable,bar',
      'EXTRA_GEN_SNAPSHOT_OPTIONS': '--enable-experiment=non-nullable,fizz',
      'BUNDLE_SKSL_PATH': 'foo/bar/baz.sksl.json',
      'PACKAGE_CONFIG': 'foo/.packages',
      'CODE_SIZE_DIRECTORY': 'foo/code-size',
    });
  });

  testWithoutContext('toGradleConfig encoding of standard values', () {
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
      androidProjectArgs: <String>['foo=bar', 'fizz=bazz']
    );

    expect(buildInfo.toGradleConfig(), <String>[
      '-Pdart-defines=Zm9vPTI=,YmFyPTI=',
      '-Pdart-obfuscation=true',
      '-Pextra-front-end-options=--enable-experiment=non-nullable,bar',
      '-Pextra-gen-snapshot-options=--enable-experiment=non-nullable,fizz',
      '-Psplit-debug-info=foo/',
      '-Ptrack-widget-creation=true',
      '-Ptree-shake-icons=true',
      '-Pbundle-sksl-path=foo/bar/baz.sksl.json',
      '-Pcode-size-directory=foo/code-size',
      '-Pfoo=bar',
      '-Pfizz=bazz'
    ]);
  });

  testWithoutContext('encodeDartDefines encodes define values with base64 encoded components', () {
    expect(encodeDartDefines(<String>['"hello"']), 'ImhlbGxvIg==');
    expect(encodeDartDefines(<String>['https://www.google.com']), 'aHR0cHM6Ly93d3cuZ29vZ2xlLmNvbQ==');
    expect(encodeDartDefines(<String>['2,3,4', '5']), 'MiwzLDQ=,NQ==');
    expect(encodeDartDefines(<String>['true', 'false', 'flase']), 'dHJ1ZQ==,ZmFsc2U=,Zmxhc2U=');
    expect(encodeDartDefines(<String>['1232,456', '2']), 'MTIzMiw0NTY=,Mg==');
  });

  testWithoutContext('decodeDartDefines decodes base64 encoded dart defines', () {
    expect(decodeDartDefines(<String, String>{
      kDartDefines: 'ImhlbGxvIg=='
    }, kDartDefines), <String>['"hello"']);
    expect(decodeDartDefines(<String, String>{
      kDartDefines: 'aHR0cHM6Ly93d3cuZ29vZ2xlLmNvbQ=='
    }, kDartDefines), <String>['https://www.google.com']);
    expect(decodeDartDefines(<String, String>{
      kDartDefines: 'MiwzLDQ=,NQ=='
    }, kDartDefines), <String>['2,3,4', '5']);
    expect(decodeDartDefines(<String, String>{
      kDartDefines: 'dHJ1ZQ==,ZmFsc2U=,Zmxhc2U='
    }, kDartDefines), <String>['true', 'false', 'flase']);
    expect(decodeDartDefines(<String, String>{
      kDartDefines: 'MTIzMiw0NTY=,Mg=='
    }, kDartDefines), <String>['1232,456', '2']);
  });
}
