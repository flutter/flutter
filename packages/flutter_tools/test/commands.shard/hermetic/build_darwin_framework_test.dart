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
      final File projectFile = fileSystem.file('/test/project.pbxproj')..createSync(recursive: true);
      fakePlistParser.setJsonContent(
        projectFile.path,
        '''
{
  "objects": {
    "ABC123": {
      "isa": "PBXGroup",
      "name": "Sources",
      "children": ["DEF456"]
    }
  }
}
''',
      );

      final List<String> result = parseVendoredFrameworksFromPbxproj(
        projectFile,
        fakePlistParser,
        logger,
      );

      expect(result, isEmpty);
    });

    testWithoutContext('parses frameworks from Frameworks group', () {
      final File projectFile = fileSystem.file('/test/project.pbxproj')..createSync(recursive: true);
      fakePlistParser.setJsonContent(
        projectFile.path,
        '''
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
''',
      );

      final List<String> result = parseVendoredFrameworksFromPbxproj(
        projectFile,
        fakePlistParser,
        logger,
      );

      expect(result, containsAll(<String>['MySDK.xcframework', 'AnotherSDK.framework']));
    });

    testWithoutContext('skips non-framework files in Frameworks group', () {
      final File projectFile = fileSystem.file('/test/project.pbxproj')..createSync(recursive: true);
      fakePlistParser.setJsonContent(
        projectFile.path,
        '''
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
''',
      );

      final List<String> result = parseVendoredFrameworksFromPbxproj(
        projectFile,
        fakePlistParser,
        logger,
      );

      expect(result, <String>['MySDK.xcframework']);
    });

    testWithoutContext('handles multiple Frameworks groups', () {
      final File projectFile = fileSystem.file('/test/project.pbxproj')..createSync(recursive: true);
      fakePlistParser.setJsonContent(
        projectFile.path,
        '''
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
''',
      );

      final List<String> result = parseVendoredFrameworksFromPbxproj(
        projectFile,
        fakePlistParser,
        logger,
      );

      expect(result, containsAll(<String>['SDK1.xcframework', 'SDK2.xcframework']));
    });

    testWithoutContext('handles invalid JSON gracefully', () {
      final File projectFile = fileSystem.file('/test/project.pbxproj')..createSync(recursive: true);
      fakePlistParser.setJsonContent(projectFile.path, 'not valid json');

      final List<String> result = parseVendoredFrameworksFromPbxproj(
        projectFile,
        fakePlistParser,
        logger,
      );

      expect(result, isEmpty);
    });
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
