// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:platform/platform.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/gradle.dart';
import 'package:flutter_tools/src/android/gradle_errors.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

final Platform linuxPlatform = FakePlatform(
  operatingSystem: 'linux',
  environment: <String, String>{},
);

// This test verifies that the terminal prompt selection when Gradle outputs
// multiple APKs works correctly. For testing of the ranking and automatic
// selection process see apk_locator_test.dart.
void main() {
  FileSystem fileSystem;
  Logger logger;
  Terminal terminal;
  MockCache cache;

  setUp(() {
    terminal = MockTerminal();
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test(terminal: terminal, hasTerminal: true);
    cache = MockCache();
  });

  testUsingContext('Can handle buildGradle invocations that lead to multiple output APKs', () async {
    // Set up the fake cache configuration.
    final Directory gradleWrapperArtifact = fileSystem.directory('gradle-wrapper')
      ..createSync();
    when(cache.getArtifactDirectory('gradle_wrapper'))
      .thenReturn(gradleWrapperArtifact);

    // Set up the fake project information.
    final FlutterProject flutterProject = MockFlutterProject();
    final File localProperties = fileSystem.file('android/local.properties')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
flutter.sdk=/flutter
sdk.dir=/Library/Android/sdk
flutter.buildMode=debug
 ''');
    fileSystem.file('android/gradle.properties')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
org.gradle.jvmargs=-Xmx1536M
android.useAndroidX=true
android.enableJetifier=true
android.enableR8=true
''');
    fileSystem.file('android/gradle/wrapper/gradle-wrapper.jar')
      .createSync(recursive: true);
    fileSystem.file('android/gradle/wrapper/gradle-wrapper.properties')
      ..createSync()
      ..writeAsStringSync('''
#Fri Jun 23 08:50:38 CEST 2017
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-5.6.2-all.zip
''');
    fileSystem.file('android/gradlew').createSync();

    // Set up project mocks
    when(flutterProject.android.isSupportedVersion()).thenReturn(true);
    when(flutterProject.android.isUsingGradle).thenReturn(true);
    when(flutterProject.android.isAppUsingAndroidX()).thenReturn(true);
    when(flutterProject.android.localPropertiesFile).thenReturn(localProperties);
    when(flutterProject.android.hostAppGradleRoot).thenReturn(fileSystem.directory('android'));
    when(flutterProject.isModule).thenReturn(false);
    when(flutterProject.android.buildDirectory).thenReturn(fileSystem.directory('build'));

    // Set up multiple APK outputs. The contents are used to verify the result.
    fileSystem.file('build/app/outputs/apk/debug/app-free1-debug.apk')
      ..createSync(recursive: true)
      ..writeAsStringSync('0');
    fileSystem.file('build/app/outputs/apk/debug/app-free2-debug.apk')
      ..createSync(recursive: true)
      ..writeAsStringSync('1');
    fileSystem.file('build/app/outputs/apk/debug/app-paid-debug.apk')
      ..createSync(recursive: true)
      ..writeAsStringSync('2');
    fileSystem.file('build/app/outputs/apk/release/app-free-release.apk')
      ..createSync(recursive: true)
      ..writeAsStringSync('3');

    // set up terminal behavior prompt which returns '2'.
    when(terminal.promptForCharInput(
      <String>['0', '1', '2', '3'],
      logger: anyNamed('logger'),
      prompt: anyNamed('prompt'))
    ).thenAnswer((Invocation invocation) async {
      return '2';
    });

    const AndroidBuildInfo androidBuildInfo = AndroidBuildInfo(BuildInfo(
      BuildMode.debug,
      'free',
      treeShakeIcons: false,
      buildName: 'v1.2.3',
      buildNumber: '23',
    ));

    await buildGradleApp(
      androidBuildInfo: androidBuildInfo,
      project: flutterProject,
      isBuildingBundle: false,
      localGradleErrors: <GradleHandledError>[],
      target: 'test',
    );

    // Verify that '2' corresponds to the expected APK.
    expect(fileSystem.file('build/app/outputs/apk/app.apk'), exists);
    expect(fileSystem.file('build/app/outputs/apk/app.apk').readAsStringSync(), '2');
  }, overrides: <Type, Generator>{
    FileSystem: () => fileSystem,
    Logger: () => logger,
    AnsiTerminal: () => terminal,
    ProcessManager: () => FakeProcessManager.any(),
    AndroidSdk: () => MockAndroidSdk(),
    Cache: () => cache,
    Platform: () => linuxPlatform,
  });
}

class MockTerminal extends Mock implements AnsiTerminal {}
class MockAndroidSdk extends Mock implements AndroidSdk {}
class MockFlutterProject extends Mock implements FlutterProject {
  @override
  final AndroidProject android = MockAndroidProject();
}
class MockAndroidProject extends Mock implements AndroidProject {}
class MockCache extends Mock implements Cache {}
