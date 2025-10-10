// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/gradle.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart' as gradle_utils;
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';

import '../../src/common.dart';
import '../../src/context.dart';

const kModulePubspec = '''
name: test
flutter:
  module:
    androidPackage: com.example
    androidX: true
''';

void main() {
  Cache.flutterRoot = getFlutterRoot();

  group('build artifacts', () {
    late FileSystem fileSystem;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
    });

    testWithoutContext('getApkDirectory in app projects', () {
      final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);

      expect(getApkDirectory(project).path, '/build/app/outputs/flutter-apk');
    });

    testWithoutContext('getApkDirectory in module projects', () {
      fileSystem.currentDirectory.childFile('pubspec.yaml').writeAsStringSync(kModulePubspec);
      final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);

      expect(project.isModule, true);
      expect(getApkDirectory(project).path, '/build/host/outputs/apk');
    });

    testWithoutContext('getBundleDirectory in app projects', () {
      final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);

      expect(getBundleDirectory(project).path, '/build/app/outputs/bundle');
    });

    testWithoutContext('getBundleDirectory in module projects', () {
      fileSystem.currentDirectory.childFile('pubspec.yaml').writeAsStringSync(kModulePubspec);
      final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);

      expect(project.isModule, true);
      expect(getBundleDirectory(project).path, '/build/host/outputs/bundle');
    });

    testWithoutContext('getRepoDirectory', () {
      expect(
        getRepoDirectory(fileSystem.directory('foo')).path,
        equals(fileSystem.path.join('foo', 'outputs', 'repo')),
      );
    });
  });

  group('gradle tasks', () {
    testWithoutContext('assemble release', () {
      expect(
        getAssembleTaskFor(
          const BuildInfo(
            BuildMode.release,
            null,
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
        ),
        equals('assembleRelease'),
      );
      expect(
        getAssembleTaskFor(
          const BuildInfo(
            BuildMode.release,
            'flavorFoo',
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
        ),
        equals('assembleFlavorFooRelease'),
      );
    });

    testWithoutContext('assemble debug', () {
      expect(getAssembleTaskFor(BuildInfo.debug), equals('assembleDebug'));
      expect(
        getAssembleTaskFor(
          const BuildInfo(
            BuildMode.debug,
            'flavorFoo',
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
        ),
        equals('assembleFlavorFooDebug'),
      );
    });

    testWithoutContext('assemble profile', () {
      expect(
        getAssembleTaskFor(
          const BuildInfo(
            BuildMode.profile,
            null,
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
        ),
        equals('assembleProfile'),
      );
      expect(
        getAssembleTaskFor(
          const BuildInfo(
            BuildMode.profile,
            'flavorFoo',
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
        ),
        equals('assembleFlavorFooProfile'),
      );
    });
  });

  group('listApkPaths', () {
    testWithoutContext('Finds APK without flavor in debug', () {
      final Iterable<String> apks = listApkPaths(
        const AndroidBuildInfo(
          BuildInfo(
            BuildMode.debug,
            '',
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
        ),
      );
      expect(apks, <String>['app-debug.apk']);
    });

    testWithoutContext('Finds APK with flavor in debug', () {
      final Iterable<String> apks = listApkPaths(
        const AndroidBuildInfo(
          BuildInfo(
            BuildMode.debug,
            'flavor1',
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
        ),
      );
      expect(apks, <String>['app-flavor1-debug.apk']);
    });

    testWithoutContext('Finds APK without flavor in release', () {
      final Iterable<String> apks = listApkPaths(
        const AndroidBuildInfo(
          BuildInfo(
            BuildMode.release,
            '',
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
        ),
      );

      expect(apks, <String>['app-release.apk']);
    });

    testWithoutContext('Finds APK with flavor in release mode', () {
      final Iterable<String> apks = listApkPaths(
        const AndroidBuildInfo(
          BuildInfo(
            BuildMode.release,
            'flavor1',
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
        ),
      );

      expect(apks, <String>['app-flavor1-release.apk']);
    });

    testWithoutContext('Finds APK with flavor in release mode', () {
      final Iterable<String> apks = listApkPaths(
        const AndroidBuildInfo(
          BuildInfo(
            BuildMode.release,
            'flavorA',
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
        ),
      );

      expect(apks, <String>['app-flavora-release.apk']);
    });

    testWithoutContext('Finds APK with flavor in release mode - AGP v3', () {
      final Iterable<String> apks = listApkPaths(
        const AndroidBuildInfo(
          BuildInfo(
            BuildMode.release,
            'flavor1',
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
        ),
      );
      expect(apks, <String>['app-flavor1-release.apk']);
    });

    testWithoutContext('Finds APK with split-per-abi', () {
      final Iterable<String> apks = listApkPaths(
        const AndroidBuildInfo(
          BuildInfo(
            BuildMode.release,
            'flavor1',
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
          splitPerAbi: true,
        ),
      );

      expect(
        apks,
        unorderedEquals(<String>[
          'app-armeabi-v7a-flavor1-release.apk',
          'app-arm64-v8a-flavor1-release.apk',
          'app-x86_64-flavor1-release.apk',
        ]),
      );
    });

    testWithoutContext('Finds APK with split-per-abi when flavor contains uppercase letters', () {
      final Iterable<String> apks = listApkPaths(
        const AndroidBuildInfo(
          BuildInfo(
            BuildMode.release,
            'flavorA',
            treeShakeIcons: false,
            packageConfigPath: '.dart_tool/package_config.json',
          ),
          splitPerAbi: true,
        ),
      );

      expect(
        apks,
        unorderedEquals(<String>[
          'app-armeabi-v7a-flavora-release.apk',
          'app-arm64-v8a-flavora-release.apk',
          'app-x86_64-flavora-release.apk',
        ]),
      );
    });
  });

  group('gradle build', () {
    testUsingContext('do not crash if there is no Android SDK', () async {
      expect(
        () {
          gradle_utils.updateLocalProperties(
            project: FlutterProject.fromDirectoryTest(globals.fs.currentDirectory),
          );
        },
        throwsToolExit(
          message:
              '${globals.logger.terminal.warningMark} No Android SDK found. Try setting the ANDROID_HOME environment variable.',
        ),
      );
    }, overrides: <Type, Generator>{AndroidSdk: () => null});
  });

  group('Gradle local.properties', () {
    late Artifacts localEngineArtifacts;
    late FileSystem fs;

    setUp(() {
      fs = MemoryFileSystem.test();
      localEngineArtifacts = Artifacts.testLocalEngine(
        localEngine: 'out/android_arm',
        localEngineHost: 'out/host_release',
      );
    });

    void testUsingAndroidContext(String description, dynamic Function() testMethod) {
      testUsingContext(
        description,
        testMethod,
        overrides: <Type, Generator>{
          Artifacts: () => localEngineArtifacts,
          Platform: () => FakePlatform(),
          FileSystem: () => fs,
          ProcessManager: () => FakeProcessManager.any(),
        },
      );
    }

    String? propertyFor(String key, File file) {
      final Iterable<String> result = file
          .readAsLinesSync()
          .where((String line) => line.startsWith('$key='))
          .map((String line) => line.split('=')[1]);
      return result.isEmpty ? null : result.first;
    }

    Future<void> checkBuildVersion({
      required String manifest,
      BuildInfo? buildInfo,
      String? expectedBuildName,
      String? expectedBuildNumber,
    }) async {
      final File manifestFile = globals.fs.file('path/to/project/pubspec.yaml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync(manifest);

      gradle_utils.updateLocalProperties(
        project: FlutterProject.fromDirectoryTest(globals.fs.directory('path/to/project')),
        buildInfo: buildInfo,
        requireAndroidSdk: false,
      );

      final File localPropertiesFile = globals.fs.file('path/to/project/android/local.properties');
      expect(propertyFor('flutter.versionName', localPropertiesFile), expectedBuildName);
      expect(propertyFor('flutter.versionCode', localPropertiesFile), expectedBuildNumber);
    }

    testUsingAndroidContext('extract build name and number from pubspec.yaml', () async {
      const manifest = '''
name: test
version: 1.0.0+1
dependencies:
  flutter:
    sdk: flutter
flutter:
''';

      const buildInfo = BuildInfo(
        BuildMode.release,
        null,
        treeShakeIcons: false,
        packageConfigPath: '.dart_tool/package_config.json',
      );
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.0',
        expectedBuildNumber: '1',
      );
    });

    testUsingAndroidContext('extract build name from pubspec.yaml', () async {
      const manifest = '''
name: test
version: 1.0.0
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const buildInfo = BuildInfo(
        BuildMode.release,
        null,
        treeShakeIcons: false,
        packageConfigPath: '.dart_tool/package_config.json',
      );
      await checkBuildVersion(manifest: manifest, buildInfo: buildInfo, expectedBuildName: '1.0.0');
    });

    testUsingAndroidContext('allow build info to override build name', () async {
      const manifest = '''
name: test
version: 1.0.0+1
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const buildInfo = BuildInfo(
        BuildMode.release,
        null,
        buildName: '1.0.2',
        treeShakeIcons: false,
        packageConfigPath: '.dart_tool/package_config.json',
      );
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '1',
      );
    });

    testUsingAndroidContext('allow build info to override build number', () async {
      const manifest = '''
name: test
version: 1.0.0+1
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const buildInfo = BuildInfo(
        BuildMode.release,
        null,
        buildNumber: '3',
        treeShakeIcons: false,
        packageConfigPath: '.dart_tool/package_config.json',
      );
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.0',
        expectedBuildNumber: '3',
      );
    });

    testUsingAndroidContext('allow build info to override build name and number', () async {
      const manifest = '''
name: test
version: 1.0.0+1
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const buildInfo = BuildInfo(
        BuildMode.release,
        null,
        buildName: '1.0.2',
        buildNumber: '3',
        treeShakeIcons: false,
        packageConfigPath: '.dart_tool/package_config.json',
      );
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '3',
      );
    });

    testUsingAndroidContext('allow build info to override build name and set number', () async {
      const manifest = '''
name: test
version: 1.0.0
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const buildInfo = BuildInfo(
        BuildMode.release,
        null,
        buildName: '1.0.2',
        buildNumber: '3',
        treeShakeIcons: false,
        packageConfigPath: '.dart_tool/package_config.json',
      );
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '3',
      );
    });

    testUsingAndroidContext('allow build info to set build name and number', () async {
      const manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      const buildInfo = BuildInfo(
        BuildMode.release,
        null,
        buildName: '1.0.2',
        buildNumber: '3',
        treeShakeIcons: false,
        packageConfigPath: '.dart_tool/package_config.json',
      );
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: buildInfo,
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '3',
      );
    });

    testUsingAndroidContext('allow build info to unset build name and number', () async {
      const manifest = '''
name: test
dependencies:
  flutter:
    sdk: flutter
flutter:
''';
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: const BuildInfo(
          BuildMode.release,
          null,
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
      );
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: const BuildInfo(
          BuildMode.release,
          null,
          buildName: '1.0.2',
          buildNumber: '3',
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
        expectedBuildName: '1.0.2',
        expectedBuildNumber: '3',
      );
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: const BuildInfo(
          BuildMode.release,
          null,
          buildName: '1.0.3',
          buildNumber: '4',
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
        expectedBuildName: '1.0.3',
        expectedBuildNumber: '4',
      );
      // Values don't get unset.
      await checkBuildVersion(
        manifest: manifest,
        expectedBuildName: '1.0.3',
        expectedBuildNumber: '4',
      );
      // Values get unset.
      await checkBuildVersion(
        manifest: manifest,
        buildInfo: const BuildInfo(
          BuildMode.release,
          null,
          treeShakeIcons: false,
          packageConfigPath: '.dart_tool/package_config.json',
        ),
      );
    });
  });

  group('isAppUsingAndroidX', () {
    late FileSystem fs;

    setUp(() {
      fs = MemoryFileSystem.test();
    });

    testUsingContext(
      'returns true when the project is using AndroidX',
      () async {
        final Directory androidDirectory = globals.fs.systemTempDirectory.createTempSync(
          'flutter_android.',
        );

        androidDirectory
            .childFile('gradle.properties')
            .writeAsStringSync('android.useAndroidX=true');

        expect(isAppUsingAndroidX(androidDirectory), isTrue);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'returns false when the project is not using AndroidX',
      () async {
        final Directory androidDirectory = globals.fs.systemTempDirectory.createTempSync(
          'flutter_android.',
        );

        androidDirectory
            .childFile('gradle.properties')
            .writeAsStringSync('android.useAndroidX=false');

        expect(isAppUsingAndroidX(androidDirectory), isFalse);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );

    testUsingContext(
      'returns false when gradle.properties does not exist',
      () async {
        final Directory androidDirectory = globals.fs.systemTempDirectory.createTempSync(
          'flutter_android.',
        );

        expect(isAppUsingAndroidX(androidDirectory), isFalse);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      },
    );
  });

  group('printHowToConsumeAar', () {
    late BufferLogger logger;
    late FileSystem fileSystem;

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
          'To learn more, visit https://flutter.dev/to/integrate-android-archive\n',
        ),
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
          'To learn more, visit https://flutter.dev/to/integrate-android-archive\n',
        ),
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
          'To learn more, visit https://flutter.dev/to/integrate-android-archive\n',
        ),
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
          'To learn more, visit https://flutter.dev/to/integrate-android-archive\n',
        ),
      );
    });
  });
}
