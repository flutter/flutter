// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/project_migrator.dart';
import 'package:flutter_tools/src/base/version.dart';
import 'package:flutter_tools/src/ios/migrations/host_app_info_plist_migration.dart';
import 'package:flutter_tools/src/ios/migrations/ios_deployment_target_migration.dart';
import 'package:flutter_tools/src/ios/migrations/project_base_configuration_migration.dart';
import 'package:flutter_tools/src/ios/migrations/project_build_location_migration.dart';
import 'package:flutter_tools/src/ios/migrations/remove_bitcode_migration.dart';
import 'package:flutter_tools/src/ios/migrations/remove_framework_link_and_embedding_migration.dart';
import 'package:flutter_tools/src/ios/migrations/xcode_build_system_migration.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/migrations/cocoapods_script_symlink.dart';
import 'package:flutter_tools/src/migrations/cocoapods_toolchain_directory_migration.dart';
import 'package:flutter_tools/src/migrations/xcode_project_object_version_migration.dart';
import 'package:flutter_tools/src/migrations/xcode_script_build_phase_migration.dart';
import 'package:flutter_tools/src/migrations/xcode_thin_binary_build_phase_input_paths_migration.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/xcode_project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';

void main () {
  group('iOS migration', () {
    late TestUsage testUsage;

    setUp(() {
      testUsage = TestUsage();
    });

    testWithoutContext('migrators succeed', () {
      final FakeIOSMigrator fakeIOSMigrator = FakeIOSMigrator();
      final ProjectMigration migration = ProjectMigration(<ProjectMigrator>[fakeIOSMigrator]);
      migration.run();
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
        iosProjectMigration.migrate();
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
        iosProjectMigration.migrate();
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
        iosProjectMigration.migrate();
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
        iosProjectMigration.migrate();
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
        iosProjectMigration.migrate();
        expect(xcodeWorkspaceSharedSettings.existsSync(), isFalse);

        expect(testLogger.traceText, contains('Xcode workspace settings not found, skipping build system migration'));
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skipped if _xcodeWorkspaceSharedSettings is null', () {
        final XcodeBuildSystemMigration iosProjectMigration = XcodeBuildSystemMigration(
          project,
          testLogger,
        );
        project.xcodeWorkspaceSharedSettings = null;

        iosProjectMigration.migrate();
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
        iosProjectMigration.migrate();
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
        iosProjectMigration.migrate();
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
        iosProjectMigration.migrate();
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
        iosProjectMigration.migrate();
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
        iosProjectMigration.migrate();
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
        iosProjectMigration.migrate();
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
        iosProjectMigration.migrate();

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
        iosProjectMigration.migrate();

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
        iosProjectMigration.migrate();

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
      late File podfile;

      setUp(() {
        memoryFileSystem = MemoryFileSystem();
        testLogger = BufferLogger.test();
        project = FakeIosProject();
        xcodeProjectInfoFile = memoryFileSystem.file('project.pbxproj');
        project.xcodeProjectInfoFile = xcodeProjectInfoFile;

        appFrameworkInfoPlist = memoryFileSystem.file('AppFrameworkInfo.plist');
        project.appFrameworkInfoPlist = appFrameworkInfoPlist;

        podfile = memoryFileSystem.file('Podfile');
        project.podfile = podfile;
      });

      testWithoutContext('skipped if files are missing', () {
        final IOSDeploymentTargetMigration iosProjectMigration = IOSDeploymentTargetMigration(
          project,
          testLogger,
        );
        iosProjectMigration.migrate();
        expect(xcodeProjectInfoFile.existsSync(), isFalse);
        expect(appFrameworkInfoPlist.existsSync(), isFalse);
        expect(podfile.existsSync(), isFalse);

        expect(testLogger.traceText, contains('Xcode project not found, skipping iOS deployment target version migration'));
        expect(testLogger.traceText, contains('AppFrameworkInfo.plist not found, skipping minimum OS version migration'));
        expect(testLogger.traceText, contains('Podfile not found, skipping global platform iOS version migration'));
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skipped if nothing to upgrade', () {
        const String xcodeProjectInfoFileContents = 'IPHONEOS_DEPLOYMENT_TARGET = 12.0;';
        xcodeProjectInfoFile.writeAsStringSync(xcodeProjectInfoFileContents);

        const String appFrameworkInfoPlistContents = '''
  <key>MinimumOSVersion</key>
  <string>12.0</string>
''';
        appFrameworkInfoPlist.writeAsStringSync(appFrameworkInfoPlistContents);

        final DateTime projectLastModified = xcodeProjectInfoFile.lastModifiedSync();

        const String podfileFileContents = "# platform :ios, '12.0'";
        podfile.writeAsStringSync(podfileFileContents);
        final DateTime podfileLastModified = podfile.lastModifiedSync();

        final IOSDeploymentTargetMigration iosProjectMigration = IOSDeploymentTargetMigration(
          project,
          testLogger,
        );
        iosProjectMigration.migrate();

        expect(xcodeProjectInfoFile.lastModifiedSync(), projectLastModified);
        expect(xcodeProjectInfoFile.readAsStringSync(), xcodeProjectInfoFileContents);
        expect(appFrameworkInfoPlist.readAsStringSync(), appFrameworkInfoPlistContents);
        expect(podfile.lastModifiedSync(), podfileLastModified);
        expect(podfile.readAsStringSync(), podfileFileContents);

        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('Xcode project is migrated to 12', () {
        xcodeProjectInfoFile.writeAsStringSync('''
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 8.0;
				MTL_ENABLE_DEBUG_INFO = YES;
				ONLY_ACTIVE_ARCH = YES;

				IPHONEOS_DEPLOYMENT_TARGET = 8.0;
				IPHONEOS_DEPLOYMENT_TARGET = 11.0;
				IPHONEOS_DEPLOYMENT_TARGET = 12.0;
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
  <key>MinimumOSVersion</key>
  <string>11.0</string>
  <key>MinimumOSVersion</key>
  <string>12.0</string>
</dict>
</plist>
''');

        podfile.writeAsStringSync('''
# platform :ios, '9.0'
platform :ios, '9.0'
# platform :ios, '11.0'
platform :ios, '11.0'
''');

        final IOSDeploymentTargetMigration iosProjectMigration = IOSDeploymentTargetMigration(
          project,
          testLogger,
        );
        iosProjectMigration.migrate();

        expect(xcodeProjectInfoFile.readAsStringSync(), '''
				GCC_WARN_UNUSED_VARIABLE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 12.0;
				MTL_ENABLE_DEBUG_INFO = YES;
				ONLY_ACTIVE_ARCH = YES;

				IPHONEOS_DEPLOYMENT_TARGET = 12.0;
				IPHONEOS_DEPLOYMENT_TARGET = 12.0;
				IPHONEOS_DEPLOYMENT_TARGET = 12.0;
''');

        expect(appFrameworkInfoPlist.readAsStringSync(), '''
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleSignature</key>
  <string>????</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
  <key>MinimumOSVersion</key>
  <string>12.0</string>
  <key>MinimumOSVersion</key>
  <string>12.0</string>
  <key>MinimumOSVersion</key>
  <string>12.0</string>
</dict>
</plist>
''');

        expect(podfile.readAsStringSync(), '''
# platform :ios, '12.0'
platform :ios, '12.0'
# platform :ios, '12.0'
platform :ios, '12.0'
''');
        // Only print once even though 2 lines were changed.
        expect('Updating minimum iOS deployment target to 12.0'.allMatches(testLogger.statusText).length, 1);
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
        final XcodeProjectObjectVersionMigration iosProjectMigration = XcodeProjectObjectVersionMigration(
          project,
          testLogger,
        );
        iosProjectMigration.migrate();
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
	objectVersion = 54;
	objects = {
			attributes = {
				LastUpgradeCheck = 1430;
				ORGANIZATIONNAME = "";
      ''';
        xcodeProjectInfoFile.writeAsStringSync(xcodeProjectInfoFileContents);

        const String xcodeProjectSchemeFileContents = '''
   LastUpgradeVersion = "1430"
''';
        xcodeProjectSchemeFile.writeAsStringSync(xcodeProjectSchemeFileContents);

        final DateTime projectLastModified = xcodeProjectInfoFile.lastModifiedSync();

        final XcodeProjectObjectVersionMigration iosProjectMigration = XcodeProjectObjectVersionMigration(
          project,
          testLogger,
        );
        iosProjectMigration.migrate();

        expect(xcodeProjectInfoFile.lastModifiedSync(), projectLastModified);
        expect(xcodeProjectInfoFile.readAsStringSync(), xcodeProjectInfoFileContents);
        expect(xcodeProjectSchemeFile.readAsStringSync(), xcodeProjectSchemeFileContents);

        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('Xcode project is migrated to newest objectVersion', () {
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

        final XcodeProjectObjectVersionMigration iosProjectMigration = XcodeProjectObjectVersionMigration(
          project,
          testLogger,
        );
        iosProjectMigration.migrate();

        expect(xcodeProjectInfoFile.readAsStringSync(), '''
	classes = {
	};
	objectVersion = 54;
	objects = {
			attributes = {
				LastUpgradeCheck = 1430;
				ORGANIZATIONNAME = "";
''');

        expect(xcodeProjectSchemeFile.readAsStringSync(), '''
<Scheme
   LastUpgradeVersion = "1430"
   version = "1.3">
''');
        // Only print once even though 3 lines were changed.
        expect('Updating project for Xcode compatibility'.allMatches(testLogger.statusText).length, 1);
      });
    });

    group('update info.plist migration', () {
      late MemoryFileSystem memoryFileSystem;
      late BufferLogger testLogger;
      late FakeIosProject project;
      late File infoPlistFile;

      setUp(() {
        memoryFileSystem = MemoryFileSystem();
        testLogger = BufferLogger.test();
        project = FakeIosProject();
        infoPlistFile = memoryFileSystem.file('info.plist');
        project.defaultHostInfoPlist = infoPlistFile;
      });

      testWithoutContext('skipped if files are missing', () {
        final HostAppInfoPlistMigration iosProjectMigration = HostAppInfoPlistMigration(
          project,
          testLogger,
        );
        iosProjectMigration.migrate();
        expect(infoPlistFile.existsSync(), isFalse);

        expect(testLogger.traceText, contains('Info.plist not found, skipping host app Info.plist migration.'));
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skipped if nothing to upgrade', () {
        const String infoPlistFileContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CADisableMinimumFrameDurationOnPhone</key>
	<true/>
	<key>UIApplicationSupportsIndirectInputEvents</key>
	<true/>
</dict>
</plist>
''';
        infoPlistFile.writeAsStringSync(infoPlistFileContent);

        final HostAppInfoPlistMigration iosProjectMigration = HostAppInfoPlistMigration(
          project,
          testLogger,
        );
        final DateTime infoPlistFileLastModified = infoPlistFile.lastModifiedSync();
        iosProjectMigration.migrate();

        expect(infoPlistFile.lastModifiedSync(), infoPlistFileLastModified);
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('info.plist is migrated', () {
        const String infoPlistFileContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>
''';
        infoPlistFile.writeAsStringSync(infoPlistFileContent);

        final HostAppInfoPlistMigration iosProjectMigration = HostAppInfoPlistMigration(
          project,
          testLogger,
        );
        iosProjectMigration.migrate();
        expect(infoPlistFile.readAsStringSync(), equals('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CADisableMinimumFrameDurationOnPhone</key>
	<true/>
	<key>UIApplicationSupportsIndirectInputEvents</key>
	<true/>
</dict>
</plist>
'''));
      });
    });

    group('remove bitcode build setting', () {
      late MemoryFileSystem memoryFileSystem;
      late BufferLogger testLogger;
      late FakeIosProject project;
      late File xcodeProjectInfoFile;

      setUp(() {
        memoryFileSystem = MemoryFileSystem();
        testLogger = BufferLogger.test();
        project = FakeIosProject();
        xcodeProjectInfoFile = memoryFileSystem.file('project.pbxproj');
        project.xcodeProjectInfoFile = xcodeProjectInfoFile;
      });

      testWithoutContext('skipped if files are missing', () {
        final RemoveBitcodeMigration migration = RemoveBitcodeMigration(
          project,
          testLogger,
        );
        expect(migration.migrate(), isTrue);
        expect(xcodeProjectInfoFile.existsSync(), isFalse);

        expect(testLogger.traceText, contains('Xcode project not found, skipping removing bitcode migration'));
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skipped if nothing to upgrade', () {
        const String xcodeProjectInfoFileContents = 'IPHONEOS_DEPLOYMENT_TARGET = 12.0;';
        xcodeProjectInfoFile.writeAsStringSync(xcodeProjectInfoFileContents);
        final DateTime projectLastModified = xcodeProjectInfoFile.lastModifiedSync();

        final RemoveBitcodeMigration migration = RemoveBitcodeMigration(
          project,
          testLogger,
        );
        expect(migration.migrate(), isTrue);

        expect(xcodeProjectInfoFile.lastModifiedSync(), projectLastModified);
        expect(xcodeProjectInfoFile.readAsStringSync(), xcodeProjectInfoFileContents);

        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('bitcode build setting is removed', () {
        xcodeProjectInfoFile.writeAsStringSync('''
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ENABLE_BITCODE = YES;
				INFOPLIST_FILE = Runner/Info.plist;

				ENABLE_BITCODE = YES;
''');

        final RemoveBitcodeMigration migration = RemoveBitcodeMigration(
          project,
          testLogger,
        );
        expect(migration.migrate(), isTrue);

        expect(xcodeProjectInfoFile.readAsStringSync(), '''
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ENABLE_BITCODE = NO;
				INFOPLIST_FILE = Runner/Info.plist;

				ENABLE_BITCODE = NO;
''');
        // Only print once even though 2 lines were changed.
        expect('Disabling deprecated bitcode Xcode build setting'.allMatches(testLogger.warningText).length, 1);
      });
    });

    group('CocoaPods script readlink', () {
      late MemoryFileSystem memoryFileSystem;
      late BufferLogger testLogger;
      late FakeIosProject project;
      late File podRunnerFrameworksScript;
      late ProcessManager processManager;
      late XcodeProjectInterpreter xcode143ProjectInterpreter;

      setUp(() {
        memoryFileSystem = MemoryFileSystem();
        podRunnerFrameworksScript = memoryFileSystem.file('Pods-Runner-frameworks.sh');
        testLogger = BufferLogger.test();
        project = FakeIosProject();
        processManager = FakeProcessManager.any();
        xcode143ProjectInterpreter = XcodeProjectInterpreter.test(processManager: processManager, version: Version(14, 3, 0));
        project.podRunnerFrameworksScript = podRunnerFrameworksScript;
      });

      testWithoutContext('skipped if files are missing', () {
        final CocoaPodsScriptReadlink iosProjectMigration = CocoaPodsScriptReadlink(
          project,
          xcode143ProjectInterpreter,
          testLogger,
        );
        iosProjectMigration.migrate();
        expect(podRunnerFrameworksScript.existsSync(), isFalse);

        expect(testLogger.traceText, contains('CocoaPods Pods-Runner-frameworks.sh script not found'));
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skipped if nothing to upgrade', () {
        const String contents = r'''
  if [ -L "${source}" ]; then
    echo "Symlinked..."
    source="$(readlink -f "${source}")"
  fi''';
        podRunnerFrameworksScript.writeAsStringSync(contents);

        final CocoaPodsScriptReadlink iosProjectMigration = CocoaPodsScriptReadlink(
          project,
          xcode143ProjectInterpreter,
          testLogger,
        );
        iosProjectMigration.migrate();
        expect(podRunnerFrameworksScript.existsSync(), isTrue);
        expect(testLogger.traceText, isEmpty);
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skipped if Xcode version below 14.3', () {
        const String contents = r'''
  if [ -L "${source}" ]; then
    echo "Symlinked..."
    source="$(readlink "${source}")"
  fi''';
        podRunnerFrameworksScript.writeAsStringSync(contents);

        final XcodeProjectInterpreter xcode142ProjectInterpreter = XcodeProjectInterpreter.test(
          processManager: processManager,
          version: Version(14, 2, 0),
        );

        final CocoaPodsScriptReadlink iosProjectMigration = CocoaPodsScriptReadlink(
          project,
          xcode142ProjectInterpreter,
          testLogger,
        );
        iosProjectMigration.migrate();
        expect(podRunnerFrameworksScript.existsSync(), isTrue);
        expect(testLogger.traceText, contains('Detected Xcode version is 14.2.0, below 14.3, skipping "readlink -f" workaround'));
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('Xcode project is migrated', () {
        const String contents = r'''
  if [ -L "${source}" ]; then
    echo "Symlinked..."
    source="$(readlink "${source}")"
  fi''';
        podRunnerFrameworksScript.writeAsStringSync(contents);

        final CocoaPodsScriptReadlink iosProjectMigration = CocoaPodsScriptReadlink(
          project,
          xcode143ProjectInterpreter,
          testLogger,
        );
        iosProjectMigration.migrate();
        expect(podRunnerFrameworksScript.readAsStringSync(), r'''
  if [ -L "${source}" ]; then
    echo "Symlinked..."
    source="$(readlink -f "${source}")"
  fi
''');
        expect(testLogger.statusText, contains('Upgrading Pods-Runner-frameworks.sh'));
      });
    });

    group('Cocoapods migrate toolchain directory', () {
      late MemoryFileSystem memoryFileSystem;
      late BufferLogger testLogger;
      late FakeIosProject project;
      late Directory podRunnerTargetSupportFiles;
      late ProcessManager processManager;
      late XcodeProjectInterpreter xcode15ProjectInterpreter;

      setUp(() {
        memoryFileSystem = MemoryFileSystem();
        podRunnerTargetSupportFiles = memoryFileSystem.directory('Pods-Runner');
        testLogger = BufferLogger.test();
        project = FakeIosProject();
        processManager = FakeProcessManager.any();
        xcode15ProjectInterpreter = XcodeProjectInterpreter.test(processManager: processManager, version: Version(15, 0, 0));
        project.podRunnerTargetSupportFiles = podRunnerTargetSupportFiles;
      });

      testWithoutContext('skip if directory is missing', () {
        final CocoaPodsToolchainDirectoryMigration iosProjectMigration = CocoaPodsToolchainDirectoryMigration(
          project,
          xcode15ProjectInterpreter,
          testLogger,
        );
        iosProjectMigration.migrate();
        expect(podRunnerTargetSupportFiles.existsSync(), isFalse);

        expect(testLogger.traceText, contains('CocoaPods Pods-Runner Target Support Files not found'));
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skip if xcconfig files are missing', () {
        podRunnerTargetSupportFiles.createSync();
        final CocoaPodsToolchainDirectoryMigration iosProjectMigration = CocoaPodsToolchainDirectoryMigration(
          project,
          xcode15ProjectInterpreter,
          testLogger,
        );
        iosProjectMigration.migrate();
        expect(podRunnerTargetSupportFiles.existsSync(), isTrue);
        expect(testLogger.traceText, isEmpty);
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skip if nothing to upgrade', () {
        podRunnerTargetSupportFiles.createSync();
        final File debugConfig = podRunnerTargetSupportFiles.childFile('Pods-Runner.debug.xcconfig');
        const String contents = r'''
LD_RUNPATH_SEARCH_PATHS = $(inherited) /usr/lib/swift '@executable_path/../Frameworks' '@loader_path/Frameworks' "${TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}"
LIBRARY_SEARCH_PATHS = $(inherited) "${TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}" /usr/lib/swift
''';
        debugConfig.writeAsStringSync(contents);

        final File profileConfig = podRunnerTargetSupportFiles.childFile('Pods-Runner.profile.xcconfig');
        profileConfig.writeAsStringSync(contents);

        final File releaseConfig = podRunnerTargetSupportFiles.childFile('Pods-Runner.release.xcconfig');
        releaseConfig.writeAsStringSync(contents);

        final CocoaPodsToolchainDirectoryMigration iosProjectMigration = CocoaPodsToolchainDirectoryMigration(
          project,
          xcode15ProjectInterpreter,
          testLogger,
        );
        iosProjectMigration.migrate();
        expect(debugConfig.existsSync(), isTrue);
        expect(testLogger.traceText, isEmpty);
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('skipped if Xcode version below 15', () {
        podRunnerTargetSupportFiles.createSync();
        final File debugConfig = podRunnerTargetSupportFiles.childFile('Pods-Runner.debug.xcconfig');
        const String contents = r'''
LD_RUNPATH_SEARCH_PATHS = $(inherited) /usr/lib/swift '@executable_path/../Frameworks' '@loader_path/Frameworks' "${DT_TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}"
LIBRARY_SEARCH_PATHS = $(inherited) "${DT_TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}" /usr/lib/swift
''';
        debugConfig.writeAsStringSync(contents);

        final File profileConfig = podRunnerTargetSupportFiles.childFile('Pods-Runner.profile.xcconfig');
        profileConfig.writeAsStringSync(contents);

        final File releaseConfig = podRunnerTargetSupportFiles.childFile('Pods-Runner.release.xcconfig');
        releaseConfig.writeAsStringSync(contents);

        final XcodeProjectInterpreter xcode14ProjectInterpreter = XcodeProjectInterpreter.test(
          processManager: processManager,
          version: Version(14, 0, 0),
        );

        final CocoaPodsToolchainDirectoryMigration iosProjectMigration = CocoaPodsToolchainDirectoryMigration(
          project,
          xcode14ProjectInterpreter,
          testLogger,
        );
        iosProjectMigration.migrate();
        expect(debugConfig.existsSync(), isTrue);
        expect(testLogger.traceText, contains('Detected Xcode version is 14.0.0, below 15.0'));
        expect(testLogger.statusText, isEmpty);
      });

      testWithoutContext('Xcode project is migrated and ignores leading whitespace', () {
        podRunnerTargetSupportFiles.createSync();
        final File debugConfig = podRunnerTargetSupportFiles.childFile('Pods-Runner.debug.xcconfig');
        const String contents = r'''
LD_RUNPATH_SEARCH_PATHS = $(inherited) /usr/lib/swift '@executable_path/../Frameworks' '@loader_path/Frameworks' "${DT_TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}"
  LIBRARY_SEARCH_PATHS = $(inherited) "${DT_TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}" /usr/lib/swift
''';
        debugConfig.writeAsStringSync(contents);

        final File profileConfig = podRunnerTargetSupportFiles.childFile('Pods-Runner.profile.xcconfig');
        profileConfig.writeAsStringSync(contents);

        final File releaseConfig = podRunnerTargetSupportFiles.childFile('Pods-Runner.release.xcconfig');
        releaseConfig.writeAsStringSync(contents);

        final CocoaPodsToolchainDirectoryMigration iosProjectMigration = CocoaPodsToolchainDirectoryMigration(
          project,
          xcode15ProjectInterpreter,
          testLogger,
        );
        iosProjectMigration.migrate();

        expect(debugConfig.existsSync(), isTrue);
        expect(debugConfig.readAsStringSync(), r'''
LD_RUNPATH_SEARCH_PATHS = $(inherited) /usr/lib/swift '@executable_path/../Frameworks' '@loader_path/Frameworks' "${TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}"
  LIBRARY_SEARCH_PATHS = $(inherited) "${TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}" /usr/lib/swift
''');
        expect(profileConfig.existsSync(), isTrue);
        expect(profileConfig.readAsStringSync(), r'''
LD_RUNPATH_SEARCH_PATHS = $(inherited) /usr/lib/swift '@executable_path/../Frameworks' '@loader_path/Frameworks' "${TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}"
  LIBRARY_SEARCH_PATHS = $(inherited) "${TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}" /usr/lib/swift
''');
        expect(releaseConfig.existsSync(), isTrue);
        expect(releaseConfig.readAsStringSync(), r'''
LD_RUNPATH_SEARCH_PATHS = $(inherited) /usr/lib/swift '@executable_path/../Frameworks' '@loader_path/Frameworks' "${TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}"
  LIBRARY_SEARCH_PATHS = $(inherited) "${TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}" /usr/lib/swift
''');
        expect(testLogger.statusText, contains('Upgrading Pods-Runner.debug.xcconfig'));
        expect(testLogger.statusText, contains('Upgrading Pods-Runner.profile.xcconfig'));
        expect(testLogger.statusText, contains('Upgrading Pods-Runner.release.xcconfig'));
      });
    });
  });

  group('update Xcode script build phase', () {
    late MemoryFileSystem memoryFileSystem;
    late BufferLogger testLogger;
    late FakeIosProject project;
    late File xcodeProjectInfoFile;

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      testLogger = BufferLogger.test();
      project = FakeIosProject();
      xcodeProjectInfoFile = memoryFileSystem.file('project.pbxproj');
      project.xcodeProjectInfoFile = xcodeProjectInfoFile;
    });

    testWithoutContext('skipped if files are missing', () {
      final XcodeScriptBuildPhaseMigration iosProjectMigration = XcodeScriptBuildPhaseMigration(
        project,
        testLogger,
      );
      iosProjectMigration.migrate();
      expect(xcodeProjectInfoFile.existsSync(), isFalse);

      expect(testLogger.traceText, contains('Xcode project not found, skipping script build phase dependency analysis removal'));
      expect(testLogger.statusText, isEmpty);
    });

    testWithoutContext('skipped if nothing to upgrade', () {
      const String xcodeProjectInfoFileContents = '''
/* Begin PBXShellScriptBuildPhase section */
		3B06AD1E1E4923F5004D2608 /* Thin Binary */ = {
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
      ''';
      xcodeProjectInfoFile.writeAsStringSync(xcodeProjectInfoFileContents);

      final DateTime projectLastModified = xcodeProjectInfoFile.lastModifiedSync();

      final XcodeScriptBuildPhaseMigration iosProjectMigration = XcodeScriptBuildPhaseMigration(
        project,
        testLogger,
      );
      iosProjectMigration.migrate();

      expect(xcodeProjectInfoFile.lastModifiedSync(), projectLastModified);
      expect(xcodeProjectInfoFile.readAsStringSync(), xcodeProjectInfoFileContents);

      expect(testLogger.statusText, isEmpty);
    });

    testWithoutContext('alwaysOutOfDate is migrated', () {
      xcodeProjectInfoFile.writeAsStringSync('''
/* Begin PBXShellScriptBuildPhase section */
		3B06AD1E1E4923F5004D2608 /* Thin Binary */ = {
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (

		9740EEB61CF901F6004384FC /* Run Script */ = {
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
			);
''');

      final XcodeScriptBuildPhaseMigration iosProjectMigration = XcodeScriptBuildPhaseMigration(
        project,
        testLogger,
      );
      iosProjectMigration.migrate();

      expect(xcodeProjectInfoFile.readAsStringSync(), '''
/* Begin PBXShellScriptBuildPhase section */
		3B06AD1E1E4923F5004D2608 /* Thin Binary */ = {
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (

		9740EEB61CF901F6004384FC /* Run Script */ = {
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
			);
''');
      expect(testLogger.statusText, contains('Removing script build phase dependency analysis'));
    });
  });

  group('update Xcode Thin Binary build phase to have input path', () {
    late MemoryFileSystem memoryFileSystem;
    late BufferLogger testLogger;
    late FakeIosProject project;
    late File xcodeProjectInfoFile;

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      testLogger = BufferLogger.test();
      project = FakeIosProject();
      xcodeProjectInfoFile = memoryFileSystem.file('project.pbxproj');
      project.xcodeProjectInfoFile = xcodeProjectInfoFile;
    });

    testWithoutContext('skipped if files are missing', () {
      final XcodeThinBinaryBuildPhaseInputPathsMigration iosProjectMigration = XcodeThinBinaryBuildPhaseInputPathsMigration(
        project,
        testLogger,
      );
      iosProjectMigration.migrate();
      expect(xcodeProjectInfoFile.existsSync(), isFalse);

      expect(testLogger.traceText, contains('Xcode project not found, skipping script build phase dependency analysis removal'));
      expect(testLogger.statusText, isEmpty);
    });

    testWithoutContext('skipped if nothing to upgrade', () {
      const String xcodeProjectInfoFileContents = r'''
/* Begin PBXShellScriptBuildPhase section */
		3B06AD1E1E4923F5004D2608 /* Thin Binary */ = {
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
				"${TARGET_BUILD_DIR}/${INFOPLIST_PATH}",
			);
      ''';
      xcodeProjectInfoFile.writeAsStringSync(xcodeProjectInfoFileContents);

      final DateTime projectLastModified = xcodeProjectInfoFile.lastModifiedSync();

      final XcodeThinBinaryBuildPhaseInputPathsMigration iosProjectMigration = XcodeThinBinaryBuildPhaseInputPathsMigration(
        project,
        testLogger,
      );
      iosProjectMigration.migrate();

      expect(xcodeProjectInfoFile.lastModifiedSync(), projectLastModified);
      expect(xcodeProjectInfoFile.readAsStringSync(), xcodeProjectInfoFileContents);

      expect(testLogger.statusText, isEmpty);
    });

    testWithoutContext('Thin Binary inputPaths is migrated', () {
      xcodeProjectInfoFile.writeAsStringSync(r'''
/* Begin PBXShellScriptBuildPhase section */
		3B06AD1E1E4923F5004D2608 /* Thin Binary */ = {
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
			);

		9740EEB61CF901F6004384FC /* Run Script */ = {
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
			);
''');

      final XcodeThinBinaryBuildPhaseInputPathsMigration iosProjectMigration = XcodeThinBinaryBuildPhaseInputPathsMigration(
        project,
        testLogger,
      );
      iosProjectMigration.migrate();

      expect(xcodeProjectInfoFile.readAsStringSync(), r'''
/* Begin PBXShellScriptBuildPhase section */
		3B06AD1E1E4923F5004D2608 /* Thin Binary */ = {
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
				"${TARGET_BUILD_DIR}/${INFOPLIST_PATH}",
			);

		9740EEB61CF901F6004384FC /* Run Script */ = {
			isa = PBXShellScriptBuildPhase;
			alwaysOutOfDate = 1;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
			);
''');
      expect(testLogger.statusText, contains('Adding input path to Thin Binary build phase.'));
    });
  });
}

class FakeIosProject extends Fake implements IosProject {
  @override
  File xcodeProjectWorkspaceData = MemoryFileSystem.test().file('xcodeProjectWorkspaceData');

  @override
  File? xcodeWorkspaceSharedSettings = MemoryFileSystem.test().file('xcodeWorkspaceSharedSettings');

  @override
  File xcodeProjectInfoFile = MemoryFileSystem.test().file('xcodeProjectInfoFile');

  @override
  File xcodeProjectSchemeFile = MemoryFileSystem.test().file('xcodeProjectSchemeFile');

  @override
  File appFrameworkInfoPlist = MemoryFileSystem.test().file('appFrameworkInfoPlist');

  @override
  File defaultHostInfoPlist = MemoryFileSystem.test().file('defaultHostInfoPlist');

  @override
  File podfile = MemoryFileSystem.test().file('Podfile');

  @override
  File podRunnerFrameworksScript = MemoryFileSystem.test().file('podRunnerFrameworksScript');

  @override
  Directory podRunnerTargetSupportFiles = MemoryFileSystem.test().directory('Pods-Runner');
}

class FakeIOSMigrator extends ProjectMigrator {
  FakeIOSMigrator()
    : super(BufferLogger.test());

  @override
  void migrate() {}

  @override
  String migrateLine(String line) {
    return line;
  }
}
