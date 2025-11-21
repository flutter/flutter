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
      final memoryFileSystem = MemoryFileSystem();
      final testLogger = BufferLogger.test();

      final project = FakeXcodeProject(
        platform: SupportedPlatform.ios.name,
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );
      final migration = LLDBInitMigration(
        project,
        BuildInfo.debug,
        testLogger,
        environmentType: EnvironmentType.physical,
        fileSystem: memoryFileSystem,
      );

      await migration.migrate();
      expect(testLogger.traceText, contains('Xcode project not found'));
      expect(
        testLogger.errorText,
        contains(
          'Running Flutter in debug mode on new iOS versions requires a LLDB Init File, but the '
          'scheme does not have it set.',
        ),
      );
    });

    group('get scheme file', () {
      testWithoutContext('fails if Xcode project info not found', () async {
        final memoryFileSystem = MemoryFileSystem();
        final testLogger = BufferLogger.test();
        final project = FakeXcodeProject(
          platform: SupportedPlatform.ios.name,
          fileSystem: memoryFileSystem,
          logger: testLogger,
        );
        _createProjectFiles(project);
        project._projectInfo = null;

        final migration = LLDBInitMigration(
          project,
          BuildInfo.debug,
          testLogger,
          environmentType: EnvironmentType.physical,
          fileSystem: memoryFileSystem,
        );
        await migration.migrate();
        expect(testLogger.traceText, contains('Unable to get Xcode project info.'));
        expect(
          testLogger.errorText,
          contains(
            'Running Flutter in debug mode on new iOS versions requires a LLDB Init File, but the '
            'scheme does not have it set.',
          ),
        );
      });

      testWithoutContext('fails if Xcode workspace not found', () async {
        final memoryFileSystem = MemoryFileSystem();
        final testLogger = BufferLogger.test();
        final project = FakeXcodeProject(
          platform: SupportedPlatform.ios.name,
          fileSystem: memoryFileSystem,
          logger: testLogger,
        );
        _createProjectFiles(project);
        project.xcodeWorkspace = null;

        final migration = LLDBInitMigration(
          project,
          BuildInfo.debug,
          testLogger,
          environmentType: EnvironmentType.physical,
          fileSystem: memoryFileSystem,
        );
        await migration.migrate();
        expect(testLogger.traceText, contains('Xcode workspace not found.'));
        expect(
          testLogger.errorText,
          contains(
            'Running Flutter in debug mode on new iOS versions requires a LLDB Init File, but the '
            'scheme does not have it set.',
          ),
        );
      });

      testWithoutContext('fails if scheme not found', () async {
        final memoryFileSystem = MemoryFileSystem();
        final testLogger = BufferLogger.test();
        final project = FakeXcodeProject(
          platform: SupportedPlatform.ios.name,
          fileSystem: memoryFileSystem,
          logger: testLogger,
        );
        _createProjectFiles(project);
        project._projectInfo = XcodeProjectInfo(<String>[], <String>[], <String>[], testLogger);

        final migration = LLDBInitMigration(
          project,
          BuildInfo.debug,
          testLogger,
          environmentType: EnvironmentType.physical,
          fileSystem: memoryFileSystem,
        );
        await expectToolExitLater(
          migration.migrate(),
          contains('You must specify a --flavor option to select one of the available schemes.'),
        );
      });

      testWithoutContext('fails if scheme file not found', () async {
        final memoryFileSystem = MemoryFileSystem();
        final testLogger = BufferLogger.test();
        final project = FakeXcodeProject(
          platform: SupportedPlatform.ios.name,
          fileSystem: memoryFileSystem,
          logger: testLogger,
        );
        _createProjectFiles(project, createSchemeFile: false);

        final migration = LLDBInitMigration(
          project,
          BuildInfo.debug,
          testLogger,
          environmentType: EnvironmentType.physical,
          fileSystem: memoryFileSystem,
        );
        await migration.migrate();
        expect(testLogger.traceText, contains('Unable to get scheme file for Runner.'));
        expect(
          testLogger.errorText,
          contains(
            'Running Flutter in debug mode on new iOS versions requires a LLDB Init File, but the '
            'Runner scheme does not have it set.',
          ),
        );
      });
    });

    testWithoutContext('does nothing if both Launch and Test are already migrated', () async {
      final memoryFileSystem = MemoryFileSystem();
      final testLogger = BufferLogger.test();
      final project = FakeXcodeProject(
        platform: SupportedPlatform.ios.name,
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );
      _createProjectFiles(project);
      project.xcodeProjectSchemeFile().writeAsStringSync(
        _validScheme(
          lldbInitFile:
              '\n      customLLDBInitFile = "\$(SRCROOT)/Flutter/ephemeral/flutter_lldbinit"',
        ),
      );

      final migration = LLDBInitMigration(
        project,
        BuildInfo.debug,
        testLogger,
        environmentType: EnvironmentType.physical,
        fileSystem: memoryFileSystem,
      );
      await migration.migrate();
      expect(testLogger.errorText, isEmpty);
    });

    testWithoutContext('prints error if only Launch action is migrated', () async {
      final memoryFileSystem = MemoryFileSystem();
      final testLogger = BufferLogger.test();
      final project = FakeXcodeProject(
        platform: SupportedPlatform.ios.name,
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );
      _createProjectFiles(project);
      project.xcodeProjectSchemeFile().writeAsStringSync(
        _validScheme(
          lldbInitFile:
              '\n      customLLDBInitFile = "\$(SRCROOT)/Flutter/ephemeral/flutter_lldbinit"',
          testLLDBInitFile: '',
        ),
      );

      final migration = LLDBInitMigration(
        project,
        BuildInfo.debug,
        testLogger,
        environmentType: EnvironmentType.physical,
        fileSystem: memoryFileSystem,
      );
      await migration.migrate();
      expect(
        testLogger.errorText,
        contains(
          'Running Flutter in debug mode on new iOS versions requires a LLDB '
          'Init File, but the Test action in the Runner scheme does not have it set.',
        ),
      );
    });

    testWithoutContext('prints error if only Test action is migrated', () async {
      final memoryFileSystem = MemoryFileSystem();
      final testLogger = BufferLogger.test();
      final project = FakeXcodeProject(
        platform: SupportedPlatform.ios.name,
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );
      _createProjectFiles(project);
      project.xcodeProjectSchemeFile().writeAsStringSync(
        _validScheme(
          testLLDBInitFile:
              '\n      customLLDBInitFile = "\$(SRCROOT)/Flutter/ephemeral/flutter_lldbinit"',
        ),
      );

      final migration = LLDBInitMigration(
        project,
        BuildInfo.debug,
        testLogger,
        environmentType: EnvironmentType.physical,
        fileSystem: memoryFileSystem,
      );
      await migration.migrate();
      expect(
        testLogger.errorText,
        contains(
          'Running Flutter in debug mode on new iOS versions requires a LLDB '
          'Init File, but the Run action in the Runner scheme does not have it set.',
        ),
      );
    });

    testWithoutContext(
      'print error if customLLDBInitFile already exists and does not contain flutter lldbinit',
      () async {
        final memoryFileSystem = MemoryFileSystem();
        final testLogger = BufferLogger.test();
        final project = FakeXcodeProject(
          platform: SupportedPlatform.ios.name,
          fileSystem: memoryFileSystem,
          logger: testLogger,
        );
        _createProjectFiles(project);
        project.xcodeProjectSchemeFile().writeAsStringSync(
          _validScheme(lldbInitFile: '\n      customLLDBInitFile = "non_flutter/.lldbinit"'),
        );

        final migration = LLDBInitMigration(
          project,
          BuildInfo.debug,
          testLogger,
          environmentType: EnvironmentType.physical,
          fileSystem: memoryFileSystem,
        );
        await migration.migrate();
        expect(
          testLogger.errorText,
          contains('Running Flutter in debug mode on new iOS versions requires a LLDB Init File'),
        );
      },
    );

    testWithoutContext(
      'skips if customLLDBInitFile already exists and contain flutter lldbinit',
      () async {
        final memoryFileSystem = MemoryFileSystem();
        final testLogger = BufferLogger.test();
        final project = FakeXcodeProject(
          platform: SupportedPlatform.ios.name,
          fileSystem: memoryFileSystem,
          logger: testLogger,
        );
        _createProjectFiles(project);
        memoryFileSystem.file('non_flutter/.lldbinit')
          ..createSync(recursive: true)
          ..writeAsStringSync('command source /path/to/Flutter/ephemeral/flutter_lldbinit');
        project.xcodeProjectSchemeFile().writeAsStringSync(
          _validScheme(lldbInitFile: '\n      customLLDBInitFile = "non_flutter/.lldbinit"'),
        );

        final migration = LLDBInitMigration(
          project,
          BuildInfo.debug,
          testLogger,
          environmentType: EnvironmentType.physical,
          fileSystem: memoryFileSystem,
        );
        await migration.migrate();
        expect(testLogger.errorText, isEmpty);
      },
    );

    testWithoutContext(
      'prints error if customLLDBInitFile already exists and not both Launch and Test contain flutter lldbinit',
      () async {
        final memoryFileSystem = MemoryFileSystem();
        final testLogger = BufferLogger.test();
        final project = FakeXcodeProject(
          platform: SupportedPlatform.ios.name,
          fileSystem: memoryFileSystem,
          logger: testLogger,
        );
        _createProjectFiles(project);
        memoryFileSystem.file('non_flutter/.lldbinit')
          ..createSync(recursive: true)
          ..writeAsStringSync('command source /path/to/Flutter/ephemeral/flutter_lldbinit');
        project.xcodeProjectSchemeFile().writeAsStringSync(
          _validScheme(
            lldbInitFile: '\n      customLLDBInitFile = "non_flutter/.lldbinit"',
            testLLDBInitFile: '\n      customLLDBInitFile = "non_flutter/.test_lldbinit"',
          ),
        );

        final migration = LLDBInitMigration(
          project,
          BuildInfo.debug,
          testLogger,
          environmentType: EnvironmentType.physical,
          fileSystem: memoryFileSystem,
        );
        await migration.migrate();
        expect(
          testLogger.errorText,
          contains('Running Flutter in debug mode on new iOS versions requires a LLDB Init File'),
        );
      },
    );

    testWithoutContext(
      'parses customLLDBInitFile if already exists and replaces Xcode build settings',
      () async {
        final memoryFileSystem = MemoryFileSystem();
        final testLogger = BufferLogger.test();
        final project = FakeXcodeProject(
          platform: SupportedPlatform.ios.name,
          fileSystem: memoryFileSystem,
          logger: testLogger,
          buildSettings: <String, String>{'SRCROOT': 'src_root'},
        );
        _createProjectFiles(project);
        memoryFileSystem.file('src_root/non_flutter/.lldbinit')
          ..createSync(recursive: true)
          ..writeAsStringSync('command source /path/to/Flutter/ephemeral/flutter_lldbinit');
        project.xcodeProjectSchemeFile().writeAsStringSync(
          _validScheme(
            lldbInitFile: '\n      customLLDBInitFile = "\$(SRCROOT)/non_flutter/.lldbinit"',
          ),
        );

        final migration = LLDBInitMigration(
          project,
          BuildInfo.debug,
          testLogger,
          environmentType: EnvironmentType.physical,
          fileSystem: memoryFileSystem,
        );
        await migration.migrate();
        expect(testLogger.errorText, isEmpty);
      },
    );

    testWithoutContext('prints error if LaunchAction is missing', () async {
      final memoryFileSystem = MemoryFileSystem();
      final testLogger = BufferLogger.test();
      final project = FakeXcodeProject(
        platform: SupportedPlatform.ios.name,
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );
      _createProjectFiles(project);
      project.xcodeProjectSchemeFile().writeAsStringSync(_missingLaunchAction);

      final migration = LLDBInitMigration(
        project,
        BuildInfo.debug,
        testLogger,
        environmentType: EnvironmentType.physical,
        fileSystem: memoryFileSystem,
      );
      await migration.migrate();
      expect(testLogger.traceText, contains('Failed to find LaunchAction for the Scheme'));
      expect(
        testLogger.errorText,
        contains(
          'Running Flutter in debug mode on new iOS versions requires a LLDB Init File, but the '
          'Runner scheme does not have it set.',
        ),
      );
    });

    testWithoutContext('prints error if TestAction is missing', () async {
      final memoryFileSystem = MemoryFileSystem();
      final testLogger = BufferLogger.test();
      final project = FakeXcodeProject(
        platform: SupportedPlatform.ios.name,
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );
      _createProjectFiles(project);
      project.xcodeProjectSchemeFile().writeAsStringSync(_missingTestAction);

      final migration = LLDBInitMigration(
        project,
        BuildInfo.debug,
        testLogger,
        environmentType: EnvironmentType.physical,
        fileSystem: memoryFileSystem,
      );
      await migration.migrate();
      expect(testLogger.traceText, contains('Failed to find TestAction for the Scheme'));
      expect(
        testLogger.errorText,
        contains(
          'Running Flutter in debug mode on new iOS versions requires a LLDB Init File, but the '
          'Runner scheme does not have it set.',
        ),
      );
    });

    testWithoutContext('prints error if scheme file is invalid XML', () async {
      final memoryFileSystem = MemoryFileSystem();
      final testLogger = BufferLogger.test();
      final project = FakeXcodeProject(
        platform: SupportedPlatform.ios.name,
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );
      _createProjectFiles(project);
      project.xcodeProjectSchemeFile().writeAsStringSync(
        '${_validScheme()} <an opening without a close>',
      );

      final migration = LLDBInitMigration(
        project,
        BuildInfo.debug,
        testLogger,
        environmentType: EnvironmentType.physical,
        fileSystem: memoryFileSystem,
      );
      await migration.migrate();
      expect(testLogger.traceText, contains('Failed to parse'));
      expect(
        testLogger.errorText,
        contains(
          'Running Flutter in debug mode on new iOS versions requires a LLDB Init File, but the '
          'Runner scheme does not have it set.',
        ),
      );
    });

    testWithoutContext('succeeds', () async {
      final memoryFileSystem = MemoryFileSystem();
      final testLogger = BufferLogger.test();
      final project = FakeXcodeProject(
        platform: SupportedPlatform.ios.name,
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );
      _createProjectFiles(project);
      project.xcodeProjectSchemeFile().writeAsStringSync(_validScheme());

      final migration = LLDBInitMigration(
        project,
        BuildInfo.debug,
        testLogger,
        environmentType: EnvironmentType.physical,
        fileSystem: memoryFileSystem,
      );
      await migration.migrate();
      expect(testLogger.errorText, isEmpty);
      expect(
        project.xcodeProjectSchemeFile().readAsStringSync(),
        _validScheme(
          lldbInitFile:
              '\n      customLLDBInitFile = "\$(SRCROOT)/Flutter/ephemeral/flutter_lldbinit"',
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

String _validScheme({String lldbInitFile = '', String? testLLDBInitFile}) {
  testLLDBInitFile ??= lldbInitFile;
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
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"$testLLDBInitFile
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

const _missingTestAction = '''
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

const _missingLaunchAction = '''
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
    this.buildSettings,
  }) : hostAppRoot = fileSystem.directory('app_name').childDirectory(platform),
       parent = FakeFlutterProject(fileSystem: fileSystem);

  final Logger logger;
  late XcodeProjectInfo? _projectInfo = XcodeProjectInfo(
    <String>['Runner'],
    <String>['Debug', 'Release', 'Profile'],
    <String>['Runner'],
    logger,
  );

  Map<String, String>? buildSettings;

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
  var hostAppProjectName = 'Runner';

  @override
  File get lldbInitFile => hostAppRoot
      .childDirectory('Flutter')
      .childDirectory('ephemeral')
      .childFile('flutter_lldbinit');

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

  @override
  Future<Map<String, String>?> buildSettingsForBuildInfo(
    BuildInfo? buildInfo, {
    String? scheme,
    String? configuration,
    String? target,
    EnvironmentType environmentType = EnvironmentType.physical,
    String? deviceId,
    bool isWatch = false,
  }) async {
    return buildSettings;
  }
}
