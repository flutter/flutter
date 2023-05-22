// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/android/java.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:test/fake.dart';
import 'package:webdriver/async_io.dart';

import '../../integration.shard/test_utils.dart';
import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';

void main() {

  late Logger logger;
  late FileSystem fs;
  late Platform platform;
  late FakeProcessManager processManager;

  setUp(() {
    logger = BufferLogger.test();
    fs = MemoryFileSystem.test();
    platform = FakePlatform(environment: <String, String>{
      'PATH': '',
    });
    processManager = FakeProcessManager.empty();
  });

  group(Java, () {

    group('find', () {
      testWithoutContext('finds the JDK bundled with Android Studio, if it exists', () {
        final AndroidStudio androidStudio = _FakeAndroidStudioWithJdk();
        final String androidStudioBundledJdkHome = androidStudio.javaPath!;
        final String expectedJavaBinaryPath = fs.path.join(androidStudioBundledJdkHome, 'bin', 'java');

        processManager.addCommand(FakeCommand(
          command: <String>[
            expectedJavaBinaryPath,
            '--version',
          ],
          stdout: '''
openjdk 19.0.2 2023-01-17
OpenJDK Runtime Environment Zulu19.32+15-CA (build 19.0.2+7)
OpenJDK 64-Bit Server VM Zulu19.32+15-CA (build 19.0.2+7, mixed mode, sharing)
'''
        ));
        final Java java = Java.find(
          androidStudio: androidStudio,
          logger: logger,
          fileSystem: fs,
          platform: platform,
          processManager: processManager,
        )!;
        final JavaVersion version = java.version!;

        expect(java.javaHome, androidStudioBundledJdkHome);
        expect(java.binaryPath, expectedJavaBinaryPath);

        expect(version.longText, 'OpenJDK Runtime Environment Zulu19.32+15-CA (build 19.0.2+7)');
        expect(version.number, '19.0.2');
      });

      testWithoutContext('finds JAVA_HOME if it is set and the JDK bundled with Android Studio could not be found', () {
        final AndroidStudio androidStudio = _FakeAndroidStudioWithoutJdk();
        const String javaHome = '/java/home';
        final String expectedJavaBinaryPath = fs.path.join(javaHome, 'bin', 'java');

        final Java java = Java.find(
          androidStudio: androidStudio,
          logger: logger,
          fileSystem: fs,
          platform: FakePlatform(environment: <String, String>{
            'JAVA_HOME': javaHome,
          }),
          processManager: processManager,
        )!;

        expect(java.javaHome, javaHome);
        expect(java.binaryPath, expectedJavaBinaryPath);
      });

      testWithoutContext('returns the java binary found on PATH if no other can be found', () {
        final AndroidStudio androidStudio = _FakeAndroidStudioWithoutJdk();
        final OperatingSystemUtils os = _FakeOperatingSystemUtilsWithJava(fileSystem);

        processManager.addCommand(
          const FakeCommand(
            command: <String>['which', 'java'],
            stdout: '/fake/which/java/path',
          ),
        );

        final Java java = Java.find(
          androidStudio: androidStudio,
          logger: logger,
          fileSystem: fs,
          platform: platform,
          processManager: processManager,
        )!;

        expect(java.javaHome, isNull);
        expect(java.binaryPath, os.which('java')!.path);
      });

      testWithoutContext('returns null if no java could be found', () {
        final AndroidStudio androidStudio = _FakeAndroidStudioWithoutJdk();
        processManager.addCommand(
          const FakeCommand(
            command: <String>['which', 'java'],
            exitCode: 1,
          ),
        );
        final Java? java = Java.find(
          androidStudio: androidStudio,
          logger: logger,
          fileSystem: fs,
          platform: platform,
          processManager: processManager,
        );
        expect(java, isNull);
      });
    });

    group('getVersionString', () {
      late Java java;

      setUp(() {
        processManager = FakeProcessManager.empty();
        java = Java(
          fileSystem: fs,
          logger: logger,
          os: FakeOperatingSystemUtils(),
          platform: platform,
          processManager: processManager,
          binaryPath: 'javaHome/bin/java',
          javaHome: 'javaHome',
        );
      });

      void addJavaVersionCommand(String output) {
        processManager.addCommand(
          FakeCommand(
            command: <String>[java.binaryPath, '--version'],
            stdout: output,
          ),
        );
      }

      testWithoutContext('parses jdk 8', () {
        addJavaVersionCommand('''
java version "1.8.0_202"
Java(TM) SE Runtime Environment (build 1.8.0_202-b10)
Java HotSpot(TM) 64-Bit Server VM (build 25.202-b10, mixed mode)
''');
        final JavaVersion version = java.version!;
        expect(version.longText, 'Java(TM) SE Runtime Environment (build 1.8.0_202-b10)');
        expect(version.number, '1.8.0');
      });
      testWithoutContext('parses jdk 11 windows', () {
        addJavaVersionCommand('''
java version "11.0.14"
Java(TM) SE Runtime Environment (build 11.0.14+10-b13)
Java HotSpot(TM) 64-Bit Server VM (build 11.0.14+10-b13, mixed mode)
''');
        final JavaVersion version = java.version!;
        expect(version.longText, 'Java(TM) SE Runtime Environment (build 11.0.14+10-b13)');
        expect(version.number, '11.0.14');
      });

      testWithoutContext('parses jdk 11 mac/linux', () {
        addJavaVersionCommand('''
openjdk version "11.0.18" 2023-01-17 LTS
OpenJDK Runtime Environment Zulu11.62+17-CA (build 11.0.18+10-LTS)
OpenJDK 64-Bit Server VM Zulu11.62+17-CA (build 11.0.18+10-LTS, mixed mode)
''');
        final JavaVersion version = java.version!;
        expect(version.longText, 'OpenJDK Runtime Environment Zulu11.62+17-CA (build 11.0.18+10-LTS)');
        expect(version.number, '11.0.18');
      });

      testWithoutContext('parses jdk 17', () {
        addJavaVersionCommand('''
openjdk 17.0.6 2023-01-17
OpenJDK Runtime Environment (build 17.0.6+0-17.0.6b802.4-9586694)
OpenJDK 64-Bit Server VM (build 17.0.6+0-17.0.6b802.4-9586694, mixed mode)
''');
        final JavaVersion version = java.version!;
        expect(version.longText, 'OpenJDK Runtime Environment (build 17.0.6+0-17.0.6b802.4-9586694)');
        expect(version.number, '17.0.6');
      });

      testWithoutContext('parses jdk 19', () {
        addJavaVersionCommand('''
openjdk 19.0.2 2023-01-17
OpenJDK Runtime Environment Homebrew (build 19.0.2)
OpenJDK 64-Bit Server VM Homebrew (build 19.0.2, mixed mode, sharing)
''');
        final JavaVersion version = java.version!;
        expect(version.longText, 'OpenJDK Runtime Environment Homebrew (build 19.0.2)');
        expect(version.number, '19.0.2');
      });

      // https://chrome-infra-packages.appspot.com/p/flutter/java/openjdk/
      testWithoutContext('parses jdk output from ci', () {
        addJavaVersionCommand('''
openjdk 11.0.2 2019-01-15
OpenJDK Runtime Environment 18.9 (build 11.0.2+9)
OpenJDK 64-Bit Server VM 18.9 (build 11.0.2+9, mixed mode)
''');
        final JavaVersion version = java.version!;
        expect(version.longText, 'OpenJDK Runtime Environment 18.9 (build 11.0.2+9)');
        expect(version.number, '11.0.2');
      });

      testWithoutContext('parses jdk two number versions', () {
        addJavaVersionCommand('openjdk 19.0 2023-01-17');
        final JavaVersion version = java.version!;
        expect(version.longText, 'openjdk 19.0 2023-01-17');
        expect(version.number, '19.0');
      });
    });
  });
}

class _FakeAndroidStudioWithJdk extends Fake implements AndroidStudio {
  @override
  String? get javaPath => '/fake/android_studio/java/path/';
}

class _FakeAndroidStudioWithoutJdk extends Fake implements AndroidStudio {
  @override
  String? get javaPath => null;
}

class _FakeOperatingSystemUtilsWithJava extends FakeOperatingSystemUtils {
  _FakeOperatingSystemUtilsWithJava(this._fileSystem);

  final FileSystem _fileSystem;
  @override
  File? which(String execName) {
    if (execName == 'java') {
      return _fileSystem.file('/fake/which/java/path');
    }
    throw const InvalidArgumentException(null, null);
  }
}
