// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/macos/migrations/flutter_application_migration.dart';
import 'package:flutter_tools/src/macos/migrations/macos_deployment_target_migration.dart';
import 'package:flutter_tools/src/macos/migrations/remove_macos_framework_link_and_embedding_migration.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';

void main() {
  group('remove link and embed migration', () {
    late TestUsage testUsage;
    late MemoryFileSystem memoryFileSystem;
    late BufferLogger testLogger;
    late FakeMacOSProject macOSProject;
    late File xcodeProjectInfoFile;

    setUp(() {
      testUsage = TestUsage();
      memoryFileSystem = MemoryFileSystem.test();
      xcodeProjectInfoFile = memoryFileSystem.file('project.pbxproj');
      testLogger = BufferLogger.test();
      macOSProject = FakeMacOSProject();
      macOSProject.xcodeProjectInfoFile = xcodeProjectInfoFile;
    });

    testWithoutContext('skipped if files are missing', () {
      final RemoveMacOSFrameworkLinkAndEmbeddingMigration macosProjectMigration =
          RemoveMacOSFrameworkLinkAndEmbeddingMigration(
        macOSProject,
        testLogger,
        testUsage,
      );
      macosProjectMigration.migrate();
      expect(testUsage.events, isEmpty);

      expect(xcodeProjectInfoFile.existsSync(), isFalse);

      expect(
          testLogger.traceText,
          contains(
              'Xcode project not found, skipping framework link and embedding migration'));
      expect(testLogger.statusText, isEmpty);
    });

    testWithoutContext('skipped if nothing to upgrade', () {
      const String contents = 'Nothing to upgrade';
      xcodeProjectInfoFile.writeAsStringSync(contents);
      final DateTime projectLastModified =
          xcodeProjectInfoFile.lastModifiedSync();

      final RemoveMacOSFrameworkLinkAndEmbeddingMigration macosProjectMigration =
          RemoveMacOSFrameworkLinkAndEmbeddingMigration(
        macOSProject,
        testLogger,
        testUsage,
      );
      macosProjectMigration.migrate();
      expect(testUsage.events, isEmpty);

      expect(xcodeProjectInfoFile.lastModifiedSync(), projectLastModified);
      expect(xcodeProjectInfoFile.readAsStringSync(), contents);

      expect(testLogger.statusText, isEmpty);
    });

    testWithoutContext('skips migrating script with embed', () {
      const String contents = r'''
shellScript = "echo \"$PRODUCT_NAME.app\" > \"$PROJECT_DIR\"/Flutter/ephemeral/.app_filename && \"$FLUTTER_ROOT\"/packages/flutter_tools/bin/macos_assemble.sh embed\n";
			''';
      xcodeProjectInfoFile.writeAsStringSync(contents);

      final RemoveMacOSFrameworkLinkAndEmbeddingMigration macosProjectMigration =
          RemoveMacOSFrameworkLinkAndEmbeddingMigration(
        macOSProject,
        testLogger,
        testUsage,
      );
      macosProjectMigration.migrate();
      expect(xcodeProjectInfoFile.readAsStringSync(), contents);
      expect(testLogger.statusText, isEmpty);
    });

    testWithoutContext('Xcode project is migrated', () {
      xcodeProjectInfoFile.writeAsStringSync(r'''
prefix D73912F022F37F9E000D13A0
D73912F222F3801D000D13A0 suffix
D73912EF22F37F9E000D13A0
keep this 1
  33D1A10422148B71006C7A3E spaces
33D1A10522148B93006C7A3E
			shellScript = "echo \"$PRODUCT_NAME.app\" > \"$PROJECT_DIR\"/Flutter/ephemeral/.app_filename\n";
keep this 2
''');

      final RemoveMacOSFrameworkLinkAndEmbeddingMigration macosProjectMigration =
          RemoveMacOSFrameworkLinkAndEmbeddingMigration(
        macOSProject,
        testLogger,
        testUsage,
      );
      macosProjectMigration.migrate();
      expect(testUsage.events, isEmpty);

      expect(xcodeProjectInfoFile.readAsStringSync(), r'''
keep this 1
			shellScript = "echo \"$PRODUCT_NAME.app\" > \"$PROJECT_DIR\"/Flutter/ephemeral/.app_filename && \"$FLUTTER_ROOT\"/packages/flutter_tools/bin/macos_assemble.sh embed\n";
keep this 2
''');
      expect(testLogger.statusText, contains('Upgrading project.pbxproj'));
    });

    testWithoutContext('migration fails with leftover App.framework reference', () {
      xcodeProjectInfoFile.writeAsStringSync('''
		D73912F022F37F9bogus /* App.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = D73912F022F37F9bogus /* App.framework */; };
''');

      final RemoveMacOSFrameworkLinkAndEmbeddingMigration macosProjectMigration =
          RemoveMacOSFrameworkLinkAndEmbeddingMigration(
        macOSProject,
        testLogger,
        testUsage,
      );

      expect(macosProjectMigration.migrate,
          throwsToolExit(message: 'Your Xcode project requires migration'));
      expect(testUsage.events, contains(
        const TestUsageEvent('macos-migration', 'remove-frameworks', label: 'failure'),
      ));
    });

    testWithoutContext(
        'migration fails with leftover FlutterMacOS.framework reference', () {
      xcodeProjectInfoFile.writeAsStringSync('''
				33D1A10522148B93bogus /* FlutterMacOS.framework in Bundle Framework */,
''');

      final RemoveMacOSFrameworkLinkAndEmbeddingMigration macosProjectMigration =
          RemoveMacOSFrameworkLinkAndEmbeddingMigration(
        macOSProject,
        testLogger,
        testUsage,
      );
      expect(macosProjectMigration.migrate,
          throwsToolExit(message: 'Your Xcode project requires migration'));
      expect(testUsage.events, contains(
        const TestUsageEvent('macos-migration', 'remove-frameworks', label: 'failure'),
      ));
    });
  });

  group('update deployment target version', () {
    late MemoryFileSystem memoryFileSystem;
    late BufferLogger testLogger;
    late FakeMacOSProject project;
    late File xcodeProjectInfoFile;
    late File podfile;

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      testLogger = BufferLogger.test();
      project = FakeMacOSProject();
      xcodeProjectInfoFile = memoryFileSystem.file('project.pbxproj');
      project.xcodeProjectInfoFile = xcodeProjectInfoFile;

      podfile = memoryFileSystem.file('Podfile');
      project.podfile = podfile;
    });

    testWithoutContext('skipped if files are missing', () {
      final MacOSDeploymentTargetMigration macOSProjectMigration = MacOSDeploymentTargetMigration(
        project,
        testLogger,
      );
      macOSProjectMigration.migrate();
      expect(xcodeProjectInfoFile.existsSync(), isFalse);
      expect(podfile.existsSync(), isFalse);

      expect(testLogger.traceText, contains('Xcode project not found, skipping macOS deployment target version migration'));
      expect(testLogger.traceText, contains('Podfile not found, skipping global platform macOS version migration'));
      expect(testLogger.statusText, isEmpty);
    });

    testWithoutContext('skipped if nothing to upgrade', () {
      const String xcodeProjectInfoFileContents = 'MACOSX_DEPLOYMENT_TARGET = 10.14;';
      xcodeProjectInfoFile.writeAsStringSync(xcodeProjectInfoFileContents);

      final DateTime projectLastModified = xcodeProjectInfoFile.lastModifiedSync();

      const String podfileFileContents = "# platform :osx, '10.14'";
      podfile.writeAsStringSync(podfileFileContents);
      final DateTime podfileLastModified = podfile.lastModifiedSync();

      final MacOSDeploymentTargetMigration macOSProjectMigration = MacOSDeploymentTargetMigration(
        project,
        testLogger,
      );
      macOSProjectMigration.migrate();

      expect(xcodeProjectInfoFile.lastModifiedSync(), projectLastModified);
      expect(xcodeProjectInfoFile.readAsStringSync(), xcodeProjectInfoFileContents);
      expect(podfile.lastModifiedSync(), podfileLastModified);
      expect(podfile.readAsStringSync(), podfileFileContents);

      expect(testLogger.statusText, isEmpty);
    });

    testWithoutContext('Xcode project is migrated from 10.11 to 10.14', () {
      xcodeProjectInfoFile.writeAsStringSync('''
 				GCC_WARN_UNUSED_VARIABLE = YES;
				MACOSX_DEPLOYMENT_TARGET = 10.11;
 				MTL_ENABLE_DEBUG_INFO = YES;
''');

      podfile.writeAsStringSync('''
# platform :osx, '10.11'
platform :osx, '10.11'
''');

      final MacOSDeploymentTargetMigration macOSProjectMigration = MacOSDeploymentTargetMigration(
        project,
        testLogger,
      );
      macOSProjectMigration.migrate();

      expect(xcodeProjectInfoFile.readAsStringSync(), '''
 				GCC_WARN_UNUSED_VARIABLE = YES;
				MACOSX_DEPLOYMENT_TARGET = 10.14;
 				MTL_ENABLE_DEBUG_INFO = YES;
''');

      expect(podfile.readAsStringSync(), '''
# platform :osx, '10.14'
platform :osx, '10.14'
''');
      // Only print once even though 2 lines were changed.
      expect('Updating minimum macOS deployment target to 10.14'.allMatches(testLogger.statusText).length, 1);
    });

    testWithoutContext('Xcode project is migrated from 10.13 to 10.14', () {
      xcodeProjectInfoFile.writeAsStringSync('''
 				GCC_WARN_UNUSED_VARIABLE = YES;
				MACOSX_DEPLOYMENT_TARGET = 10.13;
 				MTL_ENABLE_DEBUG_INFO = YES;
''');

      podfile.writeAsStringSync('''
# platform :osx, '10.13'
platform :osx, '10.13'
''');

      final MacOSDeploymentTargetMigration macOSProjectMigration = MacOSDeploymentTargetMigration(
        project,
        testLogger,
      );
      macOSProjectMigration.migrate();

      expect(xcodeProjectInfoFile.readAsStringSync(), '''
 				GCC_WARN_UNUSED_VARIABLE = YES;
				MACOSX_DEPLOYMENT_TARGET = 10.14;
 				MTL_ENABLE_DEBUG_INFO = YES;
''');

      expect(podfile.readAsStringSync(), '''
# platform :osx, '10.14'
platform :osx, '10.14'
''');
      // Only print once even though 2 lines were changed.
      expect('Updating minimum macOS deployment target to 10.14'.allMatches(testLogger.statusText).length, 1);
    });
  });

  group('update NSPrincipalClass from FlutterApplication to NSApplication', () {
    late MemoryFileSystem memoryFileSystem;
    late BufferLogger testLogger;
    late FakeMacOSProject project;
    late File infoPlistFile;
    late FakePlistParser fakePlistParser;
    late FlutterProjectFactory flutterProjectFactory;

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      fakePlistParser = FakePlistParser();
      testLogger = BufferLogger.test();
      project = FakeMacOSProject();
      infoPlistFile = memoryFileSystem.file('Info.plist');
      project.defaultHostInfoPlist = infoPlistFile;
      flutterProjectFactory = FlutterProjectFactory(
        fileSystem: memoryFileSystem,
        logger: testLogger,
      );
    });

    void testWithMocks(String description, Future<void> Function() testMethod) {
      testUsingContext(description, testMethod, overrides: <Type, Generator>{
        FileSystem: () => memoryFileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        PlistParser: () => fakePlistParser,
        FlutterProjectFactory: () => flutterProjectFactory,
      });
    }

    testWithMocks('skipped if files are missing', () async {
      final FlutterApplicationMigration macOSProjectMigration = FlutterApplicationMigration(
        project,
        testLogger,
      );
      macOSProjectMigration.migrate();
      expect(infoPlistFile.existsSync(), isFalse);

      expect(testLogger.traceText, isEmpty);
      expect(testLogger.statusText, isEmpty);
    });

    testWithMocks('skipped if no NSPrincipalClass key exists to upgrade', () async {
      final FlutterApplicationMigration macOSProjectMigration = FlutterApplicationMigration(
        project,
        testLogger,
      );
      infoPlistFile.writeAsStringSync('contents'); // Just so it exists: parser is a fake.
      macOSProjectMigration.migrate();
      expect(fakePlistParser.getStringValueFromFile(infoPlistFile.path, PlistParser.kNSPrincipalClassKey), isNull);
      expect(testLogger.statusText, isEmpty);
    });

    testWithMocks('skipped if already de-upgraded (or never migrated)', () async {
      fakePlistParser.setProperty(PlistParser.kNSPrincipalClassKey, 'NSApplication');
      final FlutterApplicationMigration macOSProjectMigration = FlutterApplicationMigration(
        project,
        testLogger,
      );
      infoPlistFile.writeAsStringSync('contents'); // Just so it exists: parser is a fake.
      macOSProjectMigration.migrate();
      expect(fakePlistParser.getStringValueFromFile(infoPlistFile.path, PlistParser.kNSPrincipalClassKey), 'NSApplication');
      expect(testLogger.statusText, isEmpty);
    });

    testWithMocks('Info.plist migrated to use NSApplication', () async {
      fakePlistParser.setProperty(PlistParser.kNSPrincipalClassKey, 'FlutterApplication');
      final FlutterApplicationMigration macOSProjectMigration = FlutterApplicationMigration(
        project,
        testLogger,
      );
      infoPlistFile.writeAsStringSync('contents'); // Just so it exists: parser is a fake.
      macOSProjectMigration.migrate();
      expect(fakePlistParser.getStringValueFromFile(infoPlistFile.path, PlistParser.kNSPrincipalClassKey), 'NSApplication');
      // Only print once.
      expect('Updating ${infoPlistFile.basename} to use NSApplication instead of FlutterApplication.'.allMatches(testLogger.statusText).length, 1);
    });

    testWithMocks('Skip if NSPrincipalClass is not NSApplication', () async {
      const String differentApp = 'DIFFERENTApplication';
      fakePlistParser.setProperty(PlistParser.kNSPrincipalClassKey, differentApp);
      final FlutterApplicationMigration macOSProjectMigration = FlutterApplicationMigration(
        project,
        testLogger,
      );
      infoPlistFile.writeAsStringSync('contents'); // Just so it exists: parser is a fake.
      macOSProjectMigration.migrate();
      expect(fakePlistParser.getStringValueFromFile(infoPlistFile.path, PlistParser.kNSPrincipalClassKey), differentApp);
      expect(testLogger.traceText, isEmpty);
    });
  });
}

class FakeMacOSProject extends Fake implements MacOSProject {
  @override
  File xcodeProjectInfoFile = MemoryFileSystem.test().file('xcodeProjectInfoFile');

  @override
  File defaultHostInfoPlist = MemoryFileSystem.test().file('InfoplistFile');

  @override
  File podfile = MemoryFileSystem.test().file('Podfile');
}
