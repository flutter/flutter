// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/ios/ios_project_migration.dart';
import 'package:flutter_tools/src/project.dart';

import '../../src/common.dart';

void main () {
  group('iOS project migration', () {
    MemoryFileSystem memoryFileSystem;
    BufferLogger testLogger;
    MockIosProject mockIosProject;
    File xcodeProjectInfoFile;
    File podfile;

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      xcodeProjectInfoFile = memoryFileSystem.file('project.pbxproj');
      podfile = memoryFileSystem.file('Podfile');

      testLogger = BufferLogger(
        terminal: AnsiTerminal(
          stdio: null,
          platform: const LocalPlatform(),
        ),
        outputPreferences: OutputPreferences.test(),
      );

      mockIosProject = MockIosProject();
      when(mockIosProject.xcodeProjectInfoFile).thenReturn(xcodeProjectInfoFile);
      when(mockIosProject.podfile).thenReturn(podfile);
    });

    testWithoutContext('skipped if files are missing', () {
      final IOSProjectMigration iosProjectMigration = IOSProjectMigration(mockIosProject, testLogger);
      iosProjectMigration.migrate();

      expect(xcodeProjectInfoFile.existsSync(), isFalse);
      expect(podfile.existsSync(), isFalse);

      expect(testLogger.traceText, contains('Xcode project not found, skipping migration'));
      expect(testLogger.traceText, contains('Podfile not found, skipping migration'));
      expect(testLogger.statusText, isEmpty);
    });

    testWithoutContext('skipped if nothing to upgrade', () {
      const String contents = 'Nothing to upgrade';
      xcodeProjectInfoFile.writeAsStringSync(contents);
      final DateTime projectLastModified = xcodeProjectInfoFile.lastModifiedSync();

      podfile.writeAsStringSync(contents);
      final DateTime podfileLastModified = podfile.lastModifiedSync();

      final IOSProjectMigration iosProjectMigration = IOSProjectMigration(mockIosProject, testLogger);
      iosProjectMigration.migrate();

      expect(xcodeProjectInfoFile.lastModifiedSync(), projectLastModified);
      expect(xcodeProjectInfoFile.readAsStringSync(), contents);

      expect(podfile.lastModifiedSync(), podfileLastModified);
      expect(podfile.readAsStringSync(), contents);
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

      final IOSProjectMigration iosProjectMigration = IOSProjectMigration(mockIosProject, testLogger);
      iosProjectMigration.migrate();

      expect(xcodeProjectInfoFile.readAsStringSync(), '''
keep this 1
			shellScript = "/bin/sh "\$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh\\" embed_and_thin";
keep this 2

''');
      expect(testLogger.statusText, contains('Upgrading project.pbxproj'));
    });

  testWithoutContext('Podfile is migrated', () {
    podfile.writeAsStringSync('''
  end
end

# Prevent Cocoapods from embedding a second Flutter framework and causing an error with the new Xcode build system.
install! 'cocoapods', :disable_input_output_paths => true

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
''');

    final IOSProjectMigration iosProjectMigration = IOSProjectMigration(mockIosProject, testLogger);
    iosProjectMigration.migrate();

    expect(podfile.readAsStringSync(), '''
  end
end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|

''');
    expect(testLogger.statusText, contains('Upgrading Podfile'));
  });
});
}

class MockIosProject extends Mock implements IosProject {}
