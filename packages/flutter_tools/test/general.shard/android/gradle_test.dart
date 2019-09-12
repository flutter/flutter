// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/android/gradle.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';
import '../../src/pubspec_schema.dart';

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
        updateLocalProperties(project: FlutterProject.current());
      } on Exception catch (e) {
        shouldBeToolExit = e;
      }
      // Ensure that we throw a meaningful ToolExit instead of a general crash.
      expect(shouldBeToolExit, isToolExit);
    });

    // Regression test for https://github.com/flutter/flutter/issues/34700
    testUsingContext('Does not return nulls in apk list', () {
      final GradleProject gradleProject = MockGradleProject();
      const AndroidBuildInfo buildInfo = AndroidBuildInfo(BuildInfo.debug);
      when(gradleProject.apkFilesFor(buildInfo)).thenReturn(<String>['not_real']);
      when(gradleProject.apkDirectory).thenReturn(fs.currentDirectory);

      expect(findApkFiles(gradleProject, buildInfo), <File>[]);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
    });

    test('androidXFailureRegex should match lines with likely AndroidX errors', () {
      final List<String> nonMatchingLines = <String>[
        ':app:preBuild UP-TO-DATE',
        'BUILD SUCCESSFUL in 0s',
        '',
      ];
      final List<String> matchingLines = <String>[
        'AAPT: error: resource android:attr/fontVariationSettings not found.',
        'AAPT: error: resource android:attr/ttcIndex not found.',
        'error: package android.support.annotation does not exist',
        'import android.support.annotation.NonNull;',
        'import androidx.annotation.NonNull;',
        'Daemon:  AAPT2 aapt2-3.2.1-4818971-linux Daemon #0',
      ];
      for (String m in nonMatchingLines) {
        expect(androidXFailureRegex.hasMatch(m), isFalse);
      }
      for (String m in matchingLines) {
        expect(androidXFailureRegex.hasMatch(m), isTrue);
      }
    });

    test('androidXPluginWarningRegex should match lines with the AndroidX plugin warnings', () {
      final List<String> nonMatchingLines = <String>[
        ':app:preBuild UP-TO-DATE',
        'BUILD SUCCESSFUL in 0s',
        'Generic plugin AndroidX text',
        '',
      ];
      final List<String> matchingLines = <String>[
        '*********************************************************************************************************************************',
        "WARNING: This version of image_picker will break your Android build if it or its dependencies aren't compatible with AndroidX.",
        'See https://goo.gl/CP92wY for more information on the problem and how to fix it.',
        'This warning prints for all Android build failures. The real root cause of the error may be unrelated.',
      ];
      for (String m in nonMatchingLines) {
        expect(androidXPluginWarningRegex.hasMatch(m), isFalse);
      }
      for (String m in matchingLines) {
        expect(androidXPluginWarningRegex.hasMatch(m), isTrue);
      }
    });

    test('ndkMessageFilter should only match lines without the error message', () {
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

    testUsingContext('Finds app bundle when flavor contains underscores in release mode', () {
      final GradleProject gradleProject = generateFakeAppBundle('foo_barRelease', 'app.aab');
      final File bundle = findBundleFile(gradleProject, const BuildInfo(BuildMode.release, 'foo_bar'));
      expect(bundle, isNotNull);
      expect(bundle.path, '/foo_barRelease/app.aab');
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
    });

    testUsingContext('Finds app bundle when flavor doesn\'t contain underscores in release mode', () {
      final GradleProject gradleProject = generateFakeAppBundle('fooRelease', 'app.aab');
      final File bundle = findBundleFile(gradleProject, const BuildInfo(BuildMode.release, 'foo'));
      expect(bundle, isNotNull);
      expect(bundle.path, '/fooRelease/app.aab');
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
    });

    testUsingContext('Finds app bundle when no flavor is used in release mode', () {
      final GradleProject gradleProject = generateFakeAppBundle('release', 'app.aab');
      final File bundle = findBundleFile(gradleProject, const BuildInfo(BuildMode.release, null));
      expect(bundle, isNotNull);
      expect(bundle.path, '/release/app.aab');
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
    });

    testUsingContext('Finds app bundle when flavor contains underscores in debug mode', () {
      final GradleProject gradleProject = generateFakeAppBundle('foo_barDebug', 'app.aab');
      final File bundle = findBundleFile(gradleProject, const BuildInfo(BuildMode.debug, 'foo_bar'));
      expect(bundle, isNotNull);
      expect(bundle.path, '/foo_barDebug/app.aab');
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
    });

    testUsingContext('Finds app bundle when flavor doesn\'t contain underscores in debug mode', () {
      final GradleProject gradleProject = generateFakeAppBundle('fooDebug', 'app.aab');
      final File bundle = findBundleFile(gradleProject, const BuildInfo(BuildMode.debug, 'foo'));
      expect(bundle, isNotNull);
      expect(bundle.path, '/fooDebug/app.aab');
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
    });

    testUsingContext('Finds app bundle when no flavor is used in debug mode', () {
      final GradleProject gradleProject = generateFakeAppBundle('debug', 'app.aab');
      final File bundle = findBundleFile(gradleProject, const BuildInfo(BuildMode.debug, null));
      expect(bundle, isNotNull);
      expect(bundle.path, '/debug/app.aab');
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
    });

    testUsingContext('Finds app bundle when flavor contains underscores in profile mode', () {
      final GradleProject gradleProject = generateFakeAppBundle('foo_barProfile', 'app.aab');
      final File bundle = findBundleFile(gradleProject, const BuildInfo(BuildMode.profile, 'foo_bar'));
      expect(bundle, isNotNull);
      expect(bundle.path, '/foo_barProfile/app.aab');
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
    });

    testUsingContext('Finds app bundle when flavor doesn\'t contain underscores in profile mode', () {
      final GradleProject gradleProject = generateFakeAppBundle('fooProfile', 'app.aab');
      final File bundle = findBundleFile(gradleProject, const BuildInfo(BuildMode.profile, 'foo'));
      expect(bundle, isNotNull);
      expect(bundle.path, '/fooProfile/app.aab');
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
    });

    testUsingContext('Finds app bundle when no flavor is used in profile mode', () {
      final GradleProject gradleProject = generateFakeAppBundle('profile', 'app.aab');
      final File bundle = findBundleFile(gradleProject, const BuildInfo(BuildMode.profile, null));
      expect(bundle, isNotNull);
      expect(bundle.path, '/profile/app.aab');
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
    });

    testUsingContext('Finds app bundle in release mode - Gradle 3.5', () {
      final GradleProject gradleProject = generateFakeAppBundle('release', 'app-release.aab');
      final File bundle = findBundleFile(gradleProject, const BuildInfo(BuildMode.release, null));
      expect(bundle, isNotNull);
      expect(bundle.path, '/release/app-release.aab');
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
    });

    testUsingContext('Finds app bundle in profile mode - Gradle 3.5', () {
      final GradleProject gradleProject = generateFakeAppBundle('profile', 'app-profile.aab');
      final File bundle = findBundleFile(gradleProject, const BuildInfo(BuildMode.profile, null));
      expect(bundle, isNotNull);
      expect(bundle.path, '/profile/app-profile.aab');
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
    });

    testUsingContext('Finds app bundle in debug mode - Gradle 3.5', () {
      final GradleProject gradleProject = generateFakeAppBundle('debug', 'app-debug.aab');
      final File bundle = findBundleFile(gradleProject, const BuildInfo(BuildMode.debug, null));
      expect(bundle, isNotNull);
      expect(bundle.path, '/debug/app-debug.aab');
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
    });

    testUsingContext('Finds app bundle when flavor contains underscores in release mode - Gradle 3.5', () {
      final GradleProject gradleProject = generateFakeAppBundle('foo_barRelease', 'app-foo_bar-release.aab');
      final File bundle = findBundleFile(gradleProject, const BuildInfo(BuildMode.release, 'foo_bar'));
      expect(bundle, isNotNull);
      expect(bundle.path, '/foo_barRelease/app-foo_bar-release.aab');
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
    });

    testUsingContext('Finds app bundle when flavor contains underscores in profile mode - Gradle 3.5', () {
      final GradleProject gradleProject = generateFakeAppBundle('foo_barProfile', 'app-foo_bar-profile.aab');
      final File bundle = findBundleFile(gradleProject, const BuildInfo(BuildMode.profile, 'foo_bar'));
      expect(bundle, isNotNull);
      expect(bundle.path, '/foo_barProfile/app-foo_bar-profile.aab');
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
    });

    testUsingContext('Finds app bundle when flavor contains underscores in debug mode - Gradle 3.5', () {
      final GradleProject gradleProject = generateFakeAppBundle('foo_barDebug', 'app-foo_bar-debug.aab');
      final File bundle = findBundleFile(gradleProject, const BuildInfo(BuildMode.debug, 'foo_bar'));
      expect(bundle, isNotNull);
      expect(bundle.path, '/foo_barDebug/app-foo_bar-debug.aab');
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
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
      final GradleProject project = GradleProject(<String>['debug', 'profile', 'release'], <String>[], '/some/dir');
      expect(project.apkFilesFor(const AndroidBuildInfo(BuildInfo.debug)).first, 'app-debug.apk');
      expect(project.apkFilesFor(const AndroidBuildInfo(BuildInfo.profile)).first, 'app-profile.apk');
      expect(project.apkFilesFor(const AndroidBuildInfo(BuildInfo.release)).first, 'app-release.apk');
      expect(project.apkFilesFor(const AndroidBuildInfo(BuildInfo(BuildMode.release, 'unknown'))).isEmpty, isTrue);
    });
    test('should provide apk file name for flavored build types', () {
      final GradleProject project = GradleProject(<String>['debug', 'profile', 'release'], <String>['free', 'paid'], '/some/dir');
      expect(project.apkFilesFor(const AndroidBuildInfo(BuildInfo(BuildMode.debug, 'free'))).first, 'app-free-debug.apk');
      expect(project.apkFilesFor(const AndroidBuildInfo(BuildInfo(BuildMode.release, 'paid'))).first, 'app-paid-release.apk');
      expect(project.apkFilesFor(const AndroidBuildInfo(BuildInfo(BuildMode.release, 'unknown'))).isEmpty, isTrue);
    });
    test('should provide apks for default build types and each ABI', () {
      final GradleProject project = GradleProject(<String>['debug', 'profile', 'release'], <String>[], '/some/dir');
      expect(project.apkFilesFor(
        const AndroidBuildInfo(
          BuildInfo.debug,
            splitPerAbi: true,
            targetArchs: <AndroidArch>[
                AndroidArch.armeabi_v7a,
                AndroidArch.arm64_v8a,
              ]
            )
          ),
        <String>[
          'app-armeabi-v7a-debug.apk',
          'app-arm64-v8a-debug.apk',
        ]);

      expect(project.apkFilesFor(
        const AndroidBuildInfo(
          BuildInfo.release,
            splitPerAbi: true,
            targetArchs: <AndroidArch>[
                AndroidArch.armeabi_v7a,
                AndroidArch.arm64_v8a,
              ]
            )
          ),
        <String>[
          'app-armeabi-v7a-release.apk',
          'app-arm64-v8a-release.apk',
        ]);

      expect(project.apkFilesFor(
        const AndroidBuildInfo(
          BuildInfo(BuildMode.release, 'unknown'),
            splitPerAbi: true,
            targetArchs: <AndroidArch>[
                AndroidArch.armeabi_v7a,
                AndroidArch.arm64_v8a,
              ]
            )
          ).isEmpty, isTrue);
    });
    test('should provide apks for each ABI and flavored build types', () {
      final GradleProject project = GradleProject(<String>['debug', 'profile', 'release'], <String>['free', 'paid'], '/some/dir');
      expect(project.apkFilesFor(
        const AndroidBuildInfo(
          BuildInfo(BuildMode.debug, 'free'),
            splitPerAbi: true,
            targetArchs: <AndroidArch>[
                AndroidArch.armeabi_v7a,
                AndroidArch.arm64_v8a,
              ]
            )
          ),
        <String>[
          'app-free-armeabi-v7a-debug.apk',
          'app-free-arm64-v8a-debug.apk',
        ]);

      expect(project.apkFilesFor(
        const AndroidBuildInfo(
          BuildInfo(BuildMode.release, 'paid'),
            splitPerAbi: true,
            targetArchs: <AndroidArch>[
                AndroidArch.armeabi_v7a,
                AndroidArch.arm64_v8a,
              ]
            )
          ),
        <String>[
          'app-paid-armeabi-v7a-release.apk',
          'app-paid-arm64-v8a-release.apk',
        ]);

      expect(project.apkFilesFor(
        const AndroidBuildInfo(
          BuildInfo(BuildMode.release, 'unknown'),
            splitPerAbi: true,
            targetArchs: <AndroidArch>[
                AndroidArch.armeabi_v7a,
                AndroidArch.arm64_v8a,
              ]
            )
          ).isEmpty, isTrue);
    });
    test('should provide assemble task name for default build types', () {
      final GradleProject project = GradleProject(<String>['debug', 'profile', 'release'], <String>[], '/some/dir');
      expect(project.assembleTaskFor(BuildInfo.debug), 'assembleDebug');
      expect(project.assembleTaskFor(BuildInfo.profile), 'assembleProfile');
      expect(project.assembleTaskFor(BuildInfo.release), 'assembleRelease');
      expect(project.assembleTaskFor(const BuildInfo(BuildMode.release, 'unknown')), isNull);
    });
    test('should provide assemble task name for flavored build types', () {
      final GradleProject project = GradleProject(<String>['debug', 'profile', 'release'], <String>['free', 'paid'], '/some/dir');
      expect(project.assembleTaskFor(const BuildInfo(BuildMode.debug, 'free')), 'assembleFreeDebug');
      expect(project.assembleTaskFor(const BuildInfo(BuildMode.release, 'paid')), 'assemblePaidRelease');
      expect(project.assembleTaskFor(const BuildInfo(BuildMode.release, 'unknown')), isNull);
    });
    test('should respect format of the flavored build types', () {
      final GradleProject project = GradleProject(<String>['debug'], <String>['randomFlavor'], '/some/dir');
      expect(project.assembleTaskFor(const BuildInfo(BuildMode.debug, 'randomFlavor')), 'assembleRandomFlavorDebug');
    });
    test('bundle should provide assemble task name for default build types', () {
      final GradleProject project = GradleProject(<String>['debug', 'profile', 'release'], <String>[], '/some/dir');
      expect(project.bundleTaskFor(BuildInfo.debug), 'bundleDebug');
      expect(project.bundleTaskFor(BuildInfo.profile), 'bundleProfile');
      expect(project.bundleTaskFor(BuildInfo.release), 'bundleRelease');
      expect(project.bundleTaskFor(const BuildInfo(BuildMode.release, 'unknown')), isNull);
    });
    test('bundle should provide assemble task name for flavored build types', () {
      final GradleProject project = GradleProject(<String>['debug', 'profile', 'release'], <String>['free', 'paid'], '/some/dir');
      expect(project.bundleTaskFor(const BuildInfo(BuildMode.debug, 'free')), 'bundleFreeDebug');
      expect(project.bundleTaskFor(const BuildInfo(BuildMode.release, 'paid')), 'bundlePaidRelease');
      expect(project.bundleTaskFor(const BuildInfo(BuildMode.release, 'unknown')), isNull);
    });
    test('bundle should respect format of the flavored build types', () {
      final GradleProject project = GradleProject(<String>['debug'], <String>['randomFlavor'], '/some/dir');
      expect(project.bundleTaskFor(const BuildInfo(BuildMode.debug, 'randomFlavor')), 'bundleRandomFlavorDebug');
    });
  });

  group('Config files', () {
    BufferLogger mockLogger;
    Directory tempDir;

    setUp(() {
      mockLogger = BufferLogger();
      tempDir = fs.systemTempDirectory.createTempSync('settings_aar_test.');

    });

    testUsingContext('create settings_aar.gradle when current settings.gradle loads plugins', () {
      const String currentSettingsGradle = '''
include ':app'

def flutterProjectRoot = rootProject.projectDir.parentFile.toPath()

def plugins = new Properties()
def pluginsFile = new File(flutterProjectRoot.toFile(), '.flutter-plugins')
if (pluginsFile.exists()) {
    pluginsFile.withReader('UTF-8') { reader -> plugins.load(reader) }
}

plugins.each { name, path ->
    def pluginDirectory = flutterProjectRoot.resolve(path).resolve('android').toFile()
    include ":\$name"
    project(":\$name").projectDir = pluginDirectory
}
''';

      const String settingsAarFile = '''
include ':app'
''';

      tempDir.childFile('settings.gradle').writeAsStringSync(currentSettingsGradle);

      final String toolGradlePath = fs.path.join(
          fs.path.absolute(Cache.flutterRoot),
          'packages',
          'flutter_tools',
          'gradle');
      fs.directory(toolGradlePath).createSync(recursive: true);
      fs.file(fs.path.join(toolGradlePath, 'deprecated_settings.gradle'))
          .writeAsStringSync(currentSettingsGradle);

      fs.file(fs.path.join(toolGradlePath, 'settings_aar.gradle.tmpl'))
          .writeAsStringSync(settingsAarFile);

      createSettingsAarGradle(tempDir);

      expect(mockLogger.statusText, contains('created successfully'));
      expect(tempDir.childFile('settings_aar.gradle').existsSync(), isTrue);

    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      Logger: () => mockLogger,
    });

    testUsingContext('create settings_aar.gradle when current settings.gradle doesn\'t load plugins', () {
      const String currentSettingsGradle = '''
include ':app'
''';

      const String settingsAarFile = '''
include ':app'
''';

      tempDir.childFile('settings.gradle').writeAsStringSync(currentSettingsGradle);

      final String toolGradlePath = fs.path.join(
          fs.path.absolute(Cache.flutterRoot),
          'packages',
          'flutter_tools',
          'gradle');
      fs.directory(toolGradlePath).createSync(recursive: true);
      fs.file(fs.path.join(toolGradlePath, 'deprecated_settings.gradle'))
          .writeAsStringSync(currentSettingsGradle);

      fs.file(fs.path.join(toolGradlePath, 'settings_aar.gradle.tmpl'))
          .writeAsStringSync(settingsAarFile);

      createSettingsAarGradle(tempDir);

      expect(mockLogger.statusText, contains('created successfully'));
      expect(tempDir.childFile('settings_aar.gradle').existsSync(), isTrue);

    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      Logger: () => mockLogger,
    });
  });

  group('Undefined task', () {
    BufferLogger mockLogger;

    setUp(() {
      mockLogger = BufferLogger();
    });

    testUsingContext('print undefined build type', () {
      final GradleProject project = GradleProject(<String>['debug', 'release'],
          const <String>['free', 'paid'], '/some/dir');

      printUndefinedTask(project, const BuildInfo(BuildMode.profile, 'unknown'));
      expect(mockLogger.errorText, contains('The Gradle project does not define a task suitable for the requested build'));
      expect(mockLogger.errorText, contains('Review the android/app/build.gradle file and ensure it defines a profile build type'));
    }, overrides: <Type, Generator>{
      Logger: () => mockLogger,
    });

    testUsingContext('print no flavors', () {
      final GradleProject project = GradleProject(<String>['debug', 'release'],
          const <String>[], '/some/dir');

      printUndefinedTask(project, const BuildInfo(BuildMode.debug, 'unknown'));
      expect(mockLogger.errorText, contains('The Gradle project does not define a task suitable for the requested build'));
      expect(mockLogger.errorText, contains('The android/app/build.gradle file does not define any custom product flavors'));
      expect(mockLogger.errorText, contains('You cannot use the --flavor option'));
    }, overrides: <Type, Generator>{
      Logger: () => mockLogger,
    });

    testUsingContext('print flavors', () {
      final GradleProject project = GradleProject(<String>['debug', 'release'],
          const <String>['free', 'paid'], '/some/dir');

      printUndefinedTask(project, const BuildInfo(BuildMode.debug, 'unknown'));
      expect(mockLogger.errorText, contains('The Gradle project does not define a task suitable for the requested build'));
      expect(mockLogger.errorText, contains('The android/app/build.gradle file defines product flavors: free, paid'));
    }, overrides: <Type, Generator>{
      Logger: () => mockLogger,
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
      final Iterable<String> result = file.readAsLinesSync()
          .where((String line) => line.startsWith('$key='))
          .map((String line) => line.split('=')[1]);
      return result.isEmpty ? null : result.first;
    }

    Future<void> checkBuildVersion({
      String manifest,
      BuildInfo buildInfo,
      String expectedBuildName,
      String expectedBuildNumber,
    }) async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterFramework,
          platform: TargetPlatform.android_arm, mode: anyNamed('mode'))).thenReturn('engine');
      when(mockArtifacts.engineOutPath).thenReturn(fs.path.join('out', 'android_arm'));

      final File manifestFile = fs.file('path/to/project/pubspec.yaml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync(manifest);

      // write schemaData otherwise pubspec.yaml file can't be loaded
      writeEmptySchemaFile(fs);

      updateLocalProperties(
        project: FlutterProject.fromPath('path/to/project'),
        buildInfo: buildInfo,
        requireAndroidSdk: false,
      );

      final File localPropertiesFile = fs.file('path/to/project/android/local.properties');
      expect(propertyFor('flutter.versionName', localPropertiesFile), expectedBuildName);
      expect(propertyFor('flutter.versionCode', localPropertiesFile), expectedBuildNumber);
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
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildNumber: '3');
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
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildName: '1.0.2', buildNumber: '3');
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
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildName: '1.0.2', buildNumber: '3');
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
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildName: '1.0.2', buildNumber: '3');
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '3',
      );
    });

    testUsingAndroidContext('allow build info to unset build name and number', () async {
      const String manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: const BuildInfo(BuildMode.release, null, buildName: null, buildNumber: null),
        expectedBuildName: null,
        expectedBuildNumber: null,
      );
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: const BuildInfo(BuildMode.release, null, buildName: '1.0.2', buildNumber: '3'),
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '3',
      );
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: const BuildInfo(BuildMode.release, null, buildName: '1.0.3', buildNumber: '4'),
        expectedBuildName: '1.0.3',
        expectedBuildNumber: '4',
      );
      // Values don't get unset.
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: null,
        expectedBuildName: '1.0.3',
        expectedBuildNumber: '4',
      );
      // Values get unset.
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: const BuildInfo(BuildMode.release, null, buildName: null, buildNumber: null),
        expectedBuildName: null,
        expectedBuildNumber: null,
      );
    });
  });

  group('gradle version', () {
    test('should be compatible with the Android plugin version', () {
      // Granular versions.
      expect(getGradleVersionFor('1.0.0'), '2.3');
      expect(getGradleVersionFor('1.0.1'), '2.3');
      expect(getGradleVersionFor('1.0.2'), '2.3');
      expect(getGradleVersionFor('1.0.4'), '2.3');
      expect(getGradleVersionFor('1.0.8'), '2.3');
      expect(getGradleVersionFor('1.1.0'), '2.3');
      expect(getGradleVersionFor('1.1.2'), '2.3');
      expect(getGradleVersionFor('1.1.2'), '2.3');
      expect(getGradleVersionFor('1.1.3'), '2.3');
      // Version Ranges.
      expect(getGradleVersionFor('1.2.0'), '2.9');
      expect(getGradleVersionFor('1.3.1'), '2.9');

      expect(getGradleVersionFor('1.5.0'), '2.2.1');

      expect(getGradleVersionFor('2.0.0'), '2.13');
      expect(getGradleVersionFor('2.1.2'), '2.13');

      expect(getGradleVersionFor('2.1.3'), '2.14.1');
      expect(getGradleVersionFor('2.2.3'), '2.14.1');

      expect(getGradleVersionFor('2.3.0'), '3.3');

      expect(getGradleVersionFor('3.0.0'), '4.1');

      expect(getGradleVersionFor('3.1.0'), '4.4');

      expect(getGradleVersionFor('3.2.0'), '4.6');
      expect(getGradleVersionFor('3.2.1'), '4.6');

      expect(getGradleVersionFor('3.3.0'), '4.10.2');
      expect(getGradleVersionFor('3.3.2'), '4.10.2');

      expect(getGradleVersionFor('3.4.0'), '5.1.1');
      expect(getGradleVersionFor('3.5.0'), '5.1.1');
    });

    test('throws on unsupported versions', () {
      expect(() => getGradleVersionFor('3.6.0'),
          throwsA(predicate<Exception>((Exception e) => e is ToolExit)));
    });
  });

  group('Gradle HTTP failures', () {
    MemoryFileSystem fs;
    Directory tempDir;
    Directory gradleWrapperDirectory;
    MockProcessManager mockProcessManager;
    String gradleBinary;

    setUp(() {
      fs = MemoryFileSystem();
      tempDir = fs.systemTempDirectory.createTempSync('artifacts_test.');
      gradleBinary = platform.isWindows ? 'gradlew.bat' : 'gradlew';
      gradleWrapperDirectory = fs.directory(
        fs.path.join(tempDir.path, 'bin', 'cache', 'artifacts', 'gradle_wrapper'));
      gradleWrapperDirectory.createSync(recursive: true);
      gradleWrapperDirectory
        .childFile(gradleBinary)
        .writeAsStringSync('irrelevant');
      gradleWrapperDirectory
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .createSync(recursive: true);
      gradleWrapperDirectory
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .childFile('gradle-wrapper.jar')
        .writeAsStringSync('irrelevant');

      mockProcessManager = MockProcessManager();
    });

    testUsingContext('throws toolExit if gradle fails while downloading', () async {
      final List<String> cmd = <String>[
        fs.path.join(fs.currentDirectory.path, 'android', gradleBinary),
        '-v',
      ];
      const String errorMessage = '''
Exception in thread "main" java.io.FileNotFoundException: https://downloads.gradle.org/distributions/gradle-4.1.1-all.zip
at sun.net.www.protocol.http.HttpURLConnection.getInputStream0(HttpURLConnection.java:1872)
at sun.net.www.protocol.http.HttpURLConnection.getInputStream(HttpURLConnection.java:1474)
at sun.net.www.protocol.https.HttpsURLConnectionImpl.getInputStream(HttpsURLConnectionImpl.java:254)
at org.gradle.wrapper.Download.downloadInternal(Download.java:58)
at org.gradle.wrapper.Download.download(Download.java:44)
at org.gradle.wrapper.Install\$1.call(Install.java:61)
at org.gradle.wrapper.Install\$1.call(Install.java:48)
at org.gradle.wrapper.ExclusiveFileAccessManager.access(ExclusiveFileAccessManager.java:65)
at org.gradle.wrapper.Install.createDist(Install.java:48)
at org.gradle.wrapper.WrapperExecutor.execute(WrapperExecutor.java:128)
at org.gradle.wrapper.GradleWrapperMain.main(GradleWrapperMain.java:61)''';
      final ProcessException exception = ProcessException(
        gradleBinary,
        <String>['-v'],
        errorMessage,
        1,
      );
      when(mockProcessManager.run(cmd, workingDirectory: anyNamed('workingDirectory'), environment: anyNamed('environment')))
        .thenThrow(exception);
      await expectLater(() async {
        await checkGradleDependencies();
      }, throwsToolExit(message: errorMessage));
    }, overrides: <Type, Generator>{
      Cache: () => Cache(rootOverride: tempDir),
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('throw toolExit if gradle fails downloading with proxy error', () async {
      final List<String> cmd = <String>[
        fs.path.join(fs.currentDirectory.path, 'android', gradleBinary),
        '-v',
      ];
      const String errorMessage = '''
Exception in thread "main" java.io.IOException: Unable to tunnel through proxy. Proxy returns "HTTP/1.1 400 Bad Request"
at sun.net.www.protocol.http.HttpURLConnection.doTunneling(HttpURLConnection.java:2124)
at sun.net.www.protocol.https.AbstractDelegateHttpsURLConnection.connect(AbstractDelegateHttpsURLConnection.java:183)
at sun.net.www.protocol.http.HttpURLConnection.getInputStream0(HttpURLConnection.java:1546)
at sun.net.www.protocol.http.HttpURLConnection.getInputStream(HttpURLConnection.java:1474)
at sun.net.www.protocol.https.HttpsURLConnectionImpl.getInputStream(HttpsURLConnectionImpl.java:254)
at org.gradle.wrapper.Download.downloadInternal(Download.java:58)
at org.gradle.wrapper.Download.download(Download.java:44)
at org.gradle.wrapper.Install\$1.call(Install.java:61)
at org.gradle.wrapper.Install\$1.call(Install.java:48)
at org.gradle.wrapper.ExclusiveFileAccessManager.access(ExclusiveFileAccessManager.java:65)
at org.gradle.wrapper.Install.createDist(Install.java:48)
at org.gradle.wrapper.WrapperExecutor.execute(WrapperExecutor.java:128)
at org.gradle.wrapper.GradleWrapperMain.main(GradleWrapperMain.java:61)''';
      final ProcessException exception = ProcessException(
        gradleBinary,
        <String>['-v'],
        errorMessage,
        1,
      );
      when(mockProcessManager.run(cmd, environment: anyNamed('environment'), workingDirectory: null))
        .thenThrow(exception);
      await expectLater(() async {
        await checkGradleDependencies();
      }, throwsToolExit(message: errorMessage));
    }, overrides: <Type, Generator>{
      Cache: () => Cache(rootOverride: tempDir),
      FileSystem: () => fs,
      ProcessManager: () => mockProcessManager,
    });
  });

  group('injectGradleWrapperIfNeeded', () {
    MemoryFileSystem memoryFileSystem;
    Directory tempDir;
    Directory gradleWrapperDirectory;

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      tempDir = memoryFileSystem.systemTempDirectory.createTempSync('artifacts_test.');
      gradleWrapperDirectory = memoryFileSystem.directory(
          memoryFileSystem.path.join(tempDir.path, 'bin', 'cache', 'artifacts', 'gradle_wrapper'));
      gradleWrapperDirectory.createSync(recursive: true);
      gradleWrapperDirectory
        .childFile('gradlew')
        .writeAsStringSync('irrelevant');
      gradleWrapperDirectory
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .createSync(recursive: true);
      gradleWrapperDirectory
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .childFile('gradle-wrapper.jar')
        .writeAsStringSync('irrelevant');
    });

    testUsingContext('Inject the wrapper when all files are missing', () {
      final Directory sampleAppAndroid = fs.directory('/sample-app/android');
      sampleAppAndroid.createSync(recursive: true);

      injectGradleWrapperIfNeeded(sampleAppAndroid);

      expect(sampleAppAndroid.childFile('gradlew').existsSync(), isTrue);

      expect(sampleAppAndroid
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .childFile('gradle-wrapper.jar')
        .existsSync(), isTrue);

      expect(sampleAppAndroid
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .childFile('gradle-wrapper.properties')
        .existsSync(), isTrue);

      expect(sampleAppAndroid
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .childFile('gradle-wrapper.properties')
        .readAsStringSync(),
            'distributionBase=GRADLE_USER_HOME\n'
            'distributionPath=wrapper/dists\n'
            'zipStoreBase=GRADLE_USER_HOME\n'
            'zipStorePath=wrapper/dists\n'
            'distributionUrl=https\\://services.gradle.org/distributions/gradle-4.10.2-all.zip\n');
    }, overrides: <Type, Generator>{
      Cache: () => Cache(rootOverride: tempDir),
      FileSystem: () => memoryFileSystem,
    });

    testUsingContext('Inject the wrapper when some files are missing', () {
      final Directory sampleAppAndroid = fs.directory('/sample-app/android');
      sampleAppAndroid.createSync(recursive: true);

      // There's an existing gradlew
      sampleAppAndroid.childFile('gradlew').writeAsStringSync('existing gradlew');

      injectGradleWrapperIfNeeded(sampleAppAndroid);

      expect(sampleAppAndroid.childFile('gradlew').existsSync(), isTrue);
      expect(sampleAppAndroid.childFile('gradlew').readAsStringSync(),
          equals('existing gradlew'));

      expect(sampleAppAndroid
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .childFile('gradle-wrapper.jar')
        .existsSync(), isTrue);

      expect(sampleAppAndroid
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .childFile('gradle-wrapper.properties')
        .existsSync(), isTrue);

      expect(sampleAppAndroid
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .childFile('gradle-wrapper.properties')
        .readAsStringSync(),
            'distributionBase=GRADLE_USER_HOME\n'
            'distributionPath=wrapper/dists\n'
            'zipStoreBase=GRADLE_USER_HOME\n'
            'zipStorePath=wrapper/dists\n'
            'distributionUrl=https\\://services.gradle.org/distributions/gradle-4.10.2-all.zip\n');
    }, overrides: <Type, Generator>{
      Cache: () => Cache(rootOverride: tempDir),
      FileSystem: () => memoryFileSystem,
    });

    testUsingContext('Gives executable permission to gradle', () {
      final Directory sampleAppAndroid = fs.directory('/sample-app/android');
      sampleAppAndroid.createSync(recursive: true);

      // Make gradlew in the wrapper executable.
      os.makeExecutable(gradleWrapperDirectory.childFile('gradlew'));

      injectGradleWrapperIfNeeded(sampleAppAndroid);

      final File gradlew = sampleAppAndroid.childFile('gradlew');
      expect(gradlew.existsSync(), isTrue);
      expect(gradlew.statSync().modeString().contains('x'), isTrue);
    }, overrides: <Type, Generator>{
      Cache: () => Cache(rootOverride: tempDir),
      FileSystem: () => memoryFileSystem,
      OperatingSystemUtils: () => OperatingSystemUtils(),
    });
  });

  group('gradle build', () {
    MockAndroidSdk mockAndroidSdk;
    MockAndroidStudio mockAndroidStudio;
    MockLocalEngineArtifacts mockArtifacts;
    MockProcessManager mockProcessManager;
    FakePlatform android;
    FileSystem fs;
    Cache cache;

    setUp(() {
      fs = MemoryFileSystem();
      mockAndroidSdk = MockAndroidSdk();
      mockAndroidStudio = MockAndroidStudio();
      mockArtifacts = MockLocalEngineArtifacts();
      mockProcessManager = MockProcessManager();
      android = fakePlatform('android');

      final Directory tempDir = fs.systemTempDirectory.createTempSync('artifacts_test.');
      cache = Cache(rootOverride: tempDir);

      final Directory gradleWrapperDirectory = tempDir
          .childDirectory('bin')
          .childDirectory('cache')
          .childDirectory('artifacts')
          .childDirectory('gradle_wrapper');
      gradleWrapperDirectory.createSync(recursive: true);
      gradleWrapperDirectory
          .childFile('gradlew')
          .writeAsStringSync('irrelevant');
      gradleWrapperDirectory
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .createSync(recursive: true);
      gradleWrapperDirectory
        .childDirectory('gradle')
        .childDirectory('wrapper')
        .childFile('gradle-wrapper.jar')
        .writeAsStringSync('irrelevant');
    });

    testUsingContext('build aar uses selected local engine', () async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterFramework,
          platform: TargetPlatform.android_arm, mode: anyNamed('mode'))).thenReturn('engine');
      when(mockArtifacts.engineOutPath).thenReturn(fs.path.join('out', 'android_arm'));

      final File manifestFile = fs.file('path/to/project/pubspec.yaml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync('''
        name: test
        version: 1.0.0+1
        dependencies:
          flutter:
            sdk: flutter
        flutter:
          module:
            androidX: false
            androidPackage: com.example.test
            iosBundleIdentifier: com.example.test
        '''
      );

      final File gradlew = fs.file('path/to/project/.android/gradlew');
      gradlew.createSync(recursive: true);

      when(mockProcessManager.run(
          <String> ['/path/to/project/.android/gradlew', '-v'],
          workingDirectory: anyNamed('workingDirectory'),
          environment: anyNamed('environment'),
      )).thenAnswer(
          (_) async => ProcessResult(1, 0, '5.1.1', ''),
      );

      // write schemaData otherwise pubspec.yaml file can't be loaded
      writeEmptySchemaFile(fs);
      fs.currentDirectory = 'path/to/project';

      // Let any process start. Assert after.
      when(mockProcessManager.start(
        any,
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'))
      ).thenAnswer((Invocation invocation) => Future<Process>.value(MockProcess()));
      fs.directory('build/outputs/repo').createSync(recursive: true);

      await buildGradleAar(
        androidBuildInfo: const AndroidBuildInfo(BuildInfo(BuildMode.release, null)),
        project: FlutterProject.current(),
        outputDir: 'build/',
        target: ''
      );

      final List<String> actualGradlewCall = verify(mockProcessManager.start(
        captureAny,
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory')),
      ).captured.single;

      expect(actualGradlewCall, contains('/path/to/project/.android/gradlew'));
      expect(actualGradlewCall, contains('-PlocalEngineOut=out/android_arm'));
    }, overrides: <Type, Generator>{
        AndroidSdk: () => mockAndroidSdk,
        AndroidStudio: () => mockAndroidStudio,
        Artifacts: () => mockArtifacts,
        Cache: () => cache,
        ProcessManager: () => mockProcessManager,
        Platform: () => android,
        FileSystem: () => fs,
      });
  });
}

/// Generates a fake app bundle at the location [directoryName]/[fileName].
GradleProject generateFakeAppBundle(String directoryName, String fileName) {
  final GradleProject gradleProject = MockGradleProject();
  when(gradleProject.bundleDirectory).thenReturn(fs.currentDirectory);

  final Directory aabDirectory = gradleProject.bundleDirectory.childDirectory(directoryName);
  fs.directory(aabDirectory).createSync(recursive: true);
  fs.file(fs.path.join(aabDirectory.path, fileName)).writeAsStringSync('irrelevant');
  return gradleProject;
}

Platform fakePlatform(String name) {
  return FakePlatform.fromPlatform(const LocalPlatform())..operatingSystem = name;
}

class MockLocalEngineArtifacts extends Mock implements LocalEngineArtifacts {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {}
class MockGradleProject extends Mock implements GradleProject {}
class MockitoAndroidSdk extends Mock implements AndroidSdk {}
class MockAndroidStudio extends Mock implements AndroidStudio {}
