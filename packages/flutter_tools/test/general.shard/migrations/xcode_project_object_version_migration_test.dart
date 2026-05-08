// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/migrations/xcode_project_object_version_migration.dart';
import 'package:flutter_tools/src/xcode_project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

void main() {
  const migratedObjectVersion = '54';
  const migratedLastUpgradeCheck = '1510';
  const migratedLastUpgradeVersion = '1510';

  group('XcodeProjectObjectVersionMigration', () {
    late MemoryFileSystem memoryFileSystem;
    late BufferLogger testLogger;
    late FakeXcodeBasedProject fakeProject;

    setUp(() {
      memoryFileSystem = MemoryFileSystem.test();
      testLogger = BufferLogger.test();
      fakeProject = FakeXcodeBasedProject(fileSystem: memoryFileSystem);
    });

    testWithoutContext('updates all values when below target', () async {
      fakeProject.xcodeProjectInfoFile.writeAsStringSync(
        _projectFilePart(objectVersion: '46', lastUpgradeCheck: '1400'),
      );
      fakeProject.schemeFile.writeAsStringSync(_schemeFilePart(lastUpgradeVersion: '1400'));
      final migration = XcodeProjectObjectVersionMigration(fakeProject, testLogger);

      await migration.migrate();

      expect(testLogger.statusText, contains('Updating project for Xcode compatibility.'));
      expect(
        fakeProject.xcodeProjectInfoFile.readAsStringSync(),
        _projectFilePart(
          objectVersion: migratedObjectVersion,
          lastUpgradeCheck: migratedLastUpgradeCheck,
        ),
      );
      expect(fakeProject.schemeFile.readAsStringSync(), _schemeFilePart(
        lastUpgradeVersion: migratedLastUpgradeVersion,
      ));
    });

    testWithoutContext('does not update when values are already at target', () async {
      fakeProject.xcodeProjectInfoFile.writeAsStringSync(_projectFilePart(
        objectVersion: migratedObjectVersion,
        lastUpgradeCheck: migratedLastUpgradeCheck,
      ));
      fakeProject.schemeFile.writeAsStringSync(_schemeFilePart(
        lastUpgradeVersion: migratedLastUpgradeVersion,
      ));
      final migration = XcodeProjectObjectVersionMigration(fakeProject, testLogger);

      await migration.migrate();

      expect(testLogger.statusText, isEmpty);
      expect(
        fakeProject.xcodeProjectInfoFile.readAsStringSync(),
        _projectFilePart(
          objectVersion: migratedObjectVersion,
          lastUpgradeCheck: migratedLastUpgradeCheck,
        ),
      );
      expect(fakeProject.schemeFile.readAsStringSync(), _schemeFilePart(
        lastUpgradeVersion: migratedLastUpgradeVersion,
      ));
    });

    testWithoutContext('does not update when values are above target', () async {
      fakeProject.xcodeProjectInfoFile.writeAsStringSync(_projectFilePart(
        objectVersion: '9999',
        lastUpgradeCheck: '99999',
      ));
      fakeProject.schemeFile.writeAsStringSync(_schemeFilePart(
        lastUpgradeVersion: '99999',
      ));
      final migration = XcodeProjectObjectVersionMigration(fakeProject, testLogger);

      await migration.migrate();

      expect(testLogger.statusText, isEmpty);
      expect(
        fakeProject.xcodeProjectInfoFile.readAsStringSync(),
        _projectFilePart(
          objectVersion: '9999',
          lastUpgradeCheck: '99999',
        ),
      );
      expect(fakeProject.schemeFile.readAsStringSync(), _schemeFilePart(
        lastUpgradeVersion: '99999',
      ));
    });
  });
}

String _projectFilePart({required String objectVersion, required String lastUpgradeCheck}) => '''
{
\tobjectVersion = $objectVersion;
}

\t\t\t\tLastUpgradeCheck = $lastUpgradeCheck;
''';

String _schemeFilePart({required String lastUpgradeVersion}) => '''
<Scheme
   LastUpgradeVersion = "$lastUpgradeVersion"
   version = "1.3">
''';

class FakeXcodeBasedProject extends Fake implements XcodeBasedProject {
  FakeXcodeBasedProject({required MemoryFileSystem fileSystem})
    : xcodeProjectInfoFile = fileSystem.file('project.pbxproj'),
      schemeFile = fileSystem.file('Runner.xcscheme');

  @override
  File xcodeProjectInfoFile;

  File schemeFile;

  @override
  File xcodeProjectSchemeFile({String? scheme}) => schemeFile;
}
