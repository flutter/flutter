// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:archive/archive.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/android/gradle.dart';
import 'package:flutter_tools/src/android/gradle_errors.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/mocks.dart';

void main() {
  group('gradle build', () {
    BufferLogger logger;
    TestUsage testUsage;
    MockAndroidSdk mockAndroidSdk;
    MockAndroidStudio mockAndroidStudio;
    MockLocalEngineArtifacts mockArtifacts;
    MockProcessManager mockProcessManager;
    FakePlatform android;
    FileSystem fileSystem;
    FileSystemUtils fileSystemUtils;
    Cache cache;
    AndroidGradleBuilder builder;

    setUp(() {
      logger = BufferLogger.test();
      testUsage = TestUsage();
      fileSystem = MemoryFileSystem.test();
      fileSystemUtils = MockFileSystemUtils();
      mockAndroidSdk = MockAndroidSdk();
      mockAndroidStudio = MockAndroidStudio();
      mockArtifacts = MockLocalEngineArtifacts();
      mockProcessManager = MockProcessManager();
      android = fakePlatform('android');
      builder = AndroidGradleBuilder(
        logger: logger,
      );

      when(mockAndroidSdk.directory).thenReturn('irrelevant');

      final Directory rootDirectory = fileSystem.currentDirectory;
      cache = Cache.test(
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
       await builder.buildGradleApp(
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

      expect(testUsage.events, contains(
        const TestUsageEvent(
          'build',
          'unspecified',
          label: 'gradle-random-event-label-failure',
          parameters: <String, String>{},
        ),
      ));
    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      Cache: () => cache,
      Platform: () => android,
      FileSystem: () => fileSystem,
      ProcessManager: () => mockProcessManager,
      Usage: () => testUsage,
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
       await builder.buildGradleApp(
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
      expect(testUsage.events, contains(
        const TestUsageEvent(
          'build',
          'unspecified',
          label: 'gradle-random-event-label-failure',
          parameters: <String, String>{},
        ),
      ));
    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      Cache: () => cache,
      Platform: () => android,
      FileSystem: () => fileSystem,
      ProcessManager: () => mockProcessManager,
      Usage: () => testUsage,
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
       await builder.buildGradleApp(
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

      expect(testUsage.events, contains(
        const TestUsageEvent(
          'build',
          'unspecified',
          label: 'gradle-random-event-label-failure',
          parameters: <String, String>{},
        ),
      ));
    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      Cache: () => cache,
      Platform: () => android,
      FileSystem: () => fileSystem,
      ProcessManager: () => mockProcessManager,
      Usage: () => testUsage,
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
       await builder.buildGradleApp(
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

    testUsingContext('logs success event after a successful retry', () async {
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

      await builder.buildGradleApp(
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

      expect(testUsage.events, contains(
        const TestUsageEvent(
          'build',
          'unspecified',
          label: 'gradle-random-event-label-success',
          parameters: <String, String>{},
        ),
      ));
    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      Cache: () => cache,
      FileSystem: () => fileSystem,
      Platform: () => android,
      ProcessManager: () => mockProcessManager,
      Usage: () => testUsage,
    });

    testUsingContext('performs code size analysis and sends analytics', () async {
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
        ..writeAsStringSync(r'''
[
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

      await builder.buildGradleApp(
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

      expect(testUsage.events, contains(
        const TestUsageEvent(
          'code-size-analysis',
          'apk',
        ),
      ));
    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      Cache: () => cache,
      FileSystem: () => fileSystem,
      Platform: () => android,
      ProcessManager: () => mockProcessManager,
      Usage: () => testUsage,
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
       await builder.buildGradleApp(
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

      expect(testUsage.events, contains(
        const TestUsageEvent(
          'build',
          'unspecified',
          label: 'gradle-random-event-label-failure',
          parameters: <String, String>{},
        ),
      ));
    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      Cache: () => cache,
      Platform: () => android,
      FileSystem: () => fileSystem,
      ProcessManager: () => mockProcessManager,
      Usage: () => testUsage,
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

      await builder.buildGradleApp(
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
        logger.statusText,
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

      await builder.buildGradleAar(
        androidBuildInfo: const AndroidBuildInfo(BuildInfo(BuildMode.release, null, treeShakeIcons: false)),
        project: FlutterProject.current(),
        outputDirectory: fileSystem.directory('build/'),
        target: '',
        buildNumber: '1.0',
      );

      expect(
        logger.statusText,
        contains('Built build/outputs/repo'),
      );
      expect(
        logger.statusText.contains('Consuming the Module'),
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

    testUsingContext('gradle exit code is properly passed on', () async {
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
      )).thenAnswer((_) async => ProcessResult(1, 108, '', ''));

      fileSystem.directory('build/outputs/repo').createSync(recursive: true);

      await expectLater(() async =>
        await builder.buildGradleAar(
          androidBuildInfo: const AndroidBuildInfo(BuildInfo(BuildMode.release, null, treeShakeIcons: false)),
          project: FlutterProject.current(),
          outputDirectory: fileSystem.directory('build/'),
          target: '',
          buildNumber: '1.0',
        )
      , throwsToolExit(exitCode: 108, message: 'Gradle task assembleAarRelease failed with exit code 108.'));

    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      AndroidStudio: () => mockAndroidStudio,
      Cache: () => cache,
      Platform: () => android,
      FileSystem: () => fileSystem,
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('build apk uses selected local engine,the engine abi is arm', () async {
      when(mockArtifacts.getArtifactPath(
        Artifact.flutterFramework,
        platform: TargetPlatform.android_arm,
        mode: anyNamed('mode'),
        environmentType: anyNamed('environmentType'),
      )).thenReturn('engine');
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
      fileSystem.file('out/android_arm/armeabi_v7a_release.maven-metadata.xml').createSync(recursive: true);
      fileSystem.file('out/android_arm/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_arm/flutter_embedding_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_arm/flutter_embedding_release.maven-metadata.xml').createSync(recursive: true);

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
        await builder.buildGradleApp(
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
      when(mockArtifacts.getArtifactPath(
        Artifact.flutterFramework,
        platform: anyNamed('platform'),
        mode: anyNamed('mode'),
        environmentType: anyNamed('environmentType'),
      )).thenReturn('engine');
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
      fileSystem.file('out/android_arm64/arm64_v8a_release.maven-metadata.xml').createSync(recursive: true);
      fileSystem.file('out/android_arm64/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_arm64/flutter_embedding_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_arm64/flutter_embedding_release.maven-metadata.xml').createSync(recursive: true);

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
        await builder.buildGradleApp(
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
      when(mockArtifacts.getArtifactPath(
        Artifact.flutterFramework,
        platform: anyNamed('platform'),
        mode: anyNamed('mode'),
        environmentType: anyNamed('environmentType'),
      )).thenReturn('engine');
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
      fileSystem.file('out/android_x86/x86_release.maven-metadata.xml').createSync(recursive: true);
      fileSystem.file('out/android_x86/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_x86/flutter_embedding_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_x86/flutter_embedding_release.maven-metadata.xml').createSync(recursive: true);

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
        await builder.buildGradleApp(
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
      when(mockArtifacts.getArtifactPath(
        Artifact.flutterFramework,
        platform: anyNamed('platform'),
        mode: anyNamed('mode'),
        environmentType: anyNamed('environmentType'),
      )).thenReturn('engine');
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
      fileSystem.file('out/android_x64/x86_64_release.maven-metadata.xml').createSync(recursive: true);
      fileSystem.file('out/android_x64/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_x64/flutter_embedding_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_x64/flutter_embedding_release.maven-metadata.xml').createSync(recursive: true);

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
        await builder.buildGradleApp(
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

    testUsingContext('honors --no-android-gradle-daemon setting', () async {
      (globals.processManager as FakeProcessManager).addCommand(
        const FakeCommand(command: <String>[
          '/android/gradlew',
          '-q',
          '--no-daemon',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          '-Ptarget=lib/main.dart',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=false',
          '-Ptree-shake-icons=false',
          'assembleRelease'
        ],
      ));
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

      await expectLater(() async {
        await builder.buildGradleApp(
          project: FlutterProject.current(),
          androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(
              BuildMode.release,
              null,
              treeShakeIcons: false,
              androidGradleDaemon: false,
            ),
          ),
          target: 'lib/main.dart',
          isBuildingBundle: false,
          localGradleErrors: const <GradleHandledError>[],
        );
      }, throwsToolExit());
    }, overrides: <Type, Generator>{
      AndroidSdk: () => mockAndroidSdk,
      AndroidStudio: () => mockAndroidStudio,
      Artifacts: () => Artifacts.test(),
      Cache: () => cache,
      Platform: () => android,
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.list(<FakeCommand>[]),
    });

    testUsingContext('build aar uses selected local engine，the engine abi is arm', () async {
      when(mockArtifacts.getArtifactPath(
        Artifact.flutterFramework,
        platform: TargetPlatform.android_arm,
        mode: anyNamed('mode'),
        environmentType: anyNamed('environmentType'),
      )).thenReturn('engine');
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
      fileSystem.file('out/android_arm/armeabi_v7a_release.maven-metadata.xml').createSync(recursive: true);
      fileSystem.file('out/android_arm/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_arm/flutter_embedding_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_arm/flutter_embedding_release.maven-metadata.xml').createSync(recursive: true);

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

      await builder.buildGradleAar(
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
      when(mockArtifacts.getArtifactPath(
        Artifact.flutterFramework,
        platform: anyNamed('platform'),
        mode: anyNamed('mode'),
        environmentType: anyNamed('environmentType'),
      )).thenReturn('engine');
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
      fileSystem.file('out/android_arm64/arm64_v8a_release.maven-metadata.xml').createSync(recursive: true);
      fileSystem.file('out/android_arm64/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_arm64/flutter_embedding_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_arm64/flutter_embedding_release.maven-metadata.xml').createSync(recursive: true);

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

      await builder.buildGradleAar(
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
      when(mockArtifacts.getArtifactPath(
        Artifact.flutterFramework,
        platform: anyNamed('platform'),
        mode: anyNamed('mode'),
        environmentType: anyNamed('environmentType'),
      )).thenReturn('engine');
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
      fileSystem.file('out/android_x86/x86_release.maven-metadata.xml').createSync(recursive: true);
      fileSystem.file('out/android_x86/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_x86/flutter_embedding_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_x86/flutter_embedding_release.maven-metadata.xml').createSync(recursive: true);

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

      await builder.buildGradleAar(
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
      when(mockArtifacts.getArtifactPath(
        Artifact.flutterFramework,
        platform: anyNamed('platform'),
        mode: anyNamed('mode'),
        environmentType: anyNamed('environmentType'),
      )).thenReturn('engine');
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
      fileSystem.file('out/android_x64/x86_64_release.maven-metadata.xml').createSync(recursive: true);
      fileSystem.file('out/android_x64/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_x64/flutter_embedding_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_x64/flutter_embedding_release.maven-metadata.xml').createSync(recursive: true);

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

      await builder.buildGradleAar(
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
}

FakePlatform fakePlatform(String name) {
  return FakePlatform(
    environment: <String, String>{'HOME': '/path/to/home'},
    operatingSystem: name,
    stdoutSupportsAnsi: false,
  );
}

class MockProcessManager extends Mock implements ProcessManager {}
class MockAndroidSdk extends Mock implements AndroidSdk {}
class MockAndroidStudio extends Mock implements AndroidStudio {}
class MockFileSystemUtils extends Mock implements FileSystemUtils {}
class MockLocalEngineArtifacts extends Mock implements LocalEngineArtifacts {}
