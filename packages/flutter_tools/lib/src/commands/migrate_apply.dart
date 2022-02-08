// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../globals.dart' as globals;
import '../project.dart';
import '../runner/flutter_command.dart';
import '../migrate/migrate_config.dart';
import '../migrate/migrate_manifest.dart';
import '../migrate/migrate_utils.dart';
import '../cache.dart';
import 'migrate.dart';

class MigrateApplyCommand extends FlutterCommand {
  MigrateApplyCommand({
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
  final String name = 'apply';

  @override
  final String description = 'Accepts the changes produced by `\$ flutter migrate start` and copies the changed files into your project files. All merge conflicts should be resolved before apply will complete successfully. If conflicts still exist, this command will print the remaining conflicted files.';

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
      throwToolExit('No migration in progress. Please run `flutter migrate start` first.');
    }

    final File manifestFile = MigrateManifest.getManifestFileFromDirectory(workingDir);
    final MigrateManifest manifest = MigrateManifest.fromFile(manifestFile);
    if (!checkAndPrintMigrateStatus(manifest, workingDir, warnConflict: true)) {
      throwToolExit('Conflicting files found.');
    }

    if (await MigrateUtils.hasUncommitedChanges(workingDir.path)) {
      throwToolExit('There are uncommitted changes in your project. Please commit, abandon, or stash your changes before trying again.');
    }

    print('Applying migration.');
    // Copy files from working dir to project root
    final List<String> allFilesToCopy = <String>[];
    allFilesToCopy.addAll(manifest.mergedFiles);
    allFilesToCopy.addAll(manifest.conflictFiles);
    allFilesToCopy.addAll(manifest.addedFiles);
    if (allFilesToCopy.isNotEmpty) {
      print('Modifying ${allFilesToCopy.length} files.');
    }
    if (manifest.deletedFiles.isNotEmpty) {
      print('Deleting ${allFilesToCopy.length} files.');
    }
    for (String localPath in allFilesToCopy) {
      final File workingFile = workingDir.childFile(localPath);
      final File targetFile = FlutterProject.current().directory.childFile(localPath);
      if (!workingFile.existsSync()) {
        continue;
      }

      if (!targetFile.existsSync()) {
        targetFile.createSync(recursive: true);
      }
      try {
        targetFile.writeAsStringSync(workingFile.readAsStringSync(), flush: true);
      } on FileSystemException {
        targetFile.writeAsBytesSync(workingFile.readAsBytesSync(), flush: true);
      }
    }
    // Delete files slated for deletion.
    for (String localPath in manifest.deletedFiles) {
      final File targetFile = FlutterProject.current().directory.childFile(localPath);
      targetFile.deleteSync();
    }

    // Update the migrate config files to reflect latest migration.
    final List<MigrateConfig> configs = await MigrateConfig.parseOrCreateMigrateConfigs();
    final String currentGitHash = await MigrateUtils.getGitHash(Cache.flutterRoot!);
    for (MigrateConfig config in configs) {
      config.lastMigrateVersion = currentGitHash;
      config.writeFile(projectDirectory: FlutterProject.current().directory);
    }

    // Clean up the working directory
    workingDir.deleteSync(recursive: true);

    globals.logger.printStatus('Migration complete. You may use commands like `git status`, `git diff` and `git restore <file>` to continue working with the migrated files.');
    return const FlutterCommandResult(ExitStatus.success);
  }
}
