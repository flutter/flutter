// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/ios/migrations/ios_deployment_target_migration.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

void main() {
  group('IOSDeploymentTargetMigration', () {
    late MemoryFileSystem memoryFileSystem;
    late BufferLogger testLogger;
    late FakeIosProject mockIosProject;
    late File xcodeProjectInfoFile;
    late File podfile;
    late File appFrameworkInfoPlist;

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
      testLogger = BufferLogger.test();
      mockIosProject = FakeIosProject();

      xcodeProjectInfoFile = memoryFileSystem.file('project.pbxproj');
      podfile = memoryFileSystem.file('Podfile');
      appFrameworkInfoPlist = memoryFileSystem.file('AppFrameworkInfo.plist');

      mockIosProject.xcodeProjectInfoFile = xcodeProjectInfoFile;
      mockIosProject.podfile = podfile;
      mockIosProject.appFrameworkInfoPlist = appFrameworkInfoPlist;
    });

    testWithoutContext('skips migration if files do not exist', () async {
      final migration = IOSDeploymentTargetMigration(mockIosProject, testLogger);

      await migration.migrate();

      expect(testLogger.traceText, contains('Xcode project not found'));
      expect(testLogger.traceText, contains('AppFrameworkInfo.plist not found'));
      expect(testLogger.traceText, contains('Podfile not found'));
      expect(xcodeProjectInfoFile.existsSync(), isFalse);
      expect(podfile.existsSync(), isFalse);
      expect(appFrameworkInfoPlist.existsSync(), isFalse);
    });

    testWithoutContext('migrates project.pbxproj', () async {
      xcodeProjectInfoFile.writeAsStringSync('''
IPHONEOS_DEPLOYMENT_TARGET = 8.0;
IPHONEOS_DEPLOYMENT_TARGET = 9.0;
IPHONEOS_DEPLOYMENT_TARGET = 11.0;
IPHONEOS_DEPLOYMENT_TARGET = 12.0;
IPHONEOS_DEPLOYMENT_TARGET = 13.0;
''');

      final migration = IOSDeploymentTargetMigration(mockIosProject, testLogger);

      await migration.migrate();

      expect(testLogger.statusText, contains('Updating minimum iOS deployment target to 13.0.'));
      expect(xcodeProjectInfoFile.readAsStringSync(), '''
IPHONEOS_DEPLOYMENT_TARGET = 13.0;
IPHONEOS_DEPLOYMENT_TARGET = 13.0;
IPHONEOS_DEPLOYMENT_TARGET = 13.0;
IPHONEOS_DEPLOYMENT_TARGET = 13.0;
IPHONEOS_DEPLOYMENT_TARGET = 13.0;
''');
    });

    testWithoutContext('migrates Podfile', () async {
      podfile.writeAsStringSync('''
platform :ios, '9.0'
platform :ios, '11.0'
platform :ios, '12.0'
platform :ios, '13.0'
''');

      final migration = IOSDeploymentTargetMigration(mockIosProject, testLogger);

      await migration.migrate();

      expect(testLogger.statusText, contains('Updating minimum iOS deployment target to 13.0.'));
      expect(podfile.readAsStringSync(), '''
platform :ios, '13.0'
platform :ios, '13.0'
platform :ios, '13.0'
platform :ios, '13.0'
''');
    });

    testWithoutContext('migrates AppFrameworkInfo.plist', () async {
      appFrameworkInfoPlist.writeAsStringSync('''
<dict>
  <key>MinimumOSVersion</key>
  <string>8.0</string>
  <key>MinimumOSVersion</key>
  <string>9.0</string>
  <key>MinimumOSVersion</key>
  <string>11.0</string>
  <key>MinimumOSVersion</key>
  <string>12.0</string>
  <key>MinimumOSVersion</key>
  <string>13.0</string>
</dict>
''');

      final migration = IOSDeploymentTargetMigration(mockIosProject, testLogger);

      await migration.migrate();

      // It should remove the keys entirely
      expect(appFrameworkInfoPlist.readAsStringSync(), '''
<dict>
</dict>
''');
    });

    testWithoutContext('does not migrate if already up to date', () async {
      xcodeProjectInfoFile.writeAsStringSync('IPHONEOS_DEPLOYMENT_TARGET = 14.0;');
      podfile.writeAsStringSync("platform :ios, '14.0'");
      appFrameworkInfoPlist.writeAsStringSync('''
<dict>
  <key>MinimumOSVersion</key>
  <string>14.0</string>
</dict>
''');

      final migration = IOSDeploymentTargetMigration(mockIosProject, testLogger);

      await migration.migrate();

      expect(testLogger.statusText, isEmpty);
      expect(xcodeProjectInfoFile.readAsStringSync(), 'IPHONEOS_DEPLOYMENT_TARGET = 14.0;');
      expect(podfile.readAsStringSync(), "platform :ios, '14.0'");
      expect(appFrameworkInfoPlist.readAsStringSync(), '''
<dict>
  <key>MinimumOSVersion</key>
  <string>14.0</string>
</dict>
''');
    });
  });
}

class FakeIosProject extends Fake implements IosProject {
  @override
  late File xcodeProjectInfoFile;

  @override
  late File podfile;

  @override
  late File appFrameworkInfoPlist;
}
