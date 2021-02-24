// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/gradle.dart';
import 'package:flutter_tools/src/android/gradle_errors.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';

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
        getAssembleTaskFor(BuildInfo.debug),
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

    testWithoutContext('Finds APK with flavor in release mode', () {
      final Iterable<String> apks = listApkPaths(
        const AndroidBuildInfo(BuildInfo(BuildMode.release, 'flavorA', treeShakeIcons: false)),
      );

      expect(apks, <String>['app-flavora-release.apk']);
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

    testWithoutContext('Finds APK with split-per-abi when flavor contains uppercase letters', () {
      final Iterable<String> apks = listApkPaths(
        const AndroidBuildInfo(BuildInfo(BuildMode.release, 'flavorA', treeShakeIcons: false), splitPerAbi: true),
      );

      expect(apks, unorderedEquals(<String>[
        'app-armeabi-v7a-flavora-release.apk',
        'app-arm64-v8a-flavora-release.apk',
        'app-x86_64-flavora-release.apk',
      ]));
    });

  });

  group('gradle build', () {
    testUsingContext('do not crash if there is no Android SDK', () async {
      expect(() {
        updateLocalProperties(project: FlutterProject.fromDirectoryTest(globals.fs.currentDirectory));
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
    FileSystem fileSystem;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      tempDir = fileSystem.systemTempDirectory.createTempSync('flutter_settings_aar_test.');
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

      final String toolGradlePath = fileSystem.path.join(
          fileSystem.path.absolute(Cache.flutterRoot),
          'packages',
          'flutter_tools',
          'gradle');
      fileSystem.directory(toolGradlePath).createSync(recursive: true);
      fileSystem.file(fileSystem.path.join(toolGradlePath, 'settings.gradle.legacy_versions'))
          .writeAsStringSync(currentSettingsGradle);

      fileSystem.file(fileSystem.path.join(toolGradlePath, 'settings_aar.gradle.tmpl'))
          .writeAsStringSync(settingsAarFile);

      createSettingsAarGradle(tempDir, testLogger);

      expect(testLogger.statusText, contains('created successfully'));
      expect(tempDir.childFile('settings_aar.gradle').existsSync(), isTrue);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
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

      final String toolGradlePath = fileSystem.path.join(
          fileSystem.path.absolute(Cache.flutterRoot),
          'packages',
          'flutter_tools',
          'gradle');
      fileSystem.directory(toolGradlePath).createSync(recursive: true);
      fileSystem.file(fileSystem.path.join(toolGradlePath, 'settings.gradle.legacy_versions'))
          .writeAsStringSync(currentSettingsGradle);

      fileSystem.file(fileSystem.path.join(toolGradlePath, 'settings_aar.gradle.tmpl'))
          .writeAsStringSync(settingsAarFile);

      createSettingsAarGradle(tempDir, testLogger);

      expect(testLogger.statusText, contains('created successfully'));
      expect(tempDir.childFile('settings_aar.gradle').existsSync(), isTrue);
    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
    });
  });

  group('Gradle local.properties', () {
    Artifacts localEngineArtifacts;
    FakePlatform android;
    FileSystem fs;

    setUp(() {
      fs = MemoryFileSystem.test();
      localEngineArtifacts = Artifacts.test(localEngine: 'out/android_arm');
      android = fakePlatform('android');
    });

    void testUsingAndroidContext(String description, dynamic testMethod()) {
      testUsingContext(description, testMethod, overrides: <Type, Generator>{
        Artifacts: () => localEngineArtifacts,
        Platform: () => android,
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
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
      final File manifestFile = globals.fs.file('path/to/project/pubspec.yaml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync(manifest);


      updateLocalProperties(
        project: FlutterProject.fromDirectoryTest(globals.fs.directory('path/to/project')),
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

      expect(getGradleVersionFor('4.0.0'), '6.7');
      expect(getGradleVersionFor('4.1.0'), '6.7');
    });

    testWithoutContext('throws on unsupported versions', () {
      expect(() => getGradleVersionFor('3.6.0'),
          throwsA(predicate<Exception>((Exception e) => e is ToolExit)));
    });
  });

  group('isAppUsingAndroidX', () {
    FileSystem fs;

    setUp(() {
      fs = MemoryFileSystem.test();
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
    AndroidGradleBuilder builder;
    BufferLogger logger;

    setUp(() {
      logger = BufferLogger.test();
      fs = MemoryFileSystem.test();
      fakeProcessManager = FakeProcessManager.list(<FakeCommand>[]);
      mockAndroidSdk = MockAndroidSdk();
      when(mockAndroidSdk.directory).thenReturn(fs.directory('irrelevant'));
      builder = AndroidGradleBuilder(
        logger: logger,
        processManager: fakeProcessManager,
        fileSystem: fs,
        artifacts: Artifacts.test(),
        usage: TestUsage(),
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(),
      );
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
            '-Pdart-obfuscation=false',
            '-Ptrack-widget-creation=false',
            '-Ptree-shake-icons=true',
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
            '-Pdart-obfuscation=false',
            '-Ptrack-widget-creation=false',
            '-Ptree-shake-icons=true',
            '-Ptarget-platform=android-arm,android-arm64,android-x64',
            'assembleAarRelease',
          ],
          workingDirectory: plugin2.childDirectory('android').path,
        ));

      await builder.buildPluginsAsAar(
        FlutterProject.fromDirectoryTest(androidDirectory),
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

      await builder.buildPluginsAsAar(
        FlutterProject.fromDirectoryTest(androidDirectory),
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
          '            url "\$storageUrl/download.flutter.io"\n'
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
          '            url "\$storageUrl/download.flutter.io"\n'
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
          '            url "\$storageUrl/download.flutter.io"\n'
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
          '            url "\$storageUrl/download.flutter.io"\n'
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
  }, skip: true); // TODO(jonahwilliams): This is an integration test and should be moved to the integration shard.
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
class MockFlutterProject extends Mock implements FlutterProject {}
