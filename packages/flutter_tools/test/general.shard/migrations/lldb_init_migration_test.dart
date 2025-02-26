// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/migrations/lldb_init_migration.dart';
import 'package:flutter_tools/src/migrations/swift_package_manager_gitignore_migration.dart';

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
        SupportedPlatform.ios,
        BuildInfo.debug,
        logger: testLogger,
      );

      await expectLater(
        () => migration.migrate(),
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

        final LLDBInitMigration projectMigration = LLDBInitMigration(
          project,
          SupportedPlatform.ios,
          BuildInfo.debug,
          logger: testLogger,
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

        final LLDBInitMigration projectMigration = LLDBInitMigration(
          project,
          SupportedPlatform.ios,
          BuildInfo.debug,
          logger: testLogger,
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

        final LLDBInitMigration projectMigration = LLDBInitMigration(
          project,
          SupportedPlatform.ios,
          BuildInfo.debug,
          logger: testLogger,
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

        final LLDBInitMigration projectMigration = LLDBInitMigration(
          project,
          SupportedPlatform.ios,
          BuildInfo.debug,
          logger: testLogger,
        );
        await expectLater(
          () => projectMigration.migrate(),
          throwsToolExit(message: 'Unable to get scheme file for Runner.'),
        );
        expect(testLogger.traceText, isEmpty);
        expect(testLogger.statusText, isEmpty);
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
      _createProjectFiles(project, SupportedPlatform.ios);
      project.xcodeProjectSchemeFile().writeAsStringSync(
        _validBuildActions(
          SupportedPlatform.ios,
          lldbInitFile: r'$(FLUTTER_ROOT)/packages/flutter_tools/bin/.lldbinit',
        ),
      );

      final LLDBInitMigration projectMigration = LLDBInitMigration(
        project,
        SupportedPlatform.ios,
        BuildInfo.debug,
        logger: testLogger,
      );
      await projectMigration.migrate();
      expect(testLogger.traceText, isEmpty);
      expect(testLogger.statusText, isEmpty);
    });

    testWithoutContext('throws error if customLLDBInitFile already exists', () async {
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
      final BufferLogger testLogger = BufferLogger.test();
      final FakeXcodeProject project = FakeXcodeProject(
        platform: SupportedPlatform.ios.name,
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );
      _createProjectFiles(project, SupportedPlatform.ios);
      project.xcodeProjectSchemeFile().writeAsStringSync(
        _validBuildActions(
          SupportedPlatform.ios,
          lldbInitFile: r'customLLDBInitFile = "non_flutter/.lldbinit"',
        ),
      );

      final LLDBInitMigration projectMigration = LLDBInitMigration(
        project,
        SupportedPlatform.ios,
        BuildInfo.debug,
        logger: testLogger,
      );
      await expectLater(
          () => projectMigration.migrate(),
          throwsToolExit(message: 'Running Flutter in debug mode on new iO'),
        );
      expect(testLogger.traceText, isEmpty);
      expect(testLogger.statusText, isEmpty);

    });

    testWithoutContext('throws error if LaunchAction is missing', () async {
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
      final BufferLogger testLogger = BufferLogger.test();
      final FakeXcodeProject project = FakeXcodeProject(
        platform: SupportedPlatform.ios.name,
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );
      _createProjectFiles(project, SupportedPlatform.ios);
      project.xcodeProjectSchemeFile().writeAsStringSync(
        _missingLaunchAction(
          SupportedPlatform.ios,
        ),
      );

      final LLDBInitMigration projectMigration = LLDBInitMigration(
        project,
        SupportedPlatform.ios,
        BuildInfo.debug,
        logger: testLogger,
      );
      await expectLater(
          () => projectMigration.migrate(),
          throwsToolExit(message: 'Failed to find LaunchAction for the Scheme'),
        );
      expect(testLogger.traceText, isEmpty);
      expect(testLogger.statusText, isEmpty);

    });

    testWithoutContext('throws error if TestAction is missing', () async {
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
      final BufferLogger testLogger = BufferLogger.test();
      final FakeXcodeProject project = FakeXcodeProject(
        platform: SupportedPlatform.ios.name,
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );
      _createProjectFiles(project, SupportedPlatform.ios);
      project.xcodeProjectSchemeFile().writeAsStringSync(
        _missingTestAction(
          SupportedPlatform.ios,
        ),
      );

      final LLDBInitMigration projectMigration = LLDBInitMigration(
        project,
        SupportedPlatform.ios,
        BuildInfo.debug,
        logger: testLogger,
      );
      await expectLater(
          () => projectMigration.migrate(),
          throwsToolExit(message: 'Failed to find TestAction for the Scheme'),
        );
      expect(testLogger.traceText, isEmpty);
      expect(testLogger.statusText, isEmpty);

    });

    testWithoutContext('throws error if scheme file is invalid XML', () async {
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
      final BufferLogger testLogger = BufferLogger.test();
      final FakeXcodeProject project = FakeXcodeProject(
        platform: SupportedPlatform.ios.name,
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );
      _createProjectFiles(project, SupportedPlatform.ios);
      project.xcodeProjectSchemeFile().writeAsStringSync(
        '${_validBuildActions(SupportedPlatform.ios)} <an opening without a close>',
      );

      final LLDBInitMigration projectMigration = LLDBInitMigration(
        project,
        SupportedPlatform.ios,
        BuildInfo.debug,
        logger: testLogger,
      );
      await expectLater(
          () => projectMigration.migrate(),
          throwsToolExit(message: 'Failed to parse'),
        );
      expect(testLogger.traceText, isEmpty);
      expect(testLogger.statusText, isEmpty);
    });

    testWithoutContext('succeeds', () async {
      final MemoryFileSystem memoryFileSystem = MemoryFileSystem();
      final BufferLogger testLogger = BufferLogger.test();
      final FakeXcodeProject project = FakeXcodeProject(
        platform: SupportedPlatform.ios.name,
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );
      _createProjectFiles(project, SupportedPlatform.ios);
      project.xcodeProjectSchemeFile().writeAsStringSync(
        _validBuildActions(
          SupportedPlatform.ios),
      );

      final LLDBInitMigration projectMigration = LLDBInitMigration(
        project,
        SupportedPlatform.ios,
        BuildInfo.debug,
        logger: testLogger,
      );
      await projectMigration.migrate();
      expect(testLogger.traceText, isEmpty);
      expect(testLogger.statusText, isEmpty);
      expect(project.xcodeProjectSchemeFile().readAsStringSync(),  _validBuildActions(
          SupportedPlatform.ios,
          lldbInitFile: '\n      customLLDBInitFile = "\$(FLUTTER_ROOT)/packages/flutter_tools/bin/.lldbinit"',
        ));
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

String _validBuildActions(SupportedPlatform platform, {String lldbInitFile = ''}) {
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
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"${lldbInitFile}
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
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"${lldbInitFile}
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

String _missingTestAction(SupportedPlatform platform, {String lldbInitFile = ''}) {
  return '''
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
      $lldbInitFile
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

String _missingLaunchAction(SupportedPlatform platform, {String lldbInitFile = ''}) {
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
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      $lldbInitFile
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
}




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
    return xcodeProjectInfoFile.existsSync() &&
        xcodeProjectInfoFile.readAsStringSync().contains('FlutterGeneratedPluginSwiftPackage');
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
