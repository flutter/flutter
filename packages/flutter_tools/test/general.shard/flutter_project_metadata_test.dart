// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/flutter_project_metadata.dart';
import 'package:flutter_tools/src/project.dart';

import '../src/common.dart';

void main() {
  late FileSystem fileSystem;
  late BufferLogger logger;
  late File metadataFile;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    logger = BufferLogger.test();
    metadataFile = fileSystem.file('.metadata');
  });

  testWithoutContext('project metadata fields are empty when file does not exist', () {
    final FlutterProjectMetadata projectMetadata = FlutterProjectMetadata(metadataFile, logger);
    expect(projectMetadata.projectType, isNull);
    expect(projectMetadata.versionChannel, isNull);
    expect(projectMetadata.versionRevision, isNull);

    expect(logger.traceText, contains('No .metadata file found at .metadata'));
  });

  testWithoutContext('project metadata fields are empty when file is empty', () {
    metadataFile.createSync();
    final FlutterProjectMetadata projectMetadata = FlutterProjectMetadata(metadataFile, logger);
    expect(projectMetadata.projectType, isNull);
    expect(projectMetadata.versionChannel, isNull);
    expect(projectMetadata.versionRevision, isNull);

    expect(logger.traceText, contains('.metadata file at .metadata was empty or malformed.'));
  });

  testWithoutContext('project metadata fields are empty when file is not valid yaml', () {
    metadataFile.writeAsStringSync(' channel: @something');
    final FlutterProjectMetadata projectMetadata = FlutterProjectMetadata(metadataFile, logger);
    expect(projectMetadata.projectType, isNull);
    expect(projectMetadata.versionChannel, isNull);
    expect(projectMetadata.versionRevision, isNull);

    expect(logger.traceText, contains('.metadata file at .metadata was empty or malformed.'));
  });

  testWithoutContext('projectType is populated when version is null', () {
    metadataFile
      ..createSync()
      ..writeAsStringSync('''
version:
project_type: plugin
      ''');
    final FlutterProjectMetadata projectMetadata = FlutterProjectMetadata(metadataFile, logger);
    expect(projectMetadata.projectType, FlutterProjectType.plugin);
    expect(projectMetadata.versionChannel, isNull);
    expect(projectMetadata.versionRevision, isNull);

    expect(logger.traceText, contains('The value of key `version` in .metadata was expected to be YamlMap but was Null'));
  });

  testWithoutContext('projectType is populated when version is malformed', () {
    metadataFile
      ..createSync()
      ..writeAsStringSync('''
version: STRING INSTEAD OF MAP
project_type: plugin
      ''');
    final FlutterProjectMetadata projectMetadata = FlutterProjectMetadata(metadataFile, logger);
    expect(projectMetadata.projectType, FlutterProjectType.plugin);
    expect(projectMetadata.versionChannel, isNull);
    expect(projectMetadata.versionRevision, isNull);

    expect(logger.traceText, contains('The value of key `version` in .metadata was expected to be YamlMap but was String'));
  });

  testWithoutContext('version is populated when projectType is malformed', () {
    metadataFile
      ..createSync()
      ..writeAsStringSync('''
version:
  revision: b59b226a49391949247e3d6122e34bb001049ae4
  channel: stable
project_type: {}
      ''');
    final FlutterProjectMetadata projectMetadata = FlutterProjectMetadata(metadataFile, logger);
    expect(projectMetadata.projectType, isNull);
    expect(projectMetadata.versionChannel, 'stable');
    expect(projectMetadata.versionRevision, 'b59b226a49391949247e3d6122e34bb001049ae4');

    expect(logger.traceText, contains('The value of key `project_type` in .metadata was expected to be String but was YamlMap'));
  });

  testWithoutContext('migrate config is populated when version is malformed', () {
    metadataFile
      ..createSync()
      ..writeAsStringSync('''
version: STRING INSTEAD OF MAP
project_type: {}

migration:
  platforms:
    - platform: root
      create_revision: abcdefg
      base_revision: baserevision

  unmanaged_files:
    - 'file1'
      ''');
    final FlutterProjectMetadata projectMetadata = FlutterProjectMetadata(metadataFile, logger);
    expect(projectMetadata.projectType, isNull);
    expect(projectMetadata.migrateConfig.platformConfigs[SupportedPlatform.root]?.createRevision, 'abcdefg');
    expect(projectMetadata.migrateConfig.platformConfigs[SupportedPlatform.root]?.baseRevision, 'baserevision');
    expect(projectMetadata.migrateConfig.unmanagedFiles[0], 'file1');

    expect(logger.traceText, contains('The value of key `version` in .metadata was expected to be YamlMap but was String'));
    expect(logger.traceText, contains('The value of key `project_type` in .metadata was expected to be String but was YamlMap'));
  });

  testWithoutContext('migrate config is populated when unmanaged_files is malformed', () {
    metadataFile
      ..createSync()
      ..writeAsStringSync('''
version:
  revision: b59b226a49391949247e3d6122e34bb001049ae4
  channel: stable
project_type: app

migration:
  platforms:
    - platform: root
      create_revision: abcdefg
      base_revision: baserevision

  unmanaged_files: {}
      ''');
    final FlutterProjectMetadata projectMetadata = FlutterProjectMetadata(metadataFile, logger);
    expect(projectMetadata.projectType, FlutterProjectType.app);
    expect(projectMetadata.migrateConfig.platformConfigs[SupportedPlatform.root]?.createRevision, 'abcdefg');
    expect(projectMetadata.migrateConfig.platformConfigs[SupportedPlatform.root]?.baseRevision, 'baserevision');
    // Tool uses default unamanged files list when malformed.
    expect(projectMetadata.migrateConfig.unmanagedFiles[0], 'lib/main.dart');

    expect(logger.traceText, contains('The value of key `unmanaged_files` in .metadata was expected to be YamlList but was YamlMap'));
  });

  testWithoutContext('platforms is populated with a malformed entry', () {
    metadataFile
      ..createSync()
      ..writeAsStringSync('''
version:
  revision: b59b226a49391949247e3d6122e34bb001049ae4
  channel: stable
project_type: app

migration:
  platforms:
    - platform: root
      create_revision: abcdefg
      base_revision: baserevision
    - platform: android
      base_revision: baserevision
    - platform: ios
      create_revision: abcdefg
      base_revision: baserevision

  unmanaged_files:
    - 'file1'
      ''');
    final FlutterProjectMetadata projectMetadata = FlutterProjectMetadata(metadataFile, logger);
    expect(projectMetadata.projectType, FlutterProjectType.app);
    expect(projectMetadata.migrateConfig.platformConfigs[SupportedPlatform.root]?.createRevision, 'abcdefg');
    expect(projectMetadata.migrateConfig.platformConfigs[SupportedPlatform.root]?.baseRevision, 'baserevision');
    expect(projectMetadata.migrateConfig.platformConfigs[SupportedPlatform.ios]?.createRevision, 'abcdefg');
    expect(projectMetadata.migrateConfig.platformConfigs[SupportedPlatform.ios]?.baseRevision, 'baserevision');
    expect(projectMetadata.migrateConfig.platformConfigs.containsKey(SupportedPlatform.android), false);
    expect(projectMetadata.migrateConfig.unmanagedFiles[0], 'file1');

    expect(logger.traceText, contains('The key `create_revision` was not found'));
  });

  group('.metadata merge', () {
    String performMerge(File current, File base, File target) {
      final FlutterProjectMetadata result = FlutterProjectMetadata.merge(
        FlutterProjectMetadata(current, logger),
        FlutterProjectMetadata(base, logger),
        FlutterProjectMetadata(target, logger),
        logger,
      );
      return result.toString();
    }

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

      final String result = performMerge(currentFile, baseFile, targetFile);
      expect(result, '''
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

      final String result = performMerge(currentFile, baseFile, targetFile);
      expect(result, '''
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

      final String result = performMerge(currentFile, baseFile, targetFile);
      expect(result, '''
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
