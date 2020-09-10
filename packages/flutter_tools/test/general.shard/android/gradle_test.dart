// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:archive/archive.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/android/gradle.dart';
import 'package:flutter_tools/src/android/gradle_errors.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';
import '../../src/pubspec_schema.dart';

void main() {
  Cache.flutterRoot = getFlutterRoot();

  group('build artifacts', () {
    FileSystem fileSystem;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
    });

    testWithoutContext('getApkDirectory in app projects', () {
      final FlutterProject project = MockFlutterProject();
      final AndroidProject androidProject = MockAndroidProject();
      when(project.android).thenReturn(androidProject);
      when(project.isModule).thenReturn(false);
      when(androidProject.buildDirectory).thenReturn(fileSystem.directory('foo'));

      expect(
        getApkDirectory(project).path,
        equals(fileSystem.path.join('foo', 'app', 'outputs', 'flutter-apk')),
      );
    });

    testWithoutContext('getApkDirectory in module projects', () {
      final FlutterProject project = MockFlutterProject();
      final AndroidProject androidProject = MockAndroidProject();
      when(project.android).thenReturn(androidProject);
      when(project.isModule).thenReturn(true);
      when(androidProject.buildDirectory).thenReturn(fileSystem.directory('foo'));

      expect(
        getApkDirectory(project).path,
        equals(fileSystem.path.join('foo', 'host', 'outputs', 'apk')),
      );
    });

    testWithoutContext('getBundleDirectory in app projects', () {
      final FlutterProject project = MockFlutterProject();
      final AndroidProject androidProject = MockAndroidProject();
      when(project.android).thenReturn(androidProject);
      when(project.isModule).thenReturn(false);
      when(androidProject.buildDirectory).thenReturn(fileSystem.directory('foo'));

      expect(
        getBundleDirectory(project).path,
        equals(fileSystem.path.join('foo', 'app', 'outputs', 'bundle')),
      );
    });

    testWithoutContext('getBundleDirectory in module projects', () {
      final FlutterProject project = MockFlutterProject();
      final AndroidProject androidProject = MockAndroidProject();
      when(project.android).thenReturn(androidProject);
      when(project.isModule).thenReturn(true);
      when(androidProject.buildDirectory).thenReturn(fileSystem.directory('foo'));

      expect(
        getBundleDirectory(project).path,
        equals(fileSystem.path.join('foo', 'host', 'outputs', 'bundle')),
      );
    });

    testWithoutContext('getRepoDirectory', () {
      expect(
        getRepoDirectory(fileSystem.directory('foo')).path,
        equals(fileSystem.path.join('foo','outputs', 'repo')),
      );
    });
  });

  group('gradle tasks', () {
    testWithoutContext('assemble release', () {
      expect(
        getAssembleTaskFor(const BuildInfo(BuildMode.release, null, treeShakeIcons: false)),
        equals('assembleRelease'),
      );
      expect(
        getAssembleTaskFor(const BuildInfo(BuildMode.release, 'flavorFoo', treeShakeIcons: false)),
        equals('assembleFlavorFooRelease'),
      );
    });

    testWithoutContext('assemble debug', () {
      expect(
        getAssembleTaskFor(const BuildInfo(BuildMode.debug, null, treeShakeIcons: false)),
        equals('assembleDebug'),
      );
      expect(
        getAssembleTaskFor(const BuildInfo(BuildMode.debug, 'flavorFoo', treeShakeIcons: false)),
        equals('assembleFlavorFooDebug'),
      );
    });

    testWithoutContext('assemble profile', () {
      expect(
        getAssembleTaskFor(const BuildInfo(BuildMode.profile, null, treeShakeIcons: false)),
        equals('assembleProfile'),
      );
      expect(
        getAssembleTaskFor(const BuildInfo(BuildMode.profile, 'flavorFoo', treeShakeIcons: false)),
        equals('assembleFlavorFooProfile'),
      );
    });
  });

  group('findBundleFile', () {
    FileSystem fileSystem;
    Usage mockUsage;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      mockUsage = MockUsage();
    });

    testWithoutContext('Finds app bundle when flavor contains underscores in release mode', () {
      final FlutterProject project = generateFakeAppBundle('foo_barRelease', 'app.aab', fileSystem);
      final File bundle = findBundleFile(project, const BuildInfo(BuildMode.release, 'foo_bar', treeShakeIcons: false));
      expect(bundle, isNotNull);
      expect(bundle.path, fileSystem.path.join('irrelevant', 'app', 'outputs', 'bundle', 'foo_barRelease', 'app.aab'));
    });

    testWithoutContext("Finds app bundle when flavor doesn't contain underscores in release mode", () {
      final FlutterProject project = generateFakeAppBundle('fooRelease', 'app.aab', fileSystem);
      final File bundle = findBundleFile(project, const BuildInfo(BuildMode.release, 'foo', treeShakeIcons: false));
      expect(bundle, isNotNull);
      expect(bundle.path, fileSystem.path.join('irrelevant', 'app', 'outputs', 'bundle', 'fooRelease', 'app.aab'));
    });

    testWithoutContext('Finds app bundle when no flavor is used in release mode', () {
      final FlutterProject project = generateFakeAppBundle('release', 'app.aab', fileSystem);
      final File bundle = findBundleFile(project, const BuildInfo(BuildMode.release, null, treeShakeIcons: false));
      expect(bundle, isNotNull);
      expect(bundle.path, fileSystem.path.join('irrelevant', 'app', 'outputs', 'bundle', 'release', 'app.aab'));
    });

    testWithoutContext('Finds app bundle when flavor contains underscores in debug mode', () {
      final FlutterProject project = generateFakeAppBundle('foo_barDebug', 'app.aab', fileSystem);
      final File bundle = findBundleFile(project, const BuildInfo(BuildMode.debug, 'foo_bar', treeShakeIcons: false));
      expect(bundle, isNotNull);
      expect(bundle.path, fileSystem.path.join('irrelevant', 'app', 'outputs', 'bundle', 'foo_barDebug', 'app.aab'));
    });

    testWithoutContext("Finds app bundle when flavor doesn't contain underscores in debug mode", () {
      final FlutterProject project = generateFakeAppBundle('fooDebug', 'app.aab', fileSystem);
      final File bundle = findBundleFile(project, const BuildInfo(BuildMode.debug, 'foo', treeShakeIcons: false));
      expect(bundle, isNotNull);
      expect(bundle.path, fileSystem.path.join('irrelevant', 'app', 'outputs', 'bundle', 'fooDebug', 'app.aab'));
    });

    testWithoutContext('Finds app bundle when no flavor is used in debug mode', () {
      final FlutterProject project = generateFakeAppBundle('debug', 'app.aab', fileSystem);
      final File bundle = findBundleFile(project, const BuildInfo(BuildMode.debug, null, treeShakeIcons: false));
      expect(bundle, isNotNull);
      expect(bundle.path, fileSystem.path.join('irrelevant', 'app', 'outputs', 'bundle', 'debug', 'app.aab'));
    });

    testWithoutContext('Finds app bundle when flavor contains underscores in profile mode', () {
      final FlutterProject project = generateFakeAppBundle('foo_barProfile', 'app.aab', fileSystem);
      final File bundle = findBundleFile(project, const BuildInfo(BuildMode.profile, 'foo_bar', treeShakeIcons: false));
      expect(bundle, isNotNull);
      expect(bundle.path, fileSystem.path.join('irrelevant', 'app', 'outputs', 'bundle', 'foo_barProfile', 'app.aab'));
    });

    testWithoutContext("Finds app bundle when flavor doesn't contain underscores in profile mode", () {
      final FlutterProject project = generateFakeAppBundle('fooProfile', 'app.aab', fileSystem);
      final File bundle = findBundleFile(project, const BuildInfo(BuildMode.profile, 'foo', treeShakeIcons: false));
      expect(bundle, isNotNull);
      expect(bundle.path, fileSystem.path.join('irrelevant', 'app', 'outputs', 'bundle', 'fooProfile', 'app.aab'));
    });

    testWithoutContext('Finds app bundle when no flavor is used in profile mode', () {
      final FlutterProject project = generateFakeAppBundle('profile', 'app.aab', fileSystem);
      final File bundle = findBundleFile(project, const BuildInfo(BuildMode.profile, null, treeShakeIcons: false));
      expect(bundle, isNotNull);
      expect(bundle.path, fileSystem.path.join('irrelevant', 'app', 'outputs', 'bundle', 'profile', 'app.aab'));
    });

    testWithoutContext('Finds app bundle in release mode - Gradle 3.5', () {
      final FlutterProject project = generateFakeAppBundle('release', 'app-release.aab', fileSystem);
      final File bundle = findBundleFile(project, const BuildInfo(BuildMode.release, null, treeShakeIcons: false));
      expect(bundle, isNotNull);
      expect(bundle.path, fileSystem.path.join('irrelevant', 'app', 'outputs', 'bundle', 'release', 'app-release.aab'));
    });

    testWithoutContext('Finds app bundle in profile mode - Gradle 3.5', () {
      final FlutterProject project = generateFakeAppBundle('profile', 'app-profile.aab', fileSystem);
      final File bundle = findBundleFile(project, const BuildInfo(BuildMode.profile, null, treeShakeIcons: false));
      expect(bundle, isNotNull);
      expect(bundle.path, fileSystem.path.join('irrelevant', 'app', 'outputs', 'bundle', 'profile', 'app-profile.aab'));
    });

    testWithoutContext('Finds app bundle in debug mode - Gradle 3.5', () {
      final FlutterProject project = generateFakeAppBundle('debug', 'app-debug.aab', fileSystem);
      final File bundle = findBundleFile(project, const BuildInfo(BuildMode.debug, null, treeShakeIcons: false));
      expect(bundle, isNotNull);
      expect(bundle.path, fileSystem.path.join('irrelevant', 'app', 'outputs', 'bundle', 'debug', 'app-debug.aab'));
    });

    testWithoutContext('Finds app bundle when flavor contains underscores in release mode - Gradle 3.5', () {
      final FlutterProject project = generateFakeAppBundle('foo_barRelease', 'app-foo_bar-release.aab', fileSystem);
      final File bundle = findBundleFile(project, const BuildInfo(BuildMode.release, 'foo_bar', treeShakeIcons: false));
      expect(bundle, isNotNull);
      expect(bundle.path, fileSystem.path.join('irrelevant', 'app', 'outputs', 'bundle', 'foo_barRelease', 'app-foo_bar-release.aab'));
    });

    testWithoutContext('Finds app bundle when flavor contains underscores in profile mode - Gradle 3.5', () {
      final FlutterProject project = generateFakeAppBundle('foo_barProfile', 'app-foo_bar-profile.aab', fileSystem);
      final File bundle = findBundleFile(project, const BuildInfo(BuildMode.profile, 'foo_bar', treeShakeIcons: false));
      expect(bundle, isNotNull);
      expect(bundle.path, fileSystem.path.join('irrelevant', 'app', 'outputs', 'bundle', 'foo_barProfile', 'app-foo_bar-profile.aab'));
    });

    testWithoutContext('Finds app bundle when flavor contains underscores in debug mode - Gradle 3.5', () {
      final FlutterProject project = generateFakeAppBundle('foo_barDebug', 'app-foo_bar-debug.aab', fileSystem);
      final File bundle = findBundleFile(project, const BuildInfo(BuildMode.debug, 'foo_bar', treeShakeIcons: false));
      expect(bundle, isNotNull);
      expect(bundle.path, fileSystem.path.join('irrelevant','app', 'outputs', 'bundle', 'foo_barDebug', 'app-foo_bar-debug.aab'));
    });

    testUsingContext('aab not found', () {
      final FlutterProject project = FlutterProject.current();
      expect(
        () {
          findBundleFile(project, const BuildInfo(BuildMode.debug, 'foo_bar', treeShakeIcons: false));
        },
        throwsToolExit(
          message:
            "Gradle build failed to produce an .aab file. It's likely that this file "
            "was generated under ${project.android.buildDirectory.path}, but the tool couldn't find it."
        )
      );
      verify(
        mockUsage.sendEvent(
          any,
          any,
          label: 'gradle-expected-file-not-found',
          parameters: const <String, String> {
            'cd37': 'androidGradlePluginVersion: 5.6.2, fileExtension: .aab',
          },
        ),
      ).called(1);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
      Usage: () => mockUsage,
    });
  });

  group('listApkPaths', () {
    testWithoutContext('Finds APK without flavor in release', () {
      final Iterable<String> apks = listApkPaths(
        const AndroidBuildInfo(BuildInfo(BuildMode.release, '', treeShakeIcons: false)),
      );

      expect(apks, <String>['app-release.apk']);
    });

    testWithoutContext('Finds APK with flavor in release mode', () {
      final Iterable<String> apks = listApkPaths(
        const AndroidBuildInfo(BuildInfo(BuildMode.release, 'flavor1', treeShakeIcons: false)),
      );

      expect(apks, <String>['app-flavor1-release.apk']);
    });

    testWithoutContext('Finds APK with flavor in release mode - AGP v3', () {
      final Iterable<String> apks = listApkPaths(
        const AndroidBuildInfo(BuildInfo(BuildMode.release, 'flavor1', treeShakeIcons: false)),
      );

      expect(apks, <String>['app-flavor1-release.apk']);
    });

    testWithoutContext('Finds APK with split-per-abi', () {
      final Iterable<String> apks = listApkPaths(
        const AndroidBuildInfo(BuildInfo(BuildMode.release, 'flavor1', treeShakeIcons: false), splitPerAbi: true),
      );

      expect(apks, unorderedEquals(<String>[
        'app-armeabi-v7a-flavor1-release.apk',
        'app-arm64-v8a-flavor1-release.apk',
        'app-x86_64-flavor1-release.apk',
      ]));
    });
  });

  group('gradle build', () {
    testUsingContext('do not crash if there is no Android SDK', () async {
      expect(() {
        updateLocalProperties(project: FlutterProject.current());
      }, throwsToolExit(
        message: '$warningMark No Android SDK found. Try setting the ANDROID_SDK_ROOT environment variable.',
      ));
    }, overrides: <Type, Generator>{
      AndroidSdk: () => null,
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
      for (final String m in nonMatchingLines) {
        expect(androidXPluginWarningRegex.hasMatch(m), isFalse);
      }
      for (final String m in matchingLines) {
        expect(androidXPluginWarningRegex.hasMatch(m), isTrue);
      }
    });
  });

  group('Config files', () {
    Directory tempDir;

    setUp(() {
      tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_settings_aar_test.');
    });

    testUsingContext('create settings_aar.gradle when current settings.gradle loads plugins', () {
      const String currentSettingsGradle = r'''
include ':app'

def flutterProjectRoot = rootProject.projectDir.parentFile.toPath()

def plugins = new Properties()
def pluginsFile = new File(flutterProjectRoot.toFile(), '.flutter-plugins')
if (pluginsFile.exists()) {
    pluginsFile.withReader('UTF-8') { reader -> plugins.load(reader) }
}

plugins.each { name, path ->
    def pluginDirectory = flutterProjectRoot.resolve(path).resolve('android').toFile()
    if (pluginDirectory.exists()) {
        include ":$name"
        project(":$name").projectDir = pluginDirectory
    }
}
''';

      const String settingsAarFile = '''
include ':app'
''';

      tempDir.childFile('settings.gradle').writeAsStringSync(currentSettingsGradle);

      final String toolGradlePath = globals.fs.path.join(
          globals.fs.path.absolute(Cache.flutterRoot),
          'packages',
          'flutter_tools',
          'gradle');
      globals.fs.directory(toolGradlePath).createSync(recursive: true);
      globals.fs.file(globals.fs.path.join(toolGradlePath, 'settings.gradle.legacy_versions'))
          .writeAsStringSync(currentSettingsGradle);

      globals.fs.file(globals.fs.path.join(toolGradlePath, 'settings_aar.gradle.tmpl'))
          .writeAsStringSync(settingsAarFile);

      createSettingsAarGradle(tempDir);

      expect(testLogger.statusText, contains('created successfully'));
      expect(tempDir.childFile('settings_aar.gradle').existsSync(), isTrue);

    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext("create settings_aar.gradle when current settings.gradle doesn't load plugins", () {
      const String currentSettingsGradle = '''
include ':app'
''';

      const String settingsAarFile = '''
include ':app'
''';

      tempDir.childFile('settings.gradle').writeAsStringSync(currentSettingsGradle);

      final String toolGradlePath = globals.fs.path.join(
          globals.fs.path.absolute(Cache.flutterRoot),
          'packages',
          'flutter_tools',
          'gradle');
      globals.fs.directory(toolGradlePath).createSync(recursive: true);
      globals.fs.file(globals.fs.path.join(toolGradlePath, 'settings.gradle.legacy_versions'))
          .writeAsStringSync(currentSettingsGradle);

      globals.fs.file(globals.fs.path.join(toolGradlePath, 'settings_aar.gradle.tmpl'))
          .writeAsStringSync(settingsAarFile);

      createSettingsAarGradle(tempDir);

      expect(testLogger.statusText, contains('created successfully'));
      expect(tempDir.childFile('settings_aar.gradle').existsSync(), isTrue);

    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem(),
      ProcessManager: () => FakeProcessManager.any(),
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
        Platform: () => android,
        FileSystem: () => fs,
        ProcessManager: () => mockProcessManager,
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
      when(mockArtifacts.engineOutPath).thenReturn(globals.fs.path.join('out', 'android_arm'));

      final File manifestFile = globals.fs.file('path/to/project/pubspec.yaml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync(manifest);

      // write schemaData otherwise pubspec.yaml file can't be loaded
      writeEmptySchemaFile(fs);

      updateLocalProperties(
        project: FlutterProject.fromPath('path/to/project'),
        buildInfo: buildInfo,
        requireAndroidSdk: false,
      );

      final File localPropertiesFile = globals.fs.file('path/to/project/android/local.properties');
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

      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, treeShakeIcons: false);
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
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, treeShakeIcons: false);
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
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildName: '1.0.2', treeShakeIcons: false);
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
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildNumber: '3', treeShakeIcons: false);
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
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildName: '1.0.2', buildNumber: '3', treeShakeIcons: false);
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
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildName: '1.0.2', buildNumber: '3', treeShakeIcons: false);
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
      const BuildInfo buildInfo = BuildInfo(BuildMode.release, null, buildName: '1.0.2', buildNumber: '3', treeShakeIcons: false);
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
        buildInfo: const BuildInfo(BuildMode.release, null, buildName: null, buildNumber: null, treeShakeIcons: false),
        expectedBuildName: null,
        expectedBuildNumber: null,
      );
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: const BuildInfo(BuildMode.release, null, buildName: '1.0.2', buildNumber: '3', treeShakeIcons: false),
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '3',
      );
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: const BuildInfo(BuildMode.release, null, buildName: '1.0.3', buildNumber: '4', treeShakeIcons: false),
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
        buildInfo: const BuildInfo(BuildMode.release, null, buildName: null, buildNumber: null, treeShakeIcons: false),
        expectedBuildName: null,
        expectedBuildNumber: null,
      );
    });
  });

  group('gradle version', () {
    testWithoutContext('should be compatible with the Android plugin version', () {
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

      expect(getGradleVersionFor('3.4.0'), '5.6.2');
      expect(getGradleVersionFor('3.5.0'), '5.6.2');
    });

    testWithoutContext('throws on unsupported versions', () {
      expect(() => getGradleVersionFor('3.6.0'),
          throwsA(predicate<Exception>((Exception e) => e is ToolExit)));
    });
  });

  group('isAppUsingAndroidX', () {
    FileSystem fs;

    setUp(() {
      fs = MemoryFileSystem();
    });

    testUsingContext('returns true when the project is using AndroidX', () async {
      final Directory androidDirectory = globals.fs.systemTempDirectory.createTempSync('flutter_android.');

      androidDirectory
        .childFile('gradle.properties')
        .writeAsStringSync('android.useAndroidX=true');

      expect(isAppUsingAndroidX(androidDirectory), isTrue);

    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('returns false when the project is not using AndroidX', () async {
      final Directory androidDirectory = globals.fs.systemTempDirectory.createTempSync('flutter_android.');

      androidDirectory
        .childFile('gradle.properties')
        .writeAsStringSync('android.useAndroidX=false');

      expect(isAppUsingAndroidX(androidDirectory), isFalse);

    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext('returns false when gradle.properties does not exist', () async {
      final Directory androidDirectory = globals.fs.systemTempDirectory.createTempSync('flutter_android.');

      expect(isAppUsingAndroidX(androidDirectory), isFalse);

    }, overrides: <Type, Generator>{
      FileSystem: () => fs,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });

  group('buildPluginsAsAar', () {
    FileSystem fs;
    FakeProcessManager fakeProcessManager;
    MockAndroidSdk mockAndroidSdk;

    setUp(() {
      fs = MemoryFileSystem();
      fakeProcessManager = FakeProcessManager.list(<FakeCommand>[]);
      mockAndroidSdk = MockAndroidSdk();
      when(mockAndroidSdk.directory).thenReturn('irrelevant');
    });

    testUsingContext('calls gradle', () async {
      final Directory androidDirectory = globals.fs.directory('android.');
      androidDirectory.createSync();
      androidDirectory
        .childFile('pubspec.yaml')
        .writeAsStringSync('name: irrelevant');

      final Directory plugin1 = globals.fs.directory('plugin1.');
      plugin1
        ..createSync()
        ..childFile('pubspec.yaml')
        .writeAsStringSync('''
name: irrelevant
flutter:
  plugin:
    androidPackage: irrelevant
''');

      plugin1
        .childDirectory('android')
        .childFile('build.gradle')
        .createSync(recursive: true);

      final Directory plugin2 = globals.fs.directory('plugin2.');
      plugin2
        ..createSync()
        ..childFile('pubspec.yaml')
        .writeAsStringSync('''
name: irrelevant
flutter:
  plugin:
    androidPackage: irrelevant
''');

      plugin2
        .childDirectory('android')
        .childFile('build.gradle')
        .createSync(recursive: true);

      androidDirectory
        .childFile('.flutter-plugins')
        .writeAsStringSync('''
plugin1=${plugin1.path}
plugin2=${plugin2.path}
''');
      final Directory buildDirectory = androidDirectory
        .childDirectory('build');
      buildDirectory
        .childDirectory('outputs')
        .childDirectory('repo')
        .createSync(recursive: true);

      final String flutterRoot = globals.fs.path.absolute(Cache.flutterRoot);
      final String initScript = globals.fs.path.join(
        flutterRoot,
        'packages',
        'flutter_tools',
        'gradle',
        'aar_init_script.gradle',
      );

      fakeProcessManager
        ..addCommand(FakeCommand(
          command: <String>[
            'gradlew',
            '-I=$initScript',
            '-Pflutter-root=$flutterRoot',
            '-Poutput-dir=${buildDirectory.path}',
            '-Pis-plugin=true',
            '-PbuildNumber=1.0',
            '-q',
            '-Pfont-subset=true',
            '-Ptarget-platform=android-arm,android-arm64,android-x64',
            'assembleAarRelease',
          ],
          workingDirectory: plugin1.childDirectory('android').path,
        ))
        ..addCommand(FakeCommand(
          command: <String>[
            'gradlew',
            '-I=$initScript',
            '-Pflutter-root=$flutterRoot',
            '-Poutput-dir=${buildDirectory.path}',
            '-Pis-plugin=true',
            '-PbuildNumber=1.0',
            '-q',
            '-Pfont-subset=true',
            '-Ptarget-platform=android-arm,android-arm64,android-x64',
            'assembleAarRelease',
          ],
          workingDirectory: plugin2.childDirectory('android').path,
        ));

      await buildPluginsAsAar(
        FlutterProject.fromPath(androidDirectory.path),
        const AndroidBuildInfo(BuildInfo(
          BuildMode.release,
          '',
          treeShakeIcons: true,
          dartObfuscation: true,
          buildNumber: '2.0'
        )),
        buildDirectory: buildDirectory,
      );
      expect(fakeProcessManager.hasRemainingExpectations, isFalse);
    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      FileSystem: () => fs,
      ProcessManager: () => fakeProcessManager,
      GradleUtils: () => FakeGradleUtils(),
    });

    testUsingContext('skips plugin without a android/build.gradle file', () async {
      final Directory androidDirectory = globals.fs.directory('android.');
      androidDirectory.createSync();
      androidDirectory
        .childFile('pubspec.yaml')
        .writeAsStringSync('name: irrelevant');

      final Directory plugin1 = globals.fs.directory('plugin1.');
      plugin1
        ..createSync()
        ..childFile('pubspec.yaml')
        .writeAsStringSync('''
name: irrelevant
flutter:
  plugin:
    androidPackage: irrelevant
''');

      androidDirectory
        .childFile('.flutter-plugins')
        .writeAsStringSync('''
plugin1=${plugin1.path}
''');
      // Create an empty android directory.
      // https://github.com/flutter/flutter/issues/46898
      plugin1.childDirectory('android').createSync();

      final Directory buildDirectory = androidDirectory.childDirectory('build');

      buildDirectory
        .childDirectory('outputs')
        .childDirectory('repo')
        .createSync(recursive: true);

      await buildPluginsAsAar(
        FlutterProject.fromPath(androidDirectory.path),
        const AndroidBuildInfo(BuildInfo.release),
        buildDirectory: buildDirectory,
      );
      expect(fakeProcessManager.hasRemainingExpectations, isFalse);
    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      FileSystem: () => fs,
      ProcessManager: () => fakeProcessManager,
      GradleUtils: () => FakeGradleUtils(),
    });
  });

  group('gradle build', () {
    Usage mockUsage;
    MockAndroidSdk mockAndroidSdk;
    MockAndroidStudio mockAndroidStudio;
    MockLocalEngineArtifacts mockArtifacts;
    MockProcessManager mockProcessManager;
    FakePlatform android;
    FileSystem fileSystem;
    FileSystemUtils fileSystemUtils;
    Cache cache;

    setUp(() {
      mockUsage = MockUsage();
      fileSystem = MemoryFileSystem();
      fileSystemUtils = MockFileSystemUtils();
      mockAndroidSdk = MockAndroidSdk();
      mockAndroidStudio = MockAndroidStudio();
      mockArtifacts = MockLocalEngineArtifacts();
      mockProcessManager = MockProcessManager();
      android = fakePlatform('android');

      when(mockAndroidSdk.directory).thenReturn('irrelevant');

      final Directory rootDirectory = fileSystem.currentDirectory;
      cache = Cache(
        rootOverride: rootDirectory,
        fileSystem: fileSystem,
      );

      final Directory gradleWrapperDirectory = rootDirectory
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

    testUsingContext('recognizes common errors - tool exit', () async {
      final Process process = createMockProcess(
        exitCode: 1,
        stdout: 'irrelevant\nSome gradle message\nirrelevant',
      );
      when(mockProcessManager.start(any,
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment')))
      .thenAnswer((_) => Future<Process>.value(process));

      fileSystem.directory('android')
        .childFile('build.gradle')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childFile('gradle.properties')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childDirectory('app')
        .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      bool handlerCalled = false;
      await expectLater(() async {
       await buildGradleApp(
          project: FlutterProject.current(),
          androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(
              BuildMode.release,
              null,
              treeShakeIcons: false,
            ),
          ),
          target: 'lib/main.dart',
          isBuildingBundle: false,
          localGradleErrors: <GradleHandledError>[
            GradleHandledError(
              test: (String line) {
                return line.contains('Some gradle message');
              },
              handler: ({
                String line,
                FlutterProject project,
                bool usesAndroidX,
                bool shouldBuildPluginAsAar,
              }) async {
                handlerCalled = true;
                return GradleBuildStatus.exit;
              },
              eventLabel: 'random-event-label',
            ),
          ],
        );
      },
      throwsToolExit(
        message: 'Gradle task assembleRelease failed with exit code 1'
      ));

      expect(handlerCalled, isTrue);

      verify(mockUsage.sendEvent(
        any,
        any,
        label: 'gradle-random-event-label-failure',
        parameters: anyNamed('parameters'),
      )).called(1);

    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      Cache: () => cache,
      Platform: () => android,
      FileSystem: () => fileSystem,
      ProcessManager: () => mockProcessManager,
      Usage: () => mockUsage,
    });

    testUsingContext('recognizes common errors - retry build', () async {
      when(mockProcessManager.start(any,
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment')))
      .thenAnswer((_) {
        final Process process = createMockProcess(
          exitCode: 1,
          stdout: 'irrelevant\nSome gradle message\nirrelevant',
        );
        return Future<Process>.value(process);
      });

      fileSystem.directory('android')
        .childFile('build.gradle')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childFile('gradle.properties')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childDirectory('app')
        .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      int testFnCalled = 0;
      await expectLater(() async {
       await buildGradleApp(
          project: FlutterProject.current(),
          androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(
              BuildMode.release,
              null,
              treeShakeIcons: false,
            ),
          ),
          target: 'lib/main.dart',
          isBuildingBundle: false,
          localGradleErrors: <GradleHandledError>[
            GradleHandledError(
              test: (String line) {
                if (line.contains('Some gradle message')) {
                  testFnCalled++;
                  return true;
                }
                return false;
              },
              handler: ({
                String line,
                FlutterProject project,
                bool usesAndroidX,
                bool shouldBuildPluginAsAar,
              }) async {
                return GradleBuildStatus.retry;
              },
              eventLabel: 'random-event-label',
            ),
          ],
        );
      }, throwsToolExit(
        message: 'Gradle task assembleRelease failed with exit code 1'
      ));

      expect(testFnCalled, equals(2));

      verify(mockUsage.sendEvent(
        any,
        any,
        label: 'gradle-random-event-label-failure',
        parameters: anyNamed('parameters'),
      )).called(1);

    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      Cache: () => cache,
      Platform: () => android,
      FileSystem: () => fileSystem,
      ProcessManager: () => mockProcessManager,
      Usage: () => mockUsage,
    });

    testUsingContext('recognizes process exceptions - tool exit', () async {
      when(mockProcessManager.start(any,
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment')))
      .thenThrow(const ProcessException('', <String>[], 'Some gradle message'));

      fileSystem.directory('android')
        .childFile('build.gradle')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childFile('gradle.properties')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childDirectory('app')
        .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      bool handlerCalled = false;
      await expectLater(() async {
       await buildGradleApp(
          project: FlutterProject.current(),
          androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(
              BuildMode.release,
              null,
              treeShakeIcons: false,
            ),
          ),
          target: 'lib/main.dart',
          isBuildingBundle: false,
          localGradleErrors: <GradleHandledError>[
            GradleHandledError(
              test: (String line) {
                return line.contains('Some gradle message');
              },
              handler: ({
                String line,
                FlutterProject project,
                bool usesAndroidX,
                bool shouldBuildPluginAsAar,
              }) async {
                handlerCalled = true;
                return GradleBuildStatus.exit;
              },
              eventLabel: 'random-event-label',
            ),
          ],
        );
      },
      throwsToolExit(
        message: 'Gradle task assembleRelease failed with exit code 1'
      ));

      expect(handlerCalled, isTrue);

      verify(mockUsage.sendEvent(
        any,
        any,
        label: 'gradle-random-event-label-failure',
        parameters: anyNamed('parameters'),
      )).called(1);

    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      Cache: () => cache,
      Platform: () => android,
      FileSystem: () => fileSystem,
      ProcessManager: () => mockProcessManager,
      Usage: () => mockUsage,
    });

    testUsingContext('rethrows unrecognized ProcessException', () async {
      when(mockProcessManager.start(any,
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment')))
      .thenThrow(const ProcessException('', <String>[], 'Unrecognized'));

      fileSystem.directory('android')
        .childFile('build.gradle')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childFile('gradle.properties')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childDirectory('app')
        .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      await expectLater(() async {
       await buildGradleApp(
          project: FlutterProject.current(),
          androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(
              BuildMode.release,
              null,
              treeShakeIcons: false,
            ),
          ),
          target: 'lib/main.dart',
          isBuildingBundle: false,
          localGradleErrors: const <GradleHandledError>[],
        );
      },
      throwsA(isA<ProcessException>()));

    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      Cache: () => cache,
      Platform: () => android,
      FileSystem: () => fileSystem,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('logs success event after a sucessful retry', () async {
      int testFnCalled = 0;
      when(mockProcessManager.start(any,
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment')))
      .thenAnswer((_) {
        Process process;
        if (testFnCalled == 0) {
          process = createMockProcess(
            exitCode: 1,
            stdout: 'irrelevant\nSome gradle message\nirrelevant',
          );
        } else {
          process = createMockProcess(
            exitCode: 0,
            stdout: 'irrelevant',
          );
        }
        testFnCalled++;
        return Future<Process>.value(process);
      });

      fileSystem.directory('android')
        .childFile('build.gradle')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childFile('gradle.properties')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childDirectory('app')
        .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      fileSystem.directory('build')
        .childDirectory('app')
        .childDirectory('outputs')
        .childDirectory('flutter-apk')
        .childFile('app-release.apk')
        .createSync(recursive: true);

      await buildGradleApp(
        project: FlutterProject.current(),
        androidBuildInfo: const AndroidBuildInfo(
          BuildInfo(
            BuildMode.release,
            null,
            treeShakeIcons: false,
          ),
        ),
        target: 'lib/main.dart',
        isBuildingBundle: false,
        localGradleErrors: <GradleHandledError>[
          GradleHandledError(
            test: (String line) {
              return line.contains('Some gradle message');
            },
            handler: ({
              String line,
              FlutterProject project,
              bool usesAndroidX,
              bool shouldBuildPluginAsAar,
            }) async {
              return GradleBuildStatus.retry;
            },
            eventLabel: 'random-event-label',
          ),
        ],
      );

      verify(mockUsage.sendEvent(
        any,
        any,
        label: 'gradle-random-event-label-success',
        parameters: anyNamed('parameters'),
      )).called(1);
    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      Cache: () => cache,
      FileSystem: () => fileSystem,
      Platform: () => android,
      ProcessManager: () => mockProcessManager,
      Usage: () => mockUsage,
    });

    testUsingContext('performs code size analyis and sends analytics', () async {
      when(mockProcessManager.start(any,
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment')))
      .thenAnswer((_) {
        return Future<Process>.value(createMockProcess(
          exitCode: 0,
          stdout: 'irrelevant',
        ));
      });

      fileSystem.directory('android')
        .childFile('build.gradle')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childFile('gradle.properties')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childDirectory('app')
        .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      final Archive archive = Archive()
        ..addFile(ArchiveFile('AndroidManifest.xml', 100,  List<int>.filled(100, 0)))
        ..addFile(ArchiveFile('META-INF/CERT.RSA', 10,  List<int>.filled(10, 0)))
        ..addFile(ArchiveFile('META-INF/CERT.SF', 10,  List<int>.filled(10, 0)))
        ..addFile(ArchiveFile('lib/arm64-v8a/libapp.so', 50,  List<int>.filled(50, 0)))
        ..addFile(ArchiveFile('lib/arm64-v8a/libflutter.so', 50, List<int>.filled(50, 0)));

      fileSystem.directory('build')
        .childDirectory('app')
        .childDirectory('outputs')
        .childDirectory('flutter-apk')
        .childFile('app-release.apk')
        ..createSync(recursive: true)
        ..writeAsBytesSync(ZipEncoder().encode(archive));

      fileSystem.file('foo/snapshot.arm64-v8a.json')
        ..createSync(recursive: true)
        ..writeAsStringSync(r'''[
{
  "l": "dart:_internal",
  "c": "SubListIterable",
  "n": "[Optimized] skip",
  "s": 2400
}
]''');
      fileSystem.file('foo/trace.arm64-v8a.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('{}');

      await buildGradleApp(
        project: FlutterProject.current(),
        androidBuildInfo: const AndroidBuildInfo(
          BuildInfo(
            BuildMode.release,
            null,
            treeShakeIcons: false,
            codeSizeDirectory: 'foo',
          ),
          targetArchs: <AndroidArch>[AndroidArch.arm64_v8a],
        ),
        target: 'lib/main.dart',
        isBuildingBundle: false,
        localGradleErrors: <GradleHandledError>[],
      );

      verify(mockUsage.sendEvent(
        'code-size-analysis',
        'apk',
      )).called(1);
    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      Cache: () => cache,
      FileSystem: () => fileSystem,
      Platform: () => android,
      ProcessManager: () => mockProcessManager,
      Usage: () => mockUsage,
    });

    testUsingContext('recognizes common errors - retry build with AAR plugins', () async {
      when(mockProcessManager.start(any,
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment')))
      .thenAnswer((_) {
        final Process process = createMockProcess(
          exitCode: 1,
          stdout: 'irrelevant\nSome gradle message\nirrelevant',
        );
        return Future<Process>.value(process);
      });

      fileSystem.directory('android')
        .childFile('build.gradle')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childFile('gradle.properties')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childDirectory('app')
        .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      int testFnCalled = 0;
      bool builtPluginAsAar = false;
      await expectLater(() async {
       await buildGradleApp(
          project: FlutterProject.current(),
          androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(
              BuildMode.release,
              null,
              treeShakeIcons: false,
            ),
          ),
          target: 'lib/main.dart',
          isBuildingBundle: false,
          localGradleErrors: <GradleHandledError>[
            GradleHandledError(
              test: (String line) {
                if (line.contains('Some gradle message')) {
                  testFnCalled++;
                  return true;
                }
                return false;
              },
              handler: ({
                String line,
                FlutterProject project,
                bool usesAndroidX,
                bool shouldBuildPluginAsAar,
              }) async {
                if (testFnCalled == 2) {
                  builtPluginAsAar = shouldBuildPluginAsAar;
                }
                return GradleBuildStatus.retryWithAarPlugins;
              },
              eventLabel: 'random-event-label',
            ),
          ],
        );
      }, throwsToolExit(
        message: 'Gradle task assembleRelease failed with exit code 1'
      ));

      expect(testFnCalled, equals(2));
      expect(builtPluginAsAar, isTrue);

      verify(mockUsage.sendEvent(
        any,
        any,
        label: 'gradle-random-event-label-failure',
        parameters: anyNamed('parameters'),
      )).called(1);

    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      Cache: () => cache,
      Platform: () => android,
      FileSystem: () => fileSystem,
      ProcessManager: () => mockProcessManager,
      Usage: () => mockUsage,
    });

    testUsingContext('indicates that an APK has been built successfully', () async {
      fileSystem.directory('android')
        .childFile('build.gradle')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childFile('gradle.properties')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childDirectory('app')
        .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      fileSystem.directory('build')
        .childDirectory('app')
        .childDirectory('outputs')
        .childDirectory('flutter-apk')
        .childFile('app-release.apk')
        .createSync(recursive: true);

      await buildGradleApp(
        project: FlutterProject.current(),
        androidBuildInfo: const AndroidBuildInfo(
          BuildInfo(
            BuildMode.release,
            null,
            treeShakeIcons: false,
          ),
        ),
        target: 'lib/main.dart',
        isBuildingBundle: false,
        localGradleErrors: const <GradleHandledError>[],
      );

      expect(
        testLogger.statusText,
        contains('Built build/app/outputs/flutter-apk/app-release.apk (0.0MB)'),
      );

    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      Cache: () => cache,
      FileSystem: () => fileSystem,
      Platform: () => android,
      ProcessManager: () => FakeProcessManager.any(),
    });

    testUsingContext("doesn't indicate how to consume an AAR when printHowToConsumeAaar is false", () async {
      final File manifestFile = fileSystem.file('pubspec.yaml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync('''
        flutter:
          module:
            androidPackage: com.example.test
        '''
      );

      fileSystem.file('.android/gradlew').createSync(recursive: true);

      fileSystem.file('.android/gradle.properties')
        .writeAsStringSync('irrelevant');

      fileSystem.file('.android/build.gradle')
        .createSync(recursive: true);

      // Let any process start. Assert after.
      when(mockProcessManager.run(
        any,
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) async => ProcessResult(1, 0, '', ''));

      fileSystem.directory('build/outputs/repo').createSync(recursive: true);

      await buildGradleAar(
        androidBuildInfo: const AndroidBuildInfo(BuildInfo(BuildMode.release, null, treeShakeIcons: false)),
        project: FlutterProject.current(),
        outputDirectory: fileSystem.directory('build/'),
        target: '',
        buildNumber: '1.0',
      );

      expect(
        testLogger.statusText,
        contains('Built build/outputs/repo'),
      );
      expect(
        testLogger.statusText.contains('Consuming the Module'),
        isFalse,
      );

    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      AndroidStudio: () => mockAndroidStudio,
      Cache: () => cache,
      Platform: () => android,
      FileSystem: () => fileSystem,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('build apk uses selected local engine,the engine abi is arm', () async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterFramework,
          platform: TargetPlatform.android_arm, mode: anyNamed('mode'))).thenReturn('engine');
      when(mockArtifacts.engineOutPath).thenReturn(fileSystem.path.join('out', 'android_arm'));

      fileSystem.file('out/android_arm/flutter_embedding_release.pom')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <version>1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b</version>
  <dependencies>
  </dependencies>
</project>
''');
      fileSystem.file('out/android_arm/armeabi_v7a_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_arm/armeabi_v7a_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_arm/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_arm/flutter_embedding_release.pom').createSync(recursive: true);

      fileSystem.file('android/gradlew').createSync(recursive: true);

      fileSystem.directory('android')
        .childFile('gradle.properties')
        .createSync(recursive: true);

      fileSystem.file('android/build.gradle')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childDirectory('app')
        .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      // Let any process start. Assert after.
      when(mockProcessManager.run(
        any,
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) async => ProcessResult(1, 0, '', ''));

      when(mockProcessManager.start(any,
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment')))
      .thenAnswer((_) {
        return Future<Process>.value(
          createMockProcess(
            exitCode: 1,
          )
        );
      });

      await expectLater(() async {
        await buildGradleApp(
          project: FlutterProject.current(),
          androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(
              BuildMode.release,
              null,
              treeShakeIcons: false,
            ),
          ),
          target: 'lib/main.dart',
          isBuildingBundle: false,
          localGradleErrors: const <GradleHandledError>[],
        );
      }, throwsToolExit());

      final List<String> actualGradlewCall = verify(
        mockProcessManager.start(
          captureAny,
          environment: anyNamed('environment'),
          workingDirectory: anyNamed('workingDirectory')
        ),
      ).captured.last as List<String>;

      expect(actualGradlewCall, contains('/android/gradlew'));
      expect(actualGradlewCall, contains('-Plocal-engine-out=out/android_arm'));
      expect(actualGradlewCall, contains('-Plocal-engine-repo=/.tmp_rand0/flutter_tool_local_engine_repo.rand0'));
      expect(actualGradlewCall, contains('-Plocal-engine-build-mode=release'));

    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      AndroidStudio: () => mockAndroidStudio,
      Artifacts: () => mockArtifacts,
      Cache: () => cache,
      Platform: () => android,
      FileSystem: () => fileSystem,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext(
        'build apk uses selected local engine,the engine abi is arm64', () async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterFramework,
          platform: anyNamed('platform'), mode: anyNamed('mode'))).thenReturn('engine');
      when(mockArtifacts.engineOutPath).thenReturn(fileSystem.path.join('out', 'android_arm64'));

      fileSystem.file('out/android_arm64/flutter_embedding_release.pom')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <version>1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b</version>
  <dependencies>
  </dependencies>
</project>
''');
      fileSystem.file('out/android_arm64/arm64_v8a_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_arm64/arm64_v8a_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_arm64/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_arm64/flutter_embedding_release.pom').createSync(recursive: true);

      fileSystem.file('android/gradlew').createSync(recursive: true);

      fileSystem.directory('android')
          .childFile('gradle.properties')
          .createSync(recursive: true);

      fileSystem.file('android/build.gradle')
          .createSync(recursive: true);

      fileSystem.directory('android')
          .childDirectory('app')
          .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      // Let any process start. Assert after.
      when(mockProcessManager.run(
        any,
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) async => ProcessResult(1, 0, '', ''));

      when(mockProcessManager.start(any,
          workingDirectory: anyNamed('workingDirectory'),
          environment: anyNamed('environment')))
          .thenAnswer((_) {
        return Future<Process>.value(
            createMockProcess(
              exitCode: 1,
            )
        );
      });

      await expectLater(() async {
        await buildGradleApp(
          project: FlutterProject.current(),
          androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(
              BuildMode.release,
              null,
              treeShakeIcons: false,
            ),
          ),
          target: 'lib/main.dart',
          isBuildingBundle: false,
          localGradleErrors: const <GradleHandledError>[],
        );
      }, throwsToolExit());

      final List<String> actualGradlewCall = verify(
        mockProcessManager.start(
            captureAny,
            environment: anyNamed('environment'),
            workingDirectory: anyNamed('workingDirectory')
        ),
      ).captured.last as List<String>;

      expect(actualGradlewCall, contains('/android/gradlew'));
      expect(actualGradlewCall, contains('-Plocal-engine-out=out/android_arm64'));
      expect(actualGradlewCall, contains('-Plocal-engine-repo=/.tmp_rand0/flutter_tool_local_engine_repo.rand0'));
      expect(actualGradlewCall, contains('-Plocal-engine-build-mode=release'));

    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      AndroidStudio: () => mockAndroidStudio,
      Artifacts: () => mockArtifacts,
      Cache: () => cache,
      Platform: () => android,
      FileSystem: () => fileSystem,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext(
        'build apk uses selected local engine,the engine abi is x86', () async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterFramework,
          platform: anyNamed('platform'), mode: anyNamed('mode'))).thenReturn('engine');
      when(mockArtifacts.engineOutPath).thenReturn(fileSystem.path.join('out', 'android_x86'));

      fileSystem.file('out/android_x86/flutter_embedding_release.pom')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <version>1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b</version>
  <dependencies>
  </dependencies>
</project>
''');
      fileSystem.file('out/android_x86/x86_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_x86/x86_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_x86/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_x86/flutter_embedding_release.pom').createSync(recursive: true);

      fileSystem.file('android/gradlew').createSync(recursive: true);

      fileSystem.directory('android')
          .childFile('gradle.properties')
          .createSync(recursive: true);

      fileSystem.file('android/build.gradle')
          .createSync(recursive: true);

      fileSystem.directory('android')
          .childDirectory('app')
          .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      // Let any process start. Assert after.
      when(mockProcessManager.run(
        any,
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) async => ProcessResult(1, 0, '', ''));

      when(mockProcessManager.start(any,
          workingDirectory: anyNamed('workingDirectory'),
          environment: anyNamed('environment')))
          .thenAnswer((_) {
        return Future<Process>.value(
            createMockProcess(
              exitCode: 1,
            )
        );
      });

      await expectLater(() async {
        await buildGradleApp(
          project: FlutterProject.current(),
          androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(
              BuildMode.release,
              null,
              treeShakeIcons: false,
            ),
          ),
          target: 'lib/main.dart',
          isBuildingBundle: false,
          localGradleErrors: const <GradleHandledError>[],
        );
      }, throwsToolExit());

      final List<String> actualGradlewCall = verify(
        mockProcessManager.start(
            captureAny,
            environment: anyNamed('environment'),
            workingDirectory: anyNamed('workingDirectory')
        ),
      ).captured.last as List<String>;

      expect(actualGradlewCall, contains('/android/gradlew'));
      expect(actualGradlewCall, contains('-Plocal-engine-out=out/android_x86'));
      expect(actualGradlewCall, contains('-Plocal-engine-repo=/.tmp_rand0/flutter_tool_local_engine_repo.rand0'));
      expect(actualGradlewCall, contains('-Plocal-engine-build-mode=release'));

    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      AndroidStudio: () => mockAndroidStudio,
      Artifacts: () => mockArtifacts,
      Cache: () => cache,
      Platform: () => android,
      FileSystem: () => fileSystem,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext(
        'build apk uses selected local engine,the engine abi is x64', () async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterFramework,
          platform: anyNamed('platform'), mode: anyNamed('mode'))).thenReturn('engine');
      when(mockArtifacts.engineOutPath).thenReturn(fileSystem.path.join('out', 'android_x64'));

      fileSystem.file('out/android_x64/flutter_embedding_release.pom')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <version>1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b</version>
  <dependencies>
  </dependencies>
</project>
''');
      fileSystem.file('out/android_x64/x86_64_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_x64/x86_64_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_x64/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_x64/flutter_embedding_release.pom').createSync(recursive: true);

      fileSystem.file('android/gradlew').createSync(recursive: true);

      fileSystem.directory('android')
          .childFile('gradle.properties')
          .createSync(recursive: true);

      fileSystem.file('android/build.gradle')
          .createSync(recursive: true);

      fileSystem.directory('android')
          .childDirectory('app')
          .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      // Let any process start. Assert after.
      when(mockProcessManager.run(
        any,
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) async => ProcessResult(1, 0, '', ''));

      when(mockProcessManager.start(any,
          workingDirectory: anyNamed('workingDirectory'),
          environment: anyNamed('environment')))
          .thenAnswer((_) {
        return Future<Process>.value(
            createMockProcess(
              exitCode: 1,
            )
        );
      });

      await expectLater(() async {
        await buildGradleApp(
          project: FlutterProject.current(),
          androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(
              BuildMode.release,
              null,
              treeShakeIcons: false,
            ),
          ),
          target: 'lib/main.dart',
          isBuildingBundle: false,
          localGradleErrors: const <GradleHandledError>[],
        );
      }, throwsToolExit());

      final List<String> actualGradlewCall = verify(
        mockProcessManager.start(
            captureAny,
            environment: anyNamed('environment'),
            workingDirectory: anyNamed('workingDirectory')
        ),
      ).captured.last as List<String>;

      expect(actualGradlewCall, contains('/android/gradlew'));
      expect(actualGradlewCall, contains('-Plocal-engine-out=out/android_x64'));
      expect(actualGradlewCall, contains('-Plocal-engine-repo=/.tmp_rand0/flutter_tool_local_engine_repo.rand0'));
      expect(actualGradlewCall, contains('-Plocal-engine-build-mode=release'));

    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      AndroidStudio: () => mockAndroidStudio,
      Artifacts: () => mockArtifacts,
      Cache: () => cache,
      Platform: () => android,
      FileSystem: () => fileSystem,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('build aar uses selected local engine，the engine abi is arm', () async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterFramework,
          platform: TargetPlatform.android_arm, mode: anyNamed('mode'))).thenReturn('engine');
      when(mockArtifacts.engineOutPath).thenReturn(fileSystem.path.join('out', 'android_arm'));

      fileSystem.file('out/android_arm/flutter_embedding_release.pom')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <version>1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b</version>
  <dependencies>
  </dependencies>
</project>
''');
      fileSystem.file('out/android_arm/armeabi_v7a_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_arm/armeabi_v7a_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_arm/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_arm/flutter_embedding_release.pom').createSync(recursive: true);

      final File manifestFile = fileSystem.file('pubspec.yaml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync('''
        flutter:
          module:
            androidPackage: com.example.test
        '''
      );

      fileSystem.directory('.android/gradle')
        .createSync(recursive: true);

      fileSystem.directory('.android/gradle/wrapper')
        .createSync(recursive: true);

      fileSystem.file('.android/gradlew').createSync(recursive: true);

      fileSystem.file('.android/gradle.properties')
        .writeAsStringSync('irrelevant');

      fileSystem.file('.android/build.gradle')
        .createSync(recursive: true);

      // Let any process start. Assert after.
      when(mockProcessManager.run(
        any,
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) async => ProcessResult(1, 0, '', ''));

      fileSystem.directory('build/outputs/repo').createSync(recursive: true);

      when(fileSystemUtils.copyDirectorySync(any, any)).thenReturn(null);

      await buildGradleAar(
        androidBuildInfo: const AndroidBuildInfo(BuildInfo(BuildMode.release, null, treeShakeIcons: false)),
        project: FlutterProject.current(),
        outputDirectory: fileSystem.directory('build/'),
        target: '',
        buildNumber: '2.0',
      );

      final List<String> actualGradlewCall = verify(
        mockProcessManager.run(
          captureAny,
          environment: anyNamed('environment'),
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).captured.last as List<String>;

      expect(actualGradlewCall, contains('/.android/gradlew'));
      expect(actualGradlewCall, contains('-Plocal-engine-out=out/android_arm'));
      expect(actualGradlewCall, contains('-Plocal-engine-repo=/.tmp_rand0/flutter_tool_local_engine_repo.rand0'));
      expect(actualGradlewCall, contains('-Plocal-engine-build-mode=release'));
      expect(actualGradlewCall, contains('-PbuildNumber=2.0'));

      // Verify the local engine repo is copied into the generated Maven repo.
      final List<dynamic> copyDirectoryArguments = verify(
        fileSystemUtils.copyDirectorySync(captureAny, captureAny)
      ).captured;

      expect(copyDirectoryArguments.length, 2);
      expect((copyDirectoryArguments.first as Directory).path, '/.tmp_rand0/flutter_tool_local_engine_repo.rand0');
      expect((copyDirectoryArguments.last as Directory).path, 'build/outputs/repo');

    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      AndroidStudio: () => mockAndroidStudio,
      Artifacts: () => mockArtifacts,
      Cache: () => cache,
      Platform: () => android,
      FileSystem: () => fileSystem,
      FileSystemUtils: () => fileSystemUtils,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext(
        'build aar uses selected local engine，the engine abi is arm64', () async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterFramework,
          platform: anyNamed('platform'), mode: anyNamed('mode'))).thenReturn('engine');
      when(mockArtifacts.engineOutPath).thenReturn(fileSystem.path.join('out', 'android_arm64'));

      fileSystem.file('out/android_arm64/flutter_embedding_release.pom')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <version>1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b</version>
  <dependencies>
  </dependencies>
</project>
''');
      fileSystem.file('out/android_arm64/arm64_v8a_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_arm64/arm64_v8a_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_arm64/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_arm64/flutter_embedding_release.pom').createSync(recursive: true);

      final File manifestFile = fileSystem.file('pubspec.yaml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync('''
        flutter:
          module:
            androidPackage: com.example.test
        '''
      );

      fileSystem.directory('.android/gradle')
          .createSync(recursive: true);

      fileSystem.directory('.android/gradle/wrapper')
          .createSync(recursive: true);

      fileSystem.file('.android/gradlew').createSync(recursive: true);

      fileSystem.file('.android/gradle.properties')
          .writeAsStringSync('irrelevant');

      fileSystem.file('.android/build.gradle')
          .createSync(recursive: true);

      // Let any process start. Assert after.
      when(mockProcessManager.run(
        any,
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) async => ProcessResult(1, 0, '', ''));

      fileSystem.directory('build/outputs/repo').createSync(recursive: true);

      when(fileSystemUtils.copyDirectorySync(any, any)).thenReturn(null);

      await buildGradleAar(
        androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(BuildMode.release, null, treeShakeIcons: false)),
        project: FlutterProject.current(),
        outputDirectory: fileSystem.directory('build/'),
        target: '',
        buildNumber: '2.0',
      );

      final List<String> actualGradlewCall = verify(
        mockProcessManager.run(
          captureAny,
          environment: anyNamed('environment'),
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).captured.last as List<String>;

      expect(actualGradlewCall, contains('/.android/gradlew'));
      expect(actualGradlewCall, contains('-Plocal-engine-out=out/android_arm64'));
      expect(actualGradlewCall, contains('-Plocal-engine-repo=/.tmp_rand0/flutter_tool_local_engine_repo.rand0'));
      expect(actualGradlewCall, contains('-Plocal-engine-build-mode=release'));
      expect(actualGradlewCall, contains('-PbuildNumber=2.0'));

      // Verify the local engine repo is copied into the generated Maven repo.
      final List<dynamic> copyDirectoryArguments = verify(
          fileSystemUtils.copyDirectorySync(captureAny, captureAny)
      ).captured;

      expect(copyDirectoryArguments.length, 2);
      expect((copyDirectoryArguments.first as Directory).path, '/.tmp_rand0/flutter_tool_local_engine_repo.rand0');
      expect((copyDirectoryArguments.last as Directory).path, 'build/outputs/repo');

    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      AndroidStudio: () => mockAndroidStudio,
      Artifacts: () => mockArtifacts,
      Cache: () => cache,
      Platform: () => android,
      FileSystem: () => fileSystem,
      FileSystemUtils: () => fileSystemUtils,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext(
        'build aar uses selected local engine，the engine abi is x86', () async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterFramework,
          platform: anyNamed('platform'), mode: anyNamed('mode'))).thenReturn('engine');
      when(mockArtifacts.engineOutPath).thenReturn(fileSystem.path.join('out', 'android_x86'));

      fileSystem.file('out/android_x86/flutter_embedding_release.pom')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <version>1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b</version>
  <dependencies>
  </dependencies>
</project>
''');
      fileSystem.file('out/android_x86/x86_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_x86/x86_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_x86/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_x86/flutter_embedding_release.pom').createSync(recursive: true);

      final File manifestFile = fileSystem.file('pubspec.yaml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync('''
        flutter:
          module:
            androidPackage: com.example.test
        '''
      );

      fileSystem.directory('.android/gradle')
          .createSync(recursive: true);

      fileSystem.directory('.android/gradle/wrapper')
          .createSync(recursive: true);

      fileSystem.file('.android/gradlew').createSync(recursive: true);

      fileSystem.file('.android/gradle.properties')
          .writeAsStringSync('irrelevant');

      fileSystem.file('.android/build.gradle')
          .createSync(recursive: true);

      // Let any process start. Assert after.
      when(mockProcessManager.run(
        any,
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) async => ProcessResult(1, 0, '', ''));

      fileSystem.directory('build/outputs/repo').createSync(recursive: true);

      when(fileSystemUtils.copyDirectorySync(any, any)).thenReturn(null);

      await buildGradleAar(
        androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(BuildMode.release, null, treeShakeIcons: false)),
        project: FlutterProject.current(),
        outputDirectory: fileSystem.directory('build/'),
        target: '',
        buildNumber: '2.0',
      );

      final List<String> actualGradlewCall = verify(
        mockProcessManager.run(
          captureAny,
          environment: anyNamed('environment'),
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).captured.last as List<String>;

      expect(actualGradlewCall, contains('/.android/gradlew'));
      expect(actualGradlewCall, contains('-Plocal-engine-out=out/android_x86'));
      expect(actualGradlewCall, contains('-Plocal-engine-repo=/.tmp_rand0/flutter_tool_local_engine_repo.rand0'));
      expect(actualGradlewCall, contains('-Plocal-engine-build-mode=release'));
      expect(actualGradlewCall, contains('-PbuildNumber=2.0'));

      // Verify the local engine repo is copied into the generated Maven repo.
      final List<dynamic> copyDirectoryArguments = verify(
          fileSystemUtils.copyDirectorySync(captureAny, captureAny)
      ).captured;

      expect(copyDirectoryArguments.length, 2);
      expect((copyDirectoryArguments.first as Directory).path, '/.tmp_rand0/flutter_tool_local_engine_repo.rand0');
      expect((copyDirectoryArguments.last as Directory).path, 'build/outputs/repo');

    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      AndroidStudio: () => mockAndroidStudio,
      Artifacts: () => mockArtifacts,
      Cache: () => cache,
      Platform: () => android,
      FileSystem: () => fileSystem,
      FileSystemUtils: () => fileSystemUtils,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext(
        'build aar uses selected local engine，the engine abi is x64', () async {
      when(mockArtifacts.getArtifactPath(Artifact.flutterFramework,
          platform: anyNamed('platform'), mode: anyNamed('mode'))).thenReturn('engine');
      when(mockArtifacts.engineOutPath).thenReturn(fileSystem.path.join('out', 'android_x64'));

      fileSystem.file('out/android_x64/flutter_embedding_release.pom')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <version>1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b</version>
  <dependencies>
  </dependencies>
</project>
''');
      fileSystem.file('out/android_x64/x86_64_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_x64/x86_64_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_x64/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_x64/flutter_embedding_release.pom').createSync(recursive: true);

      final File manifestFile = fileSystem.file('pubspec.yaml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync('''
        flutter:
          module:
            androidPackage: com.example.test
        '''
      );

      fileSystem.directory('.android/gradle')
          .createSync(recursive: true);

      fileSystem.directory('.android/gradle/wrapper')
          .createSync(recursive: true);

      fileSystem.file('.android/gradlew').createSync(recursive: true);

      fileSystem.file('.android/gradle.properties')
          .writeAsStringSync('irrelevant');

      fileSystem.file('.android/build.gradle')
          .createSync(recursive: true);

      // Let any process start. Assert after.
      when(mockProcessManager.run(
        any,
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) async => ProcessResult(1, 0, '', ''));

      fileSystem.directory('build/outputs/repo').createSync(recursive: true);

      when(fileSystemUtils.copyDirectorySync(any, any)).thenReturn(null);

      await buildGradleAar(
        androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(BuildMode.release, null, treeShakeIcons: false)),
        project: FlutterProject.current(),
        outputDirectory: fileSystem.directory('build/'),
        target: '',
        buildNumber: '2.0',
      );

      final List<String> actualGradlewCall = verify(
        mockProcessManager.run(
          captureAny,
          environment: anyNamed('environment'),
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).captured.last as List<String>;

      expect(actualGradlewCall, contains('/.android/gradlew'));
      expect(actualGradlewCall, contains('-Plocal-engine-out=out/android_x64'));
      expect(actualGradlewCall, contains('-Plocal-engine-repo=/.tmp_rand0/flutter_tool_local_engine_repo.rand0'));
      expect(actualGradlewCall, contains('-Plocal-engine-build-mode=release'));
      expect(actualGradlewCall, contains('-PbuildNumber=2.0'));

      // Verify the local engine repo is copied into the generated Maven repo.
      final List<dynamic> copyDirectoryArguments = verify(
          fileSystemUtils.copyDirectorySync(captureAny, captureAny)
      ).captured;

      expect(copyDirectoryArguments.length, 2);
      expect((copyDirectoryArguments.first as Directory).path, '/.tmp_rand0/flutter_tool_local_engine_repo.rand0');
      expect((copyDirectoryArguments.last as Directory).path, 'build/outputs/repo');

    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      AndroidStudio: () => mockAndroidStudio,
      Artifacts: () => mockArtifacts,
      Cache: () => cache,
      Platform: () => android,
      FileSystem: () => fileSystem,
      FileSystemUtils: () => fileSystemUtils,
      ProcessManager: () => mockProcessManager,
    });
  });

  group('printHowToConsumeAar', () {
    BufferLogger logger;
    FileSystem fileSystem;

    setUp(() {
      logger = BufferLogger.test();
      fileSystem = MemoryFileSystem.test();
    });

    testWithoutContext('stdout contains release, debug and profile', () async {
      printHowToConsumeAar(
        buildModes: const <String>{'release', 'debug', 'profile'},
        androidPackage: 'com.mycompany',
        repoDirectory: fileSystem.directory('build/'),
        buildNumber: '2.2',
        logger: logger,
        fileSystem: fileSystem,
      );

      expect(
        logger.statusText,
        contains(
          '\n'
          'Consuming the Module\n'
          '  1. Open <host>/app/build.gradle\n'
          '  2. Ensure you have the repositories configured, otherwise add them:\n'
          '\n'
          '      String storageUrl = System.env.FLUTTER_STORAGE_BASE_URL ?: "https://storage.googleapis.com"\n'
          '      repositories {\n'
          '        maven {\n'
          "            url 'build/'\n"
          '        }\n'
          '        maven {\n'
          "            url '\$storageUrl/download.flutter.io'\n"
          '        }\n'
          '      }\n'
          '\n'
          '  3. Make the host app depend on the Flutter module:\n'
          '\n'
          '    dependencies {\n'
          "      releaseImplementation 'com.mycompany:flutter_release:2.2'\n"
          "      debugImplementation 'com.mycompany:flutter_debug:2.2'\n"
          "      profileImplementation 'com.mycompany:flutter_profile:2.2'\n"
          '    }\n'
          '\n'
          '\n'
          '  4. Add the `profile` build type:\n'
          '\n'
          '    android {\n'
          '      buildTypes {\n'
          '        profile {\n'
          '          initWith debug\n'
          '        }\n'
          '      }\n'
          '    }\n'
          '\n'
          'To learn more, visit https://flutter.dev/go/build-aar\n'
        )
      );
    });

    testWithoutContext('stdout contains release', () async {
      printHowToConsumeAar(
        buildModes: const <String>{'release'},
        androidPackage: 'com.mycompany',
        repoDirectory: fileSystem.directory('build/'),
        logger: logger,
        fileSystem: fileSystem,
      );

      expect(
        logger.statusText,
        contains(
          '\n'
          'Consuming the Module\n'
          '  1. Open <host>/app/build.gradle\n'
          '  2. Ensure you have the repositories configured, otherwise add them:\n'
          '\n'
          '      String storageUrl = System.env.FLUTTER_STORAGE_BASE_URL ?: "https://storage.googleapis.com"\n'
          '      repositories {\n'
          '        maven {\n'
          "            url 'build/'\n"
          '        }\n'
          '        maven {\n'
          "            url '\$storageUrl/download.flutter.io'\n"
          '        }\n'
          '      }\n'
          '\n'
          '  3. Make the host app depend on the Flutter module:\n'
          '\n'
          '    dependencies {\n'
          "      releaseImplementation 'com.mycompany:flutter_release:1.0'\n"
          '    }\n'
          '\n'
          'To learn more, visit https://flutter.dev/go/build-aar\n'
        )
      );
    });

    testWithoutContext('stdout contains debug', () async {
      printHowToConsumeAar(
        buildModes: const <String>{'debug'},
        androidPackage: 'com.mycompany',
        repoDirectory: fileSystem.directory('build/'),
        logger: logger,
        fileSystem: fileSystem,
      );

      expect(
        logger.statusText,
        contains(
          '\n'
          'Consuming the Module\n'
          '  1. Open <host>/app/build.gradle\n'
          '  2. Ensure you have the repositories configured, otherwise add them:\n'
          '\n'
          '      String storageUrl = System.env.FLUTTER_STORAGE_BASE_URL ?: "https://storage.googleapis.com"\n'
          '      repositories {\n'
          '        maven {\n'
          "            url 'build/'\n"
          '        }\n'
          '        maven {\n'
          "            url '\$storageUrl/download.flutter.io'\n"
          '        }\n'
          '      }\n'
          '\n'
          '  3. Make the host app depend on the Flutter module:\n'
          '\n'
          '    dependencies {\n'
          "      debugImplementation 'com.mycompany:flutter_debug:1.0'\n"
          '    }\n'
          '\n'
          'To learn more, visit https://flutter.dev/go/build-aar\n'
        )
      );
    });

    testWithoutContext('stdout contains profile', () async {
      printHowToConsumeAar(
        buildModes: const <String>{'profile'},
        androidPackage: 'com.mycompany',
        repoDirectory: fileSystem.directory('build/'),
        buildNumber: '1.0',
        logger: logger,
        fileSystem: fileSystem,
      );

      expect(
        logger.statusText,
        contains(
          '\n'
          'Consuming the Module\n'
          '  1. Open <host>/app/build.gradle\n'
          '  2. Ensure you have the repositories configured, otherwise add them:\n'
          '\n'
          '      String storageUrl = System.env.FLUTTER_STORAGE_BASE_URL ?: "https://storage.googleapis.com"\n'
          '      repositories {\n'
          '        maven {\n'
          "            url 'build/'\n"
          '        }\n'
          '        maven {\n'
          "            url '\$storageUrl/download.flutter.io'\n"
          '        }\n'
          '      }\n'
          '\n'
          '  3. Make the host app depend on the Flutter module:\n'
          '\n'
          '    dependencies {\n'
          "      profileImplementation 'com.mycompany:flutter_profile:1.0'\n"
          '    }\n'
          '\n'
          '\n'
          '  4. Add the `profile` build type:\n'
          '\n'
          '    android {\n'
          '      buildTypes {\n'
          '        profile {\n'
          '          initWith debug\n'
          '        }\n'
          '      }\n'
          '    }\n'
          '\n'
          'To learn more, visit https://flutter.dev/go/build-aar\n'
        )
      );
    });
  });

  test('Current settings.gradle is in our legacy settings.gradle file set', () {
    // If this test fails, you probably edited templates/app/android.tmpl.
    // That's fine, but you now need to add a copy of that file to gradle/settings.gradle.legacy_versions, separated
    // from the previous versions by a line that just says ";EOF".
    final File templateSettingsDotGradle = globals.fs.file(globals.fs.path.join(Cache.flutterRoot, 'packages', 'flutter_tools', 'templates', 'app', 'android.tmpl', 'settings.gradle'));
    final File legacySettingsDotGradleFiles = globals.fs.file(globals.fs.path.join(Cache.flutterRoot, 'packages','flutter_tools', 'gradle', 'settings.gradle.legacy_versions'));
    expect(
      legacySettingsDotGradleFiles.readAsStringSync().split(';EOF').map<String>((String body) => body.trim()),
      contains(templateSettingsDotGradle.readAsStringSync().trim()),
    );
  });
}

/// Generates a fake app bundle at the location [directoryName]/[fileName].
FlutterProject generateFakeAppBundle(String directoryName, String fileName, FileSystem fileSystem) {
  final FlutterProject project = MockFlutterProject();
  final AndroidProject androidProject = MockAndroidProject();

  when(project.isModule).thenReturn(false);
  when(project.android).thenReturn(androidProject);
  when(androidProject.buildDirectory).thenReturn(fileSystem.directory('irrelevant'));

  final Directory bundleDirectory = getBundleDirectory(project);
  bundleDirectory
    .childDirectory(directoryName)
    .createSync(recursive: true);

  bundleDirectory
    .childDirectory(directoryName)
    .childFile(fileName)
    .createSync();
  return project;
}

FakePlatform fakePlatform(String name) {
  return FakePlatform(
    environment: <String, String>{'HOME': '/path/to/home'},
    operatingSystem: name,
    stdoutSupportsAnsi: false,
  );
}

class FakeGradleUtils extends GradleUtils {
  @override
  String getExecutable(FlutterProject project) {
    return 'gradlew';
  }
}

class MockAndroidSdk extends Mock implements AndroidSdk {}
class MockAndroidProject extends Mock implements AndroidProject {}
class MockAndroidStudio extends Mock implements AndroidStudio {}
class MockDirectory extends Mock implements Directory {}
class MockFile extends Mock implements File {}
class MockFileSystemUtils extends Mock implements FileSystemUtils {}
class MockFlutterProject extends Mock implements FlutterProject {}
class MockLocalEngineArtifacts extends Mock implements LocalEngineArtifacts {}
class MockProcessManager extends Mock implements ProcessManager {}
class MockXcodeProjectInterpreter extends Mock implements XcodeProjectInterpreter {}
class MockUsage extends Mock implements Usage {}
