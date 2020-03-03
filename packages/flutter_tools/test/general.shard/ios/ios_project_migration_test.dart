// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/ios/migrations/remove_framework_link_and_embedding_migration.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/project.dart';

import '../../src/common.dart';

void main () {
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
      );
      expect(iosProjectMigration.migrate(), isTrue);

      expect(xcodeProjectInfoFile.existsSync(), isFalse);

      expect(testLogger.traceText, contains('Xcode project not found, skipping migration'));
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
      );
      expect(iosProjectMigration.migrate(), isTrue);

      expect(xcodeProjectInfoFile.lastModifiedSync(), projectLastModified);
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
      );
      expect(iosProjectMigration.migrate(), isTrue);

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
      );
      expect(iosProjectMigration.migrate(), isFalse);
      expect(testLogger.errorText, contains('Your Xcode project requires migration'));
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
      );
      expect(iosProjectMigration.migrate(), isFalse);
      expect(testLogger.errorText, contains('Your Xcode project requires migration'));
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
      );
      expect(iosProjectMigration.migrate(), isFalse);
      expect(testLogger.errorText, contains('Your Xcode project requires migration'));
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
      );
      expect(iosProjectMigration.migrate(), isTrue);
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
      );
      expect(iosProjectMigration.migrate(), isFalse);
      expect(testLogger.errorText, contains('Your Xcode project requires migration'));
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
      );
      expect(iosProjectMigration.migrate(), isFalse);
      expect(testLogger.errorText, contains('Your Xcode project requires migration'));
    });
  });
}

class MockIosProject extends Mock implements IosProject {}
class MockXcode extends Mock implements Xcode {}
