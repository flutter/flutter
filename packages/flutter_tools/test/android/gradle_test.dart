// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/gradle.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/pubspec_schema.dart';

void main() {
  Cache.flutterRoot = getFlutterRoot();
  group('gradle build', () {
    test('do not crash if there is no Android SDK', () async {
      Exception shouldBeToolExit;
      try {
        // We'd like to always set androidSdk to null and test updateLocalProperties. But that's
        // currently impossible as the test is not hermetic. Luckily, our bots don't have Android
        // SDKs yet so androidSdk should be null by default.
        //
        // This test is written to fail if our bots get Android SDKs in the future: shouldBeToolExit
        // will be null and our expectation would fail. That would remind us to make these tests
        // hermetic before adding Android SDKs to the bots.
        updateLocalProperties(project: await FlutterProject.current());
      } on Exception catch (e) {
        shouldBeToolExit = e;
      }
      // Ensure that we throw a meaningful ToolExit instead of a general crash.
      expect(shouldBeToolExit, isToolExit);
    });

    test('regexp should only match lines without the error message', () {
      final List<String> nonMatchingLines = <String>[
        'NDK is missing a "platforms" directory.',
        'If you are using NDK, verify the ndk.dir is set to a valid NDK directory.  It is currently set to /usr/local/company/home/username/Android/Sdk/ndk-bundle.',
        'If you are not using NDK, unset the NDK variable from ANDROID_NDK_HOME or local.properties to remove this warning.',
      ];
      final List<String> matchingLines = <String>[
        ':app:preBuild UP-TO-DATE',
        'BUILD SUCCESSFUL in 0s',
        '',
        'Something NDK related mentioning ANDROID_NDK_HOME',
      ];
      for (String m in nonMatchingLines) {
        expect(ndkMessageFilter.hasMatch(m), isFalse);
      }
      for (String m in matchingLines) {
        expect(ndkMessageFilter.hasMatch(m), isTrue);
      }
    });
  });

  group('gradle project', () {
    GradleProject projectFrom(String properties, String tasks) => GradleProject.fromAppProperties(properties, tasks);

    test('should extract build directory from app properties', () {
      final GradleProject project = projectFrom('''
someProperty: someValue
buildDir: /Users/some/apps/hello/build/app
someOtherProperty: someOtherValue
      ''', '');
      expect(
        fs.path.normalize(project.apkDirectory.path),
        fs.path.normalize('/Users/some/apps/hello/build/app/outputs/apk'),
      );
    });
    test('should extract default build variants from app properties', () {
      final GradleProject project = projectFrom('buildDir: /Users/some/apps/hello/build/app', '''
someTask
assemble
assembleAndroidTest
assembleDebug
assembleProfile
assembleRelease
someOtherTask
      ''');
      expect(project.buildTypes, <String>['debug', 'profile', 'release']);
      expect(project.productFlavors, isEmpty);
    });
    test('should extract custom build variants from app properties', () {
      final GradleProject project = projectFrom('buildDir: /Users/some/apps/hello/build/app', '''
someTask
assemble
assembleAndroidTest
assembleDebug
assembleFree
assembleFreeAndroidTest
assembleFreeDebug
assembleFreeProfile
assembleFreeRelease
assemblePaid
assemblePaidAndroidTest
assemblePaidDebug
assemblePaidProfile
assemblePaidRelease
assembleProfile
assembleRelease
someOtherTask
      ''');
      expect(project.buildTypes, <String>['debug', 'profile', 'release']);
      expect(project.productFlavors, <String>['free', 'paid']);
    });
    test('should provide apk file name for default build types', () {
      final GradleProject project = GradleProject(<String>['debug', 'profile', 'release'], <String>[], fs.directory('/some/dir'));
      expect(project.apkFileFor(BuildInfo.debug), 'app-debug.apk');
      expect(project.apkFileFor(BuildInfo.profile), 'app-profile.apk');
      expect(project.apkFileFor(BuildInfo.release), 'app-release.apk');
      expect(project.apkFileFor(const BuildInfo(BuildMode.release, 'unknown')), isNull);
    });
    test('should provide apk file name for flavored build types', () {
      final GradleProject project = GradleProject(<String>['debug', 'profile', 'release'], <String>['free', 'paid'], fs.directory('/some/dir'));
      expect(project.apkFileFor(const BuildInfo(BuildMode.debug, 'free')), 'app-free-debug.apk');
      expect(project.apkFileFor(const BuildInfo(BuildMode.release, 'paid')), 'app-paid-release.apk');
      expect(project.apkFileFor(const BuildInfo(BuildMode.release, 'unknown')), isNull);
    });
    test('should provide assemble task name for default build types', () {
      final GradleProject project = GradleProject(<String>['debug', 'profile', 'release'], <String>[], fs.directory('/some/dir'));
      expect(project.assembleTaskFor(BuildInfo.debug), 'assembleDebug');
      expect(project.assembleTaskFor(BuildInfo.profile), 'assembleProfile');
      expect(project.assembleTaskFor(BuildInfo.release), 'assembleRelease');
      expect(project.assembleTaskFor(const BuildInfo(BuildMode.release, 'unknown')), isNull);
    });
    test('should provide assemble task name for flavored build types', () {
      final GradleProject project = GradleProject(<String>['debug', 'profile', 'release'], <String>['free', 'paid'], fs.directory('/some/dir'));
      expect(project.assembleTaskFor(const BuildInfo(BuildMode.debug, 'free')), 'assembleFreeDebug');
      expect(project.assembleTaskFor(const BuildInfo(BuildMode.release, 'paid')), 'assemblePaidRelease');
      expect(project.assembleTaskFor(const BuildInfo(BuildMode.release, 'unknown')), isNull);
    });
    test('should respect format of the flavored build types', () {
      final GradleProject project = GradleProject(<String>['debug'], <String>['randomFlavor'], fs.directory('/some/dir'));
      expect(project.assembleTaskFor(const BuildInfo(BuildMode.debug, 'randomFlavor')), 'assembleRandomFlavorDebug');
    });
  });

  group('Gradle local.properties', () {
    MockLocalEngineArtifacts mockArtifacts;
    MockProcessManager mockProcessManager;
    FakePlatform android;
    FileSystem fs;

    setUp(() {
      fs = MemoryFileSystem();
      mockArtifacts = MockLocalEngineArtifacts();
      mockProcessManager = MockProcessManager();
      android = fakePlatform('android');
    });

    void testUsingAndroidContext(String description, dynamic testMethod()) {
      testUsingContext(description, testMethod, overrides: <Type, Generator>{
        Artifacts: () => mockArtifacts,
        ProcessManager: () => mockProcessManager,
        Platform: () => android,
        FileSystem: () => fs,
      });
    }

    String propertyFor(String key, File file) {
      return file
          .readAsLinesSync()
          .where((String line) => line.startsWith('$key='))
          .map((String line) => line.split('=')[1])
          .first;
    }

    Future<void> checkBuildVersion({
      String manifest,
      BuildInfo buildInfo,
      String expectedBuildName,
      String expectedBuildNumber,
    }) async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterFramework, TargetPlatform.android_arm, any)).thenReturn('engine');
      when(mockArtifacts.engineOutPath).thenReturn(fs.path.join('out', 'android_arm'));

      final File manifestFile = fs.file('path/to/project/pubspec.yaml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync(manifest);

      // write schemaData otherwise pubspec.yaml file can't be loaded
      writeEmptySchemaFile(fs);

      try {
        updateLocalProperties(
          project: await FlutterProject.fromPath('path/to/project'),
          buildInfo: buildInfo,
        );

        final File localPropertiesFile = fs.file('path/to/project/android/local.properties');
        expect(propertyFor('flutter.versionName', localPropertiesFile), expectedBuildName);
        expect(propertyFor('flutter.versionCode', localPropertiesFile), expectedBuildNumber);
      } on Exception {
        // Android SDK not found, skip test
      }
    }

    testUsingAndroidContext('extract build name and number from pubspec.yaml', () async {
      const String manifest = '''
name: test
version: 1.0.0+1
dependencies:
  flutter:
    sdk: flutter
flutter:
''';

      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null);
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.0',
        expectedBuildNumber: '1',
      );
    });

    testUsingAndroidContext('extract build name from pubspec.yaml', () async {
      const String manifest = '''
name: test
version: 1.0.0
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null);
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.0',
        expectedBuildNumber: null,
      );
    });

    testUsingAndroidContext('allow build info to override build name', () async {
      const String manifest = '''
name: test
version: 1.0.0+1
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildName: '1.0.2');
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '1',
      );
    });

    testUsingAndroidContext('allow build info to override build number', () async {
      const String manifest = '''
name: test
version: 1.0.0+1
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildNumber: 3);
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.0',
        expectedBuildNumber: '3',
      );
    });

    testUsingAndroidContext('allow build info to override build name and number', () async {
      const String manifest = '''
name: test
version: 1.0.0+1
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildName: '1.0.2', buildNumber: 3);
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '3',
      );
    });

    testUsingAndroidContext('allow build info to override build name and set number', () async {
      const String manifest = '''
name: test
version: 1.0.0
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildName: '1.0.2', buildNumber: 3);
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '3',
      );
    });

    testUsingAndroidContext('allow build info to set build name and number', () async {
      const String manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildName: '1.0.2', buildNumber: 3);
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '3',
      );
    });
  });
}

Platform fakePlatform(String name) {
  return FakePlatform.fromPlatform(const LocalPlatform())..operatingSystem = name;
}

class MockLocalEngineArtifacts extends Mock implements LocalEngineArtifacts {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {}
