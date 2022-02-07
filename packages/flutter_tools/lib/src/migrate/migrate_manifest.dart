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
/// This manifest file is created with the results of a `flutter migrate start` run
/// but does not make use of all of the data.
class MigrateManifest {
  MigrateManifest({
    required this.migrateRootDir,
    required this.migrateResult,
  });

  MigrateManifest.fromFile(File manifestFile) : migrateResult = MigrateResult.empty(), migrateRootDir = manifestFile.parent {
    final YamlMap map = loadYaml(manifestFile.readAsStringSync());
    bool valid = map.containsKey('mergedFiles') && map.containsKey('conflictFiles') && map.containsKey('newFiles') && map.containsKey('deletedFiles');
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

  List<String> get conflictFiles {
    List<String> output = <String>[];
    for (MergeResult result in migrateResult.mergeResults) {
      if (result.hasConflict) {
        output.add(result.localPath);
      }
    }
    return output;
  }

  List<String> get mergedFiles {
    List<String> output = <String>[];
    for (MergeResult result in migrateResult.mergeResults) {
      if (!result.hasConflict) {
        output.add(result.localPath);
      }
    }
    return output;
  }

  List<String> get addedFiles {
    List<String> output = <String>[];
    for (FilePendingMigration file in migrateResult.addedFiles) {
      output.add(file.localPath);
    }
    return output;
  }
  List<String> get deletedFiles {
    List<String> output = <String>[];
    for (FilePendingMigration file in migrateResult.deletedFiles) {
      output.add(file.localPath);
    }
    return output;
  }

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
bool checkAndPrintMigrateStatus(MigrateManifest manifest, Directory workingDir, {bool warnConflict = false}) {
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
    globals.printStatus('Added files:');
    for (String localPath in manifest.addedFiles) {
      globals.printStatus('  - $localPath');
    }
  }
  if (manifest.deletedFiles.isNotEmpty) {
    globals.printStatus('Deleted files:');
    for (String localPath in manifest.deletedFiles) {
      globals.printStatus('  - $localPath');
    }
  }
  if (mergedFiles.isNotEmpty) {
    globals.printStatus('Modified files:');
    for (String localPath in mergedFiles) {
      globals.printStatus('  - $localPath');
    }
  }
  if (remainingConflicts.isNotEmpty) {
    if (warnConflict) {
      globals.printStatus('Unable to apply migration. The following files in the migration working directory still have unresolved conflicts:');
    } else {
      globals.printStatus('Merge conflicted files:');
    }
    for (String localPath in remainingConflicts) {
      globals.printStatus('  - $localPath', color: TerminalColor.red);
    }
    return false;
  }
  return true;
}
