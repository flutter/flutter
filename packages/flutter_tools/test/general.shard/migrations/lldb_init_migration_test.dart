// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/migrations/lldb_init_migration.dart';

import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

void main() {
  group('LLDBInitMigration', () {
    testWithoutContext('fails if Xcode project is not found', () async {
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
      final BufferLogger testLogger = BufferLogger.test();

      final FakeXcodeProject project = FakeXcodeProject(
        platform: SupportedPlatform.ios.name,
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );
      final LLDBInitMigration migration = LLDBInitMigration(
        project,
        BuildInfo.debug,
        logger: testLogger,
      );

      await migration.migrate();
      expect(testLogger.errorText, contains('Xcode project not found'));
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
        _createProjectFiles(project);
        project._projectInfo = null;

        final LLDBInitMigration migration = LLDBInitMigration(
          project,
          BuildInfo.debug,
          logger: testLogger,
        );
        await migration.migrate();
        expect(testLogger.errorText, contains('Unable to get Xcode project info.'));
      });

      testWithoutContext('fails if Xcode workspace not found', () async {
        final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
        final BufferLogger testLogger = BufferLogger.test();
        final FakeXcodeProject project = FakeXcodeProject(
          platform: SupportedPlatform.ios.name,
          fileSystem: memoryFileSystem,
          logger: testLogger,
        );
        _createProjectFiles(project);
        project.xcodeWorkspace = null;

        final LLDBInitMigration migration = LLDBInitMigration(
          project,
          BuildInfo.debug,
          logger: testLogger,
        );
        await migration.migrate();
        expect(testLogger.errorText, contains('Xcode workspace not found.'));
      });

      testWithoutContext('fails if scheme not found', () async {
        final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
        final BufferLogger testLogger = BufferLogger.test();
        final FakeXcodeProject project = FakeXcodeProject(
          platform: SupportedPlatform.ios.name,
          fileSystem: memoryFileSystem,
          logger: testLogger,
        );
        _createProjectFiles(project);
        project._projectInfo = XcodeProjectInfo(<String>[], <String>[], <String>[], testLogger);

        final LLDBInitMigration migration = LLDBInitMigration(
          project,
          BuildInfo.debug,
          logger: testLogger,
        );
        await migration.migrate();
        expect(
          testLogger.errorText,
          contains('You must specify a --flavor option to select one of the available schemes.'),
        );
      });

      testWithoutContext('fails if scheme file not found', () async {
        final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
        final BufferLogger testLogger = BufferLogger.test();
        final FakeXcodeProject project = FakeXcodeProject(
          platform: SupportedPlatform.ios.name,
          fileSystem: memoryFileSystem,
          logger: testLogger,
        );
        _createProjectFiles(project, createSchemeFile: false);

        final LLDBInitMigration migration = LLDBInitMigration(
          project,
          BuildInfo.debug,
          logger: testLogger,
        );
        await migration.migrate();
        expect(testLogger.errorText, contains('Unable to get scheme file for Runner.'));
      });
    });

    testWithoutContext('does nothing if already migrated', () async {
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
      final BufferLogger testLogger = BufferLogger.test();
      final FakeXcodeProject project = FakeXcodeProject(
        platform: SupportedPlatform.ios.name,
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );
      _createProjectFiles(project);
      project.xcodeProjectSchemeFile().writeAsStringSync(
        _validScheme(lldbInitFile: r'$(SRCROOT)/Flutter/ephemeral/.lldbinit'),
      );

      final LLDBInitMigration migration = LLDBInitMigration(
        project,
        BuildInfo.debug,
        logger: testLogger,
      );
      await migration.migrate();
      expect(testLogger.errorText, isEmpty);
    });

    testWithoutContext('throws error if customLLDBInitFile already exists', () async {
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
      final BufferLogger testLogger = BufferLogger.test();
      final FakeXcodeProject project = FakeXcodeProject(
        platform: SupportedPlatform.ios.name,
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );
      _createProjectFiles(project);
      project.xcodeProjectSchemeFile().writeAsStringSync(
        _validScheme(lldbInitFile: r'customLLDBInitFile = "non_flutter/.lldbinit"'),
      );

      final LLDBInitMigration migration = LLDBInitMigration(
        project,
        BuildInfo.debug,
        logger: testLogger,
      );
      await migration.migrate();
      expect(
        testLogger.errorText,
        contains('Running Flutter in debug mode on new iOS versions requires a LLDB Init File'),
      );
    });

    testWithoutContext('throws error if LaunchAction is missing', () async {
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
      final BufferLogger testLogger = BufferLogger.test();
      final FakeXcodeProject project = FakeXcodeProject(
        platform: SupportedPlatform.ios.name,
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );
      _createProjectFiles(project);
      project.xcodeProjectSchemeFile().writeAsStringSync(_missingLaunchAction);

      final LLDBInitMigration migration = LLDBInitMigration(
        project,
        BuildInfo.debug,
        logger: testLogger,
      );
      await migration.migrate();
      expect(testLogger.errorText, contains('Failed to find LaunchAction for the Scheme'));
    });

    testWithoutContext('throws error if TestAction is missing', () async {
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
      final BufferLogger testLogger = BufferLogger.test();
      final FakeXcodeProject project = FakeXcodeProject(
        platform: SupportedPlatform.ios.name,
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );
      _createProjectFiles(project);
      project.xcodeProjectSchemeFile().writeAsStringSync(_missingTestAction);

      final LLDBInitMigration migration = LLDBInitMigration(
        project,
        BuildInfo.debug,
        logger: testLogger,
      );
      await migration.migrate();
      expect(testLogger.errorText, contains('Failed to find TestAction for the Scheme'));
    });

    testWithoutContext('throws error if scheme file is invalid XML', () async {
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
      final BufferLogger testLogger = BufferLogger.test();
      final FakeXcodeProject project = FakeXcodeProject(
        platform: SupportedPlatform.ios.name,
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );
      _createProjectFiles(project);
      project.xcodeProjectSchemeFile().writeAsStringSync(
        '${_validScheme()} <an opening without a close>',
      );

      final LLDBInitMigration migration = LLDBInitMigration(
        project,
        BuildInfo.debug,
        logger: testLogger,
      );
      await migration.migrate();
      expect(testLogger.errorText, contains('Failed to parse'));
    });

    testWithoutContext('succeeds', () async {
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
      final BufferLogger testLogger = BufferLogger.test();
      final FakeXcodeProject project = FakeXcodeProject(
        platform: SupportedPlatform.ios.name,
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );
      _createProjectFiles(project);
      project.xcodeProjectSchemeFile().writeAsStringSync(_validScheme());

      final LLDBInitMigration migration = LLDBInitMigration(
        project,
        BuildInfo.debug,
        logger: testLogger,
      );
      await migration.migrate();
      expect(testLogger.errorText, isEmpty);
      expect(
        project.xcodeProjectSchemeFile().readAsStringSync(),
        _validScheme(
          lldbInitFile: '\n      customLLDBInitFile = "\$(SRCROOT)/Flutter/ephemeral/.lldbinit"',
        ),
      );
    });
  });
}

void _createProjectFiles(FakeXcodeProject project, {bool createSchemeFile = true, String? scheme}) {
  project.parent.directory.createSync(recursive: true);
  project.hostAppRoot.createSync(recursive: true);
  project.xcodeProjectInfoFile.createSync(recursive: true);
  if (createSchemeFile) {
    project.xcodeProjectSchemeFile(scheme: scheme).createSync(recursive: true);
    project.xcodeProjectSchemeFile().writeAsStringSync(_validScheme());
  }
}

String _validScheme({String lldbInitFile = ''}) {
  return '''
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1510"
   version = "1.3">
   <BuildAction>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"$lldbInitFile
      shouldUseLaunchSchemeArgsEnv = "YES">
      <MacroExpansion>
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "97C146ED1CF9000F007C117D"
            BuildableName = "Runner.app"
            BlueprintName = "Runner"
            ReferencedContainer = "container:Runner.xcodeproj">
         </BuildableReference>
      </MacroExpansion>
      <Testables>
         <TestableReference
            skipped = "NO"
            parallelizable = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "331C8080294A63A400263BE5"
               BuildableName = "RunnerTests.xctest"
               BlueprintName = "RunnerTests"
               ReferencedContainer = "container:Runner.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"$lldbInitFile
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      enableGPUValidationMode = "1"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "97C146ED1CF9000F007C117D"
            BuildableName = "Runner.app"
            BlueprintName = "Runner"
            ReferencedContainer = "container:Runner.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction>
   </ProfileAction>
   <AnalyzeAction>
   </AnalyzeAction>
   <ArchiveAction>
   </ArchiveAction>
</Scheme>
''';
}

const String _missingTestAction = '''
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1510"
   version = "1.3">
   <BuildAction>
   </BuildAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      enableGPUValidationMode = "1"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "97C146ED1CF9000F007C117D"
            BuildableName = "Runner.app"
            BlueprintName = "Runner"
            ReferencedContainer = "container:Runner.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction>
   </ProfileAction>
   <AnalyzeAction>
   </AnalyzeAction>
   <ArchiveAction>
   </ArchiveAction>
</Scheme>
''';

const String _missingLaunchAction = '''
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1510"
   version = "1.3">
   <BuildAction>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <MacroExpansion>
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "97C146ED1CF9000F007C117D"
            BuildableName = "Runner.app"
            BlueprintName = "Runner"
            ReferencedContainer = "container:Runner.xcodeproj">
         </BuildableReference>
      </MacroExpansion>
      <Testables>
         <TestableReference
            skipped = "NO"
            parallelizable = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "331C8080294A63A400263BE5"
               BuildableName = "RunnerTests.xctest"
               BlueprintName = "RunnerTests"
               ReferencedContainer = "container:Runner.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <ProfileAction>
   </ProfileAction>
   <AnalyzeAction>
   </AnalyzeAction>
   <ArchiveAction>
   </ArchiveAction>
</Scheme>
''';

class FakeFlutterProject extends Fake implements FlutterProject {
  FakeFlutterProject({required MemoryFileSystem fileSystem})
    : directory = fileSystem.directory('app_name');

  @override
  Directory directory;
}

class FakeXcodeProject extends Fake implements IosProject {
  FakeXcodeProject({
    required MemoryFileSystem fileSystem,
    required String platform,
    required this.logger,
  }) : hostAppRoot = fileSystem.directory('app_name').childDirectory(platform),
       parent = FakeFlutterProject(fileSystem: fileSystem);

  final Logger logger;
  late XcodeProjectInfo? _projectInfo = XcodeProjectInfo(
    <String>['Runner'],
    <String>['Debug', 'Release', 'Profile'],
    <String>['Runner'],
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
  File get lldbInitFile =>
      hostAppRoot.childDirectory('Flutter').childDirectory('ephemeral').childFile('.lldbinit');

  // @override
  // Directory get flutterPluginSwiftPackageDirectory => hostAppRoot
  //     .childDirectory('Flutter')
  //     .childDirectory('ephemeral')
  //     .childDirectory('Packages')
  //     .childDirectory('FlutterGeneratedPluginSwiftPackage');

  // @override
  // File get flutterPluginSwiftPackageManifest =>
  //     flutterPluginSwiftPackageDirectory.childFile('Package.swift');

  // @override
  // bool get flutterPluginSwiftPackageInProjectSettings {
  //   return xcodeProjectInfoFile.existsSync() &&
  //       xcodeProjectInfoFile.readAsStringSync().contains('FlutterGeneratedPluginSwiftPackage');
  // }

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
