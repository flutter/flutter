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
  /// Explicitly initialize the MigrateResult.
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

  /// The results of merging existing files with the target files.
  final List<MergeResult> mergeResults;

  /// Tracks the files that are to be newly added to the project.
  final List<FilePendingMigration> addedFiles;

  /// Tracks the files that are to be deleted from the project.
  final List<FilePendingMigration> deletedFiles;

  /// Tracks the temporary directories created during the migrate compute process.
  final List<Directory> tempDirectories;

  /// Mapping between the local path of a file and the type of merge that should be used.
  final Map<String, MergeType> mergeTypeMap;

  /// Mapping between the local path of a file and the diff between the base and target
  /// versions of the file.
  final Map<String, DiffResult> diffMap;

  /// The root directory of the base app.
  Directory? generatedBaseTemplateDirectory;

  /// The root directory of the target app.
  Directory? generatedTargetTemplateDirectory;

  /// The root directories of the Flutter SDK for each revision.
  Map<String, Directory> sdkDirs;
}

/// Defines available merge techniques.
enum MergeType {
  /// A standard three-way merge.
  threeWay,
  /// A two way merge that ignores the base version of the file.
  twoWay,
  /// A `CustomMerge` manually handles the merge.
  custom,
}

/// Stores a file that has been marked for migration and metadata about the file.
class FilePendingMigration {
  FilePendingMigration(this.localPath, this.file);
  String localPath;
  File file;
}
