// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/common.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../cache.dart';
import '../flutter_project_metadata.dart';
import '../migrate/migrate_manifest.dart';
import '../migrate/migrate_utils.dart';
import '../project.dart';
import '../runner/flutter_command.dart';
import '../version.dart';
import 'migrate.dart';

/// Migrate subcommand that checks the migrate working directory for unresolved conflicts and
/// applies the staged changes to the project.
class MigrateApplyCommand extends FlutterCommand {
  MigrateApplyCommand({
    bool verbose = false,
    required this.logger,
    required this.fileSystem,
  }) : _verbose = verbose {
    requiresPubspecYaml();
    argParser.addOption(
      'working-directory',
      help: 'Specifies the custom migration working directory used to stage and edit proposed changes.',
      valueHelp: 'path',
    );
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Ignore unresolved merge conflicts and apply staged changes by force.',
    );
  }

  final bool _verbose;

  final Logger logger;

  final FileSystem fileSystem;

  @override
  final String name = 'apply';

  @override
  final String description = r'Accepts the changes produced by `$ flutter migrate start` and copies the changed files into your project files. All merge conflicts should be resolved before apply will complete successfully. If conflicts still exist, this command will print the remaining conflicted files.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => const <DevelopmentArtifact>{};

  @override
  Future<FlutterCommandResult> runCommand() async {
    final FlutterProject flutterProject = FlutterProject.current();

    if (!await gitRepoExists(flutterProject.directory.path, logger)) {
      return const FlutterCommandResult(ExitStatus.fail);
    }

    final bool force = boolArg('force');

    Directory workingDirectory = flutterProject.directory.childDirectory(kDefaultMigrateWorkingDirectoryName);
    if (stringArg('working-directory') != null) {
      workingDirectory = fileSystem.directory(stringArg('working-directory'));
    }
    if (!workingDirectory.existsSync()) {
      logger.printStatus('No migration in progress. Please run:');
      MigrateUtils.printCommandText('flutter migrate start', logger);
      throwToolExit('No migration in progress.');
    }

    final File manifestFile = MigrateManifest.getManifestFileFromDirectory(workingDirectory);
    final MigrateManifest manifest = MigrateManifest.fromFile(manifestFile);
    if (!checkAndPrintMigrateStatus(manifest, workingDirectory, warnConflict: true, logger: logger) && !force) {
      throwToolExit('Conflicting files found. Resolve these conflicts and try again.');
    }

    if (await hasUncommittedChanges(flutterProject.directory.path, logger) && !force) {
      return const FlutterCommandResult(ExitStatus.fail);
    }

    logger.printStatus('Applying migration.');
    // Copy files from working directory to project root
    final List<String> allFilesToCopy = <String>[];
    allFilesToCopy.addAll(manifest.mergedFiles);
    allFilesToCopy.addAll(manifest.conflictFiles);
    allFilesToCopy.addAll(manifest.addedFiles);
    if (allFilesToCopy.isNotEmpty && _verbose) {
      logger.printStatus('Modifying ${allFilesToCopy.length} files.', indent: 2);
    }
    for (final String localPath in allFilesToCopy) {
      if (_verbose) {
        logger.printStatus('Copying $localPath');
      }
      final File workingFile = workingDirectory.childFile(localPath);
      final File targetFile = flutterProject.directory.childFile(localPath);
      if (!workingFile.existsSync()) {
        continue;
      }

      if (!targetFile.existsSync()) {
        targetFile.createSync(recursive: true);
      }
      try {
        targetFile.writeAsStringSync(workingFile.readAsStringSync(), flush: true);
      } on FileSystemException {
        logger.printStatus('Writing Bytes', indent: 2);
        targetFile.writeAsBytesSync(workingFile.readAsBytesSync(), flush: true);
      }
    }
    // Delete files slated for deletion.
    if (manifest.deletedFiles.isNotEmpty) {
      logger.printStatus('Deleting ${manifest.deletedFiles.length} files.', indent: 2);
    }
    for (final String localPath in manifest.deletedFiles) {
      final File targetFile = FlutterProject.current().directory.childFile(localPath);
      targetFile.deleteSync();
    }

    // Update the migrate config files to reflect latest migration.
    if (_verbose) {
      logger.printStatus('Updating .migrate_configs');
    }
    final FlutterProjectMetadata metadata = FlutterProjectMetadata(flutterProject.directory.childFile('.metadata'), logger);
    final FlutterVersion version = FlutterVersion(workingDirectory: flutterProject.directory.absolute.path);

    final String currentGitHash = version.frameworkRevision;
    metadata.migrateConfig.populate(
      projectDirectory: flutterProject.directory,
      currentRevision: currentGitHash,
      logger: logger,
    );

    // Clean up the working directory
    workingDirectory.deleteSync(recursive: true);

    logger.printStatus('Migration complete. You may use commands like `git status`, `git diff` and `git restore <file>` to continue working with the migrated files.');
    return const FlutterCommandResult(ExitStatus.success);
  }
}
