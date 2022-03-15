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
}
