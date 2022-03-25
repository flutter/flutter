// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/migrate/custom_merge.dart';
import 'package:flutter_tools/src/migrate/migrate_utils.dart';

import '../../src/common.dart';

void main() {
  late FileSystem fileSystem;
  late BufferLogger logger;

  setUpAll(() {
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
  });

  group('.metadata merge', () {
    late MetadataCustomMerge merger;

    setUp(() {
      merger = MetadataCustomMerge(logger: logger);
    });

    testWithoutContext('merges empty', () async {
      const String current = '';
      const String base = '';
      const String target = '';
      final File currentFile = fileSystem.file('.metadata_current');
      final File baseFile = fileSystem.file('.metadata_base');
      final File targetFile = fileSystem.file('.metadata_target');

      currentFile
        ..createSync(recursive: true)
        ..writeAsStringSync(current, flush: true);
      baseFile
        ..createSync(recursive: true)
        ..writeAsStringSync(base, flush: true);
      targetFile
        ..createSync(recursive: true)
        ..writeAsStringSync(target, flush: true);

      final MergeResult result = merger.merge(currentFile, baseFile, targetFile);
      expect(result.mergedString, '''
# This file tracks properties of this Flutter project.
# Used by Flutter tool to assess capabilities and perform upgrades etc.
#
# This file should be version controlled.

version:
  revision: null
  channel: null

project_type: 

# Tracks metadata for the flutter migrate command
migration:
  platforms:

  # User provided section

  # List of Local paths (relative to this file) that should be
  # ignored by the migrate tool.
  #
  # Files that are not part of the templates will be ignored by default.
  unmanaged_files:
    - 'lib/main.dart'
    - 'ios/Runner.xcodeproj/project.pbxproj'
''');
    });

    testWithoutContext('merge adds migration section', () async {
      const String current = '''
# my own comment
version:
  revision: abcdefg12345
  channel: stable
project_type: app
      ''';
      const String base = '''
version:
  revision: abcdefg12345base
  channel: stable
project_type: app
migration:
  platforms:
    - platform: root
      create_revision: somecreaterevision
      base_revision: somebaserevision
    - platform: android
      create_revision: somecreaterevision
      base_revision: somebaserevision
  unmanaged_files:
    - 'lib/main.dart'
    - 'ios/Runner.xcodeproj/project.pbxproj'
      ''';
      const String target = '''
version:
  revision: abcdefg12345target
  channel: stable
project_type: app
migration:
  platforms:
    - platform: root
      create_revision: somecreaterevision
      base_revision: somebaserevision
    - platform: android
      create_revision: somecreaterevision
      base_revision: somebaserevision
  unmanaged_files:
    - 'lib/main.dart'
    - 'ios/Runner.xcodeproj/project.pbxproj'
      ''';
      final File currentFile = fileSystem.file('.metadata_current');
      final File baseFile = fileSystem.file('.metadata_base');
      final File targetFile = fileSystem.file('.metadata_target');

      currentFile
        ..createSync(recursive: true)
        ..writeAsStringSync(current, flush: true);
      baseFile
        ..createSync(recursive: true)
        ..writeAsStringSync(base, flush: true);
      targetFile
        ..createSync(recursive: true)
        ..writeAsStringSync(target, flush: true);

      final MergeResult result = merger.merge(currentFile, baseFile, targetFile);
      expect(result.mergedString, '''
# This file tracks properties of this Flutter project.
# Used by Flutter tool to assess capabilities and perform upgrades etc.
#
# This file should be version controlled.

version:
  revision: abcdefg12345target
  channel: stable

project_type: app

# Tracks metadata for the flutter migrate command
migration:
  platforms:
    - platform: root
      create_revision: somecreaterevision
      base_revision: somebaserevision
    - platform: android
      create_revision: somecreaterevision
      base_revision: somebaserevision

  # User provided section

  # List of Local paths (relative to this file) that should be
  # ignored by the migrate tool.
  #
  # Files that are not part of the templates will be ignored by default.
  unmanaged_files:
    - 'lib/main.dart'
    - 'ios/Runner.xcodeproj/project.pbxproj'
''');
    });

    testWithoutContext('merge handles standard migration flow', () async {
      const String current = '''
# my own comment
version:
  revision: abcdefg12345current
  channel: stable
project_type: app
migration:
  platforms:
    - platform: root
      create_revision: somecreaterevisioncurrent
      base_revision: somebaserevisioncurrent
    - platform: android
      create_revision: somecreaterevisioncurrent
      base_revision: somebaserevisioncurrent
  unmanaged_files:
    - 'lib/main.dart'
    - 'new/file.dart'
      ''';
      const String base = '''
version:
  revision: abcdefg12345base
  channel: stable
project_type: app
migration:
  platforms:
    - platform: root
      create_revision: somecreaterevisionbase
      base_revision: somebaserevisionbase
    - platform: android
      create_revision: somecreaterevisionbase
      base_revision: somebaserevisionbase
  unmanaged_files:
    - 'lib/main.dart'
    - 'ios/Runner.xcodeproj/project.pbxproj'
      ''';
      const String target = '''
version:
  revision: abcdefg12345target
  channel: stable
project_type: app
migration:
  platforms:
    - platform: root
      create_revision: somecreaterevisiontarget
      base_revision: somebaserevisiontarget
    - platform: android
      create_revision: somecreaterevisiontarget
      base_revision: somebaserevisiontarget
  unmanaged_files:
    - 'lib/main.dart'
    - 'ios/Runner.xcodeproj/project.pbxproj'
    - 'extra/file'
      ''';
      final File currentFile = fileSystem.file('.metadata_current');
      final File baseFile = fileSystem.file('.metadata_base');
      final File targetFile = fileSystem.file('.metadata_target');

      currentFile
        ..createSync(recursive: true)
        ..writeAsStringSync(current, flush: true);
      baseFile
        ..createSync(recursive: true)
        ..writeAsStringSync(base, flush: true);
      targetFile
        ..createSync(recursive: true)
        ..writeAsStringSync(target, flush: true);

      final MergeResult result = merger.merge(currentFile, baseFile, targetFile);
      expect(result.mergedString, '''
# This file tracks properties of this Flutter project.
# Used by Flutter tool to assess capabilities and perform upgrades etc.
#
# This file should be version controlled.

version:
  revision: abcdefg12345target
  channel: stable

project_type: app

# Tracks metadata for the flutter migrate command
migration:
  platforms:
    - platform: root
      create_revision: somecreaterevisioncurrent
      base_revision: somebaserevisiontarget
    - platform: android
      create_revision: somecreaterevisioncurrent
      base_revision: somebaserevisiontarget

  # User provided section

  # List of Local paths (relative to this file) that should be
  # ignored by the migrate tool.
  #
  # Files that are not part of the templates will be ignored by default.
  unmanaged_files:
    - 'lib/main.dart'
    - 'new/file.dart'
    - 'extra/file'
''');
    });
  });
}
