// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/terminal.dart';
import 'migrate_result.dart';
import 'migrate_utils.dart';

const String _kMergedFilesKey = 'merged_files';
const String _kConflictFilesKey = 'conflict_files';
const String _kAddedFilesKey = 'added_files';
const String _kDeletedFilesKey = 'deleted_files';

/// Represents the manifest file that tracks the contents of the current
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
      throw Exception('Invalid .migrate_manifest file in the migrate working directory. File is not a Yaml map.');
    }
    final YamlMap map = yamlContents;
    bool valid = map.containsKey(_kMergedFilesKey) && map.containsKey(_kConflictFilesKey) && map.containsKey(_kAddedFilesKey) && map.containsKey(_kDeletedFilesKey);
    if (!valid) {
      throw Exception('Invalid .migrate_manifest file in the migrate working directory. File is missing an entry.');
    }
    final Object? mergedFilesYaml = map[_kMergedFilesKey];
    final Object? conflictFilesYaml = map[_kConflictFilesKey];
    final Object? addedFilesYaml = map[_kAddedFilesKey];
    final Object? deletedFilesYaml = map[_kDeletedFilesKey];
    valid = valid && (mergedFilesYaml is YamlList || mergedFilesYaml == null);
    valid = valid && (conflictFilesYaml is YamlList || conflictFilesYaml == null);
    valid = valid && (addedFilesYaml is YamlList || addedFilesYaml == null);
    valid = valid && (deletedFilesYaml is YamlList || deletedFilesYaml == null);
    if (!valid) {
      throw Exception('Invalid .migrate_manifest file in the migrate working directory. Entry is not a Yaml list.');
    }
    if (mergedFilesYaml != null) {
      for (final Object? localPath in mergedFilesYaml as YamlList) {
        if (localPath is String) {
          // We can fill the maps with partially dummy data as not all properties are used by the manifest.
          migrateResult.mergeResults.add(StringMergeResult.explicit(mergedString: '', hasConflict: false, exitCode: 0, localPath: localPath));
        }
      }
    }
    if (conflictFilesYaml != null) {
      for (final Object? localPath in conflictFilesYaml as YamlList) {
        if (localPath is String) {
          migrateResult.mergeResults.add(StringMergeResult.explicit(mergedString: '', hasConflict: true, exitCode: 1, localPath: localPath));
        }
      }
    }
    if (addedFilesYaml != null) {
      for (final Object? localPath in addedFilesYaml as YamlList) {
        if (localPath is String) {
          migrateResult.addedFiles.add(FilePendingMigration(localPath, migrateRootDir.childFile(localPath)));
        }
      }
    }
    if (deletedFilesYaml != null) {
      for (final Object? localPath in deletedFilesYaml as YamlList) {
        if (localPath is String) {
          migrateResult.deletedFiles.add(FilePendingMigration(localPath, migrateRootDir.childFile(localPath)));
        }
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

  /// A list of local paths of files that require conflict resolution.
  List<String> remainingConflictFiles(Directory workingDir) {
    final List<String> output = <String>[];
    for (final String localPath in conflictFiles) {
      if (!_conflictsResolved(workingDir.childFile(localPath).readAsStringSync())) {
        output.add(localPath);
      }
    }
    return output;
  }

  // A list of local paths of files that had conflicts and are now fully resolved.
  List<String> resolvedConflictFiles(Directory workingDir) {
    final List<String> output = <String>[];
    for (final String localPath in conflictFiles) {
      if (_conflictsResolved(workingDir.childFile(localPath).readAsStringSync())) {
        output.add(localPath);
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
    final StringBuffer mergedFileManifestContents = StringBuffer();
    final StringBuffer conflictFilesManifestContents = StringBuffer();
    for (final MergeResult result in migrateResult.mergeResults) {
      if (result.hasConflict) {
        conflictFilesManifestContents.write('  - ${result.localPath}\n');
      } else {
        mergedFileManifestContents.write('  - ${result.localPath}\n');
      }
    }

    final StringBuffer newFileManifestContents = StringBuffer();
    for (final String localPath in addedFiles) {
      newFileManifestContents.write('  - $localPath\n)');
    }

    final StringBuffer deletedFileManifestContents = StringBuffer();
    for (final String localPath in deletedFiles) {
      deletedFileManifestContents.write('  - $localPath\n');
    }

    final String migrateManifestContents = 'merged_files:\n${mergedFileManifestContents.toString()}conflict_files:\n${conflictFilesManifestContents.toString()}added_files:\n${newFileManifestContents.toString()}deleted_files:\n${deletedFileManifestContents.toString()}';
    final File migrateManifest = getManifestFileFromDirectory(migrateRootDir);
    migrateManifest.createSync(recursive: true);
    migrateManifest.writeAsStringSync(migrateManifestContents, flush: true);
  }
}

/// Returns true if the file does not contain any git conflict markers.
bool _conflictsResolved(String contents) {
  if (contents.contains('>>>>>>>') && contents.contains('=======') && contents.contains('<<<<<<<')) {
    return false;
  }
  return true;
}

/// Returns true if the migration working directory has all conflicts resolved and prints the migration status.
///
/// The migration status printout lists all added, deleted, merged, and conflicted files.
bool checkAndPrintMigrateStatus(MigrateManifest manifest, Directory workingDir, {bool warnConflict = false, Logger? logger}) {
  final StringBuffer printout = StringBuffer();
  final StringBuffer redPrintout = StringBuffer();
  bool result = true;
  final List<String> remainingConflicts = <String>[];
  final List<String> mergedFiles = <String>[];
  for (final String localPath in manifest.conflictFiles) {
    if (!_conflictsResolved(workingDir.childFile(localPath).readAsStringSync())) {
      remainingConflicts.add(localPath);
    } else {
      mergedFiles.add(localPath);
    }
  }

  mergedFiles.addAll(manifest.mergedFiles);
  if (manifest.addedFiles.isNotEmpty) {
    printout.write('Added files:\n');
    for (final String localPath in manifest.addedFiles) {
      printout.write('  - $localPath\n');
    }
  }
  if (manifest.deletedFiles.isNotEmpty) {
    printout.write('Deleted files:\n');
    for (final String localPath in manifest.deletedFiles) {
      printout.write('  - $localPath\n');
    }
  }
  if (mergedFiles.isNotEmpty) {
    printout.write('Modified files:\n');
    for (final String localPath in mergedFiles) {
      printout.write('  - $localPath\n');
    }
  }
  if (remainingConflicts.isNotEmpty) {
    if (warnConflict) {
      printout.write('Unable to apply migration. The following files in the migration working directory still have unresolved conflicts:');
    } else {
      printout.write('Merge conflicted files:');
    }
    for (final String localPath in remainingConflicts) {
      redPrintout.write('  - $localPath\n');
    }
    result = false;
  }
  if (logger != null) {
    logger.printStatus(printout.toString());
    logger.printStatus(redPrintout.toString(), color: TerminalColor.red, newline: false);
  }
  return result;
}
