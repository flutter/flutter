// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../base/file_system.dart';
import '../base/common.dart';
import '../base/logger.dart';
import '../base/terminal.dart';
import '../globals.dart' as globals;
import '../migrate/migrate_compute.dart';
import '../migrate/migrate_config.dart';
import '../migrate/migrate_manifest.dart';
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
    final dynamic yamlContents = loadYaml(manifestFile.readAsStringSync());
    if (yamlContents is! YamlMap) {
      throwToolExit('Invalid .migrate_manifest file in the migrate working directory. File is not a Yaml map', exitCode: 1);
    }
    final YamlMap map = yamlContents as YamlMap;
    final bool valid = map.containsKey('mergedFiles') && map.containsKey('conflictFiles') && map.containsKey('newFiles') && map.containsKey('deletedFiles');
    if (!valid) {
      throwToolExit('Invalid .migrate_manifest file in the migrate working directory. Fix the manifest or abandon the migration and try again.', exitCode: 1);
    }
    // We can fill the maps with partially dummy data as not all properties are used by the manifest.
    if (map['mergedFiles'] != null) {
      for (String localPath in map['mergedFiles']) {
        migrateResult.mergeResults.add(MergeResult.explicit(mergedString: '', hasConflict: false, exitCode: 0, localPath: localPath));
      }
    }
    if (map['conflictFiles'] != null) {
      for (String localPath in map['conflictFiles']) {
        migrateResult.mergeResults.add(MergeResult.explicit(mergedString: '', hasConflict: true, exitCode: 1, localPath: localPath));
      }
    }
    if (map['newFiles'] != null) {
      for (String localPath in map['newFiles']) {
        migrateResult.addedFiles.add(FilePendingMigration(localPath, migrateRootDir.childFile(localPath)));
      }
    }
    if (map['deletedFiles'] != null) {
      for (String localPath in map['deletedFiles']) {
        migrateResult.deletedFiles.add(FilePendingMigration(localPath, migrateRootDir.childFile(localPath)));
      }
    }
  }

  final Directory migrateRootDir;
  final MigrateResult migrateResult;

  /// A list of local paths of files that require conflict resolution.
  List<String> get conflictFiles {
    List<String> output = <String>[];
    for (MergeResult result in migrateResult.mergeResults) {
      if (result.hasConflict) {
        output.add(result.localPath);
      }
    }
    return output;
  }

  /// A list of local paths of files that were automatically merged.
  List<String> get mergedFiles {
    List<String> output = <String>[];
    for (MergeResult result in migrateResult.mergeResults) {
      if (!result.hasConflict) {
        output.add(result.localPath);
      }
    }
    return output;
  }

  /// A list of local paths of files that were newly added.
  List<String> get addedFiles {
    List<String> output = <String>[];
    for (FilePendingMigration file in migrateResult.addedFiles) {
      output.add(file.localPath);
    }
    return output;
  }

  /// A list of local paths of files that are marked for deletion.
  List<String> get deletedFiles {
    List<String> output = <String>[];
    for (FilePendingMigration file in migrateResult.deletedFiles) {
      output.add(file.localPath);
    }
    return output;
  }

  /// Returns the manifest file given a migration workind directory.
  static File getManifestFileFromDirectory(Directory workingDir) {
    return workingDir.childFile('.migrateManifest.yaml');
  }

  /// Writes the manifest yaml file in the working directory.
  void writeFile() {
    String mergedFileManifestContents = '';
    String conflictFilesManifestContents = '';
    for (MergeResult result in migrateResult.mergeResults) {
      if (result.hasConflict) {
        conflictFilesManifestContents += '  - ${result.localPath}\n';
      } else {
        mergedFileManifestContents += '  - ${result.localPath}\n';
      }
    }

    String newFileManifestContents = '';
    for (String localPath in addedFiles) {
      newFileManifestContents += '  - $localPath\n';
    }

    String deletedFileManifestContents = '';
    for (String localPath in deletedFiles) {
      deletedFileManifestContents += '  - $localPath\n';
    }

    final String migrateManifestContents = 'mergedFiles:\n${mergedFileManifestContents}conflictFiles:\n${conflictFilesManifestContents}newFiles:\n${newFileManifestContents}deletedFiles:\n${deletedFileManifestContents}';
    final File migrateManifest = getManifestFileFromDirectory(migrateRootDir);
    migrateManifest.createSync(recursive: true);
    migrateManifest.writeAsStringSync(migrateManifestContents, flush: true);
  }
}

/// Returns true if the migration working directory has all conflicts resolved and prints the migration status.
///
/// The migration status printout lists all added, deleted, merged, and conflicted files.
bool checkAndPrintMigrateStatus(MigrateManifest manifest, Directory workingDir, {bool warnConflict = false, bool print = true}) {
  String printout = '';
  String redPrintout = '';
  bool result = true;
  List<String> remainingConflicts = <String>[];
  List<String> mergedFiles = <String>[];
  for (String localPath in manifest.conflictFiles) {
    if (!MigrateUtils.conflictsResolved(workingDir.childFile(localPath).readAsStringSync())) {
      remainingConflicts.add(localPath);
    } else {
      mergedFiles.add(localPath);
    }
  }
  
  mergedFiles.addAll(manifest.mergedFiles);
  if (manifest.addedFiles.isNotEmpty) {
    printout += 'Added files:\n';
    for (String localPath in manifest.addedFiles) {
      printout += '  - $localPath\n';
    }
  }
  if (manifest.deletedFiles.isNotEmpty) {
    printout += 'Deleted files:\n';
    for (String localPath in manifest.deletedFiles) {
      printout += '  - $localPath\n';
    }
  }
  if (mergedFiles.isNotEmpty) {
    printout += 'Modified files:\n';
    for (String localPath in mergedFiles) {
      printout += '  - $localPath\n';
    }
  }
  if (remainingConflicts.isNotEmpty) {
    if (warnConflict) {
      printout += 'Unable to apply migration. The following files in the migration working directory still have unresolved conflicts:';
    } else {
      printout += 'Merge conflicted files:';
    }
    for (String localPath in remainingConflicts) {
      redPrintout += '  - $localPath\n';
    }
    result = false;
  }
  if (print) {
    globals.logger.printStatus(printout);
    globals.logger.printStatus(redPrintout, color: TerminalColor.red);
  }
  return result;
}
