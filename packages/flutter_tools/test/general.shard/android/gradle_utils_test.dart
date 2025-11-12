// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/base/common.dart' show ToolExit;
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/base/version_range.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/project.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';

void main() {
  group('injectGradleWrapperIfNeeded', () {
    late FileSystem fileSystem;
    late Directory gradleWrapperDirectory;
    late GradleUtils gradleUtils;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      gradleWrapperDirectory = fileSystem.directory('bin/cache/artifacts/gradle_wrapper');
      gradleWrapperDirectory.createSync(recursive: true);
      gradleWrapperDirectory.childFile('gradlew').writeAsStringSync('irrelevant');
      gradleWrapperDirectory
          .childDirectory('gradle')
          .childDirectory('wrapper')
          .createSync(recursive: true);
      gradleWrapperDirectory
          .childDirectory('gradle')
          .childDirectory('wrapper')
          .childFile('gradle-wrapper.jar')
          .writeAsStringSync('irrelevant');
      gradleUtils = GradleUtils(
        cache: Cache.test(processManager: FakeProcessManager.any(), fileSystem: fileSystem),
        platform: FakePlatform(environment: <String, String>{}),
        logger: BufferLogger.test(),
        operatingSystemUtils: FakeOperatingSystemUtils(),
      );
    });

    testWithoutContext('injects the wrapper when all files are missing', () {
      final Directory sampleAppAndroid = fileSystem.directory('/sample-app/android');
      sampleAppAndroid.createSync(recursive: true);

      gradleUtils.injectGradleWrapperIfNeeded(sampleAppAndroid);

      expect(sampleAppAndroid.childFile('gradlew').existsSync(), isTrue);

      expect(
        sampleAppAndroid
            .childDirectory('gradle')
            .childDirectory('wrapper')
            .childFile('gradle-wrapper.jar')
            .existsSync(),
        isTrue,
      );

      expect(
        sampleAppAndroid
            .childDirectory('gradle')
            .childDirectory('wrapper')
            .childFile('gradle-wrapper.properties')
            .existsSync(),
        isTrue,
      );

      expect(
        sampleAppAndroid
            .childDirectory('gradle')
            .childDirectory('wrapper')
            .childFile('gradle-wrapper.properties')
            .readAsStringSync(),
        'distributionBase=GRADLE_USER_HOME\n'
        'distributionPath=wrapper/dists\n'
        'zipStoreBase=GRADLE_USER_HOME\n'
        'zipStorePath=wrapper/dists\n'
        'distributionUrl=https\\://services.gradle.org/distributions/gradle-$templateDefaultGradleVersion-all.zip\n',
      );
    });

    testWithoutContext('injects the wrapper when some files are missing', () {
      final Directory sampleAppAndroid = fileSystem.directory('/sample-app/android');
      sampleAppAndroid.createSync(recursive: true);

      // There's an existing gradlew
      sampleAppAndroid.childFile('gradlew').writeAsStringSync('existing gradlew');

      gradleUtils.injectGradleWrapperIfNeeded(sampleAppAndroid);

      expect(sampleAppAndroid.childFile('gradlew').existsSync(), isTrue);
      expect(sampleAppAndroid.childFile('gradlew').readAsStringSync(), equals('existing gradlew'));

      expect(
        sampleAppAndroid
            .childDirectory('gradle')
            .childDirectory('wrapper')
            .childFile('gradle-wrapper.jar')
            .existsSync(),
        isTrue,
      );

      expect(
        sampleAppAndroid
            .childDirectory('gradle')
            .childDirectory('wrapper')
            .childFile('gradle-wrapper.properties')
            .existsSync(),
        isTrue,
      );

      expect(
        sampleAppAndroid
            .childDirectory('gradle')
            .childDirectory('wrapper')
            .childFile('gradle-wrapper.properties')
            .readAsStringSync(),
        'distributionBase=GRADLE_USER_HOME\n'
        'distributionPath=wrapper/dists\n'
        'zipStoreBase=GRADLE_USER_HOME\n'
        'zipStorePath=wrapper/dists\n'
        'distributionUrl=https\\://services.gradle.org/distributions/gradle-$templateDefaultGradleVersion-all.zip\n',
      );
    });

    testWithoutContext(
      'injects the wrapper and the Gradle version is derived from the AGP version',
      () {
        const testCases = <String, String>{
          // AGP version : Gradle version
          '1.0.0': '2.3',
          '3.3.1': '4.10.2',
          '3.0.0': '4.1',
          '3.0.5': '4.1',
          '3.0.9': '4.1',
          '3.1.0': '4.4',
          '3.2.0': '4.6',
          '3.3.0': '4.10.2',
          '3.4.0': '5.6.2',
          '3.5.0': '5.6.2',
          '4.0.0': '6.7',
          '4.0.5': '6.7',
          '4.1.0': '6.7',
        };

        for (final MapEntry<String, String> entry in testCases.entries) {
          final Directory sampleAppAndroid = fileSystem.systemTempDirectory.createTempSync(
            'flutter_android.',
          );
          sampleAppAndroid.childFile('build.gradle').writeAsStringSync('''
  buildscript {
      dependencies {
          classpath 'com.android.tools.build:gradle:${entry.key}'
      }
  }
  ''');
          gradleUtils.injectGradleWrapperIfNeeded(sampleAppAndroid);

          expect(sampleAppAndroid.childFile('gradlew').existsSync(), isTrue);

          expect(
            sampleAppAndroid
                .childDirectory('gradle')
                .childDirectory('wrapper')
                .childFile('gradle-wrapper.jar')
                .existsSync(),
            isTrue,
          );

          expect(
            sampleAppAndroid
                .childDirectory('gradle')
                .childDirectory('wrapper')
                .childFile('gradle-wrapper.properties')
                .existsSync(),
            isTrue,
          );

          expect(
            sampleAppAndroid
                .childDirectory('gradle')
                .childDirectory('wrapper')
                .childFile('gradle-wrapper.properties')
                .readAsStringSync(),
            'distributionBase=GRADLE_USER_HOME\n'
            'distributionPath=wrapper/dists\n'
            'zipStoreBase=GRADLE_USER_HOME\n'
            'zipStorePath=wrapper/dists\n'
            'distributionUrl=https\\://services.gradle.org/distributions/gradle-${entry.value}-all.zip\n',
          );
        }
      },
    );

    testWithoutContext('returns the gradlew path', () {
      final Directory androidDirectory = fileSystem.directory('/android')..createSync();
      androidDirectory.childFile('gradlew').createSync();
      androidDirectory.childFile('gradlew.bat').createSync();
      androidDirectory.childFile('gradle.properties').createSync();

      final FlutterProject flutterProject = FlutterProjectFactory(
        logger: BufferLogger.test(),
        fileSystem: fileSystem,
      ).fromDirectory(fileSystem.currentDirectory);

      expect(gradleUtils.getExecutable(flutterProject), androidDirectory.childFile('gradlew').path);
    });
    testWithoutContext('getGradleFileName for notWindows', () {
      expect(getGradlewFileName(notWindowsPlatform), 'gradlew');
    });
    testWithoutContext('getGradleFileName for windows', () {
      expect(getGradlewFileName(windowsPlatform), 'gradlew.bat');
    });

    testWithoutContext('returns the gradle properties file', () async {
      final Directory androidDirectory = fileSystem.directory('/android')..createSync();
      final Directory wrapperDirectory =
          androidDirectory
              .childDirectory(gradleDirectoryName)
              .childDirectory(gradleWrapperDirectoryName)
            ..createSync(recursive: true);
      final File expectedFile = await wrapperDirectory
          .childFile(gradleWrapperPropertiesFilename)
          .create();
      final File gradleWrapperFile = getGradleWrapperFile(androidDirectory);
      expect(gradleWrapperFile.path, expectedFile.path);
    });

    testWithoutContext('returns the gradle wrapper version', () async {
      const expectedVersion = '7.4.2';
      final Directory androidDirectory = fileSystem.directory('/android')..createSync();
      final Directory wrapperDirectory =
          androidDirectory.childDirectory('gradle').childDirectory('wrapper')
            ..createSync(recursive: true);
      wrapperDirectory.childFile('gradle-wrapper.properties').writeAsStringSync('''
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\\://services.gradle.org/distributions/gradle-$expectedVersion-all.zip
''');

      expect(
        await getGradleVersion(androidDirectory, BufferLogger.test(), FakeProcessManager.empty()),
        expectedVersion,
      );
    });

    testWithoutContext('ignores gradle comments', () async {
      const expectedVersion = '7.4.2';
      final Directory androidDirectory = fileSystem.directory('/android')..createSync();
      final Directory wrapperDirectory =
          androidDirectory.childDirectory('gradle').childDirectory('wrapper')
            ..createSync(recursive: true);
      wrapperDirectory.childFile('gradle-wrapper.properties').writeAsStringSync('''
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
# distributionUrl=https\\://services.gradle.org/distributions/gradle-8.0.2-all.zip
distributionUrl=https\\://services.gradle.org/distributions/gradle-$expectedVersion-all.zip
# distributionUrl=https\\://services.gradle.org/distributions/gradle-8.0.2-all.zip
''');

      expect(
        await getGradleVersion(androidDirectory, BufferLogger.test(), FakeProcessManager.empty()),
        expectedVersion,
      );
    });

    testWithoutContext('returns gradlew version, whitespace, location', () async {
      const expectedVersion = '7.4.2';
      final Directory androidDirectory = fileSystem.directory('/android')..createSync();
      final Directory wrapperDirectory =
          androidDirectory.childDirectory('gradle').childDirectory('wrapper')
            ..createSync(recursive: true);
      // Distribution url is not the last line.
      // Whitespace around distribution url.
      wrapperDirectory.childFile('gradle-wrapper.properties').writeAsStringSync('''
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl = https\\://services.gradle.org/distributions/gradle-$expectedVersion-all.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
''');

      expect(
        await getGradleVersion(androidDirectory, BufferLogger.test(), FakeProcessManager.empty()),
        expectedVersion,
      );
    });

    testWithoutContext('does not crash on hypothetical new format', () async {
      final Directory androidDirectory = fileSystem.directory('/android')..createSync();
      final Directory wrapperDirectory =
          androidDirectory.childDirectory('gradle').childDirectory('wrapper')
            ..createSync(recursive: true);
      // Distribution url is not the last line.
      // Whitespace around distribution url.
      wrapperDirectory
          .childFile('gradle-wrapper.properties')
          .writeAsStringSync(
            r'distributionUrl=https\://services.gradle.org/distributions/gradle_7.4.2_all.zip',
          );

      // FakeProcessManager.any is used here and not in other getGradleVersion
      // tests because this test does not care about process fallback logic.
      expect(
        await getGradleVersion(androidDirectory, BufferLogger.test(), FakeProcessManager.any()),
        isNull,
      );
    });

    testWithoutContext('returns the installed gradle version', () async {
      const expectedVersion = '7.4.2';
      const gradleOutput =
          '''

------------------------------------------------------------
Gradle $expectedVersion
------------------------------------------------------------

Build time:   2022-03-31 15:25:29 UTC
Revision:     540473b8118064efcc264694cbcaa4b677f61041

Kotlin:       1.5.31
Groovy:       3.0.9
Ant:          Apache Ant(TM) version 1.10.11 compiled on July 10 2021
JVM:          11.0.18 (Azul Systems, Inc. 11.0.18+10-LTS)
OS:           Mac OS X 13.2.1 aarch64
''';
      final Directory androidDirectory = fileSystem.directory('/android')..createSync();
      final ProcessManager processManager = FakeProcessManager.empty()
        ..addCommand(
          const FakeCommand(command: <String>['gradle', gradleVersionsFlag], stdout: gradleOutput),
        );

      expect(
        await getGradleVersion(androidDirectory, BufferLogger.test(), processManager),
        expectedVersion,
      );
    });

    testWithoutContext('returns the installed gradle with whitespace formatting', () async {
      const expectedVersion = '7.4.2';
      const gradleOutput = 'Gradle   $expectedVersion';
      final Directory androidDirectory = fileSystem.directory('/android')..createSync();
      final ProcessManager processManager = FakeProcessManager.empty()
        ..addCommand(
          const FakeCommand(command: <String>['gradle', gradleVersionsFlag], stdout: gradleOutput),
        );

      expect(
        await getGradleVersion(androidDirectory, BufferLogger.test(), processManager),
        expectedVersion,
      );
    });

    testWithoutContext(
      'returns the AGP version when set in Groovy build file as classpath with single quotes and commented line',
      () async {
        const expectedVersion = '7.3.0';
        final Directory androidDirectory = fileSystem.directory('/android')..createSync();
        androidDirectory.childFile('build.gradle').writeAsStringSync('''
buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        // Decoy value to ensure we ignore commented out lines.
        // classpath 'com.android.tools.build:gradle:1.1.1'
        classpath 'com.android.tools.build:gradle:$expectedVersion'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
''');

        expect(getAgpVersion(androidDirectory, BufferLogger.test()), expectedVersion);
      },
    );

    testWithoutContext(
      'returns the AGP version when set in Kotlin build file as classpath',
      () async {
        const expectedVersion = '7.3.0';
        final Directory androidDirectory = fileSystem.directory('/android')..createSync();
        androidDirectory.childFile('build.gradle.kts').writeAsStringSync('''
buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:$expectedVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
''');

        expect(getAgpVersion(androidDirectory, BufferLogger.test()), expectedVersion);
      },
    );

    testWithoutContext(
      'returns the AGP version when set in Groovy build file as compileOnly with double quotes',
      () async {
        const expectedVersion = '7.1.0';
        final Directory androidDirectory = fileSystem.directory('/android')..createSync();
        androidDirectory.childFile('build.gradle.kts').writeAsStringSync('''
dependencies {
    // compileOnly "com.android.tools.build:gradle:0.1.0" // Decoy version
    compileOnly "com.android.tools.build:gradle:$expectedVersion"
}
''');

        expect(getAgpVersion(androidDirectory, BufferLogger.test()), expectedVersion);
      },
    );
    testWithoutContext(
      'returns the AGP version when set in Kotlin build file as compileOnly',
      () async {
        const expectedVersion = '7.1.0';
        final Directory androidDirectory = fileSystem.directory('/android')..createSync();
        androidDirectory.childFile('build.gradle.kts').writeAsStringSync('''
dependencies {
    // compileOnly("com.android.tools.build:gradle:0.0.1") // Decoy version
    compileOnly("com.android.tools.build:gradle:$expectedVersion")
}
''');

        expect(getAgpVersion(androidDirectory, BufferLogger.test()), expectedVersion);
      },
    );
    testWithoutContext('returns the AGP version when set in Groovy build file as plugin', () async {
      const expectedVersion = '6.8';
      final Directory androidDirectory = fileSystem.directory('/android')..createSync();
      androidDirectory.childFile('build.gradle').writeAsStringSync('''
plugins {
    id 'com.android.application' version '$expectedVersion' apply false
}
      ''');
      expect(getAgpVersion(androidDirectory, BufferLogger.test()), expectedVersion);
    });

    testWithoutContext('returns the AGP version when set in Kotlin build file as plugin', () async {
      const expectedVersion = '7.2.0';
      final Directory androidDirectory = fileSystem.directory('/android')..createSync();
      androidDirectory.childFile('build.gradle.kts').writeAsStringSync('''
plugins {
    id("com.android.application") version "$expectedVersion" apply false
}
      ''');
      expect(getAgpVersion(androidDirectory, BufferLogger.test()), expectedVersion);
    });

    testWithoutContext(
      'returns the AGP version when set in Groovy build file as plugin with comment',
      () async {
        const expectedVersion = '6.8';
        final Directory androidDirectory = fileSystem.directory('/android')..createSync();
        androidDirectory.childFile('build.gradle').writeAsStringSync('''
plugins {
    // id 'com.android.application' version '0.1' apply false // Decoy comment
    id 'com.android.application' version '$expectedVersion' apply false
}
      ''');
        expect(getAgpVersion(androidDirectory, BufferLogger.test()), expectedVersion);
      },
    );

    testWithoutContext(
      'returns the AGP version when set in Kotlin build file as plugin with comment',
      () async {
        const expectedVersion = '7.2.0';
        final Directory androidDirectory = fileSystem.directory('/android')..createSync();
        androidDirectory.childFile('build.gradle.kts').writeAsStringSync('''
plugins {
    // id("com.android.application") version "0.1.0" apply false // Decoy comment
    id("com.android.application") version "$expectedVersion" apply false
}
      ''');
        expect(getAgpVersion(androidDirectory, BufferLogger.test()), expectedVersion);
      },
    );

    testWithoutContext('prefers the AGP version when set in Groovy, ignores Kotlin', () async {
      const versionInGroovy = '7.3.0';
      const versionInKotlin = '7.4.2';
      final Directory androidDirectory = fileSystem.directory('/android')..createSync();

      androidDirectory.childFile('build.gradle').writeAsStringSync('''
buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:$versionInGroovy'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
''');

      androidDirectory.childFile('build.gradle.kts').writeAsStringSync('''
buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:$versionInKotlin")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
''');

      expect(getAgpVersion(androidDirectory, BufferLogger.test()), versionInGroovy);
    });

    testWithoutContext('returns null when AGP version not set', () async {
      final Directory androidDirectory = fileSystem.directory('/android')..createSync();
      androidDirectory.childFile('build.gradle').writeAsStringSync('''
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
    }
}
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
''');

      expect(getAgpVersion(androidDirectory, BufferLogger.test()), null);
    });
    testWithoutContext('returns the AGP version when beta', () async {
      final Directory androidDirectory = fileSystem.directory('/android')..createSync();
      androidDirectory.childFile('build.gradle').writeAsStringSync(r'''
buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0-beta03'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
''');

      expect(getAgpVersion(androidDirectory, BufferLogger.test()), '7.3.0');
    });

    testWithoutContext('returns the AGP version when in Groovy settings as plugin', () async {
      final Directory androidDirectory = fileSystem.directory('/android')..createSync();
      // File must exist and can not have agp defined.
      androidDirectory.childFile('build.gradle').writeAsStringSync(r'');
      androidDirectory.childFile('settings.gradle').writeAsStringSync(r'''
pluginManagement {
    plugins {
        id 'dev.flutter.flutter-gradle-plugin' version '1.0.0' apply false
        id 'dev.flutter.flutter-plugin-loader' version '1.0.0'
        // Decoy value to ensure we ignore commented out lines.
        // id 'com.android.application' version '6.1.0' apply false
        id 'com.android.application' version '8.1.0' apply false
    }
}
''');

      expect(getAgpVersion(androidDirectory, BufferLogger.test()), '8.1.0');
    });

    testWithoutContext('returns the AGP version when in Kotlin settings as plugin', () async {
      final Directory androidDirectory = fileSystem.directory('/android')..createSync();
      // File must exist and cannot have agp defined.
      androidDirectory.childFile('build.gradle.kts').writeAsStringSync(r'');
      androidDirectory.childFile('settings.gradle.kts').writeAsStringSync(r'''
pluginManagement {
  plugins {
      id("dev.flutter.flutter-plugin-loader") version "1.0.0"
      // Decoy value to ensure we ignore commented out lines.
      // id("com.android.application") version "6.1.0" apply false /
      id("com.android.application") version "7.5.0" apply false
  }
}
''');

      expect(getAgpVersion(androidDirectory, BufferLogger.test()), '7.5.0');
    });

    testWithoutContext(
      'returns the AGP version when in Kotlin settings as plugin adversarial commenting',
      () async {
        final Directory androidDirectory = fileSystem.directory('/android')..createSync();
        // File must exist and cannot have agp defined.
        androidDirectory.childFile('build.gradle.kts').writeAsStringSync(r'');
        androidDirectory.childFile('settings.gradle.kts').writeAsStringSync(r'''
pluginManagement {
  plugins {
      id("dev.flutter.flutter-plugin-loader") version "1.0.0"
      // Decoy value to ensure we ignore commented out lines.
      // id("com.android.application") version "6.1.0" apply false /
      id("com.android.application") version "7.5.0" apply false // id("com.android.application") version "6.2.0" apply false
  }
}
''');

        expect(getAgpVersion(androidDirectory, BufferLogger.test()), '7.5.0');
      },
    );
    testWithoutContext('returns null when agp version is misconfigured', () async {
      final Directory androidDirectory = fileSystem.directory('/android')..createSync();
      androidDirectory.childFile('build.gradle.kts').writeAsStringSync('''
plugins {
    `java-gradle-plugin`
    `groovy`
}

dependencies {
    // intentional typo
    compileOnl("com.android.tools.build:gradle:7.3.0")
}
''');

      expect(getAgpVersion(androidDirectory, BufferLogger.test()), null);
    });

    group('validates gradle/agp versions', () {
      final testData = <GradleAgpTestData>[
        // Values too new *these need to be updated* when
        // max known gradle and max known agp versions are updated:
        // Newer AGP version supports max gradle version.
        GradleAgpTestData(
          true,
          agpVersion: '9.1',
          gradleVersion: maxKnownAndSupportedGradleVersion,
        ),
        // Newer AGP version does not even meet current gradle version requirements.
        GradleAgpTestData(false, agpVersion: '9.1', gradleVersion: '7.3'),
        // Newer AGP version requires newer gradle version.
        GradleAgpTestData(true, agpVersion: '9.1', gradleVersion: '9.1'),

        // Template versions of Gradle/AGP.
        GradleAgpTestData(
          true,
          agpVersion: templateAndroidGradlePluginVersion,
          gradleVersion: templateDefaultGradleVersion,
        ),
        GradleAgpTestData(
          true,
          agpVersion: templateAndroidGradlePluginVersionForModule,
          gradleVersion: templateDefaultGradleVersion,
        ),

        // Minimums as defined in
        // https://developer.android.com/studio/releases/gradle-plugin#updating-gradle
        GradleAgpTestData(true, agpVersion: '9.0', gradleVersion: '9.0.0'),
        GradleAgpTestData(true, agpVersion: '8.13', gradleVersion: '8.13'),
        GradleAgpTestData(true, agpVersion: '8.12', gradleVersion: '8.13'),
        GradleAgpTestData(true, agpVersion: '8.11', gradleVersion: '8.13'),
        GradleAgpTestData(true, agpVersion: '8.10', gradleVersion: '8.11.1'),
        GradleAgpTestData(true, agpVersion: '8.9', gradleVersion: '8.11.1'),
        GradleAgpTestData(true, agpVersion: '8.8', gradleVersion: '8.10.2'),
        GradleAgpTestData(true, agpVersion: '8.7', gradleVersion: '8.9'),
        GradleAgpTestData(true, agpVersion: '8.5', gradleVersion: '8.7'),
        GradleAgpTestData(true, agpVersion: '8.4', gradleVersion: '8.6'),
        GradleAgpTestData(true, agpVersion: '8.3', gradleVersion: '8.4'),
        GradleAgpTestData(true, agpVersion: '8.2', gradleVersion: '8.2'),
        GradleAgpTestData(true, agpVersion: '8.1', gradleVersion: '8.0'),
        GradleAgpTestData(true, agpVersion: '8.0', gradleVersion: '8.0'),
        GradleAgpTestData(true, agpVersion: '7.4', gradleVersion: '7.5'),
        GradleAgpTestData(true, agpVersion: '7.3', gradleVersion: '7.4'),
        GradleAgpTestData(true, agpVersion: '7.2', gradleVersion: '7.3.3'),
        GradleAgpTestData(true, agpVersion: '7.1', gradleVersion: '7.2'),
        GradleAgpTestData(true, agpVersion: '7.0', gradleVersion: '7.0'),
        GradleAgpTestData(true, agpVersion: '4.2.0', gradleVersion: '6.7.1'),
        GradleAgpTestData(true, agpVersion: '4.1.0', gradleVersion: '6.5'),
        GradleAgpTestData(true, agpVersion: '4.0.0', gradleVersion: '6.1.1'),
        GradleAgpTestData(true, agpVersion: '3.6.0', gradleVersion: '5.6.4'),
        GradleAgpTestData(true, agpVersion: '3.5.0', gradleVersion: '5.4.1'),
        GradleAgpTestData(true, agpVersion: '3.4.0', gradleVersion: '5.1.1'),
        GradleAgpTestData(true, agpVersion: '3.3.0', gradleVersion: '4.10.1'),
        // Values too old:
        GradleAgpTestData(false, agpVersion: '3.3.0', gradleVersion: '4.9'),
        GradleAgpTestData(false, agpVersion: '7.3', gradleVersion: '7.2'),
        GradleAgpTestData(false, agpVersion: '3.0.0', gradleVersion: '7.2'),
        // Null values:
        // ignore: avoid_redundant_argument_values
        GradleAgpTestData(false, agpVersion: null, gradleVersion: '7.2'),
        // ignore: avoid_redundant_argument_values
        GradleAgpTestData(false, agpVersion: '3.0.0', gradleVersion: null),
        // ignore: avoid_redundant_argument_values
        GradleAgpTestData(false, agpVersion: null, gradleVersion: null),
        // Middle AGP cases:
        GradleAgpTestData(true, agpVersion: '8.0.1', gradleVersion: '8.0'),
        GradleAgpTestData(true, agpVersion: '7.4.1', gradleVersion: '7.5'),
        GradleAgpTestData(true, agpVersion: '7.3.1', gradleVersion: '7.4'),
        GradleAgpTestData(true, agpVersion: '7.2.1', gradleVersion: '7.3.3'),
        GradleAgpTestData(true, agpVersion: '7.1.1', gradleVersion: '7.2'),
        GradleAgpTestData(true, agpVersion: '7.0.1', gradleVersion: '7.0'),
        GradleAgpTestData(true, agpVersion: '4.2.1', gradleVersion: '6.7.1'),
        GradleAgpTestData(true, agpVersion: '4.1.1', gradleVersion: '6.5'),
        GradleAgpTestData(true, agpVersion: '4.0.1', gradleVersion: '6.1.1'),
        GradleAgpTestData(true, agpVersion: '3.6.1', gradleVersion: '5.6.4'),
        GradleAgpTestData(true, agpVersion: '3.5.1', gradleVersion: '5.4.1'),
        GradleAgpTestData(true, agpVersion: '3.4.1', gradleVersion: '5.1.1'),
        GradleAgpTestData(true, agpVersion: '3.3.1', gradleVersion: '4.10.1'),

        // Higher gradle cases:
        GradleAgpTestData(true, agpVersion: '9.0', gradleVersion: '9.0.0'),
        GradleAgpTestData(true, agpVersion: '8.13', gradleVersion: '8.14'),
        GradleAgpTestData(true, agpVersion: '8.12', gradleVersion: '9.0'),
        GradleAgpTestData(true, agpVersion: '8.11', gradleVersion: '8.14'),
        GradleAgpTestData(true, agpVersion: '8.10', gradleVersion: '8.13'),
        GradleAgpTestData(true, agpVersion: '8.9', gradleVersion: '8.13'),
        GradleAgpTestData(true, agpVersion: '8.8', gradleVersion: '8.11.1'),
        GradleAgpTestData(true, agpVersion: '8.7', gradleVersion: '8.10'),
        GradleAgpTestData(true, agpVersion: '8.5', gradleVersion: '8.8'),
        GradleAgpTestData(true, agpVersion: '8.4', gradleVersion: '8.7'),
        GradleAgpTestData(true, agpVersion: '8.3', gradleVersion: '8.5'),
        GradleAgpTestData(true, agpVersion: '8.2', gradleVersion: '8.3'),
        GradleAgpTestData(true, agpVersion: '8.1', gradleVersion: '8.1'),
        GradleAgpTestData(true, agpVersion: '7.4', gradleVersion: '8.0'),
        GradleAgpTestData(true, agpVersion: '7.3', gradleVersion: '7.5'),
        GradleAgpTestData(true, agpVersion: '7.2', gradleVersion: '7.4'),
        GradleAgpTestData(true, agpVersion: '7.1', gradleVersion: '7.3.3'),
        GradleAgpTestData(true, agpVersion: '7.0', gradleVersion: '7.2'),
        GradleAgpTestData(true, agpVersion: '4.2.0', gradleVersion: '7.0'),
        GradleAgpTestData(true, agpVersion: '4.1.0', gradleVersion: '6.7.1'),
        GradleAgpTestData(true, agpVersion: '4.0.0', gradleVersion: '6.5'),
        GradleAgpTestData(true, agpVersion: '3.6.0', gradleVersion: '6.1.1'),
        GradleAgpTestData(true, agpVersion: '3.5.0', gradleVersion: '5.6.4'),
        GradleAgpTestData(true, agpVersion: '3.4.0', gradleVersion: '5.4.1'),
        GradleAgpTestData(true, agpVersion: '3.3.0', gradleVersion: '5.1.1'),
      ];
      for (final data in testData) {
        test('(gradle, agp): (${data.gradleVersion}, ${data.agpVersion})', () {
          expect(
            validateGradleAndAgp(
              BufferLogger.test(),
              gradleV: data.gradleVersion,
              agpV: data.agpVersion,
            ),
            data.validPair ? isTrue : isFalse,
            reason: 'G: ${data.gradleVersion}, AGP: ${data.agpVersion}',
          );
        });
      }
    });

    FakeCommand createKgpVersionCommand(String kgpV) {
      return FakeCommand(
        command: const <String>['./gradlew', 'kgpVersion', '-q'],
        stdout:
            '''
    KGP Version: $kgpV
    ''',
      );
    }

    testWithoutContext('returns the KGP fetched from kgpVersion gradle task', () async {
      final Directory androidDirectory = fileSystem.directory('/android')..createSync();
      // Three numbered versions.
      const kgpV2 = '1.8.22';
      final processManager2 = FakeProcessManager.list(<FakeCommand>[
        createKgpVersionCommand(kgpV2),
      ]);
      expect(await getKgpVersion(androidDirectory, BufferLogger.test(), processManager2), kgpV2);
      // 2 numbered versions
      const kgpV3 = '1.9';
      final processManager3 = FakeProcessManager.list(<FakeCommand>[
        createKgpVersionCommand(kgpV3),
      ]);
      expect(await getKgpVersion(androidDirectory, BufferLogger.test(), processManager3), kgpV3);
      final processManagerNoGradle = FakeProcessManager.empty();
      processManagerNoGradle.excludedExecutables = <String>{'./gradlew'};
      expect(
        await getKgpVersion(androidDirectory, BufferLogger.test(), processManagerNoGradle),
        null,
      );
    });

    testWithoutContext(
      'returns the KGP version when in Kotlin DSL Kotlin settings as plugin',
      () async {
        final Directory androidDirectory = fileSystem.directory('/android')..createSync();
        // File must exist and cannot have kgp defined.
        androidDirectory.childFile('build.gradle.kts').writeAsStringSync(r'');
        androidDirectory.childFile('settings.gradle.kts').writeAsStringSync(r'''
pluginManagement {
  plugins {
      id("dev.flutter.flutter-plugin-loader") version "1.0.0"
      // Decoy value to ensure we ignore commented out lines.
      // id("org.jetbrains.kotlin.android") version "6.1.0" apply false // Decoy comment
      id("org.jetbrains.kotlin.android") version "1.8.22" apply false
  }
}
''');
        final processManager = FakeProcessManager.empty();
        processManager.excludedExecutables = <String>{'./gradlew'};

        expect(
          await getKgpVersion(androidDirectory, BufferLogger.test(), processManager),
          '1.8.22',
        );
      },
    );

    testWithoutContext(
      'returns the KGP version when in Groovy DSL Kotlin settings as plugin',
      () async {
        final Directory androidDirectory = fileSystem.directory('/android')..createSync();
        // File must exist and cannot have kgp defined.
        androidDirectory.childFile('build.gradle.kts').writeAsStringSync(r'');
        androidDirectory.childFile('settings.gradle.kts').writeAsStringSync(r'''
pluginManagement {
  plugins {
      id "dev.flutter.flutter-plugin-loader"  version "1.0.0"
      // Decoy value to ensure we ignore commented out lines.
      // id "org.jetbrains.kotlin.android"  version "6.1.0" apply false // Decoy comment
      id "org.jetbrains.kotlin.android" version "1.8.22" apply false
  }
}
''');
        final processManager = FakeProcessManager.empty();
        processManager.excludedExecutables = <String>{'./gradlew'};

        expect(
          await getKgpVersion(androidDirectory, BufferLogger.test(), processManager),
          '1.8.22',
        );
      },
    );

    group('validates kgp/gradle versions', () {
      final testData = <GradleKgpTestData>[
        // Values too new.
        GradleKgpTestData(true, kgpVersion: '3.0', gradleVersion: '99.99'),

        // Template versions of Gradle/AGP.
        GradleKgpTestData(
          true,
          kgpVersion: templateKotlinGradlePluginVersion,
          // TODO(reidbaker): replace with templateDefaultGradleVersion.
          gradleVersion: '8.10',
        ),

        // Kotlin version at the edge of support window.
        GradleKgpTestData(true, kgpVersion: '2.2.20', gradleVersion: '8.14'),
        GradleKgpTestData(true, kgpVersion: '2.2.10', gradleVersion: '8.14'),
        GradleKgpTestData(true, kgpVersion: '2.2.20', gradleVersion: '7.6.3'),
        GradleKgpTestData(true, kgpVersion: '2.2.10', gradleVersion: '7.6.3'),
        GradleKgpTestData(true, kgpVersion: '2.2.0', gradleVersion: '7.6.3'),
        GradleKgpTestData(true, kgpVersion: '2.1.20', gradleVersion: '8.1'),
        GradleKgpTestData(true, kgpVersion: '2.1.10', gradleVersion: '8.3'),
        GradleKgpTestData(true, kgpVersion: '2.0.21', gradleVersion: '7.6.3'),
        GradleKgpTestData(true, kgpVersion: '2.0.20', gradleVersion: '7.6.3'),
        GradleKgpTestData(true, kgpVersion: '2.0', gradleVersion: '8.5'),
        GradleKgpTestData(true, kgpVersion: '1.9.25', gradleVersion: '8.1.1'),
        GradleKgpTestData(true, kgpVersion: '1.9.20', gradleVersion: '6.8.3'),
        GradleKgpTestData(true, kgpVersion: '1.9.10', gradleVersion: '6.8.3'),
        GradleKgpTestData(true, kgpVersion: '1.9.0', gradleVersion: '7.6.0'),
        GradleKgpTestData(true, kgpVersion: '1.8.22', gradleVersion: '7.6.0'),
        GradleKgpTestData(true, kgpVersion: '1.8.20', gradleVersion: '6.8.3'),
        GradleKgpTestData(true, kgpVersion: '1.8.11', gradleVersion: '7.3.3'),
        GradleKgpTestData(true, kgpVersion: '1.8.0', gradleVersion: '7.3.3'),
        GradleKgpTestData(true, kgpVersion: '1.7.22', gradleVersion: '7.1.1'),
        GradleKgpTestData(true, kgpVersion: '1.7.20', gradleVersion: '6.7.1'),
        GradleKgpTestData(true, kgpVersion: '1.7.10', gradleVersion: '7.0.2'),
        GradleKgpTestData(true, kgpVersion: '1.7.0', gradleVersion: '6.7.1'),
        GradleKgpTestData(true, kgpVersion: '1.6.21', gradleVersion: '6.1.1'),
        GradleKgpTestData(true, kgpVersion: '1.6.20', gradleVersion: '7.0.2'),
        // Gradle at the edge of the suppport window.
        GradleKgpTestData(true, kgpVersion: '2.2.20', gradleVersion: '8.14'),
        GradleKgpTestData(true, kgpVersion: '2.2.10', gradleVersion: '8.14'),
        GradleKgpTestData(true, kgpVersion: '2.2.0', gradleVersion: '8.14'),
        GradleKgpTestData(true, kgpVersion: '2.1.21', gradleVersion: '8.12.1'),
        GradleKgpTestData(true, kgpVersion: '2.1.20', gradleVersion: '8.11.1'),
        GradleKgpTestData(true, kgpVersion: '2.1.10', gradleVersion: '8.10.2'),
        GradleKgpTestData(true, kgpVersion: '2.1.10', gradleVersion: '8.9'),
        GradleKgpTestData(true, kgpVersion: '2.1.5', gradleVersion: '8.7'),
        GradleKgpTestData(true, kgpVersion: '2.1.0', gradleVersion: '8.7'),
        GradleKgpTestData(true, kgpVersion: '2.0.20', gradleVersion: '8.6'),
        GradleKgpTestData(true, kgpVersion: '2.0.1', gradleVersion: '8.4'),
        GradleKgpTestData(true, kgpVersion: '2.0.0', gradleVersion: '8.2'),
        GradleKgpTestData(true, kgpVersion: '1.9.25', gradleVersion: '8.0'),
        GradleKgpTestData(true, kgpVersion: '1.9.10', gradleVersion: '7.6.0'),
        GradleKgpTestData(true, kgpVersion: '1.9.7', gradleVersion: '7.5'),
        GradleKgpTestData(true, kgpVersion: '1.8.21', gradleVersion: '7.4'),
        GradleKgpTestData(true, kgpVersion: '1.9.0', gradleVersion: '7.3.3'),
        GradleKgpTestData(true, kgpVersion: '1.8.0', gradleVersion: '7.2'),
        GradleKgpTestData(true, kgpVersion: '1.7.0', gradleVersion: '7.0'),
        GradleKgpTestData(true, kgpVersion: '2.0.21', gradleVersion: '7.0'),
        GradleKgpTestData(true, kgpVersion: '1.7.22', gradleVersion: '6.7.1'),
        GradleKgpTestData(true, kgpVersion: '1.6.21', gradleVersion: '6.7.1'),
        GradleKgpTestData(true, kgpVersion: '1.6.21', gradleVersion: '6.5'),
        // Kotlin newer than max known.
        GradleKgpTestData(true, kgpVersion: '2.2.29', gradleVersion: '8.12.1'),
        // Kotlin too new for gradle version.
        GradleKgpTestData(false, kgpVersion: '2.2.20', gradleVersion: '7.6.2'),
        GradleKgpTestData(false, kgpVersion: '2.2.10', gradleVersion: '7.6.2'),
        GradleKgpTestData(false, kgpVersion: '2.2.0', gradleVersion: '7.6.2'),
        GradleKgpTestData(false, kgpVersion: '2.1.20', gradleVersion: '7.6.2'),
        GradleKgpTestData(false, kgpVersion: '2.1.0', gradleVersion: '7.6.2'),
        GradleKgpTestData(false, kgpVersion: '2.0.20', gradleVersion: '6.8.2'),
        GradleKgpTestData(false, kgpVersion: '1.9.0', gradleVersion: '6.8.2'),
        GradleKgpTestData(false, kgpVersion: '1.8.0', gradleVersion: '6.8.2'),
        GradleKgpTestData(false, kgpVersion: '1.7.22', gradleVersion: '6.7.0'),
        GradleKgpTestData(false, kgpVersion: '1.7.0', gradleVersion: '6.1.1'),
        // Kotlin too old for gradle version.
        GradleKgpTestData(false, kgpVersion: '2.1.10', gradleVersion: '8.11.1'),
        GradleKgpTestData(false, kgpVersion: '2.1.0', gradleVersion: '8.11'),
        GradleKgpTestData(false, kgpVersion: '2.0.0', gradleVersion: '8.6'),
        GradleKgpTestData(false, kgpVersion: '1.9.20', gradleVersion: '8.2'),
        GradleKgpTestData(false, kgpVersion: '1.9.0', gradleVersion: '7.7'),
        GradleKgpTestData(false, kgpVersion: '1.8.20', gradleVersion: '7.7'),
        GradleKgpTestData(false, kgpVersion: '1.8.0', gradleVersion: '7.4'),
        GradleKgpTestData(false, kgpVersion: '1.7.20', gradleVersion: '7.2'),
        GradleKgpTestData(false, kgpVersion: '1.7.0', gradleVersion: '7.0.3'),
        GradleKgpTestData(false, kgpVersion: '1.6.20', gradleVersion: '7.0.3'),
        // Kotlin older than oldest supported.
        GradleKgpTestData(false, kgpVersion: '1.6.19', gradleVersion: '7.0.3'),
        // Gradle older than oldest supported.
        GradleKgpTestData(false, kgpVersion: '1.6.20', gradleVersion: '4.10'),
        // Null values:
        // ignore: avoid_redundant_argument_values
        GradleKgpTestData(false, kgpVersion: null, gradleVersion: '7.2'),
        // ignore: avoid_redundant_argument_values
        GradleKgpTestData(false, kgpVersion: '2.1', gradleVersion: null),
        // ignore: avoid_redundant_argument_values
        GradleKgpTestData(false, kgpVersion: '', gradleVersion: ''),
        // ignore: avoid_redundant_argument_values
        GradleKgpTestData(false, kgpVersion: null, gradleVersion: null),
      ];
      for (final data in testData) {
        test('(KGP, Gradle): (${data.kgpVersion}, ${data.gradleVersion})', () {
          expect(
            validateGradleAndKGP(
              BufferLogger.test(),
              gradleV: data.gradleVersion,
              kgpV: data.kgpVersion,
            ),
            data.validPair ? isTrue : isFalse,
            reason: 'KGP: ${data.kgpVersion}, G: ${data.gradleVersion}',
          );
        });
      }
    });

    group('validates KGP/AGP versions', () {
      final testData = <KgpAgpTestData>[
        // Values too new.
        KgpAgpTestData(true, kgpVersion: '3.0', agpVersion: '99.99'),

        // Template versions of Gradle/AGP.
        KgpAgpTestData(
          true,
          kgpVersion: templateKotlinGradlePluginVersion,
          agpVersion: templateAndroidGradlePluginVersion,
        ),

        // Kotlin version at the edge of support window.
        KgpAgpTestData(true, kgpVersion: '2.2.20', agpVersion: '8.11.1'),
        KgpAgpTestData(true, kgpVersion: '2.2.20', agpVersion: '7.3.1'),
        KgpAgpTestData(true, kgpVersion: '2.2.0', agpVersion: '8.10.0'),
        KgpAgpTestData(true, kgpVersion: '2.1.21', agpVersion: '7.3.1'),
        KgpAgpTestData(true, kgpVersion: '2.1.20', agpVersion: '8.7.2'),
        KgpAgpTestData(true, kgpVersion: '2.1.20', agpVersion: '7.3.1'),
        // AGP Versions not "fully supported" by kotlin
        KgpAgpTestData(true, kgpVersion: '2.2.20', agpVersion: '8.13'),
        KgpAgpTestData(true, kgpVersion: '2.2.20', agpVersion: '8.12'),
        // Gradle versions inspired by
        // https://developer.android.com/build/releases/gradle-plugin#expandable-1
        KgpAgpTestData(true, kgpVersion: '2.1.5', agpVersion: '8.7'),
        KgpAgpTestData(true, kgpVersion: '2.1.10', agpVersion: '8.6'),
        KgpAgpTestData(true, kgpVersion: '2.0.21', agpVersion: '8.5'),
        KgpAgpTestData(true, kgpVersion: '2.0.20', agpVersion: '8.4'),
        KgpAgpTestData(true, kgpVersion: '2.0', agpVersion: '8.3.1'),
        KgpAgpTestData(true, kgpVersion: '2.1.5', agpVersion: '8.2'),
        KgpAgpTestData(true, kgpVersion: '1.9.25', agpVersion: '8.1'),
        KgpAgpTestData(true, kgpVersion: '1.9.20', agpVersion: '8.0'),
        KgpAgpTestData(true, kgpVersion: '1.9.10', agpVersion: '7.4'),
        KgpAgpTestData(true, kgpVersion: '1.8.20', agpVersion: '7.4'),
        KgpAgpTestData(true, kgpVersion: '1.8.21', agpVersion: '7.3'),
        KgpAgpTestData(true, kgpVersion: '1.8.11', agpVersion: '7.2.1'),
        KgpAgpTestData(true, kgpVersion: '1.8.0', agpVersion: '7.2.1'),
        KgpAgpTestData(true, kgpVersion: '1.8.0', agpVersion: '7.1'),
        KgpAgpTestData(true, kgpVersion: '1.7.20', agpVersion: '7.0.4'),
        KgpAgpTestData(true, kgpVersion: '1.7.22', agpVersion: '7.0'),
        KgpAgpTestData(true, kgpVersion: '1.8.22', agpVersion: '4.2.0'),
        KgpAgpTestData(true, kgpVersion: '1.6.20', agpVersion: '4.1.0'),
        // Kotlin newer than max known.
        KgpAgpTestData(true, kgpVersion: '2.2.29', agpVersion: '8.7.2'),
        // Kotlin too new for AGP version.
        KgpAgpTestData(false, kgpVersion: '2.2.20', agpVersion: '7.3.0'),
        KgpAgpTestData(false, kgpVersion: '2.2.0', agpVersion: '7.3.0'),
        KgpAgpTestData(false, kgpVersion: '2.1.20', agpVersion: '7.3.0'),
        KgpAgpTestData(false, kgpVersion: '2.1.10', agpVersion: '7.3.0'),
        KgpAgpTestData(false, kgpVersion: '2.0.21', agpVersion: '7.1.2'),
        KgpAgpTestData(false, kgpVersion: '2.0.0', agpVersion: '7.1.2'),
        KgpAgpTestData(false, kgpVersion: '1.9.25', agpVersion: '4.2.1'),
        KgpAgpTestData(false, kgpVersion: '1.8.20', agpVersion: '4.1.2'),
        // Kotlin too old for gradle version.
        KgpAgpTestData(false, kgpVersion: '2.0.20', agpVersion: '8.7.2'),
        KgpAgpTestData(false, kgpVersion: '2.0.20', agpVersion: '8.6'),
        KgpAgpTestData(false, kgpVersion: '2.0.0', agpVersion: '8.4'),
        KgpAgpTestData(false, kgpVersion: '1.9.20', agpVersion: '8.2'),
        KgpAgpTestData(false, kgpVersion: '1.9.0', agpVersion: '7.5'),
        KgpAgpTestData(false, kgpVersion: '1.8.20', agpVersion: '7.5'),
        KgpAgpTestData(false, kgpVersion: '1.8.1', agpVersion: '7.3'),
        KgpAgpTestData(false, kgpVersion: '1.7.20', agpVersion: '7.1'),
        KgpAgpTestData(false, kgpVersion: '1.7.0', agpVersion: '7.0.3'),
        KgpAgpTestData(false, kgpVersion: '1.6.19', agpVersion: '7.0.3'),
        // Unknown values.
        KgpAgpTestData(
          false,
          kgpVersion: oldestDocumentedKgpCompatabilityVersion,
          agpVersion: oldestConsideredAgpVersion,
        ),
        // Null values:
        // ignore: avoid_redundant_argument_values
        KgpAgpTestData(false, kgpVersion: null, agpVersion: '7.2'),
        // ignore: avoid_redundant_argument_values
        KgpAgpTestData(false, kgpVersion: '2.1', agpVersion: null),
        // ignore: avoid_redundant_argument_values
        KgpAgpTestData(false, kgpVersion: '', agpVersion: ''),
        // ignore: avoid_redundant_argument_values
        KgpAgpTestData(false, kgpVersion: null, agpVersion: null),
      ];
      for (final data in testData) {
        test('(KGP, AGP): (${data.kgpVersion}, ${data.agpVersion})', () {
          expect(
            validateAgpAndKgp(BufferLogger.test(), agpV: data.agpVersion, kgpV: data.kgpVersion),
            data.validPair ? isTrue : isFalse,
            reason: 'KGP: ${data.kgpVersion}, AGP: ${data.agpVersion}',
          );
        });
      }
    });

    group('Parse gradle version from distribution url', () {
      testWithoutContext('null distribution url returns null version', () {
        expect(parseGradleVersionFromDistributionUrl(null), null);
      });

      testWithoutContext('unparseable format returns null', () {
        const distributionUrl = 'aString';
        expect(parseGradleVersionFromDistributionUrl(distributionUrl), null);
      });

      testWithoutContext("recognizable 'all' format returns correct version", () {
        const distributionUrl =
            r'distributionUrl=https\://services.gradle.org/distributions/gradle-6.7-all.zip';
        expect(parseGradleVersionFromDistributionUrl(distributionUrl), '6.7');
      });

      testWithoutContext("recognizable 'bin' format returns correct version", () {
        const distributionUrl =
            r'distributionUrl=https\://services.gradle.org/distributions/gradle-6.7-bin.zip';
        expect(parseGradleVersionFromDistributionUrl(distributionUrl), '6.7');
      });

      testWithoutContext("recognizable 'rc' format returns correct version", () {
        const distributionUrl =
            r'distributionUrl=https\://services.gradle.org/distributions/gradle-8.1-rc-3-all.zip';
        expect(parseGradleVersionFromDistributionUrl(distributionUrl), '8.1');
      });
    });

    group('validates java/gradle versions', () {
      final testData = <JavaGradleTestData>[
        // Values too new *these need to be updated* when
        // max supported java and max known gradle versions are updated:
        // Newer tools version does not even meet current gradle version requirements.
        JavaGradleTestData(false, javaVersion: '20', gradleVersion: '7.5'),
        // Newer tools version requires newer gradle version.
        JavaGradleTestData(true, javaVersion: '20', gradleVersion: '8.1'),
        // Max known unsupported Java version.
        JavaGradleTestData(
          true,
          javaVersion: '24',
          gradleVersion: maxKnownAndSupportedGradleVersion,
        ),
        // Minimums as defined in
        // https://docs.gradle.org/current/userguide/compatibility.html#java
        JavaGradleTestData(true, javaVersion: '19', gradleVersion: '7.6'),
        JavaGradleTestData(true, javaVersion: '18', gradleVersion: '7.5'),
        JavaGradleTestData(true, javaVersion: '17', gradleVersion: '7.3'),
        JavaGradleTestData(true, javaVersion: '16', gradleVersion: '7.0'),
        JavaGradleTestData(true, javaVersion: '15', gradleVersion: '6.7'),
        JavaGradleTestData(true, javaVersion: '14', gradleVersion: '6.3'),
        JavaGradleTestData(true, javaVersion: '13', gradleVersion: '6.0'),
        JavaGradleTestData(true, javaVersion: '12', gradleVersion: '5.4'),
        JavaGradleTestData(true, javaVersion: '11', gradleVersion: '5.0'),
        JavaGradleTestData(true, javaVersion: '1.10', gradleVersion: '4.7'),
        JavaGradleTestData(true, javaVersion: '1.9', gradleVersion: '4.3'),
        JavaGradleTestData(true, javaVersion: '1.8', gradleVersion: '2.0'),
        // Gradle too old for Java version.
        JavaGradleTestData(false, javaVersion: '19', gradleVersion: '6.7'),
        JavaGradleTestData(false, javaVersion: '11', gradleVersion: '4.10.1'),
        JavaGradleTestData(false, javaVersion: '1.9', gradleVersion: '4.1'),
        // Null values:
        // ignore: avoid_redundant_argument_values
        JavaGradleTestData(false, javaVersion: null, gradleVersion: '7.2'),
        // ignore: avoid_redundant_argument_values
        JavaGradleTestData(false, javaVersion: '11', gradleVersion: null),
        // ignore: avoid_redundant_argument_values
        JavaGradleTestData(false, javaVersion: null, gradleVersion: null),
        // Middle Java cases:
        // https://www.java.com/releases/
        JavaGradleTestData(true, javaVersion: '19.0.2', gradleVersion: '8.0.2'),
        JavaGradleTestData(true, javaVersion: '19.0.2', gradleVersion: '8.0.0'),
        JavaGradleTestData(true, javaVersion: '18.0.2', gradleVersion: '8.0.2'),
        JavaGradleTestData(true, javaVersion: '17.0.3', gradleVersion: '7.5'),
        JavaGradleTestData(true, javaVersion: '16.0.1', gradleVersion: '7.3'),
        JavaGradleTestData(true, javaVersion: '15.0.2', gradleVersion: '7.3'),
        JavaGradleTestData(true, javaVersion: '14.0.1', gradleVersion: '7.0'),
        JavaGradleTestData(true, javaVersion: '13.0.2', gradleVersion: '6.7'),
        JavaGradleTestData(true, javaVersion: '12.0.2', gradleVersion: '6.3'),
        JavaGradleTestData(true, javaVersion: '11.0.18', gradleVersion: '6.0'),
        // Higher gradle cases:
        JavaGradleTestData(true, javaVersion: '19', gradleVersion: '8.0'),
        JavaGradleTestData(true, javaVersion: '18', gradleVersion: '8.0'),
        JavaGradleTestData(true, javaVersion: '17', gradleVersion: '7.5'),
        JavaGradleTestData(true, javaVersion: '16', gradleVersion: '7.3'),
        JavaGradleTestData(true, javaVersion: '15', gradleVersion: '7.3'),
        JavaGradleTestData(true, javaVersion: '14', gradleVersion: '7.0'),
        JavaGradleTestData(true, javaVersion: '13', gradleVersion: '6.7'),
        JavaGradleTestData(true, javaVersion: '12', gradleVersion: '6.3'),
        JavaGradleTestData(true, javaVersion: '11', gradleVersion: '6.0'),
        JavaGradleTestData(true, javaVersion: '1.10', gradleVersion: '5.4'),
        JavaGradleTestData(true, javaVersion: '1.9', gradleVersion: '5.0'),
        JavaGradleTestData(true, javaVersion: '1.8', gradleVersion: '4.3'),
        // https://github.com/flutter/flutter/issues/175669
        JavaGradleTestData(true, javaVersion: '17.0.15', gradleVersion: '8.13'),
        JavaGradleTestData(true, javaVersion: '21.0.7', gradleVersion: '8.13'),
      ];

      for (final data in testData) {
        testWithoutContext('(Java, gradle): (${data.javaVersion}, ${data.gradleVersion})', () {
          expect(
            validateJavaAndGradle(
              BufferLogger.test(),
              javaVersion: data.javaVersion,
              gradleVersion: data.gradleVersion,
            ),
            data.validPair ? isTrue : isFalse,
            reason: 'J: ${data.javaVersion}, G: ${data.gradleVersion}',
          );
        });
      }
    });
  });

  testWithoutContext('agp versions validation', () {
    final Version? parsedTemplateAndroidGradlePluginVersion = Version.parse(
      templateAndroidGradlePluginVersion,
    );
    final Version? parsedMaxKnownAgpVersionWithFullKotlinSupport = Version.parse(
      maxKnownAgpVersionWithFullKotlinSupport,
    );
    final Version? parsedMaxKnownAndSupportedAgpVersion = Version.parse(
      maxKnownAndSupportedAgpVersion,
    );
    final Version? parsedMaxKnownAgpVersion = Version.parse(maxKnownAgpVersion);

    expect(
      parsedTemplateAndroidGradlePluginVersion! <= parsedMaxKnownAgpVersionWithFullKotlinSupport!,
      isTrue,
      reason:
          'Template AGP version ($parsedTemplateAndroidGradlePluginVersion) '
          'is higher than maxKnownAgpVersionWithFullKotlinSupport ($parsedMaxKnownAgpVersionWithFullKotlinSupport). '
          'Please update the maxKnownAgpVersionWithFullKotlinSupport',
    );
    expect(
      parsedMaxKnownAndSupportedAgpVersion! <= parsedMaxKnownAgpVersion!,
      isTrue,
      reason:
          'maxKnownAndSupportedAgpVersion ($parsedMaxKnownAndSupportedAgpVersion) '
          'is higher than maxKnownAgpVersion ($parsedMaxKnownAgpVersion). '
          'Please update the maxKnownAgpVersion',
    );
    expect(
      parsedMaxKnownAgpVersionWithFullKotlinSupport < parsedMaxKnownAgpVersion,
      isTrue,
      reason:
          'maxKnownAgpVersionWithFullKotlinSupport ($parsedMaxKnownAgpVersionWithFullKotlinSupport) '
          'is higher than or equal to maxKnownAgpVersion ($parsedMaxKnownAgpVersion). '
          'Please update the maxKnownAgpVersion',
    );
  });

  group('getGradleVersionForAndroidPlugin', () {
    late FileSystem fileSystem;
    late Logger testLogger;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      testLogger = BufferLogger.test();
    });

    testWithoutContext('prefers build.gradle over build.gradle.kts', () async {
      const versionInGroovy = '4.0.0';
      const versionInKotlin = '7.4.2';
      final Directory androidDirectory = fileSystem.directory('/android')..createSync();

      androidDirectory.childFile('build.gradle').writeAsStringSync('''
buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:$versionInGroovy'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
''');

      androidDirectory.childFile('build.gradle.kts').writeAsStringSync('''
buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:$versionInKotlin")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
''');

      expect(
        getGradleVersionForAndroidPlugin(androidDirectory, testLogger),
        '6.7', // as per compatibility matrix in gradle_utils.dart
      );
    });
  });

  group('validates java/AGP versions', () {
    final testData = <JavaAgpTestData>[
      // Strictly too old Java versions for known AGP versions.
      JavaAgpTestData(false, javaVersion: '1.6', agpVersion: maxKnownAgpVersion),
      JavaAgpTestData(false, javaVersion: '1.6', agpVersion: maxKnownAndSupportedAgpVersion),
      JavaAgpTestData(false, javaVersion: '1.6', agpVersion: '4.2'),
      // Strictly too old AGP versions.
      JavaAgpTestData(false, javaVersion: '1.8', agpVersion: '1.0'),
      JavaAgpTestData(false, javaVersion: '1.8', agpVersion: '4.1'),
      JavaAgpTestData(false, javaVersion: '1.8', agpVersion: '2.3'),
      // Strictly too new Java versions for defined AGP versions.
      JavaAgpTestData(true, javaVersion: '18', agpVersion: '4.2'),
      JavaAgpTestData(true, javaVersion: '11', agpVersion: '4.2.0'),
      JavaAgpTestData(true, javaVersion: '12', agpVersion: '7.0'),
      JavaAgpTestData(true, javaVersion: '13', agpVersion: '7.1.3'),
      JavaAgpTestData(true, javaVersion: '14', agpVersion: '7.2.2'),
      JavaAgpTestData(true, javaVersion: '17', agpVersion: '7.3'),
      JavaAgpTestData(true, javaVersion: '18', agpVersion: '7.4'),
      JavaAgpTestData(true, javaVersion: '19', agpVersion: '8.0'),
      JavaAgpTestData(true, javaVersion: '19', agpVersion: '8.1'),
      JavaAgpTestData(true, javaVersion: '19', agpVersion: '8.2'),
      JavaAgpTestData(true, javaVersion: '20', agpVersion: '8.3'),
      JavaAgpTestData(true, javaVersion: '21', agpVersion: '8.4'),
      JavaAgpTestData(true, javaVersion: '21', agpVersion: '8.5'),
      JavaAgpTestData(true, javaVersion: '21', agpVersion: '8.6'),
      JavaAgpTestData(true, javaVersion: '22', agpVersion: '8.7'),
      JavaAgpTestData(true, javaVersion: '23', agpVersion: '8.8'),
      JavaAgpTestData(true, javaVersion: '23', agpVersion: '8.9'),
      JavaAgpTestData(true, javaVersion: '23', agpVersion: '8.10'),
      JavaAgpTestData(true, javaVersion: '23', agpVersion: '8.11'),
      JavaAgpTestData(true, javaVersion: '23', agpVersion: '8.12'),
      JavaAgpTestData(true, javaVersion: '23', agpVersion: '8.13'),
      JavaAgpTestData(true, javaVersion: '25', agpVersion: '9.0'),
      // Strictly too new AGP versions.
      // *The tests that follow need to be updated* when max supported AGP versions are updated:
      JavaAgpTestData(true, javaVersion: '26', agpVersion: '10.0'),
      JavaAgpTestData(true, javaVersion: '21', agpVersion: '10.0'),
      JavaAgpTestData(true, javaVersion: '17', agpVersion: '10.0'),
      JavaAgpTestData(true, javaVersion: '17.0.3', agpVersion: '10.0'),
      // Java 17 & patch versions compatibility cases
      // *The tests that follow need to be updated* when maxKnownAndSupportedAgpVersion is
      // updated:
      JavaAgpTestData(true, javaVersion: '17', agpVersion: maxKnownAndSupportedAgpVersion),
      JavaAgpTestData(true, javaVersion: '17', agpVersion: '9.0'),
      JavaAgpTestData(true, javaVersion: '17', agpVersion: '8.13'),
      JavaAgpTestData(true, javaVersion: '17', agpVersion: '8.12'),
      JavaAgpTestData(true, javaVersion: '17', agpVersion: '8.11'),
      JavaAgpTestData(true, javaVersion: '17', agpVersion: '8.10'),
      JavaAgpTestData(true, javaVersion: '17', agpVersion: '8.9.1'),
      JavaAgpTestData(true, javaVersion: '17', agpVersion: '8.8'),
      JavaAgpTestData(true, javaVersion: '17', agpVersion: '8.7'),
      JavaAgpTestData(true, javaVersion: '17', agpVersion: '8.6'),
      JavaAgpTestData(true, javaVersion: '17', agpVersion: '8.5'),
      JavaAgpTestData(true, javaVersion: '17', agpVersion: '8.4'),
      JavaAgpTestData(true, javaVersion: '17', agpVersion: '8.3'),
      JavaAgpTestData(true, javaVersion: '17', agpVersion: '8.1'),
      JavaAgpTestData(true, javaVersion: '17', agpVersion: '8.0'),
      JavaAgpTestData(true, javaVersion: '17', agpVersion: '7.4'),
      JavaAgpTestData(true, javaVersion: '25', agpVersion: maxKnownAndSupportedAgpVersion),
      JavaAgpTestData(true, javaVersion: '17.0.3', agpVersion: '8.8'),
      JavaAgpTestData(true, javaVersion: '17.0.3', agpVersion: '8.7'),
      JavaAgpTestData(true, javaVersion: '17.0.3', agpVersion: '8.6'),
      JavaAgpTestData(true, javaVersion: '17.0.3', agpVersion: '8.5'),
      JavaAgpTestData(true, javaVersion: '17.0.3', agpVersion: '8.4'),
      JavaAgpTestData(true, javaVersion: '17.0.3', agpVersion: '8.3'),
      JavaAgpTestData(true, javaVersion: '17.0.3', agpVersion: '8.2'),
      JavaAgpTestData(true, javaVersion: '17.0.3', agpVersion: '8.1'),
      JavaAgpTestData(true, javaVersion: '17.0.3', agpVersion: '8.0'),
      JavaAgpTestData(true, javaVersion: '17.0.3', agpVersion: '7.4'),
      // Java 11 & patch versions compatibility cases
      JavaAgpTestData(false, javaVersion: '11', agpVersion: '8.0'),
      JavaAgpTestData(true, javaVersion: '11', agpVersion: '7.4'),
      JavaAgpTestData(true, javaVersion: '11', agpVersion: '7.2'),
      JavaAgpTestData(true, javaVersion: '11', agpVersion: '7.0'),
      JavaAgpTestData(true, javaVersion: '11', agpVersion: '4.2'),
      JavaAgpTestData(false, javaVersion: '11.0.18', agpVersion: '8.0'),
      JavaAgpTestData(true, javaVersion: '11.0.18', agpVersion: '7.4'),
      JavaAgpTestData(true, javaVersion: '11.0.18', agpVersion: '7.2'),
      JavaAgpTestData(true, javaVersion: '11.0.18', agpVersion: '7.0'),
      JavaAgpTestData(true, javaVersion: '11.0.18', agpVersion: '4.2'),
      // Java 8 compatibility cases
      JavaAgpTestData(false, javaVersion: '1.8', agpVersion: '7.0'),
      JavaAgpTestData(
        true,
        javaVersion: '1.8',
        agpVersion: oldestDocumentedJavaAgpCompatibilityVersion,
      ), // agpVersion = 4.2
      // Java versions too old for the AGP versions
      JavaAgpTestData(false, javaVersion: '1.8', agpVersion: '7.0'),
      JavaAgpTestData(false, javaVersion: '1.8', agpVersion: '7.1.3'),
      JavaAgpTestData(false, javaVersion: '1.8', agpVersion: '7.2.2'),
      JavaAgpTestData(false, javaVersion: '1.8', agpVersion: '7.3'),
      JavaAgpTestData(false, javaVersion: '1.8', agpVersion: '7.4'),
      JavaAgpTestData(false, javaVersion: '12', agpVersion: '8.0'),
      JavaAgpTestData(false, javaVersion: '13', agpVersion: '8.1'),
      JavaAgpTestData(false, javaVersion: '14', agpVersion: '8.2'),
      JavaAgpTestData(false, javaVersion: '15', agpVersion: '8.3'),
      JavaAgpTestData(false, javaVersion: '16', agpVersion: '8.4'),
      JavaAgpTestData(false, javaVersion: '16', agpVersion: '8.5'),
      JavaAgpTestData(false, javaVersion: '16', agpVersion: '8.6'),
      JavaAgpTestData(false, javaVersion: '16', agpVersion: '8.7'),
      JavaAgpTestData(false, javaVersion: '16', agpVersion: '8.8'),
      JavaAgpTestData(false, javaVersion: '16', agpVersion: '8.9'),
      JavaAgpTestData(false, javaVersion: '16', agpVersion: '8.10'),
      JavaAgpTestData(false, javaVersion: '16', agpVersion: '8.11'),
      JavaAgpTestData(false, javaVersion: '16', agpVersion: '8.12'),
      JavaAgpTestData(false, javaVersion: '16', agpVersion: '8.13'),
      JavaAgpTestData(false, javaVersion: '16', agpVersion: '9.0'),
      JavaAgpTestData(false, javaVersion: '1.8', agpVersion: '4.1'),
      // Null value cases
      // ignore: avoid_redundant_argument_values
      JavaAgpTestData(false, javaVersion: null, agpVersion: '4.2'),
      // ignore: avoid_redundant_argument_values
      JavaAgpTestData(false, javaVersion: '1.8', agpVersion: null),
      // ignore: avoid_redundant_argument_values
      JavaAgpTestData(false, javaVersion: null, agpVersion: null),
    ];

    for (final data in testData) {
      testWithoutContext('(Java, agp): (${data.javaVersion}, ${data.agpVersion})', () {
        expect(
          validateJavaAndAgp(BufferLogger.test(), javaV: data.javaVersion, agpV: data.agpVersion),
          data.validPair ? isTrue : isFalse,
          reason: 'J: ${data.javaVersion}, AGP: ${data.agpVersion}',
        );
      });
    }
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

      expect(getGradleVersionFor('7.0'), '7.5');
      expect(getGradleVersionFor('7.1.2'), '7.5');
      expect(getGradleVersionFor('7.2'), '7.5');
      expect(getGradleVersionFor('8.0'), '8.0');
      expect(getGradleVersionFor('8.1'), '8.0');
      expect(getGradleVersionFor('8.2'), '8.2');
      expect(getGradleVersionFor('8.3'), '8.4');
      expect(getGradleVersionFor('8.4'), '8.6');
      expect(getGradleVersionFor('8.5'), '8.7');
      expect(getGradleVersionFor('8.7'), '8.9');
      expect(getGradleVersionFor('8.8'), '8.10.2');
      expect(getGradleVersionFor('8.9'), '8.11.1');
      expect(getGradleVersionFor('8.10'), '8.11.1');
      expect(getGradleVersionFor('8.11'), '8.13');
      expect(getGradleVersionFor('8.12'), '8.13');
      expect(getGradleVersionFor('8.13'), '8.13');
      expect(getGradleVersionFor('9.0'), '9.0.0');
    });

    testWithoutContext('throws on unsupported versions', () {
      expect(
        () => getGradleVersionFor('3.6.0'),
        throwsA(predicate<Exception>((Exception e) => e is ToolExit)),
      );
    });
  });
  group('detecting valid Gradle/AGP versions for given Java version and vice versa', () {
    testWithoutContext(
      'getValidGradleVersionRangeForJavaVersion returns valid Gradle version range for Java version',
      () {
        final Logger testLogger = BufferLogger.test();
        // Java version too high.
        expect(
          getValidGradleVersionRangeForJavaVersion(
            testLogger,
            javaV: oneMajorVersionHigherJavaVersion,
          ),
          isNull,
        );
        // Maximum known Java version.
        // *The test case that follows needs to be updated* when higher versions of Java are supported:
        expect(
          getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '26'),
          allOf(
            equals(getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '26.0.2')),
            isNull,
          ),
        );
        // Known supported Java versions.
        expect(
          getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '25'),
          allOf(
            equals(getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '25.0.2')),
            equals(const JavaGradleCompat(javaMin: '25', javaMax: '26', gradleMin: '9.1.0')),
          ),
        );
        expect(
          getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '24'),
          allOf(
            equals(getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '24.0.2')),
            equals(const JavaGradleCompat(javaMin: '24', javaMax: '25', gradleMin: '8.14')),
          ),
        );
        expect(
          getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '23'),
          allOf(
            equals(getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '23.0.2')),
            equals(const JavaGradleCompat(javaMin: '23', javaMax: '24', gradleMin: '8.10')),
          ),
        );
        expect(
          getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '22'),
          allOf(
            equals(getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '22.0.2')),
            equals(const JavaGradleCompat(javaMin: '22', javaMax: '23', gradleMin: '8.7')),
          ),
        );
        expect(
          getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '21'),
          allOf(
            equals(getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '21.0.2')),
            equals(const JavaGradleCompat(javaMin: '21', javaMax: '22', gradleMin: '8.4')),
          ),
        );
        expect(
          getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '20'),
          allOf(
            equals(getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '20.0.2')),
            equals(const JavaGradleCompat(javaMin: '20', javaMax: '21', gradleMin: '8.1')),
          ),
        );
        expect(
          getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '19'),
          allOf(
            equals(getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '19.0.2')),
            equals(const JavaGradleCompat(javaMin: '19', javaMax: '20', gradleMin: '7.6')),
          ),
        );
        expect(
          getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '18'),
          allOf(
            equals(getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '18.0.2')),
            equals(const JavaGradleCompat(javaMin: '18', javaMax: '19', gradleMin: '7.5')),
          ),
        );
        expect(
          getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '17'),
          allOf(
            equals(getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '17.0.2')),
            equals(const JavaGradleCompat(javaMin: '17', javaMax: '18', gradleMin: '7.3')),
          ),
        );
        expect(
          getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '16'),
          allOf(
            equals(getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '16.0.2')),
            equals(
              const JavaGradleCompat(
                javaMin: '16',
                javaMax: '17',
                gradleMin: '7.0',
                gradleMax: maxGradleVersionForJavaPre17,
              ),
            ),
          ),
        );
        expect(
          getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '15'),
          allOf(
            equals(getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '15.0.2')),
            equals(
              const JavaGradleCompat(
                javaMin: '15',
                javaMax: '16',
                gradleMin: '6.7',
                gradleMax: maxGradleVersionForJavaPre17,
              ),
            ),
          ),
        );
        expect(
          getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '14'),
          allOf(
            equals(getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '14.0.2')),
            equals(
              const JavaGradleCompat(
                javaMin: '14',
                javaMax: '15',
                gradleMin: '6.3',
                gradleMax: maxGradleVersionForJavaPre17,
              ),
            ),
          ),
        );
        expect(
          getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '13'),
          allOf(
            equals(getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '13.0.2')),
            equals(
              const JavaGradleCompat(
                javaMin: '13',
                javaMax: '14',
                gradleMin: '6.0',
                gradleMax: maxGradleVersionForJavaPre17,
              ),
            ),
          ),
        );
        expect(
          getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '12'),
          allOf(
            equals(getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '12.0.2')),
            equals(
              const JavaGradleCompat(
                javaMin: '12',
                javaMax: '13',
                gradleMin: '5.4',
                gradleMax: maxGradleVersionForJavaPre17,
              ),
            ),
          ),
        );
        expect(
          getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '11'),
          allOf(
            equals(getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '11.0.2')),
            equals(
              const JavaGradleCompat(
                javaMin: '11',
                javaMax: '12',
                gradleMin: '5.0',
                gradleMax: maxGradleVersionForJavaPre17,
              ),
            ),
          ),
        );
        expect(
          getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '1.10'),
          allOf(
            equals(getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '1.10.2')),
            equals(
              const JavaGradleCompat(
                javaMin: '1.10',
                javaMax: '1.11',
                gradleMin: '4.7',
                gradleMax: maxGradleVersionForJavaPre17,
              ),
            ),
          ),
        );
        expect(
          getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '1.9'),
          allOf(
            equals(getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '1.9.2')),
            equals(
              const JavaGradleCompat(
                javaMin: '1.9',
                javaMax: '1.10',
                gradleMin: '4.3',
                gradleMax: maxGradleVersionForJavaPre17,
              ),
            ),
          ),
        );
        // Java 1.8 -- return oldest documented compatibility info
        expect(
          getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '1.8'),
          allOf(
            equals(getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '1.8.2')),
            equals(
              const JavaGradleCompat(
                javaMin: '1.8',
                javaMax: '1.9',
                gradleMin: '2.0',
                gradleMax: maxGradleVersionForJavaPre17,
              ),
            ),
          ),
        );
        // Java version too low.
        expect(
          getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '1.7'),
          allOf(
            equals(getValidGradleVersionRangeForJavaVersion(testLogger, javaV: '1.7.2')),
            isNull,
          ),
        );
      },
    );

    testWithoutContext(
      'getMinimumAgpVersionForJavaVersion returns minimum AGP version for Java version',
      () {
        final Logger testLogger = BufferLogger.test();
        // Maximum known Java version.
        // *The test case that follows needs to be updated* as higher versions of AGP are supported:
        expect(
          getMinimumAgpVersionForJavaVersion(testLogger, javaV: oneMajorVersionHigherJavaVersion),
          equals(
            const JavaAgpCompat(
              javaMin: '17',
              javaDefault: '17',
              agpMin: '8.0',
              agpMax: maxKnownAndSupportedAgpVersion,
            ),
          ),
        );
        // Known Java versions.
        expect(
          getMinimumAgpVersionForJavaVersion(testLogger, javaV: '17'),
          allOf(
            equals(getMinimumAgpVersionForJavaVersion(testLogger, javaV: '17.0.2')),
            equals(
              const JavaAgpCompat(
                javaMin: '17',
                javaDefault: '17',
                agpMin: '8.0',
                agpMax: maxKnownAndSupportedAgpVersion,
              ),
            ),
          ),
        );
        expect(
          getMinimumAgpVersionForJavaVersion(testLogger, javaV: '15'),
          allOf(
            equals(getMinimumAgpVersionForJavaVersion(testLogger, javaV: '15.0.2')),
            equals(
              const JavaAgpCompat(javaMin: '11', javaDefault: '11', agpMin: '7.0', agpMax: '7.4'),
            ),
          ),
        );
        expect(
          getMinimumAgpVersionForJavaVersion(testLogger, javaV: '11'),
          allOf(
            equals(getMinimumAgpVersionForJavaVersion(testLogger, javaV: '11.0.2')),
            equals(
              const JavaAgpCompat(javaMin: '11', javaDefault: '11', agpMin: '7.0', agpMax: '7.4'),
            ),
          ),
        );
        expect(
          getMinimumAgpVersionForJavaVersion(testLogger, javaV: '1.9'),
          allOf(
            equals(getMinimumAgpVersionForJavaVersion(testLogger, javaV: '1.9.2')),
            equals(
              const JavaAgpCompat(javaMin: '1.8', javaDefault: '1.8', agpMin: '4.2', agpMax: '4.2'),
            ),
          ),
        );
        expect(
          getMinimumAgpVersionForJavaVersion(testLogger, javaV: '1.8'),
          allOf(
            equals(getMinimumAgpVersionForJavaVersion(testLogger, javaV: '1.8.2')),
            equals(
              const JavaAgpCompat(javaMin: '1.8', javaDefault: '1.8', agpMin: '4.2', agpMax: '4.2'),
            ),
          ),
        );
        // Java version too low.
        expect(
          getMinimumAgpVersionForJavaVersion(testLogger, javaV: '1.7'),
          allOf(equals(getMinimumAgpVersionForJavaVersion(testLogger, javaV: '1.7.2')), isNull),
        );
      },
    );

    testWithoutContext('getJavaVersionFor returns expected Java version range', () {
      // Strictly too old Gradle and AGP versions.
      expect(
        getJavaVersionFor(gradleV: '1.9', agpV: '4.1'),
        equals(const VersionRange(null, null)),
      );
      // Strictly too old Gradle or AGP version.
      expect(
        getJavaVersionFor(gradleV: '1.9', agpV: '4.2'),
        equals(const VersionRange('1.8', null)),
      );
      expect(
        getJavaVersionFor(gradleV: '2.0', agpV: '4.1'),
        equals(const VersionRange(null, '1.9')),
      );
      // Strictly too new Gradle and AGP versions.
      expect(
        getJavaVersionFor(gradleV: '9.10', agpV: '10.0'),
        equals(const VersionRange(null, null)),
      );
      // Strictly too new Gradle version and maximum version of AGP.
      //*This test case will need its expected Java range updated when a new version of AGP is supported.*
      expect(
        getJavaVersionFor(gradleV: '9.10', agpV: maxKnownAndSupportedAgpVersion),
        equals(const VersionRange('17', null)),
      );
      // Strictly too new AGP version and maximum version of Gradle.
      //*This test case will need its expected Java range updated when a new version of Gradle is supported.*
      expect(
        getJavaVersionFor(gradleV: maxKnownAndSupportedGradleVersion, agpV: '10.0'),
        equals(const VersionRange(null, oneMajorVersionHigherJavaVersion)),
      );
    });
    // Tests with a known compatible Gradle/AGP version pair.
    final List<({String agpV, String gradleV, VersionRange expected})> agpGradleData = [
      (agpV: '4.2.0', gradleV: '6.7.1', expected: const VersionRange('1.8', '16')),
      (agpV: '4.2.0', gradleV: '7.0', expected: const VersionRange('1.8', '17')),
      (agpV: '4.2.0', gradleV: '8.0', expected: const VersionRange('1.8', '20')),
      (agpV: '4.2.0', gradleV: '8.5', expected: const VersionRange('1.8', '22')),
      (agpV: '4.2.0', gradleV: '8.9.1', expected: const VersionRange('1.8', '23')),
      (agpV: '4.2.0', gradleV: '8.11', expected: const VersionRange('1.8', '24')),
      (agpV: '4.2.0', gradleV: '8.13', expected: const VersionRange('1.8', '24')),
      (agpV: '7.0', gradleV: '7.1', expected: const VersionRange('11', '17')),
      (agpV: '7.2', gradleV: '7.0', expected: const VersionRange('11', '17')),
      (agpV: '7.2', gradleV: '7.1', expected: const VersionRange('11', '17')),
      (agpV: '7.4', gradleV: '7.1', expected: const VersionRange('11', '17')),
      (agpV: '7.4', gradleV: '7.5', expected: const VersionRange('11', '19')),
      (agpV: '7.4', gradleV: '8.0', expected: const VersionRange('11', '20')),
      (agpV: '7.4', gradleV: '8.4', expected: const VersionRange('11', '22')),
      (agpV: '7.4', gradleV: '8.9.1', expected: const VersionRange('11', '23')),
      (agpV: '7.4', gradleV: '8.10', expected: const VersionRange('11', '24')),
      (agpV: '7.4', gradleV: '8.12', expected: const VersionRange('11', '24')),
      (agpV: '7.4', gradleV: '8.14', expected: const VersionRange('11', '25')),
      (agpV: '8.0', gradleV: '8.0', expected: const VersionRange('17', '20')),
      (agpV: '8.0', gradleV: '8.4', expected: const VersionRange('17', '22')),
      (agpV: '8.0', gradleV: '8.9.1', expected: const VersionRange('17', '23')),
      (agpV: '8.0', gradleV: '8.10', expected: const VersionRange('17', '24')),
      (agpV: '8.0', gradleV: '8.12', expected: const VersionRange('17', '24')),
      (agpV: '8.0', gradleV: '8.14', expected: const VersionRange('17', '25')),
      (agpV: '8.1', gradleV: '8.4', expected: const VersionRange('17', '22')),
      (agpV: '8.1', gradleV: '8.7', expected: const VersionRange('17', '23')),
      (agpV: '8.9.1', gradleV: '8.11.1', expected: const VersionRange('17', '24')),
      (agpV: '8.9.1', gradleV: '8.12', expected: const VersionRange('17', '24')),
      (agpV: '8.9.1', gradleV: '8.13', expected: const VersionRange('17', '24')),
      (agpV: '9.0', gradleV: '9.0', expected: const VersionRange('17', '25')),
      // Granular versions.
      (agpV: '8.0.1', gradleV: '8.1.1', expected: const VersionRange('17', '21')),
      (agpV: '7.2', gradleV: '7.2.2', expected: const VersionRange('11', '17')),
    ];
    for (final data in agpGradleData) {
      testWithoutContext('for AGP ${data.agpV}, gradle ${data.gradleV}', () {
        expect(getJavaVersionFor(agpV: data.agpV, gradleV: data.gradleV), data.expected);
      });
    }
    testWithoutContext('for agp/gradle', () {
      // Max values
      expect(
        getJavaVersionFor(
          agpV: maxKnownAndSupportedAgpVersion,
          gradleV: maxKnownAndSupportedGradleVersion,
        ).versionMin,
        '17',
      );
      // Template versions.
      expect(
        getJavaVersionFor(
          agpV: templateAndroidGradlePluginVersion,
          gradleV: templateAndroidGradlePluginVersion,
        ).versionMin,
        '17',
      );
    });
  });
}

class GradleAgpTestData {
  GradleAgpTestData(this.validPair, {this.gradleVersion, this.agpVersion});
  final String? gradleVersion;
  final String? agpVersion;
  final bool validPair;
}

class GradleKgpTestData {
  GradleKgpTestData(this.validPair, {this.gradleVersion, this.kgpVersion});
  final String? gradleVersion;
  final String? kgpVersion;
  final bool validPair;
}

class KgpAgpTestData {
  KgpAgpTestData(this.validPair, {this.agpVersion, this.kgpVersion});
  final String? agpVersion;
  final String? kgpVersion;
  final bool validPair;
}

class JavaGradleTestData {
  JavaGradleTestData(this.validPair, {this.javaVersion, this.gradleVersion});
  final String? gradleVersion;
  final String? javaVersion;
  final bool validPair;
}

class JavaAgpTestData {
  JavaAgpTestData(this.validPair, {this.javaVersion, this.agpVersion});
  final String? agpVersion;
  final String? javaVersion;
  final bool validPair;
}

final Platform windowsPlatform = FakePlatform(
  operatingSystem: 'windows',
  environment: <String, String>{
    'PROGRAMFILES(X86)': r'C:\Program Files (x86)\',
    'FLUTTER_ROOT': r'C:\flutter',
    'USERPROFILE': '/',
  },
);
final Platform notWindowsPlatform = FakePlatform(
  environment: <String, String>{'FLUTTER_ROOT': r'/users/someuser/flutter'},
);
