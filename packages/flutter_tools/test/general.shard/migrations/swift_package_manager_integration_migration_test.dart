// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/migrations/swift_package_manager_integration_migration.dart';

import 'package:flutter_tools/src/project.dart';
import 'package:meta/meta.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fakes.dart';

/// An override for the return value of [_runnerNativeTargetIdentifier].
///
/// This is used in tests that need a different PBXNativeTarget identifier
/// than the default for the Runner target.
@visibleForTesting
String? runnerNativeTargetIdentifierOverride;

const List<SupportedPlatform> supportedPlatforms = <SupportedPlatform>[
  SupportedPlatform.ios,
  SupportedPlatform.macos,
];

void main() {
  final TestFeatureFlags swiftPackageManagerFullyEnabledFlags = TestFeatureFlags(
    isSwiftPackageManagerEnabled: true,
  );

  test('runnerNativeTargetIdentifierOverride works', () {
    for (final SupportedPlatform supportedPlatform in supportedPlatforms) {
      runnerNativeTargetIdentifierOverride = null;
      final String overrideValue = _alternateRunnerNativeTargetIdentifier(supportedPlatform);

      expect(_runnerNativeTargetIdentifier(supportedPlatform), isNot(overrideValue));
      runnerNativeTargetIdentifierOverride = overrideValue;
      expect(_runnerNativeTargetIdentifier(supportedPlatform), overrideValue);
    }

    runnerNativeTargetIdentifierOverride = null;
  });

  group('Flutter Package Migration', () {
    testWithoutContext('skips if swift package manager is off', () async {
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
      final BufferLogger testLogger = BufferLogger.test();

      final SwiftPackageManagerIntegrationMigration projectMigration =
          SwiftPackageManagerIntegrationMigration(
            FakeXcodeProject(
              platform: SupportedPlatform.ios.name,
              fileSystem: memoryFileSystem,
              logger: testLogger,
            ),
            SupportedPlatform.ios,
            BuildInfo.debug,
            xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
            logger: testLogger,
            fileSystem: memoryFileSystem,
            plistParser: FakePlistParser(),
            features: TestFeatureFlags(),
          );
      await projectMigration.migrate();
      expect(
        testLogger.traceText,
        contains('Skipping the migration that adds Swift Package Manager integration...'),
      );
      expect(testLogger.statusText, isEmpty);
    });

    testWithoutContext("skips if there's no generated swift package", () async {
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
      final BufferLogger testLogger = BufferLogger.test();

      final SwiftPackageManagerIntegrationMigration projectMigration =
          SwiftPackageManagerIntegrationMigration(
            FakeXcodeProject(
              platform: SupportedPlatform.ios.name,
              fileSystem: memoryFileSystem,
              logger: testLogger,
            ),
            SupportedPlatform.ios,
            BuildInfo.debug,
            xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
            logger: testLogger,
            fileSystem: memoryFileSystem,
            plistParser: FakePlistParser(),
            features: swiftPackageManagerFullyEnabledFlags,
          );
      await projectMigration.migrate();
      expect(
        testLogger.traceText,
        contains('Skipping the migration that adds Swift Package Manager integration...'),
      );
      expect(testLogger.traceText, contains('The tool did not generate a Swift package.'));
      expect(testLogger.statusText, isEmpty);
    });

    testWithoutContext('fails if Xcode project not found', () async {
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
      final BufferLogger testLogger = BufferLogger.test();
      final FakeXcodeProject project = FakeXcodeProject(
        platform: SupportedPlatform.ios.name,
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );

      project.flutterPluginSwiftPackageManifest.createSync(recursive: true);

      final SwiftPackageManagerIntegrationMigration projectMigration =
          SwiftPackageManagerIntegrationMigration(
            project,
            SupportedPlatform.ios,
            BuildInfo.debug,
            xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
            logger: testLogger,
            fileSystem: memoryFileSystem,
            plistParser: FakePlistParser(),
            features: swiftPackageManagerFullyEnabledFlags,
          );
      await expectLater(
        () => projectMigration.migrate(),
        throwsToolExit(message: 'Xcode project not found.'),
      );
      expect(testLogger.traceText, isEmpty);
      expect(testLogger.statusText, isEmpty);
    });

    group('get scheme file', () {
      testWithoutContext('fails if Xcode project info not found', () async {
        final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
        final BufferLogger testLogger = BufferLogger.test();
        final FakeXcodeProject project = FakeXcodeProject(
          platform: SupportedPlatform.ios.name,
          fileSystem: memoryFileSystem,
          logger: testLogger,
        );
        _createProjectFiles(project, SupportedPlatform.ios);
        project._projectInfo = null;

        final SwiftPackageManagerIntegrationMigration projectMigration =
            SwiftPackageManagerIntegrationMigration(
              project,
              SupportedPlatform.ios,
              BuildInfo.debug,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(),
              features: swiftPackageManagerFullyEnabledFlags,
            );
        await expectLater(
          () => projectMigration.migrate(),
          throwsToolExit(message: 'Unable to get Xcode project info.'),
        );
        expect(testLogger.traceText, isEmpty);
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('fails if Xcode workspace not found', () async {
        final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
        final BufferLogger testLogger = BufferLogger.test();
        final FakeXcodeProject project = FakeXcodeProject(
          platform: SupportedPlatform.ios.name,
          fileSystem: memoryFileSystem,
          logger: testLogger,
        );
        _createProjectFiles(project, SupportedPlatform.ios);
        project.xcodeWorkspace = null;

        final SwiftPackageManagerIntegrationMigration projectMigration =
            SwiftPackageManagerIntegrationMigration(
              project,
              SupportedPlatform.ios,
              BuildInfo.debug,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(),
              features: swiftPackageManagerFullyEnabledFlags,
            );
        await expectLater(
          () => projectMigration.migrate(),
          throwsToolExit(message: 'Xcode workspace not found.'),
        );
        expect(testLogger.traceText, isEmpty);
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('fails if scheme not found', () async {
        final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
        final BufferLogger testLogger = BufferLogger.test();
        final FakeXcodeProject project = FakeXcodeProject(
          platform: SupportedPlatform.ios.name,
          fileSystem: memoryFileSystem,
          logger: testLogger,
        );
        _createProjectFiles(project, SupportedPlatform.ios);
        project._projectInfo = XcodeProjectInfo(<String>[], <String>[], <String>[], testLogger);

        final SwiftPackageManagerIntegrationMigration projectMigration =
            SwiftPackageManagerIntegrationMigration(
              project,
              SupportedPlatform.ios,
              BuildInfo.debug,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(),
              features: swiftPackageManagerFullyEnabledFlags,
            );
        await expectLater(
          () => projectMigration.migrate(),
          throwsToolExit(
            message: 'You must specify a --flavor option to select one of the available schemes.',
          ),
        );
        expect(testLogger.traceText, isEmpty);
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('fails if scheme file not found', () async {
        final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
        final BufferLogger testLogger = BufferLogger.test();
        final FakeXcodeProject project = FakeXcodeProject(
          platform: SupportedPlatform.ios.name,
          fileSystem: memoryFileSystem,
          logger: testLogger,
        );
        _createProjectFiles(project, SupportedPlatform.ios, createSchemeFile: false);

        final SwiftPackageManagerIntegrationMigration projectMigration =
            SwiftPackageManagerIntegrationMigration(
              project,
              SupportedPlatform.ios,
              BuildInfo.debug,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(),
              features: swiftPackageManagerFullyEnabledFlags,
            );
        await expectLater(
          () => projectMigration.migrate(),
          throwsToolExit(message: 'Unable to get scheme file for Runner.'),
        );
        expect(testLogger.traceText, isEmpty);
        expect(testLogger.statusText, isEmpty);
      });
    });

    testWithoutContext('does not migrate if already migrated', () async {
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
      final BufferLogger testLogger = BufferLogger.test();
      final FakeXcodeProject project = FakeXcodeProject(
        platform: SupportedPlatform.ios.name,
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );
      _createProjectFiles(project, SupportedPlatform.ios);
      project.xcodeProjectSchemeFile().writeAsStringSync(
        _validBuildActions(SupportedPlatform.ios, hasFrameworkScript: true),
      );
      project.xcodeProjectInfoFile.writeAsStringSync(
        _projectSettings(_allSectionsMigrated(SupportedPlatform.ios)),
      );

      final SwiftPackageManagerIntegrationMigration projectMigration =
          SwiftPackageManagerIntegrationMigration(
            project,
            SupportedPlatform.ios,
            BuildInfo.debug,
            xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
            logger: testLogger,
            fileSystem: memoryFileSystem,
            plistParser: FakePlistParser(),
            features: swiftPackageManagerFullyEnabledFlags,
          );
      await projectMigration.migrate();
      expect(testLogger.traceText, isEmpty);
      expect(testLogger.statusText, isEmpty);
      expect(testLogger.warningText, isEmpty);
      expect(testLogger.errorText, isEmpty);
    });

    group('migrate scheme', () {
      testWithoutContext('skipped if already updated', () async {
        final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
        final BufferLogger testLogger = BufferLogger.test();
        final FakeXcodeProject project = FakeXcodeProject(
          platform: SupportedPlatform.ios.name,
          fileSystem: memoryFileSystem,
          logger: testLogger,
        );
        _createProjectFiles(project, SupportedPlatform.ios);
        project.xcodeProjectSchemeFile().writeAsStringSync(
          _validBuildActions(SupportedPlatform.ios, hasFrameworkScript: true),
        );

        project.xcodeProjectInfoFile.writeAsStringSync('');

        final List<String> settingsAsJsonBeforeMigration = <String>[
          ..._allSectionsMigratedAsJson(SupportedPlatform.ios),
        ];
        settingsAsJsonBeforeMigration.removeAt(_buildFileSectionIndex);

        final SwiftPackageManagerIntegrationMigration projectMigration =
            SwiftPackageManagerIntegrationMigration(
              project,
              SupportedPlatform.ios,
              BuildInfo.debug,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(json: _plutilOutput(settingsAsJsonBeforeMigration)),
              features: swiftPackageManagerFullyEnabledFlags,
            );
        await expectLater(() => projectMigration.migrate(), throwsToolExit());
        expect(testLogger.traceText, contains('Runner.xcscheme already migrated. Skipping...'));
      });

      for (final SupportedPlatform platform in supportedPlatforms) {
        group('for ${platform.name}', () {
          testWithoutContext('fails if scheme file is empty', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: memoryFileSystem,
              logger: testLogger,
            );
            _createProjectFiles(project, platform);
            project.xcodeProjectSchemeFile().writeAsStringSync('');

            final SwiftPackageManagerIntegrationMigration projectMigration =
                SwiftPackageManagerIntegrationMigration(
                  project,
                  platform,
                  BuildInfo.debug,
                  xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                  logger: testLogger,
                  fileSystem: memoryFileSystem,
                  plistParser: FakePlistParser(),
                  features: swiftPackageManagerFullyEnabledFlags,
                );

            await expectLater(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Failed to parse Runner.xcscheme: Invalid xml:'),
            );
          });

          testWithoutContext('fails if scheme file has no Scheme root node', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: memoryFileSystem,
              logger: testLogger,
            );
            _createProjectFiles(project, platform);
            project.xcodeProjectSchemeFile().writeAsStringSync('<NotAScheme></NotAScheme>');

            final SwiftPackageManagerIntegrationMigration projectMigration =
                SwiftPackageManagerIntegrationMigration(
                  project,
                  platform,
                  BuildInfo.debug,
                  xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                  logger: testLogger,
                  fileSystem: memoryFileSystem,
                  plistParser: FakePlistParser(),
                  features: swiftPackageManagerFullyEnabledFlags,
                );

            await expectLater(
              () => projectMigration.migrate(),
              throwsToolExit(
                message: 'Failed to parse Runner.xcscheme: Could not find Scheme for Runner.',
              ),
            );
          });

          testWithoutContext('fails if Scheme node has no LaunchAction', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: memoryFileSystem,
              logger: testLogger,
            );
            _createProjectFiles(project, platform);
            project.xcodeProjectSchemeFile().writeAsStringSync('<Scheme></Scheme>');

            final SwiftPackageManagerIntegrationMigration projectMigration =
                SwiftPackageManagerIntegrationMigration(
                  project,
                  platform,
                  BuildInfo.debug,
                  xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                  logger: testLogger,
                  fileSystem: memoryFileSystem,
                  plistParser: FakePlistParser(),
                  features: swiftPackageManagerFullyEnabledFlags,
                );

            await expectLater(
              () => projectMigration.migrate(),
              throwsToolExit(
                message: 'Failed to parse Runner.xcscheme: Could not find LaunchAction for Runner.',
              ),
            );
          });

          testWithoutContext('fails if LaunchAction has no BuildableProductRunnable', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: memoryFileSystem,
              logger: testLogger,
            );
            _createProjectFiles(project, platform);
            project.xcodeProjectSchemeFile().writeAsStringSync('''
<Scheme>
  <LaunchAction></LaunchAction>
</Scheme>
''');

            final SwiftPackageManagerIntegrationMigration projectMigration =
                SwiftPackageManagerIntegrationMigration(
                  project,
                  platform,
                  BuildInfo.debug,
                  xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                  logger: testLogger,
                  fileSystem: memoryFileSystem,
                  plistParser: FakePlistParser(),
                  features: swiftPackageManagerFullyEnabledFlags,
                );

            await expectLater(
              () => projectMigration.migrate(),
              throwsToolExit(
                message:
                    'Failed to parse Runner.xcscheme: Could not find BuildableProductRunnable for Runner.',
              ),
            );
          });

          testWithoutContext('fails if BuildableProductRunnable has no BuildableReference', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: memoryFileSystem,
              logger: testLogger,
            );
            _createProjectFiles(project, platform);
            project.xcodeProjectSchemeFile().writeAsStringSync('''
<Scheme>
  <LaunchAction>
    <BuildableProductRunnable></BuildableProductRunnable>
  </LaunchAction>
</Scheme>
''');

            final SwiftPackageManagerIntegrationMigration projectMigration =
                SwiftPackageManagerIntegrationMigration(
                  project,
                  platform,
                  BuildInfo.debug,
                  xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                  logger: testLogger,
                  fileSystem: memoryFileSystem,
                  plistParser: FakePlistParser(),
                  features: swiftPackageManagerFullyEnabledFlags,
                );

            await expectLater(
              () => projectMigration.migrate(),
              throwsToolExit(
                message:
                    'Failed to parse Runner.xcscheme: Could not find BuildableReference for Runner.',
              ),
            );
          });

          testWithoutContext('fails if BuildableReference has no BlueprintIdentifier', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: memoryFileSystem,
              logger: testLogger,
            );
            _createProjectFiles(project, platform);
            project.xcodeProjectSchemeFile().writeAsStringSync('''
<Scheme>
  <LaunchAction>
    <BuildableProductRunnable>
      <BuildableReference
        BuildableIdentifier = "primary"
        BuildableName = "Runner.app"
        BlueprintName = "Runner"
        ReferencedContainer = "container:Runner.xcodeproj">
      </BuildableReference>
    </BuildableProductRunnable>
  </LaunchAction>
</Scheme>
''');

            final SwiftPackageManagerIntegrationMigration projectMigration =
                SwiftPackageManagerIntegrationMigration(
                  project,
                  platform,
                  BuildInfo.debug,
                  xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                  logger: testLogger,
                  fileSystem: memoryFileSystem,
                  plistParser: FakePlistParser(),
                  features: swiftPackageManagerFullyEnabledFlags,
                );

            await expectLater(
              () => projectMigration.migrate(),
              throwsToolExit(
                message:
                    'Failed to parse Runner.xcscheme: Could not find BlueprintIdentifier for Runner.',
              ),
            );
          });

          testWithoutContext('fails if BuildableReference has no BuildableName', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: memoryFileSystem,
              logger: testLogger,
            );
            _createProjectFiles(project, platform);
            project.xcodeProjectSchemeFile().writeAsStringSync('''
<Scheme>
  <LaunchAction>
    <BuildableProductRunnable>
      <BuildableReference
        BuildableIdentifier = "primary"
        BlueprintIdentifier = "${_runnerNativeTargetIdentifier(platform)}"
        BlueprintName = "Runner"
        ReferencedContainer = "container:Runner.xcodeproj">
      </BuildableReference>
    </BuildableProductRunnable>
  </LaunchAction>
</Scheme>
''');

            final SwiftPackageManagerIntegrationMigration projectMigration =
                SwiftPackageManagerIntegrationMigration(
                  project,
                  platform,
                  BuildInfo.debug,
                  xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                  logger: testLogger,
                  fileSystem: memoryFileSystem,
                  plistParser: FakePlistParser(),
                  features: swiftPackageManagerFullyEnabledFlags,
                );

            await expectLater(
              () => projectMigration.migrate(),
              throwsToolExit(
                message: 'Failed to parse Runner.xcscheme: Could not find BuildableName.',
              ),
            );
          });

          testWithoutContext('fails if BuildableReference has no BlueprintName', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: memoryFileSystem,
              logger: testLogger,
            );
            _createProjectFiles(project, platform);
            project.xcodeProjectSchemeFile().writeAsStringSync('''
<Scheme>
  <LaunchAction>
    <BuildableProductRunnable>
      <BuildableReference
        BuildableIdentifier = "primary"
        BlueprintIdentifier = "${_runnerNativeTargetIdentifier(platform)}"
        BuildableName = "Runner.app"
        ReferencedContainer = "container:Runner.xcodeproj">
      </BuildableReference>
    </BuildableProductRunnable>
  </LaunchAction>
</Scheme>
''');

            final SwiftPackageManagerIntegrationMigration projectMigration =
                SwiftPackageManagerIntegrationMigration(
                  project,
                  platform,
                  BuildInfo.debug,
                  xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                  logger: testLogger,
                  fileSystem: memoryFileSystem,
                  plistParser: FakePlistParser(),
                  features: swiftPackageManagerFullyEnabledFlags,
                );

            await expectLater(
              () => projectMigration.migrate(),
              throwsToolExit(
                message: 'Failed to parse Runner.xcscheme: Could not find BlueprintName.',
              ),
            );
          });

          testWithoutContext('fails if BuildableReference has no ReferencedContainer', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: memoryFileSystem,
              logger: testLogger,
            );
            _createProjectFiles(project, platform);
            project.xcodeProjectSchemeFile().writeAsStringSync('''
<Scheme>
  <LaunchAction>
    <BuildableProductRunnable>
      <BuildableReference
        BuildableIdentifier = "primary"
        BlueprintIdentifier = "${_runnerNativeTargetIdentifier(platform)}"
        BuildableName = "Runner.app"
        BlueprintName = "Runner">
      </BuildableReference>
    </BuildableProductRunnable>
  </LaunchAction>
</Scheme>
''');

            final SwiftPackageManagerIntegrationMigration projectMigration =
                SwiftPackageManagerIntegrationMigration(
                  project,
                  platform,
                  BuildInfo.debug,
                  xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                  logger: testLogger,
                  fileSystem: memoryFileSystem,
                  plistParser: FakePlistParser(),
                  features: swiftPackageManagerFullyEnabledFlags,
                );

            await expectLater(
              () => projectMigration.migrate(),
              throwsToolExit(
                message: 'Failed to parse Runner.xcscheme: Could not find ReferencedContainer.',
              ),
            );
          });

          testWithoutContext('fails if updated scheme is not valid xml', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: memoryFileSystem,
              logger: testLogger,
            );
            _createProjectFiles(project, platform);
            project.xcodeProjectSchemeFile().writeAsStringSync(
              '${_validBuildActions(platform)} <an opening without a close>',
            );
            final SwiftPackageManagerIntegrationMigration projectMigration =
                SwiftPackageManagerIntegrationMigration(
                  project,
                  platform,
                  BuildInfo.debug,
                  xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                  logger: testLogger,
                  fileSystem: memoryFileSystem,
                  plistParser: FakePlistParser(),
                  features: swiftPackageManagerFullyEnabledFlags,
                );

            await expectLater(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Failed to parse Runner.xcscheme: Invalid xml:'),
            );
          });

          testWithoutContext('successfully updates scheme with no BuildActionEntries', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: memoryFileSystem,
              logger: testLogger,
            );
            _createProjectFiles(project, platform);
            project.xcodeProjectSchemeFile().writeAsStringSync(
              _validBuildActions(platform, hasBuildEntries: false),
            );

            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
            ]);
            final SwiftPackageManagerIntegrationMigration projectMigration =
                SwiftPackageManagerIntegrationMigration(
                  project,
                  platform,
                  BuildInfo.debug,
                  xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                  logger: testLogger,
                  fileSystem: memoryFileSystem,
                  plistParser: plistParser,
                  features: swiftPackageManagerFullyEnabledFlags,
                );

            await projectMigration.migrate();
            expect(
              project.xcodeProjectSchemeFile().readAsStringSync(),
              _validBuildActions(platform, hasFrameworkScript: true, hasBuildEntries: false),
            );
          });

          testWithoutContext('successfully updates scheme with preexisting PreActions', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: memoryFileSystem,
              logger: testLogger,
            );
            _createProjectFiles(project, platform);
            project.xcodeProjectSchemeFile().writeAsStringSync(
              _validBuildActions(platform, hasPreActions: true),
            );
            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
            ]);
            final SwiftPackageManagerIntegrationMigration projectMigration =
                SwiftPackageManagerIntegrationMigration(
                  project,
                  platform,
                  BuildInfo.debug,
                  xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                  logger: testLogger,
                  fileSystem: memoryFileSystem,
                  plistParser: plistParser,
                  features: swiftPackageManagerFullyEnabledFlags,
                );

            await projectMigration.migrate();
            expect(
              project.xcodeProjectSchemeFile().readAsStringSync(),
              _validBuildActions(platform, hasFrameworkScript: true),
            );
          });

          testWithoutContext(
            'successfully updates scheme with no preexisting PreActions',
            () async {
              final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
              final BufferLogger testLogger = BufferLogger.test();
              final FakeXcodeProject project = FakeXcodeProject(
                platform: platform.name,
                fileSystem: memoryFileSystem,
                logger: testLogger,
              );
              _createProjectFiles(project, platform);
              project.xcodeProjectSchemeFile().writeAsStringSync(_validBuildActions(platform));

              final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
                _plutilOutput(_allSectionsMigratedAsJson(platform)),
                _plutilOutput(_allSectionsMigratedAsJson(platform)),
              ]);
              final SwiftPackageManagerIntegrationMigration projectMigration =
                  SwiftPackageManagerIntegrationMigration(
                    project,
                    platform,
                    BuildInfo.debug,
                    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                    logger: testLogger,
                    fileSystem: memoryFileSystem,
                    plistParser: plistParser,
                    features: swiftPackageManagerFullyEnabledFlags,
                  );

              await projectMigration.migrate();
              expect(
                project.xcodeProjectSchemeFile().readAsStringSync(),
                _validBuildActions(platform, hasFrameworkScript: true),
              );
            },
          );

          testWithoutContext('fails if scheme references custom target', () async {
            const String scheme = 'Other';
            const BuildInfo buildInfo = BuildInfo(
              BuildMode.debug,
              'other',
              trackWidgetCreation: true,
              treeShakeIcons: false,
              packageConfigPath: '.dart_tool/package_config.json',
            );
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: memoryFileSystem,
              logger: testLogger,
              schemes: const <String>['Runner', scheme],
            );

            final String nativeTargetIdentifier = _alternateRunnerNativeTargetIdentifier(platform);

            // Ensure that a non-default identifier works.
            expect(nativeTargetIdentifier, isNot(_runnerNativeTargetIdentifier(platform)));
            runnerNativeTargetIdentifierOverride = nativeTargetIdentifier;
            addTearDown(() {
              runnerNativeTargetIdentifierOverride = null;
            });

            // Create the Scheme file with a different BlueprintIdentifier
            // to simulate that it is made for a different target.
            _createProjectFiles(project, platform, createSchemeFile: false);
            project.xcodeProjectSchemeFile(scheme: scheme).createSync(recursive: true);
            project
                .xcodeProjectSchemeFile(scheme: scheme)
                .writeAsStringSync(_validBuildActions(platform));

            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
            ]);

            final SwiftPackageManagerIntegrationMigration projectMigration =
                SwiftPackageManagerIntegrationMigration(
                  project,
                  platform,
                  buildInfo,
                  xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                  logger: testLogger,
                  fileSystem: memoryFileSystem,
                  plistParser: plistParser,
                  features: swiftPackageManagerFullyEnabledFlags,
                );

            await expectLater(
              () => projectMigration.migrate(),
              throwsToolExit(
                message:
                    'The scheme "Other.xcscheme" references a custom target, which requires a manual migration.\n'
                    'See https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers#add-to-a-custom-xcode-target '
                    'for instructions on how to migrate custom targets.',
              ),
            );
          });
        });
      }
    });

    group('migrate pbxproj', () {
      testWithoutContext('skipped if already updated', () async {
        final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
        final BufferLogger testLogger = BufferLogger.test();
        final FakeXcodeProject project = FakeXcodeProject(
          platform: SupportedPlatform.ios.name,
          fileSystem: memoryFileSystem,
          logger: testLogger,
        );
        _createProjectFiles(project, SupportedPlatform.ios);

        project.xcodeProjectInfoFile.writeAsStringSync(
          _projectSettings(_allSectionsMigrated(SupportedPlatform.ios)),
        );

        final List<String> settingsAsJsonBeforeMigration = <String>[
          ..._allSectionsMigratedAsJson(SupportedPlatform.ios),
        ];
        settingsAsJsonBeforeMigration.removeAt(_buildFileSectionIndex);

        final SwiftPackageManagerIntegrationMigration projectMigration =
            SwiftPackageManagerIntegrationMigration(
              project,
              SupportedPlatform.ios,
              BuildInfo.debug,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(json: _plutilOutput(settingsAsJsonBeforeMigration)),
              features: swiftPackageManagerFullyEnabledFlags,
            );
        await projectMigration.migrate();
        expect(testLogger.traceText, contains('project.pbxproj already migrated. Skipping...'));
      });

      testWithoutContext('fails if unmigrated custom target is detected', () async {
        final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
        final BufferLogger testLogger = BufferLogger.test();
        const SupportedPlatform platform = SupportedPlatform.ios;
        final FakeXcodeProject project = FakeXcodeProject(
          platform: platform.name,
          fileSystem: memoryFileSystem,
          logger: testLogger,
        );

        _createProjectFiles(project, platform, createSchemeFile: false);
        project.xcodeProjectSchemeFile().createSync(recursive: true);
        project.xcodeProjectSchemeFile().writeAsStringSync(
          _validBuildActions(platform, hasFrameworkScript: true),
        );

        // Replace the PBXNativeTarget section with a two target variant,
        // where the default Runner target is migrated, but the second target is not.
        final List<String> pbxprojSections = _allSectionsUnmigrated(platform);
        pbxprojSections[_nativeTargetSectionIndex] = migratedNativeTargetSection(
          platform,
          otherNativeTarget: unmigratedOtherApplicationTarget,
        );

        project.xcodeProjectInfoFile.writeAsStringSync(_projectSettings(pbxprojSections));

        final List<String> settingsAsJsonBeforeMigration = <String>[
          ..._allSectionsUnmigratedAsJson(platform),
        ];

        settingsAsJsonBeforeMigration[_nativeTargetSectionIndex] = <String>[
          migratedNativeTargetSectionAsJson(platform),
          unmigratedOtherApplicationTargetAsJson,
        ].join(',\n');

        settingsAsJsonBeforeMigration.removeAt(_buildFileSectionIndex);

        final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
          _plutilOutput(settingsAsJsonBeforeMigration),
        ]);

        final SwiftPackageManagerIntegrationMigration projectMigration =
            SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              BuildInfo.debug,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: plistParser,
              features: swiftPackageManagerFullyEnabledFlags,
            );

        await expectLater(
          () => projectMigration.migrate(),
          throwsToolExit(
            message:
                'The PBXNativeTargets section references one or more custom targets, which requires a manual migration.\n'
                'See https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers#add-to-a-custom-xcode-target '
                'for instructions on how to migrate custom targets.',
          ),
        );
      });

      group('fails if parsing project.pbxproj', () {
        testWithoutContext('fails plutil command', () async {
          final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
          final BufferLogger testLogger = BufferLogger.test();
          final FakeXcodeProject project = FakeXcodeProject(
            platform: SupportedPlatform.ios.name,
            fileSystem: memoryFileSystem,
            logger: testLogger,
          );
          _createProjectFiles(project, SupportedPlatform.ios);

          final SwiftPackageManagerIntegrationMigration projectMigration =
              SwiftPackageManagerIntegrationMigration(
                project,
                SupportedPlatform.ios,
                BuildInfo.debug,
                xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                logger: testLogger,
                fileSystem: memoryFileSystem,
                plistParser: FakePlistParser(),
                features: swiftPackageManagerFullyEnabledFlags,
              );
          await expectLater(
            () => projectMigration.migrate(),
            throwsToolExit(message: 'Failed to parse project settings.'),
          );
        });

        testWithoutContext('returns unexpected JSON', () async {
          final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
          final BufferLogger testLogger = BufferLogger.test();
          final FakeXcodeProject project = FakeXcodeProject(
            platform: SupportedPlatform.ios.name,
            fileSystem: memoryFileSystem,
            logger: testLogger,
          );
          _createProjectFiles(project, SupportedPlatform.ios);

          final SwiftPackageManagerIntegrationMigration projectMigration =
              SwiftPackageManagerIntegrationMigration(
                project,
                SupportedPlatform.ios,
                BuildInfo.debug,
                xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                logger: testLogger,
                fileSystem: memoryFileSystem,
                plistParser: FakePlistParser(json: '[]'),
                features: swiftPackageManagerFullyEnabledFlags,
              );
          await expectLater(
            () => projectMigration.migrate(),
            throwsToolExit(message: 'project.pbxproj returned unexpected JSON response'),
          );
        });

        testWithoutContext('returns non-JSON', () async {
          final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
          final BufferLogger testLogger = BufferLogger.test();
          final FakeXcodeProject project = FakeXcodeProject(
            platform: SupportedPlatform.ios.name,
            fileSystem: memoryFileSystem,
            logger: testLogger,
          );
          _createProjectFiles(project, SupportedPlatform.ios);

          final SwiftPackageManagerIntegrationMigration projectMigration =
              SwiftPackageManagerIntegrationMigration(
                project,
                SupportedPlatform.ios,
                BuildInfo.debug,
                xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                logger: testLogger,
                fileSystem: memoryFileSystem,
                plistParser: FakePlistParser(json: 'this is not json'),
                features: swiftPackageManagerFullyEnabledFlags,
              );
          await expectLater(
            () => projectMigration.migrate(),
            throwsToolExit(message: 'project.pbxproj returned non-JSON response'),
          );
        });
      });

      group('fails if duplicate id', () {
        testWithoutContext('for PBXBuildFile', () async {
          final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
          final BufferLogger testLogger = BufferLogger.test();
          final FakeXcodeProject project = FakeXcodeProject(
            platform: SupportedPlatform.ios.name,
            fileSystem: memoryFileSystem,
            logger: testLogger,
          );
          _createProjectFiles(project, SupportedPlatform.ios);
          project.xcodeProjectInfoFile.writeAsStringSync('78A318202AECB46A00862997');

          final SwiftPackageManagerIntegrationMigration projectMigration =
              SwiftPackageManagerIntegrationMigration(
                project,
                SupportedPlatform.ios,
                BuildInfo.debug,
                xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                logger: testLogger,
                fileSystem: memoryFileSystem,
                plistParser: FakePlistParser(),
                features: swiftPackageManagerFullyEnabledFlags,
              );
          expect(
            () => projectMigration.migrate(),
            throwsToolExit(message: 'Duplicate id found for PBXBuildFile'),
          );
        });

        testWithoutContext('for XCSwiftPackageProductDependency', () async {
          final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
          final BufferLogger testLogger = BufferLogger.test();
          final FakeXcodeProject project = FakeXcodeProject(
            platform: SupportedPlatform.ios.name,
            fileSystem: memoryFileSystem,
            logger: testLogger,
          );
          _createProjectFiles(project, SupportedPlatform.ios);
          project.xcodeProjectInfoFile.writeAsStringSync('78A3181F2AECB46A00862997');

          final SwiftPackageManagerIntegrationMigration projectMigration =
              SwiftPackageManagerIntegrationMigration(
                project,
                SupportedPlatform.ios,
                BuildInfo.debug,
                xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                logger: testLogger,
                fileSystem: memoryFileSystem,
                plistParser: FakePlistParser(),
                features: swiftPackageManagerFullyEnabledFlags,
              );
          expect(
            () => projectMigration.migrate(),
            throwsToolExit(message: 'Duplicate id found for XCSwiftPackageProductDependency'),
          );
        });

        testWithoutContext('for XCLocalSwiftPackageReference', () async {
          final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
          final BufferLogger testLogger = BufferLogger.test();
          final FakeXcodeProject project = FakeXcodeProject(
            platform: SupportedPlatform.ios.name,
            fileSystem: memoryFileSystem,
            logger: testLogger,
          );
          _createProjectFiles(project, SupportedPlatform.ios);
          project.xcodeProjectInfoFile.writeAsStringSync('781AD8BC2B33823900A9FFBB');

          final SwiftPackageManagerIntegrationMigration projectMigration =
              SwiftPackageManagerIntegrationMigration(
                project,
                SupportedPlatform.ios,
                BuildInfo.debug,
                xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                logger: testLogger,
                fileSystem: memoryFileSystem,
                plistParser: FakePlistParser(),
                features: swiftPackageManagerFullyEnabledFlags,
              );
          expect(
            () => projectMigration.migrate(),
            throwsToolExit(message: 'Duplicate id found for XCLocalSwiftPackageReference'),
          );
        });
      });

      for (final SupportedPlatform platform in supportedPlatforms) {
        group('for ${platform.name}', () {
          group('migrate PBXBuildFile', () {
            testWithoutContext('fails if missing Begin PBXBuildFile section', () async {
              final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
              final BufferLogger testLogger = BufferLogger.test();
              final FakeXcodeProject project = FakeXcodeProject(
                platform: platform.name,
                fileSystem: memoryFileSystem,
                logger: testLogger,
              );
              _createProjectFiles(project, platform);

              final SwiftPackageManagerIntegrationMigration projectMigration =
                  SwiftPackageManagerIntegrationMigration(
                    project,
                    platform,
                    BuildInfo.debug,
                    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                    logger: testLogger,
                    fileSystem: memoryFileSystem,
                    plistParser: FakePlistParser(json: _plutilOutput(<String>[])),
                    features: swiftPackageManagerFullyEnabledFlags,
                  );
              expect(
                () => projectMigration.migrate(),
                throwsToolExit(message: 'Unable to find beginning of PBXBuildFile section'),
              );
            });

            testWithoutContext('fails if missing End PBXBuildFile section', () async {
              final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
              final BufferLogger testLogger = BufferLogger.test();
              final FakeXcodeProject project = FakeXcodeProject(
                platform: platform.name,
                fileSystem: memoryFileSystem,
                logger: testLogger,
              );
              _createProjectFiles(project, platform);

              final List<String> settingsBeforeMigration = <String>[
                ..._allSectionsUnmigrated(platform),
              ];
              settingsBeforeMigration[_buildFileSectionIndex] = '''
/* Begin PBXBuildFile section */
''';
              project.xcodeProjectInfoFile.writeAsStringSync(
                _projectSettings(settingsBeforeMigration),
              );
              final List<String> settingsAsJsonBeforeMigration = <String>[
                ..._allSectionsMigratedAsJson(platform),
              ];
              settingsAsJsonBeforeMigration[_buildFileSectionIndex] =
                  unmigratedBuildFileSectionAsJson;

              final SwiftPackageManagerIntegrationMigration projectMigration =
                  SwiftPackageManagerIntegrationMigration(
                    project,
                    platform,
                    BuildInfo.debug,
                    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                    logger: testLogger,
                    fileSystem: memoryFileSystem,
                    plistParser: FakePlistParser(json: _plutilOutput(<String>[])),
                    features: swiftPackageManagerFullyEnabledFlags,
                  );
              expect(
                () => projectMigration.migrate(),
                throwsToolExit(message: 'Unable to find end of PBXBuildFile section'),
              );
            });

            testWithoutContext('fails if End before Begin for PBXBuildFile section', () async {
              final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
              final BufferLogger testLogger = BufferLogger.test();
              final FakeXcodeProject project = FakeXcodeProject(
                platform: platform.name,
                fileSystem: memoryFileSystem,
                logger: testLogger,
              );
              _createProjectFiles(project, platform);

              final List<String> settingsBeforeMigration = <String>[
                ..._allSectionsUnmigrated(platform),
              ];
              settingsBeforeMigration[_buildFileSectionIndex] = '''
/* End PBXBuildFile section */
/* Begin PBXBuildFile section */
''';
              project.xcodeProjectInfoFile.writeAsStringSync(
                _projectSettings(settingsBeforeMigration),
              );
              final List<String> settingsAsJsonBeforeMigration = <String>[
                ..._allSectionsMigratedAsJson(platform),
              ];
              settingsAsJsonBeforeMigration[_buildFileSectionIndex] =
                  unmigratedBuildFileSectionAsJson;

              final SwiftPackageManagerIntegrationMigration projectMigration =
                  SwiftPackageManagerIntegrationMigration(
                    project,
                    platform,
                    BuildInfo.debug,
                    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                    logger: testLogger,
                    fileSystem: memoryFileSystem,
                    plistParser: FakePlistParser(json: _plutilOutput(<String>[])),
                    features: swiftPackageManagerFullyEnabledFlags,
                  );
              expect(
                () => projectMigration.migrate(),
                throwsToolExit(
                  message: 'Found the end of PBXBuildFile section before the beginning.',
                ),
              );
            });

            testWithoutContext('successfully added', () async {
              final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
              final BufferLogger testLogger = BufferLogger.test();
              final FakeXcodeProject project = FakeXcodeProject(
                platform: platform.name,
                fileSystem: memoryFileSystem,
                logger: testLogger,
              );
              _createProjectFiles(project, platform);

              final List<String> settingsBeforeMigration = <String>[
                ..._allSectionsUnmigrated(platform),
              ];
              settingsBeforeMigration[_buildFileSectionIndex] = unmigratedBuildFileSection;
              project.xcodeProjectInfoFile.writeAsStringSync(
                _projectSettings(settingsBeforeMigration),
              );
              final List<String> settingsAsJsonBeforeMigration = <String>[
                ..._allSectionsMigratedAsJson(platform),
              ];
              settingsAsJsonBeforeMigration[_buildFileSectionIndex] =
                  unmigratedBuildFileSectionAsJson;

              final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
                _plutilOutput(settingsAsJsonBeforeMigration),
                _plutilOutput(_allSectionsMigratedAsJson(platform)),
              ]);

              final SwiftPackageManagerIntegrationMigration projectMigration =
                  SwiftPackageManagerIntegrationMigration(
                    project,
                    platform,
                    BuildInfo.debug,
                    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                    logger: testLogger,
                    fileSystem: memoryFileSystem,
                    plistParser: plistParser,
                    features: swiftPackageManagerFullyEnabledFlags,
                  );
              await projectMigration.migrate();
              expect(testLogger.errorText, isEmpty);
              expect(
                testLogger.traceText.contains('PBXBuildFile already migrated. Skipping...'),
                isFalse,
              );
              settingsBeforeMigration[_buildFileSectionIndex] = migratedBuildFileSection;
              expect(
                project.xcodeProjectInfoFile.readAsStringSync(),
                _projectSettings(settingsBeforeMigration),
              );
              expect(plistParser.hasRemainingExpectations, isFalse);
            });
          });

          group('migrate PBXFrameworksBuildPhase', () {
            testWithoutContext('fails if missing PBXFrameworksBuildPhase section', () async {
              final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
              final BufferLogger testLogger = BufferLogger.test();
              final FakeXcodeProject project = FakeXcodeProject(
                platform: platform.name,
                fileSystem: memoryFileSystem,
                logger: testLogger,
              );
              _createProjectFiles(project, platform);

              final List<String> settingsBeforeMigration = <String>[
                ..._allSectionsUnmigrated(platform),
              ];
              settingsBeforeMigration.removeAt(_frameworksBuildPhaseSectionIndex);
              project.xcodeProjectInfoFile.writeAsStringSync(
                _projectSettings(settingsBeforeMigration),
              );
              final List<String> settingsAsJsonBeforeMigration = <String>[
                ..._allSectionsMigratedAsJson(platform),
              ];
              settingsAsJsonBeforeMigration.removeAt(_frameworksBuildPhaseSectionIndex);

              final SwiftPackageManagerIntegrationMigration projectMigration =
                  SwiftPackageManagerIntegrationMigration(
                    project,
                    platform,
                    BuildInfo.debug,
                    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                    logger: testLogger,
                    fileSystem: memoryFileSystem,
                    plistParser: FakePlistParser(
                      json: _plutilOutput(settingsAsJsonBeforeMigration),
                    ),
                    features: swiftPackageManagerFullyEnabledFlags,
                  );
              await expectLater(
                () => projectMigration.migrate(),
                throwsToolExit(
                  message: 'Unable to find beginning of PBXFrameworksBuildPhase section',
                ),
              );
            });

            testWithoutContext(
              'fails if missing Runner target subsection following PBXFrameworksBuildPhase begin header',
              () async {
                final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
                final BufferLogger testLogger = BufferLogger.test();
                final FakeXcodeProject project = FakeXcodeProject(
                  platform: platform.name,
                  fileSystem: memoryFileSystem,
                  logger: testLogger,
                );
                _createProjectFiles(project, platform);

                final List<String> settingsBeforeMigration = <String>[
                  ..._allSectionsUnmigrated(platform),
                ];
                settingsBeforeMigration[_frameworksBuildPhaseSectionIndex] = '''
/* Begin PBXFrameworksBuildPhase section */
/* End PBXFrameworksBuildPhase section */
''';
                project.xcodeProjectInfoFile.writeAsStringSync(
                  _projectSettings(settingsBeforeMigration),
                );
                final List<String> settingsAsJsonBeforeMigration = <String>[
                  ..._allSectionsMigratedAsJson(platform),
                ];
                settingsAsJsonBeforeMigration.removeAt(_frameworksBuildPhaseSectionIndex);

                final SwiftPackageManagerIntegrationMigration projectMigration =
                    SwiftPackageManagerIntegrationMigration(
                      project,
                      platform,
                      BuildInfo.debug,
                      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                      logger: testLogger,
                      fileSystem: memoryFileSystem,
                      plistParser: FakePlistParser(
                        json: _plutilOutput(settingsAsJsonBeforeMigration),
                      ),
                      features: swiftPackageManagerFullyEnabledFlags,
                    );
                await expectLater(
                  () => projectMigration.migrate(),
                  throwsToolExit(
                    message: 'Unable to find PBXFrameworksBuildPhase for Runner project',
                  ),
                );
              },
            );

            testWithoutContext(
              'fails if missing Runner target subsection before PBXFrameworksBuildPhase end header',
              () async {
                final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
                final BufferLogger testLogger = BufferLogger.test();
                final FakeXcodeProject project = FakeXcodeProject(
                  platform: platform.name,
                  fileSystem: memoryFileSystem,
                  logger: testLogger,
                );
                _createProjectFiles(project, platform);

                final List<String> settingsBeforeMigration = <String>[
                  ..._allSectionsUnmigrated(platform),
                ];
                settingsBeforeMigration[_frameworksBuildPhaseSectionIndex] = '''
/* Begin PBXFrameworksBuildPhase section */
/* End PBXFrameworksBuildPhase section */
/* Begin NonExistant section */
    ${_runnerFrameworksBuildPhaseIdentifier(platform)} /* Frameworks */ = {
    };
/* End NonExistant section */
''';
                project.xcodeProjectInfoFile.writeAsStringSync(
                  _projectSettings(settingsBeforeMigration),
                );
                final List<String> settingsAsJsonBeforeMigration = <String>[
                  ..._allSectionsMigratedAsJson(platform),
                ];
                settingsAsJsonBeforeMigration.removeAt(_frameworksBuildPhaseSectionIndex);

                final SwiftPackageManagerIntegrationMigration projectMigration =
                    SwiftPackageManagerIntegrationMigration(
                      project,
                      platform,
                      BuildInfo.debug,
                      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                      logger: testLogger,
                      fileSystem: memoryFileSystem,
                      plistParser: FakePlistParser(
                        json: _plutilOutput(settingsAsJsonBeforeMigration),
                      ),
                      features: swiftPackageManagerFullyEnabledFlags,
                    );
                await expectLater(
                  () => projectMigration.migrate(),
                  throwsToolExit(
                    message: 'Unable to find PBXFrameworksBuildPhase for Runner project',
                  ),
                );
              },
            );

            testWithoutContext('fails if missing Runner target in parsed settings', () async {
              final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
              final BufferLogger testLogger = BufferLogger.test();
              final FakeXcodeProject project = FakeXcodeProject(
                platform: platform.name,
                fileSystem: memoryFileSystem,
                logger: testLogger,
              );
              _createProjectFiles(project, platform);

              final List<String> settingsBeforeMigration = <String>[
                ..._allSectionsUnmigrated(platform),
              ];
              settingsBeforeMigration[_frameworksBuildPhaseSectionIndex] =
                  unmigratedFrameworksBuildPhaseSection(platform);
              project.xcodeProjectInfoFile.writeAsStringSync(
                _projectSettings(settingsBeforeMigration),
              );
              final List<String> settingsAsJsonBeforeMigration = <String>[
                ..._allSectionsMigratedAsJson(platform),
              ];
              settingsAsJsonBeforeMigration.removeAt(_frameworksBuildPhaseSectionIndex);

              final SwiftPackageManagerIntegrationMigration projectMigration =
                  SwiftPackageManagerIntegrationMigration(
                    project,
                    platform,
                    BuildInfo.debug,
                    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                    logger: testLogger,
                    fileSystem: memoryFileSystem,
                    plistParser: FakePlistParser(
                      json: _plutilOutput(settingsAsJsonBeforeMigration),
                    ),
                    features: swiftPackageManagerFullyEnabledFlags,
                  );
              await expectLater(
                () => projectMigration.migrate(),
                throwsToolExit(
                  message: 'Unable to find parsed PBXFrameworksBuildPhase for Runner project',
                ),
              );
            });

            testWithoutContext('successfully added when files field is missing', () async {
              final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
              final BufferLogger testLogger = BufferLogger.test();
              final FakeXcodeProject project = FakeXcodeProject(
                platform: platform.name,
                fileSystem: memoryFileSystem,
                logger: testLogger,
              );
              _createProjectFiles(project, platform);

              final List<String> settingsBeforeMigration = <String>[
                ..._allSectionsUnmigrated(platform),
              ];
              settingsBeforeMigration[_frameworksBuildPhaseSectionIndex] =
                  unmigratedFrameworksBuildPhaseSection(platform, missingFiles: true);
              project.xcodeProjectInfoFile.writeAsStringSync(
                _projectSettings(settingsBeforeMigration),
              );
              final List<String> settingsAsJsonBeforeMigration = <String>[
                ..._allSectionsUnmigratedAsJson(platform),
              ];
              settingsAsJsonBeforeMigration[_frameworksBuildPhaseSectionIndex] =
                  unmigratedFrameworksBuildPhaseSectionAsJson(platform, missingFiles: true);
              final List<String> expectedSettings = <String>[..._allSectionsMigrated(platform)];
              expectedSettings[_frameworksBuildPhaseSectionIndex] =
                  migratedFrameworksBuildPhaseSection(platform, missingFiles: true);

              final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
                _plutilOutput(settingsAsJsonBeforeMigration),
                _plutilOutput(_allSectionsMigratedAsJson(platform)),
              ]);

              final SwiftPackageManagerIntegrationMigration projectMigration =
                  SwiftPackageManagerIntegrationMigration(
                    project,
                    platform,
                    BuildInfo.debug,
                    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                    logger: testLogger,
                    fileSystem: memoryFileSystem,
                    plistParser: plistParser,
                    features: swiftPackageManagerFullyEnabledFlags,
                  );
              await projectMigration.migrate();
              expect(testLogger.errorText, isEmpty);
              expect(
                testLogger.traceText.contains(
                  'PBXFrameworksBuildPhase already migrated. Skipping...',
                ),
                isFalse,
              );
              expect(
                project.xcodeProjectInfoFile.readAsStringSync(),
                _projectSettings(expectedSettings),
              );
              expect(plistParser.hasRemainingExpectations, isFalse);
            });

            testWithoutContext('successfully added when files field is empty', () async {
              final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
              final BufferLogger testLogger = BufferLogger.test();
              final FakeXcodeProject project = FakeXcodeProject(
                platform: platform.name,
                fileSystem: memoryFileSystem,
                logger: testLogger,
              );
              _createProjectFiles(project, platform);

              final List<String> settingsBeforeMigration = <String>[
                ..._allSectionsUnmigrated(platform),
              ];
              project.xcodeProjectInfoFile.writeAsStringSync(
                _projectSettings(settingsBeforeMigration),
              );
              final List<String> settingsAsJsonBeforeMigration = <String>[
                ..._allSectionsUnmigratedAsJson(platform),
              ];

              final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
                _plutilOutput(settingsAsJsonBeforeMigration),
                _plutilOutput(_allSectionsMigratedAsJson(platform)),
              ]);

              final SwiftPackageManagerIntegrationMigration projectMigration =
                  SwiftPackageManagerIntegrationMigration(
                    project,
                    platform,
                    BuildInfo.debug,
                    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                    logger: testLogger,
                    fileSystem: memoryFileSystem,
                    plistParser: plistParser,
                    features: swiftPackageManagerFullyEnabledFlags,
                  );
              await projectMigration.migrate();
              expect(testLogger.errorText, isEmpty);
              expect(
                testLogger.traceText.contains(
                  'PBXFrameworksBuildPhase already migrated. Skipping...',
                ),
                isFalse,
              );
              expect(
                project.xcodeProjectInfoFile.readAsStringSync(),
                _projectSettings(_allSectionsMigrated(platform)),
              );
              expect(plistParser.hasRemainingExpectations, isFalse);
            });

            testWithoutContext('successfully added when files field is not empty', () async {
              final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
              final BufferLogger testLogger = BufferLogger.test();
              final FakeXcodeProject project = FakeXcodeProject(
                platform: platform.name,
                fileSystem: memoryFileSystem,
                logger: testLogger,
              );
              _createProjectFiles(project, platform);

              final List<String> settingsBeforeMigration = <String>[
                ..._allSectionsUnmigrated(platform),
              ];
              settingsBeforeMigration[_frameworksBuildPhaseSectionIndex] =
                  unmigratedFrameworksBuildPhaseSection(platform, withCocoapods: true);
              project.xcodeProjectInfoFile.writeAsStringSync(
                _projectSettings(settingsBeforeMigration),
              );
              final List<String> settingsAsJsonBeforeMigration = <String>[
                ..._allSectionsUnmigratedAsJson(platform),
              ];
              settingsAsJsonBeforeMigration[_frameworksBuildPhaseSectionIndex] =
                  unmigratedFrameworksBuildPhaseSectionAsJson(platform, withCocoapods: true);
              final List<String> expectedSettings = <String>[..._allSectionsMigrated(platform)];
              expectedSettings[_frameworksBuildPhaseSectionIndex] =
                  migratedFrameworksBuildPhaseSection(platform, withCocoapods: true);

              final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
                _plutilOutput(settingsAsJsonBeforeMigration),
                _plutilOutput(_allSectionsMigratedAsJson(platform)),
              ]);

              final SwiftPackageManagerIntegrationMigration projectMigration =
                  SwiftPackageManagerIntegrationMigration(
                    project,
                    platform,
                    BuildInfo.debug,
                    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                    logger: testLogger,
                    fileSystem: memoryFileSystem,
                    plistParser: plistParser,
                    features: swiftPackageManagerFullyEnabledFlags,
                  );
              await projectMigration.migrate();
              expect(testLogger.errorText, isEmpty);
              expect(
                testLogger.traceText.contains(
                  'PBXFrameworksBuildPhase already migrated. Skipping...',
                ),
                isFalse,
              );
              expect(
                project.xcodeProjectInfoFile.readAsStringSync(),
                _projectSettings(expectedSettings),
              );
              expect(plistParser.hasRemainingExpectations, isFalse);
            });
          });

          group('migrate PBXNativeTarget', () {
            testWithoutContext('fails if missing PBXNativeTarget section', () async {
              final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
              final BufferLogger testLogger = BufferLogger.test();
              final FakeXcodeProject project = FakeXcodeProject(
                platform: platform.name,
                fileSystem: memoryFileSystem,
                logger: testLogger,
              );
              _createProjectFiles(project, platform);

              final List<String> settingsBeforeMigration = <String>[
                ..._allSectionsUnmigrated(platform),
              ];
              settingsBeforeMigration.removeAt(_nativeTargetSectionIndex);
              project.xcodeProjectInfoFile.writeAsStringSync(
                _projectSettings(settingsBeforeMigration),
              );
              final List<String> settingsAsJsonBeforeMigration = <String>[
                ..._allSectionsUnmigratedAsJson(platform),
              ];
              settingsAsJsonBeforeMigration.removeAt(_nativeTargetSectionIndex);

              final SwiftPackageManagerIntegrationMigration projectMigration =
                  SwiftPackageManagerIntegrationMigration(
                    project,
                    platform,
                    BuildInfo.debug,
                    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                    logger: testLogger,
                    fileSystem: memoryFileSystem,
                    plistParser: FakePlistParser(
                      json: _plutilOutput(settingsAsJsonBeforeMigration),
                    ),
                    features: swiftPackageManagerFullyEnabledFlags,
                  );
              await expectLater(
                () => projectMigration.migrate(),
                throwsToolExit(message: 'Unable to find beginning of PBXNativeTarget section'),
              );
            });

            testWithoutContext('fails if missing Runner target in parsed settings', () async {
              final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
              final BufferLogger testLogger = BufferLogger.test();
              final FakeXcodeProject project = FakeXcodeProject(
                platform: platform.name,
                fileSystem: memoryFileSystem,
                logger: testLogger,
              );
              _createProjectFiles(project, platform);

              final List<String> settingsBeforeMigration = <String>[
                ..._allSectionsUnmigrated(platform),
              ];
              settingsBeforeMigration[_nativeTargetSectionIndex] = unmigratedNativeTargetSection(
                platform,
              );
              project.xcodeProjectInfoFile.writeAsStringSync(
                _projectSettings(settingsBeforeMigration),
              );
              final List<String> settingsAsJsonBeforeMigration = <String>[
                ..._allSectionsUnmigratedAsJson(platform),
              ];
              settingsAsJsonBeforeMigration.removeAt(_nativeTargetSectionIndex);

              final SwiftPackageManagerIntegrationMigration projectMigration =
                  SwiftPackageManagerIntegrationMigration(
                    project,
                    platform,
                    BuildInfo.debug,
                    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                    logger: testLogger,
                    fileSystem: memoryFileSystem,
                    plistParser: FakePlistParser(
                      json: _plutilOutput(settingsAsJsonBeforeMigration),
                    ),
                    features: swiftPackageManagerFullyEnabledFlags,
                  );
              await expectLater(
                () => projectMigration.migrate(),
                throwsToolExit(message: 'Unable to find parsed PBXNativeTarget for Runner project'),
              );
            });

            testWithoutContext(
              'fails if missing Runner target subsection following PBXNativeTarget begin header',
              () async {
                final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
                final BufferLogger testLogger = BufferLogger.test();
                final FakeXcodeProject project = FakeXcodeProject(
                  platform: platform.name,
                  fileSystem: memoryFileSystem,
                  logger: testLogger,
                );
                _createProjectFiles(project, platform);

                final List<String> settingsBeforeMigration = <String>[
                  ..._allSectionsUnmigrated(platform),
                ];
                settingsBeforeMigration[_nativeTargetSectionIndex] = '''
/* Begin PBXNativeTarget section */
/* End PBXNativeTarget section */
''';
                project.xcodeProjectInfoFile.writeAsStringSync(
                  _projectSettings(settingsBeforeMigration),
                );
                final List<String> settingsAsJsonBeforeMigration = <String>[
                  ..._allSectionsUnmigratedAsJson(platform),
                ];

                final SwiftPackageManagerIntegrationMigration projectMigration =
                    SwiftPackageManagerIntegrationMigration(
                      project,
                      platform,
                      BuildInfo.debug,
                      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                      logger: testLogger,
                      fileSystem: memoryFileSystem,
                      plistParser: FakePlistParser(
                        json: _plutilOutput(settingsAsJsonBeforeMigration),
                      ),
                      features: swiftPackageManagerFullyEnabledFlags,
                    );
                await expectLater(
                  () => projectMigration.migrate(),
                  throwsToolExit(
                    message: 'Unable to find PBXNativeTarget "Runner" for Runner project',
                  ),
                );
              },
            );

            testWithoutContext(
              'fails if missing Runner target subsection before PBXNativeTarget end header',
              () async {
                final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
                final BufferLogger testLogger = BufferLogger.test();
                final FakeXcodeProject project = FakeXcodeProject(
                  platform: platform.name,
                  fileSystem: memoryFileSystem,
                  logger: testLogger,
                );
                _createProjectFiles(project, platform);

                final List<String> settingsBeforeMigration = <String>[
                  ..._allSectionsUnmigrated(platform),
                ];
                settingsBeforeMigration[_nativeTargetSectionIndex] = '''
/* Begin PBXNativeTarget section */
/* End PBXNativeTarget section */
/* Begin NonExistant section */
    ${_runnerNativeTargetIdentifier(platform)} /* Runner */ = {
    };
/* End NonExistant section */
''';
                project.xcodeProjectInfoFile.writeAsStringSync(
                  _projectSettings(settingsBeforeMigration),
                );
                final List<String> settingsAsJsonBeforeMigration = <String>[
                  ..._allSectionsUnmigratedAsJson(platform),
                ];

                final SwiftPackageManagerIntegrationMigration projectMigration =
                    SwiftPackageManagerIntegrationMigration(
                      project,
                      platform,
                      BuildInfo.debug,
                      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                      logger: testLogger,
                      fileSystem: memoryFileSystem,
                      plistParser: FakePlistParser(
                        json: _plutilOutput(settingsAsJsonBeforeMigration),
                      ),
                      features: swiftPackageManagerFullyEnabledFlags,
                    );
                await expectLater(
                  () => projectMigration.migrate(),
                  throwsToolExit(
                    message: 'Unable to find PBXNativeTarget "Runner" for Runner project',
                  ),
                );
              },
            );

            testWithoutContext(
              'successfully added when packageProductDependencies field is missing',
              () async {
                final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
                final BufferLogger testLogger = BufferLogger.test();
                final FakeXcodeProject project = FakeXcodeProject(
                  platform: platform.name,
                  fileSystem: memoryFileSystem,
                  logger: testLogger,
                );
                _createProjectFiles(project, platform);

                final List<String> settingsBeforeMigration = <String>[
                  ..._allSectionsUnmigrated(platform),
                ];
                settingsBeforeMigration[_nativeTargetSectionIndex] = unmigratedNativeTargetSection(
                  platform,
                  missingPackageProductDependencies: true,
                );
                project.xcodeProjectInfoFile.writeAsStringSync(
                  _projectSettings(settingsBeforeMigration),
                );
                final List<String> settingsAsJsonBeforeMigration = <String>[
                  ..._allSectionsUnmigratedAsJson(platform),
                ];
                settingsAsJsonBeforeMigration[_nativeTargetSectionIndex] =
                    unmigratedNativeTargetSectionAsJson(
                      platform,
                      missingPackageProductDependencies: true,
                    );
                final List<String> expectedSettings = <String>[..._allSectionsMigrated(platform)];
                expectedSettings[_nativeTargetSectionIndex] = migratedNativeTargetSection(
                  platform,
                  missingPackageProductDependencies: true,
                );

                final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
                  _plutilOutput(settingsAsJsonBeforeMigration),
                  _plutilOutput(_allSectionsMigratedAsJson(platform)),
                ]);

                final SwiftPackageManagerIntegrationMigration projectMigration =
                    SwiftPackageManagerIntegrationMigration(
                      project,
                      platform,
                      BuildInfo.debug,
                      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                      logger: testLogger,
                      fileSystem: memoryFileSystem,
                      plistParser: plistParser,
                      features: swiftPackageManagerFullyEnabledFlags,
                    );
                await projectMigration.migrate();
                expect(testLogger.errorText, isEmpty);
                expect(
                  testLogger.traceText.contains('PBXNativeTarget already migrated. Skipping...'),
                  isFalse,
                );
                expect(
                  project.xcodeProjectInfoFile.readAsStringSync(),
                  _projectSettings(expectedSettings),
                );
                expect(plistParser.hasRemainingExpectations, isFalse);
              },
            );

            testWithoutContext(
              'successfully added when packageProductDependencies field is empty',
              () async {
                final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
                final BufferLogger testLogger = BufferLogger.test();
                final FakeXcodeProject project = FakeXcodeProject(
                  platform: platform.name,
                  fileSystem: memoryFileSystem,
                  logger: testLogger,
                );
                _createProjectFiles(project, platform);

                final List<String> settingsBeforeMigration = <String>[
                  ..._allSectionsUnmigrated(platform),
                ];
                settingsBeforeMigration[_nativeTargetSectionIndex] = unmigratedNativeTargetSection(
                  platform,
                );
                project.xcodeProjectInfoFile.writeAsStringSync(
                  _projectSettings(settingsBeforeMigration),
                );
                final List<String> settingsAsJsonBeforeMigration = <String>[
                  ..._allSectionsUnmigratedAsJson(platform),
                ];

                final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
                  _plutilOutput(settingsAsJsonBeforeMigration),
                  _plutilOutput(_allSectionsMigratedAsJson(platform)),
                ]);

                final SwiftPackageManagerIntegrationMigration projectMigration =
                    SwiftPackageManagerIntegrationMigration(
                      project,
                      platform,
                      BuildInfo.debug,
                      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                      logger: testLogger,
                      fileSystem: memoryFileSystem,
                      plistParser: plistParser,
                      features: swiftPackageManagerFullyEnabledFlags,
                    );
                await projectMigration.migrate();
                expect(testLogger.errorText, isEmpty);
                expect(
                  testLogger.traceText.contains('PBXNativeTarget already migrated. Skipping...'),
                  isFalse,
                );
                expect(
                  project.xcodeProjectInfoFile.readAsStringSync(),
                  _projectSettings(_allSectionsMigrated(platform)),
                );
                expect(plistParser.hasRemainingExpectations, isFalse);
              },
            );

            testWithoutContext(
              'successfully added when packageProductDependencies field is not empty',
              () async {
                final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
                final BufferLogger testLogger = BufferLogger.test();
                final FakeXcodeProject project = FakeXcodeProject(
                  platform: platform.name,
                  fileSystem: memoryFileSystem,
                  logger: testLogger,
                );
                _createProjectFiles(project, platform);

                final List<String> settingsBeforeMigration = <String>[
                  ..._allSectionsUnmigrated(platform),
                ];
                settingsBeforeMigration[_nativeTargetSectionIndex] = unmigratedNativeTargetSection(
                  platform,
                  withOtherDependency: true,
                );
                project.xcodeProjectInfoFile.writeAsStringSync(
                  _projectSettings(settingsBeforeMigration),
                );
                final List<String> settingsAsJsonBeforeMigration = <String>[
                  ..._allSectionsUnmigratedAsJson(platform),
                ];
                final List<String> expectedSettings = <String>[..._allSectionsMigrated(platform)];
                expectedSettings[_nativeTargetSectionIndex] = migratedNativeTargetSection(
                  platform,
                  withOtherDependency: true,
                );

                final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
                  _plutilOutput(settingsAsJsonBeforeMigration),
                  _plutilOutput(_allSectionsMigratedAsJson(platform)),
                ]);

                final SwiftPackageManagerIntegrationMigration projectMigration =
                    SwiftPackageManagerIntegrationMigration(
                      project,
                      platform,
                      BuildInfo.debug,
                      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                      logger: testLogger,
                      fileSystem: memoryFileSystem,
                      plistParser: plistParser,
                      features: swiftPackageManagerFullyEnabledFlags,
                    );
                await projectMigration.migrate();
                expect(testLogger.errorText, isEmpty);
                expect(
                  testLogger.traceText.contains('PBXNativeTarget already migrated. Skipping...'),
                  isFalse,
                );
                expect(
                  project.xcodeProjectInfoFile.readAsStringSync(),
                  _projectSettings(expectedSettings),
                );
                expect(plistParser.hasRemainingExpectations, isFalse);
              },
            );

            testWithoutContext(
              'skips PBXNativeTarget migration if all targets already migrated',
              () async {
                final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
                final BufferLogger testLogger = BufferLogger.test();
                final FakeXcodeProject project = FakeXcodeProject(
                  platform: platform.name,
                  fileSystem: memoryFileSystem,
                  logger: testLogger,
                );

                _createProjectFiles(project, platform, createSchemeFile: false);
                project.xcodeProjectSchemeFile().createSync(recursive: true);
                project.xcodeProjectSchemeFile().writeAsStringSync(
                  _validBuildActions(platform, hasFrameworkScript: true),
                );

                // Replace the PBXNativeTarget section with the migrated two target variant,
                // so that the migration skips it.
                final List<String> pbxprojSections = _allSectionsUnmigrated(platform);
                pbxprojSections[_nativeTargetSectionIndex] = migratedNativeTargetSection(
                  platform,
                  otherNativeTarget: migratedOtherApplicationTarget,
                );

                project.xcodeProjectInfoFile.writeAsStringSync(_projectSettings(pbxprojSections));

                final List<String> settingsAsJsonBeforeMigration = <String>[
                  ..._allSectionsUnmigratedAsJson(platform),
                ];

                settingsAsJsonBeforeMigration[_nativeTargetSectionIndex] = <String>[
                  migratedNativeTargetSectionAsJson(platform),
                  migratedOtherApplicationTargetAsJson,
                ].join(',\n');

                settingsAsJsonBeforeMigration.removeAt(_buildFileSectionIndex);

                final List<String> settingsAsJsonAfterMigration = <String>[
                  ..._allSectionsMigratedAsJson(platform),
                ];
                settingsAsJsonAfterMigration[_nativeTargetSectionIndex] = <String>[
                  migratedNativeTargetSectionAsJson(platform),
                  migratedOtherApplicationTargetAsJson,
                ].join(',\n');

                final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
                  _plutilOutput(settingsAsJsonBeforeMigration),
                  _plutilOutput(settingsAsJsonAfterMigration),
                ]);

                final SwiftPackageManagerIntegrationMigration projectMigration =
                    SwiftPackageManagerIntegrationMigration(
                      project,
                      platform,
                      BuildInfo.debug,
                      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                      logger: testLogger,
                      fileSystem: memoryFileSystem,
                      plistParser: plistParser,
                      features: swiftPackageManagerFullyEnabledFlags,
                    );

                await projectMigration.migrate();

                expect(
                  testLogger.traceText,
                  contains('PBXNativeTargets already migrated. Skipping...'),
                );
              },
            );

            testWithoutContext(
              'skips Runner PBXNativeTarget migration if already migrated',
              () async {
                final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
                final BufferLogger testLogger = BufferLogger.test();
                final FakeXcodeProject project = FakeXcodeProject(
                  platform: platform.name,
                  fileSystem: memoryFileSystem,
                  logger: testLogger,
                );

                _createProjectFiles(project, platform, createSchemeFile: false);
                project.xcodeProjectSchemeFile().createSync(recursive: true);
                project.xcodeProjectSchemeFile().writeAsStringSync(
                  _validBuildActions(platform, hasFrameworkScript: true),
                );

                // Replace the PBXNativeTarget section with the migrated variant, so that the migration skips it.
                final List<String> pbxprojSections = _allSectionsUnmigrated(platform);
                pbxprojSections[_nativeTargetSectionIndex] = migratedNativeTargetSection(platform);

                project.xcodeProjectInfoFile.writeAsStringSync(_projectSettings(pbxprojSections));

                final List<String> settingsAsJsonBeforeMigration = <String>[
                  ..._allSectionsUnmigratedAsJson(platform),
                ];
                settingsAsJsonBeforeMigration[_nativeTargetSectionIndex] =
                    migratedNativeTargetSectionAsJson(platform);
                settingsAsJsonBeforeMigration.removeAt(_buildFileSectionIndex);

                final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
                  _plutilOutput(settingsAsJsonBeforeMigration),
                  _plutilOutput(_allSectionsMigratedAsJson(platform)),
                ]);

                final SwiftPackageManagerIntegrationMigration projectMigration =
                    SwiftPackageManagerIntegrationMigration(
                      project,
                      platform,
                      BuildInfo.debug,
                      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                      logger: testLogger,
                      fileSystem: memoryFileSystem,
                      plistParser: plistParser,
                      features: swiftPackageManagerFullyEnabledFlags,
                    );

                await projectMigration.migrate();

                expect(
                  testLogger.traceText,
                  contains('PBXNativeTargets already migrated. Skipping...'),
                );
              },
            );

            testWithoutContext(
              'skips PBXNativeTarget unit test bundles such as RunnerTests',
              () async {
                final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
                final BufferLogger testLogger = BufferLogger.test();
                final FakeXcodeProject project = FakeXcodeProject(
                  platform: platform.name,
                  fileSystem: memoryFileSystem,
                  logger: testLogger,
                );

                _createProjectFiles(project, platform, createSchemeFile: false);
                project.xcodeProjectSchemeFile().createSync(recursive: true);
                project.xcodeProjectSchemeFile().writeAsStringSync(
                  _validBuildActions(platform, hasFrameworkScript: true),
                );

                // Replace the PBXNativeTarget section with a non migrated Runner target
                // and a RunnerTests unit testing target.
                final List<String> pbxprojSections = _allSectionsUnmigrated(platform);
                pbxprojSections[_nativeTargetSectionIndex] = unmigratedNativeTargetSection(
                  platform,
                  otherNativeTarget: _runnerTestsTarget(platform),
                );

                project.xcodeProjectInfoFile.writeAsStringSync(_projectSettings(pbxprojSections));

                final List<String> settingsAsJsonBeforeMigration = <String>[
                  ..._allSectionsUnmigratedAsJson(platform),
                ];

                settingsAsJsonBeforeMigration[_nativeTargetSectionIndex] = <String>[
                  unmigratedNativeTargetSectionAsJson(platform),
                  _runnerTestsTargetAsJson(platform),
                ].join(',\n');

                settingsAsJsonBeforeMigration.removeAt(_buildFileSectionIndex);

                final List<String> settingsAsJsonAfterMigration = <String>[
                  ..._allSectionsMigratedAsJson(platform),
                ];

                settingsAsJsonAfterMigration[_nativeTargetSectionIndex] = <String>[
                  migratedNativeTargetSectionAsJson(platform),
                  _runnerTestsTargetAsJson(platform),
                ].join(',\n');

                final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
                  _plutilOutput(settingsAsJsonBeforeMigration),
                  _plutilOutput(settingsAsJsonAfterMigration),
                ]);

                final SwiftPackageManagerIntegrationMigration projectMigration =
                    SwiftPackageManagerIntegrationMigration(
                      project,
                      platform,
                      BuildInfo.debug,
                      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                      logger: testLogger,
                      fileSystem: memoryFileSystem,
                      plistParser: plistParser,
                      features: swiftPackageManagerFullyEnabledFlags,
                    );

                await projectMigration.migrate();

                expect(
                  testLogger.errorText,
                  isNot(
                    contains(
                      'Some PBXNativeTargets were not migrated or were migrated incorrectly.',
                    ),
                  ),
                );
                expect(
                  testLogger.traceText,
                  isNot(contains('PBXNativeTargets already migrated. Skipping...')),
                );
                expect(
                  testLogger.traceText,
                  isNot(contains('PBXNativeTarget "Runner" already migrated. Skipping...')),
                );
              },
            );

            testWithoutContext(
              'skips PBXNativeTarget UI test bundles such as RunnerUITests',
              () async {
                final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
                final BufferLogger testLogger = BufferLogger.test();
                final FakeXcodeProject project = FakeXcodeProject(
                  platform: platform.name,
                  fileSystem: memoryFileSystem,
                  logger: testLogger,
                );

                _createProjectFiles(project, platform, createSchemeFile: false);
                project.xcodeProjectSchemeFile().createSync(recursive: true);
                project.xcodeProjectSchemeFile().writeAsStringSync(
                  _validBuildActions(platform, hasFrameworkScript: true),
                );

                // Replace the PBXNativeTarget section with a non migrated Runner target
                // and a RunnerUITests UI testing target.
                final List<String> pbxprojSections = _allSectionsUnmigrated(platform);
                pbxprojSections[_nativeTargetSectionIndex] = unmigratedNativeTargetSection(
                  platform,
                  otherNativeTarget: _runnerUITestsTarget(platform),
                );

                project.xcodeProjectInfoFile.writeAsStringSync(_projectSettings(pbxprojSections));

                final List<String> settingsAsJsonBeforeMigration = <String>[
                  ..._allSectionsUnmigratedAsJson(platform),
                ];

                settingsAsJsonBeforeMigration[_nativeTargetSectionIndex] = <String>[
                  unmigratedNativeTargetSectionAsJson(platform),
                  _runnerUITestsTargetAsJson(platform),
                ].join(',\n');

                settingsAsJsonBeforeMigration.removeAt(_buildFileSectionIndex);

                final List<String> settingsAsJsonAfterMigration = <String>[
                  ..._allSectionsMigratedAsJson(platform),
                ];

                settingsAsJsonAfterMigration[_nativeTargetSectionIndex] = <String>[
                  migratedNativeTargetSectionAsJson(platform),
                  _runnerUITestsTargetAsJson(platform),
                ].join(',\n');

                final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
                  _plutilOutput(settingsAsJsonBeforeMigration),
                  _plutilOutput(settingsAsJsonAfterMigration),
                ]);

                final SwiftPackageManagerIntegrationMigration projectMigration =
                    SwiftPackageManagerIntegrationMigration(
                      project,
                      platform,
                      BuildInfo.debug,
                      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                      logger: testLogger,
                      fileSystem: memoryFileSystem,
                      plistParser: plistParser,
                      features: swiftPackageManagerFullyEnabledFlags,
                    );

                await projectMigration.migrate();

                expect(
                  testLogger.errorText,
                  isNot(
                    contains(
                      'Some PBXNativeTargets were not migrated or were migrated incorrectly.',
                    ),
                  ),
                );
                expect(
                  testLogger.traceText,
                  isNot(contains('PBXNativeTargets already migrated. Skipping...')),
                );
                expect(
                  testLogger.traceText,
                  isNot(contains('PBXNativeTarget "Runner" already migrated. Skipping...')),
                );
              },
            );
          });

          group('migrate PBXProject', () {
            testWithoutContext('fails if missing PBXProject section', () async {
              final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
              final BufferLogger testLogger = BufferLogger.test();
              final FakeXcodeProject project = FakeXcodeProject(
                platform: platform.name,
                fileSystem: memoryFileSystem,
                logger: testLogger,
              );
              _createProjectFiles(project, platform);

              final List<String> settingsBeforeMigration = <String>[
                ..._allSectionsUnmigrated(platform),
              ];
              settingsBeforeMigration.removeAt(_projectSectionIndex);
              project.xcodeProjectInfoFile.writeAsStringSync(
                _projectSettings(settingsBeforeMigration),
              );
              final List<String> settingsAsJsonBeforeMigration = <String>[
                ..._allSectionsUnmigratedAsJson(platform),
              ];
              settingsAsJsonBeforeMigration.removeAt(_projectSectionIndex);

              final SwiftPackageManagerIntegrationMigration projectMigration =
                  SwiftPackageManagerIntegrationMigration(
                    project,
                    platform,
                    BuildInfo.debug,
                    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                    logger: testLogger,
                    fileSystem: memoryFileSystem,
                    plistParser: FakePlistParser(
                      json: _plutilOutput(settingsAsJsonBeforeMigration),
                    ),
                    features: swiftPackageManagerFullyEnabledFlags,
                  );
              await expectLater(
                () => projectMigration.migrate(),
                throwsToolExit(message: 'Unable to find beginning of PBXProject section'),
              );
            });

            testWithoutContext(
              'fails if missing Runner project subsection following PBXProject begin header',
              () async {
                final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
                final BufferLogger testLogger = BufferLogger.test();
                final FakeXcodeProject project = FakeXcodeProject(
                  platform: platform.name,
                  fileSystem: memoryFileSystem,
                  logger: testLogger,
                );
                _createProjectFiles(project, platform);

                final List<String> settingsBeforeMigration = <String>[
                  ..._allSectionsUnmigrated(platform),
                ];
                settingsBeforeMigration[_projectSectionIndex] = '''
/* Begin PBXProject section */
/* End PBXProject section */
''';
                project.xcodeProjectInfoFile.writeAsStringSync(
                  _projectSettings(settingsBeforeMigration),
                );

                final List<String> settingsAsJsonBeforeMigration = <String>[
                  ..._allSectionsUnmigratedAsJson(platform),
                ];
                settingsAsJsonBeforeMigration.removeAt(_projectSectionIndex);

                final SwiftPackageManagerIntegrationMigration projectMigration =
                    SwiftPackageManagerIntegrationMigration(
                      project,
                      platform,
                      BuildInfo.debug,
                      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                      logger: testLogger,
                      fileSystem: memoryFileSystem,
                      plistParser: FakePlistParser(
                        json: _plutilOutput(settingsAsJsonBeforeMigration),
                      ),
                      features: swiftPackageManagerFullyEnabledFlags,
                    );
                await expectLater(
                  () => projectMigration.migrate(),
                  throwsToolExit(message: 'Unable to find PBXProject for Runner project'),
                );
              },
            );

            testWithoutContext(
              'fails if missing Runner project subsection before PBXProject end header',
              () async {
                final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
                final BufferLogger testLogger = BufferLogger.test();
                final FakeXcodeProject project = FakeXcodeProject(
                  platform: platform.name,
                  fileSystem: memoryFileSystem,
                  logger: testLogger,
                );
                _createProjectFiles(project, platform);

                final List<String> settingsBeforeMigration = <String>[
                  ..._allSectionsUnmigrated(platform),
                ];
                settingsBeforeMigration[_projectSectionIndex] = '''
/* Begin PBXProject section */
/* End PBXProject section */
/* Begin NonExistant section */
    ${_projectIdentifier(platform)} /* Project object */ = {
    };
/* End NonExistant section */
''';
                project.xcodeProjectInfoFile.writeAsStringSync(
                  _projectSettings(settingsBeforeMigration),
                );

                final List<String> settingsAsJsonBeforeMigration = <String>[
                  ..._allSectionsUnmigratedAsJson(platform),
                ];
                settingsAsJsonBeforeMigration.removeAt(_projectSectionIndex);

                final SwiftPackageManagerIntegrationMigration projectMigration =
                    SwiftPackageManagerIntegrationMigration(
                      project,
                      platform,
                      BuildInfo.debug,
                      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                      logger: testLogger,
                      fileSystem: memoryFileSystem,
                      plistParser: FakePlistParser(
                        json: _plutilOutput(settingsAsJsonBeforeMigration),
                      ),
                      features: swiftPackageManagerFullyEnabledFlags,
                    );
                await expectLater(
                  () => projectMigration.migrate(),
                  throwsToolExit(message: 'Unable to find PBXProject for Runner project'),
                );
              },
            );

            testWithoutContext('fails if missing Runner project in parsed settings', () async {
              final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
              final BufferLogger testLogger = BufferLogger.test();
              final FakeXcodeProject project = FakeXcodeProject(
                platform: platform.name,
                fileSystem: memoryFileSystem,
                logger: testLogger,
              );
              _createProjectFiles(project, platform);

              final List<String> settingsBeforeMigration = <String>[
                ..._allSectionsUnmigrated(platform),
              ];
              settingsBeforeMigration[_projectSectionIndex] = unmigratedProjectSection(platform);
              project.xcodeProjectInfoFile.writeAsStringSync(
                _projectSettings(settingsBeforeMigration),
              );
              final List<String> settingsAsJsonBeforeMigration = <String>[
                ..._allSectionsUnmigratedAsJson(platform),
              ];
              settingsAsJsonBeforeMigration.removeAt(_projectSectionIndex);

              final SwiftPackageManagerIntegrationMigration projectMigration =
                  SwiftPackageManagerIntegrationMigration(
                    project,
                    platform,
                    BuildInfo.debug,
                    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                    logger: testLogger,
                    fileSystem: memoryFileSystem,
                    plistParser: FakePlistParser(
                      json: _plutilOutput(settingsAsJsonBeforeMigration),
                    ),
                    features: swiftPackageManagerFullyEnabledFlags,
                  );
              await expectLater(
                () => projectMigration.migrate(),
                throwsToolExit(message: 'Unable to find parsed PBXProject for Runner project'),
              );
            });

            testWithoutContext(
              'successfully added when packageReferences field is missing',
              () async {
                final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
                final BufferLogger testLogger = BufferLogger.test();
                final FakeXcodeProject project = FakeXcodeProject(
                  platform: platform.name,
                  fileSystem: memoryFileSystem,
                  logger: testLogger,
                );
                _createProjectFiles(project, platform);

                final List<String> settingsBeforeMigration = <String>[
                  ..._allSectionsUnmigrated(platform),
                ];
                settingsBeforeMigration[_projectSectionIndex] = unmigratedProjectSection(
                  platform,
                  missingPackageReferences: true,
                );
                project.xcodeProjectInfoFile.writeAsStringSync(
                  _projectSettings(settingsBeforeMigration),
                );

                final List<String> settingsAsJsonBeforeMigration = <String>[
                  ..._allSectionsUnmigratedAsJson(platform),
                ];
                settingsAsJsonBeforeMigration[_projectSectionIndex] =
                    unmigratedProjectSectionAsJson(platform, missingPackageReferences: true);

                final List<String> expectedSettings = <String>[..._allSectionsMigrated(platform)];
                expectedSettings[_projectSectionIndex] = migratedProjectSection(
                  platform,
                  missingPackageReferences: true,
                );

                final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
                  _plutilOutput(settingsAsJsonBeforeMigration),
                  _plutilOutput(_allSectionsMigratedAsJson(platform)),
                ]);

                final SwiftPackageManagerIntegrationMigration projectMigration =
                    SwiftPackageManagerIntegrationMigration(
                      project,
                      platform,
                      BuildInfo.debug,
                      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                      logger: testLogger,
                      fileSystem: memoryFileSystem,
                      plistParser: plistParser,
                      features: swiftPackageManagerFullyEnabledFlags,
                    );
                await projectMigration.migrate();
                expect(testLogger.errorText, isEmpty);
                expect(
                  testLogger.traceText.contains('PBXProject already migrated. Skipping...'),
                  isFalse,
                );
                expect(
                  project.xcodeProjectInfoFile.readAsStringSync(),
                  _projectSettings(expectedSettings),
                );
                expect(plistParser.hasRemainingExpectations, isFalse);
              },
            );

            testWithoutContext(
              'successfully added when packageReferences field is empty',
              () async {
                final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
                final BufferLogger testLogger = BufferLogger.test();
                final FakeXcodeProject project = FakeXcodeProject(
                  platform: platform.name,
                  fileSystem: memoryFileSystem,
                  logger: testLogger,
                );
                _createProjectFiles(project, platform);

                final List<String> settingsBeforeMigration = <String>[
                  ..._allSectionsUnmigrated(platform),
                ];
                settingsBeforeMigration[_projectSectionIndex] = unmigratedProjectSection(platform);
                project.xcodeProjectInfoFile.writeAsStringSync(
                  _projectSettings(settingsBeforeMigration),
                );
                final List<String> settingsAsJsonBeforeMigration = <String>[
                  ..._allSectionsUnmigratedAsJson(platform),
                ];

                final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
                  _plutilOutput(settingsAsJsonBeforeMigration),
                  _plutilOutput(_allSectionsMigratedAsJson(platform)),
                ]);

                final SwiftPackageManagerIntegrationMigration projectMigration =
                    SwiftPackageManagerIntegrationMigration(
                      project,
                      platform,
                      BuildInfo.debug,
                      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                      logger: testLogger,
                      fileSystem: memoryFileSystem,
                      plistParser: plistParser,
                      features: swiftPackageManagerFullyEnabledFlags,
                    );
                await projectMigration.migrate();
                expect(testLogger.errorText, isEmpty);
                expect(
                  testLogger.traceText.contains('PBXProject already migrated. Skipping...'),
                  isFalse,
                );
                expect(
                  project.xcodeProjectInfoFile.readAsStringSync(),
                  _projectSettings(_allSectionsMigrated(platform)),
                );
                expect(plistParser.hasRemainingExpectations, isFalse);
              },
            );

            testWithoutContext(
              'successfully added when packageReferences field is not empty',
              () async {
                final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
                final BufferLogger testLogger = BufferLogger.test();
                final FakeXcodeProject project = FakeXcodeProject(
                  platform: platform.name,
                  fileSystem: memoryFileSystem,
                  logger: testLogger,
                );
                _createProjectFiles(project, platform);

                final List<String> settingsBeforeMigration = <String>[
                  ..._allSectionsUnmigrated(platform),
                ];
                settingsBeforeMigration[_projectSectionIndex] = unmigratedProjectSection(
                  platform,
                  withOtherReference: true,
                );
                project.xcodeProjectInfoFile.writeAsStringSync(
                  _projectSettings(settingsBeforeMigration),
                );
                final List<String> settingsAsJsonBeforeMigration = <String>[
                  ..._allSectionsUnmigratedAsJson(platform),
                ];
                final List<String> expectedSettings = <String>[..._allSectionsMigrated(platform)];
                expectedSettings[_projectSectionIndex] = migratedProjectSection(
                  platform,
                  withOtherReference: true,
                );

                final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
                  _plutilOutput(settingsAsJsonBeforeMigration),
                  _plutilOutput(_allSectionsMigratedAsJson(platform)),
                ]);

                final SwiftPackageManagerIntegrationMigration projectMigration =
                    SwiftPackageManagerIntegrationMigration(
                      project,
                      platform,
                      BuildInfo.debug,
                      xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                      logger: testLogger,
                      fileSystem: memoryFileSystem,
                      plistParser: plistParser,
                      features: swiftPackageManagerFullyEnabledFlags,
                    );
                await projectMigration.migrate();
                expect(testLogger.errorText, isEmpty);
                expect(
                  testLogger.traceText.contains('PBXProject already migrated. Skipping...'),
                  isFalse,
                );
                expect(
                  project.xcodeProjectInfoFile.readAsStringSync(),
                  _projectSettings(expectedSettings),
                );
                expect(plistParser.hasRemainingExpectations, isFalse);
              },
            );
          });

          group('migrate XCLocalSwiftPackageReference', () {
            testWithoutContext('fails if unable to find section to append it after', () async {
              final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
              final BufferLogger testLogger = BufferLogger.test();
              final FakeXcodeProject project = FakeXcodeProject(
                platform: platform.name,
                fileSystem: memoryFileSystem,
                logger: testLogger,
              );
              _createProjectFiles(project, platform);

              final List<String> settingsAsJsonBeforeMigration = <String>[
                ..._allSectionsMigratedAsJson(platform),
              ];
              settingsAsJsonBeforeMigration.removeAt(_localSwiftPackageReferenceSectionIndex);

              final SwiftPackageManagerIntegrationMigration projectMigration =
                  SwiftPackageManagerIntegrationMigration(
                    project,
                    platform,
                    BuildInfo.debug,
                    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                    logger: testLogger,
                    fileSystem: memoryFileSystem,
                    plistParser: FakePlistParser(
                      json: _plutilOutput(settingsAsJsonBeforeMigration),
                    ),
                    features: swiftPackageManagerFullyEnabledFlags,
                  );
              await expectLater(
                () => projectMigration.migrate(),
                throwsToolExit(message: 'Unable to find any sections'),
              );
            });

            testWithoutContext('successfully added when section is missing', () async {
              final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
              final BufferLogger testLogger = BufferLogger.test();
              final FakeXcodeProject project = FakeXcodeProject(
                platform: platform.name,
                fileSystem: memoryFileSystem,
                logger: testLogger,
              );
              _createProjectFiles(project, platform);

              final List<String> settingsBeforeMigration = <String>[
                ..._allSectionsUnmigrated(platform),
              ];
              settingsBeforeMigration.removeAt(_localSwiftPackageReferenceSectionIndex);
              project.xcodeProjectInfoFile.writeAsStringSync(
                _projectSettings(settingsBeforeMigration),
              );
              final List<String> settingsAsJsonBeforeMigration = <String>[
                ..._allSectionsUnmigratedAsJson(platform),
              ];
              final List<String> expectedSettings = <String>[..._allSectionsMigrated(platform)];
              expectedSettings.removeAt(_localSwiftPackageReferenceSectionIndex);
              expectedSettings.add(migratedLocalSwiftPackageReferenceSection());

              final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
                _plutilOutput(settingsAsJsonBeforeMigration),
                _plutilOutput(_allSectionsMigratedAsJson(platform)),
              ]);

              final SwiftPackageManagerIntegrationMigration projectMigration =
                  SwiftPackageManagerIntegrationMigration(
                    project,
                    platform,
                    BuildInfo.debug,
                    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                    logger: testLogger,
                    fileSystem: memoryFileSystem,
                    plistParser: plistParser,
                    features: swiftPackageManagerFullyEnabledFlags,
                  );
              await projectMigration.migrate();
              expect(testLogger.errorText, isEmpty);
              expect(
                testLogger.traceText.contains(
                  'XCLocalSwiftPackageReference already migrated. Skipping...',
                ),
                isFalse,
              );
              expect(
                project.xcodeProjectInfoFile.readAsStringSync(),
                _projectSettings(expectedSettings),
              );
              expect(plistParser.hasRemainingExpectations, isFalse);
            });

            testWithoutContext('successfully added when section is empty', () async {
              final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
              final BufferLogger testLogger = BufferLogger.test();
              final FakeXcodeProject project = FakeXcodeProject(
                platform: platform.name,
                fileSystem: memoryFileSystem,
                logger: testLogger,
              );
              _createProjectFiles(project, platform);

              final List<String> settingsBeforeMigration = <String>[
                ..._allSectionsUnmigrated(platform),
              ];
              settingsBeforeMigration[_localSwiftPackageReferenceSectionIndex] =
                  unmigratedLocalSwiftPackageReferenceSection();
              project.xcodeProjectInfoFile.writeAsStringSync(
                _projectSettings(settingsBeforeMigration),
              );
              final List<String> settingsAsJsonBeforeMigration = <String>[
                ..._allSectionsUnmigratedAsJson(platform),
              ];

              final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
                _plutilOutput(settingsAsJsonBeforeMigration),
                _plutilOutput(_allSectionsMigratedAsJson(platform)),
              ]);

              final SwiftPackageManagerIntegrationMigration projectMigration =
                  SwiftPackageManagerIntegrationMigration(
                    project,
                    platform,
                    BuildInfo.debug,
                    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                    logger: testLogger,
                    fileSystem: memoryFileSystem,
                    plistParser: plistParser,
                    features: swiftPackageManagerFullyEnabledFlags,
                  );
              await projectMigration.migrate();
              expect(testLogger.errorText, isEmpty);
              expect(
                testLogger.traceText.contains(
                  'XCLocalSwiftPackageReference already migrated. Skipping...',
                ),
                isFalse,
              );
              expect(
                project.xcodeProjectInfoFile.readAsStringSync(),
                _projectSettings(_allSectionsMigrated(platform)),
              );
              expect(plistParser.hasRemainingExpectations, isFalse);
            });

            testWithoutContext('successfully added when section is not empty', () async {
              final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
              final BufferLogger testLogger = BufferLogger.test();
              final FakeXcodeProject project = FakeXcodeProject(
                platform: platform.name,
                fileSystem: memoryFileSystem,
                logger: testLogger,
              );
              _createProjectFiles(project, platform);

              final List<String> settingsBeforeMigration = <String>[
                ..._allSectionsUnmigrated(platform),
              ];
              settingsBeforeMigration[_localSwiftPackageReferenceSectionIndex] =
                  unmigratedLocalSwiftPackageReferenceSection(withOtherReference: true);
              project.xcodeProjectInfoFile.writeAsStringSync(
                _projectSettings(settingsBeforeMigration),
              );
              final List<String> settingsAsJsonBeforeMigration = <String>[
                ..._allSectionsUnmigratedAsJson(platform),
              ];
              final List<String> expectedSettings = <String>[..._allSectionsMigrated(platform)];
              expectedSettings[_localSwiftPackageReferenceSectionIndex] =
                  migratedLocalSwiftPackageReferenceSection(withOtherReference: true);

              final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
                _plutilOutput(settingsAsJsonBeforeMigration),
                _plutilOutput(_allSectionsMigratedAsJson(platform)),
              ]);

              final SwiftPackageManagerIntegrationMigration projectMigration =
                  SwiftPackageManagerIntegrationMigration(
                    project,
                    platform,
                    BuildInfo.debug,
                    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                    logger: testLogger,
                    fileSystem: memoryFileSystem,
                    plistParser: plistParser,
                    features: swiftPackageManagerFullyEnabledFlags,
                  );
              await projectMigration.migrate();
              expect(testLogger.errorText, isEmpty);
              expect(
                testLogger.traceText.contains(
                  'XCLocalSwiftPackageReference already migrated. Skipping...',
                ),
                isFalse,
              );
              expect(
                project.xcodeProjectInfoFile.readAsStringSync(),
                _projectSettings(expectedSettings),
              );
              expect(plistParser.hasRemainingExpectations, isFalse);
            });
          });

          group('migrate XCSwiftPackageProductDependency', () {
            testWithoutContext('fails if unable to find section to append it after', () async {
              final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
              final BufferLogger testLogger = BufferLogger.test();
              final FakeXcodeProject project = FakeXcodeProject(
                platform: platform.name,
                fileSystem: memoryFileSystem,
                logger: testLogger,
              );
              _createProjectFiles(project, platform);

              final List<String> settingsAsJsonBeforeMigration = <String>[
                ..._allSectionsMigratedAsJson(platform),
              ];
              settingsAsJsonBeforeMigration.removeAt(_swiftPackageProductDependencySectionIndex);

              final SwiftPackageManagerIntegrationMigration projectMigration =
                  SwiftPackageManagerIntegrationMigration(
                    project,
                    platform,
                    BuildInfo.debug,
                    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                    logger: testLogger,
                    fileSystem: memoryFileSystem,
                    plistParser: FakePlistParser(
                      json: _plutilOutput(settingsAsJsonBeforeMigration),
                    ),
                    features: swiftPackageManagerFullyEnabledFlags,
                  );
              await expectLater(
                () => projectMigration.migrate(),
                throwsToolExit(message: 'Unable to find any sections'),
              );
            });

            testWithoutContext('successfully added when section is missing', () async {
              final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
              final BufferLogger testLogger = BufferLogger.test();
              final FakeXcodeProject project = FakeXcodeProject(
                platform: platform.name,
                fileSystem: memoryFileSystem,
                logger: testLogger,
              );
              _createProjectFiles(project, platform);

              final List<String> settingsBeforeMigration = <String>[
                ..._allSectionsUnmigrated(platform),
              ];
              settingsBeforeMigration.removeAt(_swiftPackageProductDependencySectionIndex);
              project.xcodeProjectInfoFile.writeAsStringSync(
                _projectSettings(settingsBeforeMigration),
              );
              final List<String> settingsAsJsonBeforeMigration = <String>[
                ..._allSectionsUnmigratedAsJson(platform),
              ];

              final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
                _plutilOutput(settingsAsJsonBeforeMigration),
                _plutilOutput(_allSectionsMigratedAsJson(platform)),
              ]);

              final SwiftPackageManagerIntegrationMigration projectMigration =
                  SwiftPackageManagerIntegrationMigration(
                    project,
                    platform,
                    BuildInfo.debug,
                    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                    logger: testLogger,
                    fileSystem: memoryFileSystem,
                    plistParser: plistParser,
                    features: swiftPackageManagerFullyEnabledFlags,
                  );
              await projectMigration.migrate();
              expect(testLogger.errorText, isEmpty);
              expect(
                testLogger.traceText.contains(
                  'XCSwiftPackageProductDependency already migrated. Skipping...',
                ),
                isFalse,
              );
              expect(
                project.xcodeProjectInfoFile.readAsStringSync(),
                _projectSettings(_allSectionsMigrated(platform)),
              );
              expect(plistParser.hasRemainingExpectations, isFalse);
            });

            testWithoutContext('successfully added when section is empty', () async {
              final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
              final BufferLogger testLogger = BufferLogger.test();
              final FakeXcodeProject project = FakeXcodeProject(
                platform: platform.name,
                fileSystem: memoryFileSystem,
                logger: testLogger,
              );
              _createProjectFiles(project, platform);

              final List<String> settingsBeforeMigration = <String>[
                ..._allSectionsUnmigrated(platform),
              ];
              settingsBeforeMigration[_swiftPackageProductDependencySectionIndex] =
                  unmigratedSwiftPackageProductDependencySection();
              project.xcodeProjectInfoFile.writeAsStringSync(
                _projectSettings(settingsBeforeMigration),
              );
              final List<String> settingsAsJsonBeforeMigration = <String>[
                ..._allSectionsUnmigratedAsJson(platform),
              ];

              final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
                _plutilOutput(settingsAsJsonBeforeMigration),
                _plutilOutput(_allSectionsMigratedAsJson(platform)),
              ]);

              final SwiftPackageManagerIntegrationMigration projectMigration =
                  SwiftPackageManagerIntegrationMigration(
                    project,
                    platform,
                    BuildInfo.debug,
                    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                    logger: testLogger,
                    fileSystem: memoryFileSystem,
                    plistParser: plistParser,
                    features: swiftPackageManagerFullyEnabledFlags,
                  );
              await projectMigration.migrate();
              expect(testLogger.errorText, isEmpty);
              expect(
                testLogger.traceText.contains(
                  'XCSwiftPackageProductDependency already migrated. Skipping...',
                ),
                isFalse,
              );
              expect(
                project.xcodeProjectInfoFile.readAsStringSync(),
                _projectSettings(_allSectionsMigrated(platform)),
              );
              expect(plistParser.hasRemainingExpectations, isFalse);
            });

            testWithoutContext('successfully added when section is not empty', () async {
              final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
              final BufferLogger testLogger = BufferLogger.test();
              final FakeXcodeProject project = FakeXcodeProject(
                platform: platform.name,
                fileSystem: memoryFileSystem,
                logger: testLogger,
              );
              _createProjectFiles(project, platform);

              final List<String> settingsBeforeMigration = <String>[
                ..._allSectionsUnmigrated(platform),
              ];
              settingsBeforeMigration[_swiftPackageProductDependencySectionIndex] =
                  unmigratedSwiftPackageProductDependencySection(withOtherDependency: true);
              project.xcodeProjectInfoFile.writeAsStringSync(
                _projectSettings(settingsBeforeMigration),
              );
              final List<String> settingsAsJsonBeforeMigration = <String>[
                ..._allSectionsUnmigratedAsJson(platform),
              ];
              final List<String> expectedSettings = <String>[..._allSectionsMigrated(platform)];
              expectedSettings[_swiftPackageProductDependencySectionIndex] =
                  migratedSwiftPackageProductDependencySection(withOtherDependency: true);

              final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
                _plutilOutput(settingsAsJsonBeforeMigration),
                _plutilOutput(_allSectionsMigratedAsJson(platform)),
              ]);

              final SwiftPackageManagerIntegrationMigration projectMigration =
                  SwiftPackageManagerIntegrationMigration(
                    project,
                    platform,
                    BuildInfo.debug,
                    xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                    logger: testLogger,
                    fileSystem: memoryFileSystem,
                    plistParser: plistParser,
                    features: swiftPackageManagerFullyEnabledFlags,
                  );
              await projectMigration.migrate();
              expect(testLogger.errorText, isEmpty);
              expect(
                testLogger.traceText.contains(
                  'XCSwiftPackageProductDependency already migrated. Skipping...',
                ),
                isFalse,
              );
              expect(
                project.xcodeProjectInfoFile.readAsStringSync(),
                _projectSettings(expectedSettings),
              );
              expect(plistParser.hasRemainingExpectations, isFalse);
            });
          });

          testWithoutContext('throw if settings not updated correctly', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeXcodeProject project = FakeXcodeProject(
              platform: platform.name,
              fileSystem: memoryFileSystem,
              logger: testLogger,
            );
            _createProjectFiles(project, platform);
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(_allSectionsUnmigrated(platform)),
            );

            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(_allSectionsUnmigratedAsJson(platform)),
              _plutilOutput(_allSectionsUnmigratedAsJson(platform)),
            ]);

            final SwiftPackageManagerIntegrationMigration projectMigration =
                SwiftPackageManagerIntegrationMigration(
                  project,
                  platform,
                  BuildInfo.debug,
                  xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                  logger: testLogger,
                  fileSystem: memoryFileSystem,
                  plistParser: plistParser,
                  features: swiftPackageManagerFullyEnabledFlags,
                );
            await expectLater(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Settings were not updated correctly.'),
            );
            expect(
              testLogger.errorText,
              contains('PBXBuildFile was not migrated or was migrated incorrectly.'),
            );
            expect(
              testLogger.errorText,
              contains('PBXFrameworksBuildPhase was not migrated or was migrated incorrectly.'),
            );
            expect(
              testLogger.errorText,
              contains('Some PBXNativeTargets were not migrated or were migrated incorrectly.'),
            );
            expect(
              testLogger.errorText,
              contains('PBXProject was not migrated or was migrated incorrectly.'),
            );
            expect(
              testLogger.errorText,
              contains(
                'XCLocalSwiftPackageReference was not migrated or was migrated incorrectly.',
              ),
            );
            expect(
              testLogger.errorText,
              contains(
                'XCSwiftPackageProductDependency was not migrated or was migrated incorrectly.',
              ),
            );
          });
        });
      }
    });

    group('validate project settings', () {
      testWithoutContext('throw if settings fail to compile', () async {
        final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
        final BufferLogger testLogger = BufferLogger.test();
        const SupportedPlatform platform = SupportedPlatform.ios;
        final FakeXcodeProject project = FakeXcodeProject(
          platform: platform.name,
          fileSystem: memoryFileSystem,
          logger: testLogger,
        );
        _createProjectFiles(project, platform);
        project.xcodeProjectInfoFile.writeAsStringSync(
          _projectSettings(_allSectionsUnmigrated(platform)),
        );

        final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
          _plutilOutput(_allSectionsUnmigratedAsJson(platform)),
          _plutilOutput(_allSectionsMigratedAsJson(platform)),
        ]);

        final SwiftPackageManagerIntegrationMigration projectMigration =
            SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              BuildInfo.debug,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(throwErrorOnGetInfo: true),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: plistParser,
              features: swiftPackageManagerFullyEnabledFlags,
            );
        await expectLater(
          () => projectMigration.migrate(),
          throwsToolExit(message: 'Unable to get Xcode project information'),
        );
      });

      testWithoutContext('restore project settings from backup on failure', () async {
        final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
        final BufferLogger testLogger = BufferLogger.test();
        const SupportedPlatform platform = SupportedPlatform.ios;
        final FakeXcodeProject project = FakeXcodeProject(
          platform: platform.name,
          fileSystem: memoryFileSystem,
          logger: testLogger,
        );
        _createProjectFiles(project, platform);

        final String originalProjectInfo = _projectSettings(_allSectionsUnmigrated(platform));
        project.xcodeProjectInfoFile.writeAsStringSync(originalProjectInfo);
        final String originalSchemeContents = _validBuildActions(platform);

        final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
          _plutilOutput(_allSectionsUnmigratedAsJson(platform)),
          _plutilOutput(_allSectionsMigratedAsJson(platform)),
        ]);

        final FakeSwiftPackageManagerIntegrationMigration projectMigration =
            FakeSwiftPackageManagerIntegrationMigration(
              project,
              platform,
              BuildInfo.debug,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(throwErrorOnGetInfo: true),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: plistParser,
              features: swiftPackageManagerFullyEnabledFlags,
              validateBackup: true,
            );
        await expectLater(() async => projectMigration.migrate(), throwsToolExit());
        expect(testLogger.traceText, contains('Restoring project settings from backup file...'));
        expect(project.xcodeProjectInfoFile.readAsStringSync(), originalProjectInfo);
        expect(project.xcodeProjectSchemeFile().readAsStringSync(), originalSchemeContents);
      });
    });
  });
}

void _createProjectFiles(
  FakeXcodeProject project,
  SupportedPlatform platform, {
  bool createSchemeFile = true,
  String? scheme,
}) {
  project.parent.directory.createSync(recursive: true);
  project.hostAppRoot.createSync(recursive: true);
  project.xcodeProjectInfoFile.createSync(recursive: true);
  project.flutterPluginSwiftPackageManifest.createSync(recursive: true);
  if (createSchemeFile) {
    project.xcodeProjectSchemeFile(scheme: scheme).createSync(recursive: true);
    project.xcodeProjectSchemeFile().writeAsStringSync(_validBuildActions(platform));
  }
}

String _validBuildActions(
  SupportedPlatform platform, {
  bool hasPreActions = false,
  bool hasFrameworkScript = false,
  bool hasBuildEntries = true,
}) {
  final String scriptText;
  if (platform == SupportedPlatform.ios) {
    scriptText =
        r'scriptText = "/bin/sh &quot;$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh&quot; prepare&#10;">';
  } else {
    scriptText =
        r'scriptText = "&quot;$FLUTTER_ROOT&quot;/packages/flutter_tools/bin/macos_assemble.sh prepare&#10;">';
  }
  String preActions = '';
  if (hasFrameworkScript) {
    preActions = '''
\n      <PreActions>
         <ExecutionAction
            ActionType = "Xcode.IDEStandardExecutionActionsCore.ExecutionActionType.ShellScriptAction">
            <ActionContent
               title = "Run Prepare Flutter Framework Script"
               $scriptText
               <EnvironmentBuildable>
                  <BuildableReference
                     BuildableIdentifier = "primary"
                     BlueprintIdentifier = "${_runnerNativeTargetIdentifier(platform)}"
                     BuildableName = "Runner.app"
                     BlueprintName = "Runner"
                     ReferencedContainer = "container:Runner.xcodeproj">
                  </BuildableReference>
               </EnvironmentBuildable>
            </ActionContent>
         </ExecutionAction>
      </PreActions>''';
  } else if (hasPreActions) {
    preActions = '''
\n      <PreActions>
      </PreActions>''';
  }

  String buildEntries = '';
  if (hasBuildEntries) {
    buildEntries = '''
\n      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
${_validBuildableReference(platform)}
         </BuildActionEntry>
      </BuildActionEntries>
''';
  }
  return '''
<Scheme
   LastUpgradeVersion = "1510"
   version = "1.3">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">$preActions$buildEntries
   </BuildAction>
   <LaunchAction>
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
${_validBuildableReference(platform)}
      </BuildableProductRunnable>
   </LaunchAction>
</Scheme>
''';
}

String _validBuildableReference(SupportedPlatform platform) {
  return '''
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "${_runnerNativeTargetIdentifier(platform)}"
               BuildableName = "Runner.app"
               BlueprintName = "Runner"
               ReferencedContainer = "container:Runner.xcodeproj">
            </BuildableReference>''';
}

const int _buildFileSectionIndex = 0;
const int _frameworksBuildPhaseSectionIndex = 1;
const int _nativeTargetSectionIndex = 2;
const int _projectSectionIndex = 3;
const int _localSwiftPackageReferenceSectionIndex = 4;
const int _swiftPackageProductDependencySectionIndex = 5;

List<String> _allSectionsMigrated(SupportedPlatform platform) {
  return <String>[
    migratedBuildFileSection,
    migratedFrameworksBuildPhaseSection(platform),
    migratedNativeTargetSection(platform),
    migratedProjectSection(platform),
    migratedLocalSwiftPackageReferenceSection(),
    migratedSwiftPackageProductDependencySection(),
  ];
}

List<String> _allSectionsMigratedAsJson(SupportedPlatform platform) {
  return <String>[
    migratedBuildFileSectionAsJson,
    migratedFrameworksBuildPhaseSectionAsJson(platform),
    migratedNativeTargetSectionAsJson(platform),
    migratedProjectSectionAsJson(platform),
    migratedLocalSwiftPackageReferenceSectionAsJson,
    migratedSwiftPackageProductDependencySectionAsJson,
  ];
}

List<String> _allSectionsUnmigrated(SupportedPlatform platform) {
  return <String>[
    unmigratedBuildFileSection,
    unmigratedFrameworksBuildPhaseSection(platform),
    unmigratedNativeTargetSection(platform),
    unmigratedProjectSection(platform),
    unmigratedLocalSwiftPackageReferenceSection(),
    unmigratedSwiftPackageProductDependencySection(),
  ];
}

List<String> _allSectionsUnmigratedAsJson(SupportedPlatform platform) {
  return <String>[
    unmigratedBuildFileSectionAsJson,
    unmigratedFrameworksBuildPhaseSectionAsJson(platform),
    unmigratedNativeTargetSectionAsJson(platform),
    unmigratedProjectSectionAsJson(platform),
  ];
}

String _plutilOutput(List<String> objects) {
  return '''
{
  "archiveVersion" : "1",
  "classes" : {

  },
  "objects" : {
${objects.join(',\n')}
  }
}
''';
}

String _projectSettings(List<String> objects) {
  return '''
${objects.join('\n')}
''';
}

String _runnerFrameworksBuildPhaseIdentifier(SupportedPlatform platform) {
  return platform == SupportedPlatform.ios
      ? '97C146EB1CF9000F007C117D'
      : '33CC10EA2044A3C60003C045';
}

/// Get the default identifier for the Runner PBXNativeTarget.
String _runnerNativeTargetIdentifier(SupportedPlatform platform) {
  if (runnerNativeTargetIdentifierOverride != null) {
    return runnerNativeTargetIdentifierOverride!;
  }

  return platform == SupportedPlatform.ios
      ? '97C146ED1CF9000F007C117D'
      : '33CC10EC2044A3C60003C045';
}

/// Get an identifier for a PBXNativeTarget that is different from the default Runner identifier.
///
/// The value returned by this method was generated by XCode,
/// by duplicating the default Runner target for iOS and MacOS.
String _alternateRunnerNativeTargetIdentifier(SupportedPlatform platform) {
  return platform == SupportedPlatform.ios
      ? '430ACF912D82C20700EB9716'
      : '433CD29E2D82FFA9000230C8';
}

String _projectIdentifier(SupportedPlatform platform) {
  return platform == SupportedPlatform.ios
      ? '97C146E61CF9000F007C117D'
      : '33CC10E52044A3C60003C045';
}

String _runnerTestsTarget(SupportedPlatform platform) {
  return platform == SupportedPlatform.ios ? runnerTestsTargetIos : runnerTestsTargetMacos;
}

String _runnerUITestsTarget(SupportedPlatform platform) {
  return platform == SupportedPlatform.ios ? runnerUITestsTargetIos : runnerUITestsTargetMacos;
}

String _runnerTestsTargetAsJson(SupportedPlatform platform) {
  return platform == SupportedPlatform.ios
      ? runnerTestsTargetIosAsJson
      : runnerTestsTargetMacosAsJson;
}

String _runnerUITestsTargetAsJson(SupportedPlatform platform) {
  return platform == SupportedPlatform.ios
      ? runnerUITestsTargetIosAsJson
      : runnerUITestsTargetMacosAsJson;
}

// PBXBuildFile
const String unmigratedBuildFileSection = '''
/* Begin PBXBuildFile section */
		74858FAF1ED2DC5600515810 /* AppDelegate.swift in Sources */ = {isa = PBXBuildFile; fileRef = 74858FAE1ED2DC5600515810 /* AppDelegate.swift */; };
		97C146FC1CF9000F007C117D /* Main.storyboard in Resources */ = {isa = PBXBuildFile; fileRef = 97C146FA1CF9000F007C117D /* Main.storyboard */; };
/* End PBXBuildFile section */
''';
const String migratedBuildFileSection = '''
/* Begin PBXBuildFile section */
		74858FAF1ED2DC5600515810 /* AppDelegate.swift in Sources */ = {isa = PBXBuildFile; fileRef = 74858FAE1ED2DC5600515810 /* AppDelegate.swift */; };
		97C146FC1CF9000F007C117D /* Main.storyboard in Resources */ = {isa = PBXBuildFile; fileRef = 97C146FA1CF9000F007C117D /* Main.storyboard */; };
		78A318202AECB46A00862997 /* FlutterGeneratedPluginSwiftPackage in Frameworks */ = {isa = PBXBuildFile; productRef = 78A3181F2AECB46A00862997 /* FlutterGeneratedPluginSwiftPackage */; };
/* End PBXBuildFile section */
''';
const String unmigratedBuildFileSectionAsJson = '''
    "97C146FC1CF9000F007C117D" : {
      "fileRef" : "97C146FA1CF9000F007C117D",
      "isa" : "PBXBuildFile"
    },
    "74858FAF1ED2DC5600515810" : {
      "fileRef" : "74858FAE1ED2DC5600515810",
      "isa" : "PBXBuildFile"
    }''';
const String migratedBuildFileSectionAsJson = '''
    "78A318202AECB46A00862997" : {
      "isa" : "PBXBuildFile",
      "productRef" : "78A3181F2AECB46A00862997"
    },
    "97C146FC1CF9000F007C117D" : {
      "fileRef" : "97C146FA1CF9000F007C117D",
      "isa" : "PBXBuildFile"
    },
    "74858FAF1ED2DC5600515810" : {
      "fileRef" : "74858FAE1ED2DC5600515810",
      "isa" : "PBXBuildFile"
    }''';

// PBXFrameworksBuildPhase
String unmigratedFrameworksBuildPhaseSection(
  SupportedPlatform platform, {
  bool withCocoapods = false,
  bool missingFiles = false,
}) {
  return <String>[
    '/* Begin PBXFrameworksBuildPhase section */',
    '		${_runnerFrameworksBuildPhaseIdentifier(platform)} /* Frameworks */ = {',
    '			isa = PBXFrameworksBuildPhase;',
    '			buildActionMask = 2147483647;',
    if (!missingFiles) ...<String>[
      '			files = (',
      if (withCocoapods) '				FD5BB45FB410D26C457F3823 /* Pods_Runner.framework in Frameworks */,',
      '			);',
    ],
    '			runOnlyForDeploymentPostprocessing = 0;',
    '		};',
    '/* End PBXFrameworksBuildPhase section */',
  ].join('\n');
}

String migratedFrameworksBuildPhaseSection(
  SupportedPlatform platform, {
  bool withCocoapods = false,
  bool missingFiles = false,
}) {
  final List<String> filesField = <String>[
    '			files = (',
    '				78A318202AECB46A00862997 /* FlutterGeneratedPluginSwiftPackage in Frameworks */,',
    if (withCocoapods) '				FD5BB45FB410D26C457F3823 /* Pods_Runner.framework in Frameworks */,',
    '			);',
  ];
  return <String>[
    '/* Begin PBXFrameworksBuildPhase section */',
    '		${_runnerFrameworksBuildPhaseIdentifier(platform)} /* Frameworks */ = {',
    if (missingFiles) ...filesField,
    '			isa = PBXFrameworksBuildPhase;',
    '			buildActionMask = 2147483647;',
    if (!missingFiles) ...filesField,
    '			runOnlyForDeploymentPostprocessing = 0;',
    '		};',
    '/* End PBXFrameworksBuildPhase section */',
  ].join('\n');
}

String unmigratedFrameworksBuildPhaseSectionAsJson(
  SupportedPlatform platform, {
  bool withCocoapods = false,
  bool missingFiles = false,
}) {
  return <String>[
    '    "${_runnerFrameworksBuildPhaseIdentifier(platform)}" : {',
    '      "buildActionMask" : "2147483647",',
    if (!missingFiles) ...<String>[
      '      "files" : [',
      if (withCocoapods) '        "FD5BB45FB410D26C457F3823"',
      '      ],',
    ],
    '      "isa" : "PBXFrameworksBuildPhase",',
    '      "runOnlyForDeploymentPostprocessing" : "0"',
    '    }',
  ].join('\n');
}

String migratedFrameworksBuildPhaseSectionAsJson(SupportedPlatform platform) {
  return '''
    "${_runnerFrameworksBuildPhaseIdentifier(platform)}" : {
      "buildActionMask" : "2147483647",
      "files" : [
        "78A318202AECB46A00862997"
      ],
      "isa" : "PBXFrameworksBuildPhase",
      "runOnlyForDeploymentPostprocessing" : "0"
    }''';
}

// PBXNativeTarget
const String unmigratedOtherApplicationTarget = '''
   354BE72C2A385E0200F71CEE /* OtherTarget */ = {
     isa = PBXNativeTarget;
     buildConfigurationList = 354BE73C2A385E0200F71CEE /* Build configuration list for PBXNativeTarget "OtherTarget" */;
     buildPhases = (
       354BE72E2A385E0200F71CEE /* Run Script */,
       354BE72F2A385E0200F71CEE /* Sources */,
       354BE7322A385E0200F71CEE /* Frameworks */,
       354BE7342A385E0200F71CEE /* Resources */,
       35EC537E2A4038C200CBDB83 /* Embed Frameworks */,
       354BE73A2A385E0200F71CEE /* Thin Binary */,
     );
     buildRules = (
     );
     dependencies = (
     );
     name = OtherTarget;
     packageProductDependencies = (
     );
     productName = OtherTarget;
     productReference = 354BE7402A385E0200F71CEE /* OtherTarget.app */;
     productType = "com.apple.product-type.application";
   };''';

const String unmigratedOtherApplicationTargetAsJson = '''
    "354BE72C2A385E0200F71CEE" : {
      "buildConfigurationList" : "354BE73C2A385E0200F71CEE",
      "buildPhases" : [
        "354BE72E2A385E0200F71CEE",
        "354BE72F2A385E0200F71CEE",
        "354BE7322A385E0200F71CEE",
        "354BE7342A385E0200F71CEE",
        "35EC537E2A4038C200CBDB83",
        "354BE73A2A385E0200F71CEE"
      ],
      "buildRules" : [

      ],
      "dependencies" : [

      ],
      "isa" : "PBXNativeTarget",
      "name" : "OtherTarget",
      "packageProductDependencies" : [

      ],
      "productName" : "OtherTarget",
      "productReference" : "354BE7402A385E0200F71CEE",
      "productType" : "com.apple.product-type.application"
    }''';

const String migratedOtherApplicationTarget = '''
   354BE72C2A385E0200F71CEE /* OtherTarget */ = {
     isa = PBXNativeTarget;
     buildConfigurationList = 354BE73C2A385E0200F71CEE /* Build configuration list for PBXNativeTarget "OtherTarget" */;
     buildPhases = (
       354BE72E2A385E0200F71CEE /* Run Script */,
       354BE72F2A385E0200F71CEE /* Sources */,
       354BE7322A385E0200F71CEE /* Frameworks */,
       354BE7342A385E0200F71CEE /* Resources */,
       35EC537E2A4038C200CBDB83 /* Embed Frameworks */,
       354BE73A2A385E0200F71CEE /* Thin Binary */,
     );
     buildRules = (
     );
     dependencies = (
     );
     name = OtherTarget;
     packageProductDependencies = (
       78A3181F2AECB46A00862997 /* FlutterGeneratedPluginSwiftPackage */,
     );
     productName = OtherTarget;
     productReference = 354BE7402A385E0200F71CEE /* OtherTarget.app */;
     productType = "com.apple.product-type.application";
   };''';

const String migratedOtherApplicationTargetAsJson = '''
    "354BE72C2A385E0200F71CEE" : {
      "buildConfigurationList" : "354BE73C2A385E0200F71CEE",
      "buildPhases" : [
        "354BE72E2A385E0200F71CEE",
        "354BE72F2A385E0200F71CEE",
        "354BE7322A385E0200F71CEE",
        "354BE7342A385E0200F71CEE",
        "35EC537E2A4038C200CBDB83",
        "354BE73A2A385E0200F71CEE"
      ],
      "buildRules" : [

      ],
      "dependencies" : [

      ],
      "isa" : "PBXNativeTarget",
      "name" : "OtherTarget",
      "packageProductDependencies" : [
        "78A3181F2AECB46A00862997"
      ],
      "productName" : "OtherTarget",
      "productReference" : "354BE7402A385E0200F71CEE",
      "productType" : "com.apple.product-type.application"
    }''';

const String runnerTestsTargetIos = '''
   331C8080294A63A400263BE5 /* RunnerTests */ = {
     isa = PBXNativeTarget;
     buildConfigurationList = 331C8087294A63A400263BE5 /* Build configuration list for PBXNativeTarget "RunnerTests" */;
     buildPhases = (
       2AE287FFFE7E9A0A556FAB17 /* [CP] Check Pods Manifest.lock */,
       331C807D294A63A400263BE5 /* Sources */,
       331C807F294A63A400263BE5 /* Resources */,
       C6D5C1912D94BBDDC851B5AD /* Frameworks */,
     );
     buildRules = (
     );
     dependencies = (
       331C8086294A63A400263BE5 /* PBXTargetDependency */,
     );
     name = RunnerTests;
     productName = RunnerTests;
     productReference = 331C8081294A63A400263BE5 /* RunnerTests.xctest */;
     productType = "com.apple.product-type.bundle.unit-test";
   };''';

const String runnerTestsTargetIosAsJson = '''
    "331C8080294A63A400263BE5" : {
      "buildConfigurationList" : "331C8087294A63A400263BE5",
      "buildPhases" : [
        "2AE287FFFE7E9A0A556FAB17",
        "331C807D294A63A400263BE5",
        "331C807F294A63A400263BE5",
        "C6D5C1912D94BBDDC851B5AD"
      ],
      "buildRules" : [

      ],
      "dependencies" : [
        "331C8086294A63A400263BE5"
      ],
      "isa" : "PBXNativeTarget",
      "name" : "RunnerTests",
      "productName" : "RunnerTests",
      "productReference" : "331C8081294A63A400263BE5",
      "productType" : "com.apple.product-type.bundle.unit-test"
    }''';

const String runnerTestsTargetMacos = '''
   331C80D4294CF70F00263BE5 /* RunnerTests */ = {
     isa = PBXNativeTarget;
     buildConfigurationList = 331C80DE294CF71000263BE5 /* Build configuration list for PBXNativeTarget "RunnerTests" */;
     buildPhases = (
       3277B0B414012D3DCE9EE962 /* [CP] Check Pods Manifest.lock */,
       331C80D1294CF70F00263BE5 /* Sources */,
       331C80D2294CF70F00263BE5 /* Frameworks */,
       331C80D3294CF70F00263BE5 /* Resources */,
     );
     buildRules = (
     );
     dependencies = (
       331C80DA294CF71000263BE5 /* PBXTargetDependency */,
     );
     name = RunnerTests;
     productName = RunnerTests;
     productReference = 331C80D5294CF71000263BE5 /* RunnerTests.xctest */;
     productType = "com.apple.product-type.bundle.unit-test";
   };''';

const String runnerTestsTargetMacosAsJson = '''
    "331C80D4294CF70F00263BE5" : {
      "buildConfigurationList" : "331C80DE294CF71000263BE5",
      "buildPhases" : [
        "3277B0B414012D3DCE9EE962",
        "331C80D1294CF70F00263BE5",
        "331C80D2294CF70F00263BE5",
        "331C80D3294CF70F00263BE5"
      ],
      "buildRules" : [

      ],
      "dependencies" : [
        "331C80DA294CF71000263BE5"
      ],
      "isa" : "PBXNativeTarget",
      "name" : "RunnerTests",
      "productName" : "RunnerTests",
      "productReference" : "331C80D5294CF71000263BE5",
      "productType" : "com.apple.product-type.bundle.unit-test"
    }''';

const String runnerUITestsTargetIos = '''
   43AA61E72D9ACBAA00529601 /* RunnerUITests */ = {
     isa = PBXNativeTarget;
     buildConfigurationList = 43AA61F32D9ACBAA00529601 /* Build configuration list for PBXNativeTarget "RunnerUITests" */;
     buildPhases = (
       43AA61E42D9ACBAA00529601 /* Sources */,
       43AA61E52D9ACBAA00529601 /* Frameworks */,
       43AA61E62D9ACBAA00529601 /* Resources */,
     );
     buildRules = (
     );
     dependencies = (
       43AA61EF2D9ACBAA00529601 /* PBXTargetDependency */,
     );
     fileSystemSynchronizedGroups = (
       43AA61E92D9ACBAA00529601 /* RunnerUITests */,
     );
     name = RunnerUITests;
     packageProductDependencies = (
     );
     productName = RunnerUITests;
     productReference = 43AA61E82D9ACBAA00529601 /* RunnerUITests.xctest */;
     productType = "com.apple.product-type.bundle.ui-testing";
   };''';

const String runnerUITestsTargetIosAsJson = '''
    "43AA61E72D9ACBAA00529601" : {
      "buildConfigurationList" : "43AA61F32D9ACBAA00529601",
      "buildPhases" : [
        "43AA61E42D9ACBAA00529601",
        "43AA61E52D9ACBAA00529601",
        "43AA61E62D9ACBAA00529601"
      ],
      "buildRules" : [

      ],
      "dependencies" : [
        "43AA61EF2D9ACBAA00529601"
      ],
      "fileSystemSynchronizedGroups" : [
        "43AA61E92D9ACBAA00529601"
      ],
      "isa" : "PBXNativeTarget",
      "name" : "RunnerUITests",
      "productName" : "RunnerUITests",
      "productReference" : "43AA61E82D9ACBAA00529601",
      "productType" : "com.apple.product-type.bundle.ui-testing"
    }''';

const String runnerUITestsTargetMacos = '''
   43AA61F72D9ACBC800529601 /* RunnerUITests */ = {
     isa = PBXNativeTarget;
     buildConfigurationList = 43AA62032D9ACBC800529601 /* Build configuration list for PBXNativeTarget "RunnerUITests" */;
     buildPhases = (
       43AA61F42D9ACBC800529601 /* Sources */,
       43AA61F52D9ACBC800529601 /* Frameworks */,
       43AA61F62D9ACBC800529601 /* Resources */,
     );
     buildRules = (
     );
     dependencies = (
       43AA61FF2D9ACBC800529601 /* PBXTargetDependency */,
     );
     fileSystemSynchronizedGroups = (
       43AA61F92D9ACBC800529601 /* RunnerUITests */,
     );
     name = RunnerUITests;
     packageProductDependencies = (
     );
     productName = RunnerUITests;
     productReference = 43AA61F82D9ACBC800529601 /* RunnerUITests.xctest */;
     productType = "com.apple.product-type.bundle.ui-testing";
   };''';

const String runnerUITestsTargetMacosAsJson = '''
    "43AA61F72D9ACBC800529601" : {
      "buildConfigurationList" : "43AA62032D9ACBC800529601",
      "buildPhases" : [
        "43AA61F42D9ACBC800529601",
        "43AA61F52D9ACBC800529601",
        "43AA61F62D9ACBC800529601"
      ],
      "buildRules" : [

      ],
      "dependencies" : [
        "43AA61FF2D9ACBC800529601"
      ],
      "fileSystemSynchronizedGroups" : [
        "43AA61F92D9ACBC800529601"
      ],
      "isa" : "PBXNativeTarget",
      "name" : "RunnerUITests",
      "productName" : "RunnerUITests",
      "productReference" : "43AA61F82D9ACBC800529601",
      "productType" : "com.apple.product-type.bundle.ui-testing"
    }''';

String unmigratedNativeTargetSection(
  SupportedPlatform platform, {
  bool missingPackageProductDependencies = false,
  bool withOtherDependency = false,
  String? otherNativeTarget,
}) {
  final StringBuffer builder = StringBuffer();
  final String runnerTarget = <String>[
    '		${_runnerNativeTargetIdentifier(platform)} /* Runner */ = {',
    '			isa = PBXNativeTarget;',
    '			buildConfigurationList = 97C147051CF9000F007C117D /* Build configuration list for PBXNativeTarget "Runner" */;',
    '			buildPhases = (',
    '				9740EEB61CF901F6004384FC /* Run Script */,',
    '				97C146EA1CF9000F007C117D /* Sources */,',
    '				${_runnerFrameworksBuildPhaseIdentifier(platform)} /* Frameworks */,',
    '				97C146EC1CF9000F007C117D /* Resources */,',
    '				9705A1C41CF9048500538489 /* Embed Frameworks */,',
    '				3B06AD1E1E4923F5004D2608 /* Thin Binary */,',
    '			);',
    '			buildRules = (',
    '			);',
    '			dependencies = (',
    '			);',
    '			name = Runner;',
    if (!missingPackageProductDependencies) ...<String>[
      '			packageProductDependencies = (',
      if (withOtherDependency) '				010101010101010101010101 /* SomeOtherPackage */,',
      '			);',
    ],
    '			productName = Runner;',
    '			productReference = 97C146EE1CF9000F007C117D /* Runner.app */;',
    '			productType = "com.apple.product-type.application";',
    '		};',
  ].join('\n');

  builder.writeln('/* Begin PBXNativeTarget section */');

  builder.writeln(runnerTarget);

  if (otherNativeTarget != null) {
    builder.writeln(otherNativeTarget);
  }

  builder.write('/* End PBXNativeTarget section */');

  return builder.toString();
}

String migratedNativeTargetSection(
  SupportedPlatform platform, {
  bool missingPackageProductDependencies = false,
  bool withOtherDependency = false,
  String? otherNativeTarget,
}) {
  final StringBuffer builder = StringBuffer();
  final List<String> packageDependencies = <String>[
    '			packageProductDependencies = (',
    '				78A3181F2AECB46A00862997 /* FlutterGeneratedPluginSwiftPackage */,',
    if (withOtherDependency) '				010101010101010101010101 /* SomeOtherPackage */,',
    '			);',
  ];
  final String runnerTarget = <String>[
    '		${_runnerNativeTargetIdentifier(platform)} /* Runner */ = {',
    if (missingPackageProductDependencies) ...packageDependencies,
    '			isa = PBXNativeTarget;',
    '			buildConfigurationList = 97C147051CF9000F007C117D /* Build configuration list for PBXNativeTarget "Runner" */;',
    '			buildPhases = (',
    '				9740EEB61CF901F6004384FC /* Run Script */,',
    '				97C146EA1CF9000F007C117D /* Sources */,',
    '				${_runnerFrameworksBuildPhaseIdentifier(platform)} /* Frameworks */,',
    '				97C146EC1CF9000F007C117D /* Resources */,',
    '				9705A1C41CF9048500538489 /* Embed Frameworks */,',
    '				3B06AD1E1E4923F5004D2608 /* Thin Binary */,',
    '			);',
    '			buildRules = (',
    '			);',
    '			dependencies = (',
    '			);',
    '			name = Runner;',
    if (!missingPackageProductDependencies) ...packageDependencies,
    '			productName = Runner;',
    '			productReference = 97C146EE1CF9000F007C117D /* Runner.app */;',
    '			productType = "com.apple.product-type.application";',
    '		};',
  ].join('\n');

  builder.writeln('/* Begin PBXNativeTarget section */');

  builder.writeln(runnerTarget);

  if (otherNativeTarget != null) {
    builder.writeln(otherNativeTarget);
  }

  builder.write('/* End PBXNativeTarget section */');

  return builder.toString();
}

String unmigratedNativeTargetSectionAsJson(
  SupportedPlatform platform, {
  bool missingPackageProductDependencies = false,
}) {
  return <String>[
    '    "${_runnerNativeTargetIdentifier(platform)}" : {',
    '      "buildConfigurationList" : "97C147051CF9000F007C117D",',
    '      "buildPhases" : [',
    '        "9740EEB61CF901F6004384FC",',
    '        "97C146EA1CF9000F007C117D",',
    '        "${_runnerFrameworksBuildPhaseIdentifier(platform)}",',
    '        "97C146EC1CF9000F007C117D",',
    '        "9705A1C41CF9048500538489",',
    '        "3B06AD1E1E4923F5004D2608"',
    '      ],',
    '      "buildRules" : [',
    '      ],',
    '      "dependencies" : [',
    '      ],',
    '      "isa" : "PBXNativeTarget",',
    '      "name" : "Runner",',
    if (!missingPackageProductDependencies) ...<String>[
      '      "packageProductDependencies" : [',
      '      ],',
    ],
    '      "productName" : "Runner",',
    '      "productReference" : "97C146EE1CF9000F007C117D",',
    '      "productType" : "com.apple.product-type.application"',
    '    }',
  ].join('\n');
}

String migratedNativeTargetSectionAsJson(SupportedPlatform platform) {
  return '''
    "${_runnerNativeTargetIdentifier(platform)}" : {
      "buildConfigurationList" : "97C147051CF9000F007C117D",
      "buildPhases" : [
        "9740EEB61CF901F6004384FC",
        "97C146EA1CF9000F007C117D",
        "${_runnerFrameworksBuildPhaseIdentifier(platform)}",
        "97C146EC1CF9000F007C117D",
        "9705A1C41CF9048500538489",
        "3B06AD1E1E4923F5004D2608"
      ],
      "buildRules" : [

      ],
      "dependencies" : [

      ],
      "isa" : "PBXNativeTarget",
      "name" : "Runner",
      "packageProductDependencies" : [
        "78A3181F2AECB46A00862997"
      ],
      "productName" : "Runner",
      "productReference" : "97C146EE1CF9000F007C117D",
      "productType" : "com.apple.product-type.application"
    }''';
}

// PBXProject
String unmigratedProjectSection(
  SupportedPlatform platform, {
  bool missingPackageReferences = false,
  bool withOtherReference = false,
}) {
  final String nativeTargetIdentifier = _runnerNativeTargetIdentifier(platform);

  return <String>[
    '/* Begin PBXProject section */',
    '		${_projectIdentifier(platform)} /* Project object */ = {',
    '			isa = PBXProject;',
    '			attributes = {',
    '				BuildIndependentTargetsInParallel = YES;',
    '				LastUpgradeCheck = 1510;',
    '				ORGANIZATIONNAME = "";',
    '				TargetAttributes = {',
    '					331C8080294A63A400263BE5 = {',
    '						CreatedOnToolsVersion = 14.0;',
    '						TestTargetID = $nativeTargetIdentifier;',
    '					};',
    '					$nativeTargetIdentifier = {',
    '						CreatedOnToolsVersion = 7.3.1;',
    '						LastSwiftMigration = 1100;',
    '					};',
    '				};',
    '			};',
    '			buildConfigurationList = 97C146E91CF9000F007C117D /* Build configuration list for PBXProject "Runner" */;',
    '			compatibilityVersion = "Xcode 9.3";',
    '			developmentRegion = en;',
    '			hasScannedForEncodings = 0;',
    '			knownRegions = (',
    '				en,',
    '				Base,',
    '			);',
    '			mainGroup = 97C146E51CF9000F007C117D;',
    if (!missingPackageReferences) ...<String>[
      '			packageReferences = (',
      if (withOtherReference)
        '				010101010101010101010101 /* XCLocalSwiftPackageReference "SomeOtherPackage" */,',
      '			);',
    ],
    '			productRefGroup = 97C146EF1CF9000F007C117D /* Products */;',
    '			projectDirPath = "";',
    '			projectRoot = "";',
    '			targets = (',
    '				$nativeTargetIdentifier /* Runner */,',
    '				331C8080294A63A400263BE5 /* RunnerTests */,',
    '			);',
    '		};',
    '/* End PBXProject section */',
  ].join('\n');
}

String migratedProjectSection(
  SupportedPlatform platform, {
  bool missingPackageReferences = false,
  bool withOtherReference = false,
}) {
  final String nativeTargetIdentifier = _runnerNativeTargetIdentifier(platform);

  final List<String> packageDependencies = <String>[
    '			packageReferences = (',
    '				781AD8BC2B33823900A9FFBB /* XCLocalSwiftPackageReference "Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage" */,',
    if (withOtherReference)
      '				010101010101010101010101 /* XCLocalSwiftPackageReference "SomeOtherPackage" */,',
    '			);',
  ];
  return <String>[
    '/* Begin PBXProject section */',
    '		${_projectIdentifier(platform)} /* Project object */ = {',
    if (missingPackageReferences) ...packageDependencies,
    '			isa = PBXProject;',
    '			attributes = {',
    '				BuildIndependentTargetsInParallel = YES;',
    '				LastUpgradeCheck = 1510;',
    '				ORGANIZATIONNAME = "";',
    '				TargetAttributes = {',
    '					331C8080294A63A400263BE5 = {',
    '						CreatedOnToolsVersion = 14.0;',
    '						TestTargetID = $nativeTargetIdentifier;',
    '					};',
    '					$nativeTargetIdentifier = {',
    '						CreatedOnToolsVersion = 7.3.1;',
    '						LastSwiftMigration = 1100;',
    '					};',
    '				};',
    '			};',
    '			buildConfigurationList = 97C146E91CF9000F007C117D /* Build configuration list for PBXProject "Runner" */;',
    '			compatibilityVersion = "Xcode 9.3";',
    '			developmentRegion = en;',
    '			hasScannedForEncodings = 0;',
    '			knownRegions = (',
    '				en,',
    '				Base,',
    '			);',
    '			mainGroup = 97C146E51CF9000F007C117D;',
    if (!missingPackageReferences) ...packageDependencies,
    '			productRefGroup = 97C146EF1CF9000F007C117D /* Products */;',
    '			projectDirPath = "";',
    '			projectRoot = "";',
    '			targets = (',
    '				$nativeTargetIdentifier /* Runner */,',
    '				331C8080294A63A400263BE5 /* RunnerTests */,',
    '			);',
    '		};',
    '/* End PBXProject section */',
  ].join('\n');
}

String unmigratedProjectSectionAsJson(
  SupportedPlatform platform, {
  bool missingPackageReferences = false,
}) {
  final String nativeTargetIdentifier = _runnerNativeTargetIdentifier(platform);

  return <String>[
    '    "${_projectIdentifier(platform)}" : {',
    '      "attributes" : {',
    '        "BuildIndependentTargetsInParallel" : "YES",',
    '        "LastUpgradeCheck" : "1510",',
    '        "ORGANIZATIONNAME" : "",',
    '        "TargetAttributes" : {',
    '          "$nativeTargetIdentifier" : {',
    '            "CreatedOnToolsVersion" : "7.3.1",',
    '            "LastSwiftMigration" : "1100"',
    '          },',
    '          "331C8080294A63A400263BE5" : {',
    '            "CreatedOnToolsVersion" : "14.0",',
    '            "TestTargetID" : "$nativeTargetIdentifier"',
    '          }',
    '        }',
    '      },',
    '      "buildConfigurationList" : "97C146E91CF9000F007C117D",',
    '      "compatibilityVersion" : "Xcode 9.3",',
    '      "developmentRegion" : "en",',
    '      "hasScannedForEncodings" : "0",',
    '      "isa" : "PBXProject",',
    '      "knownRegions" : [',
    '        "en",',
    '        "Base"',
    '      ],',
    '      "mainGroup" : "97C146E51CF9000F007C117D",',
    if (!missingPackageReferences) ...<String>['      "packageReferences" : [', '      ],'],
    '      "productRefGroup" : "97C146EF1CF9000F007C117D",',
    '      "projectDirPath" : "",',
    '      "projectRoot" : "",',
    '      "targets" : [',
    '        "$nativeTargetIdentifier",',
    '        "331C8080294A63A400263BE5"',
    '      ]',
    '    }',
  ].join('\n');
}

String migratedProjectSectionAsJson(SupportedPlatform platform) {
  final String nativeTargetIdentifier = _runnerNativeTargetIdentifier(platform);

  return '''
    "${_projectIdentifier(platform)}" : {
      "attributes" : {
        "BuildIndependentTargetsInParallel" : "YES",
        "LastUpgradeCheck" : "1510",
        "ORGANIZATIONNAME" : "",
        "TargetAttributes" : {
          "$nativeTargetIdentifier" : {
            "CreatedOnToolsVersion" : "7.3.1",
            "LastSwiftMigration" : "1100"
          },
          "331C8080294A63A400263BE5" : {
            "CreatedOnToolsVersion" : "14.0",
            "TestTargetID" : "$nativeTargetIdentifier"
          }
        }
      },
      "buildConfigurationList" : "97C146E91CF9000F007C117D",
      "compatibilityVersion" : "Xcode 9.3",
      "developmentRegion" : "en",
      "hasScannedForEncodings" : "0",
      "isa" : "PBXProject",
      "knownRegions" : [
        "en",
        "Base"
      ],
      "mainGroup" : "97C146E51CF9000F007C117D",
      "packageReferences" : [
        "781AD8BC2B33823900A9FFBB"
      ],
      "productRefGroup" : "97C146EF1CF9000F007C117D",
      "projectDirPath" : "",
      "projectRoot" : "",
      "targets" : [
        "$nativeTargetIdentifier",
        "331C8080294A63A400263BE5"
      ]
    }''';
}

// XCLocalSwiftPackageReference
String unmigratedLocalSwiftPackageReferenceSection({bool withOtherReference = false}) {
  return <String>[
    '/* Begin XCLocalSwiftPackageReference section */',
    if (withOtherReference) ...<String>[
      '		010101010101010101010101 /* XCLocalSwiftPackageReference "SomeOtherPackage" */ = {',
      '			isa = XCLocalSwiftPackageReference;',
      '			relativePath = SomeOtherPackage;',
      '		};',
    ],
    '/* End XCLocalSwiftPackageReference section */',
  ].join('\n');
}

String migratedLocalSwiftPackageReferenceSection({bool withOtherReference = false}) {
  return <String>[
    '/* Begin XCLocalSwiftPackageReference section */',
    if (withOtherReference) ...<String>[
      '		010101010101010101010101 /* XCLocalSwiftPackageReference "SomeOtherPackage" */ = {',
      '			isa = XCLocalSwiftPackageReference;',
      '			relativePath = SomeOtherPackage;',
      '		};',
    ],
    '		781AD8BC2B33823900A9FFBB /* XCLocalSwiftPackageReference "Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage" */ = {',
    '			isa = XCLocalSwiftPackageReference;',
    '			relativePath = Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage;',
    '		};',
    '/* End XCLocalSwiftPackageReference section */',
  ].join('\n');
}

const String migratedLocalSwiftPackageReferenceSectionAsJson = '''
    "781AD8BC2B33823900A9FFBB" : {
      "isa" : "XCLocalSwiftPackageReference",
      "relativePath" : "Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage"
    }''';

// XCSwiftPackageProductDependency
String unmigratedSwiftPackageProductDependencySection({bool withOtherDependency = false}) {
  return <String>[
    '/* Begin XCSwiftPackageProductDependency section */',
    if (withOtherDependency) ...<String>[
      '		010101010101010101010101 /* SomeOtherPackage */ = {',
      '			isa = XCSwiftPackageProductDependency;',
      '			productName = SomeOtherPackage;',
      '		};',
    ],
    '/* End XCSwiftPackageProductDependency section */',
  ].join('\n');
}

String migratedSwiftPackageProductDependencySection({bool withOtherDependency = false}) {
  return <String>[
    '/* Begin XCSwiftPackageProductDependency section */',
    if (withOtherDependency) ...<String>[
      '		010101010101010101010101 /* SomeOtherPackage */ = {',
      '			isa = XCSwiftPackageProductDependency;',
      '			productName = SomeOtherPackage;',
      '		};',
    ],
    '		78A3181F2AECB46A00862997 /* FlutterGeneratedPluginSwiftPackage */ = {',
    '			isa = XCSwiftPackageProductDependency;',
    '			productName = FlutterGeneratedPluginSwiftPackage;',
    '		};',
    '/* End XCSwiftPackageProductDependency section */',
  ].join('\n');
}

const String migratedSwiftPackageProductDependencySectionAsJson = '''
    "78A3181F2AECB46A00862997" : {
      "isa" : "XCSwiftPackageProductDependency",
      "productName" : "FlutterGeneratedPluginSwiftPackage"
    }''';

class FakeXcodeProjectInterpreter extends Fake implements XcodeProjectInterpreter {
  FakeXcodeProjectInterpreter({this.throwErrorOnGetInfo = false});

  @override
  bool isInstalled = false;

  @override
  List<String> xcrunCommand() => <String>['xcrun'];

  final bool throwErrorOnGetInfo;

  @override
  Future<XcodeProjectInfo?> getInfo(String projectPath, {String? projectFilename}) async {
    if (throwErrorOnGetInfo) {
      throwToolExit('Unable to get Xcode project information');
    }
    return null;
  }
}

class FakePlistParser extends Fake implements PlistParser {
  FakePlistParser({String? json}) : _outputPerCall = (json != null) ? <String>[json] : null;

  FakePlistParser.multiple(this._outputPerCall);

  final List<String>? _outputPerCall;

  @override
  String? plistJsonContent(String filePath) {
    if (_outputPerCall != null && _outputPerCall.isNotEmpty) {
      return _outputPerCall.removeAt(0);
    }
    return null;
  }

  bool get hasRemainingExpectations {
    return _outputPerCall != null && _outputPerCall.isNotEmpty;
  }
}

class FakeXcodeProject extends Fake implements IosProject {
  FakeXcodeProject({
    required MemoryFileSystem fileSystem,
    required String platform,
    required this.logger,
    this.schemes = const <String>['Runner'],
  }) : hostAppRoot = fileSystem.directory('app_name').childDirectory(platform),
       parent = FakeFlutterProject(fileSystem: fileSystem);

  final Logger logger;
  final List<String> schemes;
  late XcodeProjectInfo? _projectInfo = XcodeProjectInfo(
    <String>['Runner'],
    <String>['Debug', 'Release', 'Profile'],
    schemes,
    logger,
  );

  @override
  Directory hostAppRoot;

  @override
  FakeFlutterProject parent;

  @override
  Directory get xcodeProject => hostAppRoot.childDirectory('$hostAppProjectName.xcodeproj');

  @override
  File get xcodeProjectInfoFile => xcodeProject.childFile('project.pbxproj');

  @override
  late Directory? xcodeWorkspace = hostAppRoot.childDirectory('$hostAppProjectName.xcworkspace');

  @override
  String hostAppProjectName = 'Runner';

  @override
  Directory get flutterPluginSwiftPackageDirectory => hostAppRoot
      .childDirectory('Flutter')
      .childDirectory('ephemeral')
      .childDirectory('Packages')
      .childDirectory('FlutterGeneratedPluginSwiftPackage');

  @override
  File get flutterPluginSwiftPackageManifest =>
      flutterPluginSwiftPackageDirectory.childFile('Package.swift');

  @override
  bool get flutterPluginSwiftPackageInProjectSettings {
    if (!xcodeProjectInfoFile.existsSync()) {
      return false;
    }

    return xcodeProjectInfoFile.readAsStringSync().contains(
      '78A318202AECB46A00862997 /* FlutterGeneratedPluginSwiftPackage in Frameworks */ = {isa = PBXBuildFile',
    );
  }

  @override
  Future<XcodeProjectInfo?> projectInfo() async {
    return _projectInfo;
  }

  @override
  File xcodeProjectSchemeFile({String? scheme}) {
    final String schemeName = scheme ?? 'Runner';
    return xcodeProject
        .childDirectory('xcshareddata')
        .childDirectory('xcschemes')
        .childFile('$schemeName.xcscheme');
  }
}

class FakeFlutterProject extends Fake implements FlutterProject {
  FakeFlutterProject({required MemoryFileSystem fileSystem})
    : directory = fileSystem.directory('app_name');

  @override
  Directory directory;
}

class FakeSwiftPackageManagerIntegrationMigration extends SwiftPackageManagerIntegrationMigration {
  FakeSwiftPackageManagerIntegrationMigration(
    super.project,
    super.platform,
    super.buildInfo, {
    required super.xcodeProjectInterpreter,
    required super.logger,
    required super.fileSystem,
    required super.plistParser,
    required super.features,
    this.validateBackup = false,
  }) : _xcodeProject = project;

  final XcodeBasedProject _xcodeProject;

  final bool validateBackup;
  @override
  void restoreFromBackup(SchemeInfo? schemeInfo) {
    if (validateBackup) {
      expect(backupProjectSettings.existsSync(), isTrue);
      final String originalSettings = backupProjectSettings.readAsStringSync();
      expect(_xcodeProject.xcodeProjectInfoFile.readAsStringSync() == originalSettings, isFalse);

      expect(schemeInfo?.backupSchemeFile, isNotNull);
      final File backupScheme = schemeInfo!.backupSchemeFile!;
      expect(backupScheme.existsSync(), isTrue);
      final String originalScheme = backupScheme.readAsStringSync();
      expect(_xcodeProject.xcodeProjectSchemeFile().readAsStringSync() == originalScheme, isFalse);

      super.restoreFromBackup(schemeInfo);
      expect(_xcodeProject.xcodeProjectInfoFile.readAsStringSync(), originalSettings);
      expect(_xcodeProject.xcodeProjectSchemeFile().readAsStringSync(), originalScheme);
    } else {
      super.restoreFromBackup(schemeInfo);
    }
  }
}
