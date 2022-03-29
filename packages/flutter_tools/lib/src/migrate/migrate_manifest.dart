// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/terminal.dart';
import '../migrate/migrate_compute.dart';
import '../migrate/migrate_utils.dart';

/// Represents the mamifest file that tracks the contents of the current
/// migration working directory.
///
/// This manifest file is created with the MigrateResult of a computeMigration run.
class MigrateManifest {
  /// Creates a new manifest from a MigrateResult.
  MigrateManifest({
    required this.migrateRootDir,
    required this.migrateResult,
  });

  /// Parses an existing migrate manifest.
  MigrateManifest.fromFile(File manifestFile) : migrateResult = MigrateResult.empty(), migrateRootDir = manifestFile.parent {
    final Object? yamlContents = loadYaml(manifestFile.readAsStringSync());
    if (yamlContents is! YamlMap) {
      throwToolExit('Invalid .migrate_manifest file in the migrate working directory. File is not a Yaml map.', exitCode: 1);
    }
    final YamlMap map = yamlContents;
    bool valid = map.containsKey('merged_files') && map.containsKey('conflict_files') && map.containsKey('added_files') && map.containsKey('deleted_files');
    if (!valid) {
      throwToolExit('Invalid .migrate_manifest file in the migrate working directory. File is missing an entry. Fix the manifest or abandon the migration and try again.', exitCode: 1);
    }
    final Object? mergedFilesYaml = map['merged_files'];
    final Object? conflictFilesYaml = map['conflict_files'];
    final Object? addedFilesYaml = map['added_files'];
    final Object? deletedFilesYaml = map['deleted_files'];
    valid = valid && (mergedFilesYaml is YamlList || mergedFilesYaml == null);
    valid = valid && (conflictFilesYaml is YamlList || conflictFilesYaml == null);
    valid = valid && (addedFilesYaml is YamlList || addedFilesYaml == null);
    valid = valid && (deletedFilesYaml is YamlList || deletedFilesYaml == null);
    if (!valid) {
      throwToolExit('Invalid .migrate_manifest file in the migrate working directory. Entry is not a Yaml list. Fix the manifest or abandon the migration and try again.', exitCode: 1);
    }
    // We can fill the maps with partially dummy data as not all properties are used by the manifest.
    if (map['merged_files'] != null) {
      for (final String localPath in map['merged_files']) {
        migrateResult.mergeResults.add(MergeResult.explicit(mergedString: '', hasConflict: false, exitCode: 0, localPath: localPath));
      }
    }
    if (map['conflict_files'] != null) {
      for (final String localPath in map['conflict_files']) {
        migrateResult.mergeResults.add(MergeResult.explicit(mergedString: '', hasConflict: true, exitCode: 1, localPath: localPath));
      }
    }
    if (map['added_files'] != null) {
      for (final String localPath in map['added_files']) {
        migrateResult.addedFiles.add(FilePendingMigration(localPath, migrateRootDir.childFile(localPath)));
      }
    }
    if (map['deleted_files'] != null) {
      for (final String localPath in map['deleted_files']) {
        migrateResult.deletedFiles.add(FilePendingMigration(localPath, migrateRootDir.childFile(localPath)));
      }
    }
  }

  final Directory migrateRootDir;
  final MigrateResult migrateResult;

  /// A list of local paths of files that require conflict resolution.
  List<String> get conflictFiles {
    final List<String> output = <String>[];
    for (final MergeResult result in migrateResult.mergeResults) {
      if (result.hasConflict) {
        output.add(result.localPath);
      }
    }
    return output;
  }

  /// A list of local paths of files that were automatically merged.
  List<String> get mergedFiles {
    final List<String> output = <String>[];
    for (final MergeResult result in migrateResult.mergeResults) {
      if (!result.hasConflict) {
        output.add(result.localPath);
      }
    }
    return output;
  }

  /// A list of local paths of files that were newly added.
  List<String> get addedFiles {
    final List<String> output = <String>[];
    for (final FilePendingMigration file in migrateResult.addedFiles) {
      output.add(file.localPath);
    }
    return output;
  }

  /// A list of local paths of files that are marked for deletion.
  List<String> get deletedFiles {
    final List<String> output = <String>[];
    for (final FilePendingMigration file in migrateResult.deletedFiles) {
      output.add(file.localPath);
    }
    return output;
  }

  /// Returns the manifest file given a migration workind directory.
  static File getManifestFileFromDirectory(Directory workingDir) {
    return workingDir.childFile('.migrate_manifest');
  }

  /// Writes the manifest yaml file in the working directory.
  void writeFile() {
    String mergedFileManifestContents = '';
    String conflictFilesManifestContents = '';
    for (final MergeResult result in migrateResult.mergeResults) {
      if (result.hasConflict) {
        conflictFilesManifestContents += '  - ${result.localPath}\n';
      } else {
        mergedFileManifestContents += '  - ${result.localPath}\n';
      }
    }

    String newFileManifestContents = '';
    for (final String localPath in addedFiles) {
      newFileManifestContents += '  - $localPath\n';
    }

    String deletedFileManifestContents = '';
    for (final String localPath in deletedFiles) {
      deletedFileManifestContents += '  - $localPath\n';
    }

    final String migrateManifestContents = 'merged_files:\n${mergedFileManifestContents}conflict_files:\n${conflictFilesManifestContents}added_files:\n${newFileManifestContents}deleted_files:\n$deletedFileManifestContents';
    final File migrateManifest = getManifestFileFromDirectory(migrateRootDir);
    migrateManifest.createSync(recursive: true);
    migrateManifest.writeAsStringSync(migrateManifestContents, flush: true);
  }
}

/// Returns true if the migration working directory has all conflicts resolved and prints the migration status.
///
/// The migration status printout lists all added, deleted, merged, and conflicted files.
bool checkAndPrintMigrateStatus(MigrateManifest manifest, Directory workingDir, {bool warnConflict = false, Logger? logger}) {
  String printout = '';
  String redPrintout = '';
  bool result = true;
  final List<String> remainingConflicts = <String>[];
  final List<String> mergedFiles = <String>[];
  for (final String localPath in manifest.conflictFiles) {
    if (!MigrateUtils.conflictsResolved(workingDir.childFile(localPath).readAsStringSync())) {
      remainingConflicts.add(localPath);
    } else {
      mergedFiles.add(localPath);
    }
  }
  
  mergedFiles.addAll(manifest.mergedFiles);
  if (manifest.addedFiles.isNotEmpty) {
    printout += 'Added files:\n';
    for (final String localPath in manifest.addedFiles) {
      printout += '  - $localPath\n';
    }
  }
  if (manifest.deletedFiles.isNotEmpty) {
    printout += 'Deleted files:\n';
    for (final String localPath in manifest.deletedFiles) {
      printout += '  - $localPath\n';
    }
  }
  if (mergedFiles.isNotEmpty) {
    printout += 'Modified files:\n';
    for (final String localPath in mergedFiles) {
      printout += '  - $localPath\n';
    }
  }
  if (remainingConflicts.isNotEmpty) {
    if (warnConflict) {
      printout += 'Unable to apply migration. The following files in the migration working directory still have unresolved conflicts:';
    } else {
      printout += 'Merge conflicted files:';
    }
    for (final String localPath in remainingConflicts) {
      redPrintout += '  - $localPath\n';
    }
    result = false;
  }
  if (logger != null) {
    logger.printStatus(printout);
    logger.printStatus(redPrintout, color: TerminalColor.red, newline: false);
  }
  return result;
}
