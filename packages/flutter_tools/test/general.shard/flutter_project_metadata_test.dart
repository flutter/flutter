// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/flutter_project_metadata.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:file/memory.dart';

import '../src/common.dart';

void main() {
  FileSystem fileSystem;
  BufferLogger logger;
  File metadataFile;

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

    expect(logger.traceText, contains('.metadata project_type version is malformed.'));
    expect(logger.traceText, contains('.metadata version is malformed.'));
  });

  testWithoutContext('project metadata fields are empty when file is empty', () {
    metadataFile.createSync();
    final FlutterProjectMetadata projectMetadata = FlutterProjectMetadata(metadataFile, logger);
    expect(projectMetadata.projectType, isNull);
    expect(projectMetadata.versionChannel, isNull);
    expect(projectMetadata.versionRevision, isNull);

    expect(logger.traceText, contains('.metadata project_type version is malformed.'));
    expect(logger.traceText, contains('.metadata version is malformed.'));
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

    expect(logger.traceText, contains('.metadata version is malformed.'));
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

    expect(logger.traceText, contains('.metadata project_type version is malformed.'));
  });
}