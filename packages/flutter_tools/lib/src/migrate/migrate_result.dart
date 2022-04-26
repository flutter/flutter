// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/file_system.dart';
import 'migrate_utils.dart';

/// Data class that holds all results and generated directories from a computeMigration run.
///
/// mergeResults, addedFiles, and deletedFiles includes the sets of files to be migrated while
/// the other members track the temporary sdk and generated app directories created by the tool.
///
/// The compute function does not clean up the temp directories, as the directories may be reused,
/// so this must be done manually afterwards.
class MigrateResult {
  MigrateResult({
    required this.mergeResults,
    required this.addedFiles,
    required this.deletedFiles,
    required this.tempDirectories,
    required this.sdkDirs,
    required this.mergeTypeMap,
    required this.diffMap,
    this.generatedBaseTemplateDirectory,
    this.generatedTargetTemplateDirectory});

  /// Creates a MigrateResult with all empty members.
  MigrateResult.empty()
    : mergeResults = <MergeResult>[],
      addedFiles = <FilePendingMigration>[],
      deletedFiles = <FilePendingMigration>[],
      tempDirectories = <Directory>[],
      mergeTypeMap = <String, MergeType>{},
      diffMap = <String, DiffResult>{},
      sdkDirs = <String, Directory>{};

  final List<MergeResult> mergeResults;
  final List<FilePendingMigration> addedFiles;
  final List<FilePendingMigration> deletedFiles;
  final List<Directory> tempDirectories;
  final Map<String, MergeType> mergeTypeMap;
  final Map<String, DiffResult> diffMap;
  Directory? generatedBaseTemplateDirectory;
  Directory? generatedTargetTemplateDirectory;
  Map<String, Directory> sdkDirs;
}

/// Defines available merge techniques.
enum MergeType {
  threeWay,
  twoWay,
  custom,
}

/// Stores a file that has been marked for migration and metadata about the file.
class FilePendingMigration {
  FilePendingMigration(this.localPath, this.file);
  String localPath;
  File file;
}
