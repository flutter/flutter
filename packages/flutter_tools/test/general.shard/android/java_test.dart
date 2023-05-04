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
          os: _FakeOperatingSystemUtilsWithoutJava(),
          platform: platform,
          processManager: processManager,
        );

        expect(java.home, androidStudioBundledJdkHome);
        expect(java.binary, expectedJavaBinaryPath);
        expect(java.getVersionString(), '19.0.2');
      });

      testWithoutContext('finds JAVA_HOME if it is set and the JDK bundled with Android Studio could not be found', () {
        final AndroidStudio androidStudio = _FakeAndroidStudioWithoutJdk();
        const String javaHome = '/java/home';
        final String expectedJavaBinaryPath = fs.path.join(javaHome, 'bin', 'java');

        final Java java = Java.find(
          androidStudio: androidStudio,
          logger: logger,
          fileSystem: fs,
          os: _FakeOperatingSystemUtilsWithoutJava(),
          platform: FakePlatform(environment: <String, String>{
            'JAVA_HOME': javaHome,
          }),
          processManager: processManager,
        );

        expect(java.home, javaHome);
        expect(java.binary, expectedJavaBinaryPath);
      });

      testWithoutContext('returns the java binary found on PATH if no other can be found', () {
        final AndroidStudio androidStudio = _FakeAndroidStudioWithoutJdk();
        final OperatingSystemUtils os = _FakeOperatingSystemUtilsWithJava(fileSystem);

        final Java java = Java.find(
          androidStudio: androidStudio,
          logger: logger,
          fileSystem: fs,
          os: os,
          platform: platform,
          processManager: processManager,
        );

        expect(java.binary, os.which('java')!.path);
        expect(java.home, isNull);
      });

      testWithoutContext('returns null object if no java could be found', () {
        final AndroidStudio androidStudio = _FakeAndroidStudioWithoutJdk();
        final OperatingSystemUtils os = _FakeOperatingSystemUtilsWithoutJava();
        final Java java = Java.find(
          androidStudio: androidStudio,
          logger: logger,
          fileSystem: fs,
          os: os,
          platform: platform,
          processManager: processManager,
        );

        expect(java.binary, isNull);
        expect(java.home, isNull);
        expect(java.getVersionString(), isNull);
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
          binary: 'javaHome/bin/java',
          home: 'javaHome',
        );
      });

      void addJavaVersionCommand(String output) {
        processManager.addCommand(
          FakeCommand(
            command: <String>[java.binary!, '--version'],
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
        expect(java.getVersionString(), '1.8.0');
      });
      testWithoutContext('parses jdk 11 windows', () {
        addJavaVersionCommand('''
java version "11.0.14"
Java(TM) SE Runtime Environment (build 11.0.14+10-b13)
Java HotSpot(TM) 64-Bit Server VM (build 11.0.14+10-b13, mixed mode)
''');
        expect(java.getVersionString(), '11.0.14');
      });

      testWithoutContext('parses jdk 11 mac/linux', () {
        addJavaVersionCommand('''
openjdk version "11.0.18" 2023-01-17 LTS
OpenJDK Runtime Environment Zulu11.62+17-CA (build 11.0.18+10-LTS)
OpenJDK 64-Bit Server VM Zulu11.62+17-CA (build 11.0.18+10-LTS, mixed mode)
''');
        expect(java.getVersionString(), '11.0.18');
      });

      testWithoutContext('parses jdk 17', () {
        addJavaVersionCommand('''
openjdk 17.0.6 2023-01-17
OpenJDK Runtime Environment (build 17.0.6+0-17.0.6b802.4-9586694)
OpenJDK 64-Bit Server VM (build 17.0.6+0-17.0.6b802.4-9586694, mixed mode)
''');
        expect(java.getVersionString(), '17.0.6');
      });

      testWithoutContext('parses jdk 19', () {
        addJavaVersionCommand('''
openjdk 19.0.2 2023-01-17
OpenJDK Runtime Environment Homebrew (build 19.0.2)
OpenJDK 64-Bit Server VM Homebrew (build 19.0.2, mixed mode, sharing)
''');
        expect(java.getVersionString(), '19.0.2');
      });

      // https://chrome-infra-packages.appspot.com/p/flutter/java/openjdk/
      testWithoutContext('parses jdk output from ci', () {
        addJavaVersionCommand('''
openjdk 11.0.2 2019-01-15
OpenJDK Runtime Environment 18.9 (build 11.0.2+9)
OpenJDK 64-Bit Server VM 18.9 (build 11.0.2+9, mixed mode)
''');
        expect(java.getVersionString(), '11.0.2');
      });

      testWithoutContext('parses jdk two number versions', () {
        addJavaVersionCommand('openjdk 19.0 2023-01-17');
        expect(java.getVersionString(), '19.0');
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

class _FakeOperatingSystemUtilsWithoutJava extends FakeOperatingSystemUtils {
  @override
  File? which(String execName) {
    if (execName == 'java') {
      return null;
    }
    throw const InvalidArgumentException(null, null);
  }
}
