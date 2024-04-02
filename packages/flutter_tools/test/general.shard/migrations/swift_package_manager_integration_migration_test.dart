// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/migrations/swift_package_manager_integration_migration.dart';

import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

const List<SupportedPlatform> supportedPlatforms = <SupportedPlatform>[
  SupportedPlatform.ios,
  SupportedPlatform.macos
];

void main() {
  group('Flutter Package Migration', () {
    testWithoutContext('fails if Xcode project not found', () {
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
      final BufferLogger testLogger = BufferLogger.test();

      final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
        FakeIosProject(fileSystem: memoryFileSystem),
        SupportedPlatform.ios,
        xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
        logger: testLogger,
        fileSystem: memoryFileSystem,
        plistParser: FakePlistParser(),
      );
      expect(() => projectMigration.migrate(), throwsToolExit(message: 'Xcode project not found.'));
      expect(testLogger.traceText, isEmpty);
      expect(testLogger.statusText, isEmpty);
    });

    group('migrate gitignore', () {
      testWithoutContext('skipped with warning if no files to update', () {
        final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
        final BufferLogger testLogger = BufferLogger.test();
        final FakeIosProject project = FakeIosProject(
          fileSystem: memoryFileSystem,
        );
        _createProjectFiles(project);

        final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
          project,
          SupportedPlatform.ios,
          xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
          logger: testLogger,
          fileSystem: memoryFileSystem,
          plistParser: FakePlistParser(),
        );
        expect(() => projectMigration.migrate(), throwsToolExit());
        expect(
          testLogger.traceText.contains('Adding FlutterGeneratedPluginSwiftPackage to app_name/.gitignore'),
          isFalse,
        );
        expect(
          testLogger.traceText.contains('Adding FlutterGeneratedPluginSwiftPackage to app_name/ios/.gitignore'),
          isFalse,
        );
        expect(
          testLogger.warningText.contains(
            'Unable to find .gitignore. Please add the following line to your .gitignore:\n'
            '  **/Flutter/Packages/ephemeral',
          ),
          isTrue,
        );
      });

      testWithoutContext('skipped if already updated', () {
        final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
        final BufferLogger testLogger = BufferLogger.test();
        final FakeIosProject project = FakeIosProject(
          fileSystem: memoryFileSystem,
        );
        _createProjectFiles(project);
        project.parent.directory.childFile('.gitignore')
            .writeAsStringSync(SwiftPackageManagerIntegrationMigration.flutterPackageGitignore);
        project.hostAppRoot.childFile('.gitignore')
            .writeAsStringSync(SwiftPackageManagerIntegrationMigration.flutterPackageGitignore);

        final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
          project,
          SupportedPlatform.ios,
          xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
          logger: testLogger,
          fileSystem: memoryFileSystem,
          plistParser: FakePlistParser(),
        );
        expect(() => projectMigration.migrate(), throwsToolExit());
        expect(
          testLogger.traceText.contains('Adding FlutterGeneratedPluginSwiftPackage to app_name/.gitignore'),
          isFalse,
        );
        expect(
          testLogger.traceText.contains('Adding FlutterGeneratedPluginSwiftPackage to app_name/ios/.gitignore'),
          isFalse,
        );
        expect(testLogger.warningText, isEmpty);
      });

      testWithoutContext('successfully updates platform specific gitignore', () {
        final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
        final BufferLogger testLogger = BufferLogger.test();
        final FakeIosProject project = FakeIosProject(
          fileSystem: memoryFileSystem,
        );
        _createProjectFiles(project);
        project.parent.directory.childFile('.gitignore').writeAsStringSync('''
**/Pods/
**/Flutter/ephemeral/
''');
        project.hostAppRoot.childFile('.gitignore').writeAsStringSync('''
**/Flutter/ephemeral/
''');

        final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
          project,
          SupportedPlatform.ios,
          xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
          logger: testLogger,
          fileSystem: memoryFileSystem,
          plistParser: FakePlistParser(),
        );
        expect(() => projectMigration.migrate(), throwsToolExit());
        expect(
          testLogger.traceText.contains('Adding FlutterGeneratedPluginSwiftPackage to app_name/.gitignore'),
          isFalse,
        );
        expect(
          testLogger.traceText,
          contains('Adding FlutterGeneratedPluginSwiftPackage to app_name/ios/.gitignore'),
        );
        expect(testLogger.warningText, isEmpty);
        expect(project.hostAppRoot.childFile('.gitignore').readAsStringSync(), '''
**/Flutter/ephemeral/

${SwiftPackageManagerIntegrationMigration.flutterPackageGitignore}
''');
      });

      testWithoutContext('successfully updates app gitignore', () {
        final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
        final BufferLogger testLogger = BufferLogger.test();
        final FakeIosProject project = FakeIosProject(
          fileSystem: memoryFileSystem,
        );
        _createProjectFiles(project);
        project.parent.directory.childFile('.gitignore').writeAsStringSync('''
**/Pods/
**/Flutter/ephemeral/
''');

        final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
          project,
          SupportedPlatform.ios,
          xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
          logger: testLogger,
          fileSystem: memoryFileSystem,
          plistParser: FakePlistParser(),
        );
        expect(() => projectMigration.migrate(), throwsToolExit());
        expect(
          testLogger.traceText.contains('Adding FlutterGeneratedPluginSwiftPackage to app_name/ios/.gitignore'),
          isFalse,
        );
        expect(
          testLogger.traceText,
          contains('Adding FlutterGeneratedPluginSwiftPackage to app_name/.gitignore'),
        );
        expect(testLogger.warningText, isEmpty);
        expect(project.parent.directory.childFile('.gitignore').readAsStringSync(),
'''
**/Pods/
**/Flutter/ephemeral/

${SwiftPackageManagerIntegrationMigration.flutterPackageGitignore}
''');
      });
    });

    group('fails if parsing project.pbxproj', () {
      testWithoutContext('fails plutil command', () {
        final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
        final BufferLogger testLogger = BufferLogger.test();
        final FakeIosProject project = FakeIosProject(
          fileSystem: memoryFileSystem,
        );
        _createProjectFiles(project);

        final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
          project,
          SupportedPlatform.ios,
          xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
          logger: testLogger,
          fileSystem: memoryFileSystem,
          plistParser: FakePlistParser(),
        );
        expect(() => projectMigration.migrate(), throwsToolExit(message: 'Failed to parse project settings.'));
      });

      testWithoutContext('returns unexpected JSON', () {
        final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
        final BufferLogger testLogger = BufferLogger.test();
        final FakeIosProject project = FakeIosProject(
          fileSystem: memoryFileSystem,
        );
        _createProjectFiles(project);

        final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
          project,
          SupportedPlatform.ios,
          xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
          logger: testLogger,
          fileSystem: memoryFileSystem,
          plistParser: FakePlistParser(json: '[]'),
        );
        expect(
          () => projectMigration.migrate(),
          throwsToolExit(message: 'project.pbxproj returned unexpected JSON response'),
        );
      });

      testWithoutContext('returns non-JSON', () {
        final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
        final BufferLogger testLogger = BufferLogger.test();
        final FakeIosProject project = FakeIosProject(
          fileSystem: memoryFileSystem,
        );
        _createProjectFiles(project);

        final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
          project,
          SupportedPlatform.ios,
          xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
          logger: testLogger,
          fileSystem: memoryFileSystem,
          plistParser: FakePlistParser(json: 'this is not json'),
        );
        expect(
          () => projectMigration.migrate(),
          throwsToolExit(message: 'project.pbxproj returned non-JSON response'),
        );
      });
    });

    for (final SupportedPlatform platform in supportedPlatforms) {
      group('for ${platform.name}', () {
        testWithoutContext('skip if all settings migrated', () async {
          final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
          final BufferLogger testLogger = BufferLogger.test();
          final FakeIosProject project = FakeIosProject(
            fileSystem: memoryFileSystem,
          );
          _createProjectFiles(project);

          final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
            project,
            platform,
            xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
            logger: testLogger,
            fileSystem: memoryFileSystem,
            plistParser: FakePlistParser(
              json: _plutilOutput(
                <String>[..._allSectionsMigratedAsJson(platform)],
              ),
            ),
          );
          await projectMigration.migrate();
          expect(
            testLogger.statusText.contains('Adding Swift Package Manager integration...'),
            isFalse,
          );
        });

        group('migrate PBXBuildFile', () {
          testWithoutContext('skipped if already updated', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(_allSectionsMigrated(platform)),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            // Must remove at least one so migration is not skipped due to being already migrated
            settingsAsJsonBeforeMigration.removeAt(_swiftPackageProductDependencySectionIndex);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(() => projectMigration.migrate(), throwsToolExit());
            expect(testLogger.traceText, contains('PBXBuildFile already migrated. Skipping...'));
          });

          testWithoutContext('fails if missing Begin PBXBuildFile section', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(<String>[]),
              ),
            );
            expect(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Unable to find beginning of PBXBuildFile section'),
            );
          });

          testWithoutContext('fails if missing End PBXBuildFile section', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform)
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
            settingsAsJsonBeforeMigration[_buildFileSectionIndex] = unmigratedBuildFileSectionAsJson;

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(<String>[]),
              ),
            );
            expect(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Unable to find end of PBXBuildFile section'),
            );
          });

          testWithoutContext('fails if End before Begin for PBXBuildFile section', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
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
            settingsAsJsonBeforeMigration[_buildFileSectionIndex] = unmigratedBuildFileSectionAsJson;

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(<String>[]),
              ),
            );
            expect(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Found the end of PBXBuildFile section before the beginning.'),
            );
          });

          testWithoutContext('successfully added', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_buildFileSectionIndex] = unmigratedBuildFileSection;
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration[_buildFileSectionIndex] = unmigratedBuildFileSectionAsJson;

            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(settingsAsJsonBeforeMigration),
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
            ]);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: plistParser,
            );
            await projectMigration.migrate();
            expect(testLogger.errorText, isEmpty);
            expect(
              testLogger.traceText.contains('PBXBuildFile already migrated. Skipping...'),
              isFalse,
            );
            expect(
              project.xcodeProjectInfoFile.readAsStringSync(),
              _projectSettings(_allSectionsMigrated(platform)),
            );
            expect(plistParser.hasRemainingExpectations, isFalse);
          });
        });

        group('migrate PBXFileReference', () {
          testWithoutContext('skipped if already updated', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(_allSectionsMigrated(platform)),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            // Must remove at least one so migration is not skipped due to being already migrated
            settingsAsJsonBeforeMigration.removeAt(_swiftPackageProductDependencySectionIndex);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(() => projectMigration.migrate(), throwsToolExit());
            expect(
              testLogger.traceText,
              contains('PBXFileReference already migrated. Skipping...'),
            );
          });

          testWithoutContext('fails if missing PBXFileReference section', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration.removeAt(_fileReferenceSectionIndex);
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration.removeAt(_fileReferenceSectionIndex);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Unable to find beginning of PBXFileReference section'),
            );
          });

          testWithoutContext('successfully added', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_fileReferenceSectionIndex] = unmigratedFileReferenceSection;
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration[_fileReferenceSectionIndex] = unmigratedFileReferenceSectionAsJson;

            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(settingsAsJsonBeforeMigration),
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
            ]);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: plistParser,
            );
            await projectMigration.migrate();
            expect(testLogger.errorText, isEmpty);
            expect(
              testLogger.traceText.contains('PBXFileReference already migrated. Skipping...'),
              isFalse,
            );
            expect(
              project.xcodeProjectInfoFile.readAsStringSync(),
              _projectSettings(_allSectionsMigrated(platform)),
            );
            expect(plistParser.hasRemainingExpectations, isFalse);
          });
        });

        group('migrate PBXFrameworksBuildPhase', () {
          testWithoutContext('skipped if already updated', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(_allSectionsMigrated(platform)),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            // Must remove at least one so migration is not skipped due to being already migrated
            settingsAsJsonBeforeMigration.removeAt(_swiftPackageProductDependencySectionIndex);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(() => projectMigration.migrate(), throwsToolExit());
            expect(
              testLogger.traceText,
              contains('PBXFrameworksBuildPhase already migrated. Skipping...'),
            );
          });

          testWithoutContext('fails if missing PBXFrameworksBuildPhase section', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration.removeAt(_frameworksBuildPhaseSectionIndex);
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration.removeAt(_frameworksBuildPhaseSectionIndex);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Unable to find beginning of PBXFrameworksBuildPhase section'),
            );
          });

          testWithoutContext('fails if missing Runner target subsection following PBXFrameworksBuildPhase begin header', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
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

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Unable to find PBXFrameworksBuildPhase for Runner target'),
            );
          });

          testWithoutContext('fails if missing Runner target subsection before PBXFrameworksBuildPhase end header', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_frameworksBuildPhaseSectionIndex] = '''
/* Begin PBXFrameworksBuildPhase section */
/* End PBXFrameworksBuildPhase section */
/* Begin NonExistant section */
    ${_runnerFrameworksBuildPhaseIdentifer(platform)} /* Frameworks */ = {
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

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Unable to find PBXFrameworksBuildPhase for Runner target'),
            );
          });

          testWithoutContext(
              'fails if missing Runner target in parsed settings', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_frameworksBuildPhaseSectionIndex] = unmigratedFrameworksBuildPhaseSection(platform);
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration.removeAt(_frameworksBuildPhaseSectionIndex);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Unable to find parsed PBXFrameworksBuildPhase for Runner target'),
            );
          });

          testWithoutContext('successfully added when files field is missing', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_frameworksBuildPhaseSectionIndex] = unmigratedFrameworksBuildPhaseSection(
              platform,
              missingFiles: true,
            );
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration[_frameworksBuildPhaseSectionIndex] = unmigratedFrameworksBuildPhaseSectionAsJson(
              platform,
              missingFiles: true,
            );
            final List<String> expectedSettings = <String>[
              ..._allSectionsMigrated(platform),
            ];
            expectedSettings[_frameworksBuildPhaseSectionIndex] = migratedFrameworksBuildPhaseSection(
              platform,
              missingFiles: true,
            );

            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(settingsAsJsonBeforeMigration),
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
            ]);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: plistParser,
            );
            await projectMigration.migrate();
            expect(testLogger.errorText, isEmpty);
            expect(
              testLogger.traceText.contains('PBXFrameworksBuildPhase already migrated. Skipping...'),
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
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_frameworksBuildPhaseSectionIndex] = unmigratedFrameworksBuildPhaseSection(
              platform,
            );
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration[_frameworksBuildPhaseSectionIndex] = unmigratedFrameworksBuildPhaseSectionAsJson(
              platform,
            );

            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(settingsAsJsonBeforeMigration),
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
            ]);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: plistParser,
            );
            await projectMigration.migrate();
            expect(testLogger.errorText, isEmpty);
            expect(
              testLogger.traceText.contains('PBXFrameworksBuildPhase already migrated. Skipping...'),
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
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_frameworksBuildPhaseSectionIndex] = unmigratedFrameworksBuildPhaseSection(
              platform,
              withCocoapods: true,
            );
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration[_frameworksBuildPhaseSectionIndex] = unmigratedFrameworksBuildPhaseSectionAsJson(
              platform,
              withCocoapods: true,
            );
            final List<String> expectedSettings = <String>[
              ..._allSectionsMigrated(platform),
            ];
            expectedSettings[_frameworksBuildPhaseSectionIndex] = migratedFrameworksBuildPhaseSection(
              platform,
              withCocoapods: true,
            );

            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(settingsAsJsonBeforeMigration),
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
            ]);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: plistParser,
            );
            await projectMigration.migrate();
            expect(testLogger.errorText, isEmpty);
            expect(
              testLogger.traceText.contains('PBXFrameworksBuildPhase already migrated. Skipping...'),
              isFalse,
            );
            expect(
              project.xcodeProjectInfoFile.readAsStringSync(),
              _projectSettings(expectedSettings),
            );
            expect(plistParser.hasRemainingExpectations, isFalse);
          });
        });

        group('migrate PBXGroup', () {
          testWithoutContext('skipped if Packages and Flutter groups already updated', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(_allSectionsMigrated(platform)),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            // Must remove at least one so migration is not skipped due to being already migrated
            settingsAsJsonBeforeMigration.removeAt(_swiftPackageProductDependencySectionIndex);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(() => projectMigration.migrate(), throwsToolExit());
            expect(
              testLogger.traceText,
              contains('PBXGroup already migrated. Skipping...'),
            );
          });

          testWithoutContext('fails if missing PBXGroup section', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration.removeAt(_groupSectionIndex);
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration.removeAt(_groupSectionIndex);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Unable to find beginning of PBXGroup section'),
            );
          });

          testWithoutContext('fails if missing Flutter PBXGroup in parsed settings', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_groupSectionIndex] = unmigratedGroupSection(platform);
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration.removeAt(_groupSectionIndex);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Unable to find parsed Flutter PBXGroup'),
            );
          });

          testWithoutContext('fails if missing Flutter group subsection following PBXGroup begin header', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_groupSectionIndex] = '''
/* Begin PBXGroup section */
/* End PBXGroup section */
''';
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration[_groupSectionIndex] =
                unmigratedGroupSectionAsJson(platform);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Unable to find Flutter PBXGroup'),
            );
          });

          testWithoutContext('fails if missing Flutter group subsection before PBXGroup end header', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_groupSectionIndex] = '''
/* Begin PBXGroup section */
/* End PBXGroup section */
/* Begin NonExistant section */
    9740EEB11CF90186004384FC /* Flutter */ = {
    };
/* End NonExistant section */
''';
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration[_groupSectionIndex] =
                unmigratedGroupSectionAsJson(platform);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );

            expect(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Unable to find Flutter PBXGroup'),
            );
          });

          testWithoutContext('successfully added when Packages group is missing', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_groupSectionIndex] = unmigratedGroupSection(
              platform,
              packagesGroupExists: false,
            );
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration[_groupSectionIndex] = unmigratedGroupSectionAsJson(
              platform,
              packagesGroupExists: false,
            );
            final List<String> expectedSettings = <String>[
              ..._allSectionsMigrated(platform),
            ];
            expectedSettings[_groupSectionIndex] = migratedGroupSection(
              platform,
              packagesGroupExists: false,
            );

            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(settingsAsJsonBeforeMigration),
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
            ]);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: plistParser,
            );
            await projectMigration.migrate();
            expect(testLogger.errorText, isEmpty);
            expect(
              testLogger.traceText.contains('PBXGroup already migrated. Skipping...'),
              isFalse,
            );
            expect(
              testLogger.traceText.contains('Packages PBXGroup already migrated. Skipping...'),
              isFalse,
            );
            expect(
              testLogger.traceText.contains('Flutter PBXGroup already migrated. Skipping...'),
              isFalse,
            );
            expect(
              project.xcodeProjectInfoFile.readAsStringSync(),
              _projectSettings(expectedSettings),
            );
            expect(plistParser.hasRemainingExpectations, isFalse);
          });

          testWithoutContext('successfully added when Packages group already exists', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_groupSectionIndex] = unmigratedGroupSection(platform);
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration[_groupSectionIndex] = unmigratedGroupSectionAsJson(platform);

            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(settingsAsJsonBeforeMigration),
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
            ]);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: plistParser,
            );
            await projectMigration.migrate();
            expect(testLogger.errorText, isEmpty);
            expect(
              testLogger.traceText.contains('Packages PBXGroup already migrated. Skipping...'),
              isTrue,
            );
            expect(
              testLogger.traceText.contains('Flutter PBXGroup already migrated. Skipping...'),
              isFalse,
            );
            expect(
              project.xcodeProjectInfoFile.readAsStringSync(),
              _projectSettings(_allSectionsMigrated(platform)),
            );
            expect(plistParser.hasRemainingExpectations, isFalse);
          });
        });

        group('migrate PBXNativeTarget', () {
          testWithoutContext('skipped if already updated', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(_allSectionsMigrated(platform)),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            // Must remove at least one so migration is not skipped due to being already migrated
            settingsAsJsonBeforeMigration.removeAt(_swiftPackageProductDependencySectionIndex);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(() => projectMigration.migrate(), throwsToolExit());
            expect(
              testLogger.traceText,
              contains('PBXNativeTarget already migrated. Skipping...'),
            );
          });

          testWithoutContext('fails if missing PBXNativeTarget section', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration.removeAt(_nativeTargetSectionIndex);
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration.removeAt(_nativeTargetSectionIndex);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Unable to find beginning of PBXNativeTarget section'),
            );
          });

          testWithoutContext('fails if missing Runner target in parsed settings', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_nativeTargetSectionIndex] = unmigratedNativeTargetSection(platform);
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration.removeAt(_nativeTargetSectionIndex);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Unable to find parsed PBXNativeTarget for Runner target'),
            );
          });

          testWithoutContext('fails if missing Runner target subsection following PBXNativeTarget begin header', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_nativeTargetSectionIndex] = '''
/* Begin PBXNativeTarget section */
/* End PBXNativeTarget section */
''';
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration[_nativeTargetSectionIndex] = unmigratedNativeTargetSectionAsJson(platform);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Unable to find PBXNativeTarget for Runner target'),
            );
          });

          testWithoutContext('fails if missing Runner target subsection before PBXNativeTarget end header', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_nativeTargetSectionIndex] = '''
/* Begin PBXNativeTarget section */
/* End PBXNativeTarget section */
/* Begin NonExistant section */
    ${_runnerNativeTargetIdentifer(platform)} /* Runner */ = {
    };
/* End NonExistant section */
''';
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration[_nativeTargetSectionIndex] = unmigratedNativeTargetSectionAsJson(platform);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Unable to find PBXNativeTarget for Runner target'),
            );
          });

          testWithoutContext('successfully added when packageProductDependencies field is missing', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_nativeTargetSectionIndex] = unmigratedNativeTargetSection(
              platform,
              missingPackageProductDependencies: true,
            );
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration[_nativeTargetSectionIndex] = unmigratedNativeTargetSectionAsJson(
              platform,
              missingPackageProductDependencies: true,
            );
            final List<String> expectedSettings = <String>[
              ..._allSectionsMigrated(platform),
            ];
            expectedSettings[_nativeTargetSectionIndex] = migratedNativeTargetSection(
              platform,
              missingPackageProductDependencies: true,
            );

            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(settingsAsJsonBeforeMigration),
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
            ]);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: plistParser,
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
          });

          testWithoutContext('successfully added when packageProductDependencies field is empty', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_nativeTargetSectionIndex] = unmigratedNativeTargetSection(platform);
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration[_nativeTargetSectionIndex] = unmigratedNativeTargetSectionAsJson(platform);

            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(settingsAsJsonBeforeMigration),
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
            ]);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: plistParser,
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
          });

          testWithoutContext('successfully added when packageProductDependencies field is not empty', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_nativeTargetSectionIndex] = unmigratedNativeTargetSection(
              platform,
              withOtherDependency: true,
            );
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration[_nativeTargetSectionIndex] = unmigratedNativeTargetSectionAsJson(platform);
            final List<String> expectedSettings = <String>[
              ..._allSectionsMigrated(platform),
            ];
            expectedSettings[_nativeTargetSectionIndex] = migratedNativeTargetSection(
              platform,
              withOtherDependency: true,
            );

            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(settingsAsJsonBeforeMigration),
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
            ]);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: plistParser,
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
          });
        });

        group('migrate PBXProject', () {
          testWithoutContext('skipped if already updated', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(_allSectionsMigrated(platform)),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            // Must remove at least one so migration is not skipped due to being already migrated
            settingsAsJsonBeforeMigration.removeAt(_swiftPackageProductDependencySectionIndex);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(() => projectMigration.migrate(), throwsToolExit());
            expect(
              testLogger.traceText,
              contains('PBXProject already migrated. Skipping...'),
            );
          });

          testWithoutContext('fails if missing PBXProject section', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration.removeAt(_projectSectionIndex);
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration.removeAt(_projectSectionIndex);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Unable to find beginning of PBXProject section'),
            );
          });

          testWithoutContext('fails if missing Runner project subsection following PBXProject begin header', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_projectSectionIndex] = '''
/* Begin PBXProject section */
/* End PBXProject section */
''';
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );

            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration.removeAt(_projectSectionIndex);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Unable to find PBXProject for Runner'),
            );
          });

          testWithoutContext('fails if missing Runner project subsection before PBXProject end header', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
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
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration.removeAt(_projectSectionIndex);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Unable to find PBXProject for Runner'),
            );
          });

          testWithoutContext('fails if missing Runner project in parsed settings', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_projectSectionIndex] = unmigratedProjectSection(platform);
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration.removeAt(_projectSectionIndex);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Unable to find parsed PBXProject for Runner'),
            );
          });

          testWithoutContext('successfully added when packageReferences field is missing', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_projectSectionIndex] = unmigratedProjectSection(
              platform,
              missingPackageReferences: true,
            );
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );

            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration[_projectSectionIndex] = unmigratedProjectSectionAsJson(
              platform,
              missingPackageReferences: true,
            );

            final List<String> expectedSettings = <String>[
              ..._allSectionsMigrated(platform),
            ];
            expectedSettings[_projectSectionIndex] = migratedProjectSection(
              platform,
              missingPackageReferences: true,
            );

            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(settingsAsJsonBeforeMigration),
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
            ]);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: plistParser,
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
          });

          testWithoutContext('successfully added when packageReferences field is empty', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_projectSectionIndex] = unmigratedProjectSection(platform);
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration[_projectSectionIndex] = unmigratedProjectSectionAsJson(platform);

            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(settingsAsJsonBeforeMigration),
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
            ]);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: plistParser,
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
          });

          testWithoutContext('successfully added when packageReferences field is not empty', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_projectSectionIndex] = unmigratedProjectSection(
              platform,
              withOtherReference: true,
            );
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration[_projectSectionIndex] = unmigratedProjectSectionAsJson(platform);
            final List<String> expectedSettings = <String>[
              ..._allSectionsMigrated(platform),
            ];
            expectedSettings[_projectSectionIndex] = migratedProjectSection(
              platform,
              withOtherReference: true,
            );

            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(settingsAsJsonBeforeMigration),
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
            ]);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: plistParser,
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
          });
        });

        group('migrate XCLocalSwiftPackageReference', () {
          testWithoutContext('skipped if already updated', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(_allSectionsMigrated(platform)),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            // Must remove at least one so migration is not skipped due to being already migrated
            settingsAsJsonBeforeMigration.removeAt(_swiftPackageProductDependencySectionIndex);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(() => projectMigration.migrate(), throwsToolExit());
            expect(
              testLogger.traceText,
              contains('XCLocalSwiftPackageReference already migrated. Skipping...'),
            );
          });

          testWithoutContext('fails if unable to find section to append it after', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration.removeAt(_localSwiftPackageReferenceSectionIndex);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Unable to find any sections'),
            );
          });

          testWithoutContext('successfully added when section is missing', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration.removeAt(_localSwiftPackageReferenceSectionIndex);
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration.removeAt(_localSwiftPackageReferenceSectionIndex);
            final List<String> expectedSettings = <String>[
              ...settingsBeforeMigration,
            ];
            expectedSettings.add(migratedLocalSwiftPackageReferenceSection());

            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(settingsAsJsonBeforeMigration),
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
            ]);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: plistParser,
            );
            await projectMigration.migrate();
            expect(testLogger.errorText, isEmpty);
            expect(
              testLogger.traceText.contains('XCLocalSwiftPackageReference already migrated. Skipping...'),
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
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_localSwiftPackageReferenceSectionIndex] = unmigratedLocalSwiftPackageReferenceSection();
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration.removeAt(_localSwiftPackageReferenceSectionIndex);

            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(settingsAsJsonBeforeMigration),
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
            ]);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: plistParser,
            );
            await projectMigration.migrate();
            expect(testLogger.errorText, isEmpty);
            expect(
              testLogger.traceText.contains('XCLocalSwiftPackageReference already migrated. Skipping...'),
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
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_localSwiftPackageReferenceSectionIndex] = unmigratedLocalSwiftPackageReferenceSection(
              withOtherReference: true,
            );
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration.removeAt(_localSwiftPackageReferenceSectionIndex);
            final List<String> expectedSettings = <String>[
              ..._allSectionsMigrated(platform),
            ];
            expectedSettings[_localSwiftPackageReferenceSectionIndex] = migratedLocalSwiftPackageReferenceSection(
              withOtherReference: true,
            );

            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(settingsAsJsonBeforeMigration),
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
            ]);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: plistParser,
            );
            await projectMigration.migrate();
            expect(testLogger.errorText, isEmpty);
            expect(
              testLogger.traceText.contains('XCLocalSwiftPackageReference already migrated. Skipping...'),
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
          testWithoutContext('skipped if already updated', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(_allSectionsMigrated(platform)),
            );

            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration.removeAt(_buildFileSectionIndex);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(() => projectMigration.migrate(), throwsToolExit());
            expect(
              testLogger.traceText,
              contains('XCSwiftPackageProductDependency already migrated. Skipping...'),
            );
          });

          testWithoutContext('fails if unable to find section to append it after', () {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration.removeAt(_swiftPackageProductDependencySectionIndex);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: FakePlistParser(
                json: _plutilOutput(settingsAsJsonBeforeMigration),
              ),
            );
            expect(
              () => projectMigration.migrate(),
              throwsToolExit(message: 'Unable to find any sections'),
            );
          });

          testWithoutContext('successfully added when section is missing', () async {
            final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
            final BufferLogger testLogger = BufferLogger.test();
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration.removeAt(_swiftPackageProductDependencySectionIndex);
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration.removeAt(_swiftPackageProductDependencySectionIndex);

            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(settingsAsJsonBeforeMigration),
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
            ]);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: plistParser,
            );
            await projectMigration.migrate();
            expect(testLogger.errorText, isEmpty);
            expect(
              testLogger.traceText.contains('XCSwiftPackageProductDependency already migrated. Skipping...'),
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
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_swiftPackageProductDependencySectionIndex] = unmigratedSwiftPackageProductDependencySection();
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration.removeAt(_swiftPackageProductDependencySectionIndex);

            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(settingsAsJsonBeforeMigration),
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
            ]);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: plistParser,
            );
            await projectMigration.migrate();
            expect(testLogger.errorText, isEmpty);
            expect(
              testLogger.traceText.contains('XCSwiftPackageProductDependency already migrated. Skipping...'),
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
            final FakeIosProject project = FakeIosProject(
              fileSystem: memoryFileSystem,
            );
            _createProjectFiles(project);

            final List<String> settingsBeforeMigration = <String>[
              ..._allSectionsMigrated(platform),
            ];
            settingsBeforeMigration[_swiftPackageProductDependencySectionIndex] = unmigratedSwiftPackageProductDependencySection(
              withOtherDependency: true,
            );
            project.xcodeProjectInfoFile.writeAsStringSync(
              _projectSettings(settingsBeforeMigration),
            );
            final List<String> settingsAsJsonBeforeMigration = <String>[
              ..._allSectionsMigratedAsJson(platform),
            ];
            settingsAsJsonBeforeMigration.removeAt(_swiftPackageProductDependencySectionIndex);
            final List<String> expectedSettings = <String>[
              ..._allSectionsMigrated(platform),
            ];
            expectedSettings[_swiftPackageProductDependencySectionIndex] = migratedSwiftPackageProductDependencySection(
              withOtherDependency: true,
            );

            final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
              _plutilOutput(settingsAsJsonBeforeMigration),
              _plutilOutput(_allSectionsMigratedAsJson(platform)),
            ]);

            final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
              project,
              platform,
              xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
              logger: testLogger,
              fileSystem: memoryFileSystem,
              plistParser: plistParser,
            );
            await projectMigration.migrate();
            expect(testLogger.errorText, isEmpty);
            expect(
              testLogger.traceText.contains('XCSwiftPackageProductDependency already migrated. Skipping...'),
              isFalse,
            );
            expect(
              project.xcodeProjectInfoFile.readAsStringSync(),
              _projectSettings(expectedSettings),
            );
            expect(plistParser.hasRemainingExpectations, isFalse);
          });
        });

        testWithoutContext('throw if settings not updated correctly', () {
          final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
          final BufferLogger testLogger = BufferLogger.test();
          final FakeIosProject project = FakeIosProject(
            fileSystem: memoryFileSystem,
          );
          _createProjectFiles(project);
          project.xcodeProjectInfoFile.writeAsStringSync(
            _projectSettings(_allSectionsMigrated(platform)),
          );

          final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
            _plutilOutput(allSectionsUnmigratedAsJson(platform)),
            _plutilOutput(allSectionsUnmigratedAsJson(platform)),
          ]);

          final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
            project,
            platform,
            xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
            logger: testLogger,
            fileSystem: memoryFileSystem,
            plistParser: plistParser,
          );
          expect(
            () => projectMigration.migrate(),
            throwsToolExit(message: 'Settings were not updated correctly.'),
          );
          expect(
            testLogger.errorText,
            contains('PBXBuildFile was not migrated or was migrated incorrectly.'),
          );
          expect(
            testLogger.errorText,
            contains('PBXFileReference was not migrated or was migrated incorrectly.'),
          );
          expect(
            testLogger.errorText,
            contains('PBXFrameworksBuildPhase was not migrated or was migrated incorrectly.'),
          );
          expect(
            testLogger.errorText,
            contains('Packages PBXGroup was not migrated or was migrated incorrectly.'),
          );
          expect(
            testLogger.errorText,
            contains('Flutter PBXGroup was not migrated or was migrated incorrectly.'),
          );
          expect(
            testLogger.errorText,
            contains('PBXNativeTarget was not migrated or was migrated incorrectly.'),
          );
          expect(
            testLogger.errorText,
            contains('PBXProject was not migrated or was migrated incorrectly.'),
          );
          expect(
            testLogger.errorText,
            contains('XCLocalSwiftPackageReference was not migrated or was migrated incorrectly.'),
          );
          expect(
            testLogger.errorText,
            contains('XCSwiftPackageProductDependency was not migrated or was migrated incorrectly.'),
          );
        });

        testWithoutContext('throw if settings fail to compile', () async {
          final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
          final BufferLogger testLogger = BufferLogger.test();
          final FakeIosProject project = FakeIosProject(
            fileSystem: memoryFileSystem,
          );
          _createProjectFiles(project);
          project.xcodeProjectInfoFile.writeAsStringSync(
            _projectSettings(_allSectionsMigrated(platform)),
          );

          final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
            _plutilOutput(allSectionsUnmigratedAsJson(platform)),
            _plutilOutput(_allSectionsMigratedAsJson(platform)),
          ]);

          final SwiftPackageManagerIntegrationMigration projectMigration = SwiftPackageManagerIntegrationMigration(
            project,
            platform,
            xcodeProjectInterpreter: FakeXcodeProjectInterpreter(
              throwErrorOnGetInfo: true,
            ),
            logger: testLogger,
            fileSystem: memoryFileSystem,
            plistParser: plistParser,
          );
          expect(
            () => projectMigration.migrate(),
            throwsToolExit(message: 'Unable to get Xcode project information'),
          );
        });

        testWithoutContext('restore project settings from backup on failure', () async {
          final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
          final BufferLogger testLogger = BufferLogger.test();
          final FakeIosProject project = FakeIosProject(
            fileSystem: memoryFileSystem,
          );
          _createProjectFiles(project);

          final String originalProjectInfo =
            _projectSettings(_allSectionsMigrated(platform),
          );
          project.xcodeProjectInfoFile.writeAsStringSync(originalProjectInfo);

          final FakePlistParser plistParser = FakePlistParser.multiple(<String>[
            _plutilOutput(allSectionsUnmigratedAsJson(platform)),
            _plutilOutput(_allSectionsMigratedAsJson(platform)),
          ]);

          final FakeSwiftPackageManagerIntegrationMigration projectMigration = FakeSwiftPackageManagerIntegrationMigration(
            project,
            platform,
            xcodeProjectInterpreter: FakeXcodeProjectInterpreter(
              throwErrorOnGetInfo: true,
            ),
            logger: testLogger,
            fileSystem: memoryFileSystem,
            plistParser: plistParser,
            validateBackup: true,
          );
          await expectLater(
            () async => projectMigration.migrate(),
            throwsToolExit(),
          );
          expect(
            testLogger.traceText,
            contains('Restoring project settings from backup file...'),
          );
          expect(
            project.xcodeProjectInfoFile.readAsStringSync(),
            originalProjectInfo,
          );
        });
      });
    }
  });
}

void _createProjectFiles(FakeIosProject project) {
  project.parent.directory.createSync(recursive: true);
  project.hostAppRoot.createSync(recursive: true);
  project.xcodeProjectInfoFile.createSync(recursive: true);
}

const int _buildFileSectionIndex = 0;
const int _fileReferenceSectionIndex = 1;
const int _frameworksBuildPhaseSectionIndex = 2;
const int _groupSectionIndex = 3;
const int _nativeTargetSectionIndex = 4;
const int _projectSectionIndex = 5;
const int _localSwiftPackageReferenceSectionIndex = 6;
const int _swiftPackageProductDependencySectionIndex = 7;

List<String> _allSectionsMigrated(SupportedPlatform platform) {
  return <String>[
    migratedBuildFileSection,
    migratedFileReferenceSection(platform),
    migratedFrameworksBuildPhaseSection(platform),
    migratedGroupSection(platform),
    migratedNativeTargetSection(platform),
    migratedProjectSection(platform),
    migratedLocalSwiftPackageReferenceSection(),
    migratedSwiftPackageProductDependencySection(),
  ];
}

List<String> _allSectionsMigratedAsJson(SupportedPlatform platform) {
  return <String>[
    migratedBuildFileSectionAsJson,
    migratedFileReferenceSectionAsJson(platform),
    migratedFrameworksBuildPhaseSectionAsJson(platform),
    migratedGroupSectionAsJson(platform),
    migratedNativeTargetSectionAsJson(platform),
    migratedProjectSectionAsJson(platform),
    migratedLocalSwiftPackageReferenceSectionAsJson,
    migratedSwiftPackageProductDependencySectionAsJson,
  ];
}

List<String> allSectionsUnmigratedAsJson(SupportedPlatform platform) {
  return <String>[
    unmigratedBuildFileSectionAsJson,
    unmigratedFileReferenceSectionAsJson,
    unmigratedFrameworksBuildPhaseSectionAsJson(platform),
    unmigratedGroupSectionAsJson(platform, packagesGroupExists: false),
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

String _runnerFrameworksBuildPhaseIdentifer(SupportedPlatform platform) {
  return platform == SupportedPlatform.ios
      ? '97C146EB1CF9000F007C117D'
      : '33CC10EA2044A3C60003C045';
}

String _flutterGroupIdentifier(SupportedPlatform platform) {
  return platform == SupportedPlatform.ios
      ? '9740EEB11CF90186004384FC'
      : '33CEB47122A05771004F2AC0';
}

String _runnerNativeTargetIdentifer(SupportedPlatform platform) {
  return platform == SupportedPlatform.ios
      ? '97C146ED1CF9000F007C117D'
      : '33CC10EC2044A3C60003C045';
}

String _projectIdentifier(SupportedPlatform platform) {
  return platform == SupportedPlatform.ios
      ? '97C146E61CF9000F007C117D'
      : '33CC10E52044A3C60003C045';
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

// PBXFileReference
const String unmigratedFileReferenceSection = '''
/* Begin PBXFileReference section */
		74858FAE1ED2DC5600515810 /* AppDelegate.swift */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = AppDelegate.swift; sourceTree = "<group>"; };
		7AFA3C8E1D35360C0083082E /* Release.xcconfig */ = {isa = PBXFileReference; lastKnownFileType = text.xcconfig; name = Release.xcconfig; path = Flutter/Release.xcconfig; sourceTree = "<group>"; };
/* End PBXFileReference section */
''';
String migratedFileReferenceSection(SupportedPlatform platform) {
  final String packagePath = (platform == SupportedPlatform.ios)
      ? 'Flutter/Packages/ephemeral/FlutterGeneratedPluginSwiftPackage'
      : 'Packages/ephemeral/FlutterGeneratedPluginSwiftPackage';
  return '''
/* Begin PBXFileReference section */
		74858FAE1ED2DC5600515810 /* AppDelegate.swift */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = AppDelegate.swift; sourceTree = "<group>"; };
		7AFA3C8E1D35360C0083082E /* Release.xcconfig */ = {isa = PBXFileReference; lastKnownFileType = text.xcconfig; name = Release.xcconfig; path = Flutter/Release.xcconfig; sourceTree = "<group>"; };
		78A3181E2AECB45400862997 /* FlutterGeneratedPluginSwiftPackage */ = {isa = PBXFileReference; lastKnownFileType = wrapper; name = FlutterGeneratedPluginSwiftPackage; path = $packagePath; sourceTree = "<group>"; };
/* End PBXFileReference section */
''';
}

String migratedFileReferenceSectionAsJson(SupportedPlatform platform) {
  final String packagePath = (platform == SupportedPlatform.ios)
      ? 'Flutter/Packages/ephemeral/FlutterGeneratedPluginSwiftPackage'
      : 'Packages/ephemeral/FlutterGeneratedPluginSwiftPackage';
  return '''
    "7AFA3C8E1D35360C0083082E" : {
      "isa" : "PBXFileReference",
      "lastKnownFileType" : "text.xcconfig",
      "name" : "Release.xcconfig",
      "path" : "Flutter/Release.xcconfig",
      "sourceTree" : "<group>"
    },
    "78A3181E2AECB45400862997" : {
      "isa" : "PBXFileReference",
      "lastKnownFileType" : "wrapper",
      "name" : "FlutterGeneratedPluginSwiftPackage",
      "path" : "$packagePath",
      "sourceTree" : "<group>"
    },
    "74858FAE1ED2DC5600515810" : {
      "fileEncoding" : "4",
      "isa" : "PBXFileReference",
      "lastKnownFileType" : "sourcecode.swift",
      "path" : "AppDelegate.swift",
      "sourceTree" : "<group>"
    }''';
}

const String unmigratedFileReferenceSectionAsJson = '''
    "7AFA3C8E1D35360C0083082E" : {
      "isa" : "PBXFileReference",
      "lastKnownFileType" : "text.xcconfig",
      "name" : "Release.xcconfig",
      "path" : "Flutter/Release.xcconfig",
      "sourceTree" : "<group>"
    },
    "74858FAE1ED2DC5600515810" : {
      "fileEncoding" : "4",
      "isa" : "PBXFileReference",
      "lastKnownFileType" : "sourcecode.swift",
      "path" : "AppDelegate.swift",
      "sourceTree" : "<group>"
    }''';

// PBXFrameworksBuildPhase
String unmigratedFrameworksBuildPhaseSection(
  SupportedPlatform platform, {
  bool withCocoapods = false,
  bool missingFiles = false,
}) {
  return <String>[
    '/* Begin PBXFrameworksBuildPhase section */',
    '		${_runnerFrameworksBuildPhaseIdentifer(platform)} /* Frameworks */ = {',
    '			isa = PBXFrameworksBuildPhase;',
    '			buildActionMask = 2147483647;',
    if (!missingFiles) ...<String>[
      '			files = (',
      if (withCocoapods)
        '				FD5BB45FB410D26C457F3823 /* Pods_Runner.framework in Frameworks */,',
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
    if (withCocoapods)
      '				FD5BB45FB410D26C457F3823 /* Pods_Runner.framework in Frameworks */,',
    '			);',
  ];
  return <String>[
    '/* Begin PBXFrameworksBuildPhase section */',
    '		${_runnerFrameworksBuildPhaseIdentifer(platform)} /* Frameworks */ = {',
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
    '    "${_runnerFrameworksBuildPhaseIdentifer(platform)}" : {',
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
    "${_runnerFrameworksBuildPhaseIdentifer(platform)}" : {
      "buildActionMask" : "2147483647",
      "files" : [
        "78A318202AECB46A00862997"
      ],
      "isa" : "PBXFrameworksBuildPhase",
      "runOnlyForDeploymentPostprocessing" : "0"
    }''';
}

// PBXGroup
String unmigratedGroupSection(
  SupportedPlatform platform, {
  bool packagesGroupExists = true,
}) {
  final List<String> packagesGroup = <String>[
    '		78A3181D2AECB45400862997 /* Packages */ = {',
    '			isa = PBXGroup;',
    '			children = (',
    '				78A3181E2AECB45400862997 /* FlutterGeneratedPluginSwiftPackage */,',
    '			);',
    '			name = Packages;',
    '			sourceTree = "<group>";',
    '		};',
  ];
  return <String>[
    '/* Begin PBXGroup section */',
    if (packagesGroupExists) ...packagesGroup,
    '		${_flutterGroupIdentifier(platform)} /* Flutter */ = {',
    '			isa = PBXGroup;',
    '			children = (',
    // '				78A3181D2AECB45400862997 /* Packages */,',
    '				3B3967151E833CAA004F5970 /* AppFrameworkInfo.plist */,',
    '				9740EEB21CF90195004384FC /* Debug.xcconfig */,',
    '				7AFA3C8E1D35360C0083082E /* Release.xcconfig */,',
    '				9740EEB31CF90195004384FC /* Generated.xcconfig */,',
    '			);',
    '			name = Flutter;',
    '			sourceTree = "<group>";',
    '		};',
    '/* End PBXGroup section */',
  ].join('\n');
}

String migratedGroupSection(
  SupportedPlatform platform, {
  bool packagesGroupExists = true,
}) {
  final List<String> packagesGroup = <String>[
    '		78A3181D2AECB45400862997 /* Packages */ = {',
    '			isa = PBXGroup;',
    '			children = (',
    '				78A3181E2AECB45400862997 /* FlutterGeneratedPluginSwiftPackage */,',
    '			);',
    '			name = Packages;',
    '			sourceTree = "<group>";',
    '		};',
  ];
  return <String>[
    '/* Begin PBXGroup section */',
    if (packagesGroupExists) ...packagesGroup,
    '		${_flutterGroupIdentifier(platform)} /* Flutter */ = {',
    '			isa = PBXGroup;',
    '			children = (',
    '				78A3181D2AECB45400862997 /* Packages */,',
    '				3B3967151E833CAA004F5970 /* AppFrameworkInfo.plist */,',
    '				9740EEB21CF90195004384FC /* Debug.xcconfig */,',
    '				7AFA3C8E1D35360C0083082E /* Release.xcconfig */,',
    '				9740EEB31CF90195004384FC /* Generated.xcconfig */,',
    '			);',
    '			name = Flutter;',
    '			sourceTree = "<group>";',
    '		};',
    if (!packagesGroupExists) ...packagesGroup,
    '/* End PBXGroup section */',
  ].join('\n');
}

String unmigratedGroupSectionAsJson(
  SupportedPlatform platform, {
  bool packagesGroupExists = true,
}) {
  final List<String> packagesGroup = <String>[
    '    "78A3181D2AECB45400862997" : {',
    '      "children" : [',
    '        "78A3181E2AECB45400862997"',
    '      ],',
    '      "isa" : "PBXGroup",',
    '      "name" : "Packages",',
    '      "sourceTree" : "<group>"',
    '    },',
  ];
  return <String>[
    if (packagesGroupExists) ...packagesGroup,
    '    "${_flutterGroupIdentifier(platform)}" : {',
    '      "children" : [',
    '        "3B3967151E833CAA004F5970",',
    '        "9740EEB21CF90195004384FC",',
    '        "7AFA3C8E1D35360C0083082E",',
    '        "9740EEB31CF90195004384FC"',
    '      ],',
    '      "isa" : "PBXGroup",',
    '      "name" : "Flutter",',
    '      "sourceTree" : "<group>"',
    '    }'
  ].join('\n');
}

String migratedGroupSectionAsJson(SupportedPlatform platform) {
  return '''
    "78A3181D2AECB45400862997" : {
      "children" : [
        "78A3181E2AECB45400862997"
      ],
      "isa" : "PBXGroup",
      "name" : "Packages",
      "sourceTree" : "<group>"
    },
    "${_flutterGroupIdentifier(platform)}" : {
      "children" : [
        "78A3181D2AECB45400862997",
        "3B3967151E833CAA004F5970",
        "9740EEB21CF90195004384FC",
        "7AFA3C8E1D35360C0083082E",
        "9740EEB31CF90195004384FC"
      ],
      "isa" : "PBXGroup",
      "name" : "Flutter",
      "sourceTree" : "<group>"
    }''';
}

// PBXNativeTarget
String unmigratedNativeTargetSection(
  SupportedPlatform platform, {
  bool missingPackageProductDependencies = false,
  bool withOtherDependency = false,
}) {
  return <String>[
    '/* Begin PBXNativeTarget section */',
    '		${_runnerNativeTargetIdentifer(platform)} /* Runner */ = {',
    '			isa = PBXNativeTarget;',
    '			buildConfigurationList = 97C147051CF9000F007C117D /* Build configuration list for PBXNativeTarget "Runner" */;',
    '			buildPhases = (',
    '				9740EEB61CF901F6004384FC /* Run Script */,',
    '				97C146EA1CF9000F007C117D /* Sources */,',
    '				${_runnerFrameworksBuildPhaseIdentifer(platform)} /* Frameworks */,',
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
      if (withOtherDependency)
        '				010101010101010101010101 /* SomeOtherPackage */,',
      '			);',
    ],
    '			productName = Runner;',
    '			productReference = 97C146EE1CF9000F007C117D /* Runner.app */;',
    '			productType = "com.apple.product-type.application";',
    '		};',
    '/* End PBXNativeTarget section */',
  ].join('\n');
}

String migratedNativeTargetSection(
  SupportedPlatform platform, {
  bool missingPackageProductDependencies = false,
  bool withOtherDependency = false,
}) {
  final List<String> packageDependencies = <String>[
    '			packageProductDependencies = (',
    '				78A3181F2AECB46A00862997 /* FlutterGeneratedPluginSwiftPackage */,',
    if (withOtherDependency)
      '				010101010101010101010101 /* SomeOtherPackage */,',
    '			);',
  ];
  return <String>[
    '/* Begin PBXNativeTarget section */',
    '		${_runnerNativeTargetIdentifer(platform)} /* Runner */ = {',
    if (missingPackageProductDependencies) ...packageDependencies,
    '			isa = PBXNativeTarget;',
    '			buildConfigurationList = 97C147051CF9000F007C117D /* Build configuration list for PBXNativeTarget "Runner" */;',
    '			buildPhases = (',
    '				9740EEB61CF901F6004384FC /* Run Script */,',
    '				97C146EA1CF9000F007C117D /* Sources */,',
    '				${_runnerFrameworksBuildPhaseIdentifer(platform)} /* Frameworks */,',
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
    '/* End PBXNativeTarget section */',
  ].join('\n');
}

String unmigratedNativeTargetSectionAsJson(
  SupportedPlatform platform, {
  bool missingPackageProductDependencies = false,
}) {
  return <String>[
    '    "${_runnerNativeTargetIdentifer(platform)}" : {',
    '      "buildConfigurationList" : "97C147051CF9000F007C117D",',
    '      "buildPhases" : [',
    '        "9740EEB61CF901F6004384FC",',
    '        "97C146EA1CF9000F007C117D",',
    '        "${_runnerFrameworksBuildPhaseIdentifer(platform)}",',
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
    "${_runnerNativeTargetIdentifer(platform)}" : {
      "buildConfigurationList" : "97C147051CF9000F007C117D",
      "buildPhases" : [
        "9740EEB61CF901F6004384FC",
        "97C146EA1CF9000F007C117D",
        "${_runnerFrameworksBuildPhaseIdentifer(platform)}",
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
    '						TestTargetID = ${_runnerNativeTargetIdentifer(platform)};',
    '					};',
    '					${_runnerNativeTargetIdentifer(platform)} = {',
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
    '				${_runnerNativeTargetIdentifer(platform)} /* Runner */,',
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
  final List<String> packageDependencies = <String>[
    '			packageReferences = (',
    '				781AD8BC2B33823900A9FFBB /* XCLocalSwiftPackageReference "Flutter/Packages/ephemeral/FlutterGeneratedPluginSwiftPackage" */,',
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
    '						TestTargetID = ${_runnerNativeTargetIdentifer(platform)};',
    '					};',
    '					${_runnerNativeTargetIdentifer(platform)} = {',
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
    '				${_runnerNativeTargetIdentifer(platform)} /* Runner */,',
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
  return <String>[
    '    "${_projectIdentifier(platform)}" : {',
    '      "attributes" : {',
    '        "BuildIndependentTargetsInParallel" : "YES",',
    '        "LastUpgradeCheck" : "1510",',
    '        "ORGANIZATIONNAME" : "",',
    '        "TargetAttributes" : {',
    '          "${_runnerNativeTargetIdentifer(platform)}" : {',
    '            "CreatedOnToolsVersion" : "7.3.1",',
    '            "LastSwiftMigration" : "1100"',
    '          },',
    '          "331C8080294A63A400263BE5" : {',
    '            "CreatedOnToolsVersion" : "14.0",',
    '            "TestTargetID" : "${_runnerNativeTargetIdentifer(platform)}"',
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
    if (!missingPackageReferences) ...<String>[
      '      "packageReferences" : [',
      '      ],',
    ],
    '      "productRefGroup" : "97C146EF1CF9000F007C117D",',
    '      "projectDirPath" : "",',
    '      "projectRoot" : "",',
    '      "targets" : [',
    '        "${_runnerNativeTargetIdentifer(platform)}",',
    '        "331C8080294A63A400263BE5"',
    '      ]',
    '    }',
  ].join('\n');
}

String migratedProjectSectionAsJson(SupportedPlatform platform) {
  return '''
    "${_projectIdentifier(platform)}" : {
      "attributes" : {
        "BuildIndependentTargetsInParallel" : "YES",
        "LastUpgradeCheck" : "1510",
        "ORGANIZATIONNAME" : "",
        "TargetAttributes" : {
          "${_runnerNativeTargetIdentifer(platform)}" : {
            "CreatedOnToolsVersion" : "7.3.1",
            "LastSwiftMigration" : "1100"
          },
          "331C8080294A63A400263BE5" : {
            "CreatedOnToolsVersion" : "14.0",
            "TestTargetID" : "${_runnerNativeTargetIdentifer(platform)}"
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
        "${_runnerNativeTargetIdentifer(platform)}",
        "331C8080294A63A400263BE5"
      ]
    }''';
}

// XCLocalSwiftPackageReference
String unmigratedLocalSwiftPackageReferenceSection({
  bool withOtherReference = false,
}) {
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

String migratedLocalSwiftPackageReferenceSection({
  bool withOtherReference = false,
}) {
  return <String>[
    '/* Begin XCLocalSwiftPackageReference section */',
    if (withOtherReference) ...<String>[
      '		010101010101010101010101 /* XCLocalSwiftPackageReference "SomeOtherPackage" */ = {',
      '			isa = XCLocalSwiftPackageReference;',
      '			relativePath = SomeOtherPackage;',
      '		};',
    ],
    '		781AD8BC2B33823900A9FFBB /* XCLocalSwiftPackageReference "Flutter/Packages/ephemeral/FlutterGeneratedPluginSwiftPackage" */ = {',
    '			isa = XCLocalSwiftPackageReference;',
    '			relativePath = Flutter/Packages/ephemeral/FlutterGeneratedPluginSwiftPackage;',
    '		};',
    '/* End XCLocalSwiftPackageReference section */',
  ].join('\n');
}

const String migratedLocalSwiftPackageReferenceSectionAsJson = '''
    "781AD8BC2B33823900A9FFBB" : {
      "isa" : "XCLocalSwiftPackageReference",
      "relativePath" : "Flutter/Packages/ephemeral/FlutterGeneratedPluginSwiftPackage"
    }''';

// XCSwiftPackageProductDependency
String unmigratedSwiftPackageProductDependencySection({
  bool withOtherDependency = false,
}) {
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

String migratedSwiftPackageProductDependencySection({
  bool withOtherDependency = false,
}) {
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
  FakeXcodeProjectInterpreter({
    this.throwErrorOnGetInfo = false,
  });

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
  FakePlistParser({
    String? json,
  }) : _outputPerCall = (json != null) ? <String>[json] : null;

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

class FakeIosProject extends Fake implements IosProject {
  FakeIosProject({
    required MemoryFileSystem fileSystem,
  })  : hostAppRoot = fileSystem.directory('app_name').childDirectory('ios'),
        parent = FakeFlutterProject(fileSystem: fileSystem),
        xcodeProjectInfoFile = fileSystem
            .directory('app_name')
            .childDirectory('ios')
            .childDirectory('Runner.xcodeproj')
            .childFile('project.pbxproj');

  @override
  FakeFlutterProject parent;

  @override
  Directory hostAppRoot;

  @override
  File xcodeProjectInfoFile;

  @override
  String hostAppProjectName = 'Runner';
}

class FakeFlutterProject extends Fake implements FlutterProject {
  FakeFlutterProject({
    required MemoryFileSystem fileSystem,
  }) : directory = fileSystem.directory('app_name');

  @override
  Directory directory;
}

class FakeSwiftPackageManagerIntegrationMigration extends SwiftPackageManagerIntegrationMigration {
  FakeSwiftPackageManagerIntegrationMigration(
    super.project,
    super.platform, {
    required super.xcodeProjectInterpreter,
    required super.logger,
    required super.fileSystem,
    required super.plistParser,
    this.validateBackup = false,
  }) : _xcodeProject = project;

  final XcodeBasedProject _xcodeProject;

  final bool validateBackup;
  @override
  void restoreFromBackup() {
    if (validateBackup) {
      expect(backupProjectSettings.existsSync(), isTrue);
      final String originalSettings = backupProjectSettings.readAsStringSync();
      expect(
        _xcodeProject.xcodeProjectInfoFile.readAsStringSync() == originalSettings,
        isFalse,
      );

      super.restoreFromBackup();
      expect(
        _xcodeProject.xcodeProjectInfoFile.readAsStringSync(),
        originalSettings,
      );
    } else {
      super.restoreFromBackup();
    }
  }
}
