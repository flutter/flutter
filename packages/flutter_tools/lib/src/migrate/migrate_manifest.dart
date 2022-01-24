// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../globals.dart' as globals;
import '../migrate/migrate_config.dart';
import '../migrate/migrate_manifest.dart';
import '../migrate/migrate_utils.dart';

class MigrateManifest {
  MigrateManifest({required this.migrateRootDir, required Map<String, MergeResult> mergeResults, required Map<String, File> additionalFiles, required Map<String, File> deletedFiles}) :
    _mergeResults = mergeResults, _additionalFiles = additionalFiles, _deletedFiles = deletedFiles;

  MigrateManifest.fromFile(File manifestFile) : migrateRootDir = manifestFile.parent, _mergeResults = <String, MergeResult>{}, _additionalFiles = <String, File>{}, _deletedFiles = <String, File>{} {
    YamlMap map = loadYaml(manifestFile.readAsStringSync());
    if (!validateYaml(map)) {
      // throw due to unvalid manifest
    }
    // We can fill the maps with partially dummy data as not all properties are used by the manifest.
    if (map['mergedFiles'] != null) {
      for (String localPath in map['mergedFiles']) {
        _mergeResults[localPath] = MergeResult.explicit(mergedContents: '', hasConflict: false, exitCode: 0);
      }
    }
    if (map['conflictFiles'] != null) {
      for (String localPath in map['conflictFiles']) {
        _mergeResults[localPath] = MergeResult.explicit(mergedContents: '', hasConflict: true, exitCode: 1);
      }
    }
    if (map['newFiles'] != null) {
      for (String localPath in map['newFiles']) {
        _additionalFiles[localPath] = migrateRootDir.childFile(localPath);
      }
    }
    if (map['deletedFiles'] != null) {
      for (String localPath in map['deletedFiles']) {
        _deletedFiles[localPath] = migrateRootDir.childFile(localPath);
      }
    }
  }

  final Directory migrateRootDir;
  final Map<String, MergeResult> _mergeResults;
  final Map<String, File> _additionalFiles;
  final Map<String, File> _deletedFiles;

  List<String> get conflictFiles {
    List<String> result = <String>[];
    for (String localPath in _mergeResults.keys) {
      if (_mergeResults[localPath]!.hasConflict) {
        result.add(localPath);
      }
    }
    return result;
  }

  List<String> get mergedFiles {
    List<String> result = <String>[];
    for (String localPath in _mergeResults.keys) {
      if (!_mergeResults[localPath]!.hasConflict) {
        result.add(localPath);
      }
    }
    return result;
  }

  List<String> get additionalFiles => _additionalFiles.keys.toList();
  List<String> get deletedFiles => _deletedFiles.keys.toList();

  static File getManifestFileFromDirectory(Directory workingDir) {
    return workingDir.childFile('.migrateManifest.yaml');
  }

  bool validateYaml(YamlMap map) {
    return map.containsKey('mergedFiles') && map.containsKey('conflictFiles') && map.containsKey('newFiles') && map.containsKey('deletedFiles');
  }

  void writeFile() {
    String mergedFileManifestContents = '';
    String conflictFilesManifestContents = '';
    for (String localPath in _mergeResults.keys) {
      MergeResult result = _mergeResults[localPath]!;
      if (result.hasConflict) {
        conflictFilesManifestContents += '  - $localPath\n';
      } else {
        mergedFileManifestContents += '  - $localPath\n';
      }
    }

    String newFileManifestContents = '';
    for (String localPath in _additionalFiles.keys) {
      newFileManifestContents += '  - $localPath\n';
      print('  Wrote Additional file $localPath');
    }

    String deletedFileManifestContents = '';
    for (String localPath in _deletedFiles.keys) {
      deletedFileManifestContents += '  - $localPath\n';
    }

    String migrateManifestContents = 'mergedFiles:\n${mergedFileManifestContents}conflictFiles:\n${conflictFilesManifestContents}newFiles:\n${newFileManifestContents}deletedFiles:\n${deletedFileManifestContents}';
    File migrateManifest = getManifestFileFromDirectory(migrateRootDir);
    migrateManifest.createSync(recursive: true);
    migrateManifest.writeAsStringSync(migrateManifestContents, flush: true);
  }
}
