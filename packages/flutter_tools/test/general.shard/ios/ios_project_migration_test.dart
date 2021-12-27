// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/project_migrator.dart';
import 'package:flutter_tools/src/ios/migrations/deployment_target_migration.dart';
import 'package:flutter_tools/src/ios/migrations/project_base_configuration_migration.dart';
import 'package:flutter_tools/src/ios/migrations/project_build_location_migration.dart';
import 'package:flutter_tools/src/ios/migrations/project_object_version_migration.dart';
import 'package:flutter_tools/src/ios/migrations/remove_framework_link_and_embedding_migration.dart';
import 'package:flutter_tools/src/ios/migrations/xcode_build_system_migration.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/xcode_project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

void main () {
  group('iOS migration', () {
    late TestUsage testUsage;

    setUp(() {
      testUsage = TestUsage();
    });

    testWithoutContext('migrators succeed', () {
      final FakeIOSMigrator fakeIOSMigrator = FakeIOSMigrator(succeeds: true);
      final ProjectMigration migration = ProjectMigration(<ProjectMigrator>[fakeIOSMigrator]);
      expect(migration.run(), isTrue);
    });

    testWithoutContext('migrators fail', () {
      final FakeIOSMigrator fakeIOSMigrator = FakeIOSMigrator(succeeds: false);
      final ProjectMigration migration = ProjectMigration(<ProjectMigrator>[fakeIOSMigrator]);
      expect(migration.run(), isFalse);
    });

    group('remove framework linking and embedding migration', () {
      late MemoryFileSystem memoryFileSystem;
      late BufferLogger testLogger;
      late FakeIosProject project;
      late File xcodeProjectInfoFile;

      setUp(() {
        memoryFileSystem = MemoryFileSystem.test();
        xcodeProjectInfoFile = memoryFileSystem.file('project.pbxproj');
        testLogger = BufferLogger.test();
        project = FakeIosProject();
        project.xcodeProjectInfoFile = xcodeProjectInfoFile;
      });

      testWithoutContext('skipped if files are missing', () {
        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          project,
          testLogger,
          testUsage
        );
        expect(iosProjectMigration.migrate(), isTrue);
        expect(testUsage.events, isEmpty);

        expect(xcodeProjectInfoFile.existsSync(), isFalse);

        expect(testLogger.traceText, contains('Xcode project not found, skipping framework link and embedding migration'));
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skipped if nothing to upgrade', () {
        const String contents = 'Nothing to upgrade';
        xcodeProjectInfoFile.writeAsStringSync(contents);
        final DateTime projectLastModified = xcodeProjectInfoFile.lastModifiedSync();

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          project,
          testLogger,
          testUsage,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        expect(testUsage.events, isEmpty);

        expect(xcodeProjectInfoFile.lastModifiedSync(), projectLastModified);
        expect(xcodeProjectInfoFile.readAsStringSync(), contents);

        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skips migrating script with embed', () {
        const String contents = r'''
shellScript = "/bin/sh \"$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh\" embed\n/bin/sh \"$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh\" thin";
			''';
        xcodeProjectInfoFile.writeAsStringSync(contents);

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          project,
          testLogger,
          testUsage,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        expect(xcodeProjectInfoFile.readAsStringSync(), contents);
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('Xcode project is migrated', () {
        xcodeProjectInfoFile.writeAsStringSync(r'''
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
			shellScript = "/bin/sh \"$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh\" thin";
keep this 2
''');

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          project,
          testLogger,
          testUsage,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        expect(testUsage.events, isEmpty);

        expect(xcodeProjectInfoFile.readAsStringSync(), r'''
keep this 1
			shellScript = "/bin/sh \"$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh\" embed_and_thin";
keep this 2
''');
        expect(testLogger.statusText, contains('Upgrading project.pbxproj'));
      });

      testWithoutContext('migration fails with leftover App.framework reference', () {
        xcodeProjectInfoFile.writeAsStringSync('''
        746232531E83B71900CC1A5E /* App.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 746232521E83B71900CC1A5E /* App.framework */; };
''');

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          project,
          testLogger,
          testUsage,
        );

        expect(iosProjectMigration.migrate, throwsToolExit(message: 'Your Xcode project requires migration'));
        expect(testUsage.events, contains(
          const TestUsageEvent('ios-migration', 'remove-frameworks', label: 'failure'),
        ));
      });

      testWithoutContext('migration fails with leftover Flutter.framework reference', () {
        xcodeProjectInfoFile.writeAsStringSync('''
      9705A1C71CF904A300538480 /* Flutter.framework in Embed Frameworks */,
''');

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          project,
          testLogger,
          testUsage,
        );
        expect(iosProjectMigration.migrate, throwsToolExit(message: 'Your Xcode project requires migration'));
        expect(testUsage.events, contains(
          const TestUsageEvent('ios-migration', 'remove-frameworks', label: 'failure'),
        ));
      });

      testWithoutContext('migration fails without Xcode installed', () {
        xcodeProjectInfoFile.writeAsStringSync('''
        746232531E83B71900CC1A5E /* App.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = 746232521E83B71900CC1A5E /* App.framework */; };
''');

        final RemoveFrameworkLinkAndEmbeddingMigration iosProjectMigration = RemoveFrameworkLinkAndEmbeddingMigration(
          project,
          testLogger,
          testUsage,
        );
        expect(iosProjectMigration.migrate, throwsToolExit(message: 'Your Xcode project requires migration'));
        expect(testUsage.events, contains(
          const TestUsageEvent('ios-migration', 'remove-frameworks', label: 'failure'),
        ));
      });
    });

    group('new Xcode build system', () {
      late MemoryFileSystem memoryFileSystem;
      late BufferLogger testLogger;
      late FakeIosProject project;
      late File xcodeWorkspaceSharedSettings;

      setUp(() {
        memoryFileSystem = MemoryFileSystem.test();
        xcodeWorkspaceSharedSettings = memoryFileSystem.file('WorkspaceSettings.xcsettings');
        testLogger = BufferLogger.test();
        project = FakeIosProject();
        project.xcodeWorkspaceSharedSettings = xcodeWorkspaceSharedSettings;
      });

      testWithoutContext('skipped if files are missing', () {
        final XcodeBuildSystemMigration iosProjectMigration = XcodeBuildSystemMigration(
          project,
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
          project,
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
          project,
          testLogger,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        expect(xcodeWorkspaceSharedSettings.existsSync(), isFalse);

        expect(testLogger.statusText, contains('Legacy build system detected, removing'));
      });
    });

    group('Xcode default build location', () {
      late MemoryFileSystem memoryFileSystem;
      late BufferLogger testLogger;
      late FakeIosProject project;
      late File xcodeProjectWorkspaceData;

      setUp(() {
        memoryFileSystem = MemoryFileSystem();
        xcodeProjectWorkspaceData = memoryFileSystem.file('contents.xcworkspacedata');
        testLogger = BufferLogger.test();
        project = FakeIosProject();
        project.xcodeProjectWorkspaceData = xcodeProjectWorkspaceData;
      });

      testWithoutContext('skipped if files are missing', () {
        final ProjectBuildLocationMigration iosProjectMigration = ProjectBuildLocationMigration(
          project,
          testLogger,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        expect(xcodeProjectWorkspaceData.existsSync(), isFalse);

        expect(testLogger.traceText, contains('Xcode project workspace data not found, skipping build location migration.'));
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skipped if nothing to upgrade', () {
        const String contents = '''
 <?xml version="1.0" encoding="UTF-8"?>
 <Workspace
    version = "1.0">
    <FileRef
      location = "self:">
    </FileRef>
 </Workspace>''';
        xcodeProjectWorkspaceData.writeAsStringSync(contents);

        final ProjectBuildLocationMigration iosProjectMigration = ProjectBuildLocationMigration(
          project,
          testLogger,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        expect(xcodeProjectWorkspaceData.existsSync(), isTrue);
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('Xcode project is migrated', () {
        const String contents = '''
 <?xml version="1.0" encoding="UTF-8"?>
 <Workspace
   version = "1.0">
   <FileRef
      location = "group:Runner.xcodeproj">
   </FileRef>
   <FileRef
      location = "group:Pods/Pods.xcodeproj">
   </FileRef>
 </Workspace>
''';
        xcodeProjectWorkspaceData.writeAsStringSync(contents);

        final ProjectBuildLocationMigration iosProjectMigration = ProjectBuildLocationMigration(
          project,
          testLogger,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        expect(xcodeProjectWorkspaceData.readAsStringSync(), '''
 <?xml version="1.0" encoding="UTF-8"?>
 <Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
 </Workspace>
''');
        expect(testLogger.statusText, contains('Upgrading contents.xcworkspacedata'));
      });
    });

    group('remove Runner project base configuration', () {
      late MemoryFileSystem memoryFileSystem;
      late BufferLogger testLogger;
      late FakeIosProject project;
      late File xcodeProjectInfoFile;

      setUp(() {
        memoryFileSystem = MemoryFileSystem();
        xcodeProjectInfoFile = memoryFileSystem.file('project.pbxproj');
        testLogger = BufferLogger.test();
        project = FakeIosProject();
        project.xcodeProjectInfoFile = xcodeProjectInfoFile;
      });

      testWithoutContext('skipped if files are missing', () {
        final ProjectBaseConfigurationMigration iosProjectMigration = ProjectBaseConfigurationMigration(
          project,
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
          project,
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
          project,
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
          project,
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

    group('update deployment target version', () {
      late MemoryFileSystem memoryFileSystem;
      late BufferLogger testLogger;
      late FakeIosProject project;
      late File xcodeProjectInfoFile;
      late File appFrameworkInfoPlist;

      setUp(() {
        memoryFileSystem = MemoryFileSystem();
        testLogger = BufferLogger.test();
        project = FakeIosProject();
        xcodeProjectInfoFile = memoryFileSystem.file('project.pbxproj');
        project.xcodeProjectInfoFile = xcodeProjectInfoFile;

        appFrameworkInfoPlist = memoryFileSystem.file('AppFrameworkInfo.plist');
        project.appFrameworkInfoPlist = appFrameworkInfoPlist;
      });

      testWithoutContext('skipped if files are missing', () {
        final DeploymentTargetMigration iosProjectMigration = DeploymentTargetMigration(
          project,
          testLogger,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        expect(xcodeProjectInfoFile.existsSync(), isFalse);
        expect(appFrameworkInfoPlist.existsSync(), isFalse);

        expect(testLogger.traceText, contains('Xcode project not found, skipping iOS deployment target version migration'));
        expect(testLogger.traceText, contains('AppFrameworkInfo.plist not found, skipping minimum OS version migration'));
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skipped if nothing to upgrade', () {
        const String xcodeProjectInfoFileContents = 'IPHONEOS_DEPLOYMENT_TARGET = 9.0;';
        xcodeProjectInfoFile.writeAsStringSync(xcodeProjectInfoFileContents);

        const String appFrameworkInfoPlistContents = '''
  <key>MinimumOSVersion</key>
  <string>9.0</string>
''';
        appFrameworkInfoPlist.writeAsStringSync(appFrameworkInfoPlistContents);

        final DateTime projectLastModified = xcodeProjectInfoFile.lastModifiedSync();

        final DeploymentTargetMigration iosProjectMigration = DeploymentTargetMigration(
          project,
          testLogger,
        );
        expect(iosProjectMigration.migrate(), isTrue);

        expect(xcodeProjectInfoFile.lastModifiedSync(), projectLastModified);
        expect(xcodeProjectInfoFile.readAsStringSync(), xcodeProjectInfoFileContents);
        expect(appFrameworkInfoPlist.readAsStringSync(), appFrameworkInfoPlistContents);

        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('Xcode project is migrated to minimum version 8.0', () {
        xcodeProjectInfoFile.writeAsStringSync('''
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 8.0;
				MTL_ENABLE_DEBUG_INFO = YES;
				ONLY_ACTIVE_ARCH = YES;

				IPHONEOS_DEPLOYMENT_TARGET = 8.0;
''');

        appFrameworkInfoPlist.writeAsStringSync('''
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleSignature</key>
  <string>????</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
  <key>MinimumOSVersion</key>
  <string>8.0</string>
</dict>
</plist>
''');

        final DeploymentTargetMigration iosProjectMigration = DeploymentTargetMigration(
          project,
          testLogger,
        );
        expect(iosProjectMigration.migrate(), isTrue);

        expect(xcodeProjectInfoFile.readAsStringSync(), '''
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 9.0;
				MTL_ENABLE_DEBUG_INFO = YES;
				ONLY_ACTIVE_ARCH = YES;

				IPHONEOS_DEPLOYMENT_TARGET = 9.0;
''');

        expect(appFrameworkInfoPlist.readAsStringSync(), '''
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleSignature</key>
  <string>????</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
  <key>MinimumOSVersion</key>
  <string>9.0</string>
</dict>
</plist>
''');
        // Only print once even though 2 lines were changed.
        expect('Updating minimum iOS deployment target from 8.0 to 9.0'.allMatches(testLogger.statusText).length, 1);
      });
    });

    group('update Xcode project object version', () {
      late MemoryFileSystem memoryFileSystem;
      late BufferLogger testLogger;
      late FakeIosProject project;
      late File xcodeProjectInfoFile;
      late File xcodeProjectSchemeFile;

      setUp(() {
        memoryFileSystem = MemoryFileSystem();
        testLogger = BufferLogger.test();
        project = FakeIosProject();
        xcodeProjectInfoFile = memoryFileSystem.file('project.pbxproj');
        project.xcodeProjectInfoFile = xcodeProjectInfoFile;

        xcodeProjectSchemeFile = memoryFileSystem.file('Runner.xcscheme');
        project.xcodeProjectSchemeFile = xcodeProjectSchemeFile;
      });

      testWithoutContext('skipped if files are missing', () {
        final ProjectObjectVersionMigration iosProjectMigration = ProjectObjectVersionMigration(
          project,
          testLogger,
        );
        expect(iosProjectMigration.migrate(), isTrue);
        expect(xcodeProjectInfoFile.existsSync(), isFalse);
        expect(xcodeProjectSchemeFile.existsSync(), isFalse);

        expect(testLogger.traceText, contains('Xcode project not found, skipping Xcode compatibility migration'));
        expect(testLogger.traceText, contains('Runner scheme not found, skipping Xcode compatibility migration'));
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skipped if nothing to upgrade', () {
        const String xcodeProjectInfoFileContents = '''
	classes = {
	};
	objectVersion = 50;
	objects = {
			attributes = {
				LastUpgradeCheck = 1300;
				ORGANIZATIONNAME = "";
      ''';
        xcodeProjectInfoFile.writeAsStringSync(xcodeProjectInfoFileContents);

        const String xcodeProjectSchemeFileContents = '''
   LastUpgradeVersion = "1300"
''';
        xcodeProjectSchemeFile.writeAsStringSync(xcodeProjectSchemeFileContents);

        final DateTime projectLastModified = xcodeProjectInfoFile.lastModifiedSync();

        final ProjectObjectVersionMigration iosProjectMigration = ProjectObjectVersionMigration(
          project,
          testLogger,
        );
        expect(iosProjectMigration.migrate(), isTrue);

        expect(xcodeProjectInfoFile.lastModifiedSync(), projectLastModified);
        expect(xcodeProjectInfoFile.readAsStringSync(), xcodeProjectInfoFileContents);
        expect(xcodeProjectSchemeFile.readAsStringSync(), xcodeProjectSchemeFileContents);

        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('Xcode project is migrated to Xcode 13', () {
        xcodeProjectInfoFile.writeAsStringSync('''
	classes = {
	};
	objectVersion = 46;
	objects = {
			attributes = {
				LastUpgradeCheck = 1020;
				ORGANIZATIONNAME = "";
''');

        xcodeProjectSchemeFile.writeAsStringSync('''
<Scheme
   LastUpgradeVersion = "1020"
   version = "1.3">
''');

        final ProjectObjectVersionMigration iosProjectMigration = ProjectObjectVersionMigration(
          project,
          testLogger,
        );
        expect(iosProjectMigration.migrate(), isTrue);

        expect(xcodeProjectInfoFile.readAsStringSync(), '''
	classes = {
	};
	objectVersion = 50;
	objects = {
			attributes = {
				LastUpgradeCheck = 1300;
				ORGANIZATIONNAME = "";
''');

        expect(xcodeProjectSchemeFile.readAsStringSync(), '''
<Scheme
   LastUpgradeVersion = "1300"
   version = "1.3">
''');
        // Only print once even though 3 lines were changed.
        expect('Updating project for Xcode compatibility'.allMatches(testLogger.statusText).length, 1);
      });
    });
  });
}

class FakeIosProject extends Fake implements IosProject {
  @override
  File xcodeProjectWorkspaceData = MemoryFileSystem.test().file('xcodeProjectWorkspaceData');

  @override
  File xcodeWorkspaceSharedSettings = MemoryFileSystem.test().file('xcodeWorkspaceSharedSettings');

  @override
  File xcodeProjectInfoFile = MemoryFileSystem.test().file('xcodeProjectInfoFile');

  @override
  File xcodeProjectSchemeFile = MemoryFileSystem.test().file('xcodeProjectSchemeFile');

  @override
  File appFrameworkInfoPlist = MemoryFileSystem.test().file('appFrameworkInfoPlist');
}

class FakeIOSMigrator extends ProjectMigrator {
  FakeIOSMigrator({required this.succeeds})
    : super(BufferLogger.test());

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
