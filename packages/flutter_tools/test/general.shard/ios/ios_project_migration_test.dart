// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/ios/migrations/ios_migrator.dart';
import 'package:flutter_tools/src/ios/migrations/project_base_configuration_migration.dart';
import 'package:flutter_tools/src/ios/migrations/remove_framework_link_and_embedding_migration.dart';
import 'package:flutter_tools/src/ios/migrations/xcode_build_system_migration.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:meta/meta.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';

void main () {
  group('iOS migration', () {
    MockUsage mockUsage;
    setUp(() {
      mockUsage = MockUsage();
    });

    testWithoutContext('migrators succeed', () {
      final FakeIOSMigrator fakeIOSMigrator = FakeIOSMigrator(succeeds: true);
      final IOSMigration migration = IOSMigration(<IOSMigrator>[fakeIOSMigrator]);
      expect(migration.run(), isTrue);
    });

    testWithoutContext('migrators fail', () {
      final FakeIOSMigrator fakeIOSMigrator = FakeIOSMigrator(succeeds: false);
      final IOSMigration migration = IOSMigration(<IOSMigrator>[fakeIOSMigrator]);
      expect(migration.run(), isFalse);
    });

    group('remove framework linking and embedding migration', () {
      MemoryFileSystem memoryFileSystem;
      BufferLogger testLogger;
      MockIosProject mockIosProject;
      File xcodeProjectInfoFile;
      MockXcode mockXcode;

      setUp(() {
        memoryFileSystem = MemoryFileSystem();
        mockXcode = MockXcode();
        xcodeProjectInfoFile = memoryFileSystem.file('project.pbxproj');

        testLogger = BufferLogger(
          terminal: AnsiTerminal(
            stdio: null,
            platform: const LocalPlatform(),
          ),
          outputPreferences: OutputPreferences.test(),
        );

        mockIosProject = MockIosProject();
        when(mockIosProject.xcodeProjectInfoFile).thenReturn(xcodeProjectInfoFile);
      });

      testWithoutContext('skipped if files are missing', () {
        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          mockIosProject,
          testLogger,
          mockXcode,
          mockUsage
        );
        expect(iosProjectMigration.migrate(), isTrue);
        verifyNever(mockUsage.sendEvent(any, any, label: anyNamed('label'), value: anyNamed('value')));

        expect(xcodeProjectInfoFile.existsSync(), isFalse);

        expect(testLogger.traceText, contains('Xcode project not found, skipping framework link and embedding migration'));
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skipped if nothing to upgrade', () {
        const String contents = 'Nothing to upgrade';
        xcodeProjectInfoFile.writeAsStringSync(contents);
        final DateTime projectLastModified = xcodeProjectInfoFile.lastModifiedSync();

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          mockIosProject,
          testLogger,
          mockXcode,
          mockUsage,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        verifyNever(mockUsage.sendEvent(any, any, label: anyNamed('label'), value: anyNamed('value')));

        expect(xcodeProjectInfoFile.lastModifiedSync(), projectLastModified);
        expect(xcodeProjectInfoFile.readAsStringSync(), contents);

        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skips migrating script with embed', () {
        const String contents = '''
shellScript = "/bin/sh \"\$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh\\" embed\\n/bin/sh \"\$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh\\" thin";
			''';
        xcodeProjectInfoFile.writeAsStringSync(contents);

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          mockIosProject,
          testLogger,
          mockXcode,
          mockUsage,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        expect(xcodeProjectInfoFile.readAsStringSync(), contents);
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('Xcode project is migrated', () {
        xcodeProjectInfoFile.writeAsStringSync('''
prefix 3B80C3941E831B6300D905FE
3B80C3951E831B6300D905FE suffix
741F496821356857001E2961
keep this 1
  3B80C3931E831B6300D905FE spaces
741F496521356807001E2961
9705A1C61CF904A100538489
9705A1C71CF904A300538489
741F496221355F47001E2961
9740EEBA1CF902C7004384FC
741F495E21355F27001E2961
			shellScript = "/bin/sh \"\$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh\\" thin";
keep this 2
''');

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          mockIosProject,
          testLogger,
          mockXcode,
          mockUsage,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        verifyNever(mockUsage.sendEvent(any, any, label: anyNamed('label'), value: anyNamed('value')));

        expect(xcodeProjectInfoFile.readAsStringSync(), '''
keep this 1
			shellScript = "/bin/sh "\$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh\\" embed_and_thin";
keep this 2
''');
        expect(testLogger.statusText, contains('Upgrading project.pbxproj'));
      });

      testWithoutContext('migration fails with leftover App.framework reference', () {
        xcodeProjectInfoFile.writeAsStringSync('''
        746232531E83B71900CC1A5E /* App.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 746232521E83B71900CC1A5E /* App.framework */; };
''');
        when(mockXcode.isInstalled).thenReturn(true);
        when(mockXcode.majorVersion).thenReturn(11);
        when(mockXcode.minorVersion).thenReturn(4);

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          mockIosProject,
          testLogger,
          mockXcode,
          mockUsage,
        );

        expect(iosProjectMigration.migrate, throwsToolExit(message: 'Your Xcode project requires migration'));
        verify(mockUsage.sendEvent('ios-migration', 'remove-frameworks', label: 'failure', value: null));
      });

      testWithoutContext('migration fails with leftover Flutter.framework reference', () {
        xcodeProjectInfoFile.writeAsStringSync('''
      9705A1C71CF904A300538480 /* Flutter.framework in Embed Frameworks */,
''');
        when(mockXcode.isInstalled).thenReturn(true);
        when(mockXcode.majorVersion).thenReturn(11);
        when(mockXcode.minorVersion).thenReturn(4);

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          mockIosProject,
          testLogger,
          mockXcode,
          mockUsage,
        );
        expect(iosProjectMigration.migrate, throwsToolExit(message: 'Your Xcode project requires migration'));
        verify(mockUsage.sendEvent('ios-migration', 'remove-frameworks', label: 'failure', value: null));
      });

      testWithoutContext('migration fails without Xcode installed', () {
        xcodeProjectInfoFile.writeAsStringSync('''
        746232531E83B71900CC1A5E /* App.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 746232521E83B71900CC1A5E /* App.framework */; };
''');
        when(mockXcode.isInstalled).thenReturn(false);

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          mockIosProject,
          testLogger,
          mockXcode,
          mockUsage,
        );
        expect(iosProjectMigration.migrate, throwsToolExit(message: 'Your Xcode project requires migration'));
        verify(mockUsage.sendEvent('ios-migration', 'remove-frameworks', label: 'failure', value: null));
      });

      testWithoutContext('migration fails on Xcode < 11.4', () {
        xcodeProjectInfoFile.writeAsStringSync('''
        746232531E83B71900CC1A5E /* App.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 746232521E83B71900CC1A5E /* App.framework */; };
''');
        when(mockXcode.isInstalled).thenReturn(true);
        when(mockXcode.majorVersion).thenReturn(11);
        when(mockXcode.minorVersion).thenReturn(3);

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          mockIosProject,
          testLogger,
          mockXcode,
          mockUsage,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        verifyNever(mockUsage.sendEvent(any, any, label: anyNamed('label'), value: anyNamed('value')));
        expect(testLogger.errorText, isEmpty);
      });

      testWithoutContext('migration fails on Xcode 11.4', () {
        xcodeProjectInfoFile.writeAsStringSync('''
        746232531E83B71900CC1A5E /* App.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 746232521E83B71900CC1A5E /* App.framework */; };
''');
        when(mockXcode.isInstalled).thenReturn(true);
        when(mockXcode.majorVersion).thenReturn(11);
        when(mockXcode.minorVersion).thenReturn(4);

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          mockIosProject,
          testLogger,
          mockXcode,
          mockUsage,
        );
        expect(iosProjectMigration.migrate, throwsToolExit(message: 'Your Xcode project requires migration'));
        verify(mockUsage.sendEvent('ios-migration', 'remove-frameworks', label: 'failure', value: null));
      });

      testWithoutContext('migration fails on Xcode 12,0', () {
        xcodeProjectInfoFile.writeAsStringSync('''
        746232531E83B71900CC1A5E /* App.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 746232521E83B71900CC1A5E /* App.framework */; };
''');
        when(mockXcode.isInstalled).thenReturn(true);
        when(mockXcode.majorVersion).thenReturn(12);
        when(mockXcode.minorVersion).thenReturn(0);

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          mockIosProject,
          testLogger,
          mockXcode,
          mockUsage,
        );
        expect(iosProjectMigration.migrate, throwsToolExit(message: 'Your Xcode project requires migration'));
        verify(mockUsage.sendEvent('ios-migration', 'remove-frameworks', label: 'failure', value: null));
      });
    });

    group('new Xcode build system', () {
      MemoryFileSystem memoryFileSystem;
      BufferLogger testLogger;
      MockIosProject mockIosProject;
      File xcodeWorkspaceSharedSettings;

      setUp(() {
        memoryFileSystem = MemoryFileSystem();
        xcodeWorkspaceSharedSettings = memoryFileSystem.file('WorkspaceSettings.xcsettings');

        testLogger = BufferLogger(
          terminal: AnsiTerminal(
            stdio: null,
            platform: const LocalPlatform(),
          ),
          outputPreferences: OutputPreferences.test(),
        );

        mockIosProject = MockIosProject();
        when(mockIosProject.xcodeWorkspaceSharedSettings).thenReturn(xcodeWorkspaceSharedSettings);
      });

      testWithoutContext('skipped if files are missing', () {
        final XcodeBuildSystemMigration iosProjectMigration = XcodeBuildSystemMigration(
          mockIosProject,
          testLogger,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        expect(xcodeWorkspaceSharedSettings.existsSync(), isFalse);

        expect(testLogger.traceText, contains('Xcode workspace settings not found, skipping build system migration'));
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skipped if nothing to upgrade', () {
        const String contents = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>BuildSystemType</key>
	<string></string>
</dict>
</plist>''';
        xcodeWorkspaceSharedSettings.writeAsStringSync(contents);

        final XcodeBuildSystemMigration iosProjectMigration = XcodeBuildSystemMigration(
          mockIosProject,
          testLogger,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        expect(xcodeWorkspaceSharedSettings.existsSync(), isTrue);
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('Xcode project is migrated', () {
        const String contents = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>BuildSystemType</key>
	<string>Original</string>
	<key>PreviewsEnabled</key>
	<false/>
</dict>
</plist>''';
        xcodeWorkspaceSharedSettings.writeAsStringSync(contents);

        final XcodeBuildSystemMigration iosProjectMigration = XcodeBuildSystemMigration(
          mockIosProject,
          testLogger,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        expect(xcodeWorkspaceSharedSettings.existsSync(), isFalse);

        expect(testLogger.statusText, contains('Legacy build system detected, removing'));
      });
    });

    group('remove Runner project base configuration', () {
      MemoryFileSystem memoryFileSystem;
      BufferLogger testLogger;
      MockIosProject mockIosProject;
      File xcodeProjectInfoFile;

      setUp(() {
        memoryFileSystem = MemoryFileSystem();
        xcodeProjectInfoFile = memoryFileSystem.file('project.pbxproj');

        testLogger = BufferLogger(
          terminal: AnsiTerminal(
            stdio: null,
            platform: const LocalPlatform(),
          ),
          outputPreferences: OutputPreferences.test(),
        );

        mockIosProject = MockIosProject();
        when(mockIosProject.xcodeProjectInfoFile).thenReturn(xcodeProjectInfoFile);
      });

      testWithoutContext('skipped if files are missing', () {
        final ProjectBaseConfigurationMigration iosProjectMigration = ProjectBaseConfigurationMigration(
          mockIosProject,
          testLogger,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        expect(xcodeProjectInfoFile.existsSync(), isFalse);

        expect(testLogger.traceText, contains('Xcode project not found, skipping Runner project build settings and configuration migration'));
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skipped if nothing to upgrade', () {
        const String contents = 'Nothing to upgrade';
        xcodeProjectInfoFile.writeAsStringSync(contents);
        final DateTime projectLastModified = xcodeProjectInfoFile.lastModifiedSync();

        final ProjectBaseConfigurationMigration iosProjectMigration = ProjectBaseConfigurationMigration(
          mockIosProject,
          testLogger,
        );
        expect(iosProjectMigration.migrate(), isTrue);

        expect(xcodeProjectInfoFile.lastModifiedSync(), projectLastModified);
        expect(xcodeProjectInfoFile.readAsStringSync(), contents);

        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('Xcode project is migrated with template identifiers', () {
        xcodeProjectInfoFile.writeAsStringSync('''
		97C147031CF9000F007C117D /* Debug */ = {
			isa = XCBuildConfiguration;
			baseConfigurationReference = 9740EEB21CF90195004384FC /* Debug.xcconfig */;
keep this 1
		249021D3217E4FDB00AE95B9 /* Profile */ = {
			isa = XCBuildConfiguration;
			baseConfigurationReference = 7AFA3C8E1D35360C0083082E /* Release.xcconfig */;
keep this 2
		97C147041CF9000F007C117D /* Release */ = {
			isa = XCBuildConfiguration;
			baseConfigurationReference = 7AFA3C8E1D35360C0083082E /* Release.xcconfig */;
keep this 3
''');

        final ProjectBaseConfigurationMigration iosProjectMigration = ProjectBaseConfigurationMigration(
          mockIosProject,
          testLogger,
        );
        expect(iosProjectMigration.migrate(), isTrue);

        expect(xcodeProjectInfoFile.readAsStringSync(), '''
		97C147031CF9000F007C117D /* Debug */ = {
			isa = XCBuildConfiguration;
keep this 1
		249021D3217E4FDB00AE95B9 /* Profile */ = {
			isa = XCBuildConfiguration;
keep this 2
		97C147041CF9000F007C117D /* Release */ = {
			isa = XCBuildConfiguration;
keep this 3
''');
        expect(testLogger.statusText, contains('Project base configurations detected, removing.'));
      });

      testWithoutContext('Xcode project is migrated with custom identifiers', () {
        xcodeProjectInfoFile.writeAsStringSync('''
		97C147031CF9000F007C1171 /* Debug */ = {
			isa = XCBuildConfiguration;
			baseConfigurationReference = 9740EEB21CF90195004384FC /* Debug.xcconfig */;
		2436755321828D23008C7051 /* Profile */ = {
			isa = XCBuildConfiguration;
			baseConfigurationReference = 7AFA3C8E1D35360C0083082E /* Release.xcconfig */;
		97C147041CF9000F007C1171 /* Release */ = {
			isa = XCBuildConfiguration;
			baseConfigurationReference = 7AFA3C8E1D35360C0083082E /* Release.xcconfig */;
      /* Begin XCConfigurationList section */
      97C146E91CF9000F007C117D /* Build configuration list for PBXProject "Runner" */ = {
        isa = XCConfigurationList;
        buildConfigurations = (
          97C147031CF9000F007C1171 /* Debug */,
          97C147041CF9000F007C1171 /* Release */,
          2436755321828D23008C7051 /* Profile */,
        );
        defaultConfigurationIsVisible = 0;
        defaultConfigurationName = Release;
      };
      97C147051CF9000F007C117D /* Build configuration list for PBXNativeTarget "Runner" */ = {
        isa = XCConfigurationList;
        buildConfigurations = (
          97C147061CF9000F007C117D /* Debug */,
          97C147071CF9000F007C117D /* Release */,
          2436755421828D23008C705F /* Profile */,
        );
        defaultConfigurationIsVisible = 0;
        defaultConfigurationName = Release;
      };
/* End XCConfigurationList section */
''');

        final ProjectBaseConfigurationMigration iosProjectMigration = ProjectBaseConfigurationMigration(
          mockIosProject,
          testLogger,
        );
        expect(iosProjectMigration.migrate(), isTrue);

        expect(xcodeProjectInfoFile.readAsStringSync(), '''
		97C147031CF9000F007C1171 /* Debug */ = {
			isa = XCBuildConfiguration;
		2436755321828D23008C7051 /* Profile */ = {
			isa = XCBuildConfiguration;
		97C147041CF9000F007C1171 /* Release */ = {
			isa = XCBuildConfiguration;
      /* Begin XCConfigurationList section */
      97C146E91CF9000F007C117D /* Build configuration list for PBXProject "Runner" */ = {
        isa = XCConfigurationList;
        buildConfigurations = (
          97C147031CF9000F007C1171 /* Debug */,
          97C147041CF9000F007C1171 /* Release */,
          2436755321828D23008C7051 /* Profile */,
        );
        defaultConfigurationIsVisible = 0;
        defaultConfigurationName = Release;
      };
      97C147051CF9000F007C117D /* Build configuration list for PBXNativeTarget "Runner" */ = {
        isa = XCConfigurationList;
        buildConfigurations = (
          97C147061CF9000F007C117D /* Debug */,
          97C147071CF9000F007C117D /* Release */,
          2436755421828D23008C705F /* Profile */,
        );
        defaultConfigurationIsVisible = 0;
        defaultConfigurationName = Release;
      };
/* End XCConfigurationList section */
''');
        expect(testLogger.statusText, contains('Project base configurations detected, removing.'));
      });
    });
  });
}

class MockIosProject extends Mock implements IosProject {}
class MockXcode extends Mock implements Xcode {}
class MockUsage extends Mock implements Usage {}

class FakeIOSMigrator extends IOSMigrator {
  FakeIOSMigrator({@required this.succeeds})
    : super(null);

  final bool succeeds;

  @override
  bool migrate() {
    return succeeds;
  }

  @override
  String migrateLine(String line) {
    return line;
  }
}
