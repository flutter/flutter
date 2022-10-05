// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/macos/migrations/remove_macos_framework_link_and_embedding_migration.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/xcode_project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

void main() {
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
    expect(macosProjectMigration.migrate(), isTrue);
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
    expect(macosProjectMigration.migrate(), isTrue);
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
    expect(macosProjectMigration.migrate(), isTrue);
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
    expect(macosProjectMigration.migrate(), isTrue);
    expect(testUsage.events, isEmpty);

    expect(xcodeProjectInfoFile.readAsStringSync(), r'''
keep this 1
			shellScript = "echo \"$PRODUCT_NAME.app\" > \"$PROJECT_DIR\"/Flutter/ephemeral/.app_filename && \"$FLUTTER_ROOT\"/packages/flutter_tools/bin/macos_assemble.sh embed\n";
keep this 2
''');
    expect(testLogger.statusText, contains('Upgrading project.pbxproj'));
  });

  testWithoutContext('migration fails with leftover App.framework reference',
      () {
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
}

class FakeMacOSProject extends Fake implements MacOSProject {
  @override
  File xcodeProjectInfoFile = MemoryFileSystem.test().file('xcodeProjectInfoFile');
}
