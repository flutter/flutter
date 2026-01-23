// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build_ios_framework.dart';
import 'package:flutter_tools/src/commands/build_macos_framework.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/version.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/test_build_system.dart';

void main() {
  late MemoryFileSystem memoryFileSystem;
  late Directory outputDirectory;
  late FakePlatform fakePlatform;

  setUpAll(() {
    Cache.disableLocking();
  });

  const storageBaseUrl = 'https://fake.googleapis.com';
  setUp(() {
    memoryFileSystem = MemoryFileSystem.test();
    fakePlatform = FakePlatform(
      operatingSystem: 'macos',
      environment: <String, String>{'FLUTTER_STORAGE_BASE_URL': storageBaseUrl},
    );

    outputDirectory =
        memoryFileSystem.systemTempDirectory
            .createTempSync('flutter_build_framework_test_output.')
            .childDirectory('Debug')
          ..createSync();
  });

  group('build ios-framework', () {
    group('podspec', () {
      const engineRevision = '0123456789abcdef';
      late Cache cache;

      setUp(() {
        final Directory rootOverride = memoryFileSystem.directory('cache');
        cache = Cache.test(
          rootOverride: rootOverride,
          platform: fakePlatform,
          fileSystem: memoryFileSystem,
          processManager: FakeProcessManager.any(),
        );
        rootOverride.childDirectory('bin').childDirectory('cache').childFile('engine.stamp')
          ..createSync(recursive: true)
          ..writeAsStringSync(engineRevision);
      });

      testUsingContext(
        'version unknown',
        () async {
          const frameworkVersion = '0.0.0-unknown';
          final fakeFlutterVersion = FakeFlutterVersion(frameworkVersion: frameworkVersion);

          final command = BuildIOSFrameworkCommand(
            logger: BufferLogger.test(),
            buildSystem: TestBuildSystem.all(BuildResult(success: true)),
            platform: fakePlatform,
            flutterVersion: fakeFlutterVersion,
            cache: cache,
            verboseHelp: false,
          );

          expect(
            () => command.produceFlutterPodspec(BuildMode.debug, outputDirectory),
            throwsToolExit(
              message:
                  '--cocoapods is only supported on the beta or stable channel. Detected version is $frameworkVersion',
            ),
          );
        },
        overrides: <Type, Generator>{
          FileSystem: () => memoryFileSystem,
          ProcessManager: () => FakeProcessManager.any(),
        },
      );

      testUsingContext(
        'throws when not on a released version',
        () async {
          const frameworkVersion = 'v1.13.10+hotfix-pre.2';
          const gitTagVersion = GitTagVersion(
            x: 1,
            y: 13,
            z: 10,
            hotfix: 13,
            commits: 2,
            hash: '',
            gitTag: frameworkVersion,
          );
          final fakeFlutterVersion = FakeFlutterVersion(
            gitTagVersion: gitTagVersion,
            frameworkVersion: frameworkVersion,
          );

          final command = BuildIOSFrameworkCommand(
            logger: BufferLogger.test(),
            buildSystem: TestBuildSystem.all(BuildResult(success: true)),
            platform: fakePlatform,
            flutterVersion: fakeFlutterVersion,
            cache: cache,
            verboseHelp: false,
          );

          expect(
            () => command.produceFlutterPodspec(BuildMode.debug, outputDirectory),
            throwsToolExit(
              message:
                  '--cocoapods is only supported on the beta or stable channel. Detected version is $frameworkVersion',
            ),
          );
        },
        overrides: <Type, Generator>{
          FileSystem: () => memoryFileSystem,
          ProcessManager: () => FakeProcessManager.any(),
        },
      );

      testUsingContext(
        'throws when license not found',
        () async {
          final fakeFlutterVersion = FakeFlutterVersion(
            gitTagVersion: const GitTagVersion(
              x: 1,
              y: 13,
              z: 10,
              hotfix: 13,
              commits: 0,
              hash: '',
              gitTag: '1.13.10+hotfix.14.0',
            ),
          );

          final command = BuildIOSFrameworkCommand(
            logger: BufferLogger.test(),
            buildSystem: TestBuildSystem.all(BuildResult(success: true)),
            platform: fakePlatform,
            flutterVersion: fakeFlutterVersion,
            cache: cache,
            verboseHelp: false,
          );

          expect(
            () => command.produceFlutterPodspec(BuildMode.debug, outputDirectory),
            throwsToolExit(message: 'Could not find license'),
          );
        },
        overrides: <Type, Generator>{
          FileSystem: () => memoryFileSystem,
          ProcessManager: () => FakeProcessManager.any(),
        },
      );

      group('is created', () {
        const frameworkVersion = 'v1.13.11+hotfix.14';
        const licenseText = 'This is the license!';

        setUp(() {
          // cache.getLicenseFile() relies on the flutter root being set.
          Cache.flutterRoot ??= getFlutterRoot();
          cache.getLicenseFile()
            ..createSync(recursive: true)
            ..writeAsStringSync(licenseText);
        });

        group('on master channel', () {
          testUsingContext(
            'created when forced',
            () async {
              const frameworkVersionWithCommits = '$frameworkVersion.pre.100';
              const gitTagVersion = GitTagVersion(
                x: 1,
                y: 13,
                z: 11,
                hotfix: 13,
                commits: 100,
                hash: '',
                gitTag: frameworkVersionWithCommits,
              );
              final fakeFlutterVersion = FakeFlutterVersion(
                gitTagVersion: gitTagVersion,
                frameworkVersion: frameworkVersionWithCommits,
              );

              final command = BuildIOSFrameworkCommand(
                logger: BufferLogger.test(),
                buildSystem: TestBuildSystem.all(BuildResult(success: true)),
                platform: fakePlatform,
                flutterVersion: fakeFlutterVersion,
                cache: cache,
                verboseHelp: false,
              );
              command.produceFlutterPodspec(BuildMode.debug, outputDirectory, force: true);

              final File expectedPodspec = outputDirectory.childFile('Flutter.podspec');
              expect(expectedPodspec.existsSync(), isTrue);
            },
            overrides: <Type, Generator>{
              FileSystem: () => memoryFileSystem,
              ProcessManager: () => FakeProcessManager.any(),
            },
          );
        });

        group('not on master channel', () {
          late FakeFlutterVersion fakeFlutterVersion;
          setUp(() {
            const frameworkVersionWithCommits = '$frameworkVersion.pre.0';
            const gitTagVersion = GitTagVersion(
              x: 1,
              y: 13,
              z: 11,
              hotfix: 13,
              commits: 0,
              hash: '',
              gitTag: frameworkVersionWithCommits,
            );
            fakeFlutterVersion = FakeFlutterVersion(
              gitTagVersion: gitTagVersion,
              frameworkVersion: frameworkVersionWithCommits,
            );
          });

          testUsingContext(
            'contains license and version',
            () async {
              final command = BuildIOSFrameworkCommand(
                logger: BufferLogger.test(),
                buildSystem: TestBuildSystem.all(BuildResult(success: true)),
                platform: fakePlatform,
                flutterVersion: fakeFlutterVersion,
                cache: cache,
                verboseHelp: false,
              );
              command.produceFlutterPodspec(BuildMode.debug, outputDirectory);

              final File expectedPodspec = outputDirectory.childFile('Flutter.podspec');
              final String podspecContents = expectedPodspec.readAsStringSync();
              expect(podspecContents, contains("'1.13.1113'"));
              expect(podspecContents, contains('# $frameworkVersion'));
              expect(podspecContents, contains(licenseText));
            },
            overrides: <Type, Generator>{
              FileSystem: () => memoryFileSystem,
              ProcessManager: () => FakeProcessManager.any(),
            },
          );

          testUsingContext(
            'debug URL',
            () async {
              final command = BuildIOSFrameworkCommand(
                logger: BufferLogger.test(),
                buildSystem: TestBuildSystem.all(BuildResult(success: true)),
                platform: fakePlatform,
                flutterVersion: fakeFlutterVersion,
                cache: cache,
                verboseHelp: false,
              );
              command.produceFlutterPodspec(BuildMode.debug, outputDirectory);

              final File expectedPodspec = outputDirectory.childFile('Flutter.podspec');
              final String podspecContents = expectedPodspec.readAsStringSync();
              expect(
                podspecContents,
                contains(
                  "'$storageBaseUrl/flutter_infra_release/flutter/$engineRevision/ios/artifacts.zip'",
                ),
              );
            },
            overrides: <Type, Generator>{
              FileSystem: () => memoryFileSystem,
              ProcessManager: () => FakeProcessManager.any(),
            },
          );

          testUsingContext(
            'profile URL',
            () async {
              final command = BuildIOSFrameworkCommand(
                logger: BufferLogger.test(),
                buildSystem: TestBuildSystem.all(BuildResult(success: true)),
                platform: fakePlatform,
                flutterVersion: fakeFlutterVersion,
                cache: cache,
                verboseHelp: false,
              );
              command.produceFlutterPodspec(BuildMode.profile, outputDirectory);

              final File expectedPodspec = outputDirectory.childFile('Flutter.podspec');
              final String podspecContents = expectedPodspec.readAsStringSync();
              expect(
                podspecContents,
                contains(
                  "'$storageBaseUrl/flutter_infra_release/flutter/$engineRevision/ios-profile/artifacts.zip'",
                ),
              );
            },
            overrides: <Type, Generator>{
              FileSystem: () => memoryFileSystem,
              ProcessManager: () => FakeProcessManager.any(),
            },
          );

          testUsingContext(
            'release URL',
            () async {
              final command = BuildIOSFrameworkCommand(
                logger: BufferLogger.test(),
                buildSystem: TestBuildSystem.all(BuildResult(success: true)),
                platform: fakePlatform,
                flutterVersion: fakeFlutterVersion,
                cache: cache,
                verboseHelp: false,
              );
              command.produceFlutterPodspec(BuildMode.release, outputDirectory);

              final File expectedPodspec = outputDirectory.childFile('Flutter.podspec');
              final String podspecContents = expectedPodspec.readAsStringSync();
              expect(
                podspecContents,
                contains(
                  "'$storageBaseUrl/flutter_infra_release/flutter/$engineRevision/ios-release/artifacts.zip'",
                ),
              );
            },
            overrides: <Type, Generator>{
              FileSystem: () => memoryFileSystem,
              ProcessManager: () => FakeProcessManager.any(),
            },
          );
        });
      });
    });
  });

  group('build macos-framework', () {
    group('podspec', () {
      const engineRevision = '0123456789abcdef';
      late Cache cache;

      setUp(() {
        final Directory rootOverride = memoryFileSystem.directory('cache');
        cache = Cache.test(
          rootOverride: rootOverride,
          platform: fakePlatform,
          fileSystem: memoryFileSystem,
          processManager: FakeProcessManager.any(),
        );
        rootOverride.childDirectory('bin').childDirectory('cache').childFile('engine.stamp')
          ..createSync(recursive: true)
          ..writeAsStringSync(engineRevision);
      });

      testUsingContext(
        'version unknown',
        () async {
          const frameworkVersion = '0.0.0-unknown';
          final fakeFlutterVersion = FakeFlutterVersion(frameworkVersion: frameworkVersion);

          final command = BuildMacOSFrameworkCommand(
            logger: BufferLogger.test(),
            buildSystem: TestBuildSystem.all(BuildResult(success: true)),
            platform: fakePlatform,
            flutterVersion: fakeFlutterVersion,
            cache: cache,
            verboseHelp: false,
          );

          expect(
            () => command.produceFlutterPodspec(BuildMode.debug, outputDirectory),
            throwsToolExit(
              message:
                  '--cocoapods is only supported on the beta or stable channel. Detected version is $frameworkVersion',
            ),
          );
        },
        overrides: <Type, Generator>{
          FileSystem: () => memoryFileSystem,
          ProcessManager: () => FakeProcessManager.any(),
        },
      );

      testUsingContext(
        'throws when not on a released version',
        () async {
          const frameworkVersion = 'v1.13.10+hotfix.14.pre.2';
          const gitTagVersion = GitTagVersion(
            x: 1,
            y: 13,
            z: 10,
            hotfix: 13,
            commits: 2,
            hash: '',
            gitTag: frameworkVersion,
          );
          final fakeFlutterVersion = FakeFlutterVersion(
            gitTagVersion: gitTagVersion,
            frameworkVersion: frameworkVersion,
          );

          final command = BuildMacOSFrameworkCommand(
            logger: BufferLogger.test(),
            buildSystem: TestBuildSystem.all(BuildResult(success: true)),
            platform: fakePlatform,
            flutterVersion: fakeFlutterVersion,
            cache: cache,
            verboseHelp: false,
          );

          expect(
            () => command.produceFlutterPodspec(BuildMode.debug, outputDirectory),
            throwsToolExit(
              message:
                  '--cocoapods is only supported on the beta or stable channel. Detected version is $frameworkVersion',
            ),
          );
        },
        overrides: <Type, Generator>{
          FileSystem: () => memoryFileSystem,
          ProcessManager: () => FakeProcessManager.any(),
        },
      );

      testUsingContext(
        'throws when license not found',
        () async {
          final fakeFlutterVersion = FakeFlutterVersion(
            gitTagVersion: const GitTagVersion(
              x: 1,
              y: 13,
              z: 10,
              hotfix: 13,
              commits: 0,
              hash: '',
              gitTag: '1.13.10+hotfix.14.pre.0',
            ),
          );

          final command = BuildMacOSFrameworkCommand(
            logger: BufferLogger.test(),
            buildSystem: TestBuildSystem.all(BuildResult(success: true)),
            platform: fakePlatform,
            flutterVersion: fakeFlutterVersion,
            cache: cache,
            verboseHelp: false,
          );

          expect(
            () => command.produceFlutterPodspec(BuildMode.debug, outputDirectory),
            throwsToolExit(message: 'Could not find license'),
          );
        },
        overrides: <Type, Generator>{
          FileSystem: () => memoryFileSystem,
          ProcessManager: () => FakeProcessManager.any(),
        },
      );

      group('is created', () {
        const frameworkVersion = 'v1.13.11+hotfix.13';
        const licenseText = 'This is the license!';

        setUp(() {
          // cache.getLicenseFile() relies on the flutter root being set.
          Cache.flutterRoot ??= getFlutterRoot();
          cache.getLicenseFile()
            ..createSync(recursive: true)
            ..writeAsStringSync(licenseText);
        });

        group('on master channel', () {
          testUsingContext(
            'created when forced',
            () async {
              const gitTagVersion = GitTagVersion(
                x: 1,
                y: 13,
                z: 11,
                hotfix: 13,
                commits: 100,
                hash: '',
                gitTag: '$frameworkVersion.pre.100',
              );
              final fakeFlutterVersion = FakeFlutterVersion(
                gitTagVersion: gitTagVersion,
                frameworkVersion: frameworkVersion,
              );

              final command = BuildMacOSFrameworkCommand(
                logger: BufferLogger.test(),
                buildSystem: TestBuildSystem.all(BuildResult(success: true)),
                platform: fakePlatform,
                flutterVersion: fakeFlutterVersion,
                cache: cache,
                verboseHelp: false,
              );
              command.produceFlutterPodspec(BuildMode.debug, outputDirectory, force: true);

              final File expectedPodspec = outputDirectory.childFile('FlutterMacOS.podspec');
              expect(expectedPodspec.existsSync(), isTrue);
            },
            overrides: <Type, Generator>{
              FileSystem: () => memoryFileSystem,
              ProcessManager: () => FakeProcessManager.any(),
            },
          );
        });

        group('not on master channel', () {
          late FakeFlutterVersion fakeFlutterVersion;
          setUp(() {
            const gitTagVersion = GitTagVersion(
              x: 1,
              y: 13,
              z: 11,
              hotfix: 13,
              commits: 0,
              hash: '',
              gitTag: '$frameworkVersion.pre.0',
            );
            fakeFlutterVersion = FakeFlutterVersion(
              gitTagVersion: gitTagVersion,
              frameworkVersion: frameworkVersion,
            );
          });

          testUsingContext(
            'contains license and version',
            () async {
              final command = BuildMacOSFrameworkCommand(
                logger: BufferLogger.test(),
                buildSystem: TestBuildSystem.all(BuildResult(success: true)),
                platform: fakePlatform,
                flutterVersion: fakeFlutterVersion,
                cache: cache,
                verboseHelp: false,
              );
              command.produceFlutterPodspec(BuildMode.debug, outputDirectory);

              final File expectedPodspec = outputDirectory.childFile('FlutterMacOS.podspec');
              final String podspecContents = expectedPodspec.readAsStringSync();
              expect(podspecContents, contains("'1.13.1113'"));
              expect(podspecContents, contains('# $frameworkVersion'));
              expect(podspecContents, contains(licenseText));
            },
            overrides: <Type, Generator>{
              FileSystem: () => memoryFileSystem,
              ProcessManager: () => FakeProcessManager.any(),
            },
          );

          testUsingContext(
            'debug URL',
            () async {
              final command = BuildMacOSFrameworkCommand(
                logger: BufferLogger.test(),
                buildSystem: TestBuildSystem.all(BuildResult(success: true)),
                platform: fakePlatform,
                flutterVersion: fakeFlutterVersion,
                cache: cache,
                verboseHelp: false,
              );
              command.produceFlutterPodspec(BuildMode.debug, outputDirectory);

              final File expectedPodspec = outputDirectory.childFile('FlutterMacOS.podspec');
              final String podspecContents = expectedPodspec.readAsStringSync();
              expect(
                podspecContents,
                contains(
                  "'$storageBaseUrl/flutter_infra_release/flutter/$engineRevision/darwin-x64/FlutterMacOS.framework.zip'",
                ),
              );
            },
            overrides: <Type, Generator>{
              FileSystem: () => memoryFileSystem,
              ProcessManager: () => FakeProcessManager.any(),
            },
          );

          testUsingContext(
            'profile URL',
            () async {
              final command = BuildMacOSFrameworkCommand(
                logger: BufferLogger.test(),
                buildSystem: TestBuildSystem.all(BuildResult(success: true)),
                platform: fakePlatform,
                flutterVersion: fakeFlutterVersion,
                cache: cache,
                verboseHelp: false,
              );
              command.produceFlutterPodspec(BuildMode.profile, outputDirectory);

              final File expectedPodspec = outputDirectory.childFile('FlutterMacOS.podspec');
              final String podspecContents = expectedPodspec.readAsStringSync();
              expect(
                podspecContents,
                contains(
                  "'$storageBaseUrl/flutter_infra_release/flutter/$engineRevision/darwin-x64-profile/FlutterMacOS.framework.zip'",
                ),
              );
            },
            overrides: <Type, Generator>{
              FileSystem: () => memoryFileSystem,
              ProcessManager: () => FakeProcessManager.any(),
            },
          );

          testUsingContext(
            'release URL',
            () async {
              final command = BuildMacOSFrameworkCommand(
                logger: BufferLogger.test(),
                buildSystem: TestBuildSystem.all(BuildResult(success: true)),
                platform: fakePlatform,
                flutterVersion: fakeFlutterVersion,
                cache: cache,
                verboseHelp: false,
              );
              command.produceFlutterPodspec(BuildMode.release, outputDirectory);

              final File expectedPodspec = outputDirectory.childFile('FlutterMacOS.podspec');
              final String podspecContents = expectedPodspec.readAsStringSync();
              expect(
                podspecContents,
                contains(
                  "'$storageBaseUrl/flutter_infra_release/flutter/$engineRevision/darwin-x64-release/FlutterMacOS.framework.zip'",
                ),
              );
            },
            overrides: <Type, Generator>{
              FileSystem: () => memoryFileSystem,
              ProcessManager: () => FakeProcessManager.any(),
            },
          );
        });
      });
    });
  });

  group('XCFrameworks', () {
    late MemoryFileSystem fileSystem;
    late FakeProcessManager fakeProcessManager;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      fakeProcessManager = FakeProcessManager.empty();
    });

    testWithoutContext('created', () async {
      final Directory frameworkA = fileSystem.directory('FrameworkA.framework')..createSync();
      final Directory frameworkB = fileSystem.directory('FrameworkB.framework')..createSync();
      final Directory output = fileSystem.directory('output');

      fakeProcessManager.addCommand(
        FakeCommand(
          command: <String>[
            'xcrun',
            'xcodebuild',
            '-create-xcframework',
            '-framework',
            frameworkA.path,
            '-framework',
            frameworkB.path,
            '-output',
            output.childDirectory('Combine.xcframework').path,
          ],
        ),
      );
      await BuildFrameworkCommand.produceXCFramework(
        <Directory>[frameworkA, frameworkB],
        'Combine',
        output,
        fakeProcessManager,
      );
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testWithoutContext('created with symbols', () async {
      final Directory parentA = fileSystem.directory('FrameworkA')..createSync();
      final File dSYMA = parentA.childFile('FrameworkA.framework.dSYM')..createSync();
      final Directory frameworkA = parentA.childDirectory('FrameworkA.framework')..createSync();
      // Flutter.framework.dSYM should be correctly filtered out.
      parentA.childFile('Flutter.framework.dSYM').createSync();

      final Directory parentB = fileSystem.directory('FrameworkB')..createSync();
      final File dSYMB = parentB.childFile('FrameworkB.framework.dSYM')..createSync();
      final Directory frameworkB = parentB.childDirectory('FrameworkB.framework')..createSync();
      final Directory output = fileSystem.directory('output');

      fakeProcessManager.addCommand(
        FakeCommand(
          command: <String>[
            'xcrun',
            'xcodebuild',
            '-create-xcframework',
            '-framework',
            frameworkA.path,
            '-debug-symbols',
            dSYMA.path,
            '-framework',
            frameworkB.path,
            '-debug-symbols',
            dSYMB.path,
            '-output',
            output.childDirectory('Combine.xcframework').path,
          ],
        ),
      );
      await BuildFrameworkCommand.produceXCFramework(
        <Directory>[frameworkA, frameworkB],
        'Combine',
        output,
        fakeProcessManager,
      );
      expect(fakeProcessManager, hasNoRemainingExpectations);
    });
  });

  group('parseVendoredFrameworksFromPbxproj', () {
    late MemoryFileSystem fileSystem;
    late BufferLogger logger;
    late FakePlistParser fakePlistParser;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      logger = BufferLogger.test();
      fakePlistParser = FakePlistParser();
    });

    testWithoutContext('returns empty list when project file does not exist', () {
      final File projectFile = fileSystem.file('/nonexistent/project.pbxproj');
      fakePlistParser.setJsonContent(projectFile.path, null);

      final List<String> result = parseVendoredFrameworksFromPbxproj(
        projectFile,
        fakePlistParser,
        logger,
      );

      expect(result, isEmpty);
    });

    testWithoutContext('returns empty list when no Frameworks group exists', () {
      final File projectFile = fileSystem.file('/test/project.pbxproj')
        ..createSync(recursive: true);
      fakePlistParser.setJsonContent(projectFile.path, '''
{
  "objects": {
    "ABC123": {
      "isa": "PBXGroup",
      "name": "Sources",
      "children": ["DEF456"]
    }
  }
}
''');

      final List<String> result = parseVendoredFrameworksFromPbxproj(
        projectFile,
        fakePlistParser,
        logger,
      );

      expect(result, isEmpty);
    });

    testWithoutContext('parses frameworks from Frameworks group', () {
      final File projectFile = fileSystem.file('/test/project.pbxproj')
        ..createSync(recursive: true);
      fakePlistParser.setJsonContent(projectFile.path, '''
{
  "objects": {
    "GROUP1": {
      "isa": "PBXGroup",
      "name": "Frameworks",
      "children": ["REF1", "REF2"]
    },
    "REF1": {
      "isa": "PBXFileReference",
      "path": "MySDK.xcframework"
    },
    "REF2": {
      "isa": "PBXFileReference",
      "path": "AnotherSDK.framework"
    }
  }
}
''');

      final List<String> result = parseVendoredFrameworksFromPbxproj(
        projectFile,
        fakePlistParser,
        logger,
      );

      expect(result, containsAll(<String>['MySDK.xcframework', 'AnotherSDK.framework']));
    });

    testWithoutContext('skips non-framework files in Frameworks group', () {
      final File projectFile = fileSystem.file('/test/project.pbxproj')
        ..createSync(recursive: true);
      fakePlistParser.setJsonContent(projectFile.path, '''
{
  "objects": {
    "GROUP1": {
      "isa": "PBXGroup",
      "name": "Frameworks",
      "children": ["REF1", "REF2", "REF3"]
    },
    "REF1": {
      "isa": "PBXFileReference",
      "path": "MySDK.xcframework"
    },
    "REF2": {
      "isa": "PBXFileReference",
      "path": "libsomething.a"
    },
    "REF3": {
      "isa": "PBXFileReference",
      "path": "something.dylib"
    }
  }
}
''');

      final List<String> result = parseVendoredFrameworksFromPbxproj(
        projectFile,
        fakePlistParser,
        logger,
      );

      expect(result, <String>['MySDK.xcframework']);
    });

    testWithoutContext('handles multiple Frameworks groups', () {
      final File projectFile = fileSystem.file('/test/project.pbxproj')
        ..createSync(recursive: true);
      fakePlistParser.setJsonContent(projectFile.path, '''
{
  "objects": {
    "GROUP1": {
      "isa": "PBXGroup",
      "name": "Frameworks",
      "children": ["REF1"]
    },
    "GROUP2": {
      "isa": "PBXGroup",
      "name": "Frameworks",
      "children": ["REF2"]
    },
    "REF1": {
      "isa": "PBXFileReference",
      "path": "SDK1.xcframework"
    },
    "REF2": {
      "isa": "PBXFileReference",
      "path": "SDK2.xcframework"
    }
  }
}
''');

      final List<String> result = parseVendoredFrameworksFromPbxproj(
        projectFile,
        fakePlistParser,
        logger,
      );

      expect(result, containsAll(<String>['SDK1.xcframework', 'SDK2.xcframework']));
    });

    testWithoutContext('handles invalid JSON gracefully', () {
      final File projectFile = fileSystem.file('/test/project.pbxproj')
        ..createSync(recursive: true);
      fakePlistParser.setJsonContent(projectFile.path, 'not valid json');

      final List<String> result = parseVendoredFrameworksFromPbxproj(
        projectFile,
        fakePlistParser,
        logger,
      );

      expect(result, isEmpty);
    });
  });

  group('copyVendoredFrameworks', () {
    late MemoryFileSystem fileSystem;
    late FakeProcessManager fakeProcessManager;
    late FakePlatform fakePlatform;
    late BufferLogger logger;
    late FakePlistParser fakePlistParser;
    late Directory modeDirectory;
    late Directory hostAppRoot;
    late Cache cache;

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      fakeProcessManager = FakeProcessManager.empty();
      fakePlatform = FakePlatform(operatingSystem: 'macos');
      logger = BufferLogger.test();
      fakePlistParser = FakePlistParser();
      cache = Cache.test(fileSystem: fileSystem, processManager: FakeProcessManager.any());

      modeDirectory = fileSystem.directory('/output/Debug')..createSync(recursive: true);
      hostAppRoot = fileSystem.directory('/project/ios')..createSync(recursive: true);
    });

    testUsingContext(
      'does nothing when Pods.xcodeproj does not exist',
      () async {
        final command = BuildIOSFrameworkCommand(
          logger: logger,
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          platform: fakePlatform,
          flutterVersion: FakeFlutterVersion(),
          cache: cache,
          verboseHelp: false,
        );

        await command.copyVendoredFrameworks(modeDirectory, hostAppRoot, fakePlistParser);

        // Should not create any frameworks in output
        expect(modeDirectory.listSync(), isEmpty);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => fakeProcessManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'does nothing when parseVendoredFrameworksFromPbxproj returns empty list',
      () async {
        // Create project.pbxproj but with no frameworks
        final File projectFile =
            hostAppRoot
                .childDirectory('Pods')
                .childDirectory('Pods.xcodeproj')
                .childFile('project.pbxproj')
              ..createSync(recursive: true);
        fakePlistParser.setJsonContent(projectFile.path, '''
{
  "objects": {
    "ABC123": {
      "isa": "PBXGroup",
      "name": "Sources",
      "children": []
    }
  }
}
''');

        final command = BuildIOSFrameworkCommand(
          logger: logger,
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          platform: fakePlatform,
          flutterVersion: FakeFlutterVersion(),
          cache: cache,
          verboseHelp: false,
        );

        await command.copyVendoredFrameworks(modeDirectory, hostAppRoot, fakePlistParser);

        // Should not create any frameworks in output
        expect(modeDirectory.listSync(), isEmpty);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => fakeProcessManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'skips Flutter.framework, Flutter.xcframework, App.framework, App.xcframework',
      () async {
        final File projectFile =
            hostAppRoot
                .childDirectory('Pods')
                .childDirectory('Pods.xcodeproj')
                .childFile('project.pbxproj')
              ..createSync(recursive: true);
        fakePlistParser.setJsonContent(projectFile.path, '''
{
  "objects": {
    "GROUP1": {
      "isa": "PBXGroup",
      "name": "Frameworks",
      "children": ["REF1", "REF2", "REF3", "REF4"]
    },
    "REF1": {
      "isa": "PBXFileReference",
      "path": "Flutter.framework"
    },
    "REF2": {
      "isa": "PBXFileReference",
      "path": "Flutter.xcframework"
    },
    "REF3": {
      "isa": "PBXFileReference",
      "path": "App.framework"
    },
    "REF4": {
      "isa": "PBXFileReference",
      "path": "App.xcframework"
    }
  }
}
''');

        // Create the framework directories in Pods (though they should be skipped)
        final Directory podsDir = hostAppRoot.childDirectory('Pods');
        podsDir.childDirectory('Flutter.framework').createSync(recursive: true);
        podsDir.childDirectory('Flutter.xcframework').createSync(recursive: true);
        podsDir.childDirectory('App.framework').createSync(recursive: true);
        podsDir.childDirectory('App.xcframework').createSync(recursive: true);

        final command = BuildIOSFrameworkCommand(
          logger: logger,
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          platform: fakePlatform,
          flutterVersion: FakeFlutterVersion(),
          cache: cache,
          verboseHelp: false,
        );

        await command.copyVendoredFrameworks(modeDirectory, hostAppRoot, fakePlistParser);

        // Should not copy any of the Flutter/App frameworks
        expect(modeDirectory.listSync(), isEmpty);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => fakeProcessManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'copies xcframework directly to output',
      () async {
        final File projectFile =
            hostAppRoot
                .childDirectory('Pods')
                .childDirectory('Pods.xcodeproj')
                .childFile('project.pbxproj')
              ..createSync(recursive: true);
        fakePlistParser.setJsonContent(projectFile.path, '''
{
  "objects": {
    "GROUP1": {
      "isa": "PBXGroup",
      "name": "Frameworks",
      "children": ["REF1"]
    },
    "REF1": {
      "isa": "PBXFileReference",
      "path": "MySDK.xcframework"
    }
  }
}
''');

        // Create the xcframework with some content
        final Directory xcframework =
            hostAppRoot.childDirectory('Pods').childDirectory('MySDK.xcframework')
              ..createSync(recursive: true);
        xcframework.childFile('Info.plist').writeAsStringSync('plist content');
        xcframework.childDirectory('ios-arm64').createSync();

        final command = BuildIOSFrameworkCommand(
          logger: logger,
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          platform: fakePlatform,
          flutterVersion: FakeFlutterVersion(),
          cache: cache,
          verboseHelp: false,
        );

        await command.copyVendoredFrameworks(modeDirectory, hostAppRoot, fakePlistParser);

        // Should copy the xcframework
        expect(modeDirectory.childDirectory('MySDK.xcframework').existsSync(), isTrue);
        expect(
          modeDirectory.childDirectory('MySDK.xcframework').childFile('Info.plist').existsSync(),
          isTrue,
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => fakeProcessManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'creates xcframework from .framework using xcodebuild',
      () async {
        final File projectFile =
            hostAppRoot
                .childDirectory('Pods')
                .childDirectory('Pods.xcodeproj')
                .childFile('project.pbxproj')
              ..createSync(recursive: true);
        fakePlistParser.setJsonContent(projectFile.path, '''
{
  "objects": {
    "GROUP1": {
      "isa": "PBXGroup",
      "name": "Frameworks",
      "children": ["REF1"]
    },
    "REF1": {
      "isa": "PBXFileReference",
      "path": "MySDK.framework"
    }
  }
}
''');

        // Create the framework
        final Directory framework =
            hostAppRoot.childDirectory('Pods').childDirectory('MySDK.framework')
              ..createSync(recursive: true);
        framework.childFile('MySDK').writeAsStringSync('binary');

        fakeProcessManager.addCommand(
          FakeCommand(
            command: <String>[
              'xcrun',
              'xcodebuild',
              '-create-xcframework',
              '-framework',
              framework.path,
              '-output',
              modeDirectory.childDirectory('MySDK.xcframework').path,
            ],
          ),
        );

        final command = BuildIOSFrameworkCommand(
          logger: logger,
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          platform: fakePlatform,
          flutterVersion: FakeFlutterVersion(),
          cache: cache,
          verboseHelp: false,
        );

        await command.copyVendoredFrameworks(modeDirectory, hostAppRoot, fakePlistParser);

        expect(fakeProcessManager, hasNoRemainingExpectations);
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => fakeProcessManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'skips framework that does not exist on disk',
      () async {
        final File projectFile =
            hostAppRoot
                .childDirectory('Pods')
                .childDirectory('Pods.xcodeproj')
                .childFile('project.pbxproj')
              ..createSync(recursive: true);
        fakePlistParser.setJsonContent(projectFile.path, '''
{
  "objects": {
    "GROUP1": {
      "isa": "PBXGroup",
      "name": "Frameworks",
      "children": ["REF1"]
    },
    "REF1": {
      "isa": "PBXFileReference",
      "path": "NonExistent.xcframework"
    }
  }
}
''');

        // Don't create the framework - it should be skipped

        final command = BuildIOSFrameworkCommand(
          logger: logger,
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          platform: fakePlatform,
          flutterVersion: FakeFlutterVersion(),
          cache: cache,
          verboseHelp: false,
        );

        await command.copyVendoredFrameworks(modeDirectory, hostAppRoot, fakePlistParser);

        // Should not create anything in output
        expect(modeDirectory.listSync(), isEmpty);
        // Should log trace message
        expect(logger.traceText, contains('Vendored framework not found'));
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => fakeProcessManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'skips duplicate frameworks with same binary name',
      () async {
        final File projectFile =
            hostAppRoot
                .childDirectory('Pods')
                .childDirectory('Pods.xcodeproj')
                .childFile('project.pbxproj')
              ..createSync(recursive: true);
        fakePlistParser.setJsonContent(projectFile.path, '''
{
  "objects": {
    "GROUP1": {
      "isa": "PBXGroup",
      "name": "Frameworks",
      "children": ["REF1", "REF2"]
    },
    "REF1": {
      "isa": "PBXFileReference",
      "path": "path1/MySDK.xcframework"
    },
    "REF2": {
      "isa": "PBXFileReference",
      "path": "path2/MySDK.xcframework"
    }
  }
}
''');

        // Create both xcframeworks
        final Directory podsDir = hostAppRoot.childDirectory('Pods');
        final Directory xcframework1 =
            podsDir.childDirectory('path1').childDirectory('MySDK.xcframework')
              ..createSync(recursive: true);
        xcframework1.childFile('Info.plist').writeAsStringSync('plist1');

        final Directory xcframework2 =
            podsDir.childDirectory('path2').childDirectory('MySDK.xcframework')
              ..createSync(recursive: true);
        xcframework2.childFile('Info.plist').writeAsStringSync('plist2');

        final command = BuildIOSFrameworkCommand(
          logger: logger,
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          platform: fakePlatform,
          flutterVersion: FakeFlutterVersion(),
          cache: cache,
          verboseHelp: false,
        );

        await command.copyVendoredFrameworks(modeDirectory, hostAppRoot, fakePlistParser);

        // Should only copy once
        expect(modeDirectory.childDirectory('MySDK.xcframework').existsSync(), isTrue);
        // Content should be from first one
        expect(
          modeDirectory
              .childDirectory('MySDK.xcframework')
              .childFile('Info.plist')
              .readAsStringSync(),
          'plist1',
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => fakeProcessManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'does not re-copy xcframework if already exists in output',
      () async {
        final File projectFile =
            hostAppRoot
                .childDirectory('Pods')
                .childDirectory('Pods.xcodeproj')
                .childFile('project.pbxproj')
              ..createSync(recursive: true);
        fakePlistParser.setJsonContent(projectFile.path, '''
{
  "objects": {
    "GROUP1": {
      "isa": "PBXGroup",
      "name": "Frameworks",
      "children": ["REF1"]
    },
    "REF1": {
      "isa": "PBXFileReference",
      "path": "MySDK.xcframework"
    }
  }
}
''');

        // Create the source xcframework
        final Directory xcframework =
            hostAppRoot.childDirectory('Pods').childDirectory('MySDK.xcframework')
              ..createSync(recursive: true);
        xcframework.childFile('Info.plist').writeAsStringSync('source plist');

        // Create existing xcframework in output with different content
        final Directory existingXcframework = modeDirectory.childDirectory('MySDK.xcframework')
          ..createSync(recursive: true);
        existingXcframework.childFile('Info.plist').writeAsStringSync('existing plist');

        final command = BuildIOSFrameworkCommand(
          logger: logger,
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          platform: fakePlatform,
          flutterVersion: FakeFlutterVersion(),
          cache: cache,
          verboseHelp: false,
        );

        await command.copyVendoredFrameworks(modeDirectory, hostAppRoot, fakePlistParser);

        // Should not overwrite existing
        expect(
          modeDirectory
              .childDirectory('MySDK.xcframework')
              .childFile('Info.plist')
              .readAsStringSync(),
          'existing plist',
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => fakeProcessManager,
        Logger: () => logger,
      },
    );

    testUsingContext(
      'handles nested framework paths',
      () async {
        final File projectFile =
            hostAppRoot
                .childDirectory('Pods')
                .childDirectory('Pods.xcodeproj')
                .childFile('project.pbxproj')
              ..createSync(recursive: true);
        fakePlistParser.setJsonContent(projectFile.path, '''
{
  "objects": {
    "GROUP1": {
      "isa": "PBXGroup",
      "name": "Frameworks",
      "children": ["REF1"]
    },
    "REF1": {
      "isa": "PBXFileReference",
      "path": "SomePlugin/Frameworks/Vendored/MySDK.xcframework"
    }
  }
}
''');

        // Create the nested xcframework
        final Directory podsDir = hostAppRoot.childDirectory('Pods');
        final Directory xcframework =
            podsDir
                .childDirectory('SomePlugin')
                .childDirectory('Frameworks')
                .childDirectory('Vendored')
                .childDirectory('MySDK.xcframework')
              ..createSync(recursive: true);
        xcframework.childFile('Info.plist').writeAsStringSync('nested plist');

        final command = BuildIOSFrameworkCommand(
          logger: logger,
          buildSystem: TestBuildSystem.all(BuildResult(success: true)),
          platform: fakePlatform,
          flutterVersion: FakeFlutterVersion(),
          cache: cache,
          verboseHelp: false,
        );

        await command.copyVendoredFrameworks(modeDirectory, hostAppRoot, fakePlistParser);

        // Should copy the xcframework to output
        expect(modeDirectory.childDirectory('MySDK.xcframework').existsSync(), isTrue);
        expect(
          modeDirectory
              .childDirectory('MySDK.xcframework')
              .childFile('Info.plist')
              .readAsStringSync(),
          'nested plist',
        );
      },
      overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => fakeProcessManager,
        Logger: () => logger,
      },
    );
  });
}

/// A fake PlistParser for testing that returns pre-configured JSON content.
class FakePlistParser extends PlistParser {
  FakePlistParser()
    : super(
        fileSystem: MemoryFileSystem.test(),
        logger: BufferLogger.test(),
        processManager: FakeProcessManager.any(),
      );

  final Map<String, String?> _jsonContentByPath = <String, String?>{};

  void setJsonContent(String path, String? content) {
    _jsonContentByPath[path] = content;
  }

  @override
  String? plistJsonContent(String filePath) {
    return _jsonContentByPath[filePath];
  }
}
