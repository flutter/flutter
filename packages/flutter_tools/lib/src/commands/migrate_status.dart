// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/terminal.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart';
import '../migrate/migrate_config.dart';
import '../migrate/migrate_manifest.dart';
import '../migrate/migrate_utils.dart';
import '../cache.dart';
import 'migrate.dart';

class MigrateStatusCommand extends FlutterCommand {
  MigrateStatusCommand({
    bool verbose = false,
  }) : _verbose = verbose {
    requiresPubspecYaml();
    argParser.addOption(
      'working-directory',
      help: '',
      defaultsTo: null,
      valueHelp: 'path',
    );
  }

  final bool _verbose;

  @override
  final String name = 'status';

  @override
  final String description = 'Prints the current status of the in progress migration.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  @override
  Future<FlutterCommandResult> runCommand() async {
    Directory workingDir = FlutterProject.current().directory.childDirectory(kDefaultMigrateWorkingDirectoryName);
    if (stringArg('working-directory') != null) {
      workingDir = globals.fs.directory(stringArg('working-directory'));
    }
    if (!workingDir.existsSync()) {
      print('No migration in progress. Start a new migration with:\n');
      print('    \$ flutter migrate start\n');
      return const FlutterCommandResult(ExitStatus.fail);
    }

    final File manifestFile = MigrateManifest.getManifestFileFromDirectory(workingDir);
    final MigrateManifest manifest = MigrateManifest.fromFile(manifestFile);

    checkAndPrintMigrateStatus(manifest, workingDir);

    return const FlutterCommandResult(ExitStatus.success);
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
      globals.printWarning('Unable to apply migration. The following files in the migration working directory still have unresolved conflicts:');
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
