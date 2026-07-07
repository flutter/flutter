// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/android/java.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:meta/meta.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/package_config.dart';
import '../../src/throwing_pub.dart';

void main() {
  late BufferLogger logger;

  setUp(() {
    logger = BufferLogger.test();
  });

  group('Gradle/KGP/AGP/Java Suggestion Reproduction Tests', () {
    const validPubspec = '''
name: hello
flutter:
''';

    Future<FlutterProject> someProject() async {
      final Directory directory = globals.fs.directory('some_project');
      writePackageConfigFiles(directory: globals.fs.currentDirectory, mainLibName: 'hello');
      directory.childFile('pubspec.yaml')
        ..createSync(recursive: true)
        ..writeAsStringSync(validPubspec);
      directory.childDirectory('ios').createSync(recursive: true);
      final Directory androidDirectory = directory.childDirectory('android')
        ..createSync(recursive: true);
      androidDirectory.childFile('AndroidManifest.xml').writeAsStringSync('<manifest></manifest>');
      return FlutterProject.fromDirectory(directory);
    }

    Future<FlutterProject> configureGradleAgpForTest({
      required String gradleV,
      required String agpV,
    }) async {
      final FlutterProject project = await someProject();
      final File buildGradle = project.directory
          .childDirectory('android')
          .childFile('build.gradle');
      buildGradle
        ..createSync(recursive: true)
        ..writeAsStringSync('''
dependencies {
    classpath 'com.android.tools.build:gradle:$agpV'
}
''');
      final File gradleWrapper = project.directory
          .childDirectory('android')
          .childDirectory('gradle')
          .childDirectory('wrapper')
          .childFile('gradle-wrapper.properties');
      gradleWrapper
        ..createSync(recursive: true)
        ..writeAsStringSync('''
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https://services.gradle.org/distributions/gradle-$gradleV-all.zip
''');
      return project;
    }

    void insertFakeGradleArtifactDir(FileSystem fs, {required Directory flutterRoot}) {
      final Directory artifactDir = flutterRoot
          .childDirectory('bin')
          .childDirectory('cache')
          .childDirectory('artifacts')
          .childDirectory('gradle_wrapper');
      artifactDir
        ..childFile('gradlew').createSync(recursive: true)
        ..childFile('gradlew.bat').createSync(recursive: true)
        ..childDirectory('wrapper').childFile('gradle-wrapper.jar').createSync(recursive: true);
    }

    @isTest
    void testInMemory(
      String description,
      Future<void> Function() testMethod, {
      required Java java,
      required ProcessManager processManager,
    }) {
      final FileSystem testFileSystem = MemoryFileSystem.test();
      final String flutterRoot = getFlutterRoot();
      final Directory fakeFlutterRoot = testFileSystem.directory(flutterRoot);
      insertFakeGradleArtifactDir(testFileSystem, flutterRoot: fakeFlutterRoot);

      testUsingContext(
        description,
        testMethod,
        overrides: <Type, Generator>{
          FileSystem: () => testFileSystem,
          ProcessManager: () => processManager,
          Java: () => java,
          AndroidStudio: () => FakeAndroidStudio(),
          Cache: () => Cache(
            logger: logger,
            fileSystem: testFileSystem,
            osUtils: globals.os,
            platform: globals.platform,
            artifacts: <ArtifactSet>[],
          ),
          FlutterProjectFactory: () =>
              FlutterProjectFactory(fileSystem: testFileSystem, logger: logger),
          Pub: ThrowingPub.new,
        },
      );
    }

    testInMemory(
      'reproduce missing suggestion for incompatible Java/Gradle versions',
      () async {
        const gradleV = '6.7.3';
        const agpV = '4.2.0';

        final FlutterProject project = await configureGradleAgpForTest(
          gradleV: gradleV,
          agpV: agpV,
        );

        final CompatibilityResult result = await project.android.hasValidJavaGradleAgpVersions();
        expect(result.success, isFalse);

        // Currently, the error description lists versions but has no suggested version range
        // for Java 17 (which should suggest Gradle >= 7.3).
        // Let's assert it MUST contain a suggestion for compatible Gradle version range.
        expect(
          result.description,
          contains(
            RegExp(
              r'Compatible Gradle version range|Update Gradle to at least "7.3"|compatible Gradle',
            ),
          ),
        );
      },
      java: FakeJava(version: Version(17, 0, 2)),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['./gradlew', 'kgpVersion', '-q'],
          stdout: 'KGP Version: 1.7.22\n',
        ),
      ]),
    );

    testInMemory(
      'reproduce missing suggestion for incompatible KGP/Gradle versions',
      () async {
        const gradleV = '8.11';
        const agpV = '8.7.2';

        final FlutterProject project = await configureGradleAgpForTest(
          gradleV: gradleV,
          agpV: agpV,
        );

        final CompatibilityResult result = await project.android.hasValidJavaGradleAgpVersions();
        expect(result.success, isFalse);

        // Currently, the error description lists versions but has no suggestion of a compatible KGP/Gradle version.
        // Let's assert it MUST contain a suggestion.
        expect(
          result.description,
          contains(
            RegExp(r'Compatible KGP version|compatible Kotlin version|Update KGP|Update Gradle'),
          ),
        );
      },
      java: FakeJava(version: Version(17, 0, 2)),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['./gradlew', 'kgpVersion', '-q'],
          stdout: 'KGP Version: 2.1.10\n',
        ),
      ]),
    );

    testInMemory(
      'reproduce missing suggestion for incompatible AGP/KGP versions',
      () async {
        const gradleV = '8.9';
        const agpV = '8.7.2';

        final FlutterProject project = await configureGradleAgpForTest(
          gradleV: gradleV,
          agpV: agpV,
        );

        final CompatibilityResult result = await project.android.hasValidJavaGradleAgpVersions();
        expect(result.success, isFalse);

        // Currently, the error description lists versions but has no suggestion of a compatible AGP/KGP version.
        // Let's assert it MUST contain a suggestion.
        expect(
          result.description,
          contains(
            RegExp(r'Compatible AGP version|compatible Kotlin version|Update AGP|Update KGP'),
          ),
        );
      },
      java: FakeJava(version: Version(17, 0, 2)),
      processManager: FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['./gradlew', 'kgpVersion', '-q'],
          stdout: 'KGP Version: 2.0.20\n',
        ),
      ]),
    );
  });
}
